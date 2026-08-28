import AppKit
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageRendererError: LocalizedError, Equatable {
    case decode
    case render
    case destination
    case sourceDestinationConflict
    var errorDescription: String? {
        switch self {
        case .decode: "The image could not be decoded."
        case .render: "The image could not be rendered."
        case .destination: "The output file could not be created."
        case .sourceDestinationConflict: "Choose a different filename so the original image stays untouched."
        }
    }
}

enum ImageRenderer {
    static let context = CIContext(options: [.cacheIntermediates: true])
    private static let softwareContext = CIContext(options: [.useSoftwareRenderer: true, .cacheIntermediates: false])

    static func normalizedImage(at url: URL) throws -> CIImage {
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else { throw ImageRendererError.decode }
        return image.transformed(by: .init(translationX: -image.extent.minX, y: -image.extent.minY))
    }

    static func cgImage(_ image: CIImage) throws -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bounds = image.extent.integral
        if let rendered = context.createCGImage(image, from: bounds, format: .RGBA8, colorSpace: colorSpace)
            ?? softwareContext.createCGImage(image, from: bounds, format: .RGBA8, colorSpace: colorSpace)
        {
            return rendered
        }

        // Some headless/test environments cannot create a CGImage directly.
        // Rendering into a CPU bitmap keeps the processing path deterministic.
        let width = Int(bounds.width), height = Int(bounds.height), rowBytes = Int(bounds.width) * 4
        guard width > 0, height > 0 else { throw ImageRendererError.render }
        var pixels = [UInt8](repeating: 0, count: rowBytes * height)
        softwareContext.render(image, toBitmap: &pixels, rowBytes: rowBytes, bounds: bounds, format: .RGBA8, colorSpace: colorSpace)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
            let rendered = CGImage(
                width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: rowBytes, space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: true,
                intent: .defaultIntent)
        else { throw ImageRendererError.render }
        return rendered
    }

    static func preview(_ image: CIImage, maxDimension: CGFloat = 1100) throws -> NSImage {
        let scale = min(1, maxDimension / max(image.extent.width, image.extent.height))
        let rendered = scale < 1 ? image.transformed(by: .init(scaleX: scale, y: scale)) : image
        let cg = try cgImage(rendered)
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    /// Decodes a bounded, orientation-correct thumbnail instead of asking SwiftUI
    /// to repeatedly decode the full-resolution source during view updates.
    static func thumbnail(at url: URL, maxPixelSize: Int) throws -> NSImage {
        guard maxPixelSize > 0,
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                    kCGImageSourceShouldCacheImmediately: true,
                ] as CFDictionary
            )
        else { throw ImageRendererError.decode }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }

    static func write(_ image: CIImage, to url: URL, type: UTType, quality: Double = 0.96) throws {
        let rendered = try cgImage(image)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw ImageRendererError.destination
        }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, rendered, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageRendererError.destination }
    }

    /// Writes through a sibling temporary file, then swaps it into place. Keeping
    /// the temporary file on the destination volume makes the final move atomic.
    static func writeAtomically(
        _ image: CIImage,
        to output: URL,
        type: UTType,
        quality: Double = 0.96,
        protecting source: URL
    ) throws {
        let sourcePath = source.resolvingSymlinksInPath().standardizedFileURL
        let outputPath = output.resolvingSymlinksInPath().standardizedFileURL
        guard sourcePath != outputPath else { throw ImageRendererError.sourceDestinationConflict }

        let fileManager = FileManager.default
        let temporary = output.deletingLastPathComponent()
            .appendingPathComponent(".imagebench-export-\(UUID().uuidString)")
            .appendingPathExtension(output.pathExtension)
        defer { try? fileManager.removeItem(at: temporary) }

        try Task.checkCancellation()
        try write(image, to: temporary, type: type, quality: quality)
        try Task.checkCancellation()

        if fileManager.fileExists(atPath: output.path) {
            _ = try fileManager.replaceItemAt(output, withItemAt: temporary)
        } else {
            try fileManager.moveItem(at: temporary, to: output)
        }
    }
}
