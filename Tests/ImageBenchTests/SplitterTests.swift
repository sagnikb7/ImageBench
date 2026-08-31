import XCTest
import UniformTypeIdentifiers
import ImageIO
@testable import ImageBench

final class SplitterTests: XCTestCase {
    func testPartDimensionsMatchRemainderDistributionAndDescribeSourceRatio() throws {
        let source = try XCTUnwrap(ImageDimensions(width: 101, height: 60))

        let columns = try SplitterEngine.partDimensions(source: source, orientation: .vertical, count: 3)
        let rows = try SplitterEngine.partDimensions(source: source, orientation: .horizontal, count: 4)

        XCTAssertEqual(source.summary, "101 × 60 px • 101:60 • 1.68")
        XCTAssertEqual(columns.map(\.width), [33, 34, 34])
        XCTAssertTrue(columns.allSatisfy { $0.height == 60 })
        XCTAssertEqual(rows.map(\.height), [15, 15, 15, 15])
        XCTAssertTrue(rows.allSatisfy { $0.width == 101 })
    }

    func testVerticalSplitDistributesRemainderWithoutLosingPixels() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("uneven.png")
        let output = temp.url.appendingPathComponent("parts")
        try TestImageFactory.make(at: input, width: 101, height: 60)
        let results = try SplitterEngine.split(input: input, outputFolder: output, orientation: .vertical, count: 3)
        let dimensions = try results.map(TestImageFactory.dimensions)
        XCTAssertEqual(dimensions.map { Int($0.width) }, [33, 34, 34])
        XCTAssertEqual(dimensions.reduce(0) { $0 + Int($1.width) }, 101)
        XCTAssertTrue(dimensions.allSatisfy { $0.height == 60 })
        XCTAssertEqual(results.map(\.lastPathComponent), ["uneven_part_01.png", "uneven_part_02.png", "uneven_part_03.png"])
    }

    func testHorizontalPartsAreNamedTopToBottom() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("striped.png")
        let output = temp.url.appendingPathComponent("parts")
        try TestImageFactory.make(at: input, width: 40, height: 40) { context, _ in
            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 0, y: 20, width: 40, height: 20))
        }
        let results = try SplitterEngine.split(input: input, outputFolder: output, orientation: .horizontal, count: 2)
        let first = try ImageRenderer.cgImage(ImageRenderer.normalizedImage(at: results[0]))
        let second = try ImageRenderer.cgImage(ImageRenderer.normalizedImage(at: results[1]))
        let firstPixel = try TestImageFactory.pixel(in: first, x: 10, y: 10)
        let secondPixel = try TestImageFactory.pixel(in: second, x: 10, y: 10)
        XCTAssertGreaterThan(firstPixel.r, 245)
        XCTAssertLessThan(firstPixel.b, 10)
        XCTAssertGreaterThan(secondPixel.b, 245)
        XCTAssertLessThan(secondPixel.r, 10)
    }

    func testRejectsCountsThatCannotProduceNonEmptySlices() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("tiny.png")
        try TestImageFactory.make(at: input, width: 3, height: 2)
        XCTAssertThrowsError(try SplitterEngine.split(input: input, outputFolder: temp.url, orientation: .vertical, count: 4)) { error in
            XCTAssertEqual(error as? SplitterError, .invalidSliceCount(requested: 4, availablePixels: 3))
        }
        XCTAssertThrowsError(try SplitterEngine.split(input: input, outputFolder: temp.url, orientation: .horizontal, count: 1)) { error in
            XCTAssertEqual(error as? SplitterError, .invalidSliceCount(requested: 1, availablePixels: 2))
        }
    }

    func testRejectsFormatsItCannotPreserveInsteadOfWritingMismatchedData() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("scan.tiff")
        try TestImageFactory.make(at: input, width: 30, height: 20, type: .tiff)

        XCTAssertThrowsError(
            try SplitterEngine.split(
                input: input,
                outputFolder: temp.url.appendingPathComponent("parts"),
                orientation: .vertical,
                count: 2
            )
        ) { error in
            XCTAssertEqual(error as? SplitterError, .unsupportedOutputFormat("tiff"))
        }
    }

    func testExistingPartsAreNotOverwritten() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.png")
        let output = temp.url.appendingPathComponent("parts")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try TestImageFactory.make(at: input, width: 60, height: 40)
        let protected = output.appendingPathComponent("photo_part_01.png")
        try Data("protected".utf8).write(to: protected)
        let results = try SplitterEngine.split(input: input, outputFolder: output, orientation: .vertical, count: 2)
        XCTAssertEqual(results[0].lastPathComponent, "photo_part_01_2.png")
        XCTAssertEqual(try String(contentsOf: protected, encoding: .utf8), "protected")
    }

    func testJPEGAndPNGOutputsPreserveOriginalFileType() throws {
        for (extensionName, type) in [("jpg", UTType.jpeg), ("png", UTType.png)] {
            let temp = try TemporaryDirectory(name: extensionName)
            let input = temp.url.appendingPathComponent("source.\(extensionName)")
            try TestImageFactory.make(at: input, width: 80, height: 50, type: type)
            let results = try SplitterEngine.split(
                input: input, outputFolder: temp.url.appendingPathComponent("parts"), orientation: .vertical, count: 2)
            XCTAssertTrue(results.allSatisfy { $0.pathExtension == extensionName })
            XCTAssertTrue(results.allSatisfy { ImageFileSupport.fileSize($0) > 0 })
        }
    }

    func testHEICOutputPreservesOriginalFileTypeWhenSupported() throws {
        guard TestImageFactory.supportsEncoding(.heic) else { throw XCTSkip("HEIC encoding is unavailable on this Mac") }
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.heic")
        try TestImageFactory.make(at: input, width: 80, height: 60, type: .heic)
        let results = try SplitterEngine.split(
            input: input, outputFolder: temp.url.appendingPathComponent("parts"), orientation: .vertical, count: 2)
        XCTAssertTrue(results.allSatisfy { $0.pathExtension == "heic" })
        XCTAssertEqual(
            try results.map { try TestImageFactory.dimensions(of: $0) }, [CGSize(width: 40, height: 60), CGSize(width: 40, height: 60)])
    }

    func testTwelveSliceLimitAndNumbering() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("large.png")
        try TestImageFactory.make(at: input, width: 100, height: 10)
        let results = try SplitterEngine.split(
            input: input, outputFolder: temp.url.appendingPathComponent("parts"), orientation: .vertical, count: 12)
        XCTAssertEqual(results.first?.lastPathComponent, "large_part_01.png")
        XCTAssertEqual(results.last?.lastPathComponent, "large_part_12.png")

        XCTAssertThrowsError(
            try SplitterEngine.split(
                input: input,
                outputFolder: temp.url.appendingPathComponent("too-many-parts"),
                orientation: .vertical,
                count: 13
            )
        ) { error in
            XCTAssertEqual(error as? SplitterError, .sliceLimitExceeded(requested: 13, maximum: 12))
        }
    }
}
