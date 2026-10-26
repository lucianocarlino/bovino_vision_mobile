import 'dart:convert';

import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_api.dart';

void useTallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 3000);
  addTearDown(tester.view.reset);
}

Map<String, Object?> lot(String id, String code, {String? name, double? target, int count = 0}) =>
    {'id': id, 'codigo': code, 'nombre': name, 'gmd_objetivo': target, 'cantidad_animales': count};

FakeApi apiWithLots() {
  final api = FakeApi();
  api.on('GET', '/lotes', (_) => [lot('l1', 'A1', name: 'Recría', target: 0.8, count: 12), lot('l2', 'B2', count: 4)]);
  return api;
}

void main() {
  testWidgets('lists the lots with name, animals, share of the herd and target', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    await pumpApp(tester, api, location: '/lotes');

    expect(find.text('Lotes'), findsWidgets);
    expect(find.text('2 lotes'), findsOneWidget);
    expect(find.text('Lote A1'), findsOneWidget);
    expect(find.text('NOMBRE Recría'), findsOneWidget);
    expect(find.text('ANIMALES 12'), findsOneWidget);
    expect(find.text('75 %'), findsOneWidget);
    expect(find.text('GMD OBJETIVO 0,80 kg/día'), findsOneWidget);
    expect(find.text('Lote B2'), findsOneWidget);
    expect(find.text('NOMBRE Sin nombre'), findsOneWidget);
    expect(find.text('25 %'), findsOneWidget);
    expect(find.text('GMD OBJETIVO Sin objetivo'), findsOneWidget);
    expect(api.sent('GET', '/lotes'), hasLength(1));
  });

  testWidgets('creating a lot posts the form and reloads the list', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    api.on('POST', '/lotes', (_) => lot('l3', 'C3', name: 'Engorde', target: 0.9));
    await pumpApp(tester, api, location: '/lotes');

    expect(find.text('Código de lote'), findsOneWidget);
    expect(find.text('Nombre (opcional)'), findsOneWidget);
    expect(find.text('GMD objetivo, kg/día (opcional)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'C3');
    await tester.enterText(find.byType(TextField).at(1), 'Engorde');
    await tester.enterText(find.byType(TextField).at(2), '0,9');
    await tester.pump();
    await tester.tap(find.text('Crear lote'));
    await tester.pumpAndSettle();

    expect(jsonDecode(api.sent('POST', '/lotes').single.body), {'codigo': 'C3', 'nombre': 'Engorde', 'gmd_objetivo': 0.9});
    expect(api.sent('GET', '/lotes'), hasLength(2));
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, isEmpty);
  });

  testWidgets('a duplicated code shows the 409 detail', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    api.on('POST', '/lotes', (_) => const FakeReply(409, {'detail': 'Ya existe un lote con ese código.'}));
    await pumpApp(tester, api, location: '/lotes');

    await tester.enterText(find.byType(TextField).at(0), 'A1');
    await tester.pump();
    await tester.tap(find.text('Crear lote'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe un lote con ese código.'), findsOneWidget);
    expect(api.sent('GET', '/lotes'), hasLength(1));
  });

  testWidgets('a target that is not a positive number is rejected before the request', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    await pumpApp(tester, api, location: '/lotes');

    await tester.enterText(find.byType(TextField).at(0), 'C3');
    await tester.enterText(find.byType(TextField).at(2), 'abc');
    await tester.pump();
    await tester.tap(find.text('Crear lote'));
    await tester.pumpAndSettle();
    expect(find.text('La GMD objetivo debe ser un número'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(2), '-1');
    await tester.tap(find.text('Crear lote'));
    await tester.pumpAndSettle();
    expect(find.text('La GMD objetivo debe ser positiva'), findsOneWidget);
    expect(api.sent('POST', '/lotes'), isEmpty);
  });

  testWidgets('without rodeo_gestionar there is no create form and no edit button', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots()..permissions = {Permissions.herdRead};
    await pumpApp(tester, api, location: '/lotes');

    expect(find.text('Lote A1'), findsOneWidget);
    expect(find.text('Crear lote'), findsNothing);
    expect(find.text('Código de lote'), findsNothing);
    expect(find.text('Editar'), findsNothing);
  });

  testWidgets('editing a lot sends only the changed fields with PUT and updates the row', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    api.on('PUT', '/lotes/l1', (_) => lot('l1', 'A1', name: 'Engorde', target: 0.8, count: 12));
    await pumpApp(tester, api, location: '/lotes');

    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar lote A1'), findsOneWidget);
    expect(find.text('Un dato ya cargado se puede cambiar, pero no dejar vacío.'), findsOneWidget);

    // The form starts with the stored values; only the name changes.
    final fields = find.descendant(of: find.ancestor(of: find.text('Editar lote A1'), matching: find.byType(Column)).first, matching: find.byType(TextField));
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, 'Recría');
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, '0,8');
    await tester.enterText(fields.at(0), 'Engorde');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(jsonDecode(api.sent('PUT', '/lotes/l1').single.body), {'nombre': 'Engorde'});
    expect(find.text('Editar lote A1'), findsNothing);
    expect(find.text('NOMBRE Engorde'), findsOneWidget);
  });

  testWidgets('a rejected edit keeps the form open with the server message', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    api.on('PUT', '/lotes/l1', (_) => const FakeReply(422, {'detail': 'La GMD objetivo debe ser positiva.'}));
    await pumpApp(tester, api, location: '/lotes');

    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.ancestor(of: find.text('Editar lote A1'), matching: find.byType(Column)).first, matching: find.byType(TextField)).at(1), '0,9');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('La GMD objetivo debe ser positiva.'), findsOneWidget);
    expect(find.text('Editar lote A1'), findsOneWidget);
    expect(jsonDecode(api.sent('PUT', '/lotes/l1').single.body), {'gmd_objetivo': 0.9});
  });

  testWidgets('with no lots it invites managers to create the first one', (tester) async {
    useTallPhone(tester);
    final api = FakeApi()..on('GET', '/lotes', (_) => []);
    await pumpApp(tester, api, location: '/lotes');

    expect(find.text('0 lotes'), findsOneWidget);
    expect(find.text('No hay lotes creados todavía'), findsOneWidget);
    expect(find.text('Creá el primero con su código para empezar a agrupar el rodeo.'), findsOneWidget);
  });

  testWidgets('a server error shows its message and Reintentar loads the lots again', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    var fail = true;
    api.on('GET', '/lotes', (_) => fail ? const FakeReply(500, {'detail': 'Falla del servidor.'}) : [lot('l1', 'A1')]);
    await pumpApp(tester, api, location: '/lotes');

    expect(find.text('Falla del servidor.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Falla del servidor.'), findsNothing);
    expect(find.text('Lote A1'), findsOneWidget);
  });

  testWidgets('without connection the screen shows the network message', (tester) async {
    useTallPhone(tester);
    final api = apiWithLots();
    api.on('GET', '/lotes', (_) => throw http.ClientException('offline'));
    await pumpApp(tester, api, location: '/lotes');

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
