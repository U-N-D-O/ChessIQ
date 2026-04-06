import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class _PuzzleEngineBackend {
  Future<void> start(void Function(String line) onOutput);
  void send(String command);
  Future<void> stop();
}

class _NullPuzzleEngineBackend extends _PuzzleEngineBackend {
  @override
  Future<void> start(void Function(String line) onOutput) async {}

  @override
  void send(String command) {}

  @override
  Future<void> stop() async {}
}

class _DesktopPuzzleEngineBackend extends _PuzzleEngineBackend {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;

  @override
  Future<void> start(void Function(String line) onOutput) async {
    _process = await Process.start('./engine/stockfish.exe', []);
    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onOutput);
  }

  @override
  void send(String command) => _process?.stdin.writeln(command);

  @override
  Future<void> stop() async {
    send('quit');
    await _stdoutSubscription?.cancel();
    _process?.kill();
    _process = null;
    _stdoutSubscription = null;
  }
}

class _IosPuzzleEngineBackend extends _PuzzleEngineBackend {
  static const _method = MethodChannel('com.chessiq/stockfish');
  static const _event = EventChannel('com.chessiq/stockfish_output');
  StreamSubscription<String>? _outputSubscription;

  @override
  Future<void> start(void Function(String line) onOutput) async {
    await _method.invokeMethod<void>('start');
    _outputSubscription = _event.receiveBroadcastStream().cast<String>().listen(
      onOutput,
    );
  }

  @override
  void send(String command) {
    _method.invokeMethod<void>('send', command);
  }

  @override
  Future<void> stop() async {
    await _method.invokeMethod<void>('stop');
    await _outputSubscription?.cancel();
    _outputSubscription = null;
  }
}

_PuzzleEngineBackend _createEngineBackend() {
  if (kIsWeb) return _NullPuzzleEngineBackend();
  if (Platform.isIOS) return _IosPuzzleEngineBackend();
  return _DesktopPuzzleEngineBackend();
}

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
  PuzzleEngineService() : _backend = _createEngineBackend();

  final _PuzzleEngineBackend _backend;
  Completer<void>? _uciReady;
  Completer<void>? _readyOk;
  Completer<PuzzleEngineAnalysis>? _pendingAnalysis;
  int _activeDepth = 20;
  bool _whiteToMove = true;
  String? _lastBestMove;
  double? _latestEvalWhitePawns;
  void Function(double evalWhitePawns)? _onEval;
  bool _started = false;

  Future<void> ensureStarted() async {
    if (_started) return;
    _uciReady = Completer<void>();
    _readyOk = Completer<void>();
    await _backend.start(_handleLine);
    _backend.send('uci');
    await _uciReady!.future.timeout(const Duration(seconds: 5));
    _backend.send('isready');
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
    _backend.send('stop');
    _pendingAnalysis?.complete(
      PuzzleEngineAnalysis(
        bestMove: _lastBestMove,
        evalWhitePawns: _latestEvalWhitePawns,
        depth: _activeDepth,
      ),
    );
    _activeDepth = depth;
    _whiteToMove = whiteToMove;
    _lastBestMove = null;
    _onEval = onEval;
    _pendingAnalysis = Completer<PuzzleEngineAnalysis>();
    _backend.send('position fen $fen');
    _backend.send('go depth $depth');
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
    await _backend.stop();
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

    _latestEvalWhitePawns = _whiteToMove ? eval : -eval;
    final callback = _onEval;
    if (callback != null && _latestEvalWhitePawns != null) {
      callback(_latestEvalWhitePawns!);
    }
  }
}
