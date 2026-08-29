import Foundation

struct ScheduleCandidate: Identifiable, Equatable {
    let id: UUID
    let name: String
    let tier: RelationshipTier
    let targetIntervalDays: Int
    let createdAt: Date
    let lastInteractionDate: Date?
    let manualDueDate: Date?
    let isArchived: Bool

    var baseDueDate: Date {
        if let manualDueDate { return manualDueDate }
        let base = lastInteractionDate ?? createdAt
        return Calendar.current.date(byAdding: .day, value: max(1, targetIntervalDays), to: base) ?? base
    }
}

struct ScheduledConnection: Identifiable, Equatable {
    let candidate: ScheduleCandidate
    let dueDate: Date
    let overdueDays: Int
    let score: Double
    var id: UUID { candidate.id }
}

struct SchedulingEngine {
    var calendar: Calendar = .current

    func queue(candidates: [ScheduleCandidate], on date: Date, target: Int, maximum: Int? = nil) -> [ScheduledConnection] {
        let day = calendar.startOfDay(for: date)
        let capacity = max(0, min(maximum ?? target, target))
        guard capacity > 0 else { return [] }

        let ranked = candidates
            .filter { !$0.isArchived }
            .map { candidate -> ScheduledConnection in
                let due = calendar.startOfDay(for: candidate.baseDueDate)
                let delta = calendar.dateComponents([.day], from: due, to: day).day ?? 0
                let overdue = max(0, delta)
                let daysUntilDue = max(0, -delta)
                let duePressure = daysUntilDue == 0 ? 20.0 : max(0, 8.0 - Double(daysUntilDue))
                let overduePressure = min(30, Double(overdue) * 1.8)
                let neverContactedBoost = candidate.lastInteractionDate == nil ? 4.0 : 0
                let score = duePressure + overduePressure + candidate.tier.priority * 3 + neverContactedBoost
                return ScheduledConnection(candidate: candidate, dueDate: due, overdueDays: overdue, score: score)
            }
            .filter { $0.dueDate <= calendar.date(byAdding: .day, value: 3, to: day)! }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
                return $0.candidate.id.uuidString < $1.candidate.id.uuidString
            }

        return balancedPrefix(ranked, capacity: capacity)
    }

    private func balancedPrefix(_ ranked: [ScheduledConnection], capacity: Int) -> [ScheduledConnection] {
        var result: [ScheduledConnection] = []
        var remaining = ranked
        var tierCounts: [RelationshipTier: Int] = [:]
        while result.count < capacity, !remaining.isEmpty {
            let minimumTierCount = RelationshipTier.allCases.map { tierCounts[$0, default: 0] }.min() ?? 0
            let preferredIndex = remaining.firstIndex { tierCounts[$0.candidate.tier, default: 0] <= minimumTierCount }
            let index = preferredIndex ?? remaining.startIndex
            let selected = remaining.remove(at: index)
            result.append(selected)
            tierCounts[selected.candidate.tier, default: 0] += 1
        }
        return result
    }

    func rebalance(candidates: [ScheduleCandidate], from date: Date, dailyTarget: Int) -> [UUID: Date] {
        guard dailyTarget > 0 else { return [:] }
        let active = candidates.filter { !$0.isArchived }.sorted {
            if $0.baseDueDate != $1.baseDueDate { return $0.baseDueDate < $1.baseDueDate }
            return $0.id.uuidString < $1.id.uuidString
        }
        let start = calendar.startOfDay(for: date)
        return Dictionary(uniqueKeysWithValues: active.enumerated().map { index, person in
            let offset = index / dailyTarget
            return (person.id, calendar.date(byAdding: .day, value: offset, to: start) ?? start)
        })
    }
}

extension Person {
    var scheduleCandidate: ScheduleCandidate {
        ScheduleCandidate(id: id, name: name, tier: tier, targetIntervalDays: targetIntervalDays, createdAt: createdAt, lastInteractionDate: lastInteractionDate, manualDueDate: manualDueDate, isArchived: archivedAt != nil)
    }

    func status(on date: Date = Date(), calendar: Calendar = .current) -> PersonStatus {
        if lastInteractionDate == nil { return .neverContacted }
        let today = calendar.startOfDay(for: date)
        let due = calendar.startOfDay(for: calculatedDueDate)
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        if days < 0 { return .drifting }
        if days == 0 { return .today }
        if days <= 3 { return .dueSoon }
        return .onTrack
    }
}
