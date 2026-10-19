import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../../core/constants/constants.dart';

class AdminSidebar extends StatelessWidget {
  final String activePage;

  const AdminSidebar({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _SidebarItem(
            label: 'Beranda',
            icon: Icons.home_outlined,
            isActive: activePage == 'dashboard',
            onTap: () => context.go('/'),
          ),
          _SidebarItem(
            label: 'Data Monitoring Laporan PSN',
            icon: Icons.assignment_outlined,
            isActive: activePage == 'monitoring',
            onTap: () => context.go('/history'),
          ),
          _SidebarItem(
            label: 'Dashboard ABJ',
            icon: Icons.bar_chart_outlined,
            isActive: activePage == 'analytics',
            onTap: () => context.go('/analytics'),
          ),
          _SidebarItem(
            label: 'Manajemen Wilayah',
            icon: Icons.map_outlined,
            isActive: activePage == 'locations',
            onTap: () => context.go('/locations'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(userProfileProvider).value;
              final isSuperAdmin = profile?.role.toLowerCase().contains('superadmin') == true;
              if (!isSuperAdmin) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 6),
                    child: Text(
                      'TATA KELOLA DINKES',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  _SidebarItem(
                    label: 'Kelola Petugas',
                    icon: Icons.manage_accounts_outlined,
                    isActive: activePage == 'users',
                    onTap: () => context.go('/user-management'),
                  ),
                  _SidebarItem(
                    label: 'Broadcast Instruksi',
                    icon: Icons.campaign_outlined,
                    isActive: activePage == 'broadcast',
                    onTap: () => context.go('/broadcast'),
                  ),
                  _SidebarItem(
                    label: 'Audit Log Sistem',
                    icon: Icons.history_edu_outlined,
                    isActive: activePage == 'audit',
                    onTap: () => context.go('/audit-logs'),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) => _SidebarItem(
              label: 'Keluar',
              icon: Icons.logout,
              isActive: false,
              isDestructive: true,
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10365F).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive 
              ? const Border(left: BorderSide(color: Color(0xFF10365F), width: 4))
              : null,
          ),
          child: ListTile(
            leading: Icon(
              icon, 
              color: isDestructive ? Colors.red : (isActive ? const Color(0xFF10365F) : const Color(0xFF64748B)), 
              size: 22
            ),
            title: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isDestructive ? Colors.red : (isActive ? const Color(0xFF10365F) : const Color(0xFF64748B)),
              ),
            ),
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
