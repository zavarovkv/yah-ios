import SwiftUI

struct HabitStatusIconView: View {
    let habit: Habit
    let isCompleted: Bool

    var body: some View {
        Image(
            systemName: habit.kind == .habit && isCompleted
                ? "checkmark"
                : habit.icon
        )
            .font(.headline)
            .foregroundStyle(habitColor.foregroundColor)
            .frame(width: 40, height: 40)
            .background(
                isCompleted ? Color.white.opacity(0.22) : habitColor.color,
                in: Circle()
            )
            .opacity(isCompleted ? 1 : 0.55)
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
                .lineLimit(1)
                .truncationMode(.tail)

            if habit.kind == .counter {
                counterSubtitle
                    .font(.caption)
                    .foregroundStyle(
                        isCompleted ? completedForegroundColor.opacity(0.8) : .secondary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } else if isCompleted, streak >= 2 {
                Text("Серия из \(streak) дней")
                    .font(.caption)
                    .foregroundStyle(completedForegroundColor.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var counterSubtitle: Text {
        if let target = habit.effectiveTargetCount {
            Text("\(count) из \(target)")
        } else {
            Text("Количество: \(count)")
        }
    }

    private var completedForegroundColor: Color {
        (HabitColor(rawValue: habit.color) ?? .blue).foregroundColor
    }
}

private struct HabitCardStyle: ViewModifier {
    let habit: Habit
    let isCompleted: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isCompleted ? habitColor.foregroundColor : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isCompleted
                            ? habitColor.color
                            : habitColor.color.opacity(0.12)
                    )
            }
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private var habitColor: HabitColor {
        HabitColor(rawValue: habit.color) ?? .blue
    }
}

extension View {
    func habitCardStyle(habit: Habit, isCompleted: Bool) -> some View {
        modifier(HabitCardStyle(habit: habit, isCompleted: isCompleted))
    }
}
