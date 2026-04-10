package com.example.chessiq

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    StockfishPlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    SystemAudioPlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
  }
}
