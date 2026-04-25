import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/widgets/location_selector.dart';

class ReportFormScreen extends HookConsumerWidget {
  const ReportFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final housesInspectedController = useTextEditingController();
    final housesPositiveController = useTextEditingController();
    final notesController = useTextEditingController();
    
    final selectedPosyanduId = useState<String?>(null);
    final selectedBreedingPlaces = useState<List<String>>([]);
    final isLoading = useState(false);

    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Posyandu')),
        );
        return;
      }

      isLoading.value = true;
      try {
        await ref.read(reportRepositoryProvider).submitReport(
          posyanduId: selectedPosyanduId.value!,
          housesInspected: int.parse(housesInspectedController.text),
          housesPositive: int.parse(housesPositiveController.text),
          breedingPlaceIds: selectedBreedingPlaces.value,
          notes: notesController.text,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dikirim!')),
          );
          ref.invalidate(myReportsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim laporan: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Laporan Jentik'),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi Pemeriksaan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              LocationSelector(
                onSelected: (v, r, p) {
                  selectedPosyanduId.value = p;
                },
              ),
              const Divider(height: 48),
              
              const Text(
                'Data Hasil Pemeriksaan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: housesInspectedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Rumah Diperiksa',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Harus diisi';
                  if (int.tryParse(val) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: housesPositiveController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Rumah Positif Jentik',
                  prefixIcon: Icon(Icons.bug_report_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Harus diisi';
                  final positive = int.tryParse(val);
                  if (positive == null) return 'Harus angka';
                  final inspected = int.tryParse(housesInspectedController.text) ?? 0;
                  if (positive > inspected) return 'Tidak boleh melebihi rumah diperiksa';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Tempat Perkembangbiakan (Ditemukan Jentik)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              breedingPlacesAsync.when(
                data: (places) => Wrap(
                  spacing: 8,
                  children: places.map((place) {
                    final id = place['id'] as String;
                    final isSelected = selectedBreedingPlaces.value.contains(id);
                    return FilterChip(
                      label: Text(place['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          selectedBreedingPlaces.value = [...selectedBreedingPlaces.value, id];
                        } else {
                          selectedBreedingPlaces.value = selectedBreedingPlaces.value.where((val) => val != id).toList();
                        }
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Gagal memuat kategori: $e'),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: isLoading.value ? null : handleSubmit,
                child: isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KIRIM LAPORAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
