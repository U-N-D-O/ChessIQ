import 'package:chessiq/core/services/engine_service.dart';
import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preempts stale live analysis output before bot search', () async {
    late _FakeEngineTransport transport;
    var readyCount = 0;
    final timeline = <EngineTimelineEvent>[];
    final service = CoordinatedEngineService.debug(
      owner: 'analysis.test',
      transportFactory: () => transport = _FakeEngineTransport((cmd, fake) {
        if (cmd == 'uci') {
          fake.emit('uciok');
          return;
        }
        if (cmd == 'isready') {
          readyCount++;
          if (readyCount == 1) {
            fake.emit('readyok');
          }
        }
      }),
    );
    await service.startScheduler(onTimelineEvent: timeline.add);

    final live = service.scheduleSearch(
      const EngineRequestSpec(
        requestId: 'live-1',
        role: EngineRequestRole.liveAnalysis,
        fen: 'fen-live',
        whiteToMove: true,
        multiPv: 2,
        depth: 12,
        timeout: Duration(milliseconds: 250),
      ),
    );
    await _flushMicrotasks();
    transport.emit('readyok');
    await _flushMicrotasks();

    final bot = service.scheduleSearch(
      const EngineRequestSpec(
        requestId: 'bot-1',
        role: EngineRequestRole.botSearch,
        fen: 'fen-bot',
        whiteToMove: false,
        multiPv: 3,
        depth: 10,
        timeout: Duration(milliseconds: 250),
      ),
    );
    await _flushMicrotasks();

    transport.emit('info depth 12 multipv 1 score cp 42 pv e2e4');
    transport.emit('bestmove e2e4');
    await _flushMicrotasks();

    transport.emit('readyok');
    await _flushMicrotasks();
    transport.emit('info depth 10 multipv 1 score cp 35 pv e7e5');
    transport.emit('bestmove e7e5');

    final liveResult = await live.result;
    final botResult = await bot.result;

    expect(liveResult.cancelled, isTrue);
    expect(liveResult.cancelReason, contains('preempted by bot-1'));
    expect(botResult.succeeded, isTrue);
    expect(botResult.bestMove, 'e7e5');
    expect(botResult.lines.single.move, 'e7e5');
    expect(
      timeline.any(
        (event) => event.type == EngineTimelineEventType.staleOutputRejected,
      ),
      isTrue,
    );
  });

  test('times out missing output and recovers on the next request', () async {
    final transports = <_FakeEngineTransport>[];
    final service = CoordinatedEngineService.debug(
      owner: 'analysis.timeout',
      transportFactory: () {
        final transport = _FakeEngineTransport((cmd, fake) {
          if (cmd == 'uci') {
            fake.emit('uciok');
            return;
          }
          if (cmd == 'isready') {
            fake.emit('readyok');
          }
        });
        transports.add(transport);
        return transport;
      },
    );
    await service.startScheduler();

    final first = service.scheduleSearch(
      const EngineRequestSpec(
        requestId: 'live-timeout',
        role: EngineRequestRole.liveAnalysis,
        fen: 'fen-timeout',
        whiteToMove: true,
        multiPv: 1,
        depth: 8,
        timeout: Duration(milliseconds: 25),
      ),
    );
    final firstResult = await first.result;

    expect(firstResult.timedOut, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(transports.length, greaterThanOrEqualTo(2));

    final latestTransport = transports.last;
    final second = service.scheduleSearch(
      const EngineRequestSpec(
        requestId: 'live-recovered',
        role: EngineRequestRole.liveAnalysis,
        fen: 'fen-recovered',
        whiteToMove: true,
        multiPv: 1,
        depth: 8,
        timeout: Duration(milliseconds: 150),
      ),
    );
    await _flushMicrotasks();
    latestTransport.emit('info depth 8 multipv 1 score cp -18 pv g8f6');
    latestTransport.emit('bestmove g8f6');

    final secondResult = await second.result;
    expect(secondResult.succeeded, isTrue);
    expect(secondResult.bestMove, 'g8f6');
    expect(secondResult.lines.single.move, 'g8f6');
  });
}

Future<void> _flushMicrotasks() {
  return Future<void>.delayed(Duration.zero);
}

class _FakeEngineTransport implements EngineTransport {
  _FakeEngineTransport(this._onCommand);

  final void Function(String command, _FakeEngineTransport transport)
  _onCommand;
  EngineOutputCallback? _onOutput;
  VoidCallback? _onExit;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start(
    EngineOutputCallback onOutput, {
    VoidCallback? onExit,
  }) async {
    _running = true;
    _onOutput = onOutput;
    _onExit = onExit;
  }

  @override
  void send(String cmd) {
    _onCommand(cmd, this);
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  void emit(String line) {
    _onOutput?.call(line);
  }

  void exit() {
    _running = false;
    _onExit?.call();
  }
}
