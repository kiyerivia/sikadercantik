import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';

class HouseReportEntry {
  final TextEditingController nikController = TextEditingController();
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  final TextEditingController rtRwController = TextEditingController();
  List<String?> selectedPlaceIds = [null];
  final TextEditingController positivePlacesCountController =
      TextEditingController();
  bool? isPositive;
  bool isEditing = false;
  DateTime? reportDate;
  String? villageName;
  String? posyanduName;

  HouseReportEntry({
    this.isPositive,
    this.isEditing = false,
    this.reportDate,
    this.villageName,
    this.posyanduName,
  });

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
    nikController.dispose();
    kkNameController.dispose();
    rtController.dispose();
    rwController.dispose();
    rtRwController.dispose();
    positivePlacesCountController.dispose();
  }
}

class _HouseInputCard extends StatefulWidget {
  final int index;
  final int totalCount;
  final HouseReportEntry entry;
  final List<HouseReportEntry>? allEntries;
  final VoidCallback? onNikChanged;
  final bool isDesktop;
  final List<Map<String, dynamic>> breedingPlaces;
  final VoidCallback? onRemove;
  final Widget Function({
    required String label,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) buildInputGroup;
  final Widget Function({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required void Function(String?)? onChanged,
    bool isDense,
    bool isLoading,
    bool isEnabled,
  }) buildDropdown;

  const _HouseInputCard({
    super.key,
    required this.index,
    required this.totalCount,
    required this.entry,
    this.allEntries,
    this.onNikChanged,
    required this.isDesktop,
    required this.breedingPlaces,
    this.onRemove,
    required this.buildInputGroup,
    required this.buildDropdown,
  });

  @override
  State<_HouseInputCard> createState() => _HouseInputCardState();
}

class _HouseInputCardState extends State<_HouseInputCard> {
  String? _getDuplicateNikError() {
    final currentNik = widget.entry.nikController.text.trim();
    if (currentNik.isEmpty || widget.allEntries == null) return null;

    for (int i = 0; i < widget.allEntries!.length; i++) {
      if (i != widget.index) {
        final otherNik = widget.allEntries![i].nikController.text.trim();
        if (otherNik.isNotEmpty && otherNik == currentNik) {
          return 'NIK sama dengan Rumah #${i + 1}';
        }
      }
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDesktop = widget.isDesktop;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Rumah #N & Hapus button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 15, color: Color(0xFF27AE60)),
                    const SizedBox(width: 5),
                    Text(
                      'Rumah #${widget.index + 1}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onRemove != null)
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red[400]),
                        const SizedBox(width: 2),
                        Text(
                          'Hapus',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          const SizedBox(height: 12),

          // Row 1: NIK, NAMA KK, RT/RW, Hasil Pemeriksaan
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: widget.buildInputGroup(
                    label: 'NIK',
                    icon: Icons.badge_outlined,
                    child: Builder(
                      builder: (context) {
                        final duplicateError = _getDuplicateNikError();
                        return TextFormField(
                          controller: entry.nikController,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          onChanged: (_) {
                            setState(() {});
                            widget.onNikChanged?.call();
                          },
                          decoration: InputDecoration(
                            hintText: '16 digit NIK',
                            counterText: '',
                            errorText: duplicateError,
                            errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: duplicateError != null ? Colors.red : Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: duplicateError != null ? Colors.red : Colors.grey[300]!),
                            ),
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: widget.buildInputGroup(
                    label: 'NAMA',
                    icon: Icons.person,
                    child: TextFormField(
                      controller: entry.kkNameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan Nama KK',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: widget.buildInputGroup(
                    label: 'RT/RW',
                    icon: Icons.home,
                    child: TextFormField(
                      controller: entry.rtRwController,
                      decoration: InputDecoration(
                        hintText: '- / -',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildHasilPemeriksaan(),
                ),
              ],
            )
          else ...[
            widget.buildInputGroup(
              label: 'NIK',
              icon: Icons.badge_outlined,
              child: Builder(
                builder: (context) {
                  final duplicateError = _getDuplicateNikError();
                  return TextFormField(
                    controller: entry.nikController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    onChanged: (_) {
                      setState(() {});
                      widget.onNikChanged?.call();
                    },
                    decoration: InputDecoration(
                      hintText: '16 digit NIK',
                      counterText: '',
                      errorText: duplicateError,
                      errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: duplicateError != null ? Colors.red : Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: duplicateError != null ? Colors.red : Colors.grey[300]!),
                      ),
                      isDense: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            widget.buildInputGroup(
              label: 'NAMA',
              icon: Icons.person,
              child: TextFormField(
                controller: entry.kkNameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Nama KK',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ),
            ),
            const SizedBox(height: 12),
            widget.buildInputGroup(
              label: 'RT/RW',
              icon: Icons.home,
              child: TextFormField(
                controller: entry.rtRwController,
                decoration: InputDecoration(
                  hintText: '- / -',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ),
            ),
            const SizedBox(height: 12),
            _buildHasilPemeriksaan(),
          ],

          const SizedBox(height: 12),

          // Row 2: Tempat Positif Jentik & Jumlah Tempat Positif
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTempatJentikSection(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildJumlahTempatSection(),
                ),
              ],
            )
          else ...[
            _buildTempatJentikSection(),
            const SizedBox(height: 12),
            _buildJumlahTempatSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHasilPemeriksaan() {
    final entry = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              'Hasil Pemeriksaan',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10365F)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  entry.isPositive = (entry.isPositive == true) ? null : true;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: entry.isPositive == true,
                    onChanged: (val) {
                      setState(() {
                        entry.isPositive = (val == true) ? true : null;
                      });
                    },
                    activeColor: const Color(0xFF27AE60),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 2),
                  Text('Positif', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                setState(() {
                  if (entry.isPositive == false) {
                    entry.isPositive = null;
                  } else {
                    entry.isPositive = false;
                    entry.selectedPlaceIds = [null];
                    entry.positivePlacesCountController.clear();
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: entry.isPositive == false,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          entry.isPositive = false;
                          entry.selectedPlaceIds = [null];
                          entry.positivePlacesCountController.clear();
                        } else {
                          entry.isPositive = null;
                        }
                      });
                    },
                    activeColor: const Color(0xFF27AE60),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 2),
                  Text('Nihil', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTempatJentikSection() {
    final entry = widget.entry;
    final isPos = entry.isPositive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              'Tempat Positif Jentik',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10365F)),
            ),
            if (isPos) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    entry.selectedPlaceIds.add(null);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF27AE60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (isPos)
          Column(
            children: List.generate(
              entry.selectedPlaceIds.length,
              (pIdx) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.buildDropdown(
                        value: entry.selectedPlaceIds[pIdx],
                        hint: 'Pilih Tempat Perkembangbiakan',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Pilih Tempat Perkembangbiakan'),
                          ),
                          ...widget.breedingPlaces.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p['id'] as String,
                              child: Text(p['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            entry.selectedPlaceIds[pIdx] = val;
                          });
                        },
                      ),
                    ),
                    if (entry.selectedPlaceIds.length > 1) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                        onPressed: () {
                          setState(() {
                            entry.selectedPlaceIds.removeAt(pIdx);
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text('-', style: GoogleFonts.outfit(color: Colors.grey[500])),
          ),
      ],
    );
  }

  Widget _buildJumlahTempatSection() {
    final entry = widget.entry;
    final isPos = entry.isPositive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.numbers, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jumlah Tempat Positif',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10365F)),
                  ),
                  Text(
                    '(DALAM SATU TEMPAT YANG DIPERIKSA)',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isPos)
          TextFormField(
            controller: entry.positivePlacesCountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Jumlah tempat',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text('-', style: GoogleFonts.outfit(color: Colors.grey[500])),
          ),
      ],
    );
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
  final Report? copyFromReport;
  final bool isEditMode;

  const ReportFormScreen({
    super.key,
    this.initialReport,
    this.copyFromReport,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final housesInspectedController = useTextEditingController();
    final housesPositiveController = useTextEditingController();

    final houseEntries = useState<List<HouseReportEntry>>([]);
    final inputHouseEntries = useState<List<HouseReportEntry>>([HouseReportEntry()]);
    final activeReportId = useState<String?>(initialReport?.id);
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(initialReport?.posyanduId ?? copyFromReport?.posyanduId);
    final reportDate = useState(initialReport?.reportDate ?? DateTime.now());
    final globalResult = useState<String?>('Ada Jentik (Positif)');
    final isLoading = useState(false);
    final hasSavedDraft = useState(false);
    final draftInfo = useState<Map<String, dynamic>?>(null);
    final tableScrollController = useScrollController();

    final myReportsAsync = ref.watch(myReportsProvider);
    final allReportsAsync = ref.watch(allReportsProvider);
    final searchQuery = useState('');
    final searchController = useTextEditingController();
    final currentPage = useState(1);
    const int pageSize = 10;

    useEffect(() {
      currentPage.value = 1;
      return null;
    }, [searchQuery.value]);

    // Watch Master Data & Profile
    final userProfileAsync = ref.watch(userProfileProvider);
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : ref.watch(allPosyandusProvider);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    final selectedVillageName = villagesAsync.maybeWhen(
      data: (villages) {
        if (selectedVillageId.value != null && villages.isNotEmpty) {
          final found = villages.firstWhere(
            (v) => v.id == selectedVillageId.value,
            orElse: () => Village(id: '', name: ''),
          );
          if (found.name.isNotEmpty) return found.name;
        }
        return 'Semua Desa';
      },
      orElse: () => 'Semua Desa',
    );

    final selectedPosyanduName = posyandusAsync.maybeWhen(
      data: (posyandus) {
        if (selectedPosyanduId.value != null && posyandus.isNotEmpty) {
          final found = posyandus.firstWhere(
            (p) => p.id == selectedPosyanduId.value,
            orElse: () => Posyandu(id: '', rwId: '', name: ''),
          );
          if (found.name.isNotEmpty) return found.name;
        }
        return 'Semua Posyandu';
      },
      orElse: () => 'Semua Posyandu',
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final sortedEntries = List<HouseReportEntry>.from(houseEntries.value)
      ..sort((a, b) {
        final da = a.reportDate ?? DateTime(2000);
        final db = b.reportDate ?? DateTime(2000);
        return db.compareTo(da);
      });

    final seenFilteredNames = <String>{};
    final filteredEntries = <HouseReportEntry>[];

    for (var entry in sortedEntries) {
      final name = entry.kkNameController.text.trim().toLowerCase();
      if (name.isEmpty) continue;

      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.toLowerCase().trim();
        final rt = entry.rtController.text.toLowerCase();
        final rw = entry.rwController.text.toLowerCase();
        final status = entry.isPositive == true
            ? 'positif ada jentik'
            : (entry.isPositive == false ? 'nihil bebas jentik' : '');
        final vName = (entry.villageName ?? '').toLowerCase();
        final pName = (entry.posyanduName ?? '').toLowerCase();
        final dateStr = entry.reportDate != null
            ? DateFormat('dd MMM yyyy', 'id_ID')
                .format(entry.reportDate!)
                .toLowerCase()
            : '';
        final matches = name.contains(q) ||
            rt.contains(q) ||
            rw.contains(q) ||
            status.contains(q) ||
            vName.contains(q) ||
            pName.contains(q) ||
            dateStr.contains(q);
        if (!matches) continue;
      }

      if (seenFilteredNames.add(name)) {
        filteredEntries.add(entry);
      }
    }

    final totalItems = filteredEntries.length;
    final totalPages = totalItems > 0 ? (totalItems / pageSize).ceil() : 1;
    final safePage = currentPage.value.clamp(1, totalPages);
    final startIndex = (safePage - 1) * pageSize;
    final endIndex = (startIndex + pageSize < totalItems) ? startIndex + pageSize : totalItems;
    final pagedEntries = totalItems > 0 ? filteredEntries.sublist(startIndex, endIndex) : <HouseReportEntry>[];

    // Initialize data when explicit initialReport or copyFromReport is passed
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
            final entry = HouseReportEntry(
              reportDate: initialReport!.reportDate,
              villageName: initialReport!.villageName,
              posyanduName: initialReport!.posyanduName,
            );
            final lines = block.split('\n');
            for (var line in lines) {
              final t = line.trim();
              if (t.startsWith('NIK: ')) {
                entry.nikController.text = t.substring(5).trim();
              } else if (t.startsWith('Nama KK: ')) {
                entry.kkNameController.text = t.substring(9).trim();
              } else if (t.startsWith('RT/RW: ')) {
                final rtrw = t.substring(7).trim();
                entry.rtRwController.text = rtrw;
                final parts = rtrw.split('/');
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
              } else if (t.startsWith('Tempat: ')) {
                final placeName = t.substring(8).trim();
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
          if (parsed.isNotEmpty) {
            houseEntries.value = parsed;
            inputHouseEntries.value = parsed;
          }
        }
      } else if (copyFromReport != null) {
        // Copy Mode: copy houses from previous report, but reset inspection results for fresh new date entry
        reportDate.value = DateTime.now();
        selectedPosyanduId.value = copyFromReport!.posyanduId;

        ref
            .read(masterRepositoryProvider)
            .getVillageIdByPosyandu(copyFromReport!.posyanduId)
            .then((vId) {
              if (vId != null) {
                selectedVillageId.value = vId;
              }
            });

        if (copyFromReport!.notes != null) {
          final parsed = <HouseReportEntry>[];
          final blocks = copyFromReport!.notes!.split('--- KK');
          for (var block in blocks) {
            if (block.trim().isEmpty) continue;
            final entry = HouseReportEntry(
              reportDate: DateTime.now(),
              villageName: copyFromReport!.villageName,
              posyanduName: copyFromReport!.posyanduName,
            );
            final lines = block.split('\n');
            for (var line in lines) {
              final t = line.trim();
              if (t.startsWith('NIK: ')) {
                entry.nikController.text = t.substring(5).trim();
              } else if (t.startsWith('Nama KK: ')) {
                entry.kkNameController.text = t.substring(9).trim();
              } else if (t.startsWith('RT/RW: ')) {
                final rtrw = t.substring(7).trim();
                entry.rtRwController.text = rtrw;
                final parts = rtrw.split('/');
                if (parts.length == 2) {
                  entry.rtController.text = parts[0].trim();
                  entry.rwController.text = parts[1].trim();
                }
              }
            }
            // Fresh values for new date
            entry.isPositive = null;
            entry.selectedPlaceIds = [null];
            entry.positivePlacesCountController.text = '';
            parsed.add(entry);
          }
          if (parsed.isNotEmpty) {
            houseEntries.value = parsed;
            inputHouseEntries.value = parsed;
            housesInspectedController.text = parsed.length.toString();
          }
        }
      }

      return null;
    }, [initialReport, copyFromReport, userProfileAsync.value]);

    // Check for saved draft on mount when creating new report
    useEffect(() {
      if (initialReport == null && copyFromReport == null) {
        SharedPreferences.getInstance().then((prefs) {
          final userId = userProfileAsync.value?.id ?? 'default';
          final raw = prefs.getString('draft_report_$userId');
          if (raw != null && raw.isNotEmpty) {
            try {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              final housesJson = map['houses'] as List<dynamic>?;
              final savedAtStr = map['savedAt'] as String?;
              final dateStr = savedAtStr != null
                  ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                      .format(DateTime.parse(savedAtStr))
                  : '';
              hasSavedDraft.value = true;
              draftInfo.value = {
                'count': housesJson?.length ?? 0,
                'date': dateStr,
              };
            } catch (_) {}
          }
        });
      }
      return null;
    }, [userProfileAsync.value]);


    // Auto-populate houseEntries by default with all submitted reports sorted by newest date first
    useEffect(() {
      if (initialReport != null || copyFromReport != null) return null;
      final myReports = myReportsAsync.value ?? <Report>[];
      final allReports = allReportsAsync.value ?? <Report>[];
      final combined = <Report>[...myReports, ...allReports];
      final parsed = _parseHouseEntriesFromReports(
        combined,
        breedingPlaces: breedingPlacesAsync.value,
      );
      if (parsed.isNotEmpty) {
        houseEntries.value = parsed;
      } else {
        houseEntries.value = _getDefaultInitialHouseEntries();
      }
      return null;
    }, [myReportsAsync.value, allReportsAsync.value, breedingPlacesAsync.value, initialReport, copyFromReport]);

    // Track active report ID when Posyandu is selected
    useEffect(() {
      if (initialReport != null || copyFromReport != null) return null;
      final pId = selectedPosyanduId.value;
      if (pId != null && pId.isNotEmpty) {
        ref.read(reportRepositoryProvider).getLatestReportByPosyandu(pId).then((latestReport) {
          if (latestReport != null) {
            activeReportId.value = latestReport.id;
          } else {
            activeReportId.value = null;
          }
        });
      } else {
        activeReportId.value = null;
      }
      return null;
    }, [selectedPosyanduId.value, initialReport, copyFromReport]);

    Future<void> saveAndAddHouseEntry(HouseReportEntry newEntry) async {
      // 1. Update existing entry in houseEntries with latest inspection date/status or insert at top
      final existingIndex = houseEntries.value.indexWhere(
        (e) =>
            e.kkNameController.text.trim().toLowerCase() ==
            newEntry.kkNameController.text.trim().toLowerCase(),
      );

      if (existingIndex != -1) {
        final old = houseEntries.value[existingIndex];
        old.reportDate = newEntry.reportDate;
        old.rtController.text = newEntry.rtController.text;
        old.rwController.text = newEntry.rwController.text;
        old.isPositive = newEntry.isPositive;
        old.selectedPlaceIds = List<String?>.from(newEntry.selectedPlaceIds);
        old.positivePlacesCountController.text =
            newEntry.positivePlacesCountController.text;
        old.villageName = newEntry.villageName;
        old.posyanduName = newEntry.posyanduName;
        houseEntries.value = [...houseEntries.value];
      } else {
        houseEntries.value = [newEntry, ...houseEntries.value];
      }

      // 2. Persist directly to Supabase
      isLoading.value = true;
      try {
        final targetDate = newEntry.reportDate ?? DateTime.now();
        final targetKk = newEntry.kkNameController.text.trim().toLowerCase();
        final isPos = newEntry.isPositive == true;
        final breedingPlaces = breedingPlacesAsync.value ?? [];
        final placeNames = <String>[];
        for (var placeId in newEntry.selectedPlaceIds) {
          if (placeId != null && placeId.isNotEmpty) {
            final found = breedingPlaces.firstWhere(
              (p) => p['id'] == placeId,
              orElse: () => {'name': '-'},
            );
            placeNames.add(found['name'] as String);
          }
        }
        final countStr = isPos
            ? (newEntry.positivePlacesCountController.text.trim().isEmpty
                ? '1'
                : newEntry.positivePlacesCountController.text.trim())
            : '0';

        // Check if there is an existing Report in Supabase matching this reportDate
        final allExistingReports = <Report>[
          ...(myReportsAsync.value ?? []),
          ...(allReportsAsync.value ?? []),
        ];

        Report? existingReport;
        for (var r in allExistingReports) {
          final isSame = r.reportDate.year == targetDate.year &&
              r.reportDate.month == targetDate.month &&
              r.reportDate.day == targetDate.day;
          if (isSame) {
            if (r.notes != null && r.notes!.toLowerCase().contains(targetKk)) {
              existingReport = r;
              break;
            }
          }
        }

        if (existingReport != null) {
          // Update the existing report notes
          final blocks = (existingReport.notes ?? '').split('--- KK');
          final updatedBlocks = <String>[];
          bool kkFound = false;

          for (var block in blocks) {
            if (block.trim().isEmpty) continue;
            if (block.toLowerCase().contains('nama kk: $targetKk') ||
                block.toLowerCase().contains('nama kk: ${targetKk.toLowerCase()}')) {
              kkFound = true;
              final sb = StringBuffer();
              sb.writeln('Nama KK: ${newEntry.kkNameController.text.trim()}');
              sb.writeln('RT/RW: ${newEntry.rtController.text.trim()}/${newEntry.rwController.text.trim()}');
              sb.writeln('Hasil: ${isPos ? "Ada Jentik" : "Nihil"}');
              sb.writeln('Tempat: ${isPos && placeNames.isNotEmpty ? placeNames.join(', ') : "-"}');
              sb.writeln('Jumlah: $countStr');
              updatedBlocks.add(sb.toString().trim());
            } else {
              updatedBlocks.add(block.trim());
            }
          }

          if (!kkFound) {
            final sb = StringBuffer();
            sb.writeln('Nama KK: ${newEntry.kkNameController.text.trim()}');
            sb.writeln('RT/RW: ${newEntry.rtController.text.trim()}/${newEntry.rwController.text.trim()}');
            sb.writeln('Hasil: ${isPos ? "Ada Jentik" : "Nihil"}');
            sb.writeln('Tempat: ${isPos && placeNames.isNotEmpty ? placeNames.join(', ') : "-"}');
            sb.writeln('Jumlah: $countStr');
            updatedBlocks.add(sb.toString().trim());
          }

          final finalNotes = StringBuffer();
          int inspected = updatedBlocks.length;
          int positive = 0;
          final allPlaceIds = <String>[];

          for (int i = 0; i < updatedBlocks.length; i++) {
            final blk = updatedBlocks[i];
            final blkIsPos = blk.contains('Hasil: Ada Jentik') || blk.contains('Hasil: Positif');
            if (blkIsPos) positive++;

            final lines = blk.split('\n');
            for (var line in lines) {
              final t = line.trim();
              if (t.startsWith('Tempat: ')) {
                final pStr = t.substring(8).trim();
                if (pStr != '-' && pStr.isNotEmpty) {
                  final pNames = pStr.split(',').map((e) => e.trim()).toList();
                  for (var nm in pNames) {
                    try {
                      final p = breedingPlaces.firstWhere((element) => element['name'] == nm);
                      allPlaceIds.add(p['id'] as String);
                    } catch (_) {}
                  }
                }
              }
            }

            finalNotes.writeln('--- KK ${i + 1} ---');
            finalNotes.writeln(blk);
            finalNotes.writeln('');
          }

          await ref.read(reportRepositoryProvider).updateReport(
            reportId: existingReport.id,
            housesInspected: inspected,
            housesPositive: positive,
            breedingPlaceIds: allPlaceIds,
            reportDate: targetDate,
            notes: finalNotes.toString(),
          );
        } else {
          // Create new report for this date
          String? pId = selectedPosyanduId.value;
          if (pId == null || pId.isEmpty) {
            if (userProfileAsync.value?.posyanduId != null &&
                userProfileAsync.value!.posyanduId!.isNotEmpty) {
              pId = userProfileAsync.value!.posyanduId;
            } else if (posyandusAsync.value?.isNotEmpty == true) {
              final found = posyandusAsync.value!.firstWhere(
                (p) =>
                    p.name.toLowerCase() ==
                    (newEntry.posyanduName ?? '').toLowerCase(),
                orElse: () => posyandusAsync.value!.first,
              );
              pId = found.id;
            }
          }
          pId ??= '20000000-0000-0000-0007-000000000001';

          final StringBuffer notesBuffer = StringBuffer();
          notesBuffer.writeln('--- KK 1 ---');
          notesBuffer.writeln('Nama KK: ${newEntry.kkNameController.text.trim()}');
          notesBuffer.writeln(
            'RT/RW: ${newEntry.rtController.text.trim()}/${newEntry.rwController.text.trim()}',
          );
          notesBuffer.writeln(
            'Hasil: ${isPos ? "Ada Jentik" : "Nihil"}',
          );
          notesBuffer.writeln(
            'Tempat: ${isPos && placeNames.isNotEmpty ? placeNames.join(', ') : "-"}',
          );
          notesBuffer.writeln(
            'Jumlah: $countStr',
          );
          notesBuffer.writeln('');

          await ref.read(reportRepositoryProvider).submitReport(
            posyanduId: pId,
            housesInspected: 1,
            housesPositive: isPos ? 1 : 0,
            breedingPlaceIds:
                newEntry.selectedPlaceIds.whereType<String>().toList(),
            reportDate: targetDate,
            notes: notesBuffer.toString(),
          );
        }

        if (context.mounted) {
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(pendingVerificationCountProvider);
          ref.invalidate(interventionCountProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data pemeriksaan (${newEntry.kkNameController.text.trim()} - ${DateFormat("dd MMM yyyy", "id_ID").format(targetDate)}) berhasil disimpan!',
              ),
              backgroundColor: const Color(0xFF27AE60),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peringatan: Gagal sinkronisasi data ke server: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> saveDraft({bool showToast = true}) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final draftList = inputHouseEntries.value.map((h) => {
          'nik': h.nikController.text.trim(),
          'kkName': h.kkNameController.text.trim(),
          'rt': h.rtController.text.trim(),
          'rw': h.rwController.text.trim(),
          'rtRw': h.rtRwController.text.trim(),
          'isPositive': h.isPositive,
          'selectedPlaceIds': h.selectedPlaceIds,
          'positivePlacesCount': h.positivePlacesCountController.text.trim(),
        }).toList();

        final draftData = jsonEncode({
          'villageId': selectedVillageId.value,
          'posyanduId': selectedPosyanduId.value,
          'reportDate': reportDate.value.toIso8601String(),
          'housesInspected': housesInspectedController.text.trim(),
          'houses': draftList,
          'savedAt': DateTime.now().toIso8601String(),
        });

        final userId = userProfileAsync.value?.id ?? 'default';
        await prefs.setString('draft_report_$userId', draftData);
        hasSavedDraft.value = true;
        draftInfo.value = {
          'count': draftList.length,
          'date': DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now()),
        };

        if (showToast && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Draf berhasil disimpan! Data aman saat Anda berpindah rumah.'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (showToast && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan draf: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> loadDraft() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = userProfileAsync.value?.id ?? 'default';
        final raw = prefs.getString('draft_report_$userId');
        if (raw == null || raw.isEmpty) return;

        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['villageId'] != null) selectedVillageId.value = map['villageId'];
        if (map['posyanduId'] != null) selectedPosyanduId.value = map['posyanduId'];
        if (map['reportDate'] != null) {
          try {
            reportDate.value = DateTime.parse(map['reportDate']);
          } catch (_) {}
        }
        if (map['housesInspected'] != null && (map['housesInspected'] as String).isNotEmpty) {
          housesInspectedController.text = map['housesInspected'];
        }

        final housesJson = map['houses'] as List<dynamic>?;
        if (housesJson != null && housesJson.isNotEmpty) {
          final entries = <HouseReportEntry>[];
          for (var item in housesJson) {
            final entry = HouseReportEntry(
              isPositive: item['isPositive'] as bool?,
              reportDate: reportDate.value,
            );
            entry.nikController.text = item['nik'] ?? '';
            entry.kkNameController.text = item['kkName'] ?? '';
            entry.rtController.text = item['rt'] ?? '';
            entry.rwController.text = item['rw'] ?? '';
            entry.rtRwController.text = item['rtRw'] ?? '';
            entry.positivePlacesCountController.text = item['positivePlacesCount'] ?? '';
            final places = item['selectedPlaceIds'] as List<dynamic>?;
            if (places != null && places.isNotEmpty) {
              entry.selectedPlaceIds = places.map((e) => e as String?).toList();
            }
            entries.add(entry);
          }
          inputHouseEntries.value = entries;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Draf laporan berhasil dimuat! Silakan lanjutkan pengisian.'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF10365F),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat draf: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> clearDraft() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = userProfileAsync.value?.id ?? 'default';
        await prefs.remove('draft_report_$userId');
        hasSavedDraft.value = false;
        draftInfo.value = null;
      } catch (_) {}
    }

    Future<void> handleSubmitBatch() async {
      final targetInspectedStr = housesInspectedController.text.trim();
      final targetInspected = int.tryParse(targetInspectedStr);

      if (targetInspected == null || targetInspected <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap masukkan Jumlah Rumah Yang Diperiksa terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final validHouses = inputHouseEntries.value.where((h) {
        return h.kkNameController.text.trim().isNotEmpty ||
            h.nikController.text.trim().isNotEmpty ||
            h.isPositive != null;
      }).toList();

      if (validHouses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan isi minimal 1 data rumah yang diperiksa!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validasi kesesuaian target jumlah rumah vs inputan data
      if (validHouses.length != targetInspected) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jumlah Data Belum Sesuai',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Jumlah data rumah yang diisi (${validHouses.length} rumah) belum sesuai dengan target Jumlah Rumah Yang Diperiksa ($targetInspected rumah).\n\n'
              'Data tidak dapat dikirim sebelum jumlahnya sesuai. Anda dapat melengkapi datanya sekarang atau klik "Simpan Draf" untuk menyimpan sementara saat berpindah rumah.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey[800], height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('LENGKAPI DATA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_add_outlined, size: 16, color: Colors.white),
                label: Text('SIMPAN DRAF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  saveDraft();
                },
              ),
            ],
          ),
        );
        return;
      }

      for (int i = 0; i < validHouses.length; i++) {
        final h = validHouses[i];
        if (h.kkNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nama KK pada Rumah #${i + 1} belum diisi!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (h.isPositive == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hasil Pemeriksaan untuk "${h.kkNameController.text.trim()}" belum dipilih (Positif / Nihil)!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Validasi NIK tidak boleh sama di antara rumah yang diinput
      final seenNiks = <String, int>{};
      for (int i = 0; i < validHouses.length; i++) {
        final h = validHouses[i];
        final nik = h.nikController.text.trim();
        if (nik.isNotEmpty) {
          if (seenNiks.containsKey(nik)) {
            final firstIdx = seenNiks[nik]! + 1;
            final currentIdx = i + 1;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NIK Tidak Boleh Sama',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'NIK "$nik" pada Rumah #$currentIdx sama dengan NIK pada Rumah #$firstIdx.\n\n'
                  'Setiap rumah harus memiliki NIK yang berbeda (tidak boleh sama). Silakan periksa kembali NIK yang diinput.',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey[800], height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10365F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('OK, SAYA PERBAIKI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
            return;
          }
          seenNiks[nik] = i;
        }
      }

      if (selectedVillageId.value == null && villagesAsync.value?.isNotEmpty == true) {
        selectedVillageId.value = villagesAsync.value!.first.id;
      }
      if (selectedPosyanduId.value == null) {
        if (userProfileAsync.value?.posyanduId != null &&
            userProfileAsync.value!.posyanduId!.isNotEmpty) {
          selectedPosyanduId.value = userProfileAsync.value!.posyanduId;
        } else if (posyandusAsync.value?.isNotEmpty == true) {
          selectedPosyanduId.value = posyandusAsync.value!.first.id;
        } else {
          selectedPosyanduId.value = '20000000-0000-0000-0007-000000000001';
        }
      }

      final entryVillage =
          (selectedVillageName != 'Semua Desa')
              ? selectedVillageName
              : 'Gumelar';
      final entryPosyandu =
          (selectedPosyanduName != 'Semua Posyandu')
              ? selectedPosyanduName
              : 'Posyandu Bina Laju Sejahtera 4';

      isLoading.value = true;
      try {
        final targetDate = reportDate.value;
        final breedingPlaces = breedingPlacesAsync.value ?? [];

        for (var h in validHouses) {
          h.reportDate = targetDate;
          h.villageName = entryVillage;
          h.posyanduName = entryPosyandu;
          if (h.rtRwController.text.trim().isNotEmpty && h.rtRwController.text.trim() != '- / -') {
            final parts = h.rtRwController.text.trim().split('/');
            if (parts.isNotEmpty) h.rtController.text = parts[0].trim();
            if (parts.length >= 2) h.rwController.text = parts[1].trim();
          }
        }

        // Check if there is an existing Report in Supabase matching this reportDate
        final allExistingReports = <Report>[
          ...(myReportsAsync.value ?? []),
          ...(allReportsAsync.value ?? []),
        ];

        Report? existingReport;
        for (var r in allExistingReports) {
          final isSame = r.reportDate.year == targetDate.year &&
              r.reportDate.month == targetDate.month &&
              r.reportDate.day == targetDate.day;
          if (isSame) {
            existingReport = r;
            break;
          }
        }

        final List<Map<String, dynamic>> allKkData = [];

        if (existingReport != null && existingReport.notes != null) {
          final blocks = existingReport.notes!.split('--- KK');
          for (var b in blocks) {
            if (b.trim().isEmpty) continue;
            String nik = '';
            String name = '';
            String rtrw = '-/-';
            bool isPos = false;
            String tempat = '-';
            String jumlah = '0';
            for (var line in b.split('\n')) {
              final t = line.trim();
              if (t.startsWith('NIK: ')) {
                nik = t.substring(5).trim();
              } else if (t.startsWith('Nama KK: ')) {
                name = t.substring(9).trim();
              } else if (t.startsWith('RT/RW: ')) {
                rtrw = t.substring(7).trim();
              } else if (t.startsWith('Hasil: ')) {
                isPos = t.contains('Ada Jentik') || t.contains('Positif');
              } else if (t.startsWith('Tempat: ')) {
                tempat = t.substring(8).trim();
              } else if (t.startsWith('Jumlah: ')) {
                jumlah = t.substring(8).trim();
              }
            }
            if (name.isNotEmpty || nik.isNotEmpty) {
              allKkData.add({
                'nik': nik,
                'name': name,
                'rtrw': rtrw,
                'isPos': isPos,
                'tempat': tempat,
                'jumlah': jumlah,
              });
            }
          }
        }

        for (var h in validHouses) {
          final hNik = h.nikController.text.trim();
          final hName = h.kkNameController.text.trim();
          final isPos = h.isPositive == true;
          final placeNames = <String>[];
          for (var placeId in h.selectedPlaceIds) {
            if (placeId != null && placeId.isNotEmpty) {
              final found = breedingPlaces.firstWhere(
                (p) => p['id'] == placeId,
                orElse: () => {'name': '-'},
              );
              placeNames.add(found['name'] as String);
            }
          }
          final countStr = isPos
              ? (h.positivePlacesCountController.text.trim().isEmpty
                  ? '1'
                  : h.positivePlacesCountController.text.trim())
              : '0';
          final rtrwStr = h.rtRwController.text.trim().isNotEmpty && h.rtRwController.text.trim() != '- / -'
              ? h.rtRwController.text.trim()
              : '${h.rtController.text.trim().isEmpty ? "-" : h.rtController.text.trim()}/${h.rwController.text.trim().isEmpty ? "-" : h.rwController.text.trim()}';

          final existingIdx = allKkData.indexWhere(
            (k) =>
                (hNik.isNotEmpty && (k['nik'] as String? ?? '') == hNik) ||
                (hName.isNotEmpty &&
                    (k['name'] as String).toLowerCase() ==
                        hName.toLowerCase()),
          );
          final entryMap = {
            'nik': hNik,
            'name': hName,
            'rtrw': rtrwStr,
            'isPos': isPos,
            'tempat': isPos && placeNames.isNotEmpty ? placeNames.join(', ') : '-',
            'jumlah': countStr,
            'placeIds': h.selectedPlaceIds.whereType<String>().toList(),
          };

          if (existingIdx != -1) {
            allKkData[existingIdx] = entryMap;
          } else {
            allKkData.add(entryMap);
          }
        }

        final finalNotes = StringBuffer();
        final customCount = int.tryParse(housesInspectedController.text.trim());
        int totalInspected = (customCount != null && customCount > 0)
            ? customCount
            : allKkData.length;
        int totalPositive = 0;
        final Set<String> allBreedingPlaceIds = {};

        for (int i = 0; i < allKkData.length; i++) {
          final kk = allKkData[i];
          final isPos = kk['isPos'] as bool;
          if (isPos) totalPositive++;

          final pIds = kk['placeIds'] as List<String>?;
          if (pIds != null) allBreedingPlaceIds.addAll(pIds);

          final tempatStr = kk['tempat'] as String;
          if (tempatStr != '-' && tempatStr.isNotEmpty) {
            for (var nm in tempatStr.split(',').map((e) => e.trim())) {
              try {
                final p = breedingPlaces.firstWhere((element) => element['name'] == nm);
                allBreedingPlaceIds.add(p['id'] as String);
              } catch (_) {}
            }
          }

          finalNotes.writeln('--- KK ${i + 1} ---');
          if (kk['nik'] != null && (kk['nik'] as String).isNotEmpty) {
            finalNotes.writeln('NIK: ${kk['nik']}');
          }
          finalNotes.writeln('Nama KK: ${kk['name']}');
          finalNotes.writeln('RT/RW: ${kk['rtrw']}');
          finalNotes.writeln('Hasil: ${isPos ? "Ada Jentik" : "Nihil"}');
          finalNotes.writeln('Tempat: ${kk['tempat']}');
          finalNotes.writeln('Jumlah: ${kk['jumlah']}');
          finalNotes.writeln('');
        }

        String? pId = selectedPosyanduId.value;
        if (pId == null || pId.isEmpty) {
          if (userProfileAsync.value?.posyanduId != null &&
              userProfileAsync.value!.posyanduId!.isNotEmpty) {
            pId = userProfileAsync.value!.posyanduId;
          } else if (posyandusAsync.value?.isNotEmpty == true) {
            final found = posyandusAsync.value!.firstWhere(
              (p) =>
                  p.name.toLowerCase() ==
                  (validHouses.first.posyanduName ?? '').toLowerCase(),
              orElse: () => posyandusAsync.value!.first,
            );
            pId = found.id;
          }
        }
        pId ??= '20000000-0000-0000-0007-000000000001';

        if (isEditMode && initialReport != null) {
          await ref.read(reportRepositoryProvider).updateReport(
            reportId: initialReport!.id,
            housesInspected: totalInspected,
            housesPositive: totalPositive,
            breedingPlaceIds: allBreedingPlaceIds.toList(),
            reportDate: targetDate,
            notes: finalNotes.toString(),
          );
        } else if (existingReport != null) {
          await ref.read(reportRepositoryProvider).updateReport(
            reportId: existingReport.id,
            housesInspected: totalInspected,
            housesPositive: totalPositive,
            breedingPlaceIds: allBreedingPlaceIds.toList(),
            reportDate: targetDate,
            notes: finalNotes.toString(),
          );
        } else {
          await ref.read(reportRepositoryProvider).submitReport(
            posyanduId: pId,
            housesInspected: totalInspected,
            housesPositive: totalPositive,
            breedingPlaceIds: allBreedingPlaceIds.toList(),
            reportDate: targetDate,
            notes: finalNotes.toString(),
          );
        }

        if (context.mounted) {
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(pendingVerificationCountProvider);
          ref.invalidate(interventionCountProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Berhasil memperbarui data laporan (${validHouses.length} rumah, tanggal ${DateFormat("dd MMM yyyy", "id_ID").format(targetDate)})!'
                    : 'Berhasil menyimpan ${validHouses.length} data rumah yang diperiksa (${DateFormat("dd MMM yyyy", "id_ID").format(targetDate)})!',
              ),
              backgroundColor: const Color(0xFF27AE60),
              duration: const Duration(seconds: 3),
            ),
          );

          await clearDraft();

          if (isEditMode) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) context.pop();
            });
          } else {
            for (var h in inputHouseEntries.value) {
              h.dispose();
            }
            inputHouseEntries.value = [HouseReportEntry()];
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan laporan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    final showDaftarRumahTable = useState(false).value;

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
                                  isEditMode
                                      ? 'EDIT LAPORAN PSN'
                                      : (copyFromReport != null
                                          ? 'ENTRI LAPORAN PSN (TANGGAL BARU)'
                                          : 'ENTRI LAPORAN PSN'),
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF10365F),
                                    fontSize: isDesktop ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isEditMode
                                      ? 'Edit data laporan PSN tanggal ${DateFormat('dd MMMM yyyy', 'id_ID').format(reportDate.value)}'
                                      : (copyFromReport != null
                                          ? 'Data rumah disalin dari laporan sebelumnya (${DateFormat('dd MMM yyyy', 'id_ID').format(copyFromReport!.reportDate)}). Silakan pilih tanggal baru dan isi hasil pemeriksaan.'
                                          : 'Catat hasil kegiatan Pemberantasan Sarang Nyamuk (PSN)'),
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

                      if (hasSavedDraft.value && !isEditMode) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFD54F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bookmark_added_rounded, color: Color(0xFFE67E22), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Draf Laporan Tersimpan Ditemukan',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: const Color(0xFFB78103),
                                      ),
                                    ),
                                    Text(
                                      'Terdapat draf tersimpan (${draftInfo.value?['count'] ?? 0} data rumah) pada ${draftInfo.value?['date'] ?? ""}. Anda dapat melanjutkan pengisian sekarang.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF795548),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => loadDraft(),
                                icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                                label: Text('Muat Draf', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => clearDraft(),
                                icon: const Icon(Icons.close, size: 18, color: Color(0xFF8D6E63)),
                                tooltip: 'Hapus Draf',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

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
                                    hint: 'Semua Desa',
                                    isLoading: villagesAsync.isLoading,
                                    items: villagesAsync.maybeWhen(
                                      data: (villages) {
                                        return [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Semua Desa'),
                                          ),
                                          ...villages.map(
                                            (v) => DropdownMenuItem<String?>(
                                              value: v.id,
                                              child: Text(v.name),
                                            ),
                                          ),
                                        ];
                                      },
                                      orElse: () => [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('Semua Desa'),
                                        ),
                                      ],
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
                                    value: selectedVillageId.value == null
                                        ? null
                                        : selectedPosyanduId.value,
                                    hint: selectedVillageId.value == null
                                        ? 'Pilih Desa terlebih dahulu'
                                        : 'Semua Posyandu',
                                    isEnabled: selectedVillageId.value != null,
                                    isLoading: selectedVillageId.value != null &&
                                        posyandusAsync.isLoading,
                                    items: selectedVillageId.value == null
                                        ? []
                                        : posyandusAsync.maybeWhen(
                                            data: (posyandus) {
                                              return [
                                                const DropdownMenuItem<String?>(
                                                  value: null,
                                                  child: Text('Semua Posyandu'),
                                                ),
                                                ...posyandus.map(
                                                  (p) => DropdownMenuItem<String?>(
                                                    value: p.id,
                                                    child: Text(p.name),
                                                  ),
                                                ),
                                              ];
                                            },
                                            orElse: () => [
                                              const DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text('Semua Posyandu'),
                                              ),
                                            ],
                                          ),
                                    onChanged: selectedVillageId.value == null
                                        ? null
                                        : (val) =>
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
                             const SizedBox(height: 14),
                             ResponsiveRow(
                               isDesktop: isDesktop,
                               children: [
                                 _buildInputGroup(
                                   label: 'Jumlah Rumah Yang Diperiksa',
                                   icon: Icons.home_work_outlined,
                                   child: TextFormField(
                                     controller: housesInspectedController,
                                     keyboardType: TextInputType.number,
                                     decoration: InputDecoration(
                                       hintText: inputHouseEntries.value.length.toString(),
                                       contentPadding: const EdgeInsets.symmetric(
                                         horizontal: 16,
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
                                   ),
                                 ),
                                 if (isDesktop) const SizedBox(),
                                 if (isDesktop) const SizedBox(),
                               ],
                             ),
                             const SizedBox(height: 16),
                             const Divider(height: 1, color: Color(0xFFE0E0E0)),
                             const SizedBox(height: 16),

                            // Dynamic list of House cards
                            ...inputHouseEntries.value.asMap().entries.map((item) {
                              final idx = item.key;
                              final entry = item.value;
                              return _HouseInputCard(
                                key: ObjectKey(entry),
                                index: idx,
                                totalCount: inputHouseEntries.value.length,
                                entry: entry,
                                allEntries: inputHouseEntries.value,
                                onNikChanged: () {
                                  inputHouseEntries.value = [...inputHouseEntries.value];
                                },
                                isDesktop: isDesktop,
                                breedingPlaces: breedingPlacesAsync.value ?? [],
                                onRemove: inputHouseEntries.value.length > 1
                                    ? () {
                                        final updated = List<HouseReportEntry>.from(inputHouseEntries.value);
                                        final removed = updated.removeAt(idx);
                                        removed.dispose();
                                        inputHouseEntries.value = updated;
                                      }
                                    : null,
                                buildInputGroup: _buildInputGroup,
                                buildDropdown: _buildDropdown,
                              );
                            }),
                            const SizedBox(height: 8),

                            // Bottom Action Buttons: "+ Tambah Data", "Simpan Draf" & "Kirim Laporan"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!isEditMode)
                                  // Small "Tambah Data" Button (only in Add/New mode)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      inputHouseEntries.value = [
                                        ...inputHouseEntries.value,
                                        HouseReportEntry(),
                                      ];
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: Color(0xFF27AE60),
                                    ),
                                    label: Text(
                                      'Tambah Data',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF27AE60),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF27AE60),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isEditMode) ...[
                                      OutlinedButton.icon(
                                        onPressed: isLoading.value ? null : () => saveDraft(),
                                        icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                          size: 16,
                                          color: Color(0xFFE67E22),
                                        ),
                                        label: Text(
                                          'Simpan Draf',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFE67E22),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFE67E22),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],

                                    // Submit Button
                                    ElevatedButton.icon(
                                      onPressed: isLoading.value
                                          ? null
                                          : () => handleSubmitBatch(),
                                      icon: isLoading.value
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                      label: Text(
                                        isEditMode
                                            ? 'Simpan Perubahan'
                                            : 'Kirim Laporan',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF27AE60),
                                        foregroundColor: Colors.white,
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (showDaftarRumahTable) ...[
                        const SizedBox(height: 24),
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
                                            flex: 4,
                                            child: Center(
                                              child: Text(
                                                'Desa / Posyandu',
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
                                  ...pagedEntries.asMap().entries.map((e) {
                                    final idx = e.key;
                                    final entry = e.value;
                                    final rowNumber = startIndex + idx + 1;
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
                                                '$rowNumber',
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
                                                  'dd MMM yyyy',
                                                  'id_ID',
                                                ).format(entry.reportDate ?? DateTime.now()),
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
                                                    idx: startIndex + idx,
                                                    reportDate:
                                                        entry.reportDate ??
                                                        reportDate.value,
                                                    villageName: entry.villageName ?? selectedVillageName,
                                                    posyanduName: entry.posyanduName ?? selectedPosyanduName,
                                                    breedingPlaces:
                                                        breedingPlacesAsync
                                                            .value ??
                                                        [],
                                                    allEntries: houseEntries.value,
                                                    allReports: [
                                                      ...(myReportsAsync.value ?? <Report>[]),
                                                      ...(allReportsAsync.value ?? <Report>[]),
                                                    ],
                                                    onAddNew: (selectedEntry) {
                                                      _showKkAddDialog(
                                                        context: context,
                                                        initialKkName: selectedEntry.kkNameController.text.trim(),
                                                        initialRt: selectedEntry.rtController.text.trim(),
                                                        initialRw: selectedEntry.rwController.text.trim(),
                                                        villageName: selectedEntry.villageName ?? selectedVillageName,
                                                        posyanduName: selectedEntry.posyanduName ?? selectedPosyanduName,
                                                        breedingPlaces:
                                                            breedingPlacesAsync
                                                                .value ??
                                                            [],
                                                        onSaved: (newEntry) {
                                                          saveAndAddHouseEntry(newEntry);
                                                        },
                                                      );
                                                    },
                                                    onEdit: (entryToEdit) {
                                                      _showKkEditDialog(
                                                        context: context,
                                                        entry: entryToEdit,
                                                        idx: startIndex + idx,
                                                        breedingPlaces:
                                                            breedingPlacesAsync
                                                                .value ??
                                                            [],
                                                        onSaved: () {
                                                          saveAndAddHouseEntry(entryToEdit);
                                                        },
                                                      );
                                                    },
                                                    onDelete: (entryToDelete) {
                                                      final newList = List<HouseReportEntry>.from(houseEntries.value);
                                                      newList.remove(entryToDelete);
                                                      entryToDelete.dispose();
                                                      houseEntries.value = newList;
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
                                          // Desa/Posyandu Column
                                          Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    (entry.villageName != null &&
                                                            entry.villageName!.isNotEmpty &&
                                                            entry.villageName != 'Semua Desa')
                                                        ? entry.villageName!
                                                        : ((selectedVillageName != 'Semua Desa')
                                                            ? selectedVillageName
                                                            : 'Gumelar'),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF10365F,
                                                      ),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    softWrap: true,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    (entry.posyanduName != null &&
                                                            entry.posyanduName!.isNotEmpty &&
                                                            entry.posyanduName != 'Semua Posyandu')
                                                        ? entry.posyanduName!
                                                        : ((selectedPosyanduName != 'Semua Posyandu')
                                                            ? selectedPosyanduName
                                                            : 'Posyandu Bina Laju Sejahtera 4'),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    softWrap: true,
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
                                  if (filteredEntries.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Center(
                                        child: Text(
                                          'Tidak ada data rumah yang sesuai dengan filter Desa / Posyandu atau pencarian.',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pagination Controls
                      if (totalItems > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${startIndex + 1}-$endIndex dari $totalItems data',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Sebelumnya (Compact)
                                  InkWell(
                                    onTap: safePage > 1
                                        ? () => currentPage.value = safePage - 1
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: safePage > 1
                                            ? const Color(0xFFF1F8F4)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: safePage > 1
                                              ? const Color(0xFF27AE60)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chevron_left_rounded,
                                            size: 16,
                                            color: safePage > 1
                                                ? const Color(0xFF27AE60)
                                                : Colors.grey[400],
                                          ),
                                          if (screenWidth > 450) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              'Prev',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: safePage > 1
                                                    ? const Color(0xFF27AE60)
                                                    : Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFC8E6C9),
                                      ),
                                    ),
                                    child: Text(
                                      '$safePage / $totalPages',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF27AE60),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Tombol Berikutnya (Compact)
                                  InkWell(
                                    onTap: safePage < totalPages
                                        ? () => currentPage.value = safePage + 1
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: safePage < totalPages
                                            ? const Color(0xFF27AE60)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (screenWidth > 450) ...[
                                            Text(
                                              'Next',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: safePage < totalPages
                                                    ? Colors.white
                                                    : Colors.grey[400],
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                          ],
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 16,
                                            color: safePage < totalPages
                                                ? Colors.white
                                                : Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      ],
                      const SizedBox(height: 24),
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
    required List<DropdownMenuItem<String?>> items,
    required void Function(String?)? onChanged,
    bool isDense = false,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return Container(
        height: isDense ? 38 : null,
        padding: EdgeInsets.symmetric(
          horizontal: isDense ? 8 : 12,
          vertical: isDense ? 0 : 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF4F6F8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hint,
                style: GoogleFonts.outfit(
                  color: Colors.grey[400],
                  fontSize: isDense ? 12 : 13,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey[400],
              size: isDense ? 14 : 16,
            ),
          ],
        ),
      );
    }
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
        child: DropdownButton<String?>(
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
    String posyanduName = "-",
    required List<Map<String, dynamic>> breedingPlaces,
    required List<HouseReportEntry> allEntries,
    required List<Report> allReports,
    required Function(HouseReportEntry entry) onAddNew,
    required Function(HouseReportEntry entryToEdit) onEdit,
    required Function(HouseReportEntry entryToDelete) onDelete,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detail KK',
      barrierColor: Colors.black.withValues(alpha: 0.54),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _KkDetailDialogWidget(
          entry: entry,
          idx: idx,
          reportDate: reportDate,
          villageName: villageName,
          posyanduName: posyanduName,
          breedingPlaces: breedingPlaces,
          allEntries: allEntries,
          allReports: allReports,
          onAddNew: (selectedEntry) {
            Navigator.of(ctx, rootNavigator: false).pop();
            onAddNew(selectedEntry);
          },
          onEdit: (selectedEntry) {
            Navigator.of(ctx, rootNavigator: false).pop();
            onEdit(selectedEntry);
          },
          onDelete: (selectedEntry) {
            Navigator.of(ctx, rootNavigator: false).pop();
            onDelete(selectedEntry);
          },
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scaleAnim = Tween<double>(
          begin: 0.85,
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
            child: child,
          ),
        );
      },
    );
  }
}

class _KkDetailDialogWidget extends StatefulWidget {
  final HouseReportEntry entry;
  final int idx;
  final DateTime reportDate;
  final String villageName;
  final String posyanduName;
  final List<Map<String, dynamic>> breedingPlaces;
  final List<HouseReportEntry> allEntries;
  final List<Report> allReports;
  final Function(HouseReportEntry entry) onAddNew;
  final Function(HouseReportEntry entry) onEdit;
  final Function(HouseReportEntry entry) onDelete;

  const _KkDetailDialogWidget({
    required this.entry,
    required this.idx,
    required this.reportDate,
    this.villageName = "-",
    this.posyanduName = "-",
    required this.breedingPlaces,
    required this.allEntries,
    required this.allReports,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_KkDetailDialogWidget> createState() => _KkDetailDialogWidgetState();
}

class _KkDetailDialogWidgetState extends State<_KkDetailDialogWidget> {
  late HouseReportEntry _selectedEntry;
  late List<HouseReportEntry> _availableEntries;

  @override
  void initState() {
    super.initState();
    _selectedEntry = widget.entry;
    _buildAvailableEntries();
  }

  void _buildAvailableEntries() {
    _availableEntries = _extractAllEntriesForKk(
      kkName: widget.entry.kkNameController.text,
      currentEntry: widget.entry,
      currentEntries: widget.allEntries,
      allReports: widget.allReports,
      breedingPlaces: widget.breedingPlaces,
      defaultVillage: widget.villageName,
      defaultPosyandu: widget.posyanduName,
    );

    // Pick entry matching widget.entry or reportDate
    final match = _availableEntries.firstWhere(
      (e) =>
          identical(e, widget.entry) ||
          (_isSameDay(e.reportDate, widget.entry.reportDate ?? widget.reportDate)),
      orElse: () => _availableEntries.isNotEmpty ? _availableEntries.first : widget.entry,
    );
    _selectedEntry = match;
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final kkName = _selectedEntry.kkNameController.text.trim().isEmpty
        ? (widget.entry.kkNameController.text.trim().isEmpty
            ? '-'
            : widget.entry.kkNameController.text.trim())
        : _selectedEntry.kkNameController.text.trim();
    final rt = _selectedEntry.rtController.text.trim().isEmpty
        ? '-'
        : _selectedEntry.rtController.text.trim();
    final rw = _selectedEntry.rwController.text.trim().isEmpty
        ? '-'
        : _selectedEntry.rwController.text.trim();
    final villageName = (_selectedEntry.villageName != null &&
            _selectedEntry.villageName!.isNotEmpty &&
            _selectedEntry.villageName != '-')
        ? _selectedEntry.villageName!
        : widget.villageName;
    final posyanduName = (_selectedEntry.posyanduName != null &&
            _selectedEntry.posyanduName!.isNotEmpty &&
            _selectedEntry.posyanduName != '-')
        ? _selectedEntry.posyanduName!
        : widget.posyanduName;

    List<String> placeNames = [];
    if (_selectedEntry.isPositive == true) {
      for (var pId in _selectedEntry.selectedPlaceIds) {
        if (pId != null && pId.isNotEmpty) {
          final found = widget.breedingPlaces.firstWhere(
            (p) => p['id'] == pId,
            orElse: () => {'name': pId},
          );
          placeNames.add(found['name'] as String);
        }
      }
    }

    final positiveCount =
        _selectedEntry.positivePlacesCountController.text.trim().isEmpty
            ? '-'
            : _selectedEntry.positivePlacesCountController.text.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                        'Data lengkap entri ke-${widget.idx + 1}',
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
              value: '#${widget.idx + 1} - $kkName',
              isBold: true,
            ),
            const SizedBox(height: 12),

            // Tanggal Laporan Dropdown Selector (Filtered specifically for this KK)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF10365F),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: Text(
                    'Tanggal Laporan',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCCE0EE)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<HouseReportEntry>(
                        value: _availableEntries.contains(_selectedEntry)
                            ? _selectedEntry
                            : (_availableEntries.isNotEmpty
                                ? _availableEntries.first
                                : null),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF2980B9),
                          size: 20,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        items: _availableEntries.map((item) {
                          final formattedDate = DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(item.reportDate ?? DateTime.now());
                          final isPos = item.isPositive == true;
                          return DropdownMenuItem<HouseReportEntry>(
                            value: item,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10365F),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPos
                                        ? const Color(0xFFFFEBEE)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPos ? 'Positif' : 'Nihil',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPos
                                          ? const Color(0xFFD32F2F)
                                          : const Color(0xFF27AE60),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              _selectedEntry = newVal;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
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
              icon: Icons.storefront_outlined,
              label: 'Posyandu',
              value: posyanduName,
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
                  child: _selectedEntry.isPositive == true
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
                      : _selectedEntry.isPositive == false
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
              value: _selectedEntry.isPositive == true
                  ? (positiveCount == '-' ? '-' : '$positiveCount wadah/tempat')
                  : '-',
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Actions (Aksi)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onAddNew(_selectedEntry),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    '+ Tambahkan Data Baru',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onDelete(_selectedEntry),
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
                        onPressed: () => widget.onEdit(_selectedEntry),
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
          ],
        ),
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

void _showKkAddDialog({
  required BuildContext context,
  required String initialKkName,
  required String initialRt,
  required String initialRw,
  String villageName = "-",
  String posyanduName = "-",
  required List<Map<String, dynamic>> breedingPlaces,
  required Function(HouseReportEntry newEntry) onSaved,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tambah Data Baru',
    barrierColor: Colors.black.withValues(alpha: 0.54),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      return _KkAddDialogWidget(
        initialKkName: initialKkName,
        initialRt: initialRt,
        initialRw: initialRw,
        villageName: villageName,
        posyanduName: posyanduName,
        breedingPlaces: breedingPlaces,
        onSaved: onSaved,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final scaleAnim = Tween<double>(
        begin: 0.85,
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
          child: child,
        ),
      );
    },
  );
}

class _KkAddDialogWidget extends StatefulWidget {
  final String initialKkName;
  final String initialRt;
  final String initialRw;
  final String villageName;
  final String posyanduName;
  final List<Map<String, dynamic>> breedingPlaces;
  final Function(HouseReportEntry newEntry) onSaved;

  const _KkAddDialogWidget({
    required this.initialKkName,
    required this.initialRt,
    required this.initialRw,
    this.villageName = "-",
    this.posyanduName = "-",
    required this.breedingPlaces,
    required this.onSaved,
  });

  @override
  State<_KkAddDialogWidget> createState() => _KkAddDialogWidgetState();
}

class _KkAddDialogWidgetState extends State<_KkAddDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _positiveCountController;
  bool? _isPositive = false;
  final List<String?> _selectedPlaceIds = [null];
  late DateTime _addReportDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialKkName);
    _rtController = TextEditingController(text: widget.initialRt);
    _rwController = TextEditingController(text: widget.initialRw);
    _positiveCountController = TextEditingController();
    _addReportDate = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _positiveCountController.dispose();
    super.dispose();
  }

  void _saveNewData() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama KK tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newEntry = HouseReportEntry(
      reportDate: _addReportDate,
      villageName: widget.villageName,
      posyanduName: widget.posyanduName,
      isPositive: _isPositive,
      isEditing: false,
    );
    newEntry.kkNameController.text = name;
    newEntry.rtController.text = _rtController.text.trim();
    newEntry.rwController.text = _rwController.text.trim();

    if (_isPositive == true) {
      newEntry.selectedPlaceIds = _selectedPlaceIds
          .whereType<String>()
          .toList();
      newEntry.positivePlacesCountController.text =
          _positiveCountController.text.trim();
    } else {
      newEntry.selectedPlaceIds = [];
      newEntry.positivePlacesCountController.clear();
    }

    Navigator.of(context).pop();
    widget.onSaved(newEntry);
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
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_home_work_rounded,
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
                        'Tambah Data Pemeriksaan Baru',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      Text(
                        'Data baru untuk ${widget.initialKkName}',
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
                    // Tanggal Pemeriksaan
                    Text(
                      'Tanggal Pemeriksaan',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _addReportDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _addReportDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_addReportDate),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF27AE60),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

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

            // Actions (Batal / Tambahkan Data)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 11),
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveNewData,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Tambahkan Data',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(vertical: 11),
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
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      return _KkEditDialogWidget(
        entry: entry,
        idx: idx,
        breedingPlaces: breedingPlaces,
        onSaved: onSaved,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final scaleAnim = Tween<double>(
        begin: 0.85,
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
          child: child,
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
  late DateTime _editReportDate;

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
    _editReportDate = widget.entry.reportDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _positiveCountController.dispose();
    super.dispose();
  }

  void _saveAsUpdate() {
    widget.entry.reportDate = _editReportDate;
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
        content: Text('Data KK ke-${widget.idx + 1} berhasil diperbarui!'),
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
                    // Tanggal Pemeriksaan Ulang / Laporan
                    Text(
                      'Tanggal Pemeriksaan Ulang / Edit Laporan',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _editReportDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _editReportDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID').format(_editReportDate),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF2980B9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

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

            // Actions (Batal / Update Data Ini)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 11),
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveAsUpdate,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Update Data Ini',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2980B9),
                      padding: const EdgeInsets.symmetric(vertical: 11),
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

List<HouseReportEntry> _extractAllEntriesForKk({
  required String kkName,
  required HouseReportEntry currentEntry,
  required List<HouseReportEntry> currentEntries,
  required List<Report> allReports,
  required List<Map<String, dynamic>> breedingPlaces,
  String? defaultVillage,
  String? defaultPosyandu,
}) {
  final targetName = kkName.trim().toLowerCase();
  final results = <HouseReportEntry>[];
  final seenDates = <String>{};

  void addEntryIfUnique(HouseReportEntry entry) {
    final d = entry.reportDate ?? DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(d);
    if (!seenDates.contains(dateKey)) {
      seenDates.add(dateKey);
      results.add(entry);
    }
  }

  // 1. Add currentEntry
  addEntryIfUnique(currentEntry);

  // 2. Add any entries from screen's currentEntries
  for (var e in currentEntries) {
    if (targetName.isEmpty ||
        e.kkNameController.text.trim().toLowerCase() == targetName) {
      addEntryIfUnique(e);
    }
  }

  // 3. Add any entries from historical allReports
  for (var rep in allReports) {
    if (rep.notes == null || rep.notes!.trim().isEmpty) continue;
    final blocks = rep.notes!.split('--- KK');
    for (var block in blocks) {
      if (block.trim().isEmpty) continue;
      final lines = block.split('\n');
      String blockNik = '';
      String blockKkName = '';
      String blockRt = '';
      String blockRw = '';
      bool? blockIsPositive;
      String blockCount = '';
      List<String?> blockPlaceIds = [];

      for (var line in lines) {
        final t = line.trim();
        if (t.startsWith('NIK: ')) {
          blockNik = t.substring(5).trim();
        } else if (t.startsWith('Nama KK: ')) {
          blockKkName = t.substring(9).trim();
        } else if (t.startsWith('RT/RW: ')) {
          final parts = t.substring(7).split('/');
          if (parts.isNotEmpty) blockRt = parts[0].trim();
          if (parts.length >= 2) blockRw = parts[1].trim();
        } else if (t.startsWith('Hasil: ')) {
          final res = t.substring(7);
          if (res.contains('Ada Jentik') || res.contains('Positif')) {
            blockIsPositive = true;
          } else if (res.contains('Nihil')) {
            blockIsPositive = false;
          }
        } else if (t.startsWith('Jumlah: ')) {
          blockCount = t.substring(8).trim();
        } else if (t.startsWith('Tempat: ')) {
          final placeStr = t.substring(8).trim();
          if (placeStr != '-' && placeStr.isNotEmpty) {
            final names = placeStr.split(',').map((e) => e.trim()).toList();
            for (var nm in names) {
              try {
                final p = breedingPlaces.firstWhere(
                  (element) => element['name'] == nm,
                );
                blockPlaceIds.add(p['id'] as String);
              } catch (_) {}
            }
          }
        }
      }

      if (targetName.isEmpty || blockKkName.toLowerCase() == targetName) {
        final entry = HouseReportEntry(
          isPositive: blockIsPositive,
          reportDate: rep.reportDate,
          villageName: (rep.villageName != null &&
                  rep.villageName!.isNotEmpty &&
                  rep.villageName != '-')
              ? rep.villageName
              : (defaultVillage ?? 'Gumelar'),
          posyanduName: (rep.posyanduName != null &&
                  rep.posyanduName!.isNotEmpty &&
                  rep.posyanduName != '-')
              ? rep.posyanduName
              : (defaultPosyandu ?? 'Posyandu Bina Laju Sejahtera 4'),
        );
        entry.nikController.text = blockNik;
        entry.kkNameController.text =
            blockKkName.isNotEmpty ? blockKkName : kkName;
        entry.rtController.text = blockRt;
        entry.rwController.text = blockRw;
        entry.positivePlacesCountController.text = blockCount;
        if (blockPlaceIds.isNotEmpty) {
          entry.selectedPlaceIds = blockPlaceIds;
        }
        addEntryIfUnique(entry);
      }
    }
  }

  // Sort descending by date (latest first)
  results.sort((a, b) {
    final da = a.reportDate ?? DateTime(2000);
    final db = b.reportDate ?? DateTime(2000);
    return db.compareTo(da);
  });

  return results;
}

List<HouseReportEntry> _parseHouseEntriesFromReports(
  List<Report> reports, {
  String? fallbackVillage,
  String? fallbackPosyandu,
  List<Map<String, dynamic>>? breedingPlaces,
}) {
  // Deduplicate reports by report id
  final seenReportIds = <String>{};
  final uniqueReports = <Report>[];
  for (var r in reports) {
    if (seenReportIds.add(r.id)) {
      uniqueReports.add(r);
    }
  }

  // 1. Sort reports descending by reportDate (latest report first)
  uniqueReports.sort((a, b) => b.reportDate.compareTo(a.reportDate));

  final Map<String, HouseReportEntry> uniqueEntriesByKk = {};

  for (var rep in uniqueReports) {
    if (rep.notes == null || rep.notes!.trim().isEmpty) continue;
    final blocks = rep.notes!.split('--- KK');
    for (var block in blocks) {
      if (block.trim().isEmpty) continue;
      final entry = HouseReportEntry();
      entry.reportDate = rep.reportDate;
      entry.villageName =
          (rep.villageName != null &&
                  rep.villageName!.isNotEmpty &&
                  rep.villageName != '-')
              ? rep.villageName
              : (fallbackVillage ?? 'Gumelar');
      entry.posyanduName =
          (rep.posyanduName != null &&
                  rep.posyanduName!.isNotEmpty &&
                  rep.posyanduName != '-')
              ? rep.posyanduName
              : (fallbackPosyandu ?? 'Posyandu Bina Laju Sejahtera 4');

      final lines = block.split('\n');
      for (var line in lines) {
        final t = line.trim();
        if (t.startsWith('NIK: ')) {
          entry.nikController.text = t.substring(5).trim();
        } else if (t.startsWith('Nama KK: ')) {
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
        } else if (t.startsWith('Tempat: ')) {
          final placeStr = t.substring(8).trim();
          if (placeStr != '-' && placeStr.isNotEmpty && breedingPlaces != null) {
            final names = placeStr.split(',').map((e) => e.trim()).toList();
            final matched = <String?>[];
            for (var nm in names) {
              try {
                final p = breedingPlaces.firstWhere(
                  (element) => element['name'] == nm,
                );
                matched.add(p['id'] as String);
              } catch (_) {}
            }
            if (matched.isNotEmpty) entry.selectedPlaceIds = matched;
          }
        }
      }
      final name = entry.kkNameController.text.trim();
      if (name.isNotEmpty) {
        final key = name.toLowerCase();
        // Since uniqueReports is sorted newest first, keep the latest report for each unique KK name
        if (!uniqueEntriesByKk.containsKey(key)) {
          uniqueEntriesByKk[key] = entry;
        }
      }
    }
  }

  if (uniqueEntriesByKk.isEmpty) {
    return _getDefaultInitialHouseEntries(
      defaultVillage: fallbackVillage,
      defaultPosyandu: fallbackPosyandu,
    );
  }

  final result = uniqueEntriesByKk.values.toList();
  // Sort entries descending by reportDate (latest updated date at the top)
  result.sort((a, b) {
    final da = a.reportDate ?? DateTime(2000);
    final db = b.reportDate ?? DateTime(2000);
    return db.compareTo(da);
  });

  return result;
}

List<HouseReportEntry> _getDefaultInitialHouseEntries({
  DateTime? defaultDate,
  String? defaultVillage,
  String? defaultPosyandu,
}) {
  final now = defaultDate ?? DateTime.now();
  final vName = defaultVillage ?? 'Gumelar';
  final pName = defaultPosyandu ?? 'Posyandu Bina Laju Sejahtera 4';

  final e1 = HouseReportEntry(
    isPositive: false,
    reportDate: now,
    villageName: vName,
    posyanduName: pName,
  );
  e1.kkNameController.text = 'Eko Setyo';
  e1.rtController.text = '09';
  e1.rwController.text = '03';

  final e2 = HouseReportEntry(
    isPositive: true,
    reportDate: now,
    villageName: vName,
    posyanduName: pName,
  );
  e2.kkNameController.text = 'Budi Santoso';
  e2.rtController.text = '02';
  e2.rwController.text = '01';
  e2.positivePlacesCountController.text = '1';

  final e3 = HouseReportEntry(
    isPositive: false,
    reportDate: now,
    villageName: vName,
    posyanduName: pName,
  );
  e3.kkNameController.text = 'Ahmad Dahlan';
  e3.rtController.text = '05';
  e3.rwController.text = '02';

  return [e1, e2, e3];
}
