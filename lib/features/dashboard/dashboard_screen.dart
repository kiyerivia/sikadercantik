import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/domain/models.dart';
import 'superadmin_dashboard_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/psn_recap_dialog.dart';
import '../../shared/services/location_service.dart';
import '../broadcast/broadcast_repository.dart';
import 'dashboard_common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profil tidak ditemukan')),
          );
        }

        final roleClean = profile.role.toLowerCase();
        if (roleClean == 'kader' || roleClean.startsWith('kader')) {
          return _KaderDashboard(profile: profile);
        } else if (roleClean == 'admin' ||
            (roleClean.startsWith('admin') &&
                !roleClean.startsWith('superadmin'))) {
          return _AdminDashboard(profile: profile);
        } else if (roleClean == 'superadmin' ||
            roleClean.startsWith('superadmin')) {
          return SuperAdminDashboardScreen(profile: profile);
        }

        return Scaffold(
          body: Center(child: Text('Role tidak valid: ${profile.role}')),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  KADER DASHBOARD
// ─────────────────────────────────────────────────────────

class _KaderDashboard extends ConsumerStatefulWidget {
  final Profile profile;
  const _KaderDashboard({required this.profile});

  @override
  ConsumerState<_KaderDashboard> createState() => _KaderDashboardState();
}

class _KaderDashboardState extends ConsumerState<_KaderDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 650 && screenWidth < 1000;
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    final locationAsync = ref.watch(currentLocationNameProvider);
    final myReportsAsync = ref.watch(myReportsProvider);
    final allReportsAsync = ref.watch(allReportsProvider);
    final activeAnnouncements = ref.watch(activeAnnouncementsProvider);

    // Calculate jentik status from real data
    final reports = myReportsAsync.value ?? [];
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
              greetingTitle: 'Halo, Kader Cantik',
              greetingSubtitle:
                  'Semangat kegiatan Posyandu\n& PSN di lingkungan kita!',
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

            if (activeAnnouncements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildDinkesInstructionBanner(
                    context, activeAnnouncements.first),
              ),
            ],

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
                  Row(
                    children: [
                      // Card 1: Input Laporan Jentik
                      Expanded(
                        child: QuickActionCard(
                          iconAsset: 'assets/images/icon_tulis_laporan.png',
                          title: 'Input Laporan',
                          subtitle: 'Jentik',
                          iconWidth: 40,
                          iconHeight: 40,
                          onTap: () => context.push('/report'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Card 2: Lihat Hasil Laporan
                      Expanded(
                        child: QuickActionCard(
                          iconAsset: 'assets/images/icon_lihat_laporan.png',
                          title: 'Lihat Hasil',
                          subtitle: 'Laporan',
                          iconWidth: 48,
                          iconHeight: 38,
                          onTap: () => context.push('/history'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Informasi Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const _InfoCard(
                text:
                    'Pastikan data yang Anda inputkan sudah benar sebelum dikirim.',
              ),
            ),

            const SizedBox(height: 12),

            // Diagram Angka Bebas Jentik dari Semua Laporan
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: AbjTrendChartCard(allReportsAsync: allReportsAsync),
            ),

            const SizedBox(height: 14),

            // Diagram Batang Rincian Pemeriksaan Jentik
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: KaderDetailedBarChartCard(allReportsAsync: allReportsAsync),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

Widget _buildDinkesInstructionBanner(
    BuildContext context, BroadcastAnnouncement item) {
    Color bannerBg = const Color(0xFF881337);
    Color bannerEnd = const Color(0xFFBE123C);
    if (item.urgency == 'penting') {
      bannerBg = const Color(0xFF9A3412);
      bannerEnd = const Color(0xFFEA580C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bannerBg, bannerEnd]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bannerEnd.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INSTRUKSI RESMI DINKES',
                        style: GoogleFonts.outfit(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: bannerBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Sasaran: ${item.targetVillageName ?? "Semua"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: bannerBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final isDesktop = MediaQuery.of(context).size.width >= 600;
              Widget content(BuildContext ctx) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign_rounded,
                            color: Color(0xFFE11D48), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Instruksi Resmi Dinas Kesehatan',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(item.title,
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item.content,
                        style: GoogleFonts.outfit(
                            fontSize: 13, height: 1.45)),
                    const SizedBox(height: 16),
                    Text('Diterbitkan oleh: ${item.authorName}',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10365F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Tutup Arahan',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );

              if (isDesktop) {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: content(ctx),
                    ),
                  ),
                );
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: content(ctx),
                    ),
                  ),
                );
              }
            },
            child: Text('Lihat Arahan',
                style: GoogleFonts.outfit(
                    fontSize: 10.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

// ─────────────────────────────────────────────────────────
//  ADMIN PUSKESMAS DASHBOARD
// ─────────────────────────────────────────────────────────

class _AdminDashboard extends ConsumerStatefulWidget {
  final Profile profile;
  const _AdminDashboard({required this.profile});

  @override
  ConsumerState<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<_AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 650 && screenWidth < 1000;
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    final reportsAsync = ref.watch(allReportsProvider);
    final locationAsync = ref.watch(currentLocationNameProvider);
    final activeAnnouncements = ref.watch(activeAnnouncementsProvider);

    // Calculate aggregated jentik status from real data
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
              greetingTitle: 'Halo, Admin Puskesmas',
              greetingSubtitle:
                  'Pantau & verifikasi kegiatan Posyandu & PSN!',
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

            if (activeAnnouncements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildDinkesInstructionBanner(
                    context, activeAnnouncements.first),
              ),
            ],

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
                            subtitle: 'Jentik',
                            onTap: () => context.push('/map'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_lihat_laporan.png',
                            title: 'Verifikasi',
                            subtitle: 'Laporan PSN',
                            iconWidth: 48,
                            iconHeight: 38,
                            onTap: () => context.push('/history'),
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
                                color: const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFFFCC80), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Color(0xFFEF6C00),
                                size: 24,
                              ),
                            ),
                            title: 'Info & Edukasi',
                            subtitle: 'Rekap PSN',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const PsnRecapDialog(),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
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
                            subtitle: 'Jentik',
                            onTap: () => context.push('/map'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            iconAsset: 'assets/images/icon_lihat_laporan.png',
                            title: 'Verifikasi',
                            subtitle: 'Laporan PSN',
                            iconWidth: 48,
                            iconHeight: 38,
                            onTap: () => context.push('/history'),
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
                                color: const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFFFCC80), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Color(0xFFEF6C00),
                                size: 24,
                              ),
                            ),
                            title: 'Info & Edukasi',
                            subtitle: 'Rekap PSN',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const PsnRecapDialog(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ringkasan Laporan Section
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
                        'Ringkasan Laporan',
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

            // Diagram Capaian ABJ
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: AbjTrendChartCard(allReportsAsync: reportsAsync),
            ),

            const SizedBox(height: 14),

            // Diagram Batang Rincian Pemeriksaan Jentik (Semua Tahun)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: DetailedBarChartCard(allReportsAsync: reportsAsync),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  INFORMASI CARD
// ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.secondaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
