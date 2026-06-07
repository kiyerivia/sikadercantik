import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';

class LocationManagementScreen extends HookConsumerWidget {
  const LocationManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesAsync = ref.watch(villagesProvider);
    final searchQuery = useState<String>('');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    children: const [
                      TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF68B744))),
                    ],
                  ),
                ),
                Text(
                  'MANAJEMEN PUSKESMAS & LOKASI',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 8),
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
                    Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF10365F), size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Banner Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2E86C1), Color(0xFF1B4F72)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.map_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manajemen Wilayah PSN', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Kelola hierarki data master Desa, RW, dan Posyandu untuk keperluan pelaporan dan pemantauan jentik nyamuk.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search & Filter Bar & Add Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      onChanged: (val) => searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: 'Cari nama desa atau wilayah...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVillageDialog(context, ref),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text('Tambah Desa', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10365F),
                      minimumSize: const Size(120, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Village List
          Expanded(
            child: villagesAsync.when(
              data: (villages) {
                const gumelarVillages = [
                  'cilangkap',
                  'cihonje',
                  'paningkaban',
                  'karangkemojing',
                  'gancang',
                  'kedungurang',
                  'gumelar',
                  'tlaga',
                  'samudra',
                  'samudra kulon',
                ];
                final gumelarOnly = villages
                    .where((v) => gumelarVillages.contains(v.name.trim().toLowerCase()))
                    .toList();

                final filtered = searchQuery.value.isEmpty
                    ? gumelarOnly
                    : gumelarOnly.where((v) => v.name.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Tidak ada desa/wilayah yang ditemukan.', style: GoogleFonts.outfit(fontSize: 16, color: Colors.blueGrey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final village = filtered[index];
                    return _VillageExpandable(village: village);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Gagal memuat data: $e')),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddVillageDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final isLoading = ValueNotifier(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tambah Desa Baru', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF10365F))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan nama desa atau kelurahan baru:', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nama Desa / Kelurahan',
                labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10365F), width: 2)),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              isLoading.value = true;
              try {
                await ref.read(masterRepositoryProvider).insertVillage(name);
                ref.invalidate(villagesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Desa "$name" berhasil ditambahkan!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red));
                }
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10365F),
              minimumSize: const Size(90, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) => loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(80, 42)),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _VillageExpandable extends ConsumerWidget {
  final Village village;

  const _VillageExpandable({required this.village});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey[200]!)),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF10365F).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_city, color: Color(0xFF10365F), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Desa / Wilayah', style: GoogleFonts.outfit(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                  Text(village.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            color: const Color(0xFFF4F8FA),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DAFTAR RW', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _confirmDeleteVillage(context, ref, village),
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: Text('Hapus Desa', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddRwDialog(context, ref, village),
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF10365F)),
                          label: Text('Tambah RW', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10365F))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: Color(0xFF10365F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RWList(villageId: village.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVillage(BuildContext context, WidgetRef ref, Village village) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Desa / Wilayah?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda yakin ingin menghapus "${village.name}" beserta semua data RW dan Posyandu di dalamnya? Tindakan ini tidak dapat dibatalkan.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(90, 42),
            ),
            onPressed: () async {
              try {
                await ref.read(masterRepositoryProvider).deleteVillage(village.id);
                ref.invalidate(villagesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Desa "${village.name}" berhasil dihapus'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddRwDialog(BuildContext context, WidgetRef ref, Village village) {
    final controller = TextEditingController();
    final isLoading = ValueNotifier(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tambah RW Baru - ${village.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF10365F))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan nomor atau nama RW baru untuk desa ini:', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nomor RW (Contoh: 01)',
                labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10365F), width: 2)),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            onPressed: () async {
              final rwNumber = controller.text.trim();
              if (rwNumber.isEmpty) return;
              isLoading.value = true;
              try {
                await ref.read(masterRepositoryProvider).insertRw(villageId: village.id, rwNumber: rwNumber);
                ref.invalidate(rwsProvider(village.id));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RW $rwNumber berhasil ditambahkan di ${village.name}!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red));
                }
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10365F),
              minimumSize: const Size(90, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) => loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(80, 42)),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RWList extends ConsumerWidget {
  final String villageId;

  const _RWList({required this.villageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rwsAsync = ref.watch(rwsProvider(villageId));

    return rwsAsync.when(
      data: (rws) {
        if (rws.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Belum ada data RW di desa ini.', style: GoogleFonts.outfit(color: Colors.grey[500], fontStyle: FontStyle.italic)),
          );
        }
        return Column(
          children: rws.map((rw) => _RWExpandable(rw: rw, villageId: villageId)).toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

class _RWExpandable extends ConsumerWidget {
  final RW rw;
  final String villageId;

  const _RWExpandable({required this.rw, required this.villageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        title: Text('RW ${rw.rwNumber}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10365F), fontSize: 15)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.people_outline, color: Colors.blueGrey, size: 20),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('POSYANDU DI RW ${rw.rwNumber}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _confirmDeleteRw(context, ref, rw),
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: Text('Hapus RW', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddPosyanduDialog(context, ref, rw),
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF2E86C1)),
                          label: Text('Tambah Posyandu', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2E86C1))),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                _PosyanduList(rwId: rw.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRw(BuildContext context, WidgetRef ref, RW rw) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus RW ${rw.rwNumber}?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda yakin ingin menghapus RW ${rw.rwNumber} beserta semua Posyandu di dalamnya? Tindakan ini tidak dapat dibatalkan.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(90, 42),
            ),
            onPressed: () async {
              try {
                await ref.read(masterRepositoryProvider).deleteRw(rw.id);
                ref.invalidate(rwsProvider(rw.villageId));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RW ${rw.rwNumber} berhasil dihapus'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPosyanduDialog(BuildContext context, WidgetRef ref, RW rw) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final chairController = TextEditingController();
    final phoneController = TextEditingController();
    final isLoading = ValueNotifier(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tambah Posyandu - RW ${rw.rwNumber}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF10365F))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Masukkan informasi posyandu baru:', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Posyandu *',
                  labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10365F), width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chairController,
                decoration: InputDecoration(
                  labelText: 'Nama Ketua',
                  labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor HP Ketua',
                  labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  labelStyle: GoogleFonts.outfit(color: Colors.blueGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              isLoading.value = true;
              try {
                await ref.read(masterRepositoryProvider).insertPosyandu(
                  rwId: rw.id,
                  name: name,
                  chairName: chairController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );
                ref.invalidate(posyandusProvider(rw.id));
                ref.invalidate(posyandusByVillageProvider(villageId));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Posyandu "$name" berhasil ditambahkan!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red));
                }
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10365F),
              minimumSize: const Size(90, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) => loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(80, 42)),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PosyanduList extends ConsumerWidget {
  final String rwId;

  const _PosyanduList({required this.rwId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posyandusAsync = ref.watch(posyandusProvider(rwId));

    return posyandusAsync.when(
      data: (posyandus) {
        if (posyandus.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada posyandu di RW ini.', style: GoogleFonts.outfit(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 12)),
          );
        }
        return Column(
          children: posyandus.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
            child: ListTile(
              dense: true,
              title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10365F), fontSize: 14)),
              subtitle: p.namaKetua != null && p.namaKetua!.isNotEmpty
                  ? Text('Ketua: ${p.namaKetua} ${p.nomorHp != null ? '(${p.nomorHp})' : ''}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))
                  : null,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.local_hospital, color: Color(0xFF2980B9), size: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                tooltip: 'Hapus Posyandu',
                onPressed: () => _confirmDeletePosyandu(context, ref, p, rwId),
              ),
            ),
          )).toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
      error: (e, s) => Text('Error: $e'),
    );
  }

  void _confirmDeletePosyandu(BuildContext context, WidgetRef ref, Posyandu p, String rwId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Posyandu?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda yakin ingin menghapus "${p.name}"? Tindakan ini tidak dapat dibatalkan.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(90, 42),
            ),
            onPressed: () async {
              try {
                await ref.read(masterRepositoryProvider).deletePosyandu(p.id);
                ref.invalidate(posyandusProvider(rwId));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Posyandu "${p.name}" berhasil dihapus'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

