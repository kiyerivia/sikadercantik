import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/master_providers.dart';

class LocationSelector extends HookConsumerWidget {
  final String? initialVillageId;
  final String? initialRwId;
  final String? initialPosyanduId;
  final Function(String? villageId, String? rwId, String? posyanduId) onSelected;

  const LocationSelector({
    super.key,
    this.initialVillageId,
    this.initialRwId,
    this.initialPosyanduId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesAsync = ref.watch(villagesProvider);
    
    final selectedVillage = useState<String?>(initialVillageId);
    final selectedRW = useState<String?>(initialRwId);
    final selectedPosyandu = useState<String?>(initialPosyanduId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Village Dropdown
        villagesAsync.when(
          data: (villages) => DropdownButtonFormField<String>(
            value: selectedVillage.value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Desa/Kelurahan',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: villages.map((v) => DropdownMenuItem(
              value: v.id, 
              child: Text(v.name, overflow: TextOverflow.ellipsis)
            )).toList(),
            onChanged: (val) {
              selectedVillage.value = val;
              selectedRW.value = null;
              selectedPosyandu.value = null;
              onSelected(val, null, null);
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Gagal memuat desa: $e', style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 16),
        
        // RW Dropdown
        if (selectedVillage.value != null) ...[
          ref.watch(rwsProvider(selectedVillage.value!)).when(
            data: (rws) => DropdownButtonFormField<String>(
              value: selectedRW.value,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'RW',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
              items: rws.map((r) => DropdownMenuItem(
                value: r.id, 
                child: Text('RW ${r.rwNumber}')
              )).toList(),
              onChanged: (val) {
                selectedRW.value = val;
                selectedPosyandu.value = null;
                onSelected(selectedVillage.value, val, null);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Gagal memuat RW: $e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),
        ] else ...[
          DropdownButtonFormField<String>(
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'RW',
              prefixIcon: Icon(Icons.numbers_outlined),
              hintText: 'Pilih Desa terlebih dahulu',
            ),
            items: const [],
          ),
          const SizedBox(height: 16),
        ],

        // Posyandu Dropdown
        if (selectedRW.value != null) ...[
          ref.watch(posyandusProvider(selectedRW.value!)).when(
            data: (posyandus) => DropdownButtonFormField<String>(
              value: selectedPosyandu.value,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Posyandu',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              items: posyandus.map((p) => DropdownMenuItem(
                value: p.id, 
                child: Text(p.name, overflow: TextOverflow.ellipsis)
              )).toList(),
              onChanged: (val) {
                selectedPosyandu.value = val;
                onSelected(selectedVillage.value, selectedRW.value, val);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Gagal memuat Posyandu: $e', style: const TextStyle(color: Colors.red)),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Posyandu',
              prefixIcon: Icon(Icons.local_hospital_outlined),
              hintText: 'Pilih RW terlebih dahulu',
            ),
            items: const [],
          ),
        ],
      ],
    );
  }
}
