import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext

    let habit: Habit
    let onDeleted: (UUID) -> Void

    @State private var draft: HabitDraft
    @State private var saveError: String?
    @State private var isConfirmingDeletion = false
    @State private var isConfirmingHistoricalRuleChange = false
    @State private var isSaving = false

    init(habit: Habit, onDeleted: @escaping (UUID) -> Void) {
        self.habit = habit
        self.onDeleted = onDeleted
        _draft = State(initialValue: HabitDraft(habit: habit))
    }

    var body: some View {
        HabitFormView(
            draft: $draft,
            actionTitle: "Сохранить",
            action: requestSave,
            showsActionButton: false,
            deleteAction: { isConfirmingDeletion = true }
        )
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить", action: requestSave)
                    .disabled(!draft.isValid || isSaving)
            }
        }
        .confirmationDialog(
            "Изменить правила привычки?",
            isPresented: $isConfirmingHistoricalRuleChange,
            titleVisibility: .visible
        ) {
            Button("Сохранить изменения", action: saveHabit)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(
                "Расписание, цель или интервал применятся ко всей истории и могут изменить аналитику."
            )
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

    private func requestSave() {
        guard draft.isValid else { return }
        guard !habit.completions.isEmpty, draft.changesHistoricalRules(of: habit) else {
            saveHabit()
            return
        }
        isConfirmingHistoricalRuleChange = true
    }

    private func saveHabit() {
        guard !isSaving else { return }
        Task { await saveHabitAsync() }
    }

    @MainActor
    private func saveHabitAsync() async {
        guard draft.isValid else { return }
        isSaving = true
        defer { isSaving = false }

        if draft.hasReminder, draft.changesReminder(of: habit) {
            do {
                guard try await HabitReminderScheduler.requestAuthorizationIfNeeded() else {
                    saveError = AppLocalization.string(
                        "Разрешите уведомления в настройках системы или отключите напоминание.",
                        locale: locale
                    )
                    return
                }
            } catch {
                saveError = error.localizedDescription
                return
            }
        }

        let previousInterval = habit.effectiveCounterInterval
        draft.apply(to: habit)

        do {
            if previousInterval != habit.effectiveCounterInterval {
                try HabitCompletionStore.rebucketCompletions(
                    for: habit,
                    calendar: calendar,
                    context: modelContext
                )
            }
            try await HabitReminderScheduler.synchronize(habit: habit, locale: locale)
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            try? await HabitReminderScheduler.synchronize(habit: habit, locale: locale)
            saveError = error.localizedDescription
        }
    }

    private func deleteHabit() {
        let identifier = habit.identifier
        modelContext.delete(habit)

        do {
            try modelContext.save()
            HabitReminderScheduler.remove(habitID: identifier)
            onDeleted(identifier)
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
