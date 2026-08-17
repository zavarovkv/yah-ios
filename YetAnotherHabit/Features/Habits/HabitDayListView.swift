import SwiftData
import SwiftUI

struct HabitDayListView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext

    let habits: [Habit]
    let selectedDate: Date
    let completedIdentifiers: Set<String>
    let onCompletionChanged: (_ identifier: String, _ isCompleted: Bool) -> Void
    let onHabitDeleted: (UUID) -> Void
    @Binding var persistenceError: String?

    init(
        habits: [Habit],
        selectedDate: Date,
        completedIdentifiers: Set<String>,
        onCompletionChanged: @escaping (_ identifier: String, _ isCompleted: Bool) -> Void,
        onHabitDeleted: @escaping (UUID) -> Void,
        persistenceError: Binding<String?>
    ) {
        self.habits = habits
        self.selectedDate = selectedDate
        self.completedIdentifiers = completedIdentifiers
        self.onCompletionChanged = onCompletionChanged
        self.onHabitDeleted = onHabitDeleted
        _persistenceError = persistenceError

    }

    var body: some View {
        List {
            ForEach(habits) { habit in
                HabitRowView(
                    habit: habit,
                    isCompleted: isCompleted(habit),
                    streak: streak(for: habit),
                    canToggleCompletion: canChangeCompletion,
                    onToggleCompletion: { toggleCompletion(for: habit) },
                    onDeleted: onHabitDeleted
                )
                .if(canChangeCompletion) { row in
                    row
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                setCompletion(true, for: habit)
                            } label: {
                                Label("Выполнено", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                setCompletion(false, for: habit)
                            } label: {
                                Label("Не выполнено", systemImage: "xmark")
                            }
                            .tint(.gray)
                        }
                    }
                }
            }
        .listStyle(.plain)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        completedIdentifiers.contains(
            HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
            )
        )
    }

    private func streak(for habit: Habit) -> Int {
        HabitStreakCalculator.streak(
            for: habit,
            through: selectedDate,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var canChangeCompletion: Bool {
        calendar.startOfDay(for: selectedDate) <= calendar.startOfDay(for: .now)
    }

    private func toggleCompletion(for habit: Habit) {
        setCompletion(!isCompleted(habit), for: habit)
    }

    private func setCompletion(_ isCompleted: Bool, for habit: Habit) {
        guard canChangeCompletion else { return }

        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        )

        do {
            try HabitCompletionStore.setCompleted(
                isCompleted,
                habit: habit,
                date: selectedDate,
                calendar: calendar,
                context: modelContext
            )
            onCompletionChanged(identifier, isCompleted)
        } catch {
            modelContext.rollback()
            persistenceError = error.localizedDescription
        }
    }
}
