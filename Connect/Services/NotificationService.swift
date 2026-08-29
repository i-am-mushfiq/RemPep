import Foundation
@preconcurrency import UserNotifications

actor NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func updateDailyReminder(level: NotificationLevel, target: Int, hour: Int, minute: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: ["connect.daily", "connect.followup"])
        guard level != .off else { return }
        let content = UNMutableNotificationContent()
        content.title = "A little connection goes a long way"
        content.body = "You have up to \(target) people to reconnect with today."
        content.sound = .default
        content.userInfo = ["route": "today"]
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "connect.daily", content: content, trigger: trigger))
        if level == .persistent {
            let followUp = UNMutableNotificationContent()
            followUp.title = "Your connections are here when you're ready"
            followUp.body = "A quick check-in can be enough for today."
            followUp.userInfo = ["route": "today"]
            var evening = DateComponents()
            evening.hour = max(17, min(21, hour + 8))
            evening.minute = minute
            try? await center.add(UNNotificationRequest(identifier: "connect.followup", content: followUp, trigger: UNCalendarNotificationTrigger(dateMatching: evening, repeats: true)))
        }
    }

    func updateImportantDates(_ dates: [ImportantDateNotification], level: NotificationLevel) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("connect.date.") })
        guard level == .standard || level == .persistent else { return }
        for item in dates {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "It's \(item.personName)'s \(item.kind.lowercased()). You may want to reach out."
            content.userInfo = ["route": "today"]
            var components = Calendar.current.dateComponents([.year, .month, .day], from: item.date)
            components.hour = 9
            if item.repeatsYearly { components.year = nil }
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: item.repeatsYearly)
            try? await center.add(UNNotificationRequest(identifier: "connect.date.\(item.id.uuidString)", content: content, trigger: trigger))
        }
    }
}

struct ImportantDateNotification: Sendable {
    let id: UUID
    let personName: String
    let title: String
    let kind: String
    let date: Date
    let repeatsYearly: Bool
}
