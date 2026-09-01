import SwiftUI
import UIKit

struct HabitAppearancePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var icon: String
    @Binding var color: HabitColor
    @State private var selectedIconPage: Int
    @State private var selectedColorPage: Int

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: HabitAppearanceOptions.columnCount
    )

    init(icon: Binding<String>, color: Binding<HabitColor>) {
        _icon = icon
        _color = color
        _selectedIconPage = State(
            initialValue: (HabitAppearanceOptions.icons.firstIndex(
                of: icon.wrappedValue
            ) ?? 0) / HabitAppearanceOptions.iconsPerPage
        )
        _selectedColorPage = State(
            initialValue: (HabitColor.allCases.firstIndex(
                of: color.wrappedValue
            ) ?? 0) / HabitAppearanceOptions.colorsPerPage
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Иконка") {
                    VStack(spacing: 8) {
                        TabView(selection: $selectedIconPage) {
                            ForEach(iconPages.indices, id: \.self) { pageIndex in
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(iconPages[pageIndex], id: \.self) { candidate in
                                        iconButton(candidate)
                                    }
                                }
                                .tag(pageIndex)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 200)

                        AppearancePageControl(
                            numberOfPages: iconPages.count,
                            currentPage: $selectedIconPage
                        )
                        .frame(height: 28)
                    }
                }

                Section("Цвет") {
                    VStack(spacing: 8) {
                        TabView(selection: $selectedColorPage) {
                            ForEach(colorPages.indices, id: \.self) { pageIndex in
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(colorPages[pageIndex]) { candidate in
                                        colorButton(candidate)
                                    }
                                }
                                .tag(pageIndex)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 96)

                        AppearancePageControl(
                            numberOfPages: colorPages.count,
                            currentPage: $selectedColorPage
                        )
                        .frame(height: 28)
                    }
                }
            }
            .navigationTitle("Оформление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var iconPages: [[String]] {
        pages(
            for: HabitAppearanceOptions.icons,
            size: HabitAppearanceOptions.iconsPerPage
        )
    }

    private var colorPages: [[HabitColor]] {
        pages(
            for: HabitColor.allCases,
            size: HabitAppearanceOptions.colorsPerPage
        )
    }

    private func iconButton(_ candidate: String) -> some View {
        let iconNumber = (HabitAppearanceOptions.icons.firstIndex(of: candidate) ?? 0) + 1

        return Button {
            icon = candidate
        } label: {
            Image(systemName: candidate)
                .font(.title3)
                .foregroundStyle(
                    icon == candidate ? color.foregroundColor : color.color
                )
                .frame(width: 40, height: 40)
                .background {
                    Circle().fill(
                        icon == candidate
                            ? color.color
                            : Color.secondary.opacity(0.12)
                    )
                }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Иконка \(iconNumber)")
        .accessibilityAddTraits(icon == candidate ? .isSelected : [])
    }

    private func colorButton(_ candidate: HabitColor) -> some View {
        Button {
            color = candidate
        } label: {
            Circle()
                .fill(candidate.color)
                .frame(width: 40, height: 40)
                .overlay {
                    if color == candidate {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(candidate.foregroundColor)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(Text(candidate.title))
        .accessibilityAddTraits(color == candidate ? .isSelected : [])
    }

    private func pages<Element>(for elements: [Element], size: Int) -> [[Element]] {
        stride(from: 0, to: elements.count, by: size).map { startIndex in
            Array(elements[startIndex..<min(startIndex + size, elements.count)])
        }
    }
}

private struct AppearancePageControl: UIViewRepresentable {
    let numberOfPages: Int
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.backgroundStyle = .minimal
        pageControl.hidesForSinglePage = true
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.pageIndicatorTintColor = .tertiaryLabel
        pageControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.pageChanged(_:)),
            for: .valueChanged
        )
        return pageControl
    }

    func updateUIView(_ pageControl: UIPageControl, context: Context) {
        context.coordinator.parent = self
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPage
    }

    final class Coordinator: NSObject {
        var parent: AppearancePageControl

        init(parent: AppearancePageControl) {
            self.parent = parent
        }

        @objc func pageChanged(_ sender: UIPageControl) {
            parent.currentPage = sender.currentPage
        }
    }
}
