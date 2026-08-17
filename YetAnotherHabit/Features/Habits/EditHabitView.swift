import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habit: Habit

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: HabitColor
    @State private var scheduledWeekdays: Set<Int>
    @State private var saveError: String?

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: HabitColor(rawValue: habit.color) ?? .blue)
        _scheduledWeekdays = State(initialValue: Set(habit.scheduledWeekdays))
    }

    var body: some View {
        HabitFormView(
            name: $name,
            selectedIcon: $selectedIcon,
            selectedColor: $selectedColor,
            scheduledWeekdays: $scheduledWeekdays,
            actionTitle: "Сохранить",
            action: saveHabit
        )
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .saveErrorAlert($saveError)
    }

    private func saveHabit() {
        habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.icon = selectedIcon
        habit.color = selectedColor.rawValue
        habit.scheduledWeekdays = scheduledWeekdays.sorted()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
