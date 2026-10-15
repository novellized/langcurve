class MorphologyLemmatizer {
  static const Map<String, String> _irregularMap = {
    // Irregular Verbs
    'went': 'go', 'gone': 'go',
    'bought': 'buy', 'brought': 'bring', 'took': 'take', 'taken': 'take',
    'driven': 'drive', 'drove': 'drive', 'saw': 'see', 'seen': 'see',
    'wrote': 'write', 'written': 'write', 'drank': 'drink', 'drunk': 'drink',
    'swam': 'swim', 'swum': 'swim', 'ran': 'run', 'began': 'begin', 'begun': 'begin',
    'flew': 'fly', 'flown': 'fly', 'grew': 'grow', 'grown': 'grow',
    'knew': 'know', 'known': 'know', 'threw': 'throw', 'thrown': 'throw',
    'spoke': 'speak', 'spoken': 'speak', 'broke': 'break', 'broken': 'break',
    'chose': 'choose', 'chosen': 'choose', 'stole': 'steal', 'stolen': 'steal',
    'froze': 'freeze', 'frozen': 'freeze', 'forgot': 'forget', 'forgotten': 'forget',
    'got': 'get', 'gotten': 'get', 'sat': 'sit', 'came': 'come', 'became': 'become',
    'gave': 'give', 'given': 'give', 'stood': 'stand', 'understood': 'understand',
    'built': 'build', 'thought': 'think', 'taught': 'teach', 'caught': 'catch',
    'fought': 'fight', 'found': 'find', 'spent': 'spend', 'sent': 'send',
    'left': 'leave', 'kept': 'keep', 'slept': 'sleep', 'met': 'meet', 'felt': 'feel',
    'meant': 'mean', 'lost': 'lose', 'paid': 'pay', 'said': 'say', 'led': 'lead',
    'made': 'make', 'had': 'have', 'done': 'do', 'did': 'do', 'was': 'be', 'were': 'be', 'been': 'be',

    // Irregular Nouns
    'children': 'child', 'men': 'man', 'women': 'woman', 'feet': 'foot',
    'teeth': 'tooth', 'geese': 'goose', 'mice': 'mouse', 'people': 'person',
    'matrices': 'matrix', 'vertices': 'vertex', 'indices': 'index',
    'analyses': 'analysis', 'hypotheses': 'hypothesis', 'criteria': 'criterion',
    'phenomena': 'phenomenon',

    // Irregular Adjectives & Adverbs
    'better': 'good', 'best': 'good', 'worse': 'bad', 'worst': 'bad',
    'farther': 'far', 'farthest': 'far', 'more': 'much', 'most': 'much',
    'less': 'little', 'least': 'little'
  };

  /// Morphological analyzer (Lemmatizer) to extract root word (Lemma)
  static String lemmatize(String word) {
    final clean = word.trim().toLowerCase();
    if (clean.length <= 2) return clean;

    // 1. Direct Irregular Mapping Check
    if (_irregularMap.containsKey(clean)) {
      return _irregularMap[clean]!;
    }

    // 2. Rule-based lemmatizer
    if (clean.endsWith('ies') && !clean.endsWith('aies') && !clean.endsWith('eies')) {
      return '${clean.substring(0, clean.length - 3)}y'; // studies -> study
    }
    if (clean.endsWith('ied')) {
      return '${clean.substring(0, clean.length - 3)}y'; // studied -> study
    }
    if (clean.endsWith('ing')) {
      final base = clean.substring(0, clean.length - 3);
      if (base.endsWith('cod') || base.endsWith('mak') || base.endsWith('writ') || base.endsWith('us')) {
        return '${base}e'; // coding -> code
      }
      // check double consonants: e.g. running -> run
      if (base.length > 2 && base[base.length - 1] == base[base.length - 2]) {
        return base.substring(0, base.length - 1);
      }
      return base;
    }
    if (clean.endsWith('ed')) {
      final base = clean.substring(0, clean.length - 2);
      if (base.endsWith('d') || base.endsWith('t')) {
        return base; // wanted -> want
      }
      if (clean.endsWith('ied')) {
        return '${base.substring(0, base.length - 1)}y';
      }
      // e.g. created -> create
      if (base.endsWith('creat') || base.endsWith('us') || base.endsWith('lik')) {
        return '${base}e';
      }
      return base;
    }
    if (clean.endsWith('s') && !clean.endsWith('ss') && !clean.endsWith('us') && !clean.endsWith('is')) {
      if (clean.endsWith('es')) {
        if (clean.endsWith('boxes') || clean.endsWith('classes') || clean.endsWith('matches')) {
          return clean.substring(0, clean.length - 2);
        }
        return clean.substring(0, clean.length - 1);
      }
      return clean.substring(0, clean.length - 1); // algorithms -> algorithm
    }

    return clean;
  }
}
