import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bus.dart';
import '../models/bus_log.dart';
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final _rng = Random();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'bus_tracker_v2.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE buses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        busNumber TEXT NOT NULL,
        routeName TEXT NOT NULL,
        driverName TEXT NOT NULL DEFAULT 'Unknown',
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL,
        speed INTEGER NOT NULL DEFAULT 0,
        passengerCount INTEGER NOT NULL DEFAULT 0,
        capacity INTEGER NOT NULL DEFAULT 50,
        lastUpdated TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bus_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        busId INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed INTEGER NOT NULL,
        status TEXT NOT NULL,
        passengerCount INTEGER NOT NULL DEFAULT 0,
        recordedAt TEXT NOT NULL,
        FOREIGN KEY (busId) REFERENCES buses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_logs_bus ON bus_logs(busId, recordedAt DESC)');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now();
    final seeds = [
      {
        'busNumber': 'B-101',
        'routeName': 'Kostay Cham → Baridaka',
        'driverName': 'Mohammed Hayder',
        'latitude': 36.1901,
        'longitude': 44.0091,
        'status': 'on_route',
        'speed': 62,
        'passengerCount': 38,
        'capacity': 50,
      },
      {
        'busNumber': 'B-202',
        'routeName': 'Rozh City→ Qaiwan International University',
        'driverName': 'Aran Amanj',
        'latitude': 36.2021,
        'longitude': 44.0215,
        'status': 'delayed',
        'speed': 8,
        'passengerCount': 45,
        'capacity': 50,
      },
      {
        'busNumber': 'B-303',
        'routeName': 'Dania City → Tavga',
        'driverName': 'Hazhan Halwan',
        'latitude': 36.1850,
        'longitude': 43.9980,
        'status': 'stopped',
        'speed': 0,
        'passengerCount': 12,
        'capacity': 60,
      },
      {
        'busNumber': 'B-404',
        'routeName': 'Shar Hospital → Ali Nammali',
        'driverName': 'Bawar Hakim',
        'latitude': 36.1765,
        'longitude': 44.0310,
        'status': 'on_route',
        'speed': 45,
        'passengerCount': 29,
        'capacity': 40,
      },
      {
        'busNumber': 'B-505',
        'routeName': 'Naw Bazar Loop',
        'driverName': 'Dyar Dler',
        'latitude': 36.2100,
        'longitude': 44.0050,
        'status': 'maintenance',
        'speed': 0,
        'passengerCount': 0,
        'capacity': 50,
      },
      {
        'busNumber': 'B-505',
        'routeName': 'Raparin → Ma3mal Jgaraka ',
        'driverName': 'Rawezh Wali',
        'latitude': 36.2100,
        'longitude': 44.0050,
       'status': 'on_route',
        'speed': 45,
        'passengerCount': 21,
       'capacity': 50,
},
    ];

    for (final s in seeds) {
      final id = await db.insert('buses', {
        ...s,
        'lastUpdated': now.toIso8601String(),
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
      });

      // Seed some historical logs
      for (int i = 10; i >= 0; i--) {
        await db.insert('bus_logs', {
          'busId': id,
          'latitude': (s['latitude'] as double) + (_rng.nextDouble() * 0.01 - 0.005),
          'longitude': (s['longitude'] as double) + (_rng.nextDouble() * 0.01 - 0.005),
          'speed': s['speed'],
          'status': s['status'],
          'passengerCount': s['passengerCount'],
          'recordedAt': now.subtract(Duration(minutes: i * 3)).toIso8601String(),
        });
      }
    }
  }

  // ── Bus CRUD ──────────────────────────────────────────

  Future<int> insertBus(Bus bus) async {
    final db = await database;
    return db.insert('buses', bus.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Bus>> getAllBuses({String? statusFilter, String? search}) async {
    final db = await database;
    String where = '';
    final args = <dynamic>[];

    if (statusFilter != null && statusFilter != 'all') {
      where = 'status = ?';
      args.add(statusFilter);
    }
    if (search != null && search.isNotEmpty) {
      final clause = '(busNumber LIKE ? OR routeName LIKE ? OR driverName LIKE ?)';
      where = where.isEmpty ? clause : '$where AND $clause';
      final q = '%$search%';
      args.addAll([q, q, q]);
    }

    final maps = await db.query(
      'buses',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'busNumber ASC',
    );
    return maps.map(Bus.fromMap).toList();
  }

  Future<Bus?> getBusById(int id) async {
    final db = await database;
    final maps = await db.query('buses', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Bus.fromMap(maps.first);
  }

  Future<int> updateBus(Bus bus) async {
    final db = await database;
    return db.update('buses', bus.toMap(),
        where: 'id = ?', whereArgs: [bus.id]);
  }

  Future<int> deleteBus(int id) async {
    final db = await database;
    return db.delete('buses', where: 'id = ?', whereArgs: [id]);
  }

  // ── Fleet Stats ───────────────────────────────────────

  Future<Map<String, int>> getFleetStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count FROM buses GROUP BY status
    ''');
    final stats = <String, int>{'total': 0};
    for (final row in result) {
      stats[row['status'] as String] = row['count'] as int;
      stats['total'] = (stats['total'] ?? 0) + (row['count'] as int);
    }
    return stats;
  }

  Future<Map<String, double>> getFleetAverages() async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT 
        AVG(speed) as avgSpeed,
        AVG(CAST(passengerCount AS REAL) / capacity) as avgOccupancy
      FROM buses WHERE status != 'maintenance'
    ''');
    return {
      'avgSpeed': (r.first['avgSpeed'] as num?)?.toDouble() ?? 0,
      'avgOccupancy': (r.first['avgOccupancy'] as num?)?.toDouble() ?? 0,
    };
  }

  // ── Bus Logs ──────────────────────────────────────────

  Future<void> insertLog(BusLog log) async {
    final db = await database;
    await db.insert('bus_logs', log.toMap());
    // Keep only last 100 logs per bus
    await db.execute('''
      DELETE FROM bus_logs WHERE busId = ? AND id NOT IN (
        SELECT id FROM bus_logs WHERE busId = ? ORDER BY recordedAt DESC LIMIT 100
      )
    ''', [log.busId, log.busId]);
  }

  Future<List<BusLog>> getLogsForBus(int busId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'bus_logs',
      where: 'busId = ?',
      whereArgs: [busId],
      orderBy: 'recordedAt DESC',
      limit: limit,
    );
    return maps.map(BusLog.fromMap).toList();
  }

  // ── Simulate Real-time GPS ────────────────────────────

  Future<({Bus updated, String? statusChange})> simulateGpsUpdate(int busId) async {
    final bus = await getBusById(busId);
    if (bus == null) throw Exception('Bus not found');

    final prevStatus = bus.status;

    // Random GPS drift
    final dlat = (_rng.nextDouble() - 0.5) * 0.002;
    final dlng = (_rng.nextDouble() - 0.5) * 0.002;

    // Simulate speed and passenger changes
    int newSpeed = bus.speed;
    int newPassengers = bus.passengerCount;
    String newStatus = bus.status;

    if (bus.status != 'maintenance' && bus.status != 'stopped') {
      newSpeed = (20 + _rng.nextInt(60)).clamp(0, 90);
      newPassengers = (bus.passengerCount + _rng.nextInt(7) - 3)
          .clamp(0, bus.capacity);
      // Random status flip (5% chance)
      if (_rng.nextInt(20) == 0) {
        final statuses = ['on_route', 'delayed'];
        newStatus = statuses[_rng.nextInt(statuses.length)];
      }
    }

    final updated = bus.copyWith(
      latitude: bus.latitude + dlat,
      longitude: bus.longitude + dlng,
      speed: newSpeed,
      passengerCount: newPassengers,
      status: newStatus,
      lastUpdated: DateTime.now(),
    );

    await updateBus(updated);
    await insertLog(BusLog(
      busId: busId,
      latitude: updated.latitude,
      longitude: updated.longitude,
      speed: updated.speed,
      status: updated.status,
      passengerCount: updated.passengerCount,
      recordedAt: updated.lastUpdated,
    ));

    return (
      updated: updated,
      statusChange: newStatus != prevStatus ? newStatus : null,
    );
  }

  Future<void> simulateAllBuses() async {
    final buses = await getAllBuses();
    for (final b in buses) {
      if (b.status != 'maintenance' && b.id != null) {
        await simulateGpsUpdate(b.id!);
      }
    }
  }
}