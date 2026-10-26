import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Name of the session cookie issued by `POST /auth/sesion`.
const sessionCookieName = 'bovinovision_sesion';

final _sessionCookiePattern = RegExp('(?:^|[,;]\\s*)$sessionCookieName=([^;,\\s]+)');

/// Value of the session cookie inside a `Set-Cookie` header, or null.
String? extractSessionToken(String? setCookieHeader) {
  if (setCookieHeader == null) return null;
  return _sessionCookiePattern.firstMatch(setCookieHeader)?.group(1);
}

/// File part of a multipart upload. The backend validates the part's content type.
class MultipartUpload {
  const MultipartUpload({required this.field, required this.filename, required this.contentType, required this.bytes});

  final String field;
  final String filename;
  final String contentType;
  final List<int> bytes;
}

/// HTTP client for the BovinoVision API.
///
/// The API authenticates with an `HttpOnly` session cookie. A non-browser client has no
/// cookie jar, so the token is kept here and sent back in the `Cookie` header.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(seconds: 60),
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final Duration uploadTimeout;
  final http.Client _http;

  String? sessionToken;

  /// Called when a request answers 401, i.e. the session expired or was revoked.
  void Function()? onUnauthorized;

  Map<String, String> get authHeaders =>
      sessionToken == null ? const {} : {'Cookie': '$sessionCookieName=$sessionToken'};

  Uri uri(String path, [Map<String, Object?>? query]) {
    final basePath = baseUrl.path.endsWith('/') ? baseUrl.path.substring(0, baseUrl.path.length - 1) : baseUrl.path;
    final parameters = <String, String>{
      for (final entry in (query ?? const <String, Object?>{}).entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return baseUrl.replace(path: '$basePath$path', queryParameters: parameters.isEmpty ? null : parameters);
  }

  /// URL of a stored photo (`GET /imagenes/{id}`); load it with [authHeaders].
  String imageUrl(String imageId) => uri('/imagenes/$imageId').toString();

  Future<Object?> get(String path, {Map<String, Object?>? query}) async =>
      decodeJson(await send('GET', path, query: query));

  Future<Object?> post(String path, {Object? body, bool handleUnauthorized = true}) async =>
      decodeJson(await send('POST', path, body: body, handleUnauthorized: handleUnauthorized));

  Future<Object?> put(String path, {Object? body}) async => decodeJson(await send('PUT', path, body: body));

  Future<void> delete(String path) async => send('DELETE', path);

  /// Sends a JSON request and returns the raw response; throws [ApiException] unless it is 2xx.
  Future<http.Response> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool handleUnauthorized = true,
  }) {
    final request = http.Request(method, uri(path, query))
      ..headers.addAll({'Accept': 'application/json', ...authHeaders});
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    return _execute(request, timeout, handleUnauthorized);
  }

  Future<Object?> postMultipart(String path, {required Map<String, String> fields, required MultipartUpload file}) async {
    final boundary = 'bovinovision-${Random().nextInt(1 << 32).toRadixString(16)}${DateTime.now().microsecondsSinceEpoch}';
    final request = http.Request('POST', uri(path))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        ...authHeaders,
      })
      ..bodyBytes = _multipartBody(boundary, fields, file);
    return decodeJson(await _execute(request, uploadTimeout, true));
  }

  /// True when `GET /health` answers 200 within a few seconds.
  Future<bool> isReachable() async {
    try {
      final response = await _http.get(uri('/health')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void close() => _http.close();

  Future<http.Response> _execute(http.Request request, Duration limit, bool handleUnauthorized) async {
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(limit));
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    } on TimeoutException {
      throw const ApiException.network();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    if (response.statusCode == 401 && handleUnauthorized) onUnauthorized?.call();
    throw ApiException(_problemMessage(response), statusCode: response.statusCode);
  }

  Object? decodeJson(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// RFC 9457 ProblemDetails: `detail`, else the flattened `errors`, else `title`.
  String _problemMessage(http.Response response) {
    try {
      final problem = jsonDecode(utf8.decode(response.bodyBytes));
      if (problem is Map<String, Object?>) {
        final detail = problem['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        final errors = problem['errors'];
        if (errors is Map && errors.isNotEmpty) {
          return errors.values.expand((value) => value is List ? value : [value]).join(' ');
        }
        final title = problem['title'];
        if (title is String && title.isNotEmpty) return title;
      }
    } on FormatException {
      // Not JSON: fall through to the generic message.
    }
    return 'Error inesperado del servidor (${response.statusCode}).';
  }

  List<int> _multipartBody(String boundary, Map<String, String> fields, MultipartUpload file) {
    final builder = BytesBuilder(copy: false);
    void write(String text) => builder.add(utf8.encode(text));
    for (final entry in fields.entries) {
      write('--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n');
    }
    write(
      '--$boundary\r\nContent-Disposition: form-data; name="${file.field}"; filename="${file.filename}"\r\n'
      'Content-Type: ${file.contentType}\r\n\r\n',
    );
    builder.add(file.bytes);
    write('\r\n--$boundary--\r\n');
    return builder.takeBytes();
  }
}
