import SwiftUI

struct DayProgressView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    let data: HabitPresentationData
    let date: Date

    var body: some View {
        let identifiers = completedIdentifiers
        let sections = HabitDaySorter.sections(
            in: scheduledHabits,
            for: date,
            calendar: calendar
        ) { count(for: $0) }

        NavigationStack {
            Group {
                if scheduledHabits.isEmpty {
                    ContentUnavailableView(
                        "Привычек на этот день нет.",
                        systemImage: "checkmark.circle",
                        description: Text("Для выбранной даты ничего не запланировано.")
                    )
                } else {
                    List {
                        habitSection(
                            title: "Не выполнено",
                            habits: sections.pending,
                            completedIdentifiers: identifiers
                        )
                        habitSection(
                            title: "Счётчики",
                            habits: sections.openCounters,
                            completedIdentifiers: identifiers
                        )
                        habitSection(
                            title: "Выполнено",
                            habits: sections.completed,
                            completedIdentifiers: identifiers
                        )
                    }
                    .listStyle(.plain)
                    .contentMargins(.top, 0, for: .scrollContent)
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

    @ViewBuilder
    private func habitSection(
        title: LocalizedStringKey,
        habits: [Habit],
        completedIdentifiers: Set<String>
    ) -> some View {
        if !habits.isEmpty {
            Section {
                HabitSectionHeaderView(title: title, count: habits.count)
                    .habitSectionHeaderRowStyle()

                ForEach(habits) { habit in
                    ReadOnlyHabitRowView(
                        habit: habit,
                        count: count(for: habit),
                        streak: streak(
                            for: habit,
                            completedIdentifiers: completedIdentifiers
                        )
                    )
                }
            }
        }
    }

    private var scheduledHabits: [Habit] {
        return HabitDaySorter.sorted(
            data.habits.filter { $0.isScheduled(on: date, calendar: calendar) },
            for: date,
            completionCounts: completionCounts,
            calendar: calendar
        )
    }

    private func count(for habit: Habit) -> Int {
        let identifier = HabitCompletionPeriod.identifier(
            for: habit,
            containing: date,
            calendar: calendar
        )
        return completionCounts[identifier, default: 0]
    }

    private func streak(
        for habit: Habit,
        completedIdentifiers: Set<String>
    ) -> Int {
        guard habit.kind == .habit else { return 0 }

        if !habit.isGoalMet(by: count(for: habit)) {
            return HabitStreakCalculator.streakBefore(
                date,
                for: habit,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            )
        }

        return HabitStreakCalculator.streak(
            for: habit,
            through: date,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var completedIdentifiers: Set<String> {
        data.completedIdentifiers
    }

    private var completionCounts: [String: Int] {
        data.completionCounts
    }
}
