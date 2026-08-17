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
                                progressRing(progress)
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

    private func progress(for date: Date) -> Double? {
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        return progressByDayKey[dayKey]
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
}
