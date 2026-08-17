import SwiftData
import SwiftUI

struct MonthlyProgressChartView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

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

            Text("Выполнено за \(monthTitle)")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
    }

    private var progress: Double {
        monthlySnapshot.progress
    }

    private var percentValue: Int {
        Int((progress * 100).rounded())
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).locale(locale))
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

    private var monthlySnapshot: HabitProgressCalculator.Snapshot {
        HabitProgressCalculator.snapshot(
            for: monthDatesThroughToday,
            habits: appDataState.visibleHabits(from: habits),
            completedIdentifiers: appDataState.visibleCompletionIdentifiers(
                from: Set(completions.map(\.identifier))
            ),
            calendar: calendar
        )
    }
}
