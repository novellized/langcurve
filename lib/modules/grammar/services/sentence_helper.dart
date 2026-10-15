class SentenceHelper {
  static const Map<String, List<String>> _irregularVerbs = {
    'be': ['am', 'is', 'are', 'was', 'were', 'been', 'being'],
    'have': ['had', 'has', 'having'],
    'do': ['did', 'done', 'does', 'doing'],
    'go': ['went', 'gone', 'goes', 'going'],
    'say': ['said', 'says', 'saying'],
    'make': ['made', 'makes', 'making'],
    'get': ['got', 'gotten', 'gets', 'getting'],
    'take': ['took', 'taken', 'takes', 'taking'],
    'come': ['came', 'come', 'comes', 'coming'],
    'see': ['saw', 'seen', 'sees', 'seeing'],
    'know': ['knew', 'known', 'knows', 'knowing'],
    'give': ['gave', 'given', 'gives', 'giving'],
    'find': ['found', 'finds', 'finding'],
    'think': ['thought', 'thinks', 'thinking'],
    'tell': ['told', 'tells', 'telling'],
    'become': ['became', 'becomes', 'becoming'],
    'show': ['showed', 'shown', 'shows', 'showing'],
    'leave': ['left', 'leaves', 'leaving'],
    'feel': ['felt', 'feels', 'feeling'],
    'put': ['put', 'puts', 'putting'],
    'bring': ['brought', 'brings', 'bringing'],
    'begin': ['began', 'begun', 'begins', 'beginning'],
    'keep': ['kept', 'keeps', 'keeping'],
    'hold': ['held', 'holds', 'holding'],
    'write': ['wrote', 'written', 'writes', 'writing'],
    'stand': ['stood', 'stands', 'standing'],
    'hear': ['heard', 'hears', 'hearing'],
    'let': ['let', 'lets', 'letting'],
    'mean': ['meant', 'means', 'meaning'],
    'set': ['set', 'sets', 'setting'],
    'meet': ['met', 'meets', 'meeting'],
    'run': ['ran', 'run', 'runs', 'running'],
    'pay': ['paid', 'pays', 'paying'],
    'sit': ['sat', 'sits', 'sitting'],
    'speak': ['spoke', 'spoken', 'speaks', 'speaking'],
    'lie': ['lay', 'lain', 'lies', 'lying'],
    'lead': ['led', 'leads', 'leading'],
    'read': ['read', 'reads', 'reading'],
    'grow': ['grew', 'grown', 'grows', 'growing'],
    'lose': ['lost', 'loses', 'losing'],
    'fall': ['fell', 'fallen', 'falls', 'falling'],
    'send': ['sent', 'sends', 'sending'],
    'build': ['built', 'builds', 'building'],
    'understand': ['understood', 'understands', 'understanding'],
    'draw': ['drew', 'drawn', 'draws', 'drawing'],
    'break': ['broke', 'broken', 'breaks', 'breaking'],
    'spend': ['spent', 'spends', 'spending'],
    'cut': ['cut', 'cuts', 'cutting'],
    'rise': ['rose', 'risen', 'rises', 'rising'],
    'drive': ['drove', 'driven', 'drives', 'driving'],
    'buy': ['bought', 'buys', 'buying'],
    'wear': ['wore', 'worn', 'wears', 'wearing'],
    'choose': ['chose', 'chosen', 'chooses', 'choosing'],
    'fly': ['flew', 'flown', 'flies', 'flying'],
    'swim': ['swam', 'swum', 'swims', 'swimming'],
    'drink': ['drank', 'drunk', 'drinks', 'drinking'],
    'eat': ['ate', 'eaten', 'eats', 'eating'],
    'sleep': ['slept', 'sleeps', 'sleeping'],
    'teach': ['taught', 'teaches', 'teaching'],
    'catch': ['caught', 'catches', 'catching'],
    'fight': ['fought', 'fights', 'fighting'],
    'freeze': ['froze', 'frozen', 'freezes', 'freezing'],
    'forget': ['forgot', 'forgotten', 'forgets', 'forgetting'],
    'steal': ['stole', 'stolen', 'steals', 'stealing'],
    'ring': ['rang', 'rung', 'rings', 'ringing'],
    'sing': ['sang', 'sung', 'sings', 'singing'],
    'win': ['won', 'wins', 'winning'],
  };

  /// Generates regular inflections and irregular forms for a word
  static List<String> getWordPatterns(String word) {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final patterns = <String>{clean};

    // Regular inflections
    if (clean.endsWith('y')) {
      final root = clean.substring(0, clean.length - 1);
      patterns.addAll([
        '${root}ies',
        '${root}ied',
        '${clean}ing',
      ]);
    } else if (clean.endsWith('e')) {
      final root = clean.substring(0, clean.length - 1);
      patterns.addAll([
        '${clean}s',
        '${root}ing',
        '${root}ed',
        '${root}d',
      ]);
    } else {
      patterns.addAll([
        '${clean}s',
        '${clean}es',
        '${clean}ed',
        '${clean}ing',
        '${clean}d',
      ]);
    }

    // Add irregular forms
    if (_irregularVerbs.containsKey(clean)) {
      patterns.addAll(_irregularVerbs[clean]!);
    }

    final sorted = patterns.toList()..sort((a, b) => b.length.compareTo(a.length));
    return sorted;
  }

  /// Checks if target word or its inflections appear in sentence
  static bool checkWordInSentence(String word, String sentence) {
    if (sentence.trim().isEmpty || word.trim().isEmpty) return false;
    final patterns = getWordPatterns(word);
    final escaped = patterns.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($escaped)\\b', caseSensitive: false);
    return regex.hasMatch(sentence);
  }

  /// Masks target word in sentence for flashcard fill-in-the-blank practice
  static String maskWordInSentence(String word, String sentence, {String mask = '_______'}) {
    if (sentence.trim().isEmpty || word.trim().isEmpty) return sentence;
    final patterns = getWordPatterns(word);
    final escaped = patterns.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($escaped)\\b', caseSensitive: false);
    return sentence.replaceAll(regex, mask);
  }

  /// Highlights target word in sentence with customizable tags
  static String highlightWordInSentence(
    String word,
    String sentence, {
    String prefix = '<b>',
    String suffix = '</b>',
  }) {
    if (sentence.trim().isEmpty || word.trim().isEmpty) return sentence;
    final patterns = getWordPatterns(word);
    final escaped = patterns.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($escaped)\\b', caseSensitive: false);
    return sentence.replaceAllMapped(regex, (match) => '$prefix${match.group(0)}$suffix');
  }
}
