import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExifFileSupport {
    static let standardExtensions = Set([
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "bmp", "gif", "webp",
    ])
    static let rawExtensions = Set([
        "3fr", "arw", "cr2", "cr3", "dng", "erf", "iiq", "mef", "mos", "mrw", "nef", "nrw", "orf",
        "ori", "pef", "ptx", "raf", "raw", "rw2", "rwl", "sr2", "srf", "x3f",
    ])
    static let supportedExtensions = standardExtensions.union(rawExtensions)

    static var contentTypes: [UTType] {
        var types = [UTType.image]
        for fileExtension in rawExtensions.sorted() {
            guard let type = UTType(filenameExtension: fileExtension), !types.contains(type) else { continue }
            types.append(type)
        }
        return types
    }

    static func supports(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func isRAW(_ url: URL) -> Bool {
        rawExtensions.contains(url.pathExtension.lowercased())
    }
}

struct ExifMetadataField: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { label }
}

struct ExifMetadataSection: Identifiable, Equatable {
    let title: String
    let fields: [ExifMetadataField]

    var id: String { title }
}

struct ExifHistogram: Equatable {
    let luminance: [Double]
    let red: [Double]
    let green: [Double]
    let blue: [Double]

    static let empty = ExifHistogram(
        luminance: Array(repeating: 0, count: 256),
        red: Array(repeating: 0, count: 256),
        green: Array(repeating: 0, count: 256),
        blue: Array(repeating: 0, count: 256)
    )
}

struct ExifInspection {
    let url: URL
    let preview: NSImage?
    let histogram: ExifHistogram
    let sections: [ExifMetadataSection]
    let isRAW: Bool

    var fieldCount: Int { sections.reduce(0) { $0 + $1.fields.count } }
}
