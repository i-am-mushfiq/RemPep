import SwiftUI

enum ConnectTheme {
    static let background = Color.black
    static let secondaryBackground = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let card = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let elevated = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let accent = Color(red: 0.31, green: 0.84, blue: 0.70)
    static let secondaryText = Color(red: 161/255, green: 161/255, blue: 166/255)
}

struct ConnectCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.caption.weight(.semibold)).tracking(0.8).foregroundStyle(ConnectTheme.secondaryText)
    }
}

extension Date {
    var friendlyDueDescription: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Due today" }
        if calendar.isDateInTomorrow(self) { return "Due tomorrow" }
        if self < calendar.startOfDay(for: Date()) {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: self), to: calendar.startOfDay(for: Date())).day ?? 0
            return days == 1 ? "Ready since yesterday" : "Ready for \(days) days"
        }
        return "Due \(formatted(.relative(presentation: .named)))"
    }
}
