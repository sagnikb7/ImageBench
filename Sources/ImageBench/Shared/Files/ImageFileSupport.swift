import Foundation
import UniformTypeIdentifiers

enum ImageFileSupport {
    /// Formats that Core Image can normalize before mozjpeg compression.
    static let compressorInputExtensions = Set([
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "bmp", "gif", "webp",
    ])

    /// Formats whose encoder and file extension are preserved by the editing tools.
    static let formatPreservingExtensions = Set(["jpg", "jpeg", "png", "heic", "heif"])
    static let formatPreservingContentTypes: [UTType] = [.jpeg, .png, .heic]

    static func supportsCompressionInput(_ url: URL) -> Bool {
        compressorInputExtensions.contains(normalizedExtension(of: url))
    }

    static func supportsFormatPreservingOutput(_ url: URL) -> Bool {
        formatPreservingExtensions.contains(normalizedExtension(of: url))
    }

    static func contentType(for url: URL) -> UTType {
        switch normalizedExtension(of: url) {
        case "png": .png
        case "heic", "heif": .heic
        case "tif", "tiff": .tiff
        case "bmp": .bmp
        case "gif": .gif
        case "webp": .webP
        case "jpg", "jpeg": .jpeg
        default: .jpeg
        }
    }

    static func formatPreservingContentType(for url: URL) -> UTType? {
        guard supportsFormatPreservingOutput(url) else { return nil }
        return contentType(for: url)
    }

    static func fileSize(_ url: URL) -> Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
    }

    static func uniqueOutput(in folder: URL, stem: String, extension ext: String) -> URL {
        var candidate = folder.appendingPathComponent(stem).appendingPathExtension(ext)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(stem)_\(suffix)").appendingPathExtension(ext)
            suffix += 1
        }
        return candidate
    }

    private static func normalizedExtension(of url: URL) -> String {
        url.pathExtension.lowercased()
    }
}
