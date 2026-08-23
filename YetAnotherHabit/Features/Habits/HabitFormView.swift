import SwiftUI

struct HabitFormView: View {
    @Environment(\.locale) private var locale
    @Binding var draft: HabitDraft

    let actionTitle: LocalizedStringKey
    let action: () -> Void
    var showsActionButton = true
    var deleteAction: (() -> Void)?

    @State private var isPresentingAppearance = false

    var body: some View {
        Form {
            nameSection
            scheduleSection
            typeSection

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
                }
            }
        }
    }

    private var typeSection: some View {
        Section {
            Picker("Тип", selection: $draft.kind) {
                Label("Привычка", systemImage: "checkmark.circle")
                    .tag(HabitKind.habit)
                Label("Счётчик", systemImage: "plusminus.circle")
                    .tag(HabitKind.counter)
            }
            .pickerStyle(.navigationLink)

            if draft.kind == .counter {
                TextField(
                    "Цель (необязательно)",
                    value: $draft.targetCount,
                    format: .number
                )
                .keyboardType(.numberPad)
            }
        } header: {
            Text("Тип")
        } footer: {
            if draft.kind == .counter {
                Text("Цель отмечает день выполненным, но не ограничивает значение счётчика.")
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
}
