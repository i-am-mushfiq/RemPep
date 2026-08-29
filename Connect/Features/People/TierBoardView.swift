import SwiftUI
import SwiftData

struct TierBoardView: View {
    @Environment(\.modelContext) private var context
    let people: [Person]
    let sort: PeopleSort
    @State private var targetedTier: RelationshipTier?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Drag a card to change its relationship tier", systemImage: "hand.draw")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(RelationshipTier.allCases) { tier in
                        TierColumn(
                            tier: tier,
                            people: sorted(people.filter { $0.tier == tier }),
                            isTargeted: targetedTier == tier,
                            move: move
                        )
                        .dropDestination(for: String.self) { identifiers, _ in
                            guard
                                let value = identifiers.first,
                                let id = UUID(uuidString: value),
                                let person = people.first(where: { $0.id == id })
                            else { return false }
                            withAnimation(.easeInOut(duration: 0.25)) { move(person, tier) }
                            return true
                        } isTargeted: { isTargeted in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if isTargeted { targetedTier = tier }
                                else if targetedTier == tier { targetedTier = nil }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .scrollIndicators(.hidden)
        }
        .background(ConnectTheme.background)
        .accessibilityLabel("Relationship tier board")
    }

    private func move(_ person: Person, _ tier: RelationshipTier) {
        RelationshipService(context: context).move(person, to: tier)
    }

    private func sorted(_ people: [Person]) -> [Person] {
        people.sorted { lhs, rhs in
            switch sort {
            case .dueDate:
                lhs.calculatedDueDate == rhs.calculatedDueDate ? lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending : lhs.calculatedDueDate < rhs.calculatedDueDate
            case .tier, .name:
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .lastInteraction:
                (lhs.lastInteractionDate ?? .distantPast) > (rhs.lastInteractionDate ?? .distantPast)
            }
        }
    }
}

private struct TierColumn: View {
    let tier: RelationshipTier
    let people: [Person]
    let isTargeted: Bool
    let move: (Person, RelationshipTier) -> Void

    var body: some View {
        LazyVStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(tier.title, systemImage: tier.symbol).font(.headline)
                    Text(tier.cadenceDescription).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(people.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ConnectTheme.elevated, in: Capsule())
            }
            .padding(.bottom, 4)

            if people.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.and.hand.point.up.left").font(.title2)
                    Text("Drop someone here").font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 112)
                .accessibilityHidden(true)
            } else {
                ForEach(people) { person in
                    TierBoardCard(person: person, currentTier: tier, move: move)
                }
            }
            Spacer(minLength: 80)
        }
        .padding(14)
        .frame(width: 280, alignment: .top)
        .frame(minHeight: 430, alignment: .top)
        .background(
            isTargeted ? ConnectTheme.accent.opacity(0.16) : ConnectTheme.secondaryBackground,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isTargeted ? ConnectTheme.accent : Color.clear, lineWidth: 2)
        }
        .animation(.easeInOut(duration: 0.2), value: people.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(tier.title), \(people.count) people")
    }
}

private struct TierBoardCard: View {
    let person: Person
    let currentTier: RelationshipTier
    let move: (Person, RelationshipTier) -> Void

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(value: person) {
                HStack(spacing: 10) {
                    PersonAvatar(person: person, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(person.name).font(.headline).lineLimit(1)
                        Text(person.calculatedDueDate.friendlyDueDescription)
                            .font(.caption)
                            .foregroundStyle(person.status().color)
                        if currentTier == .custom {
                            Text("Every \(person.targetIntervalDays) days").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Menu {
                Section("Move to") {
                    ForEach(RelationshipTier.allCases.filter { $0 != currentTier }) { tier in
                        Button { move(person, tier) } label: { Label(tier.title, systemImage: tier.symbol) }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle").frame(width: 36, height: 44)
            }
            .accessibilityLabel("Move \(person.name) to another tier")
        }
        .padding(12)
        .background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .draggable(person.id.uuidString) {
            HStack(spacing: 8) {
                PersonAvatar(person: person, size: 34)
                Text(person.name).font(.headline)
            }
            .padding(10)
            .background(ConnectTheme.elevated, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityHint("Drag to another tier, or use the move menu")
    }
}
