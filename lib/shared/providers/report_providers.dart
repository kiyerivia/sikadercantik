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

final allAdminNotesProvider = FutureProvider<Map<String, String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('interventions')
      .select('report_id, description')
      .eq('type', 'Tindakan')
      .order('created_at', ascending: true);
  
  Map<String, String> map = {};
  for (var row in (response as List)) {
    map[row['report_id'] as String] = row['description'] as String;
  }
  return map;
});

final interventionCountProvider = Provider<int>((ref) {
  final reportsAsync = ref.watch(myReportsProvider);
  return reportsAsync.maybeWhen(
    data: (reports) => reports.where((r) => r.status == 'need_intervention').length,
    orElse: () => 0,
  );
});

final pendingVerificationCountProvider = Provider<int>((ref) {
  final reportsAsync = ref.watch(allReportsProvider);
  return reportsAsync.maybeWhen(
    data: (reports) => reports.where((r) => r.status == 'submitted').length,
    orElse: () => 0,
  );
});
