import SwiftUI

enum HabitColor: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case pink
    case purple
    case red

    var id: Self { self }

    var color: Color {
        switch self {
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .red: .red
        }
    }

    var title: String {
        switch self {
        case .blue: String(localized: "Синий")
        case .green: String(localized: "Зелёный")
        case .orange: String(localized: "Оранжевый")
        case .pink: String(localized: "Розовый")
        case .purple: String(localized: "Фиолетовый")
        case .red: String(localized: "Красный")
        }
    }
}
