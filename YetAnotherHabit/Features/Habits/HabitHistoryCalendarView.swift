import SwiftUI

struct HabitHistoryCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let habit: Habit
    let completedIdentifiers: Set<String>
    let completionCounts: [String: Int]

    @State private var displayedMonth = Date.now

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .disabled(!canMoveToPreviousMonth)
                .accessibilityLabel("Предыдущий месяц")

                Spacer()

                Text(
                    displayedMonth.formatted(
                        .dateTime.month(.wide).year().locale(locale)
                    )
                )
                .font(.headline)

                Spacer()

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .disabled(!canMoveToNextMonth)
                .accessibilityLabel("Следующий месяц")
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<7, id: \.self) { weekday in
                    Text(
                        WeekCalendar.weekdayTitle(
                            forMondayBasedIndex: weekday,
                            locale: locale
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(weekday >= 5 ? Color.red.opacity(0.7) : .secondary)
                }

                ForEach(MonthGrid.cells(for: displayedMonth, calendar: calendar)) { cell in
                    if let date = cell.date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            displayedMonth = MonthGrid.start(of: .now, calendar: calendar)
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 7)
    }

    private func dayCell(_ date: Date) -> some View {
        let status = HabitAnalyticsCalculator.status(
            for: date,
            habit: habit,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )

        return Text(date, format: .dateTime.day())
            .font(.subheadline.weight(.medium))
            .foregroundStyle(foregroundStyle(for: status))
            .frame(width: 36, height: 36)
            .background {
                dayBackground(for: status)
            }
            .frame(width: 40, height: 40)
            .overlay(alignment: .bottom) {
                if calendar.isDateInToday(date) {
                    Circle()
                        .fill(status == .completed ? Color.white : habitColor)
                        .frame(width: 4, height: 4)
                        .padding(.bottom, 4)
                }
            }
            .accessibilityLabel(
                date.formatted(
                    .dateTime
                        .weekday(.wide)
                        .day()
                        .month(.wide)
                        .year()
                        .locale(locale)
                )
            )
            .accessibilityValue(accessibilityValue(for: status, date: date))
    }

    @ViewBuilder
    private func dayBackground(for status: HabitAnalyticsCalculator.DayStatus) -> some View {
        switch status {
        case .completed:
            Circle().fill(habitColor)
        case .missed:
            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        case .unavailable, .unscheduled, .upcoming, .pending:
            EmptyView()
        }
    }

    private func foregroundStyle(
        for status: HabitAnalyticsCalculator.DayStatus
    ) -> Color {
        switch status {
        case .completed:
            .white
        case .missed, .pending:
            .primary
        case .upcoming, .unscheduled:
            Color.secondary.opacity(0.55)
        case .unavailable:
            Color.secondary.opacity(0.25)
        }
    }

    private func accessibilityValue(
        for status: HabitAnalyticsCalculator.DayStatus,
        date: Date
    ) -> Text {
        if habit.kind == .counter {
            let identifier = HabitCompletionPeriod.identifier(
                for: habit,
                containing: date,
                calendar: calendar
            )
            return statusAccessibilityValue(for: status)
                + Text(", ")
                + Text("Количество: \(completionCounts[identifier, default: 0])")
        }

        return statusAccessibilityValue(for: status)
    }

    private func statusAccessibilityValue(
        for status: HabitAnalyticsCalculator.DayStatus
    ) -> Text {
        switch status {
        case .completed:
            return Text("Выполнено")
        case .missed:
            return Text("Не выполнено")
        case .pending, .upcoming:
            return Text("Запланировано")
        case .unavailable, .unscheduled:
            return Text("Не запланировано")
        }
    }

    private var canMoveToPreviousMonth: Bool {
        displayedMonth > MonthGrid.start(of: habit.createdAt, calendar: calendar)
    }

    private var canMoveToNextMonth: Bool {
        displayedMonth < MonthGrid.start(of: .now, calendar: calendar)
    }

    private func moveMonth(by value: Int) {
        withAnimation(
            accessibilityReduceMotion ? nil : .easeInOut(duration: 0.2)
        ) {
            displayedMonth = MonthGrid.addingMonths(
                value,
                to: displayedMonth,
                calendar: calendar
            )
        }
    }

    private var habitColor: Color {
        HabitColor(rawValue: habit.color)?.color ?? .blue
    }
}
