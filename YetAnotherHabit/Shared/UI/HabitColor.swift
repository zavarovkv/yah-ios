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
        case .blue: String(localized: "Синий", locale: AppLanguage.selectedLocale)
        case .green: String(localized: "Зелёный", locale: AppLanguage.selectedLocale)
        case .orange: String(localized: "Оранжевый", locale: AppLanguage.selectedLocale)
        case .pink: String(localized: "Розовый", locale: AppLanguage.selectedLocale)
        case .purple: String(localized: "Фиолетовый", locale: AppLanguage.selectedLocale)
        case .red: String(localized: "Красный", locale: AppLanguage.selectedLocale)
        }
    }
}
