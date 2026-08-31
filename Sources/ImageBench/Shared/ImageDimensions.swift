import Foundation

struct ImageDimensions: Equatable, Sendable {
    let width: Int
    let height: Int

    init?(width: Int, height: Int) {
        guard width > 0, height > 0 else { return nil }
        self.width = width
        self.height = height
    }

    init?(size: CGSize) {
        self.init(width: Int(size.width.rounded()), height: Int(size.height.rounded()))
    }

    var ratio: Double { Double(width) / Double(height) }

    var summary: String {
        let divisor = greatestCommonDivisor(width, height)
        return "\(width) × \(height) px • \(width / divisor):\(height / divisor) • \(formattedRatio(ratio))"
    }

    private func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
        var a = abs(lhs)
        var b = abs(rhs)
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return max(1, a)
    }
}

func formattedRatio(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
}
