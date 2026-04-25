import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'report_providers.dart';
import '../domain/models.dart';

final allReportsProvider = FutureProvider<List<Report>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getAllReports();
});

final adminStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  return reportsAsync.whenData((reports) {
    int totalInspected = 0;
    int totalPositive = 0;
    for (var r in reports) {
      totalInspected += r.housesInspected;
      totalPositive += r.housesPositive;
    }
    double abj = totalInspected > 0 ? (totalInspected - totalPositive) / totalInspected * 100 : 0;
    return {
      'totalInspected': totalInspected,
      'totalPositive': totalPositive,
      'abj': abj,
      'reportCount': reports.length,
      'needVerification': reports.where((r) => r.status == 'submitted').length,
    };
  });
});
