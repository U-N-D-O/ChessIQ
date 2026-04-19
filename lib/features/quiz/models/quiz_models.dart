import 'package:chessiq/features/analysis/models/analysis_models.dart';

const int quizAcademyPromotionRequirement = 3;

enum GambitQuizMode { guessName, guessLine }

enum QuizDifficulty { easy, medium, hard, veryHard }

enum QuizTrendFilter { both, guessName, guessLine }

enum QuizStatsDifficultyFilter { all, easy, medium, hard, veryHard }

enum QuizStudyCategory { basic, advanced, master, grandmaster, library }

class QuizAccuracyPoint {
  final String dayLabel;
  final double value;

  const QuizAccuracyPoint({required this.dayLabel, required this.value});
}

class QuizBoardSnapshot {
  final Map<String, String> boardState;
  final bool whiteToMove;
  final int shownPly;
  final List<EngineLine> continuation;

  QuizBoardSnapshot({
    required this.boardState,
    required this.whiteToMove,
    required this.shownPly,
    required this.continuation,
  });
}

class QuizAcademyProgress {
  final int requiredPerfectSessions;
  final Map<QuizDifficulty, int> perfectSessionsByDifficulty;

  const QuizAcademyProgress({
    this.requiredPerfectSessions = quizAcademyPromotionRequirement,
    this.perfectSessionsByDifficulty = const <QuizDifficulty, int>{},
  });

  factory QuizAcademyProgress.initial({
    int requiredPerfectSessions = quizAcademyPromotionRequirement,
  }) {
    return QuizAcademyProgress(
      requiredPerfectSessions: requiredPerfectSessions,
      perfectSessionsByDifficulty: {
        for (final difficulty in QuizDifficulty.values) difficulty: 0,
      },
    );
  }

  factory QuizAcademyProgress.fromMap(
    Map<dynamic, dynamic>? map, {
    int requiredPerfectSessions = quizAcademyPromotionRequirement,
  }) {
    final values = <QuizDifficulty, int>{};
    for (final difficulty in QuizDifficulty.values) {
      final raw = map?[difficulty.name];
      final parsed = raw is num ? raw.toInt() : 0;
      final safeValue = parsed < 0
          ? 0
          : (parsed > requiredPerfectSessions
                ? requiredPerfectSessions
                : parsed);
      values[difficulty] = safeValue;
    }
    return QuizAcademyProgress(
      requiredPerfectSessions: requiredPerfectSessions,
      perfectSessionsByDifficulty: values,
    );
  }

  Map<String, int> toMap() {
    return {
      for (final difficulty in QuizDifficulty.values)
        difficulty.name: perfectSessionsFor(difficulty),
    };
  }

  int perfectSessionsFor(QuizDifficulty difficulty) {
    return perfectSessionsByDifficulty[difficulty] ?? 0;
  }

  int remainingPerfectSessionsFor(QuizDifficulty difficulty) {
    final remaining = requiredPerfectSessions - perfectSessionsFor(difficulty);
    return remaining < 0 ? 0 : remaining;
  }

  bool isDifficultyCompleted(QuizDifficulty difficulty) {
    return perfectSessionsFor(difficulty) >= requiredPerfectSessions;
  }

  bool isDifficultyUnlocked(QuizDifficulty difficulty) {
    if (difficulty == QuizDifficulty.values.first) {
      return true;
    }
    return isDifficultyCompleted(QuizDifficulty.values[difficulty.index - 1]);
  }

  QuizDifficulty highestUnlockedDifficulty() {
    var unlocked = QuizDifficulty.values.first;
    for (final difficulty in QuizDifficulty.values) {
      if (isDifficultyUnlocked(difficulty)) {
        unlocked = difficulty;
      }
    }
    return unlocked;
  }

  QuizDifficulty? nextDifficulty(QuizDifficulty difficulty) {
    final nextIndex = difficulty.index + 1;
    if (nextIndex >= QuizDifficulty.values.length) {
      return null;
    }
    return QuizDifficulty.values[nextIndex];
  }

  bool get isTrackComplete {
    return isDifficultyCompleted(QuizDifficulty.values.last);
  }

  int get totalPerfectSessions {
    var total = 0;
    for (final difficulty in QuizDifficulty.values) {
      total += perfectSessionsFor(difficulty);
    }
    return total;
  }

  QuizAcademyProgress recordPerfectSession(QuizDifficulty difficulty) {
    if (!isDifficultyUnlocked(difficulty) ||
        isDifficultyCompleted(difficulty)) {
      return this;
    }

    final updatedValues = <QuizDifficulty, int>{
      for (final entry in perfectSessionsByDifficulty.entries)
        entry.key: entry.value,
    };
    updatedValues[difficulty] = perfectSessionsFor(difficulty) + 1;

    return QuizAcademyProgress(
      requiredPerfectSessions: requiredPerfectSessions,
      perfectSessionsByDifficulty: updatedValues,
    );
  }
}

class QuizSessionAcademyOutcome {
  final QuizDifficulty sessionDifficulty;
  final QuizDifficulty activeDifficultyAfterSession;
  final QuizDifficulty? nextDifficulty;
  final double accuracy;
  final bool perfectSession;
  final bool earnedProgressCredit;
  final bool unlockedNextDifficulty;
  final bool completedTrack;
  final int completedPerfectSessions;
  final int requiredPerfectSessions;

  const QuizSessionAcademyOutcome({
    required this.sessionDifficulty,
    required this.activeDifficultyAfterSession,
    required this.nextDifficulty,
    required this.accuracy,
    required this.perfectSession,
    required this.earnedProgressCredit,
    required this.unlockedNextDifficulty,
    required this.completedTrack,
    required this.completedPerfectSessions,
    required this.requiredPerfectSessions,
  });
}
