import ActivityKit
import AppIntents
import Flutter
import UIKit
import UserNotifications
import WatchConnectivity
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Let flutter_local_notifications show reminders while ONO is open.
    UNUserNotificationCenter.current().delegate = self
    // The Apple Watch app: today's list and timers out, ticks back.
    OnoWatch.shared.activate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OnoLiveTimer") {
      OnoLiveTimer.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OnoFocus") {
      OnoFocus.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OnoWatch") {
      OnoWatch.shared.register(messenger: registrar.messenger())
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
        OnoWatch.shared.setTimer(
          title: args["title"] as? String ?? "", endsAtMs: ms, next: args["next"] as? String ?? "")
        start(
          title: args["title"] as? String ?? "ONO",
          endsAt: Date(timeIntervalSince1970: ms / 1000),
          kind: args["kind"] as? String ?? "timer",
          next: args["next"] as? String ?? "",
          result: result)
      case "end":
        OnoWatch.shared.setTimer(title: "", endsAtMs: 0, next: "")
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

// MARK: - Focus filter: a Focus tells Today which part of the day it is

/// Answers lib/services/device_focus.dart on the "ono/focus" channel.
enum OnoFocus {
  static let key = "ono_focus_part"
  private static var channel: FlutterMethodChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "ono/focus", binaryMessenger: messenger)
    c.setMethodCallHandler { call, result in
      if call.method == "current" {
        result(UserDefaults.standard.string(forKey: key))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = c
  }

  /// Called by the filter when a Focus turns on (a part) or off (nil).
  static func set(_ part: String?) {
    UserDefaults.standard.set(part, forKey: key)
    DispatchQueue.main.async { channel?.invokeMethod("changed", arguments: part) }
  }
}

@available(iOS 16.0, *)
enum OnoFocusPart: String, AppEnum {
  case work, personal, winddown

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Part of your day")
  static var caseDisplayRepresentations: [OnoFocusPart: DisplayRepresentation] = [
    .work: "Work",
    .personal: "Personal time",
    .winddown: "Winding down",
  ]
}

/// Settings → Focus → (Work, Personal, Sleep…) → Focus Filters → ONO.
/// While that Focus is on, Today shows the work part, the restoring
/// tools or the evening (shutdown); when it ends, the clock decides again.
@available(iOS 16.0, *)
struct OnoFocusFilter: SetFocusFilterIntent {
  static var title: LocalizedStringResource = "Set what ONO's Today shows"
  static var description: IntentDescription? = IntentDescription(
    "While this Focus is on, Today shows the part of your day it is for.")

  @Parameter(title: "Today shows")
  var part: OnoFocusPart?

  var displayRepresentation: DisplayRepresentation {
    switch part {
    case .work?: return DisplayRepresentation(title: "ONO", subtitle: "Work")
    case .personal?: return DisplayRepresentation(title: "ONO", subtitle: "Personal time")
    case .winddown?: return DisplayRepresentation(title: "ONO", subtitle: "Winding down")
    case nil: return DisplayRepresentation(title: "ONO", subtitle: "Choose a part of your day")
    }
  }

  func perform() async throws -> some IntentResult {
    OnoFocus.set(part?.rawValue)
    return .result()
  }
}

// MARK: - Apple Watch: today's list and timers out, ticks back

/// Sends what the widget shows (plus a running timer) to the watch app
/// (ios/ONOWatch) and queues its ticks where the widget's go
/// ("pending_ticks" in the app group), for the app to record.
final class OnoWatch: NSObject, WCSessionDelegate {
  static let shared = OnoWatch()
  private static let appGroup = "group.com.eminhuseynzade.ono"
  private var channel: FlutterMethodChannel?
  private var context: [String: Any] = [:]

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "ono/watch", binaryMessenger: messenger)
    c.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      if call.method == "context" {
        let values = call.arguments as? [String: Any] ?? [:]
        // An empty map clears the watch (signed out, everything deleted).
        self.context = values.isEmpty ? [:] : self.context.merging(values) { _, new in new }
        self.send()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = c
  }

  func setTimer(title: String, endsAtMs: Double, next: String) {
    context["timer_title"] = title
    context["timer_ends"] = endsAtMs
    context["timer_next"] = next
    send()
  }

  private func send() {
    let s = WCSession.default
    guard WCSession.isSupported(), s.activationState == .activated,
          s.isPaired, s.isWatchAppInstalled
    else { return }
    // Property-list values only.
    let clean = context.filter { $0.value is String || $0.value is NSNumber }
    try? s.updateApplicationContext(clean)
  }

  private func receive(_ message: [String: Any]) {
    guard let id = message["tick"] as? String, let day = message["date"] as? String else { return }
    let on = message["on"] as? Bool ?? true
    let d = UserDefaults(suiteName: OnoWatch.appGroup)
    // The widget shows the same tick at once.
    if let json = d?.string(forKey: "items"), let data = json.data(using: .utf8),
       var list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
      for i in list.indices where list[i]["id"] as? String == id { list[i]["d"] = on }
      if let out = try? JSONSerialization.data(withJSONObject: list),
         let text = String(data: out, encoding: .utf8) {
        d?.set(text, forKey: "items")
      }
    }
    var pending: [[String: Any]] = []
    if let json = d?.string(forKey: "pending_ticks"), let data = json.data(using: .utf8),
       let old = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
      pending = old
    }
    pending.append(["id": id, "date": day, "on": on])
    if let out = try? JSONSerialization.data(withJSONObject: pending),
       let text = String(data: out, encoding: .utf8) {
      d?.set(text, forKey: "pending_ticks")
    }
    WidgetCenter.shared.reloadAllTimelines()
    DispatchQueue.main.async { self.channel?.invokeMethod("ticksWaiting", arguments: nil) }
  }

  func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
               error: Error?) {
    if state == .activated { DispatchQueue.main.async { self.send() } }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    receive(message)
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    receive(userInfo)
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    // A different watch was paired: listen on the new one.
    WCSession.default.activate()
  }
}
