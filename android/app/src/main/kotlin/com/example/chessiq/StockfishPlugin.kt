package com.qila.chessiq

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.OutputStreamWriter
import java.nio.charset.StandardCharsets
import java.util.concurrent.ConcurrentLinkedQueue

class StockfishPlugin(
  private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

  companion object {
    private const val METHOD_CHANNEL = "com.chessiq/stockfish"
    private const val EVENT_CHANNEL = "com.chessiq/stockfish_output"
    private const val TAG = "ChessIQStockfish"

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
  private val pendingOutput = ConcurrentLinkedQueue<String>()
  private var eventSink: EventChannel.EventSink? = null
  private var process: Process? = null
  private var outputThread: Thread? = null
  private var waitThread: Thread? = null

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
    flushPendingOutput()
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun startEngine(result: MethodChannel.Result) {
    if (process != null) {
      result.success(null)
      return
    }

    val stockfishFile = File(context.applicationInfo.nativeLibraryDir, "libstockfish.so")
    if (!stockfishFile.exists()) {
      Log.e(TAG, "Missing installed library at ${stockfishFile.absolutePath}")
      result.error(
        "MISSING_STOCKFISH_LIBRARY",
        missingLibraryMessage(stockfishFile),
        null,
      )
      return
    }

    try {
      Log.i(TAG, "Starting Stockfish from ${stockfishFile.absolutePath}")
      process = ProcessBuilder(stockfishFile.absolutePath)
        .directory(stockfishFile.parentFile)
        .redirectErrorStream(true)
        .start()
    } catch (error: Exception) {
      Log.e(TAG, "Failed to start Stockfish", error)
      result.error("START_FAILED", "Failed to start Stockfish process: ${error.message}", null)
      process = null
      return
    }

    outputThread = Thread {
      try {
        process?.inputStream?.bufferedReader(StandardCharsets.UTF_8)?.useLines { lines ->
          lines.forEach { line ->
            Log.d(TAG, "stdout: $line")
            emitOutput(line)
          }
        }
      } catch (_: Exception) {
        // Best-effort output streaming.
      }
    }.apply {
      name = "ChessIQ-Stockfish-stdout"
      start()
    }

    waitThread = Thread {
      val runningProcess = process ?: return@Thread
      val exitCode = try {
        runningProcess.waitFor()
      } catch (_: InterruptedException) {
        return@Thread
      }

      Log.i(TAG, "Stockfish exited with code $exitCode")
      mainHandler.post {
        if (process === runningProcess) {
          process = null
          outputThread = null
          waitThread = null
          eventSink?.endOfStream()
        }
      }
    }.apply {
      name = "ChessIQ-Stockfish-wait"
      start()
    }

    result.success(null)
  }

  private fun sendCommand(cmd: String) {
    try {
      val writer = OutputStreamWriter(process?.outputStream ?: return, StandardCharsets.UTF_8)
      writer.write(cmd)
      writer.write("\n")
      writer.flush()
      Log.v(TAG, "stdin: $cmd")
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
    waitThread = null
  }

  private fun emitOutput(line: String) {
    mainHandler.post {
      val sink = eventSink
      if (sink != null) {
        sink.success(line)
      } else {
        pendingOutput.add(line)
      }
    }
  }

  private fun flushPendingOutput() {
    val sink = eventSink ?: return
    while (true) {
      val line = pendingOutput.poll() ?: break
      sink.success(line)
    }
  }

  private fun missingLibraryMessage(stockfishFile: File): String {
    return buildString {
      append("Android needs a packaged Stockfish library for this device. ")
      append("Expected installed library at '${stockfishFile.absolutePath}'. ")
      append("Build Android Stockfish into android/app/src/main/jniLibs/<abi>/libstockfish.so. ")
      append("Supported ABIs: ${supportedAbiSummary()}. ")
      append("Build the Android Stockfish libraries locally or via the GitHub Android workflow.")
    }
  }

  private fun supportedAbiSummary(): String {
    val supportedAbis = Build.SUPPORTED_ABIS.toList()
    return if (supportedAbis.isEmpty()) "unknown" else supportedAbis.joinToString(", ")
  }
}
