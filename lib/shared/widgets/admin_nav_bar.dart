import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AdminNavBar extends StatelessWidget {
  final String activePage;

  const AdminNavBar({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavButton(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              isActive: activePage == 'dashboard',
              onTap: () => context.go('/'),
            ),
            _NavButton(
              label: 'Analisis',
              icon: Icons.bar_chart_rounded,
              isActive: activePage == 'analytics',
              onTap: () => context.go('/analytics'),
            ),
            _NavButton(
              label: 'Monitoring',
              icon: Icons.fact_check_outlined,
              isActive: activePage == 'monitoring',
              onTap: () => context.go('/history'),
            ),
            _NavButton(
              label: 'Wilayah',
              icon: Icons.map_outlined,
              isActive: activePage == 'locations',
              onTap: () => context.go('/locations'),
            ),
            _NavButton(
              label: 'Sebaran',
              icon: Icons.location_on_outlined,
              isActive: activePage == 'map',
              onTap: () => context.go('/map'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10365F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
