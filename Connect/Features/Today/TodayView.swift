import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @Query private var settingsList: [UserSettings]
    @Binding var showQuickAdd: Bool
    @State private var loggingPerson: Person?
    @State private var selectedPerson: Person?
    @State private var showRecovery = false

    private var settings: UserSettings { settingsList.first ?? UserSettings() }
    private var activePeople: [Person] { people.filter { $0.archivedAt == nil } }
    private var completed: Int { MetricsService().completedToday(activePeople) }
    private var queue: [Person] {
        let ids = SchedulingEngine().queue(candidates: activePeople.map(\.scheduleCandidate), on: Date(), target: settings.dailyTarget, maximum: settings.dailyMaximum).map(\.id)
        return ids.compactMap { id in activePeople.first { $0.id == id } }
    }
    private var isRecoverySuggested: Bool {
        activePeople.filter { $0.calculatedDueDate < Calendar.current.date(byAdding: .day, value: -7, to: Date())! }.count > settings.dailyMaximum
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting).font(.subheadline).foregroundStyle(.secondary)
                        Text("Today").font(.largeTitle.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 16) {
                        ProgressRing(completed: completed, target: settings.dailyTarget)
                        Text(completed >= settings.dailyTarget ? "Your rhythm is on track." : "A small amount of attention goes a long way.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity)

                    if isRecoverySuggested {
                        Button { showRecovery = true } label: {
                            ConnectCard {
                                Label("Let's reconnect gradually", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.headline)
                                Text("Your schedule can be spread out again—no catching up all at once.").font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
                            }
                        }.buttonStyle(.plain)
                    }

                    SectionLabel(text: "Today's connections")
                    if activePeople.isEmpty {
                        EmptyPeopleCard { showQuickAdd = true }
                    } else if queue.isEmpty {
                        ConnectCard {
                            Label("You're caught up", systemImage: "checkmark.circle.fill").font(.title3.bold()).foregroundStyle(ConnectTheme.accent)
                            Text("Nothing needs your attention today.").foregroundStyle(.secondary).padding(.top, 2)
                        }
                    } else {
                        ForEach(queue) { person in
                            TodayPersonCard(person: person, connect: { loggingPerson = person }, open: { selectedPerson = person })
                        }
                    }

                    if let tip = RapportService().tip() {
                        SectionLabel(text: "A thought for today")
                        ConnectCard { Label(tip, systemImage: "quote.bubble").font(.body) }
                    }
                }.padding()
            }
            .background(ConnectTheme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { showQuickAdd = true } label: { Image(systemName: "plus").font(.headline) }.accessibilityLabel("Quick add") }
            }
            .sheet(item: $loggingPerson) { person in InteractionLoggingView(person: person) }
            .sheet(item: $selectedPerson) { person in NavigationStack { PersonDetailView(person: person) } }
            .confirmationDialog("Reconnect gradually", isPresented: $showRecovery, titleVisibility: .visible) {
                Button("Rebalance my schedule") { RelationshipService(context: context).rebalance(activePeople, dailyTarget: settings.dailyTarget) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("We'll spread ready connections across the coming days, starting with today's manageable target.") }
            .onAppear { refreshWidget() }
            .onChange(of: completed) { _, _ in refreshWidget() }
        }
    }

    private func refreshWidget() { WidgetSnapshotService.write(queue: queue, completed: completed, target: settings.dailyTarget) }
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) { case 5..<12: "Good morning"; case 12..<18: "Good afternoon"; default: "Good evening" }
    }
}

private struct TodayPersonCard: View {
    let person: Person
    let connect: () -> Void
    let open: () -> Void
    var body: some View {
        ConnectCard {
            HStack(alignment: .top, spacing: 14) {
                PersonAvatar(person: person)
                VStack(alignment: .leading, spacing: 5) {
                    Text(person.name).font(.headline)
                    Text(person.calculatedDueDate.friendlyDueDescription).font(.caption).foregroundStyle(person.status().color)
                    Text(RapportService().contextualLine(for: person)).font(.subheadline).foregroundStyle(.secondary).lineLimit(2).padding(.top, 4)
                    HStack {
                        Button("Connect", action: connect).buttonStyle(.borderedProminent).controlSize(.regular)
                        Button("Context", action: open).buttonStyle(.bordered).controlSize(.regular)
                    }.padding(.top, 8)
                }
            }
        }
    }
}

private struct EmptyPeopleCard: View {
    let action: () -> Void
    var body: some View {
        ConnectCard {
            Text("Your relationships live here.").font(.title3.bold())
            Text("Add the people you want to stay connected with.").foregroundStyle(.secondary).padding(.vertical, 4)
            Button("Add someone", action: action).buttonStyle(.borderedProminent).padding(.top, 4)
        }
    }
}
