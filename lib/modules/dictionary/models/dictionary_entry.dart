class DefinitionItem {
  final String definition;
  final String? example;
  String? translatedDefinition;

  DefinitionItem({
    required this.definition,
    this.example,
    this.translatedDefinition,
  });

  Map<String, dynamic> toMap() {
    return {
      'definition': definition,
      'example': example,
      'translated_definition': translatedDefinition,
    };
  }

  factory DefinitionItem.fromMap(Map<String, dynamic> map) {
    return DefinitionItem(
      definition: map['definition'] as String,
      example: map['example'] as String?,
      translatedDefinition: map['translated_definition'] as String?,
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<DefinitionItem> definitions;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  Map<String, dynamic> toMap() {
    return {
      'partOfSpeech': partOfSpeech,
      'definitions': definitions.map((d) => d.toMap()).toList(),
    };
  }

  factory Meaning.fromMap(Map<String, dynamic> map) {
    final defs = (map['definitions'] as List<dynamic>? ?? [])
        .map((d) => DefinitionItem.fromMap(d as Map<String, dynamic>))
        .toList();
    return Meaning(
      partOfSpeech: (map['partOfSpeech'] as String?) ?? 'vocabulary',
      definitions: defs,
    );
  }
}

class DictionaryEntry {
  final String word;
  final String phonetic;
  final String? phoneticUk;
  final String? audioUrlUk;
  final String? phoneticUs;
  final String? audioUrlUs;
  final List<Meaning> meanings;
  final String? cefrLevel;
  final List<String> synonyms;
  final List<String> antonyms;
  String? vietnameseMeaning;

  DictionaryEntry({
    required this.word,
    this.phonetic = '',
    this.phoneticUk,
    this.audioUrlUk,
    this.phoneticUs,
    this.audioUrlUs,
    required this.meanings,
    this.cefrLevel,
    this.synonyms = const [],
    this.antonyms = const [],
    this.vietnameseMeaning,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'phonetic': phonetic,
      'phonetic_uk': phoneticUk,
      'audio_url_uk': audioUrlUk,
      'phonetic_us': phoneticUs,
      'audio_url_us': audioUrlUs,
      'meanings': meanings.map((m) => m.toMap()).toList(),
      'cefr_level': cefrLevel,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'vietnamese_meaning': vietnameseMeaning,
    };
  }
}
