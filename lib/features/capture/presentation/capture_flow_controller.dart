import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/data/herd_api.dart';
import '../../../core/data/herd_models.dart';
import '../data/capture_api.dart';
import '../data/capture_models.dart';
import '../data/photo_picker.dart';
import 'capture_summary.dart';

/// Outcome of an estimation: a weighing, or the capture that failed.
class CaptureResult {
  const CaptureResult({required this.capture, this.weighing});

  final Capture capture;

  /// Null when the estimation failed.
  final Weighing? weighing;

  bool get isEstimated => weighing != null;
}

class _OpenSession {
  const _OpenSession(this.token, this.id);

  final String? token;
  final String id;
}

String _messageOf(Object error) => error is ApiException ? error.message : 'No se pudo completar la operación.';

/// State of the capture wizard (`useCaptura.ts` of the web app): one capture session, the
/// animal being weighed, its photo, the polling of the estimation and the result.
class CaptureFlowController extends ChangeNotifier {
  CaptureFlowController({required this._client, required this._herd}) : _api = CaptureApi(_client);

  /// Session opened by the last "Nueva captura", per client and login. Coming back to the capture
  /// home and starting again resumes it, as the web app does while its page stays open.
  static final _openSessions = Expando<_OpenSession>();

  final ApiClient _client;
  final HerdApi _herd;
  final CaptureApi _api;

  String? _sessionId;
  CaptureStep _step = CaptureStep.identify;
  Animal? _animal;
  Capture? _capture;
  CaptureResult? _result;
  bool _loading = false;
  bool _removingPhoto = false;
  bool _openingAnimal = false;
  String? _error;
  String? _notice;
  Uint8List? _preview;
  final _previews = <String, Uint8List>{};
  int _galleryVersion = 0;

  bool _disposed = false;
  bool _sessionRequested = false;
  bool _animalRequested = false;
  int _pollTicket = 0;
  Timer? _pollTimer;
  Completer<void>? _pause;

  String? get sessionId => _sessionId;
  CaptureStep get step => _step;
  Animal? get animal => _animal;
  Capture? get capture => _capture;
  CaptureResult? get result => _result;
  bool get loading => _loading;
  bool get removingPhoto => _removingPhoto;
  bool get openingAnimal => _openingAnimal;
  String? get error => _error;
  String? get notice => _notice;

  /// Photo just taken, shown in the frame until it is removed or replaced.
  Uint8List? get preview => _preview;

  /// Local copies of the photos taken in this flow, by capture id, for the gallery.
  Map<String, Uint8List> get previews => _previews;

  /// Changes whenever a capture is added, removed or finishes, so the gallery reloads.
  int get galleryVersion => _galleryVersion;

  Back? get back => _animal == null ? null : backFrom(_step, photoRegistered: _capture != null);

  /// Opens the capture session (or resumes the remembered one) and, when [animalId] is given,
  /// loads that animal so identification is skipped. Safe to call again.
  void start({String? animalId}) {
    if (animalId != null && !_animalRequested) {
      _animalRequested = true;
      _openAnimal(animalId);
    }
    _openSession();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }

  /// Invalidates the running poll and cancels its wait, so no timer outlives the flow.
  void _stopPolling() {
    _pollTicket++;
    _pollTimer?.cancel();
    final pause = _pause;
    if (pause != null && !pause.isCompleted) pause.complete();
  }

  Future<void> _waitForNextPoll() {
    final pause = _pause = Completer<void>();
    _pollTimer = Timer(CaptureSettings.pollInterval, pause.complete);
    return pause.future;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _openSession() async {
    final remembered = _openSessions[_client];
    if (remembered != null && remembered.token == _client.sessionToken) {
      if (_sessionId == null) {
        _sessionId = remembered.id;
        _emit();
      }
      return;
    }
    if (_sessionRequested) return;
    _sessionRequested = true;
    _error = null;
    try {
      final session = await _api.startSession();
      _openSessions[_client] = _OpenSession(_client.sessionToken, session.id);
      _sessionId = session.id;
    } catch (error) {
      _sessionRequested = false;
      _error = _messageOf(error);
    }
    _emit();
  }

  Future<void> _openAnimal(String id) async {
    _openingAnimal = true;
    _emit();
    try {
      selectAnimal(await _herd.animal(id));
    } catch (error) {
      // Identifying the animal by hand is still possible.
      _error = 'No pudimos abrir el animal elegido. ${_messageOf(error)}';
    }
    _openingAnimal = false;
    _emit();
  }

  void selectAnimal(Animal animal) {
    _animal = animal;
    _capture = null;
    _result = null;
    _preview = null;
    _error = null;
    _notice = null;
    _step = CaptureStep.photo;
    _emit();
  }

  void reportError(String message) {
    _error = message;
    _emit();
  }

  /// Takes a photo from [source] and registers it in the API.
  Future<void> takePhoto(PhotoSource source) async {
    if (_sessionId == null || _animal == null || _loading) return;
    final PickedPhoto? photo;
    try {
      photo = await CaptureSettings.photoPicker.pick(source);
    } catch (_) {
      reportError('No pudimos abrir la cámara. Revisá los permisos de la aplicación.');
      return;
    }
    if (photo == null || _disposed) return;
    _preview = photo.bytes;
    await _upload(photo);
  }

  Future<void> _upload(PickedPhoto photo) async {
    _loading = true;
    _error = null;
    _notice = null;
    _emit();
    try {
      final registered = await _api.upload(sessionId: _sessionId!, animalId: _animal!.id, photo: photo);
      _capture = registered;
      _previews[registered.id] = photo.bytes;
      _galleryVersion++;
    } catch (error) {
      _error = _messageOf(error);
    }
    _loading = false;
    _emit();
  }

  Future<void> requestWeighing() async {
    final captured = _capture;
    if (captured == null) return;
    final ticket = _pollTicket;
    _loading = true;
    _error = null;
    _emit();
    try {
      await _api.requestWeighing(captured.id);
      // The operator may have left while the request was in flight.
      if (_disposed || ticket != _pollTicket) return;
      _step = CaptureStep.processing;
    } catch (error) {
      _error = _messageOf(error);
      return;
    } finally {
      _loading = false;
      _emit();
    }
    await _pollUntilDone(captured.id);
  }

  void retryPolling() {
    final captured = _capture;
    if (captured != null) _pollUntilDone(captured.id);
  }

  /// Polls the capture until the background estimation ends in `procesada` or `fallida`.
  Future<void> _pollUntilDone(String captureId) async {
    final ticket = ++_pollTicket;
    bool current() => !_disposed && ticket == _pollTicket;
    _error = null;
    _emit();
    try {
      for (;;) {
        final latest = await _api.capture(captureId);
        if (!current()) return;
        _capture = latest;
        _emit();

        if (latest.status == CaptureStatus.failed) return _finish(CaptureResult(capture: latest));
        final eventId = latest.weighingEventId;
        if (latest.status == CaptureStatus.processed && eventId != null) {
          final weighing = await _api.weighing(eventId);
          if (!current()) return;
          return _finish(CaptureResult(capture: latest, weighing: weighing));
        }

        await _waitForNextPoll();
        if (!current()) return;
      }
    } catch (error) {
      if (!current()) return;
      _error = _messageOf(error);
      _emit();
    }
  }

  void _finish(CaptureResult result) {
    _result = result;
    _step = CaptureStep.result;
    _galleryVersion++;
    _emit();
  }

  Future<void> confirm() async {
    final current = _result;
    final weighing = current?.weighing;
    if (current == null || weighing == null) return;
    _loading = true;
    _error = null;
    _emit();
    try {
      final confirmed = await _api.confirm(current.capture.id);
      _result = CaptureResult(capture: confirmed, weighing: weighing);
    } catch (error) {
      _error = _messageOf(error);
    }
    _loading = false;
    _emit();
  }

  /// "Tomar otra": leaves the animal and starts the next capture of the session.
  void nextAnimal() {
    _stopPolling();
    _animal = null;
    _capture = null;
    _result = null;
    _preview = null;
    _error = null;
    _notice = null;
    _step = CaptureStep.identify;
    _emit();
  }

  /// "Sacar otra foto" after a failed upload.
  void retryPhoto() {
    _capture = null;
    _preview = null;
    _error = null;
    _emit();
  }

  /// Drops the registered photo in the API so no unprocessed capture is left behind.
  Future<bool> removePhoto() async {
    final captured = _capture;
    if (captured == null) return true;
    _loading = true;
    _removingPhoto = true;
    _error = null;
    _emit();
    try {
      await _api.discard(captured.id);
    } on ApiException catch (error) {
      // Already gone: the goal of the operator is met.
      if (!error.isNotFound) {
        _error = error.message;
        return false;
      }
    } catch (error) {
      _error = _messageOf(error);
      return false;
    } finally {
      _loading = false;
      _removingPhoto = false;
      _emit();
    }
    _previews.remove(captured.id);
    _capture = null;
    _preview = null;
    _galleryVersion++;
    _emit();
    return true;
  }

  Future<void> goBack() async {
    final target = back;
    if (target == null) return;
    if (target.discardPhoto && !await removePhoto()) return;
    // Stops the polling of an estimation that keeps running on the server.
    _stopPolling();
    _capture = null;
    _result = null;
    _preview = null;
    _error = null;
    _notice = target.backgroundNotice
        ? 'La estimación sigue en curso: vas a ver su resultado en las fotos de la sesión.'
        : null;
    if (target.target == CaptureStep.identify) _animal = null;
    _step = target.target;
    _emit();
  }

  /// Prepares leaving for the capture home; false when a registered photo could not be discarded.
  Future<bool> leave() async {
    if (_step == CaptureStep.photo && !await removePhoto()) return false;
    // An estimation in progress keeps running on the server and shows up in the session photos.
    _stopPolling();
    return true;
  }
}
