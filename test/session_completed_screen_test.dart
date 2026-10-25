import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/core/theme/app_theme.dart';
import 'package:bovino_vision_mobile/features/capture/presentation/screens/estimation_status_screen.dart';
import 'package:bovino_vision_mobile/features/capture/presentation/screens/session_completed_screen.dart';
import 'package:bovino_vision_mobile/features/home/data/home_mock_data.dart';
import 'package:bovino_vision_mobile/features/home/presentation/screens/home_screen.dart';

void main() {
  Widget buildTestableWidget({
    SessionCompletedData? initialData,
    bool? isOffline,
    VoidCallback? onBackPressed,
    VoidCallback? onDiscardMeasurement,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: SessionCompletedScreen(
        initialData: initialData,
        isOffline: isOffline,
        onBackPressed: onBackPressed,
        onDiscardMeasurement: onDiscardMeasurement,
      ),
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

  group('SessionCompletedScreen - Modo Online y Carrusel', () {
    testWidgets('Modo Online: Renderiza carrusel con detalles de animales y peso grande', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verifica título principal
      expect(find.text('Resultados de sesión'), findsOneWidget);

      // Verifica indicador de animales en carrusel
      expect(find.text('Animal 1 de 2'), findsOneWidget);

      // Verifica datos del primer animal
      expect(find.text('AR-003421'), findsOneWidget);
      expect(find.text('Peso estimado'), findsWidgets);
      expect(find.text('458'), findsOneWidget);
      expect(find.text('kg'), findsWidgets);
      expect(find.text('A-12 - Potrero 4'), findsWidgets);
      expect(find.text('443 kg • +15 kg en 33 días'), findsOneWidget);
      expect(find.text('F. López'), findsWidgets);

      // Reglas de diseño: Se elimina la foto y los indicadores de precisión y error
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('90,4'), findsNothing);
      expect(find.textContaining('90.4'), findsNothing);
      expect(find.textContaining('±'), findsNothing);
      expect(find.textContaining('Precisión'), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);

      // Reglas de botones: Se eliminan "Confirmar y enviar" y "Tomar otra"
      expect(find.text('Confirmar y enviar'), findsNothing);
      expect(find.text('Tomar otra'), findsNothing);

      // Solo se mantiene "Descartar esta medición"
      expect(find.text('Descartar esta medición'), findsOneWidget);

      // Regla de no incluir códigos técnicos
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('Navegación en carrusel PageView: Permite desplazarse horizontalmente al segundo animal', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Animal 1 de 2'), findsOneWidget);
      expect(find.text('AR-003421'), findsOneWidget);

      // Deslizar horizontalmente para navegar al siguiente animal
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verifica que cambió al segundo animal
      expect(find.text('Animal 2 de 2'), findsOneWidget);
      expect(find.text('AR-003422'), findsOneWidget);
      expect(find.text('510'), findsOneWidget);
      expect(find.text('490 kg • +20 kg en 33 días'), findsOneWidget);
    });

    testWidgets('Funciones pendientes disparan SnackBar con texto exacto "Not implemented"', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. Botón "Descartar esta medición"
      final discardButton = find.text('Descartar esta medición');
      await tester.ensureVisible(discardButton);
      await tester.tap(discardButton);
      await tester.pumpAndSettle();

      expect(find.text('Not implemented'), findsOneWidget);

      // 2. Botón volver atrás
      final backButton = find.byTooltip('Volver');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Not implemented'), findsOneWidget);
    });
  });

  group('SessionCompletedScreen - Modo Offline', () {
    testWidgets('Modo Offline: No muestra carrusel detallado y muestra únicamente Fecha, Hora y Cantidad total', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget(isOffline: true));
      await tester.pumpAndSettle();

      // Verifica indicador offline
      expect(find.text('Dispositivo sin conexión'), findsOneWidget);
      expect(
        find.text('El detalle individual de los animales no está disponible sin conexión a internet para optimizar el almacenamiento local.'),
        findsOneWidget,
      );

      // No se muestra el carrusel ni datos individuales de animales
      expect(find.byType(PageView), findsNothing);
      expect(find.text('AR-003421'), findsNothing);
      expect(find.text('AR-003422'), findsNothing);
      expect(find.text('458'), findsNothing);
      expect(find.text('510'), findsNothing);
      expect(find.text('Descartar esta medición'), findsNothing);

      // Muestra únicamente: Fecha de la sesión, Hora, y Cantidad total de animales
      expect(find.text('Resumen de la sesión'), findsOneWidget);
      expect(find.text('Fecha de la sesión'), findsOneWidget);
      expect(find.text('15/05/2026'), findsWidgets);

      expect(find.text('Hora'), findsOneWidget);
      expect(find.text('09:12'), findsWidgets);

      expect(find.text('Cantidad total de animales'), findsOneWidget);
      expect(find.text('12'), findsWidgets);

      // Sin códigos técnicos
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('Permite alternar interactivamente entre Modo Online y Offline mediante el chip de la AppBar', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(buildTestableWidget(isOffline: false));
      await tester.pumpAndSettle();

      // Inicialmente en Online con carrusel
      expect(find.text('Online'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Tocar chip de conectividad para cambiar a Offline
      await tester.tap(find.text('Online'));
      await tester.pumpAndSettle();

      // Debe pasar a Offline
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Dispositivo sin conexión'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);

      // Tocar nuevamente para volver a Online
      await tester.tap(find.text('Offline'));
      await tester.pumpAndSettle();

      // Carrusel restaurado
      expect(find.text('Online'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('AR-003421'), findsOneWidget);
    });
  });

  group('SessionCompletedScreen - Enlace con sesiones subidas y estimadas', () {
    testWidgets('Al tocar una sesión sincronizada y estimada en HomeScreen navega a SessionCompletedScreen', (tester) async {
      setMobileScreenSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Busca la sesión sincronizada "Hoy, 08:45"
      final syncedSessionItem = find.text('Hoy, 08:45');
      expect(syncedSessionItem, findsOneWidget);
      await tester.ensureVisible(syncedSessionItem);
      await tester.tap(syncedSessionItem);
      await tester.pumpAndSettle();

      // Debe encontrarse en SessionCompletedScreen
      expect(find.text('Resultados de sesión'), findsOneWidget);
      expect(find.text('Animal 1 de 2'), findsOneWidget);
      expect(find.text('AR-003421'), findsOneWidget);
      expect(find.text('458'), findsOneWidget);

      // Al pulsar volver atrás, regresa a HomeScreen
      final backButton = find.byTooltip('Volver');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('BovinoVision'), findsWidgets);
      expect(find.text('INICIAR CAPTURA'), findsOneWidget);
    });

    testWidgets('En EstimationStatusScreen completada, el botón VER RESULTADOS DE LA SESIÓN navega a SessionCompletedScreen', (tester) async {
      setMobileScreenSize(tester);
      final syncedSession = const RecentSessionModel(
        id: 's1',
        animalsProcessed: 12,
        timestamp: '08:45',
        date: 'Hoy',
        time: '08:45',
        isPending: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EstimationStatusScreen.fromSession(session: syncedSession),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica presencia del botón "VER RESULTADOS DE LA SESIÓN"
      final viewResultsButton = find.text('VER RESULTADOS DE LA SESIÓN');
      expect(viewResultsButton, findsOneWidget);

      await tester.tap(viewResultsButton);
      await tester.pumpAndSettle();

      // Debe abrir SessionCompletedScreen con los datos de la sesión
      expect(find.text('Resultados de sesión'), findsOneWidget);
      expect(find.text('AR-003421'), findsOneWidget);
      expect(find.text('458'), findsOneWidget);
    });
  });
}
