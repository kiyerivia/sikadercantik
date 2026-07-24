import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';

class MasterRepository {
  final SupabaseClient _client;

  MasterRepository(this._client);

  static final List<Village> _fallbackVillages = [
    Village(id: 'v-cilangkap', name: 'Cilangkap'),
    Village(id: 'v-cihonje', name: 'Cihonje'),
    Village(id: 'v-paningkaban', name: 'Paningkaban'),
    Village(id: 'v-karangkemojing', name: 'Karangkemojing'),
    Village(id: 'v-gancang', name: 'Gancang'),
    Village(id: 'v-kedungurang', name: 'Kedungurang'),
    Village(id: 'v-gumelar', name: 'Gumelar'),
    Village(id: 'v-tlaga', name: 'Tlaga'),
    Village(id: 'v-samudra', name: 'Samudra'),
    Village(id: 'v-samudra-kulon', name: 'Samudra Kulon'),
  ];

  static final Map<String, List<Posyandu>> _fallbackPosyandusByVillage = {
    'v-cilangkap': [
      Posyandu(id: 'p-cilangkap-1', rwId: 'rw-cilangkap-1', name: 'Posyandu Bina Sejahtera 1'),
      Posyandu(id: 'p-cilangkap-2', rwId: 'rw-cilangkap-2', name: 'Posyandu Bina Sejahtera 2'),
      Posyandu(id: 'p-cilangkap-3', rwId: 'rw-cilangkap-3', name: 'Posyandu Bina Sejahtera 3'),
      Posyandu(id: 'p-cilangkap-4', rwId: 'rw-cilangkap-4', name: 'Posyandu Bina Sejahtera 4'),
      Posyandu(id: 'p-cilangkap-5', rwId: 'rw-cilangkap-5', name: 'Posyandu Bina Sejahtera 5'),
      Posyandu(id: 'p-cilangkap-6', rwId: 'rw-cilangkap-6', name: 'Posyandu Bina Sejahtera 6'),
    ],
    'v-cihonje': [
      Posyandu(id: 'p-cihonje-1', rwId: 'rw-cihonje-2', name: 'Posyandu Dahlia 1'),
      Posyandu(id: 'p-cihonje-2', rwId: 'rw-cihonje-3', name: 'Posyandu Melati'),
      Posyandu(id: 'p-cihonje-3', rwId: 'rw-cihonje-7', name: 'Posyandu Puji Lestari'),
      Posyandu(id: 'p-cihonje-4', rwId: 'rw-cihonje-8', name: 'Posyandu Dahlia 2'),
      Posyandu(id: 'p-cihonje-5', rwId: 'rw-cihonje-9', name: 'Posyandu Cempaka'),
      Posyandu(id: 'p-cihonje-6', rwId: 'rw-cihonje-12', name: 'Posyandu Budi Sasono 1'),
      Posyandu(id: 'p-cihonje-7', rwId: 'rw-cihonje-13', name: 'Posyandu Boby Lestari'),
      Posyandu(id: 'p-cihonje-8', rwId: 'rw-cihonje-14', name: 'Posyandu Laksono Utomo'),
      Posyandu(id: 'p-cihonje-9', rwId: 'rw-cihonje-16', name: 'Posyandu Wijaya Kusuma'),
      Posyandu(id: 'p-cihonje-10', rwId: 'rw-cihonje-17', name: 'Posyandu Budi Sasono 2'),
      Posyandu(id: 'p-cihonje-11', rwId: 'rw-cihonje-18', name: 'Posyandu Regil Rahayu'),
    ],
    'v-paningkaban': [
      Posyandu(id: 'p-paningkaban-1', rwId: 'rw-paningkaban-1', name: 'Posyandu Jatiwaluyo'),
      Posyandu(id: 'p-paningkaban-2', rwId: 'rw-paningkaban-2', name: 'Posyandu Widodo'),
      Posyandu(id: 'p-paningkaban-3', rwId: 'rw-paningkaban-3', name: 'Posyandu Lestari'),
      Posyandu(id: 'p-paningkaban-4', rwId: 'rw-paningkaban-4', name: 'Posyandu Rahayu'),
    ],
    'v-karangkemojing': [
      Posyandu(id: 'p-karangkemojing-1', rwId: 'rw-karangkemojing-1', name: 'Posyandu Sari Asih'),
      Posyandu(id: 'p-karangkemojing-2', rwId: 'rw-karangkemojing-2', name: 'Posyandu Mardi Siwi'),
      Posyandu(id: 'p-karangkemojing-3', rwId: 'rw-karangkemojing-2', name: 'Posyandu Pamardi Siwi'),
      Posyandu(id: 'p-karangkemojing-4', rwId: 'rw-karangkemojing-3', name: 'Posyandu Mekar Sari'),
      Posyandu(id: 'p-karangkemojing-5', rwId: 'rw-karangkemojing-3', name: 'Posyandu Mugi Lestari'),
      Posyandu(id: 'p-karangkemojing-6', rwId: 'rw-karangkemojing-4', name: 'Posyandu Karya Lestari'),
      Posyandu(id: 'p-karangkemojing-7', rwId: 'rw-karangkemojing-4', name: 'Posyandu Basuki'),
    ],
    'v-gancang': [
      Posyandu(id: 'p-gancang-1', rwId: 'rw-gancang-1', name: 'Posyandu Tunas Bangsa 1'),
      Posyandu(id: 'p-gancang-2', rwId: 'rw-gancang-4', name: 'Posyandu Tunas Bangsa 2'),
      Posyandu(id: 'p-gancang-3', rwId: 'rw-gancang-5', name: 'Posyandu Tunas Bangsa 3'),
      Posyandu(id: 'p-gancang-4', rwId: 'rw-gancang-2', name: 'Posyandu Tunas Bangsa 4'),
      Posyandu(id: 'p-gancang-5', rwId: 'rw-gancang-5', name: 'Posyandu Tunas Bangsa 5'),
      Posyandu(id: 'p-gancang-6', rwId: 'rw-gancang-3', name: 'Posyandu Tunas Bangsa 6'),
    ],
    'v-kedungurang': [
      Posyandu(id: 'p-kedungurang-1', rwId: 'rw-kedungurang-4', name: 'Posyandu Taman Sari'),
      Posyandu(id: 'p-kedungurang-2', rwId: 'rw-kedungurang-1', name: 'Posyandu Mawar'),
      Posyandu(id: 'p-kedungurang-3', rwId: 'rw-kedungurang-7', name: 'Posyandu Melati'),
      Posyandu(id: 'p-kedungurang-4', rwId: 'rw-kedungurang-6', name: 'Posyandu Sanggar Sari'),
      Posyandu(id: 'p-kedungurang-5', rwId: 'rw-kedungurang-2', name: 'Posyandu Laju Sejahtera'),
      Posyandu(id: 'p-kedungurang-6', rwId: 'rw-kedungurang-8', name: 'Posyandu Mugi Rahayu'),
      Posyandu(id: 'p-kedungurang-7', rwId: 'rw-kedungurang-3', name: 'Posyandu Mugi Lestari'),
    ],
    'v-gumelar': [
      Posyandu(id: 'p-gumelar-1', rwId: 'rw-gumelar-1', name: 'Posyandu Bina Laju Sejahtera 1'),
      Posyandu(id: 'p-gumelar-2', rwId: 'rw-gumelar-2', name: 'Posyandu Bina Laju Sejahtera 2'),
      Posyandu(id: 'p-gumelar-3', rwId: 'rw-gumelar-3', name: 'Posyandu Bina Laju Sejahtera 3'),
      Posyandu(id: 'p-gumelar-4', rwId: 'rw-gumelar-4', name: 'Posyandu Bina Laju Sejahtera 4'),
      Posyandu(id: 'p-gumelar-5', rwId: 'rw-gumelar-5', name: 'Posyandu Bina Laju Sejahtera 5'),
      Posyandu(id: 'p-gumelar-6', rwId: 'rw-gumelar-6', name: 'Posyandu Bina Laju Sejahtera 6'),
      Posyandu(id: 'p-gumelar-7', rwId: 'rw-gumelar-7', name: 'Posyandu Bina Laju Sejahtera 7'),
      Posyandu(id: 'p-gumelar-8', rwId: 'rw-gumelar-8', name: 'Posyandu Bina Laju Sejahtera 8'),
      Posyandu(id: 'p-gumelar-9', rwId: 'rw-gumelar-9', name: 'Posyandu Bina Laju Sejahtera 9'),
      Posyandu(id: 'p-gumelar-10', rwId: 'rw-gumelar-10', name: 'Posyandu Bina Laju Sejahtera 10'),
      Posyandu(id: 'p-gumelar-11', rwId: 'rw-gumelar-11', name: 'Posyandu Bina Laju Sejahtera 11'),
    ],
    'v-tlaga': [
      Posyandu(id: 'p-tlaga-1', rwId: 'rw-tlaga-1', name: 'Posyandu Balita Rahayu 1'),
      Posyandu(id: 'p-tlaga-2', rwId: 'rw-tlaga-2', name: 'Posyandu Balita Rahayu 2'),
      Posyandu(id: 'p-tlaga-3', rwId: 'rw-tlaga-3', name: 'Posyandu Balita Rahayu 3'),
      Posyandu(id: 'p-tlaga-4', rwId: 'rw-tlaga-4', name: 'Posyandu Balita Rahayu 4'),
      Posyandu(id: 'p-tlaga-5', rwId: 'rw-tlaga-5', name: 'Posyandu Balita Rahayu 5'),
      Posyandu(id: 'p-tlaga-6', rwId: 'rw-tlaga-6', name: 'Posyandu Balita Rahayu 6'),
      Posyandu(id: 'p-tlaga-7', rwId: 'rw-tlaga-7', name: 'Posyandu Balita Rahayu 7'),
      Posyandu(id: 'p-tlaga-8', rwId: 'rw-tlaga-8', name: 'Posyandu Balita Rahayu 8'),
    ],
    'v-samudra': [
      Posyandu(id: 'p-samudra-1', rwId: 'rw-samudra-1', name: 'Posyandu Harapan Bangsa 1'),
      Posyandu(id: 'p-samudra-2', rwId: 'rw-samudra-2', name: 'Posyandu Harapan Bangsa 2'),
      Posyandu(id: 'p-samudra-3', rwId: 'rw-samudra-3', name: 'Posyandu Harapan Bangsa 3'),
      Posyandu(id: 'p-samudra-4', rwId: 'rw-samudra-4', name: 'Posyandu Harapan Bangsa 4'),
      Posyandu(id: 'p-samudra-5', rwId: 'rw-samudra-5', name: 'Posyandu Harapan Bangsa 5'),
      Posyandu(id: 'p-samudra-6', rwId: 'rw-samudra-6', name: 'Posyandu Harapan Bangsa 6'),
      Posyandu(id: 'p-samudra-7', rwId: 'rw-samudra-7', name: 'Posyandu Harapan Bangsa 7'),
      Posyandu(id: 'p-samudra-8', rwId: 'rw-samudra-8', name: 'Posyandu Harapan Bangsa 8'),
    ],
    'v-samudra-kulon': [
      Posyandu(id: 'p-samudra-kulon-1', rwId: 'rw-samudra-kulon-1', name: 'Posyandu Mawar'),
      Posyandu(id: 'p-samudra-kulon-2', rwId: 'rw-samudra-kulon-2', name: 'Posyandu Budi Asih'),
      Posyandu(id: 'p-samudra-kulon-3', rwId: 'rw-samudra-kulon-3', name: 'Posyandu Kasih Ibu'),
      Posyandu(id: 'p-samudra-kulon-4', rwId: 'rw-samudra-kulon-4', name: 'Posyandu Anak Sehat'),
      Posyandu(id: 'p-samudra-kulon-5', rwId: 'rw-samudra-kulon-5', name: 'Posyandu Sayang Anak'),
    ],
  };

  static final List<Map<String, dynamic>> _fallbackBreedingPlaces = [
    {'id': 'bp-1', 'name': 'Bak Mandi / WC', 'is_active': true},
    {'id': 'bp-2', 'name': 'Toren / Penampungan Air', 'is_active': true},
    {'id': 'bp-3', 'name': 'Vas Bunga / Pot', 'is_active': true},
    {'id': 'bp-4', 'name': 'Ban Bekas / Kaleng', 'is_active': true},
    {'id': 'bp-5', 'name': 'Tatakan Dispenser / Kulkas', 'is_active': true},
    {'id': 'bp-6', 'name': 'Sampah Plastik / Genangan Air', 'is_active': true},
    {'id': 'bp-7', 'name': 'Sumur / Kolam Air', 'is_active': true},
    {'id': 'bp-8', 'name': 'Lain-lain', 'is_active': true},
  ];

  Future<List<Village>> getVillages() async {
    try {
      final response = await _client.from('villages').select().order('name');
      final allVillages = (response as List).map((m) => Village.fromMap(m)).toList();

      if (allVillages.isNotEmpty) {
        const gumelarVillages = [
          'cilangkap',
          'cihonje',
          'paningkaban',
          'karangkemojing',
          'gancang',
          'kedungurang',
          'gumelar',
          'tlaga',
          'samudra',
          'samudra kulon',
        ];

        final filtered = allVillages
            .where((v) => gumelarVillages.any((g) => v.name.trim().toLowerCase().contains(g)))
            .toList();

        final result = filtered.isNotEmpty ? filtered : allVillages;
        result.sort((a, b) => a.name.compareTo(b.name));
        return result;
      }
    } catch (e) {
      print('Error fetching villages from Supabase: $e. Using static fallback data.');
    }
    return _fallbackVillages;
  }

  Future<List<RW>> getRWs(String villageId) async {
    try {
      final response = await _client
          .from('rws')
          .select()
          .eq('village_id', villageId)
          .order('rw_number');
      final list = (response as List).map((m) => RW.fromMap(m)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Fallback RW list based on posyandus
    final posyandus = await getPosyandusByVillage(villageId);
    final rwSet = <String>{};
    final rwList = <RW>[];
    for (var p in posyandus) {
      if (rwSet.add(p.rwId)) {
        rwList.add(RW(id: p.rwId, villageId: villageId, rwNumber: p.rwId.replaceAll(RegExp(r'[^\d]'), '')));
      }
    }
    return rwList.isNotEmpty ? rwList : [RW(id: 'rw-1', villageId: villageId, rwNumber: '1')];
  }

  Future<List<Posyandu>> getPosyandus(String rwId) async {
    try {
      final response = await _client
          .from('posyandus')
          .select('*, rws(*)')
          .eq('rw_id', rwId)
          .order('name');
      final list = (response as List).map((m) => Posyandu.fromMap(m)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Fallback search across all villages
    for (var entry in _fallbackPosyandusByVillage.entries) {
      final matches = entry.value.where((p) => p.rwId == rwId).toList();
      if (matches.isNotEmpty) return matches;
    }
    return [];
  }

  Future<List<Posyandu>> getPosyandusByVillage(String villageId) async {
    try {
      final response = await _client
          .from('posyandus')
          .select('*, rws!inner(*)')
          .eq('rws.village_id', villageId)
          .order('name');
      final list = (response as List).map((m) => Posyandu.fromMap(m)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Check fallback map by villageId or name matching
    if (_fallbackPosyandusByVillage.containsKey(villageId)) {
      return _fallbackPosyandusByVillage[villageId]!;
    }

    final villages = await getVillages();
    final village = villages.firstWhere(
      (v) => v.id == villageId,
      orElse: () => _fallbackVillages.firstWhere(
        (v) => v.id == villageId,
        orElse: () => Village(id: '', name: ''),
      ),
    );

    final normalized = village.name.toLowerCase().trim().replaceAll(' ', '-');
    final key = 'v-$normalized';
    if (_fallbackPosyandusByVillage.containsKey(key)) {
      return _fallbackPosyandusByVillage[key]!;
    }

    for (var entry in _fallbackPosyandusByVillage.entries) {
      final cleanKey = entry.key.replaceAll('v-', '');
      if (cleanKey.isNotEmpty && (normalized.contains(cleanKey) || cleanKey.contains(normalized))) {
        return entry.value;
      }
    }

    // Default to Gumelar posyandus if village matched gumelar
    if (village.name.toLowerCase().contains('gumelar')) {
      return _fallbackPosyandusByVillage['v-gumelar']!;
    }

    return _fallbackPosyandusByVillage['v-gumelar'] ?? _fallbackPosyandusByVillage.values.first;
  }

  Future<String?> getVillageIdByPosyandu(String posyanduId) async {
    try {
      final response = await _client
          .from('posyandus')
          .select('rws(village_id)')
          .eq('id', posyanduId)
          .single();
      final vId = response['rws']['village_id'] as String?;
      if (vId != null && vId.isNotEmpty) return vId;
    } catch (_) {}

    for (var entry in _fallbackPosyandusByVillage.entries) {
      if (entry.value.any((p) => p.id == posyanduId)) {
        final fallbackKey = entry.key; // e.g. 'v-gumelar'
        final villages = await getVillages();
        final matched = villages.firstWhere(
          (v) => v.id == fallbackKey || v.name.toLowerCase().trim().replaceAll(' ', '-') == fallbackKey.replaceAll('v-', ''),
          orElse: () => _fallbackVillages.firstWhere((v) => v.id == fallbackKey, orElse: () => Village(id: fallbackKey, name: 'Gumelar')),
        );
        return matched.id;
      }
    }
    final villages = await getVillages();
    final gumelar = villages.firstWhere(
      (v) => v.name.toLowerCase().contains('gumelar'),
      orElse: () => _fallbackVillages.firstWhere((v) => v.id == 'v-gumelar'),
    );
    return gumelar.id;
  }

  Future<String> insertVillage(String name) async {
    final resp = await _client.from('villages').insert({'name': name}).select('id').single();
    return (resp)['id'] as String;
  }

  Future<String> insertRw({required String villageId, required String rwNumber}) async {
    final resp = await _client.from('rws').insert({
      'village_id': villageId,
      'rw_number': rwNumber,
    }).select('id').single();
    return (resp)['id'] as String;
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
      'tahun_pendirian': year,
      'alamat': address,
      'nama_ketua': chairName,
      'nomor_hp': phone,
    }).select('id').single();
    return (resp)['id'] as String;
  }

  Future<void> deleteVillage(String id) async {
    await _client.from('villages').delete().eq('id', id);
  }

  Future<void> deleteRw(String id) async {
    await _client.from('rws').delete().eq('id', id);
  }

  Future<void> deletePosyandu(String id) async {
    await _client.from('posyandus').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getBreedingPlaces() async {
    try {
      final response = await _client
          .from('mosquito_breeding_places')
          .select()
          .eq('is_active', true)
          .order('name');
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return _fallbackBreedingPlaces;
  }
}
