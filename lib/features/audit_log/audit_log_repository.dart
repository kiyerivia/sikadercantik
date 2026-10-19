import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';

class AuditLogRepository {
  final SupabaseClient _client;
  static const String _prefKey = 'sikadercantik_audit_logs_cache';

  AuditLogRepository(this._client);

  static final List<AuditLogEntry> _defaultLogs = [
    AuditLogEntry(
      id: 'log-001',
      userName: 'Superadmin Dinkes',
      userRole: 'superadmin',
      actionType: 'broadcast_instruksi',
      description: 'Menerbitkan Instruksi Dinas: Gerakan PSN Serentak Menghadapi Puncak Musim Hujan 2026 ke seluruh kader posyandu.',
      targetId: 'ann-001',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AuditLogEntry(
      id: 'log-002',
      userName: 'Admin Puskesmas Gumelar',
      userRole: 'admin',
      actionType: 'verifikasi_laporan',
      description: 'Memverifikasi laporan PSN Posyandu Bina Sejahtera 1 (Desa Cilangkap) periode Oktober 2026.',
      targetId: 'rep-001',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AuditLogEntry(
      id: 'log-003',
      userName: 'Admin Puskesmas Gumelar',
      userRole: 'admin',
      actionType: 'intervensi',
      description: 'Menginstruksikan intervensi Kunjungan Rumah & Abatisasi pada temuan 2 rumah positif jentik di Posyandu Dahlia 1.',
      targetId: 'rep-002',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    AuditLogEntry(
      id: 'log-004',
      userName: 'Superadmin Dinkes',
      userRole: 'superadmin',
      actionType: 'kelola_pengguna',
      description: 'Menyetujui pendaftaran dan menetapkan penugasan Kader Siti Aminah ke Posyandu Bina Sejahtera 2.',
      targetId: 'usr-004',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AuditLogEntry(
      id: 'log-005',
      userName: 'Superadmin Dinkes',
      userRole: 'superadmin',
      actionType: 'kelola_wilayah',
      description: 'Memperbarui koordinat Geotagging GPS Posyandu Dahlia 2 (-7.3752, 108.9921).',
      targetId: 'pos-004',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AuditLogEntry(
      id: 'log-006',
      userName: 'Superadmin Dinkes',
      userRole: 'superadmin',
      actionType: 'ekspor_data',
      description: 'Mengunduh Dokumen Resmi SK Rekapitulasi ABJ Kabupaten Banyumas Triwulan III.',
      targetId: 'doc-pdf-01',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Future<List<AuditLogEntry>> getAuditLogs() async {
    try {
      // 1. Try fetching from Supabase table
      final response = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      final list = (response as List)
          .map((item) => AuditLogEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      if (list.isNotEmpty) {
        await _saveToLocalCache(list);
        return list;
      }
    } catch (e) {
      debugPrint('AuditLogRepository: remote fetch fallback: $e');
    }

    // 2. Fallback to SharedPreferences cache
    final localList = await _loadFromLocalCache();
    if (localList.isNotEmpty) {
      return localList;
    }

    // 3. If empty, seed default logs
    await _saveToLocalCache(_defaultLogs);
    return _defaultLogs;
  }

  Future<void> logAction({
    required String actionType,
    required String description,
    String? targetId,
    Profile? actor,
  }) async {
    final currentUser = _client.auth.currentUser;
    final String userId = actor?.id ?? currentUser?.id ?? '';
    final String userName = actor?.fullName ??
        (currentUser?.email != null ? currentUser!.email!.split('@').first : 'Superadmin Dinkes');
    final String userRole = actor?.role ?? 'superadmin';

    final newEntry = AuditLogEntry(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId.isNotEmpty ? userId : null,
      userName: userName,
      userRole: userRole,
      actionType: actionType,
      description: description,
      targetId: targetId,
      createdAt: DateTime.now(),
    );

    // Save to local cache first
    final currentList = await _loadFromLocalCache();
    final updatedList = [newEntry, ...currentList];
    await _saveToLocalCache(updatedList);

    // Attempt writing to Supabase
    try {
      await _client.from('audit_logs').insert({
        'user_id': userId.isNotEmpty ? userId : null,
        'user_name': userName,
        'user_role': userRole,
        'action_type': actionType,
        'description': description,
        'target_id': targetId,
      });
    } catch (e) {
      debugPrint('AuditLogRepository: Supabase insert skipped ($e)');
    }
  }

  Future<List<AuditLogEntry>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => AuditLogEntry.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('AuditLogRepository: error loading local cache: $e');
    }
    return [];
  }

  Future<void> _saveToLocalCache(List<AuditLogEntry> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(logs.map((e) => e.toMap()).toList());
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('AuditLogRepository: error saving local cache: $e');
    }
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuditLogRepository(client);
});

final auditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  return await repo.getAuditLogs();
});
