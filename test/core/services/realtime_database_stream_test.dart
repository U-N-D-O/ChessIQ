import 'dart:async';
import 'dart:convert';

import 'package:chessiq/core/services/realtime_database_stream.dart';
import 'package:chessiq/features/vs_friend/models/remote_friend_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _StreamClient extends http.BaseClient {
  final events = StreamController<List<int>>();
  bool closed = false;
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(events.stream, 200);
  }

  @override
  void close() {
    closed = true;
    unawaited(events.close());
  }
}

void main() {
  test('nested patches preserve the board, avatars and move history', () {
    final tree = RealtimeDatabaseTree();
    tree.apply('put', '/', {
      'fen': 'original',
      'whiteAvatarId': 'normal-celicianmara',
      'moves': [
        {'ply': 0, 'uci': 'e2e4'},
      ],
      'clocks': {'whiteMsRemaining': 1000, 'blackMsRemaining': 1000},
    });
    final result = tree.apply('patch', '/', {
      'blackAvatarId': 'rare-agentnova',
      'clocks/whiteMsRemaining': 900,
      'moves/1': {'ply': 1, 'uci': 'e7e5'},
    })!;
    expect(result['fen'], 'original');
    expect(result['whiteAvatarId'], 'normal-celicianmara');
    expect(result['blackAvatarId'], 'rare-agentnova');
    expect(result['clocks'], {
      'whiteMsRemaining': 900,
      'blackMsRemaining': 1000,
    });
    expect((result['moves'] as Map)['0']['uci'], 'e2e4');
    expect((result['moves'] as Map)['1']['uci'], 'e7e5');
    expect(
      tree.apply('put', '/blackAvatarId', null)!.containsKey('blackAvatarId'),
      isFalse,
    );
  });

  test('root replacement on rematch clears the previous round', () {
    final tree = RealtimeDatabaseTree();
    tree.apply('put', '/', {
      'moves': [1, 2],
      'outcome': 'draw',
    });
    expect(tree.apply('put', '/', {'nextPly': 0}), {'nextPly': 0});
  });

  test(
    'stream delivers fragmented events immediately and closes on cancel',
    () async {
      final client = _StreamClient();
      final received = Completer<Map<String, dynamic>>();
      final subscription = watchRealtimeDatabase(
        authenticatedUrl: () async =>
            Uri.parse('https://example.test/match.json'),
        clientFactory: () => client,
      ).listen(received.complete);
      client.events.add(utf8.encode('event: put\r\ndata: {"path":"/","da'));
      client.events.add(utf8.encode('ta":{"nextPly":1}}\r\n\r\n'));
      expect(await received.future, {'nextPly': 1});
      expect(client.request!.headers['Accept'], 'text/event-stream');
      await subscription.cancel();
      expect(client.closed, isTrue);
    },
  );

  test(
    'reconnect obtains fresh authentication and a new root snapshot',
    () async {
      final clients = <_StreamClient>[];
      var authCalls = 0;
      final first = Completer<void>();
      final second = Completer<void>();
      final values = <Map<String, dynamic>>[];
      final subscription =
          watchRealtimeDatabase(
            authenticatedUrl: () async {
              authCalls++;
              return Uri.parse(
                'https://example.test/match.json?auth=$authCalls',
              );
            },
            retryDelay: const Duration(milliseconds: 5),
            clientFactory: () {
              final client = _StreamClient();
              clients.add(client);
              client.events.add(
                utf8.encode(
                  'event: put\ndata: {"path":"/","data":{"nextPly":${clients.length}}}\n\n',
                ),
              );
              return client;
            },
          ).listen((value) {
            values.add(value);
            if (values.length == 1) first.complete();
            if (values.length == 2) second.complete();
          }, onError: (Object _) {});
      await first.future;
      await clients.first.events.close();
      await second.future.timeout(const Duration(seconds: 2));
      expect(authCalls, 2);
      expect(values.last['nextPly'], 2);
      await subscription.cancel();
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test(
    'late responses cannot roll back moves but a new round can reset ply',
    () {
      RemoteFriendMatchSnapshot snapshot(int ply, int updated, int started) =>
          RemoteFriendMatchSnapshot.fromMap({
            'matchId': 'match',
            'nextPly': ply,
            'updatedAtMs': updated,
            'startedAtMs': started,
          });
      final current = snapshot(12, 1000, 100);
      expect(snapshot(11, 900, 100).isOlderThan(current), isTrue);
      expect(snapshot(11, 1000, 100).isOlderThan(current), isTrue);
      expect(snapshot(12, 1100, 100).isOlderThan(current), isFalse);
      expect(snapshot(0, 2000, 2000).isOlderThan(current), isFalse);
    },
  );
}
