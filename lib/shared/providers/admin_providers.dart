import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'report_providers.dart';

// allReportsProvider is now moved to report_providers.dart to avoid duplication

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
      'needVerification': reports.where((r) => r.status == 'need_intervention').length,
    };
  });
});
