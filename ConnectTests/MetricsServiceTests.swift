import XCTest
import SwiftData
@testable import Connect

@MainActor
final class MetricsServiceTests: XCTestCase {
    func testCoverageCountsRelationshipsInsideTheirRhythm() throws {
        let container = PersistenceController.preview()
        let context = container.mainContext
        let today = Date()
        let onTrack = Person(name: "On track", tier: .close)
        onTrack.createdAt = today
        let overdue = Person(name: "Ready", tier: .close)
        overdue.createdAt = Calendar.current.date(byAdding: .day, value: -10, to: today)!
        context.insert(onTrack); context.insert(overdue)
        XCTAssertEqual(MetricsService().coverage([onTrack, overdue], on: today), 0.5, accuracy: 0.001)
    }

    func testArchivedPeopleDoNotReduceCoverage() throws {
        let container = PersistenceController.preview()
        let person = Person(name: "Archived", tier: .close)
        person.createdAt = .distantPast
        person.archivedAt = Date()
        container.mainContext.insert(person)
        XCTAssertEqual(MetricsService().coverage([person]), 1)
    }
}
