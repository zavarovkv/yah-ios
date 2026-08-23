import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case russian = "ru"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case portugueseBrazil = "pt-BR"

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Как в системе"
        case .russian: "Русский"
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .portugueseBrazil: "Português (Brasil)"
        }
    }

    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .russian, .english, .spanish, .french, .portugueseBrazil:
            Locale(identifier: rawValue)
        }
    }
}
