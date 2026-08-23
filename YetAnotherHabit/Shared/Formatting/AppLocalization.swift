import Foundation

enum AppLocalization {
    static func string(
        _ key: String.LocalizationValue,
        locale: Locale,
        bundle: Bundle = .main
    ) -> String {
        guard let localization = Bundle.preferredLocalizations(
                  from: bundle.localizations,
                  forPreferences: [locale.identifier]
              ).first,
              let localizationPath = bundle.path(
                  forResource: localization,
                  ofType: "lproj"
              ),
              let localizedBundle = Bundle(path: localizationPath) else {
            return String(localized: key, bundle: bundle, locale: locale)
        }

        return String(localized: key, bundle: localizedBundle, locale: locale)
    }
}
