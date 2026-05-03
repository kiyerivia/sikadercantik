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

  Future<String> insertVillage(String name) async {
    final resp = await _client.from('villages').insert({'name': name}).select('id').single();
    return (resp as Map<String, dynamic>)['id'] as String;
  }

  Future<String> insertRw({required String villageId, required String rwNumber}) async {
    final resp = await _client.from('rws').insert({
      'village_id': villageId,
      'rw_number': rwNumber,
    }).select('id').single();
    return (resp as Map<String, dynamic>)['id'] as String;
  }

  Future<String> insertPosyandu({
    required String rwId,
    required String name,
    String? year,
    String? address,
    String? chairName,
    String? phone,
  }) async {
    final resp = await _client.from('posyandus').insert({
      'rw_id': rwId,
      'name': name,
      if (year != null) 'year_established': year,
      if (address != null) 'address': address,
      if (chairName != null) 'chair_name': chairName,
      if (phone != null) 'phone_number': phone,
    }).select('id').single();
    return (resp as Map<String, dynamic>)['id'] as String;
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
