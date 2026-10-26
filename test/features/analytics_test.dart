import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/features/panel/panel_api.dart';
import 'package:bovino_vision_mobile/features/panel/panel_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';

Map<String, Object?> alertJson(String id, {int priority = 1, String type = 'perdida_peso', String animal = 'AR-1', String date = '2026-10-24T10:00:00Z'}) => {
      'id': id,
      'id_evento': 'e$id',
      'id_animal': 'animal-$id',
      'animal_identificador': animal,
      'tipo': type,
      'prioridad': priority,
      'variacion': -0.35,
      'gmd_esperada': type == 'estancamiento' ? 0.8 : null,
      'estado': 'activa',
      'fecha_generacion': date,
    };

FakeApi analyticsApi() {
  final api = FakeApi()..permissions = {Permissions.herdRead, Permissions.herdManage, Permissions.analyticsRead};
  api
    ..on('GET', '/lotes', (_) => [
          {'id': 'l1', 'codigo': 'A-12', 'nombre': 'Recría', 'gmd_objetivo': 0.8, 'cantidad_animales': 3},
        ])
    ..on('GET', '/panel', (_) => {
          'cantidad_animales': 4,
          'peso_promedio_kg': 412.35,
          'gmd_promedio_kg_dia': 0.72,
          'animales_con_gmd': 2,
          'evolucion_peso_promedio': [
            {'fecha': '2026-09-01', 'peso_promedio_kg': 400.0},
            {'fecha': '2026-10-01', 'peso_promedio_kg': 420.0},
          ],
        })
    ..on('GET', '/alertas', (_) => [
          alertJson('1', priority: 2, type: 'estancamiento', animal: 'AR-2'),
          alertJson('2', priority: 1, animal: 'AR-1'),
        ]);
  return api;
}

/// Tall phone-width surface so long scrolling screens build all their sections.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Panel', () {
    testWidgets('shows KPIs, subtitle and the most urgent alerts first', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, analyticsApi(), location: '/panel');

      expect(find.text('Panel del rodeo'), findsOneWidget);
      expect(find.text('4 cabezas en 1 lote · datos al 1 oct'), findsOneWidget);
      expect(find.text('412,4 kg'), findsOneWidget);
      expect(find.text('0,72 kg/día'), findsOneWidget);
      expect(find.text('Ver las 2 alertas'), findsOneWidget);
      final urgent = tester.getTopLeft(find.text('AR-1')).dy;
      final medium = tester.getTopLeft(find.text('AR-2')).dy;
      expect(urgent, lessThan(medium));
      expect(find.text('Pérdida de peso: GMD -0,35 kg/día'), findsOneWidget);
      expect(find.text('Estancamiento: GMD -0,35 kg/día (objetivo +0,80 kg/día)'), findsOneWidget);
    });

    testWidgets('filtering by lot sends id_lote and keeps only that lot\'s alerts', (tester) async {
      final api = analyticsApi()
        ..on('GET', '/animales', (_) => [
              {'id': 'animal-2', 'identificador': 'AR-1', 'id_establecimiento': 'e', 'alertas_activas': 1},
            ]);
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/panel');

      await tester.tap(find.text('Todo el rodeo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lote A-12').last);
      await tester.pumpAndSettle();

      expect(api.sent('GET', '/panel').last.url.queryParameters, {'id_lote': 'l1'});
      expect(api.sent('GET', '/animales').last.url.queryParameters, {'id_lote': 'l1', 'con_alertas_activas': 'true'});
      expect(find.text('Real contra objetivo del lote A-12'), findsOneWidget);
      expect(find.text('Ver la alerta'), findsOneWidget);
      expect(find.text('AR-2'), findsNothing);
    });

    testWidgets('a failed panel load shows the message with a retry', (tester) async {
      final api = analyticsApi()..on('GET', '/panel', (_) => const FakeReply(500, {'detail': 'Se cayó la base.'}));
      await pumpApp(tester, api, location: '/panel');

      expect(find.text('Se cayó la base.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Alertas', () {
    testWidgets('lists active alerts with counts per priority', (tester) async {
      await pumpApp(tester, analyticsApi(), location: '/alertas');

      expect(find.text('Alertas del rodeo'), findsOneWidget);
      expect(find.text('1 de prioridad alta'), findsOneWidget);
      expect(find.text('1 de prioridad media'), findsOneWidget);
      expect(find.text('0 de prioridad baja'), findsOneWidget);
      expect(find.text('AR-1'), findsOneWidget);
      expect(find.text('AR-2'), findsOneWidget);
    });

    testWidgets('resolving an alert posts it and removes the card', (tester) async {
      final api = analyticsApi()..on('POST', '/alertas/2/resolver', (_) => const FakeReply(204));
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/alertas');

      await tester.tap(find.text('Resolver').at(1));
      await tester.pumpAndSettle();

      expect(api.sent('POST', '/alertas/2/resolver'), hasLength(1));
      expect(find.text('AR-1'), findsNothing);
      expect(find.text('AR-2'), findsOneWidget);
    });

    testWidgets('the resolve action needs rodeo_gestionar', (tester) async {
      final api = analyticsApi()..permissions = {Permissions.herdRead, Permissions.analyticsRead};
      await pumpApp(tester, api, location: '/alertas');

      expect(find.text('Resolver'), findsNothing);
      expect(find.text('Ver ficha'), findsNWidgets(2));
    });

    testWidgets('"Ver ficha" opens the animal', (tester) async {
      await pumpApp(tester, analyticsApi(), location: '/alertas');

      await tester.tap(find.text('Ver ficha').first);
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/animales/animal-1');
    });

    testWidgets('without alerts shows the empty state', (tester) async {
      final api = analyticsApi()..on('GET', '/alertas', (_) => []);
      await pumpApp(tester, api, location: '/alertas');

      expect(find.text('No hay alertas activas'), findsOneWidget);
    });
  });

  test('target curve adds the lot target GMD per calendar day from the first point', () {
    final curve = targetCurve(const [
      EvolutionPoint(date: '2026-09-01', averageWeightKg: 400),
      EvolutionPoint(date: '2026-09-05'),
      EvolutionPoint(date: '2026-09-11', averageWeightKg: 405),
    ], 0.5);
    expect(curve, [400, 405]);
    expect(targetCurve(const [EvolutionPoint(date: '2026-09-01', averageWeightKg: 400)], null), isNull);
  });

  test('panel subtitle wording', () {
    expect(panelSubtitle(heads: 1, lots: 1), '1 cabeza en 1 lote');
    expect(panelSubtitle(heads: 1248, lots: 6, lastDate: '2026-05-24'), '1.248 cabezas en 6 lotes · datos al 24 may');
    expect(panelSubtitle(heads: 30, lots: 6, lotCode: 'A-12'), '30 cabezas en el lote A-12');
  });
}
