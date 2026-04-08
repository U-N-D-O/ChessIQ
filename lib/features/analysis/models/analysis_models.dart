enum BoardPerspective { white, black, auto }

enum BoardThemeMode { dark, light, monochrome, ember, aurora }

enum PieceThemeMode { classic, ember, frost }

enum AppSection { menu, analysis, gambitQuiz, botSetup, puzzleAcademy }

enum OpeningMode { off, yellowGlow, blueGlow }

class MoveRecord {
  final String notation;
  final String pieceMoved;
  final String? pieceCaptured;
  final Map<String, String> state;
  final bool isWhite;
  final bool whiteKingMoved;
  final bool blackKingMoved;
  final bool whiteKingsideRookMoved;
  final bool whiteQueensideRookMoved;
  final bool blackKingsideRookMoved;
  final bool blackQueensideRookMoved;
  final String? enPassantTarget;

  MoveRecord({
    required this.notation,
    required this.pieceMoved,
    this.pieceCaptured,
    required this.state,
    required this.isWhite,
    required this.whiteKingMoved,
    required this.blackKingMoved,
    required this.whiteKingsideRookMoved,
    required this.whiteQueensideRookMoved,
    required this.blackKingsideRookMoved,
    required this.blackQueensideRookMoved,
    this.enPassantTarget,
  });
}

class EngineLine {
  final String move;
  final int eval;
  final int depth;
  final int multiPv;

  EngineLine(this.move, this.eval, this.depth, this.multiPv);

  Map<String, dynamic> toMap() {
    return {'move': move, 'eval': eval, 'depth': depth, 'multiPv': multiPv};
  }

  static EngineLine? fromMap(Map<dynamic, dynamic> data) {
    final move = data['move']?.toString();
    final eval = (data['eval'] as num?)?.toInt();
    final depth = (data['depth'] as num?)?.toInt();
    final multiPv = (data['multiPv'] as num?)?.toInt();
    if (move == null || move.length < 4) return null;
    if (eval == null || depth == null || multiPv == null) return null;
    return EngineLine(move, eval, depth, multiPv);
  }
}

class EcoLine {
  final String name;
  final String normalizedMoves;
  final List<String> moveTokens;
  final bool isGambit;

  EcoLine({
    required this.name,
    required this.normalizedMoves,
    required this.moveTokens,
    required this.isGambit,
  });
}
