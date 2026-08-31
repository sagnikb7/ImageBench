import CoreImage
import Foundation

enum SplitOrientation: String, CaseIterable, Identifiable, Sendable {
    case horizontal = "Horizontal rows"
    case vertical = "Vertical columns"
    var id: Self { self }
}

enum SplitterError: LocalizedError, Equatable {
    case invalidSliceCount(requested: Int, availablePixels: Int)
    case sliceLimitExceeded(requested: Int, maximum: Int)
    case unsupportedOutputFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidSliceCount(let requested, let available):
            "Cannot create \(requested) non-empty slices from only \(available) pixels."
        case .unsupportedOutputFormat(let ext):
            "The .\(ext) format cannot be preserved by the splitter. Choose JPEG, PNG, or HEIC."
        case .sliceLimitExceeded(let requested, let maximum):
            "ImageBench supports up to \(maximum) slices per export; \(requested) were requested."
        }
    }
}

enum SplitterEngine {
    static let maximumSlices = 12

    static func partDimensions(
        source: ImageDimensions,
        orientation: SplitOrientation,
        count: Int
    ) throws -> [ImageDimensions] {
        let availablePixels = orientation == .vertical ? source.width : source.height
        let ranges = try sliceRanges(availablePixels: availablePixels, count: count)
        return ranges.compactMap { range in
            if orientation == .vertical {
                ImageDimensions(width: range.count, height: source.height)
            } else {
                ImageDimensions(width: source.width, height: range.count)
            }
        }
    }

    static func split(input: URL, outputFolder: URL, orientation: SplitOrientation, count: Int) throws -> [URL] {
        let image = try ImageRenderer.normalizedImage(at: input)
        let width = Int(image.extent.width.rounded(.down))
        let height = Int(image.extent.height.rounded(.down))
        guard width > 0, height > 0 else { throw ImageRendererError.decode }
        let availablePixels = orientation == .vertical ? width : height
        let ranges = try sliceRanges(availablePixels: availablePixels, count: count)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        let ext = input.pathExtension.lowercased()
        guard let type = ImageFileSupport.formatPreservingContentType(for: input) else {
            throw SplitterError.unsupportedOutputFormat(ext)
        }
        let digits = max(2, String(count).count)
        var outputs: [URL] = []
        for index in 0..<count {
            try Task.checkCancellation()
            let crop: CGRect
            let range = ranges[index]
            if orientation == .vertical {
                crop = CGRect(x: range.lowerBound, y: 0, width: range.count, height: height)
            } else {
                // Core Image's origin is bottom-left; user-facing row order is top-to-bottom.
                crop = CGRect(x: 0, y: height - range.upperBound, width: width, height: range.count)
            }
            let part = image.cropped(to: crop).transformed(by: .init(translationX: -crop.minX, y: -crop.minY))
            let number = String(format: "%0*d", digits, index + 1)
            let output = ImageFileSupport.uniqueOutput(in: outputFolder, stem: "\(input.displayName)_part_\(number)", extension: ext)
            try ImageRenderer.write(part, to: output, type: type)
            outputs.append(output)
        }
        return outputs
    }

    private static func sliceRanges(availablePixels: Int, count: Int) throws -> [Range<Int>] {
        guard count <= maximumSlices else {
            throw SplitterError.sliceLimitExceeded(requested: count, maximum: maximumSlices)
        }
        guard count >= 2, count <= availablePixels else {
            throw SplitterError.invalidSliceCount(requested: count, availablePixels: availablePixels)
        }
        return (0..<count).map { index in
            // Computing both boundaries from the full dimension distributes remainders
            // without accumulating rounding error across slices.
            let start = Int((Double(index) * Double(availablePixels) / Double(count)).rounded(.down))
            let end = Int((Double(index + 1) * Double(availablePixels) / Double(count)).rounded(.down))
            return start..<end
        }
    }
}
