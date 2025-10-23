import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/complaint_model.dart';

class ComplaintLocalDataSource {
  static Database? _database;
  static const String tableName = 'complaints';

  Future<Database> get database async {
    try {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      print('Error accessing database: $e');
      throw Exception('Failed to access local database: ${e.toString()}');
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'complaints.db');

      return await openDatabase(
        path,
        version: 3, // Incremented version for landmark column
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
              area TEXT,
              landmark TEXT,
              status TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT,
              assignedTo TEXT,
              assignedBy TEXT,
              assignedAt TEXT,
              completedAt TEXT,
              adminNotes TEXT,
              contractorNotes TEXT,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Migration from version 1 to version 2
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN area TEXT');
            await db
                .execute('ALTER TABLE $tableName ADD COLUMN assignedBy TEXT');
            await db
                .execute('ALTER TABLE $tableName ADD COLUMN assignedAt TEXT');
            await db
                .execute('ALTER TABLE $tableName ADD COLUMN completedAt TEXT');
            await db.execute(
                'ALTER TABLE $tableName ADD COLUMN contractorNotes TEXT');
          }
          // Migration from version 2 to version 3
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN landmark TEXT');
          }
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      throw Exception('Failed to initialize local database: ${e.toString()}');
    }
  }

  Future<String> insertComplaint(ComplaintModel complaint) async {
    try {
      final db = await database;
      await db.insert(tableName, complaint.toMap());
      return complaint.id;
    } catch (e) {
      print('Error inserting complaint ${complaint.id}: $e');
      throw Exception('Failed to insert complaint locally: ${e.toString()}');
    }
  }

  Future<List<ComplaintModel>> getUnsyncedComplaints() async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        where: 'synced = ?',
        whereArgs: [0],
      );
      return maps.map((map) => ComplaintModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting unsynced complaints: $e');
      throw Exception(
          'Failed to retrieve unsynced complaints: ${e.toString()}');
    }
  }

  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => ComplaintModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user complaints for userId $userId: $e');
      throw Exception(
          'Failed to retrieve user complaints from local storage: ${e.toString()}');
    }
  }

  Future<void> markAsSynced(String complaintId) async {
    try {
      final db = await database;
      await db.update(
        tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [complaintId],
      );
    } catch (e) {
      print(
          'Error marking complaint as synced (complaintId: $complaintId): $e');
      throw Exception('Failed to mark complaint as synced: ${e.toString()}');
    }
  }

  Future<int> getUnsyncedCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE synced = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting unsynced count: $e');
      throw Exception(
          'Failed to get unsynced complaint count: ${e.toString()}');
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      final db = await database;
      await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [complaintId],
      );
    } catch (e) {
      print('Error deleting complaint (complaintId: $complaintId): $e');
      throw Exception(
          'Failed to delete complaint from local storage: ${e.toString()}');
    }
  }

  /// Reset database - useful for development/testing
  /// WARNING: This will delete all local data
  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'complaints.db');

      // Close existing connection
      await _database?.close();
      _database = null;

      // Delete the database file
      await deleteDatabase(path);

      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
      throw Exception('Failed to reset database: ${e.toString()}');
    }
  }
}
