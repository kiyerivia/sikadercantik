import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_providers.dart';
import '../../features/report/report_repository.dart';
import '../domain/models.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReportRepository(client);
});

final myReportsProvider = FutureProvider<List<Report>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getMyReports();
});

final allReportsProvider = FutureProvider<List<Report>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getAllReports();
});

final interventionsByReportProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, reportId) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getInterventionsByReport(reportId);
});

final interventionCountProvider = Provider<int>((ref) {
  final reportsAsync = ref.watch(myReportsProvider);
  return reportsAsync.maybeWhen(
    data: (reports) => reports.where((r) => r.status == 'need_intervention').length,
    orElse: () => 0,
  );
});
