enum HabitAppearanceOptions {
    static let columnCount = 6
    static let iconRowsPerPage = 4
    static let colorRowsPerPage = 2
    static let iconsPerPage = columnCount * iconRowsPerPage
    static let colorsPerPage = columnCount * colorRowsPerPage

    static let icons = [
        "checkmark", "figure.run", "book.fill", "drop.fill",
        "heart.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "dumbbell.fill", "pills.fill", "brain.head.profile", "cup.and.saucer.fill",
        "figure.walk", "bicycle", "fork.knife", "waterbottle.fill",
        "bed.double.fill", "alarm.fill", "pencil", "music.note",
        "paintpalette.fill", "camera.fill", "cart.fill", "house.fill",
        "flame.fill", "bolt.fill", "sparkles", "star.fill",
        "target", "flag.fill", "trophy.fill", "medal.fill",
        "cross.case.fill", "stethoscope", "bandage.fill", "lungs.fill",
        "eye.fill", "ear.fill", "mouth.fill", "waveform.path.ecg",
        "graduationcap.fill", "laptopcomputer", "keyboard", "doc.text.fill",
        "newspaper.fill", "lightbulb.fill", "globe", "character.book.closed.fill",
        "gamecontroller.fill", "headphones", "mic.fill", "film.fill",
        "tv.fill", "theatermasks.fill", "puzzlepiece.fill", "paintbrush.fill",
        "car.fill", "bus.fill", "airplane", "tram.fill",
        "map.fill", "location.fill", "scooter", "fuelpump.fill",
        "phone.fill", "envelope.fill", "bubble.left.fill", "person.2.fill",
        "pawprint.fill", "fish.fill", "hare.fill", "tortoise.fill",
        "clock.fill", "calendar", "timer", "hourglass",
        "briefcase.fill", "creditcard.fill", "gift.fill", "shippingbox.fill",
        "basketball.fill", "football.fill", "baseball.fill", "soccerball",
        "figure.pool.swim", "figure.hiking", "mountain.2.fill", "tree.fill",
        "hammer.fill", "wrench.and.screwdriver.fill", "scissors", "ruler.fill",
        "icloud.fill", "bell.fill", "bookmark.fill", "key.fill",
    ]

    static func randomIcon() -> String {
        icons.randomElement() ?? "checkmark"
    }

    static func randomColor() -> HabitColor {
        HabitColor.allCases.randomElement() ?? .blue
    }
}
