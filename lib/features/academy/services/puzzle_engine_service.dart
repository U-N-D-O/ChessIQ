import 'dart:async';

import 'package:chessiq/core/services/engine_service.dart';

class PuzzleEngineAnalysis {
  const PuzzleEngineAnalysis({
    required this.bestMove,
    required this.evalWhitePawns,
    required this.depth,
  });

  final String? bestMove;
  final double? evalWhitePawns;
  final int depth;
}

class PuzzleEngineService {
  PuzzleEngineService()
    : _engine = createEngineService(owner: _academyPuzzleEngineOwner);

  static const String _academyPuzzleEngineOwner = 'academy.puzzle';

  final EngineService _engine;
  Completer<void>? _uciReady;
  Completer<void>? _readyOk;
  Completer<PuzzleEngineAnalysis>? _pendingAnalysis;
  int _activeDepth = 20;
  String? _lastBestMove;
  double? _latestEvalWhitePawns;
  bool _whiteToMove = true; // Added variable to track turn perspective
  void Function(double evalWhitePawns)? _onEval;
  bool _started = false;

  Future<void> ensureStarted() async {
    if (_started) return;
    _uciReady = Completer<void>();
    _readyOk = Completer<void>();
    await _engine.start(_handleLine);
    _engine.send('uci');
    await _uciReady!.future.timeout(const Duration(seconds: 5));
    _engine.send('isready');
    await _readyOk!.future.timeout(const Duration(seconds: 5));
    _started = true;
  }

  Future<PuzzleEngineAnalysis> analyzePosition(
    String fen, {
    required bool whiteToMove,
    int depth = 20,
    void Function(double evalWhitePawns)? onEval,
  }) async {
    await ensureStarted();
    _engine.send('stop');
    _pendingAnalysis?.complete(
      PuzzleEngineAnalysis(
        bestMove: _lastBestMove,
        evalWhitePawns: _latestEvalWhitePawns,
        depth: _activeDepth,
      ),
    );
    _whiteToMove = whiteToMove; // Save the perspective for the engine output
    _activeDepth = depth;
    _lastBestMove = null;
    _onEval = onEval;
    _pendingAnalysis = Completer<PuzzleEngineAnalysis>();
    _engine.send('position fen $fen');
    _engine.send('go depth $depth');
    return _pendingAnalysis!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => PuzzleEngineAnalysis(
        bestMove: _lastBestMove,
        evalWhitePawns: _latestEvalWhitePawns,
        depth: depth,
      ),
    );
  }

  Future<void> dispose() async {
    _started = false;
    _pendingAnalysis = null;
    await _engine.stop();
  }

  void _handleLine(String line) {
    if (line == 'uciok') {
      _uciReady?.complete();
      return;
    }
    if (line == 'readyok') {
      _readyOk?.complete();
      return;
    }
    if (line.startsWith('info ')) {
      _parseInfoLine(line);
      return;
    }
    if (line.startsWith('bestmove ')) {
      final segments = line.split(' ');
      _lastBestMove = segments.length > 1 && segments[1] != '(none)'
          ? segments[1]
          : null;
      _pendingAnalysis?.complete(
        PuzzleEngineAnalysis(
          bestMove: _lastBestMove,
          evalWhitePawns: _latestEvalWhitePawns,
          depth: _activeDepth,
        ),
      );
      _pendingAnalysis = null;
    }
  }

  void _parseInfoLine(String line) {
    final match = RegExp(r'score (cp|mate) (-?\d+)').firstMatch(line);
    if (match == null) return;
    final kind = match.group(1);
    final rawValue = int.tryParse(match.group(2) ?? '');
    if (rawValue == null) return;

    double eval;
    if (kind == 'mate') {
      eval = rawValue.isNegative ? -12.0 : 12.0;
    } else {
      eval = rawValue / 100.0;
    }

    // Engine evaluations are always from the perspective of the side to move.
    // We flip the evaluation here if it's Black's turn to make it absolute for White.
    if (!_whiteToMove) {
      eval = -eval;
    }

    _latestEvalWhitePawns = eval;
    final callback = _onEval;
    if (callback != null && _latestEvalWhitePawns != null) {
      callback(_latestEvalWhitePawns!);
    }
  }
}
