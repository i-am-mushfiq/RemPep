import SwiftUI
import SwiftData

enum PeopleFilter: String, CaseIterable, Identifiable {
    case all, due, overdue, onTrack, close, important, familiar, occasional, recent, never
    var id: String { rawValue }
    var title: String {
        switch self { case .onTrack: "On track"; case .recent: "Recently contacted"; case .never: "Never contacted"; default: rawValue.capitalized }
    }
}

enum PeopleSort: String, CaseIterable, Identifiable {
    case dueDate, tier, lastInteraction, name
    var id: String { rawValue }
    var title: String {
        switch self { case .dueDate: "Due date"; case .lastInteraction: "Last interaction"; default: rawValue.capitalized }
    }
}

private enum PeopleLayout: String {
    case list, board
}

struct PeopleView: View {
    @Query private var people: [Person]
    @State private var search = ""
    @State private var filter: PeopleFilter = .all
    @State private var sort: PeopleSort = .dueDate
    @State private var showAdd = false
    @State private var deepLinkedPerson: Person?
    @State private var layout: PeopleLayout = .list

    private var active: [Person] { people.filter { $0.archivedAt == nil } }
    private var boardPeople: [Person] { active.filter { search.isEmpty || $0.name.localizedStandardContains(search) } }
    private var visible: [Person] {
        let searched = active.filter { search.isEmpty || $0.name.localizedStandardContains(search) }
        let filtered = searched.filter { person in
            switch filter {
            case .all: true
            case .due: [.today, .dueSoon].contains(person.status())
            case .overdue: person.status() == .drifting
            case .onTrack: person.status() == .onTrack
            case .close: person.tier == .close
            case .important: person.tier == .important
            case .familiar: person.tier == .familiar
            case .occasional: person.tier == .occasional
            case .recent: person.lastInteractionDate.map { $0 > Calendar.current.date(byAdding: .day, value: -7, to: Date())! } ?? false
            case .never: person.lastInteractionDate == nil
            }
        }
        return filtered.sorted { lhs, rhs in
            switch sort {
            case .dueDate: lhs.calculatedDueDate == rhs.calculatedDueDate ? lhs.name < rhs.name : lhs.calculatedDueDate < rhs.calculatedDueDate
            case .tier: lhs.tier.priority == rhs.tier.priority ? lhs.name < rhs.name : lhs.tier.priority > rhs.tier.priority
            case .lastInteraction: (lhs.lastInteractionDate ?? .distantPast) > (rhs.lastInteractionDate ?? .distantPast)
            case .name: lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if layout == .list {
                    List {
                        Section {
                            HStack(spacing: 10) {
                                StatusCount(title: "Ready", value: active.filter { [.today, .drifting].contains($0.status()) }.count, color: .yellow)
                                StatusCount(title: "Soon", value: active.filter { $0.status() == .dueSoon }.count, color: .orange)
                                StatusCount(title: "On track", value: active.filter { $0.status() == .onTrack }.count, color: .green)
                            }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                        }
                        Section {
                            ForEach(visible) { person in
                                NavigationLink(value: person) { PersonRow(person: person) }
                            }
                        } header: { Text("\(visible.count) people") }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    TierBoardView(people: boardPeople, sort: sort)
                        .transition(.opacity)
                }
            }
            .background(ConnectTheme.background)
            .navigationTitle("People")
            .searchable(text: $search, prompt: "Search people")
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { withAnimation(.easeInOut(duration: 0.2)) { layout = layout == .list ? .board : .list } } label: { Image(systemName: layout == .list ? "rectangle.split.3x1" : "list.bullet") }
                        .accessibilityLabel(layout == .list ? "Show tier board" : "Show people list")
                    Menu {
                        if layout == .list {
                            Picker("Filter", selection: $filter) { ForEach(PeopleFilter.allCases) { Text($0.title).tag($0) } }
                            Divider()
                        }
                        Picker("Sort", selection: $sort) { ForEach(PeopleSort.allCases) { Text($0.title).tag($0) } }
                    } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddPersonView() }
            .sheet(item: $deepLinkedPerson) { person in NavigationStack { PersonDetailView(person: person) } }
            .onAppear { openDeepLinkIfNeeded() }
            .onChange(of: DeepLinkRouter.shared.selectedPersonID) { _, _ in openDeepLinkIfNeeded() }
            .overlay { if active.isEmpty { ContentUnavailableView("Your relationships live here", systemImage: "person.2", description: Text("Add the people you want to stay connected with.")) } }
        }
    }

    private func openDeepLinkIfNeeded() {
        guard let id = DeepLinkRouter.shared.selectedPersonID, let person = people.first(where: { $0.id == id }) else { return }
        deepLinkedPerson = person
        DeepLinkRouter.shared.selectedPersonID = nil
    }
}

private struct StatusCount: View {
    let title: String; let value: Int; let color: Color
    var body: some View { VStack(alignment: .leading, spacing: 3) { Text("\(value)").font(.title2.bold()).foregroundStyle(color); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 16)) }
}

private struct PersonRow: View {
    let person: Person
    var body: some View {
        HStack(spacing: 12) {
            PersonAvatar(person: person, size: 44)
            VStack(alignment: .leading, spacing: 3) { Text(person.name).font(.headline); HStack { Circle().fill(person.status().color).frame(width: 7, height: 7); Text(person.status().title); Text("· Every \(person.targetIntervalDays) days") }.font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 4).accessibilityElement(children: .combine)
    }
}
