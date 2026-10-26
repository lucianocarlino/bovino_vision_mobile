import 'dart:convert';
import 'dart:typed_data';

import 'package:bovino_vision_mobile/features/capture/data/photo_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_api.dart';

/// 1x1 transparent PNG.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class FakePhotoPicker implements PhotoPicker {
  PickedPhoto? next = PickedPhoto(bytes: Uint8List.fromList(tinyPng), filename: 'vaca.png', contentType: 'image/png');
  Object? failure;
  final requested = <PhotoSource>[];

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    requested.add(source);
    if (failure != null) throw failure!;
    return next;
  }
}

Map<String, Object?> animalJson({String id = 'a1', String tag = 'ARG 0042'}) => {
  'id': id,
  'identificador': tag,
  'raza': 'Angus',
  'lote_codigo': 'A-12',
  'sexo': 'macho',
  'alertas_activas': 0,
};

Map<String, Object?> captureJson({
  String status = 'registrada',
  int attempts = 0,
  String? reason,
  String? eventId,
  String? reviewedAt,
}) => {
  'id': 'c1',
  'id_sesion': 'ses-1',
  'id_animal': 'a1',
  'fecha_captura': DateTime.now().toUtc().toIso8601String(),
  'estado': status,
  'motivo_fallo': reason,
  'intentos': attempts,
  'fecha_revision': reviewedAt,
  'id_evento_pesaje': eventId,
};

Map<String, Object?> weighingJson({Map<String, Object?>? previous, Map<String, Object?>? alert, double weight = 400}) =>
    {
      'id': 'e1',
      'id_animal': 'a1',
      'id_captura': 'c1',
      'estado': 'confirmado',
      'peso_kg': weight,
      'fecha_pesaje': DateTime.now().toUtc().toIso8601String(),
      'version_modelo': 'v1',
      'id_imagen': 'img-1',
      'animal_identificador': 'ARG 0042',
      'lote_codigo': 'A-12',
      'ultimo_peso_previo': previous,
      'alerta': alert,
      'operario': 'Francisco López',
    };

/// A fake API with the whole capture flow answering: session, search, upload, polling and result.
/// [captureStates] are served by `GET /capturas/c1` in order; the last one repeats.
FakeApi captureApi({List<Map<String, Object?>>? captureStates, Map<String, Object?>? weighing}) {
  final states =
      captureStates ??
      [
        captureJson(status: 'pendiente'),
        captureJson(status: 'procesando', attempts: 1),
        captureJson(status: 'procesada', eventId: 'e1'),
      ];
  var polls = 0;
  return FakeApi()
    ..on('GET', '/sesiones-captura', (_) => [])
    ..on('POST', '/sesiones-captura', (_) => FakeReply(201, {'id': 'ses-1', 'estado': 'activa'}))
    ..on('GET', '/sesiones-captura/ses-1/capturas', (_) => [])
    ..on('GET', '/animales', (request) {
      final query = request.url.queryParameters['q'];
      return query == '0042' ? [animalJson()] : [];
    })
    ..on('GET', '/animales/a1', (_) => animalJson())
    ..on(
      'POST',
      '/animales',
      (request) =>
          FakeReply(201, animalJson(id: 'a9', tag: (jsonDecode(request.body) as Map)['identificador'] as String)),
    )
    ..on('POST', '/capturas', (_) => FakeReply(201, captureJson()))
    ..on('DELETE', '/capturas/c1', (_) => const FakeReply(204))
    ..on('POST', '/pesajes', (_) => const FakeReply(202))
    ..on('GET', '/capturas/c1', (_) => states[(polls++).clamp(0, states.length - 1)])
    ..on('GET', '/pesajes/e1', (_) => weighing ?? weighingJson())
    ..on(
      'POST',
      '/capturas/c1/confirmar',
      (_) => captureJson(status: 'procesada', eventId: 'e1', reviewedAt: DateTime.now().toUtc().toIso8601String()),
    );
}

/// Body of a multipart request as text, to assert its fields and part headers.
String multipartText(http.Request request) => latin1.decode(request.bodyBytes);

/// Phone-sized surface tall enough for the whole wizard, so lazy lists build every widget.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lets requests and the (shortened) poll timer run; spinners never "settle".
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
