import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/domain/models.dart';
import 'superadmin_dashboard_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/user_profile_menu.dart';

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

        if (profile.role == 'kader') {
          return _KaderDashboard(profile: profile);
        } else if (profile.role == 'admin') {
          return _AdminDashboard(profile: profile);
        } else if (profile.role == 'superadmin') {
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

Widget _buildAppBarTitle() {
  return Image.asset(
    'assets/images/kader/sikadercantik_header.png',
    height: 40,
    fit: BoxFit.contain,
  );
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: _buildAppBarTitle(),
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 12),
          const UserProfileMenu(),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/kader/kader_dashboard.jpg',
                          ),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                  'Kader PSN',
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
                                    color: AppTheme.textDark.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.eco,
                              color: AppTheme.primaryGreen.withOpacity(0.2),
                              size: 48,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60), // Space for floating card
                // Menu Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PILIH MENU',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MenuCardFull(
                        title: 'Input Laporan PSN (Baru)',
                        subtitle: 'Klik untuk membuat laporan PSN baru',
                        icon: Icons.note_add_rounded,
                        iconColor: AppTheme.primaryGreen,
                        bgColor: const Color(0xFFF1F8EE),
                        onTap: () => context.push('/report'),
                      ),
                      const SizedBox(height: 12),
                      _MenuCardFull(
                        title: 'Riwayat Laporan PSN',
                        subtitle:
                            'Lihat dan kelola laporan PSN yang sudah dikirim',
                        icon: Icons.history_rounded,
                        iconColor: AppTheme.secondaryBlue,
                        bgColor: const Color(0xFFEBF8FE),
                        onTap: () => context.push('/history'),
                      ),
                      const SizedBox(height: 12),
                      const _InfoCard(
                        text:
                            'Pastikan data yang Anda inputkan sudah benar sebelum dikirim.',
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: _buildAppBarTitle(),
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 12),
          const UserProfileMenu(),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
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
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                    color: AppTheme.textDark.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.eco,
                              color: AppTheme.primaryGreen.withOpacity(0.2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      Row(
                        children: [
                          Expanded(
                            child: _MenuGridItem(
                              title: 'Kelola Kader',
                              subtitle: 'Kelola data dan\nakun kader',
                              icon: Icons.people_alt,
                              iconColor: AppTheme.primaryGreen,
                              onTap: () {},
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
                              title: 'Info & Pengumuman',
                              subtitle: 'Kelola informasi\ndan pengumuman',
                              icon: Icons.campaign,
                              iconColor: AppTheme.secondaryBlue,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
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
                                  'Bulan Ini',
                                  style: GoogleFonts.outfit(fontSize: 12),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatItem(
                            val: '128',
                            label: 'Total Laporan',
                            icon: Icons.description,
                            color: Colors.green,
                          ),
                          _StatItem(
                            val: '112',
                            label: 'Terverifikasi',
                            icon: Icons.check_circle,
                            color: Colors.blue,
                          ),
                          _StatItem(
                            val: '16',
                            label: 'Menunggu',
                            icon: Icons.schedule,
                            color: Colors.orange,
                          ),
                          _StatItem(
                            val: '0',
                            label: 'Ditolak',
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCardFull extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _MenuCardFull({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textDark.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: 24),
            ],
          ),
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
                        color: AppTheme.textDark.withOpacity(0.6),
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
        border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.2)),
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
                    color: AppTheme.textDark.withOpacity(0.7),
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
                color: AppTheme.textDark.withOpacity(0.6),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
