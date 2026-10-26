import 'dart:convert';

import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/core/widgets/app_badge.dart';
import 'package:bovino_vision_mobile/core/widgets/line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import 'rodeo_fixtures.dart';

// Noon UTC keeps the calendar day the same in every time zone from UTC-12 to UTC+11.
const _weighings = [
  {
    'id': 'w3',
    'peso_kg': 452.0,
    'fecha_pesaje': '2026-10-20T12:00:00Z',
    'fecha_procesamiento': '2026-10-20T12:01:00Z',
    'version_modelo': 'v1',
    'id_imagen_utilizada': 'img3',
    'lote_codigo': 'A1',
    'gmd_kg_dia': 0.85,
    'operario': 'F. López',
  },
  {
    'id': 'w2',
    'peso_kg': 440.0,
    'fecha_pesaje': '2026-10-06T12:00:00Z',
    'fecha_procesamiento': '2026-10-06T12:01:00Z',
    'version_modelo': 'v1',
    'id_imagen_utilizada': 'img2',
    'lote_codigo': 'A1',
    'gmd_kg_dia': -0.36,
    'operario': null,
  },
  {
    'id': 'w1',
    'peso_kg': 445.0,
    'fecha_pesaje': '2026-09-22T12:00:00Z',
    'fecha_procesamiento': '2026-09-22T12:01:00Z',
    'version_modelo': 'v1',
    'id_imagen_utilizada': 'img1',
    'lote_codigo': null,
    'gmd_kg_dia': null,
    'operario': null,
  },
];

const _alerts = [
  {
    'id': 'al1',
    'id_evento': 'e1',
    'id_animal': 'a1',
    'animal_identificador': 'AR-001',
    'tipo': 'perdida_peso',
    'prioridad': 1,
    'variacion': -0.4,
    'gmd_esperada': null,
    'estado': 'activa',
    'fecha_generacion': '2026-10-21T12:00:00Z',
  },
  {
    'id': 'al0',
    'id_evento': 'e0',
    'id_animal': 'a1',
    'animal_identificador': 'AR-001',
    'tipo': 'estancamiento',
    'prioridad': 2,
    'variacion': 0.1,
    'gmd_esperada': 0.8,
    'estado': 'resuelta',
    'fecha_generacion': '2026-09-30T12:00:00Z',
  },
];

const _assignments = [
  {'id_lote': 'l1', 'lote_codigo': 'A1', 'vigente_desde': '2026-10-01T12:00:00Z', 'vigente_hasta': null},
  {'id_lote': 'l2', 'lote_codigo': 'B2', 'vigente_desde': '2026-08-15T12:00:00Z', 'vigente_hasta': '2026-10-01T12:00:00Z'},
];

FakeApi _apiWithAnimal({Object? weighings = _weighings, Object? alerts = _alerts}) {
  final api = FakeApi();
  registerHerd(api);
  api
    ..on('GET', '/animales/a1', (_) => animalJson())
    ..on('GET', '/animales/a1/pesajes', (_) => weighings)
    ..on('GET', '/animales/a1/alertas', (_) => alerts)
    ..on('GET', '/animales/a1/historial-lotes', (_) => _assignments);
  return api;
}

void main() {
  testWidgets('shows the data, KPIs, active alerts, weighings with differences and lot history', (tester) async {
    useTallPhone(tester);
    await pumpApp(tester, _apiWithAnimal(), location: '/animales/a1');

    expect(find.text('AR-001'), findsOneWidget);
    expect(find.text('Macho · Nació el 10/01/2025'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Angus'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Lote A1'), findsOneWidget);

    // KPIs.
    expect(find.text('ÚLTIMO PESAJE'), findsOneWidget);
    expect(find.text('+12,0 kg'), findsOneWidget);
    expect(find.text('VARIACIÓN VS. ANTERIOR'), findsOneWidget);
    expect(find.text('+0,85 kg/día'), findsOneWidget);
    expect(find.text('GMD DEL ÚLTIMO INTERVALO'), findsOneWidget);
    expect(find.text('PESAJES'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Only the active alert is shown, with the web wording.
    expect(find.text('Pérdida de peso: GMD -0,40 kg/día · prioridad alta · 21/10/2026'), findsOneWidget);
    expect(find.textContaining('Estancamiento'), findsNothing);
    expect(find.text('Este animal no tiene alertas activas.'), findsNothing);

    // Growth curve and chronological record, newest first, with the difference vs. the previous one.
    expect(find.text('Curva de crecimiento'), findsOneWidget);
    expect(find.byType(LineChartView), findsOneWidget);
    expect(find.text('Registro cronológico de pesajes'), findsOneWidget);
    expect(find.text('+12 kg'), findsOneWidget);
    expect(find.text('-5 kg'), findsOneWidget);
    expect(find.text('GMD +0,85 kg/día'), findsOneWidget);
    expect(find.text('GMD -0,36 kg/día'), findsOneWidget);
    expect(find.text('20 oct 2026 · F. López'), findsOneWidget);
    expect(find.text('22 sept 2026'), findsOneWidget);
    expect(find.text('Sin lote'), findsOneWidget);

    // Lot history.
    expect(find.text('Historial de lotes'), findsOneWidget);
    expect(find.text('01/10/2026 – hoy'), findsOneWidget);
    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('15/08/2026 – 01/10/2026'), findsOneWidget);
  });

  testWidgets('an animal with no alerts and no weighings says so', (tester) async {
    useTallPhone(tester);
    await pumpApp(tester, _apiWithAnimal(weighings: [], alerts: []), location: '/animales/a1');

    expect(find.text('Este animal no tiene alertas activas.'), findsOneWidget);
    expect(find.text('Todavía no tiene pesajes registrados'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    // The weigh button shows in the header and in the empty record.
    expect(find.text('Pesar este animal'), findsNWidgets(2));
  });

  testWidgets('"Pesar este animal" opens the capture wizard with the animal selected', (tester) async {
    useTallPhone(tester);
    await pumpApp(tester, _apiWithAnimal(), location: '/animales/a1');

    await tester.tap(find.text('Pesar este animal'));
    await tester.pumpAndSettle();

    final uri = currentUri(tester);
    expect(uri.path, '/captura/nueva');
    expect(uri.queryParameters, {'animal': 'a1'});
  });

  testWidgets('without capturas_registrar there is no weigh button; without rodeo_gestionar no edit button', (tester) async {
    useTallPhone(tester);
    final api = _apiWithAnimal()..permissions = {Permissions.herdRead};
    await pumpApp(tester, api, location: '/animales/a1');

    expect(find.text('AR-001'), findsOneWidget);
    expect(find.text('Pesar este animal'), findsNothing);
    expect(find.text('Editar datos'), findsNothing);
  });

  testWidgets('editing sends only the changed fields with PUT and refreshes the file', (tester) async {
    useTallPhone(tester);
    final api = _apiWithAnimal();
    api.on('PUT', '/animales/a1', (_) => animalJson(breedId: 'r2', breed: 'Hereford'));
    await pumpApp(tester, api, location: '/animales/a1');

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    expect(find.text('Editar datos del animal'), findsOneWidget);
    expect(find.text('Un dato ya cargado se puede cambiar, pero no dejar vacío.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hereford').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final put = api.sent('PUT', '/animales/a1').single;
    expect(jsonDecode(put.body), {'id_raza': 'r2'});
    expect(find.text('Editar datos del animal'), findsNothing);
    expect(find.widgetWithText(AppBadge, 'Hereford'), findsOneWidget);
    // The lot did not change, so its history is not requested again.
    expect(api.sent('GET', '/animales/a1/historial-lotes'), hasLength(1));
  });

  testWidgets('a rejected edit keeps the form open with the server message', (tester) async {
    useTallPhone(tester);
    final api = _apiWithAnimal();
    api.on('PUT', '/animales/a1', (_) => const FakeReply(404, {'detail': 'El lote no existe.'}));
    await pumpApp(tester, api, location: '/animales/a1');

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hereford').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('El lote no existe.'), findsOneWidget);
    expect(find.text('Editar datos del animal'), findsOneWidget);
  });

  testWidgets('saving without changes closes the edit card without a request', (tester) async {
    useTallPhone(tester);
    final api = _apiWithAnimal();
    await pumpApp(tester, api, location: '/animales/a1');

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(api.sent('PUT', '/animales/a1'), isEmpty);
    expect(find.text('Editar datos del animal'), findsNothing);
  });

  testWidgets('an unknown animal shows the server message with Reintentar', (tester) async {
    useTallPhone(tester);
    final api = _apiWithAnimal();
    api.on('GET', '/animales/a1', (_) => const FakeReply(404, {'detail': 'No existe el animal.'}));
    await pumpApp(tester, api, location: '/animales/a1');

    expect(find.text('No existe el animal.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
