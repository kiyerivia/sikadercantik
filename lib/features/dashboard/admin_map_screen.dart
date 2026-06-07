import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import 'map_providers.dart';

class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _center = LatLng(-7.4120, 108.9950);

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

  Future<void> _getCurrentLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _tempLocation = newLocation;
      });

      _mapController.move(
        newLocation,
        18.0,
      ); // Zoom lebih dekat agar mudah di-tap presisi

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Lokasi GPS ditemukan! (Geser/klik langsung pada atap bangunan jika kurang pas)',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
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
                    : 'Peta Sebaran Jentik (OpenLayers/OSM)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
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
                  color: Colors.red.withOpacity(0.25),
                  borderColor: Colors.red.withOpacity(0.8),
                  borderStrokeWidth: 2,
                  useRadiusInMeter: true,
                  radius: 300,
                )).toList());
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12.5, // Zoom out to show all 10 villages
                  onTap: (tapPosition, point) => _handleMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                    color: _getColor(v.abj).withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                            color: _getColor(_infoAbj),
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
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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

              // Tombol Lokasi Sekarang (Bulat di Kanan Bawah saat Edit Mode)
              if (_isEditMode && _selectedPosyandu != null)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    tooltip: 'Dapatkan Lokasi GPS Saat Ini',
                    child: _isLoadingLocation
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Icon(Icons.my_location, size: 28),
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
        color: Colors.blue.shade50.withOpacity(0.4),
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
        color: Colors.red.shade50.withOpacity(0.4),
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
