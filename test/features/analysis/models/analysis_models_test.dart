import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:chessiq/features/analysis/models/move_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoveRecord session grading metadata', () {
    test('copyWith preserves and updates runtime-only grading fields', () {
      final baseline = MoveRecord(
        notation: 'Nf3',
        pieceMoved: 'n_w',
        state: const {'g1': 'n_w'},
        isWhite: true,
        whiteKingMoved: false,
        blackKingMoved: false,
        whiteKingsideRookMoved: false,
        whiteQueensideRookMoved: false,
        blackKingsideRookMoved: false,
        blackQueensideRookMoved: false,
        uci: 'g1f3',
        quality: MoveQuality.book,
        qualityExplanation:
            'Book move. The first 6 plies are feedback-only, so no points are awarded.',
        moveRank: 2,
        cpGapFromBest: 18,
        qualityConfidence: MoveQualityConfidence.medium,
        chargeBefore: 50,
        chargeAfter: 50,
        scoringSuppressedReason:
            MoveQualityScoringSuppressionReason.openingFeedbackOnly,
      );

      final updated = baseline.copyWith(
        quality: MoveQuality.strong,
        qualityExplanation: 'Near-best move after the opening window.',
        qualityConfidence: MoveQualityConfidence.high,
        chargeAfter: 65,
        scoringSuppressedReason: null,
      );

      expect(updated.uci, 'g1f3');
      expect(updated.moveRank, 2);
      expect(updated.cpGapFromBest, 18);
      expect(updated.chargeBefore, 50);
      expect(updated.chargeAfter, 65);
      expect(updated.quality, MoveQuality.strong);
      expect(updated.qualityConfidence, MoveQualityConfidence.high);
      expect(updated.scoringSuppressedReason, isNull);
    });
  });
}
