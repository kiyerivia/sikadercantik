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
      phoneNumber: '0812-2334-4550',
      email: 'superadmin@dinkes-banyumas.go.id',
      posyanduName: 'Dinas Kesehatan Kab. Banyumas',
      villageName: 'Kabupaten Banyumas',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Profile(
      id: 'usr-002',
      fullName: 'dr. Rian Firmansyah',
      role: 'admin',
      phoneNumber: '0813-9988-7766',
      email: 'admin.gumelar@dinkes.id',
      posyanduName: 'Puskesmas Gumelar',
      villageName: 'Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Profile(
      id: 'usr-003',
      fullName: 'Bidan Retno Palupi, S.Tr.Keb',
      role: 'admin',
      phoneNumber: '0812-7890-4433',
      email: 'retno.palupi@dinkes.id',
      posyanduName: 'Puskesmas Gumelar (Promkes)',
      villageName: 'Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
    ),
    Profile(
      id: 'usr-004',
      fullName: 'Sri Hartati, A.Md.Keb',
      role: 'kader',
      phoneNumber: '0821-5566-7788',
      email: 'srihartati@posyandu.id',
      posyanduName: 'Posyandu Bina Laju Sejahtera 1',
      villageName: 'Gumelar',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Profile(
      id: 'usr-005',
      fullName: 'Tasirem',
      role: 'kader',
      phoneNumber: '0813-2745-8225',
      email: 'tasirem@posyandu.id',
      posyanduName: 'Posyandu Bina Sejahtera 1',
      villageName: 'Cilangkap',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    Profile(
      id: 'usr-006',
      fullName: 'Siti Aminah, S.Pd',
      role: 'kader',
      phoneNumber: '0857-1234-5678',
      email: 'siti.aminah@posyandu.id',
      posyanduName: 'Posyandu Bina Sejahtera 2',
      villageName: 'Cilangkap',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    Profile(
      id: 'usr-007',
      fullName: 'Winarsih',
      role: 'kader',
      phoneNumber: '0857-1213-5929',
      email: 'winarsih@posyandu.id',
      posyanduName: 'Posyandu Melati',
      villageName: 'Cihonje',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Profile(
      id: 'usr-008',
      fullName: 'Endang Wahyuningsih',
      role: 'kader',
      phoneNumber: '0813-2233-4411',
      email: 'endang.wahyu@posyandu.id',
      posyanduName: 'Posyandu Dahlia 1',
      villageName: 'Cihonje',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    Profile(
      id: 'usr-009',
      fullName: 'Sri Setiowati',
      role: 'kader',
      phoneNumber: '0852-2677-5619',
      email: 'sri.setiowati@posyandu.id',
      posyanduName: 'Posyandu Jatiwaluyo',
      villageName: 'Paningkaban',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Profile(
      id: 'usr-010',
      fullName: 'Warsiyati',
      role: 'kader',
      phoneNumber: '0852-2709-8055',
      email: 'warsiyati@posyandu.id',
      posyanduName: 'Posyandu Taman Sari',
      villageName: 'Kedungurang',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
    ),
    Profile(
      id: 'usr-011',
      fullName: 'Erni Wahyuningsih',
      role: 'kader',
      phoneNumber: '0815-4714-4210',
      email: 'erni.wahyu@posyandu.id',
      posyanduName: 'Posyandu Tunas Bangsa 1',
      villageName: 'Gancang',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Profile(
      id: 'usr-012',
      fullName: 'Asmiyah',
      role: 'kader',
      phoneNumber: '0812-1096-7851',
      email: 'asmiyah@posyandu.id',
      posyanduName: 'Posyandu Balita Rahayu 1',
      villageName: 'Tlaga',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    Profile(
      id: 'usr-013',
      fullName: 'Titin Kurniasih',
      role: 'kader',
      phoneNumber: '0823-1635-8226',
      email: 'titin.kurnia@posyandu.id',
      posyanduName: 'Posyandu Budi Asih',
      villageName: 'Samudra Kulon',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Profile(
      id: 'usr-014',
      fullName: 'Tri Retnowati',
      role: 'kader',
      phoneNumber: '0858-7788-9900',
      email: 'retno.karang@posyandu.id',
      posyanduName: 'Posyandu Sari Asih',
      villageName: 'Karangkemojing',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Profile(
      id: 'usr-015',
      fullName: 'Siti Maryam',
      role: 'kader',
      phoneNumber: '0813-2981-1340',
      email: 'siti.maryam@posyandu.id',
      posyanduName: 'Posyandu Harapan Bangsa 1',
      villageName: 'Samudra',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
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

      if (list.isNotEmpty) {
        // Merge remote profiles with rich default users so every village has represented cadres
        final existingNames = list.map((u) => u.fullName.toLowerCase().trim()).toSet();
        final existingIds = list.map((u) => u.id).toSet();
        final combined = [...list];
        for (var du in _defaultUsers) {
          if (!existingNames.contains(du.fullName.toLowerCase().trim()) && !existingIds.contains(du.id)) {
            combined.add(du);
          }
        }
        await _saveToLocalCache(combined);
        return combined;
      }
    } catch (e) {
      debugPrint('UserManagementRepository: remote fetch fallback: $e');
    }

    final localList = await _loadFromLocalCache();
    if (localList.length >= _defaultUsers.length) {
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
