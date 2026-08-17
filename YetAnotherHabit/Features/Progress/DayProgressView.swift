import SwiftData
import SwiftUI

struct DayProgressView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.russian.rawValue
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    let date: Date
    let onWillDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if scheduledHabits.isEmpty {
                    ScreenEmptyState(
                        title: "Привычек на этот день нет.",
                        systemImage: "checkmark.circle",
                        description: "Для выбранной даты ничего не запланировано."
                    )
                } else {
                    List(scheduledHabits) { habit in
                        ReadOnlyHabitRowView(
                            habit: habit,
                            isCompleted: isCompleted(habit),
                            streak: streak(for: habit)
                        )
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(
                DateTitleFormatter.title(
                    for: date,
                    calendar: calendar,
                    locale: selectedLocale
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(
                SheetDismissObserver(onWillDismiss: onWillDismiss)
            )
        }
    }

    private var scheduledHabits: [Habit] {
        appDataState.visibleHabits(from: habits)
            .filter { $0.isScheduled(on: date, calendar: calendar) }
    }

    private var selectedLocale: Locale {
        AppLanguage(rawValue: appLanguage)?.locale ?? locale
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: date, calendar: calendar)
        )
        let identifiers = appDataState.visibleCompletionIdentifiers(
            from: Set(completions.map(\.identifier))
        )
        return identifiers.contains(identifier)
    }

    private func streak(for habit: Habit) -> Int {
        HabitStreakCalculator.streak(
            for: habit,
            through: date,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var completedIdentifiers: Set<String> {
        appDataState.visibleCompletionIdentifiers(
            from: Set(completions.map(\.identifier))
        )
    }
}
