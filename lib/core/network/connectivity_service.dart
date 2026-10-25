import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para monitorear conectividad y alcanzabilidad de red (Offline-First).
/// Detecta si hay interfaces de red activas y verifica si el backend/internet
/// es alcanzable en condiciones rurales o de campo.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity;
  final Future<bool> Function()? _customReachabilityChecker;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isBackendReachable = true;
  bool? _simulatedOnline;

  // StreamController para emitir cambios de conectividad efectiva
  final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();

  ConnectivityService({
    Connectivity? connectivity,
    Future<bool> Function()? reachabilityChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _customReachabilityChecker = reachabilityChecker {
    _initConnectivity();
  }

  /// Indica si el dispositivo está en línea y con acceso efectivo
  bool get isOnline => _simulatedOnline ?? (_isOnline && _isBackendReachable);

  /// Indica si hay una interfaz de red conectada (WiFi / Celular)
  bool get hasNetworkInterface => _isOnline;

  /// Indica si el servidor o internet es alcanzable
  bool get isBackendReachable => _isBackendReachable;

  /// Stream para reaccionar a cambios en tiempo real
  Stream<bool> get onConnectivityChanged =>
      _connectivityStreamController.stream;

  /// Permite simular pérdida o recuperación de conexión (útil para pruebas y modo demo)
  void setSimulatedOnline(bool? simulated) {
    if (_simulatedOnline != simulated) {
      _simulatedOnline = simulated;
      final effectiveOnline = isOnline;
      _connectivityStreamController.add(effectiveOnline);
      notifyListeners();
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error al verificar conectividad inicial: $e');
      _isOnline = true;
      _isBackendReachable = true;
      notifyListeners();
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  /// Verifica interfaces activas y luego testea alcanzabilidad de red
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasConnection = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    _isOnline = hasConnection;

    if (!hasConnection) {
      _isBackendReachable = false;
    } else {
      _isBackendReachable = await checkBackendReachability();
    }

    final effectiveStatus = isOnline;
    _connectivityStreamController.add(effectiveStatus);
    notifyListeners();
  }

  /// Comprueba alcanzabilidad mediante DNS/ping a servidor
  Future<bool> checkBackendReachability() async {
    if (_customReachabilityChecker != null) {
      return await _customReachabilityChecker();
    }

    if (kIsWeb) return true;

    try {
      // Intenta resolver host público o backend con timeout corto
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Backend o internet inalcanzable (ej: WiFi sin salida o campo sin señal)
      return false;
    }
  }

  /// Fuerza una verificación manual de conectividad
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
      return isOnline;
    } catch (e) {
      debugPrint('Error comprobando conectividad: $e');
      return isOnline;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectivityStreamController.close();
    super.dispose();
  }
}
