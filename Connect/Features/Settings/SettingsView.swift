import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @Query private var settingsList: [UserSettings]
    @AppStorage("iCloudEnabled") private var iCloudEnabled = true
    @State private var exportDocument: ConnectExportDocument?
    @State private var exportType: UTType = .json
    @State private var exporting = false
    @State private var showArchived = false

    private var settings: UserSettings { settingsList.first ?? UserSettings() }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily connections") {
                    Stepper("Minimum: \(settings.dailyMinimum)", value: binding(\.dailyMinimum), in: 0...10)
                    Stepper("Target: \(settings.dailyTarget)", value: binding(\.dailyTarget), in: 1...15)
                    Stepper("Maximum: \(settings.dailyMaximum)", value: binding(\.dailyMaximum), in: 1...20)
                    Button("Rebalance schedule") { RelationshipService(context: context).rebalance(people.filter { $0.archivedAt == nil }, dailyTarget: settings.dailyTarget) }
                }
                Section("Notifications") {
                    Picker("Level", selection: Binding(get: { settings.notificationLevel }, set: { settings.notificationLevel = $0; saveAndSchedule() })) { ForEach(NotificationLevel.allCases) { Text($0.title).tag($0) } }
                    DatePicker("Reminder time", selection: reminderBinding, displayedComponents: .hourAndMinute)
                    Text("Reminders use aggregate counts by default and avoid relationship details.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Rapport & feedback") {
                    Toggle("Occasional rapport tips", isOn: binding(\.rapportLearningEnabled))
                    Toggle("Subtle haptics", isOn: binding(\.hapticsEnabled))
                }
                Section("Privacy & data") {
                    Toggle("Private iCloud sync", isOn: $iCloudEnabled).onChange(of: iCloudEnabled) { _, value in settings.iCloudEnabled = value; try? context.save() }
                    Text("Sync preference takes effect after relaunch. The app remains fully functional offline.").font(.footnote).foregroundStyle(.secondary)
                    Button("Export JSON") { prepareExport(type: .json) }
                    Button("Export people CSV") { prepareExport(type: .commaSeparatedText) }
                    Button("Archived people") { showArchived = true }
                }
                Section("About") {
                    LabeledContent("Connect", value: "1.0")
                    Text("Make remembering effortless and connecting easy, while keeping the actual relationship human.").font(.footnote).foregroundStyle(.secondary)
                    Text("No ads. No third-party relationship analytics. No automatic messages.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(ConnectTheme.background).navigationTitle("Settings")
            .fileExporter(isPresented: $exporting, document: exportDocument, contentType: exportType, defaultFilename: exportType == .json ? "Connect Export" : "Connect People") { _ in }
            .sheet(isPresented: $showArchived) { ArchivedPeopleView() }
        }
    }

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<UserSettings, T>) -> Binding<T> {
        Binding(get: { settings[keyPath: keyPath] }, set: { settings[keyPath: keyPath] = $0; normalize(); try? context.save() })
    }
    private var reminderBinding: Binding<Date> {
        Binding(get: { Calendar.current.date(from: DateComponents(hour: settings.reminderHour, minute: settings.reminderMinute)) ?? Date() }, set: { let parts = Calendar.current.dateComponents([.hour, .minute], from: $0); settings.reminderHour = parts.hour ?? 10; settings.reminderMinute = parts.minute ?? 0; saveAndSchedule() })
    }
    private func normalize() {
        settings.dailyMinimum = min(settings.dailyMinimum, settings.dailyTarget)
        settings.dailyMaximum = max(settings.dailyMaximum, settings.dailyTarget)
    }
    private func saveAndSchedule() {
        try? context.save()
        let level = settings.notificationLevel, target = settings.dailyTarget, hour = settings.reminderHour, minute = settings.reminderMinute
        let dateNotifications = people.flatMap { person in (person.importantDates ?? []).map { ImportantDateNotification(id: $0.id, personName: person.name, title: $0.title, kind: $0.kind.title, date: $0.date, repeatsYearly: $0.repeatsYearly) } }
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            await NotificationService.shared.updateDailyReminder(level: level, target: target, hour: hour, minute: minute)
            await NotificationService.shared.updateImportantDates(dateNotifications, level: level)
        }
    }
    private func prepareExport(type: UTType) {
        exportType = type
        let data: Data
        if type == .json { data = (try? ExportService().jsonData(people: people, settings: settings)) ?? Data() } else { data = ExportService().csvData(people: people) }
        exportDocument = ConnectExportDocument(data: data, type: type)
        exporting = true
    }
}

struct ConnectExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    let data: Data
    let type: UTType
    init(data: Data, type: UTType) { self.data = data; self.type = type }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data(); type = configuration.contentType }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

private struct ArchivedPeopleView: View {
    @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context; @Query private var people: [Person]
    var body: some View { NavigationStack { List(people.filter { $0.archivedAt != nil }) { person in HStack { Text(person.name); Spacer(); Button("Restore") { RelationshipService(context: context).restore(person) } } }.navigationTitle("Archived people").overlay { if people.allSatisfy({ $0.archivedAt == nil }) { ContentUnavailableView("No archived people", systemImage: "archivebox") } }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } } }
}
