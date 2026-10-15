import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Exports all topics, vocabularies, review logs, and XP to a JSON string
  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;

    final topics = await db.query('topics', orderBy: 'id ASC');
    final vocabularies = await db.query('vocabularies', orderBy: 'id ASC');
    final reviewLogs = await db.query('review_logs', orderBy: 'id ASC');
    final userRow = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);

    final Map<String, dynamic> exportMap = {
      'version': '1.0',
      'export_date': DateTime.now().toIso8601String(),
      'user': {
        'xp': userRow.isNotEmpty ? (userRow.first['xp'] ?? 0) : 0,
      },
      'topics': topics,
      'vocabularies': vocabularies,
      'review_logs': reviewLogs,
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Restores data from a backup JSON string
  Future<void> importBackupJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Định dạng file sao lưu không hợp lệ.');
    }

    final topics = decoded['topics'];
    final vocabularies = decoded['vocabularies'];
    if (topics is! List || vocabularies is! List) {
      throw Exception('File sao lưu thiếu dữ liệu topics hoặc vocabularies.');
    }

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Import or update topics (map old topic id -> new/existing topic id)
      final Map<int, int> topicIdMap = {};

      for (final t in topics) {
        if (t is Map) {
          final oldId = t['id'] as int?;
          final name = (t['name'] ?? '').toString().trim();
          final desc = t['description']?.toString();

          if (name.isNotEmpty) {
            final existing = await txn.query('topics', where: 'name = ?', whereArgs: [name]);
            final int targetTopicId;
            if (existing.isNotEmpty) {
              targetTopicId = existing.first['id'] as int;
            } else {
              targetTopicId = await txn.insert('topics', {
                'name': name,
                'description': desc,
              });
            }
            if (oldId != null) {
              topicIdMap[oldId] = targetTopicId;
            }
          }
        }
      }

      // 2. Import vocabularies
      for (final v in vocabularies) {
        if (v is Map) {
          final oldTopicId = v['topic_id'] as int?;
          final targetTopicId = topicIdMap[oldTopicId] ?? oldTopicId;
          final word = (v['word'] ?? '').toString().trim().toLowerCase();

          if (targetTopicId != null && word.isNotEmpty) {
            await txn.insert(
              'vocabularies',
              {
                'topic_id': targetTopicId,
                'word': word,
                'definition': v['definition'] ?? '',
                'part_of_speech': v['part_of_speech'] ?? '',
                'phonetic_uk': v['phonetic_uk'],
                'audio_url_uk': v['audio_url_uk'],
                'phonetic_us': v['phonetic_us'],
                'audio_url_us': v['audio_url_us'],
                'user_example': v['user_example'],
                'easiness': v['easiness'] ?? 2.5,
                'interval': v['interval'] ?? 0,
                'repetitions': v['repetitions'] ?? 0,
                'due_date': v['due_date'] ?? DateTime.now().toIso8601String(),
                'correct_count': v['correct_count'] ?? 0,
                'wrong_count': v['wrong_count'] ?? 0,
                'cefr_level': v['cefr_level'],
                'synonyms': v['synonyms'],
                'antonyms': v['antonyms'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }

      // 3. Import review logs if present
      final reviewLogs = decoded['review_logs'];
      if (reviewLogs is List) {
        for (final r in reviewLogs) {
          if (r is Map && r['word'] != null && r['quality'] != null) {
            await txn.insert(
              'review_logs',
              {
                'user_id': 1,
                'word': r['word'].toString(),
                'quality': r['quality'] as int,
                'easiness': (r['easiness'] as num?)?.toDouble() ?? 2.5,
                'interval': (r['interval'] as int?) ?? 0,
                'created_at': (r['created_at'] ?? DateTime.now().toIso8601String()).toString(),
              },
            );
          }
        }
      }

      // 4. Update XP if present
      if (decoded['user'] is Map && decoded['user']['xp'] != null) {
        final xp = decoded['user']['xp'] as int;
        await txn.update(
          'user_profile',
          {'xp': xp},
          where: 'id = ?',
          whereArgs: [1],
        );
      }
    });
  }
}
