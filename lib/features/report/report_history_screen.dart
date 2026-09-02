import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/domain/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportHistoryScreen extends HookConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final villagesAsync = ref.watch(villagesProvider);
    final isAdmin = profileAsync.maybeWhen(
      data: (p) => p?.role == 'admin' || p?.role == 'superadmin',
      orElse: () => false,
    );

    final selectedMonth = useState<String>('Semua');
    final selectedYear = useState<String>('Semua');
    final selectedVillage = useState<String>('Semua');
    final selectedPosyandu = useState<String>('Semua');
    final searchQuery = useState<String>('');
    final searchController = useTextEditingController();
    final scrollController = useScrollController();
    final tempNotes = useRef<Map<String, String>>({});
    final savingLocks = useRef<Map<String, bool>>({});

    final reportsAsync = profileAsync.maybeWhen(
      data: (profile) => (profile?.role == 'admin' || profile?.role == 'superadmin')
          ? ref.watch(allReportsProvider)
          : ref.watch(myReportsProvider),
      orElse: () => const AsyncValue.loading(),
    );

    final adminNotesAsync = ref.watch(allAdminNotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/psn_logo_new.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
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
                  'RIWAYAT LAPORAN',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
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
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF10365F), size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  child: Text(
                    'Beranda',
                    style: GoogleFonts.outfit(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.blueGrey,
                ),
                Text(
                  'Riwayat Laporan PSN',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'DATA MONITORING LAPORAN PSN',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berikut adalah data laporan PSN yang dikirim oleh kader.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filters
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;

                        final matchedVillage = villagesAsync.maybeWhen(
                          data: (villages) {
                            if (selectedVillage.value == 'Semua') return null;
                            return villages
                                .where((v) => v.name.toLowerCase().trim() == selectedVillage.value.toLowerCase().trim())
                                .firstOrNull;
                          },
                          orElse: () => null,
                        );

                        final posyandusAsync = matchedVillage != null
                            ? ref.watch(posyandusByVillageProvider(matchedVillage.id))
                            : ref.watch(allPosyandusProvider);

                        final posyanduWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih Posyandu',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: posyandusAsync.when(
                                          data: (posyandus) {
                                            final posyanduNames = posyandus
                                                .map((p) => p.name)
                                                .toSet()
                                                .toList()
                                              ..sort();
                                            return DropdownButton<String>(
                                              value: posyanduNames.contains(selectedPosyandu.value)
                                                  ? selectedPosyandu.value
                                                  : 'Semua',
                                              isDense: true,
                                              isExpanded: true,
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: const Color(0xFF10365F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  selectedPosyandu.value = val;
                                                }
                                              },
                                              items: [
                                                const DropdownMenuItem(
                                                  value: 'Semua',
                                                  child: Text('Semua'),
                                                ),
                                                ...posyanduNames.map(
                                                  (name) => DropdownMenuItem(
                                                    value: name,
                                                    child: Text(
                                                      name,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () => DropdownButton<String>(
                                            value: 'Semua',
                                            isDense: true,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Semua',
                                                child: Text('Memuat...'),
                                              ),
                                            ],
                                            onChanged: null,
                                          ),
                                          error: (e, s) => DropdownButton<String>(
                                            value: 'Semua',
                                            isDense: true,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Semua',
                                                child: Text('Semua'),
                                              ),
                                            ],
                                            onChanged: null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final desaWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home_work,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih Desa',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: villagesAsync.when(
                                          data: (villages) {
                                            final gumelarVillages = [
                                              'cilangkap', 'cihonje', 'paningkaban', 'karangkemojing',
                                              'gancang', 'kedungurang', 'gumelar', 'tlaga', 'samudra', 'samudra kulon',
                                            ];
                                            final gumelarOnly = villages
                                                .where((v) => gumelarVillages.contains(v.name.trim().toLowerCase()))
                                                .toList();
                                            return DropdownButton<String>(
                                              value: selectedVillage.value,
                                              isDense: true,
                                              isExpanded: true,
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: const Color(0xFF10365F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  selectedVillage.value = val;
                                                  selectedPosyandu.value = 'Semua';
                                                }
                                              },
                                              items: [
                                                const DropdownMenuItem(
                                                  value: 'Semua',
                                                  child: Text('Semua'),
                                                ),
                                                ...gumelarOnly.map(
                                                  (v) => DropdownMenuItem(
                                                    value: v.name,
                                                    child: Text(v.name),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () => DropdownButton<String>(
                                            value: 'Semua',
                                            isDense: true,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Semua',
                                                child: Text('Memuat...'),
                                              ),
                                            ],
                                            onChanged: null,
                                          ),
                                          error: (e, s) => DropdownButton<String>(
                                            value: 'Semua',
                                            isDense: true,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Semua',
                                                child: Text('Error'),
                                              ),
                                            ],
                                            onChanged: null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final bulanWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih Bulan',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedMonth.value,
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: const Color(0xFF10365F),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          onChanged: (val) {
                                            if (val != null) {
                                              selectedMonth.value = val;
                                            }
                                          },
                                          items:
                                              [
                                                    'Semua',
                                                    'Januari',
                                                    'Februari',
                                                    'Maret',
                                                    'April',
                                                    'Mei',
                                                    'Juni',
                                                    'Juli',
                                                    'Agustus',
                                                    'September',
                                                    'Oktober',
                                                    'November',
                                                    'Desember',
                                                  ]
                                                  .map<
                                                    DropdownMenuItem<String>
                                                  >(
                                                    (e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text(
                                                        e,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final tahunWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih Tahun',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedYear.value,
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: const Color(0xFF10365F),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          onChanged: (val) {
                                            if (val != null) {
                                              selectedYear.value = val;
                                            }
                                          },
                                          items:
                                              [
                                                    'Semua',
                                                    '2024',
                                                    '2025',
                                                    '2026',
                                                    '2027',
                                                  ]
                                                  .map<
                                                    DropdownMenuItem<String>
                                                  >(
                                                    (e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text(
                                                        e,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: desaWidget),
                                  const SizedBox(width: 12),
                                  Expanded(child: posyanduWidget),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: bulanWidget),
                                  const SizedBox(width: 12),
                                  Expanded(child: tahunWidget),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: desaWidget),
                              const SizedBox(width: 16),
                              Expanded(child: posyanduWidget),
                              const SizedBox(width: 16),
                              Expanded(child: bulanWidget),
                              const SizedBox(width: 16),
                              Expanded(child: tahunWidget),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Search & Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (val) => searchQuery.value = val,
                            onSubmitted: (val) => searchQuery.value = val,
                            decoration: InputDecoration(
                              hintText: 'Ketik untuk mencari...',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            searchQuery.value = searchController.text.trim();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Cari',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            minimumSize: const Size(
                              0,
                              50,
                            ), // Override infinity width global theme
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(allReportsProvider);
                            ref.invalidate(myReportsProvider);
                            ref.invalidate(allAdminNotesProvider);
                            ref.invalidate(villagesProvider);
                            ref.invalidate(allPosyandusProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Data riwayat berhasil diperbarui',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Refresh',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            minimumSize: const Size(
                              0,
                              50,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Table
                    reportsAsync.when(
                      data: (reports) {
                        var filtered = reports.where((r) => r.status != 'draft').toList();

                        // Month filter
                        if (selectedMonth.value != 'Semua') {
                          final monthIndex =
                              [
                                'Januari',
                                'Februari',
                                'Maret',
                                'April',
                                'Mei',
                                'Juni',
                                'Juli',
                                'Agustus',
                                'September',
                                'Oktober',
                                'November',
                                'Desember',
                              ].indexOf(selectedMonth.value) +
                              1;
                          filtered = filtered
                              .where((r) => r.reportDate.month == monthIndex)
                              .toList();
                        }

                        // Year filter
                        if (selectedYear.value != 'Semua') {
                          filtered = filtered
                              .where(
                                (r) =>
                                    r.reportDate.year.toString() ==
                                    selectedYear.value,
                              )
                              .toList();
                        }

                        // Village filter
                        if (selectedVillage.value != 'Semua') {
                          filtered = filtered
                              .where(
                                (r) =>
                                    (r.villageName ?? '')
                                        .toLowerCase()
                                        .trim() ==
                                    selectedVillage.value.toLowerCase().trim(),
                              )
                              .toList();
                        }

                        // Posyandu filter
                        if (selectedPosyandu.value != 'Semua') {
                          filtered = filtered
                              .where(
                                (r) =>
                                    (r.posyanduName ?? '')
                                        .toLowerCase()
                                        .trim() ==
                                    selectedPosyandu.value.toLowerCase().trim(),
                              )
                              .toList();
                        }

                        // Search filter
                        if (searchQuery.value.isNotEmpty) {
                          filtered = filtered
                              .where(
                                (r) =>
                                    (r.villageName ?? '')
                                        .toLowerCase()
                                        .contains(
                                          searchQuery.value.toLowerCase(),
                                        ) ||
                                    (r.posyanduName ?? '')
                                        .toLowerCase()
                                        .contains(
                                          searchQuery.value.toLowerCase(),
                                        ),
                              )
                              .toList();
                        }

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  thickness: 8,
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowColor: WidgetStateProperty.all(
                                        const Color(0xFFF4F8FA),
                                      ),
                                      columnSpacing: 20,
                                      dataRowMinHeight: 50,
                                      dataRowMaxHeight: 60,
                                      headingTextStyle: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10365F),
                                      ),
                                      columns: [
                                        const DataColumn(label: Text('No')),
                                        const DataColumn(
                                          label: Text('Tanggal PSN'),
                                        ),
                                        const DataColumn(
                                          label: Text('Nama Desa'),
                                        ),
                                        const DataColumn(
                                          label: Text('Posyandu'),
                                        ),
                                        const DataColumn(
                                          label: Text('Rumah Diperiksa'),
                                          numeric: true,
                                        ),
                                        const DataColumn(
                                          label: Text('Positif Jentik'),
                                          numeric: true,
                                        ),
                                        const DataColumn(label: Text('ABJ')),
                                        const DataColumn(
                                          label: SizedBox(
                                            width: 250,
                                            child: Text('Aksi'),
                                          ),
                                        ),
                                        if (isAdmin)
                                          const DataColumn(
                                            label: Text('Intervensi'),
                                          ),
                                        if (isAdmin)
                                          const DataColumn(
                                            label: Text('Keterangan'),
                                          ),
                                        if (isAdmin)
                                          const DataColumn(
                                            label: Text('Hapus'),
                                          ),
                                      ],
                                      rows: filtered.asMap().entries.map<DataRow>((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final report = entry.value;
                                        final abjValue =
                                            ((report.housesInspected -
                                                report.housesPositive) /
                                            (report.housesInspected > 0
                                                ? report.housesInspected
                                                : 1) *
                                            100);
                                        final isSudah =
                                            report.status == 'verified';

                                        final adminNote = adminNotesAsync
                                            .maybeWhen(
                                              data: (map) => map[report.id],
                                              orElse: () => null,
                                            );

                                        return DataRow(
                                          color: WidgetStateProperty.all(
                                            index % 2 == 0
                                                ? Colors.white
                                                : const Color(0xFFF4F8FA),
                                          ),
                                          onSelectChanged: (_) =>
                                              _showReportSummaryDialog(
                                                context,
                                                ref,
                                                report,
                                                reports,
                                                isAdmin,
                                              ),
                                          cells: [
                                            DataCell(
                                              Text(
                                                '${index + 1}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    DateFormat('dd MMMM yyyy').format(report.reportDate),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('HH:mm:ss').format(report.createdAt),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                report.villageName ?? '-',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                report.posyanduName ?? '-',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${report.housesInspected}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${report.housesPositive}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${abjValue.toStringAsFixed(1)}%',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: abjValue >= 95
                                                      ? Colors.green[600]
                                                      : Colors.orange[600],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // 1. Lihat Laporan
                                                    OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _showReportSummaryDialog(
                                                            context,
                                                            ref,
                                                            report,
                                                            reports,
                                                            isAdmin,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.visibility_outlined,
                                                        size: 13,
                                                        color: Color(0xFF10365F),
                                                      ),
                                                      label: Text(
                                                        'Lihat',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF10365F),
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(0xFF10365F),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    // 2. Tambah Laporan (Salin data tanggal sebelumnya)
                                                    OutlinedButton.icon(
                                                      onPressed: () => context.push(
                                                        '/report',
                                                        extra: {
                                                          'copyFrom': report,
                                                          'mode': 'copy',
                                                        },
                                                      ),
                                                      icon: const Icon(
                                                        Icons.add_circle_outline,
                                                        size: 13,
                                                        color: Color(0xFF27AE60),
                                                      ),
                                                      label: Text(
                                                        'Tambah Laporan',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF27AE60),
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(0xFF27AE60),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    // 3. Edit Laporan
                                                    OutlinedButton.icon(
                                                      onPressed: () => context.push(
                                                        '/report',
                                                        extra: {
                                                          'report': report,
                                                          'mode': 'edit',
                                                        },
                                                      ),
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 13,
                                                        color: Color(0xFF29B6F6),
                                                      ),
                                                      label: Text(
                                                        'Edit',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF29B6F6),
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(0xFF29B6F6),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isAdmin)
                                              DataCell(
                                                Container(
                                                  height: 28,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: isSudah
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      value: isSudah
                                                          ? 'Sudah'
                                                          : 'Belum',
                                                      isDense: true,
                                                      icon: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      items: ['Belum', 'Sudah']
                                                          .map(
                                                            (
                                                              e,
                                                            ) => DropdownMenuItem(
                                                              value: e,
                                                              child: Text(
                                                                e,
                                                                style: GoogleFonts.outfit(
                                                                  fontSize: 11,
                                                                  color:
                                                                      e ==
                                                                          'Sudah'
                                                                      ? Colors
                                                                            .green
                                                                      : Colors
                                                                            .red,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                      onChanged: (val) async {
                                                        if (val == 'Sudah' &&
                                                            !isSudah) {
                                                          await Supabase
                                                              .instance
                                                              .client
                                                              .from('reports')
                                                              .update({
                                                                'status':
                                                                    'verified',
                                                              })
                                                              .eq(
                                                                'id',
                                                                report.id,
                                                              );
                                                          ref.invalidate(
                                                            allReportsProvider,
                                                          );
                                                        } else if (val ==
                                                                'Belum' &&
                                                            isSudah) {
                                                          await Supabase
                                                              .instance
                                                              .client
                                                              .from('reports')
                                                              .update({
                                                                'status':
                                                                    'submitted',
                                                              })
                                                              .eq(
                                                                'id',
                                                                report.id,
                                                              );
                                                          ref.invalidate(
                                                            allReportsProvider,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (isAdmin)
                                              DataCell(
                                                Builder(
                                                  builder: (context) {
                                                    Future<void> saveNote(
                                                      String val,
                                                    ) async {
                                                      if (savingLocks
                                                              .value[report
                                                              .id] ==
                                                          true) {
                                                        return;
                                                      }
                                                      if (val ==
                                                          (adminNote ?? '')) {
                                                        return;
                                                      }
                                                      if (val == '-' &&
                                                          (adminNote == null ||
                                                              adminNote
                                                                  .trim()
                                                                  .isEmpty)) {
                                                        return;
                                                      }

                                                      savingLocks.value[report
                                                              .id] =
                                                          true;
                                                      try {
                                                        await Supabase
                                                            .instance
                                                            .client
                                                            .from(
                                                              'interventions',
                                                            )
                                                            .delete()
                                                            .eq(
                                                              'report_id',
                                                              report.id,
                                                            )
                                                            .eq(
                                                              'type',
                                                              'kunjungan_rumah',
                                                            );
                                                        if (val
                                                                .trim()
                                                                .isNotEmpty &&
                                                            val.trim() != '-') {
                                                          await Supabase
                                                              .instance
                                                              .client
                                                              .from(
                                                                'interventions',
                                                              )
                                                              .insert({
                                                                'report_id':
                                                                    report.id,
                                                                'type':
                                                                    'kunjungan_rumah',
                                                                'description':
                                                                    val.trim(),
                                                                'admin_id': Supabase
                                                                    .instance
                                                                    .client
                                                                    .auth
                                                                    .currentUser!
                                                                    .id,
                                                              });
                                                        }
                                                        ref.invalidate(
                                                          allAdminNotesProvider,
                                                        );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Catatan berhasil disimpan!',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              duration:
                                                                  Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Gagal menyimpan: $e',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 4,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                      } finally {
                                                        Future.delayed(
                                                          const Duration(
                                                            milliseconds: 500,
                                                          ),
                                                          () {
                                                            savingLocks
                                                                    .value[report
                                                                    .id] =
                                                                false;
                                                          },
                                                        );
                                                      }
                                                    }

                                                    return SizedBox(
                                                      width: 150,
                                                      child: Focus(
                                                        onFocusChange:
                                                            (hasFocus) async {
                                                              if (!hasFocus &&
                                                                  tempNotes
                                                                      .value
                                                                      .containsKey(
                                                                        report
                                                                            .id,
                                                                      )) {
                                                                await saveNote(
                                                                  tempNotes
                                                                      .value[report
                                                                      .id]!,
                                                                );
                                                              }
                                                            },
                                                        child: TextFormField(
                                                          initialValue:
                                                              (adminNote ==
                                                                      null ||
                                                                  adminNote
                                                                      .trim()
                                                                      .isEmpty)
                                                              ? '-'
                                                              : adminNote,
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .blueGrey,
                                                              ),
                                                          textInputAction:
                                                              TextInputAction
                                                                  .done,
                                                          onChanged: (val) =>
                                                              tempNotes
                                                                      .value[report
                                                                      .id] =
                                                                  val,
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                'Ketik lalu klik luar...',
                                                            hintStyle: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[400],
                                                            ),
                                                            isDense: true,
                                                            contentPadding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 8,
                                                                  horizontal: 8,
                                                                ),
                                                            border: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey[300]!,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey[300]!,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderSide:
                                                                  const BorderSide(
                                                                    color: Color(
                                                                      0xFF29B6F6,
                                                                    ),
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                          ),
                                                          onFieldSubmitted:
                                                              (val) async {
                                                                await saveNote(
                                                                  val,
                                                                );
                                                              },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            if (isAdmin)
                                              DataCell(
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: Text(
                                                          'Konfirmasi Hapus',
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        content: Text(
                                                          'Apakah Anda yakin ingin menghapus data laporan ini?',
                                                          style:
                                                              GoogleFonts.outfit(),
                                                        ),
                                                        actionsAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        actions: [
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              try {
                                                                await ref
                                                                    .read(
                                                                      reportRepositoryProvider,
                                                                    )
                                                                    .deleteReport(
                                                                      report.id,
                                                                    );
                                                                ref.invalidate(
                                                                  allReportsProvider,
                                                                );
                                                                if (context
                                                                    .mounted) {
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                        'Laporan berhasil dihapus!',
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green,
                                                                    ),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                if (context
                                                                    .mounted) {
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Gagal menghapus: $e',
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                              minimumSize:
                                                                  const Size(
                                                                    80,
                                                                    40,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Hapus',
                                                              style: GoogleFonts.outfit(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            style: TextButton.styleFrom(
                                                              minimumSize:
                                                                  const Size(
                                                                    80,
                                                                    40,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Batal',
                                                              style: GoogleFonts.outfit(
                                                                color: Colors
                                                                    .blueGrey,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Menampilkan ${filtered.length} data dari ${reports.length} laporan',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF29B6F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '1',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, s) => Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Info
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF29B6F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data diperbarui secara otomatis berdasarkan laporan PSN kader. Pastikan intervensi dilakukan untuk meningkatkan capaian ABJ.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportSummaryDialog(
    BuildContext context,
    WidgetRef ref,
    Report report,
    List<Report> allReports,
    bool isAdmin,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ViewReportDialog(
        initialReport: report,
        allReports: allReports,
        isAdmin: isAdmin,
        ref: ref,
      ),
    );
  }
}

class _ViewReportDialog extends StatefulWidget {
  final Report initialReport;
  final List<Report> allReports;
  final bool isAdmin;
  final WidgetRef ref;

  const _ViewReportDialog({
    required this.initialReport,
    required this.allReports,
    required this.isAdmin,
    required this.ref,
  });

  @override
  State<_ViewReportDialog> createState() => _ViewReportDialogState();
}

class _ViewReportDialogState extends State<_ViewReportDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialReport.reportDate;
  }

  Report? _findReportForDate(DateTime date) {
    for (var r in widget.allReports) {
      final isSamePosyandu = (r.posyanduId == widget.initialReport.posyanduId) ||
          (r.posyanduName != null &&
              r.posyanduName!.isNotEmpty &&
              r.posyanduName == widget.initialReport.posyanduName);
      final isSameDate = r.reportDate.year == date.year &&
          r.reportDate.month == date.month &&
          r.reportDate.day == date.day;
      if (isSamePosyandu && isSameDate) {
        return r;
      }
    }
    return null;
  }

  List<DateTime> _getAvailableDates() {
    final dates = <DateTime>[];
    for (var r in widget.allReports) {
      final isSamePosyandu = (r.posyanduId == widget.initialReport.posyanduId) ||
          (r.posyanduName != null &&
              r.posyanduName!.isNotEmpty &&
              r.posyanduName == widget.initialReport.posyanduName);
      if (isSamePosyandu) {
        if (!dates.any((d) =>
            d.year == r.reportDate.year &&
            d.month == r.reportDate.month &&
            d.day == r.reportDate.day)) {
          dates.add(r.reportDate);
        }
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  List<Map<String, String>> _parseHouses(String? notes) {
    final houses = <Map<String, String>>[];
    if (notes != null) {
      final blocks = notes.split('--- KK');
      for (var block in blocks) {
        if (block.trim().isEmpty) continue;
        final data = <String, String>{};
        final lines = block.split('\n');
        for (var line in lines) {
          final t = line.trim();
          if (t.startsWith('NIK: ')) {
            data['nik'] = t.substring(5).trim();
          } else if (t.startsWith('Nama KK: ')) {
            data['kk'] = t.substring(9).trim();
          } else if (t.startsWith('RT/RW: ')) {
            final parts = t.substring(7).split('/');
            if (parts.length == 2) {
              data['rt'] = parts[0].trim();
              data['rw'] = parts[1].trim();
            } else {
              data['rtrw'] = t.substring(7).trim();
            }
          } else if (t.startsWith('Tempat: ')) {
            data['tempat'] = t.substring(8).trim();
          } else if (t.startsWith('Hasil: ')) {
            data['hasil'] = t.substring(7).trim();
          } else if (t.startsWith('Jumlah: ')) {
            data['jumlah'] = t.substring(8).trim();
          }
        }
        if (data.isNotEmpty) houses.add(data);
      }
    }
    return houses;
  }

  @override
  Widget build(BuildContext context) {
    final report = _findReportForDate(_selectedDate);
    final availableDates = _getAvailableDates();
    final houses = report != null ? _parseHouses(report.notes) : <Map<String, String>>[];
    final abjValue = report != null
        ? ((report.housesInspected - report.housesPositive) /
            (report.housesInspected > 0 ? report.housesInspected : 1) *
            100)
        : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10365F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: Color(0xFF10365F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIHAT LAPORAN PSN',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10365F),
                          ),
                        ),
                        Text(
                          '${widget.initialReport.posyanduName ?? "-"} • ${widget.initialReport.villageName ?? "-"}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 20),

            // Date Picker Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFF10365F), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10365F),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.edit_calendar, size: 14, color: Color(0xFF10365F)),
                        label: Text(
                          'Ganti Tanggal',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10365F),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10365F)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                  if (availableDates.length > 1) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Tanggal Laporan Dientri: ',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.blueGrey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: availableDates.map((d) {
                                final isSelected = d.year == _selectedDate.year &&
                                    d.month == _selectedDate.month &&
                                    d.day == _selectedDate.day;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = d;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF10365F)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF10365F)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('dd MMM yyyy', 'id_ID').format(d),
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : const Color(0xFF10365F),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Body: If report exists on selected date, show summary & list; else show empty state
            Flexible(
              child: report != null
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Stats Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'Rumah Diperiksa',
                                        '${report.housesInspected}',
                                        Colors.blue[700]!,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'Positif Jentik',
                                        '${report.housesPositive}',
                                        report.housesPositive > 0
                                            ? Colors.red[700]!
                                            : Colors.green[700]!,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'ABJ',
                                        '${abjValue.toStringAsFixed(1)}%',
                                        abjValue >= 95
                                            ? Colors.green[700]!
                                            : Colors.orange[700]!,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'Status',
                                        report.status == 'verified'
                                            ? 'TERKIRIM'
                                            : (report.status == 'need_intervention'
                                                ? 'PERLU PERBAIKAN'
                                                : 'SUBMITTED'),
                                        report.status == 'verified'
                                            ? Colors.green[700]!
                                            : (report.status == 'need_intervention'
                                                ? Colors.orange[800]!
                                                : Colors.blueGrey),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (report.status == 'need_intervention') ...[
                            Consumer(
                              builder: (context, ref, child) {
                                final interventionsAsync = ref.watch(
                                  interventionsByReportProvider(report.id),
                                );
                                return interventionsAsync.when(
                                  data: (items) {
                                    if (items.isEmpty) return const SizedBox.shrink();
                                    final latest = items.first;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange.shade800,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'CATATAN PERBAIKAN DARI ADMIN:',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: Colors.orange.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            latest['description'] ?? '-',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: Colors.orange.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (e, _) => const SizedBox.shrink(),
                                );
                              },
                            ),
                          ],

                          Text(
                            'Daftar Rumah yang Diperiksa (${houses.length} KK):',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10365F),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (houses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Text(
                                'Data detail KK tidak tersedia untuk laporan ini.',
                                style: GoogleFonts.outfit(color: Colors.grey[600]),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: houses.length,
                              itemBuilder: (context, index) {
                                final h = houses[index];
                                final isPos = h['hasil'] == 'Ada Jentik' ||
                                    h['hasil'] == 'Positif' ||
                                    (h['hasil'] ?? '').toLowerCase().contains('positif') ||
                                    (h['hasil'] ?? '').toLowerCase().contains('ada jentik');
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isPos ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isPos ? Colors.red.shade200 : Colors.green.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rumah #${index + 1}',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: const Color(0xFF10365F),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPos ? Colors.red[600] : Colors.green[600],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isPos ? 'Positif Jentik' : 'Nihil',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (h['nik'] != null && h['nik']!.isNotEmpty)
                                        _buildInfoRow('NIK', h['nik']!),
                                      _buildInfoRow('Nama KK', h['kk'] ?? '-'),
                                      _buildInfoRow('RT/RW', h['rtrw'] ?? '${h['rt'] ?? "-"}/${h['rw'] ?? "-"}'),
                                      if (isPos) ...[
                                        _buildInfoRow('Tempat Jentik', h['tempat'] ?? '-'),
                                        if (h['jumlah'] != null && h['jumlah']!.isNotEmpty && h['jumlah'] != '0')
                                          _buildInfoRow('Jumlah Tempat Positif', h['jumlah']!),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 56,
                            color: Colors.blueGrey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak Ada Laporan pada Tanggal Ini',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10365F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kader belum mengentri data laporan pada tanggal ${DateFormat("dd MMMM yyyy", "id_ID").format(_selectedDate)}.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (availableDates.isNotEmpty) ...[
                            Text(
                              'Silakan pilih tanggal laporan yang telah dientri kader:',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: availableDates.map((d) {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = d;
                                    });
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                                  label: Text(
                                    DateFormat('dd MMMM yyyy', 'id_ID').format(d),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27AE60),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Footer buttons
            Row(
              children: [
                if (widget.isAdmin && report != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_late, color: Colors.white, size: 16),
                      label: Text(
                        'MINTA PERBAIKAN',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showInterventionNoteDialog(context, widget.ref, report);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10365F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'TUTUP',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.blueGrey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10365F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInterventionNoteDialog(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permintaan Perbaikan Laporan',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kirimkan catatan perbaikan kepada kader terkait laporan di ${report.posyanduName ?? report.villageName ?? "fasilitas ini"}.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Tuliskan bagian mana yang salah dan apa yang harus diperbaiki oleh kader...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final desc = controller.text.trim();
              Navigator.pop(context); // Tutup modal input

              try {
                await ref
                    .read(reportRepositoryProvider)
                    .addIntervention(
                      reportId: report.id,
                      type: 'psn_ulang',
                      description: desc,
                    );
                ref.invalidate(allReportsProvider);
                ref.invalidate(myReportsProvider);
                ref.invalidate(allAdminNotesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Permintaan perbaikan berhasil dikirim ke kader!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengirim permintaan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'KIRIM PERMINTAAN',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
