import 'move_quality.dart';

enum BoardPerspective { white, black, auto }

enum BoardThemeMode { dark, light, monochrome, ember, aurora, sakura, tropical }

enum PieceThemeMode { classic, ember, frost, tuttiFrutti, spectral }

enum AppSection { menu, analysis, gambitQuiz, botSetup, puzzleAcademy }

enum OpeningMode { off, yellowGlow, blueGlow, violetGlow }

class MoveRecord {
  static const Object _sentinel = Object();

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
  final String? uci;
  final MoveQuality? quality;
  final double? preMoveWinProbability;
  final double? postMoveWinProbability;
  final double? deltaWinProbabilityLoss;
  final String? qualityExplanation;
  final int? moveRank;
  final int? cpGapFromBest;
  final MoveQualityConfidence? qualityConfidence;
  final bool? isSacrifice;
  final int? chargeBefore;
  final int? chargeAfter;
  final MoveQualityScoringSuppressionReason? scoringSuppressedReason;

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
    this.uci,
    this.quality,
    this.preMoveWinProbability,
    this.postMoveWinProbability,
    this.deltaWinProbabilityLoss,
    this.qualityExplanation,
    this.moveRank,
    this.cpGapFromBest,
    this.qualityConfidence,
    this.isSacrifice,
    this.chargeBefore,
    this.chargeAfter,
    this.scoringSuppressedReason,
  });

  MoveRecord copyWith({
    String? notation,
    String? pieceMoved,
    Object? pieceCaptured = _sentinel,
    Map<String, String>? state,
    bool? isWhite,
    bool? whiteKingMoved,
    bool? blackKingMoved,
    bool? whiteKingsideRookMoved,
    bool? whiteQueensideRookMoved,
    bool? blackKingsideRookMoved,
    bool? blackQueensideRookMoved,
    Object? enPassantTarget = _sentinel,
    Object? uci = _sentinel,
    Object? quality = _sentinel,
    Object? preMoveWinProbability = _sentinel,
    Object? postMoveWinProbability = _sentinel,
    Object? deltaWinProbabilityLoss = _sentinel,
    Object? qualityExplanation = _sentinel,
    Object? moveRank = _sentinel,
    Object? cpGapFromBest = _sentinel,
    Object? qualityConfidence = _sentinel,
    Object? isSacrifice = _sentinel,
    Object? chargeBefore = _sentinel,
    Object? chargeAfter = _sentinel,
    Object? scoringSuppressedReason = _sentinel,
  }) {
    return MoveRecord(
      notation: notation ?? this.notation,
      pieceMoved: pieceMoved ?? this.pieceMoved,
      pieceCaptured: identical(pieceCaptured, _sentinel)
          ? this.pieceCaptured
          : pieceCaptured as String?,
      state: state ?? this.state,
      isWhite: isWhite ?? this.isWhite,
      whiteKingMoved: whiteKingMoved ?? this.whiteKingMoved,
      blackKingMoved: blackKingMoved ?? this.blackKingMoved,
      whiteKingsideRookMoved:
          whiteKingsideRookMoved ?? this.whiteKingsideRookMoved,
      whiteQueensideRookMoved:
          whiteQueensideRookMoved ?? this.whiteQueensideRookMoved,
      blackKingsideRookMoved:
          blackKingsideRookMoved ?? this.blackKingsideRookMoved,
      blackQueensideRookMoved:
          blackQueensideRookMoved ?? this.blackQueensideRookMoved,
      enPassantTarget: identical(enPassantTarget, _sentinel)
          ? this.enPassantTarget
          : enPassantTarget as String?,
      uci: identical(uci, _sentinel) ? this.uci : uci as String?,
      quality: identical(quality, _sentinel)
          ? this.quality
          : quality as MoveQuality?,
      preMoveWinProbability: identical(preMoveWinProbability, _sentinel)
          ? this.preMoveWinProbability
          : preMoveWinProbability as double?,
      postMoveWinProbability: identical(postMoveWinProbability, _sentinel)
          ? this.postMoveWinProbability
          : postMoveWinProbability as double?,
      deltaWinProbabilityLoss: identical(deltaWinProbabilityLoss, _sentinel)
          ? this.deltaWinProbabilityLoss
          : deltaWinProbabilityLoss as double?,
      qualityExplanation: identical(qualityExplanation, _sentinel)
          ? this.qualityExplanation
          : qualityExplanation as String?,
      moveRank: identical(moveRank, _sentinel)
          ? this.moveRank
          : moveRank as int?,
      cpGapFromBest: identical(cpGapFromBest, _sentinel)
          ? this.cpGapFromBest
          : cpGapFromBest as int?,
      qualityConfidence: identical(qualityConfidence, _sentinel)
          ? this.qualityConfidence
          : qualityConfidence as MoveQualityConfidence?,
      isSacrifice: identical(isSacrifice, _sentinel)
          ? this.isSacrifice
          : isSacrifice as bool?,
      chargeBefore: identical(chargeBefore, _sentinel)
          ? this.chargeBefore
          : chargeBefore as int?,
      chargeAfter: identical(chargeAfter, _sentinel)
          ? this.chargeAfter
          : chargeAfter as int?,
      scoringSuppressedReason: identical(scoringSuppressedReason, _sentinel)
          ? this.scoringSuppressedReason
          : scoringSuppressedReason as MoveQualityScoringSuppressionReason?,
    );
  }
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
