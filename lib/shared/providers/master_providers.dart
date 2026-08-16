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

final posyandusByVillageProvider = FutureProvider.family<List<Posyandu>, String>((ref, villageId) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getPosyandusByVillage(villageId);
});

final allPosyandusProvider = FutureProvider<List<Posyandu>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  final villages = await repo.getVillages();
  final list = <Posyandu>[];
  for (var v in villages) {
    final pList = await repo.getPosyandusByVillage(v.id);
    list.addAll(pList);
  }
  final Map<String, Posyandu> uniqueMap = {};
  for (var p in list) {
    if (!uniqueMap.containsKey(p.id)) {
      uniqueMap[p.id] = p;
    }
  }
  final result = uniqueMap.values.toList();
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
});

final breedingPlacesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getBreedingPlaces();
});
