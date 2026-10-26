import 'package:bovino_vision_mobile/core/data/herd_models.dart';
import 'package:bovino_vision_mobile/features/rodeo/domain/rodeo_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weightDifference shows the signed difference with one decimal only when needed', () {
    expect(weightDifference(452, 440)!.text, '+12 kg');
    expect(weightDifference(440, 450.5)!.text, '-10,5 kg');
    expect(weightDifference(440, 440)!.text, '0 kg');
    expect(weightDifference(440, 440)!.tone, DifferenceTone.unchanged);
    expect(weightDifference(440, 450.5)!.tone, DifferenceTone.loss);
    expect(weightDifference(452, null), isNull);
  });

  test('goalFraction needs a GMD and a positive target', () {
    expect(goalFraction(0.4, 0.8), 0.5);
    expect(goalFraction(null, 0.8), isNull);
    expect(goalFraction(0.4, null), isNull);
    expect(goalFraction(0.4, 0), isNull);
  });

  test('animalChips falls back to the web placeholders', () {
    const animal = Animal(id: 'a', identifier: 'AR-1');
    expect(animalChips(animal), ['Raza sin registrar', 'Edad sin registrar', 'Sin lote']);
    expect(animalSubtitle(animal), isNull);
  });

  test('herdKpis describes an empty herd', () {
    final kpis = herdKpis(HerdSummary.of(const []));
    expect([for (final k in kpis) k.value], ['0', '—', '—', '0']);
    expect(kpis[0].detail, '0 lotes activos');
  });
}
