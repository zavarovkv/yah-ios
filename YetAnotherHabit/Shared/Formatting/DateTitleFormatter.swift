import Foundation

enum DateTitleFormatter {
    static func title(for date: Date, calendar: Calendar, locale: Locale) -> String {
        if calendar.isDateInToday(date) {
            return String(localized: "Сегодня")
        }

        if calendar.isDateInTomorrow(date) {
            return String(localized: "Завтра")
        }

        if calendar.isDateInYesterday(date) {
            return String(localized: "Вчера")
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(locale)
        )
    }
}
