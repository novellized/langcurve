import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/database/database_helper.dart';
import '../../translation/services/translation_service.dart';
import '../models/dictionary_entry.dart';
import 'cefr_classifier.dart';
import 'morphology_lemmatizer.dart';

class DictionaryService {
  final http.Client _client;
  final DatabaseHelper _dbHelper;
  final TranslationService _translationService;

  DictionaryService({
    http.Client? client,
    DatabaseHelper? dbHelper,
    TranslationService? translationService,
  })  : _client = client ?? http.Client(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _translationService = translationService ?? TranslationService();

  /// Looks up a word with morphological analysis, caching, audio extraction, and Vietnamese translation
  Future<DictionaryEntry> lookupWord(String rawWord, {bool autoTranslate = true}) async {
    final clean = rawWord.trim().toLowerCase();
    if (clean.isEmpty) {
      throw Exception('Vui lòng nhập từ cần tra cứu.');
    }

    // 1. Lemmatize word to base root (lemma)
    final lemma = MorphologyLemmatizer.lemmatize(clean);

    // 2. Check local SQLite cache first (Offline support & save quota)
    final cached = await _getCachedWord(lemma);
    if (cached != null) {
      if (autoTranslate && (cached.vietnameseMeaning == null || cached.vietnameseMeaning!.isEmpty)) {
        cached.vietnameseMeaning = await _translationService.translateEnToVi(lemma);
      }
      return cached;
    }

    // 3. Fetch from External API (Free Dictionary API)
    DictionaryEntry? entry;
    try {
      final url = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(lemma)}');
      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          entry = _parseFreeDictionaryEntry(data[0] as Map<String, dynamic>, lemma);
          // Save to local SQLite cache
          await _saveWordToCache(lemma, 'free-dictionary-api', jsonEncode(data[0]));
        }
      }
    } catch (_) {
      // API error or offline - continue to TTS fallback
    }

    // 4. Fallback to Google TTS if word not found in external dictionary
    entry ??= _createGoogleTtsFallback(lemma);

    // 5. Enrich with Vietnamese translations
    if (autoTranslate) {
      entry.vietnameseMeaning = await _translationService.translateEnToVi(lemma);
      // Translate first definition of each meaning
      for (final m in entry.meanings) {
        for (final d in m.definitions.take(2)) {
          d.translatedDefinition = await _translationService.translateEnToVi(d.definition);
        }
      }
    }

    return entry;
  }

  /// Parses Free Dictionary API response into DictionaryEntry with dual UK/US audio
  DictionaryEntry _parseFreeDictionaryEntry(Map<String, dynamic> raw, String lemma) {
    String phoneticUk = '';
    String audioUrlUk = '';
    String phoneticUs = '';
    String audioUrlUs = '';

    final phonetics = (raw['phonetics'] as List<dynamic>? ?? []);

    for (final p in phonetics) {
      if (p is Map) {
        final audio = (p['audio'] ?? '').toString().toLowerCase();
        final text = (p['text'] ?? '').toString().toLowerCase();

        final isUk = audio.contains('-uk') || audio.contains('/uk/') || text.contains('uk');
        final isUs = audio.contains('-us') || audio.contains('/us/') || text.contains('us');

        if (isUk && audioUrlUk.isEmpty) {
          audioUrlUk = p['audio']?.toString() ?? '';
          phoneticUk = p['text']?.toString() ?? '';
        }
        if (isUs && audioUrlUs.isEmpty) {
          audioUrlUs = p['audio']?.toString() ?? '';
          phoneticUs = p['text']?.toString() ?? '';
        }
      }
    }

    // Secondary fill if missing audio
    if (audioUrlUk.isEmpty || audioUrlUs.isEmpty) {
      for (final p in phonetics) {
        if (p is Map && (p['audio'] ?? '').toString().isNotEmpty) {
          final audio = p['audio'].toString();
          final text = p['text']?.toString() ?? '';
          if (audioUrlUk.isEmpty) {
            audioUrlUk = audio;
            if (phoneticUk.isEmpty) phoneticUk = text;
          } else if (audioUrlUs.isEmpty) {
            audioUrlUs = audio;
            if (phoneticUs.isEmpty) phoneticUs = text;
          }
        }
      }
    }

    // Google TTS Fallback for missing UK or US audio
    if (audioUrlUk.isEmpty) {
      audioUrlUk = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-GB&client=tw-ob&q=${Uri.encodeComponent(lemma)}&dialect=-uk';
    }
    if (audioUrlUs.isEmpty) {
      audioUrlUs = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(lemma)}&dialect=-us';
    }

    if (phoneticUk.isEmpty) phoneticUk = (raw['phonetic'] ?? '').toString();
    if (phoneticUs.isEmpty) phoneticUs = phoneticUk;

    // Parse meanings
    final List<Meaning> meaningsList = [];
    final Set<String> synonymsSet = {};
    final Set<String> antonymsSet = {};

    final rawMeanings = (raw['meanings'] as List<dynamic>? ?? []);
    for (final m in rawMeanings) {
      if (m is Map) {
        final pos = (m['partOfSpeech'] ?? 'vocabulary').toString();
        final rawDefs = (m['definitions'] as List<dynamic>? ?? []);
        final defItems = <DefinitionItem>[];

        for (final d in rawDefs) {
          if (d is Map) {
            defItems.add(DefinitionItem(
              definition: (d['definition'] ?? '').toString(),
              example: d['example']?.toString(),
            ));
            if (d['synonyms'] is List) {
              synonymsSet.addAll((d['synonyms'] as List).map((s) => s.toString()));
            }
            if (d['antonyms'] is List) {
              antonymsSet.addAll((d['antonyms'] as List).map((a) => a.toString()));
            }
          }
        }

        if (m['synonyms'] is List) {
          synonymsSet.addAll((m['synonyms'] as List).map((s) => s.toString()));
        }
        if (m['antonyms'] is List) {
          antonymsSet.addAll((m['antonyms'] as List).map((a) => a.toString()));
        }

        meaningsList.add(Meaning(partOfSpeech: pos, definitions: defItems));
      }
    }

    return DictionaryEntry(
      word: lemma,
      phonetic: phoneticUk.isNotEmpty ? phoneticUk : (raw['phonetic'] ?? '').toString(),
      phoneticUk: phoneticUk,
      audioUrlUk: audioUrlUk,
      phoneticUs: phoneticUs,
      audioUrlUs: audioUrlUs,
      meanings: meaningsList,
      cefrLevel: CefrClassifier.classify(lemma),
      synonyms: synonymsSet.take(8).toList(),
      antonyms: antonymsSet.take(8).toList(),
    );
  }

  /// Create Google TTS fallback entry when external dictionary API fails
  DictionaryEntry _createGoogleTtsFallback(String lemma) {
    final audioUk = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-GB&client=tw-ob&q=${Uri.encodeComponent(lemma)}&dialect=-uk';
    final audioUs = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(lemma)}&dialect=-us';

    return DictionaryEntry(
      word: lemma,
      phonetic: '/$lemma/',
      phoneticUk: '/uk/',
      audioUrlUk: audioUk,
      phoneticUs: '/us/',
      audioUrlUs: audioUs,
      meanings: [
        Meaning(
          partOfSpeech: 'vocabulary',
          definitions: [
            DefinitionItem(
              definition: 'Định nghĩa đang được cập nhật (Google TTS Fallback).',
              example: '',
            ),
          ],
        )
      ],
      cefrLevel: CefrClassifier.classify(lemma),
    );
  }

  Future<DictionaryEntry?> _getCachedWord(String word) async {
    final db = await _dbHelper.database;
    final rows = await db.query('word_cache', where: 'word = ?', whereArgs: [word]);
    if (rows.isNotEmpty) {
      try {
        final raw = jsonDecode(rows.first['raw_payload'] as String);
        return _parseFreeDictionaryEntry(raw, word);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _saveWordToCache(String word, String source, String rawPayload) async {
    final db = await _dbHelper.database;
    await db.insert(
      'word_cache',
      {
        'word': word,
        'source': source,
        'raw_payload': rawPayload,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
