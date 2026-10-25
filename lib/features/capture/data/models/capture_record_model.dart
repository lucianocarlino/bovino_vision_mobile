/// Modelo de datos para una captura y pesaje individual persistida en SQLite
class CaptureRecordModel {
  final String id;
  final String animalId;
  final String loteId;
  final String sessionId;
  final double pesoEstimado;
  final double? confianza;
  final String imagenPath;
  final DateTime timestamp;
  final String syncStatus; // 'pending' | 'synced'

  const CaptureRecordModel({
    required this.id,
    required this.animalId,
    required this.loteId,
    required this.sessionId,
    required this.pesoEstimado,
    this.confianza,
    required this.imagenPath,
    required this.timestamp,
    this.syncStatus = 'pending',
  });

  bool get isPending => syncStatus == 'pending';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'lote_id': loteId,
      'session_id': sessionId,
      'peso_estimado': pesoEstimado,
      'confianza': confianza,
      'imagen_path': imagenPath,
      'timestamp': timestamp.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory CaptureRecordModel.fromMap(Map<String, dynamic> map) {
    return CaptureRecordModel(
      id: map['id'] as String,
      animalId: map['animal_id'] as String,
      loteId: map['lote_id'] as String,
      sessionId: map['session_id'] as String,
      pesoEstimado: (map['peso_estimado'] as num).toDouble(),
      confianza: (map['confianza'] as num?)?.toDouble(),
      imagenPath: map['imagen_path'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  CaptureRecordModel copyWith({
    String? id,
    String? animalId,
    String? loteId,
    String? sessionId,
    double? pesoEstimado,
    double? confianza,
    String? imagenPath,
    DateTime? timestamp,
    String? syncStatus,
  }) {
    return CaptureRecordModel(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      loteId: loteId ?? this.loteId,
      sessionId: sessionId ?? this.sessionId,
      pesoEstimado: pesoEstimado ?? this.pesoEstimado,
      confianza: confianza ?? this.confianza,
      imagenPath: imagenPath ?? this.imagenPath,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
