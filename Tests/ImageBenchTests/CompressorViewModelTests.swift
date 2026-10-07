import Foundation
import XCTest
@testable import ImageBench

@MainActor
final class CompressorViewModelTests: XCTestCase {
    func testCustomQualityUsesFivePointStepsAcrossZeroToOneHundred() {
        let model = CompressorViewModel()
        model.options.quality = 82

        model.selectPreset(.custom)
        XCTAssertEqual(model.options.quality, 80)

        model.setCustomQuality(88)
        XCTAssertEqual(model.options.quality, 90)
        model.setCustomQuality(-10)
        XCTAssertEqual(model.options.quality, 0)
        model.setCustomQuality(120)
        XCTAssertEqual(model.options.quality, 100)
    }

    func testSelectingInputAssignsLazyCompressedOutputFolder() throws {
        let temp = try TemporaryDirectory()
        let expectedOutput = temp.url.appendingPathComponent("compressed_output", isDirectory: true)
        let model = CompressorViewModel()
        defer { model.cancel() }

        model.selectInputFolder(temp.url)

        XCTAssertEqual(model.outputFolder?.standardizedFileURL, expectedOutput.standardizedFileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedOutput.path))
    }

    func testSelectingAnotherInputPreservesExplicitOutputFolder() throws {
        let temp = try TemporaryDirectory()
        let explicitOutput = temp.url.appendingPathComponent("Chosen Destination", isDirectory: true)
        let input = temp.url.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        let model = CompressorViewModel()
        defer { model.cancel() }
        model.selectOutputFolder(explicitOutput)

        model.selectInputFolder(input)

        XCTAssertEqual(model.outputFolder?.standardizedFileURL, explicitOutput.standardizedFileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: explicitOutput.path))
    }

    func testChangingInputMovesTheAutomaticOutputUntilUserChoosesOne() throws {
        let temp = try TemporaryDirectory()
        let firstInput = temp.url.appendingPathComponent("First", isDirectory: true)
        let secondInput = temp.url.appendingPathComponent("Second", isDirectory: true)
        try FileManager.default.createDirectory(at: firstInput, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondInput, withIntermediateDirectories: true)
        let model = CompressorViewModel()
        defer { model.cancel() }

        model.selectInputFolder(firstInput)
        model.selectInputFolder(secondInput)

        let expectedOutput = secondInput.appendingPathComponent("compressed_output", isDirectory: true)
        XCTAssertEqual(model.outputFolder?.standardizedFileURL, expectedOutput.standardizedFileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedOutput.path))
    }

    func testAutomaticFolderSkipsExistingFilesAndDirectories() throws {
        let temp = try TemporaryDirectory()
        try Data("keep".utf8).write(to: temp.url.appendingPathComponent("compressed_output"))
        try FileManager.default.createDirectory(
            at: temp.url.appendingPathComponent("compressed_output_1"), withIntermediateDirectories: false)
        let reserved = try CompressionOutputDirectory.reserve(in: temp.url)
        XCTAssertEqual(reserved.lastPathComponent, "compressed_output_2")
        XCTAssertTrue(CompressionOutputDirectory.isMarked(reserved))
        XCTAssertEqual(try Data(contentsOf: temp.url.appendingPathComponent("compressed_output")), Data("keep".utf8))
    }

    func testExplicitDestinationIsReusedWithoutMarkingSourceFolders() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        try TestImageFactory.make(at: input, width: 32, height: 24)
        let model = CompressorViewModel()
        model.acceptDropped([input])
        model.selectOutputFolder(temp.url)
        model.options.removeAllMetadata = true
        for _ in 0..<2 {
            model.start(cjpeg: try TestTools.cjpeg(), exiftool: nil)
            try await waitUntilIdle(model)
            XCTAssertEqual(model.batchResult?.written, 1)
            XCTAssertEqual(model.batchResult?.failures.count, 0)
            XCTAssertEqual(model.outputFolder, temp.url)
            XCTAssertFalse(CompressionOutputDirectory.isMarked(temp.url))
        }
    }

    func testLegacyOutputIsExcludedFromInputSelection() async throws {
        let temp = try TemporaryDirectory()
        let oldOutput = temp.url.appendingPathComponent("Compressed Output")
        try FileManager.default.createDirectory(at: oldOutput, withIntermediateDirectories: false)
        try Data().write(to: oldOutput.appendingPathComponent("old.jpg"))
        let input = temp.url.appendingPathComponent("original.jpg")
        try Data().write(to: input)
        let model = CompressorViewModel()
        model.selectInputFolder(temp.url)
        try await waitUntilIdle(model)
        XCTAssertEqual(model.images.map(\.standardizedFileURL), [input.standardizedFileURL])
    }

    func testFailedPreflightRemovesAutomaticReservation() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.jpg")
        try Data().write(to: input)
        let model = CompressorViewModel()
        model.acceptDropped([input])
        model.start(cjpeg: temp.url.appendingPathComponent("missing-encoder"), exiftool: nil)
        XCTAssertFalse(model.isRunning)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent("compressed_output").path))
        XCTAssertFalse(model.resultMessage.isEmpty)
    }

    func testRepeatedExportsReserveSeparateMarkedFolders() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        try TestImageFactory.make(at: input, width: 32, height: 24)
        let originalBytes = try Data(contentsOf: input)
        let model = CompressorViewModel()
        defer { model.cancel() }
        model.acceptDropped([input])
        model.options.removeAllMetadata = true
        var outputs: [URL: Data] = [:]
        for name in ["compressed_output", "compressed_output_1", "compressed_output_2"] {
            model.start(cjpeg: try TestTools.cjpeg(), exiftool: nil)
            try await waitUntilIdle(model)
            XCTAssertEqual(model.batchResult?.written, 1)
            XCTAssertEqual(model.batchResult?.failures.count, 0)
            let folder = try XCTUnwrap(model.outputFolder)
            XCTAssertEqual(folder.lastPathComponent, name)
            XCTAssertTrue(CompressionOutputDirectory.isMarked(folder))
            let output = try XCTUnwrap(model.batchResult?.successes.first?.output)
            XCTAssertEqual(output.deletingLastPathComponent(), folder)
            XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 32, height: 24))
            for (previous, bytes) in outputs { XCTAssertEqual(try Data(contentsOf: previous), bytes) }
            outputs[output] = try Data(contentsOf: output)
            XCTAssertEqual(try Data(contentsOf: input), originalBytes)
        }
        // A fresh model represents reopening the tool, with no remembered output path.
        let reopened = CompressorViewModel()
        defer { reopened.cancel() }
        reopened.selectInputFolder(temp.url)
        try await waitUntilIdle(reopened)
        XCTAssertEqual(reopened.images.map(\.standardizedFileURL), [input.standardizedFileURL])
        XCTAssertEqual(reopened.outputFolder?.lastPathComponent, "compressed_output_3")
    }

    private func waitUntilIdle(_ model: CompressorViewModel) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(15))
        while model.isRunning || model.isScanning {
            guard ContinuousClock.now < deadline else {
                model.cancel()
                throw NSError(domain: "CompressorViewModelTests.timeout", code: 1)
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func testCompletedBatchReportsComparableBeforeAfterSavings() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        let output = temp.url.appendingPathComponent("source.jpg")
        try Data(repeating: 7, count: 100).write(to: input)
        let model = CompressorViewModel()
        model.batchResult = CompressionBatchResult(
            successes: [CompressionSuccess(input: input, output: output, bytes: 80)]
        )

        XCTAssertEqual(model.inputBytesForLastRun, 100)
        XCTAssertEqual(model.outputBytesForLastRun, 80)
        XCTAssertEqual(model.sizeChangeBytes, 20)
        XCTAssertEqual(model.sizeChangePercentage, 20)
    }

    func testCompletedBatchReportsSignedSizeIncrease() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source.png")
        let output = temp.url.appendingPathComponent("source.jpg")
        try Data(repeating: 7, count: 100).write(to: input)
        let model = CompressorViewModel()
        model.batchResult = CompressionBatchResult(
            successes: [CompressionSuccess(input: input, output: output, bytes: 125)]
        )

        XCTAssertEqual(model.sizeChangeBytes, -25)
        XCTAssertEqual(model.sizeChangePercentage, -25)
    }
}
