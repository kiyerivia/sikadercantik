import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';
import 'broadcast_repository.dart';

class BroadcastManagementScreen extends ConsumerStatefulWidget {
  const BroadcastManagementScreen({super.key});

  @override
  ConsumerState<BroadcastManagementScreen> createState() =>
      _BroadcastManagementScreenState();
}

class _BroadcastManagementScreenState
    extends ConsumerState<BroadcastManagementScreen> {
  int _selectedFilter = 0; // 0: Semua, 1: Aktif, 2: Diarsipkan

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Broadcast Instruksi Dinas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Komunikasi Satu Arah Dinkes ke Seluruh Kader',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan data',
            onPressed: () => ref.invalidate(announcementsProvider),
          ),
          const NotificationBadge(),
          const SizedBox(width: 6),
          const UserProfileMenu(),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text(
          'Buat Instruksi Baru',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: () => _showCreateAnnouncementDialog(context, userProfile),
      ),
      body: Column(
        children: [
          // Banner Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF881337), Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBE123C).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Komando & Instruksi Lapangan',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Instruksi yang diterbitkan akan langsung tampil di lonceng notifikasi dan beranda aplikasi seluruh kader & admin puskesmas.',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterTab(0, 'Semua Instruksi'),
                const SizedBox(width: 8),
                _buildFilterTab(1, 'Sedang Aktif'),
                const SizedBox(width: 8),
                _buildFilterTab(2, 'Diarsipkan'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Announcement List
          Expanded(
            child: announcementsAsync.when(
              data: (list) {
                final filtered = list.where((item) {
                  if (_selectedFilter == 1) return item.isActive;
                  if (_selectedFilter == 2) return !item.isActive;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilter == 1
                                ? 'Tidak ada instruksi aktif saat ini'
                                : 'Belum ada data instruksi',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Klik tombol "+ Buat Instruksi Baru" untuk mengirim arahan ke kader.',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildAnnouncementCard(context, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat instruksi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10365F) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF10365F) : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, BroadcastAnnouncement item) {
    Color urgencyColor;
    Color urgencyBg;
    String urgencyLabel;

    switch (item.urgency) {
      case 'darurat':
        urgencyColor = const Color(0xFFE11D48);
        urgencyBg = const Color(0xFFFFE4E6);
        urgencyLabel = 'SIAGA DARURAT DBD';
        break;
      case 'penting':
        urgencyColor = const Color(0xFFD97706);
        urgencyBg = const Color(0xFFFEF3C7);
        urgencyLabel = 'INSTRUKSI PENTING';
        break;
      default:
        urgencyColor = const Color(0xFF16A34A);
        urgencyBg = const Color(0xFFDCFCE7);
        urgencyLabel = 'PENGUMUMAN RUTIN';
    }

    final dateFormatted =
        DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive ? urgencyColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: item.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Urgency Tag + Active Switch + Delete
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: urgencyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        urgencyLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: urgencyColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!item.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DIARSIPKAN',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                  onSelected: (val) async {
                    if (val == 'toggle') {
                      await ref
                          .read(broadcastRepositoryProvider)
                          .toggleAnnouncementActive(item.id, !item.isActive);
                      ref.invalidate(announcementsProvider);
                    } else if (val == 'delete') {
                      final confirm = await _showDeleteConfirm(context);
                      if (confirm == true) {
                        await ref
                            .read(broadcastRepositoryProvider)
                            .deleteAnnouncement(item.id);
                        ref.invalidate(announcementsProvider);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            item.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                            size: 18,
                            color: const Color(0xFF10365F),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.isActive ? 'Arsipkan Instruksi' : 'Aktifkan Kembali',
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(
                            'Hapus Permanen',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 6),

            // Content
            Text(
              item.content,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 14),

            // Footer Details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Target: ${item.targetVillageName ?? "Seluruh Kabupaten"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatted,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Instruksi?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Instruksi dinas ini akan dihapus dari sistem dan tidak lagi tampil di aplikasi kader.',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context, Profile? authorProfile) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedUrgency = 'penting';
    String? selectedVillageId;
    String selectedVillageName = 'Seluruh Kabupaten / Puskesmas';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final villages = ref.watch(villagesProvider).value ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFFE11D48), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Instruksi Dinas Baru',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      Text(
                        'Broadcast Komunikasi Serentak ke Seluruh Kader',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tingkat Urgensi
                    Text(
                      'Tingkat Urgensi Instruksi:',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildUrgencyRadio(
                          label: 'Rutin',
                          val: 'biasa',
                          selected: selectedUrgency,
                          color: const Color(0xFF16A34A),
                          onSelect: (v) => setDialogState(() => selectedUrgency = v),
                        ),
                        const SizedBox(width: 6),
                        _buildUrgencyRadio(
                          label: 'Penting',
                          val: 'penting',
                          selected: selectedUrgency,
                          color: const Color(0xFFD97706),
                          onSelect: (v) => setDialogState(() => selectedUrgency = v),
                        ),
                        const SizedBox(width: 6),
                        _buildUrgencyRadio(
                          label: 'Darurat DBD',
                          val: 'darurat',
                          selected: selectedUrgency,
                          color: const Color(0xFFE11D48),
                          onSelect: (v) => setDialogState(() => selectedUrgency = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Target Wilayah
                    Text(
                      'Target Cakupan Wilayah:',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVillageId,
                          isExpanded: true,
                          hint: Text(
                            'Seluruh Kabupaten / Puskesmas',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Seluruh Kabupaten / Wilayah Puskesmas',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...villages.map((v) => DropdownMenuItem<String>(
                                  value: v.id,
                                  child: Text('Desa ${v.name}', style: GoogleFonts.outfit(fontSize: 13)),
                                )),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedVillageId = val;
                              if (val == null) {
                                selectedVillageName = 'Seluruh Kabupaten / Puskesmas';
                              } else {
                                final match = villages.firstWhere((v) => v.id == val);
                                selectedVillageName = 'Desa ${match.name}';
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Judul Instruksi
                    Text(
                      'Judul Instruksi / Pengumuman:',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Gerakan PSN Serentak Menghadapi Puncak Musim Hujan',
                        hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Isi Arahan
                    Text(
                      'Arahan Teknis / Isi Instruksi:',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Jelaskan instruksi tindak lanjut: target rumah diperiksa, fokus tempat perindukan jentik, pembagian bubuk abate, atau jadwal pelaporan...',
                        hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  'Siarkan Sekarang',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();

                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Judul dan isi instruksi tidak boleh kosong!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  await ref.read(broadcastRepositoryProvider).createAnnouncement(
                        title: title,
                        content: content,
                        urgency: selectedUrgency,
                        targetVillageId: selectedVillageId,
                        targetVillageName: selectedVillageName,
                        authorProfile: authorProfile,
                      );

                  ref.invalidate(announcementsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF15803D),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Instruksi dinas berhasil disiarkan ke seluruh kader!',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUrgencyRadio({
    required String label,
    required String val,
    required String selected,
    required Color color,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = selected == val;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
