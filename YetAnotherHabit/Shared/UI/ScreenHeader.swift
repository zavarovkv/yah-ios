import SwiftUI

struct ScreenHeader: View {
    let title: LocalizedStringKey
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    headerLabel
                }
                .buttonStyle(.plain)
            } else {
                headerLabel
            }
        }
    }

    private var headerLabel: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal)
    }
}
