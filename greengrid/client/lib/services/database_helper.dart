import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/carbon_reading.dart';
import '../models/zone_monitored.dart';


class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName    = 'greengrid_cache.db';
  static const _dbVersion = 1;

  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE zones_cache (
            id          INTEGER PRIMARY KEY,
            zone_key    TEXT NOT NULL UNIQUE,
            zone_name   TEXT NOT NULL,
            user_label  TEXT,
            notes       TEXT,
            created_at  TEXT,
            updated_at  TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE readings_cache (
            id                   INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id            INTEGER,
            zone_key             TEXT NOT NULL,
            carbon_intensity     REAL,
            renewable_percentage REAL,
            fossil_percentage    REAL,
            power_breakdown_json TEXT,
            reading_datetime     TEXT NOT NULL,
            fetched_at           TEXT,
            UNIQUE(zone_key, reading_datetime)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_readings_zone ON readings_cache(zone_key)',
        );
        await db.execute(
          'CREATE INDEX idx_readings_dt ON readings_cache(reading_datetime)',
        );
      },
    );
  }

  
  Future<void> cacheZones(List<ZoneMonitored> zones) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('zones_cache');
      for (final z in zones) {
        await txn.insert(
          'zones_cache',
          z.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Upsert di una singola zona (usato dopo create/update/patch).
  Future<void> cacheZone(ZoneMonitored zone) async {
    final db = await _database;
    await db.insert(
      'zones_cache',
      zone.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ZoneMonitored>> getCachedZones() async {
    final db = await _database;
    final rows = await db.query(
      'zones_cache',
      orderBy: 'created_at DESC',
    );
    return rows.map(ZoneMonitored.fromSqlite).toList();
  }

  Future<void> removeCachedZone(int id) async {
    final db = await _database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'zones_cache',
        columns: ['zone_key'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final zk = rows.first['zone_key'] as String;
        await txn.delete('readings_cache', where: 'zone_key = ?', whereArgs: [zk]);
      }
      await txn.delete('zones_cache', where: 'id = ?', whereArgs: [id]);
    });
  }

  
  Future<void> cacheReadings(String zoneKey, List<CarbonReading> readings) async {
    if (readings.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final r in readings) {
      final row = r.toSqlite();
    
      row.remove('id');
      row['server_id']  = r.id;
      row['zone_key']   = zoneKey; 
      batch.insert(
        'readings_cache',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CarbonReading>> getCachedReadings(String zoneKey, {int limit = 50}) async {
    final db = await _database;
    final rows = await db.query(
      'readings_cache',
      where: 'zone_key = ?',
      whereArgs: [zoneKey],
      orderBy: 'reading_datetime DESC',
      limit: limit,
    );
    return rows.map(CarbonReading.fromSqlite).toList();
  }

  
  Future<void> clearOldReadings(int daysToKeep) async {
    final db = await _database;
    final threshold = DateTime.now()
        .toUtc()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();
    await db.delete(
      'readings_cache',
      where: 'reading_datetime < ?',
      whereArgs: [threshold],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
