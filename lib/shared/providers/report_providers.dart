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
