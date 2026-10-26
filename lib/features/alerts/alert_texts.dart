import '../../core/data/herd_models.dart';
import '../../core/format/formatters.dart';
import '../../core/widgets/app_badge.dart';

// Alert wording and ordering, ported from the web app (`src/features/alertas/textos.ts`
// and `tarjetas.ts`).

enum PriorityLevel {
  high('alta', BadgeTone.danger),
  medium('media', BadgeTone.warning),
  low('baja', BadgeTone.neutral);

  const PriorityLevel(this.label, this.tone);

  final String label;
  final BadgeTone tone;

  /// Priority 1 is the most urgent; the API uses 1 for weight loss and 2 for stagnation.
  static PriorityLevel of(int priority) => priority <= 1
      ? PriorityLevel.high
      : priority == 2
          ? PriorityLevel.medium
          : PriorityLevel.low;
}

/// "Estancamiento: GMD +0,20 kg/día (objetivo +0,80 kg/día)".
String describeAlert(Alert alert) {
  final target = alert.type == AlertType.stagnation && alert.expectedGmd != null
      ? ' (objetivo ${formatGmd(alert.expectedGmd!)})'
      : '';
  return '${alert.type.label}: GMD ${formatGmd(alert.variation)}$target';
}

/// The [limit] alerts to highlight: most urgent first, then the most recent.
List<Alert> featuredAlerts(List<Alert> alerts, int limit) {
  final sorted = [...alerts]..sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0 ? byPriority : parseApiDate(b.createdAt).compareTo(parseApiDate(a.createdAt));
    });
  return sorted.take(limit).toList();
}

/// Link text of the panel strip that leads to the full list.
String seeAlertsText(int count) => count == 1 ? 'Ver la alerta' : 'Ver las $count alertas';
