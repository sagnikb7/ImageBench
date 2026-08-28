import Foundation

/// Accumulates exact command output without forcing SwiftUI to redraw for every
/// line while the technical disclosure is closed.
struct CompressionLogBuffer: Equatable {
    private(set) var lines: [String] = []

    var text: String { lines.joined(separator: "\n") }

    mutating func reset() {
        lines.removeAll(keepingCapacity: true)
    }

    @discardableResult
    mutating func append(_ line: String) -> Bool {
        let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        lines.append(normalized)
        return true
    }
}
