import SwiftUI

enum HabitColor: String, CaseIterable, Identifiable {
    case blue
    case brown
    case coral
    case cyan
    case gold
    case gray
    case graphite
    case green
    case indigo
    case lavender
    case lime
    case magenta
    case mint
    case navy
    case olive
    case orange
    case peach
    case pink
    case plum
    case purple
    case red
    case sky
    case teal
    case yellow

    var id: Self { self }

    var color: Color {
        switch self {
        case .blue: .blue
        case .brown: .brown
        case .coral: Color(red: 0.95, green: 0.35, blue: 0.32)
        case .cyan: .cyan
        case .gold: Color(red: 0.95, green: 0.65, blue: 0.08)
        case .gray: .gray
        case .graphite: Color(red: 0.32, green: 0.34, blue: 0.38)
        case .green: .green
        case .indigo: .indigo
        case .lavender: Color(red: 0.62, green: 0.52, blue: 0.92)
        case .lime: Color(red: 0.55, green: 0.76, blue: 0.16)
        case .magenta: Color(red: 0.86, green: 0.18, blue: 0.56)
        case .mint: .mint
        case .navy: Color(red: 0.12, green: 0.28, blue: 0.56)
        case .olive: Color(red: 0.48, green: 0.52, blue: 0.16)
        case .orange: .orange
        case .peach: Color(red: 0.98, green: 0.62, blue: 0.46)
        case .pink: .pink
        case .plum: Color(red: 0.48, green: 0.18, blue: 0.38)
        case .purple: .purple
        case .red: .red
        case .sky: Color(red: 0.34, green: 0.68, blue: 0.94)
        case .teal: .teal
        case .yellow: .yellow
        }
    }

    var foregroundColor: Color {
        switch self {
        case .cyan, .gold, .lime, .mint, .olive, .peach, .sky, .yellow:
            Color.black.opacity(0.78)
        default:
            .white
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .blue: "Синий"
        case .brown: "Коричневый"
        case .coral: "Коралловый"
        case .cyan: "Голубой"
        case .gold: "Золотой"
        case .gray: "Серый"
        case .graphite: "Графитовый"
        case .green: "Зелёный"
        case .indigo: "Индиго"
        case .lavender: "Лавандовый"
        case .lime: "Лаймовый"
        case .magenta: "Малиновый"
        case .mint: "Мятный"
        case .navy: "Тёмно-синий"
        case .olive: "Оливковый"
        case .orange: "Оранжевый"
        case .peach: "Персиковый"
        case .pink: "Розовый"
        case .plum: "Сливовый"
        case .purple: "Фиолетовый"
        case .red: "Красный"
        case .sky: "Небесный"
        case .teal: "Бирюзовый"
        case .yellow: "Жёлтый"
        }
    }
}
