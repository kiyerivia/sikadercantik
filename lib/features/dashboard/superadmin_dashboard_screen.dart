import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/user_profile_menu.dart';

Widget _buildAppBarTitle() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text('Si ', style: GoogleFonts.caveat(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      Text('KADER ', style: GoogleFonts.outfit(color: AppTheme.primaryGreen, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1)),
      Text('Cantik ', style: GoogleFonts.caveat(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
    ],
  );
}

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const SuperAdminDashboardScreen({super.key, required this.profile});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {

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
          const SizedBox(width: 8),
          const UserProfileMenu(),
          const SizedBox(width: 16),
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
                          image: AssetImage('assets/images/superadmin_dashboard_illustration.png.png'),
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
                                  'Superadmin',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dinas Kesehatan',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textDark.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.eco, color: AppTheme.primaryGreen.withOpacity(0.2), size: 48),
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
                        'DASHBOARD SUPERADMIN',
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
                              title: 'Kelola Wilayah',
                              subtitle: 'Kelola data wilayah\ndan puskesmas',
                              icon: Icons.location_on,
                              iconColor: AppTheme.primaryBlue,
                              onTap: () => context.push('/locations'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuGridItem(
                              title: 'Kelola Pengguna',
                              subtitle: 'Kelola admin dan\nsuperadmin',
                              icon: Icons.people_alt,
                              iconColor: AppTheme.secondaryBlue,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuGridItem(
                              title: 'Monitoring Laporan',
                              subtitle: 'Monitoring laporan\nseluruh wilayah',
                              icon: Icons.bar_chart,
                              iconColor: AppTheme.primaryBlue,
                              onTap: () => context.push('/analytics'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuGridItem(
                              title: 'Pengaturan Sistem',
                              subtitle: 'Pengaturan aplikasi\ndan sistem',
                              icon: Icons.settings,
                              iconColor: AppTheme.primaryBlue,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Statistik Nasional
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Statistik Nasional',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Text('Tahun Ini', style: GoogleFonts.outfit(fontSize: 12)),
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
                          _StatItem(val: '12.456', label: 'Total Laporan', icon: Icons.description, color: Colors.green),
                          _StatItem(val: '10.987', label: 'Terverifikasi', icon: Icons.check_circle, color: Colors.blue),
                          _StatItem(val: '1.234', label: 'Menunggu', icon: Icons.schedule, color: Colors.orange),
                          _StatItem(val: '235', label: 'Ditolak', icon: Icons.cancel, color: Colors.red),
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

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({required this.val, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
