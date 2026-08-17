import SwiftUI

struct ProgressScreen: View {
    @State private var selectedDate: Date?
    @State private var presentedDate = Date.now
    @State private var calendarResetID = 0
    @State private var isPresentingDayProgress = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Прогресс", action: returnToCurrentMonth)

                MonthCalendarView(
                    selectedDate: $selectedDate,
                    resetID: calendarResetID,
                    onDateSelected: presentDayProgress
                )
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.horizontal)

                MonthlyProgressChartView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                returnToCurrentMonth()
            }
            .sheet(isPresented: $isPresentingDayProgress, onDismiss: clearSelection) {
                DayProgressView(date: presentedDate, onWillDismiss: clearSelection)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(uiColor: .systemBackground))
            }
        }
    }

    private func returnToCurrentMonth() {
        selectedDate = nil
        calendarResetID += 1
    }

    private func presentDayProgress(_ date: Date) {
        selectedDate = date
        presentedDate = date
        isPresentingDayProgress = true
    }

    private func clearSelection() {
        selectedDate = nil
    }
}
