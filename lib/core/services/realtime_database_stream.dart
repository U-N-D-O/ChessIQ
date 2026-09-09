import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Firebase REST event stream, using the same REST Auth identity as mutations.
/// Each subscription owns its connection and closes it immediately on cancel.
Stream<Map<String, dynamic>> watchRealtimeDatabase({
  required Future<Uri> Function() authenticatedUrl,
  http.Client Function()? clientFactory,
  Duration retryDelay = const Duration(seconds: 1),
}) {
  late StreamController<Map<String, dynamic>> controller;
  http.Client? client;
  Timer? retry;
  var cancelled = false;

  Future<void> connect() async {
    if (cancelled) return;
    final connection = (clientFactory ?? http.Client.new)();
    client = connection;
    try {
      final url = await authenticatedUrl();
      if (cancelled) return;
      final request = http.Request('GET', url)
        ..headers['Accept'] = 'text/event-stream';
      final response = await connection
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw StateError('Match stream returned ${response.statusCode}.');
      }
      final tree = RealtimeDatabaseTree();
      var event = '';
      final data = <String>[];
      await for (final line
          in response.stream
              .timeout(const Duration(seconds: 90))
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (cancelled) break;
        if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          data.add(line.substring(5).trimLeft());
        } else if (line.isEmpty) {
          if (event == 'cancel' || event == 'auth_revoked') {
            throw StateError('Match stream access interrupted ($event).');
          }
          if ((event == 'put' || event == 'patch') && data.isNotEmpty) {
            final payload = jsonDecode(data.join('\n')) as Map;
            final value = tree.apply(
              event,
              payload['path'] as String,
              payload['data'],
            );
            if (value != null) controller.add(value);
          }
          event = '';
          data.clear();
        }
      }
      if (!cancelled) throw StateError('Match stream disconnected.');
    } catch (error, stack) {
      if (!cancelled) controller.addError(error, stack);
    } finally {
      connection.close();
      if (!cancelled) retry = Timer(retryDelay, connect);
    }
  }

  controller = StreamController<Map<String, dynamic>>(
    onListen: connect,
    onCancel: () {
      cancelled = true;
      retry?.cancel();
      client?.close();
    },
  );
  return controller.stream;
}

/// Applies Firebase put/patch events, including nested paths and array nodes.
class RealtimeDatabaseTree {
  dynamic _value;

  Map<String, dynamic>? apply(String event, String path, dynamic data) {
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (event == 'put') {
      _value = _replace(_value, segments, data);
    } else if (event == 'patch' && data is Map) {
      for (final entry in data.entries) {
        _value = _replace(_value, [
          ...segments,
          ...entry.key.toString().split('/'),
        ], entry.value);
      }
    }
    return _value is Map ? Map<String, dynamic>.from(_value as Map) : null;
  }

  dynamic _replace(dynamic node, List<String> path, dynamic value) {
    if (path.isEmpty) return value;
    final map = node is Map
        ? Map<String, dynamic>.from(node)
        : node is List
        ? <String, dynamic>{for (var i = 0; i < node.length; i++) '$i': node[i]}
        : <String, dynamic>{};
    final key = path.first;
    final child = _replace(map[key], path.sublist(1), value);
    if (child == null) {
      map.remove(key);
    } else {
      map[key] = child;
    }
    return map;
  }
}
