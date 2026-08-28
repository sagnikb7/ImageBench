import CoreImage
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class ImageRendererTests: XCTestCase {
    func testThumbnailBoundsLargeSourcesWithoutChangingAspectRatio() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("large.png")
        try TestImageFactory.make(at: input, width: 1_200, height: 600)

        let thumbnail = try ImageRenderer.thumbnail(at: input, maxPixelSize: 240)

        XCTAssertEqual(thumbnail.size.width, 240)
        XCTAssertEqual(thumbnail.size.height, 120)
    }

    func testNormalizedImageStartsAtZero() throws {
        let translated = CIImage(color: .red).cropped(to: CGRect(x: 25, y: 40, width: 30, height: 20))
        let normalized = translated.transformed(by: .init(translationX: -translated.extent.minX, y: -translated.extent.minY))
        XCTAssertEqual(normalized.extent, CGRect(x: 0, y: 0, width: 30, height: 20))
        XCTAssertEqual(try ImageRenderer.cgImage(normalized).width, 30)
    }

    func testPreviewRespectsMaximumDimension() throws {
        let image = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 2000, height: 1000))
        let preview = try ImageRenderer.preview(image, maxDimension: 500)
        XCTAssertEqual(preview.size.width, 500)
        XCTAssertEqual(preview.size.height, 250)
    }

    func testWritesReadablePNGAndJPEG() throws {
        let temp = try TemporaryDirectory()
        let image = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 48))
        for (name, type) in [("output.png", UTType.png), ("output.jpg", UTType.jpeg)] {
            let output = temp.url.appendingPathComponent(name)
            try ImageRenderer.write(image, to: output, type: type)
            XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 64, height: 48))
            XCTAssertGreaterThan(ImageFileSupport.fileSize(output), 0)
        }
    }

    func testUnreadableInputThrowsDecodeError() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("broken.jpg")
        try Data("not an image".utf8).write(to: input)
        XCTAssertThrowsError(try ImageRenderer.normalizedImage(at: input)) { error in
            XCTAssertEqual(error as? ImageRendererError, .decode)
        }
    }

    func testAtomicWriteRejectsTheOriginalInputPath() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("original.png")
        try TestImageFactory.make(at: input, width: 20, height: 10)
        let originalData = try Data(contentsOf: input)
        let image = try ImageRenderer.normalizedImage(at: input)

        XCTAssertThrowsError(
            try ImageRenderer.writeAtomically(image, to: input, type: .png, protecting: input)
        ) { error in
            XCTAssertEqual(error as? ImageRendererError, .sourceDestinationConflict)
        }
        XCTAssertEqual(try Data(contentsOf: input), originalData)
    }

    func testAtomicWriteReplacesAnExistingOutputWithoutChangingSource() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("original.png")
        let output = temp.url.appendingPathComponent("copy.png")
        try TestImageFactory.make(at: input, width: 24, height: 12)
        try Data("old output".utf8).write(to: output)
        let originalData = try Data(contentsOf: input)

        try ImageRenderer.writeAtomically(
            try ImageRenderer.normalizedImage(at: input),
            to: output,
            type: .png,
            protecting: input
        )

        XCTAssertEqual(try Data(contentsOf: input), originalData)
        XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 24, height: 12))
    }
}
