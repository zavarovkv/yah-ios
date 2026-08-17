import SwiftUI

struct WeekCalendarPagerView: View {
    @Environment(\.calendar) private var calendar
    @GestureState private var dragOffset: CGFloat = 0
    @State private var transitionOffset: CGFloat = 0

    @Binding var displayedWeekStart: Date
    @Binding var selectedDate: Date
    let progressByDayKey: [String: Double]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                weekPage(offset: -1)
                    .frame(width: geometry.size.width)

                weekPage(offset: 0)
                    .frame(width: geometry.size.width)

                weekPage(offset: 1)
                    .frame(width: geometry.size.width)
            }
            .offset(
                x: -geometry.size.width + transitionOffset + dragOffset
            )
            .contentShape(Rectangle())
            .gesture(weekSwipeGesture(pageWidth: geometry.size.width))
        }
        .clipped()
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

    @ViewBuilder
    private func weekPage(offset: Int) -> some View {
        if let weekStart = WeekCalendar.addWeeks(
            offset,
            to: displayedWeekStart,
            calendar: calendar
        ) {
            WeekCalendarView(
                weekStart: weekStart,
                selectedDate: $selectedDate,
                progressByDayKey: progressByDayKey
            )
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func weekSwipeGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                let projectedWidth = value.predictedEndTranslation.width
                let direction: Int

                if projectedWidth < -threshold {
                    direction = 1
                } else if projectedWidth > threshold {
                    direction = -1
                } else {
                    transitionOffset = value.translation.width
                    withAnimation(.snappy) {
                        transitionOffset = 0
                    }
                    return
                }

                transitionOffset = value.translation.width
                withAnimation(
                    .easeOut(duration: 0.25),
                    completionCriteria: .logicallyComplete
                ) {
                    transitionOffset = direction > 0 ? -pageWidth : pageWidth
                } completion: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        moveWeek(by: direction)
                        transitionOffset = 0
                    }
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
