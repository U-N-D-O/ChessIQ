import 'dart:convert';

import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/firebase_options.dart';
import 'package:http/http.dart' as http;

class ScoreboardService {
  ScoreboardService._();

  static final ScoreboardService instance = ScoreboardService._();

  static const String _databaseUrl = kFirebaseRealtimeDatabaseUrl;
  static const String _globalPath = 'academy_scoreboard/global';
  static const String _countryRoot = 'academy_scoreboard/by_country';

  String _countryKey(String country) {
    final normalized = country.trim().isEmpty ? 'Unknown' : country.trim();
    return Uri.encodeComponent(
      normalized.replaceAll(RegExp(r'[.#$\[\]/]'), '_'),
    );
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_databaseUrl/$path.json');
    if (query == null) return uri;
    return uri.replace(queryParameters: query);
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
      final normalizedCountry = country.trim().isEmpty
          ? 'Unknown'
          : country.trim();
      final payload = {
        'handle': trimmedHandle,
        'country': normalizedCountry,
        'score': score,
        'title': title,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      final body = jsonEncode(payload);
      final postGlobal = http.post(_url(_globalPath), body: body);
      final postCountry = http.post(
        _url('$_countryRoot/${_countryKey(normalizedCountry)}'),
        body: body,
      );
      await Future.wait([postGlobal, postCountry]);
    } catch (_) {
      // Keep scoreboard sync best-effort and avoid crashing the app.
    }
  }

  Future<List<LeaderboardEntry>> fetchTopScores({
    String? country,
    int limit = 10,
  }) async {
    try {
      final path = country == null || country.trim().isEmpty
          ? _globalPath
          : '$_countryRoot/${_countryKey(country)}';
      final uri = _url(path, {
        'orderBy': jsonEncode('score'),
        'limitToLast': '$limit',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return const <LeaderboardEntry>[];

      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return const <LeaderboardEntry>[];

      final entries = data.values.whereType<Map<String, dynamic>>().map((
        entry,
      ) {
        final handle = (entry['handle'] as String?)?.trim() ?? 'Unknown Player';
        final score = (entry['score'] as num?)?.toInt() ?? 0;
        final title = (entry['title'] as String?) ?? '';
        return LeaderboardEntry(
          rank: 0,
          handle: handle,
          score: score,
          title: title,
        );
      }).toList();

      entries.sort((a, b) => b.score.compareTo(a.score));
      for (var i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          rank: i + 1,
          handle: entries[i].handle,
          score: entries[i].score,
          title: entries[i].title,
        );
      }
      return entries;
    } catch (_) {
      return const <LeaderboardEntry>[];
    }
  }
}
