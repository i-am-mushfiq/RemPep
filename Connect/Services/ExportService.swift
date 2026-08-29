import Foundation

@MainActor
struct ExportService {
    func jsonData(people: [Person], settings: UserSettings) throws -> Data {
        let payload = ExportPayload(
            exportedAt: Date(),
            settings: .init(dailyMinimum: settings.dailyMinimum, dailyTarget: settings.dailyTarget, dailyMaximum: settings.dailyMaximum, notificationLevel: settings.notificationLevelRaw),
            people: people.map(ExportPerson.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func csvData(people: [Person]) -> Data {
        var rows = ["record_type,person_id,person_name,timestamp,type,quality,category,content,expires_at,tier,target_interval,next_due,archived"]
        let formatter = ISO8601DateFormatter()
        for person in people {
            rows.append(["person", person.id.uuidString, person.name, formatter.string(from: person.createdAt), "", "", "", person.notes, "", person.tierRaw, String(person.targetIntervalDays), formatter.string(from: person.calculatedDueDate), person.archivedAt == nil ? "false" : "true"].map(csvEscape).joined(separator: ","))
            for interaction in person.activeInteractions {
                rows.append(["interaction", person.id.uuidString, person.name, formatter.string(from: interaction.timestamp), interaction.typeRaw, interaction.qualityRaw, "", interaction.notes ?? "", "", "", "", "", ""].map(csvEscape).joined(separator: ","))
            }
            for memory in person.memories ?? [] {
                rows.append(["memory", person.id.uuidString, person.name, formatter.string(from: memory.createdAt), "", "", memory.categoryRaw, memory.content, memory.expiresAt.map(formatter.string) ?? "", "", "", "", ""].map(csvEscape).joined(separator: ","))
            }
            for date in person.importantDates ?? [] {
                rows.append(["important_date", person.id.uuidString, person.name, formatter.string(from: date.date), date.kindRaw, "", "", date.title, "", "", "", "", ""].map(csvEscape).joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    private func csvEscape(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
}

private struct ExportPayload: Codable {
    let exportedAt: Date
    let settings: ExportSettings
    let people: [ExportPerson]
}
private struct ExportSettings: Codable { let dailyMinimum: Int; let dailyTarget: Int; let dailyMaximum: Int; let notificationLevel: String }
private struct ExportPerson: Codable {
    let id: UUID; let name: String; let contactIdentifier: String?; let tier: String; let targetIntervalDays: Int; let notes: String; let createdAt: Date; let archivedAt: Date?; let manualDueDate: Date?; let interactions: [ExportInteraction]; let memories: [ExportMemory]; let importantDates: [ExportImportantDate]
    init(_ person: Person) {
        id = person.id; name = person.name; contactIdentifier = person.contactIdentifier; tier = person.tierRaw; targetIntervalDays = person.targetIntervalDays; notes = person.notes; createdAt = person.createdAt; archivedAt = person.archivedAt; manualDueDate = person.manualDueDate
        interactions = person.activeInteractions.map { .init(timestamp: $0.timestamp, type: $0.typeRaw, quality: $0.qualityRaw, durationMinutes: $0.durationMinutes, notes: $0.notes) }
        memories = (person.memories ?? []).map { .init(category: $0.categoryRaw, content: $0.content, createdAt: $0.createdAt, expiresAt: $0.expiresAt, lifespan: $0.lifespanRaw, userApproved: $0.userApproved) }
        importantDates = (person.importantDates ?? []).map { .init(title: $0.title, date: $0.date, kind: $0.kindRaw, repeatsYearly: $0.repeatsYearly) }
    }
}
private struct ExportInteraction: Codable { let timestamp: Date; let type: String; let quality: String; let durationMinutes: Int?; let notes: String? }
private struct ExportMemory: Codable { let category: String; let content: String; let createdAt: Date; let expiresAt: Date?; let lifespan: String; let userApproved: Bool }
private struct ExportImportantDate: Codable { let title: String; let date: Date; let kind: String; let repeatsYearly: Bool }
