import 'dart:convert';

import 'package:bovino_vision_mobile/core/auth/session.dart';
import 'package:bovino_vision_mobile/core/format/formatters.dart';
import 'package:bovino_vision_mobile/features/capture/data/photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import 'capture_test_support.dart';

void main() {
  late FakePhotoPicker picker;

  setUp(() {
    picker = FakePhotoPicker();
    CaptureSettings.photoPicker = picker;
    CaptureSettings.pollInterval = const Duration(milliseconds: 10);
  });

  tearDown(() {
    CaptureSettings.photoPicker = const ImagePickerPhotoPicker();
    CaptureSettings.pollInterval = const Duration(seconds: 1);
  });

  /// Opens the wizard from the capture home and finds an animal, leaving the photo step open.
  Future<FakeApi> openPhotoStep(WidgetTester tester, {FakeApi? api}) async {
    final fake = api ?? captureApi();
    useTallScreen(tester);
    await pumpApp(tester, fake, location: '/captura');
    await tester.tap(find.text('Nueva captura'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '0042');
    await settle(tester);
    await tester.tap(find.text('ARG 0042'));
    await settle(tester);
    return fake;
  }

  Future<void> uploadAndProcess(WidgetTester tester) async {
    await tester.tap(find.text('Galería'));
    await settle(tester);
    await tester.tap(find.text('Procesar pesaje'));
    await settle(tester, frames: 20);
  }

  group('capture home', () {
    testWidgets('greets the user, offers a new capture and lists recent sessions', (tester) async {
      final now = DateTime.now();
      final api = captureApi()
        ..on(
          'GET',
          '/sesiones-captura',
          (_) => [
            {
              'id': 's1',
              'fecha_inicio': now.toUtc().toIso8601String(),
              'estado': 'activa',
              'cantidad_capturas': 3,
              'cantidad_procesadas': 3,
            },
            {
              'id': 's2',
              'fecha_inicio': '2020-03-05T12:00:00Z',
              'estado': 'finalizada',
              'cantidad_capturas': 1,
              'cantidad_procesadas': 1,
            },
          ],
        );
      await pumpApp(tester, api, location: '/captura');

      expect(find.textContaining(RegExp('^(Buenos días|Buenas tardes|Buenas noches),\$')), findsOneWidget);
      expect(find.text('Francisco López'), findsOneWidget);
      expect(find.text('En línea'), findsOneWidget);
      expect(find.text('Nueva captura'), findsOneWidget);
      expect(find.text('Pesá sin arrear: 4 tomas y listo'), findsOneWidget);
      expect(find.text('Sesiones recientes'), findsOneWidget);
      expect(find.text('3 animales procesados'), findsOneWidget);
      expect(find.text('1 animal procesado'), findsOneWidget);
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text(formatTime(now.toUtc().toIso8601String())), findsOneWidget);
      expect(find.text('05/03/2020'), findsOneWidget);
      expect(api.sent('GET', '/sesiones-captura').single.url.queryParameters, {'limite': '5'});
    });

    testWidgets('without sessions it says so', (tester) async {
      await pumpApp(tester, captureApi(), location: '/captura');

      expect(find.text('Todavía no hiciste capturas'), findsOneWidget);
      expect(find.text('Las sesiones que empieces van a aparecer acá.'), findsOneWidget);
    });

    testWidgets('a failed load shows the server message and can be retried', (tester) async {
      final api = captureApi()
        ..on('GET', '/sesiones-captura', (_) => const FakeReply(500, {'detail': 'Base de datos caída'}));
      await pumpApp(tester, api, location: '/captura');

      expect(find.text('No pudimos cargar las sesiones recientes: Base de datos caída'), findsOneWidget);
      api.on('GET', '/sesiones-captura', (_) => []);
      await tester.tap(find.text('Reintentar'));
      await settle(tester);

      expect(find.text('Todavía no hiciste capturas'), findsOneWidget);
    });

    testWidgets('"Nueva captura" opens the wizard and posts a capture session', (tester) async {
      final api = captureApi();
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura');

      await tester.tap(find.text('Nueva captura'));
      await settle(tester);

      expect(api.sent('POST', '/sesiones-captura'), hasLength(1));
      expect(find.text('Paso 1 de 4'), findsOneWidget);
      expect(find.text('Identificá el animal'), findsOneWidget);
      expect(find.text('Ingresá la caravana. Si no existe, la das de alta.'), findsOneWidget);
    });

    testWidgets('coming back to the home and starting again resumes the open session', (tester) async {
      final api = captureApi();
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura');
      await tester.tap(find.text('Nueva captura'));
      await settle(tester);

      await tester.tap(find.text('Inicio de captura'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/captura');
      await tester.tap(find.text('Nueva captura'));
      await settle(tester);

      expect(api.sent('POST', '/sesiones-captura'), hasLength(1));
      expect(api.sent('GET', '/sesiones-captura'), hasLength(2), reason: 'the recent sessions reload when coming back');
    });

    testWidgets('offline it shows "Sin conexión" and does not start a capture', (tester) async {
      final api = captureApi();
      await pumpApp(tester, api, location: '/captura', online: false);

      expect(find.text('Sin conexión'), findsWidgets);
      expect(find.textContaining('Necesitás conexión'), findsOneWidget);
      await tester.tap(find.text('Nueva captura'));
      await settle(tester);

      expect(currentPath(tester), '/captura');
      expect(api.sent('POST', '/sesiones-captura'), isEmpty);
    });
  });

  group('identify the animal', () {
    testWidgets('searching calls /animales?q= and picking an animal opens the photo step', (tester) async {
      final api = await openPhotoStep(tester);

      expect(api.sent('GET', '/animales').single.url.queryParameters, {'q': '0042'});
      expect(find.text('Paso 2 de 4'), findsOneWidget);
      expect(find.text('Foto del animal'), findsOneWidget);
      expect(find.text('Caravana ARG 0042'), findsOneWidget);
      expect(find.text('ESPERANDO ANIMAL'), findsOneWidget);
      expect(find.text('Luz correcta'), findsOneWidget);
      expect(find.text('Acercate 1 m'), findsOneWidget);
      expect(find.text('Encuadre'), findsOneWidget);
      expect(find.text('Usar cámara'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);
      expect(find.text('Elegir otro animal'), findsOneWidget);
    });

    testWidgets('search results show breed and lot', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, captureApi(), location: '/captura/nueva');
      await settle(tester);

      await tester.enterText(find.byType(TextField), '0042');
      await settle(tester);

      expect(find.text('Angus · Lote A-12'), findsOneWidget);
    });

    testWidgets('an unknown tag offers "Dar de alta" and registering posts the animal', (tester) async {
      final api = captureApi();
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura/nueva');
      await settle(tester);

      await tester.enterText(find.byType(TextField), '9999');
      await settle(tester);
      expect(find.text('No hay ningún animal con la caravana “9999”.'), findsOneWidget);
      await tester.tap(find.text('Dar de alta “9999”'));
      await settle(tester);

      final body = jsonDecode(api.sent('POST', '/animales').single.body) as Map<String, Object?>;
      expect(body['identificador'], '9999');
      expect(find.text('Foto del animal'), findsOneWidget);
      expect(find.text('Caravana 9999'), findsOneWidget);
    });

    testWidgets('without rodeo_gestionar there is no way to register the animal', (tester) async {
      final api = captureApi()..permissions = {Permissions.captureRecord, Permissions.herdRead};
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura/nueva');
      await settle(tester);

      await tester.enterText(find.byType(TextField), '9999');
      await settle(tester);

      expect(find.text('No hay ningún animal con la caravana “9999”.'), findsOneWidget);
      expect(find.textContaining('Dar de alta'), findsNothing);
    });

    testWidgets('/captura/nueva?animal=<id> loads that animal and skips identification', (tester) async {
      final api = captureApi();
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura/nueva?animal=a1');
      await settle(tester);

      expect(api.sent('GET', '/animales/a1'), hasLength(1));
      expect(api.sent('POST', '/sesiones-captura'), hasLength(1));
      expect(find.text('Foto del animal'), findsOneWidget);
      expect(find.text('Caravana ARG 0042'), findsOneWidget);
      expect(find.text('Identificá el animal'), findsNothing);
    });

    testWidgets('an animal that cannot be opened falls back to identification with the reason', (tester) async {
      final api = captureApi()
        ..on('GET', '/animales/a1', (_) => const FakeReply(404, {'detail': 'Animal inexistente'}));
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura/nueva?animal=a1');
      await settle(tester);

      expect(find.text('Identificá el animal'), findsOneWidget);
      expect(find.text('No pudimos abrir el animal elegido. Animal inexistente'), findsOneWidget);
    });
  });

  group('photo', () {
    testWidgets('a photo from the gallery is uploaded as multipart with its content type', (tester) async {
      final api = await openPhotoStep(tester);

      await tester.tap(find.text('Galería'));
      await settle(tester);

      expect(picker.requested, [PhotoSource.gallery]);
      final request = api.sent('POST', '/capturas').single;
      expect(request.headers['Content-Type'], startsWith('multipart/form-data; boundary='));
      final body = multipartText(request);
      expect(body, contains('name="id_sesion"\r\n\r\nses-1'));
      expect(body, contains('name="id_animal"\r\n\r\na1'));
      expect(body, contains('name="imagen"; filename="vaca.png"\r\nContent-Type: image/png'));
      expect(find.text('Foto cargada. Lista para estimar el peso.'), findsOneWidget);
      expect(find.text('Procesar pesaje'), findsOneWidget);
      expect(find.text('Quitar foto'), findsOneWidget);
      expect(find.text('Usar cámara'), findsNothing);
    });

    testWidgets('the camera button asks the picker for the camera', (tester) async {
      await openPhotoStep(tester);

      await tester.tap(find.text('Usar cámara'));
      await settle(tester);

      expect(picker.requested, [PhotoSource.camera]);
    });

    testWidgets('cancelling the picker sends nothing', (tester) async {
      final api = await openPhotoStep(tester);
      picker.next = null;

      await tester.tap(find.text('Usar cámara'));
      await settle(tester);

      expect(api.sent('POST', '/capturas'), isEmpty);
      expect(find.text('Usar cámara'), findsOneWidget);
    });

    testWidgets('a 422 shows the server detail and offers another photo', (tester) async {
      final api = captureApi()
        ..on('POST', '/capturas', (_) => const FakeReply(422, {'detail': 'La imagen debe ser JPEG, PNG o WebP.'}));
      await openPhotoStep(tester, api: api);

      await tester.tap(find.text('Galería'));
      await settle(tester);

      expect(find.text('No se pudo registrar la foto: La imagen debe ser JPEG, PNG o WebP.'), findsOneWidget);
      expect(find.text('Procesar pesaje'), findsNothing);
      await tester.tap(find.text('Sacar otra foto'));
      await settle(tester);

      expect(find.text('Usar cámara'), findsOneWidget);
      expect(find.textContaining('No se pudo registrar la foto'), findsNothing);
    });

    testWidgets('"Quitar foto" deletes the capture and brings the buttons back', (tester) async {
      final api = await openPhotoStep(tester);
      await tester.tap(find.text('Galería'));
      await settle(tester);

      await tester.tap(find.text('Quitar foto'));
      await settle(tester);

      expect(api.sent('DELETE', '/capturas/c1'), hasLength(1));
      expect(find.text('Usar cámara'), findsOneWidget);
      expect(find.text('Procesar pesaje'), findsNothing);
    });

    testWidgets('a 404 while removing the photo counts as removed', (tester) async {
      final api = captureApi()..on('DELETE', '/capturas/c1', (_) => const FakeReply(404, {'detail': 'No existe'}));
      await openPhotoStep(tester, api: api);
      await tester.tap(find.text('Galería'));
      await settle(tester);

      await tester.tap(find.text('Quitar foto'));
      await settle(tester);

      expect(find.text('Usar cámara'), findsOneWidget);
      expect(find.text('No existe'), findsNothing);
    });

    testWidgets('the session gallery lists the photos with their status', (tester) async {
      final api = captureApi()
        ..on(
          'GET',
          '/sesiones-captura/ses-1/capturas',
          (_) => [
            {
              'id': 'c0',
              'id_animal': 'a1',
              'animal_identificador': 'ARG 0001',
              'fecha_captura': '2020-03-05T12:00:00Z',
              'estado': 'fallida',
              'motivo_fallo': 'Foto borrosa',
              'id_imagen': 'i0',
            },
            {
              'id': 'c1',
              'id_animal': 'a1',
              'animal_identificador': 'ARG 0007',
              'fecha_captura': '2020-03-05T12:05:00Z',
              'estado': 'procesada',
              'id_imagen': 'i1',
            },
          ],
        );
      await openPhotoStep(tester, api: api);

      expect(find.text('Fotos de esta sesión'), findsOneWidget);
      expect(find.text('2 capturas'), findsOneWidget);
      expect(find.text('Pesada'), findsOneWidget);
      expect(find.text('Falló'), findsOneWidget);
      expect(find.text('Foto borrosa'), findsOneWidget);
      expect(find.text('ARG 0001'), findsOneWidget);
    });

    testWidgets('offline the wizard does not start and warns about the missing connection', (tester) async {
      final api = captureApi();
      useTallScreen(tester);
      await pumpApp(tester, api, location: '/captura/nueva?animal=a1', online: false);
      await settle(tester);

      expect(find.textContaining('Necesitás conexión'), findsOneWidget);
      expect(api.sent('POST', '/sesiones-captura'), isEmpty);
      expect(api.sent('GET', '/animales/a1'), isEmpty);
    });
  });

  group('estimation and result', () {
    testWidgets('"Procesar pesaje" posts the capture, polls it and shows the result', (tester) async {
      final api = await openPhotoStep(tester);

      await uploadAndProcess(tester);

      expect(jsonDecode(api.sent('POST', '/pesajes').single.body), {'id_captura': 'c1'});
      expect(api.sent('GET', '/capturas/c1').length, greaterThanOrEqualTo(3));
      expect(api.sent('GET', '/pesajes/e1'), hasLength(1));
      expect(find.text('Paso 4 de 4'), findsOneWidget);
      expect(find.text('Resultado del pesaje'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
      expect(find.text('PESO ESTIMADO'), findsOneWidget);
      expect(find.text('400 kg'), findsOneWidget);
      expect(find.text('Identificador SENASA'), findsOneWidget);
      expect(find.text('ARG 0042'), findsWidgets);
      expect(find.text('Lote'), findsOneWidget);
      expect(find.text('A-12'), findsOneWidget);
      expect(find.text('Operario'), findsOneWidget);
      expect(find.text('F. López · hoy ${formatTime(DateTime.now().toUtc().toIso8601String())}'), findsOneWidget);
      expect(find.text('Raza'), findsOneWidget);
      expect(find.text('Angus'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Macho'), findsOneWidget);
      expect(
        find.text('Es el primer pesaje de este animal: todavía no hay un peso anterior para comparar.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar y enviar'), findsOneWidget);
      expect(find.text('Tomar otra'), findsOneWidget);
      expect(find.text('Tomar otra foto'), findsOneWidget);
    });

    testWidgets('while estimating it shows the checklist with the attempt number', (tester) async {
      final api = captureApi(
        captureStates: [captureJson(status: 'procesando', attempts: 2, reason: 'Timeout del modelo')],
      );
      await openPhotoStep(tester, api: api);
      await tester.tap(find.text('Galería'));
      await settle(tester);
      await tester.tap(find.text('Procesar pesaje'));
      await settle(tester);

      expect(find.text('Paso 3 de 4'), findsOneWidget);
      expect(find.text('Estimando peso…'), findsOneWidget);
      expect(find.text('No cierres la aplicación.'), findsOneWidget);
      expect(find.text('Foto subida'), findsOneWidget);
      expect(find.text('En la cola de procesamiento'), findsOneWidget);
      expect(find.text('Procesando la foto (intento 2)'), findsOneWidget);
      expect(find.text('Peso estimado'), findsOneWidget);
      expect(find.text('Último intento: Timeout del modelo. Se reintenta automáticamente.'), findsOneWidget);
      expect(find.text('Volver a la foto'), findsOneWidget);

      // The wizard is torn down (stopping the poll) before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the result shows the previous weighing, its change and an alert', (tester) async {
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8)).toUtc().toIso8601String();
      final api = captureApi(
        weighing: weighingJson(
          weight: 400.5,
          previous: {'peso_kg': 380, 'fecha_pesaje': eightDaysAgo},
          alert: {'tipo': 'estancamiento', 'variacion': 0.4, 'gmd_esperada': 0.9},
        ),
      );
      await openPhotoStep(tester, api: api);

      await uploadAndProcess(tester);

      expect(find.text('400,5 kg'), findsOneWidget);
      expect(find.text('Pesaje anterior'), findsOneWidget);
      expect(find.text('380 kg · +20,5 kg en 8 días'), findsOneWidget);
      expect(find.text('Estancamiento: GMD +0,40 kg/día (objetivo +0,90 kg/día)'), findsOneWidget);
      expect(find.textContaining('Es el primer pesaje'), findsNothing);
    });

    testWidgets('a failed estimation shows the reason and "Pesar otro animal"', (tester) async {
      final api = captureApi(
        captureStates: [captureJson(status: 'fallida', reason: 'No se detectó el animal')],
      );
      await openPhotoStep(tester, api: api);

      await uploadAndProcess(tester);

      expect(find.text('No se pudo estimar el peso'), findsOneWidget);
      expect(find.textContaining('No se detectó el animal'), findsOneWidget);
      expect(find.textContaining('Registrá una nueva captura para volver a intentarlo.'), findsOneWidget);
      expect(api.sent('GET', '/pesajes/e1'), isEmpty);

      await tester.tap(find.text('Pesar otro animal'));
      await settle(tester);
      expect(find.text('Identificá el animal'), findsOneWidget);
    });

    testWidgets('a polling error can be retried with "Volver a consultar"', (tester) async {
      var failing = true;
      final api = captureApi()
        ..on('GET', '/capturas/c1', (_) {
          if (failing) return const FakeReply(500, {'detail': 'Servidor ocupado'});
          return captureJson(status: 'procesada', eventId: 'e1');
        });
      await openPhotoStep(tester, api: api);
      await tester.tap(find.text('Galería'));
      await settle(tester);
      await tester.tap(find.text('Procesar pesaje'));
      await settle(tester);

      expect(find.text('No se pudo consultar el estado: Servidor ocupado'), findsOneWidget);
      failing = false;
      await tester.tap(find.text('Volver a consultar'));
      await settle(tester, frames: 20);

      expect(find.text('Resultado del pesaje'), findsOneWidget);
    });

    testWidgets('"Confirmar y enviar" posts the confirmation and marks the result as confirmed', (tester) async {
      final api = await openPhotoStep(tester);
      await uploadAndProcess(tester);

      await tester.tap(find.text('Confirmar y enviar'));
      await settle(tester);

      expect(api.sent('POST', '/capturas/c1/confirmar'), hasLength(1));
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Resultado confirmado'), findsOneWidget);
      expect(find.text('Confirmar y enviar'), findsNothing);
      expect(find.text('Tomar otra foto'), findsNothing);
    });

    testWidgets('"Tomar otra" goes to the next animal inside the same session', (tester) async {
      final api = await openPhotoStep(tester);
      await uploadAndProcess(tester);

      await tester.tap(find.text('Tomar otra'));
      await settle(tester);

      expect(find.text('Paso 1 de 4'), findsOneWidget);
      expect(find.text('Identificá el animal'), findsOneWidget);
      expect(api.sent('POST', '/sesiones-captura'), hasLength(1));
    });

    testWidgets('"Tomar otra foto" goes back to the photo step of the same animal', (tester) async {
      final api = await openPhotoStep(tester);
      await uploadAndProcess(tester);

      await tester.tap(find.text('Tomar otra foto'));
      await settle(tester);

      expect(find.text('Paso 2 de 4'), findsOneWidget);
      expect(find.text('Caravana ARG 0042'), findsOneWidget);
      expect(find.text('Usar cámara'), findsOneWidget);
      expect(api.sent('DELETE', '/capturas/c1'), isEmpty, reason: 'weighings are immutable, nothing is discarded');
    });

    testWidgets('"Elegir otro animal" discards the registered photo first', (tester) async {
      final api = await openPhotoStep(tester);
      await tester.tap(find.text('Galería'));
      await settle(tester);

      await tester.tap(find.text('Elegir otro animal'));
      await settle(tester);

      expect(api.sent('DELETE', '/capturas/c1'), hasLength(1));
      expect(find.text('Identificá el animal'), findsOneWidget);
    });
  });
}
