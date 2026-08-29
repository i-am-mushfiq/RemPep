import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var contactIdentifier: String?
    var phoneNumber: String?
    var emailAddress: String?
    var tierRaw: String = RelationshipTier.familiar.rawValue
    var targetIntervalDays: Int = 30
    var preferredChannelsRaw: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var archivedAt: Date?
    var manualDueDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \Interaction.person) var interactions: [Interaction]? = []
    @Relationship(deleteRule: .cascade, inverse: \Memory.person) var memories: [Memory]? = []
    @Relationship(deleteRule: .cascade, inverse: \ImportantDate.person) var importantDates: [ImportantDate]? = []

    init(name: String, tier: RelationshipTier = .familiar, targetIntervalDays: Int? = nil) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tierRaw = tier.rawValue
        self.targetIntervalDays = max(1, targetIntervalDays ?? tier.defaultInterval)
        self.createdAt = Date()
    }

    var tier: RelationshipTier {
        get { RelationshipTier(rawValue: tierRaw) ?? .familiar }
        set { tierRaw = newValue.rawValue }
    }
    var preferredChannels: [ContactChannel] {
        get { preferredChannelsRaw.split(separator: ",").compactMap { ContactChannel(rawValue: String($0)) } }
        set { preferredChannelsRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }
    var activeInteractions: [Interaction] { (interactions ?? []).sorted { $0.timestamp > $1.timestamp } }
    var activeMemories: [Memory] { (memories ?? []).filter { !$0.isExpired }.sorted { $0.createdAt > $1.createdAt } }
    var lastInteractionDate: Date? { activeInteractions.first?.timestamp }
    var calculatedDueDate: Date {
        if let manualDueDate { return manualDueDate }
        let base = lastInteractionDate ?? createdAt
        return Calendar.current.date(byAdding: .day, value: targetIntervalDays, to: base) ?? base
    }
}

@Model
final class Interaction {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var typeRaw: String = InteractionType.message.rawValue
    var qualityRaw: String = InteractionQuality.good.rawValue
    var durationMinutes: Int?
    var notes: String?
    var person: Person?

    init(person: Person, timestamp: Date = Date(), type: InteractionType, quality: InteractionQuality, durationMinutes: Int? = nil, notes: String? = nil) {
        self.id = UUID()
        self.person = person
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.qualityRaw = quality.rawValue
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
    var type: InteractionType { InteractionType(rawValue: typeRaw) ?? .other }
    var quality: InteractionQuality { InteractionQuality(rawValue: qualityRaw) ?? .good }
}

@Model
final class Memory {
    var id: UUID = UUID()
    var categoryRaw: String = MemoryCategory.general.rawValue
    var content: String = ""
    var createdAt: Date = Date()
    var expiresAt: Date?
    var lifespanRaw: String = MemoryLifespan.longTerm.rawValue
    var userApproved: Bool = true
    var person: Person?

    init(person: Person, content: String, category: MemoryCategory = .general, lifespan: MemoryLifespan = .longTerm, expiresAt: Date? = nil) {
        self.id = UUID()
        self.person = person
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryRaw = category.rawValue
        self.lifespanRaw = lifespan.rawValue
        self.expiresAt = expiresAt
        self.userApproved = true
        self.createdAt = Date()
    }
    var category: MemoryCategory { MemoryCategory(rawValue: categoryRaw) ?? .general }
    var lifespan: MemoryLifespan { MemoryLifespan(rawValue: lifespanRaw) ?? .longTerm }
    var isExpired: Bool { expiresAt.map { $0 < Date() } ?? false }
}

@Model
final class ImportantDate {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var kindRaw: String = ImportantDateKind.custom.rawValue
    var repeatsYearly: Bool = false
    var person: Person?

    init(person: Person, title: String, date: Date, kind: ImportantDateKind, repeatsYearly: Bool = false) {
        self.id = UUID()
        self.person = person
        self.title = title
        self.date = date
        self.kindRaw = kind.rawValue
        self.repeatsYearly = repeatsYearly
    }
    var kind: ImportantDateKind { ImportantDateKind(rawValue: kindRaw) ?? .custom }
}

@Model
final class UserSettings {
    var id: UUID = UUID()
    var dailyMinimum: Int = 2
    var dailyTarget: Int = 3
    var dailyMaximum: Int = 5
    var notificationLevelRaw: String = NotificationLevel.minimal.rawValue
    var reminderHour: Int = 10
    var reminderMinute: Int = 0
    var rapportLearningEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var iCloudEnabled: Bool = true
    var onboardingComplete: Bool = false
    var lastRebalancedAt: Date?

    init() {}
    var notificationLevel: NotificationLevel {
        get { NotificationLevel(rawValue: notificationLevelRaw) ?? .minimal }
        set { notificationLevelRaw = newValue.rawValue }
    }
}

@Model
final class Milestone {
    var id: UUID = UUID()
    var kind: String = ""
    var title: String = ""
    var detail: String = ""
    var achievedAt: Date = Date()
    init(kind: String, title: String, detail: String, achievedAt: Date = Date()) {
        self.id = UUID(); self.kind = kind; self.title = title; self.detail = detail; self.achievedAt = achievedAt
    }
}
