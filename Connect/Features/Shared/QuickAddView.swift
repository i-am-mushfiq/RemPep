import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var destination: Destination?
    enum Destination: String, Identifiable { case person, interaction, memory; var id: String { rawValue } }

    var body: some View {
        NavigationStack {
            List {
                Button { destination = .person } label: { Label("Add person", systemImage: "person.badge.plus") }
                Button { destination = .interaction } label: { Label("Log interaction", systemImage: "checkmark.bubble") }
                Button { destination = .memory } label: { Label("Add memory", systemImage: "brain.head.profile") }
            }.navigationTitle("Quick add").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $destination) { destination in
                switch destination {
                case .person: AddPersonView()
                case .interaction: PersonPickerView(purpose: .interaction)
                case .memory: PersonPickerView(purpose: .memory)
                }
            }
        }.presentationDetents([.medium])
    }
}
