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
  final allVillages = await repo.getVillages();
  
  // List of 10 villages in Gumelar sub-district
  const gumelarVillages = [
    'Gumelar', 'Cihonje', 'Cilangkap', 'Gancang', 
    'Karangkemojing', 'Kedungurang', 'Paningkaban', 
    'Samudra', 'Samudra Kulon', 'Tlaga'
  ];

  return allVillages.where((v) => gumelarVillages.contains(v.name)).toList();
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

final breedingPlacesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return await repo.getBreedingPlaces();
});
