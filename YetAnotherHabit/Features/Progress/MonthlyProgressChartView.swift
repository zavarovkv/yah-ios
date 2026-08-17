import SwiftData
import SwiftUI

struct MonthlyProgressChartView: View {
    private enum Period: CaseIterable {
        case month
        case week
        case day

        var next: Period {
            switch self {
            case .month: .week
            case .week: .day
            case .day: .month
            }
        }
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @State private var period: Period = .month

    var body: some View {
        VStack(spacing: 14) {
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
            .animation(.easeInOut(duration: 0.25), value: progress)

            Text(periodTitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                period = period.next
            }
        }
        .accessibilityHint("Нажмите, чтобы переключить период")
        .accessibilityElement(children: .combine)
    }

    private var progress: Double {
        snapshot.progress
    }

    private var percentValue: Int {
        Int((progress * 100).rounded())
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).locale(locale))
    }

    private var periodTitle: String {
        switch period {
        case .month:
            let format = String(localized: "Выполнено за %@", locale: locale)
            return String(format: format, monthTitle)
        case .week:
            return String(localized: "Выполнено за неделю", locale: locale)
        case .day:
            return String(localized: "Выполнено за день", locale: locale)
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
        HabitProgressCalculator.snapshot(
            for: snapshotDates,
            habits: appDataState.visibleHabits(from: habits),
            completedIdentifiers: appDataState.visibleCompletionIdentifiers(
                from: Set(completions.map(\.identifier))
            ),
            calendar: calendar
        )
    }
}
