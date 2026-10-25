import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/connectivity_service.dart';
import '../../features/capture/data/repositories/capture_repository.dart';

/// Servicio encargado de la sincronización en segundo plano de registros locales
/// hacia el backend al detectar conectividad activa.
class SyncService extends ChangeNotifier {
  final ConnectivityService connectivityService;
  final CaptureRepository captureRepository;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<bool>? _connectivitySubscription;

  // Callback opcional invocado al completar una sincronización
  VoidCallback? onSyncCompleted;

  SyncService({
    required this.connectivityService,
    required this.captureRepository,
    this.onSyncCompleted,
  }) {
    _initAutoSync();
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  void _initAutoSync() {
    _connectivitySubscription =
        connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('[SyncService] Conectividad recuperada. Verificando registros pendientes...');
        syncPendingRecords();
      }
    });
  }

  /// Ejecuta el proceso de sincronización de pesajes pendientes hacia el backend
  Future<bool> syncPendingRecords() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Sincronización ya en curso. Omitiendo.');
      return false;
    }

    if (!connectivityService.isOnline) {
      debugPrint('[SyncService] Sin conexión o backend inalcanzable. No es posible sincronizar.');
      return false;
    }

    final pending = await captureRepository.getPendingCaptures();
    if (pending.isEmpty) {
      debugPrint('[SyncService] No hay registros locales pendientes de sincronización.');
      return true;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('[SyncService] Sincronizando ${pending.length} pesajes pendientes...');

      // Simulación de envío al backend en segundo plano con control de latencia
      await Future.delayed(const Duration(milliseconds: 700));

      // Verificación final de conectividad antes de confirmar
      if (!connectivityService.isOnline) {
        debugPrint('[SyncService] Conexión perdida durante la sincronización.');
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Marcar registros como sincronizados en SQLite
      final idsToMark = pending.map((c) => c.id).toList();
      await captureRepository.markCapturesSynced(idsToMark);

      _lastSyncTime = DateTime.now();
      debugPrint('[SyncService] Sincronización completada exitosamente.');
      onSyncCompleted?.call();
      return true;
    } catch (e) {
      debugPrint('[SyncService] Error durante sincronización: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
