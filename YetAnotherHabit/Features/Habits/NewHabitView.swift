import SwiftData
import SwiftUI

struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext

    let selectedDate: Date
    let onSaved: (Habit) -> Void

    @State private var draft: HabitDraft
    @State private var saveError: String?

    init(selectedDate: Date, onSaved: @escaping (Habit) -> Void) {
        self.selectedDate = selectedDate
        self.onSaved = onSaved
        _draft = State(initialValue: .randomized())
    }

    var body: some View {
        HabitFormView(
            draft: $draft,
            actionTitle: "Добавить",
            action: addHabit
        )
        .navigationTitle("Новая привычка")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .saveErrorAlert($saveError)
    }

    private func addHabit() {
        guard draft.isValid else { return }
        let habit = draft.makeHabit(
            createdAt: calendar.startOfDay(for: selectedDate)
        )

        modelContext.insert(habit)

        do {
            try modelContext.save()
            onSaved(habit)
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
