import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_vision_mobile/core/network/connectivity_service.dart';
import 'package:bovino_vision_mobile/core/sync/sync_service.dart';
import 'package:bovino_vision_mobile/core/theme/app_theme.dart';
import 'package:bovino_vision_mobile/features/capture/data/datasources/capture_local_datasource.dart';
import 'package:bovino_vision_mobile/features/capture/data/models/capture_record_model.dart';
import 'package:bovino_vision_mobile/features/capture/data/repositories/capture_repository.dart';
import 'package:bovino_vision_mobile/features/home/data/home_mock_data.dart';
import 'package:bovino_vision_mobile/features/home/presentation/providers/home_sync_provider.dart';
import 'package:bovino_vision_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:bovino_vision_mobile/features/home/presentation/widgets/recent_sessions_list.dart';
import 'package:bovino_vision_mobile/features/home/presentation/widgets/sync_status_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline-first Persistence & Sync Tests', () {
    late CaptureLocalDataSource localDataSource;
    late CaptureRepository captureRepository;
    late ConnectivityService connectivityService;
    late SyncService syncService;

    setUp(() {
      localDataSource = CaptureLocalDataSource();
      captureRepository = CaptureRepository(localDataSource: localDataSource);
      connectivityService = ConnectivityService(
        reachabilityChecker: () async => true,
      );
      syncService = SyncService(
        connectivityService: connectivityService,
        captureRepository: captureRepository,
      );
    });

    test('CaptureLocalDataSource guarda pesajes y computa conteo pendiente', () async {
      expect(await captureRepository.getPendingCount(), 0);

      final capture1 = CaptureRecordModel(
        id: 'cap_1',
        animalId: 'AR-001001',
        loteId: 'lote_test',
        sessionId: 'ses_1',
        pesoEstimado: 420.5,
        imagenPath: 'assets/mock_cow.jpg',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      final capture2 = CaptureRecordModel(
        id: 'cap_2',
        animalId: 'AR-001002',
        loteId: 'lote_test',
        sessionId: 'ses_1',
        pesoEstimado: 460.0,
        imagenPath: 'assets/mock_cow.jpg',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      await captureRepository.saveSessionCaptures([capture1, capture2]);

      expect(await captureRepository.getPendingCount(), 2);
      final pending = await captureRepository.getPendingCaptures();
      expect(pending.length, 2);
      expect(pending.first.animalId, 'AR-001001');

      // Marcar sincronizados
      await captureRepository.markCapturesSynced(['cap_1', 'cap_2']);
      expect(await captureRepository.getPendingCount(), 0);
    });

    test('SyncService no sincroniza si el backend o la red está inalcanzable', () async {
      connectivityService.setSimulatedOnline(false);

      final capture = CaptureRecordModel(
        id: 'cap_offline',
        animalId: 'AR-002001',
        loteId: 'lote_test',
        sessionId: 'ses_offline',
        pesoEstimado: 410.0,
        imagenPath: 'assets/mock_cow.jpg',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      await captureRepository.saveSessionCaptures([capture]);
      expect(await captureRepository.getPendingCount(), 1);

      final result = await syncService.syncPendingRecords();
      expect(result, false);
      // Sigue pendiente en SQLite
      expect(await captureRepository.getPendingCount(), 1);
    });

    test('SyncService sincroniza exitosamente cuando la red está activa', () async {
      // Inicia offline para encolar pesaje
      connectivityService.setSimulatedOnline(false);

      final capture = CaptureRecordModel(
        id: 'cap_sync',
        animalId: 'AR-003001',
        loteId: 'lote_test',
        sessionId: 'ses_sync',
        pesoEstimado: 440.0,
        imagenPath: 'assets/mock_cow.jpg',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      await captureRepository.saveSessionCaptures([capture]);
      expect(await captureRepository.getPendingCount(), 1);

      // Al recuperar conexión se dispara la sincronización en segundo plano automáticamente
      connectivityService.setSimulatedOnline(true);
      await Future.delayed(const Duration(milliseconds: 900));

      expect(await captureRepository.getPendingCount(), 0);
    });

    test('HomeSyncProvider refleja dinámicamente estado con pesajes pendientes vs sincronizados', () async {
      final provider = HomeSyncProvider(
        connectivityService: connectivityService,
        captureRepository: captureRepository,
        syncService: syncService,
      );

      await provider.loadData();
      expect(provider.syncStatus.isSynced, true);
      expect(provider.syncStatus.title, 'Sincronización completa');

      // Añadir pesaje pendiente
      final capture = CaptureRecordModel(
        id: 'cap_prov_1',
        animalId: 'AR-004001',
        loteId: 'lote_test',
        sessionId: 'ses_prov',
        pesoEstimado: 430.0,
        imagenPath: 'assets/mock_cow.jpg',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      await captureRepository.saveSessionCaptures([capture]);
      await provider.loadData();

      expect(provider.syncStatus.isSynced, false);
      expect(provider.pendingCount, 1);
      expect(provider.syncStatus.title, '1 pesaje pendiente de sincronización');
    });
  });

  group('UI Offline-First Dynamic Widgets Tests', () {
    testWidgets('Indicador de conectividad en HomeHeader muestra "En línea" y "Sin conexión"', (tester) async {
      // 1. Estado En línea
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: HomeHeader(
              user: UserModel(name: 'Francisco López', initials: 'FL', isOnline: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('En línea'), findsOneWidget);
      expect(find.text('Sin conexión'), findsNothing);

      // 2. Estado Sin conexión
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: HomeHeader(
              user: UserModel(name: 'Francisco López', initials: 'FL', isOnline: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('En línea'), findsNothing);
    });

    testWidgets('SyncStatusCard cambia a alerta visual con pesajes pendientes', (tester) async {
      // 1. Sin pendientes (Sincronización completa)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SyncStatusCard(
              syncStatus: SyncStatusModel(
                isSynced: true,
                title: 'Sincronización completa',
                message: 'Los datos del rodeo están actualizados.',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sincronización completa'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);

      // 2. Con 3 pesajes pendientes (Alerta visual)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SyncStatusCard(
              syncStatus: SyncStatusModel(
                isSynced: false,
                title: '3 pesajes pendientes de sincronización',
                message: 'Almacenado localmente en SQLite. Se sincronizará al conectar.',
                pendingCount: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 pesajes pendientes de sincronización'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('RecentSessionsList muestra solo día, hora y cantidad de animales (sin nombre de sesión)', (tester) async {
      final sessions = [
        const RecentSessionModel(
          id: 'ses_local',
          animalsProcessed: 5,
          timestamp: '11:20',
          date: 'Hoy',
          time: '11:20',
          isPending: true,
        ),
        const RecentSessionModel(
          id: 's1',
          animalsProcessed: 12,
          timestamp: '08:45',
          date: 'Hoy',
          time: '08:45',
          isPending: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecentSessionsList(sessions: sessions),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No debe contener nombres de sesión
      expect(find.text('Lote Norte - Pesaje'), findsNothing);
      expect(find.text('Sesión Local - Campo'), findsNothing);

      // Muestra día y hora
      expect(find.text('Hoy, 11:20'), findsOneWidget);
      expect(find.text('Hoy, 08:45'), findsOneWidget);

      // Muestra cantidad de animales
      expect(find.text('5 animales'), findsOneWidget);
      expect(find.text('12 animales'), findsOneWidget);

      // Muestra indicador y badge para la sesión pendiente
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      expect(find.byIcon(Icons.assignment_turned_in_rounded), findsOneWidget);
    });
  });
}
