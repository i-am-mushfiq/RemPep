import SwiftUI
import SwiftData

struct PersonPickerView: View {
    enum Purpose { case interaction, memory }
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var people: [Person]
    let purpose: Purpose
    @State private var search = ""
    @State private var selected: Person?

    var body: some View {
        NavigationStack {
            List(people.filter { $0.archivedAt == nil && (search.isEmpty || $0.name.localizedStandardContains(search)) }) { person in Button { selected = person } label: { HStack { PersonAvatar(person: person, size: 40); Text(person.name).foregroundStyle(.primary) } } }
                .searchable(text: $search, prompt: "Who did you connect with?").navigationTitle(purpose == .interaction ? "Log interaction" : "Add memory")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .sheet(item: $selected) { person in if purpose == .interaction { InteractionLoggingView(person: person) } else { MemoryEditor(person: person) } }
        }
    }
}
