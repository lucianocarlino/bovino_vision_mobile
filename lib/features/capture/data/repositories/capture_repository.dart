import '../datasources/capture_local_datasource.dart';
import '../models/capture_record_model.dart';
import '../../../home/data/home_mock_data.dart';

/// Repositorio para la gestión de pesajes y capturas biométricas (Offline-first).
class CaptureRepository {
  final CaptureLocalDataSource _localDataSource;

  CaptureRepository({CaptureLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? CaptureLocalDataSource();

  /// Registra una lista de capturas correspondientes a una sesión de campo
  Future<void> saveSessionCaptures(List<CaptureRecordModel> captures) async {
    await _localDataSource.saveCaptures(captures);
  }

  /// Retorna la cantidad de capturas pendientes de sincronización
  Future<int> getPendingCount() async {
    return await _localDataSource.getPendingCount();
  }

  /// Retorna las capturas que aún no fueron sincronizadas con el backend
  Future<List<CaptureRecordModel>> getPendingCaptures() async {
    return await _localDataSource.getPendingCaptures();
  }

  /// Marca registros como sincronizados exitosamente
  Future<void> markCapturesSynced(List<String> captureIds) async {
    await _localDataSource.markCapturesSynced(captureIds);
  }

  /// Combina las sesiones sincronizadas de base con las sesiones locales
  Future<List<RecentSessionModel>> getCombinedRecentSessions({
    List<RecentSessionModel>? baseSyncedSessions,
  }) async {
    final localSessions = await _localDataSource.getLocalSessions();
    final defaultBase = baseSyncedSessions ??
        const [
          RecentSessionModel(
            id: 's1',
            location: '',
            animalsProcessed: 12,
            timestamp: '08:45',
            date: 'Hoy',
            time: '08:45',
            isPending: false,
          ),
          RecentSessionModel(
            id: 's2',
            location: '',
            animalsProcessed: 30,
            timestamp: 'Ayer',
            date: 'Ayer',
            time: '16:20',
            isPending: false,
          ),
        ];

    // Se colocan primero las sesiones locales (pendientes o recientes) y luego las remotas sincronizadas
    return [...localSessions, ...defaultBase];
  }
}
