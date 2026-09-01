import SwiftUI

struct MonthlyProgressChartView: View {
    private enum Period: CaseIterable, Identifiable {
        case day
        case week
        case month

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .day: "День"
            case .week: "Неделя"
            case .month: "Месяц"
            }
        }
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let data: HabitPresentationData
    @State private var period: Period = .month

    var body: some View {
        let progress = snapshot.progress
        let percentValue = Int((progress * 100).rounded())

        VStack(spacing: 14) {
            Picker("Период", selection: $period) {
                ForEach(Period.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(percentValue)\u{00A0}%")
                    .font(.title.bold())
                    .contentTransition(.numericText())
            }
            .frame(width: 150, height: 150)
            .animation(
                accessibilityReduceMotion ? nil : .easeInOut(duration: 0.25),
                value: progress
            )

            Text(periodTitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).locale(locale))
    }

    private var periodTitle: String {
        switch period {
        case .month:
            let format = AppLocalization.string("Выполнено за %@", locale: locale)
            return String(format: format, locale: locale, monthTitle)
        case .week:
            return AppLocalization.string("Выполнено за неделю", locale: locale)
        case .day:
            return AppLocalization.string("Выполнено за день", locale: locale)
        }
    }

    private var monthDatesThroughToday: [Date] {
        let today = calendar.startOfDay(for: .now)
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return []
        }

        var dates: [Date] = []
        var date = monthInterval.start
        while date <= today {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = nextDate
        }
        return dates
    }

    private var weekDatesThroughToday: [Date] {
        let today = calendar.startOfDay(for: .now)
        return WeekCalendar.dates(
            starting: WeekCalendar.startOfWeek(containing: today, calendar: calendar),
            calendar: calendar
        )
        .filter { calendar.startOfDay(for: $0) <= today }
    }

    private var snapshotDates: [Date] {
        switch period {
        case .month: monthDatesThroughToday
        case .week: weekDatesThroughToday
        case .day: [calendar.startOfDay(for: .now)]
        }
    }

    private var snapshot: HabitProgressCalculator.Snapshot {
        return HabitProgressCalculator.snapshot(
            for: snapshotDates,
            habits: data.habits,
            completedIdentifiers: data.completedIdentifiers,
            calendar: calendar
        )
    }
}
