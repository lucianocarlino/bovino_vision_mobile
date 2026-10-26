import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the backend can be reached: a network interface must be up and
/// the reachability check (by default `GET /health`) must succeed.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({required Future<bool> Function() reachabilityChecker, Connectivity? connectivity})
      : _checkReachability = reachabilityChecker,
        _connectivity = connectivity ?? Connectivity() {
    _start();
  }

  /// Fixed state without platform plugins, for tests.
  ConnectivityService.fixed(bool online)
      : _checkReachability = (() async => online),
        _connectivity = null,
        _isOnline = online;

  final Future<bool> Function() _checkReachability;
  final Connectivity? _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _disposed = false;

  bool get isOnline => _isOnline;

  Future<void> _start() async {
    final connectivity = _connectivity!;
    try {
      _subscription = connectivity.onConnectivityChanged.listen(_update);
      await _update(await connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('Connectivity plugin unavailable, assuming online: $error');
    }
  }

  Future<void> _update(List<ConnectivityResult> results) async {
    final hasInterface = results.any((result) => result != ConnectivityResult.none);
    _setOnline(hasInterface && await _checkReachability());
  }

  /// Checks again now, e.g. when the user retries after a failure.
  Future<bool> refresh() async {
    final connectivity = _connectivity;
    if (connectivity == null) {
      _setOnline(await _checkReachability());
    } else {
      await _update(await connectivity.checkConnectivity());
    }
    return _isOnline;
  }

  void _setOnline(bool online) {
    if (_disposed || online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
