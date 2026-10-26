import 'package:bovino_vision_mobile/core/api/api_exception.dart';
import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/core/widgets/app_badge.dart';
import 'package:bovino_vision_mobile/features/rodeo/presentation/animal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_api.dart';

import 'rodeo_fixtures.dart';

void main() {
  testWidgets('lists the animals as cards and computes the four tiles from the herd', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales');

    expect(find.text('2 resultados'), findsOneWidget);

    // Tiles: label (upper case), value and detail line.
    expect(find.text('TOTAL ANIMALES'), findsOneWidget);
    expect(find.text('2 lotes activos'), findsOneWidget);
    expect(find.text('416 kg'), findsOneWidget);
    expect(find.text('Último pesaje de 2 animales'), findsOneWidget);
    expect(find.text('0,65 kg/día'), findsOneWidget);
    expect(find.text('2 animales con dos pesajes o más'), findsOneWidget);
    expect(find.text('ALERTAS ACTIVAS'), findsOneWidget);
    expect(find.text('En 1 animal'), findsOneWidget);

    // First card: lot pill, SENASA ID, breed, last weight, GMD, alerts and target share.
    expect(find.text('ID SENASA'), findsNWidgets(2));
    expect(find.text('AR-001'), findsOneWidget);
    expect(find.text('Angus'), findsOneWidget);
    expect(find.text('452,0 kg'), findsOneWidget);
    expect(find.text('+0,85 kg/día'), findsOneWidget);
    expect(find.text('Sin alertas activas'), findsOneWidget);
    expect(find.text('106 % del objetivo'), findsOneWidget);

    // Second card: its lot has no target, so there is no share; two alerts.
    expect(find.text('AR-002'), findsOneWidget);
    expect(find.text('2 alertas activas'), findsOneWidget);
    expect(find.textContaining('del objetivo'), findsOneWidget);

    // One request is enough: the unfiltered list also feeds the tiles.
    expect(api.sent('GET', '/animales'), hasLength(1));
  });

  testWidgets('an animal without data shows the placeholders of the web app', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on(
      'GET',
      '/animales',
      (_) => [animalJson(lotId: null, lotCode: null, breed: null, breedId: null, weight: null, gmd: null)],
    );
    await pumpApp(tester, api, location: '/animales');

    expect(find.text('Sin lote'), findsOneWidget);
    expect(find.text('Sin registrar'), findsOneWidget);
    expect(find.text('Sin pesajes'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Todavía sin pesajes'), findsOneWidget);
    expect(find.text('Hace falta un segundo pesaje'), findsOneWidget);
    expect(find.text('Ninguna pendiente'), findsOneWidget);
  });

  testWidgets('typing in the search sends q once the user pauses', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales');

    await tester.enterText(find.byType(TextField), 'AR-00');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final requests = api.sent('GET', '/animales');
    expect(requests, hasLength(2));
    expect(requests.last.url.queryParameters, {'q': 'AR-00'});
  });

  testWidgets('a lot chip sends id_lote and narrows the tiles to that lot', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/animales', (request) => request.url.queryParameters['id_lote'] == null ? herdJson : [herdJson.first]);
    await pumpApp(tester, api, location: '/animales');

    await tester.tap(find.widgetWithText(AppFilterChip, 'Lote A1'));
    await tester.pumpAndSettle();

    expect(api.sent('GET', '/animales').last.url.queryParameters, {'id_lote': 'l1'});
    expect(find.text('1 resultado'), findsOneWidget);
    // The tiles describe the lot, computed from the unfiltered herd.
    expect(find.text('Lote A1'), findsNWidgets(3)); // chip, tile detail and card pill
    expect(find.text('452 kg'), findsOneWidget);
    expect(find.text('Alertas activas'.toUpperCase()), findsOneWidget);
    expect(find.text('Ninguna pendiente'), findsOneWidget);
    expect(api.sent('GET', '/animales'), hasLength(2));
  });

  testWidgets('the Alertas chip sends con_alertas_activas but keeps the tiles of the whole herd', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/animales', (request) => request.url.queryParameters.containsKey('con_alertas_activas') ? [herdJson.last] : herdJson);
    await pumpApp(tester, api, location: '/animales');

    await tester.ensureVisible(find.widgetWithText(AppFilterChip, 'Alertas'));
    await tester.tap(find.widgetWithText(AppFilterChip, 'Alertas'));
    await tester.pumpAndSettle();

    expect(api.sent('GET', '/animales').last.url.queryParameters, {'con_alertas_activas': 'true'});
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('2 lotes activos'), findsOneWidget);
    expect(find.text('416 kg'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(AppFilterChip, 'Todos'));
    await tester.tap(find.widgetWithText(AppFilterChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(api.sent('GET', '/animales').last.url.queryParameters, isEmpty);
    expect(find.text('2 resultados'), findsOneWidget);
  });

  testWidgets('"Nuevo animal" opens the sign-up screen for users who manage the herd', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales');

    await tester.tap(find.text('Nuevo animal'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/animales/nuevo');
  });

  testWidgets('"Nuevo animal" is hidden without rodeo_gestionar', (tester) async {
    useTallPhone(tester);
    final api = FakeApi()..permissions = {Permissions.herdRead, Permissions.captureRecord};
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales');

    expect(find.text('AR-001'), findsOneWidget);
    expect(find.text('Nuevo animal'), findsNothing);
  });

  testWidgets('tapping a card opens the animal file and coming back refreshes the list', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api
      ..on('GET', '/animales/a1', (_) => herdJson.first)
      ..on('GET', '/animales/a1/pesajes', (_) => [])
      ..on('GET', '/animales/a1/alertas', (_) => [])
      ..on('GET', '/animales/a1/historial-lotes', (_) => []);
    await pumpApp(tester, api, location: '/animales');

    await tester.tap(find.text('AR-001'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/animales/a1');

    await tester.tap(find.descendant(of: find.byType(BackLink), matching: find.byIcon(Icons.arrow_back)));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/animales');
    expect(api.sent('GET', '/animales'), hasLength(2));
    expect(find.text('AR-001'), findsOneWidget);
  });

  testWidgets('a search without results offers to clear the filters', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/animales', (request) => request.url.queryParameters.containsKey('q') ? [] : herdJson);
    await pumpApp(tester, api, location: '/animales');

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Ningún animal coincide con los filtros'), findsOneWidget);
    expect(find.text('Probá con otra búsqueda o quitá los filtros para ver todo el rodeo.'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();

    expect(api.sent('GET', '/animales').last.url.queryParameters, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(find.text('AR-001'), findsOneWidget);
  });

  testWidgets('an empty herd invites managers to add the first animal', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/animales', (_) => []);
    await pumpApp(tester, api, location: '/animales');

    expect(find.text('Todavía no hay animales cargados'), findsOneWidget);
    expect(find.text('Dá de alta el primero para empezar a registrar sus pesajes.'), findsOneWidget);
    expect(find.text('Dar de alta un animal'), findsOneWidget);
    expect(find.text('0 resultados'), findsOneWidget);
  });

  testWidgets('a server error shows its message and Reintentar loads the list again', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    var fail = true;
    api.on('GET', '/animales', (_) => fail ? const FakeReply(500, {'detail': 'Falla del servidor.'}) : herdJson);
    await pumpApp(tester, api, location: '/animales');

    expect(find.text('Falla del servidor.'), findsOneWidget);
    expect(find.text('AR-001'), findsNothing);

    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Falla del servidor.'), findsNothing);
    expect(find.text('AR-001'), findsOneWidget);
  });

  testWidgets('without connection the list shows the network message with Reintentar', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/animales', (_) => throw http.ClientException('offline'));
    await pumpApp(tester, api, location: '/animales');

    expect(find.text(ApiException.networkMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
