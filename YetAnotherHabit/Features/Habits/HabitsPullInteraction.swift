import Observation
import SwiftUI

enum HabitsPullAction: Equatable {
    case returnToToday
}

@MainActor
@Observable
final class HabitsPullInteractionState {
    var distance: CGFloat = 0
    var startDistance: CGFloat?
    var actionSnapshot: HabitsPullAction?
    var pendingAction: HabitsPullAction?
    var isReady = false
    var feedbackTrigger = 0
}

struct HabitsPullIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let state: HabitsPullInteractionState
    let action: HabitsPullAction?
    let returnToTodaySystemImage: String
    let threshold: CGFloat
    let revealDistance: CGFloat
    let contentHeight: CGFloat
    let maximumHeight: CGFloat
    let isEmptyState: Bool

    var body: some View {
        Group {
            if let displayedAction {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(
                                indicatorColor.opacity(state.isReady ? 0.22 : 0.16),
                                lineWidth: 2.5
                            )

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                indicatorColor,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        Image(systemName: systemImage(for: displayedAction))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(indicatorColor)
                    }
                    .frame(width: 24, height: 24)

                    Text(title(for: displayedAction))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(indicatorColor)
                        .scaleEffect(state.isReady ? 1.05 : 1)
                        .animation(readinessAnimation, value: state.isReady)
                }
                .opacity(min(progress * 1.6, 1))
                .offset(y: verticalOffset)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: maximumHeight, alignment: .top)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .sensoryFeedback(.selection, trigger: state.feedbackTrigger)
    }

    private var displayedAction: HabitsPullAction? {
        state.actionSnapshot ?? action
    }

    private var progress: Double {
        let visibleDistance = max(state.distance - revealDistance, 0)
        let visibleRange = max(threshold - revealDistance, 1)
        return min(max(Double(visibleDistance / visibleRange), 0), 1)
    }

    private var indicatorColor: Color {
        state.isReady ? .accentColor : .secondary
    }

    private var readinessAnimation: Animation? {
        guard !accessibilityReduceMotion else { return nil }

        return state.isReady
            ? .smooth(duration: 0.28)
            : .smooth(duration: 0.22)
    }

    private var verticalOffset: CGFloat {
        let availableHeight = isEmptyState
            ? resistedHeight
            : min(state.distance, maximumHeight)
        return max((availableHeight - contentHeight) / 2, 0)
    }

    private var resistedHeight: CGFloat {
        let distanceBeforeThreshold = min(state.distance, threshold)
        let distanceAfterThreshold = max(state.distance - threshold, 0)
        return min(
            max(distanceBeforeThreshold * 0.68 + distanceAfterThreshold * 0.16, 0),
            maximumHeight
        )
    }

    private func title(for action: HabitsPullAction) -> LocalizedStringKey {
        switch action {
        case .returnToToday:
            return "Сегодня"
        }
    }

    private func systemImage(for action: HabitsPullAction) -> String {
        switch action {
        case .returnToToday:
            return returnToTodaySystemImage
        }
    }
}
