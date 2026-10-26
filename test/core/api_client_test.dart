import 'dart:convert';
import 'dart:io';

import 'package:bovino_vision_mobile/core/api/api_client.dart';
import 'package:bovino_vision_mobile/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object? body, int status, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8', ...headers});

void main() {
  test('builds URLs under the base path and skips null query values', () {
    final client = ApiClient(baseUrl: Uri.parse('http://10.0.2.2:8000/'), httpClient: MockClient((_) async => http.Response('', 200)));
    expect(client.uri('/animales', {'q': 'AR 1', 'id_lote': null}).toString(), 'http://10.0.2.2:8000/animales?q=AR+1');

    final prefixed = ApiClient(baseUrl: Uri.parse('https://host/api'), httpClient: MockClient((_) async => http.Response('', 200)));
    expect(prefixed.uri('/lotes').toString(), 'https://host/api/lotes');
    expect(prefixed.imageUrl('abc'), 'https://host/api/imagenes/abc');
  });

  test('sends the session cookie and JSON body, and decodes the JSON response', () async {
    late http.Request sent;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((request) async {
        sent = request;
        return jsonResponse({'id': '1', 'identificador': 'AR-1'}, 201);
      }),
    )..sessionToken = 'tok123';

    final result = await client.post('/animales', body: {'identificador': 'AR-1'});

    expect(sent.method, 'POST');
    expect(sent.headers['Cookie'], 'bovinovision_sesion=tok123');
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {'identificador': 'AR-1'});
    expect(result, {'id': '1', 'identificador': 'AR-1'});
  });

  test('returns null for empty 202/204 bodies', () async {
    final client = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => http.Response('', 202)));
    expect(await client.post('/pesajes', body: {'id_captura': 'c1'}), isNull);
  });

  test('turns ProblemDetails into ApiException with detail, flattened errors or title', () async {
    Future<ApiException> failWith(Object body, int status) async {
      final client = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => jsonResponse(body, status)));
      try {
        await client.get('/x');
      } on ApiException catch (e) {
        return e;
      }
      fail('expected ApiException');
    }

    final conflict = await failWith({'title': 'Conflict', 'detail': 'Ya existe un animal con identificador AR-1'}, 409);
    expect(conflict.message, 'Ya existe un animal con identificador AR-1');
    expect(conflict.statusCode, 409);

    final validation = await failWith({
      'title': 'One or more validation errors occurred.',
      'errors': {
        'identificador': ['El identificador es obligatorio'],
        'sexo': ['Valor inválido'],
      },
    }, 400);
    expect(validation.message, 'El identificador es obligatorio Valor inválido');

    final titleOnly = await failWith({'title': 'Not Found'}, 404);
    expect(titleOnly.message, 'Not Found');
  });

  test('calls onUnauthorized on 401 unless the request opts out', () async {
    var calls = 0;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((_) async => jsonResponse({'detail': 'Iniciá sesión para continuar.'}, 401)),
    )..onUnauthorized = () => calls++;

    await expectLater(client.get('/animales'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(calls, 1);

    await expectLater(client.post('/auth/sesion', body: {}, handleUnauthorized: false), throwsA(isA<ApiException>()));
    expect(calls, 1);
  });

  test('maps connection failures to a network ApiException', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((_) async => throw const SocketException('unreachable')),
    );
    await expectLater(
      client.get('/animales'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true).having((e) => e.message, 'message', ApiException.networkMessage)),
    );
  });

  test('uploads multipart fields and a file part with an explicit content type', () async {
    late http.Request sent;
    final client = ApiClient(
      baseUrl: Uri.parse('http://api'),
      httpClient: MockClient((request) async {
        sent = request;
        return jsonResponse({'id': 'c1', 'estado': 'registrada'}, 201);
      }),
    )..sessionToken = 'tok';

    final result = await client.postMultipart(
      '/capturas',
      fields: {'id_sesion': 's1', 'id_animal': 'a1'},
      file: MultipartUpload(field: 'imagen', filename: 'foto.jpg', contentType: 'image/jpeg', bytes: [1, 2, 3]),
    );

    expect(result, {'id': 'c1', 'estado': 'registrada'});
    expect(sent.headers['Cookie'], 'bovinovision_sesion=tok');
    final contentType = sent.headers['Content-Type']!;
    expect(contentType, startsWith('multipart/form-data; boundary='));
    final body = latin1.decode(sent.bodyBytes);
    expect(body, contains('Content-Disposition: form-data; name="id_sesion"\r\n\r\ns1\r\n'));
    expect(body, contains('Content-Disposition: form-data; name="id_animal"\r\n\r\na1\r\n'));
    expect(body, contains('Content-Disposition: form-data; name="imagen"; filename="foto.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'));
  });

  test('reports reachability from GET /health', () async {
    final up = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((r) async => jsonResponse({'status': 'ok'}, r.url.path == '/health' ? 200 : 404)));
    expect(await up.isReachable(), isTrue);

    final down = ApiClient(baseUrl: Uri.parse('http://api'), httpClient: MockClient((_) async => throw const SocketException('down')));
    expect(await down.isReachable(), isFalse);
  });

  test('extracts the session token from Set-Cookie', () {
    expect(
      extractSessionToken('bovinovision_sesion=abc-DEF_123; expires=Mon, 26 Oct 2026 12:00:00 GMT; path=/; secure; samesite=strict; httponly'),
      'abc-DEF_123',
    );
    expect(extractSessionToken('other=1, bovinovision_sesion=xyz; path=/'), 'xyz');
    expect(extractSessionToken('other=1'), isNull);
    expect(extractSessionToken(null), isNull);
  });
}
