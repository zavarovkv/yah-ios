import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let streak: Int
    let canToggleCompletion: Bool
    let onToggleCompletion: () -> Void
    let onDeleted: (UUID) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCompletion) {
                Image(systemName: isCompleted ? "checkmark" : habit.icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        isCompleted ? Color.white.opacity(0.22) : color,
                        in: Circle()
                    )
                    .opacity(isCompleted ? 1 : 0.55)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(canToggleCompletion)
            .accessibilityLabel(isCompleted ? "Отметить невыполненной" : "Отметить выполненной")
            .accessibilityRespondsToUserInteraction(canToggleCompletion)

            NavigationLink {
                EditHabitView(habit: habit, onDeleted: onDeleted)
            } label: {
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
            }
            .tint(isCompleted ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCompleted ? color : color.opacity(0.12))
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }

    private var color: Color {
        HabitColor(rawValue: habit.color)?.color ?? .blue
    }
}
