import Foundation

enum DateTitleFormatter {
    static func title(for date: Date, calendar: Calendar, locale: Locale) -> String {
        if calendar.isDateInToday(date) {
            return String(localized: "Сегодня", locale: locale)
        }

        if calendar.isDateInTomorrow(date) {
            return String(localized: "Завтра", locale: locale)
        }

        if calendar.isDateInYesterday(date) {
            return String(localized: "Вчера", locale: locale)
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(locale)
        )
    }
}
