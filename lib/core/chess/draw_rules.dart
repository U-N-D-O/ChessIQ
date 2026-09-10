enum DrawReason {
  stalemate,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
}

bool hasExactlyOneKingPerSide(Map<String, String> boardState) {
  var whiteKingCount = 0;
  var blackKingCount = 0;

  for (final piece in boardState.values) {
    if (piece == 'k_w') {
      whiteKingCount += 1;
    } else if (piece == 'k_b') {
      blackKingCount += 1;
    }
  }

  return whiteKingCount == 1 && blackKingCount == 1;
}

bool hasInsufficientMatingMaterial(Map<String, String> boardState) {
  final materialPieces = <_MaterialPieceOnBoard>[];

  for (final entry in boardState.entries) {
    final piece = entry.value;
    if (piece.isEmpty || piece.startsWith('k')) {
      continue;
    }
    materialPieces.add(
      _MaterialPieceOnBoard(square: entry.key, pieceType: piece[0]),
    );
  }

  if (materialPieces.any(
    (piece) => piece.isPawn || piece.isRook || piece.isQueen,
  )) {
    return false;
  }

  if (materialPieces.isEmpty) {
    return true;
  }

  if (materialPieces.length == 1) {
    final piece = materialPieces.single;
    return piece.isBishop || piece.isKnight;
  }

  if (materialPieces.every((piece) => piece.isBishop)) {
    return _allBishopsShareSquareColor(materialPieces);
  }

  return false;
}

bool _allBishopsShareSquareColor(List<_MaterialPieceOnBoard> bishops) {
  if (bishops.isEmpty) {
    return false;
  }

  final firstColorParity = _squareColorParity(bishops.first.square);
  if (firstColorParity == null) {
    return false;
  }

  for (final bishop in bishops.skip(1)) {
    if (_squareColorParity(bishop.square) != firstColorParity) {
      return false;
    }
  }

  return true;
}

int? _squareColorParity(String square) {
  if (square.length != 2) {
    return null;
  }

  final file = square.codeUnitAt(0) - 97;
  final rank = int.tryParse(square.substring(1));
  if (file < 0 || file > 7 || rank == null || rank < 1 || rank > 8) {
    return null;
  }

  return (file + rank - 1) & 1;
}

class _MaterialPieceOnBoard {
  const _MaterialPieceOnBoard({required this.square, required this.pieceType});

  final String square;
  final String pieceType;

  bool get isBishop => pieceType == 'b';
  bool get isKnight => pieceType == 'n';
  bool get isPawn => pieceType == 'p';
  bool get isQueen => pieceType == 'q';
  bool get isRook => pieceType == 't';
}

/// Returns true if placing [piece] on [square] is a valid pawn placement.
///
/// White pawns can only exist on ranks 2–7 (they start on rank 2 and promote
/// on rank 8, so they are never legally present on ranks 1 or 8).  Black
/// pawns follow the same rule in the opposite direction.  Any non-pawn piece
/// passes unconditionally.
bool isValidPawnSquare(String piece, String square) {
  if (!piece.startsWith('p_')) return true;
  if (square.length != 2) return false;
  final rank = int.tryParse(square[1]);
  if (rank == null) return false;
  return rank >= 2 && rank <= 7;
}

/// Returns a short explanation when [boardState] is unsafe to use as an
/// analysis position, or null when the position is structurally safe.
///
/// Analysis positions may be unusual, but they still need to fit inside the
/// bounds of a real chess position. In particular, a side cannot have more
/// than 16 pieces in total or more than 8 pawns. Allowing those positions can
/// make the chess/FEN and engine layers disagree about the position.
String? validateAnalysisBoardState(Map<String, String> boardState) {
  const validPieces = <String>{
    'p_w',
    'n_w',
    'b_w',
    't_w',
    'q_w',
    'k_w',
    'p_b',
    'n_b',
    'b_b',
    't_b',
    'q_b',
    'k_b',
  };

  var whitePieces = 0;
  var blackPieces = 0;
  var whitePawns = 0;
  var blackPawns = 0;
  String? whiteKingSquare;
  String? blackKingSquare;

  for (final entry in boardState.entries) {
    final square = entry.key;
    final piece = entry.value;
    if (!RegExp(r'^[a-h][1-8]$').hasMatch(square)) {
      return 'Invalid square: $square';
    }
    if (!validPieces.contains(piece)) {
      return 'Invalid piece on $square';
    }
    if (!isValidPawnSquare(piece, square)) {
      return 'Pawns cannot be placed on the first or last rank';
    }

    final isWhite = piece.endsWith('_w');
    if (isWhite) {
      whitePieces += 1;
      if (piece == 'p_w') whitePawns += 1;
      if (piece == 'k_w') whiteKingSquare = square;
    } else {
      blackPieces += 1;
      if (piece == 'p_b') blackPawns += 1;
      if (piece == 'k_b') blackKingSquare = square;
    }
  }

  if (whiteKingSquare == null || blackKingSquare == null) {
    return 'Keep one white king and one black king on the board';
  }
  if (whitePieces > 16 || blackPieces > 16) {
    return 'Each side can have at most 16 pieces';
  }
  if (whitePawns > 8 || blackPawns > 8) {
    return 'Each side can have at most 8 pawns';
  }

  final whiteFile = whiteKingSquare.codeUnitAt(0) - 97;
  final whiteRank = int.parse(whiteKingSquare[1]) - 1;
  final blackFile = blackKingSquare.codeUnitAt(0) - 97;
  final blackRank = int.parse(blackKingSquare[1]) - 1;
  if ((whiteFile - blackFile).abs() <= 1 &&
      (whiteRank - blackRank).abs() <= 1) {
    return 'The kings cannot be on neighbouring squares';
  }

  return null;
}

bool isSafeAnalysisBoardState(Map<String, String> boardState) {
  return validateAnalysisBoardState(boardState) == null;
}

/// Removes any entry from [boardState] whose piece violates [isValidPawnSquare].
///
/// Used when restoring a saved board to prevent invalid positions (e.g. a
/// white pawn on rank 1) from being sent to Stockfish and crashing the app.
Map<String, String> sanitizeBoardState(Map<String, String> boardState) {
  return Map<String, String>.fromEntries(
    boardState.entries.where((e) => isValidPawnSquare(e.value, e.key)),
  );
}

String buildBoardFen(Map<String, String> boardState) {
  final buffer = StringBuffer();
  for (var rank = 8; rank >= 1; rank--) {
    var emptySquares = 0;
    for (var fileIndex = 0; fileIndex < 8; fileIndex++) {
      final square = '${String.fromCharCode(97 + fileIndex)}$rank';
      final piece = boardState[square];
      if (piece == null) {
        emptySquares += 1;
        continue;
      }

      if (emptySquares > 0) {
        buffer.write(emptySquares);
        emptySquares = 0;
      }

      var fenPiece = piece[0];
      if (fenPiece == 't') {
        fenPiece = 'r';
      }
      if (piece.endsWith('_w')) {
        fenPiece = fenPiece.toUpperCase();
      }
      buffer.write(fenPiece);
    }

    if (emptySquares > 0) {
      buffer.write(emptySquares);
    }
    if (rank > 1) {
      buffer.write('/');
    }
  }

  return buffer.toString();
}

String buildPositionKey({
  required Map<String, String> boardState,
  required bool isWhiteTurn,
  required bool whiteKingMoved,
  required bool blackKingMoved,
  required bool whiteKingsideRookMoved,
  required bool whiteQueensideRookMoved,
  required bool blackKingsideRookMoved,
  required bool blackQueensideRookMoved,
  required String? enPassantTarget,
}) {
  final castling = StringBuffer();
  if (!whiteKingMoved &&
      !whiteKingsideRookMoved &&
      boardState['e1'] == 'k_w' &&
      boardState['h1'] == 't_w') {
    castling.write('K');
  }
  if (!whiteKingMoved &&
      !whiteQueensideRookMoved &&
      boardState['e1'] == 'k_w' &&
      boardState['a1'] == 't_w') {
    castling.write('Q');
  }
  if (!blackKingMoved &&
      !blackKingsideRookMoved &&
      boardState['e8'] == 'k_b' &&
      boardState['h8'] == 't_b') {
    castling.write('k');
  }
  if (!blackKingMoved &&
      !blackQueensideRookMoved &&
      boardState['e8'] == 'k_b' &&
      boardState['a8'] == 't_b') {
    castling.write('q');
  }

  final normalizedEnPassantTarget = normalizeEnPassantTarget(
    boardState: boardState,
    isWhiteTurn: isWhiteTurn,
    enPassantTarget: enPassantTarget,
  );

  return '${buildBoardFen(boardState)} ${isWhiteTurn ? 'w' : 'b'} '
      '${castling.isEmpty ? '-' : castling.toString()} '
      '${normalizedEnPassantTarget ?? '-'}';
}

int advanceHalfmoveClock({
  required int currentHalfmoveClock,
  required String pieceMoved,
  required String? pieceCaptured,
}) {
  if (pieceMoved.startsWith('p_') || pieceMoved.startsWith('p')) {
    return 0;
  }
  if (pieceCaptured != null && pieceCaptured.isNotEmpty) {
    return 0;
  }
  return currentHalfmoveClock + 1;
}

String? normalizeEnPassantTarget({
  required Map<String, String> boardState,
  required bool isWhiteTurn,
  required String? enPassantTarget,
}) {
  if (enPassantTarget == null ||
      enPassantTarget.isEmpty ||
      enPassantTarget == '-') {
    return null;
  }
  if (enPassantTarget.length != 2) {
    return null;
  }

  final targetFile = enPassantTarget.codeUnitAt(0);
  final targetRank = int.tryParse(enPassantTarget[1]);
  if (targetFile < 97 || targetFile > 104 || targetRank == null) {
    return null;
  }

  final moverColor = isWhiteTurn ? '_w' : '_b';
  final capturedColor = isWhiteTurn ? '_b' : '_w';
  final sourceRank = isWhiteTurn ? targetRank - 1 : targetRank + 1;
  final capturedPawnRank = isWhiteTurn ? targetRank - 1 : targetRank + 1;

  if (sourceRank < 1 || sourceRank > 8) {
    return null;
  }

  final capturedPawnSquare =
      '${String.fromCharCode(targetFile)}$capturedPawnRank';
  if (boardState[capturedPawnSquare] != 'p$capturedColor') {
    return null;
  }

  for (final fileOffset in const <int>[-1, 1]) {
    final sourceFile = targetFile + fileOffset;
    if (sourceFile < 97 || sourceFile > 104) {
      continue;
    }
    final sourceSquare = '${String.fromCharCode(sourceFile)}$sourceRank';
    if (boardState[sourceSquare] == 'p$moverColor') {
      return enPassantTarget;
    }
  }

  return null;
}
