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
  bool isEditing = false;

  HouseReportEntry({this.isPositive, this.isEditing = false});

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
    final activeReportId = useState<String?>(initialReport?.id);
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(initialReport?.posyanduId);
    final reportDate = useState(initialReport?.reportDate ?? DateTime.now());
    final globalResult = useState<String?>('Ada Jentik (Positif)');
    final isLoading = useState(false);
    final tableScrollController = useScrollController();
    final tempKkNameController = useTextEditingController();
    final tempRtRwController = useTextEditingController();
    final tempHasilPemeriksaan = useState<String?>(null);
    final tempSelectedPlaceIds = useState<List<String?>>([null]);
    final tempPositiveCountController = useTextEditingController();

    final myReportsAsync = ref.watch(myReportsProvider);
    final allReportsAsync = ref.watch(allReportsProvider);
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    // Watch Master Data & Profile
    final userProfileAsync = ref.watch(userProfileProvider);
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : const AsyncValue.data(<Posyandu>[]);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    final selectedVillageName = villagesAsync.maybeWhen(
      data: (villages) {
        if (selectedVillageId.value == null) return null;
        final found = villages.firstWhere(
          (v) => v.id == selectedVillageId.value,
          orElse: () => Village(id: '', name: ''),
        );
        return found.name.isNotEmpty ? found.name : null;
      },
      orElse: () => null,
    );

    final puskesmasName = 'Puskesmas Gumelar';

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final filteredEntries = houseEntries.value.where((entry) {
      if (searchQuery.value.trim().isEmpty) return true;
      final q = searchQuery.value.toLowerCase().trim();
      final name = entry.kkNameController.text.toLowerCase();
      final rt = entry.rtController.text.toLowerCase();
      final rw = entry.rwController.text.toLowerCase();
      final status = entry.isPositive == true
          ? 'positif ada jentik'
          : (entry.isPositive == false ? 'nihil bebas jentik' : '');
      return name.contains(q) ||
          rt.contains(q) ||
          rw.contains(q) ||
          status.contains(q);
    }).toList();

    // Initialize data when explicit initialReport is passed
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
              } else if (t.startsWith('Hasil: ')) {
                final res = t.substring(7);
                if (res.contains('Ada Jentik') || res.contains('Positif')) {
                  entry.isPositive = true;
                } else if (res.contains('Nihil')) {
                  entry.isPositive = false;
                }
              } else if (t.startsWith('Jumlah: ')) {
                entry.positivePlacesCountController.text = t.substring(8);
              } else if (t.startsWith('Tempat: ')) {
                final placeName = t.substring(8);
                if (placeName != '-') {
                  final names = placeName
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  breedingPlacesAsync.whenData((places) {
                    final matched = <String?>[];
                    for (var nm in names) {
                      try {
                        final p = places.firstWhere(
                          (element) => element['name'] == nm,
                        );
                        matched.add(p['id'] as String);
                      } catch (_) {}
                    }
                    if (matched.isNotEmpty) entry.selectedPlaceIds = matched;
                  });
                }
              }
            }
            if (entry.isPositive == null) {
              if (entry.positivePlacesCountController.text.isNotEmpty ||
                  entry.selectedPlaceIds.any((id) => id != null)) {
                entry.isPositive = true;
              }
            }
            parsed.add(entry);
          }
          if (parsed.isNotEmpty) houseEntries.value = parsed;
        }
      }

      return () {
        for (var entry in houseEntries.value) {
          entry.dispose();
        }
      };
    }, [initialReport, userProfileAsync.value]);

    // Auto-populate houseEntries by default with previous submitted KK entries or default samples
    useEffect(() {
      if (initialReport != null) return null;
      if (houseEntries.value.isEmpty) {
        final myReports = myReportsAsync.value ?? <Report>[];
        final allReports = allReportsAsync.value ?? <Report>[];
        final combined = <Report>[...myReports, ...allReports];
        final parsed = _parseHouseEntriesFromReports(combined);
        if (parsed.isNotEmpty) {
          houseEntries.value = parsed;
        } else {
          houseEntries.value = _getDefaultInitialHouseEntries();
        }
      }
      return null;
    }, [myReportsAsync.value, allReportsAsync.value, initialReport]);

    // Automatically load existing report data from Supabase when Posyandu is selected
    useEffect(() {
      if (initialReport != null) return null;

      final pId = selectedPosyanduId.value;
      if (pId == null || pId.isEmpty) {
        activeReportId.value = null;
        if (houseEntries.value.isEmpty) {
          final combined = <Report>[
            ...(myReportsAsync.value ?? <Report>[]),
            ...(allReportsAsync.value ?? <Report>[]),
          ];
          final parsed = _parseHouseEntriesFromReports(combined);
          houseEntries.value = parsed.isNotEmpty
              ? parsed
              : _getDefaultInitialHouseEntries();
        }
        return null;
      }

      ref.read(reportRepositoryProvider).getLatestReportByPosyandu(pId).then((
        latestReport,
      ) {
        if (latestReport != null) {
          activeReportId.value = latestReport.id;
          if (latestReport.notes != null && latestReport.notes!.isNotEmpty) {
            final parsed = <HouseReportEntry>[];
            final blocks = latestReport.notes!.split('--- KK');
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
                    entry.rtController.text = parts[0].trim();
                    entry.rwController.text = parts[1].trim();
                  }
                } else if (t.startsWith('Hasil: ')) {
                  final res = t.substring(7);
                  if (res.contains('Ada Jentik') || res.contains('Positif')) {
                    entry.isPositive = true;
                  } else if (res.contains('Nihil')) {
                    entry.isPositive = false;
                  }
                } else if (t.startsWith('Jumlah: ')) {
                  entry.positivePlacesCountController.text = t.substring(8);
                } else if (t.startsWith('Tempat: ')) {
                  final placeName = t.substring(8);
                  if (placeName != '-') {
                    final names = placeName
                        .split(',')
                        .map((e) => e.trim())
                        .toList();
                    breedingPlacesAsync.whenData((places) {
                      final matched = <String?>[];
                      for (var nm in names) {
                        try {
                          final p = places.firstWhere(
                            (element) => element['name'] == nm,
                          );
                          matched.add(p['id'] as String);
                        } catch (_) {}
                      }
                      if (matched.isNotEmpty) entry.selectedPlaceIds = matched;
                    });
                  }
                }
              }
              if (entry.isPositive == null) {
                if (entry.positivePlacesCountController.text.isNotEmpty ||
                    entry.selectedPlaceIds.any((id) => id != null)) {
                  entry.isPositive = true;
                }
              }
              parsed.add(entry);
            }
            houseEntries.value = parsed;
          }
        } else {
          activeReportId.value = null;
          if (houseEntries.value.isEmpty) {
            final combined = <Report>[
              ...(myReportsAsync.value ?? <Report>[]),
              ...(allReportsAsync.value ?? <Report>[]),
            ];
            final parsed = _parseHouseEntriesFromReports(combined);
            houseEntries.value = parsed.isNotEmpty
                ? parsed
                : _getDefaultInitialHouseEntries();
          }
        }
      });

      return null;
    }, [selectedPosyanduId.value]);

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

      // Automatically add top form fields if user filled them without pressing "Entri Laporan"
      if (tempKkNameController.text.trim().isNotEmpty ||
          tempHasilPemeriksaan.value != null) {
        final newEntry = HouseReportEntry(
          isPositive: tempHasilPemeriksaan.value == 'Ada Jentik (Positif)'
              ? true
              : (tempHasilPemeriksaan.value == 'Nihil' ? false : null),
          isEditing: false,
        );
        if (tempKkNameController.text.trim().isNotEmpty) {
          newEntry.kkNameController.text = tempKkNameController.text.trim();
        }
        if (tempRtRwController.text.trim().isNotEmpty &&
            tempRtRwController.text.trim() != '- / -') {
          final parts = tempRtRwController.text.trim().split('/');
          if (parts.isNotEmpty) newEntry.rtController.text = parts[0].trim();
          if (parts.length >= 2) newEntry.rwController.text = parts[1].trim();
        }
        if (tempHasilPemeriksaan.value == 'Ada Jentik (Positif)') {
          final validPlaces = tempSelectedPlaceIds.value
              .whereType<String>()
              .toList();
          if (validPlaces.isNotEmpty) {
            newEntry.selectedPlaceIds = validPlaces;
          }
          if (tempPositiveCountController.text.trim().isNotEmpty) {
            newEntry.positivePlacesCountController.text =
                tempPositiveCountController.text.trim();
          }
        }
        houseEntries.value = [...houseEntries.value, newEntry];

        tempKkNameController.clear();
        tempRtRwController.clear();
        tempHasilPemeriksaan.value = null;
        tempSelectedPlaceIds.value = [null];
        tempPositiveCountController.clear();
      }

      if (houseEntries.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silakan isi dan tambahkan data rumah yang diperiksa terlebih dahulu!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        int housesInspected = houseEntries.value.length;
        int housesPositive = 0;

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          final isPos = entry.isPositive == true;
          if (isPos) housesPositive++;

          notesBuffer.writeln('--- KK ${i + 1} ---');
          notesBuffer.writeln('Nama KK: ${entry.kkNameController.text.trim()}');
          notesBuffer.writeln(
            'RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}',
          );
          notesBuffer.writeln('Hasil: ${isPos ? "Ada Jentik" : "Nihil"}');

          if (isPos) {
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
          } else {
            notesBuffer.writeln('Tempat: -');
            notesBuffer.writeln('Jumlah: 0');
          }
          notesBuffer.writeln('');
        }

        final targetReportId = activeReportId.value ?? initialReport?.id;
        final isEditMode = targetReportId != null;

        if (isEditMode) {
          await ref
              .read(reportRepositoryProvider)
              .updateReport(
                reportId: targetReportId,
                housesInspected: housesInspected,
                housesPositive: housesPositive,
                breedingPlaceIds: allBreedingPlaceIds,
                reportDate: reportDate.value,
                notes: notesBuffer.toString(),
              );
        } else {
          await ref
              .read(reportRepositoryProvider)
              .submitReport(
                posyanduId: selectedPosyanduId.value!,
                housesInspected: housesInspected,
                housesPositive: housesPositive,
                breedingPlaceIds: allBreedingPlaceIds,
                reportDate: reportDate.value,
                notes: notesBuffer.toString(),
              );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Laporan berhasil diperbarui!'
                    : 'Laporan berhasil disimpan!',
              ),
              backgroundColor: const Color(0xFF27AE60),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan laporan: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
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

      if (tempKkNameController.text.trim().isNotEmpty ||
          tempHasilPemeriksaan.value != null) {
        final newEntry = HouseReportEntry(
          isPositive: tempHasilPemeriksaan.value == 'Ada Jentik (Positif)'
              ? true
              : (tempHasilPemeriksaan.value == 'Nihil' ? false : null),
          isEditing: false,
        );
        if (tempKkNameController.text.trim().isNotEmpty) {
          newEntry.kkNameController.text = tempKkNameController.text.trim();
        }
        if (tempRtRwController.text.trim().isNotEmpty &&
            tempRtRwController.text.trim() != '- / -') {
          final parts = tempRtRwController.text.trim().split('/');
          if (parts.isNotEmpty) newEntry.rtController.text = parts[0].trim();
          if (parts.length >= 2) newEntry.rwController.text = parts[1].trim();
        }
        if (tempHasilPemeriksaan.value == 'Ada Jentik (Positif)') {
          final validPlaces = tempSelectedPlaceIds.value
              .whereType<String>()
              .toList();
          if (validPlaces.isNotEmpty) {
            newEntry.selectedPlaceIds = validPlaces;
          }
          if (tempPositiveCountController.text.trim().isNotEmpty) {
            newEntry.positivePlacesCountController.text =
                tempPositiveCountController.text.trim();
          }
        }
        houseEntries.value = [...houseEntries.value, newEntry];

        tempKkNameController.clear();
        tempRtRwController.clear();
        tempHasilPemeriksaan.value = null;
        tempSelectedPlaceIds.value = [null];
        tempPositiveCountController.clear();
      }

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        int housesInspected = houseEntries.value.length;
        int housesPositive = 0;

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          final isPos = entry.isPositive == true;
          if (isPos) housesPositive++;

          notesBuffer.writeln('--- KK ${i + 1} ---');
          notesBuffer.writeln('Nama KK: ${entry.kkNameController.text.trim()}');
          notesBuffer.writeln(
            'RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}',
          );
          notesBuffer.writeln('Hasil: ${isPos ? "Ada Jentik" : "Nihil"}');

          if (isPos) {
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
          } else {
            notesBuffer.writeln('Tempat: -');
            notesBuffer.writeln('Jumlah: 0');
          }
          notesBuffer.writeln('');
        }

        final targetReportId = activeReportId.value ?? initialReport?.id;
        final isEditMode = targetReportId != null;

        if (isEditMode) {
          await ref
              .read(reportRepositoryProvider)
              .updateReport(
                reportId: targetReportId,
                housesInspected: housesInspected,
                housesPositive: housesPositive,
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
                housesInspected: housesInspected,
                housesPositive: housesPositive,
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
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            // Row 1: NAMA, RT/RW, Hasil Pemeriksaan (Checkboxes default null)
                            isDesktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _buildInputGroup(
                                          label: 'NAMA',
                                          icon: Icons.person,
                                          child: TextFormField(
                                            controller: tempKkNameController,
                                            decoration: InputDecoration(
                                              hintText: 'Masukkan Nama KK',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: _buildInputGroup(
                                          label: 'RT/RW',
                                          icon: Icons.home,
                                          child: TextFormField(
                                            controller: tempRtRwController,
                                            decoration: InputDecoration(
                                              hintText: '- / -',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.checklist,
                                                  size: 16,
                                                  color: Colors.blueGrey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Hasil Pemeriksaan',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF10365F,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    tempHasilPemeriksaan.value =
                                                        'Ada Jentik (Positif)';
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value:
                                                            tempHasilPemeriksaan
                                                                .value ==
                                                            'Ada Jentik (Positif)',
                                                        onChanged: (val) {
                                                          if (val == true) {
                                                            tempHasilPemeriksaan
                                                                    .value =
                                                                'Ada Jentik (Positif)';
                                                          } else {
                                                            tempHasilPemeriksaan
                                                                    .value =
                                                                null;
                                                          }
                                                        },
                                                        activeColor:
                                                            const Color(
                                                              0xFF27AE60,
                                                            ),
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'Positif',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                InkWell(
                                                  onTap: () {
                                                    tempHasilPemeriksaan.value =
                                                        'Nihil';
                                                    tempSelectedPlaceIds.value =
                                                        [null];
                                                    tempPositiveCountController
                                                        .clear();
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value:
                                                            tempHasilPemeriksaan
                                                                .value ==
                                                            'Nihil',
                                                        onChanged: (val) {
                                                          if (val == true) {
                                                            tempHasilPemeriksaan
                                                                    .value =
                                                                'Nihil';
                                                            tempSelectedPlaceIds
                                                                .value = [
                                                              null,
                                                            ];
                                                            tempPositiveCountController
                                                                .clear();
                                                          } else {
                                                            tempHasilPemeriksaan
                                                                    .value =
                                                                null;
                                                          }
                                                        },
                                                        activeColor:
                                                            const Color(
                                                              0xFF27AE60,
                                                            ),
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'Nihil',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildInputGroup(
                                        label: 'NAMA',
                                        icon: Icons.person,
                                        child: TextFormField(
                                          controller: tempKkNameController,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan Nama KK',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInputGroup(
                                        label: 'RT/RW',
                                        icon: Icons.home,
                                        child: TextFormField(
                                          controller: tempRtRwController,
                                          decoration: InputDecoration(
                                            hintText: '- / -',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.checklist,
                                                size: 16,
                                                color: Colors.blueGrey,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Hasil Pemeriksaan',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  tempHasilPemeriksaan.value =
                                                      'Ada Jentik (Positif)';
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value:
                                                          tempHasilPemeriksaan
                                                              .value ==
                                                          'Ada Jentik (Positif)',
                                                      onChanged: (val) {
                                                        if (val == true) {
                                                          tempHasilPemeriksaan
                                                                  .value =
                                                              'Ada Jentik (Positif)';
                                                        } else {
                                                          tempHasilPemeriksaan
                                                                  .value =
                                                              null;
                                                        }
                                                      },
                                                      activeColor: const Color(
                                                        0xFF27AE60,
                                                      ),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Positif',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              InkWell(
                                                onTap: () {
                                                  tempHasilPemeriksaan.value =
                                                      'Nihil';
                                                  tempSelectedPlaceIds.value = [
                                                    null,
                                                  ];
                                                  tempPositiveCountController
                                                      .clear();
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value:
                                                          tempHasilPemeriksaan
                                                              .value ==
                                                          'Nihil',
                                                      onChanged: (val) {
                                                        if (val == true) {
                                                          tempHasilPemeriksaan
                                                                  .value =
                                                              'Nihil';
                                                          tempSelectedPlaceIds
                                                              .value = [
                                                            null,
                                                          ];
                                                          tempPositiveCountController
                                                              .clear();
                                                        } else {
                                                          tempHasilPemeriksaan
                                                                  .value =
                                                              null;
                                                        }
                                                      },
                                                      activeColor: const Color(
                                                        0xFF27AE60,
                                                      ),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Nihil',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 16),
                            // Row 2: Tempat Positif Jentik (+ button) & Jumlah Tempat Positif (Enter subtext)
                            isDesktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.water_drop,
                                                  size: 16,
                                                  color: Colors.blueGrey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Tempat Positif Jentik',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF10365F,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () {
                                                    tempSelectedPlaceIds
                                                        .value = [
                                                      ...tempSelectedPlaceIds
                                                          .value,
                                                      null,
                                                    ];
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF27AE60,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            tempHasilPemeriksaan.value ==
                                                    'Ada Jentik (Positif)'
                                                ? Column(
                                                    children: List.generate(
                                                      tempSelectedPlaceIds
                                                          .value
                                                          .length,
                                                      (pIdx) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 8.0,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: _buildDropdown(
                                                                value: tempSelectedPlaceIds
                                                                    .value[pIdx],
                                                                hint:
                                                                    'Pilih Tempat Positif',
                                                                isLoading:
                                                                    breedingPlacesAsync
                                                                        .isLoading,
                                                                items: breedingPlacesAsync.maybeWhen(
                                                                  data: (places) => places
                                                                      .map(
                                                                        (
                                                                          p,
                                                                        ) => DropdownMenuItem(
                                                                          value:
                                                                              p['id']
                                                                                  as String,
                                                                          child: Text(
                                                                            p['name']
                                                                                as String,
                                                                          ),
                                                                        ),
                                                                      )
                                                                      .toList(),
                                                                  orElse: () =>
                                                                      [],
                                                                ),
                                                                onChanged: (val) {
                                                                  final newList =
                                                                      List<
                                                                        String?
                                                                      >.from(
                                                                        tempSelectedPlaceIds
                                                                            .value,
                                                                      );
                                                                  newList[pIdx] =
                                                                      val;
                                                                  tempSelectedPlaceIds
                                                                          .value =
                                                                      newList;
                                                                },
                                                              ),
                                                            ),
                                                            if (tempSelectedPlaceIds
                                                                    .value
                                                                    .length >
                                                                1) ...[
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              InkWell(
                                                                onTap: () {
                                                                  final newList =
                                                                      List<
                                                                        String?
                                                                      >.from(
                                                                        tempSelectedPlaceIds
                                                                            .value,
                                                                      );
                                                                  newList
                                                                      .removeAt(
                                                                        pIdx,
                                                                      );
                                                                  tempSelectedPlaceIds
                                                                          .value =
                                                                      newList;
                                                                },
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        6,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .red[50],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '-',
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.numbers,
                                                  size: 16,
                                                  color: Colors.blueGrey,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Jumlah Tempat Positif',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 12,
                                                              color:
                                                                  const Color(
                                                                    0xFF10365F,
                                                                  ),
                                                            ),
                                                      ),
                                                      Text(
                                                        '(DALAM SATU TEMPAT YANG DIPERIKSA)',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 9,
                                                              color: Colors
                                                                  .grey[600],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            tempHasilPemeriksaan.value ==
                                                    'Ada Jentik (Positif)'
                                                ? TextFormField(
                                                    controller:
                                                        tempPositiveCountController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      hintText: 'Jumlah tempat',
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .grey[300]!,
                                                                ),
                                                          ),
                                                      isDense: true,
                                                    ),
                                                  )
                                                : Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '-',
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.water_drop,
                                                size: 16,
                                                color: Colors.blueGrey,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Tempat Positif Jentik',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () {
                                                  tempSelectedPlaceIds.value = [
                                                    ...tempSelectedPlaceIds
                                                        .value,
                                                    null,
                                                  ];
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF27AE60,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          tempHasilPemeriksaan.value ==
                                                  'Ada Jentik (Positif)'
                                              ? Column(
                                                  children: List.generate(
                                                    tempSelectedPlaceIds
                                                        .value
                                                        .length,
                                                    (pIdx) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: _buildDropdown(
                                                              value: tempSelectedPlaceIds
                                                                  .value[pIdx],
                                                              hint:
                                                                  'Pilih Tempat Positif',
                                                              isLoading:
                                                                  breedingPlacesAsync
                                                                      .isLoading,
                                                              items: breedingPlacesAsync.maybeWhen(
                                                                data: (places) => places
                                                                    .map(
                                                                      (
                                                                        p,
                                                                      ) => DropdownMenuItem(
                                                                        value:
                                                                            p['id']
                                                                                as String,
                                                                        child: Text(
                                                                          p['name']
                                                                              as String,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                                orElse: () =>
                                                                    [],
                                                              ),
                                                              onChanged: (val) {
                                                                final newList =
                                                                    List<
                                                                      String?
                                                                    >.from(
                                                                      tempSelectedPlaceIds
                                                                          .value,
                                                                    );
                                                                newList[pIdx] =
                                                                    val;
                                                                tempSelectedPlaceIds
                                                                        .value =
                                                                    newList;
                                                              },
                                                            ),
                                                          ),
                                                          if (tempSelectedPlaceIds
                                                                  .value
                                                                  .length >
                                                              1) ...[
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                final newList =
                                                                    List<
                                                                      String?
                                                                    >.from(
                                                                      tempSelectedPlaceIds
                                                                          .value,
                                                                    );
                                                                newList
                                                                    .removeAt(
                                                                      pIdx,
                                                                    );
                                                                tempSelectedPlaceIds
                                                                        .value =
                                                                    newList;
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .red[50],
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                child: const Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 18,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '-',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.numbers,
                                                size: 16,
                                                color: Colors.blueGrey,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Jumlah Tempat Positif',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF10365F,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '(DALAM SATU TEMPAT YANG DIPERIKSA)',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 9,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          tempHasilPemeriksaan.value ==
                                                  'Ada Jentik (Positif)'
                                              ? TextFormField(
                                                  controller:
                                                      tempPositiveCountController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: 'Jumlah tempat',
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey[300]!,
                                                              ),
                                                        ),
                                                    isDense: true,
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '-',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final newEntry = HouseReportEntry(
                                    isPositive:
                                        tempHasilPemeriksaan.value ==
                                            'Ada Jentik (Positif)'
                                        ? true
                                        : (tempHasilPemeriksaan.value == 'Nihil'
                                              ? false
                                              : null),
                                    isEditing: false,
                                  );
                                  if (tempKkNameController.text
                                      .trim()
                                      .isNotEmpty) {
                                    newEntry.kkNameController.text =
                                        tempKkNameController.text.trim();
                                  }
                                  if (tempRtRwController.text
                                          .trim()
                                          .isNotEmpty &&
                                      tempRtRwController.text.trim() !=
                                          '- / -') {
                                    final parts = tempRtRwController.text
                                        .trim()
                                        .split('/');
                                    if (parts.isNotEmpty) {
                                      newEntry.rtController.text = parts[0]
                                          .trim();
                                    }
                                    if (parts.length >= 2) {
                                      newEntry.rwController.text = parts[1]
                                          .trim();
                                    }
                                  }
                                  if (tempHasilPemeriksaan.value ==
                                      'Ada Jentik (Positif)') {
                                    final validPlaces = tempSelectedPlaceIds
                                        .value
                                        .whereType<String>()
                                        .toList();
                                    if (validPlaces.isNotEmpty) {
                                      newEntry.selectedPlaceIds = validPlaces;
                                    }
                                    if (tempPositiveCountController.text
                                        .trim()
                                        .isNotEmpty) {
                                      newEntry
                                          .positivePlacesCountController
                                          .text = tempPositiveCountController
                                          .text
                                          .trim();
                                    }
                                  }

                                  houseEntries.value = [
                                    ...houseEntries.value,
                                    newEntry,
                                  ];

                                  tempKkNameController.clear();
                                  tempRtRwController.clear();
                                  tempHasilPemeriksaan.value = null;
                                  tempSelectedPlaceIds.value = [null];
                                  tempPositiveCountController.clear();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Laporan berhasil di-entri ke daftar',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  'Entri Laporan',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: isDesktop
                                      ? const Size(180, 48)
                                      : const Size(double.infinity, 48),
                                  backgroundColor: const Color(0xFF27AE60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Section Header
                      Row(
                        children: [
                          const Icon(Icons.list_alt, color: Color(0xFF10365F)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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

                      // Search Field for KK Entries
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (val) => searchQuery.value = val,
                          decoration: InputDecoration(
                            hintText: 'Cari nama KK, RT/RW, atau status...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF10365F),
                              size: 20,
                            ),
                            suffixIcon: searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      searchQuery.value = '';
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                          ),
                        ),
                      ),
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
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            controller: tableScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: (screenWidth - (isDesktop ? 48 : 32)) < 450
                                  ? 450
                                  : (screenWidth - (isDesktop ? 48 : 32)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Table Header
                                  Container(
                                    color: const Color(0xFFE8F5E9),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                'Tanggal Laporan',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'Nama KK',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'Desa/Puskesmas',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                'Status',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF10365F,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Table Rows
                                  ...filteredEntries.asMap().entries.map((e) {
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
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Center(
                                              child: Text(
                                                '${idx + 1}',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(reportDate.value),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          // Nama KK
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: InkWell(
                                                onTap: () {
                                                  _showKkDetailDialog(
                                                    context: context,
                                                    entry: entry,
                                                    idx: idx,
                                                    reportDate:
                                                        reportDate.value,
                                                    villageName:
                                                        selectedVillageName ??
                                                        '-',
                                                    puskesmasName:
                                                        puskesmasName,
                                                    breedingPlaces:
                                                        breedingPlacesAsync
                                                            .value ??
                                                        [],
                                                    onEdit: () {
                                                      _showKkEditDialog(
                                                        context: context,
                                                        entry: entry,
                                                        idx: idx,
                                                        breedingPlaces:
                                                            breedingPlacesAsync
                                                                .value ??
                                                            [],
                                                        onSaved: () {
                                                          houseEntries.value = [
                                                            ...houseEntries
                                                                .value,
                                                          ];
                                                        },
                                                      );
                                                    },
                                                    onDelete: () {
                                                      final newList =
                                                          List<
                                                            HouseReportEntry
                                                          >.from(
                                                            houseEntries.value,
                                                          );
                                                      houseEntries.value =
                                                          List<
                                                              HouseReportEntry
                                                            >.from(
                                                              houseEntries
                                                                  .value,
                                                            )
                                                            ..remove(entry);
                                                      entry.dispose();
                                                      houseEntries.value =
                                                          newList;
                                                    },
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 4,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          entry
                                                                  .kkNameController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? '-'
                                                              : entry
                                                                    .kkNameController
                                                                    .text
                                                                    .trim(),
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                              0xFF2980B9,
                                                            ),
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      const Icon(
                                                        Icons.info_outline,
                                                        size: 13,
                                                        color: Color(
                                                          0xFF2980B9,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          // Desa/Puskesmas Column
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    (selectedVillageName !=
                                                                null &&
                                                            selectedVillageName
                                                                .isNotEmpty)
                                                        ? selectedVillageName
                                                        : '-',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF10365F,
                                                      ),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    puskesmasName,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Color(0xFFC8E6C9),
                                          ),
                                          // Status Badge
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Center(
                                                child: entry.isPositive == true
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFFFEBEE,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFFFFCDD2,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Positif',
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
                                                                      0xFFD32F2F,
                                                                    ),
                                                              ),
                                                        ),
                                                      )
                                                    : entry.isPositive == false
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFE8F5E9,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFFC8E6C9,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Nihil',
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
                                                                      0xFF27AE60,
                                                                    ),
                                                              ),
                                                        ),
                                                      )
                                                    : Text(
                                                        '-',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[500],
                                                            ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Bottom Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading.value
                                  ? null
                                  : handleSaveDraft,
                              icon: const Icon(
                                Icons.save_outlined,
                                color: Color(0xFF2980B9),
                              ),
                              label: Text(
                                'SIMPAN DRAFT',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2980B9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                side: const BorderSide(
                                  color: Color(0xFF2980B9),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading.value ? null : handleSubmit,
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: Text(
                                initialReport != null
                                    ? 'UPDATE LAPORAN'
                                    : 'KIRIM LAPORAN',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: const Color(0xFF27AE60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
      padding: EdgeInsets.symmetric(horizontal: isDense ? 8 : 12),
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

  void _showKkDetailDialog({
    required BuildContext context,
    required HouseReportEntry entry,
    required int idx,
    required DateTime reportDate,
    String villageName = "-",
    String puskesmasName = "-",
    required List<Map<String, dynamic>> breedingPlaces,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detail KK',
      barrierColor: Colors.black.withValues(alpha: 0.54),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scaleAnim = Tween<double>(
          begin: 0.2,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
        final fadeAnim = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut));

        return ScaleTransition(
          scale: scaleAnim,
          child: FadeTransition(
            opacity: fadeAnim,
            child: _KkDetailDialogWidget(
              entry: entry,
              idx: idx,
              reportDate: reportDate,
              villageName: villageName,
              puskesmasName: puskesmasName,
              breedingPlaces: breedingPlaces,
              onEdit: () {
                Navigator.of(ctx).pop();
                onEdit();
              },
              onDelete: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
          ),
        );
      },
    );
  }
}

class _KkDetailDialogWidget extends StatelessWidget {
  final HouseReportEntry entry;
  final int idx;
  final DateTime reportDate;
  final String villageName;
  final String puskesmasName;
  final List<Map<String, dynamic>> breedingPlaces;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KkDetailDialogWidget({
    required this.entry,
    required this.idx,
    required this.reportDate,
    this.villageName = "-",
    this.puskesmasName = "-",
    required this.breedingPlaces,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final kkName = entry.kkNameController.text.trim().isEmpty
        ? '-'
        : entry.kkNameController.text.trim();
    final rt = entry.rtController.text.trim().isEmpty
        ? '-'
        : entry.rtController.text.trim();
    final rw = entry.rwController.text.trim().isEmpty
        ? '-'
        : entry.rwController.text.trim();

    List<String> placeNames = [];
    if (entry.isPositive == true) {
      for (var pId in entry.selectedPlaceIds) {
        if (pId != null && pId.isNotEmpty) {
          final found = breedingPlaces.firstWhere(
            (p) => p['id'] == pId,
            orElse: () => {'name': pId},
          );
          placeNames.add(found['name'] as String);
        }
      }
    }

    final positiveCount =
        entry.positivePlacesCountController.text.trim().isEmpty
        ? '-'
        : entry.positivePlacesCountController.text.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Color(0xFF27AE60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Rumah / KK',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      Text(
                        'Data lengkap entri ke-${idx + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Details List
            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'No - Nama KK',
              value: '#${idx + 1} - $kkName',
              isBold: true,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal Laporan',
              value: DateFormat('dd/MM/yyyy').format(reportDate),
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'RT / RW',
              value: 'RT $rt / RW $rw',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.holiday_village_outlined,
              label: 'Desa',
              value: villageName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.local_hospital_outlined,
              label: 'Puskesmas',
              value: puskesmasName,
            ),
            const SizedBox(height: 12),
            // Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  size: 18,
                  color: Color(0xFF10365F),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: Text(
                    'Status',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: entry.isPositive == true
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFCDD2),
                              ),
                            ),
                            child: Text(
                              'Ada Jentik (Positif)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        )
                      : entry.isPositive == false
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                              ),
                            ),
                            child: Text(
                              'Bebas Jentik (Nihil)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF27AE60),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          '-',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.place_outlined,
              label: 'Tempat Positif Jentik',
              value: placeNames.isEmpty ? '-' : placeNames.join(', '),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.format_list_numbered_outlined,
              label: 'Jumlah Tempat Positif',
              value: entry.isPositive == true
                  ? (positiveCount == '-' ? '-' : '$positiveCount wadah/tempat')
                  : '-',
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Actions (Aksi)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Edit Data',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2980B9),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10365F)),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF10365F),
            ),
          ),
        ),
      ],
    );
  }
}

void _showKkEditDialog({
  required BuildContext context,
  required HouseReportEntry entry,
  required int idx,
  required List<Map<String, dynamic>> breedingPlaces,
  required VoidCallback onSaved,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit Data KK',
    barrierColor: Colors.black.withValues(alpha: 0.54),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final scaleAnim = Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
      final fadeAnim = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut));

      return ScaleTransition(
        scale: scaleAnim,
        child: FadeTransition(
          opacity: fadeAnim,
          child: _KkEditDialogWidget(
            entry: entry,
            idx: idx,
            breedingPlaces: breedingPlaces,
            onSaved: onSaved,
          ),
        ),
      );
    },
  );
}

class _KkEditDialogWidget extends StatefulWidget {
  final HouseReportEntry entry;
  final int idx;
  final List<Map<String, dynamic>> breedingPlaces;
  final VoidCallback onSaved;

  const _KkEditDialogWidget({
    required this.entry,
    required this.idx,
    required this.breedingPlaces,
    required this.onSaved,
  });

  @override
  State<_KkEditDialogWidget> createState() => _KkEditDialogWidgetState();
}

class _KkEditDialogWidgetState extends State<_KkEditDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _positiveCountController;
  late bool? _isPositive;
  late List<String?> _selectedPlaceIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.entry.kkNameController.text,
    );
    _rtController = TextEditingController(text: widget.entry.rtController.text);
    _rwController = TextEditingController(text: widget.entry.rwController.text);
    _positiveCountController = TextEditingController(
      text: widget.entry.positivePlacesCountController.text,
    );
    _isPositive = widget.entry.isPositive;
    _selectedPlaceIds = widget.entry.selectedPlaceIds.isEmpty
        ? [null]
        : List<String?>.from(widget.entry.selectedPlaceIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _positiveCountController.dispose();
    super.dispose();
  }

  void _save() {
    widget.entry.kkNameController.text = _nameController.text.trim();
    widget.entry.rtController.text = _rtController.text.trim();
    widget.entry.rwController.text = _rwController.text.trim();
    widget.entry.isPositive = _isPositive;
    if (_isPositive == true) {
      widget.entry.selectedPlaceIds = _selectedPlaceIds
          .whereType<String>()
          .toList();
      widget.entry.positivePlacesCountController.text = _positiveCountController
          .text
          .trim();
    } else {
      widget.entry.selectedPlaceIds = [];
      widget.entry.positivePlacesCountController.clear();
    }

    Navigator.of(context).pop();
    widget.onSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data KK ke-${widget.idx + 1} berhasil diperbarui'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF27AE60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF2980B9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Edit Data KK',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      Text(
                        'Edit data entri ke-${widget.idx + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Form Inputs in SingleChildScrollView
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama KK
                    Text(
                      'Nama Kepala Keluarga (KK)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Nama KK',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // RT / RW side-by-side
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RT',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10365F),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _rtController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '00',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RW',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10365F),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _rwController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '00',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status Option (Positif / Nihil)
                    Text(
                      'Hasil Pemeriksaan Jentik',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPositive = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isPositive == true
                                    ? const Color(0xFFFFEBEE)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isPositive == true
                                      ? const Color(0xFFE53935)
                                      : Colors.grey[300]!,
                                  width: _isPositive == true ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Positif Jentik',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isPositive == true
                                        ? const Color(0xFFD32F2F)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPositive = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isPositive == false
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isPositive == false
                                      ? const Color(0xFF27AE60)
                                      : Colors.grey[300]!,
                                  width: _isPositive == false ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Bebas Jentik (Nihil)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isPositive == false
                                        ? const Color(0xFF27AE60)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Conditional Breeding Places section if _isPositive == true
                    if (_isPositive == true) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tempat Positif Jentik',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10365F),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPlaceIds.add(null);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF27AE60),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: List.generate(
                          _selectedPlaceIds.length,
                          (pIdx) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value:
                                            (widget.breedingPlaces.any(
                                              (item) =>
                                                  item['id'] ==
                                                  _selectedPlaceIds[pIdx],
                                            ))
                                            ? _selectedPlaceIds[pIdx]
                                            : null,
                                        isExpanded: true,
                                        isDense: true,
                                        hint: Text(
                                          'Pilih tempat jentik',
                                          style: GoogleFonts.outfit(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        items: widget.breedingPlaces
                                            .map(
                                              (place) =>
                                                  DropdownMenuItem<String>(
                                                    value:
                                                        place['id'] as String,
                                                    child: Text(
                                                      place['name'] as String,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedPlaceIds[pIdx] = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                if (_selectedPlaceIds.length > 1) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPlaceIds.removeAt(pIdx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Jumlah tempat positif
                      Text(
                        'Jumlah Tempat Positif',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _positiveCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Jumlah wadah/tempat',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Actions (Batal & Simpan)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<HouseReportEntry> _parseHouseEntriesFromReports(List<Report> reports) {
  final result = <HouseReportEntry>[];
  final seenNames = <String>{};

  for (var rep in reports) {
    if (rep.notes == null || rep.notes!.trim().isEmpty) continue;
    final blocks = rep.notes!.split('--- KK');
    for (var block in blocks) {
      if (block.trim().isEmpty) continue;
      final entry = HouseReportEntry();
      final lines = block.split('\n');
      for (var line in lines) {
        final t = line.trim();
        if (t.startsWith('Nama KK: ')) {
          entry.kkNameController.text = t.substring(9).trim();
        } else if (t.startsWith('RT/RW: ')) {
          final parts = t.substring(7).split('/');
          if (parts.length == 2) {
            entry.rtController.text = parts[0].trim();
            entry.rwController.text = parts[1].trim();
          }
        } else if (t.startsWith('Hasil: ')) {
          final res = t.substring(7);
          if (res.contains('Ada Jentik') || res.contains('Positif')) {
            entry.isPositive = true;
          } else if (res.contains('Nihil')) {
            entry.isPositive = false;
          }
        } else if (t.startsWith('Jumlah: ')) {
          entry.positivePlacesCountController.text = t.substring(8).trim();
        }
      }
      final name = entry.kkNameController.text.trim();
      if (name.isNotEmpty && !seenNames.contains(name.toLowerCase())) {
        seenNames.add(name.toLowerCase());
        result.add(entry);
      }
    }
  }
  return result;
}

List<HouseReportEntry> _getDefaultInitialHouseEntries() {
  final e1 = HouseReportEntry(isPositive: false);
  e1.kkNameController.text = 'Eko Setyo';
  e1.rtController.text = '09';
  e1.rwController.text = '03';

  final e2 = HouseReportEntry(isPositive: true);
  e2.kkNameController.text = 'Budi Santoso';
  e2.rtController.text = '02';
  e2.rwController.text = '01';
  e2.positivePlacesCountController.text = '1';

  final e3 = HouseReportEntry(isPositive: false);
  e3.kkNameController.text = 'Ahmad Dahlan';
  e3.rtController.text = '05';
  e3.rwController.text = '02';

  return [e1, e2, e3];
}
