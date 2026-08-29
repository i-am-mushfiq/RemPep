import SwiftUI

struct ProgressRing: View {
    let completed: Int
    let target: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { target > 0 ? min(1, Double(completed) / Double(target)) : 0 }

    var body: some View {
        ZStack {
            Circle().stroke(ConnectTheme.elevated, lineWidth: 18)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ConnectTheme.accent, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: progress)
            VStack(spacing: 2) {
                Text("\(completed)").font(.system(size: 50, weight: .bold, design: .rounded)).contentTransition(.numericText())
                Text("of \(target) done").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's connections")
        .accessibilityValue("\(completed) of \(target) completed")
    }
}
