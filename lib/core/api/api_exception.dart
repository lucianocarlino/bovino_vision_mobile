/// Failure of an API call, with the message to show the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  const ApiException.network() : this(networkMessage);

  static const networkMessage = 'No se pudo conectar con el servidor. Revisá tu conexión.';

  final String message;

  /// HTTP status, or null when the server could not be reached.
  final int? statusCode;

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
