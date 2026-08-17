import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCompletion) {
                Image(systemName: isCompleted ? "checkmark" : habit.icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(color, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Отметить невыполненной" : "Отметить выполненной")

            NavigationLink {
                EditHabitView(habit: habit)
            } label: {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            0
        }
    }

    private var color: Color {
        HabitColor(rawValue: habit.color)?.color ?? .blue
    }
}
