import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:chessiq/features/analysis/models/move_quality.dart';
import 'package:flutter_test/flutter_test.dart';

EngineSearchUpdate _engineUpdate({
  required String requestId,
  required String fen,
  required bool whiteToMove,
  required int depth,
  required int evalCp,
  required String move,
  EngineRequestRole role = EngineRequestRole.liveAnalysis,
}) {
  final request = EngineRequestSpec(
    requestId: requestId,
    role: role,
    fen: fen,
    whiteToMove: whiteToMove,
    multiPv: 1,
    depth: depth,
    timeout: const Duration(milliseconds: 900),
  );
  final line = EngineLine(move, evalCp, depth, 1);
  return EngineSearchUpdate(
    request: request,
    line: line,
    snapshot: EvalSnapshot.fromRelativeScore(
      requestId: requestId,
      role: role,
      fen: fen,
      whiteToMove: whiteToMove,
      depth: depth,
      multiPv: 1,
      relativeEvalCp: evalCp,
      timestamp: DateTime.utc(2026, 4, 26, 12, depth),
    ),
    timestamp: DateTime.utc(2026, 4, 26, 12, depth),
  );
}

void main() {
  group('Engine request models', () {
    test('normalizes snapshot scores to white-side centipawns', () {
      final snapshot = EvalSnapshot.fromRelativeScore(
        requestId: 'analysis-1',
        role: EngineRequestRole.liveAnalysis,
        fen: 'fen white',
        whiteToMove: false,
        depth: 18,
        multiPv: 1,
        relativeEvalCp: 63,
        timestamp: DateTime.utc(2026, 4, 23),
      );

      expect(snapshot.evalCpWhite, -63);
      expect(snapshot.evalPawnsWhite, closeTo(-0.63, 1e-9));
      expect(snapshot.centipawnsForPov(false), 63);
      expect(snapshot.pawnsForPov(false), closeTo(0.63, 1e-9));
    });

    test('builds go command with searchmoves for explicit requests', () {
      const request = EngineRequestSpec(
        requestId: 'confirm-1',
        role: EngineRequestRole.backgroundConfirmation,
        fen: 'fen black',
        whiteToMove: true,
        multiPv: 2,
        depth: 12,
        timeout: Duration(milliseconds: 900),
        searchMoves: <String>['e2e4', 'd2d4'],
      );

      expect(request.goCommand, 'go depth 12 searchmoves e2e4 d2d4');
    });
  });

  group('Position analysis cache', () {
    test('keeps deepest primary evidence and richest matching line set', () {
      final shallow = _engineUpdate(
        requestId: 'live-1',
        fen: 'fen cache',
        whiteToMove: true,
        depth: 8,
        evalCp: 34,
        move: 'e2e4',
      );
      final deep = _engineUpdate(
        requestId: 'live-2',
        fen: 'fen cache',
        whiteToMove: true,
        depth: 12,
        evalCp: 48,
        move: 'd2d4',
      );
      final regressed = _engineUpdate(
        requestId: 'live-3',
        fen: 'fen cache',
        whiteToMove: true,
        depth: 6,
        evalCp: 21,
        move: 'g1f3',
      );

      final entry = const PositionAnalysisCacheEntry(fen: 'fen cache')
          .mergedWithPrimaryUpdate(shallow)
          .mergedWithPrimaryUpdate(deep)
          .mergedWithPrimaryUpdate(regressed)
          .mergedWithAnalysisLines(<EngineLine>[
            EngineLine('d2d4', 48, 12, 1),
            EngineLine('e2e4', 31, 12, 2),
          ])
          .mergedWithAnalysisLines(<EngineLine>[EngineLine('g1f3', 21, 6, 1)]);

      expect(entry.evalSnapshot, isNotNull);
      expect(entry.evalSnapshot!.depth, 12);
      expect(entry.primaryLine, isNotNull);
      expect(entry.primaryLine!.move, 'd2d4');
      expect(entry.primaryLine!.depth, 12);
      expect(entry.analysisDepth, 12);
      expect(entry.analysisLines, hasLength(2));
      expect(entry.analysisLines.first.move, 'd2d4');
    });
  });

  group('Move quality evidence resolution', () {
    test(
      'defers publication until same-fen pre-move evidence is confirmed',
      () {
        final postMoveCache = const PositionAnalysisCacheEntry(fen: 'fen post')
            .mergedWithPrimaryUpdate(
              _engineUpdate(
                requestId: 'post-1',
                fen: 'fen post',
                whiteToMove: false,
                depth: 10,
                evalCp: -22,
                move: 'e7e5',
                role: EngineRequestRole.backgroundConfirmation,
              ),
            );

        final unresolved = resolveMoveQualityEvidence(
          moverIsWhite: true,
          capturedPreMoveLines: const <EngineLine>[],
          capturedPreMoveMoverWinProbability: null,
          capturedPreMoveMoverEvalPawns: null,
          preMoveCacheEntry: null,
          livePostMoveLine: null,
          livePostMoveWhiteToMove: null,
          postMoveCacheEntry: postMoveCache,
          minimumDepth: 10,
        );

        expect(unresolved.isReadyToPublish, isFalse);
        expect(unresolved.needsPreMoveConfirmation, isTrue);
        expect(unresolved.needsPostMoveConfirmation, isFalse);

        final preMoveCache = const PositionAnalysisCacheEntry(fen: 'fen pre')
            .mergedWithPrimaryUpdate(
              _engineUpdate(
                requestId: 'pre-1',
                fen: 'fen pre',
                whiteToMove: true,
                depth: 10,
                evalCp: 55,
                move: 'd2d4',
                role: EngineRequestRole.backgroundConfirmation,
              ),
            );

        final resolved = resolveMoveQualityEvidence(
          moverIsWhite: true,
          capturedPreMoveLines: const <EngineLine>[],
          capturedPreMoveMoverWinProbability: null,
          capturedPreMoveMoverEvalPawns: null,
          preMoveCacheEntry: preMoveCache,
          livePostMoveLine: null,
          livePostMoveWhiteToMove: null,
          postMoveCacheEntry: postMoveCache,
          minimumDepth: 10,
        );

        expect(resolved.isReadyToPublish, isTrue);
        expect(resolved.needsPreMoveConfirmation, isFalse);
        expect(resolved.needsPostMoveConfirmation, isFalse);
        expect(resolved.usedPreMoveFallback, isFalse);
        expect(resolved.preMoveMoverEvalPawns, closeTo(0.55, 1e-9));
        expect(resolved.preMoveMoverWinProbability, greaterThan(0.5));
        expect(resolved.postMoveLine, isNotNull);
        expect(resolved.postMoveWhiteToMove, isFalse);
      },
    );
  });

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

  group('Opening prefix helpers', () {
    final ecoLines = <EcoLine>[
      EcoLine(
        name: 'King Pawn Opening',
        normalizedMoves: 'e4',
        moveTokens: const <String>['e4'],
        isGambit: false,
      ),
      EcoLine(
        name: 'Open Game',
        normalizedMoves: 'e4 e5',
        moveTokens: const <String>['e4', 'e5'],
        isGambit: false,
      ),
      EcoLine(
        name: 'Italian Game',
        normalizedMoves: 'e4 e5 nf3 nc6 bc4',
        moveTokens: const <String>['e4', 'e5', 'nf3', 'nc6', 'bc4'],
        isGambit: false,
      ),
      EcoLine(
        name: 'Ruy Lopez Berlin Defense',
        normalizedMoves: 'e4 e5 nf3 nc6 bb5 nf6 o-o nxe4',
        moveTokens: const <String>[
          'e4',
          'e5',
          'nf3',
          'nc6',
          'bb5',
          'nf6',
          'o-o',
          'nxe4',
        ],
        isGambit: false,
      ),
    ];
    final ecoOpenings = <String, String>{
      'e4': 'King Pawn Opening',
      'e4 e5': 'Open Game',
      'e4 e5 nf3': 'King Knight Opening',
      'e4 e5 nf3 nc6': 'Three Knights Game',
    };

    test('matches only full registered opening prefixes', () {
      expect(
        matchesRegisteredOpeningPrefix(ecoLines, const <String>[
          'e4',
          'e5',
          'nf3',
        ]),
        isTrue,
      );
      expect(
        matchesRegisteredOpeningPrefix(ecoLines, const <String>['e4', 'a5']),
        isFalse,
      );
    });

    test('matches registered opening prefixes beyond six plies', () {
      expect(
        matchesRegisteredOpeningPrefix(ecoLines, const <String>[
          'e4',
          'e5',
          'nf3',
          'nc6',
          'bb5',
          'nf6',
          'o-o',
        ]),
        isTrue,
      );
    });

    test('does not fall back to shorter opening names after a deviation', () {
      expect(
        resolveRegisteredOpeningName(
          ecoOpenings: ecoOpenings,
          ecoLines: ecoLines,
          moveTokens: const <String>['e4', 'e5', 'h4'],
        ),
        isEmpty,
      );
    });

    test('keeps the deepest exact registered name while still on-book', () {
      expect(
        resolveRegisteredOpeningName(
          ecoOpenings: ecoOpenings,
          ecoLines: ecoLines,
          moveTokens: const <String>['e4', 'e5', 'nf3', 'nc6', 'bc4'],
        ),
        'Three Knights Game',
      );
    });
  });
}
