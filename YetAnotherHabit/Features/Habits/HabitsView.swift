import SwiftData
import SwiftUI

private enum HabitRoute: Hashable {
    case analytics(UUID)
    case edit(UUID)
}

private enum HabitsPullAction {
    case returnToToday
    case setSectionExpanded(HabitSectionExpansionPolicy.Section, Bool)
}

struct HabitsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(AppDataState.self) private var appDataState
    @Query(sort: \Habit.createdAt, animation: .default) private var habits: [Habit]
    @Query(filter: #Predicate<HabitCompletion> { $0.isCompleted })
    private var completions: [HabitCompletion]
    @AppStorage(AppPreferenceKey.completedHabitsSectionExpanded)
    private var prefersCompletedSectionExpanded = true
    @AppStorage(AppPreferenceKey.countersSectionExpanded)
    private var prefersCountersSectionExpanded = true

    @State private var selectedDate = Date.now
    @State private var displayedWeekStart = WeekCalendar.startOfWeek(containing: .now)
    @State private var isCreatingHabit = false
    @State private var persistenceError: String?
    @State private var returnTransitionEdge: Edge = .trailing
    @State private var calendarTransitionID = 0
    @State private var dayTransitionID = 0
    @State private var navigationPath: [HabitRoute] = []
    @State private var isDayContentAtTop = true
    @State private var returnPullDistance: CGFloat = 0
    @State private var isReturnPullReady = false
    @State private var returnFeedbackTrigger = 0
    @State private var hasInitializedCalendar = false

    private let returnPullThreshold: CGFloat = 68

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                ZStack {
                    WeekCalendarPagerView(
                        displayedWeekStart: $displayedWeekStart,
                        selectedDate: $selectedDate,
                        progressByDayKey: progressByDayKey
                    )
                    .id(calendarTransitionID)
                    .transition(.push(from: returnTransitionEdge))
                }
                .frame(height: 72)
                .padding(.top, 12)
                .clipped()

                pullActionIndicator

                dayContent
                    .id(dayTransitionID)
                    .transition(.push(from: returnTransitionEdge))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .simultaneousGesture(pullActionGesture)
            .sensoryFeedback(.selection, trigger: returnFeedbackTrigger)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: returnToToday) {
                        Text(
                            DateTitleFormatter.title(
                                for: selectedDate,
                                calendar: calendar,
                                locale: locale
                            )
                        )
                        .font(.headline)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Вернуться к сегодняшней дате")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить привычку")
                }
            }
            .navigationDestination(isPresented: $isCreatingHabit) {
                NewHabitView(selectedDate: selectedDate) { habit in
                    appDataState.recordAdded(habit)
                }
            }
            .navigationDestination(for: HabitRoute.self, destination: habitDestination)
            .onChange(of: habits.map(\.identifier)) {
                reconcileAppDataState()
            }
            .onChange(of: completions.map(\.identifier)) {
                reconcileAppDataState()
            }
            .onChange(of: completions.map(\.count)) {
                reconcileAppDataState()
            }
            .onAppear(perform: initializeCalendar)
            .saveErrorAlert($persistenceError)
        }
    }

    @ViewBuilder
    private var dayContent: some View {
        if scheduledHabits.isEmpty {
            ZStack {
                Color.clear

                ContentUnavailableView {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(emptyStateForegroundColor)
                        .accessibilityHidden(true)
                } description: {
                    Text(emptyStateMessage)
                        .font(.body)
                        .foregroundStyle(emptyStateForegroundColor)
                        .multilineTextAlignment(.center)
                } actions: {
                    Button("Добавить", systemImage: "plus") {
                        isCreatingHabit = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .tint(.accentColor)
                }
            }
            .onAppear {
                isDayContentAtTop = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        } else {
            HabitDayListView(
                habits: scheduledHabits,
                selectedDate: selectedDate,
                completionCounts: completionCounts,
                completedIdentifiers: completedIdentifiers,
                onCountChanged: recordCountChange,
                onOpenHabit: { navigationPath.append(.analytics($0)) },
                onEditHabit: { navigationPath.append(.edit($0)) },
                onScrollTopChanged: { isDayContentAtTop = $0 },
                prefersCompletedSectionExpanded: $prefersCompletedSectionExpanded,
                prefersCountersSectionExpanded: $prefersCountersSectionExpanded,
                persistenceError: $persistenceError
            )
            .padding(.top, 16)
            .id(WeekCalendar.dayKey(for: selectedDate, calendar: calendar))
        }
    }

    private var emptyStateMessage: LocalizedStringKey {
        displayedHabits.isEmpty
            ? "Создайте первую привычку, чтобы начать."
            : "На этот день привычек нет."
    }

    private var emptyStateForegroundColor: Color {
        Color.accentColor.opacity(0.52)
    }

    @ViewBuilder
    private func habitDestination(_ route: HabitRoute) -> some View {
        switch route {
        case .analytics(let identifier):
            if let habit = habit(with: identifier) {
                HabitAnalyticsView(habit: habit) {
                    navigationPath.append(.edit(identifier))
                }
            } else {
                missingHabitView
            }
        case .edit(let identifier):
            if let habit = habit(with: identifier) {
                EditHabitView(habit: habit, onDeleted: handleHabitDeleted)
            } else {
                missingHabitView
            }
        }
    }

    private var missingHabitView: some View {
        ContentUnavailableView(
            "Привычка не найдена",
            systemImage: "exclamationmark.triangle"
        )
    }

    private func habit(with identifier: UUID) -> Habit? {
        displayedHabits.first { $0.identifier == identifier }
    }

    private func handleHabitDeleted(_ identifier: UUID) {
        appDataState.recordDeleted(identifier: identifier)
        navigationPath.removeAll()
    }

    private var scheduledHabits: [Habit] {
        HabitDaySorter.sorted(
            displayedHabits.filter {
                $0.isScheduled(on: selectedDate, calendar: calendar)
            },
            for: selectedDate,
            completionCounts: completionCounts,
            calendar: calendar
        )
    }

    private var displayedHabits: [Habit] {
        appDataState.visibleHabits(from: habits)
    }

    private var progressByDayKey: [String: Double] {
        let today = calendar.startOfDay(for: .now)
        let visibleDates = (-1...1)
            .compactMap {
                WeekCalendar.addWeeks(
                    $0,
                    to: displayedWeekStart,
                    calendar: calendar
                )
            }
            .flatMap { WeekCalendar.dates(starting: $0, calendar: calendar) }

        return visibleDates.reduce(into: [:]) { result, date in
                guard calendar.startOfDay(for: date) <= today else { return }

                let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
                result[dayKey] = HabitProgressCalculator.progress(
                    for: date,
                    habits: displayedHabits,
                    completedIdentifiers: completedIdentifiers,
                    calendar: calendar
                )
            }
    }

    private var completedIdentifiers: Set<String> {
        HabitCompletionIndex.identifiers(
            in: completionCounts,
            habits: displayedHabits
        )
    }

    private var completionCounts: [String: Int] {
        appDataState.visibleCompletionCounts(
            from: HabitCompletionIndex.counts(in: completions)
        )
    }

    private func recordCountChange(identifier: String, count: Int) {
        appDataState.recordCount(identifier: identifier, count: count)
    }

    private func reconcileAppDataState() {
        appDataState.reconcile(
            habits: habits,
            completionCounts: HabitCompletionIndex.counts(in: completions)
        )
    }

    private func returnToToday() {
        let today = Date.now
        let todayWeekStart = WeekCalendar.startOfWeek(containing: today, calendar: calendar)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let todayDay = calendar.startOfDay(for: today)
        let isAlreadyShowingToday = selectedDay == todayDay
            && calendar.isDate(displayedWeekStart, inSameDayAs: todayWeekStart)

        guard !isAlreadyShowingToday else { return }

        let isReturningFromFuture = selectedDay > todayDay
            || (selectedDay == todayDay && displayedWeekStart > todayWeekStart)
        let isChangingWeek = !calendar.isDate(
            displayedWeekStart,
            inSameDayAs: todayWeekStart
        )
        returnTransitionEdge = isReturningFromFuture ? .leading : .trailing

        withAnimation(.snappy(duration: 0.35)) {
            selectedDate = today
            displayedWeekStart = todayWeekStart
            dayTransitionID += 1
            if isChangingWeek {
                calendarTransitionID += 1
            }
        }
    }

    @ViewBuilder
    private var pullActionIndicator: some View {
        Group {
            if let pullAction {
                Label(
                    pullActionTitle(for: pullAction),
                    systemImage: pullActionSystemImage(for: pullAction)
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())
                .opacity(returnPullProgress)
                .scaleEffect(0.86 + 0.14 * returnPullProgress)
                .offset(y: 8 * CGFloat(returnPullProgress))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: pullIndicatorHeight)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var canReturnToToday: Bool {
        let today = calendar.startOfDay(for: .now)
        return calendar.startOfDay(for: selectedDate) != today
            || !calendar.isDate(
                displayedWeekStart,
                inSameDayAs: WeekCalendar.startOfWeek(containing: today, calendar: calendar)
            )
    }

    private var returnToTodaySystemImage: String {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let today = calendar.startOfDay(for: .now)
        if selectedDay != today {
            return selectedDay > today ? "arrow.left" : "arrow.right"
        }

        let todayWeekStart = WeekCalendar.startOfWeek(
            containing: today,
            calendar: calendar
        )
        return displayedWeekStart > todayWeekStart ? "arrow.left" : "arrow.right"
    }

    private var returnPullProgress: Double {
        min(max(Double(returnPullDistance / returnPullThreshold), 0), 1)
    }

    private var pullIndicatorHeight: CGFloat {
        guard pullAction != nil else { return 0 }
        return 52 * CGFloat(returnPullProgress)
    }

    private var pullActionGesture: some Gesture {
        // Pull-to-refresh would communicate a data refresh and display a spinner.
        // SwiftUI has no native pull gesture for navigation, so this scoped drag
        // preserves the requested return-to-today interaction without false UI.
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let translation = value.translation
                guard
                    pullAction != nil,
                    isDayContentAtTop,
                    translation.height > 0,
                    abs(translation.height) > abs(translation.width)
                else {
                    resetReturnPull()
                    return
                }

                returnPullDistance = translation.height
                let isReady = translation.height >= returnPullThreshold
                if isReady, !isReturnPullReady {
                    returnFeedbackTrigger += 1
                }
                isReturnPullReady = isReady
            }
            .onEnded { value in
                let translation = value.translation
                let action = pullAction
                let shouldPerform = action != nil
                    && isDayContentAtTop
                    && translation.height >= returnPullThreshold
                    && abs(translation.height) > abs(translation.width)

                resetReturnPull()
                if shouldPerform, let action {
                    performPullAction(action)
                }
            }
    }

    private var pullAction: HabitsPullAction? {
        if canReturnToToday {
            return .returnToToday
        }

        guard let action = HabitSectionExpansionPolicy.actionAfterPull(
            hasCompletedSection: hasCompletedSection,
            isCompletedSectionExpanded: prefersCompletedSectionExpanded,
            hasCountersSection: hasCountersSection,
            isCountersSectionExpanded: prefersCountersSectionExpanded
        ) else {
            return nil
        }
        return .setSectionExpanded(action.section, action.isExpanded)
    }

    private var hasCountersSection: Bool {
        scheduledHabits.contains {
            $0.kind == .counter && $0.effectiveTargetCount == nil
        }
    }

    private var hasCompletedSection: Bool {
        scheduledHabits.contains {
            HabitDaySorter.belongsToCompletedSection($0, count: count(for: $0))
        }
    }

    private func count(for habit: Habit) -> Int {
        let dayKey = WeekCalendar.dayKey(for: selectedDate, calendar: calendar)
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: dayKey
        )
        return completionCounts[identifier, default: 0]
    }

    private func pullActionTitle(for action: HabitsPullAction) -> LocalizedStringKey {
        switch action {
        case .returnToToday:
            return "Сегодня"
        case .setSectionExpanded(_, true):
            return "Развернуть"
        case .setSectionExpanded(_, false):
            return "Свернуть"
        }
    }

    private func pullActionSystemImage(for action: HabitsPullAction) -> String {
        switch action {
        case .returnToToday:
            return returnToTodaySystemImage
        case .setSectionExpanded(_, true):
            return "chevron.down"
        case .setSectionExpanded(_, false):
            return "chevron.up"
        }
    }

    private func performPullAction(_ action: HabitsPullAction) {
        switch action {
        case .returnToToday:
            returnToToday()
        case .setSectionExpanded(let section, let isExpanded):
            withAnimation(.smooth(duration: 0.32)) {
                switch section {
                case .completed:
                    prefersCompletedSectionExpanded = isExpanded
                case .counters:
                    prefersCountersSectionExpanded = isExpanded
                }
            }
        }
    }

    private func resetReturnPull() {
        withAnimation(.easeOut(duration: 0.15)) {
            returnPullDistance = 0
            isReturnPullReady = false
        }
    }

    private func initializeCalendar() {
        guard !hasInitializedCalendar else { return }

        let today = Date.now
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selectedDate = today
            displayedWeekStart = WeekCalendar.startOfWeek(
                containing: today,
                calendar: calendar
            )
            hasInitializedCalendar = true
        }
    }

}
