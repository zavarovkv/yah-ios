import SwiftUI

struct HabitSectionHeaderView: View {
    let title: LocalizedStringKey
    let count: Int
    var isExpanded = true
    var showsDisclosureIndicator = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(count, format: .number)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())

            Spacer()

            if showsDisclosureIndicator {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
        }
        .textCase(nil)
        .contentShape(Rectangle())
    }
}

extension View {
    // SwiftUI pins native List section headers in the plain style and exposes
    // no opt-out on iOS 18. A regular list row preserves List behavior while
    // allowing the title to scroll naturally with its section.
    func habitSectionHeaderRowStyle() -> some View {
        frame(minHeight: 44)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .accessibilityAddTraits(.isHeader)
    }
}
