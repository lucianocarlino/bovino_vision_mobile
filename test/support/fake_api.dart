import 'dart:convert';

import 'package:bovino_vision_mobile/core/api/api_client.dart';
import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/core/auth/session_store.dart';
import 'package:bovino_vision_mobile/core/network/connectivity_service.dart';
import 'package:bovino_vision_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef FakeHandler = Object? Function(http.Request request);

/// Reply with an explicit status (and optional JSON body) from a [FakeApi] handler.
class FakeReply {
  const FakeReply(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

/// Route-based fake of the BovinoVision API for widget tests.
///
/// Register handlers with `api.on('GET', '/animales', (request) => [...])`. A handler returns
/// a JSON-encodable body (answered with 200) or a [FakeReply]. Unregistered routes answer 404.
/// Every request is recorded in [requests].
class FakeApi {
  FakeApi() {
    on('GET', '/auth/sesion', (_) => sessionJson(permissions));
    on('GET', '/health', (_) => {'status': 'ok'});
  }

  final _handlers = <String, FakeHandler>{};
  final requests = <http.Request>[];
  Set<String> permissions = {Permissions.captureRecord, Permissions.herdRead, Permissions.herdManage};

  void on(String method, String path, FakeHandler handler) => _handlers['$method $path'] = handler;

  /// Requests sent to `METHOD /path` (query string ignored).
  List<http.Request> sent(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == path).toList();

  late final client = ApiClient(
    baseUrl: Uri.parse('http://api.test'),
    httpClient: MockClient((request) async {
      requests.add(request);
      final handler = _handlers['${request.method} ${request.url.path}'];
      if (handler == null) return _json({'title': 'Not Found', 'detail': 'Sin ruta falsa: ${request.method} ${request.url.path}'}, 404);
      final result = handler(request);
      if (result is FakeReply) return _json(result.body, result.status, result.headers);
      return _json(result, 200);
    }),
  );

  static http.Response _json(Object? body, int status, [Map<String, String> headers = const {}]) => http.Response.bytes(
        body == null ? const [] : utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8', ...headers},
      );

  static Map<String, Object?> sessionJson(Set<String> permissions) => {
        'usuario': {
          'id': 'u1',
          'nombre': 'Francisco López',
          'correo': 'fl@campo.ar',
          'id_rol': 'r5',
          'rol': 'Operario de Campo',
          'activo': true,
        },
        'permisos': permissions.toList(),
        'expira_en': DateTime.now().add(const Duration(hours: 8)).toUtc().toIso8601String(),
      };

  /// Store with a valid session, so the app opens signed in.
  SessionStore signedInStore() => MemorySessionStore(
        StoredSession(token: 'test-token', session: Session.fromJson(sessionJson(permissions))),
      );
}

/// Pumps the whole app against [api], signed in unless [signedIn] is false, and optionally
/// navigates to [location].
Future<void> pumpApp(
  WidgetTester tester,
  FakeApi api, {
  String? location,
  bool signedIn = true,
  bool online = true,
}) async {
  await tester.pumpWidget(
    BovinoVisionApp(
      apiClient: api.client,
      sessionStore: signedIn ? api.signedInStore() : MemorySessionStore(),
      connectivityService: ConnectivityService.fixed(online),
    ),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    goTo(tester, location);
    await tester.pumpAndSettle();
  }
}

/// Navigates the running app to [location].
void goTo(WidgetTester tester, String location) {
  final context = tester.element(find.byType(Navigator).first);
  GoRouter.of(context).go(location);
}

/// Current path of the running app.
String currentPath(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
}
