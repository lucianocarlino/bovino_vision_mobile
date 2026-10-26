// Herd entities of the BovinoVision API (snake_case JSON, UUID strings, ISO 8601 dates).

double? _toDouble(Object? value) => value == null ? null : (value as num).toDouble();

enum Sex {
  male('macho', 'Macho'),
  female('hembra', 'Hembra');

  const Sex(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Sex? fromApi(Object? value) => switch (value) {
        'macho' => Sex.male,
        'hembra' => Sex.female,
        _ => null,
      };
}

/// `Raza`: one of the seeded breeds.
class Breed {
  const Breed({required this.id, required this.name});

  factory Breed.fromJson(Map<String, Object?> json) => Breed(id: json['id'] as String, name: json['nombre'] as String);

  final String id;
  final String name;
}

/// `Lote`: group of animals with an optional target GMD (kg/day).
class Lot {
  const Lot({required this.id, required this.code, this.name, this.gmdTarget, this.animalCount = 0});

  factory Lot.fromJson(Map<String, Object?> json) => Lot(
        id: json['id'] as String,
        code: json['codigo'] as String,
        name: json['nombre'] as String?,
        gmdTarget: _toDouble(json['gmd_objetivo']),
        animalCount: (json['cantidad_animales'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String code;
  final String? name;
  final double? gmdTarget;
  final int animalCount;

  /// "Lote A-12", the label the web app uses for chips and cards.
  String get label => 'Lote $code';
}

/// `Animal` as listed by `GET /animales` and `GET /animales/{id}`.
class Animal {
  const Animal({
    required this.id,
    required this.identifier,
    this.lotId,
    this.lotCode,
    this.breedId,
    this.breed,
    this.sex,
    this.birthDate,
    this.lastWeightKg,
    this.gmdKgPerDay,
    this.activeAlerts = 0,
    this.lastWeighingImageId,
  });

  factory Animal.fromJson(Map<String, Object?> json) => Animal(
        id: json['id'] as String,
        identifier: json['identificador'] as String,
        lotId: json['id_lote'] as String?,
        lotCode: json['lote_codigo'] as String?,
        breedId: json['id_raza'] as String?,
        breed: json['raza'] as String?,
        sex: Sex.fromApi(json['sexo']),
        birthDate: json['fecha_nacimiento'] as String?,
        lastWeightKg: _toDouble(json['ultimo_peso_kg']),
        gmdKgPerDay: _toDouble(json['gmd_kg_dia']),
        activeAlerts: (json['alertas_activas'] as num?)?.toInt() ?? 0,
        lastWeighingImageId: json['id_imagen_ultimo_pesaje'] as String?,
      );

  final String id;

  /// SENASA tag ("caravana").
  final String identifier;
  final String? lotId;
  final String? lotCode;
  final String? breedId;
  final String? breed;
  final Sex? sex;

  /// Calendar date "YYYY-MM-DD".
  final String? birthDate;
  final double? lastWeightKg;

  /// GMD between the last two weighings; null with fewer than two.
  final double? gmdKgPerDay;
  final int activeAlerts;

  /// Photo of the latest weighing (`GET /imagenes/{id}`); null when never weighed.
  final String? lastWeighingImageId;
}

/// Body of `POST /animales`; only [identifier] is required.
class NewAnimal {
  const NewAnimal({required this.identifier, this.breedId, this.sex, this.birthDate, this.lotId});

  final String identifier;
  final String? breedId;
  final Sex? sex;
  final String? birthDate;
  final String? lotId;

  Map<String, Object?> toJson() => {
        'identificador': identifier.trim(),
        'id_raza': breedId,
        'sexo': sex?.apiValue,
        'fecha_nacimiento': birthDate,
        'id_lote': lotId,
      };
}

enum AlertType {
  weightLoss('perdida_peso', 'Pérdida de peso'),
  stagnation('estancamiento', 'Estancamiento');

  const AlertType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AlertType fromApi(Object? value) => value == 'estancamiento' ? AlertType.stagnation : AlertType.weightLoss;
}

/// `Alerta` of `GET /alertas` and `GET /animales/{id}/alertas`; [variation] is the interval GMD.
class Alert {
  const Alert({
    required this.id,
    required this.animalId,
    required this.animalIdentifier,
    required this.type,
    required this.priority,
    required this.variation,
    this.expectedGmd,
    required this.active,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, Object?> json) => Alert(
        id: json['id'] as String,
        animalId: json['id_animal'] as String,
        animalIdentifier: json['animal_identificador'] as String? ?? '',
        type: AlertType.fromApi(json['tipo']),
        priority: (json['prioridad'] as num).toInt(),
        variation: (json['variacion'] as num).toDouble(),
        expectedGmd: _toDouble(json['gmd_esperada']),
        active: json['estado'] == 'activa',
        createdAt: json['fecha_generacion'] as String,
      );

  final String id;
  final String animalId;
  final String animalIdentifier;
  final AlertType type;

  /// 1 is the most urgent.
  final int priority;
  final double variation;
  final double? expectedGmd;
  final bool active;
  final String createdAt;
}
