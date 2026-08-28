import Foundation

extension ByteCountFormatter {
    static func string(for bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

extension URL {
    var displayName: String { deletingPathExtension().lastPathComponent }
}
