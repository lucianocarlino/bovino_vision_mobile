import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/features/capture/presentation/screens/estimation_status_screen.dart';
import 'package:bovino_vision_mobile/features/home/data/home_mock_data.dart';
import 'package:bovino_vision_mobile/features/home/presentation/widgets/recent_sessions_list.dart';

void main() {
  testWidgets('EstimationStatusScreen renders default mock correctly and omits caravana box and estimar peso step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EstimationStatusScreen(),
      ),
    );

    // Verify Title & absence of "4/4"
    expect(find.text('Captura de ganado'), findsOneWidget);
    expect(find.textContaining('4/4'), findsNothing);

    // Verify Caravana box is removed
    expect(find.textContaining('Caravana:'), findsNothing);

    // Verify Headline
    expect(find.text('Sincronizando sesión...'), findsOneWidget);
    expect(find.textContaining('No cierres la aplicación'), findsOneWidget);

    // Verify Progress percentage
    expect(find.text('Progreso de sincronización'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);

    // Verify 3 synchronization steps (omitting estimar peso)
    expect(find.text('Conexión al backend establecida'), findsOneWidget);
    expect(find.text('Prioridad asignada en cola'), findsOneWidget);
    expect(find.text('Subiendo imagen (1/1)'), findsOneWidget);
    expect(find.text('45% completado (1.2 MB / 2.6 MB)'), findsOneWidget);
    expect(find.text('Estimando peso (IA)'), findsNothing);

    // Verify offline-first info card
    expect(find.text('Podés seguir capturando'), findsOneWidget);
    expect(
      find.textContaining('Si perdés señal, la estimación queda en cola y se envía sola cuando vuelva la conexión.'),
      findsOneWidget,
    );
  });

  testWidgets('Al tocar la X retorna a la pantalla anterior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EstimationStatusScreen(),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open EstimationStatusScreen
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Captura de ganado'), findsOneWidget);

    // Tap Close 'X' button
    final closeButton = find.byTooltip('Cerrar');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify we returned to the previous screen and EstimationStatusScreen is gone
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Captura de ganado'), findsNothing);
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
    expect(find.text('Sincronizando sesión...'), findsOneWidget);
    expect(find.textContaining('Caravana:'), findsNothing);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('Subiendo imagen (1/1)'), findsOneWidget);
    expect(find.text('Estimando peso (IA)'), findsNothing);
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
    expect(find.text('Sincronización completada'), findsOneWidget);
    expect(find.textContaining('Caravana:'), findsNothing);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Imagen subida (1/1)'), findsOneWidget);
    expect(find.text('Estimando peso (IA)'), findsNothing);
    expect(find.text('Sesión sincronizada con éxito'), findsOneWidget);
  });
}
