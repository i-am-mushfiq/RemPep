import UIKit

enum HapticsService {
    @MainActor
    static func connectionSaved(enabled: Bool, completedTarget: Bool) {
        guard enabled, !UIAccessibility.isReduceMotionEnabled else { return }
        if completedTarget { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        else { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    }
}
