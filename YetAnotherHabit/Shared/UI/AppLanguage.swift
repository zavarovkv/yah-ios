import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"

    var id: Self { self }

    var title: String {
        switch self {
        case .russian: "Русский"
        case .english: "English"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    static var selectedLocale: Locale {
        let value = UserDefaults.standard.string(forKey: "appLanguage") ?? russian.rawValue
        return AppLanguage(rawValue: value)?.locale ?? AppLanguage.russian.locale
    }
}
