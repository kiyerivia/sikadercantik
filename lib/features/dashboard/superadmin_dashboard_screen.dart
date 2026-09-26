import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/report_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/psn_recap_dialog.dart';
import '../../shared/services/location_service.dart';
import 'dashboard_common_widgets.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const SuperAdminDashboardScreen({super.key, required this.profile});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 650 && screenWidth < 1000;
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    final reportsAsync = ref.watch(allReportsProvider);
    final locationAsync = ref.watch(currentLocationNameProvider);

    // Calculate aggregated jentik status from all reports
    final reports = reportsAsync.value ?? [];
    final positiveHouses =
        reports.fold<int>(0, (sum, r) => sum + r.housesPositive);

    final bool isSafe = positiveHouses == 0;
    final String statusLabel =
        isSafe ? 'Terpantau Aman' : 'Ada $positiveHouses Jentik';
    final Color statusColor =
        isSafe ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    final IconData statusIcon =
        isSafe ? Icons.check_circle : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section (Curved Header + Village Background + White Shape + Center Emblem + Greeting + Jentik Status)
            DashboardHeroSection(
              greetingTitle: 'Halo, Super Admin Dinkes',
              greetingSubtitle:
                  'Monitoring kegiatan Posyandu & PSN se-Kabupaten!',
              locationAsync: locationAsync,
              statusLabel: statusLabel,
              statusColor: statusColor,
              statusIcon: statusIcon,
              onStatusTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const PsnRecapDialog(),
                );
              },
            ),

            const SizedBox(height: 16),

            // Aksi Cepat Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aksi Cepat',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10365F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (screenWidth >= 900)
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_posyandu.png',
                            title: 'Kelola Wilayah',
                            subtitle: 'Puskesmas',
                            iconWidth: 44,
                            iconHeight: 40,
                            onTap: () => context.push('/locations'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_lihat_laporan.png',
                            title: 'Monitoring',
                            subtitle: 'Semua Laporan',
                            iconWidth: 48,
                            iconHeight: 38,
                            onTap: () => context.push('/superadmin-reports'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: QuickActionCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFA5D6A7), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                            title: 'Rekapitulasi',
                            subtitle: 'Grafik ABJ',
                            onTap: () => context.push('/analytics'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: QuickActionCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F5FE),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF81D4FA), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF0288D1),
                                size: 24,
                              ),
                            ),
                            title: 'Peta Sebaran',
                            subtitle: 'Kabupaten',
                            onTap: () => context.push('/map'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_posyandu.png',
                            title: 'Kelola Wilayah',
                            subtitle: 'Puskesmas',
                            iconWidth: 44,
                            iconHeight: 40,
                            onTap: () => context.push('/locations'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_lihat_laporan.png',
                            title: 'Monitoring',
                            subtitle: 'Semua Laporan',
                            iconWidth: 48,
                            iconHeight: 38,
                            onTap: () => context.push('/superadmin-reports'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFA5D6A7), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                            title: 'Rekapitulasi',
                            subtitle: 'Grafik ABJ',
                            onTap: () => context.push('/analytics'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F5FE),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF81D4FA), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF0288D1),
                                size: 24,
                              ),
                            ),
                            title: 'Peta Sebaran',
                            subtitle: 'Kabupaten',
                            onTap: () => context.push('/map'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Statistik Laporan Se-Kabupaten
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: reportsAsync.when(
                data: (reports) {
                  final total = reports.length;
                  final verified =
                      reports.where((r) => r.status == 'verified').length;
                  final waiting =
                      reports.where((r) => r.status == 'submitted').length;
                  final intervention = reports
                      .where((r) =>
                          r.status == 'need_intervention' ||
                          r.status == 'draft')
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Laporan Se-Kabupaten',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10365F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DashboardStatItem(
                                        val: '$total',
                                        label: 'Total Laporan',
                                        icon: Icons.description_rounded,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DashboardStatItem(
                                        val: '$verified',
                                        label: 'Terverifikasi',
                                        icon: Icons.check_circle_rounded,
                                        color: const Color(0xFF0288D1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DashboardStatItem(
                                        val: '$waiting',
                                        label: 'Menunggu',
                                        icon: Icons.schedule_rounded,
                                        color: const Color(0xFFF57C00),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DashboardStatItem(
                                        val: '$intervention',
                                        label: 'Perlu Perbaikan',
                                        icon: Icons.warning_amber_rounded,
                                        color: const Color(0xFFD32F2F),
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
                                  child: DashboardStatItem(
                                    val: '$total',
                                    label: 'Total Laporan',
                                    icon: Icons.description_rounded,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatItem(
                                    val: '$verified',
                                    label: 'Terverifikasi',
                                    icon: Icons.check_circle_rounded,
                                    color: const Color(0xFF0288D1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatItem(
                                    val: '$waiting',
                                    label: 'Menunggu',
                                    icon: Icons.schedule_rounded,
                                    color: const Color(0xFFF57C00),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatItem(
                                    val: '$intervention',
                                    label: 'Perlu Perbaikan',
                                    icon: Icons.warning_amber_rounded,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Text(
                  'Gagal memuat rekap: $err',
                  style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diagram ABJ
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: AbjTrendChartCard(allReportsAsync: reportsAsync),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
