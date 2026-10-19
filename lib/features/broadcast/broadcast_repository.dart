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
      title: 'Gerakan PSN Serentak Menghadapi Musim Hujan 2026',
      content:
          'Seluruh kader Posyandu se-Kecamatan Gumelar diinstruksikan melakukan pemeriksaan jentik serentak minimal 25 rumah per RT. Prioritaskan penampungan air terbuka, dispenser, dan talang air yang berisiko menjadi perindukan nyamuk Aedes aegypti.',
      urgency: 'darurat',
      targetVillageId: null,
      targetVillageName: 'Seluruh Kabupaten / Puskesmas',
      authorName: 'Dinas Kesehatan Kab. Banyumas',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    BroadcastAnnouncement(
      id: 'ann-002',
      title: 'Penyaluran Bubuk Abate & Larvasida Selektif',
      content:
          'Puskesmas telah mendistribusikan stok larvasida abate ke koordinator posyandu desa dengan capaian ABJ di bawah 95%. Berikan abatisasi selektif untuk penampungan yang sulit dikuras secara rutin.',
      urgency: 'penting',
      targetVillageId: null,
      targetVillageName: 'Desa Rawan ABJ < 95%',
      authorName: 'Seksi P2M Dinkes',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
    if (localList.isNotEmpty) {
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
