import SwiftData
import SwiftUI

struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext

    let selectedDate: Date
    let onSaved: (Habit) -> Void

    @State private var draft: HabitDraft
    @State private var saveError: String?
    @State private var isSaving = false

    init(selectedDate: Date, onSaved: @escaping (Habit) -> Void) {
        self.selectedDate = selectedDate
        self.onSaved = onSaved
        _draft = State(initialValue: .randomized())
    }

    var body: some View {
        HabitFormView(
            draft: $draft,
            actionTitle: "Добавить",
            action: addHabit,
            showsActionButton: false
        )
        .navigationTitle("Новая привычка")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Добавить", action: addHabit)
                    .disabled(!draft.isValid || isSaving)
            }
        }
        .saveErrorAlert($saveError)
    }

    private func addHabit() {
        guard !isSaving else { return }
        Task { await addHabitAsync() }
    }

    @MainActor
    private func addHabitAsync() async {
        guard draft.isValid else { return }
        isSaving = true
        defer { isSaving = false }

        if draft.hasReminder {
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

        let habit = draft.makeHabit(
            createdAt: calendar.startOfDay(for: selectedDate)
        )

        do {
            try await HabitReminderScheduler.synchronize(habit: habit, locale: locale)
            modelContext.insert(habit)
            try modelContext.save()
            onSaved(habit)
            dismiss()
        } catch {
            modelContext.rollback()
            HabitReminderScheduler.remove(habitID: habit.identifier)
            saveError = error.localizedDescription
        }
    }
}
