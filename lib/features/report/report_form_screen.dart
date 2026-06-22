import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';

class HouseReportEntry {
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  String? selectedPlaceId;
  final TextEditingController positivePlacesCountController = TextEditingController();

  HouseReportEntry();

  void dispose() {
    kkNameController.dispose();
    rtController.dispose();
    rwController.dispose();
    positivePlacesCountController.dispose();
  }
}

class ResponsiveRow extends StatelessWidget {
  final bool isDesktop;
  final List<Widget> children;
  
  const ResponsiveRow({super.key, required this.isDesktop, required this.children});

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      List<Widget> rowChildren = [];
      for (int i = 0; i < children.length; i++) {
        rowChildren.add(Expanded(child: children[i]));
        if (i < children.length - 1) rowChildren.add(const SizedBox(width: 16));
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren);
    } else {
      List<Widget> colChildren = [];
      for (int i = 0; i < children.length; i++) {
        colChildren.add(children[i]);
        if (i < children.length - 1) colChildren.add(const SizedBox(height: 16));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: colChildren);
    }
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
    final globalResult = useState<String?>('Ada Jentik (Positif)');
    final isLoading = useState(false);

    // Watch Master Data
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : const AsyncValue.data(<Posyandu>[]);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Initialize data
    useEffect(() {
      if (initialReport != null) {
        housesInspectedController.text = initialReport!.housesInspected.toString();
        housesPositiveController.text = initialReport!.housesPositive.toString();
        
        if (initialReport!.housesPositive > 0) {
          globalResult.value = 'Ada Jentik (Positif)';
        } else {
          globalResult.value = 'Nihil';
        }

        ref.read(masterRepositoryProvider).getVillageIdByPosyandu(initialReport!.posyanduId).then((vId) {
          selectedVillageId.value = vId;
        });

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
              } else if (t.startsWith('Jumlah: ')) {
                entry.positivePlacesCountController.text = t.substring(8);
              } else if (t.startsWith('Tempat: ')) {
                // Try to find place ID by name
                final placeName = t.substring(8);
                if (placeName != '-') {
                  breedingPlacesAsync.whenData((places) {
                    try {
                      final p = places.firstWhere((element) => element['name'] == placeName);
                      entry.selectedPlaceId = p['id'] as String;
                    } catch (_) {}
                  });
                }
              }
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

    Future<void> handleSubmit() async {
      if (selectedVillageId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih Desa terlebih dahulu!'), backgroundColor: Colors.orange));
        return;
      }

      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih Posyandu terlebih dahulu!'), backgroundColor: Colors.orange));
        return;
      }

      if (!formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan lengkapi semua kolom yang wajib diisi!'), backgroundColor: Colors.redAccent));
        return;
      }

      final expectedInspected = int.tryParse(housesInspectedController.text) ?? 0;
      final expectedPositive = int.tryParse(housesPositiveController.text) ?? 0;
      
      if (expectedPositive > expectedInspected) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah Rumah Positif tidak boleh lebih besar dari Jumlah Rumah Diperiksa!'), backgroundColor: Colors.redAccent));
        return;
      }

      if (globalResult.value == 'Ada Jentik (Positif)') {
        if (expectedPositive == 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hasil PSN Ada Jentik, tapi Jumlah Rumah Positif 0!'), backgroundColor: Colors.redAccent));
          return;
        }
        if (houseEntries.value.length != expectedPositive) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Total Data Rumah yang diinput (${houseEntries.value.length}) harus sama dengan Jumlah Rumah Positif ($expectedPositive)!'), backgroundColor: Colors.redAccent));
          return;
        }

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          if (entry.kkNameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan isi Nama KK pada baris #${i + 1}!'), backgroundColor: Colors.orange));
            return;
          }
          if (entry.selectedPlaceId == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan pilih Tempat Positif Jentik pada baris #${i + 1}!'), backgroundColor: Colors.orange));
            return;
          }
        }
      } else {
        if (expectedPositive > 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hasil PSN Nihil, tapi Jumlah Rumah Positif lebih dari 0!'), backgroundColor: Colors.redAccent));
          return;
        }
      }

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        if (globalResult.value == 'Ada Jentik (Positif)') {
          for (int i = 0; i < houseEntries.value.length; i++) {
            final entry = houseEntries.value[i];
            notesBuffer.writeln('--- KK ${i + 1} ---');
            notesBuffer.writeln('Nama KK: ${entry.kkNameController.text.trim()}');
            notesBuffer.writeln('RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}');
            notesBuffer.writeln('Hasil: Ada Jentik');
            
            final breedingPlaces = breedingPlacesAsync.value ?? [];
            String placeName = '-';
            if (entry.selectedPlaceId != null) {
              final found = breedingPlaces.firstWhere((p) => p['id'] == entry.selectedPlaceId, orElse: () => {'name': '-'});
              placeName = found['name'] as String;
              allBreedingPlaceIds.add(entry.selectedPlaceId!);
            }

            notesBuffer.writeln('Tempat: $placeName');
            notesBuffer.writeln('Jumlah: ${entry.positivePlacesCountController.text.trim()}');
            notesBuffer.writeln('');
          }
        } else {
            notesBuffer.writeln('Hasil Pemeriksaan: Nihil');
        }

        if (isEdit) {
          await ref.read(reportRepositoryProvider).updateReport(
            reportId: initialReport!.id,
            housesInspected: expectedInspected,
            housesPositive: expectedPositive,
            breedingPlaceIds: allBreedingPlaceIds,
            reportDate: reportDate.value,
            notes: notesBuffer.toString(),
          );
        } else {
          await ref.read(reportRepositoryProvider).submitReport(
            posyanduId: selectedPosyanduId.value!,
            housesInspected: expectedInspected,
            housesPositive: expectedPositive,
            breedingPlaceIds: allBreedingPlaceIds,
            reportDate: reportDate.value,
            notes: notesBuffer.toString(),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdit ? 'Laporan berhasil diperbarui!' : 'Laporan berhasil dikirim!')),
          );
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(pendingVerificationCountProvider);
          ref.invalidate(interventionCountProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim laporan: $e')));
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF10365F), // Match image blue header exactly
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Colors.white),
                  const SizedBox(width: 16),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover, errorBuilder: (ctx, err, trace) => const Icon(Icons.bug_report, color: Colors.blue)),
                  ),
                  const SizedBox(width: 12),
                  if (screenWidth > 400) // Hide text on very small screens to avoid overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              children: const [
                                TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                                TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF68B744))),
                              ],
                            ),
                          ),
                          Text('Entri Laporan PSN', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  const NotificationBadge(),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF68B744),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      if (screenWidth > 600) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Siti Kader', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Kader PSN', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF10365F), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ENTRI LAPORAN PSN',
                                  style: GoogleFonts.outfit(color: const Color(0xFF10365F), fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Catat hasil kegiatan Pemberantasan Sarang Nyamuk (PSN)',
                                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: isDesktop ? 14 : 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Top Card Form
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            ResponsiveRow(
                              isDesktop: isDesktop,
                              children: [
                                _buildInputGroup(
                                  label: 'Nama Desa',
                                  icon: Icons.location_on,
                                  child: _buildDropdown(
                                    value: selectedVillageId.value,
                                    hint: 'Pilih Desa',
                                    items: villagesAsync.maybeWhen(
                                      data: (villages) {
                                        return villages.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList();
                                      },
                                      orElse: () => [],
                                    ),
                                    onChanged: (val) {
                                      selectedVillageId.value = val;
                                      selectedPosyanduId.value = null;
                                    },
                                  ),
                                ),
                                _buildInputGroup(
                                  label: 'Nama Posyandu',
                                  icon: Icons.people,
                                  child: _buildDropdown(
                                    value: selectedPosyanduId.value,
                                    hint: 'Pilih Posyandu',
                                    items: posyandusAsync.maybeWhen(
                                      data: (posyandus) {
                                        return posyandus.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList();
                                      },
                                      orElse: () => [],
                                    ),
                                    onChanged: (val) => selectedPosyanduId.value = val,
                                  ),
                                ),
                                _buildInputGroup(
                                  label: 'Tanggal Laporan',
                                  icon: Icons.calendar_today,
                                  child: InkWell(
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(DateFormat('dd MMM yyyy', 'id_ID').format(reportDate.value)),
                                          Icon(Icons.calendar_month, color: Colors.grey[600], size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ResponsiveRow(
                              isDesktop: isDesktop,
                              children: [
                                _buildInputGroup(
                                  label: 'Jumlah Rumah Diperiksa',
                                  icon: Icons.home,
                                  child: _buildTextInput(housesInspectedController, '-', isNumber: true),
                                ),
                                _buildInputGroup(
                                  label: 'Jumlah Rumah Positif Jentik',
                                  icon: Icons.add_box,
                                  iconColor: Colors.green,
                                  child: _buildTextInput(housesPositiveController, '-', isNumber: true),
                                ),
                                _buildInputGroup(
                                  label: 'Hasil PSN (Pemberantasan Sarang Nyamuk)',
                                  icon: Icons.bug_report,
                                  iconColor: Colors.green,
                                  child: _buildDropdown(
                                    value: globalResult.value,
                                    hint: 'Pilih Hasil',
                                    items: const [
                                      DropdownMenuItem(value: 'Ada Jentik (Positif)', child: Text('Ada Jentik (Positif)')),
                                      DropdownMenuItem(value: 'Nihil', child: Text('Nihil')),
                                    ],
                                    onChanged: (val) => globalResult.value = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Copy Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy, color: Color(0xFF2980B9)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Copy Laporan Bulan Lalu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2980B9), fontSize: 14)),
                                  Text('Salin data KK positif jentik dari laporan bulan sebelumnya', style: GoogleFonts.outfit(color: const Color(0xFF2980B9), fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF2980B9)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Table Section
                      if (globalResult.value == 'Ada Jentik (Positif)') ...[
                        if (isDesktop)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.list_alt, color: Color(0xFF10365F)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('DAFTAR RUMAH POSITIF JENTIK', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10365F), fontSize: 16)),
                                          Text('Isikan data rumah yang ditemukan positif jentik', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  houseEntries.value = [...houseEntries.value, HouseReportEntry()];
                                },
                                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                label: Text('Tambah KK Baru', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: const Color(0xFF27AE60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.list_alt, color: Color(0xFF10365F)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('DAFTAR RUMAH POSITIF JENTIK', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10365F), fontSize: 16)),
                                        Text('Isikan data rumah yang ditemukan positif jentik', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    houseEntries.value = [...houseEntries.value, HouseReportEntry()];
                                  },
                                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                  label: Text('Tambah KK Baru', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    backgroundColor: const Color(0xFF27AE60),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        
                        // Table Data inside Horizontal Scroll
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: (screenWidth - (isDesktop ? 48 : 32)) < 800 ? 800 : (screenWidth - (isDesktop ? 48 : 32)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Table Header
                                  Container(
                                    color: const Color(0xFFE8F5E9),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 40, child: Text('No.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        Expanded(flex: 3, child: Text('Nama KK', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        Expanded(flex: 1, child: Text('RT', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        Expanded(flex: 1, child: Text('RW', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        Expanded(flex: 3, child: Text('Tempat Positif Jentik', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        Expanded(flex: 2, child: Text('Jumlah Tempat Positif', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                        SizedBox(width: 60, child: Text('Aksi', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10365F)))),
                                      ],
                                    ),
                                  ),
                                  // Table Rows
                                  ...houseEntries.value.asMap().entries.map((e) {
                                    final idx = e.key;
                                    final entry = e.value;
                                    return Container(
                                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 40, child: Text('${idx + 1}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: TextFormField(
                                                controller: entry.kkNameController,
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(Icons.person, size: 18, color: Colors.blue),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: TextFormField(
                                                controller: entry.rtController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: TextFormField(
                                                controller: entry.rwController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: _buildDropdown(
                                                value: entry.selectedPlaceId,
                                                hint: 'Pilih Tempat',
                                                items: breedingPlacesAsync.maybeWhen(
                                                  data: (places) => places.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                                                  orElse: () => [],
                                                ),
                                                onChanged: (val) {
                                                  entry.selectedPlaceId = val;
                                                  houseEntries.value = [...houseEntries.value];
                                                },
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: TextFormField(
                                                controller: entry.positivePlacesCountController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 60,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () {
                                                  if (houseEntries.value.length > 1) {
                                                    final newList = List<HouseReportEntry>.from(houseEntries.value);
                                                    newList.removeAt(idx);
                                                    entry.dispose();
                                                    houseEntries.value = newList;
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(8)),
                                                  child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Bottom Actions
                      ResponsiveRow(
                        isDesktop: isDesktop,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.save, color: Color(0xFF2980B9)),
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SIMPAN DRAFT', style: GoogleFonts.outfit(color: const Color(0xFF2980B9), fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Simpan sementara laporan', style: GoogleFonts.outfit(color: const Color(0xFF2980B9), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              side: const BorderSide(color: Color(0xFF2980B9)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: const Color(0xFFF0F7FF),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoading.value ? null : handleSubmit,
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('KIRIM LAPORAN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Kirim laporan ke admin puskesmas', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: const Color(0xFF27AE60),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup({required String label, required IconData icon, Color? iconColor, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10365F)), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Wajib diisi';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    bool isDense = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDense ? 8 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: isDense ? 12 : 13), overflow: TextOverflow.ellipsis),
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: isDense ? 16 : 24),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
