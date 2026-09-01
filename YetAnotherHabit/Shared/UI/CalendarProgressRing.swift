import SwiftUI

struct CalendarProgressRing: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 3)

            if progress > 0 {
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: 42, height: 42)
        .animation(
            accessibilityReduceMotion ? nil : .easeInOut(duration: 0.2),
            value: progress
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
