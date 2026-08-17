import SwiftUI

struct ReadOnlyHabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark" : habit.icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    isCompleted ? Color.white.opacity(0.22) : color,
                    in: Circle()
                )
                .opacity(isCompleted ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body.weight(.medium))

                if isCompleted, streak >= 2 {
                    Text("Серия из \(streak) дней")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .foregroundStyle(isCompleted ? .white : .primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCompleted ? color : color.opacity(0.12))
        }
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        HabitColor(rawValue: habit.color)?.color ?? .blue
    }
}
