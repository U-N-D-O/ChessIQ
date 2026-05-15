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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureIosAudioSession();

  // Run non-blocking initialisations in parallel.
  await Future.wait([
    AdService.instance.initialize(),
    FirebaseAuthService.instance.initialize(),
    PurchaseService.instance.initialize(),
  ]);

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(SystemAudioService.muteSoundsKey)) {
    final phoneMuted = _isIOS ? false : await SystemAudioService.isPhoneMuted();
    await prefs.setBool(SystemAudioService.muteSoundsKey, phoneMuted);
  }

  runApp(const ChessIQApp());
}
