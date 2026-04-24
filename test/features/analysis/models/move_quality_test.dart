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
          currentOpening: 'Italian Game',
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
      expect(assessment.explanation, 'Opening: Italian Game');
      expect(assessment.explanation, isNot(contains('first 6 plies')));
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

        expect(assessment.quality, MoveQuality.strong);
        expect(assessment.explanation, MoveQuality.strong.explanation);
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

      expect(assessment.quality, MoveQuality.optimal);
      expect(
        assessment.scoringSuppressedReason,
        MoveQualityScoringSuppressionReason.obviousMove,
      );
      expect(assessment.explanation, contains('do not build charge'));
    });

    test('keeps the engine best move optimal despite post-move drift', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.31,
          preMoveMoverWinProbability: 0.78,
          postMoveMoverWinProbability: 0.47,
          preMoveMoverEvalPawns: 1.9,
          playedMoveRank: 1,
          cpGapFromBest: 0,
        ),
      );

      expect(assessment.quality, MoveQuality.optimal);
      expect(assessment.explanation, MoveQuality.optimal.explanation);
    });

    test('maps the engine second line to strong directly', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.18,
          preMoveMoverWinProbability: 0.71,
          postMoveMoverWinProbability: 0.53,
          preMoveMoverEvalPawns: 1.6,
          playedMoveRank: 2,
          cpGapFromBest: 14,
        ),
      );
      expect(assessment.quality, MoveQuality.strong);
      expect(assessment.explanation, MoveQuality.strong.explanation);
    });

    test('keeps close third-line alternatives as solid', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.08,
          preMoveMoverWinProbability: 0.54,
          postMoveMoverWinProbability: 0.46,
          preMoveMoverEvalPawns: 0.3,
          playedMoveRank: 3,
          cpGapFromBest: 32,
        ),
      );

      expect(assessment.quality, MoveQuality.solid);
    });

    test('does not keep catastrophic third-line losses as solid', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.34,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.18,
          preMoveMoverEvalPawns: 0.2,
          playedMoveRank: 3,
          cpGapFromBest: 30,
        ),
      );

      expect(assessment.quality, MoveQuality.criticalFailure);
    });

    test('downgrades the worst fully covered third move to slip', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.03,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.49,
          preMoveMoverEvalPawns: 0.1,
          playedMoveRank: 3,
          cpGapFromBest: 28,
          cpGapFromNextBetter: 18,
          totalLegalMoveCount: 3,
          analyzedLegalMoveCount: 3,
        ),
      );

      expect(assessment.quality, MoveQuality.slip);
      expect(assessment.explanation, contains('weakest move'));
    });

    test('keeps a tied fully covered third move as solid', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.03,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.49,
          preMoveMoverEvalPawns: 0.1,
          playedMoveRank: 3,
          cpGapFromBest: 18,
          cpGapFromNextBetter: 8,
          totalLegalMoveCount: 3,
          analyzedLegalMoveCount: 3,
        ),
      );

      expect(assessment.quality, MoveQuality.solid);
    });

    test('does not keep the worse of two legal moves as strong', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.015,
          preMoveMoverWinProbability: 0.51,
          postMoveMoverWinProbability: 0.495,
          preMoveMoverEvalPawns: 0.0,
          playedMoveRank: 2,
          cpGapFromBest: 30,
          cpGapFromNextBetter: 30,
          totalLegalMoveCount: 2,
          analyzedLegalMoveCount: 2,
        ),
      );

      expect(assessment.quality, MoveQuality.slip);
    });

    test('keeps a near-equal second move strong when fully covered', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.015,
          preMoveMoverWinProbability: 0.51,
          postMoveMoverWinProbability: 0.495,
          preMoveMoverEvalPawns: 0.0,
          playedMoveRank: 2,
          cpGapFromBest: 12,
          cpGapFromNextBetter: 12,
          totalLegalMoveCount: 2,
          analyzedLegalMoveCount: 2,
        ),
      );

      expect(assessment.quality, MoveQuality.strong);
    });

    test('does not promote catastrophic cp-gap alternatives to strong', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.36,
          preMoveMoverWinProbability: 0.53,
          postMoveMoverWinProbability: 0.17,
          preMoveMoverEvalPawns: 0.25,
          cpGapFromBest: 22,
        ),
      );

      expect(assessment.quality, MoveQuality.criticalFailure);
    });

    test('does not keep fourth-line alternatives in solid by default', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.08,
          preMoveMoverWinProbability: 0.54,
          postMoveMoverWinProbability: 0.46,
          preMoveMoverEvalPawns: 0.3,
          playedMoveRank: 4,
          cpGapFromBest: 48,
        ),
      );

      expect(assessment.quality, MoveQuality.slip);
    });

    test('does not upgrade wider cp-gap slips back to solid', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.09,
          preMoveMoverWinProbability: 0.52,
          postMoveMoverWinProbability: 0.43,
          preMoveMoverEvalPawns: 0.2,
          cpGapFromBest: 44,
        ),
      );

      expect(assessment.quality, MoveQuality.slip);
    });

    test('keeps opening top-line moves as book even with harsh drift', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.27,
          preMoveMoverWinProbability: 0.58,
          postMoveMoverWinProbability: 0.31,
          preMoveMoverEvalPawns: 0.4,
          currentOpening: 'Scotch Game',
          playedMoveRank: 1,
          cpGapFromBest: 0,
          insideOpeningExemption: true,
        ),
      );

      expect(assessment.quality, MoveQuality.book);
      expect(
        assessment.scoringSuppressedReason,
        MoveQualityScoringSuppressionReason.openingFeedbackOnly,
      );
      expect(assessment.explanation, 'Opening: Scotch Game');
    });

    test('uses opening label for low-confidence book feedback', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.08,
          preMoveMoverWinProbability: 0.54,
          postMoveMoverWinProbability: 0.46,
          preMoveMoverEvalPawns: 0.2,
          currentOpening: 'Queen\'s Gambit Declined',
          cpGapFromBest: 64,
          playedMoveRank: 6,
          insideOpeningExemption: true,
          confidence: MoveQualityConfidence.low,
        ),
      );

      expect(assessment.quality, MoveQuality.book);
      expect(
        assessment.scoringSuppressedReason,
        MoveQualityScoringSuppressionReason.openingFeedbackOnly,
      );
      expect(assessment.explanation, 'Opening: Queen\'s Gambit Declined');
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

    test('does not hide catastrophic low-confidence losses behind solid', () {
      final assessment = classifyMoveQuality(
        const MoveQualityClassificationContext(
          deltaWpLoss: 0.41,
          preMoveMoverWinProbability: 0.51,
          postMoveMoverWinProbability: 0.10,
          preMoveMoverEvalPawns: 0.1,
          confidence: MoveQualityConfidence.low,
        ),
      );

      expect(assessment.quality, MoveQuality.criticalFailure);
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

      expect(hardStrongMove.quality, MoveQuality.optimal);
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

    test('describes book moves as staying in registered theory', () {
      expect(MoveQuality.book.explanation, contains('registered opening move'));
      expect(MoveQuality.book.explanation, isNot(contains('6 plies')));
    });
  });
}
