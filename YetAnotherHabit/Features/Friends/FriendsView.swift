import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    ScreenHeader(title: "Друзья")
                    Spacer()
                }

                ScreenEmptyState(
                    title: "Друзей пока нет.",
                    systemImage: "person.2",
                    description: "Здесь позже появятся ваши друзья."
                )
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
