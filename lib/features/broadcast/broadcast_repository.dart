import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import '../audit_log/audit_log_repository.dart';

class BroadcastRepository {
  final SupabaseClient _client;
  final AuditLogRepository _auditRepo;
  static const String _prefKey = 'sikadercantik_announcements_cache';

  BroadcastRepository(this._client, this._auditRepo);

  static final List<BroadcastAnnouncement> _defaultAnnouncements = [
    BroadcastAnnouncement(
      id: 'ann-001',
      title: 'Instruksi Gerakan PSN 3M Plus Serentak Puncak Musim Hujan',
      content:
          'Seluruh kader Posyandu se-Kecamatan Gumelar diinstruksikan melakukan pemeriksaan jentik serentak minimal 25-30 rumah per RT. Prioritaskan penampungan air terbuka, dispenser, vas bunga, dan talang air yang berisiko menjadi perindukan nyamuk Aedes aegypti.',
      urgency: 'darurat',
      targetVillageId: null,
      targetVillageName: 'Seluruh Wilayah Puskesmas Gumelar',
      authorName: 'Dinas Kesehatan Kab. Banyumas',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BroadcastAnnouncement(
      id: 'ann-002',
      title: 'Peringatan Dini Peningkatan Kasus DBD di Perbatasan Desa Cihonje',
      content:
          'Ditemukan indikasi peningkatan kepadatan jentik nyamuk pada penampungan air di RW 02 dan RW 08 Desa Cihonje (ABJ < 90%). Bidan Desa dan seluruh kader diharapkan meningkatkan pemantauan mingguan serta membagikan bubuk abate secara terarah.',
      urgency: 'penting',
      targetVillageId: null,
      targetVillageName: 'Desa Cihonje & Sekitarnya',
      authorName: 'Seksi P2M Puskesmas Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    BroadcastAnnouncement(
      id: 'ann-003',
      title: 'Penyaluran Stok Larvasida Abate & Pipet Uji Jentik Periode November 2026',
      content:
          'Distribusi logistik pemeriksaan jentik (bubuk abate 100g, pipet plastik, dan senter LED pemeriksaan jentik) telah tiba di Puskesmas Gumelar. Ketua Posyandu dapat mengambil jatah logistik di ruang promkes pada jam kerja.',
      urgency: 'penting',
      targetVillageId: null,
      targetVillageName: 'Koordinator Posyandu 10 Desa',
      authorName: 'Farmasi & Promkes Dinkes',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    BroadcastAnnouncement(
      id: 'ann-004',
      title: 'Apresiasi Capaian Angka Bebas Jentik (ABJ) Wilayah Desa Paningkaban & Cilangkap',
      content:
          'Dinas Kesehatan mengapresiasi kerja keras kader Posyandu di Desa Paningkaban dan Cilangkap yang berhasil mempertahankan ABJ di atas 98% selama tiga bulan berturut-turut. Mari pertahankan status Bebas DBD!',
      urgency: 'biasa',
      targetVillageId: null,
      targetVillageName: 'Desa Paningkaban & Cilangkap',
      authorName: 'dr. H. Hendro Sutrisno, M.Kes (Superadmin)',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    BroadcastAnnouncement(
      id: 'ann-005',
      title: 'Panduan Pengisian Laporan Digital & Validasi Geotagging SiKaderCantik',
      content:
          'Bagi kader yang melakukan pemeriksaan lapangan, pastikan GPS aktif saat memasukkan data KK baru. Fitur peta interaktif kini menampilkan klasterisasi jentik secara real-time untuk mempermudah evaluasi bulanan.',
      urgency: 'biasa',
      targetVillageId: null,
      targetVillageName: 'Seluruh Kader & Admin Puskesmas',
      authorName: 'Tim IT Dinkes Banyumas',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  Future<List<BroadcastAnnouncement>> getAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((e) => BroadcastAnnouncement.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (list.isNotEmpty) {
        await _saveToLocalCache(list);
        return list;
      }
    } catch (e) {
      debugPrint('BroadcastRepository: remote fetch fallback: $e');
    }

    final localList = await _loadFromLocalCache();
    if (localList.length >= _defaultAnnouncements.length) {
      return localList;
    }

    await _saveToLocalCache(_defaultAnnouncements);
    return _defaultAnnouncements;
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String urgency,
    String? targetVillageId,
    String? targetVillageName,
    Profile? authorProfile,
  }) async {
    final currentUser = _client.auth.currentUser;
    final String author = authorProfile?.fullName ?? 'Superadmin Dinkes';

    final newAnnouncement = BroadcastAnnouncement(
      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      urgency: urgency,
      targetVillageId: targetVillageId,
      targetVillageName: targetVillageName ?? 'Seluruh Kabupaten',
      createdBy: currentUser?.id,
      authorName: author,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 1. Cache locally
    final currentList = await _loadFromLocalCache();
    final updatedList = [newAnnouncement, ...currentList];
    await _saveToLocalCache(updatedList);

    // 2. Try inserting to Supabase
    try {
      await _client.from('announcements').insert({
        'title': title,
        'content': content,
        'urgency': urgency,
        'target_village_id': targetVillageId,
        'target_village_name': targetVillageName ?? 'Seluruh Kabupaten',
        'created_by': currentUser?.id,
        'author_name': author,
        'is_active': true,
      });
    } catch (e) {
      debugPrint('BroadcastRepository: Supabase insert skipped ($e)');
    }

    // 3. Log into Audit Trail
    await _auditRepo.logAction(
      actionType: 'broadcast_instruksi',
      description: 'Menerbitkan Instruksi Dinas baru: "$title" (Tingkat Urgensi: ${urgency.toUpperCase()}).',
      targetId: newAnnouncement.id,
      actor: authorProfile,
    );
  }

  Future<void> toggleAnnouncementActive(String id, bool newStatus) async {
    final list = await _loadFromLocalCache();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = BroadcastAnnouncement(
        id: list[index].id,
        title: list[index].title,
        content: list[index].content,
        urgency: list[index].urgency,
        targetVillageId: list[index].targetVillageId,
        targetVillageName: list[index].targetVillageName,
        createdBy: list[index].createdBy,
        authorName: list[index].authorName,
        isActive: newStatus,
        createdAt: list[index].createdAt,
      );
      list[index] = updated;
      await _saveToLocalCache(list);
    }

    try {
      await _client
          .from('announcements')
          .update({'is_active': newStatus})
          .eq('id', id);
    } catch (_) {}

    await _auditRepo.logAction(
      actionType: 'broadcast_instruksi',
      description: '${newStatus ? "Mengaktifkan kembali" : "Mengarsipkan"} Instruksi Dinas (ID: $id).',
      targetId: id,
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    final list = await _loadFromLocalCache();
    list.removeWhere((e) => e.id == id);
    await _saveToLocalCache(list);

    try {
      await _client.from('announcements').delete().eq('id', id);
    } catch (_) {}

    await _auditRepo.logAction(
      actionType: 'broadcast_instruksi',
      description: 'Menghapus Instruksi Dinas (ID: $id).',
      targetId: id,
    );
  }

  Future<List<BroadcastAnnouncement>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => BroadcastAnnouncement.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('BroadcastRepository: error loading local cache: $e');
    }
    return [];
  }

  Future<void> _saveToLocalCache(List<BroadcastAnnouncement> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(list.map((e) => e.toMap()).toList());
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('BroadcastRepository: error saving local cache: $e');
    }
  }
}

final broadcastRepositoryProvider = Provider<BroadcastRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return BroadcastRepository(client, auditRepo);
});

final announcementsProvider = FutureProvider<List<BroadcastAnnouncement>>((ref) async {
  final repo = ref.watch(broadcastRepositoryProvider);
  return await repo.getAnnouncements();
});

final activeAnnouncementsProvider = Provider<List<BroadcastAnnouncement>>((ref) {
  final all = ref.watch(announcementsProvider).value ?? [];
  return all.where((a) => a.isActive).toList();
});
