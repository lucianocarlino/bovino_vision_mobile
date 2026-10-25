import 'package:bovino_vision_mobile/core/theme/app_theme.dart';
import 'package:bovino_vision_mobile/features/rodeo/presentation/screens/animal_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  group('AnimalCreateScreen Tests', () {
    testWidgets('Renderiza formulario sin cabecera de foto, sin elementos de lectura y sin códigos técnicos', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const AnimalCreateScreen()));
      await tester.pumpAndSettle();

      // 1. AppBar
      expect(find.text('Registrar Animal'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // 2. Cabecera de foto estrictamente eliminada
      expect(find.text('Añadir foto del animal'), findsNothing);
      expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
      expect(find.byIcon(Icons.add_a_photo_rounded), findsNothing);

      // 3. Tarjetas y Campos de Entrada obligatorios
      expect(find.text('IDENTIFICADOR SENASA'), findsOneWidget);
      expect(find.text('RAZA'), findsOneWidget);
      expect(find.text('SEXO'), findsOneWidget);
      expect(find.text('LOTE'), findsOneWidget);
      expect(find.text('NACIMIENTO'), findsOneWidget);

      // 4. Elementos de lectura eliminados estrictamente
      expect(find.text('ÚLTIMO PESO'), findsNothing);
      expect(find.text('Último Peso'), findsNothing);
      expect(find.text('GMD'), findsNothing);
      expect(find.text('Historial de pesajes'), findsNothing);
      expect(find.text('Últimos pesajes'), findsNothing);
      expect(find.text('Iniciar nuevo pesaje'), findsNothing);

      // 5. Botón principal de acción
      expect(find.text('Guardar Animal'), findsOneWidget);

      // 6. Sin códigos técnicos
      expect(find.textContaining('RF-'), findsNothing);
      expect(find.textContaining('CU-'), findsNothing);
    });

    testWidgets('Permite crear un nuevo lote desde el menú desplegable y lo selecciona automáticamente', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const AnimalCreateScreen()));
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      // Dropdown de Lote es el tercero (índice 2)
      final loteDropdown = dropdowns.at(2);
      await tester.ensureVisible(loteDropdown);
      await tester.tap(loteDropdown);
      await tester.pumpAndSettle();

      // Opción de crear nuevo lote en el dropdown
      final createLoteOption = find.text('+ Nuevo lote').last;
      expect(createLoteOption, findsOneWidget);
      await tester.tap(createLoteOption);
      await tester.pumpAndSettle();

      // Verifica apertura del diálogo de creación
      expect(find.text('Nuevo Lote'), findsOneWidget);
      final inputField = find.widgetWithText(TextFormField, 'Nombre o número de lote');
      expect(inputField, findsOneWidget);

      // Escribe el nombre del nuevo lote
      await tester.enterText(inputField, 'Potrero Especial 9');
      await tester.pumpAndSettle();

      // Confirma creación
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Crear');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // El nuevo lote debe estar seleccionado y visible en el formulario
      expect(find.text('Potrero Especial 9'), findsOneWidget);
    });

    testWidgets('Permite crear una nueva raza desde el menú desplegable y la selecciona automáticamente', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const AnimalCreateScreen()));
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      // Dropdown de Raza es el primero (índice 0)
      final razaDropdown = dropdowns.at(0);
      await tester.ensureVisible(razaDropdown);
      await tester.tap(razaDropdown);
      await tester.pumpAndSettle();

      // Opción de crear nueva raza en el dropdown
      final createRazaOption = find.text('+ Nueva raza').last;
      expect(createRazaOption, findsOneWidget);
      await tester.tap(createRazaOption);
      await tester.pumpAndSettle();

      // Verifica apertura del diálogo de creación
      expect(find.text('Nueva Raza'), findsOneWidget);
      final inputField = find.widgetWithText(TextFormField, 'Nombre de la raza');
      expect(inputField, findsOneWidget);

      // Escribe el nombre de la nueva raza
      await tester.enterText(inputField, 'Senepol');
      await tester.pumpAndSettle();

      // Confirma creación
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Crear');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // La nueva raza debe estar seleccionada y visible en el formulario
      expect(find.text('Senepol'), findsOneWidget);
    });

    testWidgets('Validación: Al presionar Guardar Animal con campos vacíos activa validadores requeridos', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const AnimalCreateScreen()));
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Guardar Animal');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validadores activados
      expect(find.text('El identificador SENASA es obligatorio'), findsOneWidget);
      expect(find.text('Requerido'), findsNWidgets(4));

      // No debe mostrar SnackBar ya que el formulario no es válido
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Al completar los campos y presionar Guardar Animal guarda el registro, invoca callback y notifica', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Map<String, dynamic>? createdAnimalResult;

      await tester.pumpWidget(
        buildTestableWidget(
          AnimalCreateScreen(
            onAnimalCreated: (animal) {
              createdAnimalResult = animal;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Ingresar Identificador SENASA
      final idInput = find.widgetWithText(TextFormField, 'Ej. AR-003421');
      expect(idInput, findsOneWidget);
      await tester.enterText(idInput, 'AR-987654-Z');
      await tester.pumpAndSettle();

      // 2. Seleccionar Raza existente
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.at(0));
      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hereford').last);
      await tester.pumpAndSettle();

      // 3. Seleccionar Sexo
      await tester.ensureVisible(dropdowns.at(1));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hembra').last);
      await tester.pumpAndSettle();

      // 4. Seleccionar Lote existente
      await tester.ensureVisible(dropdowns.at(2));
      await tester.tap(dropdowns.at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lote B-05').last);
      await tester.pumpAndSettle();

      // 5. Seleccionar Fecha de Nacimiento
      final birthInput = find.widgetWithText(TextFormField, 'DD/MM/AAAA');
      expect(birthInput, findsOneWidget);
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

      // Presionar "Guardar Animal"
      final saveButton = find.widgetWithText(ElevatedButton, 'Guardar Animal');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      // Debe confirmar guardado con SnackBar de éxito
      expect(find.text('Animal AR-987654-Z registrado con éxito'), findsOneWidget);

      // Se debe haber creado el objeto con los datos correctos
      expect(createdAnimalResult, isNotNull);
      expect(createdAnimalResult!['id'], equals('AR-987654-Z'));
      expect(createdAnimalResult!['raza'], equals('Hereford'));
      expect(createdAnimalResult!['sexo'], equals('Hembra'));
      expect(createdAnimalResult!['lote'], equals('Lote B-05'));
      expect(createdAnimalResult!['estado'], equals('Registrado'));
    });
  });
}
