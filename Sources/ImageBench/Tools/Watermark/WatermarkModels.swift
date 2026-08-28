import CoreGraphics
import Foundation

enum WatermarkKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case text = "Text"
    case image = "Image"

    var id: Self { self }
}

struct WatermarkColor: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double

    static let white = WatermarkColor(red: 1, green: 1, blue: 1)

    func normalized() -> WatermarkColor {
        WatermarkColor(
            red: red.clamped(to: 0...1),
            green: green.clamped(to: 0...1),
            blue: blue.clamped(to: 0...1)
        )
    }
}

struct WatermarkPlacement: Codable, Equatable, Sendable {
    /// Center coordinates measured from the image's top-left corner.
    var x: Double
    var y: Double

    static let bottomRight = WatermarkPlacement(x: 0.84, y: 0.86)

    func normalized() -> WatermarkPlacement {
        WatermarkPlacement(x: x.clamped(to: 0...1), y: y.clamped(to: 0...1))
    }
}

struct WatermarkDraft: Codable, Equatable, Sendable {
    var kind: WatermarkKind = .text
    var text = "© Your Name"
    var color = WatermarkColor.white
    var opacity = 0.82
    var relativeWidth = 0.24
    var placement = WatermarkPlacement.bottomRight

    static var cleanSlate: WatermarkDraft {
        var draft = WatermarkDraft()
        draft.text = ""
        return draft
    }

    func normalized() -> WatermarkDraft {
        var copy = self
        copy.color = color.normalized()
        copy.opacity = opacity.clamped(to: 0.1...1)
        copy.relativeWidth = relativeWidth.clamped(to: 0.05...0.8)
        copy.placement = placement.normalized()
        return copy
    }
}

struct WatermarkPreset: Codable, Equatable, Identifiable, Sendable {
    let slot: Int
    let draft: WatermarkDraft
    let cachedImageFilename: String?
    let updatedAt: Date

    var id: Int { slot }
}

enum WatermarkLayout {
    /// Returns a top-left-origin frame. Both the SwiftUI preview and Core Image
    /// export use this function so a saved preset has the same visual placement.
    static func frame(
        canvasSize: CGSize,
        overlayAspectRatio: CGFloat,
        draft: WatermarkDraft
    ) -> CGRect {
        guard canvasSize.width > 0, canvasSize.height > 0,
            overlayAspectRatio.isFinite, overlayAspectRatio > 0
        else { return .zero }

        let normalized = draft.normalized()
        var width = canvasSize.width * normalized.relativeWidth
        var height = width / overlayAspectRatio
        let maximumHeight = canvasSize.height * 0.9
        if height > maximumHeight {
            height = maximumHeight
            width = height * overlayAspectRatio
        }

        let halfWidth = width / 2
        let halfHeight = height / 2
        let centerX = (canvasSize.width * normalized.placement.x).clamped(to: halfWidth...(canvasSize.width - halfWidth))
        let centerY = (canvasSize.height * normalized.placement.y).clamped(to: halfHeight...(canvasSize.height - halfHeight))
        return CGRect(x: centerX - halfWidth, y: centerY - halfHeight, width: width, height: height)
    }
}

extension Comparable {
    fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
