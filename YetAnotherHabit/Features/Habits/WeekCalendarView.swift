import SwiftUI

struct WeekCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    let weekStart: Date
    @Binding var selectedDate: Date
    let progressByDayKey: [String: Double]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(WeekCalendar.dates(starting: weekStart, calendar: calendar), id: \.self) { date in
                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 8) {
                        Text(
                            WeekCalendar.weekdayTitle(
                                for: date,
                                calendar: calendar,
                                locale: locale
                            )
                        )
                            .font(.caption)
                            .foregroundStyle(
                                WeekCalendar.isWeekend(date, calendar: calendar)
                                    ? Color.red.opacity(0.7)
                                    : Color.secondary
                            )

                        ZStack {
                            if let progress = progress(for: date) {
                                CalendarProgressRing(progress: progress)
                            }

                            Text(date, format: .dateTime.day())
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 34, height: 34)
                                .foregroundStyle(isSelected(date) ? .white : .primary)
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
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    date.formatted(
                        .dateTime
                            .weekday(.wide)
                            .day()
                            .month(.wide)
                        .locale(locale)
                    )
                )
                .accessibilityValue(accessibilityProgressValue(for: date))
                .accessibilityAddTraits(isSelected(date) ? .isSelected : [])
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func progress(for date: Date) -> Double? {
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        return progressByDayKey[dayKey]
    }

    private func accessibilityProgressValue(for date: Date) -> Text {
        guard let progress = progress(for: date) else { return Text(verbatim: "") }
        return Text(
            progress,
            format: .percent.precision(.fractionLength(0))
        )
    }

}
