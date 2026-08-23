import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habit: Habit
    let onDeleted: (UUID) -> Void

    @State private var draft: HabitDraft
    @State private var saveError: String?
    @State private var isConfirmingDeletion = false

    init(habit: Habit, onDeleted: @escaping (UUID) -> Void) {
        self.habit = habit
        self.onDeleted = onDeleted
        _draft = State(initialValue: HabitDraft(habit: habit))
    }

    var body: some View {
        HabitFormView(
            draft: $draft,
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
                    .disabled(!draft.isValid)
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
        guard draft.isValid else { return }
        draft.apply(to: habit)

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
}
