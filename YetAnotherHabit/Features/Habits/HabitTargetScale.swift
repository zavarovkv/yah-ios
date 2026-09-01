import Foundation

enum HabitTargetScale {
    static let values = [
        1, 2, 3, 4, 5, 6, 8, 10, 12, 15,
        20, 25, 30, 40, 50, 75, 100, 125, 150, 200,
        250, 300, 400, 500, 600, 750, 999
    ]

    static let defaultValue = 1
    static let minimumValue = 1
    static let maximumValue = 999

    static var positions: ClosedRange<Double> {
        0...Double(values.count - 1)
    }

    static func position(for value: Int) -> Double {
        var nearestIndex = values.startIndex
        var nearestDistance = abs(Double(values[nearestIndex]) - Double(value))

        for index in values.indices.dropFirst() {
            let distance = abs(Double(values[index]) - Double(value))
            if distance < nearestDistance {
                nearestIndex = index
                nearestDistance = distance
            }
        }

        return Double(nearestIndex)
    }

    static func value(at position: Double) -> Int {
        guard position.isFinite else { return defaultValue }

        let index = min(
            max(Int(position.rounded()), values.startIndex),
            values.index(before: values.endIndex)
        )
        return values[index]
    }
}
