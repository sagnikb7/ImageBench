import AppKit
import CoreImage
import Foundation

enum AspectPreset: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "4:5"
    case story = "9:16"
    case wide = "16:9"
    case instagramTwo = "16:10"
    case instagramThree = "12:5"
    case custom = "Custom"
    var id: Self { self }

    var label: String {
        switch self {
        case .square: "1:1 — Square"
        case .portrait: "4:5 — Portrait"
        case .story: "9:16 — Story"
        case .wide: "16:9 — Widescreen"
        case .instagramTwo: "16:10 — Two Instagram panels"
        case .instagramThree: "12:5 — Three Instagram panels"
        case .custom: "Custom…"
        }
    }

    var help: String {
        switch self {
        case .instagramTwo: "Splits into two seamless 4:5 portrait posts."
        case .instagramThree: "Splits into three seamless 4:5 portrait posts."
        default: "Adds canvas around the original without cropping it."
        }
    }

    func ratio(customWidth: Double, customHeight: Double) -> CGFloat {
        switch self {
        case .square: return 1
        case .portrait: return 4.0 / 5.0
        case .story: return 9.0 / 16.0
        case .wide: return 16.0 / 9.0
        case .instagramTwo: return 16.0 / 10.0
        case .instagramThree: return 12.0 / 5.0
        case .custom:
            guard customWidth.isFinite, customHeight.isFinite, customWidth > 0, customHeight > 0 else { return 1 }
            let value = customWidth / customHeight
            guard value.isFinite else { return 1 }
            return CGFloat(min(20, max(0.05, value)))
        }
    }
}

enum FillStyle: String, CaseIterable, Identifiable {
    case white = "White"
    case black = "Black"
    case blur = "Gaussian blur"
    var id: Self { self }
}

enum AspectFillerError: LocalizedError, Equatable {
    case invalidTargetRatio
    case canvasTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidTargetRatio: "The target aspect ratio must be a positive, finite number."
        case .canvasTooLarge: "The requested aspect ratio would create an image that is too large to process safely."
        }
    }
}

enum AspectFillerEngine {
    static func compose(input: URL, targetRatio: CGFloat, style: FillStyle) throws -> CIImage {
        let original = try ImageRenderer.normalizedImage(at: input)
        return try compose(original: original, targetRatio: targetRatio, style: style)
    }

    static func compose(original: CIImage, targetRatio: CGFloat, style: FillStyle) throws -> CIImage {
        try Task.checkCancellation()
        guard targetRatio.isFinite, targetRatio > 0 else { throw AspectFillerError.invalidTargetRatio }
        let sourceSize = original.extent.size
        let sourceRatio = sourceSize.width / sourceSize.height
        let canvasSize: CGSize
        if sourceRatio > targetRatio {
            canvasSize = CGSize(width: sourceSize.width, height: sourceSize.width / targetRatio)
        } else {
            canvasSize = CGSize(width: sourceSize.height * targetRatio, height: sourceSize.height)
        }
        guard canvasSize.width.isFinite, canvasSize.height.isFinite,
            canvasSize.width <= 32_768, canvasSize.height <= 32_768,
            canvasSize.width * canvasSize.height <= 150_000_000
        else {
            throw AspectFillerError.canvasTooLarge
        }
        let canvasRect = CGRect(origin: .zero, size: CGSize(width: canvasSize.width.rounded(), height: canvasSize.height.rounded()))
        let background: CIImage
        switch style {
        case .white:
            background = CIImage(color: .white).cropped(to: canvasRect)
        case .black:
            background = CIImage(color: .black).cropped(to: canvasRect)
        case .blur:
            let scale = max(canvasRect.width / sourceSize.width, canvasRect.height / sourceSize.height)
            let scaled = original.transformed(by: .init(scaleX: scale, y: scale))
            let centered = scaled.transformed(
                by: .init(
                    translationX: (canvasRect.width - scaled.extent.width) / 2 - scaled.extent.minX,
                    y: (canvasRect.height - scaled.extent.height) / 2 - scaled.extent.minY))
            background = centered.clampedToExtent()
                .applyingFilter(
                    "CIGaussianBlur", parameters: [kCIInputRadiusKey: max(24, min(canvasRect.width, canvasRect.height) * 0.035)]
                )
                .cropped(to: canvasRect)
        }
        let foreground = original.transformed(
            by: .init(
                translationX: (canvasRect.width - sourceSize.width) / 2,
                y: (canvasRect.height - sourceSize.height) / 2))
        return foreground.composited(over: background).cropped(to: canvasRect)
    }
}

/// Keeps the decoded source image warm between interactive preview changes.
/// Export still takes the independent full-resolution path in the engine.
actor AspectFillerPreviewRenderer {
    private var cachedURL: URL?
    private var cachedImage: CIImage?

    func preview(input: URL, targetRatio: CGFloat, style: FillStyle) throws -> NSImage {
        try Task.checkCancellation()
        let original: CIImage
        if cachedURL == input, let cachedImage {
            original = cachedImage
        } else {
            original = try ImageRenderer.normalizedImage(at: input)
            cachedURL = input
            cachedImage = original
        }
        let composed = try AspectFillerEngine.compose(original: original, targetRatio: targetRatio, style: style)
        try Task.checkCancellation()
        return try ImageRenderer.preview(composed, maxDimension: 900)
    }
}
