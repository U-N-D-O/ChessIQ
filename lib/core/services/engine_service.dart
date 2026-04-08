import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef EngineOutputCallback = void Function(String line);

abstract class EngineService {
  Future<void> start(EngineOutputCallback onOutput);
  void send(String cmd);
  Future<void> stop();
}

abstract class _EngineBackend implements EngineService {
  @override
  Future<void> start(EngineOutputCallback onOutput);

  @override
  void send(String cmd);

  @override
  Future<void> stop();
}

class _NullEngineBackend extends _EngineBackend {
  @override
  Future<void> start(EngineOutputCallback onOutput) async {}

  @override
  void send(String cmd) {}

  @override
  Future<void> stop() async {}
}

class _DesktopEngineBackend extends _EngineBackend {
  Process? _process;
  StreamSubscription<String>? _sub;

  @override
  Future<void> start(EngineOutputCallback onOutput) async {
    _process = await Process.start('./engine/stockfish.exe', []);
    _sub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onOutput);
  }

  @override
  void send(String cmd) => _process?.stdin.writeln(cmd);

  @override
  Future<void> stop() async {
    send('quit');
    await _sub?.cancel();
    _process?.kill();
    _process = null;
    _sub = null;
  }
}

class _IosEngineBackend extends _EngineBackend {
  static const _method = MethodChannel('com.chessiq/stockfish');
  static const _event = EventChannel('com.chessiq/stockfish_output');
  StreamSubscription<dynamic>? _sub;

  @override
  Future<void> start(EngineOutputCallback onOutput) async {
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

_EngineBackend _createEngineBackend() {
  if (kIsWeb) return _NullEngineBackend();
  if (Platform.isIOS) return _IosEngineBackend();
  return _DesktopEngineBackend();
}

class _StockfishSessionCoordinator {
  _StockfishSessionCoordinator._();

  static final _StockfishSessionCoordinator instance =
      _StockfishSessionCoordinator._();

  _EngineBackend? _backend;
  String? _activeOwner;
  EngineOutputCallback? _onOutput;
  int _sessionToken = 0;
  Future<void> _pendingOperation = Future<void>.value();

  Future<void> acquire({
    required String owner,
    required EngineOutputCallback onOutput,
  }) {
    return _enqueue(() async {
      if (_backend != null && _activeOwner == owner) {
        _onOutput = onOutput;
        return;
      }

      await _disposeActiveSession();

      final backend = _createEngineBackend();
      final token = ++_sessionToken;
      _backend = backend;
      _activeOwner = owner;
      _onOutput = onOutput;

      try {
        await backend.start((line) {
          if (_sessionToken != token || _activeOwner != owner) {
            return;
          }
          _onOutput?.call(line);
        });
      } catch (_) {
        if (_sessionToken == token && _activeOwner == owner) {
          _backend = null;
          _activeOwner = null;
          _onOutput = null;
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
  CoordinatedEngineService({required this.owner});

  final String owner;

  @override
  Future<void> start(EngineOutputCallback onOutput) {
    return _StockfishSessionCoordinator.instance.acquire(
      owner: owner,
      onOutput: onOutput,
    );
  }

  @override
  void send(String cmd) {
    _StockfishSessionCoordinator.instance.send(owner: owner, command: cmd);
  }

  @override
  Future<void> stop() {
    return _StockfishSessionCoordinator.instance.release(owner);
  }
}

EngineService createEngineService({required String owner}) {
  return CoordinatedEngineService(owner: owner);
}
