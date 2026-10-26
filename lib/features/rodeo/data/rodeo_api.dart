import '../../../core/api/api_client.dart';
import '../../../core/data/herd_models.dart';

List<Map<String, Object?>> _list(Object? json) => (json as List).cast<Map<String, Object?>>();

/// `PesajeHistorial`: one weighing event of an animal.
class Weighing {
  const Weighing({
    required this.id,
    required this.weightKg,
    required this.weighedAt,
    this.imageId,
    this.lotCode,
    this.gmdKgPerDay,
    this.operatorName,
  });

  factory Weighing.fromJson(Map<String, Object?> json) => Weighing(
        id: json['id'] as String,
        weightKg: (json['peso_kg'] as num).toDouble(),
        weighedAt: json['fecha_pesaje'] as String,
        imageId: json['id_imagen_utilizada'] as String?,
        lotCode: json['lote_codigo'] as String?,
        gmdKgPerDay: (json['gmd_kg_dia'] as num?)?.toDouble(),
        operatorName: json['operario'] as String?,
      );

  final String id;
  final double weightKg;
  final String weighedAt;

  /// Photo the estimation used (`GET /imagenes/{id}`).
  final String? imageId;
  final String? lotCode;

  /// GMD against the previous weighing; null for the first one or same-day weighings.
  final double? gmdKgPerDay;
  final String? operatorName;
}

/// `AsignacionLote`: one period of an animal in a lot; [until] is null for the current one.
class LotAssignment {
  const LotAssignment({required this.lotId, required this.lotCode, required this.since, this.until});

  factory LotAssignment.fromJson(Map<String, Object?> json) => LotAssignment(
        lotId: json['id_lote'] as String,
        lotCode: json['lote_codigo'] as String,
        since: json['vigente_desde'] as String,
        until: json['vigente_hasta'] as String?,
      );

  final String lotId;
  final String lotCode;
  final String since;
  final String? until;
}

/// Body of `PUT /animales/{id}`: only the fields that change. The API keeps the stored
/// value of a null field, so nothing can be cleared.
class AnimalChanges {
  const AnimalChanges({this.breedId, this.sex, this.birthDate, this.lotId});

  final String? breedId;
  final Sex? sex;
  final String? birthDate;
  final String? lotId;

  bool get isEmpty => breedId == null && sex == null && birthDate == null && lotId == null;

  Map<String, Object?> toJson() => {
        if (breedId != null) 'id_raza': breedId,
        if (sex != null) 'sexo': sex!.apiValue,
        if (birthDate != null) 'fecha_nacimiento': birthDate,
        if (lotId != null) 'id_lote': lotId,
      };
}

/// Animal endpoints that only the herd screens use; the shared ones live in `HerdApi`.
class RodeoApi {
  const RodeoApi(this._client);

  final ApiClient _client;

  /// 404 when the animal or the lot does not exist.
  Future<Animal> updateAnimal(String id, AnimalChanges changes) async =>
      Animal.fromJson(await _client.put('/animales/$id', body: changes.toJson()) as Map<String, Object?>);

  /// Weighing events, newest first.
  Future<List<Weighing>> weighings(String animalId) async =>
      _list(await _client.get('/animales/$animalId/pesajes')).map(Weighing.fromJson).toList();

  Future<List<LotAssignment>> lotHistory(String animalId) async =>
      _list(await _client.get('/animales/$animalId/historial-lotes')).map(LotAssignment.fromJson).toList();
}
