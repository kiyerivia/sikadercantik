import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import 'map_providers.dart';

enum MapTileTheme {
  googleRoadmap(
    label: 'Google Maps (Standar)',
    sublabel: 'Peta jalan raya jelas, navigasi & landmark',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    maxZoom: 20.0,
    icon: Icons.map_outlined,
  ),
  googleHybrid(
    label: 'Google Maps Satelit (Hybrid)',
    sublabel: 'Citra satelit asli + nama jalan & atap rumah',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    maxZoom: 20.0,
    icon: Icons.satellite_alt_outlined,
  ),
  googleTerrain(
    label: 'Google Maps Terrain',
    sublabel: 'Topografi, kontur daratan & perbukitan',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    maxZoom: 20.0,
    icon: Icons.terrain_outlined,
  ),
  osm(
    label: 'OpenStreetMap (OSM)',
    sublabel: 'Peta terbuka komunitas OpenLayers / OSM',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19.0,
    icon: Icons.public_outlined,
  );

  final String label;
  final String sublabel;
  final String urlTemplate;
  final List<String> subdomains;
  final double maxZoom;
  final IconData icon;

  const MapTileTheme({
    required this.label,
    required this.sublabel,
    required this.urlTemplate,
    required this.subdomains,
    required this.maxZoom,
    required this.icon,
  });
}

class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _center = LatLng(-7.3890, 108.9920);

  // State Tema Peta
  MapTileTheme _currentTheme = MapTileTheme.googleRoadmap;

  // State Live GPS Tracking (Google Maps Live Location)
  StreamSubscription<Position>? _positionStream;
  LatLng? _userLocation;
  double? _userAccuracy;
  bool _isLiveTracking = false;
  bool _followUserLocation = false;

  // State untuk mode edit
  bool _isEditMode = false;
  Posyandu? _selectedToView;
  Posyandu? _selectedPosyandu;
  Posyandu? _selectedToDelete;
  LatLng? _tempLocation;
  bool _isLoadingLocation = false;

  // State untuk pencarian
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // State untuk info window saat marker di-tap
  String? _infoTitle;
  double _infoAbj = 100.0;
  int _infoInspected = 0;

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleMapTap(LatLng position) {
    if (_isEditMode && _selectedPosyandu != null) {
      setState(() {
        _tempLocation = position;
      });
    } else if (!_isEditMode) {
      setState(() {
        _infoTitle = null;
      });
    }
  }

  Future<void> _startLiveTracking({bool centerMap = true}) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan GPS tidak aktif di perangkat Anda.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak oleh browser/perangkat.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi diblokir permanen di pengaturan browser/perangkat.';
      }

      // 1. Ambil lokasi awal segera
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final currentLatLng = LatLng(initialPos.latitude, initialPos.longitude);

      setState(() {
        _userLocation = currentLatLng;
        _userAccuracy = initialPos.accuracy;
        _isLiveTracking = true;
        _followUserLocation = true;

        if (_isEditMode && _selectedPosyandu != null) {
          _tempLocation = currentLatLng;
        }
      });

      if (centerMap) {
        _mapController.move(currentLatLng, 17.5);
      }

      // 2. Continuous real-time GPS stream
      await _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2, // Tiap 2 meter
        ),
      ).listen((Position pos) {
        if (!mounted) return;
        final newLatLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = newLatLng;
          _userAccuracy = pos.accuracy;

          if (_isEditMode && _selectedPosyandu != null && _tempLocation == null) {
            _tempLocation = newLatLng;
          }
        });

        if (_followUserLocation) {
          _mapController.move(newLatLng, _mapController.camera.zoom);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📍 Live GPS Aktif! Titik biru mengikuti pergerakan posisi Anda secara realtime.',
                    style: GoogleFonts.outfit(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A73E8),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengaktifkan live GPS: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _toggleLiveTracking() {
    if (_isLiveTracking) {
      if (_userLocation != null && !_followUserLocation) {
        setState(() {
          _followUserLocation = true;
        });
        _mapController.move(_userLocation!, 17.5);
      } else {
        _positionStream?.cancel();
        _positionStream = null;
        setState(() {
          _isLiveTracking = false;
          _followUserLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Live GPS Tracking dinonaktifkan.',
              style: GoogleFonts.outfit(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      _startLiveTracking(centerMap: true);
    }
  }


  void _showLayerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          color: Color(0xFF10365F),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih Mode Peta',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10365F),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ganti tampilan peta ke Google Maps standar, satelit hybrid, terrain, atau OSM.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: MapTileTheme.values.map((theme) {
                        final isSelected = _currentTheme == theme;
                        return Card(
                          elevation: isSelected ? 2 : 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1A73E8)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          color: isSelected
                              ? const Color(0xFFE8F0FE)
                              : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1A73E8)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                theme.icon,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blueGrey,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              theme.label,
                              style: GoogleFonts.outfit(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFF1A73E8)
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              theme.sublabel,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF1A73E8),
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _currentTheme = theme;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveLocation() async {
    if (_selectedPosyandu == null || _tempLocation == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('posyandus')
          .update({
            'latitude': _tempLocation!.latitude,
            'longitude': _tempLocation!.longitude,
          })
          .eq('id', _selectedPosyandu!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi ${_selectedPosyandu!.name} berhasil disimpan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditMode = false;
          _selectedToView = null;
          _selectedPosyandu = null;
          _selectedToDelete = null;
          _tempLocation = null;
        });
        ref.invalidate(posyanduListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan lokasi: $e\n\n💡 SOLUSI: Jika muncul error "Could not find column in schema cache", buka dashboard Supabase Anda -> Settings -> API -> klik tombol "Reload schema cache" (atau jalankan query SQL: NOTIFY pgrst, reload_schema;). Pastikan juga tabel posyandus memiliki kolom latitude & longitude tipe float8.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _deleteLocation() async {
    if (_selectedToDelete == null) return;

    final target = _selectedToDelete!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Koordinat?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade800,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus koordinat lokasi peta untuk "${target.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('posyandus')
          .update({'latitude': null, 'longitude': null})
          .eq('id', target.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koordinat ${target.name} berhasil dihapus.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        setState(() {
          _selectedToDelete = null;
          _selectedToView = null;
        });
        ref.invalidate(posyanduListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus koordinat: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Color _getColor(double abj) {
    if (abj >= 95) return Colors.green.shade600;
    if (abj >= 85) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final posyanduAsync = ref.watch(posyanduListProvider);
    final abjDataAsync = ref.watch(posyanduAbjProvider);
    final villageDataAsync = ref.watch(villageMapDataProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isEditMode
            ? Colors.orange.shade800
            : const Color(0xFF10365F),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Cari nama desa...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  final query = val.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    final villages = villageDataAsync.value ?? [];
                    final matches = villages.where((v) => v.name.toLowerCase().contains(query)).toList();
                    if (matches.length == 1) {
                      _mapController.move(LatLng(matches.first.latitude, matches.first.longitude), 15.0);
                    }
                  }
                },
                onSubmitted: (val) {
                  final query = val.trim().toLowerCase();
                  if (query.isEmpty) return;
                  final villages = villageDataAsync.value ?? [];
                  final matches = villages.where((v) => v.name.toLowerCase().contains(query)).toList();
                  if (matches.isNotEmpty) {
                    final v = matches.first;
                    setState(() {
                      _mapController.move(LatLng(v.latitude, v.longitude), 18.0);
                      _infoTitle = v.name;
                      _infoAbj = v.abj;
                      _infoInspected = v.inspected;
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              )
            : Text(
                _isEditMode
                    ? 'Klik Peta untuk Presisi Titik Lokasi'
                    : 'Peta Sebaran Jentik (${_currentTheme == MapTileTheme.googleHybrid ? 'Google Satelit' : _currentTheme == MapTileTheme.googleRoadmap ? 'Google Maps' : _currentTheme == MapTileTheme.googleTerrain ? 'Google Terrain' : 'OSM'})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else if (_isEditMode) {
              setState(() {
                _isEditMode = false;
                _selectedToView = null;
                _selectedPosyandu = null;
                _selectedToDelete = null;
                _tempLocation = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditMode && !_isSearching)
            IconButton(
              icon: const Icon(Icons.layers_outlined, color: Colors.white),
              tooltip: 'Pilih Mode Peta',
              onPressed: _showLayerSelector,
            ),
          if (!_isEditMode && !_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Cari Desa',
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Tutup Pencarian',
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          if (!_isEditMode && !_isSearching)
            IconButton(
              icon: const Icon(Icons.edit_location_alt, color: Colors.white),
              tooltip: 'Edit Lokasi Posyandu',
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
              onPressed: () {
                ref.invalidate(posyanduAbjProvider);
                ref.invalidate(posyanduListProvider);
                ref.invalidate(villageMapDataProvider);
                setState(() {
                  _infoTitle = null;
                });
              },
            ),
        ],
      ),
      body: posyanduAsync.when(
        data: (posyandus) {
          final abjStats = abjDataAsync.value ?? {};
          final villages = villageDataAsync.value ?? [];

          final String query = _searchQuery.trim().toLowerCase();

          final List<Marker> markers = [];
          final List<CircleMarker> circles = [];

          if (_isEditMode) {
            markers.addAll(posyandus
              .where((p) => p.latitude != null && p.longitude != null)
              .map((p) => Marker(
                  point: LatLng(p.latitude!, p.longitude!),
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ))
              .toList());
          } else {
            final filteredVillages = villages.where((v) => query.isEmpty || v.name.toLowerCase().contains(query)).toList();
            
            markers.addAll(filteredVillages.map((v) => Marker(
                  point: LatLng(v.latitude, v.longitude),
                  width: 120,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _infoTitle = v.name;
                        _infoAbj = v.abj;
                        _infoInspected = v.inspected;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColor(v.abj),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            v.name,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList());
                
            circles.addAll(filteredVillages
              .where((v) => v.abj < 100.0)
              .map((v) => CircleMarker(
                  point: LatLng(v.latitude, v.longitude),
                  color: Colors.red.withValues(alpha: 0.25),
                  borderColor: Colors.red.withValues(alpha: 0.8),
                  borderStrokeWidth: 2,
                  useRadiusInMeter: true,
                  radius: 300,
                )).toList());
          }

          // Live GPS User Location (Google Maps Pulsing Blue Dot & Accuracy)
          if (_userLocation != null) {
            circles.add(
              CircleMarker(
                point: _userLocation!,
                color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                borderColor: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                borderStrokeWidth: 1.5,
                useRadiusInMeter: true,
                radius: (_userAccuracy != null && _userAccuracy! > 5)
                    ? _userAccuracy!
                    : 15,
              ),
            );

            markers.add(
              Marker(
                point: _userLocation!,
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _infoTitle = '📍 Lokasi Saya (Real-time GPS)';
                      _infoAbj = 100.0;
                      _infoInspected = 0;
                    });
                  },
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing glow
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
                          ),
                        ),
                        // Blue Dot Google Maps
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A73E8),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12.5, // Zoom out to show all 10 villages
                  onTap: (tapPosition, point) => _handleMapTap(point),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && _followUserLocation) {
                      setState(() {
                        _followUserLocation = false;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _currentTheme.urlTemplate,
                    subdomains: _currentTheme.subdomains,
                    maxZoom: _currentTheme.maxZoom,
                    userAgentPackageName: 'com.example.sikadercantik',
                  ),
                  CircleLayer(circles: circles), // Added Area Effect
                  MarkerLayer(markers: markers),
                ],
              ),

              // Pop-up Daftar Hasil Pencarian saat Mengetik
              if (_isSearching && query.isNotEmpty)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: (_isEditMode ? [] : villageDataAsync.value ?? [])
                            .where((v) => query.isNotEmpty && v.name.toLowerCase().contains(query))
                            .map((v) {
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _getColor(v.abj).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.map,
                                    color: _getColor(v.abj),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  v.name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'ABJ: ${v.abj.toStringAsFixed(1)}% | ${v.inspected} rumah diperiksa',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  setState(() {
                                    _mapController.move(
                                      LatLng(v.latitude, v.longitude),
                                      18.0,
                                    );
                                    _infoTitle = v.name;
                                    _infoAbj = v.abj;
                                    _infoInspected = v.inspected;
                                    _isSearching = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                ),

              if (_isEditMode) _buildEditPanel(posyandus, abjStats),

              if (!_isEditMode && markers.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada koordinat Desa yang diset di peta.\nKlik ikon Edit Lokasi di pojok kanan atas untuk mulai menandai koordinat Desa.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.blueGrey.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Layer Selector Chip (Pojok Kanan Atas Peta)
              if (!_isSearching)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _showLayerSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentTheme.icon,
                              color: const Color(0xFF10365F),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentTheme == MapTileTheme.googleHybrid
                                  ? 'Satelit Hybrid'
                                  : _currentTheme == MapTileTheme.googleRoadmap
                                      ? 'Google Maps'
                                      : _currentTheme == MapTileTheme.googleTerrain
                                          ? 'Terrain'
                                          : 'OSM',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.blueGrey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Pop-up Info Window Floating Card
              if (!_isEditMode && _infoTitle != null)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(
                            color: _infoTitle!.contains('Lokasi Saya')
                                ? const Color(0xFF1A73E8)
                                : _getColor(_infoAbj),
                            width: 6,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _infoTitle!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10365F),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _infoTitle = null),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_infoTitle!.contains('Lokasi Saya')) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.gps_fixed,
                                  size: 20,
                                  color: Color(0xFF1A73E8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Koordinat GPS: ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  _userLocation != null
                                      ? '${_userLocation!.latitude.toStringAsFixed(5)}, ${_userLocation!.longitude.toStringAsFixed(5)}'
                                      : '-',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10365F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.radar,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Akurasi: ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  _userAccuracy != null
                                      ? '±${_userAccuracy!.toStringAsFixed(1)} meter'
                                      : 'Optimal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 20,
                                  color: Colors.blueGrey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Capaian Angka Bebas Jentik (ABJ): ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  '${_infoAbj.toStringAsFixed(1)}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getColor(_infoAbj),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 20,
                                  color: Colors.blueGrey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Rumah Diperiksa: ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  '$_infoInspected rumah',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Legend Overlay (Sembunyikan saat edit agar tidak penuh)
              if (!_isEditMode)
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Keterangan ABJ:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          Colors.green.shade600,
                          'Aman (>= 95%)',
                        ),
                        _buildLegendItem(
                          Colors.orange.shade600,
                          'Waspada (85-94%)',
                        ),
                        _buildLegendItem(Colors.red.shade600, 'Bahaya (< 85%)'),
                      ],
                    ),
                  ),
                ),

              // Floating Controls Google Maps di Pojok Kanan Bawah (Zoom & Live GPS)
              Positioned(
                bottom: 24,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Controls
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                (_mapController.camera.zoom + 1).clamp(3.0, 20.0),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.add, size: 22, color: Color(0xFF10365F)),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          InkWell(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                (_mapController.camera.zoom - 1).clamp(3.0, 20.0),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.remove, size: 22, color: Color(0xFF10365F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // My Location / Live GPS FAB
                    FloatingActionButton(
                      heroTag: 'map_realtime_location_fab',
                      onPressed: _isLoadingLocation ? null : _toggleLiveTracking,
                      backgroundColor: _isLiveTracking
                          ? const Color(0xFF1A73E8)
                          : Colors.white,
                      foregroundColor: _isLiveTracking
                          ? Colors.white
                          : const Color(0xFF1A73E8),
                      elevation: 6,
                      tooltip: _isLiveTracking
                          ? (_followUserLocation
                              ? 'GPS Live Aktif (Mengikuti posisi Anda)'
                              : 'Pusatkan ke Posisi Saya')
                          : 'Pusatkan & Aktifkan Live GPS Tracking',
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF1A73E8),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  _isLiveTracking
                                      ? (_followUserLocation
                                          ? Icons.my_location
                                          : Icons.location_searching)
                                      : Icons.my_location,
                                  size: 26,
                                ),
                                if (_isLiveTracking && _followUserLocation)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEditPanel(
    List<Posyandu> posyandus,
    Map<String, dynamic> abjStats,
  ) {
    final markedPosyandus = posyandus
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    final bool isWide = MediaQuery.of(context).size.width >= 768;

    // Jika Posyandu sudah dipilih untuk ditandai, sembunyikan panel besar agar tidak menutupi peta
    if (_selectedPosyandu != null) {
      return Positioned(
        top: 20,
        left: 20,
        right: 20,
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.orange.shade800,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Menandai: ${_selectedPosyandu!.name}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tempLocation == null
                            ? 'Klik/tap di peta atau tombol GPS di kanan bawah'
                            : 'Koordinat: ${_tempLocation!.latitude.toStringAsFixed(5)}, ${_tempLocation!.longitude.toStringAsFixed(5)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tempLocation != null) ...[
                  ElevatedButton.icon(
                    key: const ValueKey('banner_save_button'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: Text(
                      'Simpan',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _saveLocation,
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Batal / Kembali ke Pilihan',
                  onPressed: () {
                    setState(() {
                      _selectedPosyandu = null;
                      _tempLocation = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_outlined,
                            color: Color(0xFF10365F),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengaturan Titik Lokasi Peta',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                      onPressed: () => setState(() {
                        _isEditMode = false;
                        _selectedToView = null;
                        _selectedPosyandu = null;
                        _selectedToDelete = null;
                        _tempLocation = null;
                      }),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Bagian Atas: Dropdown Lihat Fasilitas yang Sudah Ditandai
                Row(
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      color: Color(0xFF10365F),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lihat Lokasi Fasilitas / Posyandu di Peta',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Posyandu>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Fasilitas / Posyandu yang Sudah Ditandai',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  initialValue: _selectedToView,
                  items: markedPosyandus.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name,
                        style: GoogleFonts.outfit(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedToView = val;
                      if (val != null &&
                          val.latitude != null &&
                          val.longitude != null) {
                        final latlng = LatLng(val.latitude!, val.longitude!);
                        _mapController.move(latlng, 18.0);
                        final stats = abjStats[val.id];
                        final abj = stats?['abj'] ?? 100.0;
                        final inspected = stats?['inspected'] ?? 0;
                        _infoTitle = val.name;
                        _infoAbj = (abj is num) ? abj.toDouble() : 100.0;
                        _infoInspected = (inspected is int) ? inspected : 0;
                        _isEditMode = false; // Panel otomatis tertutup!
                      }
                    });
                  },
                ),

                const SizedBox(height: 20),
                const Divider(height: 24),

                // Bagian Bawah Responsif (Kiri: Tambah/Ubah | Kanan: Hapus)
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAddEditBox(posyandus)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDeleteBox(markedPosyandus)),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAddEditBox(posyandus),
                      const SizedBox(height: 16),
                      _buildDeleteBox(markedPosyandus),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEditBox(List<Posyandu> posyandus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_location_alt_outlined,
                color: Colors.blue.shade800,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tambah / Ubah Titik Lokasi',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Posyandu>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pilih untuk Ditandai',
              border: OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.local_hospital_rounded,
                color: Colors.green,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            initialValue: _selectedPosyandu,
            items: posyandus.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(
                  p.name,
                  style: GoogleFonts.outfit(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              _selectedPosyandu = val;
              _tempLocation = val?.latitude != null && val?.longitude != null
                  ? LatLng(val!.latitude!, val.longitude!)
                  : null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBox(List<Posyandu> markedPosyandus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hapus Titik Koordinat',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (markedPosyandus.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada fasilitas / Posyandu yang ditandai.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<Posyandu>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih untuk Dihapus',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              initialValue: _selectedToDelete,
              items: markedPosyandus.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    style: GoogleFonts.outfit(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedToDelete = val),
            ),
            if (_selectedToDelete != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteLocation,
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: Text(
                    'Hapus Koordinat',
                    style: GoogleFonts.outfit(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade400, width: 1.5),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 11)),
        ],
      ),
    );
  }
}
