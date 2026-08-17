import SwiftUI

struct WeekCalendarPagerView: View {
    @Environment(\.calendar) private var calendar
    @GestureState private var dragOffset: CGFloat = 0

    @Binding var displayedWeekStart: Date
    @Binding var selectedDate: Date
    let progressByDayKey: [String: Double]

    var body: some View {
        WeekCalendarView(
            weekStart: displayedWeekStart,
            selectedDate: $selectedDate,
            progressByDayKey: progressByDayKey
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .offset(x: dragOffset)
        .contentShape(Rectangle())
        .gesture(weekSwipeGesture)
        .animation(.interactiveSpring, value: dragOffset)
        .frame(height: 72, alignment: .top)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                moveWeek(by: 1)
            case .decrement:
                moveWeek(by: -1)
            @unknown default:
                break
            }
        }
    }

    private var weekSwipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50

                if value.translation.width < -threshold {
                    moveWeek(by: 1)
                } else if value.translation.width > threshold {
                    moveWeek(by: -1)
                }
            }
    }

    private func moveWeek(by value: Int) {
        guard let newWeekStart = WeekCalendar.addWeeks(
            value,
            to: displayedWeekStart,
            calendar: calendar
        ) else {
            return
        }

        displayedWeekStart = newWeekStart
        selectedDate = WeekCalendar.selectedDate(
            whenMovingTo: newWeekStart,
            direction: value,
            calendar: calendar
        )
    }
}
