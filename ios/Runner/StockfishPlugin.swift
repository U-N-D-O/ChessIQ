import Flutter
import UIKit

private let kMethodChannel = "com.chessiq/stockfish"
private let kEventChannel  = "com.chessiq/stockfish_output"

/// Bridges in-process Stockfish (native static library) to Flutter.
public class StockfishPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let method = FlutterMethodChannel(
            name: kMethodChannel,
            binaryMessenger: registrar.messenger()
        )
        let event = FlutterEventChannel(
            name: kEventChannel,
            binaryMessenger: registrar.messenger()
        )
        let instance = StockfishPlugin()
        registrar.addMethodCallDelegate(instance, channel: method)
        event.setStreamHandler(instance)
    }

    // MARK: - State

    private var eventSink: FlutterEventSink?
    private let engine = StockfishBridge.shared()

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            startEngine(result: result)
        case "send":
            guard let cmd = call.arguments as? String else {
                result(FlutterError(code: "BAD_ARG", message: "Expected String argument", details: nil))
                return
            }
            engine.sendCommand(cmd)
            result(nil)
        case "stop":
            engine.stop()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Engine Lifecycle

    private func startEngine(result: @escaping FlutterResult) {
        engine.setOutputHandler { [weak self] line in
            self?.eventSink?(line)
        }

        var nsError: NSError?
        let ok = engine.start(&nsError)
        if ok {
            result(nil)
            return
        }

        result(
            FlutterError(
                code: "IN_PROCESS_START_FAIL",
                message: nsError?.localizedDescription ?? "Failed to start Stockfish in-process engine",
                details: nil
            )
        )
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        engine.setOutputHandler(nil)
        return nil
    }
}
