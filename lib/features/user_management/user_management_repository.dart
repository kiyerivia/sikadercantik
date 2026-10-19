import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';
import '../audit_log/audit_log_repository.dart';

class UserManagementRepository {
  final SupabaseClient _client;
  final AuditLogRepository _auditRepo;
  static const String _prefKey = 'sikadercantik_users_cache';

  UserManagementRepository(this._client, this._auditRepo);

  static final List<Profile> _defaultUsers = [
    Profile(
      id: 'usr-001',
      fullName: 'dr. H. Hendro Sutrisno, M.Kes',
      role: 'superadmin',
      phoneNumber: '081223344550',
      email: 'superadmin@dinkes-banyumas.go.id',
      posyanduName: 'Dinas Kesehatan Kab. Banyumas',
      villageName: 'Kabupaten Banyumas',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Profile(
      id: 'usr-002',
      fullName: 'dr. Rian Firmansyah (Admin Puskesmas)',
      role: 'admin',
      phoneNumber: '081399887766',
      email: 'admin.gumelar@dinkes.id',
      posyanduName: 'Puskesmas Gumelar',
      villageName: 'Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Profile(
      id: 'usr-003',
      fullName: 'Siti Aminah, S.Pd',
      role: 'kader',
      posyanduId: '20000000-0000-0000-0001-000000000001',
      phoneNumber: '085712345678',
      email: 'siti.kader@posyandu.id',
      posyanduName: 'Posyandu Bina Sejahtera 1',
      villageName: 'Cilangkap',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Profile(
      id: 'usr-004',
      fullName: 'Endang Wahyuningsih',
      role: 'kader',
      posyanduId: '20000000-0000-0000-0002-000000000001',
      phoneNumber: '081322334411',
      email: 'endang.kader@posyandu.id',
      posyanduName: 'Posyandu Dahlia 1',
      villageName: 'Cihonje',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Profile(
      id: 'usr-005',
      fullName: 'Budi Santoso (Kader PSN)',
      role: 'kader',
      posyanduId: '20000000-0000-0000-0007-000000000001',
      phoneNumber: '082155667788',
      email: 'budi.gumelar@posyandu.id',
      posyanduName: 'Posyandu Bina Laju Sejahtera 1',
      villageName: 'Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Profile(
      id: 'usr-006',
      fullName: 'Tri Retnowati',
      role: 'kader',
      posyanduId: '20000000-0000-0000-0003-000000000001',
      phoneNumber: '085877889900',
      email: 'retno.paningkaban@posyandu.id',
      posyanduName: 'Posyandu Jatiwaluyo',
      villageName: 'Paningkaban',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  Future<List<Profile>> getAllUsers() async {
    try {
      final response = await _client.from('profiles').select('''
        id,
        full_name,
        role,
        posyandu_id,
        phone_number,
        avatar_url,
        created_at,
        posyandus (
          id,
          name,
          rws (
            id,
            rw_number,
            villages (
              id,
              name
            )
          )
        )
      ''').order('role').order('full_name');

      final list = (response as List).map((item) {
        return Profile.fromMap(Map<String, dynamic>.from(item));
      }).toList();

      if (list.length >= 2) {
        await _saveToLocalCache(list);
        return list;
      }
    } catch (e) {
      debugPrint('UserManagementRepository: remote fetch fallback: $e');
    }

    final localList = await _loadFromLocalCache();
    if (localList.isNotEmpty) {
      return localList;
    }

    await _saveToLocalCache(_defaultUsers);
    return _defaultUsers;
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? posyanduId,
    String? posyanduName,
    String? villageName,
    String? phoneNumber,
  }) async {
    String newUserId = 'usr-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Try creating an authentic Supabase Auth user without overriding current session
    try {
      final standaloneClient = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
      );
      final res = await standaloneClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      if (res.user != null) {
        newUserId = res.user!.id;
      }
    } catch (e) {
      debugPrint('UserManagementRepository: secondary auth signup note: $e');
    }

    final newProfile = Profile(
      id: newUserId,
      fullName: fullName,
      role: role,
      posyanduId: posyanduId,
      posyanduName: posyanduName,
      villageName: villageName,
      phoneNumber: phoneNumber,
      email: email,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 2. Try inserting into Supabase profiles table
    try {
      await _client.from('profiles').upsert({
        'id': newUserId,
        'full_name': fullName,
        'role': role,
        'posyandu_id': posyanduId,
        'phone_number': phoneNumber,
      });
    } catch (e) {
      debugPrint('UserManagementRepository: Supabase profile upsert skipped ($e)');
    }

    // 3. Update local cache
    final currentList = await _loadFromLocalCache();
    final updatedList = [newProfile, ...currentList.where((u) => u.id != newUserId)];
    await _saveToLocalCache(updatedList);

    // 4. Record Audit Log
    final roleLabel = role == 'admin' ? 'Admin Puskesmas' : (role == 'superadmin' ? 'Superadmin' : 'Kader PSN');
    await _auditRepo.logAction(
      actionType: 'kelola_pengguna',
      description: 'Menambahkan akun petugas baru: $fullName ($roleLabel), Email: $email.',
      targetId: newUserId,
    );
  }

  Future<void> updateUserPosyandu({
    required String userId,
    required String posyanduId,
    required String posyanduName,
    required String villageName,
  }) async {
    // 1. Update in local cache
    final list = await _loadFromLocalCache();
    final index = list.indexWhere((u) => u.id == userId);
    String userName = 'Petugas';
    if (index != -1) {
      userName = list[index].fullName;
      list[index] = list[index].copyWith(
        posyanduId: posyanduId,
        posyanduName: posyanduName,
        villageName: villageName,
      );
      await _saveToLocalCache(list);
    }

    // 2. Update in Supabase
    try {
      await _client.from('profiles').update({
        'posyandu_id': posyanduId,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('UserManagementRepository: update posyandu remote error: $e');
    }

    // 3. Audit Log
    await _auditRepo.logAction(
      actionType: 'kelola_pengguna',
      description: 'Pengalihan penugasan kader $userName ke Posyandu $posyanduName (Desa $villageName).',
      targetId: userId,
    );
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final list = await _loadFromLocalCache();
    final index = list.indexWhere((u) => u.id == userId);
    String userName = 'Petugas';
    if (index != -1) {
      userName = list[index].fullName;
      list[index] = list[index].copyWith(isActive: isActive);
      await _saveToLocalCache(list);
    }

    try {
      await _client.from('profiles').update({
        'is_active': isActive,
      }).eq('id', userId);
    } catch (_) {}

    await _auditRepo.logAction(
      actionType: 'kelola_pengguna',
      description: '${isActive ? "Mengaktifkan" : "Menonaktifkan"} akun petugas $userName (ID: $userId).',
      targetId: userId,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String userName,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('UserManagementRepository: reset password note ($e)');
    }

    await _auditRepo.logAction(
      actionType: 'kelola_pengguna',
      description: 'Mengirimkan instruksi reset sandi untuk akun $userName ($email).',
      targetId: email,
    );
  }

  Future<List<Profile>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = jsonDecode(jsonString);
        return decoded.map((item) {
          final map = Map<String, dynamic>.from(item);
          return Profile(
            id: map['id']?.toString() ?? '',
            fullName: map['full_name']?.toString() ?? '',
            role: map['role']?.toString() ?? 'kader',
            posyanduId: map['posyandu_id']?.toString(),
            phoneNumber: map['phone_number']?.toString(),
            avatarUrl: map['avatar_url']?.toString(),
            isActive: map['is_active'] != null ? map['is_active'] == true : true,
            posyanduName: map['posyandu_name']?.toString(),
            villageName: map['village_name']?.toString(),
            email: map['email']?.toString(),
            createdAt: map['created_at'] != null
                ? DateTime.tryParse(map['created_at'].toString())
                : null,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('UserManagementRepository: error loading local cache: $e');
    }
    return [];
  }

  Future<void> _saveToLocalCache(List<Profile> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((p) => {
            'id': p.id,
            'full_name': p.fullName,
            'role': p.role,
            'posyandu_id': p.posyanduId,
            'phone_number': p.phoneNumber,
            'avatar_url': p.avatarUrl,
            'is_active': p.isActive,
            'posyandu_name': p.posyanduName,
            'village_name': p.villageName,
            'email': p.email,
            'created_at': p.createdAt?.toIso8601String(),
          }).toList();
      await prefs.setString(_prefKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('UserManagementRepository: error saving local cache: $e');
    }
  }
}

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return UserManagementRepository(client, auditRepo);
});

final allManagedUsersProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(userManagementRepositoryProvider);
  return await repo.getAllUsers();
});
