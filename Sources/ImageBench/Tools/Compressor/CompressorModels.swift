import Foundation

enum CompressionPreset: String, CaseIterable, Identifiable, Sendable {
    case archive = "Cloud Archive (Sony mirrorless)"
    case web = "Web Optimized"
    case maximum = "Maximum Compression"
    case custom = "Custom"
    var id: Self { self }

    var displayName: String {
        switch self {
        case .archive: "Cloud Archive"
        case .web: "Web Optimized"
        case .maximum: "Maximum Compression"
        case .custom: "Custom Settings…"
        }
    }

    var detail: String {
        switch self {
        case .archive: "High quality for camera originals and long-term storage."
        case .web: "Balanced quality and size for websites and everyday sharing."
        case .maximum: "Prioritizes the smallest practical JPEG output."
        case .custom: "Fine-tune quality, chroma sampling, and encoder options."
        }
    }
}

enum MetadataPolicy: String, CaseIterable, Identifiable, Sendable {
    case keep = "Keep Everything"
    case removeLocation = "Remove Location"
    case removeEXIF = "Remove EXIF"
    case removeAll = "Remove All Metadata"

    var id: Self { self }
    var detail: String {
        switch self {
        case .keep: "Preserves supported camera, copyright, and location metadata."
        case .removeLocation: "Removes GPS coordinates while preserving other camera details."
        case .removeEXIF: "Removes EXIF camera data, including embedded GPS information."
        case .removeAll: "Creates a clean JPEG without copying source metadata."
        }
    }
}

struct CompressionOptions: Sendable {
    static let customQualityRange = 0...100
    static let customQualityStep = 5

    var quality = 82
    var progressive = true
    var optimize = true
    var quantTable = 3
    var sampling = "2x2"
    var removeEXIF = false
    var removeGPS = false
    var removeAllMetadata = false

    mutating func apply(_ preset: CompressionPreset) {
        switch preset {
        case .archive:
            quality = 82; progressive = true; optimize = true; quantTable = 3; sampling = "2x2"
        case .web:
            quality = 75; progressive = true; optimize = true; quantTable = 0; sampling = ""
        case .maximum:
            quality = 60; progressive = true; optimize = true; quantTable = 0; sampling = "2x2"
        case .custom: break
        }
    }

    var cjpegArguments: [String] {
        var result = ["-quality", String(quality)]
        if progressive { result.append("-progressive") }
        if optimize { result.append("-optimize") }
        if quantTable > 0 { result += ["-quant-table", String(quantTable)] }
        if !sampling.isEmpty { result += ["-sample", sampling] }
        return result
    }

    static func normalizedCustomQuality(_ quality: Int) -> Int {
        let clamped = min(customQualityRange.upperBound, max(customQualityRange.lowerBound, quality))
        return Int((Double(clamped) / Double(customQualityStep)).rounded()) * customQualityStep
    }
}

struct CompressionJob: Sendable {
    let inputs: [URL]
    let outputFolder: URL
    let cjpeg: URL
    let exiftool: URL?
    let options: CompressionOptions
}

struct CompressionSuccess: Sendable, Equatable {
    let input: URL
    let output: URL
    let bytes: Int64
}

struct CompressionFailure: Sendable, Equatable, Identifiable {
    let input: URL
    let output: URL?
    let message: String

    var id: URL { input }
}

struct CompressionBatchResult: Sendable, Equatable {
    var successes: [CompressionSuccess] = []
    var failures: [CompressionFailure] = []
    var skipped: [URL] = []
    var wasCancelled = false

    var written: Int { successes.count }
    var bytes: Int64 { successes.reduce(0) { $0 + $1.bytes } }
    var processed: Int { successes.count + failures.count }
}
