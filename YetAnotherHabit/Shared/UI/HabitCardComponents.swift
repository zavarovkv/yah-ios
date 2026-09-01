import SwiftUI

enum HabitCardVisualState: Equatable {
    case pending
    case counter
    case completed

    init(habit: Habit, isCompleted: Bool) {
        if isCompleted {
            self = .completed
        } else if habit.kind == .counter {
            self = .counter
        } else {
            self = .pending
        }
    }

    var fillColor: Color {
        switch self {
        case .pending:
            Color.secondary.opacity(0.08)
        case .counter:
            Color.orange.opacity(0.12)
        case .completed:
            Color.green.opacity(0.12)
        }
    }

    var borderColor: Color {
        switch self {
        case .pending:
            Color.secondary.opacity(0.1)
        case .counter:
            Color.orange.opacity(0.18)
        case .completed:
            Color.green.opacity(0.18)
        }
    }
}

struct HabitStatusIconView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let habit: Habit
    let isCompleted: Bool

    var body: some View {
        Image(
            systemName: habit.kind == .habit && isCompleted
                ? "checkmark"
                : habit.icon
        )
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(
                .bounce,
                options: .nonRepeating,
                value: accessibilityReduceMotion ? false : isCompleted
            )
            .font(.headline)
            .foregroundStyle(habitColor.color)
            .frame(width: 40, height: 40)
            .background(
                habitColor.color.opacity(isCompleted ? 0.24 : 0.16),
                in: Circle()
            )
            .opacity(isCompleted ? 1 : 0.72)
            .transaction { transaction in
                if accessibilityReduceMotion {
                    transaction.animation = nil
                }
            }
    }

    private var habitColor: HabitColor {
        HabitColor(rawValue: habit.color) ?? .blue
    }
}

struct HabitSummaryView: View {
    let habit: Habit
    let isCompleted: Bool
    let streak: Int
    var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.body.weight(.medium))
                .lineLimit(2)
                .truncationMode(.tail)

            if habit.kind == .counter {
                counterSubtitle
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if streak >= 2 {
                Text("Серия из \(streak) дней")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var counterSubtitle: Text {
        switch (habit.effectiveCounterInterval, habit.effectiveTargetCount) {
        case (.daily, .some(let target)):
            Text("\(count) из \(target) сегодня")
        case (.daily, .none):
            Text("\(count) сегодня")
        case (.weekly, .some(let target)):
            Text("\(count) из \(target) на этой неделе")
        case (.weekly, .none):
            Text("\(count) на этой неделе")
        case (.biweekly, .some(let target)):
            Text("\(count) из \(target) за две недели")
        case (.biweekly, .none):
            Text("\(count) за две недели")
        case (.monthly, .some(let target)):
            Text("\(count) из \(target) в этом месяце")
        case (.monthly, .none):
            Text("\(count) в этом месяце")
        case (.yearly, .some(let target)):
            Text("\(count) из \(target) в этом году")
        case (.yearly, .none):
            Text("\(count) в этом году")
        }
    }

}

private struct HabitCardStyle: ViewModifier {
    let state: HabitCardVisualState

    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

                shape
                    .fill(state.fillColor)
                    .overlay {
                        shape.strokeBorder(
                            state.borderColor,
                            lineWidth: 1
                        )
                    }
            }
            .padding(.vertical, 2)
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

extension View {
    func habitCardStyle(habit: Habit, isCompleted: Bool) -> some View {
        modifier(
            HabitCardStyle(
                state: HabitCardVisualState(
                    habit: habit,
                    isCompleted: isCompleted
                )
            )
        )
    }
}
