import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/main.dart';

void main() {
  testWidgets('BovinoVision HomeScreen smoke test', (WidgetTester tester) async {
    // Inicializa el árbol de widgets
    await tester.pumpWidget(const BovinoVisionApp());
    await tester.pumpAndSettle();

    // Verifica que los elementos clave del mock estén presentes en la pantalla de inicio
    expect(find.text('BovinoVision'), findsWidgets);
    expect(find.text('Francisco López'), findsOneWidget);
    expect(find.text('FL'), findsOneWidget);
    expect(find.text('Sincronización completa'), findsOneWidget);
    expect(find.text('INICIAR CAPTURA'), findsOneWidget);
    expect(find.text('Total Rodeo'), findsOneWidget);
    expect(find.text('Lotes Activos'), findsOneWidget);
    expect(find.text('Capturas Hoy'), findsOneWidget);
    // En las sesiones se muestra el día, la hora y la cantidad de animales (sin nombre de sesión)
    expect(find.text('Hoy, 08:45'), findsOneWidget);
    expect(find.text('Ayer, 16:20'), findsOneWidget);
    expect(find.text('12 animales'), findsOneWidget);
    expect(find.text('30 animales'), findsOneWidget);
    expect(find.text('Lote Norte - Pesaje'), findsNothing);
  });

  testWidgets('Tapping unimplemented bottom navigation items displays "Not implemented"', (WidgetTester tester) async {
    await tester.pumpWidget(const BovinoVisionApp());
    await tester.pumpAndSettle();

    // Tap on third navigation destination (index 2 - Usuarios no implementado)
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Not implemented'), findsOneWidget);
  });

  testWidgets('Al pulsar la pestaña Rodeo en el menú inferior navega al buscador de animales', (WidgetTester tester) async {
    await tester.pumpWidget(const BovinoVisionApp());
    await tester.pumpAndSettle();

    // Pulsa la segunda opción del menú inferior (index 1: Rodeo / Buscador de animales)
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();

    // Verifica que se encuentre en RodeoScreen y muestre el buscador de animales
    expect(find.text('Rodeo'), findsWidgets);
    expect(find.text('Buscar por ID SENASA o lote...'), findsOneWidget);
    expect(find.text('AR-339281-C'), findsOneWidget);
    expect(find.text('AR-440192-K'), findsOneWidget);
  });

  testWidgets('Al pulsar INICIAR CAPTURA navega hacia CaptureScreen sin referencias tecnicas RF', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const BovinoVisionApp());
    await tester.pumpAndSettle();

    // Presiona INICIAR CAPTURA para navegar a la pantalla de captura
    final ctaFinder = find.text('INICIAR CAPTURA');
    await tester.ensureVisible(ctaFinder);
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    // Verifica que se encuentre en CaptureScreen
    expect(find.text('Captura Biométrica'), findsOneWidget);
    expect(find.text('Ej: AR-003421'), findsOneWidget);
    expect(find.text('0 tomas'), findsOneWidget);
    expect(find.text('3 en cola'), findsNothing);
    expect(find.textContaining('RF'), findsNothing);
  });

  testWidgets('Finalizar sesion con confirmacion regresa a la pantalla principal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const BovinoVisionApp());
    await tester.pumpAndSettle();

    // Navega a CaptureScreen
    final ctaFinder = find.text('INICIAR CAPTURA');
    await tester.ensureVisible(ctaFinder);
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    // Presiona FINALIZAR SESIÓN DE CAPTURA
    final finishButton = find.text('FINALIZAR SESIÓN DE CAPTURA');
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    // Verifica diálogo de confirmación
    expect(find.text('Finalizar sesión'), findsOneWidget);
    expect(find.text('CONFIRMAR'), findsOneWidget);

    // Confirma la finalización
    await tester.tap(find.text('CONFIRMAR'));
    await tester.pumpAndSettle();

    // Verifica que regresó a la pantalla principal (HomeScreen)
    expect(find.text('INICIAR CAPTURA'), findsOneWidget);
    expect(find.text('Francisco López'), findsOneWidget);
  });
}
