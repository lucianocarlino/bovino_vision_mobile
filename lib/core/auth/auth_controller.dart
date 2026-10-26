import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'session.dart';
import 'session_store.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Owns the login session: restores it on startup, logs in and out, and signs out when
/// the API answers 401.
class AuthController extends ChangeNotifier {
  AuthController({required this._client, required this._store, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _client.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _client;
  final SessionStore _store;
  final DateTime Function() _clock;

  AuthStatus _status = AuthStatus.unknown;
  Session? _session;
  bool _expired = false;

  AuthStatus get status => _status;
  Session? get session => _session;

  /// True after the server ended the session (401); the login screen explains it.
  bool get sessionExpired => _expired;

  bool can(String permission) => _session?.can(permission) ?? false;

  /// Reopens the stored session. Without connection the cached session is trusted
  /// until its expiry; the server still has the last word on the next request.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored == null || stored.session.isExpired(_clock())) {
      await _store.clear();
      _setSignedOut();
      return;
    }

    _client.sessionToken = stored.token;
    try {
      final json = await _client.get('/auth/sesion');
      final session = Session.fromJson(json as Map<String, Object?>);
      await _store.write(StoredSession(token: stored.token, session: session));
      _setSignedIn(session);
    } on ApiException catch (error) {
      if (error.isUnauthorized) return; // _handleUnauthorized already signed out.
      _setSignedIn(stored.session);
    }
  }

  /// Logs in; throws [ApiException] with the server message on failure.
  Future<void> login(String email, String password) async {
    final response = await _client.send(
      'POST',
      '/auth/sesion',
      body: {'correo': email.trim(), 'contrasena': password},
      handleUnauthorized: false,
    );
    final token = extractSessionToken(response.headers['set-cookie']);
    if (token == null) {
      throw const ApiException('El servidor no devolvió la sesión. Revisá la URL del backend.');
    }
    final session = Session.fromJson(_client.decodeJson(response) as Map<String, Object?>);
    _client.sessionToken = token;
    await _store.write(StoredSession(token: token, session: session));
    _expired = false;
    _setSignedIn(session);
  }

  /// Ends the session on the server when possible and always forgets it locally.
  Future<void> logout() async {
    try {
      await _client.send('DELETE', '/auth/sesion', handleUnauthorized: false);
    } on ApiException {
      // The local session is dropped anyway; the server one expires on its own.
    }
    await _clearLocal();
    _setSignedOut();
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.signedOut) return;
    _expired = _status == AuthStatus.signedIn;
    _clearLocal();
    _setSignedOut();
  }

  Future<void> _clearLocal() async {
    _client.sessionToken = null;
    await _store.clear();
  }

  void _setSignedIn(Session session) {
    _session = session;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  void _setSignedOut() {
    _session = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
