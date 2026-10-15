class SM2Result {
  final double easiness;
  final int repetitions;
  final int interval;
  final DateTime dueDate;

  SM2Result({
    required this.easiness,
    required this.repetitions,
    required this.interval,
    required this.dueDate,
  });
}

class SrsEngine {
  /// Applies the SuperMemo-2 (SM-2) algorithm
  /// [quality]: review rating score 0 - 5
  /// [currentEF]: current Easiness Factor (default 2.5)
  /// [currentRepetitions]: current consecutive correct repetition count
  /// [currentInterval]: current interval in days
  static SM2Result calculateSM2({
    required int quality,
    required double currentEF,
    required int currentRepetitions,
    required int currentInterval,
    DateTime? baseDate,
  }) {
    final now = baseDate ?? DateTime.now();

    // 1. If quality is poor (< 3), reset repetitions to 0 and set next review in 1 day
    if (quality < 3) {
      final reducedEF = (currentEF - 0.2).clamp(1.3, 5.0);
      return SM2Result(
        easiness: double.parse(reducedEF.toStringAsFixed(2)),
        repetitions: 0,
        interval: 1,
        dueDate: now.add(const Duration(days: 1)),
      );
    }

    // 2. Calculate next repetitions and review interval
    final nextRepetitions = currentRepetitions + 1;
    final int nextInterval;

    if (nextRepetitions == 1) {
      nextInterval = 1; // 1 day
    } else if (nextRepetitions == 2) {
      nextInterval = 6; // 6 days
    } else {
      nextInterval = (currentInterval * currentEF).round();
    }

    // 3. Adjust Easiness Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final nextEF = currentEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    final finalEF = nextEF < 1.3 ? 1.3 : nextEF;

    return SM2Result(
      easiness: double.parse(finalEF.toStringAsFixed(2)),
      repetitions: nextRepetitions,
      interval: nextInterval,
      dueDate: now.add(Duration(days: nextInterval)),
    );
  }

  /// Calculates XP gained based on review quality
  static int calculateXpReward(int quality) {
    if (quality == 5) return 20;
    if (quality >= 3) return 10;
    return 0;
  }
}
