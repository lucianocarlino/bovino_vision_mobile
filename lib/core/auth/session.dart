/// Permission codes of the API roles that the app uses.
abstract final class Permissions {
  static const captureRecord = 'capturas_registrar';
  static const herdRead = 'rodeo_consultar';
  static const herdManage = 'rodeo_gestionar';
  static const analyticsRead = 'analitica_consultar';
}

/// Logged-in user, as returned inside `Sesion`.
class SessionUser {
  const SessionUser({required this.id, required this.name, required this.email, required this.role});

  factory SessionUser.fromJson(Map<String, Object?> json) => SessionUser(
        id: json['id'] as String,
        name: json['nombre'] as String,
        email: json['correo'] as String,
        role: json['rol'] as String? ?? '',
      );

  final String id;
  final String name;
  final String email;
  final String role;

  Map<String, Object?> toJson() => {'id': id, 'nombre': name, 'correo': email, 'rol': role};
}

/// `Sesion` of `POST/GET /auth/sesion`: user, permission codes and absolute expiry.
class Session {
  const Session({required this.user, required this.permissions, required this.expiresAt});

  factory Session.fromJson(Map<String, Object?> json) => Session(
        user: SessionUser.fromJson(json['usuario'] as Map<String, Object?>),
        permissions: Set.unmodifiable((json['permisos'] as List).cast<String>()),
        expiresAt: DateTime.parse(json['expira_en'] as String),
      );

  final SessionUser user;
  final Set<String> permissions;
  final DateTime expiresAt;

  bool can(String permission) => permissions.contains(permission);

  bool isExpired([DateTime? now]) => !expiresAt.isAfter(now ?? DateTime.now());

  Map<String, Object?> toJson() => {
        'usuario': user.toJson(),
        'permisos': permissions.toList(),
        'expira_en': expiresAt.toUtc().toIso8601String(),
      };
}
