import AppIntents
import SwiftData

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Show today's connections"
    static var description = IntentDescription("Open your calm daily connection queue.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run { DeepLinkRouter.shared.requestedTab = .today }
        return .result(dialog: "Opening today's connections.")
    }
}

struct LogConnectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a connection"
    static var description = IntentDescription("Log a recent interaction by name.")
    @Parameter(title: "Person") var personName: String
    @Parameter(title: "Meaningful", default: false) var meaningful: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.container.mainContext
        let people = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        guard let person = people.first(where: { $0.archivedAt == nil && $0.name.localizedCaseInsensitiveCompare(personName) == .orderedSame }) else {
            return .result(dialog: "I couldn't find \(personName) in Connect.")
        }
        RelationshipService(context: context).logInteraction(for: person, type: .other, quality: meaningful ? .meaningful : .good)
        return .result(dialog: "Logged your connection with \(person.name).")
    }
}

struct GetOverduePeopleIntent: AppIntent {
    static var title: LocalizedStringResource = "Get people ready to reconnect"
    static var description = IntentDescription("See who is ready for a gentle check-in.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let context = PersistenceController.shared.container.mainContext
        let people = ((try? context.fetch(FetchDescriptor<Person>())) ?? []).filter { $0.archivedAt == nil && [.today, .drifting].contains($0.status()) }.sorted { $0.calculatedDueDate < $1.calculatedDueDate }
        let value = people.prefix(5).map(\.name).joined(separator: ", ")
        let message = value.isEmpty ? "You're caught up." : "Ready to reconnect: \(value)."
        return .result(value: value, dialog: IntentDialog(stringLiteral: message))
    }
}

struct ConnectShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenTodayIntent(), phrases: ["Show my connections in \(.applicationName)", "Who should I contact in \(.applicationName)"], shortTitle: "Today's connections", systemImageName: "person.2.fill")
        AppShortcut(intent: LogConnectionIntent(), phrases: ["Log a connection in \(.applicationName)"], shortTitle: "Log connection", systemImageName: "checkmark.bubble.fill")
        AppShortcut(intent: GetOverduePeopleIntent(), phrases: ["Who is ready in \(.applicationName)"], shortTitle: "Ready to reconnect", systemImageName: "clock.fill")
    }
}
