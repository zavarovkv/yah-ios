import SwiftUI

struct HabitFormView: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: HabitColor
    @Binding var scheduledWeekdays: Set<Int>

    let actionTitle: LocalizedStringKey
    let action: () -> Void

    private let icons = [
        "checkmark", "figure.run", "book.fill", "drop.fill",
        "heart.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "dumbbell.fill", "pills.fill", "brain.head.profile", "cup.and.saucer.fill"
    ]

    var body: some View {
        Form {
            Section("Название") {
                TextField("Например, читать 20 минут", text: $name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
            }

            Section("Дни недели") {
                HStack {
                    ForEach(0..<7, id: \.self) { weekday in
                        Button {
                            toggleWeekday(weekday)
                        } label: {
                            Text(WeekCalendar.weekdayTitle(forMondayBasedIndex: weekday))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(scheduledWeekdays.contains(weekday) ? .white : .primary)
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle().fill(
                                        scheduledWeekdays.contains(weekday)
                                            ? selectedColor.color
                                            : Color.secondary.opacity(0.12)
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityAddTraits(
                            scheduledWeekdays.contains(weekday) ? .isSelected : []
                        )
                    }
                }
            }

            Section("Иконка") {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 5),
                    spacing: 12
                ) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(
                                    selectedIcon == icon ? .white : selectedColor.color
                                )
                                .background {
                                    Circle().fill(
                                        selectedIcon == icon
                                            ? selectedColor.color
                                            : Color.secondary.opacity(0.12)
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel(icon)
                        .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Цвет") {
                HStack {
                    ForEach(HabitColor.allCases) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityLabel(color.title)
                        .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(selectedColor.color)
                .disabled(trimmedName.isEmpty || scheduledWeekdays.isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleWeekday(_ weekday: Int) {
        if scheduledWeekdays.contains(weekday) {
            scheduledWeekdays.remove(weekday)
        } else {
            scheduledWeekdays.insert(weekday)
        }
    }
}
