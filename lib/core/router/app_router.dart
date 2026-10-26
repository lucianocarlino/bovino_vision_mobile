import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/alerts_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/capture/presentation/capture_flow_screen.dart';
import '../../features/capture/presentation/capture_home_screen.dart';
import '../../features/lots/presentation/lots_screen.dart';
import '../../features/panel/panel_screen.dart';
import '../../features/rodeo/presentation/animal_create_screen.dart';
import '../../features/rodeo/presentation/animal_detail_screen.dart';
import '../../features/rodeo/presentation/rodeo_screen.dart';
import '../auth/auth_controller.dart';
import 'app_shell.dart';
import 'sections.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const noAccess = '/sin-acceso';
  static const capture = '/captura';

  /// New capture wizard; `?animal=<id>` skips the identification step.
  static const captureNew = '/captura/nueva';
  static const rodeo = '/animales';
  static const animalNew = '/animales/nuevo';
  static const lots = '/lotes';
  static const panel = '/panel';
  static const alerts = '/alertas';

  static String animal(String id) => '/animales/$id';
  static String captureFor(String animalId) => '$captureNew?animal=$animalId';
}

/// Decides where a navigation lands given the session state; null keeps the location.
String? authRedirect(AuthController auth, String location) {
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      final permissions = auth.session!.permissions;
      final home = homePathFor(permissions);
      if (home == null) return location == AppRoutes.noAccess ? null : AppRoutes.noAccess;
      if (location == AppRoutes.splash || location == AppRoutes.login || location == AppRoutes.noAccess) return home;
      final section = sectionFor(location);
      if (section != null && !permissions.contains(section.permission)) return home;
      return null;
  }
}

GoRouter buildRouter(AuthController auth) => GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: auth,
      redirect: (context, state) => authRedirect(auth, state.uri.path),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: AppRoutes.noAccess, builder: (_, _) => const NoAccessScreen()),
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: AppRoutes.capture,
              builder: (_, _) => const CaptureHomeScreen(),
              routes: [
                GoRoute(
                  path: 'nueva',
                  builder: (_, state) => CaptureFlowScreen(animalId: state.uri.queryParameters['animal']),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.rodeo,
              builder: (_, _) => const RodeoScreen(),
              routes: [
                GoRoute(path: 'nuevo', builder: (_, _) => const AnimalCreateScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AnimalDetailScreen(
                    key: ValueKey(state.pathParameters['id']),
                    animalId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(path: AppRoutes.lots, builder: (_, _) => const LotsScreen()),
            GoRoute(path: AppRoutes.panel, builder: (_, _) => const PanelScreen()),
            GoRoute(path: AppRoutes.alerts, builder: (_, _) => const AlertsScreen()),
          ],
        ),
      ],
    );
