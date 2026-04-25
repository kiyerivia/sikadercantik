import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/auth_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profil tidak ditemukan'));

          return Column(
            children: [
              // 1. Sayurbox Custom Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
                color: const Color(0xFF1D7423),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pantau Jentik di',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Pilih Lokasi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Profile Menu with Logout
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              ref.read(authRepositoryProvider).signOut();
                            }
                          },
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text(
                            'Cari laporan atau wilayah...',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Banner Promo Placeholder
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1000'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                                begin: Alignment.bottomLeft,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.bottomLeft,
                            child: const Text(
                              'Bersama Lawan\nDemam Berdarah',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                      // 3. Main Service Cards (Egg & Rice style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            if (profile.role == 'kader') ...[
                              Expanded(
                                child: _SayurboxProductCard(
                                  title: 'Input Laporan',
                                  price: 'PSN Baru',
                                  image: Icons.add_circle_outline,
                                  color: Colors.orange,
                                  onTap: () => context.push('/report'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SayurboxProductCard(
                                  title: 'Riwayat Saya',
                                  price: 'Lihat Data',
                                  image: Icons.history,
                                  color: Colors.blue,
                                  onTap: () => context.push('/history'),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: _SayurboxProductCard(
                                  title: 'Monitoring',
                                  price: 'Cek Laporan',
                                  image: Icons.analytics_outlined,
                                  color: const Color(0xFF1D7423),
                                  onTap: () => context.push('/analytics'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SayurboxProductCard(
                                  title: 'Lokasi',
                                  price: 'Atur Wilayah',
                                  image: Icons.map_outlined,
                                  color: Colors.purple,
                                  onTap: () => context.push('/locations'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 4. Category Icons
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CategoryIcon(icon: Icons.new_releases, label: 'Terbaru', color: Colors.amber),
                            _CategoryIcon(icon: Icons.verified_user, label: 'Verifikasi', color: Colors.green),
                            _CategoryIcon(icon: Icons.warning, label: 'Waspada', color: Colors.red),
                            _CategoryIcon(icon: Icons.people, label: 'Kader', color: Colors.blue),
                            _CategoryIcon(icon: Icons.assessment, label: 'Statistik', color: Colors.purple),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      // 5. Floating Bottom Bar (Tidied up)
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1D7423),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Anda belum mengirim laporan hari ini',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SayurboxProductCard extends StatelessWidget {
  final String title;
  final String price;
  final IconData image;
  final Color color;
  final VoidCallback onTap;

  const _SayurboxProductCard({
    required this.title,
    required this.price,
    required this.image,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Icon(image, size: 50, color: color),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFF1D7423), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1D7423), borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      price,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryIcon({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
