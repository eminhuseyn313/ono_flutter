// ONO Home Screen and Lock Screen widget.
// The Flutter app writes a snapshot into the shared app group (see
// lib/services/widget_sync.dart); this extension only reads and draws it.
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
    date: Date(), score: 7, streak: 12, day: 41, protein: 110, cardsDue: 6,
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
  var lineWidth: CGFloat = 7

  var body: some View {
    ZStack {
      Circle().stroke(Color.onoCard, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: CGFloat(min(score, 10)) / 10)
        .stroke(Color.onoAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
      VStack(spacing: 0) {
        Text("\(score)")
          .font(.system(size: 26, weight: .regular, design: .serif))
          .foregroundStyle(score >= 7 ? Color.onoAccent : Color.onoIvory)
        Text("/10").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.onoGrey)
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
      ScoreRing(score: e.score).frame(width: 64, height: 64)
        .frame(maxWidth: .infinity)
      Text(e.score >= 7 ? "Day held" : "\(7 - e.score) to hold")
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
        ScoreRing(score: e.score, lineWidth: 8).frame(width: 76, height: 76)
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
      Gauge(value: Double(min(entry.score, 10)), in: 0...10) {
        Text("ONO")
      } currentValueLabel: {
        Text("\(entry.score)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 1) {
        Text("ONO · \(entry.score)/10").font(.headline)
        Text("\(entry.streak)-day streak")
        Text("\(entry.blockTime) \(entry.blockTitle)").lineLimit(1)
      }
    case .accessoryInline:
      Text("\(entry.score)/10 · \(entry.streak)-day streak")
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

@main
struct ONOWidgetBundle: WidgetBundle {
  var body: some Widget { ONOWidget() }
}
