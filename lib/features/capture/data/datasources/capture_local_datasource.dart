import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../home/data/home_mock_data.dart';
import '../models/capture_record_model.dart';

/// Fuente de datos local basada en SQLite para persistencia offline-first de pesajes.
class CaptureLocalDataSource {
  final AppDatabase _appDatabase;

  // Fallback en memoria en caso de entornos de test sin binding nativo
  final List<CaptureRecordModel> _memoryStore = [];

  CaptureLocalDataSource({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase();

  /// Inserta una o varias capturas en la base de datos local y su correspondiente
  /// entrada en la cola de sincronización (sync_queue) dentro de una transacción.
  Future<void> saveCaptures(List<CaptureRecordModel> captures) async {
    if (captures.isEmpty) return;

    try {
      final db = await _appDatabase.database;

      await db.transaction((txn) async {
        for (final capture in captures) {
          // 1. Asegurar lote padre para cumplir la llave foránea
          await txn.insert(
            DatabaseTables.tableLotes,
            {
              'id': capture.loteId,
              'nombre': 'Lote Principal',
              'descripcion': 'Lote asignado automáticamente en campo',
              'activo': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          // 2. Asegurar animal padre para cumplir la llave foránea
          await txn.insert(
            DatabaseTables.tableAnimals,
            {
              'id': capture.animalId,
              'caravana_id': capture.animalId,
              'lote_id': capture.loteId,
              'categoria': 'Bovino',
              'raza': 'Angus/Criollo',
              'sexo': 'M',
              'ultimo_peso': capture.pesoEstimado,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          // 3. Insertar registro de captura
          await txn.insert(
            DatabaseTables.tableCaptures,
            capture.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 4. Insertar entrada en la cola de sincronización (sync_queue)
          await txn.insert(
            DatabaseTables.tableSyncQueue,
            {
              'id': 'sync_${capture.id}',
              'entity_type': 'capture',
              'entity_id': capture.id,
              'action': 'CREATE',
              'payload': jsonEncode(capture.toMap()),
              'retry_count': 0,
              'last_attempt': null,
              'created_at': DateTime.now().toIso8601String(),
              'status': capture.syncStatus,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      for (final capture in captures) {
        _memoryStore.removeWhere((c) => c.id == capture.id);
        _memoryStore.add(capture);
      }
    }
  }

  /// Retorna la cantidad de registros locales pendientes de sincronización
  Future<int> getPendingCount() async {
    try {
      final db = await _appDatabase.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseTables.tableCaptures} WHERE sync_status = ?',
        ['pending'],
      );
      if (result.isNotEmpty) {
        return Sqflite.firstIntValue(result) ?? 0;
      }
      return 0;
    } catch (e) {
      return _memoryStore.where((c) => c.isPending).length;
    }
  }

  /// Retorna todos los pesajes pendientes de sincronización
  Future<List<CaptureRecordModel>> getPendingCaptures() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseTables.tableCaptures,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'timestamp ASC',
      );

      return maps.map((m) => CaptureRecordModel.fromMap(m)).toList();
    } catch (e) {
      return _memoryStore.where((c) => c.isPending).toList();
    }
  }

  /// Marca una lista de identificadores de captura como sincronizados ('synced')
  /// tanto en la tabla captures como en sync_queue
  Future<void> markCapturesSynced(List<String> captureIds) async {
    if (captureIds.isEmpty) return;

    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        for (final id in captureIds) {
          await txn.update(
            DatabaseTables.tableCaptures,
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [id],
          );

          await txn.update(
            DatabaseTables.tableSyncQueue,
            {
              'status': 'synced',
              'last_attempt': DateTime.now().toIso8601String(),
            },
            where: 'entity_id = ?',
            whereArgs: [id],
          );
        }
      });
    } catch (e) {
      for (final id in captureIds) {
        final idx = _memoryStore.indexWhere((c) => c.id == id);
        if (idx != -1) {
          _memoryStore[idx] = _memoryStore[idx].copyWith(syncStatus: 'synced');
        }
      }
    }
  }

  /// Obtiene sesiones agrupadas generadas localmente (día, hora y cantidad de animales)
  Future<List<RecentSessionModel>> getLocalSessions() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> rows = await db.rawQuery('''
        SELECT 
          session_id,
          COUNT(*) as total_animals,
          MAX(timestamp) as last_timestamp,
          MIN(sync_status) as min_sync,
          MAX(sync_status) as max_sync
        FROM ${DatabaseTables.tableCaptures}
        GROUP BY session_id
        ORDER BY last_timestamp DESC
      ''');

      return rows.map((row) {
        final sessionId = row['session_id'] as String;
        final count = row['total_animals'] as int;
        final timestampStr = row['last_timestamp'] as String;
        final minSync = row['min_sync'] as String?;
        final maxSync = row['max_sync'] as String?;

        final isPending = (minSync == 'pending' || maxSync == 'pending');

        DateTime? parsedTime;
        try {
          parsedTime = DateTime.parse(timestampStr);
        } catch (_) {}

        final now = DateTime.now();
        String day = 'Hoy';
        String time = '00:00';

        if (parsedTime != null) {
          final isToday = parsedTime.year == now.year &&
              parsedTime.month == now.month &&
              parsedTime.day == now.day;
          final isYesterday = parsedTime.year == now.year &&
              parsedTime.month == now.month &&
              parsedTime.day == now.day - 1;

          if (isToday) {
            day = 'Hoy';
          } else if (isYesterday) {
            day = 'Ayer';
          } else {
            day = '${parsedTime.day.toString().padLeft(2, '0')}/${parsedTime.month.toString().padLeft(2, '0')}';
          }

          time = '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}';
        }

        return RecentSessionModel(
          id: sessionId,
          location: '',
          animalsProcessed: count,
          timestamp: '$day $time',
          date: day,
          time: time,
          isPending: isPending,
        );
      }).toList();
    } catch (e) {
      if (_memoryStore.isEmpty) return [];

      final Map<String, List<CaptureRecordModel>> grouped = {};
      for (final c in _memoryStore) {
        grouped.putIfAbsent(c.sessionId, () => []).add(c);
      }

      return grouped.entries.map((entry) {
        final hasPending = entry.value.any((c) => c.isPending);
        final last = entry.value.last;
        final timeStr = '${last.timestamp.hour.toString().padLeft(2, '0')}:${last.timestamp.minute.toString().padLeft(2, '0')}';

        return RecentSessionModel(
          id: entry.key,
          location: '',
          animalsProcessed: entry.value.length,
          timestamp: 'Hoy $timeStr',
          date: 'Hoy',
          time: timeStr,
          isPending: hasPending,
        );
      }).toList();
    }
  }
}
