import SwiftUI

struct HabitFormView: View {
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Binding var draft: HabitDraft

    let actionTitle: LocalizedStringKey
    let action: () -> Void
    var showsActionButton = true
    var deleteAction: (() -> Void)?

    @State private var isPresentingAppearance = false
    @State private var targetSliderFeedback = 0

    var body: some View {
        Form {
            nameSection
            scheduleSection
            propertiesSection
            reminderSection

            if showsActionButton {
                actionSection
            }

            if let deleteAction {
                Section {
                    Button("Удалить привычку", role: .destructive) {
                        deleteAction()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $isPresentingAppearance) {
            HabitAppearancePicker(
                icon: $draft.icon,
                color: $draft.color
            )
        }
    }

    private var nameSection: some View {
        Section("Название") {
            HStack(spacing: 12) {
                Button {
                    isPresentingAppearance = true
                } label: {
                    Image(systemName: draft.icon)
                        .font(.headline)
                        .foregroundStyle(draft.color.foregroundColor)
                        .frame(width: 40, height: 40)
                        .background(draft.color.color, in: Circle())
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Выбрать иконку и цвет")

                TextField("Например, читать 20 минут", text: $draft.name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
            }
        }
    }

    private var scheduleSection: some View {
        Section("Дни недели") {
            HStack {
                ForEach(0..<7, id: \.self) { weekday in
                    Button {
                        toggleWeekday(weekday)
                    } label: {
                        Text(
                            WeekCalendar.weekdayTitle(
                                forMondayBasedIndex: weekday,
                                locale: locale
                            )
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            draft.scheduledWeekdays.contains(weekday) ? .white : .primary
                        )
                        .frame(width: 36, height: 36)
                        .background {
                            Circle().fill(
                                draft.scheduledWeekdays.contains(weekday)
                                    ? draft.color.color
                                    : Color.secondary.opacity(0.12)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityAddTraits(
                        draft.scheduledWeekdays.contains(weekday) ? .isSelected : []
                    )
                    .accessibilityLabel(
                        WeekCalendar.weekdayAccessibilityTitle(
                            forMondayBasedIndex: weekday,
                            locale: locale
                        )
                    )
                }
            }
        }
    }

    private var propertiesSection: some View {
        Section {
            Picker("Тип", selection: $draft.kind) {
                Label("Привычка", systemImage: "checkmark.circle")
                    .tag(HabitKind.habit)
                Label("Счётчик", systemImage: "plusminus.circle")
                    .tag(HabitKind.counter)
            }
            .pickerStyle(.navigationLink)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }

            if draft.kind == .counter {
                Picker("Интервал", selection: $draft.counterInterval) {
                    Text("Ежедневно").tag(CounterInterval.daily)
                    Text("Еженедельно").tag(CounterInterval.weekly)
                    Text("Каждые две недели").tag(CounterInterval.biweekly)
                    Text("Ежемесячно").tag(CounterInterval.monthly)
                    if draft.counterInterval == .yearly {
                        Text("Ежегодно").tag(CounterInterval.yearly)
                    }
                }
                .pickerStyle(.navigationLink)

                Toggle("Установить цель", isOn: targetEnabled)

                if draft.targetCount != nil {
                    targetEditor
                        .transition(targetEditorTransition)
                }
            }
        } header: {
            Text("Свойства")
        } footer: {
            if draft.kind == .counter, draft.targetCount != nil {
                Text("Цель отмечает интервал выполненным, но не ограничивает значение счётчика.")
            }
        }
    }

    private var targetEditor: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Значение")

                Spacer()

                TextField(
                    "Значение",
                    value: targetCount,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(minWidth: 64, maxWidth: 120)
                .accessibilityLabel("Значение")
            }

            Slider(
                value: targetSliderPosition,
                in: HabitTargetScale.positions,
                step: 1
            ) {
                Text("Цель")
            } minimumValueLabel: {
                Text(HabitTargetScale.minimumValue, format: .number)
            } maximumValueLabel: {
                Text(
                    HabitTargetScale.maximumValue,
                    format: .number.notation(.compactName)
                )
            }
            .font(.caption)
            .accessibilityValue(
                Text(draft.targetCount ?? HabitTargetScale.defaultValue, format: .number)
            )
            .sensoryFeedback(.selection, trigger: targetSliderFeedback)
        }
    }

    private var targetEditorTransition: AnyTransition {
        accessibilityReduceMotion
            ? .identity
            : .opacity.combined(with: .move(edge: .top))
    }

    private var reminderSection: some View {
        Section {
            Toggle("Напоминать", isOn: reminderEnabled)

            if draft.hasReminder {
                DatePicker(
                    "Время",
                    selection: reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .transition(targetEditorTransition)
            }
        } header: {
            Text("Напоминание")
        } footer: {
            if draft.hasReminder {
                Text("Уведомление придёт в выбранные дни недели.")
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: action) {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(draft.color.color)
            .disabled(!draft.isValid)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func toggleWeekday(_ weekday: Int) {
        if draft.scheduledWeekdays.contains(weekday) {
            draft.scheduledWeekdays.remove(weekday)
        } else {
            draft.scheduledWeekdays.insert(weekday)
        }
    }

    private var targetEnabled: Binding<Bool> {
        Binding(
            get: { draft.targetCount != nil },
            set: { isEnabled in
                withAnimation(
                    accessibilityReduceMotion ? nil : .snappy(duration: 0.25)
                ) {
                    draft.targetCount = isEnabled
                        ? (draft.targetCount ?? HabitTargetScale.defaultValue)
                        : nil
                }
            }
        )
    }

    private var reminderEnabled: Binding<Bool> {
        Binding(
            get: { draft.hasReminder },
            set: { isEnabled in
                withAnimation(
                    accessibilityReduceMotion ? nil : .snappy(duration: 0.25)
                ) {
                    if isEnabled {
                        draft.setReminder(hour: 9, minute: 0)
                    } else {
                        draft.setReminder(hour: nil, minute: nil)
                    }
                }
            }
        )
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                calendar.date(
                    bySettingHour: draft.reminderHour ?? 9,
                    minute: draft.reminderMinute ?? 0,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { date in
                let components = calendar.dateComponents([.hour, .minute], from: date)
                draft.setReminder(hour: components.hour, minute: components.minute)
            }
        )
    }

    private var targetCount: Binding<Int> {
        Binding(
            get: { draft.targetCount ?? HabitTargetScale.defaultValue },
            set: {
                draft.targetCount = min(
                    max($0, HabitTargetScale.minimumValue),
                    HabitTargetScale.maximumValue
                )
            }
        )
    }

    private var targetSliderPosition: Binding<Double> {
        Binding(
            get: {
                HabitTargetScale.position(
                    for: draft.targetCount ?? HabitTargetScale.defaultValue
                )
            },
            set: { position in
                let value = HabitTargetScale.value(at: position)
                guard value != draft.targetCount else { return }

                draft.targetCount = value
                targetSliderFeedback += 1
            }
        )
    }
}
