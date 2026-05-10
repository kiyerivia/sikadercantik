import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/providers/admin_providers.dart';
import '../../shared/widgets/admin_nav_bar.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final abjByVillageAsync = ref.watch(abjByVillageProvider);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);

    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar (As seen in image)
          if (MediaQuery.of(context).size.width > 900)
            const _Sidebar(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Nav Bar (The horizontal one we added previously for consistency)
                  const AdminNavBar(activePage: 'analytics'),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Dashboard ABJ',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau capaian Angka Bebas Jentik (ABJ) berdasarkan data laporan PSN kader.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Pilih Puskesmas',
                          value: 'Puskesmas Gumelar',
                          icon: Icons.local_hospital_outlined,
                          onChanged: (val) {},
                          items: const ['Puskesmas Gumelar'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Pilih Bulan',
                          value: monthNames[selectedMonth - 1],
                          icon: Icons.calendar_today_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(selectedMonthProvider.notifier).state = monthNames.indexOf(val) + 1;
                            }
                          },
                          items: monthNames,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Pilih Tahun',
                          value: selectedYear.toString(),
                          icon: Icons.calendar_month_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(selectedYearProvider.notifier).state = int.parse(val);
                            }
                          },
                          items: List.generate(5, (i) => (DateTime.now().year - 2 + i).toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart Section
                  _ChartCard(
                    monthName: monthNames[selectedMonth - 1],
                    year: selectedYear,
                    data: abjByVillageAsync,
                  ),
                  const SizedBox(height: 24),

                  // Stats Section
                  _StatsSection(
                    monthName: monthNames[selectedMonth - 1],
                    year: selectedYear,
                    data: dashboardStatsAsync,
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data diperbarui secara otomatis berdasarkan laporan PSN kader. Pastikan intervensi dilakukan untuk meningkatkan capaian ABJ.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _SidebarItem(label: 'Beranda', icon: Icons.home_outlined, isActive: false),
          _SidebarItem(label: 'Data Monitoring Laporan PSN', icon: Icons.assignment_outlined, isActive: false),
          _SidebarItem(label: 'Dashboard ABJ', icon: Icons.bar_chart_outlined, isActive: true),
          _SidebarItem(label: 'Manajemen Wilayah', icon: Icons.map_outlined, isActive: false),
          const Spacer(),
          _SidebarItem(label: 'Keluar', icon: Icons.logout, isActive: false, isDestructive: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDestructive;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: isDestructive ? Colors.red : (isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B)), size: 20),
          title: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isDestructive ? Colors.red : (isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B)),
            ),
          ),
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B), fontWeight: FontWeight.bold),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String monthName;
  final int year;
  final AsyncValue<Map<String, double>> data;

  const _ChartCard({required this.monthName, required this.year, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capaian ABJ per Desa',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              Text('Bulan $monthName $year', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: data.when(
              data: (map) {
                if (map.isEmpty) return const Center(child: Text('Tidak ada data'));
                
                final villages = map.keys.toList();
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < villages.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    villages[value.toInt()],
                                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 60,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(villages.length, (index) {
                      final abj = map[villages[index]]!;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: abj,
                            color: abj >= 90 ? const Color(0xFF22C55E) : (abj >= 80 ? const Color(0xFF3B82F6) : const Color(0xFFF97316)),
                            width: 16,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 90,
                          color: const Color(0xFF22C55E).withOpacity(0.5),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF22C55E), fontWeight: FontWeight.bold),
                            labelResolver: (line) => 'Target ABJ ≥ 90%',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _LegendItem(color: const Color(0xFF22C55E), label: 'Desa dengan ABJ ≥ 90%', count: data.maybeWhen(data: (m) => m.values.where((v) => v >= 90).length, orElse: () => 0)),
              const SizedBox(width: 24),
              _LegendItem(color: const Color(0xFFF97316), label: 'Desa dengan ABJ < 90%', count: data.maybeWhen(data: (m) => m.values.where((v) => v < 90).length, orElse: () => 0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            Text('$count Desa', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String monthName;
  final int year;
  final AsyncValue<Map<String, dynamic>> data;

  const _StatsSection({required this.monthName, required this.year, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan PSN Kader',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              Text('Bulan $monthName $year', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 24),
          data.when(
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.assignment_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        label: 'Jumlah Laporan PSN',
                        value: stats['totalReports'].toString(),
                        subLabel: 'Total laporan PSN yang dikirim oleh kader',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF22C55E),
                        bgColor: const Color(0xFFF0FDF4),
                        label: 'Sudah Intervensi',
                        value: stats['intervened'].toString(),
                        subLabel: 'Laporan yang sudah dilakukan intervensi petugas',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _InterventionProgress(rate: stats['interventionRate'] as double),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final String subLabel;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                Text(subLabel, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterventionProgress extends StatelessWidget {
  final double rate;
  const _InterventionProgress({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tingkat Intervensi', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                Text('(Sudah Intervensi / Total Laporan)', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
              ],
            ),
            Text('${rate.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: rate / 100,
            minHeight: 12,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
          ),
        ),
      ],
    );
  }
}
