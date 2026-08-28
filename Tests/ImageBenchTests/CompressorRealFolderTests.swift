import Foundation
import XCTest
@testable import ImageBench

final class CompressorRealFolderTests: XCTestCase {
    func testOptInRealFolderCompression() async throws {
        guard let path = ProcessInfo.processInfo.environment["IMAGEBENCH_REAL_FOLDER"], !path.isEmpty else {
            throw XCTSkip("Set IMAGEBENCH_REAL_FOLDER to run the private-library diagnostic.")
        }

        let inputFolder = URL(fileURLWithPath: path, isDirectory: true)
        let inputs = try CompressionInputScanner.scan(folder: inputFolder)
        XCTAssertFalse(inputs.isEmpty, "The selected folder contains no supported images.")

        let temp = try TemporaryDirectory()
        let output = temp.url.appendingPathComponent("Compressed Output")
        var options = CompressionOptions()
        options.apply(.web)
        let job = CompressionJob(
            inputs: inputs,
            outputFolder: output,
            cjpeg: try TestTools.cjpeg(),
            exiftool: try TestTools.exiftool(),
            options: options
        )

        _ = try CompressionPreflight.run(job: job)
        let start = ContinuousClock.now
        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
        let elapsed = start.duration(to: .now)

        let failures = result.failures.map { "\($0.input.lastPathComponent): \($0.message)" }.joined(separator: "\n")
        XCTAssertEqual(result.written, inputs.count, failures)
        XCTAssertEqual(result.failures, [], failures)
        XCTAssertEqual(result.skipped, [])
        XCTAssertFalse(result.wasCancelled)
        print("ImageBench real-folder diagnostic: compressed \(result.written) images in \(elapsed)")
    }
}
