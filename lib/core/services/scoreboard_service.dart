import 'package:chessiq/core/config.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ScoreboardService {
  ScoreboardService._();

  static final ScoreboardService instance = ScoreboardService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;
    await Firebase.initializeApp();
    await _ensureSignedIn();
    _initialized = true;
  }

  bool get _enabled => kEnableRemoteScoreboard;

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) return;
    await auth.signInAnonymously();
  }

  Future<void> submitScore({
    required String handle,
    required String country,
    required int score,
    required String title,
  }) async {
    if (!_enabled) return;

    try {
      await initialize();
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;
      final doc = FirebaseFirestore.instance
          .collection('academy_scoreboard')
          .doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);
        final existingScore = snapshot.exists
            ? (snapshot.data()?['score'] as int? ?? 0)
            : 0;
        if (score <= existingScore) return;
        transaction.set(doc, {
          'userId': user.uid,
          'handle': handle,
          'country': country.trim().isEmpty ? 'Unknown' : country.trim(),
          'score': score,
          'title': title,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // Keep scoreboard sync best-effort and avoid crashing the app.
    }
  }

  Future<List<LeaderboardEntry>> fetchTopScores({
    String? country,
    int limit = 10,
  }) async {
    if (!_enabled) return const <LeaderboardEntry>[];

    try {
      await initialize();
      var query = FirebaseFirestore.instance
          .collection('academy_scoreboard')
          .orderBy('score', descending: true)
          .limit(limit);
      if (country != null && country.trim().isNotEmpty) {
        query = query.where('country', isEqualTo: country.trim());
      }
      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];
      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final handle = (data['handle'] as String?)?.trim() ?? 'Unknown Player';
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final title = (data['title'] as String?) ?? '';
        entries.add(
          LeaderboardEntry(
            rank: i + 1,
            handle: handle,
            score: score,
            title: title,
          ),
        );
      }
      return entries;
    } catch (_) {
      return const <LeaderboardEntry>[];
    }
  }
}
