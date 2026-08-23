import Foundation

enum DateTitleFormatter {
    static func title(for date: Date, calendar: Calendar, locale: Locale) -> String {
        if calendar.isDateInToday(date) {
            return AppLocalization.string("Сегодня", locale: locale)
        }

        if calendar.isDateInTomorrow(date) {
            return AppLocalization.string("Завтра", locale: locale)
        }

        if calendar.isDateInYesterday(date) {
            return AppLocalization.string("Вчера", locale: locale)
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(locale)
        )
    }
}
