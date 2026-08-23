import SwiftData
import SwiftUI

struct HabitAnalyticsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Query(filter: #Predicate<HabitCompletion> { $0.isCompleted })
    private var completions: [HabitCompletion]

    let habit: Habit
    let onEdit: () -> Void

    var body: some View {
        let identifiers = completedIdentifiers
        let snapshot = HabitAnalyticsCalculator.snapshot(
            for: habit,
            completedIdentifiers: identifiers,
            through: .now,
            calendar: calendar
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                overviewSection(snapshot: snapshot)

                analyticsSection("История") {
                    HabitHistoryCalendarView(
                        habit: habit,
                        completedIdentifiers: identifiers,
                        completionCounts: completionCounts
                    )
                }

                analyticsSection("Расписание") {
                    Label(scheduleTitle, systemImage: "calendar")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Редактировать", systemImage: "pencil", action: onEdit)
            }
        }
    }

    private func overviewSection(
        snapshot: HabitAnalyticsCalculator.Snapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Обзор")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                metricCard(
                    title: "Текущая серия",
                    value: String(snapshot.currentStreak),
                    systemImage: "flame.fill"
                )
                metricCard(
                    title: "Лучшая серия",
                    value: String(snapshot.bestStreak),
                    systemImage: "trophy.fill"
                )
                metricCard(
                    title: "За 30 дней",
                    value: recentProgressTitle(for: snapshot),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                metricCard(
                    title: habit.kind == .counter ? "Общее количество" : "Всего выполнений",
                    value: String(totalValue(for: snapshot)),
                    systemImage: "checkmark.circle.fill"
                )
            }
        }
    }

    private func analyticsSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func metricCard(
        title: LocalizedStringKey,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(habitColor)

            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var completedIdentifiers: Set<String> {
        HabitCompletionIndex.identifiers(
            in: completionCounts,
            habits: [habit]
        )
    }

    private var completionCounts: [String: Int] {
        HabitCompletionIndex.counts(
            in: completions,
            for: habit.identifier
        )
    }

    private func totalValue(for snapshot: HabitAnalyticsCalculator.Snapshot) -> Int {
        habit.kind == .counter
            ? completionCounts.values.reduce(0, +)
            : snapshot.completedCount
    }

    private func recentProgressTitle(
        for snapshot: HabitAnalyticsCalculator.Snapshot
    ) -> String {
        guard let progress = snapshot.recentProgress else { return "—" }
        return progress.formatted(
            .percent
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }

    private var scheduleTitle: String {
        habit.scheduledWeekdays
            .sorted()
            .map {
                WeekCalendar.weekdayTitle(
                    forMondayBasedIndex: $0,
                    locale: locale
                )
            }
            .joined(separator: ", ")
    }

    private var habitColor: Color {
        HabitColor(rawValue: habit.color)?.color ?? .blue
    }
}
