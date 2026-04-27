import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';

class MasterRepository {
  final SupabaseClient _client;

  MasterRepository(this._client);

  Future<List<Village>> getVillages() async {
    final response = await _client.from('villages').select().order('name');
    return (response as List).map((m) => Village.fromMap(m)).toList();
  }

  Future<List<RW>> getRWs(String villageId) async {
    final response = await _client
        .from('rws')
        .select()
        .eq('village_id', villageId)
        .order('rw_number');
    return (response as List).map((m) => RW.fromMap(m)).toList();
  }

  Future<List<Posyandu>> getPosyandus(String rwId) async {
    final response = await _client
        .from('posyandus')
        .select()
        .eq('rw_id', rwId)
        .order('name');
    return (response as List).map((m) => Posyandu.fromMap(m)).toList();
  }

  Future<List<Posyandu>> getPosyandusByVillage(String villageId) async {
    final response = await _client
        .from('posyandus')
        .select('*, rws!inner(*)')
        .eq('rws.village_id', villageId)
        .order('name');
    return (response as List).map((m) => Posyandu.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getBreedingPlaces() async {
    final response = await _client
        .from('mosquito_breeding_places')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}
