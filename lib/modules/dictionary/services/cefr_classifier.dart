class CefrClassifier {
  static final Set<String> _a1 = {
    'be', 'have', 'do', 'say', 'go', 'get', 'make', 'know', 'think', 'take', 'see', 'come', 'want', 'look',
    'use', 'find', 'give', 'tell', 'work', 'call', 'try', 'ask', 'need', 'feel', 'become', 'leave', 'put',
    'mean', 'keep', 'let', 'begin', 'seem', 'help', 'talk', 'turn', 'start', 'show', 'hear', 'play', 'run',
    'move', 'like', 'live', 'believe', 'hold', 'bring', 'write', 'provide', 'sit', 'stand', 'lose', 'pay',
    'meet', 'include', 'continue', 'set', 'learn', 'change', 'lead', 'understand', 'watch', 'follow', 'stop',
    'create', 'speak', 'read', 'allow', 'add', 'spend', 'grow', 'open', 'walk', 'win', 'offer', 'love',
    'remember', 'consider', 'appear', 'buy', 'wait', 'serve', 'die', 'send', 'expect', 'build', 'stay',
    'fall', 'cut', 'reach', 'kill', 'remain', 'hello', 'good', 'bad', 'happy', 'sad', 'english', 'book',
    'time', 'day', 'year', 'water'
  };

  static final Set<String> _a2 = {
    'study', 'travel', 'prepare', 'finish', 'decide', 'arrive', 'explain', 'suggest', 'receive', 'discuss',
    'contain', 'design', 'manage', 'improve', 'develop', 'require', 'product', 'program', 'project', 'client',
    'career', 'office', 'meeting', 'finance', 'hotel', 'flight', 'dinner', 'lunch', 'breakfast', 'ticket',
    'station', 'airport', 'holiday', 'museum', 'weather', 'winter', 'summer', 'autumn', 'spring', 'family',
    'friend', 'sister', 'brother', 'mother', 'father', 'house', 'apartment'
  };

  static final Set<String> _b1 = {
    'algorithm', 'responsive', 'synergy', 'itinerary', 'achieve', 'benefit', 'challenge', 'compare', 'confirm',
    'discover', 'encourage', 'establish', 'focus', 'identify', 'imagine', 'intend', 'measure', 'observe',
    'prevent', 'realize', 'reduce', 'reflect', 'remove', 'replace', 'satisfy', 'solve', 'structure', 'support',
    'trust', 'value', 'culture', 'economy', 'education', 'environment', 'health', 'industry', 'opinion',
    'politics', 'society', 'technology'
  };

  static final Set<String> _b2 = {
    'collaborate', 'innovate', 'optimize', 'specialize', 'implement', 'integrate', 'evaluate', 'coordinate',
    'negotiate', 'transform', 'advocate', 'facilitate', 'generate', 'simulate', 'sustain', 'validate',
    'diversity', 'framework', 'infrastructure', 'strategy', 'dynamic', 'perspective', 'significant',
    'alternative', 'efficient', 'flexible', 'sustainable'
  };

  static final Set<String> _c1 = {
    'detriment', 'ubiquitous', 'meticulous', 'anomaly', 'paradigm', 'empirical', 'cognitive', 'scrutinize',
    'ameliorate', 'equivocal', 'lucid', 'precarious', 'superfluous', 'transient', 'ephemeral', 'aesthetic',
    'pragmatic', 'resolute', 'tenacious', 'vulnerable', 'conundrum', 'discrepancy', 'implication',
    'predecessor', 'subsequent'
  };

  static final Set<String> _c2 = {
    'exacerbate', 'obsolescence', 'juxtaposition', 'cacophony', 'epiphany', 'surreptitious', 'fastidious',
    'quintessential', 'capricious', 'nefarious', 'recalcitrant', 'sycophant', 'ubiquity', 'paradoxical',
    'idiosyncrasy', 'indefatigable', 'mellifluous', 'panacea', 'serendipity', 'zenith'
  };

  /// Classify word CEFR level (A1 -> C2)
  static String classify(String word) {
    final clean = word.toLowerCase().trim();

    if (_a1.contains(clean)) return 'A1';
    if (_a2.contains(clean)) return 'A2';
    if (_b1.contains(clean)) return 'B1';
    if (_b2.contains(clean)) return 'B2';
    if (_c1.contains(clean)) return 'C1';
    if (_c2.contains(clean)) return 'C2';

    // Length-based heuristic fallback
    if (clean.length <= 4) return 'A2';
    if (clean.length <= 6) return 'B1';
    if (clean.length <= 8) return 'B2';
    if (clean.length <= 11) return 'C1';
    return 'C2';
  }
}
