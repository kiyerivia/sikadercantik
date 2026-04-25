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
  if (data == null) return null;
  return Profile.fromMap(data);
});
