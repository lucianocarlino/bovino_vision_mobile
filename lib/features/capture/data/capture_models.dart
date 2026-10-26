// Capture entities of the BovinoVision API (snake_case JSON, UUID strings, ISO 8601 dates).

double? _toDouble(Object? value) => value == null ? null : (value as num).toDouble();

/// `SesionCaptura`: a work session of one operator.
class CaptureSession {
  const CaptureSession({required this.id});

  factory CaptureSession.fromJson(Map<String, Object?> json) => CaptureSession(id: json['id'] as String);

  final String id;
}

/// `SesionReciente` of `GET /sesiones-captura`.
class RecentSession {
  const RecentSession({required this.id, required this.startedAt, required this.active, required this.processedCount});

  factory RecentSession.fromJson(Map<String, Object?> json) => RecentSession(
    id: json['id'] as String,
    startedAt: json['fecha_inicio'] as String,
    active: json['estado'] == 'activa',
    processedCount: (json['cantidad_procesadas'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String startedAt;

  /// The session was not closed yet.
  final bool active;
  final int processedCount;
}

enum CaptureStatus {
  registered,
  pending,
  processing,
  processed,
  failed;

  static CaptureStatus fromApi(Object? value) => switch (value) {
    'registrada' => CaptureStatus.registered,
    'procesando' => CaptureStatus.processing,
    'procesada' => CaptureStatus.processed,
    'fallida' => CaptureStatus.failed,
    _ => CaptureStatus.pending,
  };
}

/// `Captura`: one photo of an animal and the state of its estimation.
class Capture {
  const Capture({
    required this.id,
    required this.status,
    this.failureReason,
    this.attempts = 0,
    this.reviewedAt,
    this.weighingEventId,
  });

  factory Capture.fromJson(Map<String, Object?> json) => Capture(
    id: json['id'] as String,
    status: CaptureStatus.fromApi(json['estado']),
    failureReason: json['motivo_fallo'] as String?,
    attempts: (json['intentos'] as num?)?.toInt() ?? 0,
    reviewedAt: json['fecha_revision'] as String?,
    weighingEventId: json['id_evento_pesaje'] as String?,
  );

  final String id;
  final CaptureStatus status;
  final String? failureReason;
  final int attempts;

  /// Set once the operator confirmed the result.
  final String? reviewedAt;
  final String? weighingEventId;

  bool get isConfirmed => reviewedAt != null;
}

/// `CapturaDeSesion` of `GET /sesiones-captura/{id}/capturas`.
class SessionCapture {
  const SessionCapture({
    required this.id,
    required this.animalIdentifier,
    required this.capturedAt,
    required this.status,
    this.failureReason,
    this.imageId,
  });

  factory SessionCapture.fromJson(Map<String, Object?> json) => SessionCapture(
    id: json['id'] as String,
    animalIdentifier: json['animal_identificador'] as String? ?? '',
    capturedAt: json['fecha_captura'] as String,
    status: CaptureStatus.fromApi(json['estado']),
    failureReason: json['motivo_fallo'] as String?,
    imageId: json['id_imagen'] as String?,
  );

  final String id;
  final String animalIdentifier;
  final String capturedAt;
  final CaptureStatus status;
  final String? failureReason;
  final String? imageId;
}

enum WeighingAlertType {
  weightLoss('Pérdida de peso'),
  stagnation('Estancamiento');

  const WeighingAlertType(this.label);

  final String label;

  static WeighingAlertType fromApi(Object? value) =>
      value == 'estancamiento' ? WeighingAlertType.stagnation : WeighingAlertType.weightLoss;
}

/// `AlertaDePesaje`: the alert raised by a weighing; [variation] is the interval GMD.
class WeighingAlert {
  const WeighingAlert({required this.type, required this.variation, this.expectedGmd});

  factory WeighingAlert.fromJson(Map<String, Object?> json) => WeighingAlert(
    type: WeighingAlertType.fromApi(json['tipo']),
    variation: (json['variacion'] as num).toDouble(),
    expectedGmd: _toDouble(json['gmd_esperada']),
  );

  final WeighingAlertType type;
  final double variation;
  final double? expectedGmd;
}

/// `PesoPrevio`: the animal's last weighing before this one.
class PreviousWeight {
  const PreviousWeight({required this.weightKg, required this.weighedAt});

  factory PreviousWeight.fromJson(Map<String, Object?> json) =>
      PreviousWeight(weightKg: (json['peso_kg'] as num).toDouble(), weighedAt: json['fecha_pesaje'] as String);

  final double weightKg;
  final String weighedAt;
}

/// `Pesaje` of `GET /pesajes/{id}`: the estimated weight and its context.
class Weighing {
  const Weighing({
    required this.id,
    required this.weightKg,
    required this.weighedAt,
    required this.animalIdentifier,
    this.imageId,
    this.lotCode,
    this.previous,
    this.alert,
    this.operator,
  });

  factory Weighing.fromJson(Map<String, Object?> json) => Weighing(
    id: json['id'] as String,
    weightKg: (json['peso_kg'] as num).toDouble(),
    weighedAt: json['fecha_pesaje'] as String,
    animalIdentifier: json['animal_identificador'] as String? ?? '',
    imageId: json['id_imagen'] as String?,
    lotCode: json['lote_codigo'] as String?,
    previous: json['ultimo_peso_previo'] == null
        ? null
        : PreviousWeight.fromJson(json['ultimo_peso_previo'] as Map<String, Object?>),
    alert: json['alerta'] == null ? null : WeighingAlert.fromJson(json['alerta'] as Map<String, Object?>),
    operator: json['operario'] as String?,
  );

  final String id;
  final double weightKg;
  final String weighedAt;
  final String animalIdentifier;
  final String? imageId;
  final String? lotCode;
  final PreviousWeight? previous;
  final WeighingAlert? alert;

  /// Name of the user who took the capture.
  final String? operator;
}
