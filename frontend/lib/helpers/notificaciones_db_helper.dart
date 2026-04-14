import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notificacion.dart';

class NotificacionesDbHelper {
  static final NotificacionesDbHelper _instance = NotificacionesDbHelper._();
  static Database? _database;

  NotificacionesDbHelper._();

  factory NotificacionesDbHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yoverifico.db');

    return await openDatabase(
      path,
      version: 2, // 🔼 Migración a v2
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notificaciones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT,
            cuerpo TEXT,
            vehiculo_id TEXT,
            tipo_notificacion TEXT,
            fecha TEXT,
            leida INTEGER DEFAULT 0,
            -- Campos nuevos (opcionales) para remotas / metadatos
            dedup_key TEXT,
            message_id TEXT,
            source TEXT,
            severity TEXT,
            data_json TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Agrega columnas opcionales sin romper registros previos
          await db
              .execute('ALTER TABLE notificaciones ADD COLUMN dedup_key TEXT');
          await db
              .execute('ALTER TABLE notificaciones ADD COLUMN message_id TEXT');
          await db.execute('ALTER TABLE notificaciones ADD COLUMN source TEXT');
          await db
              .execute('ALTER TABLE notificaciones ADD COLUMN severity TEXT');
          await db
              .execute('ALTER TABLE notificaciones ADD COLUMN data_json TEXT');
        }
      },
    );
  }

  Future<int> insertar(Notificacion notificacion) async {
    final db = await database;
    return await db.insert(
      'notificaciones',
      notificacion.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Para locales (vehículo) se mantiene igual.
  /// Si algún día llamas con 'GLOBAL', deduplica contra registros con vehiculo_id NULL.
  Future<bool> existeNotificacionHoy(String vehiculoId, String tipo) async {
    final db = await database;
    final now = DateTime.now();
    final inicioDeHoy =
        DateTime(now.year, now.month, now.day).toIso8601String();
    final finDeHoy =
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    List<Map<String, dynamic>> maps;

    if (vehiculoId == 'GLOBAL') {
      // Caso global: vehiculo_id IS NULL
      maps = await db.query(
        'notificaciones',
        where:
            'vehiculo_id IS NULL AND tipo_notificacion = ? AND fecha BETWEEN ? AND ?',
        whereArgs: [tipo, inicioDeHoy, finDeHoy],
        limit: 1,
      );
    } else {
      // Caso normal por vehículo
      maps = await db.query(
        'notificaciones',
        where:
            'vehiculo_id = ? AND tipo_notificacion = ? AND fecha BETWEEN ? AND ?',
        whereArgs: [vehiculoId, tipo, inicioDeHoy, finDeHoy],
        limit: 1,
      );
    }

    return maps.isNotEmpty;
  }

  Future<int> eliminar(int id) async {
    final db = await database;
    return await db.delete(
      'notificaciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Notificacion>> getNotificaciones() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notificaciones',
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Notificacion.fromJson(maps[i]));
  }

  Future<List<Notificacion>> getNotificacionesPorVehiculoId(
      String vehiculoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notificaciones',
      where: 'vehiculo_id = ?',
      whereArgs: [vehiculoId],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Notificacion.fromJson(maps[i]));
  }

  Future<void> eliminarNotificacionesPorVehiculo(String vehiculoId) async {
    final db = await database;
    await db.delete(
      'notificaciones',
      where: 'vehiculo_id = ?',
      whereArgs: [vehiculoId],
    );
  }

  Future<int> marcarComoLeida(int id) async {
    final db = await database;
    return await db.update(
      'notificaciones',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarTodasComoLeidas() async {
    final db = await database;
    await db.update('notificaciones', {'leida': 1});
  }

  Future<int> getNotificacionesNoLeidasCount() async {
    final db = await database;
    final count = await db
        .rawQuery('SELECT COUNT(*) FROM notificaciones WHERE leida = 0');
    return Sqflite.firstIntValue(count) ?? 0;
  }

  /// Borra TODAS las notificaciones de la tabla.
  Future<void> eliminarTodas() async {
    final db = await database;
    await db.delete('notificaciones');
  }

  /// (Opcional) Cierra la conexión a la BD.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// (Opcional) Borra por completo el archivo de BD y la recrea al próximo acceso.
  Future<void> dropDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yoverifico.db');

    await close();
    await deleteDatabase(path);
  }
}
