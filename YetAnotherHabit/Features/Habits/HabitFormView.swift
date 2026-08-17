import SwiftUI

struct HabitFormView: View {
    @Environment(\.locale) private var locale
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: HabitColor
    @Binding var scheduledWeekdays: Set<Int>

    let actionTitle: LocalizedStringKey
    let action: () -> Void
    var showsActionButton = true
    var deleteAction: (() -> Void)?

    private let icons = [
        "checkmark", "figure.run", "book.fill", "drop.fill",
        "heart.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "dumbbell.fill", "pills.fill", "brain.head.profile", "cup.and.saucer.fill",
        "figure.walk", "bicycle", "fork.knife", "waterbottle.fill",
        "bed.double.fill", "alarm.fill", "pencil", "music.note",
        "paintpalette.fill", "camera.fill", "cart.fill", "house.fill"
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
                            Text(
                                WeekCalendar.weekdayTitle(
                                    forMondayBasedIndex: weekday,
                                    locale: locale
                                )
                            )
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
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(iconPages.indices, id: \.self) { pageIndex in
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible()),
                                    count: 6
                                ),
                                spacing: 4
                            ) {
                                ForEach(iconPages[pageIndex], id: \.self) { icon in
                                    iconButton(icon)
                                }
                            }
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
            }

            Section("Цвет") {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(colorPages.indices, id: \.self) { pageIndex in
                            HStack {
                                ForEach(colorPages[pageIndex]) { color in
                                    colorButton(color)
                                }
                            }
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
            }

            if showsActionButton {
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

            if let deleteAction {
                Section {
                    Button("Удалить привычку", role: .destructive) {
                        deleteAction()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var iconPages: [[String]] {
        stride(from: 0, to: icons.count, by: 12).map { startIndex in
            Array(icons[startIndex..<min(startIndex + 12, icons.count)])
        }
    }

    private var colorPages: [[HabitColor]] {
        let colors = HabitColor.allCases
        return stride(from: 0, to: colors.count, by: 6).map { startIndex in
            Array(colors[startIndex..<min(startIndex + 6, colors.count)])
        }
    }

    private func iconButton(_ icon: String) -> some View {
        Button {
            selectedIcon = icon
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .foregroundStyle(selectedIcon == icon ? .white : selectedColor.color)
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

    private func colorButton(_ color: HabitColor) -> some View {
        Button {
            selectedColor = color
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 36, height: 36)
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

    private func toggleWeekday(_ weekday: Int) {
        if scheduledWeekdays.contains(weekday) {
            scheduledWeekdays.remove(weekday)
        } else {
            scheduledWeekdays.insert(weekday)
        }
    }
}
