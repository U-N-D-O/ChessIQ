import 'package:chessiq/features/analysis/models/move_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('centipawnsToWinProbability', () {
    test('is centered at zero and symmetric', () {
      final positive = centipawnsToWinProbability(100);
      final negative = centipawnsToWinProbability(-100);

      expect(centipawnsToWinProbability(0), closeTo(0.5, 1e-9));
      expect(positive, greaterThan(0.5));
      expect(positive + negative, closeTo(1.0, 1e-9));
    });

    test('respects mover perspective for black', () {
      expect(
        whiteCentipawnsToMoverWinProbability(-60, moverIsWhite: false),
        greaterThan(0.5),
      );
      expect(
        whiteCentipawnsToMoverWinProbability(60, moverIsWhite: false),
        lessThan(0.5),
      );
    });
  });

  group('deltaWpLoss', () {
    test('stabilizes tiny differences and clamps improvements', () {
      expect(
        deltaWpLoss(
          bestContinuationMoverWinProbability: 0.6004,
          playedMoveMoverWinProbability: 0.6000,
        ),
        0.0,
      );
      expect(
        deltaWpLoss(
          bestContinuationMoverWinProbability: 0.55,
          playedMoveMoverWinProbability: 0.60,
        ),
        0.0,
      );
      expect(
        deltaWpLoss(
          bestContinuationMoverWinProbability: 0.70,
          playedMoveMoverWinProbability: 0.62,
        ),
        closeTo(0.08, 1e-9),
      );
    });
  });

  group('classifyBaselineMoveQuality', () {
    test('uses the requested threshold boundaries', () {
      expect(classifyBaselineMoveQuality(0.0), MoveQuality.optimal);
      expect(classifyBaselineMoveQuality(0.019), MoveQuality.strong);
      expect(classifyBaselineMoveQuality(0.03), MoveQuality.solid);
      expect(classifyBaselineMoveQuality(0.08), MoveQuality.slip);
      expect(classifyBaselineMoveQuality(0.15), MoveQuality.error);
      expect(classifyBaselineMoveQuality(0.20), MoveQuality.criticalFailure);
    });

    test('scales thresholds for sub-1000 strength estimates only', () {
      expect(
        classifyBaselineMoveQuality(0.021, playerStrengthEstimate: 900),
        MoveQuality.strong,
      );
      expect(
        classifyBaselineMoveQuality(0.021, playerStrengthEstimate: 1200),
        MoveQuality.solid,
      );
    });
  });

  group('classifyMoveQuality', () {
    test('prioritizes masterstroke over baseline grading', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.0,
          preMoveMoverWinProbability: 0.48,
          postMoveMoverWinProbability: 0.69,
          preMoveMoverEvalPawns: 2.8,
          isSacrifice: true,
          cpGapFromBest: 0,
          playedMoveRank: 1,
        ),
      );

      expect(assessment.quality, MoveQuality.masterstroke);
    });

    test('prioritizes crucial when only saving move holds the band', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.06,
          preMoveMoverWinProbability: 0.37,
          postMoveMoverWinProbability: 0.44,
          preMoveMoverEvalPawns: -0.7,
          preservingNonLosingContinuationCount: 1,
          playedMoveRank: 1,
        ),
      );

      expect(assessment.quality, MoveQuality.crucial);
    });

    test('prioritizes oversight after an opponent mistake', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.01,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.55,
          preMoveMoverEvalPawns: 0.4,
          previousOpponentQuality: MoveQuality.error,
          availableReplySwing: 0.20,
          capturedReplySwing: 0.04,
        ),
      );

      expect(assessment.quality, MoveQuality.oversight);
    });

    test('downgrades equal opening top-line moves to book feedback', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.014,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.506,
          preMoveMoverEvalPawns: 0.1,
          cpGapFromBest: 18,
          playedMoveRank: 2,
          insideOpeningExemption: true,
        ),
      );

      expect(assessment.quality, MoveQuality.book);
      expect(
        assessment.scoringSuppressedReason,
        MoveQualityScoringSuppressionReason.openingFeedbackOnly,
      );
      expect(assessment.explanation, contains('feedback-only'));
    });

    test(
      'keeps equal-position top-line alternatives out of negative labels',
      () {
        final assessment = classifyMoveQuality(
          const MoveQualityClassificationContext(
            deltaWpLoss: 0.11,
            preMoveMoverWinProbability: 0.51,
            postMoveMoverWinProbability: 0.40,
            preMoveMoverEvalPawns: 0.2,
            cpGapFromBest: 22,
            playedMoveRank: 2,
          ),
        );

        expect(assessment.quality, MoveQuality.solid);
        expect(assessment.explanation, contains('equal position'));
      },
    );

    test('suppresses charge for obvious equal-position best moves', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.0,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.52,
          preMoveMoverEvalPawns: 0.12,
          cpGapFromBest: 4,
          playedMoveRank: 1,
        ),
      );

      expect(assessment.quality, MoveQuality.solid);
      expect(
        assessment.scoringSuppressedReason,
        MoveQualityScoringSuppressionReason.obviousMove,
      );
      expect(assessment.explanation, contains('do not build charge'));
    });

    test('suppresses special labels when confidence is low', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.0,
          preMoveMoverWinProbability: 0.48,
          postMoveMoverWinProbability: 0.69,
          preMoveMoverEvalPawns: 2.8,
          isSacrifice: true,
          cpGapFromBest: 0,
          playedMoveRank: 1,
          confidence: MoveQualityConfidence.low,
        ),
      );

      expect(assessment.quality, MoveQuality.optimal);
      expect(assessment.confidence, MoveQualityConfidence.low);
      expect(assessment.quality, isNot(MoveQuality.masterstroke));
    });

    test('downgrades low-confidence equal positions to neutral feedback', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.09,
          preMoveMoverWinProbability: 0.51,
          postMoveMoverWinProbability: 0.42,
          preMoveMoverEvalPawns: 0.15,
          confidence: MoveQualityConfidence.low,
        ),
      );

      expect(assessment.quality, MoveQuality.solid);
      expect(assessment.explanation, MoveQuality.solid.explanation);
    });
  });

  group('charge mapping', () {
    test('maps charge deltas and clamps to the valid range', () {
      expect(MoveQuality.masterstroke.chargeDelta, 50);
      expect(MoveQuality.oversight.chargeDelta, 0);
      final openingAssessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.0,
          preMoveMoverWinProbability: 0.51,
          postMoveMoverWinProbability: 0.51,
          preMoveMoverEvalPawns: 0.0,
          cpGapFromBest: 0,
          playedMoveRank: 1,
          insideOpeningExemption: true,
        ),
      );
      expect(
        updatedMoveQualityCharge(
          current: 80,
          quality: MoveQuality.masterstroke,
        ),
        100,
      );
      expect(
        updatedMoveQualityCharge(current: 10, quality: MoveQuality.error),
        0,
      );
      expect(
        updatedMoveQualityCharge(current: 55, assessment: openingAssessment),
        55,
      );
    });

    test('still awards charge for strong moves in non-equal positions', () {
      final hardStrongMove = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.01,
          preMoveMoverWinProbability: 0.63,
          postMoveMoverWinProbability: 0.62,
          preMoveMoverEvalPawns: 1.2,
          cpGapFromBest: 8,
          playedMoveRank: 1,
        ),
      );

      expect(hardStrongMove.quality, MoveQuality.strong);
      expect(
        updatedMoveQualityCharge(current: 40, assessment: hardStrongMove),
        55,
      );
    });
  });

  group('presentation mapping', () {
    test('uses distinct and less confusing symbols', () {
      expect(
        MoveQuality.optimal.displaySymbol,
        isNot(MoveQuality.strong.displaySymbol),
      );
      expect(MoveQuality.solid.displaySymbol, isNot('?!'));
      expect(MoveQuality.book.displaySymbol, 'Bk');
    });
  });
}
