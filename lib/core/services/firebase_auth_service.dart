import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages an anonymous Firebase Auth identity via the REST Identity Toolkit.
///
/// No `firebase_core` SDK is needed – the Web API key from
/// GoogleService-Info.plist / google-services.json is sufficient.
///
/// The obtained ID token is used by [ScoreboardService] as the `?auth=`
/// parameter on RTDB requests and as the `Authorization: Bearer` header when
/// calling Cloud Functions.
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  // Web API key from ios/Runner/GoogleService-Info.plist
  static const String _apiKey = 'AIzaSyAL5PbGAF9z-7C9DL01vTuz9ijEqMtyT60';

  static const String _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';
  static const String _refreshUrl =
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey';

  static const String _prefUid = 'fauth_uid';
  static const String _prefRefreshToken = 'fauth_refresh';
  static const String _prefIdToken = 'fauth_id_token';
  static const String _prefExpiryMs = 'fauth_expiry_ms';

  String? _uid;
  String? _idToken;
  String? _refreshToken;
  DateTime? _expiry;

  /// Firebase UID for the anonymous user, or null before initialisation.
  String? get uid => _uid;

  /// Loads persisted credentials and refreshes or creates a new account as
  /// needed. Should be called once in [main] before [runApp].
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString(_prefUid);
    _refreshToken = prefs.getString(_prefRefreshToken);
    _idToken = prefs.getString(_prefIdToken);
    final expiryMs = prefs.getInt(_prefExpiryMs);
    if (expiryMs != null) {
      _expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    }

    if (_uid == null || _refreshToken == null) {
      await _signInAnonymously();
    } else if (_isExpiredOrSoon()) {
      await _refreshIdToken();
    }
  }

  /// Returns a valid ID token, refreshing it if it expires within 5 minutes.
  /// Returns null if offline or if sign-in failed.
  Future<String?> getIdToken() async {
    if (_idToken != null && !_isExpiredOrSoon()) return _idToken;
    if (_refreshToken != null) {
      await _refreshIdToken();
    } else {
      await _signInAnonymously();
    }
    return _idToken;
  }

  bool _isExpiredOrSoon() {
    if (_expiry == null) return true;
    return _expiry!.isBefore(DateTime.now().add(const Duration(minutes: 5)));
  }

  Future<void> _signInAnonymously() async {
    try {
      final response = await http.post(
        Uri.parse(_signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _persist(
          uid: data['localId'] as String,
          idToken: data['idToken'] as String,
          refreshToken: data['refreshToken'] as String,
          expiresIn: int.parse(data['expiresIn'] as String),
        );
      }
    } catch (_) {
      // Best-effort. App continues with unauthenticated public RTDB reads.
    }
  }

  Future<void> _refreshIdToken() async {
    try {
      final response = await http.post(
        Uri.parse(_refreshUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$_refreshToken',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _persist(
          uid: data['user_id'] as String,
          idToken: data['id_token'] as String,
          refreshToken: data['refresh_token'] as String,
          expiresIn: int.parse(data['expires_in'] as String),
        );
      } else {
        // Refresh token revoked – create a new anonymous account.
        _refreshToken = null;
        await _signInAnonymously();
      }
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _persist({
    required String uid,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    _uid = uid;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _expiry = DateTime.now().add(Duration(seconds: expiresIn));
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_prefUid, uid),
      prefs.setString(_prefIdToken, idToken),
      prefs.setString(_prefRefreshToken, refreshToken),
      prefs.setInt(_prefExpiryMs, _expiry!.millisecondsSinceEpoch),
    ]);
  }
}
