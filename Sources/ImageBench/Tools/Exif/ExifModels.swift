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

struct ExifCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    init?(latitude: Double, longitude: Double) {
        guard latitude.isFinite, longitude.isFinite,
            (-90...90).contains(latitude), (-180...180).contains(longitude)
        else { return nil }
        self.latitude = latitude
        self.longitude = longitude
    }

    var displayValue: String {
        String(
            format: "%.6f, %.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            latitude,
            longitude
        )
    }

    var googleMapsURL: URL? {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: displayValue),
        ]
        return components?.url
    }
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
    let coordinate: ExifCoordinate?

    var fieldCount: Int { sections.reduce(0) { $0 + $1.fields.count } }
}
