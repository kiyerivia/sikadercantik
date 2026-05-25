import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/notification_badge.dart';

class HouseReportEntry {
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  final TextEditingController positivePlacesCountController = TextEditingController();
  String? selectedResult;
  List<String?> selectedPlaceIds = [null];

  HouseReportEntry();

  void dispose() {
    kkNameController.dispose();
    rtController.dispose();
    rwController.dispose();
    positivePlacesCountController.dispose();
  }
}

class ReportFormScreen extends HookConsumerWidget {
  final Report? initialReport;
  const ReportFormScreen({super.key, this.initialReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final housesInspectedController = useTextEditingController();
    final housesPositiveController = useTextEditingController();
    
    final houseEntries = useState<List<HouseReportEntry>>([]);
    final isEdit = initialReport != null;
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(initialReport?.posyanduId);
    final reportDate = useState(initialReport?.reportDate ?? DateTime.now());
    final isLoading = useState(false);

    // Initialize data
    useEffect(() {
      if (initialReport != null) {
        // Populate totals
        housesInspectedController.text = initialReport!.housesInspected.toString();
        housesPositiveController.text = initialReport!.housesPositive.toString();
        
        // Fetch village ID
        ref.read(masterRepositoryProvider).getVillageIdByPosyandu(initialReport!.posyanduId).then((vId) {
          selectedVillageId.value = vId;
        });

        // Parse notes
        if (initialReport!.notes != null) {
          final parsed = <HouseReportEntry>[];
          final blocks = initialReport!.notes!.split('--- KK');
          for (var block in blocks) {
            if (block.trim().isEmpty) continue;
            final entry = HouseReportEntry();
            final lines = block.split('\n');
            for (var line in lines) {
              final t = line.trim();
              if (t.startsWith('Nama KK: ')) {
                entry.kkNameController.text = t.substring(9);
              } else if (t.startsWith('RT/RW: ')) {
                final parts = t.substring(7).split('/');
                if (parts.length == 2) {
                  entry.rtController.text = parts[0];
                  entry.rwController.text = parts[1];
                }
              }
              else if (t.startsWith('Hasil: ')) entry.selectedResult = t.substring(7);
              else if (t.startsWith('Jumlah: ')) entry.positivePlacesCountController.text = t.substring(8);
            }
            parsed.add(entry);
          }
          if (parsed.isNotEmpty) houseEntries.value = parsed;
        }
      } else if (houseEntries.value.isEmpty) {
        houseEntries.value = [HouseReportEntry()];
      }
      
      return () {
        for (var entry in houseEntries.value) {
          entry.dispose();
        }
      };
    }, [initialReport]);

    // Watch Master Data
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : const AsyncValue.data(<Posyandu>[]);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    Future<void> handleSubmit() async {
      // 1. Validate Desa
      if (selectedVillageId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih Desa terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. Validate Posyandu
      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih Posyandu terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 3. Form Validation (Inspect / Positive house counts and KK texts)
      if (!formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan lengkapi semua kolom yang wajib diisi!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 4. Validate KK Entries
      for (int i = 0; i < houseEntries.value.length; i++) {
        final entry = houseEntries.value[i];
        
        // Status Pemeriksaan must be chosen
        if (entry.selectedResult == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silakan pilih Status Pemeriksaan pada DATA KK POSITIF #${i + 1}!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Validate Nama KK (Required for both Ada Jentik and Nihil)
        if (entry.kkNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silakan isi Nama KK pada DATA KK POSITIF #${i + 1}!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        // Validate RT (Required for both Ada Jentik and Nihil)
        if (entry.rtController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silakan isi RT pada DATA KK POSITIF #${i + 1}!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        // Validate RW (Required for both Ada Jentik and Nihil)
        if (entry.rwController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silakan isi RW pada DATA KK POSITIF #${i + 1}!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (entry.selectedResult == 'Ada Jentik') {
          // Validate Tempat Positif Jentik
          final activePlaces = entry.selectedPlaceIds.where((id) => id != null).toList();
          if (activePlaces.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Silakan pilih minimal satu Tempat Positif Jentik pada DATA KK POSITIF #${i + 1}!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          if (entry.selectedPlaceIds.any((id) => id == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ada Tempat Positif Jentik yang belum dipilih pada DATA KK POSITIF #${i + 1}!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          // Validate Jumlah Tempat Positif
          final countText = entry.positivePlacesCountController.text.trim();
          if (countText.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Silakan isi Jumlah Tempat Positif pada DATA KK POSITIF #${i + 1}!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          final countVal = int.tryParse(countText);
          if (countVal == null || countVal <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Jumlah Tempat Positif pada DATA KK POSITIF #${i + 1} harus lebih dari 0!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      }

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          notesBuffer.writeln('--- KK ${i + 1} ---');
          notesBuffer.writeln('Nama KK: ${entry.kkNameController.text.trim()}');
          notesBuffer.writeln('RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}');
          notesBuffer.writeln('Hasil: ${entry.selectedResult ?? "-"}');
          
          final isNihil = entry.selectedResult == 'Nihil';
          final places = isNihil ? <String>[] : entry.selectedPlaceIds.where((id) => id != null).cast<String>().toList();
          
          // Map IDs to Names for display in notes
          final breedingPlaces = breedingPlacesAsync.value ?? [];
          final placeNames = places.map((id) {
            final found = breedingPlaces.firstWhere(
              (p) => p['id'] == id,
              orElse: () => {'name': id},
            );
            return found['name'] as String;
          }).toList();

          notesBuffer.writeln('Tempat: ${isNihil || placeNames.isEmpty ? "-" : placeNames.join(", ")}');
          notesBuffer.writeln('Jumlah: ${isNihil ? "-" : entry.positivePlacesCountController.text.trim()}');
          notesBuffer.writeln('');

          allBreedingPlaceIds.addAll(places);
        }

        if (isEdit) {
          await ref.read(reportRepositoryProvider).updateReport(
            reportId: initialReport!.id,
            housesInspected: int.tryParse(housesInspectedController.text) ?? 0,
            housesPositive: int.tryParse(housesPositiveController.text) ?? 0,
            breedingPlaceIds: allBreedingPlaceIds,
            notes: notesBuffer.toString(),
          );
        } else {
          await ref.read(reportRepositoryProvider).submitReport(
            posyanduId: selectedPosyanduId.value!,
            housesInspected: int.tryParse(housesInspectedController.text) ?? 0,
            housesPositive: int.tryParse(housesPositiveController.text) ?? 0,
            breedingPlaceIds: allBreedingPlaceIds,
            notes: notesBuffer.toString(),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdit ? 'Laporan berhasil diperbarui dan dikirim ulang untuk verifikasi!' : 'Laporan berhasil dikirim dan tersimpan di database!')),
          );
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(pendingVerificationCountProvider);
          ref.invalidate(interventionCountProvider);
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
      backgroundColor: const Color(0xFFD4E6F1), // Light blue background like sky
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Same as before)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F618D), Color(0xFF2980B9)], // Dark to mid blue
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const [
                        TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF82E0AA))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const NotificationBadge(),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'logout') {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1F618D), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Breadcrumbs (Same as before)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Text('Beranda', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 12)),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: Colors.blueGrey),
                  Text(isEdit ? 'Edit Laporan PSN' : 'Entri Laporan PSN', style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // Main Form Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isEdit && initialReport != null)
                      Consumer(
                        builder: (context, ref, child) {
                          final interventionsAsync = ref.watch(interventionsByReportProvider(initialReport!.id));
                          
                          return interventionsAsync.when(
                            data: (items) {
                              if (items.isEmpty || initialReport?.status != 'need_intervention') {
                                return const SizedBox.shrink();
                              }
                              final latest = items.first; 
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red[200]!, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'INSTRUKSI PERBAIKAN ADMIN',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w900, 
                                            color: Colors.red[900],
                                            letterSpacing: 1.2,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      latest['description'] ?? '-',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15, 
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Oleh: Admin Puskesmas',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: LinearProgressIndicator(),
                            ),
                            error: (err, _) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Gagal memuat instruksi: $err',
                                style: TextStyle(color: Colors.red[900], fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          isEdit ? 'EDIT LAPORAN PSN' : 'ENTRI LAPORAN PSN',
                          style: GoogleFonts.outfit(color: const Color(0xFF154360), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Global Fields
                        _buildLabel(iconWidget: const Icon(Icons.location_on, size: 16, color: Colors.blue), label: 'Nama Desa', isRequired: true),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          key: ValueKey('village_form_${selectedVillageId.value}'),
                          value: selectedVillageId.value,
                          hint: villagesAsync.maybeWhen(loading: () => 'Memuat desa...', orElse: () => 'Pilih Desa'),
                          onChanged: villagesAsync.isLoading ? null : (val) {
                            selectedVillageId.value = val;
                            selectedPosyanduId.value = null;
                          },
                          items: villagesAsync.maybeWhen(
                            data: (villages) {
                              const gumelarVillages = [
                                'cilangkap',
                                'cihonje',
                                'paningkaban',
                                'karangkemojing',
                                'gancang',
                                'kedungurang',
                                'gumelar',
                                'tlaga',
                                'samudra',
                                'samudra kulon',
                              ];
                              final gumelarOnly = villages
                                  .where((v) => gumelarVillages.contains(v.name.trim().toLowerCase()))
                                  .toList();
                              final sorted = List<Village>.from(gumelarOnly)
                                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                              return sorted.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name, style: GoogleFonts.outfit(fontSize: 12)))).toList();
                            },
                            orElse: () => [],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(iconWidget: Image.asset('assets/images/icon_posyandu.png', width: 16, height: 16), label: 'Nama Posyandu', isRequired: true),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          key: ValueKey('posyandu_form_${selectedVillageId.value}_${selectedPosyanduId.value}'),
                          value: selectedPosyanduId.value,
                          hint: posyandusAsync.maybeWhen(loading: () => 'Memuat posyandu...', orElse: () => 'Pilih Posyandu'),
                          onChanged: (posyandusAsync.isLoading || selectedVillageId.value == null) ? null : (val) => selectedPosyanduId.value = val,
                          items: posyandusAsync.maybeWhen(
                            data: (posyandus) {
                              final sorted = List<Posyandu>.from(posyandus)
                                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                              return sorted.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: GoogleFonts.outfit(fontSize: 12)))).toList();
                            },
                            orElse: () => [],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(iconWidget: const Icon(Icons.calendar_today, size: 16, color: Colors.blue), label: 'Tanggal Laporan', isRequired: true),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: reportDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) reportDate.value = date;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 12),
                                Text(DateFormat('dd MMMM yyyy').format(reportDate.value)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF154360),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Jumlah Rumah Diperiksa'),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildNumericInput(
                                    housesInspectedController,
                                    hintText: '-',
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF154360),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Jumlah Rumah Positif Jentik'),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildNumericInput(
                                    housesPositiveController,
                                    hintText: '-',
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40, thickness: 1, color: Color(0xFFD4E6F1)),

                        // House Entries
                        ...houseEntries.value.asMap().entries.map((e) {
                          final idx = e.key;
                          final entry = e.value;
                          final isAdaJentik = entry.selectedResult == 'Ada Jentik';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('DATA KK POSITIF #${idx + 1}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F618D))),
                                  if (houseEntries.value.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        final newList = List<HouseReportEntry>.from(houseEntries.value);
                                        newList.removeAt(idx);
                                        entry.dispose();
                                        houseEntries.value = newList;
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLabel(
                                iconWidget: Image.asset('assets/images/icon_mosquito.png', width: 18, height: 18),
                                label: 'Status Pemeriksaan',
                                isRequired: true,
                              ),
                              const SizedBox(height: 8),
                              _buildDropdown(
                                key: ValueKey('status_entry_$idx'),
                                value: entry.selectedResult,
                                hint: 'Pilih Status',
                                onChanged: (val) {
                                  entry.selectedResult = val;
                                  if (val == 'Nihil') {
                                    entry.selectedPlaceIds = [null];
                                    entry.positivePlacesCountController.text = '0';
                                  } else {
                                    entry.positivePlacesCountController.clear();
                                  }
                                  houseEntries.value = [...houseEntries.value]; // Trigger rebuild
                                },
                                items: ['Ada Jentik', 'Nihil'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 12)))).toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(
                                iconWidget: const Icon(Icons.assignment, size: 16, color: Colors.teal),
                                label: 'Nama KK & RT/RW',
                                isRequired: true,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildTextInput(
                                      entry.kkNameController,
                                      'Nama *',
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildSmallLabel('RT', isRequired: true),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 45,
                                    child: _buildSmallTextInput(
                                      entry.rtController,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return '';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSmallLabel('RW', isRequired: true),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 45,
                                    child: _buildSmallTextInput(
                                      entry.rwController,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return '';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              Builder(
                                builder: (context) {
                                  final bool isNihil = entry.selectedResult == 'Nihil';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Multiple Breeding Places
                                      _buildLabel(
                                        iconWidget: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                        label: 'Tempat Positif Jentik',
                                        isRequired: isAdaJentik,
                                      ),
                                      const SizedBox(height: 8),
                                      if (isNihil)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('-', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        ...entry.selectedPlaceIds.asMap().entries.map((pIdxEntry) {
                                          final pIdx = pIdxEntry.key;
                                          final pValue = pIdxEntry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildDropdown(
                                                    value: pValue,
                                                    hint: breedingPlacesAsync.maybeWhen(loading: () => 'Memuat tempat...', orElse: () => 'Pilih Tempat'),
                                                    onChanged: (val) {
                                                      entry.selectedPlaceIds[pIdx] = val;
                                                      houseEntries.value = [...houseEntries.value];
                                                    },
                                                    items: breedingPlacesAsync.maybeWhen(
                                                      data: (places) => places.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String, style: GoogleFonts.outfit(fontSize: 12)))).toList(),
                                                      orElse: () => [],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (entry.selectedPlaceIds.length > 1)
                                                  InkWell(
                                                    onTap: () {
                                                      entry.selectedPlaceIds.removeAt(pIdx);
                                                      houseEntries.value = [...houseEntries.value];
                                                    },
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
                                                  ),
                                                if (pIdx == entry.selectedPlaceIds.length - 1)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: InkWell(
                                                      onTap: () {
                                                        entry.selectedPlaceIds.add(null);
                                                        houseEntries.value = [...houseEntries.value];
                                                      },
                                                      borderRadius: BorderRadius.circular(20),
                                                      child: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      const SizedBox(height: 16),
                                      _buildLabel(
                                        iconWidget: const Icon(Icons.settings, size: 16, color: Colors.teal),
                                        label: 'Jumlah Tempat Positif',
                                        isRequired: isAdaJentik,
                                      ),
                                      const SizedBox(height: 8),
                                      if (isNihil)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('-', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        SizedBox(
                                          width: double.infinity,
                                          child: _buildNumericInput(
                                            entry.positivePlacesCountController,
                                            hintText: '-',
                                            validator: (val) {
                                              if (isAdaJentik) {
                                                if (val == null || val.trim().isEmpty) {
                                                  return 'Wajib diisi';
                                                }
                                                final numVal = int.tryParse(val);
                                                if (numVal == null || numVal <= 0) {
                                                  return 'Harus > 0';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              if (idx == houseEntries.value.length - 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () {
                                      houseEntries.value = [...houseEntries.value, HouseReportEntry()];
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset('assets/images/icon_kk.png', width: 40, height: 40),
                                          const SizedBox(height: 8),
                                          Text('Tambah data', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
                                          Text('Kartu Keluarga', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              const Divider(height: 32),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading.value ? null : handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEdit ? const Color(0xFF2980B9) : const Color(0xFF27AE60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isLoading.value
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(isEdit ? 'SIMPAN PERUBAHAN' : 'KIRIM LAPORAN', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildSmallLabel(String text, {bool isRequired = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
          children: [
            TextSpan(text: text),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel({
    required Widget iconWidget,
    required String label,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF154360),
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTextInput(TextEditingController controller, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      validator: validator,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
        errorStyle: const TextStyle(height: 0), // hide validation text under tiny box
      ),
    );
  }

   Widget _buildDropdown({
    Key? key,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 350,
          borderRadius: BorderRadius.circular(12),
          icon: isDisabled && hint.contains('Memuat')
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumericInput(
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}

