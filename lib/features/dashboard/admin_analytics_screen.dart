import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/admin_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  // 0: Bar Chart, 1: Trend Line, 2: Detailed Table
  int _activeViewMode = 0;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final villageDetailsAsync = ref.watch(villageAbjDetailsProvider);
    final monthlyTrendAsync = ref.watch(monthlyAbjTrendProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    final monthNames = [
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
      'Desember'
    ];

    final monthOptions = ['Semua', ...monthNames];
    final currentYear = DateTime.now().year;
    final yearOptions = [
      'Semua',
      ...List.generate(5, (i) => (currentYear - 2 + i).toString())
    ];

    final activeMonthText =
        selectedMonth == 0 ? 'Semua Bulan' : monthNames[selectedMonth - 1];
    final activeYearText =
        selectedYear == 0 ? 'Semua Tahun' : selectedYear.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_dinas_banyumas.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Analitik Capaian ABJ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBadge(),
          SizedBox(width: 10),
          UserProfileMenu(),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title + Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring Angka Bebas Jentik (ABJ)',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evaluasi data epidemiologi jentik berdasarkan laporan kader PSN se-wilayah kerja.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/map'),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: Text('Peta Digital', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Filter Bar (Puskesmas, Bulan, Tahun)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Puskesmas badge
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded,
                              size: 18, color: Color(0xFF0288D1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Wilayah Kerja',
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B))),
                                Text(
                                  'Puskesmas Gumelar',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10365F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bulan Dropdown
                  Expanded(
                    flex: 3,
                    child: _FilterDropdown(
                      label: 'Bulan Laporan',
                      value: selectedMonth == 0
                          ? 'Semua'
                          : monthNames[selectedMonth - 1],
                      icon: Icons.calendar_today_rounded,
                      items: monthOptions,
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'Semua') {
                            ref.read(selectedMonthProvider.notifier).set(0);
                          } else {
                            ref
                                .read(selectedMonthProvider.notifier)
                                .set(monthNames.indexOf(val) + 1);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tahun Dropdown
                  Expanded(
                    flex: 3,
                    child: _FilterDropdown(
                      label: 'Tahun Laporan',
                      value: selectedYear == 0
                          ? 'Semua'
                          : selectedYear.toString(),
                      icon: Icons.date_range_rounded,
                      items: yearOptions,
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'Semua') {
                            ref.read(selectedYearProvider.notifier).set(0);
                          } else {
                            ref
                                .read(selectedYearProvider.notifier)
                                .set(int.parse(val));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary KPI Cards (4 Cards)
            statsAsync.when(
              data: (stats) {
                final double avgAbj = (stats['avgAbj'] as num?)?.toDouble() ?? 100.0;
                final int totalInspected = (stats['totalInspected'] as num?)?.toInt() ?? 0;
                final int totalPositive = (stats['totalPositive'] as num?)?.toInt() ?? 0;
                final int totalFree = (stats['totalFree'] as num?)?.toInt() ?? 0;

                return villageDetailsAsync.when(
                  data: (villages) {
                    final targetMetCount = villages.where((v) => v.isTargetMet).length;
                    final targetFailedCount = villages.where((v) => !v.isTargetMet).length;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 800;
                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Rata-rata ABJ',
                                      value: '${avgAbj.toStringAsFixed(1)}%',
                                      subtitle: avgAbj >= 95.0
                                          ? 'Memenuhi Target (≥95%)'
                                          : 'Di Bawah Target',
                                      color: avgAbj >= 95.0
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFEF4444),
                                      icon: Icons.health_and_safety_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Desa Capai Target',
                                      value: '$targetMetCount Desa',
                                      subtitle: 'ABJ ≥ 95% Kemenkes',
                                      color: const Color(0xFF22C55E),
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Desa Belum Capai',
                                      value: '$targetFailedCount Desa',
                                      subtitle: 'Perlu intervensi PSN',
                                      color: const Color(0xFFF59E0B),
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Rumah Diperiksa',
                                      value: '$totalInspected',
                                      subtitle: '$totalPositive Positif | $totalFree Bebas',
                                      color: const Color(0xFF0288D1),
                                      icon: Icons.home_work_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Rata-rata ABJ Wilayah',
                                  value: '${avgAbj.toStringAsFixed(1)}%',
                                  subtitle: avgAbj >= 95.0
                                      ? 'Memenuhi Target (≥95%)'
                                      : 'Di Bawah Target',
                                  color: avgAbj >= 95.0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.health_and_safety_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Desa Memenuhi Target',
                                  value: '$targetMetCount Desa',
                                  subtitle: 'ABJ ≥ 95% Kemenkes',
                                  color: const Color(0xFF22C55E),
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Desa Rawan Jentik',
                                  value: '$targetFailedCount Desa',
                                  subtitle: 'Perlu intervensi PSN',
                                  color: const Color(0xFFEF4444),
                                  icon: Icons.warning_amber_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Total Rumah Diperiksa',
                                  value: '$totalInspected Rumah',
                                  subtitle: '$totalPositive Positif | $totalFree Bebas',
                                  color: const Color(0xFF0288D1),
                                  icon: Icons.home_work_rounded,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              )),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // ── Main Chart Card with Switchable Tabs ──
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Header: Title & View Switcher Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Capaian ABJ per Desa',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10365F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: const Color(0xFFA5D6A7)),
                                ),
                                child: Text(
                                  'Standar Kemenkes ≥95%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Periode: $activeMonthText $activeYearText • Klik batang atau desa untuk rincian data',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      // View Mode Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ViewTabButton(
                              icon: Icons.bar_chart_rounded,
                              label: 'Batang',
                              isActive: _activeViewMode == 0,
                              onTap: () => setState(() => _activeViewMode = 0),
                            ),
                            const SizedBox(width: 4),
                            _ViewTabButton(
                              icon: Icons.show_chart_rounded,
                              label: 'Tren Bulanan',
                              isActive: _activeViewMode == 1,
                              onTap: () => setState(() => _activeViewMode = 1),
                            ),
                            const SizedBox(width: 4),
                            _ViewTabButton(
                              icon: Icons.table_chart_rounded,
                              label: 'Tabel Rincian',
                              isActive: _activeViewMode == 2,
                              onTap: () => setState(() => _activeViewMode = 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Display according to Active View Mode
                  if (_activeViewMode == 0)
                    _buildBarChartView(villageDetailsAsync)
                  else if (_activeViewMode == 1)
                    _buildTrendChartView(monthlyTrendAsync, activeYearText)
                  else
                    _buildDetailedTableView(villageDetailsAsync),

                  const SizedBox(height: 20),

                  // Legend below chart
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      villageDetailsAsync.maybeWhen(
                        data: (villages) => _LegendBadge(
                          color: const Color(0xFF22C55E),
                          label: 'Memenuhi Target (ABJ ≥ 95%)',
                          count:
                              '${villages.where((v) => v.isTargetMet).length} Desa',
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      villageDetailsAsync.maybeWhen(
                        data: (villages) => _LegendBadge(
                          color: const Color(0xFFF59E0B),
                          label: 'Waspada (85% - 94.9%)',
                          count:
                              '${villages.where((v) => v.isWarning).length} Desa',
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      villageDetailsAsync.maybeWhen(
                        data: (villages) => _LegendBadge(
                          color: const Color(0xFFEF4444),
                          label: 'Rawan Jentik (< 85%)',
                          count:
                              '${villages.where((v) => v.isDanger).length} Desa',
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Edukasi & Rekomendasi Medis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panduan Angka Bebas Jentik (Kemenkes RI)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Angka Bebas Jentik (ABJ) dihitung dari persentase rumah/tempat penampungan yang bebas jentik terhadap seluruh rumah yang diperiksa. Standar nasional bebas jentik adalah ≥ 95%. Wilayah dengan ABJ di bawah 95% memiliki risiko transmisi DBD lebih tinggi dan wajib dilakukan intervensi PSN 3M Plus serentak.',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF1E40AF),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  1. Bar Chart View (Properly clamped 0% to 105%)
  // ─────────────────────────────────────────────────────────

  Widget _buildBarChartView(
      AsyncValue<List<VillageAbjDetail>> villageDetailsAsync) {
    return villageDetailsAsync.when(
      data: (villages) {
        if (villages.isEmpty) {
          return const SizedBox(
            height: 260,
            child: Center(child: Text('Tidak ada data laporan untuk periode ini')),
          );
        }

        return SizedBox(
          height: 320,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: 105,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFF1F5F9),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  left: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  top: BorderSide.none,
                  right: BorderSide.none,
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 95,
                    color: const Color(0xFF22C55E),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                      ),
                      labelResolver: (line) => 'Target ABJ ≥ 95%',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      if (value > 100) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < villages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Transform.rotate(
                            angle: -0.45,
                            child: Text(
                              villages[idx].villageName,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response != null && response.spot != null) {
                    final idx = response.spot!.touchedBarGroupIndex;
                    if (idx >= 0 && idx < villages.length) {
                      _showVillageDetailDialog(context, villages[idx]);
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF10365F),
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final v = villages[groupIndex];
                    return BarTooltipItem(
                      '${v.villageName}\n',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'ABJ: ${v.abj.toStringAsFixed(1)}% (${v.statusCategory})\n',
                          style: GoogleFonts.outfit(
                            color: v.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Diperiksa: ${v.totalInspected} | Bebas: ${v.totalFree} | Positif: ${v.totalPositive}\n',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '👉 Klik untuk lihat rincian',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF38BDF8),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: List.generate(villages.length, (index) {
                final v = villages[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: v.abj,
                      color: v.statusColor,
                      width: 22,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  2. Trend Line View (Progression across months)
  // ─────────────────────────────────────────────────────────

  Widget _buildTrendChartView(
      AsyncValue<List<MonthlyAbjTrend>> monthlyTrendAsync,
      String yearText) {
    return monthlyTrendAsync.when(
      data: (trends) {
        return SizedBox(
          height: 320,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 105,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFF1F5F9),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  left: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  top: BorderSide.none,
                  right: BorderSide.none,
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 95,
                    color: const Color(0xFF22C55E),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                      ),
                      labelResolver: (line) => 'Target ABJ 95%',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      if (value > 100) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < trends.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            trends[idx].monthName,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10365F),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF10365F),
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      if (idx < 0 || idx >= trends.length) return null;
                      final t = trends[idx];
                      return LineTooltipItem(
                        '${t.monthName} $yearText\n',
                        GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'ABJ: ${t.abj.toStringAsFixed(1)}%\n',
                            style: GoogleFonts.outfit(
                              color: t.abj >= 95.0
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Diperiksa: ${t.inspected} | Bebas: ${t.free} | Positif: ${t.positive}',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (i) => FlSpot(i.toDouble(), trends[i].abj),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  preventCurveOverShooting: true,
                  color: const Color(0xFF0288D1),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isTarget = spot.y >= 95;
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: isTarget
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF0288D1),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0288D1).withValues(alpha: 0.25),
                        const Color(0xFF0288D1).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  3. Detailed Table View (All Villages with breakdown)
  // ─────────────────────────────────────────────────────────

  Widget _buildDetailedTableView(
      AsyncValue<List<VillageAbjDetail>> villageDetailsAsync) {
    return villageDetailsAsync.when(
      data: (villages) {
        if (villages.isEmpty) {
          return const Center(child: Text('Tidak ada data laporan'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columnSpacing: 20,
            horizontalMargin: 12,
            columns: [
              DataColumn(
                label: Text('Desa',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('Diperiksa',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('Bebas',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('Positif',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('ABJ (%)',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('House Index',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('Status Target',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
              DataColumn(
                label: Text('Aksi',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ),
            ],
            rows: villages.map((v) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: v.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.villageName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('${v.totalInspected} rumah',
                      style: GoogleFonts.outfit())),
                  DataCell(Text('${v.totalFree} rumah',
                      style: GoogleFonts.outfit(color: const Color(0xFF22C55E), fontWeight: FontWeight.w600))),
                  DataCell(Text('${v.totalPositive} rumah',
                      style: GoogleFonts.outfit(
                          color: v.totalPositive > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: v.abj / 100,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(v.statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${v.abj.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: v.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('${v.houseIndex.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: v.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        v.statusCategory,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: v.statusColor,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: Color(0xFF0288D1), size: 20),
                      tooltip: 'Lihat Rincian',
                      onPressed: () => _showVillageDetailDialog(context, v),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Detail Modal for Individual Village
  // ─────────────────────────────────────────────────────────

  void _showVillageDetailDialog(BuildContext context, VillageAbjDetail v) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: v.statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_city_rounded,
                    color: v.statusColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desa ${v.villageName}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F),
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Rincian Epidemiologi Capaian ABJ',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ABJ Gauge Meter Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: v.statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: v.statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: v.abj / 100,
                                strokeWidth: 7,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    v.statusColor),
                              ),
                              Center(
                                child: Text(
                                  '${v.abj.toStringAsFixed(0)}%',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: v.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.statusCategory,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: v.statusColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Target Nasional Kemenkes: ≥ 95.0%\nSelisih Target: ${(v.abj - 95.0).toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4 Data Metric Boxes
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMiniBox(
                          label: 'Rumah Diperiksa',
                          value: '${v.totalInspected}',
                          icon: Icons.search_rounded,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailMiniBox(
                          label: 'Bebas Jentik',
                          value: '${v.totalFree}',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMiniBox(
                          label: 'Positif Jentik',
                          value: '${v.totalPositive}',
                          icon: Icons.pest_control_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailMiniBox(
                          label: 'House Index (HI)',
                          value: '${v.houseIndex.toStringAsFixed(1)}%',
                          icon: Icons.percent_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rekomendasi Medis
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekomendasi Tindakan:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: const Color(0xFF10365F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.recommendation,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Total laporan dari kader: ${v.reportCount} laporan (${v.posyanduCount} Posyandu aktif)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Helper Widgets
// ─────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final Function(String?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 9.5, color: const Color(0xFF64748B))),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF10365F),
                fontWeight: FontWeight.bold,
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10365F),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewTabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color:
                  isActive ? const Color(0xFF10365F) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF10365F)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String label;
  final String count;

  const _LegendBadge({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
        ),
        Text(
          count,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _DetailMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailMiniBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 9.5, color: const Color(0xFF64748B))),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
