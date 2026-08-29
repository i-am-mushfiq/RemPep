import SwiftUI
import SwiftData

@main
struct ConnectApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(ConnectTheme.accent)
                .onOpenURL { DeepLinkRouter.shared.handle($0) }
        }
        .modelContainer(persistence.container)
    }
}

@MainActor
@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()
    var selectedPersonID: UUID?
    var requestedTab: AppTab = .today

    func handle(_ url: URL) {
        guard url.scheme == "connect" else { return }
        if url.host == "person", let value = url.pathComponents.dropFirst().first { selectedPersonID = UUID(uuidString: value); requestedTab = .people }
        else { requestedTab = .today }
    }
}

enum AppTab: Hashable { case today, people, trends, settings }
