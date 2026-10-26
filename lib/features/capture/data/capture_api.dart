import '../../../core/api/api_client.dart';
import 'capture_models.dart';
import 'photo_picker.dart';

List<Map<String, Object?>> _list(Object? json) => (json as List).cast<Map<String, Object?>>();

Map<String, Object?> _object(Object? json) => json as Map<String, Object?>;

/// Capture sessions, photos and weighings: the endpoints behind the capture flow.
class CaptureApi {
  const CaptureApi(this._client);

  final ApiClient _client;

  /// Sessions of the current user, newest first; [limit] goes from 1 to 20.
  Future<List<RecentSession>> recentSessions({int limit = 5}) async =>
      _list(await _client.get('/sesiones-captura', query: {'limite': limit})).map(RecentSession.fromJson).toList();

  Future<CaptureSession> startSession() async =>
      CaptureSession.fromJson(_object(await _client.post('/sesiones-captura')));

  /// Registers the photo; 422 when the image is not acceptable.
  Future<Capture> upload({required String sessionId, required String animalId, required PickedPhoto photo}) async {
    final json = await _client.postMultipart(
      '/capturas',
      fields: {'id_sesion': sessionId, 'id_animal': animalId},
      file: MultipartUpload(
        field: 'imagen',
        filename: photo.filename,
        contentType: photo.contentType,
        bytes: photo.bytes,
      ),
    );
    return Capture.fromJson(_object(json));
  }

  Future<Capture> capture(String id) async => Capture.fromJson(_object(await _client.get('/capturas/$id')));

  /// The operator acknowledges the result; it never changes the weighing.
  Future<Capture> confirm(String id) async => Capture.fromJson(_object(await _client.post('/capturas/$id/confirmar')));

  /// Discards a photo that was not sent to estimation; 404 when it is already gone.
  Future<void> discard(String id) => _client.delete('/capturas/$id');

  Future<List<SessionCapture>> sessionCaptures(String sessionId) async =>
      _list(await _client.get('/sesiones-captura/$sessionId/capturas')).map(SessionCapture.fromJson).toList();

  /// Queues the estimation (202, no body); poll [capture] for the outcome.
  Future<void> requestWeighing(String captureId) async {
    await _client.post('/pesajes', body: {'id_captura': captureId});
  }

  Future<Weighing> weighing(String eventId) async => Weighing.fromJson(_object(await _client.get('/pesajes/$eventId')));
}
