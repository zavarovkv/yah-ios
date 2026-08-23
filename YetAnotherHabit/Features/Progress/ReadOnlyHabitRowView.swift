import SwiftUI

struct ReadOnlyHabitRowView: View {
    let habit: Habit
    let count: Int
    let streak: Int

    private var isCompleted: Bool {
        habit.contributesToDailyGoal && habit.isGoalMet(by: count)
    }

    var body: some View {
        HStack(spacing: 12) {
            HabitStatusIconView(habit: habit, isCompleted: isCompleted)
            HabitSummaryView(
                habit: habit,
                isCompleted: isCompleted,
                streak: streak,
                count: count
            )
        }
        .habitCardStyle(habit: habit, isCompleted: isCompleted)
        .accessibilityElement(children: .combine)
    }
}
