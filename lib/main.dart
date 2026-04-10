import 'package:chessiq/core/app/chess_iq_app.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:chessiq/core/services/system_audio_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(SystemAudioService.muteSoundsKey)) {
    final phoneMuted = await SystemAudioService.isPhoneMuted();
    await prefs.setBool(SystemAudioService.muteSoundsKey, phoneMuted);
  }

  runApp(const ChessIQApp());
}
