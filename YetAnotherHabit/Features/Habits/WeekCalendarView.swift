import SwiftUI

struct WeekCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    let weekStart: Date
    @Binding var selectedDate: Date

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

                        Text(date, format: .dateTime.day())
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(isSelected(date) ? .white : .primary)
                            .background {
                                if isSelected(date) {
                                    Circle().fill(.tint)
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
                .accessibilityAddTraits(isSelected(date) ? .isSelected : [])
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}
