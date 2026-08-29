import Foundation
import WidgetKit

struct WidgetPersonSnapshot: Codable, Identifiable {
    let id: UUID
    let name: String
    let context: String
}

struct WidgetSnapshot: Codable {
    let date: Date
    let completed: Int
    let target: Int
    let people: [WidgetPersonSnapshot]
}

@MainActor
enum WidgetSnapshotService {
    static let suite = "group.com.connect.relationships"
    static let key = "widget.snapshot"

    static func write(queue: [Person], completed: Int, target: Int) {
        let snapshot = WidgetSnapshot(date: Date(), completed: completed, target: target, people: queue.prefix(3).map { .init(id: $0.id, name: $0.name, context: RapportService().contextualLine(for: $0)) })
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: suite)?.set(data, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "ConnectWidget")
    }
}
