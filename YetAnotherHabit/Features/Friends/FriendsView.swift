import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Друзей пока нет",
                systemImage: "person.2",
                description: Text("Здесь позже появятся ваши друзья.")
            )
            .navigationTitle("Друзья")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
