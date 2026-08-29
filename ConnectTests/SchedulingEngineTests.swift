import XCTest
@testable import Connect

final class SchedulingEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var today: Date!
    private var engine: SchedulingEngine!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        today = calendar.date(from: DateComponents(year: 2026, month: 8, day: 29))!
        engine = SchedulingEngine(calendar: calendar)
    }

    func testOnePersonWeeklyBecomesDueAfterSevenDays() {
        let person = candidate(interval: 7, last: day(-7))
        XCTAssertEqual(engine.queue(candidates: [person], on: today, target: 3).map(\.id), [person.id])
    }

    func testTenWeeklyPeopleRespectDailyTarget() {
        let people = (0..<10).map { candidate(name: "P\($0)", interval: 7, last: day(-7)) }
        XCTAssertEqual(engine.queue(candidates: people, on: today, target: 3).count, 3)
    }

    func testFortyMixedIntervalsRemainBoundedAndTierBalanced() {
        let tiers: [RelationshipTier] = [.close, .important, .familiar, .occasional]
        let people = (0..<40).map { index in candidate(name: "P\(index)", tier: tiers[index % tiers.count], interval: tiers[index % tiers.count].defaultInterval, last: day(-90)) }
        let queue = engine.queue(candidates: people, on: today, target: 5)
        XCTAssertEqual(queue.count, 5)
        XCTAssertGreaterThanOrEqual(Set(queue.map { $0.candidate.tier }).count, 4)
    }

    func testMultiplePeopleDueSameDayAreDeterministic() {
        let people = (0..<12).map { candidate(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", $0 + 1))!, name: "P\($0)", last: day(-30)) }
        XCTAssertEqual(engine.queue(candidates: people, on: today, target: 4), engine.queue(candidates: people.shuffled(), on: today, target: 4))
    }

    func testMissingOneDayRaisesOverduePriority() {
        let late = candidate(name: "Late", last: day(-31))
        let due = candidate(name: "Due", last: day(-30))
        XCTAssertEqual(engine.queue(candidates: [due, late], on: today, target: 1).first?.id, late.id)
    }

    func testMissingSevenDaysStillRespectsCapacity() {
        let people = (0..<20).map { candidate(name: "P\($0)", last: day(-37)) }
        XCTAssertEqual(engine.queue(candidates: people, on: today, target: 3, maximum: 5).count, 3)
    }

    func testMissingThirtyDaysHasCappedOverdueScore() {
        let thirtyLate = candidate(name: "Thirty", tier: .occasional, last: day(-60))
        let yearLate = candidate(name: "Year", tier: .occasional, last: day(-395))
        let first = engine.queue(candidates: [thirtyLate], on: today, target: 1).first!
        let second = engine.queue(candidates: [yearLate], on: today, target: 1).first!
        XCTAssertEqual(first.score, second.score)
    }

    func testCompletingMoreThanTargetMovesCompletedPeopleOut() {
        let completed = (0..<5).map { candidate(name: "Done\($0)", last: today) }
        XCTAssertTrue(engine.queue(candidates: completed, on: today, target: 3).isEmpty)
    }

    func testCompletingLessThanTargetDoesNotOverfillQueue() {
        let due = candidate(name: "Due", last: day(-30))
        XCTAssertEqual(engine.queue(candidates: [due], on: today, target: 3).count, 1)
    }

    func testChangingFrequencyChangesDueState() {
        let monthly = candidate(name: "Monthly", interval: 30, last: day(-10))
        let weekly = candidate(id: monthly.id, name: "Weekly", interval: 7, last: day(-10))
        XCTAssertTrue(engine.queue(candidates: [monthly], on: today, target: 1).isEmpty)
        XCTAssertEqual(engine.queue(candidates: [weekly], on: today, target: 1).first?.id, weekly.id)
    }

    func testArchivedPersonIsExcludedAndRestoredPersonReturns() {
        let archived = candidate(name: "Archived", last: day(-30), archived: true)
        let restored = candidate(id: archived.id, name: "Restored", last: day(-30), archived: false)
        XCTAssertTrue(engine.queue(candidates: [archived], on: today, target: 1).isEmpty)
        XCTAssertEqual(engine.queue(candidates: [restored], on: today, target: 1).count, 1)
    }

    func testManualDueDateOverridesCalculatedDate() {
        let person = candidate(name: "Manual", interval: 60, last: today, manualDue: today)
        XCTAssertEqual(engine.queue(candidates: [person], on: today, target: 1).count, 1)
    }

    func testEarlyInteractionResetsFromActualInteractionDate() {
        let person = candidate(name: "Early", interval: 30, last: today)
        XCTAssertEqual(person.baseDueDate, day(30))
    }

    func testLateInteractionResetsFromActualInteractionDate() {
        let lateInteraction = day(-2)
        let person = candidate(name: "Late", interval: 15, last: lateInteraction)
        XCTAssertEqual(person.baseDueDate, day(13))
    }

    func testRecoveryRebalanceSpreadsBacklogAtTargetCapacity() {
        let people = (0..<10).map { candidate(name: "P\($0)", last: day(-90)) }
        let schedule = engine.rebalance(candidates: people, from: today, dailyTarget: 3)
        let counts = Dictionary(grouping: schedule.values, by: { $0 }).mapValues(\.count)
        XCTAssertEqual(schedule.count, 10)
        XCTAssertLessThanOrEqual(counts.values.max() ?? 0, 3)
        XCTAssertEqual(Set(schedule.values).count, 4)
    }

    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }
    private func candidate(id: UUID = UUID(), name: String = "Person", tier: RelationshipTier = .familiar, interval: Int = 30, last: Date?, manualDue: Date? = nil, archived: Bool = false) -> ScheduleCandidate {
        ScheduleCandidate(id: id, name: name, tier: tier, targetIntervalDays: interval, createdAt: day(-100), lastInteractionDate: last, manualDueDate: manualDue, isArchived: archived)
    }
}
