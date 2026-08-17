import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habit: Habit
    let onDeleted: (UUID) -> Void

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: HabitColor
    @State private var scheduledWeekdays: Set<Int>
    @State private var saveError: String?
    @State private var isConfirmingDeletion = false

    init(habit: Habit, onDeleted: @escaping (UUID) -> Void) {
        self.habit = habit
        self.onDeleted = onDeleted
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
            action: saveHabit,
            showsActionButton: false,
            deleteAction: { isConfirmingDeletion = true }
        )
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить", action: saveHabit)
                    .disabled(trimmedName.isEmpty || scheduledWeekdays.isEmpty)
            }
        }
        .alert(
            "Удалить привычку?",
            isPresented: $isConfirmingDeletion
        ) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive, action: deleteHabit)
        } message: {
            Text("Вся история выполнения этой привычки будет удалена.")
        }
        .saveErrorAlert($saveError)
    }

    private func saveHabit() {
        habit.name = trimmedName
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

    private func deleteHabit() {
        let identifier = habit.identifier
        modelContext.delete(habit)

        do {
            try modelContext.save()
            onDeleted(identifier)
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
