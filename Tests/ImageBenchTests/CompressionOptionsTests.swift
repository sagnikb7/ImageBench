import XCTest
@testable import ImageBench

final class CompressionOptionsTests: XCTestCase {
    func testArchivePresetMatchesDocumentedMozjpegArguments() {
        var options = CompressionOptions()
        options.apply(.archive)
        XCTAssertEqual(options.cjpegArguments, ["-quality", "82", "-progressive", "-optimize", "-quant-table", "3", "-sample", "2x2"])
    }

    func testWebPresetMatchesDocumentedMozjpegArguments() {
        var options = CompressionOptions()
        options.apply(.web)
        XCTAssertEqual(options.cjpegArguments, ["-quality", "75", "-progressive", "-optimize"])
    }

    func testMaximumPresetMatchesDocumentedMozjpegArguments() {
        var options = CompressionOptions()
        options.apply(.maximum)
        XCTAssertEqual(options.cjpegArguments, ["-quality", "60", "-progressive", "-optimize", "-sample", "2x2"])
    }

    func testCustomArgumentsOmitDisabledOptions() {
        var options = CompressionOptions()
        options.quality = 91
        options.progressive = false
        options.optimize = false
        options.quantTable = 0
        options.sampling = ""
        XCTAssertEqual(options.cjpegArguments, ["-quality", "91"])
    }

    func testSelectingCustomDoesNotDestroyCurrentValues() {
        var options = CompressionOptions(quality: 67, progressive: false, optimize: false, quantTable: 7, sampling: "1x1")
        options.apply(.custom)
        XCTAssertEqual(options.cjpegArguments, ["-quality", "67", "-quant-table", "7", "-sample", "1x1"])
    }
}
