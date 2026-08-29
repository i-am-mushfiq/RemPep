import WidgetKit
import SwiftUI

private struct WidgetPersonSnapshot: Codable, Identifiable {
    let id: UUID
    let name: String
    let context: String
}
private struct WidgetSnapshot: Codable {
    let date: Date
    let completed: Int
    let target: Int
    let people: [WidgetPersonSnapshot]
}

private struct ConnectEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private struct ConnectProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConnectEntry { .init(date: Date(), snapshot: .init(date: Date(), completed: 2, target: 3, people: [.init(id: UUID(), name: "Contact A", context: "Follow up on their recent update"), .init(id: UUID(), name: "Contact B", context: "Ask how their plans went")])) }
    func getSnapshot(in context: Context, completion: @escaping (ConnectEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ConnectEntry>) -> Void) {
        let entry = entry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
    private func entry() -> ConnectEntry {
        let defaults = UserDefaults(suiteName: "group.com.connect.relationships")
        let snapshot = defaults?.data(forKey: "widget.snapshot").flatMap { try? JSONDecoder().decode(WidgetSnapshot.self, from: $0) } ?? WidgetSnapshot(date: Date(), completed: 0, target: 3, people: [])
        return ConnectEntry(date: Date(), snapshot: snapshot)
    }
}

private struct ConnectWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ConnectEntry
    private var progress: Double { entry.snapshot.target > 0 ? min(1, Double(entry.snapshot.completed) / Double(entry.snapshot.target)) : 0 }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .accessoryCircular: Gauge(value: progress) { Text("Connections") } currentValueLabel: { Text("\(entry.snapshot.completed)/\(entry.snapshot.target)").font(.caption.bold()) }.gaugeStyle(.accessoryCircular)
        case .accessoryRectangular: VStack(alignment: .leading) { Text("Connections").font(.caption.bold()); Text("\(entry.snapshot.completed) of \(entry.snapshot.target) today"); if let first = entry.snapshot.people.first { Text(first.name).font(.caption2) } }
        default: medium
        }
    }
    private var small: some View {
        VStack(alignment: .leading) {
            Gauge(value: progress) { Text("Connections") } currentValueLabel: { Text("\(entry.snapshot.completed)/\(entry.snapshot.target)").font(.title3.bold()) }.gaugeStyle(.accessoryCircularCapacity).tint(Color(red: 0.31, green: 0.84, blue: 0.70))
            Spacer(); Text("connections").font(.headline); Text(entry.snapshot.completed >= entry.snapshot.target ? "In rhythm" : "Today").font(.caption).foregroundStyle(.secondary)
        }.widgetURL(URL(string: "connect://today"))
    }
    private var medium: some View {
        HStack(spacing: 16) {
            Gauge(value: progress) { Text("Connections") } currentValueLabel: { Text("\(entry.snapshot.completed)/\(entry.snapshot.target)").font(.headline) }.gaugeStyle(.accessoryCircularCapacity).tint(Color(red: 0.31, green: 0.84, blue: 0.70)).frame(width: 70)
            VStack(alignment: .leading, spacing: 5) {
                Text("TODAY").font(.caption2.bold()).foregroundStyle(.secondary)
                if entry.snapshot.people.isEmpty { Text("You're caught up").font(.headline) } else { ForEach(entry.snapshot.people.prefix(3)) { person in Link(destination: URL(string: "connect://person/\(person.id.uuidString)")!) { Text(person.name).font(.subheadline.weight(.semibold)).lineLimit(1) } } }
            }; Spacer()
        }
    }
}

struct ConnectWidget: Widget {
    let kind = "ConnectWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConnectProvider()) { entry in
            ConnectWidgetView(entry: entry).containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("Today's connections")
        .description("See your relationship rhythm and who is ready for a check-in.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct ConnectWidgetBundle: WidgetBundle {
    var body: some Widget { ConnectWidget() }
}
