import 'package:chessiq/features/quiz/models/quiz_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizAcademyProgress', () {
    test('starts with only easy unlocked', () {
      const progress = QuizAcademyProgress();

      expect(progress.perfectSessionsFor(QuizDifficulty.easy), 0);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.easy), isTrue);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.medium), isFalse);
      expect(progress.highestUnlockedDifficulty(), QuizDifficulty.easy);
    });

    test('requires perfect sessions in order to unlock next difficulty', () {
      var progress = QuizAcademyProgress.initial();

      progress = progress.recordPerfectSession(QuizDifficulty.medium);
      expect(progress.perfectSessionsFor(QuizDifficulty.medium), 0);

      progress = progress.recordPerfectSession(QuizDifficulty.easy);
      progress = progress.recordPerfectSession(QuizDifficulty.easy);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.medium), isFalse);

      progress = progress.recordPerfectSession(QuizDifficulty.easy);
      expect(progress.perfectSessionsFor(QuizDifficulty.easy), 3);
      expect(progress.isDifficultyCompleted(QuizDifficulty.easy), isTrue);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.medium), isTrue);
      expect(progress.highestUnlockedDifficulty(), QuizDifficulty.medium);
    });

    test('caps credit at the promotion requirement', () {
      var progress = QuizAcademyProgress.initial();

      for (var index = 0; index < 5; index++) {
        progress = progress.recordPerfectSession(QuizDifficulty.easy);
      }

      expect(
        progress.perfectSessionsFor(QuizDifficulty.easy),
        quizAcademyPromotionRequirement,
      );
    });

    test(
      'fromMap clamps invalid values and preserves completed track state',
      () {
        final progress = QuizAcademyProgress.fromMap({
          'easy': 99,
          'medium': -2,
          'hard': 3,
          'veryHard': 3,
        });

        expect(
          progress.perfectSessionsFor(QuizDifficulty.easy),
          quizAcademyPromotionRequirement,
        );
        expect(progress.perfectSessionsFor(QuizDifficulty.medium), 0);
        expect(progress.perfectSessionsFor(QuizDifficulty.hard), 3);
        expect(progress.perfectSessionsFor(QuizDifficulty.veryHard), 3);
        expect(progress.isTrackComplete, isTrue);
      },
    );
  });
}
