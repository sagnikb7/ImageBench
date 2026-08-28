import Foundation
import ImageIO

enum CompressionPreflightError: LocalizedError, Equatable {
    case noInputs
    case missingExecutable(String)
    case exiftoolRequired
    case outputUnavailable(String)
    case outputNotWritable(String)
    case insufficientOutputSpace(required: Int64, available: Int64)
    case insufficientTemporarySpace(required: Int64, available: Int64)

    var errorDescription: String? {
        switch self {
        case .noInputs:
            "No supported images were selected."
        case .missingExecutable(let name):
            "The required \(name) executable is unavailable."
        case .exiftoolRequired:
            "ExifTool is required to preserve or selectively remove metadata."
        case .outputUnavailable(let detail):
            "The output folder could not be prepared: \(detail)"
        case .outputNotWritable(let path):
            "ImageBench cannot write to the output folder: \(path)"
        case .insufficientOutputSpace(let required, let available):
            "The output disk needs about \(Self.bytes(required)), but only \(Self.bytes(available)) is available."
        case .insufficientTemporarySpace(let required, let available):
            "The temporary disk needs about \(Self.bytes(required)), but only \(Self.bytes(available)) is available."
        }
    }

    private static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }
}

struct CompressionPreflightReport: Sendable, Equatable {
    let estimatedOutputBytes: Int64
    let estimatedTemporaryBytes: Int64
    let outputAvailableBytes: Int64?
    let temporaryAvailableBytes: Int64?
}

enum CompressionPreflight {
    static let safetyMargin: Int64 = 64 * 1_024 * 1_024

    static func run(job: CompressionJob, fileManager: FileManager = .default) throws -> CompressionPreflightReport {
        guard !job.inputs.isEmpty else { throw CompressionPreflightError.noInputs }
        try requireExecutable(job.cjpeg, named: "mozjpeg")
        if !job.options.removeAllMetadata {
            guard let exiftool = job.exiftool else { throw CompressionPreflightError.exiftoolRequired }
            try requireExecutable(exiftool, named: "ExifTool")
        }

        do {
            try fileManager.createDirectory(at: job.outputFolder, withIntermediateDirectories: true)
        } catch {
            throw CompressionPreflightError.outputUnavailable(error.localizedDescription)
        }
        try verifyWritable(job.outputFolder, fileManager: fileManager)

        let outputRequired = estimatedOutputBytes(for: job.inputs)
        let temporaryRequired = estimatedTemporaryBytes(for: job.inputs)
        let outputAvailable = availableCapacity(at: job.outputFolder)
        let temporaryAvailable = availableCapacity(at: fileManager.temporaryDirectory)
        try validateCapacity(required: outputRequired, available: outputAvailable, temporary: false)
        try validateCapacity(required: temporaryRequired, available: temporaryAvailable, temporary: true)
        return CompressionPreflightReport(
            estimatedOutputBytes: outputRequired,
            estimatedTemporaryBytes: temporaryRequired,
            outputAvailableBytes: outputAvailable,
            temporaryAvailableBytes: temporaryAvailable
        )
    }

    static func estimatedOutputBytes(for inputs: [URL]) -> Int64 {
        safetyMargin + inputs.reduce(0) { $0 + max(0, ImageFileSupport.fileSize($1)) }
    }

    static func estimatedTemporaryBytes(for inputs: [URL]) -> Int64 {
        let largestRGB = inputs.reduce(Int64(0)) { largest, input in
            guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
                let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
            else { return largest }
            let pixels = width.int64Value.multipliedReportingOverflow(by: height.int64Value)
            guard !pixels.overflow else { return Int64.max }
            let bytes = pixels.partialValue.multipliedReportingOverflow(by: 3)
            return max(largest, bytes.overflow ? Int64.max : bytes.partialValue)
        }
        let total = largestRGB.addingReportingOverflow(safetyMargin)
        return total.overflow ? Int64.max : total.partialValue
    }

    static func validateCapacity(required: Int64, available: Int64?, temporary: Bool) throws {
        guard let available, available < required else { return }
        if temporary {
            throw CompressionPreflightError.insufficientTemporarySpace(required: required, available: available)
        }
        throw CompressionPreflightError.insufficientOutputSpace(required: required, available: available)
    }

    private static func requireExecutable(_ url: URL, named name: String) throws {
        guard FileManager.default.isExecutableFile(atPath: url.path) else {
            throw CompressionPreflightError.missingExecutable(name)
        }
    }

    private static func verifyWritable(_ folder: URL, fileManager: FileManager) throws {
        let probe = folder.appendingPathComponent(".imagebench-write-test-\(UUID().uuidString)")
        guard fileManager.createFile(atPath: probe.path, contents: Data()) else {
            throw CompressionPreflightError.outputNotWritable(folder.path(percentEncoded: false))
        }
        do {
            try fileManager.removeItem(at: probe)
        } catch {
            throw CompressionPreflightError.outputNotWritable(folder.path(percentEncoded: false))
        }
    }

    private static func availableCapacity(at url: URL) -> Int64? {
        if let values = try? url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]) {
            if let important = values.volumeAvailableCapacityForImportantUsage, important > 0 { return important }
            if let regular = values.volumeAvailableCapacity, regular > 0 { return Int64(regular) }
        }
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: url.path),
            let free = attributes[.systemFreeSize] as? NSNumber,
            free.int64Value > 0
        {
            return free.int64Value
        }
        // Some app and test sandboxes report zero instead of making capacity
        // information available. A successful write probe is more trustworthy
        // than treating that sentinel as a genuinely full disk.
        return nil
    }
}
