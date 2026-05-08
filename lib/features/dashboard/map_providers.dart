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
