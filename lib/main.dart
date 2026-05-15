import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:chessiq/core/app/chess_iq_app.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:chessiq/core/services/purchase_service.dart';
import 'package:chessiq/core/services/system_audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

Future<void> _configureIosAudioSession() async {
  if (!_isIOS) {
    return;
  }

  await AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ),
  );
}

Future<void> _seedMutePreference() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(SystemAudioService.muteSoundsKey)) {
    final phoneMuted = _isIOS ? false : await SystemAudioService.isPhoneMuted();
    await prefs.setBool(SystemAudioService.muteSoundsKey, phoneMuted);
  }
}

Future<void> _runStartupTask(
  String label,
  Future<void> Function() task, {
  Duration? timeout,
}) async {
  try {
    final future = task();
    if (timeout != null) {
      await future.timeout(timeout);
      return;
    }
    await future;
  } catch (error, stackTrace) {
    debugPrint('Startup warmup failed for $label: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _startDeferredStartupWarmups() {
  unawaited(
    _runStartupTask(
      'AdService.initialize',
      AdService.instance.initialize,
      timeout: const Duration(seconds: 15),
    ),
  );
  unawaited(
    _runStartupTask(
      'FirebaseAuthService.initialize',
      FirebaseAuthService.instance.initialize,
      timeout: const Duration(seconds: 20),
    ),
  );
  unawaited(
    _runStartupTask(
      'PurchaseService.initialize',
      PurchaseService.instance.initialize,
      timeout: const Duration(seconds: 20),
    ),
  );
  unawaited(
    _runStartupTask(
      'mute preference seed',
      _seedMutePreference,
      timeout: const Duration(seconds: 5),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ChessIQApp());

  // Let Flutter paint immediately so a slow plugin, store, or network call
  // cannot strand iOS users on a blank launch screen.
  unawaited(
    _runStartupTask(
      'iOS audio session',
      _configureIosAudioSession,
      timeout: const Duration(seconds: 5),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startDeferredStartupWarmups();
  });
}
