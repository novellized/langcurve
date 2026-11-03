import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/core/database/database_helper.dart';
import 'package:langcurve/core/services/audio_service.dart';
import 'package:langcurve/modules/translation/services/translation_service.dart';
import 'package:langcurve/modules/dictionary/services/dictionary_service.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE word_cache (
        word TEXT PRIMARY KEY,
        source TEXT,
        raw_payload TEXT,
        updated_at TEXT
      )
    ''');
    DatabaseHelper.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TranslationService Tests', () {
    test('Translates using primary Google endpoint with User-Agent', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('translate.googleapis.com')) {
          expect(request.headers.keys.any((k) => k.toLowerCase() == 'user-agent'), isTrue);
          return http.Response.bytes(
            utf8.encode(jsonEncode([
              [
                ['học', 'study', null, null, 1]
              ]
            ])),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = TranslationService(client: mockClient);
      final result = await service.translateEnToVi('study');
      expect(result, equals('học'));
    });

    test('Falls back to secondary Google endpoint when primary fails', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('translate.googleapis.com')) {
          return http.Response('Forbidden', 403);
        }
        if (request.url.toString().contains('clients5.google.com')) {
          return http.Response.bytes(
            utf8.encode(jsonEncode(['thuật toán'])),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = TranslationService(client: mockClient);
      final result = await service.translateEnToVi('algorithm');
      expect(result, equals('thuật toán'));
    });
  });

  group('AudioService & DictionaryService Audio Tests', () {
    test('Normalizes protocol-relative URLs correctly', () {
      final fallbackUk = AudioService.getFallbackTtsUrl('study', isUk: true);
      final fallbackUs = AudioService.getFallbackTtsUrl('study', isUk: false);

      expect(fallbackUk, contains('_gb_1.mp3'));
      expect(fallbackUk, contains('study'));
      expect(fallbackUs, contains('_us_1.mp3'));
      expect(fallbackUs, contains('study'));
    });

    test('DictionaryService normalizes relative audio URLs from API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('api.dictionaryapi.dev')) {
          return http.Response(
            jsonEncode([
              {
                'word': 'test',
                'phonetics': [
                  {
                    'text': '/test/',
                    'audio': '//ssl.gstatic.com/dictionary/static/sounds/20200429/test--_gb_1.mp3'
                  }
                ],
                'meanings': []
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final helper = DatabaseHelper.withDatabase(db);
      final dictService = DictionaryService(client: mockClient, dbHelper: helper);
      final entry = await dictService.lookupWord('test', autoTranslate: false);

      expect(entry.audioUrlUk, startsWith('https://ssl.gstatic.com/'));
    });
  });
}
