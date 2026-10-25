/// Modelo de dominio para un elemento capturado en la galería de sesión actual.
class SessionGalleryItem {
  final String id;
  final String animalId;
  final String imageThumbnail;
  final DateTime? capturedAt;

  const SessionGalleryItem({
    required this.id,
    required this.animalId,
    required this.imageThumbnail,
    this.capturedAt,
  });

  factory SessionGalleryItem.fromJson(Map<String, dynamic> json) {
    return SessionGalleryItem(
      id: json['id'] as String? ?? '',
      animalId: json['animalId'] as String? ?? '',
      imageThumbnail: json['imageThumbnail'] as String? ?? '',
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animalId': animalId,
      'imageThumbnail': imageThumbnail,
      if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
    };
  }

  SessionGalleryItem copyWith({
    String? id,
    String? animalId,
    String? imageThumbnail,
    DateTime? capturedAt,
  }) {
    return SessionGalleryItem(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      imageThumbnail: imageThumbnail ?? this.imageThumbnail,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
