import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/capture/presentation/screens/estimation_status_screen.dart';
import '../../features/capture/presentation/screens/session_completed_screen.dart';
import '../../features/home/data/home_mock_data.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/rodeo/presentation/screens/animal_create_screen.dart';
import '../../features/rodeo/presentation/screens/animal_detail_screen.dart';
import '../../features/rodeo/presentation/screens/rodeo_screen.dart';

class AppRouter {
  static const String homeRoute = '/';
  static const String captureRoute = '/capture';
  static const String rodeoRoute = '/rodeo';
  static const String animalDetailRoute = '/animal-detail';
  static const String animalCreateRoute = '/animal-create';
  static const String traceabilityRoute = '/traceability';
  static const String syncRoute = '/sync';
  static const String estimationStatusRoute = '/estimation-status';
  static const String sessionCompletedRoute = '/session-completed';

  static final GoRouter router = GoRouter(
    initialLocation: homeRoute,
    routes: [
      GoRoute(
        path: homeRoute,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: rodeoRoute,
        builder: (context, state) => const RodeoScreen(),
      ),
      GoRoute(
        path: animalDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnimalDetailScreen(
            initialData: extra,
          );
        },
      ),
      GoRoute(
        path: animalCreateRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnimalCreateScreen(
            isOffline: extra?['isOffline'] as bool?,
            initialLotes: extra?['lotes'] as List<String>?,
          );
        },
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
      GoRoute(
        path: sessionCompletedRoute,
        builder: (context, state) {
          if (state.extra is SessionCompletedData) {
            return SessionCompletedScreen(
              initialData: state.extra as SessionCompletedData,
            );
          }
          if (state.extra is RecentSessionModel) {
            return SessionCompletedScreen.fromSession(
              session: state.extra as RecentSessionModel,
            );
          }
          return const SessionCompletedScreen();
        },
      ),
    ],
  );
}
