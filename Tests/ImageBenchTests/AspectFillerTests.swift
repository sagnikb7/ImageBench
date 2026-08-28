import CoreImage
import XCTest
@testable import ImageBench

final class AspectFillerTests: XCTestCase {
    func testPresetRatios() {
        XCTAssertEqual(AspectPreset.square.ratio(customWidth: 99, customHeight: 1), 1)
        XCTAssertEqual(AspectPreset.portrait.ratio(customWidth: 1, customHeight: 1), 4.0 / 5.0)
        XCTAssertEqual(AspectPreset.story.ratio(customWidth: 1, customHeight: 1), 9.0 / 16.0)
        XCTAssertEqual(AspectPreset.wide.ratio(customWidth: 1, customHeight: 1), 16.0 / 9.0)
        XCTAssertEqual(AspectPreset.instagramTwo.ratio(customWidth: 1, customHeight: 1), 16.0 / 10.0)
        XCTAssertEqual(AspectPreset.instagramThree.ratio(customWidth: 1, customHeight: 1), 12.0 / 5.0)
        XCTAssertEqual(AspectPreset.custom.ratio(customWidth: 3, customHeight: 2), 1.5)
    }

    func testInvalidCustomRatioRemainsPositiveAndFinite() {
        for pair in [(0.0, 0.0), (-4.0, 2.0), (2.0, -4.0), (.infinity, 1.0), (1.0, .nan)] {
            let ratio = AspectPreset.custom.ratio(customWidth: pair.0, customHeight: pair.1)
            XCTAssertTrue(ratio.isFinite)
            XCTAssertGreaterThan(ratio, 0)
        }
    }

    func testEngineRejectsInvalidOrDangerouslyLargeCanvases() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("portrait.png")
        try TestImageFactory.make(at: input, width: 100, height: 2_000)
        XCTAssertThrowsError(try AspectFillerEngine.compose(input: input, targetRatio: 0, style: .black)) { error in
            XCTAssertEqual(error as? AspectFillerError, .invalidTargetRatio)
        }
        XCTAssertThrowsError(try AspectFillerEngine.compose(input: input, targetRatio: 20, style: .blur)) { error in
            XCTAssertEqual(error as? AspectFillerError, .canvasTooLarge)
        }
    }

    func testWideImageExpandsVerticallyForSquare() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("wide.png")
        try TestImageFactory.make(at: input, width: 160, height: 90)
        for style in FillStyle.allCases {
            let result = try AspectFillerEngine.compose(input: input, targetRatio: 1, style: style)
            XCTAssertEqual(result.extent, CGRect(x: 0, y: 0, width: 160, height: 160), style.rawValue)
        }
    }

    func testPortraitImageExpandsHorizontallyForWidescreen() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("portrait.png")
        try TestImageFactory.make(at: input, width: 80, height: 120)
        let result = try AspectFillerEngine.compose(input: input, targetRatio: 16.0 / 9.0, style: .black)
        XCTAssertEqual(result.extent.width, 213)
        XCTAssertEqual(result.extent.height, 120)
    }

    func testWhiteAndBlackFillColorsAreOpaqueAndOriginalIsCentered() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("red-wide.png")
        try TestImageFactory.make(at: input, width: 40, height: 20) { context, rect in
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(rect)
        }

        let white = try ImageRenderer.cgImage(AspectFillerEngine.compose(input: input, targetRatio: 1, style: .white))
        let whiteCorner = try TestImageFactory.pixel(in: white, x: 2, y: 2)
        XCTAssertApproximately(whiteCorner.r, 255)
        XCTAssertApproximately(whiteCorner.g, 255)
        XCTAssertApproximately(whiteCorner.b, 255)
        XCTAssertEqual(whiteCorner.a, 255)

        let black = try ImageRenderer.cgImage(AspectFillerEngine.compose(input: input, targetRatio: 1, style: .black))
        let blackCorner = try TestImageFactory.pixel(in: black, x: 2, y: 2)
        XCTAssertApproximately(blackCorner.r, 0)
        XCTAssertApproximately(blackCorner.g, 0)
        XCTAssertApproximately(blackCorner.b, 0)
        XCTAssertEqual(blackCorner.a, 255)

        let center = try TestImageFactory.pixel(in: black, x: 20, y: 20)
        XCTAssertGreaterThan(center.r, 245)
        // Color-space conversion may introduce a small non-red component; dominance
        // is what proves that the centered foreground survived composition.
        XCTAssertLessThan(center.g, 80)
        XCTAssertLessThan(center.b, 80)
    }

    func testBlurFillRendersOpaqueOutputAtTargetDimensions() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("gradient.png")
        try TestImageFactory.make(at: input, width: 90, height: 160) { context, rect in
            let colors = [CGColor(red: 1, green: 0, blue: 0, alpha: 1), CGColor(red: 0, green: 0, blue: 1, alpha: 1)] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        }
        let composition = try AspectFillerEngine.compose(input: input, targetRatio: 1, style: .blur)
        let rendered = try ImageRenderer.cgImage(composition)
        XCTAssertEqual(rendered.width, 160)
        XCTAssertEqual(rendered.height, 160)
        XCTAssertEqual(try TestImageFactory.pixel(in: rendered, x: 1, y: 1).a, 255)
    }

    func testExportedJPEGHasExpectedDimensions() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        let output = temp.url.appendingPathComponent("filled.jpg")
        try TestImageFactory.make(at: input, width: 100, height: 50)
        let result = try AspectFillerEngine.compose(input: input, targetRatio: 4.0 / 5.0, style: .blur)
        try ImageRenderer.write(result, to: output, type: .jpeg, quality: 0.97)
        XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 100, height: 125))
        XCTAssertGreaterThan(ImageFileSupport.fileSize(output), 0)
    }
}
