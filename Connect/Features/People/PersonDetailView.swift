import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Bindable var person: Person
    @State private var showLog = false
    @State private var showMemory = false
    @State private var showPrompt = false
    @State private var showEdit = false
    @State private var showDate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) { PersonAvatar(person: person, size: 92); Text(person.name).font(.largeTitle.bold()); Text("Every \(person.targetIntervalDays) days · \(person.tier.title)").foregroundStyle(.secondary) }
                ConnectCard {
                    SectionLabel(text: "Next connection")
                    Text(person.calculatedDueDate.formatted(date: .long, time: .omitted)).font(.title2.bold()).padding(.top, 5)
                    Text(person.calculatedDueDate.friendlyDueDescription).foregroundStyle(person.status().color)
                }
                if !person.activeMemories.isEmpty {
                    VStack(alignment: .leading, spacing: 10) { SectionLabel(text: "Remember"); ForEach(person.activeMemories.prefix(5)) { memory in ConnectCard { Text(memory.category.title).font(.caption).foregroundStyle(ConnectTheme.accent); Text(memory.content).font(.body).padding(.top, 2) } } }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if !(person.importantDates ?? []).isEmpty {
                    VStack(alignment: .leading, spacing: 10) { SectionLabel(text: "Important dates"); ForEach(person.importantDates ?? []) { date in ConnectCard { HStack { VStack(alignment: .leading) { Text(date.title).font(.headline); Text(date.kind.title).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(date.date.formatted(date: .abbreviated, time: .omitted)) } } } }.frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "History")
                    if person.activeInteractions.isEmpty { Text("Your first connection will appear here.").foregroundStyle(.secondary).padding() }
                    ForEach(person.activeInteractions) { interaction in
                        HStack { Image(systemName: interaction.type.symbol).frame(width: 28).foregroundStyle(ConnectTheme.accent); VStack(alignment: .leading) { Text(interaction.type.title).font(.headline); Text(interaction.quality.title).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(interaction.timestamp.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary) }.padding(.vertical, 6)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding().padding(.bottom, 80)
        }
        .background(ConnectTheme.background)
        .navigationTitle(person.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Button("Edit", systemImage: "pencil") { showEdit = true }; Button("Add memory", systemImage: "brain.head.profile") { showMemory = true }; Button("Add important date", systemImage: "calendar.badge.plus") { showDate = true }; Button("Snooze 2 days", systemImage: "clock") { RelationshipService(context: context).snooze(person) }; Divider(); Button("Archive", systemImage: "archivebox") { RelationshipService(context: context).archive(person) } } label: { Image(systemName: "ellipsis.circle") } } }
        .safeAreaInset(edge: .bottom) {
            HStack { Button { showPrompt = true } label: { Label("Help me start", systemImage: "sparkles") }.buttonStyle(.bordered); Button { showLog = true } label: { Label("Connect now", systemImage: "message.fill") }.buttonStyle(.borderedProminent) }.padding().frame(maxWidth: .infinity).background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showLog) { InteractionLoggingView(person: person) }
        .sheet(isPresented: $showMemory) { MemoryEditor(person: person) }
        .sheet(isPresented: $showDate) { ImportantDateEditor(person: person) }
        .sheet(isPresented: $showPrompt) { ConversationPromptView(person: person) }
        .sheet(isPresented: $showEdit) { PersonEditor(person: person) }
    }
}

private struct PersonEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var person: Person
    var body: some View { NavigationStack { Form { TextField("Name", text: $person.name); Picker("Tier", selection: $person.tierRaw) { ForEach(RelationshipTier.allCases) { Text($0.title).tag($0.rawValue) } }; Stepper("Every \(person.targetIntervalDays) days", value: $person.targetIntervalDays, in: 1...365); TextField("Notes", text: $person.notes, axis: .vertical) } .navigationTitle("Edit person").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { try? context.save(); dismiss() } } } } }
}

struct MemoryEditor: View {
    @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context
    let person: Person; @State private var content = ""; @State private var category: MemoryCategory = .general; @State private var lifespan: MemoryLifespan = .longTerm; @State private var expiresAt = Date(); @State private var hasExpiration = false
    var body: some View { NavigationStack { Form { TextField("What do you want to remember?", text: $content, axis: .vertical).lineLimit(3...6); Picker("Category", selection: $category) { ForEach(MemoryCategory.allCases) { Text($0.title).tag($0) } }; Picker("Lifespan", selection: $lifespan) { ForEach(MemoryLifespan.allCases) { Text($0.title).tag($0) } }; Toggle("Expiration date", isOn: $hasExpiration); if hasExpiration { DatePicker("Expires", selection: $expiresAt, displayedComponents: .date) } }.navigationTitle("Add memory").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { context.insert(Memory(person: person, content: content, category: category, lifespan: lifespan, expiresAt: hasExpiration ? expiresAt : nil)); try? context.save(); dismiss() }.disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } } } }
}

private struct ImportantDateEditor: View {
    @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context
    let person: Person; @State private var title = ""; @State private var date = Date(); @State private var kind: ImportantDateKind = .birthday; @State private var repeats = true
    var body: some View { NavigationStack { Form { TextField("Title", text: $title); DatePicker("Date", selection: $date, displayedComponents: .date); Picker("Type", selection: $kind) { ForEach(ImportantDateKind.allCases) { Text($0.title).tag($0) } }; Toggle("Repeats yearly", isOn: $repeats) }.navigationTitle("Important date").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { context.insert(ImportantDate(person: person, title: title.isEmpty ? kind.title : title, date: date, kind: kind, repeatsYearly: repeats)); try? context.save(); dismiss() } } } } }
}
