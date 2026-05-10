import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';

class AdminSidebar extends StatelessWidget {
  final String activePage;

  const AdminSidebar({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width <= 900) return const SizedBox.shrink();

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
        borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
