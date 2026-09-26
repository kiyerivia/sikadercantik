import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/domain/models.dart';

class SuperAdminReportsScreen extends ConsumerStatefulWidget {
  const SuperAdminReportsScreen({super.key});

  @override
  ConsumerState<SuperAdminReportsScreen> createState() => _SuperAdminReportsScreenState();
}

class _SuperAdminReportsScreenState extends ConsumerState<SuperAdminReportsScreen> {
  String? selectedBulan;
  String? selectedTahun;
  String? selectedKecamatan;
  String? selectedDesa;
  String? selectedPosyandu;
  String? _userSelectedViewMode; // 'card' or 'table'

  @override
  Widget build(BuildContext context) {
    final villagesAsync = ref.watch(villagesProvider);
    final reportsAsync = ref.watch(allReportsProvider);
    final allReports = reportsAsync.value ?? [];
    final interventionsAsync = ref.watch(allInterventionsProvider);
    final allInterventions = interventionsAsync.value ?? [];

    String? selectedDesaName;
    villagesAsync.whenData((villages) {
      if (selectedDesa != null) {
        for (final v in villages) {
          if (v.id == selectedDesa) {
            selectedDesaName = v.name;
            break;
          }
        }
      }
    });

    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthIndex = selectedBulan == null ? 0 : (monthNames.indexOf(selectedBulan!) + 1);
    final targetYear = int.tryParse(selectedTahun ?? '') ?? 0;

    final filteredReports = allReports.where((r) {
      final matchMonth = monthIndex == 0 || r.reportDate.month == monthIndex;
      final matchYear = targetYear == 0 || r.reportDate.year == targetYear;
      bool matchDesa = true;
      if (selectedDesaName != null && selectedDesaName!.isNotEmpty) {
        matchDesa = r.villageName != null &&
            r.villageName!.trim().toLowerCase() == selectedDesaName!.trim().toLowerCase();
      }
      return matchMonth && matchYear && matchDesa;
    }).toList();

    final int totalLaporan = filteredReports.length;
    final List<Report> positiveReports = filteredReports.where((r) => r.housesPositive > 0).toList();
    final int totalPositiveHouses = filteredReports.fold<int>(0, (sum, r) => sum + r.housesPositive);
    final int totalInspectedHouses = filteredReports.fold<int>(0, (sum, r) => sum + r.housesInspected);

    final int safePositive = totalPositiveHouses.clamp(0, totalInspectedHouses);
    final int safeFree = (totalInspectedHouses - safePositive).clamp(0, totalInspectedHouses);
    final double calculatedAbj = totalInspectedHouses > 0
        ? ((safeFree / totalInspectedHouses) * 100.0).clamp(0.0, 100.0)
        : 100.0;

    final Set<String> uniqueKaderIds = filteredReports.map((r) => r.kaderId).toSet();
    final int totalKaderAktif = uniqueKaderIds.length;

    final int totalIntervensi = allInterventions.where((i) {
      final rId = i['report_id']?.toString();
      return filteredReports.any((r) => r.id == rId);
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA), // Light bluish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.bug_report, color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
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
                    'REKAP & LAPORAN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBadge(),
          SizedBox(width: 8),
          UserProfileMenu(),
          SizedBox(width: 12),
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
                  'Rekap & Laporan PSN',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2E86C1), Color(0xFF1B4F72)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assessment_outlined, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rekap & Laporan PSN',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unduh dan ekspor rekapitulasi data surveilans jentik, ABJ, dan kegiatan kader dalam format spreadsheet Excel.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

            // Filter Cards Row (Pilih Bulan, Pilih Tahun, Pilih Kelurahan)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterCard(
                      label: 'Pilih Bulan',
                      value: selectedBulan ?? 'Semua',
                      items: [
                        'Semua', 'Januari', 'Februari', 'Maret', 'April',
                        'Mei', 'Juni', 'Juli', 'Agustus', 'September',
                        'Oktober', 'November', 'Desember',
                      ],
                      onChanged: (val) => setState(() => selectedBulan = val == 'Semua' ? null : val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterCard(
                      label: 'Pilih Tahun',
                      value: selectedTahun ?? 'Semua',
                      items: ['Semua', '2023', '2024', '2025', '2026'],
                      onChanged: (val) => setState(() => selectedTahun = val == 'Semua' ? null : val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: villagesAsync.when(
                      data: (villages) {
                        final gumelarVillages = [
                          'cilangkap', 'cihonje', 'paningkaban', 'karangkemojing',
                          'gancang', 'kedungurang', 'gumelar', 'tlaga', 'samudra', 'samudra kulon',
                        ];
                        final gumelarOnly = villages
                            .where((v) => gumelarVillages.contains(v.name.trim().toLowerCase()))
                            .toList();
                        final names = ['Semua', ...gumelarOnly.map((v) => v.name)];
                        final currentValue = selectedDesa != null
                            ? gumelarOnly.firstWhere((v) => v.id == selectedDesa, orElse: () => gumelarOnly.first).name
                            : 'Semua';
                        return _buildFilterCard(
                          label: 'Pilih Kelurahan',
                          value: currentValue,
                          items: names,
                          onChanged: (val) {
                            if (val == null || val == 'Semua') {
                              setState(() {
                                selectedDesa = null;
                                selectedPosyandu = null;
                              });
                            } else {
                              final found = gumelarOnly.firstWhere((v) => v.name == val);
                              setState(() {
                                selectedDesa = found.id;
                                selectedPosyandu = null;
                              });
                            }
                          },
                        );
                      },
                      loading: () => _buildFilterCard(label: 'Pilih Kelurahan', value: 'Memuat...', items: const ['Memuat...'], onChanged: null),
                      error: (_, _) => _buildFilterCard(label: 'Pilih Kelurahan', value: 'Error', items: const ['Error'], onChanged: null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report List Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final showCards = _userSelectedViewMode == 'card' || (_userSelectedViewMode == null && isNarrow);

                final reports = [
                  {
                    'no': '1',
                    'nama': 'Rekap Laporan PSN',
                    'deskripsi': 'Rekap seluruh laporan PSN dari semua kader berdasarkan filter wilayah dan waktu.',
                    'icon': Icons.assignment_outlined,
                    'color': const Color(0xFF2E86C1),
                    'statBadge': totalLaporan > 0 ? '$totalLaporan Data Masuk' : '0 Laporan',
                    'statColor': const Color(0xFF2E86C1),
                  },
                  {
                    'no': '2',
                    'nama': 'Rekap Rumah Positif Jentik',
                    'deskripsi': 'Daftar rumah dan lokasi dengan hasil temuan jentik positif per wilayah.',
                    'icon': Icons.home_work_outlined,
                    'color': const Color(0xFFE67E22),
                    'statBadge': totalPositiveHouses > 0 ? '$totalPositiveHouses Rumah Positif (${positiveReports.length} Laporan)' : '0 Temuan (Aman)',
                    'statColor': totalPositiveHouses > 0 ? const Color(0xFFE67E22) : const Color(0xFF2E7D32),
                  },
                  {
                    'no': '3',
                    'nama': 'Rekap Intervensi PSN',
                    'deskripsi': 'Status dan tindak lanjut intervensi pada temuan jentik dan sarang nyamuk.',
                    'icon': Icons.health_and_safety_outlined,
                    'color': const Color(0xFF27AE60),
                    'statBadge': totalIntervensi > 0 ? '$totalIntervensi Tindak Lanjut' : 'Siap Ditindaklanjuti',
                    'statColor': const Color(0xFF27AE60),
                  },
                  {
                    'no': '4',
                    'nama': 'Capaian ABJ per Wilayah',
                    'deskripsi': 'Persentase dan evaluasi Angka Bebas Jentik (ABJ) per puskesmas/kecamatan.',
                    'icon': Icons.bar_chart_rounded,
                    'color': const Color(0xFF8E44AD),
                    'statBadge': totalInspectedHouses > 0 ? 'ABJ ${calculatedAbj.toStringAsFixed(1)}% (Target ≥95%)' : 'Standar Kemenkes',
                    'statColor': calculatedAbj >= 95.0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                  },
                  {
                    'no': '5',
                    'nama': 'Rekap Laporan per Kader',
                    'deskripsi': 'Jumlah keaktifan laporan dan cakupan pemeriksaan per petugas kader.',
                    'icon': Icons.badge_outlined,
                    'color': const Color(0xFF16A085),
                    'statBadge': totalKaderAktif > 0 ? '$totalKaderAktif Kader Aktif' : 'Semua Kader',
                    'statColor': const Color(0xFF16A085),
                  },
                  {
                    'no': '6',
                    'nama': 'Rekap Kunjungan Kader',
                    'deskripsi': 'Frekuensi dan riwayat kunjungan kader pemantau jentik ke rumah warga.',
                    'icon': Icons.directions_walk_outlined,
                    'color': const Color(0xFFD35400),
                    'statBadge': totalInspectedHouses > 0 ? '$totalInspectedHouses Rumah Dikunjungi' : 'Monitoring Rutin',
                    'statColor': const Color(0xFFD35400),
                  },
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Sync Info Chip
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data Tersinkronisasi: $totalLaporan laporan terfilter dari database live Supabase (ABJ Rata-rata ${calculatedAbj.toStringAsFixed(1)}%).',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1B5E20),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Laporan Rekap PSN',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF10365F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pilih dokumen untuk diunduh (Format Excel .xlsx)',
                                style: GoogleFonts.outfit(
                                  color: Colors.blueGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // View Switcher (Kartu / Tabel)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _userSelectedViewMode = 'card'),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: showCards ? const Color(0xFF10365F) : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.view_agenda_outlined, size: 14, color: showCards ? Colors.white : Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Kartu',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: showCards ? Colors.white : Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _userSelectedViewMode = 'table'),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !showCards ? const Color(0xFF10365F) : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart_outlined, size: 14, color: !showCards ? Colors.white : Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tabel',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: !showCards ? Colors.white : Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (showCards)
                      ...reports.map((r) => _buildReportCard(
                            no: r['no'] as String,
                            nama: r['nama'] as String,
                            deskripsi: r['deskripsi'] as String,
                            icon: r['icon'] as IconData,
                            iconColor: r['color'] as Color,
                            statBadge: r['statBadge'] as String,
                            statColor: r['statColor'] as Color,
                            onDownload: () => _downloadReport(
                              context,
                              nama: r['nama'] as String,
                              statBadge: r['statBadge'] as String,
                              totalLaporan: totalLaporan,
                              totalInspected: totalInspectedHouses,
                              totalPositive: totalPositiveHouses,
                              abj: calculatedAbj,
                            ),
                          ))
                    else
                      _buildDesktopTable(
                        reports,
                        totalLaporan: totalLaporan,
                        totalInspected: totalInspectedHouses,
                        totalPositive: totalPositiveHouses,
                        abj: calculatedAbj,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan 6 jenis laporan',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F).withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '1',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Catatan Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.2)),
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
                    child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File laporan dalam format Excel (.xlsx) dapat dibuka menggunakan Microsoft Excel atau aplikasi sejenis.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F).withValues(alpha: 0.7),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }

  Widget _buildFilterCard({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.22)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF10365F)),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10365F),
              ),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReport(
    BuildContext context, {
    required String nama,
    required String statBadge,
    required int totalLaporan,
    required int totalInspected,
    required int totalPositive,
    required double abj,
  }) {
    final bulanStr = selectedBulan ?? 'Semua Bulan';
    final tahunStr = selectedTahun ?? 'Semua Tahun';
    final desaStr = selectedDesa == null || selectedDesa == 'Semua' ? 'Semua Desa' : 'Desa Terpilih';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF68B744).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.file_download_outlined, color: Color(0xFF2E7D32), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unduh Dokumen Laporan',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF10365F),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sync Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tersinkron Real-time dari Database Supabase',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Detail dokumen laporan yang akan diunduh:',
                style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('• Periode: $bulanStr $tahunStr', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey[800])),
                    Text('• Wilayah: Kecamatan Gumelar ($desaStr)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey[800])),
                    Text('• Format File: Microsoft Excel (.xlsx)', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                    const Divider(height: 16),
                    Text('Ringkasan Data Tersaring:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jumlah Baris Data:', style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.blueGrey[700])),
                        Text('$totalLaporan data', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rumah Diperiksa:', style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.blueGrey[700])),
                        Text('$totalInspected rumah', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Temuan Positif Jentik:', style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.blueGrey[700])),
                        Text('$totalPositive rumah', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: totalPositive > 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Capaian ABJ:', style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.blueGrey[700])),
                        Text('${abj.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: abj >= 95.0 ? const Color(0xFF2E7D32) : const Color(0xFFF57C00))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFF2E7D32),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'File "$nama.xlsx" ($totalLaporan baris data) berhasil disiapkan untuk diunduh.',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: Text('Unduh Sekarang', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF68B744),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String no,
    required String nama,
    required String deskripsi,
    required IconData icon,
    required Color iconColor,
    required String statBadge,
    required Color statColor,
    required VoidCallback onDownload,
  }) {
    final periodText = selectedBulan != null
        ? '$selectedBulan ${selectedTahun ?? '2026'}'
        : (selectedTahun != null ? 'Tahun $selectedTahun' : 'Semua Periode');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular pastel icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Middle Content: Title, Description, and Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10365F),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF546E7A),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          periodText,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.insights_rounded, size: 10, color: statColor),
                            const SizedBox(width: 4),
                            Text(
                              statBadge,
                              style: GoogleFonts.outfit(
                                color: statColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.table_chart_rounded, size: 11, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              'EXCEL .xlsx',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2E7D32),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
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
            const SizedBox(width: 10),
            // Unduh Button
            ElevatedButton(
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A859),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Unduh',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    List<Map<String, dynamic>> reportList, {
    required int totalLaporan,
    required int totalInspected,
    required int totalPositive,
    required double abj,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Center(child: _headerText('No.'))),
                    SizedBox(width: 180, child: _headerText('Nama Laporan')),
                    SizedBox(width: 250, child: _headerText('Deskripsi')),
                    SizedBox(width: 140, child: Center(child: _headerText('Status Data'))),
                    SizedBox(width: 80, child: Center(child: _headerText('Format'))),
                    SizedBox(width: 96, child: Center(child: _headerText('Aksi'))),
                  ],
                ),
              ),
              // Table Rows
              ...reportList.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == reportList.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Center(
                          child: Text(
                            item['no'] as String,
                            style: GoogleFonts.outfit(color: const Color(0xFF10365F), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['nama'] as String,
                                style: GoogleFonts.outfit(color: const Color(0xFF10365F), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Text(
                          item['deskripsi'] as String,
                          style: GoogleFonts.outfit(color: Colors.blueGrey[700], fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item['statColor'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: (item['statColor'] as Color).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item['statBadge'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(color: item['statColor'] as Color, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Excel',
                              style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadReport(
                              context,
                              nama: item['nama'] as String,
                              statBadge: item['statBadge'] as String,
                              totalLaporan: totalLaporan,
                              totalInspected: totalInspected,
                              totalPositive: totalPositive,
                              abj: abj,
                            ),
                            icon: const Icon(Icons.download, color: Colors.white, size: 14),
                            label: Text('Unduh', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF68B744),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              visualDensity: VisualDensity.compact,
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
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: const Color(0xFF10365F),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
