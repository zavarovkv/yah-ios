import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query(sort: \Habit.createdAt, animation: .default) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @State private var selectedDate = Date.now
    @State private var displayedWeekStart = WeekCalendar.startOfWeek(containing: .now)
    @State private var isPresentingNewHabit = false
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    header

                    WeekCalendarPagerView(
                        displayedWeekStart: $displayedWeekStart,
                        selectedDate: $selectedDate,
                        progressByDayKey: progressByDayKey
                    )
                    .padding(.top, 12)

                    if scheduledHabits.isEmpty {
                        Spacer()
                    } else {
                        HabitDayListView(
                            habits: scheduledHabits,
                            selectedDate: selectedDate,
                            completedIdentifiers: completedIdentifiers,
                            onCompletionChanged: recordCompletionChange,
                            onHabitDeleted: { appDataState.recordDeleted(identifier: $0) },
                            persistenceError: $persistenceError
                        )
                        .id(WeekCalendar.dayKey(for: selectedDate, calendar: calendar))
                    }
                }

                if scheduledHabits.isEmpty {
                    ScreenEmptyState(
                        title: displayedHabits.isEmpty
                            ? "Привычек пока нет."
                            : "На этот день привычек нет.",
                        systemImage: "checkmark.circle",
                        description: displayedHabits.isEmpty
                            ? "Создайте первую привычку, чтобы начать."
                            : "Выберите другой день или измените расписание."
                    )
                    .allowsHitTesting(false)
                }
            }
            .simultaneousGesture(returnToTodayGesture)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isPresentingNewHabit) {
                NewHabitView(selectedDate: selectedDate) { habit in
                    appDataState.recordAdded(habit)
                }
            }
            .onChange(of: habits.map(\.identifier)) {
                reconcileAppDataState()
            }
            .onChange(of: completions.map(\.identifier)) {
                reconcileAppDataState()
            }
            .saveErrorAlert($persistenceError)
        }
    }

    private var header: some View {
        ZStack {
            Button(action: returnToToday) {
                Text(
                    DateTitleFormatter.title(
                        for: selectedDate,
                        calendar: calendar,
                        locale: locale
                    )
                )
                .font(.headline)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Вернуться к сегодняшней дате")

            HStack {
                Spacer()

                Button {
                    isPresentingNewHabit = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(.accentColor)
                .accessibilityLabel("Добавить привычку")
            }
        }
        .frame(height: 56)
        .padding(.horizontal)
    }

    private var scheduledHabits: [Habit] {
        displayedHabits.filter { $0.isScheduled(on: selectedDate, calendar: calendar) }
    }

    private var displayedHabits: [Habit] {
        appDataState.visibleHabits(from: habits)
    }

    private var progressByDayKey: [String: Double] {
        let today = calendar.startOfDay(for: .now)

        return WeekCalendar.dates(starting: displayedWeekStart, calendar: calendar)
            .reduce(into: [:]) { result, date in
                guard calendar.startOfDay(for: date) <= today else { return }

                let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
                result[dayKey] = HabitProgressCalculator.progress(
                    for: date,
                    habits: displayedHabits,
                    completedIdentifiers: completedIdentifiers,
                    calendar: calendar
                )
            }
    }

    private var completedIdentifiers: Set<String> {
        appDataState.visibleCompletionIdentifiers(
            from: Set(completions.map(\.identifier))
        )
    }

    private func recordCompletionChange(identifier: String, isCompleted: Bool) {
        appDataState.recordCompletion(identifier: identifier, isCompleted: isCompleted)
    }

    private func reconcileAppDataState() {
        appDataState.reconcile(
            habits: habits,
            completionIdentifiers: Set(completions.map(\.identifier))
        )
    }

    private func returnToToday() {
        let today = Date.now
        selectedDate = today
        displayedWeekStart = WeekCalendar.startOfWeek(containing: today, calendar: calendar)
    }

    private var returnToTodayGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let translation = value.translation
                guard
                    translation.height > 60,
                    abs(translation.height) > abs(translation.width)
                else {
                    return
                }

                withAnimation {
                    returnToToday()
                }
            }
    }

}
