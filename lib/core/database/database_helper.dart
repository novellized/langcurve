import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  DatabaseHelper.withDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('langcurve.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Enable FFI on desktop platforms (Windows, Linux, macOS) or in test environments
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationSupportDirectory();
      dbPath = join(docDir.path, filePath);
    } else {
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = join(defaultDatabasesPath, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Topics table
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT
      )
    ''');

    // 2. Vocabularies & SRS progress table
    await db.execute('''
      CREATE TABLE vocabularies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        definition TEXT DEFAULT '',
        part_of_speech TEXT DEFAULT '',
        phonetic_uk TEXT,
        audio_url_uk TEXT,
        phonetic_us TEXT,
        audio_url_us TEXT,
        user_example TEXT,
        easiness REAL DEFAULT 2.5,
        interval INTEGER DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        due_date TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        wrong_count INTEGER DEFAULT 0,
        cefr_level TEXT,
        synonyms TEXT,
        antonyms TEXT,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE,
        UNIQUE(topic_id, word)
      )
    ''');

    // 3. Historical review logs (Curve Analytics)
    await db.execute('''
      CREATE TABLE review_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER DEFAULT 1,
        word TEXT NOT NULL,
        quality INTEGER NOT NULL,
        easiness REAL NOT NULL,
        interval INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. User profile & XP table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        xp INTEGER DEFAULT 0,
        email TEXT
      )
    ''');

    // 5. Offline dictionary cache table
    await db.execute('''
      CREATE TABLE word_cache (
        word TEXT PRIMARY KEY,
        source TEXT,
        raw_payload TEXT,
        updated_at TEXT
      )
    ''');

    // Seed default topics
    await db.insert('topics', {
      'name': 'Technology',
      'description': 'Vocabulary related to computers, coding, software, and the digital world.'
    });
    await db.insert('topics', {
      'name': 'Business & Career',
      'description': 'Vocabulary for professional environments, meetings, finance, and office life.'
    });
    await db.insert('topics', {
      'name': 'Travel & Leisure',
      'description': 'Words and phrases for commuting, exploring new places, hotel stays, and dining.'
    });

    // Seed default user
    await db.insert('user_profile', {
      'id': 1,
      'xp': 0,
      'email': 'guest@langcurve.local'
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
