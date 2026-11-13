import ActivityKit
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Let flutter_local_notifications show reminders while ONO is open.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OnoLiveTimer") {
      OnoLiveTimer.register(messenger: registrar.messenger())
    }
  }
}

// MARK: - Lock Screen countdown (Live Activity)

/// Must match the struct of the same name in ios/ONOWidget/ONOWidget.swift,
/// which draws it on the Lock Screen and in the Dynamic Island.
struct OnoTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var endsAt: Date
    var next: String
  }

  /// focus, timer or rest: picks the icon.
  var kind: String
}

/// Answers lib/services/live_timer.dart on the "ono/live_activity" channel.
enum OnoLiveTimer {
  private static var channel: FlutterMethodChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "ono/live_activity", binaryMessenger: messenger)
    c.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any] ?? [:]
        let ms = (args["endsAtMs"] as? NSNumber)?.doubleValue ?? 0
        start(
          title: args["title"] as? String ?? "ONO",
          endsAt: Date(timeIntervalSince1970: ms / 1000),
          kind: args["kind"] as? String ?? "timer",
          next: args["next"] as? String ?? "",
          result: result)
      case "end":
        endAll { result(nil) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = c
  }

  @available(iOS 16.2, *)
  private static func start(
    title: String, endsAt: Date, kind: String, next: String, result: @escaping FlutterResult
  ) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled, endsAt > Date() else {
      result(false)
      return
    }
    let state = OnoTimerAttributes.ContentState(title: title, endsAt: endsAt, next: next)
    Task {
      // One countdown at a time.
      for activity in Activity<OnoTimerAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      var ok = true
      do {
        _ = try Activity.request(
          attributes: OnoTimerAttributes(kind: kind),
          content: ActivityContent(state: state, staleDate: endsAt),
          pushType: nil)
      } catch {
        ok = false
      }
      DispatchQueue.main.async { result(ok) }
    }
  }

  @available(iOS 16.2, *)
  private static func endAll(_ done: @escaping () -> Void) {
    Task {
      for activity in Activity<OnoTimerAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      DispatchQueue.main.async { done() }
    }
  }
}
