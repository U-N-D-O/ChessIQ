import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:chessiq/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

bool get _supportsNativeFirebaseMessaging =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_supportsNativeFirebaseMessaging) {
    return;
  }

  await PushNotificationService.instance.ensureFirebaseInitialized();
  debugPrint(
    '[PushNotificationService] Background message received: '
    '${message.messageId ?? 'unknown'}',
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const String _registerPushTokenFunction = 'registerPushDeviceToken';
  static const String _installationIdPrefKey = 'push_installation_id_v1';

  static bool _backgroundHandlerRegistered = false;

  Future<void>? _initializeFuture;
  bool _foregroundPresentationConfigured = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static void registerBackgroundHandler() {
    if (!_supportsNativeFirebaseMessaging || _backgroundHandlerRegistered) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  Future<void> initialize() async {
    if (!_supportsNativeFirebaseMessaging) {
      return;
    }

    return _initializeFuture ??= _initializeInternal();
  }

  Future<void> ensureFirebaseInitialized() async {
    if (!_supportsNativeFirebaseMessaging) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  Future<void> _initializeInternal() async {
    await ensureFirebaseInitialized();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await _configureForegroundPresentation();
  }

  Future<void> _configureForegroundPresentation() async {
    if (_foregroundPresentationConfigured ||
        defaultTargetPlatform != TargetPlatform.iOS) {
      _foregroundPresentationConfigured = true;
      return;
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _foregroundPresentationConfigured = true;
  }

  Future<NotificationSettings?> requestRemoteFriendPermissions() async {
    if (!_supportsNativeFirebaseMessaging) {
      return null;
    }

    await initialize();
    return FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<String?> currentToken() async {
    if (!_supportsNativeFirebaseMessaging) {
      return null;
    }

    await initialize();
    return FirebaseMessaging.instance.getToken();
  }

  Stream<RemoteMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  Future<RemoteMessage?> getInitialMessage() async {
    if (!_supportsNativeFirebaseMessaging) {
      return null;
    }

    await initialize();
    return FirebaseMessaging.instance.getInitialMessage();
  }

  Future<void> prepareRemoteFriendNotifications() async {
    if (!_supportsNativeFirebaseMessaging) {
      return;
    }

    try {
      final settings = await requestRemoteFriendPermissions();
      if (!_notificationPermissionGranted(settings)) {
        return;
      }

      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((token) {
            unawaited(_registerPushTokenWithBackend(token));
          }, onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              '[PushNotificationService] Token refresh listener failed: '
              '$error',
            );
            debugPrintStack(stackTrace: stackTrace);
          });

      final token = await currentToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _registerPushTokenWithBackend(token);
    } catch (error, stackTrace) {
      debugPrint(
        '[PushNotificationService] Remote friend notification prep failed: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _notificationPermissionGranted(NotificationSettings? settings) {
    return settings?.authorizationStatus == AuthorizationStatus.authorized ||
        settings?.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _registerPushTokenWithBackend(String token) async {
    final idToken = await FirebaseAuthService.instance.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      return;
    }

    final installationId = await _installationId();
    final uri = Uri.parse(
      '$kFirebaseCloudFunctionsBaseUrl/$_registerPushTokenFunction',
    );
    final response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(<String, Object>{
            'data': <String, Object>{
              'installationId': installationId,
              'token': token,
              'platform': switch (defaultTargetPlatform) {
                TargetPlatform.android => 'android',
                TargetPlatform.iOS => 'ios',
                _ => 'unknown',
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      debugPrint(
        '[PushNotificationService] Push token registration failed '
        'with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_installationIdPrefKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final random = Random.secure();
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (int index = 0; index < 32; index++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    final installationId = buffer.toString();
    await prefs.setString(_installationIdPrefKey, installationId);
    return installationId;
  }
}