import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  final Profile profile;
  const SuperAdminDashboardScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005B9F), // Deeper blue to match image
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.white),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 18,
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
                        style: TextStyle(color: Color(0xFF82E0AA)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'SUPER ADMIN\nDINAS KESEHATAN KABUPATEN',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
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
              child: Icon(Icons.person, color: Color(0xFF005B9F), size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              height: 240,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F4FA),
                image: DecorationImage(
                  image: AssetImage('assets/images/superadmin_bg.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 24,
                  top: 40,
                  right: 120, // Space for the character
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF003049),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                      ),
                    ),
                    Text(
                      'Super Admin',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF005B9F),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003049).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dinas Kesehatan Kabupaten',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu Section
            Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILIH MENU',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF003049),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _MenuCard(
                    title: 'Dashboard Monitoring',
                    subtitle: 'Pantau ringkasan pelaksanaan PSN, capaian ABJ, dan kinerja puskesmas secara keseluruhan.',
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF1976D2), // Blue
                    bgColor: const Color(0xFFE3F2FD),
                    onTap: () => context.push('/analytics'),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'Data PSN & Intervensi',
                    subtitle: 'Lihat dan kelola data laporan PSN, rumah positif jentik, dan status intervensi petugas.',
                    icon: Icons.assignment_rounded,
                    iconColor: const Color(0xFF388E3C), // Green
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () => context.push('/history'),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'Manajemen Wilayah & User',
                    subtitle: 'Kelola data wilayah kerja, puskesmas, posyandu, RT/RW, serta akun admin dan kader.',
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF7B1FA2), // Purple
                    bgColor: const Color(0xFFF3E5F5),
                    onTap: () => context.push('/locations'), // Will go to locations management
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'Rekap & Laporan PSN',
                    subtitle: 'Unduh dan cetak rekap laporan PSN, capaian ABJ, dan laporan lainnya dalam format PDF atau Excel.',
                    icon: Icons.description_rounded,
                    iconColor: const Color(0xFFF57C00), // Orange
                    bgColor: const Color(0xFFFFF3E0),
                    onTap: () => context.push('/superadmin-reports'), // Action for report download
                  ),
                  const SizedBox(height: 24),
                  const _InfoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor, width: 2), // Light tinted border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Solid colored rounded square for icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF003049),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF003049).withOpacity(0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: iconColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF003049),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data diperbarui setiap 1 jam sekali.\nPastikan penginputan data oleh kader dilakukan secara rutin.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF003049).withOpacity(0.7),
                    fontSize: 12,
                    height: 1.4,
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
