import 'package:flutter/services.dart';

class SystemAudioService {
  static const MethodChannel _channel = MethodChannel(
    'com.chessiq/system_audio',
  );
  static const String muteSoundsKey = 'mute_sounds_v1';

  static Future<bool> isPhoneMuted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPhoneMuted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
