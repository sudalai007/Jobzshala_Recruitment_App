import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/jobs/domain/entities/job.dart';
import '../../features/jobs/presentation/pages/job_detail_page.dart';
import '../../features/jobs/presentation/pages/job_matches_page.dart';

class AppRoute {
  final String name;
  final String path;

  AppRoute(this.name, this.path);
}

class CustomNavigationHelper {
  static final CustomNavigationHelper _instance =
      CustomNavigationHelper._internal();

  static CustomNavigationHelper get instance => _instance;

  static late final GoRouter router;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext? get context =>
      router.routerDelegate.navigatorKey.currentContext;

  static final AppRoute matches = AppRoute("matches", "/");
  static final AppRoute jobDetail = AppRoute("jobDetail", "/jobs/:id");

  CustomNavigationHelper._internal() {
    final routes = [
      GoRoute(
        path: matches.path,
        name: matches.name,
        pageBuilder: (context, GoRouterState state) {
          return getPage(
            child: const JobMatchesPage(),
            state: state,
          );
        },
      ),
      GoRoute(
        path: jobDetail.path,
        name: jobDetail.name,
        pageBuilder: (context, GoRouterState state) {
          final jobId = state.pathParameters['id'] ?? '';
          final job = state.extra is Job ? state.extra as Job : null;
          return getPage(
            child: JobDetailPage(jobId: jobId, initialJob: job),
            state: state,
          );
        },
      ),
    ];

    router = GoRouter(
      routes: routes,
      navigatorKey: navigatorKey,
      initialLocation: matches.path,
      debugLogDiagnostics: true,
    );
  }

  static Page getPage({required Widget child, required GoRouterState state}) {
    return MaterialPage(key: state.pageKey, child: child);
  }

  void goToMatches() {
    router.goNamed(matches.name);
  }

  void pushJobDetail(String jobId, {Job? job}) {
    router.pushNamed(
      jobDetail.name,
      pathParameters: {'id': jobId},
      extra: job,
    );
  }

  void pop() {
    if (router.canPop()) {
      router.pop();
    }
  }
}

class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();

  static NavigationHelper get instance => _instance;

  NavigationHelper._internal() {
    debugPrint("**********NavigationHelper called");
  }
}
