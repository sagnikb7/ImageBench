import Foundation
import XCTest
@testable import ImageBench

final class CompressorScaleTests: XCTestCase {
    func testScannerHandlesTwelveHundredImages() async throws {
        let temp = try TemporaryDirectory()
        for index in 0..<1_200 {
            let folder = temp.url.appendingPathComponent("album-\(index / 100)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("photo-\(index).jpg")
            XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: Data([0xFF, 0xD8, 0xFF, 0xD9])))
        }

        let start = ContinuousClock.now
        let files = try CompressionInputScanner.scan(folder: temp.url)
        let elapsed = start.duration(to: .now)

        XCTAssertEqual(files.count, 1_200)
        print("ImageBench scale: scanned 1,200 files in \(elapsed)")
    }

    func testOptInTwoHundredImageCompressionBenchmark() async throws {
        guard ProcessInfo.processInfo.environment["IMAGEBENCH_RUN_BENCHMARKS"] == "1" else {
            throw XCTSkip("Set IMAGEBENCH_RUN_BENCHMARKS=1 to run the subprocess benchmark.")
        }
        let temp = try TemporaryDirectory()
        let output = temp.url.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let inputs = try (0..<200).map { index -> URL in
            let file = temp.url.appendingPathComponent("photo-\(index).png")
            try TestImageFactory.make(at: file, width: 64, height: 48)
            return file
        }
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(inputs: inputs, outputFolder: output, cjpeg: try TestTools.cjpeg(), exiftool: nil, options: options)

        let start = ContinuousClock.now
        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
        let elapsed = start.duration(to: .now)

        XCTAssertEqual(result.written, 200)
        XCTAssertEqual(result.failures, [])
        print("ImageBench benchmark: compressed 200 images in \(elapsed)")
    }
}
