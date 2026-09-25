import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/domain/models.dart';
import 'superadmin_dashboard_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/user_profile_menu.dart';
import '../../shared/widgets/psn_recap_dialog.dart';
import '../../shared/services/location_service.dart';

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
        } else if (roleClean == 'admin' || (roleClean.startsWith('admin') && !roleClean.startsWith('superadmin'))) {
          return _AdminDashboard(profile: profile);
        } else if (roleClean == 'superadmin' || roleClean.startsWith('superadmin')) {
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

class _CurvedHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const _CurvedHeaderBar();

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final horizontalPadding = isDesktop ? 32.0 : 20.0;

    return Container(
      width: double.infinity,
      color: const Color(0xFF012857),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/header.png',
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
              ),
              Positioned(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_dinas_banyumas.png',
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SiKader Cantik',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NotificationBadge(),
                        SizedBox(width: 12),
                        UserProfileMenu(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
      appBar: const _CurvedHeaderBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1, 2, 3, 4, 5: Hero Section (Adaptive for Windows & HP)
            _buildHeroSection(
              context,
              screenWidth,
              horizontalPadding,
              locationAsync,
              statusLabel,
              statusColor,
              statusIcon,
            ),

            const SizedBox(height: 24),

            // 7: Aksi Cepat Section
            _buildQuickActionsSection(context, horizontalPadding),

            const SizedBox(height: 20),

            // Informasi Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const _InfoCard(
                text:
                    'Pastikan data yang Anda inputkan sudah benar sebelum dikirim.',
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingContent(
    AsyncValue<String> locationAsync, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Halo, Kader Cantik',
          style: GoogleFonts.outfit(
            color: const Color(0xFF10365F),
            fontSize: isDesktop ? 17 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Semangat selalu untuk kegiatan Posyandu\ndan PSN di lingkungan kita!',
          style: GoogleFonts.outfit(
            color: const Color(0xFF4A5568),
            fontSize: isDesktop ? 11.5 : 9.5,
            height: 1.25,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: const Color(0xFF10365F),
              size: isDesktop ? 15 : 13,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: locationAsync.when(
                data: (loc) => Text(
                  loc,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: isDesktop ? 11 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => Text(
                  'Mencari lokasi akurat...',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF718096),
                    fontSize: isDesktop ? 11 : 10,
                  ),
                ),
                error: (_, _) => Text(
                  LocationService.defaultLocation,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: isDesktop ? 11 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJentikButtonContent(
    BuildContext context,
    String statusLabel,
    Color statusColor,
    IconData statusIcon, {
    bool isDesktop = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => const PsnRecapDialog(),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 14 : 4,
            vertical: isDesktop ? 12 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 6 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border:
                      Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
                ),
                child: Image.asset(
                  'assets/images/icon_mosquito_blue.png',
                  width: isDesktop ? 34 : 26,
                  height: isDesktop ? 34 : 26,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : 5),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jentik Nyamuk',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10365F),
                        fontSize: isDesktop ? 14.5 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontSize: isDesktop ? 13 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: isDesktop ? 17 : 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 4 : 2),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF0288D1),
                size: isDesktop ? 22 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    double screenWidth,
    double horizontalPadding,
    AsyncValue<String> locationAsync,
    String statusLabel,
    Color statusColor,
    IconData statusIcon,
  ) {
    if (screenWidth < 768) {
      // ── HP / MOBILE MODE (Proportionally fitted, zero overflow) ──
      const double baseWidth = 620.0;
      const double heroHeight = 280.0;
      final scale = screenWidth / baseWidth;

      return SizedBox(
        width: screenWidth,
        height: heroHeight * scale,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: baseWidth,
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 215,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/background_dashboard.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 6,
                  right: 6,
                  height: 128,
                  child: Image.asset(
                    'assets/images/shape_white.png',
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 12,
                  width: 200,
                  height: 104,
                  child: _buildGreetingContent(locationAsync, isDesktop: false),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  width: 220,
                  height: 100,
                  child: _buildJentikButtonContent(
                    context,
                    statusLabel,
                    statusColor,
                    statusIcon,
                    isDesktop: false,
                  ),
                ),
                Positioned(
                  top: 76,
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_sikadercantik_new.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── WINDOWS / DESKTOP MODE (Full width adaptation) ──
    const double heroHeight = 310.0;

    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Layer 1: Background spans 100% full width
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/background_dashboard.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // Layer 2: Shape White spans horizontally full width with horizontalPadding
          Positioned(
            bottom: 0,
            left: horizontalPadding,
            right: horizontalPadding,
            height: 138,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/shape_white.png',
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTRB(80, 30, 597, 118),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Greeting Content
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildGreetingContent(
                              locationAsync,
                              isDesktop: true,
                            ),
                          ),
                        ),
                        // Center reserved slot for Logo
                        const SizedBox(width: 230),
                        // Right Jentik Button
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: _buildJentikButtonContent(
                                context,
                                statusLabel,
                                statusColor,
                                statusIcon,
                                isDesktop: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Layer 3: Center Emblem Logo
          Positioned(
            top: 65,
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo_sikadercantik_new.png',
                width: 230,
                height: 230,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Aksi Cepat',
            style: GoogleFonts.outfit(
              color: const Color(0xFF10365F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          // Two Action Cards with new icons (Icon on top, text below)
          Row(
            children: [
              // Card 1: Input Laporan Jentik
              Expanded(
                child: _QuickActionCard(
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
                child: _QuickActionCard(
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
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double iconWidth;
  final double iconHeight;

  const _QuickActionCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconWidth = 40,
    this.iconHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F4FD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBCE0FD), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    width: iconWidth,
                    height: iconHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10365F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE65100),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final horizontalPadding = isDesktop
        ? (screenWidth - 1000) / 2
        : (isTablet ? (screenWidth - 680) / 2 : 20.0);
    final heroHeight = isDesktop ? 340.0 : (isTablet ? 320.0 : 280.0);
    final reportsAsync = ref.watch(allReportsProvider);
    final locationAsync = ref.watch(currentLocationNameProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const _CurvedHeaderBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: heroHeight,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/admin_dashboard_illustration.png',
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang,',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Admin Puskesmas',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryGreen,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Puskesmas Gumelar',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textDark.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryBlue,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                locationAsync.when(
                                  data: (loc) => Text(
                                    loc,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textDark.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  loading: () => Text(
                                    'Mencari lokasi...',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textDark.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                  error: (_, _) => Text(
                                    LocationService.defaultLocation,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textDark.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.eco,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Menu Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DASHBOARD ADMIN',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Peta Sebaran',
                            subtitle: 'Pantau pemetaan jentik\ndi wilayah kerja',
                            icon: Icons.map_rounded,
                            iconColor: AppTheme.primaryGreen,
                            onTap: () => context.push('/map'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Verifikasi Laporan',
                            subtitle: 'Verifikasi laporan\nPSN dari kader',
                            icon: Icons.fact_check,
                            iconColor: const Color(0xFF81C784),
                            onTap: () => context.push('/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Rekapitulasi',
                            subtitle: 'Lihat rekapitulasi\nlaporan PSN',
                            icon: Icons.bar_chart,
                            iconColor: AppTheme.primaryBlue,
                            onTap: () => context.push('/analytics'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Info & Rekap PSN',
                            subtitle: 'Kelola informasi\ndan rekapitulasi',
                            icon: Icons.campaign,
                            iconColor: AppTheme.secondaryBlue,
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
                          child: _MenuGridItem(
                            title: 'Peta Sebaran',
                            subtitle: 'Pantau pemetaan jentik\ndi wilayah kerja',
                            icon: Icons.map_rounded,
                            iconColor: AppTheme.primaryGreen,
                            onTap: () => context.push('/map'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Verifikasi Laporan',
                            subtitle: 'Verifikasi laporan\nPSN dari kader',
                            icon: Icons.fact_check,
                            iconColor: const Color(0xFF81C784),
                            onTap: () => context.push('/history'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Rekapitulasi',
                            subtitle: 'Lihat rekapitulasi\nlaporan PSN',
                            icon: Icons.bar_chart,
                            iconColor: AppTheme.primaryBlue,
                            onTap: () => context.push('/analytics'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MenuGridItem(
                            title: 'Info & Rekap PSN',
                            subtitle: 'Kelola informasi\ndan rekapitulasi',
                            icon: Icons.campaign,
                            iconColor: AppTheme.secondaryBlue,
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
                  const SizedBox(height: 24),

                  // Ringkasan Laporan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ringkasan Laporan',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Semua Waktu',
                              style: GoogleFonts.outfit(fontSize: 12),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  reportsAsync.when(
                    data: (reports) {
                      final total = reports.length;
                      final verified = reports.where((r) => r.status == 'verified').length;
                      final waiting = reports.where((r) => r.status == 'submitted').length;
                      final intervention = reports.where((r) => r.status == 'need_intervention' || r.status == 'draft').length;

                      if (screenWidth < 500) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _StatItem(
                                    val: '$total',
                                    label: 'Total Laporan',
                                    icon: Icons.description,
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _StatItem(
                                    val: '$verified',
                                    label: 'Terverifikasi',
                                    icon: Icons.check_circle,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatItem(
                                    val: '$waiting',
                                    label: 'Menunggu',
                                    icon: Icons.schedule,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _StatItem(
                                    val: '$intervention',
                                    label: 'Perlu Perbaikan',
                                    icon: Icons.warning_amber_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(
                              val: '$total',
                              label: 'Total Laporan',
                              icon: Icons.description,
                              color: Colors.green,
                            ),
                            _StatItem(
                              val: '$verified',
                              label: 'Terverifikasi',
                              icon: Icons.check_circle,
                              color: Colors.blue,
                            ),
                            _StatItem(
                              val: '$waiting',
                              label: 'Menunggu',
                              icon: Icons.schedule,
                              color: Colors.orange,
                            ),
                            _StatItem(
                              val: '$intervention',
                              label: 'Perlu Perbaikan',
                              icon: Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                          ],
                        );
                      }
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'Gagal memuat rekap: $err',
                      style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _MenuGridItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuGridItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textDark.withValues(alpha: 0.6),
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          Icon(Icons.info_outline, color: AppTheme.secondaryBlue, size: 24),
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

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.val,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: GoogleFonts.outfit(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.textDark.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
