import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    let container: ModelContainer

    static let schema = Schema([
        Person.self, Interaction.self, Memory.self, ImportantDate.self,
        UserSettings.self, Milestone.self
    ])

    private init(inMemory: Bool = false) {
        if inMemory {
            container = try! ModelContainer(for: Self.schema, configurations: ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: true))
            return
        }
        do {
            let cloudPreference = UserDefaults.standard.object(forKey: "iCloudEnabled") as? Bool ?? true
            let primary = ModelConfiguration("Connect", schema: Self.schema, cloudKitDatabase: cloudPreference ? .automatic : .none)
            container = try ModelContainer(for: Self.schema, configurations: primary)
        } catch {
            do {
                let local = ModelConfiguration("ConnectLocal", schema: Self.schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: Self.schema, configurations: local)
            } catch {
                fatalError("Unable to create Connect data store: \(error.localizedDescription)")
            }
        }
    }

    static func preview() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: configuration)
    }
}

@MainActor
enum SettingsStore {
    static func current(in context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? context.fetch(descriptor).first { return settings }
        let settings = UserSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
