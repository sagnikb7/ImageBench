import CoreImage
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class WatermarkEngineTests: XCTestCase {
    func testTextWatermarksUseArial() {
        XCTAssertEqual(WatermarkEngine.textFontName, "Arial")
    }

    func testLayoutUsesRelativeCoordinatesAndKeepsOverlayInsideCanvas() {
        var draft = WatermarkDraft()
        draft.relativeWidth = 0.25
        draft.placement = WatermarkPlacement(x: 1, y: 1)

        let frame = WatermarkLayout.frame(
            canvasSize: CGSize(width: 400, height: 200),
            overlayAspectRatio: 2,
            draft: draft
        )

        XCTAssertEqual(frame.size, CGSize(width: 100, height: 50))
        XCTAssertEqual(frame.maxX, 400)
        XCTAssertEqual(frame.maxY, 200)
    }

    func testTallWatermarkIsScaledToRemainInsideCanvas() {
        var draft = WatermarkDraft()
        draft.relativeWidth = 0.8

        let frame = WatermarkLayout.frame(
            canvasSize: CGSize(width: 400, height: 100),
            overlayAspectRatio: 0.25,
            draft: draft
        )

        XCTAssertEqual(frame.height, 90)
        XCTAssertEqual(frame.width, 22.5)
        XCTAssertGreaterThanOrEqual(frame.minX, 0)
        XCTAssertLessThanOrEqual(frame.maxX, 400)
    }

    func testImageWatermarkIsCompositedAtConfiguredSize() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        let watermark = temp.url.appendingPathComponent("mark.png")
        try TestImageFactory.make(at: input, width: 200, height: 100) { context, rect in
            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.fill(rect)
        }
        try TestImageFactory.make(at: watermark, width: 20, height: 10) { context, rect in
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(rect)
        }
        var draft = WatermarkDraft()
        draft.kind = .image
        draft.opacity = 1
        draft.relativeWidth = 0.2
        draft.placement = WatermarkPlacement(x: 0.5, y: 0.5)

        let result = try ImageRenderer.cgImage(
            WatermarkEngine.compose(input: input, draft: draft, imageWatermarkURL: watermark)
        )
        let center = try TestImageFactory.pixel(in: result, x: 100, y: 50)
        let corner = try TestImageFactory.pixel(in: result, x: 5, y: 5)

        XCTAssertGreaterThan(center.r, 245)
        XCTAssertLessThan(center.b, 10)
        XCTAssertLessThan(corner.r, 10)
        XCTAssertGreaterThan(corner.b, 245)
    }

    func testOpacityBlendsWatermarkWithSource() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("black.png")
        let watermark = temp.url.appendingPathComponent("white.png")
        try TestImageFactory.make(at: input, width: 100, height: 100) { context, rect in
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fill(rect)
        }
        try TestImageFactory.make(at: watermark, width: 20, height: 20) { context, rect in
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(rect)
        }
        var draft = WatermarkDraft()
        draft.kind = .image
        draft.opacity = 0.5
        draft.relativeWidth = 0.2
        draft.placement = WatermarkPlacement(x: 0.5, y: 0.5)

        let result = try ImageRenderer.cgImage(
            WatermarkEngine.compose(input: input, draft: draft, imageWatermarkURL: watermark)
        )
        let center = try TestImageFactory.pixel(in: result, x: 50, y: 50)
        // Core Image blends in a linear working color space, so 50% white is
        // brighter than an arithmetic 128 once converted back to sRGB.
        XCTAssertGreaterThan(center.r, 170)
        XCTAssertLessThan(center.r, 215)
        XCTAssertApproximately(center.g, center.r, tolerance: 2)
        XCTAssertApproximately(center.b, center.r, tolerance: 2)
    }

    func testTextWatermarkRequiresNonEmptyTextAndRendersPreview() throws {
        var draft = WatermarkDraft()
        draft.kind = .text
        draft.text = "   "
        XCTAssertThrowsError(try WatermarkEngine.textPreview(draft: draft)) { error in
            XCTAssertEqual(error as? WatermarkEngineError, .emptyText)
        }

        draft.text = "Studio Signature"
        let preview = try WatermarkEngine.textPreview(draft: draft)
        XCTAssertGreaterThan(preview.size.width, preview.size.height)
        XCTAssertGreaterThan(preview.size.height, 0)
    }

    func testExportPreservesDimensionsAndNeverChangesSource() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        let output = temp.url.appendingPathComponent("watermarked.png")
        let watermark = temp.url.appendingPathComponent("mark.png")
        try TestImageFactory.make(at: input, width: 160, height: 90)
        try TestImageFactory.make(at: watermark, width: 30, height: 10)
        let originalData = try Data(contentsOf: input)
        var draft = WatermarkDraft()
        draft.kind = .image

        try WatermarkEngine.export(
            input: input,
            draft: draft,
            imageWatermarkURL: watermark,
            output: output,
            type: .png
        )

        XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 160, height: 90))
        XCTAssertEqual(try Data(contentsOf: input), originalData)
        XCTAssertGreaterThan(ImageFileSupport.fileSize(output), 0)
    }

    func testExportRefusesToOverwriteItsSource() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        try TestImageFactory.make(at: input, width: 80, height: 40)
        let originalData = try Data(contentsOf: input)
        var draft = WatermarkDraft()
        draft.text = "ImageBench"

        XCTAssertThrowsError(
            try WatermarkEngine.export(
                input: input,
                draft: draft,
                imageWatermarkURL: nil,
                output: input,
                type: .png
            )
        ) { error in
            XCTAssertEqual(error as? ImageRendererError, .sourceDestinationConflict)
        }
        XCTAssertEqual(try Data(contentsOf: input), originalData)
    }
}
