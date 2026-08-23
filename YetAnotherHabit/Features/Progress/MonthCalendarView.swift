import SwiftData
import SwiftUI

struct MonthCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query(filter: #Predicate<HabitCompletion> { $0.isCompleted })
    private var completions: [HabitCompletion]

    @Binding var selectedDate: Date?
    let resetID: Int
    let onDateSelected: (Date) -> Void
    @State private var displayedMonth: Date
    @State private var visiblePage: Int? = 0

    init(
        selectedDate: Binding<Date?>,
        resetID: Int,
        onDateSelected: @escaping (Date) -> Void
    ) {
        _selectedDate = selectedDate
        self.resetID = resetID
        self.onDateSelected = onDateSelected
        _displayedMonth = State(
            initialValue: MonthGrid.start(
                of: selectedDate.wrappedValue ?? .now,
                calendar: .autoupdatingCurrent
            )
        )
    }

    var body: some View {
        let visibleHabits = appDataState.visibleHabits(from: habits)
        let visibleCompletionCounts = appDataState.visibleCompletionCounts(
            from: HabitCompletionIndex.counts(in: completions)
        )
        let visibleCompletionIdentifiers = HabitCompletionIndex.identifiers(
            in: visibleCompletionCounts,
            habits: visibleHabits
        )

        VStack(spacing: 14) {
            HStack {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Предыдущий месяц")

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year().locale(locale)))
                    .font(.headline)

                Spacer()

                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Следующий месяц")
            }

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(-1...1, id: \.self) { offset in
                        monthPage(
                            offset: offset,
                            habits: visibleHabits,
                            completedIdentifiers: visibleCompletionIdentifiers
                        )
                            .containerRelativeFrame(.horizontal)
                            .id(offset)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visiblePage)
            .defaultScrollAnchor(.center)
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .idle {
                    commitVisiblePage()
                }
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onChange(of: resetID) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = MonthGrid.start(of: .now, calendar: calendar)
                visiblePage = 0
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 7)
    }

    private func monthPage(
        offset: Int,
        habits: [Habit],
        completedIdentifiers: Set<String>
    ) -> some View {
        let month = MonthGrid.addingMonths(
            offset,
            to: displayedMonth,
            calendar: calendar
        )
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<7, id: \.self) { weekday in
                Text(WeekCalendar.weekdayTitle(forMondayBasedIndex: weekday, locale: locale))
                    .font(.caption)
                    .foregroundStyle(weekday >= 5 ? Color.red.opacity(0.7) : .secondary)
            }

            ForEach(MonthGrid.cells(for: month, calendar: calendar)) { cell in
                if let date = cell.date {
                    Button {
                        selectedDate = date
                        onDateSelected(date)
                    } label: {
                        ZStack {
                            if let progress = progress(
                                for: date,
                                habits: habits,
                                completedIdentifiers: completedIdentifiers
                            ) {
                                CalendarProgressRing(progress: progress)
                            }

                            Text(date, format: .dateTime.day())
                                .font(.subheadline)
                                .foregroundStyle(dateForegroundColor(date))
                                .frame(width: 34, height: 34)
                                .background {
                                    if isSelected(date) {
                                        Circle().fill(.tint)
                                    }
                                }
                        }
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .bottom) {
                            if calendar.isDateInToday(date) {
                                Circle()
                                    .fill(isSelected(date) ? Color.white : Color.accentColor)
                                    .frame(width: 4, height: 4)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isFuture(date))
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
                    .accessibilityValue(
                        accessibilityProgressValue(
                            for: date,
                            habits: habits,
                            completedIdentifiers: completedIdentifiers
                        )
                    )
                    .accessibilityAddTraits(isSelected(date) ? .isSelected : [])
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func dateForegroundColor(_ date: Date) -> Color {
        if isSelected(date) {
            return .white
        }
        if isFuture(date) {
            return Color.secondary.opacity(0.45)
        }
        return .primary
    }

    private func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: .now)
    }

    private func progress(
        for date: Date,
        habits: [Habit],
        completedIdentifiers: Set<String>
    ) -> Double? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: .now) else {
            return nil
        }

        return HabitProgressCalculator.progress(
            for: date,
            habits: habits,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private func accessibilityProgressValue(
        for date: Date,
        habits: [Habit],
        completedIdentifiers: Set<String>
    ) -> Text {
        guard let progress = progress(
            for: date,
            habits: habits,
            completedIdentifiers: completedIdentifiers
        ) else {
            return Text(verbatim: "")
        }

        return Text(
            progress,
            format: .percent.precision(.fractionLength(0))
        )
    }

    private func moveMonth(by value: Int) {
        displayedMonth = MonthGrid.addingMonths(
            value,
            to: displayedMonth,
            calendar: calendar
        )
    }

    private func commitVisiblePage() {
        guard let visiblePage, visiblePage != 0 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            moveMonth(by: visiblePage)
            self.visiblePage = 0
        }
    }
}
