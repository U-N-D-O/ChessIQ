import Flutter
import UIKit
import Darwin

private let kMethodChannel = "com.chessiq/stockfish"
private let kEventChannel  = "com.chessiq/stockfish_output"

/// Bridges Stockfish (bundled binary) to Flutter via MethodChannel + EventChannel.
/// The binary is launched as a child process using posix_spawn and communicates
/// via stdin/stdout pipes on a background thread.
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
    private var enginePID: pid_t = 0
    private var stdinFD:  Int32  = -1   // parent writes → engine stdin
    private var stdoutFD: Int32  = -1   // parent reads  ← engine stdout

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
            writeToEngine(cmd)
            result(nil)
        case "stop":
            stopEngine()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Engine Lifecycle

    private func startEngine(result: @escaping FlutterResult) {
        guard enginePID == 0 else { result(nil); return }

        guard let binaryPath = Bundle.main.path(forResource: "stockfish", ofType: nil) else {
            result(FlutterError(
                code: "NOT_FOUND",
                message: "stockfish binary not found in app bundle. See ios/STOCKFISH_SETUP.md.",
                details: nil
            ))
            return
        }

        // pipes[0] = read end, pipes[1] = write end
        var stdinPipe:  [Int32] = [-1, -1]
        var stdoutPipe: [Int32] = [-1, -1]

        guard Darwin.pipe(&stdinPipe)  == 0,
              Darwin.pipe(&stdoutPipe) == 0 else {
            result(FlutterError(code: "PIPE_FAIL", message: "pipe() failed", details: nil))
            return
        }

        var fa: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fa)
        // Child reads from stdinPipe[0] as stdin
        posix_spawn_file_actions_adddup2(&fa, stdinPipe[0],  STDIN_FILENO)
        // Child writes to stdoutPipe[1] as stdout and stderr
        posix_spawn_file_actions_adddup2(&fa, stdoutPipe[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&fa, stdoutPipe[1], STDERR_FILENO)
        // Close parent-side ends inside the child
        posix_spawn_file_actions_addclose(&fa, stdinPipe[1])
        posix_spawn_file_actions_addclose(&fa, stdoutPipe[0])

        var argv: [UnsafeMutablePointer<CChar>?] = [strdup(binaryPath), nil]
        defer { argv.forEach { free($0) } }

        var childPID: pid_t = 0
        let rc = posix_spawn(&childPID, binaryPath, &fa, nil, &argv, nil)
        posix_spawn_file_actions_destroy(&fa)

        // Close child-side ends in parent
        Darwin.close(stdinPipe[0])
        Darwin.close(stdoutPipe[1])

        guard rc == 0 else {
            Darwin.close(stdinPipe[1])
            Darwin.close(stdoutPipe[0])
            result(FlutterError(
                code: "SPAWN_FAIL",
                message: "posix_spawn failed (code \(rc)): \(String(cString: strerror(rc)))",
                details: nil
            ))
            return
        }

        enginePID = childPID
        stdinFD   = stdinPipe[1]    // parent writes here
        stdoutFD  = stdoutPipe[0]   // parent reads here

        Thread.detachNewThread { [weak self] in self?.readLoop() }
        result(nil)
    }

    private func readLoop() {
        let bufSize = 4096
        var buf = [UInt8](repeating: 0, count: bufSize)
        var partial = ""

        while true {
            let n = Darwin.read(stdoutFD, &buf, bufSize)
            if n <= 0 { break }
            let chunk = String(bytes: buf[0..<n], encoding: .utf8) ?? ""
            var lines = (partial + chunk).components(separatedBy: "\n")
            partial = lines.removeLast()  // last element may be incomplete
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                DispatchQueue.main.async { [weak self] in
                    self?.eventSink?(trimmed)
                }
            }
        }
    }

    private func writeToEngine(_ cmd: String) {
        guard stdinFD != -1 else { return }
        (cmd + "\n").withCString { ptr in
            _ = Darwin.write(stdinFD, ptr, strlen(ptr))
        }
    }

    private func stopEngine() {
        writeToEngine("quit")
        if stdinFD  != -1 { Darwin.close(stdinFD);  stdinFD  = -1 }
        if stdoutFD != -1 { Darwin.close(stdoutFD); stdoutFD = -1 }
        if enginePID != 0 {
            kill(enginePID, SIGTERM)
            waitpid(enginePID, nil, 0)
            enginePID = 0
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
