import 'dart:convert';

import 'package:bovino_vision_mobile/core/data/herd_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import 'rodeo_fixtures.dart';

Future<void> _pick(WidgetTester tester, Finder dropdown, String option) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the sign-up form with the catalogs of the API', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales/nuevo');

    expect(find.text('Nuevo animal'), findsOneWidget);
    expect(find.text('Identificador del nuevo animal'), findsOneWidget);
    expect(find.text('Raza'), findsOneWidget);
    expect(find.text('Sexo'), findsOneWidget);
    expect(find.text('Fecha de nacimiento'), findsOneWidget);
    expect(find.text('Lote'), findsOneWidget);
    expect(find.text('dd/mm/aaaa'), findsOneWidget);
    expect(api.sent('GET', '/razas'), hasLength(1));
    expect(api.sent('GET', '/lotes'), isNotEmpty);
  });

  testWidgets('the birth date picker speaks Spanish', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales/nuevo');

    await tester.tap(find.text('dd/mm/aaaa'));
    await tester.pumpAndSettle();

    final dialog = find.byType(DatePickerDialog);
    expect(dialog, findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Selecciona una fecha')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Cancelar')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('ACEPTAR')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Cancel')), findsNothing);
  });

  testWidgets('Agregar posts the typed data and goes back to the refreshed list', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('POST', '/animales', (_) => animalJson(id: 'a3', identifier: 'AR-777'));
    await pumpApp(tester, api, location: '/animales');
    await tester.tap(find.text('Nuevo animal'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '  AR-777 ');
    await tester.pump();
    await _pick(tester, find.byType(DropdownButton<String?>).first, 'Angus');
    await _pick(tester, find.byType(DropdownButton<Sex?>), 'Hembra');
    await tester.tap(find.text('dd/mm/aaaa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), '15/03/2024');
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('15/03/2024'), findsOneWidget);
    await _pick(tester, find.byType(DropdownButton<String?>).last, 'Lote A1');

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    final post = api.sent('POST', '/animales').single;
    expect(jsonDecode(post.body), {
      'identificador': 'AR-777',
      'id_raza': 'r1',
      'sexo': 'hembra',
      'fecha_nacimiento': '2024-03-15',
      'id_lote': 'l1',
    });
    expect(currentPath(tester), '/animales');
    expect(api.sent('GET', '/animales'), hasLength(2));
  });

  testWidgets('with only the identifier the optional fields are sent empty', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('POST', '/animales', (_) => animalJson(id: 'a3', identifier: 'AR-778'));
    await pumpApp(tester, api, location: '/animales/nuevo');

    await tester.enterText(find.byType(TextField).last, 'AR-778');
    await tester.pump();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(jsonDecode(api.sent('POST', '/animales').single.body), {
      'identificador': 'AR-778',
      'id_raza': null,
      'sexo': null,
      'fecha_nacimiento': null,
      'id_lote': null,
    });
  });

  testWidgets('a duplicated identifier shows the 409 detail and stays on the form', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('POST', '/animales', (_) => const FakeReply(409, {'detail': 'Ya existe un animal con ese identificador.'}));
    await pumpApp(tester, api, location: '/animales/nuevo');

    await tester.enterText(find.byType(TextField).last, 'AR-001');
    await tester.pump();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe un animal con ese identificador.'), findsOneWidget);
    expect(currentPath(tester), '/animales/nuevo');
    expect(find.text('AR-001'), findsOneWidget);
  });

  testWidgets('a blank identifier cannot be submitted', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales/nuevo');

    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.pump();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(api.sent('POST', '/animales'), isEmpty);
  });

  testWidgets('Cancelar goes back to the list without creating anything', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    await pumpApp(tester, api, location: '/animales/nuevo');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/animales');
    expect(api.sent('POST', '/animales'), isEmpty);
  });

  testWidgets('a failing catalog load shows the message with Reintentar', (tester) async {
    useTallPhone(tester);
    final api = FakeApi();
    registerHerd(api);
    api.on('GET', '/razas', (_) => const FakeReply(500, {'detail': 'Falla del servidor.'}));
    await pumpApp(tester, api, location: '/animales/nuevo');

    expect(find.text('Falla del servidor.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
