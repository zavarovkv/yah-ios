import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let count: Int
    let streak: Int
    let canChangeCompletion: Bool
    let onToggleCompletion: () -> Void
    let onCountChanged: (Int) -> Void
    let onOpenAnalytics: () -> Void

    private var isCompleted: Bool {
        habit.contributesToDailyGoal && habit.isGoalMet(by: count)
    }

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon

            Button(action: onOpenAnalytics) {
                HabitSummaryView(
                    habit: habit,
                    isCompleted: isCompleted,
                    streak: streak,
                    count: count
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .accessibilityHint("Открыть аналитику привычки")

            if habit.kind == .counter, canChangeCompletion {
                Stepper(
                    value: Binding(
                        get: { count },
                        set: onCountChanged
                    ),
                    in: 0...HabitCompletionStore.maximumDailyCount
                ) {
                    EmptyView()
                }
                .labelsHidden()
                .fixedSize()
                .sensoryFeedback(.selection, trigger: count)
                .accessibilityLabel("Количество")
                .accessibilityValue(Text(count, format: .number))
            }
        }
        .habitCardStyle(habit: habit, isCompleted: isCompleted)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: count)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if habit.kind == .habit, canChangeCompletion {
            Button(action: onToggleCompletion) {
                HabitStatusIconView(habit: habit, isCompleted: isCompleted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Не выполнено" : "Выполнено")
        } else {
            HabitStatusIconView(
                habit: habit,
                isCompleted: isCompleted
            )
            .accessibilityHidden(true)
        }
    }
}
