class GrammarError {
  final String message;
  final int offset;
  final int length;
  final List<String> replacements;
  final String badText;

  GrammarError({
    required this.message,
    required this.offset,
    required this.length,
    required this.replacements,
    required this.badText,
  });

  factory GrammarError.fromMap(Map<String, dynamic> map, String fullSentence) {
    final offset = (map['offset'] as int?) ?? 0;
    final length = (map['length'] as int?) ?? 0;
    final badText = (offset + length <= fullSentence.length)
        ? fullSentence.substring(offset, offset + length)
        : '';
    final replacements = (map['replacements'] as List<dynamic>? ?? [])
        .map((r) => (r is Map ? r['value'] : r).toString())
        .take(3)
        .toList();

    return GrammarError(
      message: (map['message'] as String?) ?? 'Grammar issue',
      offset: offset,
      length: length,
      replacements: replacements,
      badText: badText,
    );
  }
}
