import 'dart:convert';

import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  testWidgets('without a stored session the app opens the login screen', (tester) async {
    await pumpApp(tester, FakeApi(), signedIn: false);

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('login sends the credentials and lands on the home section of the role', (tester) async {
    final api = FakeApi()
      ..on('POST', '/auth/sesion', (_) => FakeReply(200, FakeApi.sessionJson({Permissions.captureRecord, Permissions.herdRead}), {
            'set-cookie': 'bovinovision_sesion=nuevo; path=/; secure; samesite=strict; httponly',
          }));
    await pumpApp(tester, api, signedIn: false);

    await tester.enterText(find.byType(TextFormField).at(0), 'fl@campo.ar');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(jsonDecode(api.sent('POST', '/auth/sesion').single.body), {'correo': 'fl@campo.ar', 'contrasena': 'secreto123'});
    expect(currentPath(tester), '/captura');
  });

  testWidgets('a rejected login shows the server message', (tester) async {
    final api = FakeApi()..on('POST', '/auth/sesion', (_) => const FakeReply(401, {'detail': 'Usuario o contraseña incorrectos.'}));
    await pumpApp(tester, api, signedIn: false);

    await tester.enterText(find.byType(TextFormField).at(0), 'fl@campo.ar');
    await tester.enterText(find.byType(TextFormField).at(1), 'mala');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(currentPath(tester), '/login');
  });

  testWidgets('empty credentials are not sent', (tester) async {
    final api = FakeApi();
    await pumpApp(tester, api, signedIn: false);

    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá tu correo.'), findsOneWidget);
    expect(find.text('Ingresá tu contraseña.'), findsOneWidget);
    expect(api.sent('POST', '/auth/sesion'), isEmpty);
  });

  testWidgets('the bottom bar shows only the sections the operator may open', (tester) async {
    await pumpApp(tester, FakeApi());

    expect(currentPath(tester), '/captura');
    expect(find.text('Captura'), findsWidgets);
    expect(find.text('Rodeo'), findsOneWidget);
    expect(find.text('Lotes'), findsOneWidget);
    expect(find.text('Panel'), findsNothing);
    expect(find.text('Alertas'), findsNothing);
  });

  testWidgets('analytics users also get Panel and Alertas', (tester) async {
    final api = FakeApi()..permissions = {Permissions.herdRead, Permissions.analyticsRead};
    await pumpApp(tester, api);

    expect(currentPath(tester), '/panel');
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Captura'), findsNothing);
  });

  testWidgets('a section without permission redirects to the home section', (tester) async {
    await pumpApp(tester, FakeApi(), location: '/panel');
    expect(currentPath(tester), '/captura');
  });

  testWidgets('tapping a bottom bar item navigates to its section', (tester) async {
    await pumpApp(tester, FakeApi());

    await tester.tap(find.text('Lotes'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/lotes');
  });

  testWidgets('a role without mobile sections sees the no-access screen', (tester) async {
    final api = FakeApi()..permissions = {'usuarios_gestionar'};
    await pumpApp(tester, api);

    expect(find.textContaining('Tu rol no tiene acceso a la aplicación móvil'), findsOneWidget);
  });

  testWidgets('logout ends the session on the server and returns to login', (tester) async {
    final api = FakeApi()..on('DELETE', '/auth/sesion', (_) => const FakeReply(204));
    await pumpApp(tester, api);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(api.sent('DELETE', '/auth/sesion').single.headers['Cookie'], 'bovinovision_sesion=test-token');
    expect(currentPath(tester), '/login');
  });

  testWidgets('a 401 during use returns to login with the expired-session notice', (tester) async {
    final api = FakeApi();
    await pumpApp(tester, api);
    api.on('GET', '/lotes', (_) => const FakeReply(401, {'detail': 'Iniciá sesión para continuar.'}));

    await api.client.get('/lotes').catchError((_) => null);
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/login');
    expect(find.text('Tu sesión terminó. Iniciá sesión de nuevo.'), findsOneWidget);
  });
}
