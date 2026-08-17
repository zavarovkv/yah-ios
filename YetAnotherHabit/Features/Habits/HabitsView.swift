import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var selectedDate = Date.now
    @State private var displayedWeekStart = WeekCalendar.startOfWeek(containing: .now)
    @State private var isPresentingNewHabit = false
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                WeekCalendarPagerView(
                    displayedWeekStart: $displayedWeekStart,
                    selectedDate: $selectedDate
                )

                Group {
                    if scheduledHabits.isEmpty {
                        ContentUnavailableView(
                            habits.isEmpty ? "Привычек пока нет" : "На этот день привычек нет",
                            systemImage: "checkmark.circle",
                            description: Text(
                                habits.isEmpty
                                    ? "Создайте первую привычку, чтобы начать."
                                    : "Выберите другой день или измените расписание."
                            )
                        )
                    } else {
                        HabitDayListView(
                            habits: scheduledHabits,
                            selectedDate: selectedDate,
                            calendar: calendar,
                            persistenceError: $persistenceError
                        )
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isPresentingNewHabit) {
                NewHabitView()
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
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .accessibilityLabel("Добавить привычку")
            }
        }
        .frame(height: 56)
        .padding(.horizontal)
    }

    private var scheduledHabits: [Habit] {
        habits.filter { $0.isScheduled(on: selectedDate, calendar: calendar) }
    }

    private func returnToToday() {
        let today = Date.now
        selectedDate = today
        displayedWeekStart = WeekCalendar.startOfWeek(containing: today, calendar: calendar)
    }

}
