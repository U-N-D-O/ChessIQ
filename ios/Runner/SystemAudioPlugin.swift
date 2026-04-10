import Flutter
import UIKit
import AVFoundation

public class SystemAudioPlugin: NSObject, FlutterPlugin {
  private static let channelName = "com.chessiq/system_audio"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = SystemAudioPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isPhoneMuted":
      result(isPhoneMuted())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isPhoneMuted() -> Bool {
    let session = AVAudioSession.sharedInstance()
    return session.secondaryAudioShouldBeSilencedHint
  }
}
