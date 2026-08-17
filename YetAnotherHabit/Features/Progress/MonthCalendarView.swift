import SwiftData
import SwiftUI

struct MonthCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @Binding var selectedDate: Date?
    let resetID: Int
    let onDateSelected: (Date) -> Void
    @State private var displayedMonth: Date
    @GestureState private var dragOffset: CGFloat = 0
    @State private var transitionOffset: CGFloat = 0

    init(
        selectedDate: Binding<Date?>,
        resetID: Int,
        onDateSelected: @escaping (Date) -> Void
    ) {
        _selectedDate = selectedDate
        self.resetID = resetID
        self.onDateSelected = onDateSelected
        _displayedMonth = State(
            initialValue: Self.monthStart(for: selectedDate.wrappedValue ?? .now)
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year().locale(locale)))
                    .font(.headline)

                Spacer()

                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }

            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    monthPage(offset: -1)
                        .frame(width: geometry.size.width, alignment: .top)

                    monthPage(offset: 0)
                        .frame(width: geometry.size.width, alignment: .top)

                    monthPage(offset: 1)
                        .frame(width: geometry.size.width, alignment: .top)
                }
                .offset(x: -geometry.size.width + transitionOffset + dragOffset)
                .contentShape(Rectangle())
                .gesture(monthSwipeGesture(pageWidth: geometry.size.width))
            }
            .frame(height: 300)
            .clipped()
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onAppear {
            displayedMonth = Self.monthStart(for: .now, calendar: calendar)
        }
        .onChange(of: resetID) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = Self.monthStart(for: .now, calendar: calendar)
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 7)
    }

    private func monthPage(offset: Int) -> some View {
        let month = monthByAdding(offset, to: displayedMonth)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<7, id: \.self) { weekday in
                Text(WeekCalendar.weekdayTitle(forMondayBasedIndex: weekday, locale: locale))
                    .font(.caption)
                    .foregroundStyle(weekday >= 5 ? Color.red.opacity(0.7) : .secondary)
            }

            ForEach(Array(monthCells(for: month).enumerated()), id: \.offset) { _, date in
                if let date {
                    Button {
                        selectedDate = date
                        onDateSelected(date)
                    } label: {
                        ZStack {
                            if let progress = progress(for: date) {
                                progressRing(progress)
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
                        .frame(width: 42, height: 42)
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
                } else {
                    Color.clear.frame(width: 34, height: 34)
                }
            }
        }
    }

    private func monthSwipeGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let projectedWidth = value.predictedEndTranslation.width
                let direction: Int

                if projectedWidth < -50 {
                    direction = 1
                } else if projectedWidth > 50 {
                    direction = -1
                } else {
                    transitionOffset = value.translation.width
                    withAnimation(.snappy) {
                        transitionOffset = 0
                    }
                    return
                }

                transitionOffset = value.translation.width
                withAnimation(.easeOut(duration: 0.25), completionCriteria: .logicallyComplete) {
                    transitionOffset = direction > 0 ? -pageWidth : pageWidth
                } completion: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        moveMonth(by: direction)
                        transitionOffset = 0
                    }
                }
            }
    }

    private func monthCells(for month: Date) -> [Date?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: month),
            let firstDate = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }

        let leadingEmptyDays = WeekCalendar.mondayBasedWeekday(for: firstDate, calendar: calendar)
        let dates = range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDate)
        }
        return Array(repeating: nil, count: leadingEmptyDays) + dates.map(Optional.some)
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

    private func progress(for date: Date) -> Double? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: .now) else {
            return nil
        }

        return HabitProgressCalculator.progress(
            for: date,
            habits: appDataState.visibleHabits(from: habits),
            completedIdentifiers: appDataState.visibleCompletionIdentifiers(
                from: Set(completions.map(\.identifier))
            ),
            calendar: calendar
        )
    }

    private func progressRing(_ progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 3)

            if progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: 42, height: 42)
        .animation(.easeInOut(duration: 0.2), value: progress)
        .allowsHitTesting(false)
    }

    private func moveMonth(by value: Int) {
        displayedMonth = monthByAdding(value, to: displayedMonth)
    }

    private func monthByAdding(_ value: Int, to month: Date) -> Date {
        guard let date = calendar.date(byAdding: .month, value: value, to: month) else {
            return month
        }
        return Self.monthStart(for: date, calendar: calendar)
    }

    private static func monthStart(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
