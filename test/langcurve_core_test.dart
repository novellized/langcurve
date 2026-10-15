import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/modules/dictionary/services/morphology_lemmatizer.dart';
import 'package:langcurve/modules/dictionary/services/cefr_classifier.dart';
import 'package:langcurve/modules/srs/services/srs_engine.dart';
import 'package:langcurve/modules/grammar/services/sentence_helper.dart';
import 'package:langcurve/modules/notebook/models/vocabulary.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MorphologyLemmatizer Tests', () {
    test('Lemmatizes irregular verbs correctly', () {
      expect(MorphologyLemmatizer.lemmatize('went'), equals('go'));
      expect(MorphologyLemmatizer.lemmatize('bought'), equals('buy'));
      expect(MorphologyLemmatizer.lemmatize('written'), equals('write'));
      expect(MorphologyLemmatizer.lemmatize('ran'), equals('run'));
      expect(MorphologyLemmatizer.lemmatize('was'), equals('be'));
    });

    test('Lemmatizes irregular nouns correctly', () {
      expect(MorphologyLemmatizer.lemmatize('children'), equals('child'));
      expect(MorphologyLemmatizer.lemmatize('women'), equals('woman'));
      expect(MorphologyLemmatizer.lemmatize('criteria'), equals('criterion'));
    });

    test('Lemmatizes irregular comparative adjectives', () {
      expect(MorphologyLemmatizer.lemmatize('better'), equals('good'));
      expect(MorphologyLemmatizer.lemmatize('worse'), equals('bad'));
      expect(MorphologyLemmatizer.lemmatize('least'), equals('little'));
    });

    test('Lemmatizes regular inflections', () {
      expect(MorphologyLemmatizer.lemmatize('studies'), equals('study'));
      expect(MorphologyLemmatizer.lemmatize('studied'), equals('study'));
      expect(MorphologyLemmatizer.lemmatize('running'), equals('run'));
      expect(MorphologyLemmatizer.lemmatize('coding'), equals('code'));
      expect(MorphologyLemmatizer.lemmatize('wanted'), equals('want'));
      expect(MorphologyLemmatizer.lemmatize('boxes'), equals('box'));
      expect(MorphologyLemmatizer.lemmatize('algorithms'), equals('algorithm'));
    });
  });

  group('CefrClassifier Tests', () {
    test('Classifies predefined words accurately', () {
      expect(CefrClassifier.classify('hello'), equals('A1'));
      expect(CefrClassifier.classify('travel'), equals('A2'));
      expect(CefrClassifier.classify('algorithm'), equals('B1'));
      expect(CefrClassifier.classify('optimize'), equals('B2'));
      expect(CefrClassifier.classify('meticulous'), equals('C1'));
      expect(CefrClassifier.classify('serendipity'), equals('C2'));
    });

    test('Uses length fallback for unknown words', () {
      expect(CefrClassifier.classify('xyz'), equals('A2'));
      expect(CefrClassifier.classify('simple'), equals('B1'));
    });
  });

  group('SrsEngine Tests', () {
    test('Resets interval and decreases EF when quality < 3', () {
      final res = SrsEngine.calculateSM2(
        quality: 1,
        currentEF: 2.5,
        currentRepetitions: 3,
        currentInterval: 10,
      );

      expect(res.repetitions, equals(0));
      expect(res.interval, equals(1));
      expect(res.easiness, equals(2.3));
    });

    test('Increments repetitions and applies interval scaling when quality >= 3', () {
      // First review
      final res1 = SrsEngine.calculateSM2(
        quality: 4,
        currentEF: 2.5,
        currentRepetitions: 0,
        currentInterval: 0,
      );
      expect(res1.repetitions, equals(1));
      expect(res1.interval, equals(1));

      // Second review
      final res2 = SrsEngine.calculateSM2(
        quality: 5,
        currentEF: res1.easiness,
        currentRepetitions: res1.repetitions,
        currentInterval: res1.interval,
      );
      expect(res2.repetitions, equals(2));
      expect(res2.interval, equals(6));

      // Third review
      final res3 = SrsEngine.calculateSM2(
        quality: 5,
        currentEF: res2.easiness,
        currentRepetitions: res2.repetitions,
        currentInterval: res2.interval,
      );
      expect(res3.repetitions, equals(3));
      expect(res3.interval, greaterThan(6));
    });

    test('Awards correct XP based on quality', () {
      expect(SrsEngine.calculateXpReward(5), equals(20));
      expect(SrsEngine.calculateXpReward(4), equals(10));
      expect(SrsEngine.calculateXpReward(3), equals(10));
      expect(SrsEngine.calculateXpReward(2), equals(0));
      expect(SrsEngine.calculateXpReward(0), equals(0));
    });
  });

  group('SentenceHelper Tests', () {
    test('Generates word inflections including irregular forms', () {
      final patterns = SentenceHelper.getWordPatterns('go');
      expect(patterns.contains('went'), isTrue);
      expect(patterns.contains('gone'), isTrue);
      expect(patterns.contains('going'), isTrue);
    });

    test('Validates if word appears in sentence', () {
      expect(
        SentenceHelper.checkWordInSentence('run', 'She is running very fast today.'),
        isTrue,
      );
      expect(
        SentenceHelper.checkWordInSentence('fly', 'The birds flew across the sky.'),
        isTrue,
      );
      expect(
        SentenceHelper.checkWordInSentence('car', 'He was taking care of his cat.'),
        isFalse, // Word boundary protects against matching 'care'
      );
    });

    test('Masks target word correctly', () {
      final masked = SentenceHelper.maskWordInSentence(
        'speak',
        'She spoke clearly in the meeting.',
      );
      expect(masked, equals('She _______ clearly in the meeting.'));
    });

    test('Highlights target word correctly', () {
      final highlighted = SentenceHelper.highlightWordInSentence(
        'study',
        'We studied for the exam.',
      );
      expect(highlighted, equals('We <b>studied</b> for the exam.'));
    });
  });

  group('Vocabulary Model Tests', () {
    test('Computes isDue and countdownText accurately', () {
      final dueVocab = Vocabulary(
        topicId: 1,
        word: 'test',
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(dueVocab.isDue, isTrue);
      expect(dueVocab.countdownText, equals('Due now'));

      final futureVocab = Vocabulary(
        topicId: 1,
        word: 'future',
        dueDate: DateTime.now().add(const Duration(hours: 5)),
      );
      expect(futureVocab.isDue, isFalse);
      expect(futureVocab.countdownText, contains('hour'));
    });
  });
}
