import 'dart:convert';

import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:chessiq/features/vs_friend/models/remote_friend_models.dart';
import 'package:chessiq/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteFriendMutationResult {
  const RemoteFriendMutationResult({
    required this.success,
    required this.invite,
    required this.snapshot,
    this.reason,
  });

  factory RemoteFriendMutationResult.fromResultMap(
    Map<String, dynamic> result,
  ) {
    final payload = _parseRemoteFriendMutationPayload(result);
    return RemoteFriendMutationResult(
      success: result['success'] != false,
      reason: result['reason']?.toString().trim(),
      invite: payload.invite,
      snapshot: payload.snapshot,
    );
  }

  final bool success;
  final String? reason;
  final RemoteFriendInvite invite;
  final RemoteFriendMatchSnapshot snapshot;
}

class RemoteFriendMoveResult extends RemoteFriendMutationResult {
  const RemoteFriendMoveResult({
    required super.success,
    required super.invite,
    required super.snapshot,
    required this.acceptedMove,
    super.reason,
  });

  factory RemoteFriendMoveResult.fromResultMap(Map<String, dynamic> result) {
    final payload = _parseRemoteFriendMutationPayload(result);
    return RemoteFriendMoveResult(
      success: result['success'] != false,
      acceptedMove: result['acceptedMove'] == true,
      reason: result['reason']?.toString().trim(),
      invite: payload.invite,
      snapshot: payload.snapshot,
    );
  }

  final bool acceptedMove;
}

class RemoteFriendMatchMembership {
  const RemoteFriendMatchMembership({
    required this.matchId,
    required this.inviteCode,
    required this.status,
    required this.updatedAt,
  });

  final String matchId;
  final String inviteCode;
  final RemoteFriendMatchStatus status;
  final DateTime updatedAt;
}

class RemoteFriendService {
  RemoteFriendService._();

  static final RemoteFriendService instance = RemoteFriendService._();

  static const String _databaseUrl = kFirebaseRealtimeDatabaseUrl;
  static const String _cfBase =
      'https://us-central1-chessiq-89b45.cloudfunctions.net';
  static const String _createInviteFunction = 'createFriendMatchInvite';
  static const String _joinInviteFunction = 'joinFriendMatchInvite';
  static const String _submitMoveFunction = 'submitFriendMatchMove';
  static const String _actOnMatchFunction = 'actOnFriendMatch';

  Future<RemoteFriendMutationResult> createInvite({
    required RemoteFriendTimeControl timeControl,
    RemoteFriendSeatPreference seatPreference =
        RemoteFriendSeatPreference.random,
  }) async {
    final result = await _callFunction(_createInviteFunction, <String, dynamic>{
      'timeControl': timeControl.toMap(),
      'seatPreference': seatPreference.wireName,
    });
    return RemoteFriendMutationResult.fromResultMap(result);
  }

  Future<RemoteFriendMutationResult> joinInvite(String inviteCode) async {
    final result = await _callFunction(_joinInviteFunction, <String, dynamic>{
      'inviteCode': inviteCode.trim().toUpperCase(),
    });
    return RemoteFriendMutationResult.fromResultMap(result);
  }

  Future<RemoteFriendMatchSnapshot> fetchMatch(String matchId) async {
    final json = await _readAuthedJson('friend_matches/${matchId.trim()}');
    if (json == null) {
      throw StateError('Remote friend match not found.');
    }
    if (json is! Map) {
      throw StateError('Remote friend match payload was not a JSON object.');
    }
    final map = json.cast<String, dynamic>();
    map.putIfAbsent('matchId', () => matchId.trim());
    return RemoteFriendMatchSnapshot.fromMap(map);
  }

  Future<List<RemoteFriendMatchMembership>> fetchMyMatchMemberships() async {
    await FirebaseAuthService.instance.initialize();
    final uid = FirebaseAuthService.instance.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'Remote friend matches require an authenticated user id.',
      );
    }

    final json = await _readAuthedJson('friend_match_memberships/$uid');
    if (json == null) {
      return const <RemoteFriendMatchMembership>[];
    }
    if (json is! Map) {
      throw StateError(
        'Friend match membership payload was not a JSON object.',
      );
    }

    final memberships = <RemoteFriendMatchMembership>[];
    for (final entry in json.entries) {
      final rawValue = entry.value;
      if (rawValue is! Map) {
        continue;
      }
      final membership = rawValue.cast<String, dynamic>();
      memberships.add(
        RemoteFriendMatchMembership(
          matchId: entry.key,
          inviteCode: membership['inviteCode']?.toString().trim() ?? '',
          status: remoteFriendMatchStatusFromWire(
            membership['status']?.toString(),
          ),
          updatedAt: _dateTimeFromMilliseconds(
            (membership['updatedAtMs'] as num?)?.toInt() ?? 0,
          ),
        ),
      );
    }
    memberships.sort(
      (left, right) => right.updatedAt.compareTo(left.updatedAt),
    );
    return List<RemoteFriendMatchMembership>.unmodifiable(memberships);
  }

  Future<RemoteFriendMoveResult> submitMove({
    required String matchId,
    required String moveUci,
    int? expectedPly,
  }) async {
    final data = <String, dynamic>{
      'matchId': matchId.trim(),
      'moveUci': moveUci.trim().toLowerCase(),
    };
    if (expectedPly != null) {
      data['expectedPly'] = expectedPly;
    }
    final result = await _callFunction(_submitMoveFunction, data);
    return RemoteFriendMoveResult.fromResultMap(result);
  }

  Future<RemoteFriendMutationResult> actOnMatch({
    required String matchId,
    required RemoteFriendMatchAction action,
  }) async {
    final result = await _callFunction(_actOnMatchFunction, <String, dynamic>{
      'matchId': matchId.trim(),
      'action': action.wireName,
    });
    return RemoteFriendMutationResult.fromResultMap(result);
  }

  Future<Uri> _authedUrl(String path, [Map<String, String>? extra]) async {
    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      final authError = FirebaseAuthService.instance.lastError;
      final message = authError != null && authError.isNotEmpty
          ? 'Remote friend sync needs a valid sign-in. $authError'
          : 'Remote friend sync needs a valid sign-in. Reopen the app and try again.';
      throw Exception(message);
    }

    final uri = Uri.parse('$_databaseUrl/$path.json');
    final query = <String, String>{...?extra, 'auth': token};
    return uri.replace(queryParameters: query);
  }

  Future<dynamic> _readAuthedJson(String path) async {
    final response = await http
        .get(await _authedUrl(path))
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw Exception('Remote friend read timed out.');
          },
        );

    if (response.statusCode != 200) {
      throw Exception(
        _formatHttpFailure(
          action: 'read remote friend match state',
          response: response,
        ),
      );
    }

    final trimmedBody = response.body.trim();
    if (trimmedBody.isEmpty || trimmedBody == 'null') {
      return null;
    }
    return jsonDecode(trimmedBody);
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    await FirebaseAuthService.instance.initialize();
    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      final authError = FirebaseAuthService.instance.lastError;
      final message = authError != null && authError.isNotEmpty
          ? 'Remote friend sync needs a valid sign-in. $authError'
          : 'Remote friend sync needs a valid sign-in. Reopen the app and try again.';
      throw Exception(message);
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$_cfBase/$name');
    debugPrint('[RemoteFriendService] Calling Cloud Function: $uri');

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode({'data': data}))
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Cloud Function request timed out');
            },
          );

      Map<String, dynamic> body = const <String, dynamic>{};
      final trimmedBody = response.body.trim();
      final looksLikeJson =
          trimmedBody.startsWith('{') || trimmedBody.startsWith('[');
      if (trimmedBody.isNotEmpty && looksLikeJson) {
        final decoded = jsonDecode(trimmedBody);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      }

      if (response.statusCode != 200) {
        final error = body['error'];
        final message = error is Map<String, dynamic>
            ? (error['message']?.toString().trim() ?? '')
            : '';
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Remote friend service returned ${response.statusCode}.',
        );
      }

      return (body['result'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
    } catch (error) {
      debugPrint('[RemoteFriendService] Exception: $error');
      rethrow;
    }
  }

  String _formatHttpFailure({
    required String action,
    required http.Response response,
  }) {
    final trimmedBody = response.body.trim();
    final contentType = response.headers['content-type'] ?? '';
    final bodyPreview = trimmedBody.isEmpty
        ? ''
        : trimmedBody
              .replaceAll(RegExp(r'\s+'), ' ')
              .substring(
                0,
                trimmedBody.length > 160 ? 160 : trimmedBody.length,
              );

    if (contentType.contains('text/html')) {
      return 'ChessIQ could not $action. Firebase returned HTML '
          '(${response.statusCode}) instead of JSON. Preview: $bodyPreview';
    }

    if (bodyPreview.isNotEmpty) {
      return 'ChessIQ could not $action. Firebase returned '
          '${response.statusCode}: $bodyPreview';
    }

    return 'ChessIQ could not $action. Firebase returned '
        '${response.statusCode}.';
  }
}

class _ParsedRemoteFriendMutationPayload {
  const _ParsedRemoteFriendMutationPayload({
    required this.invite,
    required this.snapshot,
  });

  final RemoteFriendInvite invite;
  final RemoteFriendMatchSnapshot snapshot;
}

_ParsedRemoteFriendMutationPayload _parseRemoteFriendMutationPayload(
  Map<String, dynamic> result,
) {
  final inviteMap = result['invite'];
  final snapshotMap = result['snapshot'];
  if (inviteMap is! Map || snapshotMap is! Map) {
    throw StateError(
      'Remote friend mutation response is missing invite or snapshot data.',
    );
  }

  return _ParsedRemoteFriendMutationPayload(
    invite: RemoteFriendInvite.fromMap(inviteMap.cast<String, dynamic>()),
    snapshot: RemoteFriendMatchSnapshot.fromMap(
      snapshotMap.cast<String, dynamic>(),
    ),
  );
}

DateTime _dateTimeFromMilliseconds(int milliseconds) {
  return DateTime.fromMillisecondsSinceEpoch(milliseconds.clamp(0, 1 << 62));
}
