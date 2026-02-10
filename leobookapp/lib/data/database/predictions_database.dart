import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PredictionsDatabase {
  static const String _dbName = 'predictions.db';
  static const String _tableName = 'predictions';

  Database? _database;
  String? _dbPath;

  /// Get the database instance, downloading if necessary
  Future<Database> getDatabase(String downloadUrl) async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    // Get the app documents directory
    final directory = await getApplicationDocumentsDirectory();
    _dbPath = join(directory.path, _dbName);

    // Check if database exists locally
    final dbFile = File(_dbPath!);
    if (!await dbFile.exists()) {
      debugPrint('Database not found locally. Downloading from GitHub...');
      await _downloadDatabase(downloadUrl, _dbPath!);
    } else {
      debugPrint('Database found locally at: $_dbPath');
    }

    // Open the database
    _database = await openDatabase(_dbPath!, readOnly: true);
    return _database!;
  }

  /// Download the database file from GitHub
  Future<void> _downloadDatabase(String url, String savePath) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint(
          'Database downloaded successfully (${response.bodyBytes.length} bytes)',
        );
      } else {
        throw Exception('Failed to download database: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading database: $e');
      rethrow;
    }
  }

  /// Query all predictions
  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    final db = _database;
    if (db == null) {
      throw Exception('Database not initialized. Call getDatabase() first.');
    }
    return await db.query(_tableName);
  }

  /// Query predictions by date
  Future<List<Map<String, dynamic>>> getPredictionsByDate(String date) async {
    final db = _database;
    if (db == null) {
      throw Exception('Database not initialized. Call getDatabase() first.');
    }
    return await db.query(_tableName, where: 'date = ?', whereArgs: [date]);
  }

  /// Query prediction by fixture ID
  Future<Map<String, dynamic>?> getPredictionByFixtureId(
    String fixtureId,
  ) async {
    final db = _database;
    if (db == null) {
      throw Exception('Database not initialized. Call getDatabase() first.');
    }
    final results = await db.query(
      _tableName,
      where: 'fixture_id = ?',
      whereArgs: [fixtureId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Query predictions by league
  Future<List<Map<String, dynamic>>> getPredictionsByLeague(
    String league,
  ) async {
    final db = _database;
    if (db == null) {
      throw Exception('Database not initialized. Call getDatabase() first.');
    }
    return await db.query(
      _tableName,
      where: 'region_league LIKE ?',
      whereArgs: ['%$league%'],
    );
  }

  /// Force refresh the database by re-downloading
  Future<void> refreshDatabase(String downloadUrl) async {
    // Close existing database
    await _database?.close();
    _database = null;

    // Delete local file
    if (_dbPath != null) {
      final file = File(_dbPath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Local database deleted');
      }
    }

    // Re-download
    await getDatabase(downloadUrl);
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Check if database file exists locally
  Future<bool> isDatabaseCached() async {
    if (_dbPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _dbPath = join(directory.path, _dbName);
    }
    return await File(_dbPath!).exists();
  }
}
