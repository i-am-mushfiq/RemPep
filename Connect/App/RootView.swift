import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var allSettings: [UserSettings]
    @State private var selectedTab: AppTab = .today
    @State private var showQuickAdd = false

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        Group {
            if let settings, settings.onboardingComplete {
                TabView(selection: $selectedTab) {
                    TodayView(showQuickAdd: $showQuickAdd).tabItem { Label("Today", systemImage: "circle.circle.fill") }.tag(AppTab.today)
                    PeopleView().tabItem { Label("People", systemImage: "person.2.fill") }.tag(AppTab.people)
                    TrendsView().tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }.tag(AppTab.trends)
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(AppTab.settings)
                }
                .onChange(of: DeepLinkRouter.shared.requestedTab) { _, tab in selectedTab = tab }
                .sheet(isPresented: $showQuickAdd) { QuickAddView() }
            } else if let settings {
                OnboardingView(settings: settings)
            } else {
                ProgressView().task { _ = SettingsStore.current(in: context) }
            }
        }
        .background(ConnectTheme.background.ignoresSafeArea())
    }
}
