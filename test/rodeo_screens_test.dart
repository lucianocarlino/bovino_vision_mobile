import 'package:bovino_vision_mobile/core/theme/app_theme.dart';
import 'package:bovino_vision_mobile/features/rodeo/data/rodeo_mock_data.dart';
import 'package:bovino_vision_mobile/features/rodeo/presentation/screens/animal_create_screen.dart';
import 'package:bovino_vision_mobile/features/rodeo/presentation/screens/animal_detail_screen.dart';
import 'package:bovino_vision_mobile/features/rodeo/presentation/screens/rodeo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  group('RodeoScreen Tests', () {
    testWidgets('Renderiza elementos visuales, omite avatar, box de totales y box de alertas', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RodeoScreen()));
      await tester.pumpAndSettle();

      // Título en AppBar
      expect(find.text('Rodeo'), findsWidgets);

      // No debe contener avatar o iniciales en el menú superior
      expect(find.text('FL'), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);

      // El box de totales y el de alertas fueron eliminados según especificación
      expect(find.text('TOTAL CABEZAS'), findsNothing);
      expect(find.text('1.248'), findsNothing);
      expect(find.text('Alertas'), findsNothing);

      // Animales del listado mock
      expect(find.text('AR-339281-C'), findsOneWidget);
      expect(find.text('AR-440192-K'), findsOneWidget);
      expect(find.text('452 kg'), findsOneWidget);
      expect(find.text('388 kg'), findsOneWidget);
      expect(find.text('Aberdeen Angus'), findsOneWidget);
      expect(find.text('Hereford'), findsOneWidget);
      expect(find.text('Óptimo'), findsOneWidget);
      expect(find.text('Crecimiento'), findsOneWidget);

      // Pestaña Rodeo en NavigationBar seleccionada (index 1)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(1));

      // FAB con ícono add para "Agregar animal"
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(find.descendant(of: fab, matching: find.byIcon(Icons.add)), findsOneWidget);

      // Sin códigos técnicos
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('Al pulsar FAB Agregar animal navega a AnimalCreateScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RodeoScreen()));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(AnimalCreateScreen), findsOneWidget);
      expect(find.text('Registrar Animal'), findsOneWidget);
    });

    testWidgets('Al crear y guardar un animal desde el FAB, se añade y muestra en el listado de Rodeo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const RodeoScreen()));
      await tester.pumpAndSettle();

      // Pulsa el FAB
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(AnimalCreateScreen), findsOneWidget);

      // Completa los campos
      final idInput = find.widgetWithText(TextFormField, 'Ej. AR-003421');
      await tester.enterText(idInput, 'AR-112233-X');
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.at(0));
      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brangus').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(dropdowns.at(1));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Macho').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(dropdowns.at(2));
      await tester.tap(dropdowns.at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lote A-12').last);
      await tester.pumpAndSettle();

      final birthInput = find.widgetWithText(TextFormField, 'DD/MM/AAAA');
      await tester.ensureVisible(birthInput);
      await tester.tap(birthInput);
      await tester.pumpAndSettle();

      final okFinder = find.text('OK');
      if (okFinder.evaluate().isNotEmpty) {
        await tester.tap(okFinder);
        await tester.pumpAndSettle();
      } else {
        final aceptarFinder = find.text('Aceptar');
        if (aceptarFinder.evaluate().isNotEmpty) {
          await tester.tap(aceptarFinder);
          await tester.pumpAndSettle();
        }
      }

      // Presiona Guardar Animal
      final saveButton = find.widgetWithText(ElevatedButton, 'Guardar Animal');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Regresa a RodeoScreen y el nuevo animal debe estar visible en el listado
      expect(find.byType(RodeoScreen), findsOneWidget);
      expect(find.text('AR-112233-X'), findsOneWidget);
    });

    testWidgets('Permite filtrar animales por Lote', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RodeoScreen()));
      await tester.pumpAndSettle();

      // Inicialmente se muestran ambos
      expect(find.text('AR-339281-C'), findsOneWidget);
      expect(find.text('AR-440192-K'), findsOneWidget);

      // Filtra por Lote A-12
      final loteChip = find.text('Lote A-12');
      expect(loteChip, findsOneWidget);
      await tester.tap(loteChip);
      await tester.pumpAndSettle();

      expect(find.text('AR-339281-C'), findsOneWidget);
      expect(find.text('AR-440192-K'), findsNothing);

      // Filtra por Lote B-05
      final loteBChip = find.text('Lote B-05');
      expect(loteBChip, findsOneWidget);
      await tester.tap(loteBChip);
      await tester.pumpAndSettle();

      expect(find.text('AR-339281-C'), findsNothing);
      expect(find.text('AR-440192-K'), findsOneWidget);
    });

    testWidgets('Al tocar tarjeta de animal navega a AnimalDetailScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RodeoScreen()));
      await tester.pumpAndSettle();

      final animalCard = find.text('AR-339281-C');
      await tester.tap(animalCard);
      await tester.pumpAndSettle();

      expect(find.byType(AnimalDetailScreen), findsOneWidget);
      expect(find.text('AR-339281-C'), findsWidgets);
    });
  });

  group('AnimalDetailScreen Tests', () {
    testWidgets('Modo Online (isOffline == false) muestra imagen de captura', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AnimalDetailScreen(isOffline: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Última captura'), findsOneWidget);
      expect(find.text('Imagen no disponible'), findsNothing);
    });

    testWidgets('Modo Offline (isOffline == true) muestra placeholder estético vacío', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AnimalDetailScreen(isOffline: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imagen no disponible'), findsOneWidget);
      expect(find.text('Modo sin conexión activo'), findsOneWidget);
      expect(find.text('Última captura'), findsNothing);
    });

    testWidgets('Muestra valores de negocio y componentes "Not implemented", sin botón de pesaje', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AnimalDetailScreen(
            isOffline: false,
            initialData: RodeoMockData.rawJson,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Valores mantenidos del diseño
      expect(find.text('IDENTIFICADOR SENASA'), findsOneWidget);
      expect(find.text('AR-003421'), findsWidgets);
      expect(find.text('Aberdeen Angus'), findsWidgets);
      expect(find.text('Macho'), findsOneWidget);
      expect(find.text('24 meses'), findsOneWidget);
      expect(find.text('A-12 - Potrero 4'), findsOneWidget);
      expect(find.text('15 mar 2022'), findsOneWidget);
      expect(find.text('482 kg'), findsOneWidget);

      // Componentes con aviso "Not implemented"
      // 1. Salud (chip superior)
      expect(find.text('Salud: Not implemented'), findsOneWidget);

      // 2. GMD (tarjeta atenuada)
      expect(find.text('GMD'), findsOneWidget);

      // 3. Historial de pesajes (gráfico y lista inferior)
      expect(find.text('Gráfico de evolución: Not implemented'), findsOneWidget);
      expect(find.text('Lista de pesajes históricos: Not implemented'), findsOneWidget);

      // El botón Iniciar nuevo pesaje debe estar eliminado
      expect(find.text('Iniciar nuevo pesaje'), findsNothing);

      // Sin códigos técnicos
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('Permite modificar identificador, lote, raza, sexo y nacimiento y actualiza la vista', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AnimalDetailScreen(
            isOffline: false,
            initialData: RodeoMockData.rawJson,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre diálogo de edición mediante el icono en AppBar
      final editButton = find.byTooltip('Modificar animal');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verifica que el diálogo se abra con los campos
      expect(find.text('Modificar animal'), findsOneWidget);
      expect(find.text('Identificador SENASA'), findsOneWidget);
      expect(find.text('Lote'), findsOneWidget);
      expect(find.text('Raza'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Nacimiento'), findsOneWidget);

      // Encuentra los TextFormFields y modifica los valores
      final idFinder = find.widgetWithText(TextFormField, 'Identificador SENASA');
      final loteFinder = find.widgetWithText(TextFormField, 'Lote');
      final razaFinder = find.widgetWithText(TextFormField, 'Raza');
      final sexoFinder = find.widgetWithText(TextFormField, 'Sexo');
      final nacimientoFinder = find.widgetWithText(TextFormField, 'Nacimiento');

      await tester.enterText(idFinder, 'AR-999999');
      await tester.enterText(loteFinder, 'Lote Especial');
      await tester.enterText(razaFinder, 'Brangus');
      await tester.enterText(sexoFinder, 'Hembra');
      await tester.enterText(nacimientoFinder, '10 oct 2023');
      await tester.pumpAndSettle();

      // Presiona Guardar
      final guardarButton = find.widgetWithText(ElevatedButton, 'Guardar');
      await tester.tap(guardarButton);
      await tester.pumpAndSettle();

      // Verifica que los valores modificados se reflejan en pantalla
      expect(find.text('AR-999999'), findsWidgets);
      expect(find.text('Lote Especial'), findsOneWidget);
      expect(find.text('Brangus'), findsWidgets);
      expect(find.text('Hembra'), findsOneWidget);
      expect(find.text('10 oct 2023'), findsOneWidget);

      // Notificación de confirmación
      expect(find.text('Datos del animal actualizados'), findsOneWidget);
    });

    testWidgets('Al pulsar componentes Not implemented en detalle muestra SnackBar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AnimalDetailScreen(isOffline: false),
        ),
      );
      await tester.pumpAndSettle();

      final saludChip = find.text('Salud: Not implemented');
      await tester.tap(saludChip);
      await tester.pump();

      expect(
        find.descendant(of: find.byType(SnackBar), matching: find.text('Not implemented')),
        findsOneWidget,
      );
    });
  });
}
