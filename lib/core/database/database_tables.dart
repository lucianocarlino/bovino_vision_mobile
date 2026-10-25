/// Definición de Esquemas DDL para la Base de Datos SQLite Local (Offline-first)
class DatabaseTables {
  // Tabla de Lotes
  static const String tableLotes = 'lotes';
  static const String createTableLotes = '''
    CREATE TABLE $tableLotes (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'synced'
    );
  ''';

  // Tabla de Animales e Identificación
  static const String tableAnimals = 'animals';
  static const String createTableAnimals = '''
    CREATE TABLE $tableAnimals (
      id TEXT PRIMARY KEY,
      caravana_id TEXT NOT NULL UNIQUE,
      lote_id TEXT NOT NULL,
      categoria TEXT,
      raza TEXT,
      sexo TEXT,
      ultimo_peso REAL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'synced',
      FOREIGN KEY (lote_id) REFERENCES $tableLotes (id) ON DELETE CASCADE
    );
  ''';

  // Tabla de Capturas y Pesajes Biométricos
  static const String tableCaptures = 'captures';
  static const String createTableCaptures = '''
    CREATE TABLE $tableCaptures (
      id TEXT PRIMARY KEY,
      animal_id TEXT NOT NULL,
      lote_id TEXT NOT NULL,
      session_id TEXT NOT NULL,
      peso_estimado REAL NOT NULL,
      confianza REAL,
      imagen_path TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY (animal_id) REFERENCES $tableAnimals (id) ON DELETE CASCADE,
      FOREIGN KEY (lote_id) REFERENCES $tableLotes (id) ON DELETE CASCADE
    );
  ''';

  // Cola de Sincronización en Segundo Plano
  static const String tableSyncQueue = 'sync_queue';
  static const String createTableSyncQueue = '''
    CREATE TABLE $tableSyncQueue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      last_attempt TEXT,
      created_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending'
    );
  ''';
}
