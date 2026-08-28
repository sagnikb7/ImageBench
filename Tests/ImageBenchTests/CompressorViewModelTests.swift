import Foundation
import XCTest
@testable import ImageBench

@MainActor
final class CompressorViewModelTests: XCTestCase {
    func testSelectingInputAssignsLazyCompressedOutputFolder() throws {
        let temp = try TemporaryDirectory()
        let expectedOutput = temp.url.appendingPathComponent("Compressed Output", isDirectory: true)
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

        let expectedOutput = secondInput.appendingPathComponent("Compressed Output", isDirectory: true)
        XCTAssertEqual(model.outputFolder?.standardizedFileURL, expectedOutput.standardizedFileURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedOutput.path))
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
