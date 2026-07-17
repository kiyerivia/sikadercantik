import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/report_providers.dart';
import '../domain/models.dart';

class PsnRecapDialog extends ConsumerWidget {
  const PsnRecapDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: reportsAsync.when(
                data: (reports) => _buildContent(context, reports),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(color: Color(0xFF10365F)),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Gagal memuat data rekap: $err',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10365F), Color(0xFF0D6E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekap Keseluruhan Data PSN',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pemberantasan Sarang Nyamuk - Puskesmas Gumelar',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Report> reports) {
    int totalInspected = 0;
    int totalPositive = 0;
    final Map<String, int> villageInspected = {};
    final Map<String, int> villagePositive = {};

    for (var r in reports) {
      totalInspected += r.housesInspected;
      totalPositive += r.housesPositive;
      final vName = r.villageName?.trim() ?? 'Wilayah Lainnya';
      if (vName.isNotEmpty) {
        villageInspected[vName] = (villageInspected[vName] ?? 0) + r.housesInspected;
        villagePositive[vName] = (villagePositive[vName] ?? 0) + r.housesPositive;
      }
    }

    final int totalNegative = totalInspected - totalPositive;
    final double overallAbj = totalInspected > 0
        ? ((totalInspected - totalPositive) / totalInspected) * 100
        : 100.0;
    final bool isTargetMet = overallAbj >= 95.0;

    final sortedVillages = villageInspected.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero ABJ Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTargetMet
                    ? [const Color(0xFF1E8449), const Color(0xFF27AE60)]
                    : [const Color(0xFFD35400), const Color(0xFFE67E22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isTargetMet ? const Color(0xFF27AE60) : const Color(0xFFE67E22))
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Angka Bebas Jentik (ABJ) Nasional',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${overallAbj.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTargetMet ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTargetMet
                                  ? 'Target Kemenkes Terpenuhi (≥ 95%)'
                                  : 'Di Bawah Target Kemenkes (< 95%)',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTargetMet ? Icons.verified : Icons.analytics_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Grid Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetricCard(
                    width: cardWidth,
                    label: 'Total Laporan',
                    value: '${reports.length}',
                    unit: 'Laporan',
                    icon: Icons.assignment_turned_in,
                    color: const Color(0xFF2980B9),
                  ),
                  _buildMetricCard(
                    width: cardWidth,
                    label: 'Rumah Diperiksa',
                    value: '$totalInspected',
                    unit: 'Rumah',
                    icon: Icons.home_work_outlined,
                    color: const Color(0xFF3F51B5),
                  ),
                  _buildMetricCard(
                    width: cardWidth,
                    label: 'Positif Jentik',
                    value: '$totalPositive',
                    unit: 'Rumah',
                    icon: Icons.bug_report_outlined,
                    color: const Color(0xFFE74C3C),
                  ),
                  _buildMetricCard(
                    width: cardWidth,
                    label: 'Bebas Jentik',
                    value: '$totalNegative',
                    unit: 'Rumah',
                    icon: Icons.verified_user_outlined,
                    color: const Color(0xFF27AE60),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Section Title
          Text(
            'Breakdown ABJ Per Desa',
            style: GoogleFonts.outfit(
              color: const Color(0xFF10365F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Persentase rumah bebas jentik di wilayah kerja Puskesmas Gumelar',
            style: GoogleFonts.outfit(
              color: Colors.blueGrey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          // Village List
          if (sortedVillages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Belum ada data pemeriksaan desa.',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedVillages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final village = sortedVillages[index];
                final vInspected = villageInspected[village] ?? 0;
                final vPositive = villagePositive[village] ?? 0;
                final vAbj = vInspected > 0
                    ? ((vInspected - vPositive) / vInspected) * 100
                    : 100.0;
                final bool vTargetMet = vAbj >= 95.0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              village,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10365F),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (vTargetMet ? const Color(0xFF27AE60) : const Color(0xFFE67E22))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${vAbj.toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: vTargetMet
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFFD35400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$vInspected Diperiksa | $vPositive Positif Jentik',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                          Text(
                            vTargetMet ? 'Aman' : 'Waspada',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: vTargetMet ? Colors.green[700] : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vAbj / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            vTargetMet ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.blueGrey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10365F),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.outfit(
                        color: Colors.blueGrey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: Text(
              'Tutup Info',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10365F),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
