import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef EngineOutputCallback = void Function(String line);
typedef EngineTransportFactory = EngineTransport Function();

abstract class EngineService {
  Future<void> start(EngineOutputCallback onOutput);
  void send(String cmd);
  Future<void> stop();
}

abstract class EngineTransport implements EngineService {
  bool get isRunning;

  @override
  Future<void> start(EngineOutputCallback onOutput, {VoidCallback? onExit});

  @override
  void send(String cmd);

  @override
  Future<void> stop();
}

class _NullEngineBackend extends EngineTransport {
  @override
  bool get isRunning => true;

  @override
  Future<void> start(
    EngineOutputCallback onOutput, {
    VoidCallback? onExit,
  }) async {}

  @override
  void send(String cmd) {}

  @override
  Future<void> stop() async {}
}

class _DesktopEngineBackend extends EngineTransport {
  Process? _process;
  StreamSubscription<String>? _sub;
  StreamSubscription<String>? _stderrSub;
  VoidCallback? _onExit;

  @override
  bool get isRunning => _process != null;

  @override
  Future<void> start(
    EngineOutputCallback onOutput, {
    VoidCallback? onExit,
  }) async {
    final process = await Process.start('./engine/stockfish.exe', []);
    _process = process;
    _onExit = onExit;
    _sub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onOutput);
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});
    unawaited(process.stdin.done.catchError((_) {}));
    unawaited(
      process.exitCode
          .then((_) {
            if (identical(_process, process)) {
              _process = null;
            }
            _onExit?.call();
          })
          .catchError((_) {}),
    );
  }

  @override
  void send(String cmd) {
    final process = _process;
    if (process == null) {
      return;
    }

    try {
      process.stdin.writeln(cmd);
    } on ProcessException {
      _process = null;
    } on SocketException {
      _process = null;
    } on StateError {
      _process = null;
    }
  }

  @override
  Future<void> stop() async {
    final process = _process;
    _process = null;
    if (process == null) {
      await _sub?.cancel();
      _sub = null;
      await _stderrSub?.cancel();
      _stderrSub = null;
      _onExit = null;
      return;
    }

    try {
      process.stdin.writeln('quit');
    } on ProcessException {
      // Best-effort shutdown. The process may already be exiting.
    } on SocketException {
      // Best-effort shutdown. The pipe may already be closing.
    } on StateError {
      // Sink already closed.
    } on Object {
      // Best-effort shutdown. The process may already be exiting.
    }
    await _sub?.cancel();
    await _stderrSub?.cancel();
    try {
      process.kill();
    } on ProcessException {
      // Process already gone.
    }
    _sub = null;
    _stderrSub = null;
    _onExit = null;
  }
}

class _IosEngineBackend extends EngineTransport {
  static const _method = MethodChannel('com.chessiq/stockfish');
  static const _event = EventChannel('com.chessiq/stockfish_output');
  StreamSubscription<dynamic>? _sub;

  @override
  bool get isRunning => _sub != null;

  @override
  Future<void> start(
    EngineOutputCallback onOutput, {
    VoidCallback? onExit,
  }) async {
    await _method.invokeMethod<void>('start');
    _sub = _event.receiveBroadcastStream().cast<String>().listen(onOutput);
  }

  @override
  void send(String cmd) {
    unawaited(_method.invokeMethod<void>('send', cmd));
  }

  @override
  Future<void> stop() async {
    await _method.invokeMethod<void>('stop');
    await _sub?.cancel();
    _sub = null;
  }
}

class _AndroidEngineBackend extends EngineTransport {
  static const _method = MethodChannel('com.chessiq/stockfish');
  static const _event = EventChannel('com.chessiq/stockfish_output');
  StreamSubscription<dynamic>? _sub;

  @override
  bool get isRunning => _sub != null;

  @override
  Future<void> start(
    EngineOutputCallback onOutput, {
    VoidCallback? onExit,
  }) async {
    await _method.invokeMethod<void>('start');
    _sub = _event.receiveBroadcastStream().cast<String>().listen(onOutput);
  }

  @override
  void send(String cmd) {
    unawaited(_method.invokeMethod<void>('send', cmd));
  }

  @override
  Future<void> stop() async {
    await _method.invokeMethod<void>('stop');
    await _sub?.cancel();
    _sub = null;
  }
}

EngineTransport _createEngineTransport() {
  if (kIsWeb) return _NullEngineBackend();
  if (Platform.isIOS) return _IosEngineBackend();
  if (Platform.isAndroid) return _AndroidEngineBackend();
  return _DesktopEngineBackend();
}

class _StockfishSessionCoordinator {
  _StockfishSessionCoordinator({EngineTransportFactory? transportFactory})
    : _transportFactory = transportFactory ?? _createEngineTransport;

  static final _StockfishSessionCoordinator instance =
      _StockfishSessionCoordinator();

  final EngineTransportFactory _transportFactory;
  EngineTransport? _backend;
  String? _activeOwner;
  EngineOutputCallback? _onOutput;
  VoidCallback? _onExit;
  int _sessionToken = 0;
  Future<void> _pendingOperation = Future<void>.value();

  Future<void> acquire({
    required String owner,
    required EngineOutputCallback onOutput,
    VoidCallback? onExit,
  }) {
    return _enqueue(() async {
      if (_backend != null && _activeOwner == owner && _backend!.isRunning) {
        _onOutput = onOutput;
        _onExit = onExit;
        return;
      }

      await _disposeActiveSession();

      final backend = _transportFactory();
      final token = ++_sessionToken;
      _backend = backend;
      _activeOwner = owner;
      _onOutput = onOutput;
      _onExit = onExit;

      try {
        await backend.start(
          (line) {
            if (_sessionToken != token || _activeOwner != owner) {
              return;
            }
            _onOutput?.call(line);
          },
          onExit: () {
            if (_sessionToken != token || _activeOwner != owner) {
              return;
            }
            _backend = null;
            _onExit?.call();
          },
        );
      } catch (_) {
        if (_sessionToken == token && _activeOwner == owner) {
          _backend = null;
          _activeOwner = null;
          _onOutput = null;
          _onExit = null;
        }
        rethrow;
      }
    });
  }

  void send({required String owner, required String command}) {
    if (_activeOwner != owner) return;
    _backend?.send(command);
  }

  Future<void> release(String owner) {
    return _enqueue(() async {
      if (_activeOwner != owner) return;
      await _disposeActiveSession();
    });
  }

  Future<void> _disposeActiveSession() async {
    final backend = _backend;
    _backend = null;
    _activeOwner = null;
    _onOutput = null;
    _onExit = null;
    _sessionToken++;

    if (backend == null) return;
    try {
      await backend.stop();
    } catch (_) {
      // Best-effort teardown to avoid blocking the next session.
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final completer = Completer<void>();
    _pendingOperation = _pendingOperation.catchError((_) {}).then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

class CoordinatedEngineService extends EngineService {
  CoordinatedEngineService({required this.owner})
    : _coordinator = _StockfishSessionCoordinator.instance;

  CoordinatedEngineService.debug({
    required this.owner,
    EngineTransportFactory? transportFactory,
  }) : _coordinator = _StockfishSessionCoordinator(
         transportFactory: transportFactory,
       );

  final String owner;
  final _StockfishSessionCoordinator _coordinator;
  EngineOutputCallback? _rawOnOutput;
  bool _schedulerStarted = false;
  bool _stopping = false;
  Completer<void>? _schedulerStart;
  Completer<void>? _uciReady;
  Completer<void>? _readyBarrier;
  bool _drainingQueue = false;
  final List<_ScheduledSearchTask> _queuedTasks = <_ScheduledSearchTask>[];
  _ScheduledSearchTask? _barrierTask;
  _ScheduledSearchTask? _activeTask;
  void Function(EngineTimelineEvent event)? _onTimelineEvent;

  @override
  Future<void> start(EngineOutputCallback onOutput) {
    _rawOnOutput = onOutput;
    _schedulerStarted = false;
    return _coordinator.acquire(owner: owner, onOutput: onOutput);
  }

  @override
  void send(String cmd) {
    if (_schedulerStarted) {
      final normalized = cmd.trim();
      if (normalized == 'stop') {
        cancelSearches(reason: 'manual stop');
        _sendRaw('stop');
        return;
      }
      if (normalized == 'ucinewgame') {
        cancelSearches(reason: 'ucinewgame');
        _sendRaw('stop');
        _sendRaw(normalized);
        return;
      }
    }
    _sendRaw(cmd);
  }

  @override
  Future<void> stop() async {
    _stopping = true;
    cancelSearches(reason: 'service stopped');
    _barrierTask = null;
    _activeTask = null;
    _queuedTasks.clear();
    _schedulerStarted = false;
    _rawOnOutput = null;
    try {
      await _coordinator.release(owner);
    } finally {
      _stopping = false;
    }
  }

  Future<void> startScheduler({
    void Function(EngineTimelineEvent event)? onTimelineEvent,
  }) {
    _onTimelineEvent = onTimelineEvent ?? _onTimelineEvent;
    if (_schedulerStarted) {
      return Future<void>.value();
    }
    final pendingStart = _schedulerStart;
    if (pendingStart != null) {
      return pendingStart.future;
    }

    final completer = Completer<void>();
    _schedulerStart = completer;
    unawaited(() async {
      try {
        _rawOnOutput = null;
        await _coordinator.acquire(
          owner: owner,
          onOutput: _handleSchedulerLine,
          onExit: _handleBackendExit,
        );
        final uciReady = Completer<void>();
        _uciReady = uciReady;
        _sendRaw('uci');
        await uciReady.future.timeout(const Duration(seconds: 5));
        await _awaitReadyBarrier();
        _schedulerStarted = true;
        completer.complete();
        unawaited(_drainQueue());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_schedulerStart, completer)) {
          _schedulerStart = null;
        }
      }
    }());
    return completer.future;
  }

  EngineSearchHandle scheduleSearch(
    EngineRequestSpec request, {
    void Function(EngineSearchUpdate update)? onUpdate,
  }) {
    final task = _ScheduledSearchTask(request, onUpdate: onUpdate);
    _emitTimeline(EngineTimelineEventType.queued, request: request);

    _cancelSupersededQueuedTasks(
      request,
      reason: 'superseded by ${request.requestId}',
    );
    final activeTask = _activeTask;
    if (activeTask != null && _shouldPreempt(activeTask.request, request)) {
      _activeTask = null;
      _cancelTask(activeTask, 'preempted by ${request.requestId}');
      _sendRaw('stop');
    }
    final barrierTask = _barrierTask;
    if (barrierTask != null && _shouldPreempt(barrierTask.request, request)) {
      _barrierTask = null;
      _cancelTask(barrierTask, 'preempted by ${request.requestId}');
    }

    _queuedTasks.add(task);
    _queuedTasks.sort(_compareTasks);
    unawaited(_drainQueue());
    return task.handle;
  }

  void cancelSearches({
    Set<EngineRequestRole>? roles,
    String reason = 'canceled',
  }) {
    _queuedTasks.removeWhere((task) {
      if (!_matchesRole(task.request.role, roles)) {
        return false;
      }
      _cancelTask(task, reason);
      return true;
    });

    final barrierTask = _barrierTask;
    if (barrierTask != null && _matchesRole(barrierTask.request.role, roles)) {
      _barrierTask = null;
      _cancelTask(barrierTask, reason);
    }

    final activeTask = _activeTask;
    if (activeTask != null && _matchesRole(activeTask.request.role, roles)) {
      _activeTask = null;
      _cancelTask(activeTask, reason);
      _sendRaw('stop');
    }
  }

  Future<void> restartScheduler({String reason = 'restart'}) {
    return _restartSchedulerInternal(reason: reason);
  }

  void _sendRaw(String cmd) {
    _coordinator.send(owner: owner, command: cmd);
  }

  void _handleSchedulerLine(String line) {
    final rawHandler = _rawOnOutput;
    if (!_schedulerStarted && rawHandler != null) {
      rawHandler(line);
      return;
    }

    if (line == 'uciok') {
      _uciReady?.complete();
      _uciReady = null;
      return;
    }
    if (line == 'readyok') {
      _readyBarrier?.complete();
      _readyBarrier = null;
      return;
    }

    final activeTask = _activeTask;
    if (activeTask == null) {
      if (line.startsWith('info ') || line.startsWith('bestmove ')) {
        _emitTimeline(
          EngineTimelineEventType.staleOutputRejected,
          detail: line.split(' ').first,
        );
      }
      return;
    }

    if (line.startsWith('info ')) {
      _handleInfoLine(activeTask, line);
      return;
    }
    if (line.startsWith('bestmove ')) {
      _handleBestMoveLine(activeTask, line);
    }
  }

  void _handleInfoLine(_ScheduledSearchTask task, String line) {
    final depthMatch = RegExp(r'\bdepth (\d+)').firstMatch(line);
    final moveMatch = RegExp(
      r'\bpv ([a-h][1-8][a-h][1-8][nbrq]?)',
    ).firstMatch(line);
    if (depthMatch == null || moveMatch == null) {
      return;
    }

    final multiPvMatch = RegExp(r'\bmultipv (\d+)').firstMatch(line);
    final multiPv = int.tryParse(multiPvMatch?.group(1) ?? '1') ?? 1;
    if (multiPv > task.request.multiPv) {
      return;
    }

    final cpMatch = RegExp(r'\bscore cp (-?\d+)').firstMatch(line);
    final mateMatch = RegExp(r'\bscore mate (-?\d+)').firstMatch(line);
    final relativeCp = cpMatch != null
        ? int.parse(cpMatch.group(1)!)
        : mateMatch != null
        ? _mateScoreToCentipawns(int.parse(mateMatch.group(1)!))
        : 0;
    final depth = int.parse(depthMatch.group(1)!);
    final engineLine = EngineLine(
      moveMatch.group(1)!,
      relativeCp,
      depth,
      multiPv,
    );
    task.lines[multiPv] = engineLine;

    final snapshot = EvalSnapshot.fromRelativeScore(
      requestId: task.request.requestId,
      role: task.request.role,
      fen: task.request.fen,
      whiteToMove: task.request.whiteToMove,
      depth: depth,
      multiPv: multiPv,
      relativeEvalCp: relativeCp,
      timestamp: DateTime.now(),
    );
    if (task.firstInfoAt == null) {
      task.firstInfoAt = snapshot.timestamp;
      _emitTimeline(EngineTimelineEventType.firstInfo, request: task.request);
      if (task.request.firstInfoTimeout != null) {
        _armTaskTimeout(task, _remainingTaskTimeout(task));
      }
    }

    final update = EngineSearchUpdate(
      request: task.request,
      line: engineLine,
      snapshot: snapshot,
      timestamp: snapshot.timestamp,
    );
    task.pushUpdate(update);
  }

  void _handleBestMoveLine(_ScheduledSearchTask task, String line) {
    final bestMoveMatch = RegExp(r'^bestmove\s+(\S+)').firstMatch(line);
    final bestMove = bestMoveMatch?.group(1);
    _completeTask(
      task,
      bestMove: bestMove == null || bestMove == '(none)' ? null : bestMove,
    );
  }

  Future<void> _drainQueue() async {
    if (_drainingQueue || _activeTask != null || _barrierTask != null) {
      return;
    }
    _drainingQueue = true;
    try {
      await startScheduler(onTimelineEvent: _onTimelineEvent);
      while (_schedulerStarted &&
          _activeTask == null &&
          _barrierTask == null &&
          _queuedTasks.isNotEmpty) {
        final nextTask = _queuedTasks.removeAt(0);
        if (nextTask.isDone) {
          continue;
        }
        _barrierTask = nextTask;
        try {
          await _awaitReadyBarrier(sendStop: true);
        } catch (error) {
          if (identical(_barrierTask, nextTask)) {
            _barrierTask = null;
          }
          _failTask(nextTask, 'engine ready barrier failed: $error');
          await _restartSchedulerInternal(reason: 'ready barrier failed');
          continue;
        }
        if (!identical(_barrierTask, nextTask) || nextTask.isDone) {
          continue;
        }
        _barrierTask = null;
        _startTask(nextTask);
      }
    } finally {
      _drainingQueue = false;
    }
  }

  Future<void> _awaitReadyBarrier({bool sendStop = false}) async {
    final completer = Completer<void>();
    _readyBarrier = completer;
    if (sendStop) {
      _sendRaw('stop');
    }
    _sendRaw('isready');
    await completer.future.timeout(const Duration(seconds: 3));
  }

  void _armTaskTimeout(_ScheduledSearchTask task, Duration timeout) {
    task.timeoutTimer?.cancel();
    task.timeoutTimer = Timer(timeout, () {
      _handleTaskTimeout(task);
    });
  }

  Duration _remainingTaskTimeout(_ScheduledSearchTask task) {
    final startedAt = task.startedAt;
    if (startedAt == null) {
      return task.request.timeout;
    }
    final remaining =
        task.request.timeout - DateTime.now().difference(startedAt);
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  void _startTask(_ScheduledSearchTask task) {
    task.startedAt = DateTime.now();
    _activeTask = task;
    _emitTimeline(EngineTimelineEventType.started, request: task.request);
    for (final command in task.request.preCommands) {
      _sendRaw(command);
    }
    _sendRaw('setoption name MultiPV value ${task.request.multiPv}');
    _sendRaw('position fen ${task.request.fen}');
    _sendRaw(task.request.goCommand);
    _armTaskTimeout(
      task,
      task.request.firstInfoTimeout ?? task.request.timeout,
    );
  }

  void _handleTaskTimeout(_ScheduledSearchTask task) {
    if (!identical(_activeTask, task) || task.isDone) {
      return;
    }
    _emitTimeline(EngineTimelineEventType.timedOut, request: task.request);
    _activeTask = null;
    final timedOutWithoutInfo = task.firstInfoAt == null;
    _finishTask(task, timedOut: true);
    _sendRaw('stop');
    if (timedOutWithoutInfo) {
      unawaited(
        _restartSchedulerInternal(
          reason: 'timeout with no info for ${task.request.requestId}',
        ),
      );
    } else {
      unawaited(_drainQueue());
    }
  }

  Future<void> _restartSchedulerInternal({required String reason}) async {
    if (_stopping) {
      return;
    }
    _schedulerStarted = false;
    _emitTimeline(EngineTimelineEventType.backendRestarted, detail: reason);
    await _coordinator.release(owner);
    if (_stopping) {
      return;
    }
    await startScheduler(onTimelineEvent: _onTimelineEvent);
  }

  void _handleBackendExit() {
    if (_stopping) {
      return;
    }
    _schedulerStarted = false;
    _emitTimeline(EngineTimelineEventType.backendExited);

    final barrierTask = _barrierTask;
    _barrierTask = null;
    if (barrierTask != null) {
      _failTask(barrierTask, 'engine backend exited');
    }

    final activeTask = _activeTask;
    _activeTask = null;
    if (activeTask != null) {
      _failTask(activeTask, 'engine backend exited');
    }
    unawaited(_restartSchedulerInternal(reason: 'backend exited'));
  }

  void _completeTask(_ScheduledSearchTask task, {String? bestMove}) {
    if (!identical(_activeTask, task) || task.isDone) {
      return;
    }
    _activeTask = null;
    _finishTask(task, bestMove: bestMove);
    _emitTimeline(EngineTimelineEventType.completed, request: task.request);
    unawaited(_drainQueue());
  }

  void _cancelTask(_ScheduledSearchTask task, String reason) {
    if (task.isDone) {
      return;
    }
    _runCleanupCommands(task.request);
    _emitTimeline(
      EngineTimelineEventType.cancelled,
      request: task.request,
      detail: reason,
    );
    task.finish(
      EngineSearchResult(
        request: task.request,
        lines: task.sortedLines,
        bestMove: task.bestMove,
        queuedAt: task.queuedAt,
        startedAt: task.startedAt,
        firstInfoAt: task.firstInfoAt,
        completedAt: DateTime.now(),
        cancelled: true,
        cancelReason: reason,
      ),
    );
  }

  void _failTask(_ScheduledSearchTask task, String reason) {
    if (task.isDone) {
      return;
    }
    _runCleanupCommands(task.request);
    _emitTimeline(
      EngineTimelineEventType.failed,
      request: task.request,
      detail: reason,
    );
    task.finish(
      EngineSearchResult(
        request: task.request,
        lines: task.sortedLines,
        bestMove: task.bestMove,
        queuedAt: task.queuedAt,
        startedAt: task.startedAt,
        firstInfoAt: task.firstInfoAt,
        completedAt: DateTime.now(),
        failureReason: reason,
      ),
    );
  }

  void _finishTask(
    _ScheduledSearchTask task, {
    String? bestMove,
    bool timedOut = false,
  }) {
    if (task.isDone) {
      return;
    }
    _runCleanupCommands(task.request);
    task.bestMove = bestMove ?? task.bestMove;
    task.finish(
      EngineSearchResult(
        request: task.request,
        lines: task.sortedLines,
        bestMove: task.bestMove,
        queuedAt: task.queuedAt,
        startedAt: task.startedAt,
        firstInfoAt: task.firstInfoAt,
        completedAt: DateTime.now(),
        timedOut: timedOut,
      ),
    );
  }

  void _cancelSupersededQueuedTasks(
    EngineRequestSpec request, {
    required String reason,
  }) {
    _queuedTasks.removeWhere((task) {
      if (task.request.role != request.role) {
        return false;
      }
      _cancelTask(task, reason);
      return true;
    });
  }

  bool _shouldPreempt(EngineRequestSpec active, EngineRequestSpec next) {
    if (active.role == next.role) {
      return true;
    }
    return next.role.priority > active.role.priority;
  }

  bool _matchesRole(EngineRequestRole role, Set<EngineRequestRole>? roles) {
    return roles == null || roles.contains(role);
  }

  int _compareTasks(_ScheduledSearchTask left, _ScheduledSearchTask right) {
    final priority = right.request.role.priority.compareTo(
      left.request.role.priority,
    );
    if (priority != 0) {
      return priority;
    }
    return left.queuedAt.compareTo(right.queuedAt);
  }

  void _emitTimeline(
    EngineTimelineEventType type, {
    EngineRequestSpec? request,
    String? detail,
  }) {
    _onTimelineEvent?.call(
      EngineTimelineEvent(
        type: type,
        request: request,
        detail: detail,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _runCleanupCommands(EngineRequestSpec request) {
    for (final command in request.cleanupCommands) {
      _sendRaw(command);
    }
  }
}

int _mateScoreToCentipawns(int mateScore) {
  if (mateScore > 0) {
    return 10000;
  }
  if (mateScore < 0) {
    return -10000;
  }
  return 0;
}

class EngineSearchHandle {
  EngineSearchHandle._({
    required this.request,
    required Stream<EngineSearchUpdate> updates,
    required Future<EngineSearchResult> result,
    required void Function(String reason) onCancel,
  }) : _updates = updates,
       _result = result,
       _onCancel = onCancel;

  final EngineRequestSpec request;
  final Stream<EngineSearchUpdate> _updates;
  final Future<EngineSearchResult> _result;
  final void Function(String reason) _onCancel;

  Stream<EngineSearchUpdate> get updates => _updates;

  Future<EngineSearchResult> get result => _result;

  void cancel({String reason = 'canceled'}) {
    _onCancel(reason);
  }
}

class _ScheduledSearchTask {
  _ScheduledSearchTask(this.request, {this.onUpdate})
    : queuedAt = DateTime.now(),
      _updates = StreamController<EngineSearchUpdate>.broadcast(),
      _result = Completer<EngineSearchResult>();

  final EngineRequestSpec request;
  final void Function(EngineSearchUpdate update)? onUpdate;
  final DateTime queuedAt;
  final StreamController<EngineSearchUpdate> _updates;
  final Completer<EngineSearchResult> _result;
  final Map<int, EngineLine> lines = <int, EngineLine>{};
  DateTime? startedAt;
  DateTime? firstInfoAt;
  String? bestMove;
  Timer? timeoutTimer;

  EngineSearchHandle get handle => EngineSearchHandle._(
    request: request,
    updates: _updates.stream,
    result: _result.future,
    onCancel: (reason) {
      if (_result.isCompleted) {
        return;
      }
      finish(
        EngineSearchResult(
          request: request,
          lines: sortedLines,
          bestMove: bestMove,
          queuedAt: queuedAt,
          startedAt: startedAt,
          firstInfoAt: firstInfoAt,
          completedAt: DateTime.now(),
          cancelled: true,
          cancelReason: reason,
        ),
      );
    },
  );

  bool get isDone => _result.isCompleted;

  List<EngineLine> get sortedLines {
    final sorted = lines.values.toList();
    sorted.sort((a, b) => a.multiPv.compareTo(b.multiPv));
    return sorted;
  }

  void pushUpdate(EngineSearchUpdate update) {
    if (_result.isCompleted) {
      return;
    }
    _updates.add(update);
    onUpdate?.call(update);
  }

  void finish(EngineSearchResult result) {
    if (_result.isCompleted) {
      return;
    }
    timeoutTimer?.cancel();
    _result.complete(result);
    unawaited(_updates.close());
  }
}

CoordinatedEngineService createEngineService({required String owner}) {
  return CoordinatedEngineService(owner: owner);
}
