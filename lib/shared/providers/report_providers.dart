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

final myDraftReportsProvider = Provider<List<Report>>((ref) {
  final reportsAsync = ref.watch(myReportsProvider);
  return reportsAsync.maybeWhen(
    data: (reports) => reports.where((r) => r.status == 'draft').toList(),
    orElse: () => [],
  );
});

final allReportsProvider = FutureProvider<List<Report>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getAllReports();
});

final interventionsByReportProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, reportId) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getInterventionsByReport(reportId);
});

final allInterventionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('interventions')
      .select('*')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response as List);
});

final allAdminNotesProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final interventions = await ref.watch(allInterventionsProvider.future);
    Map<String, String> map = {};
    for (var row in interventions) {
      final rId = row['report_id']?.toString();
      final desc = row['description']?.toString();
      if (rId != null && desc != null && !map.containsKey(rId)) {
        map[rId] = desc;
      }
    }
    return map;
  } catch (_) {
    return {};
  }
});

final intervenedReportIdsProvider = Provider<Set<String>>((ref) {
  final interventionsAsync = ref.watch(allInterventionsProvider);
  return interventionsAsync.maybeWhen(
    data: (list) => list
        .map((i) => i['report_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet(),
    orElse: () => <String>{},
  );
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
