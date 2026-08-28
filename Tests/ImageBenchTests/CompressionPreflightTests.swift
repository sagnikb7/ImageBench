import Foundation
import XCTest
@testable import ImageBench

final class CompressionPreflightTests: XCTestCase {
    func testOutputEstimateIncludesInputsAndSafetyMargin() throws {
        let temp = try TemporaryDirectory()
        let first = temp.url.appendingPathComponent("first.jpg")
        let second = temp.url.appendingPathComponent("second.jpg")
        try Data(repeating: 1, count: 11).write(to: first)
        try Data(repeating: 2, count: 17).write(to: second)
        XCTAssertEqual(
            CompressionPreflight.estimatedOutputBytes(for: [first, second]),
            CompressionPreflight.safetyMargin + 28
        )
    }

    func testTemporaryEstimateUsesLargestDecodedImage() throws {
        let temp = try TemporaryDirectory()
        let small = temp.url.appendingPathComponent("small.png")
        let large = temp.url.appendingPathComponent("large.png")
        try TestImageFactory.make(at: small, width: 10, height: 10)
        try TestImageFactory.make(at: large, width: 40, height: 20)
        XCTAssertEqual(
            CompressionPreflight.estimatedTemporaryBytes(for: [small, large]),
            CompressionPreflight.safetyMargin + 40 * 20 * 3
        )
    }

    func testCapacityValidationReportsOutputShortfall() {
        XCTAssertThrowsError(try CompressionPreflight.validateCapacity(required: 1_000, available: 999, temporary: false)) { error in
            XCTAssertEqual(error as? CompressionPreflightError, .insufficientOutputSpace(required: 1_000, available: 999))
        }
    }

    func testCapacityValidationReportsTemporaryShortfall() {
        XCTAssertThrowsError(try CompressionPreflight.validateCapacity(required: 2_000, available: 1_000, temporary: true)) { error in
            XCTAssertEqual(error as? CompressionPreflightError, .insufficientTemporarySpace(required: 2_000, available: 1_000))
        }
    }

    func testUnknownCapacityDoesNotBlockWork() {
        XCTAssertNoThrow(try CompressionPreflight.validateCapacity(required: .max, available: nil, temporary: false))
    }

    func testRunCreatesOutputAndRemovesWriteProbe() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.png")
        let output = temp.url.appendingPathComponent("nested/output")
        try TestImageFactory.make(at: input, width: 24, height: 16)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(inputs: [input], outputFolder: output, cjpeg: try TestTools.cjpeg(), exiftool: nil, options: options)

        let report = try CompressionPreflight.run(job: job)

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertGreaterThan(report.estimatedOutputBytes, 0)
        let names = try FileManager.default.contentsOfDirectory(atPath: output.path)
        XCTAssertFalse(names.contains { $0.hasPrefix(".imagebench-write-test-") })
    }

    func testRunRejectsMissingExifToolWhenMetadataMustBeCopied() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.png")
        try TestImageFactory.make(at: input, width: 20, height: 20)
        let job = CompressionJob(
            inputs: [input], outputFolder: temp.url.appendingPathComponent("output"), cjpeg: try TestTools.cjpeg(), exiftool: nil,
            options: CompressionOptions())
        XCTAssertThrowsError(try CompressionPreflight.run(job: job)) { error in
            XCTAssertEqual(error as? CompressionPreflightError, .exiftoolRequired)
        }
    }
}
