package com.example.chessiq

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.nio.charset.StandardCharsets

class StockfishPlugin(
  private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

  companion object {
    private const val METHOD_CHANNEL = "com.chessiq/stockfish"
    private const val EVENT_CHANNEL = "com.chessiq/stockfish_output"

    @JvmStatic
    fun registerWith(messenger: BinaryMessenger, context: Context) {
      val method = MethodChannel(messenger, METHOD_CHANNEL)
      val event = EventChannel(messenger, EVENT_CHANNEL)
      val plugin = StockfishPlugin(context)
      method.setMethodCallHandler(plugin)
      event.setStreamHandler(plugin)
    }
  }

  private val mainHandler = Handler(Looper.getMainLooper())
  private var eventSink: EventChannel.EventSink? = null
  private var process: Process? = null
  private var outputThread: Thread? = null

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "start" -> startEngine(result)
      "send" -> {
        val cmd = call.arguments as? String
        if (cmd == null) {
          result.error("BAD_ARG", "Expected String argument", null)
          return
        }
        sendCommand(cmd)
        result.success(null)
      }
      "stop" -> {
        stopEngine()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun startEngine(result: MethodChannel.Result) {
    if (process != null) {
      result.success(null)
      return
    }

    val assetName = selectAssetName()
    if (assetName == null) {
      result.error("NO_STOCKFISH_ASSET", "No Stockfish asset available for this ABI", null)
      return
    }

    val stockfishFile = File(context.filesDir, "stockfish")
    try {
      context.assets.open(assetName).use { input ->
        FileOutputStream(stockfishFile).use { output ->
          input.copyTo(output)
        }
      }
      stockfishFile.setExecutable(true)
      stockfishFile.setReadable(true)
      stockfishFile.setWritable(true)
    } catch (error: Exception) {
      result.error("ASSET_COPY_FAILED", "Failed to copy Stockfish binary: ${error.message}", null)
      return
    }

    try {
      process = ProcessBuilder(stockfishFile.absolutePath)
        .redirectErrorStream(true)
        .start()
    } catch (error: Exception) {
      result.error("START_FAILED", "Failed to start Stockfish process: ${error.message}", null)
      process = null
      return
    }

    outputThread = Thread {
      try {
        process?.inputStream?.bufferedReader(StandardCharsets.UTF_8)?.useLines { lines ->
          lines.forEach { line ->
            mainHandler.post {
              eventSink?.success(line)
            }
          }
        }
      } catch (_: Exception) {
        // Best-effort output streaming.
      }
    }.apply { start() }

    result.success(null)
  }

  private fun sendCommand(cmd: String) {
    try {
      val writer = OutputStreamWriter(process?.outputStream ?: return, StandardCharsets.UTF_8)
      writer.write(cmd)
      writer.write("\n")
      writer.flush()
    } catch (_: Exception) {
      // Sending is best-effort.
    }
  }

  private fun stopEngine() {
    try {
      process?.destroy()
    } catch (_: Exception) {
    }
    process = null
    outputThread = null
  }

  private fun selectAssetName(): String? {
    val supportedAbis = if (Build.SUPPORTED_64_BIT_ABIS.isNotEmpty()) {
      Build.SUPPORTED_64_BIT_ABIS.toList()
    } else {
      Build.SUPPORTED_ABIS.toList()
    }

    return when {
      supportedAbis.any { it.startsWith("arm64") } -> "stockfish-arm64-v8a"
      supportedAbis.any { it.startsWith("armeabi") } -> "stockfish-armeabi-v7a"
      supportedAbis.any { it.startsWith("x86_64") } -> "stockfish-x86_64"
      supportedAbis.any { it.startsWith("x86") } -> "stockfish-x86"
      else -> null
    }
  }
}
