package com.example.chessiq

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SystemAudioPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  companion object {
    private const val CHANNEL = "com.chessiq/system_audio"

    @JvmStatic
    fun registerWith(messenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
      val channel = MethodChannel(messenger, CHANNEL)
      val plugin = SystemAudioPlugin().apply {
        this.context = context
      }
      channel.setMethodCallHandler(plugin)
      plugin.channel = channel
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, CHANNEL)
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "isPhoneMuted" -> result.success(isPhoneMuted())
      else -> result.notImplemented()
    }
  }

  private fun isPhoneMuted(): Boolean {
    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    return when (audioManager?.ringerMode) {
      AudioManager.RINGER_MODE_SILENT, AudioManager.RINGER_MODE_VIBRATE -> true
      else -> false
    }
  }
}
