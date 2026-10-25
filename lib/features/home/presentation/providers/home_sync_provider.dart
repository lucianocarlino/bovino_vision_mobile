import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../capture/data/models/capture_record_model.dart';
import '../../../capture/data/repositories/capture_repository.dart';
import '../../data/home_mock_data.dart';

/// Controlador de estado (ChangeNotifier) para el Dashboard principal y sincronización.
/// Separa la lógica de negocio, persistencia y red de la interfaz visual.
class HomeSyncProvider extends ChangeNotifier {
  final ConnectivityService connectivityService;
  final CaptureRepository captureRepository;
  final SyncService syncService;

  int _pendingCount = 0;
  List<RecentSessionModel> _recentSessions = [];
  bool _isLoading = false;

  UserModel _user = const UserModel(
    name: 'Francisco López',
    initials: 'FL',
    isOnline: true,
  );

  HomeSyncProvider({
    required this.connectivityService,
    required this.captureRepository,
    required this.syncService,
  }) {
    // Escuchar cambios de conectividad
    connectivityService.addListener(_onConnectivityChanged);
    // Escuchar cambios del servicio de sincronización
    syncService.addListener(_onSyncServiceChanged);
    syncService.onSyncCompleted = loadData;

    _updateUserState();
    loadData();
  }

  bool get isLoading => _isLoading;
  bool get isOnline => connectivityService.isOnline;
  bool get isSyncing => syncService.isSyncing;
  int get pendingCount => _pendingCount;
  UserModel get user => _user;
  List<RecentSessionModel> get recentSessions => _recentSessions;

  /// Retorna el modelo dinámico de estado de sincronización
  SyncStatusModel get syncStatus {
    if (isSyncing) {
      return SyncStatusModel(
        isSynced: false,
        title: 'Sincronizando registros...',
        message: 'Subiendo pesajes locales al servidor central...',
        pendingCount: _pendingCount,
        isSyncing: true,
      );
    }

    if (_pendingCount > 0) {
      final unit = _pendingCount == 1 ? 'pesaje pendiente' : 'pesajes pendientes';
      return SyncStatusModel(
        isSynced: false,
        title: '$_pendingCount $unit de sincronización',
        message: isOnline
            ? 'Conexión activa. Sincronización en segundo plano disponible.'
            : 'Almacenado localmente en SQLite. Se sincronizará al conectar.',
        pendingCount: _pendingCount,
        isSyncing: false,
      );
    }

    return const SyncStatusModel(
      isSynced: true,
      title: 'Sincronización completa',
      message: 'Los datos del rodeo están actualizados.',
      pendingCount: 0,
      isSyncing: false,
    );
  }

  /// Retorna las métricas del rodeo
  MetricsModel get metrics {
    return MetricsModel(
      totalRodeo: 1248,
      activeLotes: 6,
      capturesToday: 42 + _pendingCount,
    );
  }

  void _onConnectivityChanged() {
    _updateUserState();
    notifyListeners();
  }

  void _onSyncServiceChanged() {
    notifyListeners();
  }

  void _updateUserState() {
    _user = _user.copyWith(isOnline: connectivityService.isOnline);
  }

  /// Carga datos persistidos desde SQLite y actualiza el estado
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingCount = await captureRepository.getPendingCount();
      _recentSessions = await captureRepository.getCombinedRecentSessions();
    } catch (e) {
      debugPrint('[HomeSyncProvider] Error al cargar datos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dispara una sincronización manual o en segundo plano
  Future<bool> syncNow() async {
    final success = await syncService.syncPendingRecords();
    await loadData();
    return success;
  }

  /// Registra una sesión de capturas/pesajes en la base de datos local SQLite
  Future<void> recordCaptureSession({
    required String sessionId,
    required List<CaptureRecordModel> captures,
  }) async {
    await captureRepository.saveSessionCaptures(captures);
    await loadData();

    // Si hay conexión activa, intentar sincronizar de inmediato en segundo plano
    if (isOnline) {
      syncService.syncPendingRecords();
    }
  }

  /// Permite simular cambio de estado de red para demostración y testing
  void setSimulatedConnectivity(bool? online) {
    connectivityService.setSimulatedOnline(online);
  }

  @override
  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }
}
