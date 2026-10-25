import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/network/connectivity_service.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/capture/data/repositories/capture_repository.dart';
import 'features/home/presentation/providers/home_sync_provider.dart';

void main() async {
  // Asegura la inicialización de los bindings nativos de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de orientación vertical y barra de estado de sistema para uso en campo
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BovinoVisionApp());
}

/// Punto de entrada del árbol de Widgets de BovinoVision con arquitectura Offline-First
class BovinoVisionApp extends StatefulWidget {
  final ConnectivityService? connectivityService;
  final CaptureRepository? captureRepository;
  final SyncService? syncService;
  final HomeSyncProvider? homeSyncProvider;

  const BovinoVisionApp({
    super.key,
    this.connectivityService,
    this.captureRepository,
    this.syncService,
    this.homeSyncProvider,
  });

  @override
  State<BovinoVisionApp> createState() => _BovinoVisionAppState();
}

class _BovinoVisionAppState extends State<BovinoVisionApp> {
  late final ConnectivityService _connectivityService;
  late final CaptureRepository _captureRepository;
  late final SyncService _syncService;
  late final HomeSyncProvider _homeSyncProvider;

  @override
  void initState() {
    super.initState();
    _connectivityService = widget.connectivityService ?? ConnectivityService();
    _captureRepository = widget.captureRepository ?? CaptureRepository();
    _syncService = widget.syncService ??
        SyncService(
          connectivityService: _connectivityService,
          captureRepository: _captureRepository,
        );
    _homeSyncProvider = widget.homeSyncProvider ??
        HomeSyncProvider(
          connectivityService: _connectivityService,
          captureRepository: _captureRepository,
          syncService: _syncService,
        );
  }

  @override
  void dispose() {
    if (widget.homeSyncProvider == null) _homeSyncProvider.dispose();
    if (widget.syncService == null) _syncService.dispose();
    if (widget.connectivityService == null) _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>.value(value: _connectivityService),
        Provider<CaptureRepository>.value(value: _captureRepository),
        ChangeNotifierProvider<SyncService>.value(value: _syncService),
        ChangeNotifierProvider<HomeSyncProvider>.value(value: _homeSyncProvider),
      ],
      child: MaterialApp.router(
        title: 'BovinoVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
