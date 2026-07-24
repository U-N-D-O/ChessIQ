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

  group('isValidPawnSquare', () {
    test('allows non-pawn pieces on any rank', () {
      expect(isValidPawnSquare('q_w', 'a1'), isTrue);
      expect(isValidPawnSquare('n_b', 'h8'), isTrue);
      expect(isValidPawnSquare('k_w', 'e1'), isTrue);
    });

    test('allows white pawn on ranks 2 through 7', () {
      for (int rank = 2; rank <= 7; rank++) {
        expect(isValidPawnSquare('p_w', 'e$rank'), isTrue,
            reason: 'white pawn on rank $rank should be valid');
      }
    });

    test('allows black pawn on ranks 2 through 7', () {
      for (int rank = 2; rank <= 7; rank++) {
        expect(isValidPawnSquare('p_b', 'd$rank'), isTrue,
            reason: 'black pawn on rank $rank should be valid');
      }
    });

    test('rejects white pawn on rank 1', () {
      expect(isValidPawnSquare('p_w', 'e1'), isFalse);
      expect(isValidPawnSquare('p_w', 'a1'), isFalse);
    });

    test('rejects white pawn on rank 8', () {
      expect(isValidPawnSquare('p_w', 'e8'), isFalse);
      expect(isValidPawnSquare('p_w', 'h8'), isFalse);
    });

    test('rejects black pawn on rank 1', () {
      expect(isValidPawnSquare('p_b', 'a1'), isFalse);
      expect(isValidPawnSquare('p_b', 'f1'), isFalse);
    });

    test('rejects black pawn on rank 8', () {
      expect(isValidPawnSquare('p_b', 'a8'), isFalse);
      expect(isValidPawnSquare('p_b', 'g8'), isFalse);
    });
  });

  group('sanitizeBoardState', () {
    test('removes white pawns on rank 1', () {
      final board = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'f1': 'p_w',
        'a2': 'p_w',
      };
      final sanitized = sanitizeBoardState(board);
      expect(sanitized.containsKey('f1'), isFalse);
      expect(sanitized['a2'], 'p_w');
      expect(sanitized['e1'], 'k_w');
      expect(sanitized['e8'], 'k_b');
    });

    test('removes white pawns on rank 8', () {
      final board = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'c8': 'p_w',
        'g7': 'p_w',
      };
      final sanitized = sanitizeBoardState(board);
      expect(sanitized.containsKey('c8'), isFalse);
      expect(sanitized['g7'], 'p_w');
    });

    test('removes black pawns on rank 1', () {
      final board = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'b1': 'p_b',
        'd7': 'p_b',
      };
      final sanitized = sanitizeBoardState(board);
      expect(sanitized.containsKey('b1'), isFalse);
      expect(sanitized['d7'], 'p_b');
    });

    test('removes black pawns on rank 8', () {
      final board = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'a8': 'p_b',
        'e7': 'p_b',
      };
      final sanitized = sanitizeBoardState(board);
      expect(sanitized.containsKey('a8'), isFalse);
      expect(sanitized['e7'], 'p_b');
    });

    test('preserves all valid pieces', () {
      final board = <String, String>{
        'e1': 'k_w',
        'e8': 'k_b',
        'a2': 'p_w',
        'b7': 'p_b',
        'h1': 't_w',
        'a8': 't_b',
        'c1': 'b_w',
        'd4': 'q_w',
      };
      final sanitized = sanitizeBoardState(board);
      expect(sanitized, equals(board));
    });

    test('returns empty map when all pieces are invalid', () {
      final board = <String, String>{
        'a1': 'p_w',
        'h8': 'p_b',
        'b1': 'p_b',
      };
      expect(sanitizeBoardState(board), isEmpty);
    });
  });
}
