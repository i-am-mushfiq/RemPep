import XCTest
import SwiftData
@testable import Connect

@MainActor
final class RelationshipServiceTests: XCTestCase {
    func testMovingBetweenStandardTiersAdoptsNewDefaultCadence() {
        let container = PersistenceController.preview()
        let context = container.mainContext
        let person = Person(name: "Contact A", tier: .close)
        context.insert(person)

        RelationshipService(context: context).move(person, to: .familiar)

        XCTAssertEqual(person.tier, .familiar)
        XCTAssertEqual(person.targetIntervalDays, RelationshipTier.familiar.defaultInterval)
    }

    func testMovingPreservesIntentionallyCustomizedCadence() {
        let container = PersistenceController.preview()
        let context = container.mainContext
        let person = Person(name: "Contact B", tier: .close, targetIntervalDays: 11)
        context.insert(person)

        RelationshipService(context: context).move(person, to: .important)

        XCTAssertEqual(person.tier, .important)
        XCTAssertEqual(person.targetIntervalDays, 11)
    }

    func testMovingToCustomKeepsExistingCadence() {
        let container = PersistenceController.preview()
        let context = container.mainContext
        let person = Person(name: "Contact C", tier: .important)
        context.insert(person)

        RelationshipService(context: context).move(person, to: .custom)

        XCTAssertEqual(person.tier, .custom)
        XCTAssertEqual(person.targetIntervalDays, RelationshipTier.important.defaultInterval)
    }

    func testMovingToCurrentTierDoesNothing() {
        let container = PersistenceController.preview()
        let context = container.mainContext
        let person = Person(name: "Contact D", tier: .occasional, targetIntervalDays: 75)
        context.insert(person)

        RelationshipService(context: context).move(person, to: .occasional)

        XCTAssertEqual(person.tier, .occasional)
        XCTAssertEqual(person.targetIntervalDays, 75)
    }
}
