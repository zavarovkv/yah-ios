import SwiftUI

enum HabitColor: String, CaseIterable, Identifiable {
    case blue
    case brown
    case cyan
    case green
    case indigo
    case mint
    case orange
    case pink
    case purple
    case red
    case teal
    case yellow

    var id: Self { self }

    var color: Color {
        switch self {
        case .blue: .blue
        case .brown: .brown
        case .cyan: .cyan
        case .green: .green
        case .indigo: .indigo
        case .mint: .mint
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .red: .red
        case .teal: .teal
        case .yellow: .yellow
        }
    }

    var title: String {
        switch self {
        case .blue: String(localized: "Синий", locale: AppLanguage.selectedLocale)
        case .brown: String(localized: "Коричневый", locale: AppLanguage.selectedLocale)
        case .cyan: String(localized: "Голубой", locale: AppLanguage.selectedLocale)
        case .green: String(localized: "Зелёный", locale: AppLanguage.selectedLocale)
        case .indigo: String(localized: "Индиго", locale: AppLanguage.selectedLocale)
        case .mint: String(localized: "Мятный", locale: AppLanguage.selectedLocale)
        case .orange: String(localized: "Оранжевый", locale: AppLanguage.selectedLocale)
        case .pink: String(localized: "Розовый", locale: AppLanguage.selectedLocale)
        case .purple: String(localized: "Фиолетовый", locale: AppLanguage.selectedLocale)
        case .red: String(localized: "Красный", locale: AppLanguage.selectedLocale)
        case .teal: String(localized: "Бирюзовый", locale: AppLanguage.selectedLocale)
        case .yellow: String(localized: "Жёлтый", locale: AppLanguage.selectedLocale)
        }
    }
}
