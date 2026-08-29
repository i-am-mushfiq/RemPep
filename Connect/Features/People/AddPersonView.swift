import SwiftUI
import SwiftData

struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var tier: RelationshipTier = .familiar
    @State private var interval = 30
    @State private var memory = ""
    @State private var showContacts = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name).textContentType(.name)
                    Button { showContacts = true } label: { Label("Add from Contacts", systemImage: "person.crop.circle.badge.plus") }
                }
                Section("How often do you want to reconnect?") {
                    Picker("Frequency", selection: $tier) { ForEach(RelationshipTier.allCases) { Text($0.title).tag($0) } }.onChange(of: tier) { _, newValue in if newValue != .custom { interval = newValue.defaultInterval } }
                    Stepper("Every \(interval) days", value: $interval, in: 1...365)
                }
                Section("Optional context") { TextField("What do you want to remember?", text: $memory, axis: .vertical).lineLimit(2...5) }
            }
            .navigationTitle("Add person").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { _ = RelationshipService(context: context).addPerson(name: name, tier: tier, interval: interval, initialMemory: memory); dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .sheet(isPresented: $showContacts) { ContactImportView() }
        }
    }
}

struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var contacts: [ImportedContact] = []
    @State private var selected: Set<String> = []
    @State private var tier: RelationshipTier = .familiar
    @State private var interval = 30
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        NavigationStack {
            List(contacts) { contact in
                Button { if selected.contains(contact.id) { selected.remove(contact.id) } else { selected.insert(contact.id) } } label: {
                    HStack { Image(systemName: selected.contains(contact.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.contains(contact.id) ? ConnectTheme.accent : .secondary); Text(contact.name).foregroundStyle(.primary); Spacer() }
                }.buttonStyle(.plain)
            }
            .overlay { if loading { ProgressView("Loading contacts…") } else if let error { ContentUnavailableView("Contacts unavailable", systemImage: "person.crop.circle.badge.exclamationmark", description: Text(error)) } }
            .navigationTitle("Choose people")
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    VStack(spacing: 8) {
                        Picker("Frequency", selection: $tier) { ForEach(RelationshipTier.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented).onChange(of: tier) { _, value in if value != .custom { interval = value.defaultInterval } }
                        if tier == .custom { Stepper("Every \(interval) days", value: $interval, in: 1...365) }
                        Button("Add \(selected.count) people") { importSelected() }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                    }.padding().background(.ultraThinMaterial)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        do { contacts = try await ContactImportService().fetchContacts() } catch { self.error = error.localizedDescription }
        loading = false
    }
    private func importSelected() {
        for contact in contacts where selected.contains(contact.id) {
            let person = Person(name: contact.name, tier: tier, targetIntervalDays: interval)
            person.contactIdentifier = contact.id; person.phoneNumber = contact.phone; person.emailAddress = contact.email; person.photoData = contact.photoData
            context.insert(person)
        }
        try? context.save(); dismiss()
    }
}
