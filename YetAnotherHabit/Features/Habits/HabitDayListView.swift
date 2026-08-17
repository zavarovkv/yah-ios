import SwiftData
import SwiftUI

struct HabitDayListView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [HabitCompletion]

    let habits: [Habit]
    let selectedDate: Date
    @Binding var persistenceError: String?

    init(
        habits: [Habit],
        selectedDate: Date,
        calendar: Calendar,
        persistenceError: Binding<String?>
    ) {
        self.habits = habits
        self.selectedDate = selectedDate
        _persistenceError = persistenceError

        let dayKey = WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        _completions = Query(
            filter: #Predicate<HabitCompletion> { completion in
                completion.dayKey == dayKey
            }
        )
    }

    var body: some View {
        List {
            ForEach(habits) { habit in
                HabitRowView(
                    habit: habit,
                    isCompleted: completion(for: habit) != nil,
                    onToggleCompletion: { toggleCompletion(for: habit) }
                )
            }
            .onDelete(perform: deleteHabits)
        }
        .listStyle(.plain)
    }

    private func completion(for habit: Habit) -> HabitCompletion? {
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        )
        return completions.first { $0.identifier == identifier }
    }

    private func toggleCompletion(for habit: Habit) {
        let dayKey = WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        let identifier = HabitCompletion.identifier(habitID: habit.identifier, dayKey: dayKey)
        let matchingCompletions = completions.filter { $0.identifier == identifier }

        if matchingCompletions.isEmpty {
            modelContext.insert(
                HabitCompletion(
                    date: calendar.startOfDay(for: selectedDate),
                    dayKey: dayKey,
                    habit: habit
                )
            )
        } else {
            matchingCompletions.forEach(modelContext.delete)
        }

        saveChanges()
    }

    private func deleteHabits(at offsets: IndexSet) {
        offsets.map { habits[$0] }.forEach(modelContext.delete)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceError = error.localizedDescription
        }
    }
}
