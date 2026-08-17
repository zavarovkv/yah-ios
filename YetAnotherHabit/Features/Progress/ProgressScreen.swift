import SwiftUI

struct ProgressScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Прогресса пока нет",
                systemImage: "chart.bar",
                description: Text("Здесь появится прогресс по вашим привычкам.")
            )
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
