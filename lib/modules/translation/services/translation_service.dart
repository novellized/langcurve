import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final http.Client _client;
  final Map<String, String> _memoryCache = {};

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
  };

  TranslationService({http.Client? client}) : _client = client ?? http.Client();

  /// Translates English text to Vietnamese using Google Translate with fallback chain
  Future<String?> translateEnToVi(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    if (_memoryCache.containsKey(clean)) {
      return _memoryCache[clean];
    }

    // 1. Primary Google Translate API (client=gtx with User-Agent)
    try {
      final googleUrl = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=${Uri.encodeComponent(clean)}',
      );
      final res = await _client.get(googleUrl, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final translated = (data[0] as List)
              .map((chunk) => chunk is List && chunk.isNotEmpty ? chunk[0]?.toString() : '')
              .where((s) => s != null && s.isNotEmpty)
              .join('');
          if (translated.isNotEmpty && !translated.contains('MYMEMORY WARNING')) {
            _memoryCache[clean] = translated;
            return translated;
          }
        }
      }
    } on Exception catch (_) {
      // Fall through
    }

    // 2. Secondary Google Translate Endpoint (client=dict-chrome-ex)
    try {
      final googleUrl2 = Uri.parse(
        'https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=en&tl=vi&q=${Uri.encodeComponent(clean)}',
      );
      final res = await _client.get(googleUrl2, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String? translated;
        if (data is List && data.isNotEmpty) {
          if (data[0] is List && (data[0] as List).isNotEmpty) {
            translated = (data[0] as List)[0]?.toString();
          } else if (data[0] is String) {
            translated = data[0].toString();
          }
        } else if (data is String) {
          translated = data;
        }

        if (translated != null &&
            translated.isNotEmpty &&
            !translated.contains('MYMEMORY WARNING')) {
          _memoryCache[clean] = translated;
          return translated;
        }
      }
    } on Exception catch (_) {
      // Fall through
    }

    // 3. Tertiary fallback: MyMemory API
    try {
      final myMemoryUrl = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(clean)}&langpair=en|vi&de=langcurve_app@outlook.com',
      );
      final res = await _client.get(myMemoryUrl).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['responseData'] != null) {
          final translated = data['responseData']['translatedText'] as String?;
          if (translated != null &&
              translated.isNotEmpty &&
              !translated.contains('MYMEMORY WARNING')) {
            _memoryCache[clean] = translated;
            return translated;
          }
        }
      }
    } on Exception catch (_) {
      // Fall through
    }

    return null;
  }
}
