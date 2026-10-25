import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/features/capture/presentation/screens/estimation_status_screen.dart';
import 'package:bovino_vision_mobile/features/home/data/home_mock_data.dart';
import 'package:bovino_vision_mobile/features/home/presentation/widgets/recent_sessions_list.dart';

void main() {
  testWidgets('EstimationStatusScreen renders default mock correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EstimationStatusScreen(),
      ),
    );

    // Verify Title & absence of "4/4"
    expect(find.text('Captura de ganado'), findsOneWidget);
    expect(find.textContaining('4/4'), findsNothing);

    // Verify Animal ID and headline
    expect(find.textContaining('AR-003421'), findsOneWidget);
    expect(find.text('Estimando peso...'), findsOneWidget);
    expect(find.textContaining('No cierres la aplicación'), findsOneWidget);

    // Verify Progress percentage
    expect(find.text('Progreso del análisis'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);

    // Verify 4 synchronization steps
    expect(find.text('Conexión al backend establecida'), findsOneWidget);
    expect(find.text('Prioridad asignada en cola'), findsOneWidget);
    expect(find.text('Subiendo imagen (1/1)'), findsOneWidget);
    expect(find.text('45% completado (1.2 MB / 2.6 MB)'), findsOneWidget);
    expect(find.text('Estimando peso (IA)'), findsOneWidget);

    // Verify offline-first info card
    expect(find.text('Podés seguir capturando'), findsOneWidget);
    expect(
      find.textContaining('Si perdés señal, la estimación queda en cola y se envía sola cuando vuelva la conexión.'),
      findsOneWidget,
    );

    // Verify Close button shows "Not implemented" SnackBar
    final closeButton = find.byTooltip('Cerrar');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump();

    expect(find.text('Not implemented'), findsOneWidget);
  });

  testWidgets('Al tocar una sesión pendiente navega a EstimationStatusScreen con estado en progreso', (tester) async {
    final pendingSession = const RecentSessionModel(
      id: 'ses_pending_1',
      animalsProcessed: 1,
      timestamp: 'Hoy 10:15',
      date: 'Hoy',
      time: '10:15',
      isPending: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentSessionsList(
            sessions: [pendingSession],
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap on the pending session
    await tester.tap(find.text('Hoy, 10:15'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should be on EstimationStatusScreen
    expect(find.text('Captura de ganado'), findsOneWidget);
    expect(find.text('Estimando peso...'), findsOneWidget);
    expect(find.text('Caravana: AR-003421'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('Subiendo imagen (1/1)'), findsOneWidget);
    expect(find.text('Podés seguir capturando'), findsOneWidget);
  });

  testWidgets('Al tocar una sesión sincronizada navega a EstimationStatusScreen con estado completado', (tester) async {
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
        home: Scaffold(
          body: RecentSessionsList(
            sessions: [syncedSession],
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap on the synced session
    await tester.tap(find.text('Hoy, 08:45'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should be on EstimationStatusScreen with completed status
    expect(find.text('Captura de ganado'), findsOneWidget);
    expect(find.text('Estimación completada'), findsOneWidget);
    expect(find.textContaining('AR-001012'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Imagen subida (1/1)'), findsOneWidget);
    expect(find.text('Sesión sincronizada con éxito'), findsOneWidget);
  });
}
