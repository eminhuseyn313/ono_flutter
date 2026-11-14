// ONO Home Screen and Lock Screen widget.
// The Flutter app writes a snapshot into the shared app group (see
// lib/services/widget_sync.dart); this extension only reads and draws it.
// It also draws the Lock Screen countdown (Live Activity) that the app
// starts for deep work, tool timers and rest between sets.
import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

private let appGroup = "group.com.eminhuseynzade.ono"

private extension Color {
  static let onoBackground = Color(red: 0.043, green: 0.047, blue: 0.055)
  static let onoCard = Color(red: 0.078, green: 0.086, blue: 0.102)
  static let onoAccent = Color(red: 0.784, green: 0.537, blue: 0.290)
  static let onoIvory = Color(red: 0.953, green: 0.937, blue: 0.906)
  static let onoGrey = Color(red: 0.639, green: 0.620, blue: 0.584)
}

struct OnoEntry: TimelineEntry {
  let date: Date
  let score: Int
  /// Daily items and how many hold the day (the list is configurable).
  let total: Int
  let target: Int
  let streak: Int
  let day: Int
  let protein: Int
  let cardsDue: Int
  let phase: String
  let blockTime: String
  let blockTitle: String
  /// False when the app hasn't written today's snapshot yet.
  let isToday: Bool

  static let sample = OnoEntry(
    date: Date(), score: 7, total: 10, target: 7, streak: 12, day: 41, protein: 110, cardsDue: 6,
    phase: "Foundation", blockTime: "07:45", blockTitle: "Domain scan",
    isToday: true)
}

private struct Block: Decodable {
  let m: Int
  let t: String
}

struct OnoProvider: TimelineProvider {
  func placeholder(in context: Context) -> OnoEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (OnoEntry) -> Void) {
    completion(context.isPreview ? .sample : entry(at: Date()))
  }

  /// One entry at each schedule block left today, so "now" stays right
  /// without opening the app; a fresh timeline at midnight.
  func getTimeline(in context: Context, completion: @escaping (Timeline<OnoEntry>) -> Void) {
    let now = Date()
    let start = Calendar.current.startOfDay(for: now)
    let midnight = start.addingTimeInterval(24 * 60 * 60)
    var dates = [now]
    for b in blocks() {
      let d = start.addingTimeInterval(TimeInterval(b.m * 60))
      if d > now { dates.append(d) }
    }
    dates.append(midnight)
    completion(Timeline(entries: dates.map { entry(at: $0) }, policy: .after(midnight)))
  }

  private var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

  private func blocks() -> [Block] {
    guard let json = defaults?.string(forKey: "blocks"),
          let data = json.data(using: .utf8),
          let list = try? JSONDecoder().decode([Block].self, from: data)
    else { return [] }
    return list
  }

  private func entry(at date: Date) -> OnoEntry {
    let d = defaults
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.dateFormat = "yyyy-MM-dd"
    let isToday = d?.string(forKey: "date") == f.string(from: date)
    let minute = Calendar.current.component(.hour, from: date) * 60
      + Calendar.current.component(.minute, from: date)
    let list = blocks()
    let current = list.last(where: { $0.m <= minute }) ?? list.last
    let time = current.map { String(format: "%02d:%02d", $0.m / 60, $0.m % 60) } ?? ""
    return OnoEntry(
      date: date,
      score: isToday ? (d?.integer(forKey: "score") ?? 0) : 0,
      // integer(forKey:) is 0 for a missing key (signed out): fall back.
      total: max((d?.object(forKey: "total") as? Int) ?? 10, 1),
      target: max((d?.object(forKey: "target") as? Int) ?? 7, 1),
      streak: d?.integer(forKey: "streak") ?? 0,
      day: d?.integer(forKey: "day") ?? 0,
      protein: isToday ? (d?.integer(forKey: "protein") ?? 0) : 0,
      cardsDue: d?.integer(forKey: "cards_due") ?? 0,
      phase: d?.string(forKey: "phase") ?? "",
      blockTime: time,
      blockTitle: current?.t ?? "Open ONO",
      isToday: isToday)
  }
}

// MARK: - Views

private struct ScoreRing: View {
  let score: Int
  var total: Int = 10
  var target: Int = 7
  var lineWidth: CGFloat = 7

  var body: some View {
    ZStack {
      Circle().stroke(Color.onoCard, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: CGFloat(min(score, total)) / CGFloat(total))
        .stroke(Color.onoAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
      VStack(spacing: 0) {
        Text("\(score)")
          .font(.system(size: 26, weight: .regular, design: .serif))
          .foregroundStyle(score >= target ? Color.onoAccent : Color.onoIvory)
        Text("/\(total)").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.onoGrey)
      }
    }
  }
}

private struct SmallView: View {
  let e: OnoEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("ONO").font(.system(size: 11, weight: .bold)).tracking(2)
          .foregroundStyle(Color.onoAccent)
        Spacer()
        Label("\(e.streak)", systemImage: "flame.fill")
          .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.onoIvory)
      }
      ScoreRing(score: e.score, total: e.total, target: e.target).frame(width: 64, height: 64)
        .frame(maxWidth: .infinity)
      Text(e.score >= e.target ? "Day held" : "\(e.target - e.score) to hold")
        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.onoGrey)
        .frame(maxWidth: .infinity)
    }
  }
}

private struct MediumView: View {
  let e: OnoEntry
  var body: some View {
    HStack(spacing: 16) {
      VStack(spacing: 6) {
        ScoreRing(score: e.score, total: e.total, target: e.target, lineWidth: 8).frame(width: 76, height: 76)
        Label("\(e.streak)", systemImage: "flame.fill")
          .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.onoIvory)
      }
      VStack(alignment: .leading, spacing: 5) {
        Text("\(e.blockTime) · NOW").font(.system(size: 10, weight: .bold)).tracking(1.5)
          .foregroundStyle(Color.onoAccent)
        Text(e.isToday ? e.blockTitle : "Open ONO to start today")
          .font(.system(size: 17, weight: .regular, design: .serif))
          .foregroundStyle(Color.onoIvory).lineLimit(2)
        Spacer(minLength: 2)
        Text("Protein \(e.protein)/150 g").font(.system(size: 11, weight: .semibold))
          .foregroundStyle(e.protein >= 150 ? Color.onoAccent : Color.onoGrey)
        Text(e.cardsDue > 0 ? "\(e.cardsDue) cards to review" : "Review done")
          .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.onoGrey)
        Text("Day \(e.day) · \(e.phase)").font(.system(size: 11)).foregroundStyle(Color.onoGrey)
      }
      Spacer(minLength: 0)
    }
  }
}

struct OnoWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: OnoEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: Double(min(entry.score, entry.total)), in: 0...Double(entry.total)) {
        Text("ONO")
      } currentValueLabel: {
        Text("\(entry.score)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 1) {
        Text("ONO · \(entry.score)/\(entry.total)").font(.headline)
        Text("\(entry.streak)-day streak")
        Text("\(entry.blockTime) \(entry.blockTitle)").lineLimit(1)
      }
    case .accessoryInline:
      Text("\(entry.score)/\(entry.total) · \(entry.streak)-day streak")
    case .systemMedium:
      MediumView(e: entry)
    default:
      SmallView(e: entry)
    }
  }
}

struct ONOWidget: Widget {
  let kind = "ONOWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OnoProvider()) { entry in
      OnoWidgetView(entry: entry)
        .containerBackground(Color.onoBackground, for: .widget)
    }
    .configurationDisplayName("ONO")
    .description("Daily 10, streak and what this moment asks for.")
    .supportedFamilies([
      .systemSmall, .systemMedium,
      .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ])
  }
}

// MARK: - Today's list, ticked from the Home Screen (iOS 17)

/// One daily item as the app writes it ("items" in the app group).
struct OnoItem: Codable, Hashable {
  let id: String
  let t: String
  var d: Bool
}

/// The app group holds what the widget shows and the ticks waiting for the
/// app ("pending_ticks"), which ONO records the next time it opens.
enum OnoTicks {
  static func items(_ d: UserDefaults?) -> [OnoItem] {
    guard let json = d?.string(forKey: "items"), let data = json.data(using: .utf8),
          let list = try? JSONDecoder().decode([OnoItem].self, from: data)
    else { return [] }
    return list
  }

  static func toggle(_ id: String, day: String) {
    guard let d = UserDefaults(suiteName: appGroup) else { return }
    var list = items(d)
    guard let i = list.firstIndex(where: { $0.id == id }) else { return }
    list[i].d.toggle()
    if let data = try? JSONEncoder().encode(list), let json = String(data: data, encoding: .utf8) {
      d.set(json, forKey: "items")
    }
    if d.string(forKey: "date") == day {
      d.set(list.filter { $0.d }.count, forKey: "score")
    }
    var pending: [[String: Any]] = []
    if let json = d.string(forKey: "pending_ticks"), let data = json.data(using: .utf8),
       let old = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
      pending = old
    }
    pending.append(["id": id, "date": day, "on": list[i].d])
    if let data = try? JSONSerialization.data(withJSONObject: pending),
       let json = String(data: data, encoding: .utf8) {
      d.set(json, forKey: "pending_ticks")
    }
  }
}

struct OnoTickIntent: AppIntent {
  static var title: LocalizedStringResource = "Tick a daily item"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Item") var itemId: String
  @Parameter(title: "Day") var day: String

  init() {}

  init(itemId: String, day: String) {
    self.itemId = itemId
    self.day = day
  }

  func perform() async throws -> some IntentResult {
    OnoTicks.toggle(itemId, day: day)
    return .result()
  }
}

struct ItemsEntry: TimelineEntry {
  let date: Date
  let day: String
  let items: [OnoItem]
  let score: Int
  let target: Int
  let first: String
  let isToday: Bool

  static let sample = ItemsEntry(
    date: Date(), day: "", score: 1, target: 2, first: "",
    items: [OnoItem(id: "a", t: "Morning walk", d: true), OnoItem(id: "b", t: "Read 20 minutes", d: false),
            OnoItem(id: "c", t: "Call someone", d: false)],
    isToday: true)

  init(date: Date, day: String, score: Int, target: Int, first: String, items: [OnoItem], isToday: Bool) {
    self.date = date
    self.day = day
    self.items = items
    self.score = score
    self.target = target
    self.first = first
    self.isToday = isToday
  }
}

struct ItemsProvider: TimelineProvider {
  func placeholder(in context: Context) -> ItemsEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (ItemsEntry) -> Void) {
    completion(context.isPreview ? .sample : entry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ItemsEntry>) -> Void) {
    let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
    completion(Timeline(entries: [entry()], policy: .after(midnight)))
  }

  private func entry() -> ItemsEntry {
    let d = UserDefaults(suiteName: appGroup)
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.dateFormat = "yyyy-MM-dd"
    let day = d?.string(forKey: "date") ?? ""
    let list = OnoTicks.items(d)
    return ItemsEntry(
      date: Date(), day: day,
      score: list.filter { $0.d }.count,
      target: max((d?.object(forKey: "target") as? Int) ?? 1, 1),
      first: d?.string(forKey: "first") ?? "",
      items: list,
      isToday: day == f.string(from: Date()))
  }
}

struct ItemsView: View {
  @Environment(\.widgetFamily) private var family
  let e: ItemsEntry

  var body: some View {
    let large = family == .systemLarge
    // Medium shows the next open items; large shows the whole list.
    let shown = Array((large ? e.items : e.items.filter { !$0.d }).prefix(large ? 8 : 3))
    VStack(alignment: .leading, spacing: large ? 8 : 6) {
      HStack {
        Text("Today").font(.headline).foregroundStyle(Color.onoIvory)
        Spacer()
        Text("\(e.score)/\(e.items.count)")
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(e.score >= e.target ? Color.onoAccent : Color.onoGrey)
      }
      if !e.isToday || e.items.isEmpty {
        Text("Open ONO to start today.").font(.subheadline).foregroundStyle(Color.onoGrey)
      } else if shown.isEmpty {
        Text("Everything on today's list is done.").font(.subheadline).foregroundStyle(Color.onoGrey)
      } else {
        ForEach(shown, id: \.id) { item in
          Button(intent: OnoTickIntent(itemId: item.id, day: e.day)) {
            HStack(spacing: 8) {
              Image(systemName: item.d ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.d ? Color.onoAccent : Color.onoGrey)
              Text(item.t)
                .font(.subheadline)
                .foregroundStyle(item.d ? Color.onoGrey : Color.onoIvory)
                .lineLimit(1)
              Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      if large && e.isToday && !e.first.isEmpty {
        Spacer(minLength: 0)
        Text("First of today's three: \(e.first)")
          .font(.caption)
          .foregroundStyle(Color.onoGrey)
          .lineLimit(2)
      }
      Spacer(minLength: 0)
    }
  }
}

struct ONOItemsWidget: Widget {
  let kind = "ONOItems"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ItemsProvider()) { entry in
      ItemsView(e: entry)
        .containerBackground(Color.onoBackground, for: .widget)
    }
    .configurationDisplayName("ONO · today's list")
    .description("Tick your daily items from the Home Screen.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Lock Screen countdown (Live Activity)

/// Must match the struct of the same name in ios/Runner/AppDelegate.swift.
struct OnoTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var endsAt: Date
    var next: String
  }

  var kind: String
}

private func timerIcon(_ kind: String) -> String {
  switch kind {
  case "focus": return "brain.head.profile"
  case "rest": return "dumbbell.fill"
  default: return "timer"
  }
}

/// Counts down by itself: the system redraws the time, ONO needn't run.
private func countdown(_ endsAt: Date) -> Text {
  let now = Date()
  return Text(timerInterval: min(now, endsAt)...endsAt, countsDown: true)
}

struct OnoTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: OnoTimerAttributes.self) { context in
      HStack(spacing: 12) {
        Image(systemName: timerIcon(context.attributes.kind))
          .font(.title2)
          .foregroundStyle(Color.onoAccent)
        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.title)
            .font(.headline)
            .foregroundStyle(Color.onoIvory)
            .lineLimit(1)
          if !context.state.next.isEmpty {
            Text("Next: \(context.state.next)")
              .font(.caption)
              .foregroundStyle(Color.onoGrey)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 8)
        countdown(context.state.endsAt)
          .font(.system(size: 34, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(Color.onoIvory)
          .multilineTextAlignment(.trailing)
          .frame(width: 112, alignment: .trailing)
      }
      .padding(16)
      .activityBackgroundTint(Color.onoBackground)
      .activitySystemActionForegroundColor(Color.onoAccent)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: timerIcon(context.attributes.kind))
            .font(.title2)
            .foregroundStyle(Color.onoAccent)
        }
        DynamicIslandExpandedRegion(.trailing) {
          countdown(context.state.endsAt)
            .font(.title2)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .frame(width: 80, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.next.isEmpty
               ? context.state.title
               : "\(context.state.title) · next: \(context.state.next)")
            .font(.caption)
            .lineLimit(1)
        }
      } compactLeading: {
        Image(systemName: timerIcon(context.attributes.kind))
          .foregroundStyle(Color.onoAccent)
      } compactTrailing: {
        countdown(context.state.endsAt)
          .monospacedDigit()
          .multilineTextAlignment(.trailing)
          .frame(width: 44)
      } minimal: {
        Image(systemName: timerIcon(context.attributes.kind))
          .foregroundStyle(Color.onoAccent)
      }
      .keylineTint(Color.onoAccent)
    }
  }
}

@main
struct ONOWidgetBundle: WidgetBundle {
  var body: some Widget {
    ONOWidget()
    ONOItemsWidget()
    OnoTimerLiveActivity()
  }
}
