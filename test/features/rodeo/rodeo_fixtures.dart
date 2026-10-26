import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api.dart';

/// A tall phone so that long lists are fully built without scrolling.
void useTallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 3000);
  addTearDown(tester.view.reset);
}

/// Full URI (path and query) of the running app.
Uri currentUri(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).routerDelegate.currentConfiguration.uri;
}

Map<String, Object?> animalJson({
  String id = 'a1',
  String identifier = 'AR-001',
  String? lotId = 'l1',
  String? lotCode = 'A1',
  String? breedId = 'r1',
  String? breed = 'Angus',
  String? sex = 'macho',
  String? birthDate = '2025-01-10',
  double? weight = 452,
  double? gmd = 0.85,
  int alerts = 0,
  String? imageId,
}) =>
    {
      'id': id,
      'identificador': identifier,
      'id_lote': lotId,
      'lote_codigo': lotCode,
      'id_raza': breedId,
      'raza': breed,
      'sexo': sex,
      'fecha_nacimiento': birthDate,
      'ultimo_peso_kg': weight,
      'gmd_kg_dia': gmd,
      'alertas_activas': alerts,
      'id_imagen_ultimo_pesaje': imageId,
    };

Map<String, Object?> lotJson({
  String id = 'l1',
  String code = 'A1',
  String? name,
  double? target = 0.8,
  int count = 1,
}) =>
    {'id': id, 'codigo': code, 'nombre': name, 'gmd_objetivo': target, 'cantidad_animales': count};

const breedsJson = [
  {'id': 'r1', 'nombre': 'Angus'},
  {'id': 'r2', 'nombre': 'Hereford'},
];

/// Two animals: AR-001 in lot A1 (452 kg, +0,85 kg/día) and AR-002 in lot B2 with two alerts.
final herdJson = [
  animalJson(),
  animalJson(
    id: 'a2',
    identifier: 'AR-002',
    lotId: 'l2',
    lotCode: 'B2',
    breedId: 'r2',
    breed: 'Hereford',
    sex: 'hembra',
    weight: 380,
    gmd: 0.45,
    alerts: 2,
  ),
];

final lotsJson = [lotJson(count: 1), lotJson(id: 'l2', code: 'B2', target: null)];

/// Registers the herd list, lots and breeds endpoints on [api].
void registerHerd(FakeApi api) {
  api
    ..on('GET', '/animales', (_) => herdJson)
    ..on('GET', '/lotes', (_) => lotsJson)
    ..on('GET', '/razas', (_) => breedsJson);
}
