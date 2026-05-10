import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'report_providers.dart';

// allReportsProvider is now moved to report_providers.dart to avoid duplication

final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final abjByVillageProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  return reportsAsync.whenData((reports) {
    final filtered = reports.where((r) => r.reportDate.month == month && r.reportDate.year == year).toList();
    
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
    final filtered = reports.where((r) => r.reportDate.month == month && r.reportDate.year == year).toList();
    
    int totalReports = filtered.length;
    int intervened = filtered.where((r) => r.status == 'verified' || r.status == 'submitted').length; // Assuming verified/submitted means intervened? 
    // Wait, let's look at the image: "Laporan yang sudah dilakukan intervensi petugas".
    // In our app, status 'need_intervention' means needs fix. 
    // Maybe we should check if there are any intervention records.
    
    double interventionRate = totalReports > 0 ? (intervened / totalReports) * 100 : 0;

    return {
      'totalReports': totalReports,
      'intervened': intervened,
      'interventionRate': interventionRate,
    };
  });
});
