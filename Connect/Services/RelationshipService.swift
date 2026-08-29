import Foundation
import SwiftData

@MainActor
struct RelationshipService {
    let context: ModelContext

    func addPerson(name: String, tier: RelationshipTier, interval: Int, initialMemory: String = "") -> Person {
        let person = Person(name: name, tier: tier, targetIntervalDays: interval)
        context.insert(person)
        if !initialMemory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            context.insert(Memory(person: person, content: initialMemory))
        }
        try? context.save()
        return person
    }

    func logInteraction(for person: Person, type: InteractionType, quality: InteractionQuality, notes: String = "", memory: String = "", at date: Date = Date()) {
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let interaction = Interaction(person: person, timestamp: date, type: type, quality: quality, notes: cleanNotes.isEmpty ? nil : cleanNotes)
        context.insert(interaction)
        person.manualDueDate = nil
        let cleanMemory = memory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanMemory.isEmpty { context.insert(Memory(person: person, content: cleanMemory)) }
        try? context.save()
    }

    func snooze(_ person: Person, days: Int = 2) {
        person.manualDueDate = Calendar.current.date(byAdding: .day, value: max(1, days), to: Date())
        try? context.save()
    }

    func archive(_ person: Person) {
        person.archivedAt = Date()
        try? context.save()
    }

    func restore(_ person: Person) {
        person.archivedAt = nil
        try? context.save()
    }

    func move(_ person: Person, to tier: RelationshipTier) {
        let previousTier = person.tier
        guard previousTier != tier else { return }
        let followedPreviousDefault = previousTier != .custom && person.targetIntervalDays == previousTier.defaultInterval
        person.tier = tier
        if followedPreviousDefault && tier != .custom {
            person.targetIntervalDays = tier.defaultInterval
        }
        try? context.save()
    }

    func rebalance(_ people: [Person], dailyTarget: Int, from date: Date = Date()) {
        let dates = SchedulingEngine().rebalance(candidates: people.map(\.scheduleCandidate), from: date, dailyTarget: dailyTarget)
        for person in people { person.manualDueDate = dates[person.id] }
        SettingsStore.current(in: context).lastRebalancedAt = date
        try? context.save()
    }
}
