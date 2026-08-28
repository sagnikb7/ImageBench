import AppKit
import CoreImage
import CoreText
import Foundation
import UniformTypeIdentifiers

enum WatermarkEngineError: LocalizedError, Equatable {
    case emptyText
    case missingImage
    case invalidOverlay

    var errorDescription: String? {
        switch self {
        case .emptyText: "Enter watermark text before exporting."
        case .missingImage: "Choose a readable watermark image before exporting."
        case .invalidOverlay: "The watermark could not be rendered."
        }
    }
}

enum WatermarkEngine {
    static let textFontName = "Arial"

    static func compose(input: URL, draft: WatermarkDraft, imageWatermarkURL: URL?) throws -> CIImage {
        try Task.checkCancellation()
        let source = try ImageRenderer.normalizedImage(at: input)
        let normalized = draft.normalized()
        let overlay = try overlayImage(draft: normalized, imageWatermarkURL: imageWatermarkURL)
        guard overlay.extent.width > 0, overlay.extent.height > 0 else { throw WatermarkEngineError.invalidOverlay }

        let topLeftFrame = WatermarkLayout.frame(
            canvasSize: source.extent.size,
            overlayAspectRatio: overlay.extent.width / overlay.extent.height,
            draft: normalized
        )
        guard !topLeftFrame.isEmpty else { throw WatermarkEngineError.invalidOverlay }

        let scale = topLeftFrame.width / overlay.extent.width
        let scaled = overlay.transformed(by: .init(scaleX: scale, y: scale))
        let bottomLeftY = source.extent.height - topLeftFrame.maxY
        let positioned = scaled.transformed(
            by: .init(
                translationX: topLeftFrame.minX - scaled.extent.minX,
                y: bottomLeftY - scaled.extent.minY
            )
        )
        let translucent = positioned.applyingFilter(
            "CIColorMatrix",
            parameters: ["inputAVector": CIVector(x: 0, y: 0, z: 0, w: normalized.opacity)]
        )
        return translucent.composited(over: source).cropped(to: source.extent)
    }

    static func textPreview(draft: WatermarkDraft) throws -> NSImage {
        try ImageRenderer.preview(try textImage(draft: draft), maxDimension: 900)
    }

    static func export(
        input: URL,
        draft: WatermarkDraft,
        imageWatermarkURL: URL?,
        output: URL,
        type: UTType
    ) throws {
        try Task.checkCancellation()
        let composition = try compose(input: input, draft: draft, imageWatermarkURL: imageWatermarkURL)
        try ImageRenderer.writeAtomically(composition, to: output, type: type, quality: 0.97, protecting: input)
    }

    private static func overlayImage(draft: WatermarkDraft, imageWatermarkURL: URL?) throws -> CIImage {
        switch draft.kind {
        case .text:
            return try textImage(draft: draft)
        case .image:
            guard let imageWatermarkURL else { throw WatermarkEngineError.missingImage }
            return try ImageRenderer.normalizedImage(at: imageWatermarkURL)
        }
    }

    private static func textImage(draft: WatermarkDraft) throws -> CIImage {
        let text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw WatermarkEngineError.emptyText }

        let color = draft.color.normalized()
        let coreTextFont = CTFontCreateWithName(textFontName as CFString, 180, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): coreTextFont,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): NSColor(
                srgbRed: color.red,
                green: color.green,
                blue: color.blue,
                alpha: 1
            ).cgColor,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])
        let padding: CGFloat = 18
        let width = max(1, Int(ceil(bounds.width + padding * 2)))
        let height = max(1, Int(ceil(bounds.height + padding * 2)))
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { throw WatermarkEngineError.invalidOverlay }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: padding - bounds.minX, y: padding - bounds.minY)
        CTLineDraw(line, context)
        guard let rendered = context.makeImage() else { throw WatermarkEngineError.invalidOverlay }
        return CIImage(cgImage: rendered)
    }
}
