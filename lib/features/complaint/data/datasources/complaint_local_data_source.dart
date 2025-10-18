import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/complaint_model.dart';

class ComplaintLocalDataSource {
  static Database? _database;
  static const String tableName = 'complaints';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'complaints.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            userName TEXT NOT NULL,
            type TEXT NOT NULL,
            description TEXT NOT NULL,
            mediaUrls TEXT,
            locationLat REAL,
            locationLng REAL,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            assignedTo TEXT,
            adminNotes TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<String> insertComplaint(ComplaintModel complaint) async {
    final db = await database;
    await db.insert(tableName, complaint.toMap());
    return complaint.id;
  }

  Future<List<ComplaintModel>> getUnsyncedComplaints() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((map) => ComplaintModel.fromMap(map)).toList();
  }

  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ComplaintModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String complaintId) async {
    final db = await database;
    await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [complaintId],
    );
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteComplaint(String complaintId) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [complaintId],
    );
  }
}
