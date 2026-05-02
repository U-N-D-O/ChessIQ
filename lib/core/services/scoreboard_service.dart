import 'dart:convert';

import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum HandleAvailabilityStatus {
  available,
  taken,
  renameRequired,
  verificationUnavailable,
}

class DeleteProfileResult {
  const DeleteProfileResult({required this.authDeleted});

  final bool authDeleted;
}

/// Scoreboard service – traffic-minimised and authenticated.
///
/// **Writes** go through the `submitAcademyScoreV2` Cloud Function so that
/// the RTDB security rules can block all direct client writes.
///
/// **Reads** go directly to RTDB (public path) with an optional auth token
/// attached when one is available.
///
/// Cache short-circuits write calls when score/handle/country are unchanged.
class ScoreboardService {
  ScoreboardService._();

  static final ScoreboardService instance = ScoreboardService._();

  static const String _databaseUrl = kFirebaseRealtimeDatabaseUrl;
  static const String _globalPath = 'academy_scoreboard/global';
  static const String _countryRoot = 'academy_scoreboard/by_country';
  static const String _submitAcademyScoreFunction = 'submitAcademyScoreV2';
  static const String _submitAcademyScoreFallbackFunction =
      'submitAcademyScore';
  static const String _checkHandleAvailabilityFunction =
      'checkHandleAvailabilityV2';
  static const String _checkHandleAvailabilityFallbackFunction =
      'checkHandleAvailability';
  static const String _moderatedHandlePrefix = 'ACADEMY_HANDLE_MODERATED:';

  // Cloud Function base URL (project: chessiq-89b45, region: us-central1)
  static const String _cfBase =
      'https://us-central1-chessiq-89b45.cloudfunctions.net';

  // SharedPreferences cache keys
  static const String _prefHandle = 'sb_last_handle';
  static const String _prefCountry = 'sb_last_country';
  static const String _prefScore = 'sb_last_score';

  String? _lastFunctionError;

  String? get lastFunctionError => _lastFunctionError;

  String _handleKey(String handle) {
    final normalized = handle.trim().isEmpty
        ? 'unknown_player'
        : handle.trim().toLowerCase();
    return Uri.encodeComponent(
      normalized.replaceAll(RegExp(r'[^a-z0-9_\- ]'), '_').replaceAll(' ', '_'),
    );
  }

  String _countryKey(String country) {
    final normalized = country.trim().isEmpty ? 'Unknown' : country.trim();
    return Uri.encodeComponent(
      normalized.replaceAll(RegExp(r'[.#$\[\]/]'), '_'),
    );
  }

  bool _isMissingFunctionError(String? message) {
    final normalized = (message ?? '').toLowerCase();
    return normalized.contains('returned html (404)') ||
        normalized.contains('function error 404') ||
        normalized.contains('not found') ||
        normalized.contains('endpoint may be unavailable');
  }

  String _stripModeratedHandlePrefix(String message) {
    final index = message.toUpperCase().indexOf(_moderatedHandlePrefix);
    if (index < 0) {
      return message.replaceFirst('Exception: ', '').trim();
    }
    return message
        .substring(index + _moderatedHandlePrefix.length)
        .replaceFirst('Exception: ', '')
        .trim();
  }

  Future<Map<String, dynamic>> _callPreferredFunction({
    required String primary,
    required String fallback,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _callFunction(primary, data);
    } catch (error) {
      final message = _lastFunctionError ?? error.toString();
      if (!_isMissingFunctionError(message)) {
        rethrow;
      }
      return _callFunction(fallback, data);
    }
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_databaseUrl/$path.json');
    if (query == null) return uri;
    return uri.replace(queryParameters: query);
  }

  /// Adds the current auth token to an RTDB URL so authenticated rules apply.
  Future<Uri> _authedUrl(String path, [Map<String, String>? extra]) async {
    final token = await FirebaseAuthService.instance.getIdToken();
    final query = <String, String>{...?extra};
    if (token != null) query['auth'] = token;
    return _url(path, query.isEmpty ? null : query);
  }

  /// Calls a Firebase callable Cloud Function with the current ID token.
  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    _lastFunctionError = null;
    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      final authError = FirebaseAuthService.instance.lastError;
      final message = authError != null && authError.isNotEmpty
          ? 'Authentication required before scoreboard registration. $authError'
          : 'Authentication required before scoreboard registration. Ensure anonymous auth is enabled in Firebase Auth > Sign-in method and try again.';
      _lastFunctionError = message;
      throw Exception(message);
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse('$_cfBase/$name');
    debugPrint('[ScoreboardService] Calling Cloud Function: $uri');

    try {
      final bodyPayload = jsonEncode({'data': data});
      http.Response? response;
      Object? lastTimeoutError;

      // Cold starts on newly deployed functions can exceed short client timeouts,
      // so we give one retry before surfacing an error to the profile dialog.
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          response = await http
              .post(uri, headers: headers, body: bodyPayload)
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () {
                  throw Exception('Cloud Function request timed out');
                },
              );
          break;
        } catch (e) {
          if (e.toString().toLowerCase().contains('timed out') &&
              attempt == 0) {
            lastTimeoutError = e;
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        throw lastTimeoutError ?? Exception('Cloud Function request timed out');
      }

      Map<String, dynamic> body = const <String, dynamic>{};
      final trimmedBody = response.body.trim();
      final contentType = response.headers['content-type'] ?? '';
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
            ? (error['message']?.toString() ?? '')
            : '';
        final bodyPreview = trimmedBody.isEmpty
            ? ''
            : trimmedBody
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .substring(
                    0,
                    trimmedBody.length > 160 ? 160 : trimmedBody.length,
                  );
        final errorMsg = message.isNotEmpty
            ? message
            : contentType.contains('text/html')
            ? 'Cloud Function returned HTML (${response.statusCode}) instead of JSON. The endpoint may be unavailable, blocked by a firewall/proxy, or serving an error page. Preview: $bodyPreview'
            : bodyPreview.isNotEmpty
            ? 'Cloud Function error ${response.statusCode}: $bodyPreview'
            : 'Cloud Function error ${response.statusCode}';
        _lastFunctionError = errorMsg;
        debugPrint('[ScoreboardService] Error: $errorMsg');
        throw Exception(errorMsg);
      }
      if (trimmedBody.isNotEmpty && !looksLikeJson) {
        final preview = trimmedBody
            .replaceAll(RegExp(r'\s+'), ' ')
            .substring(0, trimmedBody.length > 160 ? 160 : trimmedBody.length);
        final errorMsg = contentType.contains('text/html')
            ? 'Cloud Function returned HTML instead of JSON. The endpoint may be unavailable, blocked by a firewall/proxy, or serving an error page. Preview: $preview'
            : 'Cloud Function returned a non-JSON response. Preview: $preview';
        _lastFunctionError = errorMsg;
        throw Exception(errorMsg);
      }
      debugPrint('[ScoreboardService] Success');
      return (body['result'] as Map<String, dynamic>?) ?? const {};
    } catch (e) {
      _lastFunctionError ??= e.toString();
      debugPrint('[ScoreboardService] Exception: $e');
      rethrow;
    }
  }

  Future<void> submitScore({
    required String handle,
    required String country,
    required int score,
    required String title,
  }) async {
    try {
      final trimmedHandle = handle.trim().isEmpty
          ? 'Unknown Player'
          : handle.trim();
      final handleKey = _handleKey(trimmedHandle);
      final normalizedCountry = country.trim().isEmpty
          ? 'Unknown'
          : country.trim();

      // ── Skip write if nothing changed since last submission ────────────────
      final prefs = await SharedPreferences.getInstance();
      final cachedHandle = prefs.getString(_prefHandle);
      final cachedCountry = prefs.getString(_prefCountry);
      final cachedScore = prefs.getInt(_prefScore);

      if (cachedHandle == handleKey &&
          cachedCountry == normalizedCountry &&
          cachedScore == score) {
        return;
      }

      await _callPreferredFunction(
        primary: _submitAcademyScoreFunction,
        fallback: _submitAcademyScoreFallbackFunction,
        data: {
          'handle': trimmedHandle,
          'country': normalizedCountry,
          'score': score,
          'title': title,
        },
      );

      // ── Persist cache ─────────────────────────────────────────────────────
      await Future.wait([
        prefs.setString(_prefHandle, handleKey),
        prefs.setString(_prefCountry, normalizedCountry),
        prefs.setInt(_prefScore, score),
      ]);
    } catch (e) {
      debugPrint('Scoreboard submit failed: $e');
      // Best-effort; don't surface leaderboard errors to the user.
    }
  }

  /// Atomically reserves/updates a player's leaderboard profile on backend.
  ///
  /// This calls `submitAcademyScoreV2` directly so nickname ownership is
  /// validated server-side before the app accepts the profile locally.
  Future<HandleAvailabilityStatus> registerProfile({
    required String handle,
    required String country,
    required int score,
    required String title,
  }) async {
    final trimmedHandle = handle.trim();
    if (trimmedHandle.isEmpty) {
      return HandleAvailabilityStatus.verificationUnavailable;
    }

    final normalizedCountry = country.trim().isEmpty
        ? 'Unknown'
        : country.trim();

    try {
      await _callPreferredFunction(
        primary: _submitAcademyScoreFunction,
        fallback: _submitAcademyScoreFallbackFunction,
        data: {
          'handle': trimmedHandle,
          'country': normalizedCountry,
          'score': score,
          'title': title,
        },
      );
      return HandleAvailabilityStatus.available;
    } catch (e) {
      final rawMessage = _lastFunctionError ?? e.toString();
      if (rawMessage.toUpperCase().contains(_moderatedHandlePrefix)) {
        _lastFunctionError = _stripModeratedHandlePrefix(rawMessage);
        return HandleAvailabilityStatus.renameRequired;
      }

      final message = rawMessage.toLowerCase();
      if (message.contains('already-exists') ||
          message.contains('already taken') ||
          message.contains('nickname is already taken')) {
        return HandleAvailabilityStatus.taken;
      }
      _lastFunctionError ??= rawMessage;
      return HandleAvailabilityStatus.verificationUnavailable;
    }
  }

  Future<HandleAvailabilityStatus> checkHandleAvailability({
    required String handle,
    String? currentHandle,
  }) async {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) {
      return HandleAvailabilityStatus.verificationUnavailable;
    }

    // Primary: Cloud Function checks the private handle_registry node.
    try {
      final result = await _callPreferredFunction(
        primary: _checkHandleAvailabilityFunction,
        fallback: _checkHandleAvailabilityFallbackFunction,
        data: {'handle': trimmed},
      );
      if (result['moderated'] == true) {
        return HandleAvailabilityStatus.renameRequired;
      }
      final available = result['available'];
      if (available is bool) {
        final normalizedRequested = trimmed.toLowerCase();
        final normalizedCurrent = currentHandle?.trim().toLowerCase();
        if (available &&
            normalizedCurrent != null &&
            normalizedRequested == normalizedCurrent) {
          return HandleAvailabilityStatus.available;
        }
        return available
            ? HandleAvailabilityStatus.available
            : HandleAvailabilityStatus.taken;
      }
      return HandleAvailabilityStatus.verificationUnavailable;
    } catch (_) {
      // Fallback: public scoreboard read (works before CF is deployed).
      try {
        final requestedKey = _handleKey(trimmed);
        final uri = await _authedUrl('$_globalPath/$requestedKey');
        final response = await http.get(uri);
        if (response.statusCode != 200) {
          return HandleAvailabilityStatus.verificationUnavailable;
        }
        final decoded = jsonDecode(response.body);
        return decoded == null
            ? HandleAvailabilityStatus.available
            : HandleAvailabilityStatus.taken;
      } catch (_) {
        return HandleAvailabilityStatus.verificationUnavailable;
      }
    }
  }

  Future<bool> isHandleAvailable({
    required String handle,
    String? currentHandle,
  }) async {
    return await checkHandleAvailability(
          handle: handle,
          currentHandle: currentHandle,
        ) ==
        HandleAvailabilityStatus.available;
  }

  Future<DeleteProfileResult> deleteProfile({
    bool deleteAnonymousIdentity = true,
  }) async {
    _lastFunctionError = null;

    final result = await _callFunction('deleteAcademyProfile', {
      'deleteAnonymousAuth': deleteAnonymousIdentity,
    });

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_prefHandle),
      prefs.remove(_prefCountry),
      prefs.remove(_prefScore),
    ]);

    final authDeleted = result['authDeleted'] == true;
    if (deleteAnonymousIdentity && authDeleted) {
      await FirebaseAuthService.instance.rotateAnonymousIdentity();
    }

    return DeleteProfileResult(authDeleted: authDeleted);
  }

  Future<List<LeaderboardEntry>> fetchTopScores({
    String? country,
    int limit = 10,
  }) async {
    _lastFunctionError = null;
    try {
      final path = country == null || country.trim().isEmpty
          ? _globalPath
          : '$_countryRoot/${_countryKey(country)}';
      final indexedUri = await _authedUrl(path, {
        'orderBy': jsonEncode('score'),
        'limitToLast': '$limit',
      });
      var response = await http.get(indexedUri);

      // Some RTDB rule-sets require .indexOn for orderBy and return 400 when
      // missing. Fall back to a plain fetch so the leaderboard still works.
      if (response.statusCode != 200) {
        response = await http.get(await _authedUrl(path));
      }

      if (response.statusCode != 200) {
        _lastFunctionError =
            'Leaderboard request failed with status ${response.statusCode}.';
        throw Exception(_lastFunctionError);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return const <LeaderboardEntry>[];

      final dedupedByHandle = <String, LeaderboardEntry>{};
      for (final raw in data.values) {
        if (raw is! Map<String, dynamic>) continue;
        final h = (raw['handle'] as String?)?.trim() ?? 'Unknown Player';
        final s = (raw['score'] as num?)?.toInt() ?? 0;
        final t = (raw['title'] as String?) ?? '';
        final c = (raw['country'] as String?)?.trim();
        final key = h.toLowerCase();
        final existing = dedupedByHandle[key];
        if (existing == null || s > existing.score) {
          dedupedByHandle[key] = LeaderboardEntry(
            rank: 0,
            handle: h,
            score: s,
            title: t,
            country: c != null && c.isNotEmpty ? c : null,
          );
        }
      }

      final entries = dedupedByHandle.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      if (entries.length > limit) entries.removeRange(limit, entries.length);
      for (var i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          rank: i + 1,
          handle: entries[i].handle,
          score: entries[i].score,
          title: entries[i].title,
          country: entries[i].country,
        );
      }
      return entries;
    } catch (e) {
      _lastFunctionError ??= e.toString();
      rethrow;
    }
  }
}
