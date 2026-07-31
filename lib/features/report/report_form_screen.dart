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
import '../../shared/widgets/user_profile_menu.dart';

class HouseReportEntry {
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  List<String?> selectedPlaceIds = [null];
  final TextEditingController positivePlacesCountController =
      TextEditingController();
  bool? isPositive;

  HouseReportEntry({this.isPositive});

  String? get selectedPlaceId =>
      selectedPlaceIds.isNotEmpty ? selectedPlaceIds.first : null;
  set selectedPlaceId(String? val) {
    if (selectedPlaceIds.isEmpty) {
      selectedPlaceIds = [val];
    } else {
      selectedPlaceIds[0] = val;
    }
  }

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

  const ResponsiveRow({
    super.key,
    required this.isDesktop,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      List<Widget> rowChildren = [];
      for (int i = 0; i < children.length; i++) {
        rowChildren.add(Expanded(child: children[i]));
        if (i < children.length - 1) rowChildren.add(const SizedBox(width: 16));
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      );
    } else {
      List<Widget> colChildren = [];
      for (int i = 0; i < children.length; i++) {
        colChildren.add(children[i]);
        if (i < children.length - 1) {
          colChildren.add(const SizedBox(height: 16));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: colChildren,
      );
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
    final tableScrollController = useScrollController();

    // Watch Master Data & Profile
    final userProfileAsync = ref.watch(userProfileProvider);
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
        housesInspectedController.text = initialReport!.housesInspected
            .toString();
        housesPositiveController.text = initialReport!.housesPositive
            .toString();

        if (initialReport!.housesPositive > 0) {
          globalResult.value = 'Ada Jentik (Positif)';
        } else {
          globalResult.value = 'Nihil';
        }

        ref
            .read(masterRepositoryProvider)
            .getVillageIdByPosyandu(initialReport!.posyanduId)
            .then((vId) {
              if (vId != null) {
                selectedVillageId.value = vId;
              }
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
                      final p = places.firstWhere(
                        (element) => element['name'] == placeName,
                      );
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
      } else {
        if (houseEntries.value.isEmpty) {
          houseEntries.value = [HouseReportEntry()];
        }
      }

      return () {
        for (var entry in houseEntries.value) {
          entry.dispose();
        }
      };
    }, [initialReport, userProfileAsync.value]);



    Future<void> handleSubmit() async {
      if (selectedVillageId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih Desa terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih Posyandu terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan lengkapi semua kolom yang wajib diisi!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final expectedInspected =
          int.tryParse(housesInspectedController.text) ?? 0;
      final expectedPositive = int.tryParse(housesPositiveController.text) ?? 0;

      if (expectedPositive > expectedInspected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Jumlah Rumah Positif tidak boleh lebih besar dari Jumlah Rumah Diperiksa!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (globalResult.value == 'Ada Jentik (Positif)') {
        if (expectedPositive == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hasil PSN Ada Jentik, tapi Jumlah Rumah Positif 0!',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        if (houseEntries.value.length != expectedPositive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Total Data Rumah yang diinput (${houseEntries.value.length}) harus sama dengan Jumlah Rumah Positif ($expectedPositive)!',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          if (entry.kkNameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Silakan isi Nama KK pada baris #${i + 1}!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          final validPlaceIds = entry.selectedPlaceIds
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();
          if (validPlaceIds.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Silakan pilih Tempat Positif Jentik pada baris #${i + 1}!',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      } else {
        if (expectedPositive > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hasil PSN Nihil, tapi Jumlah Rumah Positif lebih dari 0!',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
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
            notesBuffer.writeln(
              'Nama KK: ${entry.kkNameController.text.trim()}',
            );
            notesBuffer.writeln(
              'RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}',
            );
            notesBuffer.writeln('Hasil: Ada Jentik');

            final breedingPlaces = breedingPlacesAsync.value ?? [];
            List<String> placeNames = [];
            for (var pId in entry.selectedPlaceIds) {
              if (pId != null && pId.isNotEmpty) {
                allBreedingPlaceIds.add(pId);
                final found = breedingPlaces.firstWhere(
                  (p) => p['id'] == pId,
                  orElse: () => {'name': '-'},
                );
                placeNames.add(found['name'] as String);
              }
            }

            notesBuffer.writeln(
              'Tempat: ${placeNames.isEmpty ? '-' : placeNames.join(', ')}',
            );
            notesBuffer.writeln(
              'Jumlah: ${entry.positivePlacesCountController.text.trim()}',
            );
            notesBuffer.writeln('');
          }
        } else {
          notesBuffer.writeln('Hasil Pemeriksaan: Nihil');
        }

        if (isEdit) {
          await ref
              .read(reportRepositoryProvider)
              .updateReport(
                reportId: initialReport!.id,
                housesInspected: expectedInspected,
                housesPositive: expectedPositive,
                breedingPlaceIds: allBreedingPlaceIds,
                reportDate: reportDate.value,
                notes: notesBuffer.toString(),
              );
        } else {
          await ref
              .read(reportRepositoryProvider)
              .submitReport(
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
            SnackBar(
              content: Text(
                isEdit
                    ? 'Laporan berhasil diperbarui!'
                    : 'Laporan berhasil dikirim!',
              ),
            ),
          );
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(pendingVerificationCountProvider);
          ref.invalidate(interventionCountProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal mengirim laporan: $e')));
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSaveDraft() async {
      if (selectedVillageId.value == null || selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silakan pilih Desa dan Posyandu terlebih dahulu untuk menyimpan draft!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final expectedInspected =
          int.tryParse(housesInspectedController.text) ?? 0;
      final expectedPositive = int.tryParse(housesPositiveController.text) ?? 0;

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        if (globalResult.value == 'Ada Jentik (Positif)') {
          for (int i = 0; i < houseEntries.value.length; i++) {
            final entry = houseEntries.value[i];
            notesBuffer.writeln('--- KK ${i + 1} ---');
            notesBuffer.writeln(
              'Nama KK: ${entry.kkNameController.text.trim()}',
            );
            notesBuffer.writeln(
              'RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}',
            );
            notesBuffer.writeln('Hasil: Ada Jentik');

            final breedingPlaces = breedingPlacesAsync.value ?? [];
            String placeName = '-';
            if (entry.selectedPlaceId != null) {
              final found = breedingPlaces.firstWhere(
                (p) => p['id'] == entry.selectedPlaceId,
                orElse: () => {'name': '-'},
              );
              placeName = found['name'] as String;
              allBreedingPlaceIds.add(entry.selectedPlaceId!);
            }

            notesBuffer.writeln('Tempat: $placeName');
            notesBuffer.writeln(
              'Jumlah: ${entry.positivePlacesCountController.text.trim()}',
            );
            notesBuffer.writeln('');
          }
        } else {
          notesBuffer.writeln('Hasil Pemeriksaan: Nihil');
        }

        if (isEdit) {
          await ref
              .read(reportRepositoryProvider)
              .updateReport(
                reportId: initialReport!.id,
                housesInspected: expectedInspected,
                housesPositive: expectedPositive,
                breedingPlaceIds: allBreedingPlaceIds,
                reportDate: reportDate.value,
                notes: notesBuffer.toString(),
                status: 'draft',
              );
        } else {
          await ref
              .read(reportRepositoryProvider)
              .submitReport(
                posyanduId: selectedPosyanduId.value!,
                housesInspected: expectedInspected,
                housesPositive: expectedPositive,
                breedingPlaceIds: allBreedingPlaceIds,
                reportDate: reportDate.value,
                notes: notesBuffer.toString(),
                status: 'draft',
              );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan berhasil disimpan sebagai Draft!'),
              backgroundColor: Color(0xFF2980B9),
            ),
          );
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan draft: $e')));
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/psn_logo_new.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) =>
                          const Icon(Icons.bug_report, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (screenWidth >
                      400) // Hide text on very small screens to avoid overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'SI KADER ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'PSN',
                                  style: TextStyle(color: Color(0xFF68B744)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Entri Laporan PSN',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  const NotificationBadge(),
                  const SizedBox(width: 12),
                  const UserProfileMenu(),
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
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF10365F),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ENTRI LAPORAN PSN',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF10365F),
                                    fontSize: isDesktop ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Catat hasil kegiatan Pemberantasan Sarang Nyamuk (PSN)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey[600],
                                    fontSize: isDesktop ? 14 : 12,
                                  ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    isLoading: villagesAsync.isLoading,
                                    items: villagesAsync.maybeWhen(
                                      data: (villages) {
                                        return villages
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v.id,
                                                child: Text(v.name),
                                              ),
                                            )
                                            .toList();
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
                                    hint: selectedVillageId.value == null
                                        ? 'Pilih Desa Terlebih Dahulu'
                                        : 'Pilih Posyandu',
                                    isLoading: posyandusAsync.isLoading,
                                    items: posyandusAsync.maybeWhen(
                                      data: (posyandus) {
                                        return posyandus
                                            .map(
                                              (p) => DropdownMenuItem(
                                                value: p.id,
                                                child: Text(p.name),
                                              ),
                                            )
                                            .toList();
                                      },
                                      orElse: () => [],
                                    ),
                                    onChanged: (val) =>
                                        selectedPosyanduId.value = val,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                              'id_ID',
                                            ).format(reportDate.value),
                                          ),
                                          Icon(
                                            Icons.calendar_month,
                                            color: Colors.grey[600],
                                            size: 18,
                                          ),
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
                                  child: _buildTextInput(
                                    housesInspectedController,
                                    '-',
                                    isNumber: true,
                                  ),
                                ),
                                _buildInputGroup(
                                  label: 'Jumlah Rumah Positif Jentik',
                                  icon: Icons.add_box,
                                  iconColor: Colors.green,
                                  child: _buildTextInput(
                                    housesPositiveController,
                                    '-',
                                    isNumber: true,
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),



                      // Table Section
                        if (isDesktop)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.list_alt,
                                      color: Color(0xFF10365F),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'DAFTAR RUMAH YANG DIPERIKSA',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF10365F),
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Isikan data rumah yang diperiksa',
                                            style: GoogleFonts.outfit(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  houseEntries.value = [
                                    ...houseEntries.value,
                                    HouseReportEntry(),
                                  ];
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  'Tambah KK Baru',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: const Color(0xFF27AE60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
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
                                  const Icon(
                                    Icons.list_alt,
                                    color: Color(0xFF10365F),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DAFTAR RUMAH YANG DIPERIKSA',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10365F),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Isikan data rumah yang diperiksa',
                                          style: GoogleFonts.outfit(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
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
                                    houseEntries.value = [
                                      ...houseEntries.value,
                                      HouseReportEntry(),
                                    ];
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Tambah KK Baru',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    backgroundColor: const Color(0xFF27AE60),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Table Data inside Horizontal Scrollbar
                        if (!isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.swipe_left,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Geser tabel ke samping ➔',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: RawScrollbar(
                            controller: tableScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: 8.0,
                            radius: const Radius.circular(4),
                            thumbColor: const Color(0xFF27AE60),
                            trackColor: const Color(0xFFE8F5E9),
                            padding: const EdgeInsets.only(bottom: 2),
                            child: SingleChildScrollView(
                              controller: tableScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: (screenWidth - (isDesktop ? 48 : 32)) < 800
                                    ? 800
                                    : (screenWidth - (isDesktop ? 48 : 32)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                  // Table Header
                                  Container(
                                    color: const Color(0xFFE8F5E9),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Center(
                                              child: Text(
                                                'No.',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'Nama KK',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text(
                                                'RT',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text(
                                                'RW',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6.0),
                                                  child: Text(
                                                    'Jentik',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: const Color(0xFF10365F),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Positif',
                                                        textAlign: TextAlign.center,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF10365F),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'Nihil',
                                                        textAlign: TextAlign.center,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF10365F),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                              ],
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'Tempat Positif Jentik',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                'Jumlah Tempat Positif',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC8E6C9)),
                                          SizedBox(
                                            width: 60,
                                            child: Center(
                                              child: Text(
                                                'Aksi',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(0xFF10365F),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Table Rows
                                  ...houseEntries.value.asMap().entries.map((
                                    e,
                                  ) {
                                    final idx = e.key;
                                    final entry = e.value;
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey[200]!,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Padding(
                                               padding: const EdgeInsets.only(top: 8),
                                               child: Text(
                                              '${idx + 1}',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                              ),
                                           ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: TextFormField(
                                                controller:
                                                    entry.kkNameController,
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  prefixIconConstraints: const BoxConstraints(
                                                    minWidth: 30,
                                                    minHeight: 38,
                                                    maxHeight: 38,
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: TextFormField(
                                                controller: entry.rtController,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: TextFormField(
                                                controller: entry.rwController,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Kolom Jentik (Positif / Nihil)
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Expanded(
                                                    child: Center(
                                                      child: InkWell(
                                                        onTap: () {
                                                          entry.isPositive = (entry.isPositive == true) ? null : true;
                                                          houseEntries.value = [...houseEntries.value];
                                                        },
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: BoxDecoration(
                                                            color: entry.isPositive == true ? const Color(0xFFEBF5FF) : Colors.white,
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: entry.isPositive == true ? const Color(0xFF2980B9) : Colors.grey[300]!,
                                                              width: entry.isPositive == true ? 1.5 : 1,
                                                            ),
                                                          ),
                                                          child: entry.isPositive == true
                                                              ? const Icon(
                                                                  Icons.check,
                                                                  size: 18,
                                                                  color: Color(0xFF2980B9),
                                                                )
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Center(
                                                      child: InkWell(
                                                        onTap: () {
                                                          entry.isPositive = (entry.isPositive == false) ? null : false;
                                                          houseEntries.value = [...houseEntries.value];
                                                        },
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: BoxDecoration(
                                                            color: entry.isPositive == false ? const Color(0xFFEBF5FF) : Colors.white,
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: entry.isPositive == false ? const Color(0xFF2980B9) : Colors.grey[300]!,
                                                              width: entry.isPositive == false ? 1.5 : 1,
                                                            ),
                                                          ),
                                                          child: entry.isPositive == false
                                                              ? const Icon(
                                                                  Icons.check,
                                                                  size: 18,
                                                                  color: Color(0xFF2980B9),
                                                                )
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: entry.isPositive == true
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ...entry.selectedPlaceIds
                                                            .asMap()
                                                            .entries
                                                            .map((pEntry) {
                                                          final pIdx = pEntry.key;
                                                          final pValue = pEntry.value;
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                              bottom: 4.0,
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: _buildDropdown(
                                                                    value: pValue,
                                                                    hint: 'Pilih Tempat',
                                                                    items: breedingPlacesAsync
                                                                        .maybeWhen(
                                                                          data: (places) => places
                                                                              .map(
                                                                                (p) => DropdownMenuItem(
                                                                                  value: p['id'] as String,
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                                                    child: Text(
                                                                                      p['name'] as String,
                                                                                      style: GoogleFonts.outfit(fontSize: 12),
                                                                                      softWrap: true,
                                                                                      maxLines: 3,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                          orElse: () => [],
                                                                        ),
                                                                    onChanged: (val) {
                                                                      entry.selectedPlaceIds[pIdx] = val;
                                                                      houseEntries.value = [
                                                                        ...houseEntries.value,
                                                                      ];
                                                                    },
                                                                    isDense: true,
                                                                  ),
                                                                ),
                                                                if (entry.selectedPlaceIds.length > 1) ...[
                                                                  const SizedBox(width: 4),
                                                                  Tooltip(
                                                                    message: 'Hapus Tempat Ini',
                                                                    child: InkWell(
                                                                      onTap: () {
                                                                        entry.selectedPlaceIds.removeAt(pIdx);
                                                                        houseEntries.value = [
                                                                          ...houseEntries.value,
                                                                        ];
                                                                      },
                                                                      borderRadius: BorderRadius.circular(6),
                                                                      child: Container(
                                                                        padding: const EdgeInsets.all(6),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.red[100],
                                                                          borderRadius: BorderRadius.circular(6),
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons.remove,
                                                                          color: Colors.red,
                                                                          size: 16,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                        InkWell(
                                                          onTap: () {
                                                            entry.selectedPlaceIds.add(null);
                                                            houseEntries.value = [
                                                              ...houseEntries.value,
                                                            ];
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.only(top: 2.0),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.add_circle_outline,
                                                                  size: 14,
                                                                  color: Color(0xFF27AE60),
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'Tambah pilihan tempat',
                                                                  style: GoogleFonts.outfit(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: const Color(0xFF27AE60),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: entry.isPositive == true
                                                  ? TextFormField(
                                                      controller: entry
                                                          .positivePlacesCountController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign: TextAlign.center,
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: Colors.grey[300]!,
                                                          ),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              borderSide: BorderSide(
                                                                color:
                                                                    Colors.grey[300]!,
                                                              ),
                                                            ),
                                                        isDense: true,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 60,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () {
                                                  if (houseEntries
                                                          .value
                                                          .length >
                                                      1) {
                                                    final newList =
                                                        List<
                                                          HouseReportEntry
                                                        >.from(
                                                          houseEntries.value,
                                                        );
                                                    newList.removeAt(idx);
                                                    entry.dispose();
                                                    houseEntries.value =
                                                        newList;
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[400],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ],
                              ),
                             ),
                           ),
                         ),
                       ),
                      const SizedBox(height: 40),

                      // Bottom Actions
                      ResponsiveRow(
                        isDesktop: isDesktop,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isLoading.value ? null : handleSaveDraft,
                            icon: const Icon(
                              Icons.save,
                              color: Color(0xFF2980B9),
                            ),
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SIMPAN DRAFT',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2980B9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Simpan sementara laporan',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2980B9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              side: const BorderSide(color: Color(0xFF2980B9)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                    Text(
                                      'KIRIM LAPORAN',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Kirim laporan ke admin puskesmas',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: const Color(0xFF27AE60),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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

  Widget _buildInputGroup({
    required String label,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF10365F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Wajib diisi';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
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
    bool isLoading = false,
  }) {
    if (isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDense ? 8 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Memuat data...',
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: isDense ? 12 : 13,
              ),
            ),
          ],
        ),
      );
    }

    final safeValue = (items.any((item) => item.value == value)) ? value : null;

    return Container(
      height: isDense ? 38 : null,
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? 8 : 12,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          itemHeight: null,
          menuMaxHeight: 400,
          hint: Text(
            hint,
            style: GoogleFonts.outfit(
              color: Colors.grey[500],
              fontSize: isDense ? 12 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          isDense: isDense,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey,
            size: isDense ? 16 : 24,
          ),
          items: items,
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}
