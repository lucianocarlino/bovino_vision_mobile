import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/api_config.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/session_store.dart';
import 'core/data/herd_api.dart';
import 'core/network/connectivity_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only: the app is used one-handed in the field.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: AppColors.white, statusBarIconBrightness: Brightness.dark),
  );

  runApp(BovinoVisionApp(apiClient: ApiClient(baseUrl: Uri.parse(ApiConfig.baseUrl)), sessionStore: FileSessionStore()));
}

/// Root widget. Dependencies are injectable so tests can run it against a fake API.
class BovinoVisionApp extends StatefulWidget {
  const BovinoVisionApp({super.key, required this.apiClient, required this.sessionStore, this.connectivityService});

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ConnectivityService? connectivityService;

  @override
  State<BovinoVisionApp> createState() => _BovinoVisionAppState();
}

class _BovinoVisionAppState extends State<BovinoVisionApp> {
  late final AuthController _auth;
  late final ConnectivityService _connectivity;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(client: widget.apiClient, store: widget.sessionStore)
      ..addListener(_forgetCachedPhotosOnSignOut)
      ..restore();
    _connectivity = widget.connectivityService ?? ConnectivityService(reachabilityChecker: widget.apiClient.isReachable);
    _router = buildRouter(_auth);
  }

  /// Photos are cached by URL, not by session, so the next user must not see the previous one's.
  void _forgetCachedPhotosOnSignOut() {
    if (_auth.status != AuthStatus.signedOut) return;
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    if (widget.connectivityService == null) _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.apiClient),
        Provider<HerdApi>(create: (_) => HerdApi(widget.apiClient)),
        ChangeNotifierProvider<AuthController>.value(value: _auth),
        ChangeNotifierProvider<ConnectivityService>.value(value: _connectivity),
      ],
      child: MaterialApp.router(
        title: 'BovinoVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
