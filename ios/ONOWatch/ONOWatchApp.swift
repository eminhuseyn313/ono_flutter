// ONO on Apple Watch: today's list to tick, the first of today's three,
// and a running timer or rest. The iPhone app sends what its widget shows
// (OnoWatch in ios/Runner/AppDelegate.swift); ticks go back to it and are
// recorded when ONO next opens. Nothing is stored here but that copy.
import SwiftUI
import WatchConnectivity
import WatchKit

private let accent = Color(red: 0.784, green: 0.537, blue: 0.290)

struct WatchItem: Identifiable, Codable, Hashable {
  let id: String
  let t: String
  var d: Bool
}

final class PhoneLink: NSObject, ObservableObject, WCSessionDelegate {
  @Published var items: [WatchItem] = []
  @Published var day = ""
  @Published var score = 0
  @Published var target = 1
  @Published var streak = 0
  @Published var first = ""
  @Published var timerTitle = ""
  @Published var timerEnds: Date?
  @Published var timerNext = ""

  private static let saved = "ono_context"

  override init() {
    super.init()
    load(UserDefaults.standard.dictionary(forKey: PhoneLink.saved) ?? [:])
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  var isToday: Bool {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.dateFormat = "yyyy-MM-dd"
    return day == f.string(from: Date())
  }

  private func load(_ c: [String: Any]) {
    day = c["date"] as? String ?? ""
    score = (c["score"] as? NSNumber)?.intValue ?? 0
    target = max((c["target"] as? NSNumber)?.intValue ?? 1, 1)
    streak = (c["streak"] as? NSNumber)?.intValue ?? 0
    first = c["first"] as? String ?? ""
    if let json = c["items"] as? String, let data = json.data(using: .utf8),
       let list = try? JSONDecoder().decode([WatchItem].self, from: data) {
      items = list
    } else {
      items = []
    }
    timerTitle = c["timer_title"] as? String ?? ""
    let ms = (c["timer_ends"] as? NSNumber)?.doubleValue ?? 0
    timerEnds = ms > 0 ? Date(timeIntervalSince1970: ms / 1000) : nil
    timerNext = c["timer_next"] as? String ?? ""
  }

  private func take(_ c: [String: Any]) {
    UserDefaults.standard.set(c, forKey: PhoneLink.saved)
    load(c)
  }

  func toggle(_ item: WatchItem) {
    guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
    items[i].d.toggle()
    score = items.filter { $0.d }.count
    WKInterfaceDevice.current().play(items[i].d ? .success : .click)
    let message: [String: Any] = ["tick": item.id, "date": day, "on": items[i].d]
    let s = WCSession.default
    guard s.activationState == .activated else { return }
    if s.isReachable {
      s.sendMessage(message, replyHandler: nil) { _ in s.transferUserInfo(message) }
    } else {
      // Delivered when the iPhone app next runs.
      s.transferUserInfo(message)
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
               error: Error?) {
    let c = session.receivedApplicationContext
    if !c.isEmpty { DispatchQueue.main.async { self.take(c) } }
  }

  func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
    DispatchQueue.main.async { self.take(context) }
  }
}

@main
struct ONOWatchApp: App {
  @StateObject private var link = PhoneLink()

  var body: some Scene {
    WindowGroup {
      TodayView().environmentObject(link)
    }
  }
}

struct TodayView: View {
  @EnvironmentObject var link: PhoneLink

  var body: some View {
    NavigationStack {
      List {
        if let ends = link.timerEnds, ends > Date() {
          Section {
            VStack(alignment: .leading, spacing: 2) {
              Text(link.timerTitle).font(.headline)
              Text(timerInterval: Date()...ends, countsDown: true)
                .font(.system(.title, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
              if !link.timerNext.isEmpty {
                Text("Next: \(link.timerNext)").font(.caption2).foregroundStyle(.secondary)
              }
            }
          }
        }
        if !link.isToday || link.items.isEmpty {
          Text("Open ONO on your iPhone to start today.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        } else {
          Section {
            ForEach(link.items) { item in
              Button {
                link.toggle(item)
              } label: {
                HStack(spacing: 8) {
                  Image(systemName: item.d ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.d ? accent : .secondary)
                  Text(item.t)
                    .lineLimit(2)
                    .foregroundStyle(item.d ? .secondary : .primary)
                }
              }
              .accessibilityValue(item.d ? "Done" : "Not done")
            }
          } header: {
            Text("Today · \(link.score)/\(link.items.count)")
          } footer: {
            if link.score >= link.target {
              Text("Today is held.").foregroundStyle(accent)
            }
          }
          if !link.first.isEmpty {
            Section("First of today's three") {
              Text(link.first).font(.footnote)
            }
          }
          if link.streak > 0 {
            Text("\(link.streak)-day streak").font(.footnote).foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("ONO")
    }
    .tint(accent)
  }
}
