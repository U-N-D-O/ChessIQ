import 'package:chessiq/core/chess/draw_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasExactlyOneKingPerSide', () {
    test('returns true when both sides have one king', () {
      expect(
        hasExactlyOneKingPerSide(<String, String>{
          'e1': 'k_w',
          'e8': 'k_b',
          'd4': 'q_w',
        }),
        isTrue,
      );
    });

    test('returns false when a king is missing', () {
      expect(
        hasExactlyOneKingPerSide(<String, String>{'e1': 'k_w', 'd4': 'q_w'}),
        isFalse,
      );
    });

    test('returns false when one side has multiple kings', () {
      expect(
        hasExactlyOneKingPerSide(<String, String>{
          'e1': 'k_w',
          'd2': 'k_w',
          'e8': 'k_b',
        }),
        isFalse,
      );
    });
  });

  group('hasInsufficientMatingMaterial', () {
    test('detects king versus king as a dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'e8': 'k_b',
        }),
        isTrue,
      );
    });

    test('detects king and bishop versus king as a dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'c1': 'b_w',
          'e8': 'k_b',
        }),
        isTrue,
      );
    });

    test('detects king and knight versus king as a dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'g1': 'n_w',
          'e8': 'k_b',
        }),
        isTrue,
      );
    });

    test('detects same-colored bishops as a dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'c1': 'b_w',
          'e8': 'k_b',
          'f8': 'b_b',
        }),
        isTrue,
      );
    });

    test('does not flag opposite-colored bishops as dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'c1': 'b_w',
          'e8': 'k_b',
          'c8': 'b_b',
        }),
        isFalse,
      );
    });

    test('does not flag bishop and knight versus king as dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'c1': 'b_w',
          'g1': 'n_w',
          'e8': 'k_b',
        }),
        isFalse,
      );
    });

    test('does not flag rook versus king as dead position', () {
      expect(
        hasInsufficientMatingMaterial(<String, String>{
          'e1': 'k_w',
          'h1': 't_w',
          'e8': 'k_b',
        }),
        isFalse,
      );
    });
  });

  group('advanceHalfmoveClock', () {
    test('increments after a quiet non-pawn move', () {
      expect(
        advanceHalfmoveClock(
          currentHalfmoveClock: 17,
          pieceMoved: 'n_w',
          pieceCaptured: null,
        ),
        18,
      );
    });

    test('resets after a pawn move', () {
      expect(
        advanceHalfmoveClock(
          currentHalfmoveClock: 17,
          pieceMoved: 'p_w',
          pieceCaptured: null,
        ),
        0,
      );
    });

    test('resets after a capture', () {
      expect(
        advanceHalfmoveClock(
          currentHalfmoveClock: 17,
          pieceMoved: 'n_w',
          pieceCaptured: 'b_b',
        ),
        0,
      );
    });
  });

  group('buildPositionKey', () {
    test('drops en passant target when no capture is available', () {
      final boardState = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'd5': 'p_b',
      };

      expect(
        buildPositionKey(
          boardState: boardState,
          isWhiteTurn: true,
          whiteKingMoved: true,
          blackKingMoved: true,
          whiteKingsideRookMoved: true,
          whiteQueensideRookMoved: true,
          blackKingsideRookMoved: true,
          blackQueensideRookMoved: true,
          enPassantTarget: 'd6',
        ),
        '4k3/8/8/3p4/8/8/8/4K3 w - -',
      );
    });

    test('keeps en passant target when a capture is available', () {
      final boardState = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'c5': 'p_w',
        'd5': 'p_b',
      };

      expect(
        buildPositionKey(
          boardState: boardState,
          isWhiteTurn: true,
          whiteKingMoved: true,
          blackKingMoved: true,
          whiteKingsideRookMoved: true,
          whiteQueensideRookMoved: true,
          blackKingsideRookMoved: true,
          blackQueensideRookMoved: true,
          enPassantTarget: 'd6',
        ),
        '4k3/8/8/2Pp4/8/8/8/4K3 w - d6',
      );
    });

    test('includes castling rights when they remain available', () {
      final boardState = <String, String>{
        'a1': 't_w',
        'e1': 'k_w',
        'h1': 't_w',
        'a8': 't_b',
        'e8': 'k_b',
        'h8': 't_b',
      };

      expect(
        buildPositionKey(
          boardState: boardState,
          isWhiteTurn: false,
          whiteKingMoved: false,
          blackKingMoved: false,
          whiteKingsideRookMoved: false,
          whiteQueensideRookMoved: false,
          blackKingsideRookMoved: false,
          blackQueensideRookMoved: false,
          enPassantTarget: null,
        ),
        'r3k2r/8/8/8/8/8/8/R3K2R b KQkq -',
      );
    });
  });
}
