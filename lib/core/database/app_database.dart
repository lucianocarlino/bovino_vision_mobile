import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_tables.dart';

/// Gestor Singleton de Base de Datos SQLite para BovinoVision
class AppDatabase {
  static const String _databaseName = 'bovino_vision_local.db';
  static const int _databaseVersion = 1;

  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Permite inyectar una base de datos para pruebas unitarias o integración
  static set testDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Habilitar integridad referencial para llaves foráneas
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DatabaseTables.createTableLotes);
    await db.execute(DatabaseTables.createTableAnimals);
    await db.execute(DatabaseTables.createTableCaptures);
    await db.execute(DatabaseTables.createTableSyncQueue);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
