import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/carbon_reading.dart';
import '../models/zone_monitored.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'greengrid.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE zones_monitored (
            id INTEGER PRIMARY KEY,
            zone_key TEXT NOT NULL UNIQUE,
            zone_name TEXT NOT NULL,
            user_label TEXT,
            notes TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE carbon_readings (
            id INTEGER PRIMARY KEY,
            zone_key TEXT NOT NULL,
            carbon_intensity REAL,
            renewable_percentage REAL,
            fossil_percentage REAL,
            power_breakdown_json TEXT,
            reading_datetime TEXT NOT NULL,
            fetched_at TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_readings_zone ON carbon_readings(zone_key)',
        );
        await db.execute(
          'CREATE INDEX idx_readings_dt ON carbon_readings(reading_datetime)',
        );
      },
    );
  }

  Future<void> upsertZones(List<ZoneMonitored> zones) async {
    final d = await db;
    final batch = d.batch();
    for (final z in zones) {
      batch.insert(
        'zones_monitored',
        z.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertZone(ZoneMonitored zone) async {
    final d = await db;
    await d.insert(
      'zones_monitored',
      zone.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ZoneMonitored>> getCachedZones() async {
    final d = await db;
    final rows = await d.query(
      'zones_monitored',
      orderBy: 'created_at DESC',
    );
    return rows.map(ZoneMonitored.fromSqlite).toList();
  }

  Future<void> deleteZone(int id) async {
    final d = await db;
    await d.delete('zones_monitored', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertReadings(List<CarbonReading> readings) async {
    final d = await db;
    final batch = d.batch();
    for (final r in readings) {
      batch.insert(
        'carbon_readings',
        r.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CarbonReading>> getCachedReadings({String? zoneKey, int limit = 50}) async {
    final d = await db;
    final rows = await d.query(
      'carbon_readings',
      where: zoneKey != null ? 'zone_key = ?' : null,
      whereArgs: zoneKey != null ? [zoneKey] : null,
      orderBy: 'reading_datetime DESC',
      limit: limit,
    );
    return rows.map(CarbonReading.fromSqlite).toList();
  }

  Future<void> clearReadingsForZone(String zoneKey) async {
    final d = await db;
    await d.delete('carbon_readings', where: 'zone_key = ?', whereArgs: [zoneKey]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
