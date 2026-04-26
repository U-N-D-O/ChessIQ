import 'move_quality.dart';

enum BoardPerspective { white, black, auto }

enum BoardThemeMode { dark, light, monochrome, ember, aurora, sakura, tropical }

enum PieceThemeMode { classic, ember, frost, tuttiFrutti, spectral, monochrome }

enum AppSection { menu, analysis, gambitQuiz, botSetup, puzzleAcademy }

enum OpeningMode { off, yellowGlow, blueGlow, violetGlow }

enum EngineRequestRole {
  liveAnalysis,
  botSearch,
  moveGrading,
  backgroundConfirmation;

  int get priority {
    switch (this) {
      case EngineRequestRole.botSearch:
        return 300;
      case EngineRequestRole.moveGrading:
        return 200;
      case EngineRequestRole.liveAnalysis:
        return 100;
      case EngineRequestRole.backgroundConfirmation:
        return 0;
    }
  }
}

class EngineRequestSpec {
  const EngineRequestSpec({
    required this.requestId,
    required this.role,
    required this.fen,
    required this.whiteToMove,
    required this.multiPv,
    required this.timeout,
    this.firstInfoTimeout,
    this.depth,
    this.moveTime,
    this.preCommands = const <String>[],
    this.cleanupCommands = const <String>[],
    this.searchMoves = const <String>[],
  }) : assert(depth != null || moveTime != null);

  final String requestId;
  final EngineRequestRole role;
  final String fen;
  final bool whiteToMove;
  final int multiPv;
  final Duration timeout;
  final Duration? firstInfoTimeout;
  final int? depth;
  final Duration? moveTime;
  final List<String> preCommands;
  final List<String> cleanupCommands;
  final List<String> searchMoves;

  String get fenHash => fen.hashCode.toUnsigned(32).toRadixString(16);

  String get goCommand {
    final parts = <String>['go'];
    if (moveTime != null) {
      parts.addAll(<String>['movetime', '${moveTime!.inMilliseconds}']);
    } else {
      parts.addAll(<String>['depth', '${depth ?? 1}']);
    }
    if (searchMoves.isNotEmpty) {
      parts.add('searchmoves');
      parts.addAll(searchMoves);
    }
    return parts.join(' ');
  }

  bool matchesFen(String candidateFen) => fen == candidateFen;
}

class EvalSnapshot {
  const EvalSnapshot({
    required this.requestId,
    required this.role,
    required this.fen,
    required this.whiteToMove,
    required this.depth,
    required this.multiPv,
    required this.evalCpWhite,
    required this.timestamp,
  });

  factory EvalSnapshot.fromRelativeScore({
    required String requestId,
    required EngineRequestRole role,
    required String fen,
    required bool whiteToMove,
    required int depth,
    required int multiPv,
    required int relativeEvalCp,
    required DateTime timestamp,
  }) {
    return EvalSnapshot(
      requestId: requestId,
      role: role,
      fen: fen,
      whiteToMove: whiteToMove,
      depth: depth,
      multiPv: multiPv,
      evalCpWhite: whiteToMove ? relativeEvalCp : -relativeEvalCp,
      timestamp: timestamp,
    );
  }

  final String requestId;
  final EngineRequestRole role;
  final String fen;
  final bool whiteToMove;
  final int depth;
  final int multiPv;
  final int evalCpWhite;
  final DateTime timestamp;

  double get evalPawnsWhite => evalCpWhite / 100.0;

  int centipawnsForPov(bool whitePov) => whitePov ? evalCpWhite : -evalCpWhite;

  double pawnsForPov(bool whitePov) => centipawnsForPov(whitePov) / 100.0;

  bool matchesFen(String candidateFen) => fen == candidateFen;
}

class EngineSearchUpdate {
  const EngineSearchUpdate({
    required this.request,
    required this.line,
    required this.snapshot,
    required this.timestamp,
  });

  final EngineRequestSpec request;
  final EngineLine line;
  final EvalSnapshot snapshot;
  final DateTime timestamp;

  bool get isPrimaryVariation => line.multiPv == 1;
}

class PositionAnalysisCacheEntry {
  static const Object _sentinel = Object();

  const PositionAnalysisCacheEntry({
    required this.fen,
    this.evalSnapshot,
    this.primaryLine,
    this.analysisLines = const <EngineLine>[],
  });

  final String fen;
  final EvalSnapshot? evalSnapshot;
  final EngineLine? primaryLine;
  final List<EngineLine> analysisLines;

  int get analysisDepth =>
      analysisLines.isEmpty ? 0 : analysisLines.first.depth;

  int get primaryDepth => primaryLine?.depth ?? 0;

  PositionAnalysisCacheEntry copyWith({
    Object? evalSnapshot = _sentinel,
    Object? primaryLine = _sentinel,
    Object? analysisLines = _sentinel,
  }) {
    return PositionAnalysisCacheEntry(
      fen: fen,
      evalSnapshot: identical(evalSnapshot, _sentinel)
          ? this.evalSnapshot
          : evalSnapshot as EvalSnapshot?,
      primaryLine: identical(primaryLine, _sentinel)
          ? this.primaryLine
          : primaryLine as EngineLine?,
      analysisLines: identical(analysisLines, _sentinel)
          ? this.analysisLines
          : analysisLines as List<EngineLine>,
    );
  }

  PositionAnalysisCacheEntry mergedWithPrimaryUpdate(
    EngineSearchUpdate update,
  ) {
    assert(update.request.fen == fen);
    return copyWith(
      evalSnapshot: preferBestEvalSnapshot(evalSnapshot, update.snapshot),
      primaryLine: preferDeeperEngineLine(primaryLine, update.line),
    );
  }

  PositionAnalysisCacheEntry mergedWithAnalysisLines(
    List<EngineLine> nextLines,
  ) {
    return copyWith(
      analysisLines: preferDeeperAnalysisLines(analysisLines, nextLines),
    );
  }
}

class MoveQualityEvidenceResolution {
  const MoveQualityEvidenceResolution({
    required this.preMoveLines,
    required this.preMoveMoverWinProbability,
    required this.preMoveMoverEvalPawns,
    required this.postMoveLine,
    required this.postMoveWhiteToMove,
    required this.usedPreMoveFallback,
    required this.needsPreMoveConfirmation,
    required this.needsPostMoveConfirmation,
  });

  final List<EngineLine> preMoveLines;
  final double? preMoveMoverWinProbability;
  final double? preMoveMoverEvalPawns;
  final EngineLine? postMoveLine;
  final bool? postMoveWhiteToMove;
  final bool usedPreMoveFallback;
  final bool needsPreMoveConfirmation;
  final bool needsPostMoveConfirmation;

  bool get isReadyToPublish =>
      !needsPreMoveConfirmation && !needsPostMoveConfirmation;
}

EvalSnapshot? preferBestEvalSnapshot(
  EvalSnapshot? current,
  EvalSnapshot? candidate,
) {
  if (candidate == null) {
    return current;
  }
  if (current == null) {
    return candidate;
  }
  if (candidate.depth != current.depth) {
    return candidate.depth > current.depth ? candidate : current;
  }
  return candidate.timestamp.isAfter(current.timestamp) ? candidate : current;
}

EngineLine? preferDeeperEngineLine(EngineLine? current, EngineLine? candidate) {
  if (candidate == null) {
    return current;
  }
  if (current == null) {
    return candidate;
  }
  if (candidate.depth != current.depth) {
    return candidate.depth > current.depth ? candidate : current;
  }
  return candidate;
}

List<EngineLine> preferDeeperAnalysisLines(
  List<EngineLine> current,
  List<EngineLine> candidate,
) {
  final normalizedCurrent = _normalizedEngineLines(current);
  final normalizedCandidate = _normalizedEngineLines(candidate);
  final currentDepth = normalizedCurrent.isEmpty
      ? 0
      : normalizedCurrent.first.depth;
  final candidateDepth = normalizedCandidate.isEmpty
      ? 0
      : normalizedCandidate.first.depth;

  if (candidateDepth > currentDepth) {
    return normalizedCandidate;
  }
  if (currentDepth > candidateDepth) {
    return normalizedCurrent;
  }
  if (normalizedCandidate.length >= normalizedCurrent.length &&
      normalizedCandidate.isNotEmpty) {
    return normalizedCandidate;
  }
  return normalizedCurrent;
}

MoveQualityEvidenceResolution resolveMoveQualityEvidence({
  required bool moverIsWhite,
  required List<EngineLine> capturedPreMoveLines,
  required double? capturedPreMoveMoverWinProbability,
  required double? capturedPreMoveMoverEvalPawns,
  PositionAnalysisCacheEntry? preMoveCacheEntry,
  EngineLine? livePostMoveLine,
  bool? livePostMoveWhiteToMove,
  PositionAnalysisCacheEntry? postMoveCacheEntry,
  required int minimumDepth,
}) {
  final normalizedCapturedPreMoveLines = _normalizedEngineLines(
    capturedPreMoveLines,
  );
  final preMoveLines = preferDeeperAnalysisLines(
    normalizedCapturedPreMoveLines,
    preMoveCacheEntry?.analysisLines ?? const <EngineLine>[],
  );

  final capturedPreMovePrimaryLine = normalizedCapturedPreMoveLines.isEmpty
      ? null
      : normalizedCapturedPreMoveLines.first;
  final cachedPreMovePrimaryLine = preMoveCacheEntry?.primaryLine;
  final resolvedPreMovePrimaryLine = preferDeeperEngineLine(
    capturedPreMovePrimaryLine,
    cachedPreMovePrimaryLine,
  );
  final resolvedPreMoveSnapshot = preMoveCacheEntry?.evalSnapshot;

  final hasMaturePreMoveSnapshot =
      resolvedPreMoveSnapshot != null &&
      resolvedPreMoveSnapshot.depth >= minimumDepth;
  final hasMaturePreMovePrimaryLine =
      resolvedPreMovePrimaryLine != null &&
      resolvedPreMovePrimaryLine.depth >= minimumDepth;

  double? preMoveMoverWinProbability;
  double? preMoveMoverEvalPawns;
  var usedPreMoveFallback = false;
  if (hasMaturePreMoveSnapshot) {
    final whiteEvalPawns = resolvedPreMoveSnapshot.evalPawnsWhite;
    preMoveMoverEvalPawns = moverIsWhite ? whiteEvalPawns : -whiteEvalPawns;
    preMoveMoverWinProbability = centipawnsToWinProbability(
      preMoveMoverEvalPawns * 100,
    );
  } else if (hasMaturePreMovePrimaryLine) {
    final canReuseCapturedEval =
        capturedPreMovePrimaryLine != null &&
        resolvedPreMovePrimaryLine == capturedPreMovePrimaryLine &&
        capturedPreMovePrimaryLine.depth >= minimumDepth &&
        capturedPreMoveMoverWinProbability != null &&
        capturedPreMoveMoverEvalPawns != null;
    if (canReuseCapturedEval) {
      preMoveMoverWinProbability = capturedPreMoveMoverWinProbability;
      preMoveMoverEvalPawns = capturedPreMoveMoverEvalPawns;
    } else {
      preMoveMoverEvalPawns = resolvedPreMovePrimaryLine.eval / 100.0;
      preMoveMoverWinProbability = whiteCentipawnsToMoverWinProbability(
        moverIsWhite
            ? resolvedPreMovePrimaryLine.eval
            : -resolvedPreMovePrimaryLine.eval,
        moverIsWhite: moverIsWhite,
      );
      usedPreMoveFallback = true;
    }
  }

  final resolvedPostMoveLine = preferDeeperEngineLine(
    postMoveCacheEntry?.primaryLine,
    livePostMoveLine,
  );
  final resolvedPostMoveWhiteToMove = resolvedPostMoveLine == null
      ? null
      : identical(resolvedPostMoveLine, livePostMoveLine)
      ? livePostMoveWhiteToMove ?? postMoveCacheEntry?.evalSnapshot?.whiteToMove
      : postMoveCacheEntry?.evalSnapshot?.whiteToMove ??
            livePostMoveWhiteToMove;
  final hasMaturePostMoveLine =
      resolvedPostMoveLine != null &&
      resolvedPostMoveWhiteToMove != null &&
      resolvedPostMoveLine.depth >= minimumDepth;

  return MoveQualityEvidenceResolution(
    preMoveLines: preMoveLines,
    preMoveMoverWinProbability: preMoveMoverWinProbability,
    preMoveMoverEvalPawns: preMoveMoverEvalPawns,
    postMoveLine: resolvedPostMoveLine,
    postMoveWhiteToMove: resolvedPostMoveWhiteToMove,
    usedPreMoveFallback: usedPreMoveFallback,
    needsPreMoveConfirmation:
        !hasMaturePreMoveSnapshot && !hasMaturePreMovePrimaryLine,
    needsPostMoveConfirmation: !hasMaturePostMoveLine,
  );
}

List<EngineLine> _normalizedEngineLines(List<EngineLine> lines) {
  final normalized = List<EngineLine>.from(lines);
  normalized.sort((a, b) => a.multiPv.compareTo(b.multiPv));
  return normalized;
}

class EngineSearchResult {
  const EngineSearchResult({
    required this.request,
    required this.lines,
    required this.bestMove,
    required this.queuedAt,
    required this.completedAt,
    this.startedAt,
    this.firstInfoAt,
    this.timedOut = false,
    this.cancelled = false,
    this.cancelReason,
    this.failureReason,
  });

  final EngineRequestSpec request;
  final List<EngineLine> lines;
  final String? bestMove;
  final DateTime queuedAt;
  final DateTime? startedAt;
  final DateTime? firstInfoAt;
  final DateTime completedAt;
  final bool timedOut;
  final bool cancelled;
  final String? cancelReason;
  final String? failureReason;

  bool get succeeded => !timedOut && !cancelled && failureReason == null;
}

enum EngineTimelineEventType {
  queued,
  started,
  firstInfo,
  completed,
  cancelled,
  timedOut,
  staleOutputRejected,
  failed,
  backendExited,
  backendRestarted,
}

class EngineTimelineEvent {
  const EngineTimelineEvent({
    required this.type,
    required this.timestamp,
    this.request,
    this.detail,
  });

  final EngineTimelineEventType type;
  final DateTime timestamp;
  final EngineRequestSpec? request;
  final String? detail;
}

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

bool matchesRegisteredOpeningPrefix(
  List<EcoLine> ecoLines,
  List<String> moveTokens,
) {
  if (moveTokens.isEmpty) {
    return false;
  }

  for (final line in ecoLines) {
    if (line.moveTokens.length < moveTokens.length) {
      continue;
    }

    var matches = true;
    for (var index = 0; index < moveTokens.length; index++) {
      if (line.moveTokens[index] != moveTokens[index]) {
        matches = false;
        break;
      }
    }

    if (matches) {
      return true;
    }
  }

  return false;
}

String resolveRegisteredOpeningName({
  required Map<String, String> ecoOpenings,
  required List<EcoLine> ecoLines,
  required List<String> moveTokens,
}) {
  if (!matchesRegisteredOpeningPrefix(ecoLines, moveTokens)) {
    return '';
  }

  for (var len = moveTokens.length; len >= 1; len--) {
    final candidate = moveTokens.sublist(0, len).join(' ');
    final opening = ecoOpenings[candidate];
    if (opening != null && opening.isNotEmpty) {
      return opening;
    }
  }

  return '';
}
