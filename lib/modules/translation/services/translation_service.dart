import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final http.Client _client;
  final Map<String, String> _memoryCache = {};

  TranslationService({http.Client? client}) : _client = client ?? http.Client();

  /// Translates English text to Vietnamese using Google Translate with MyMemory fallback
  Future<String?> translateEnToVi(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    if (_memoryCache.containsKey(clean)) {
      return _memoryCache[clean];
    }

    // 1. Try Google Translate API (fast, reliable, high quota)
    try {
      final googleUrl = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=${Uri.encodeComponent(clean)}',
      );
      final res = await _client.get(googleUrl).timeout(const Duration(seconds: 6));
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
    } catch (e) {
      // Fall through to fallback
    }

    // 2. Fallback to MyMemory API
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
    } catch (e) {
      // Fall through
    }

    return null;
  }
}
