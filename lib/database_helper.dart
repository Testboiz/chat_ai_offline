// import 'dart:io';
// import 'package:flutter/services.dart';
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
    _database = await _setupDatabase();
    return _database!;
  }

  Future<Database> _setupDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'chat_database.db'),
      version: 1,
      onCreate: (db, version) {
        return db.transaction((txn) async {
          txn.execute("""
CREATE TABLE IF NOT EXISTS chats (
    chat_id      TEXT    PRIMARY KEY
                         NOT NULL,
    chat_name    TEXT    NOT NULL,
    created_at   INTEGER DEFAULT (CURRENT_TIMESTAMP) 
                         NOT NULL,
    updated_at   INTEGER DEFAULT (CURRENT_TIMESTAMP) 
                         NOT NULL,
    last_chat_at INTEGER DEFAULT (CURRENT_TIMESTAMP) 
);

""");
          txn.execute("""
CREATE TABLE IF NOT EXISTS chat_messages (
    message_id   TEXT NOT NULL,
    message_text TEXT NOT NULL,
    role         TEXT DEFAULT ('user' OR
                               'assistant'),
    chat_id      TEXT REFERENCES chats (chat_id),
    created_at   TEXT NOT NULL
                      DEFAULT (CURRENT_TIMESTAMP) 
);
""");
        });
      },
    );
  }
}
