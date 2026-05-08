import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import 'map_providers.dart';

class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  late GoogleMapController mapController;
  static const LatLng _center = LatLng(-7.4120, 108.9950);

  // State untuk mode edit
  bool _isEditMode = false;
  Posyandu? _selectedPosyandu;
  LatLng? _tempLocation;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _handleMapTap(LatLng position) {
    if (_isEditMode && _selectedPosyandu != null) {
      setState(() {
        _tempLocation = position;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedPosyandu == null || _tempLocation == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('posyandus').update({
        'latitude': _tempLocation!.latitude,
        'longitude': _tempLocation!.longitude,
      }).eq('id', _selectedPosyandu!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lokasi ${_selectedPosyandu!.name} berhasil disimpan!')),
        );
        setState(() {
          _isEditMode = false;
          _selectedPosyandu = null;
          _tempLocation = null;
        });
        ref.invalidate(posyanduListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan lokasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double _getHue(double abj) {
    if (abj >= 95) return BitmapDescriptor.hueGreen;
    if (abj >= 85) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  @override
  Widget build(BuildContext context) {
    final posyanduAsync = ref.watch(posyanduListProvider);
    final abjDataAsync = ref.watch(posyanduAbjProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isEditMode ? Colors.orange.shade800 : const Color(0xFF1F618D),
        title: Text(
          _isEditMode ? 'Klik Peta untuk Set Lokasi' : 'Peta Sebaran Jentik',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isEditMode) {
              setState(() => _isEditMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit_location_alt, color: Colors.white),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(posyanduAbjProvider);
              ref.invalidate(posyanduListProvider);
            },
          ),
        ],
      ),
      body: posyanduAsync.when(
        data: (posyandus) {
          final abjStats = abjDataAsync.value ?? {};
          
          final markers = posyandus.where((p) => p.latitude != null && p.longitude != null).map((p) {
            final stats = abjStats[p.id];
            final abj = stats?['abj'] ?? 100.0;
            
            return Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.latitude!, p.longitude!),
              infoWindow: InfoWindow(
                title: p.name,
                snippet: 'ABJ: ${abj.toStringAsFixed(1)}% | Diperiksa: ${stats?['inspected'] ?? 0}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(abj)),
            );
          }).toSet();

          // Tambah marker sementara saat edit
          if (_isEditMode && _tempLocation != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('temp'),
                position: _tempLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(title: _selectedPosyandu?.name ?? 'Lokasi Baru'),
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                onTap: _handleMapTap,
                initialCameraPosition: const CameraPosition(
                  target: _center,
                  zoom: 14.0,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
              ),
              
              if (_isEditMode)
                _buildEditPanel(posyandus),

              if (!_isEditMode && markers.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Belum ada koordinat Posyandu yang diset. Klik ikon Edit Lokasi di pojok kanan atas untuk mulai.',
                      textAlign: TextAlign.center,
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
                      color: Colors.white.withOpacity(0.9),
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
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.green, 'Aman (>= 95%)'),
                        _buildLegendItem(Colors.orange, 'Waspada (85-94%)'),
                        _buildLegendItem(Colors.red, 'Bahaya (< 85%)'),
                      ],
                    ),
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

  Widget _buildEditPanel(List<Posyandu> posyandus) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Posyandu>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Posyandu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                initialValue: _selectedPosyandu,
                items: posyandus.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPosyandu = val),
              ),
              const SizedBox(height: 16),
              if (_selectedPosyandu != null)
                Text(
                  _tempLocation == null 
                    ? 'Sekarang, silakan klik titik di peta untuk ${_selectedPosyandu!.name}'
                    : 'Lokasi terpilih: ${_tempLocation!.latitude.toStringAsFixed(4)}, ${_tempLocation!.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue.shade900),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditMode = false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _tempLocation == null ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan Lokasi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
