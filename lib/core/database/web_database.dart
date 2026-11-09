import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Pure-Dart implementation of sqflite [Database] and [Transaction] for Flutter Web (Chrome).
/// Persists all tables (`topics`, `vocabularies`, `review_logs`, `user_profile`, `word_cache`)
/// in browser `localStorage` via [SharedPreferences].
class WebSqliteDatabase implements Database, Transaction {
  static const String _storageKey = 'langcurve_web_sqlite_v3';

  final SharedPreferences? _prefs;
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'topics': [],
    'vocabularies': [],
    'review_logs': [],
    'user_profile': [],
    'word_cache': [],
  };
  final Map<String, int> _autoIdCounters = {
    'topics': 0,
    'vocabularies': 0,
    'review_logs': 0,
    'user_profile': 0,
  };
  bool _isOpen = true;

  WebSqliteDatabase._(this._prefs);

  static Future<WebSqliteDatabase> open({
    required Future<void> Function(Database db, int version) onCreate,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }

    final db = WebSqliteDatabase._(prefs);
    final savedJson = prefs?.getString(_storageKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        final tablesMap = decoded['tables'] as Map<String, dynamic>? ?? {};
        for (final entry in tablesMap.entries) {
          final rows = (entry.value as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          db._tables[entry.key] = rows;
        }
        final countersMap = decoded['counters'] as Map<String, dynamic>? ?? {};
        for (final entry in countersMap.entries) {
          db._autoIdCounters[entry.key] = (entry.value as num).toInt();
        }
        return db;
      } catch (_) {
        // Corrupted web state; recreate cleanly below
      }
    }

    await onCreate(db, 3);
    await db._persist();
    return db;
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final payload = jsonEncode({
      'tables': _tables,
      'counters': _autoIdCounters,
    });
    await prefs.setString(_storageKey, payload);
  }

  List<Map<String, dynamic>> _table(String name) {
    return _tables.putIfAbsent(name, () => []);
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    // DDL statements (CREATE TABLE / ALTER TABLE / PRAGMA) are handled dynamically by map storage
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = _table(table);
    final row = Map<String, dynamic>.from(values);

    if (table == 'word_cache') {
      final wordKey = row['word'];
      rows.removeWhere((r) => r['word'] == wordKey);
      rows.add(row);
      await _persist();
      return 1;
    }

    if (table == 'topics') {
      final name = row['name'];
      final existingIdx = rows.indexWhere((r) => r['name'] == name);
      if (existingIdx != -1) {
        if (conflictAlgorithm == ConflictAlgorithm.replace) {
          final existingId = rows[existingIdx]['id'] as int;
          row['id'] = existingId;
          rows[existingIdx] = row;
          await _persist();
          return existingId;
        }
        throw Exception('Topic "$name" already exists.');
      }
    }

    if (table == 'vocabularies') {
      final topicId = row['topic_id'];
      final word = row['word'];
      final existingIdx = rows.indexWhere(
        (r) => r['topic_id'] == topicId && r['word'] == word,
      );
      if (existingIdx != -1 && conflictAlgorithm == ConflictAlgorithm.replace) {
        final existingId = rows[existingIdx]['id'] as int;
        row['id'] = existingId;
        rows[existingIdx] = row;
        await _persist();
        return existingId;
      }
    }

    int id;
    if (row['id'] is int) {
      id = row['id'] as int;
      final currentMax = _autoIdCounters[table] ?? 0;
      if (id > currentMax) {
        _autoIdCounters[table] = id;
      }
      rows.removeWhere((r) => r['id'] == id);
    } else {
      id = (_autoIdCounters[table] ?? 0) + 1;
      _autoIdCounters[table] = id;
      row['id'] = id;
    }

    rows.add(row);
    await _persist();
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final rows = _table(table);
    var matched = rows
        .where((r) => _matchesWhere(r, where, whereArgs))
        .map((r) => Map<String, Object?>.from(r))
        .toList();

    if (orderBy != null && orderBy.trim().isNotEmpty) {
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      final col = parts.first;
      final isDesc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';
      matched.sort((a, b) {
        final va = a[col];
        final vb = b[col];
        int cmp;
        if (va is num && vb is num) {
          cmp = va.compareTo(vb);
        } else {
          cmp = (va?.toString() ?? '').compareTo(vb?.toString() ?? '');
        }
        return isDesc ? -cmp : cmp;
      });
    }

    if (offset != null && offset > 0) {
      matched = matched.skip(offset).toList();
    }
    if (limit != null && limit >= 0) {
      matched = matched.take(limit).toList();
    }

    return matched;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final normalized = sql.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    if (normalized == 'select count(*) from topics') {
      return [
        {'COUNT(*)': _table('topics').length}
      ];
    }

    if (normalized == 'select count(distinct word) from vocabularies') {
      final distinctWords = _table('vocabularies')
          .map((r) => (r['word'] ?? '').toString().toLowerCase())
          .where((w) => w.isNotEmpty)
          .toSet();
      return [
        {'COUNT(DISTINCT word)': distinctWords.length}
      ];
    }

    if (normalized.contains('from vocabularies where user_example is not null')) {
      final count = _table('vocabularies').where((r) {
        final ex = r['user_example']?.toString().trim() ?? '';
        return ex.isNotEmpty;
      }).length;
      return [
        {'COUNT(*)': count}
      ];
    }

    if (normalized.contains('from review_logs where created_at like ?')) {
      final pattern = (arguments?.first?.toString() ?? '').replaceAll('%', '');
      final count = _table('review_logs').where((r) {
        final createdAt = r['created_at']?.toString() ?? '';
        return createdAt.startsWith(pattern);
      }).length;
      return [
        {'COUNT(*)': count}
      ];
    }

    if (normalized.contains('from vocabularies where topic_id = ?')) {
      final topicId = arguments?.first;
      final count =
          _table('vocabularies').where((r) => r['topic_id'] == topicId).length;
      return [
        {'COUNT(*)': count}
      ];
    }

    if (normalized.contains('from review_logs') &&
        normalized.contains('group by date')) {
      final userId = arguments != null && arguments.isNotEmpty
          ? arguments.first
          : 1;
      final logs = _table('review_logs')
          .where((r) => (r['user_id'] ?? 1) == userId)
          .toList();

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final log in logs) {
        final createdAt = (log['created_at'] ?? '').toString();
        if (createdAt.length >= 10) {
          final date = createdAt.substring(0, 10);
          grouped.putIfAbsent(date, () => []).add(log);
        }
      }

      final sortedDates = grouped.keys.toList()..sort();
      return sortedDates.map((date) {
        final items = grouped[date]!;
        final wordCount = items.length;
        final totalEf = items.fold<double>(
          0.0,
          (sum, r) => sum + ((r['easiness'] as num?)?.toDouble() ?? 2.5),
        );
        final avgEf =
            wordCount > 0 ? double.parse((totalEf / wordCount).toStringAsFixed(2)) : 2.5;
        final correctCount = items
            .where((r) => ((r['quality'] as num?)?.toInt() ?? 0) >= 3)
            .length;
        final wrongCount = items
            .where((r) => ((r['quality'] as num?)?.toInt() ?? 0) < 3)
            .length;
        return <String, Object?>{
          'date': date,
          'word_count': wordCount,
          'avg_easiness': avgEf,
          'correct_count': correctCount,
          'wrong_count': wrongCount,
        };
      }).toList();
    }

    return [];
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = _table(table);
    int updated = 0;
    for (final row in rows) {
      if (_matchesWhere(row, where, whereArgs)) {
        row.addAll(values);
        updated++;
      }
    }
    if (updated > 0) {
      await _persist();
    }
    return updated;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = _table(table);
    final toRemove =
        rows.where((r) => _matchesWhere(r, where, whereArgs)).toList();

    if (table == 'topics' && toRemove.isNotEmpty) {
      final removedTopicIds = toRemove.map((r) => r['id']).toSet();
      _table('vocabularies')
          .removeWhere((v) => removedTopicIds.contains(v['topic_id']));
    }

    rows.removeWhere((r) => _matchesWhere(r, where, whereArgs));
    if (toRemove.isNotEmpty) {
      await _persist();
    }
    return toRemove.length;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    final res = await action(this);
    await _persist();
    return res;
  }

  bool _matchesWhere(
    Map<String, dynamic> row,
    String? where,
    List<Object?>? whereArgs,
  ) {
    if (where == null || where.trim().isEmpty) return true;
    final args = whereArgs ?? const [];
    final clauses = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    int argIdx = 0;

    for (final clause in clauses) {
      final parts = clause.split('=');
      if (parts.length == 2) {
        final col = parts[0].trim();
        final rhs = parts[1].trim();
        final expected = rhs == '?' && argIdx < args.length
            ? args[argIdx++]
            : rhs.replaceAll("'", '');
        if (row[col] != expected) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get path => 'web_local_storage/$_storageKey';

  @override
  Database get database => this;

  @override
  Batch batch() => throw UnimplementedError();

  Future<int> getVersion() async => 3;

  Future<void> setVersion(int version) async {}

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) =>
      throw UnimplementedError();

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) =>
      throw UnimplementedError();

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) =>
      throw UnimplementedError();

  @override
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List<Object?>? arguments,
  ]) =>
      throw UnimplementedError();

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) =>
      transaction(action);
}
