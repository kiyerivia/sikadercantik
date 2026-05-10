import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'report_providers.dart';
import '../domain/models.dart';

class MonthNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().month;
  void set(int val) => state = val;
}
final selectedMonthProvider = NotifierProvider<MonthNotifier, int>(MonthNotifier.new);

class YearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void set(int val) => state = val;
}
final selectedYearProvider = NotifierProvider<YearNotifier, int>(YearNotifier.new);

final abjByVillageProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  return reportsAsync.whenData((reports) {
    final filtered = reports.where((r) {
      final matchMonth = month == 0 || r.reportDate.month == month;
      final matchYear = year == 0 || r.reportDate.year == year;
      return matchMonth && matchYear;
    }).toList();
    
    final Map<String, List<Report>> grouped = {};
    for (var r in filtered) {
      final village = r.villageName ?? 'Unknown';
      grouped.putIfAbsent(village, () => []).add(r);
    }

    final Map<String, double> result = {};
    grouped.forEach((village, villageReports) {
      int totalInspected = 0;
      int totalPositive = 0;
      for (var r in villageReports) {
        totalInspected += r.housesInspected;
        totalPositive += r.housesPositive;
      }
      double abj = totalInspected > 0 ? (totalInspected - totalPositive) / totalInspected * 100 : 0;
      result[village] = abj;
    });
    
    return result;
  });
});

final dashboardStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  return reportsAsync.whenData((reports) {
    final filtered = reports.where((r) {
      final matchMonth = month == 0 || r.reportDate.month == month;
      final matchYear = year == 0 || r.reportDate.year == year;
      return matchMonth && matchYear;
    }).toList();
    
    int totalReports = filtered.length;
    int intervened = filtered.where((r) => r.status == 'verified' || r.status == 'submitted').length; 
    
    double interventionRate = totalReports > 0 ? (intervened / totalReports) * 100 : 0;

    return {
      'totalReports': totalReports,
      'intervened': intervened,
      'interventionRate': interventionRate,
    };
  });
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
      'needVerification': reports.where((r) => r.status == 'need_intervention').length,
    };
  });
});
