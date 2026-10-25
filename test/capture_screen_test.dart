import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/core/theme/app_theme.dart';
import 'package:bovino_vision_mobile/features/capture/capture_screen.dart';

void main() {
  Widget buildTestableWidget({CaptureScreenData? initialData}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: CaptureScreen(initialData: initialData),
    );
  }

  void setMobileScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('CaptureScreen - Reglas de Requisitos ERS y Diseño Visual', () {
    testWidgets('Renderiza campo con placeholder no válido, galería inicialmente vacía (0 tomas) y omite QR', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verifica presencia del campo de texto editable con placeholder de ejemplo
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, '');
      expect(textField.decoration?.hintText, 'Ej: AR-003421');

      // Verifica que la sesión comienza limpia sin fotos previas
      expect(find.text('0 tomas'), findsOneWidget);
      expect(find.text('No hay capturas registradas en la sesión.'), findsOneWidget);

      // Verifica que la opción de QR fue eliminada
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
      expect(find.byTooltip('Escanear identificación'), findsNothing);

      // Verifica chip offline "3 en cola"
      expect(find.text('3 en cola'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      // Verifica que no existan códigos técnicos en la interfaz
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('El placeholder no es válido: exige ingresar identificación antes de capturar', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Presiona el obturador sin haber ingresado caravana
      final shutterFinder = find.byIcon(Icons.camera_alt_rounded);
      await tester.ensureVisible(shutterFinder);
      await tester.tap(shutterFinder);
      await tester.pumpAndSettle();

      // Debe mostrar advertencia de validación
      expect(
        find.text('Por favor ingrese la identificación o caravana del animal.'),
        findsOneWidget,
      );
      expect(find.text('0 tomas'), findsOneWidget);
    });

    testWidgets('Permite ingresar caravana, registra captura y actualiza la galería de sesión', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Ingresamos el identificador del animal
      await tester.enterText(textFieldFinder, 'AR-008888');
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'AR-008888');

      // Tomamos la captura para el animal ingresado
      final shutterFinder = find.byIcon(Icons.camera_alt_rounded);
      await tester.ensureVisible(shutterFinder);
      await tester.tap(shutterFinder);
      await tester.pumpAndSettle();

      // Debe registrar la captura con el nuevo ID ingresado y pasar a 1 toma
      expect(
        find.text('Captura registrada exitosamente para el animal AR-008888.'),
        findsOneWidget,
      );
      expect(find.text('1 toma'), findsOneWidget);
      expect(find.text('AR-008888'), findsWidgets);
    });

    testWidgets('Cumple regla "Sin límite de tomas": no muestra "1/4" ni "1 de 4 tomas"', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // No debe existir el indicador "1/4" en la barra superior
      expect(find.text('1/4'), findsNothing);

      // No debe existir el texto "1 de 4 tomas" en la galería inferior
      expect(find.text('1 de 4 tomas'), findsNothing);

      // Debe existir la Galería de sesión
      expect(find.text('Galería de sesión'), findsOneWidget);
    });

    testWidgets('Cumple regla "Sin indicadores en tiempo real": omite chips superpuestos', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Chips que no deben aparecer
      expect(find.text('Luz correcta'), findsNothing);
      expect(find.text('Acercate 1 m'), findsNothing);
      expect(find.text('Encuadre'), findsNothing);
    });

    testWidgets('Dispara SnackBar con texto exacto "Not implemented" en funciones pendientes', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. Botón Flash en AppBar
      await tester.tap(find.byTooltip('Alternar Flash'));
      await tester.pumpAndSettle();
      expect(find.text('Not implemented'), findsOneWidget);

      // 2. Botón Galería en los controles
      await tester.tap(find.byTooltip('Galería de fotos'));
      await tester.pumpAndSettle();
      expect(find.text('Not implemented'), findsOneWidget);

      // 3. Botón Alternar cámara
      await tester.tap(find.byTooltip('Alternar cámara'));
      await tester.pumpAndSettle();
      expect(find.text('Not implemented'), findsOneWidget);
    });

    testWidgets('Aplica regla de negocio: "Solo se toma una foto por animal"', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      final shutterFinder = find.byIcon(Icons.camera_alt_rounded);
      await tester.ensureVisible(shutterFinder);

      // 1. Ingresa AR-003421 y toma la primera foto
      await tester.enterText(textFieldFinder, 'AR-003421');
      await tester.pumpAndSettle();
      await tester.tap(shutterFinder);
      await tester.pumpAndSettle();
      expect(find.text('1 toma'), findsOneWidget);

      // 2. Intenta ingresar nuevamente el mismo animal AR-003421
      await tester.enterText(textFieldFinder, 'AR-003421');
      await tester.pumpAndSettle();
      await tester.tap(shutterFinder);
      await tester.pumpAndSettle();

      // Debe alertar que el animal ya cuenta con captura en esta sesión
      expect(
        find.textContaining('ya cuenta con una captura registrada'),
        findsOneWidget,
      );
      expect(find.text('1 toma'), findsOneWidget);
    });

    testWidgets('Al presionar Finalizar Sesion solicita confirmacion y permite cancelar o confirmar', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final finishButtonFinder = find.text('FINALIZAR SESIÓN DE CAPTURA');
      await tester.ensureVisible(finishButtonFinder);
      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();

      // Debe mostrar el modal de confirmación con 0 tomas registradas inicialmente
      expect(find.text('Finalizar sesión'), findsOneWidget);
      expect(find.textContaining('¿Desea finalizar la sesión de captura actual?'), findsOneWidget);
      expect(find.textContaining('Se registrarán 0 tomas'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('CONFIRMAR'), findsOneWidget);

      // Al presionar CANCELAR, el diálogo se cierra y permanece en la pantalla
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar sesión'), findsNothing);
      expect(find.text('Captura Biométrica'), findsOneWidget);
    });
  });
}
