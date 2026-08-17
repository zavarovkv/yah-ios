import SwiftData
import SwiftUI

struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedIcon = "checkmark"
    @State private var selectedColor = HabitColor.blue
    @State private var scheduledWeekdays = Set(0..<7)
    @State private var saveError: String?

    var body: some View {
        HabitFormView(
            name: $name,
            selectedIcon: $selectedIcon,
            selectedColor: $selectedColor,
            scheduledWeekdays: $scheduledWeekdays,
            actionTitle: "Добавить",
            action: addHabit
        )
        .navigationTitle("Новая привычка")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .saveErrorAlert($saveError)
    }

    private func addHabit() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor.rawValue,
            scheduledWeekdays: scheduledWeekdays.sorted()
        )

        modelContext.insert(habit)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(habit)
            saveError = error.localizedDescription
        }
    }
}
