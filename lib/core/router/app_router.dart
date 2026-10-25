import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/capture/presentation/screens/estimation_status_screen.dart';
import '../../features/home/data/home_mock_data.dart';
import '../../features/home/presentation/screens/home_screen.dart';

class AppRouter {
  static const String homeRoute = '/';
  static const String captureRoute = '/capture';
  static const String traceabilityRoute = '/traceability';
  static const String syncRoute = '/sync';
  static const String estimationStatusRoute = '/estimation-status';

  static final GoRouter router = GoRouter(
    initialLocation: homeRoute,
    routes: [
      GoRoute(
        path: homeRoute,
        builder: (context, state) => const HomeScreen(),
      ),
      // Rutas del MVP delimitadas para fases subsiguientes
      GoRoute(
        path: captureRoute,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Not implemented')),
        ),
      ),
      GoRoute(
        path: traceabilityRoute,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Not implemented')),
        ),
      ),
      GoRoute(
        path: syncRoute,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Not implemented')),
        ),
      ),
      GoRoute(
        path: estimationStatusRoute,
        builder: (context, state) {
          final session = state.extra as RecentSessionModel?;
          if (session != null) {
            return EstimationStatusScreen.fromSession(session: session);
          }
          return const EstimationStatusScreen();
        },
      ),
    ],
  );
}
