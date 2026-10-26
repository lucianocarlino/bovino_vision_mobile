import 'package:bovino_vision_mobile/features/capture/data/capture_models.dart';
import 'package:bovino_vision_mobile/features/capture/data/photo_picker.dart';
import 'package:bovino_vision_mobile/features/capture/presentation/capture_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the content type comes from the file extension', () {
    expect(contentTypeFor('a.jpg'), 'image/jpeg');
    expect(contentTypeFor('a.JPEG'), 'image/jpeg');
    expect(contentTypeFor('a.png'), 'image/png');
    expect(contentTypeFor('a.webp'), 'image/webp');
    expect(contentTypeFor('a.heic'), 'image/jpeg');
    expect(contentTypeFor('sin_extension'), 'image/jpeg');
  });

  test('the greeting follows the hour', () {
    expect(greetingFor(DateTime(2026, 10, 25, 7)), 'Buenos días');
    expect(greetingFor(DateTime(2026, 10, 25, 15)), 'Buenas tardes');
    expect(greetingFor(DateTime(2026, 10, 25, 23)), 'Buenas noches');
    expect(greetingFor(DateTime(2026, 10, 25, 3)), 'Buenas noches');
  });

  test('names are abbreviated to initial and last word', () {
    expect(abbreviateName('Francisco López'), 'F. López');
    expect(abbreviateName('Ana María de la Cruz'), 'A. Cruz');
    expect(abbreviateName('Francisco'), 'Francisco');
  });

  test('the previous weighing shows the change and the calendar days between weighings', () {
    Weighing weighing(double kg, String at, double previousKg, String previousAt) => Weighing(
      id: 'e',
      weightKg: kg,
      weighedAt: at,
      animalIdentifier: 'X',
      previous: PreviousWeight(weightKg: previousKg, weighedAt: previousAt),
    );

    final gain = previousWeighingRow(weighing(458, '2026-10-20T15:00:00', 443, '2026-09-17T10:00:00'))!;
    expect(gain.value, '443 kg · +15 kg en 33 días');
    expect(gain.tone, RowTone.positive);

    final loss = previousWeighingRow(weighing(440.5, '2026-10-20T15:00:00', 443, '2026-10-19T10:00:00'))!;
    expect(loss.value, '443 kg · -2,5 kg en 1 día');
    expect(loss.tone, RowTone.negative);

    expect(
      previousWeighingRow(weighing(443, '2026-10-20T15:00:00', 443, '2026-10-20T08:00:00'))!.value,
      '443 kg · +0 kg el mismo día',
    );
  });

  test('the estimation checklist follows the capture state', () {
    List<EstimationState> states(Capture? capture) => estimationSteps(capture).map((step) => step.state).toList();
    Capture capture(CaptureStatus status, {int attempts = 0}) => Capture(id: 'c', status: status, attempts: attempts);

    expect(states(null), [
      EstimationState.current,
      EstimationState.pending,
      EstimationState.pending,
      EstimationState.pending,
    ]);
    expect(states(capture(CaptureStatus.pending)), [
      EstimationState.done,
      EstimationState.current,
      EstimationState.pending,
      EstimationState.pending,
    ]);
    expect(states(capture(CaptureStatus.processed)), everyElement(EstimationState.done));
    expect(estimationSteps(capture(CaptureStatus.processing, attempts: 3))[2].text, 'Procesando la foto (intento 3)');
    expect(estimationSteps(capture(CaptureStatus.processing, attempts: 1))[2].text, 'Procesando la foto');
  });

  test('back leads to the previous step and only discards a registered photo', () {
    expect(backFrom(CaptureStep.identify, photoRegistered: false), isNull);
    expect(backFrom(CaptureStep.photo, photoRegistered: true)!.discardPhoto, isTrue);
    expect(backFrom(CaptureStep.photo, photoRegistered: false)!.discardPhoto, isFalse);
    expect(backFrom(CaptureStep.processing, photoRegistered: true)!.backgroundNotice, isTrue);
    expect(backFrom(CaptureStep.result, photoRegistered: true)!.label, 'Tomar otra foto');
  });
}
