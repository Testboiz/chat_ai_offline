import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDb();
    return _database!;
  }

  // TODO : modify after testing 
  Future<Database> _openDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "chat_database.db");

    await deleteDatabase(path); // remove after testing

    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    final data =
        await rootBundle.load(join("assets", "db", "chat_database.db"));
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);

    return openDatabase(path);
  }
}
