import SwiftData
import SwiftUI

struct DayProgressView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query(filter: #Predicate<HabitCompletion> { $0.isCompleted })
    private var completions: [HabitCompletion]

    let date: Date

    var body: some View {
        let identifiers = completedIdentifiers

        NavigationStack {
            Group {
                if scheduledHabits.isEmpty {
                    ContentUnavailableView(
                        "Привычек на этот день нет.",
                        systemImage: "checkmark.circle",
                        description: Text("Для выбранной даты ничего не запланировано.")
                    )
                } else {
                    List(scheduledHabits) { habit in
                        ReadOnlyHabitRowView(
                            habit: habit,
                            count: count(for: habit),
                            streak: streak(
                                for: habit,
                                completedIdentifiers: identifiers
                            )
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
                    locale: locale
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var scheduledHabits: [Habit] {
        let visibleHabits = appDataState.visibleHabits(from: habits)
        return HabitDaySorter.sorted(
            visibleHabits.filter { $0.isScheduled(on: date, calendar: calendar) },
            for: date,
            completionCounts: completionCounts,
            calendar: calendar
        )
    }

    private func count(for habit: Habit) -> Int {
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: date, calendar: calendar)
        )
        return completionCounts[identifier, default: 0]
    }

    private func streak(
        for habit: Habit,
        completedIdentifiers: Set<String>
    ) -> Int {
        HabitStreakCalculator.streak(
            for: habit,
            through: date,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var completedIdentifiers: Set<String> {
        HabitCompletionIndex.identifiers(
            in: completionCounts,
            habits: appDataState.visibleHabits(from: habits)
        )
    }

    private var completionCounts: [String: Int] {
        appDataState.visibleCompletionCounts(
            from: HabitCompletionIndex.counts(in: completions)
        )
    }
}
