import SwiftUI
import UIKit

struct ConversationPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    let person: Person
    @State private var mode: ConversationMode = .quick
    @State private var launchedChannel = false
    @State private var askToLog = false
    @State private var showLog = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Conversation mode", selection: $mode) { ForEach(ConversationMode.allCases) { Text($0.title).tag($0) } }.pickerStyle(.menu)
                    if !person.activeMemories.isEmpty { SectionLabel(text: "Remember"); ForEach(person.activeMemories.prefix(3)) { Label($0.content, systemImage: "circle.fill").font(.subheadline) } }
                    SectionLabel(text: "You could say")
                    ForEach(RapportService().prompts(for: person, mode: mode), id: \.self) { prompt in
                        ConnectCard { Text("“\(prompt)”").font(.body); Button { UIPasteboard.general.string = prompt } label: { Label("Copy", systemImage: "doc.on.doc") }.font(.caption).padding(.top, 6) }
                    }
                    Text("Use your own voice. A genuine, simple message is better than polished wording.").font(.footnote).foregroundStyle(.secondary)
                    channelButtons
                }.padding()
            }.navigationTitle("Before you reach out").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
                .onChange(of: scenePhase) { _, phase in if phase == .active && launchedChannel { launchedChannel = false; askToLog = true } }
                .confirmationDialog("Did you connect?", isPresented: $askToLog, titleVisibility: .visible) { Button("Yes, log it") { showLog = true }; Button("Not yet", role: .cancel) {} } message: { Text("Logging takes just a moment and resets the next connection date.") }
                .sheet(isPresented: $showLog) { InteractionLoggingView(person: person) }
        }
    }

    @ViewBuilder private var channelButtons: some View {
        HStack {
            if let phone = person.phoneNumber, let encoded = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let sms = URL(string: "sms:\(encoded)") { Button { launchedChannel = true; openURL(sms) } label: { Label("Message", systemImage: "message.fill") }.buttonStyle(.borderedProminent) }
            if let phone = person.phoneNumber, let encoded = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let tel = URL(string: "tel:\(encoded)") { Button { launchedChannel = true; openURL(tel) } label: { Label("Call", systemImage: "phone.fill") }.buttonStyle(.bordered) }
        }
    }
}
