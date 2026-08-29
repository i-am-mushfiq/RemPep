import SwiftUI
import SwiftData

struct InteractionLoggingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]
    let person: Person
    @State private var type: InteractionType = .message
    @State private var quality: InteractionQuality = .good
    @State private var memory = ""
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                HStack { PersonAvatar(person: person, size: 56); VStack(alignment: .leading) { Text(person.name).font(.title2.bold()); Text(step == 0 ? "How did you connect?" : "How did it go?").foregroundStyle(.secondary) } }
                if step == 0 {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(InteractionType.allCases) { item in
                            Button { type = item; step = 1 } label: { Label(item.title, systemImage: item.symbol).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered)
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(InteractionQuality.allCases) { item in
                            Button { quality = item } label: {
                                HStack { Text(item.title); Spacer(); if quality == item { Image(systemName: "checkmark.circle.fill").foregroundStyle(ConnectTheme.accent) } }.frame(minHeight: 44)
                            }.buttonStyle(.plain).padding(.horizontal).background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    TextField("Anything worth remembering? (optional)", text: $memory, axis: .vertical).lineLimit(3...5).padding().background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 14))
                    Button("Save connection") {
                        RelationshipService(context: context).logInteraction(for: person, type: type, quality: quality, memory: memory)
                        HapticsService.connectionSaved(enabled: settingsList.first?.hapticsEnabled ?? true, completedTarget: false)
                        dismiss()
                    }.buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity)
                }
                Spacer()
            }.padding()
            .navigationTitle("Log connection").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.presentationDetents([.medium, .large])
    }
}
