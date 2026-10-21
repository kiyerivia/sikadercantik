import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';

// Provider untuk mengambil data Posyandu beserta koordinatnya
final posyanduListProvider = FutureProvider<List<Posyandu>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase.from('posyandus').select();
  return (response as List).map((m) => Posyandu.fromMap(m)).toList();
});

// Provider untuk data ABJ per Posyandu (diambil dari laporan terbaru)
final posyanduAbjProvider = FutureProvider<Map<String, Map<String, dynamic>>>((
  ref,
) async {
  final supabase = ref.watch(supabaseClientProvider);

  // Ambil laporan terbaru untuk setiap posyandu
  // Dalam realita, kita mungkin butuh query yang lebih kompleks (group by),
  // tapi untuk awal kita ambil semua laporan dan proses di client.
  final response = await supabase
      .from('reports')
      .select('posyandu_id, houses_inspected, houses_positive, report_date')
      .order('report_date', ascending: false);

  final List data = response as List;
  final Map<String, Map<String, dynamic>> stats = {};

  for (var item in data) {
    final id = item['posyandu_id'] as String;
    if (!stats.containsKey(id)) {
      final inspected = item['houses_inspected'] as int;
      final positive = item['houses_positive'] as int;
      final abj = inspected > 0
          ? ((inspected - positive) / inspected) * 100
          : 100.0;

      stats[id] = {
        'abj': abj,
        'inspected': inspected,
        'positive': positive,
        'date': item['report_date'],
      };
    }
  }

  return stats;
});

/// Koordinat resmi titik pusat setiap desa di Kecamatan Gumelar sesuai Google Maps / GIS
const Map<String, ({double lat, double lon})> kGumelarVillageCoordinates = {
  'gumelar': (lat: -7.375703, lon: 108.980212),
  'cihonje': (lat: -7.396250, lon: 108.993298),
  'cilangkap': (lat: -7.389525, lon: 108.963448),
  'gancang': (lat: -7.403909, lon: 109.021787),
  'kedungurang': (lat: -7.382196, lon: 109.023586),
  'paningkaban': (lat: -7.426398, lon: 108.992495),
  'karangkemojing': (lat: -7.435949, lon: 109.010416),
  'samudra': (lat: -7.351828, lon: 109.013096),
  'samudra kulon': (lat: -7.364052, lon: 108.988237),
  'tlaga': (lat: -7.366452, lon: 108.969701),
};

class VillageMapData {
  final String name;
  final double latitude;
  final double longitude;
  final double abj;
  final int inspected;
  
  VillageMapData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.abj,
    required this.inspected,
  });
}

final villageMapDataProvider = FutureProvider<List<VillageMapData>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  final pRes = await supabase.from('posyandus').select('id, latitude, longitude, rws(villages(name))');
  final rRes = await supabase.from('reports').select('posyandu_id, houses_inspected, houses_positive, report_date');
  
  Map<String, List<Map<String, dynamic>>> villagePosyandus = {};
  Map<String, String> posyanduToVillage = {};
  
  for (var p in pRes as List) {
    final vName = p['rws']?['villages']?['name'] as String?;
    if (vName != null) {
      posyanduToVillage[p['id']] = vName;
      if (p['latitude'] != null && p['longitude'] != null) {
        villagePosyandus.putIfAbsent(vName, () => []).add(p);
      }
    }
  }
  
  Map<String, int> villageInspected = {};
  Map<String, int> villagePositive = {};
  
  for (var r in rRes as List) {
    final pid = r['posyandu_id'] as String;
    final vName = posyanduToVillage[pid];
    if (vName != null) {
       villageInspected[vName] = (villageInspected[vName] ?? 0) + (r['houses_inspected'] as int);
       villagePositive[vName] = (villagePositive[vName] ?? 0) + (r['houses_positive'] as int);
    }
  }
  
  // Pastikan seluruh 10 desa di Kecamatan Gumelar ditampilkan dengan koordinat resmi Google Maps
  final allVillageNames = <String>{
    ...villagePosyandus.keys,
    'Gumelar',
    'Cihonje',
    'Cilangkap',
    'Gancang',
    'Kedungurang',
    'Paningkaban',
    'Karangkemojing',
    'Samudra',
    'Samudra Kulon',
    'Tlaga',
  };

  List<VillageMapData> result = [];
  for (var vName in allVillageNames) {
    final key = vName.trim().toLowerCase();
    final canonical = kGumelarVillageCoordinates[key];
    
    double targetLat;
    double targetLon;

    if (canonical != null) {
      targetLat = canonical.lat;
      targetLon = canonical.lon;
    } else {
      final posys = villagePosyandus[vName] ?? [];
      if (posys.isNotEmpty) {
        double sumLat = 0;
        double sumLon = 0;
        for (var p in posys) {
          sumLat += p['latitude'] as double;
          sumLon += p['longitude'] as double;
        }
        targetLat = sumLat / posys.length;
        targetLon = sumLon / posys.length;
      } else {
        continue;
      }
    }

    int inspected = villageInspected[vName] ?? 0;
    int positive = villagePositive[vName] ?? 0;
    double abj = inspected > 0 ? ((inspected - positive) / inspected) * 100 : 100.0;

    result.add(VillageMapData(
      name: vName,
      latitude: targetLat,
      longitude: targetLon,
      abj: abj,
      inspected: inspected,
    ));
  }
  
  return result;
});
