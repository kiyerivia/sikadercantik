import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';

class MasterRepository {
  final SupabaseClient _client;

  MasterRepository(this._client);

  static final List<Village> _fallbackVillages = [
    Village(id: '10000000-0000-0000-0000-000000000001', name: 'Cilangkap'),
    Village(id: '10000000-0000-0000-0000-000000000002', name: 'Cihonje'),
    Village(id: '10000000-0000-0000-0000-000000000003', name: 'Paningkaban'),
    Village(id: '10000000-0000-0000-0000-000000000004', name: 'Karangkemojing'),
    Village(id: '10000000-0000-0000-0000-000000000005', name: 'Gancang'),
    Village(id: '10000000-0000-0000-0000-000000000006', name: 'Kedungurang'),
    Village(id: '10000000-0000-0000-0000-000000000007', name: 'Gumelar'),
    Village(id: '10000000-0000-0000-0000-000000000008', name: 'Tlaga'),
    Village(id: '10000000-0000-0000-0000-000000000009', name: 'Samudra'),
    Village(id: '10000000-0000-0000-0000-000000000010', name: 'Samudra Kulon'),
  ];

  static final Map<String, List<Posyandu>> _fallbackPosyandusByVillage = {
    '10000000-0000-0000-0000-000000000001': [
      Posyandu(id: '20000000-0000-0000-0001-000000000001', rwId: '30000000-0000-0000-0001-000000000001', name: 'Posyandu Bina Sejahtera 1'),
      Posyandu(id: '20000000-0000-0000-0001-000000000002', rwId: '30000000-0000-0000-0001-000000000002', name: 'Posyandu Bina Sejahtera 2'),
      Posyandu(id: '20000000-0000-0000-0001-000000000003', rwId: '30000000-0000-0000-0001-000000000003', name: 'Posyandu Bina Sejahtera 3'),
      Posyandu(id: '20000000-0000-0000-0001-000000000004', rwId: '30000000-0000-0000-0001-000000000004', name: 'Posyandu Bina Sejahtera 4'),
      Posyandu(id: '20000000-0000-0000-0001-000000000005', rwId: '30000000-0000-0000-0001-000000000005', name: 'Posyandu Bina Sejahtera 5'),
      Posyandu(id: '20000000-0000-0000-0001-000000000006', rwId: '30000000-0000-0000-0001-000000000006', name: 'Posyandu Bina Sejahtera 6'),
    ],
    '10000000-0000-0000-0000-000000000002': [
      Posyandu(id: '20000000-0000-0000-0002-000000000001', rwId: '30000000-0000-0000-0002-000000000002', name: 'Posyandu Dahlia 1'),
      Posyandu(id: '20000000-0000-0000-0002-000000000002', rwId: '30000000-0000-0000-0002-000000000003', name: 'Posyandu Melati'),
      Posyandu(id: '20000000-0000-0000-0002-000000000003', rwId: '30000000-0000-0000-0002-000000000007', name: 'Posyandu Puji Lestari'),
      Posyandu(id: '20000000-0000-0000-0002-000000000004', rwId: '30000000-0000-0000-0002-000000000008', name: 'Posyandu Dahlia 2'),
      Posyandu(id: '20000000-0000-0000-0002-000000000005', rwId: '30000000-0000-0000-0002-000000000009', name: 'Posyandu Cempaka'),
      Posyandu(id: '20000000-0000-0000-0002-000000000006', rwId: '30000000-0000-0000-0002-000000000012', name: 'Posyandu Budi Sasono 1'),
      Posyandu(id: '20000000-0000-0000-0002-000000000007', rwId: '30000000-0000-0000-0002-000000000013', name: 'Posyandu Boby Lestari'),
      Posyandu(id: '20000000-0000-0000-0002-000000000008', rwId: '30000000-0000-0000-0002-000000000014', name: 'Posyandu Laksono Utomo'),
      Posyandu(id: '20000000-0000-0000-0002-000000000009', rwId: '30000000-0000-0000-0002-000000000016', name: 'Posyandu Wijaya Kusuma'),
      Posyandu(id: '20000000-0000-0000-0002-000000000010', rwId: '30000000-0000-0000-0002-000000000017', name: 'Posyandu Budi Sasono 2'),
      Posyandu(id: '20000000-0000-0000-0002-000000000011', rwId: '30000000-0000-0000-0002-000000000018', name: 'Posyandu Regil Rahayu'),
    ],
    '10000000-0000-0000-0000-000000000003': [
      Posyandu(id: '20000000-0000-0000-0003-000000000001', rwId: '30000000-0000-0000-0003-000000000001', name: 'Posyandu Jatiwaluyo'),
      Posyandu(id: '20000000-0000-0000-0003-000000000002', rwId: '30000000-0000-0000-0003-000000000002', name: 'Posyandu Widodo'),
      Posyandu(id: '20000000-0000-0000-0003-000000000003', rwId: '30000000-0000-0000-0003-000000000003', name: 'Posyandu Lestari'),
      Posyandu(id: '20000000-0000-0000-0003-000000000004', rwId: '30000000-0000-0000-0003-000000000004', name: 'Posyandu Rahayu'),
    ],
    '10000000-0000-0000-0000-000000000004': [
      Posyandu(id: '20000000-0000-0000-0004-000000000001', rwId: '30000000-0000-0000-0004-000000000001', name: 'Posyandu Sari Asih'),
      Posyandu(id: '20000000-0000-0000-0004-000000000002', rwId: '30000000-0000-0000-0004-000000000002', name: 'Posyandu Mardi Siwi'),
      Posyandu(id: '20000000-0000-0000-0004-000000000003', rwId: '30000000-0000-0000-0004-000000000002', name: 'Posyandu Pamardi Siwi'),
      Posyandu(id: '20000000-0000-0000-0004-000000000004', rwId: '30000000-0000-0000-0004-000000000003', name: 'Posyandu Mekar Sari'),
      Posyandu(id: '20000000-0000-0000-0004-000000000005', rwId: '30000000-0000-0000-0004-000000000003', name: 'Posyandu Mugi Lestari'),
      Posyandu(id: '20000000-0000-0000-0004-000000000006', rwId: '30000000-0000-0000-0004-000000000004', name: 'Posyandu Karya Lestari'),
      Posyandu(id: '20000000-0000-0000-0004-000000000007', rwId: '30000000-0000-0000-0004-000000000004', name: 'Posyandu Basuki'),
    ],
    '10000000-0000-0000-0000-000000000005': [
      Posyandu(id: '20000000-0000-0000-0005-000000000001', rwId: '30000000-0000-0000-0005-000000000001', name: 'Posyandu Tunas Bangsa 1'),
      Posyandu(id: '20000000-0000-0000-0005-000000000002', rwId: '30000000-0000-0000-0005-000000000004', name: 'Posyandu Tunas Bangsa 2'),
      Posyandu(id: '20000000-0000-0000-0005-000000000003', rwId: '30000000-0000-0000-0005-000000000005', name: 'Posyandu Tunas Bangsa 3'),
      Posyandu(id: '20000000-0000-0000-0005-000000000004', rwId: '30000000-0000-0000-0005-000000000002', name: 'Posyandu Tunas Bangsa 4'),
      Posyandu(id: '20000000-0000-0000-0005-000000000005', rwId: '30000000-0000-0000-0005-000000000005', name: 'Posyandu Tunas Bangsa 5'),
      Posyandu(id: '20000000-0000-0000-0005-000000000006', rwId: '30000000-0000-0000-0005-000000000003', name: 'Posyandu Tunas Bangsa 6'),
    ],
    '10000000-0000-0000-0000-000000000006': [
      Posyandu(id: '20000000-0000-0000-0006-000000000001', rwId: '30000000-0000-0000-0006-000000000004', name: 'Posyandu Taman Sari'),
      Posyandu(id: '20000000-0000-0000-0006-000000000002', rwId: '30000000-0000-0000-0006-000000000001', name: 'Posyandu Mawar'),
      Posyandu(id: '20000000-0000-0000-0006-000000000003', rwId: '30000000-0000-0000-0006-000000000007', name: 'Posyandu Melati'),
      Posyandu(id: '20000000-0000-0000-0006-000000000004', rwId: '30000000-0000-0000-0006-000000000006', name: 'Posyandu Sanggar Sari'),
      Posyandu(id: '20000000-0000-0000-0006-000000000005', rwId: '30000000-0000-0000-0006-000000000002', name: 'Posyandu Laju Sejahtera'),
      Posyandu(id: '20000000-0000-0000-0006-000000000006', rwId: '30000000-0000-0000-0006-000000000008', name: 'Posyandu Mugi Rahayu'),
      Posyandu(id: '20000000-0000-0000-0006-000000000007', rwId: '30000000-0000-0000-0006-000000000003', name: 'Posyandu Mugi Lestari'),
    ],
    '10000000-0000-0000-0000-000000000007': [
      Posyandu(id: '20000000-0000-0000-0007-000000000001', rwId: '30000000-0000-0000-0007-000000000001', name: 'Posyandu Bina Laju Sejahtera 1'),
      Posyandu(id: '20000000-0000-0000-0007-000000000002', rwId: '30000000-0000-0000-0007-000000000002', name: 'Posyandu Bina Laju Sejahtera 2'),
      Posyandu(id: '20000000-0000-0000-0007-000000000003', rwId: '30000000-0000-0000-0007-000000000003', name: 'Posyandu Bina Laju Sejahtera 3'),
      Posyandu(id: '20000000-0000-0000-0007-000000000004', rwId: '30000000-0000-0000-0007-000000000004', name: 'Posyandu Bina Laju Sejahtera 4'),
      Posyandu(id: '20000000-0000-0000-0007-000000000005', rwId: '30000000-0000-0000-0007-000000000005', name: 'Posyandu Bina Laju Sejahtera 5'),
      Posyandu(id: '20000000-0000-0000-0007-000000000006', rwId: '30000000-0000-0000-0007-000000000006', name: 'Posyandu Bina Laju Sejahtera 6'),
      Posyandu(id: '20000000-0000-0000-0007-000000000007', rwId: '30000000-0000-0000-0007-000000000007', name: 'Posyandu Bina Laju Sejahtera 7'),
      Posyandu(id: '20000000-0000-0000-0007-000000000008', rwId: '30000000-0000-0000-0007-000000000008', name: 'Posyandu Bina Laju Sejahtera 8'),
      Posyandu(id: '20000000-0000-0000-0007-000000000009', rwId: '30000000-0000-0000-0007-000000000009', name: 'Posyandu Bina Laju Sejahtera 9'),
      Posyandu(id: '20000000-0000-0000-0007-000000000010', rwId: '30000000-0000-0000-0007-000000000010', name: 'Posyandu Bina Laju Sejahtera 10'),
      Posyandu(id: '20000000-0000-0000-0007-000000000011', rwId: '30000000-0000-0000-0007-000000000011', name: 'Posyandu Bina Laju Sejahtera 11'),
    ],
    '10000000-0000-0000-0000-000000000008': [
      Posyandu(id: '20000000-0000-0000-0008-000000000001', rwId: '30000000-0000-0000-0008-000000000001', name: 'Posyandu Balita Rahayu 1'),
      Posyandu(id: '20000000-0000-0000-0008-000000000002', rwId: '30000000-0000-0000-0008-000000000002', name: 'Posyandu Balita Rahayu 2'),
      Posyandu(id: '20000000-0000-0000-0008-000000000003', rwId: '30000000-0000-0000-0008-000000000003', name: 'Posyandu Balita Rahayu 3'),
      Posyandu(id: '20000000-0000-0000-0008-000000000004', rwId: '30000000-0000-0000-0008-000000000004', name: 'Posyandu Balita Rahayu 4'),
      Posyandu(id: '20000000-0000-0000-0008-000000000005', rwId: '30000000-0000-0000-0008-000000000005', name: 'Posyandu Balita Rahayu 5'),
      Posyandu(id: '20000000-0000-0000-0008-000000000006', rwId: '30000000-0000-0000-0008-000000000006', name: 'Posyandu Balita Rahayu 6'),
      Posyandu(id: '20000000-0000-0000-0008-000000000007', rwId: '30000000-0000-0000-0008-000000000007', name: 'Posyandu Balita Rahayu 7'),
      Posyandu(id: '20000000-0000-0000-0008-000000000008', rwId: '30000000-0000-0000-0008-000000000008', name: 'Posyandu Balita Rahayu 8'),
    ],
    '10000000-0000-0000-0000-000000000009': [
      Posyandu(id: '20000000-0000-0000-0009-000000000001', rwId: '30000000-0000-0000-0009-000000000001', name: 'Posyandu Harapan Bangsa 1'),
      Posyandu(id: '20000000-0000-0000-0009-000000000002', rwId: '30000000-0000-0000-0009-000000000002', name: 'Posyandu Harapan Bangsa 2'),
      Posyandu(id: '20000000-0000-0000-0009-000000000003', rwId: '30000000-0000-0000-0009-000000000003', name: 'Posyandu Harapan Bangsa 3'),
      Posyandu(id: '20000000-0000-0000-0009-000000000004', rwId: '30000000-0000-0000-0009-000000000004', name: 'Posyandu Harapan Bangsa 4'),
      Posyandu(id: '20000000-0000-0000-0009-000000000005', rwId: '30000000-0000-0000-0009-000000000005', name: 'Posyandu Harapan Bangsa 5'),
      Posyandu(id: '20000000-0000-0000-0009-000000000006', rwId: '30000000-0000-0000-0009-000000000006', name: 'Posyandu Harapan Bangsa 6'),
      Posyandu(id: '20000000-0000-0000-0009-000000000007', rwId: '30000000-0000-0000-0009-000000000007', name: 'Posyandu Harapan Bangsa 7'),
      Posyandu(id: '20000000-0000-0000-0009-000000000008', rwId: '30000000-0000-0000-0009-000000000008', name: 'Posyandu Harapan Bangsa 8'),
    ],
    '10000000-0000-0000-0000-000000000010': [
      Posyandu(id: '20000000-0000-0000-0010-000000000001', rwId: '30000000-0000-0000-0010-000000000001', name: 'Posyandu Mawar'),
      Posyandu(id: '20000000-0000-0000-0010-000000000002', rwId: '30000000-0000-0000-0010-000000000002', name: 'Posyandu Budi Asih'),
      Posyandu(id: '20000000-0000-0000-0010-000000000003', rwId: '30000000-0000-0000-0010-000000000003', name: 'Posyandu Kasih Ibu'),
      Posyandu(id: '20000000-0000-0000-0010-000000000004', rwId: '30000000-0000-0000-0010-000000000004', name: 'Posyandu Anak Sehat'),
      Posyandu(id: '20000000-0000-0000-0010-000000000005', rwId: '30000000-0000-0000-0010-000000000005', name: 'Posyandu Sayang Anak'),
    ],
  };

  static final List<Map<String, dynamic>> _fallbackBreedingPlaces = [
    {'id': '40000000-0000-0000-0000-000000000001', 'name': 'Bak Mandi / WC', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000002', 'name': 'Toren / Penampungan Air', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000003', 'name': 'Vas Bunga / Pot', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000004', 'name': 'Ban Bekas / Kaleng', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000005', 'name': 'Tatakan Dispenser / Kulkas', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000006', 'name': 'Sampah Plastik / Genangan Air', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000007', 'name': 'Sumur / Kolam Air', 'is_active': true},
    {'id': '40000000-0000-0000-0000-000000000008', 'name': 'Lain-lain', 'is_active': true},
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
    return rwList.isNotEmpty ? rwList : [RW(id: '30000000-0000-0000-0000-000000000001', villageId: villageId, rwNumber: '1')];
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

    for (var entry in _fallbackPosyandusByVillage.entries) {
      final matches = entry.value.where((p) => p.rwId == rwId).toList();
      if (matches.isNotEmpty) return matches;
    }
    return [];
  }

  Future<List<Posyandu>> getPosyandusByVillage(String villageId) async {
    final bool isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(villageId);

    String targetVillageId = villageId;

    if (!isUuid) {
      final villages = await getVillages();
      final cleanName = villageId.replaceAll('v-', '').replaceAll('-', ' ').trim().toLowerCase();
      final matched = villages.firstWhere(
        (v) => v.name.toLowerCase().contains(cleanName) || cleanName.contains(v.name.toLowerCase()),
        orElse: () => villages.first,
      );
      targetVillageId = matched.id;
    }

    try {
      final response = await _client
          .from('posyandus')
          .select('*, rws!inner(*)')
          .eq('rws.village_id', targetVillageId)
          .order('name');
      final list = (response as List).map((m) => Posyandu.fromMap(m)).toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      print('Error fetching posyandus for village: $e');
    }

    if (_fallbackPosyandusByVillage.containsKey(targetVillageId)) {
      return _fallbackPosyandusByVillage[targetVillageId]!;
    }

    final villages = await getVillages();
    final village = villages.firstWhere(
      (v) => v.id == targetVillageId,
      orElse: () => villages.first,
    );

    return _fallbackPosyandusByVillage[village.id] ??
        _fallbackPosyandusByVillage['10000000-0000-0000-0000-000000000007'] ??
        _fallbackPosyandusByVillage.values.first;
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

  Future<Map<String, dynamic>> addBreedingPlace(String name) async {
    try {
      final resp = await _client.from('mosquito_breeding_places').insert({
        'name': name,
        'is_active': true,
      }).select().single();
      return Map<String, dynamic>.from(resp);
    } catch (e) {
      // Fallback local map if offline/error
      return {
        'id': '40000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}',
        'name': name,
        'is_active': true,
      };
    }
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
