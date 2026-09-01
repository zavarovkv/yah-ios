import SwiftUI

struct WeekCalendarPagerView: View {
    @Environment(\.calendar) private var calendar
    @State private var visiblePage: Int? = 0
    @State private var isPagingByGesture = false

    @Binding var displayedWeekStart: Date
    @Binding var selectedDate: Date
    let progressByDayKey: [String: Double]
    let onNavigationInteractionChanged: (Bool) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(-1...1, id: \.self) { offset in
                        weekPage(offset: offset)
                            .frame(width: geometry.size.width)
                            .id(offset)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visiblePage, anchor: .center)
            .defaultScrollAnchor(.center)
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .tracking || newPhase == .interacting {
                    if !isPagingByGesture {
                        onNavigationInteractionChanged(true)
                    }
                    isPagingByGesture = true
                } else if newPhase == .idle, isPagingByGesture {
                    isPagingByGesture = false
                    commitVisiblePage()
                    onNavigationInteractionChanged(false)
                } else if newPhase == .idle {
                    recenterPage()
                }
            }
            .onChange(of: visiblePage) { _, newValue in
                guard !isPagingByGesture, newValue != 0 else { return }
                recenterPage()
            }
            .onAppear(perform: recenterPage)
        }
        .clipped()
        .frame(height: 72, alignment: .top)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                moveWeekWithNavigationFeedback(by: 1)
            case .decrement:
                moveWeekWithNavigationFeedback(by: -1)
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
                progressByDayKey: progressByDayKey,
                onNavigationInteractionChanged: onNavigationInteractionChanged
            )
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func commitVisiblePage() {
        guard let visiblePage, visiblePage != 0 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            moveWeek(by: visiblePage)
            self.visiblePage = 0
        }
    }

    private func recenterPage() {
        guard visiblePage != 0 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            visiblePage = 0
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

    private func moveWeekWithNavigationFeedback(by value: Int) {
        onNavigationInteractionChanged(true)
        moveWeek(by: value)
        onNavigationInteractionChanged(false)
    }
}
