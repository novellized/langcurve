import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grammar_error.dart';

class GrammarCheckerService {
  final http.Client _client;

  GrammarCheckerService({http.Client? client}) : _client = client ?? http.Client();

  /// Check sentence grammar using LanguageTool API
  Future<List<GrammarError>> checkGrammar(String sentence) async {
    final clean = sentence.trim();
    if (clean.isEmpty) return [];

    try {
      final url = Uri.parse('https://api.languagetool.org/v2/check');
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'text=${Uri.encodeQueryComponent(clean)}&language=en-US',
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['matches'] is List) {
          final matches = data['matches'] as List;
          return matches
              .map((m) => GrammarError.fromMap(m as Map<String, dynamic>, clean))
              .toList();
        }
      }
    } catch (e) {
      // Return empty list on network error / timeout to avoid blocking user flow
    }

    return [];
  }
}
