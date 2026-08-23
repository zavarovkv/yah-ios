import SwiftData
import SwiftUI

struct HabitDayListView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext

    let habits: [Habit]
    let selectedDate: Date
    let completionCounts: [String: Int]
    let completedIdentifiers: Set<String>
    let onCountChanged: (_ identifier: String, _ count: Int) -> Void
    let onOpenHabit: (UUID) -> Void
    let onEditHabit: (UUID) -> Void
    let onScrollTopChanged: (Bool) -> Void
    @Binding var prefersCompletedSectionExpanded: Bool
    @Binding var prefersCountersSectionExpanded: Bool
    @Binding var persistenceError: String?

    var body: some View {
        List {
            if showsDailySuccessBanner {
                Section {
                    dailySuccessBanner
                }
            }

            if !pendingHabits.isEmpty {
                Section {
                    sectionHeaderLabel(
                        title: "Не выполнено",
                        count: pendingHabits.count,
                        isExpanded: true,
                        showsDisclosureIndicator: false
                    )
                    .habitSectionHeaderRowStyle()

                    ForEach(pendingHabits) { habit in
                        habitRow(for: habit)
                    }
                }
            }

            if !openCounterHabits.isEmpty {
                collapsibleHabitSection(
                    title: "Счётчики",
                    count: openCounterHabits.count,
                    expandedPreference: $prefersCountersSectionExpanded,
                    expandedHint: "Скрыть счётчики",
                    collapsedHint: "Показать счётчики"
                ) {
                    ForEach(openCounterHabits) { habit in
                        habitRow(for: habit)
                    }
                }
            }

            if !completedHabits.isEmpty {
                collapsibleHabitSection(
                    title: "Выполнено",
                    count: completedHabits.count,
                    expandedPreference: $prefersCompletedSectionExpanded,
                    expandedHint: "Скрыть выполненные привычки",
                    collapsedHint: "Показать выполненные привычки"
                ) {
                    ForEach(completedHabits) { habit in
                        habitRow(for: habit)
                    }
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.top, 0, for: .scrollContent)
        .animation(.snappy(duration: 0.3), value: habits.map(\.identifier))
        .animation(.snappy(duration: 0.25), value: openCounterHabits.count)
        .animation(.snappy(duration: 0.25), value: completedHabits.count)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y <= geometry.contentInsets.top + 1
        } action: { _, isAtTop in
            onScrollTopChanged(isAtTop)
        }
    }

    private var dailySuccessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Все цели достигнуты")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Отличная работа!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.green.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var showsDailySuccessBanner: Bool {
        HabitDailySuccessPolicy.shouldShowBanner(
            for: selectedDate,
            habits: habits,
            completionCounts: completionCounts,
            calendar: calendar
        )
    }

    @ViewBuilder
    private func habitRow(for habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            count: count(for: habit),
            streak: streak(for: habit),
            canChangeCompletion: canChangeCompletion,
            onToggleCompletion: { toggleCompletion(for: habit) },
            onCountChanged: { setCount($0, for: habit) },
            onOpenAnalytics: { onOpenHabit(habit.identifier) }
        )
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onEditHabit(habit.identifier)
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canChangeCompletion, habit.kind == .habit {
                Button {
                    toggleCompletion(for: habit)
                } label: {
                    if isCompleted(habit) {
                        Label("Не выполнено", systemImage: "xmark")
                    } else {
                        Label("Выполнено", systemImage: "checkmark")
                    }
                }
                .tint(isCompleted(habit) ? .gray : .green)
            }
        }
    }

    @ViewBuilder
    private func collapsibleHabitSection<Content: View>(
        title: LocalizedStringKey,
        count: Int,
        expandedPreference: Binding<Bool>,
        expandedHint: LocalizedStringKey,
        collapsedHint: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isHistoricalDay {
            Section {
                sectionHeaderLabel(
                    title: title,
                    count: count,
                    isExpanded: true,
                    showsDisclosureIndicator: false
                )
                .habitSectionHeaderRowStyle()

                content()
            }
        } else {
            Section {
                Button {
                    withAnimation(.smooth(duration: 0.32)) {
                        expandedPreference.wrappedValue.toggle()
                    }
                } label: {
                    sectionHeaderLabel(
                        title: title,
                        count: count,
                        isExpanded: expandedPreference.wrappedValue,
                        showsDisclosureIndicator: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(
                    expandedPreference.wrappedValue ? expandedHint : collapsedHint
                )
                .habitSectionHeaderRowStyle()

                if expandedPreference.wrappedValue {
                    content()
                }
            }
        }
    }

    private func sectionHeaderLabel(
        title: LocalizedStringKey,
        count: Int,
        isExpanded: Bool,
        showsDisclosureIndicator: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(count, format: .number)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())

            Spacer()

            if showsDisclosureIndicator {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
        }
        .textCase(nil)
        .contentShape(Rectangle())
    }

    private var pendingHabits: [Habit] {
        habits.filter {
            $0.contributesToDailyGoal
                && !HabitDaySorter.belongsToCompletedSection($0, count: count(for: $0))
        }
    }

    private var completedHabits: [Habit] {
        habits.filter {
            HabitDaySorter.belongsToCompletedSection($0, count: count(for: $0))
        }
    }

    private var openCounterHabits: [Habit] {
        habits.filter { $0.kind == .counter && $0.effectiveTargetCount == nil }
    }

    private var isHistoricalDay: Bool {
        HabitDayPolicy.isHistorical(selectedDate, calendar: calendar)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        habit.isGoalMet(by: count(for: habit))
    }

    private func count(for habit: Habit) -> Int {
        completionCounts[completionIdentifier(for: habit), default: 0]
    }

    private func streak(for habit: Habit) -> Int {
        HabitStreakCalculator.streak(
            for: habit,
            through: selectedDate,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var canChangeCompletion: Bool {
        HabitDayPolicy.canChangeStatus(on: selectedDate, calendar: calendar)
    }

    private func toggleCompletion(for habit: Habit) {
        setCompletion(!isCompleted(habit), for: habit)
    }

    private func setCompletion(_ isCompleted: Bool, for habit: Habit) {
        setCount(isCompleted ? 1 : 0, for: habit)
    }

    private func setCount(_ count: Int, for habit: Habit) {
        guard canChangeCompletion else { return }

        let identifier = completionIdentifier(for: habit)

        do {
            try HabitCompletionStore.setCount(
                count,
                habit: habit,
                date: selectedDate,
                calendar: calendar,
                context: modelContext
            )
            onCountChanged(identifier, count)
        } catch {
            modelContext.rollback()
            persistenceError = error.localizedDescription
        }
    }

    private func completionIdentifier(for habit: Habit) -> String {
        HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        )
    }
}

private extension View {
    // SwiftUI pins native List section headers in the plain style and exposes
    // no opt-out on iOS 18. A regular list row preserves List swipe behavior
    // while allowing the title to scroll naturally with its section.
    func habitSectionHeaderRowStyle() -> some View {
        frame(minHeight: 44)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityAddTraits(.isHeader)
    }
}
