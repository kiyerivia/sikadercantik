import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_repository.dart';
import '../domain/models.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  final user = authState?.session?.user;
  
  if (user == null) return null;
  
  final repo = ref.watch(authRepositoryProvider);
  final data = await repo.getUserProfile(user.id);
  if (data == null) {
    final emailPrefix = user.email?.split('@').first ?? 'Kader';
    final roleClean = emailPrefix.toLowerCase();
    String assignedRole = 'kader';
    if (roleClean.contains('superadmin')) {
      assignedRole = 'superadmin';
    } else if (roleClean.contains('admin')) {
      assignedRole = 'admin';
    } else {
      assignedRole = roleClean.startsWith('kader') ? roleClean : 'kader';
    }

    // Auto-insert profile into Supabase so foreign keys won't fail when saving reports/drafts
    try {
      final client = ref.watch(supabaseClientProvider);
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': emailPrefix,
        'role': assignedRole,
      });
    } catch (e) {
      print('Auto-create profile error: $e');
    }

    return Profile(
      id: user.id,
      fullName: emailPrefix,
      role: assignedRole,
    );
  }
  return Profile.fromMap(data);
});
