import '../../core/api/api_client.dart';

double? _toDouble(Object? value) => value == null ? null : (value as num).toDouble();

class EvolutionPoint {
  const EvolutionPoint({required this.date, this.averageWeightKg});

  factory EvolutionPoint.fromJson(Map<String, Object?> json) =>
      EvolutionPoint(date: json['fecha'] as String, averageWeightKg: _toDouble(json['peso_promedio_kg']));

  /// Calendar date "YYYY-MM-DD".
  final String date;
  final double? averageWeightKg;
}

/// `Panel` of `GET /panel`.
class PanelData {
  const PanelData({
    required this.animalCount,
    this.averageWeightKg,
    this.averageGmd,
    required this.animalsWithGmd,
    required this.evolution,
  });

  factory PanelData.fromJson(Map<String, Object?> json) => PanelData(
        animalCount: (json['cantidad_animales'] as num).toInt(),
        averageWeightKg: _toDouble(json['peso_promedio_kg']),
        averageGmd: _toDouble(json['gmd_promedio_kg_dia']),
        animalsWithGmd: (json['animales_con_gmd'] as num).toInt(),
        evolution: (json['evolucion_peso_promedio'] as List)
            .cast<Map<String, Object?>>()
            .map(EvolutionPoint.fromJson)
            .toList(),
      );

  final int animalCount;
  final double? averageWeightKg;
  final double? averageGmd;
  final int animalsWithGmd;
  final List<EvolutionPoint> evolution;
}

/// `Reporte` of `GET /reportes`.
class PeriodReport {
  const PeriodReport({required this.weighings, required this.animals, this.averageWeightKg, this.averageGmd});

  factory PeriodReport.fromJson(Map<String, Object?> json) => PeriodReport(
        weighings: (json['cantidad_pesajes'] as num).toInt(),
        animals: (json['cantidad_animales'] as num).toInt(),
        averageWeightKg: _toDouble(json['peso_promedio_kg']),
        averageGmd: _toDouble(json['gmd_promedio_kg_dia']),
      );

  final int weighings;
  final int animals;
  final double? averageWeightKg;
  final double? averageGmd;
}

/// Analytics endpoints; both need `analitica_consultar`.
class PanelApi {
  const PanelApi(this._client);

  final ApiClient _client;

  Future<PanelData> panel({String? lotId}) async =>
      PanelData.fromJson(await _client.get('/panel', query: {'id_lote': lotId}) as Map<String, Object?>);

  /// Dates are "YYYY-MM-DD"; answers 422 when [from] is after [to].
  Future<PeriodReport> report({required String from, required String to, String? lotId}) async {
    final json = await _client.get('/reportes', query: {'desde': from, 'hasta': to, 'id_lote': lotId});
    return PeriodReport.fromJson(json as Map<String, Object?>);
  }
}

int _daysBetween(String from, String to) {
  DateTime asUtc(String value) {
    final parts = value.substring(0, 10).split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  return asUtc(to).difference(asUtc(from)).inDays;
}

/// Target weight at each real point: the first average weight plus the lot's target daily gain
/// times the days since that point. Null when the lot has no target or there are no points.
List<double>? targetCurve(List<EvolutionPoint> points, double? gmdTarget) {
  if (gmdTarget == null) return null;
  final real = points.where((p) => p.averageWeightKg != null).toList();
  if (real.isEmpty) return null;
  final first = real.first;
  return [for (final p in real) first.averageWeightKg! + gmdTarget * _daysBetween(first.date, p.date)];
}
