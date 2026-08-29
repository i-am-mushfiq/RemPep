import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @Bindable var settings: UserSettings
    @State private var step = 0
    @State private var showAdd = false
    @State private var showContacts = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) { ForEach(0..<4) { index in Capsule().fill(index <= step ? ConnectTheme.accent : ConnectTheme.elevated).frame(height: 4) } }.padding()
            TabView(selection: $step) {
                IntroStep().tag(0)
                PeopleStep(count: people.filter { $0.archivedAt == nil }.count, add: { showAdd = true }, contacts: { showContacts = true }).tag(1)
                CapacityStep(settings: settings).tag(2)
                NotificationStep().tag(3)
            }.tabViewStyle(.page(indexDisplayMode: .never)).animation(.easeInOut(duration: 0.25), value: step)
            Button(step == 3 ? "Start connecting" : "Continue") { advance() }.buttonStyle(.borderedProminent).controlSize(.large).padding().frame(maxWidth: .infinity)
        }
        .background(ConnectTheme.background)
        .sheet(isPresented: $showAdd) { AddPersonView() }
        .sheet(isPresented: $showContacts) { ContactImportView() }
    }

    private func advance() {
        if step < 3 { step += 1 } else {
            settings.onboardingComplete = true
            try? context.save()
            let level = settings.notificationLevel, target = settings.dailyTarget, hour = settings.reminderHour, minute = settings.reminderMinute
            Task { _ = await NotificationService.shared.requestAuthorization(); await NotificationService.shared.updateDailyReminder(level: level, target: target, hour: hour, minute: minute) }
        }
    }
}

private struct IntroStep: View {
    var body: some View { VStack(spacing: 20) { Spacer(); Image(systemName: "person.2.wave.2.fill").font(.system(size: 64)).foregroundStyle(ConnectTheme.accent); Text("Stay connected\nwithout remembering everything").font(.largeTitle.bold()).multilineTextAlignment(.center); Text("Connect keeps the context and the timing. You keep the relationship human.").font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal); Spacer() }.padding() }
}
private struct PeopleStep: View {
    let count: Int; let add: () -> Void; let contacts: () -> Void
    var body: some View { VStack(spacing: 18) { Spacer(); Text("Who matters to you?").font(.largeTitle.bold()); Text(count == 0 ? "Start with a few people. You can add the rest anytime." : "\(count) people added").foregroundStyle(.secondary).multilineTextAlignment(.center); Button(action: contacts) { Label("Choose from Contacts", systemImage: "person.crop.circle.badge.plus") }.buttonStyle(.borderedProminent).controlSize(.large); Button("Add manually", action: add).buttonStyle(.bordered); Spacer() }.padding() }
}
private struct CapacityStep: View {
    @Bindable var settings: UserSettings
    var body: some View { VStack(spacing: 24) { Spacer(); Text("What feels manageable?").font(.largeTitle.bold()).multilineTextAlignment(.center); Text("Daily connections").foregroundStyle(.secondary); HStack { ForEach(1...5, id: \.self) { value in Button("\(value)") { settings.dailyTarget = value; settings.dailyMinimum = max(0, value - 1); settings.dailyMaximum = value + 2 }.buttonStyle(.borderedProminent).tint(value == settings.dailyTarget ? ConnectTheme.accent : ConnectTheme.elevated).controlSize(.large) } }; Text("We'll keep each day close to this target and gently rebalance when life gets busy.").foregroundStyle(.secondary).multilineTextAlignment(.center); Spacer() }.padding() }
}
private struct NotificationStep: View {
    var body: some View { VStack(spacing: 20) { Spacer(); Image(systemName: "bell.badge.fill").font(.system(size: 58)).foregroundStyle(ConnectTheme.accent); Text("One gentle reminder").font(.largeTitle.bold()); Text("Connect sends a single aggregate reminder by default—never a stream of guilt-inducing alerts.").foregroundStyle(.secondary).multilineTextAlignment(.center); Text("You can change this anytime in Settings.").font(.footnote).foregroundStyle(.tertiary); Spacer() }.padding() }
}
