import 'session_gallery_item.dart';

/// Modelo de datos de estado para la pantalla de captura según la especificación ERS.
class CaptureScreenData {
  final int pendingSyncCount;
  final String currentAnimalId;
  final List<SessionGalleryItem> sessionGallery;

  const CaptureScreenData({
    required this.pendingSyncCount,
    required this.currentAnimalId,
    required this.sessionGallery,
  });

  factory CaptureScreenData.fromJson(Map<String, dynamic> json) {
    return CaptureScreenData(
      pendingSyncCount: json['pendingSyncCount'] as int? ?? 0,
      currentAnimalId: json['currentAnimalId'] as String? ?? '',
      sessionGallery: (json['sessionGallery'] as List<dynamic>?)
              ?.map((item) =>
                  SessionGalleryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingSyncCount': pendingSyncCount,
      'currentAnimalId': currentAnimalId,
      'sessionGallery': sessionGallery.map((item) => item.toJson()).toList(),
    };
  }

  CaptureScreenData copyWith({
    int? pendingSyncCount,
    String? currentAnimalId,
    List<SessionGalleryItem>? sessionGallery,
  }) {
    return CaptureScreenData(
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      currentAnimalId: currentAnimalId ?? this.currentAnimalId,
      sessionGallery: sessionGallery ?? this.sessionGallery,
    );
  }

  /// Estado inicial de la sesión de captura:
  /// La sesión inicia sin capturas previas (galería vacía) y con el identificador vacío,
  /// mostrando un placeholder de ejemplo (no válido) para obligar al ingreso de la caravana.
  static const Map<String, dynamic> rawJson = {
    "pendingSyncCount": 3,
    "currentAnimalId": "",
    "sessionGallery": []
  };

  static CaptureScreenData get staticMock => CaptureScreenData.fromJson(rawJson);
}
