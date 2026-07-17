import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import '../domain/models.dart';
import '../../core/theme/app_theme.dart';
import 'user_profile_menu.dart';
import 'psn_recap_dialog.dart';
import '../../features/dashboard/map_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    ref.watch(posyanduListProvider);
    final routerState = GoRouterState.of(context);
    final String location = routerState.matchedLocation;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return child;
        }

        final roleClean = profile.role.toLowerCase();

        if (roleClean == 'kader' || roleClean.startsWith('kader')) {
          return _buildKaderShell(context, ref, profile, location);
        } else if (roleClean == 'admin' || (roleClean.startsWith('admin') && !roleClean.startsWith('superadmin'))) {
          return _buildAdminShell(context, ref, profile, location);
        } else if (roleClean == 'superadmin' || roleClean.startsWith('superadmin')) {
          return _buildSuperAdminShell(context, ref, profile, location);
        }

        return child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref, Profile profile) {
    final posyandusAsync = ref.read(posyanduListProvider);
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final email = currentUser?.email ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => ProfileDetailDialog(
        profile: profile,
        email: email,
        posyandus: posyandusAsync.value,
        onAvatarUpdated: () => ref.invalidate(userProfileProvider),
      ),
    );
  }

  void _showPsnRecapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const PsnRecapDialog(),
    );
  }

  Widget _buildKaderShell(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String location,
  ) {
    int currentIndex = 0;
    if (location == '/') {
      currentIndex = 0;
    } else if (location.startsWith('/history') || location.startsWith('/report')) {
      currentIndex = 1;
    } else if (location.startsWith('/info')) {
      currentIndex = 2;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/history');
          } else if (index == 2) {
            _showPsnRecapDialog(context);
          } else if (index == 3) {
            _showProfileDialog(context, ref, profile);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryBlue,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Informasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildAdminShell(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String location,
  ) {
    int currentIndex = 0;
    if (location == '/') {
      currentIndex = 0;
    } else if (location.startsWith('/history') || location.startsWith('/report-detail')) {
      currentIndex = 2;
    } else if (location.startsWith('/analytics')) {
      currentIndex = 3;
    } else if (location.startsWith('/map')) {
      currentIndex = 3; // map maps to Rekap/analytics or we can add it to sub-navigation
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 2) {
            context.go('/history');
          } else if (index == 3) {
            context.go('/analytics');
          } else if (index == 4) {
            _showPsnRecapDialog(context);
          } else if (index == 5) {
            _showProfileDialog(context, ref, profile);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryBlue,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kader'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Verifikasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rekap'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Info'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildSuperAdminShell(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String location,
  ) {
    int currentIndex = 0;
    if (location == '/') {
      currentIndex = 0;
    } else if (location.startsWith('/locations')) {
      currentIndex = 1;
    } else if (location.startsWith('/analytics') || location.startsWith('/superadmin-reports')) {
      currentIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/locations');
          } else if (index == 3) {
            context.go('/analytics');
          } else if (index == 5) {
            _showProfileDialog(context, ref, profile);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryBlue,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Wilayah'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Monitoring'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
