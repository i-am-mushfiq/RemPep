import Foundation

struct DailyMetric: Identifiable {
    let date: Date
    let connections: Int
    let target: Int
    var id: Date { date }
}

struct WeeklySummary {
    let connections: Int
    let peopleReached: Int
    let meaningful: Int
    let rhythm: Double
}

@MainActor
struct MetricsService {
    var calendar: Calendar = .current

    func completedToday(_ people: [Person], on date: Date = Date()) -> Int {
        let day = calendar.startOfDay(for: date)
        return people.filter { person in
            person.activeInteractions.contains { calendar.isDate($0.timestamp, inSameDayAs: day) }
        }.count
    }

    func coverage(_ people: [Person], on date: Date = Date()) -> Double {
        let active = people.filter { $0.archivedAt == nil }
        guard !active.isEmpty else { return 1 }
        let covered = active.filter { $0.calculatedDueDate >= calendar.startOfDay(for: date) }.count
        return Double(covered) / Double(active.count)
    }

    func dailyMetrics(_ people: [Person], target: Int, days: Int = 14, ending date: Date = Date()) -> [DailyMetric] {
        (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) else { return nil }
            let count = people.filter { person in person.activeInteractions.contains { calendar.isDate($0.timestamp, inSameDayAs: day) } }.count
            return DailyMetric(date: day, connections: count, target: target)
        }
    }

    func weeklySummary(_ people: [Person], target: Int, ending date: Date = Date()) -> WeeklySummary {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: date))!
        let interactions = people.flatMap(\.activeInteractions).filter { $0.timestamp >= start && $0.timestamp <= date }
        let unique = Set(interactions.compactMap { $0.person?.id }).count
        let meaningful = interactions.filter { $0.quality == .meaningful || $0.quality == .inPerson }.count
        let expected = max(1, target * 7)
        return WeeklySummary(connections: interactions.count, peopleReached: unique, meaningful: meaningful, rhythm: min(1, Double(interactions.count) / Double(expected)))
    }
}
