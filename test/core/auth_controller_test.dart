import 'dart:convert';
import 'dart:io';

import 'package:bovino_vision_mobile/core/api/api_client.dart';
import 'package:bovino_vision_mobile/core/api/api_exception.dart';
import 'package:bovino_vision_mobile/core/auth/auth_controller.dart';
import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/core/auth/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final now = DateTime.utc(2026, 10, 25, 12);

Map<String, Object?> sessionJson({String expires = '2026-10-26T00:00:00Z', List<String> permisos = const ['capturas_registrar']}) => {
      'usuario': {'id': 'u1', 'nombre': 'Francisco López', 'correo': 'fl@campo.ar', 'id_rol': 'r', 'rol': 'Operario de Campo', 'activo': true},
      'permisos': permisos,
      'expira_en': expires,
    };

http.Response json(Object? body, int status, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

StoredSession stored({String token = 'old', String expires = '2026-10-26T00:00:00Z'}) =>
    StoredSession(token: token, session: Session.fromJson(sessionJson(expires: expires)));

void main() {
  test('login keeps the cookie token, stores the session and signs in', () async {
    late http.Request loginRequest;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((request) async {
        loginRequest = request;
        return json(sessionJson(), 200, headers: {'set-cookie': 'bovinovision_sesion=tok42; path=/; secure; samesite=strict; httponly'});
      }),
    );
    final store = MemorySessionStore();
    final auth = AuthController(client: client, store: store, clock: () => now);

    await auth.login(' fl@campo.ar ', 'secreto123');

    expect(jsonDecode(loginRequest.body), {'correo': 'fl@campo.ar', 'contrasena': 'secreto123'});
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.session!.user.name, 'Francisco López');
    expect(auth.can(Permissions.captureRecord), isTrue);
    expect(auth.can(Permissions.analyticsRead), isFalse);
    expect(client.sessionToken, 'tok42');
    expect(store.stored!.token, 'tok42');
  });

  test('login failure surfaces the server detail and stays signed out', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((_) async => json({'detail': 'Usuario o contraseña incorrectos.'}, 401)),
    );
    final store = MemorySessionStore();
    final auth = AuthController(client: client, store: store, clock: () => now);
    await auth.restore();

    await expectLater(
      auth.login('x@y.z', 'mala'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Usuario o contraseña incorrectos.')),
    );
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isFalse);
    expect(store.stored, isNull);
  });

  test('restore without a stored session signs out', () async {
    final auth = AuthController(
      client: ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => fail('no request expected'))),
      store: MemorySessionStore(),
      clock: () => now,
    );
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
  });

  test('restore drops an expired stored session without calling the server', () async {
    final store = MemorySessionStore(stored(expires: '2026-10-25T11:00:00Z'));
    final auth = AuthController(
      client: ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => fail('no request expected'))),
      store: store,
      clock: () => now,
    );
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
    expect(store.stored, isNull);
  });

  test('restore validates the stored token and refreshes the cached session', () async {
    late http.Request request;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((r) async {
        request = r;
        return json(sessionJson(permisos: ['capturas_registrar', 'rodeo_consultar']), 200);
      }),
    );
    final store = MemorySessionStore(stored());
    final auth = AuthController(client: client, store: store, clock: () => now);

    await auth.restore();

    expect(request.method, 'GET');
    expect(request.url.path, '/auth/sesion');
    expect(request.headers['Cookie'], 'bovinovision_sesion=old');
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.can(Permissions.herdRead), isTrue);
    expect(store.stored!.session.permissions, contains('rodeo_consultar'));
  });

  test('restore signs out and forgets the token when the server answers 401', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((_) async => json({'detail': 'Iniciá sesión para continuar.'}, 401)),
    );
    final store = MemorySessionStore(stored());
    final auth = AuthController(client: client, store: store, clock: () => now);

    await auth.restore();

    expect(auth.status, AuthStatus.signedOut);
    expect(store.stored, isNull);
    expect(client.sessionToken, isNull);
  });

  test('restore keeps the cached session when the server is unreachable', () async {
    final client = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => throw const SocketException('down')));
    final auth = AuthController(client: client, store: MemorySessionStore(stored()), clock: () => now);

    await auth.restore();

    expect(auth.status, AuthStatus.signedIn);
    expect(auth.session!.user.name, 'Francisco López');
    expect(client.sessionToken, 'old');
  });

  test('a 401 on any later request signs out and flags the expired session', () async {
    var authorized = true;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((_) async => authorized ? json(sessionJson(), 200) : json({'detail': 'Iniciá sesión para continuar.'}, 401)),
    );
    final store = MemorySessionStore(stored());
    final auth = AuthController(client: client, store: store, clock: () => now);
    await auth.restore();
    expect(auth.status, AuthStatus.signedIn);

    authorized = false;
    await expectLater(client.get('/animales'), throwsA(isA<ApiException>()));
    await Future<void>.delayed(Duration.zero);

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
    expect(store.stored, isNull);
  });

  test('logout clears the local session even if the server call fails', () async {
    final client = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((r) async {
      if (r.method == 'DELETE') throw const SocketException('down');
      return json(sessionJson(), 200);
    }));
    final store = MemorySessionStore(stored());
    final auth = AuthController(client: client, store: store, clock: () => now);
    await auth.restore();

    await auth.logout();

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isFalse);
    expect(store.stored, isNull);
    expect(client.sessionToken, isNull);
  });
}
