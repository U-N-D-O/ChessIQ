enum DrawReason {
  stalemate,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
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
