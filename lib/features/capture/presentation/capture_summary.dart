// Pure presentation rules of the capture flow, ported from the web app
// (`sesionesRecientes.ts`, `resumenDePesaje.ts`, `pasosDeEstimacion.ts`, `estadoCaptura.ts`, `navegacion.ts`).

import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../data/capture_models.dart';

/// "Buenos días", "Buenas tardes" or "Buenas noches" for the hour of [now].
String greetingFor(DateTime now) {
  if (now.hour >= 6 && now.hour < 12) return 'Buenos días';
  if (now.hour >= 12 && now.hour < 20) return 'Buenas tardes';
  return 'Buenas noches';
}

/// "Francisco López" becomes "F. López": first initial and last word; a single word stays as is.
String abbreviateName(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length < 2) return words.first;
  return '${words.first.substring(0, 1)}. ${words.last}';
}

enum DayReference { today, yesterday }

int _dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// Calendar days (local days, not 24 h blocks) from [from] to [to].
int calendarDaysBetween(String from, String to) => _dayNumber(parseApiDate(to)) - _dayNumber(parseApiDate(from));

/// Whether [value] falls on the calendar day of [now] or the day before; null otherwise.
DayReference? dayReference(String value, DateTime now) => switch (_dayNumber(now) - _dayNumber(parseApiDate(value))) {
  0 => DayReference.today,
  1 => DayReference.yesterday,
  _ => null,
};

class SessionSummary {
  const SessionSummary({required this.detail, required this.when, required this.inProgress});

  /// "12 animales procesados".
  final String detail;

  /// Hour for a session of today, "Ayer", or the date.
  final String when;
  final bool inProgress;
}

SessionSummary summarizeSession(RecentSession session, DateTime now) {
  final processed = session.processedCount;
  final when = switch (dayReference(session.startedAt, now)) {
    DayReference.today => formatTime(session.startedAt),
    DayReference.yesterday => 'Ayer',
    null => formatDate(session.startedAt),
  };
  return SessionSummary(
    detail: '$processed ${processed == 1 ? 'animal procesado' : 'animales procesados'}',
    when: when,
    inProgress: session.active,
  );
}

/// "440 kg" or "440,5 kg": decimals only when the weight has them.
String readableWeight(double kg) => formatKg(kg, kg == kg.roundToDouble() ? 0 : 1);

enum RowTone { positive, negative }

/// A row of the result sheet; [tone] colors the value (a gain reads green, a loss red).
class ResultRow {
  const ResultRow(this.label, this.value, [this.tone]);

  final String label;
  final String value;
  final RowTone? tone;
}

/// "443 kg · +15 kg en 33 días": the previous weight, the change and the days between weighings.
ResultRow? previousWeighingRow(Weighing weighing) {
  final previous = weighing.previous;
  if (previous == null) return null;

  final difference = (weighing.weightKg - previous.weightKg) * 10;
  final rounded = difference.roundToDouble() / 10;
  final sign = rounded >= 0 ? '+' : '-';
  final days = calendarDaysBetween(previous.weighedAt, weighing.weighedAt);
  final span = days == 0 ? 'el mismo día' : 'en $days ${days == 1 ? 'día' : 'días'}';
  final change = formatNumber(rounded.abs(), rounded == rounded.roundToDouble() ? 0 : 1);

  return ResultRow(
    'Pesaje anterior',
    '${readableWeight(previous.weightKg)} · $sign$change kg $span',
    rounded >= 0 ? RowTone.positive : RowTone.negative,
  );
}

/// "F. López · hoy 09:12": who took the capture and when; null when the operator is unknown.
String? describeOperator(String? operator, String weighedAt, DateTime now) {
  if (operator == null || operator.trim().isEmpty) return null;
  final when = switch (dayReference(weighedAt, now)) {
    DayReference.today => 'hoy ${formatTime(weighedAt)}',
    DayReference.yesterday => 'ayer ${formatTime(weighedAt)}',
    null => formatDateTime(weighedAt),
  };
  return '${abbreviateName(operator)} · $when';
}

/// Breed, sex and age of the animal, only those it has.
List<ResultRow> animalRows(Animal? animal, DateTime now) {
  if (animal == null) return const [];
  final age = animal.birthDate == null ? null : formatAge(animal.birthDate!, today: now);
  return [
    if (animal.breed != null) ResultRow('Raza', animal.breed!),
    if (animal.sex != null) ResultRow('Sexo', animal.sex!.label),
    if (age != null) ResultRow('Edad', age),
  ];
}

/// Data sheet of the result: tag, lot, previous weighing and operator (each only when known),
/// followed by the animal's breed, sex and age.
List<ResultRow> resultSheet(Weighing weighing, Animal? animal, DateTime now) {
  final previous = previousWeighingRow(weighing);
  final operator = describeOperator(weighing.operator, weighing.weighedAt, now);
  return [
    ResultRow('Identificador SENASA', weighing.animalIdentifier),
    if (weighing.lotCode != null && weighing.lotCode!.isNotEmpty) ResultRow('Lote', weighing.lotCode!),
    ?previous,
    if (operator != null) ResultRow('Operario', operator),
    ...animalRows(animal, now),
  ];
}

/// "Pérdida de peso: GMD -0,50 kg/día", with the lot target for stagnation.
String describeAlert(WeighingAlert alert) {
  final target = alert.type == WeighingAlertType.stagnation && alert.expectedGmd != null
      ? ' (objetivo ${formatGmd(alert.expectedGmd!)})'
      : '';
  return '${alert.type.label}: GMD ${formatGmd(alert.variation)}$target';
}

enum EstimationState { done, current, pending }

class EstimationStep {
  const EstimationStep(this.text, this.state);

  final String text;
  final EstimationState state;
}

/// The steps the estimation really goes through, read from the capture's state:
/// photo uploaded, queued, processing, estimated. `registered` counts as queued.
List<EstimationStep> estimationSteps(Capture? capture) {
  final done = capture == null
      ? 0
      : switch (capture.status) {
          CaptureStatus.registered || CaptureStatus.pending => 1,
          CaptureStatus.processing || CaptureStatus.failed => 2,
          CaptureStatus.processed => 4,
        };
  final attempt = capture != null && capture.status == CaptureStatus.processing && capture.attempts > 1
      ? ' (intento ${capture.attempts})'
      : '';
  final texts = ['Foto subida', 'En la cola de procesamiento', 'Procesando la foto$attempt', 'Peso estimado'];

  return [
    for (var index = 0; index < texts.length; index++)
      EstimationStep(
        texts[index],
        index < done ? EstimationState.done : (index == done ? EstimationState.current : EstimationState.pending),
      ),
  ];
}

/// Label of a capture in the session gallery; queued and in-progress read the same.
(String label, BadgeTone tone) captureStatusBadge(CaptureStatus status) => switch (status) {
  CaptureStatus.registered => ('Sin procesar', BadgeTone.neutral),
  CaptureStatus.pending || CaptureStatus.processing => ('Estimando', BadgeTone.warning),
  CaptureStatus.processed => ('Pesada', BadgeTone.brand),
  CaptureStatus.failed => ('Falló', BadgeTone.danger),
};

enum CaptureStep { identify, photo, processing, result }

/// Where "back" leads from a step.
class Back {
  const Back({required this.target, required this.label, this.discardPhoto = false, this.backgroundNotice = false});

  final CaptureStep target;
  final String label;

  /// The photo already registered in the API must be discarded before leaving.
  final bool discardPhoto;

  /// The estimation keeps running on the server, so the operator is told where to find it.
  final bool backgroundNotice;
}

Back? backFrom(CaptureStep step, {required bool photoRegistered}) => switch (step) {
  CaptureStep.identify => null,
  CaptureStep.photo => Back(target: CaptureStep.identify, label: 'Elegir otro animal', discardPhoto: photoRegistered),
  CaptureStep.processing => const Back(target: CaptureStep.photo, label: 'Volver a la foto', backgroundNotice: true),
  CaptureStep.result => const Back(target: CaptureStep.photo, label: 'Tomar otra foto'),
};
