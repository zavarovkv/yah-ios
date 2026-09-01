import SwiftUI

struct ProgressScreen: View {
    private struct PresentedDay: Identifiable {
        let date: Date

        var id: Date { date }
    }

    @Environment(\.calendar) private var calendar
    @State private var selectedDate: Date?
    @State private var presentedDay: PresentedDay?
    @State private var calendarResetID = 0
    let data: HabitPresentationData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MonthlyProgressChartView(data: data)

                    Divider()
                        .padding(.horizontal)

                    MonthCalendarView(
                        data: data,
                        selectedDate: $selectedDate,
                        resetID: calendarResetID,
                        initialCalendar: calendar,
                        onDateSelected: presentDayProgress
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button("Прогресс", action: returnToCurrentMonth)
                        .font(.headline)
                        .buttonStyle(.plain)
                        .accessibilityHint("Вернуться к текущему месяцу")
                }
            }
            .sheet(item: $presentedDay, onDismiss: clearSelection) { selection in
                DayProgressView(data: data, date: selection.date)
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
        presentedDay = PresentedDay(date: date)
    }

    private func clearSelection() {
        selectedDate = nil
    }
}
