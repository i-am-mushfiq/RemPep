import Foundation

enum ConversationMode: String, CaseIterable, Identifiable {
    case quick, catchUp, meaningful, plan
    var id: String { rawValue }
    var title: String {
        switch self {
        case .quick: "Quick check-in"
        case .catchUp: "Catch up"
        case .meaningful: "Meaningful conversation"
        case .plan: "Plan something"
        }
    }
}

@MainActor
struct RapportService {
    func prompts(for person: Person, mode: ConversationMode) -> [String] {
        let memory = person.activeMemories.first?.content
        var prompts: [String] = []
        if let memory, !memory.isEmpty {
            switch mode {
            case .quick: prompts.append("Hey — randomly thought of you. How's \(memory.lowercased()) going?")
            case .catchUp: prompts.append("You mentioned \(memory.lowercased()). How did that turn out?")
            case .meaningful: prompts.append("I've been wondering how you've felt about \(memory.lowercased()) lately.")
            case .plan: prompts.append("Want to catch up soon and tell me more about \(memory.lowercased())?")
            }
        }
        prompts.append("Hey \(person.name), you crossed my mind today. What's new?")
        prompts.append(mode == .plan ? "Are you free to do something together soon?" : "How have you been, really?")
        return Array(prompts.prefix(3))
    }

    func contextualLine(for person: Person) -> String {
        if let memory = person.activeMemories.first { return memory.content }
        if let last = person.lastInteractionDate { return "Last connected \(last.formatted(.relative(presentation: .named)))" }
        return "Start with a simple hello"
    }

    func tip(for date: Date = Date()) -> String? {
        let week = Calendar.current.component(.weekOfYear, from: date)
        guard week.isMultiple(of: 2) else { return nil }
        let tips = [
            "Follow up on one small detail they shared last time.",
            "Don't only ask questions—share something from your own week.",
            "Listen for what matters underneath the update.",
            "A short, genuine check-in is enough."
        ]
        return tips[week % tips.count]
    }
}
