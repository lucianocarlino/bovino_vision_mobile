import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';

// Herd figures and wording, ported from the web app (`src/features/animales/rodeo.ts`
// and `src/features/alertas/textos.ts`).

/// Figures behind the four tiles of the herd list.
class HerdSummary {
  const HerdSummary({
    required this.head,
    required this.withAlerts,
    required this.alerts,
    required this.lots,
    required this.avgWeightKg,
    required this.withWeight,
    required this.avgGmd,
    required this.withGmd,
  });

  factory HerdSummary.of(List<Animal> animals) {
    final weights = [for (final a in animals) ?a.lastWeightKg];
    final gmds = [for (final a in animals) ?a.gmdKgPerDay];
    return HerdSummary(
      head: animals.length,
      withAlerts: animals.where((a) => a.activeAlerts > 0).length,
      alerts: animals.fold(0, (sum, a) => sum + a.activeAlerts),
      lots: {for (final a in animals) ?a.lotId}.length,
      avgWeightKg: _average(weights),
      withWeight: weights.length,
      avgGmd: _average(gmds),
      withGmd: gmds.length,
    );
  }

  final int head;

  /// Animals with at least one active alert.
  final int withAlerts;

  /// Sum of the active alerts of every animal.
  final int alerts;

  /// Distinct lots with at least one of these animals.
  final int lots;
  final double? avgWeightKg;
  final int withWeight;
  final double? avgGmd;
  final int withGmd;
}

double? _average(List<double> values) =>
    values.isEmpty ? null : values.reduce((sum, value) => sum + value) / values.length;

String _animals(int count) => '${formatNumber(count)} ${count == 1 ? 'animal' : 'animales'}';

/// Content of one KPI tile.
class KpiData {
  const KpiData({required this.label, required this.value, required this.detail});

  final String label;
  final String value;
  final String detail;
}

/// The four tiles of the herd list; [lotCode] is set when they describe a single lot.
List<KpiData> herdKpis(HerdSummary summary, {String? lotCode}) {
  final activeLots = '${formatNumber(summary.lots)} ${summary.lots == 1 ? 'lote activo' : 'lotes activos'}';
  return [
    KpiData(
      label: 'Total animales',
      value: formatNumber(summary.head),
      detail: lotCode != null ? 'Lote $lotCode' : activeLots,
    ),
    KpiData(
      label: 'Peso promedio',
      value: summary.avgWeightKg == null ? '—' : formatKg(summary.avgWeightKg!),
      detail: summary.withWeight > 0 ? 'Último pesaje de ${_animals(summary.withWeight)}' : 'Todavía sin pesajes',
    ),
    KpiData(
      label: 'GMD promedio',
      value: summary.avgGmd == null ? '—' : '${formatNumber(summary.avgGmd!, 2)} kg/día',
      detail: summary.withGmd > 0
          ? '${_animals(summary.withGmd)} con dos pesajes o más'
          : 'Hace falta un segundo pesaje',
    ),
    KpiData(
      label: 'Alertas activas',
      value: formatNumber(summary.alerts),
      detail: summary.withAlerts > 0 ? 'En ${_animals(summary.withAlerts)}' : 'Ninguna pendiente',
    ),
  ];
}

/// The animal's GMD as a fraction of its lot target; null without GMD or a positive target.
double? goalFraction(double? gmd, double? target) {
  if (gmd == null || target == null || target <= 0) return null;
  return gmd / target;
}

enum DifferenceTone { gain, loss, unchanged }

/// Weight change against the previous weighing: "+15 kg" or "-10,5 kg". Null without a previous one.
({String text, DifferenceTone tone})? weightDifference(double current, double? previous) {
  if (previous == null) return null;
  // Same rounding as JavaScript's Math.round, which the web app uses.
  final difference = ((current - previous) * 10 + 0.5).floor() / 10;
  if (difference == 0) return (text: formatKg(0), tone: DifferenceTone.unchanged);
  final magnitude = formatKg(difference.abs(), difference == difference.truncate() ? 0 : 1);
  return difference > 0
      ? (text: '+$magnitude', tone: DifferenceTone.gain)
      : (text: '-$magnitude', tone: DifferenceTone.loss);
}

/// "15 may 2024 · F. López"; just the date when the weighing has no operator.
String dateOperatorLine(String weighedAt, String? operatorName) {
  final day = '${formatShortDate(weighedAt)} ${parseApiDate(weighedAt).year}';
  return operatorName == null ? day : '$day · $operatorName';
}

/// Chips under the animal's name: breed, age and lot.
List<String> animalChips(Animal animal, {DateTime? today}) {
  final age = animal.birthDate == null ? null : formatAge(animal.birthDate!, today: today);
  return [
    animal.breed ?? 'Raza sin registrar',
    age ?? 'Edad sin registrar',
    animal.lotCode != null ? 'Lote ${animal.lotCode}' : 'Sin lote',
  ];
}

/// "Macho · Nació el 20/10/2025", or null when neither is known.
String? animalSubtitle(Animal animal) {
  final parts = [
    ?animal.sex?.label,
    if (animal.birthDate != null) 'Nació el ${formatDate(animal.birthDate!)}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// "YYYY-MM-DD", the format of the API's calendar dates.
String toApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}
