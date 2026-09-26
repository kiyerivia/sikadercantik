import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'report_providers.dart';
import '../domain/models.dart';

class MonthNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().month;
  void set(int val) => state = val;
}

final selectedMonthProvider =
    NotifierProvider<MonthNotifier, int>(MonthNotifier.new);

class YearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void set(int val) => state = val;
}

final selectedYearProvider =
    NotifierProvider<YearNotifier, int>(YearNotifier.new);

// ─────────────────────────────────────────────────────────
//  Detailed Village ABJ Model
// ─────────────────────────────────────────────────────────

class VillageAbjDetail {
  final String villageName;
  final int totalInspected;
  final int totalPositive;
  final int totalFree;
  final double abj;
  final double houseIndex;
  final int reportCount;
  final int posyanduCount;
  final List<Report> reports;

  const VillageAbjDetail({
    required this.villageName,
    required this.totalInspected,
    required this.totalPositive,
    required this.totalFree,
    required this.abj,
    required this.houseIndex,
    required this.reportCount,
    this.posyanduCount = 0,
    this.reports = const [],
  });

  bool get isTargetMet => abj >= 95.0; // Standar Kemenkes RI ≥ 95%
  bool get isWarning => abj >= 85.0 && abj < 95.0;
  bool get isDanger => abj < 85.0;

  String get statusCategory {
    if (abj >= 95.0) return 'Memenuhi Target (≥95%)';
    if (abj >= 85.0) return 'Waspada (85-94.9%)';
    return 'Rawan Jentik (<85%)';
  }

  Color get statusColor {
    if (abj >= 95.0) return const Color(0xFF22C55E); // Green
    if (abj >= 85.0) return const Color(0xFFF59E0B); // Amber / Waspada
    return const Color(0xFFEF4444); // Red / Bahaya
  }

  String get recommendation {
    if (abj >= 95.0) {
      return 'Pertahankan pemantauan rutin PSN mingguan & apresiasi kader.';
    } else if (abj >= 85.0) {
      return 'Tingkatkan gerakan PSN 3M Plus serentak & penyuluhan warga.';
    } else {
      return 'Intervensi segera! Pelaksanaan PSN masif, abatisasi selektif & fogging fokus.';
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Monthly ABJ Trend Model
// ─────────────────────────────────────────────────────────

class MonthlyAbjTrend {
  final int month;
  final String monthName;
  final int inspected;
  final int positive;
  final int free;
  final double abj;
  final bool hasData;

  const MonthlyAbjTrend({
    required this.month,
    required this.monthName,
    required this.inspected,
    required this.positive,
    required this.free,
    required this.abj,
    required this.hasData,
  });
}

// ─────────────────────────────────────────────────────────
//  Providers
// ─────────────────────────────────────────────────────────

final villageAbjDetailsProvider =
    Provider<AsyncValue<List<VillageAbjDetail>>>((ref) {
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
      final village = (r.villageName != null && r.villageName!.isNotEmpty)
          ? r.villageName!
          : 'Wilayah Umum';
      grouped.putIfAbsent(village, () => []).add(r);
    }

    final List<VillageAbjDetail> details = [];
    grouped.forEach((village, villageReports) {
      int totalInspected = 0;
      int totalPositive = 0;
      final Set<String> posyandus = {};

      for (var r in villageReports) {
        totalInspected += r.housesInspected;
        final safePos = r.housesPositive.clamp(0, r.housesInspected);
        totalPositive += safePos;
        if (r.posyanduName != null && r.posyanduName!.isNotEmpty) {
          posyandus.add(r.posyanduName!);
        }
      }

      final safePos = totalPositive.clamp(0, totalInspected);
      final safeFree = (totalInspected - safePos).clamp(0, totalInspected);
      final abj = totalInspected > 0
          ? ((safeFree / totalInspected) * 100.0).clamp(0.0, 100.0)
          : 100.0;
      final hi = totalInspected > 0
          ? ((safePos / totalInspected) * 100.0).clamp(0.0, 100.0)
          : 0.0;

      details.add(VillageAbjDetail(
        villageName: village,
        totalInspected: totalInspected,
        totalPositive: safePos,
        totalFree: safeFree,
        abj: abj,
        houseIndex: hi,
        reportCount: villageReports.length,
        posyanduCount: posyandus.length,
        reports: villageReports,
      ));
    });

    // Default sort: alphabetical by village name
    details.sort((a, b) => a.villageName.compareTo(b.villageName));
    return details;
  });
});

final abjByVillageProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  final detailsAsync = ref.watch(villageAbjDetailsProvider);
  return detailsAsync.whenData((details) {
    final Map<String, double> map = {};
    for (var d in details) {
      map[d.villageName] = d.abj;
    }
    return map;
  });
});

final monthlyAbjTrendProvider =
    Provider<AsyncValue<List<MonthlyAbjTrend>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  final year = ref.watch(selectedYearProvider);

  const monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  return reportsAsync.whenData((reports) {
    final targetYear = year == 0 ? DateTime.now().year : year;
    final yearReports =
        reports.where((r) => r.reportDate.year == targetYear).toList();

    final List<MonthlyAbjTrend> trends = [];
    for (int m = 1; m <= 12; m++) {
      final mReports =
          yearReports.where((r) => r.reportDate.month == m).toList();
      int inspected = 0;
      int positive = 0;
      for (var r in mReports) {
        inspected += r.housesInspected;
        positive += r.housesPositive.clamp(0, r.housesInspected);
      }
      final safePositive = positive.clamp(0, inspected);
      final safeFree = (inspected - safePositive).clamp(0, inspected);
      final bool hasData = mReports.isNotEmpty && inspected > 0;
      final abj = hasData
          ? ((safeFree / inspected) * 100.0).clamp(0.0, 100.0)
          : (m <= DateTime.now().month ? 100.0 : 0.0);

      trends.add(MonthlyAbjTrend(
        month: m,
        monthName: monthNames[m],
        inspected: inspected,
        positive: safePositive,
        free: safeFree,
        abj: abj,
        hasData: hasData,
      ));
    }
    return trends;
  });
});

final dashboardStatsProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
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
    int intervened = filtered
        .where((r) => r.status == 'verified' || r.status == 'submitted')
        .length;

    double interventionRate =
        totalReports > 0 ? (intervened / totalReports) * 100 : 0;

    int totalInspected = 0;
    int totalPositive = 0;
    for (var r in filtered) {
      totalInspected += r.housesInspected;
      totalPositive += r.housesPositive.clamp(0, r.housesInspected);
    }
    final safePositive = totalPositive.clamp(0, totalInspected);
    final safeFree = (totalInspected - safePositive).clamp(0, totalInspected);
    final avgAbj = totalInspected > 0
        ? ((safeFree / totalInspected) * 100.0).clamp(0.0, 100.0)
        : 100.0;

    return {
      'totalReports': totalReports,
      'intervened': intervened,
      'interventionRate': interventionRate,
      'totalInspected': totalInspected,
      'totalPositive': safePositive,
      'totalFree': safeFree,
      'avgAbj': avgAbj,
    };
  });
});

final adminStatsProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  return reportsAsync.whenData((reports) {
    int totalInspected = 0;
    int totalPositive = 0;
    for (var r in reports) {
      totalInspected += r.housesInspected;
      totalPositive += r.housesPositive.clamp(0, r.housesInspected);
    }
    final safePos = totalPositive.clamp(0, totalInspected);
    final safeFree = (totalInspected - safePos).clamp(0, totalInspected);
    double abj = totalInspected > 0
        ? ((safeFree / totalInspected) * 100.0).clamp(0.0, 100.0)
        : 100.0;
    return {
      'totalInspected': totalInspected,
      'totalPositive': safePos,
      'abj': abj,
      'reportCount': reports.length,
      'needVerification':
          reports.where((r) => r.status == 'need_intervention').length,
    };
  });
});
