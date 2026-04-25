import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_providers.dart';
import '../../features/master_data/master_repository.dart';
import '../domain/models.dart';

final masterRepositoryProvider = Provider<MasterRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MasterRepository(client);
});

final villagesProvider = FutureProvider<List<Village>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getVillages();
});

final rwsProvider = FutureProvider.family<List<RW>, String>((ref, villageId) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getRWs(villageId);
});

final posyandusProvider = FutureProvider.family<List<Posyandu>, String>((ref, rwId) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getPosyandus(rwId);
});

final breedingPlacesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getBreedingPlaces();
});
