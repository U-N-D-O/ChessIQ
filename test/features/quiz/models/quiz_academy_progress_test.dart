import 'package:chessiq/features/quiz/models/quiz_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizAcademyProgress', () {
    test('starts with only easy unlocked', () {
      const progress = QuizAcademyProgress();

      expect(progress.perfectSessionsFor(QuizDifficulty.easy), 0);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.easy), isTrue);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.medium), isFalse);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.hard), isFalse);
      expect(progress.isDifficultyUnlocked(QuizDifficulty.veryHard), isFalse);
      expect(progress.highestUnlockedDifficulty(), QuizDifficulty.easy);
    });

    test(
      'unlocks each tier after one perfect session in the previous tier',
      () {
        var progress = QuizAcademyProgress.initial();

        progress = progress.recordPerfectSession(QuizDifficulty.medium);
        expect(progress.perfectSessionsFor(QuizDifficulty.medium), 0);

        progress = progress.recordPerfectSession(QuizDifficulty.easy);
        expect(progress.perfectSessionsFor(QuizDifficulty.easy), 1);
        expect(progress.isDifficultyCompleted(QuizDifficulty.easy), isTrue);
        expect(progress.isDifficultyUnlocked(QuizDifficulty.medium), isTrue);
        expect(progress.highestUnlockedDifficulty(), QuizDifficulty.medium);

        progress = progress.recordPerfectSession(QuizDifficulty.medium);
        expect(progress.perfectSessionsFor(QuizDifficulty.medium), 1);
        expect(progress.isDifficultyUnlocked(QuizDifficulty.hard), isTrue);

        progress = progress.recordPerfectSession(QuizDifficulty.hard);
        expect(progress.perfectSessionsFor(QuizDifficulty.hard), 1);
        expect(progress.isDifficultyUnlocked(QuizDifficulty.veryHard), isTrue);
        expect(progress.highestUnlockedDifficulty(), QuizDifficulty.veryHard);
      },
    );

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
          'hard': 7,
          'veryHard': 4,
        });

        expect(
          progress.perfectSessionsFor(QuizDifficulty.easy),
          quizAcademyPromotionRequirement,
        );
        expect(progress.perfectSessionsFor(QuizDifficulty.medium), 0);
        expect(
          progress.perfectSessionsFor(QuizDifficulty.hard),
          quizAcademyPromotionRequirement,
        );
        expect(
          progress.perfectSessionsFor(QuizDifficulty.veryHard),
          quizAcademyPromotionRequirement,
        );
        expect(progress.isTrackComplete, isTrue);
      },
    );
  });
}
