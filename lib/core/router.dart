import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/admin_analytics_screen.dart';
import '../features/master_data/location_management_screen.dart';
import '../features/report/report_form_screen.dart';
import '../features/report/report_history_screen.dart';
import '../features/report/report_detail_screen.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/domain/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = authState.value;
      final loggingIn = state.matchedLocation == '/login';

      if (auth?.session?.user == null) {
        return '/login';
      }

      if (loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/locations',
        builder: (context, state) => const LocationManagementScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportFormScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const ReportHistoryScreen(),
      ),
      GoRoute(
        path: '/report-detail',
        builder: (context, state) =>
            ReportDetailScreen(report: state.extra as Report),
      ),
    ],
  );
});
