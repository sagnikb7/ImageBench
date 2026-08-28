import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

@MainActor
private final class ProgressRecorder {
    var events: [(completed: Int, current: String, log: String)] = []
}

final class CompressorIntegrationTests: XCTestCase {
    func testPPMBridgeHasExactHeaderPayloadAndIsAcceptedByMozjpeg() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("source image.png")
        try TestImageFactory.make(at: input, width: 12, height: 8)
        let ppm = try CompressorEngine.makeCJPEGInput(for: input, in: temp.url)
        let data = try Data(contentsOf: ppm)
        let header = Data("P6\n12 8\n255\n".utf8)
        XCTAssertTrue(data.starts(with: header))
        XCTAssertEqual(data.count, header.count + 12 * 8 * 3)

        let output = temp.url.appendingPathComponent("encoded.jpg")
        let result = try await ProcessRunner.run(
            executable: try TestTools.cjpeg(),
            arguments: [
                "-quality", "82", "-progressive", "-optimize", "-quant-table", "3", "-sample", "2x2", "-outfile", output.path, ppm.path,
            ]
        )
        XCTAssertEqual(result.status, 0, result.error)
        XCTAssertEqual(try TestImageFactory.dimensions(of: output), CGSize(width: 12, height: 8))
    }

    func testTransparentPNGIsFlattenedOntoWhiteBeforeJPEGEncoding() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("transparent.png")
        try TestImageFactory.make(at: input, width: 10, height: 10) { context, _ in
            context.clear(CGRect(x: 0, y: 0, width: 10, height: 10))
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
        }
        let ppm = try CompressorEngine.makeCJPEGInput(for: input, in: temp.url)
        let data = try Data(contentsOf: ppm)
        let header = Data("P6\n10 10\n255\n".utf8)
        XCTAssertTrue(data.starts(with: header))
        XCTAssertEqual(Array(data[header.count..<(header.count + 3)]), [255, 255, 255])
    }

    func testHEICInputCompressesToJPEGWhenSupported() async throws {
        guard TestImageFactory.supportsEncoding(.heic) else { throw XCTSkip("HEIC encoding is unavailable on this Mac") }
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("camera.heic")
        try TestImageFactory.make(at: input, width: 72, height: 54, type: .heic)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let result = try await compress(input: input, outputFolder: temp.url.appendingPathComponent("output"), options: options)
        XCTAssertEqual(result.output.pathExtension, "jpg")
        XCTAssertEqual(try TestImageFactory.dimensions(of: result.output), CGSize(width: 72, height: 54))
    }

    func testAllDocumentedPresetsProduceReadableJPEGs() async throws {
        for preset in [CompressionPreset.archive, .web, .maximum] {
            let temp = try TemporaryDirectory(name: preset.rawValue)
            let input = temp.url.appendingPathComponent("photo.png")
            try TestImageFactory.make(at: input, width: 96, height: 64)
            var options = CompressionOptions()
            options.apply(preset)
            options.removeAllMetadata = true
            let result = try await compress(input: input, outputFolder: temp.url.appendingPathComponent("output"), options: options)
            XCTAssertEqual(result.written, 1, preset.rawValue)
            XCTAssertEqual(try TestImageFactory.dimensions(of: result.output), CGSize(width: 96, height: 64))
            XCTAssertGreaterThan(result.bytes, 0)
        }
    }

    func testProgressAndCommandLogReportEveryFile() async throws {
        let temp = try TemporaryDirectory()
        let inputs = try (1...3).map { index -> URL in
            let url = temp.url.appendingPathComponent("photo \(index)'s.png")
            try TestImageFactory.make(at: url, width: 40 + index, height: 30)
            return url
        }
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let recorder = await MainActor.run { ProgressRecorder() }
        let job = CompressionJob(
            inputs: inputs, outputFolder: temp.url.appendingPathComponent("output"), cjpeg: try TestTools.cjpeg(), exiftool: nil,
            options: options)
        try FileManager.default.createDirectory(at: job.outputFolder, withIntermediateDirectories: true)
        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { completed, current, log in
            recorder.events.append((completed, current, log))
        }
        XCTAssertEqual(result.written, 3)
        let events = await MainActor.run { recorder.events }
        XCTAssertEqual(events.last?.completed, 3)
        XCTAssertEqual(Set(events.filter { $0.log.hasPrefix("'") }.map(\.current)), Set(inputs.map(\.lastPathComponent)))
        XCTAssertTrue(events.contains { $0.log.contains(".ppm") && $0.log.contains("'\\''") })
    }

    func testExistingOutputIsNeverOverwritten() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.png")
        let outputFolder = temp.url.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        try TestImageFactory.make(at: input, width: 50, height: 40)
        let protected = outputFolder.appendingPathComponent("photo.jpg")
        try Data("do not overwrite".utf8).write(to: protected)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        _ = try await compress(input: input, outputFolder: outputFolder, options: options)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFolder.appendingPathComponent("photo_2.jpg").path))
        XCTAssertEqual(try String(contentsOf: protected, encoding: .utf8), "do not overwrite")
    }

    func testFailedEncoderLeavesNoPartialOutput() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("photo.png")
        let output = temp.url.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try TestImageFactory.make(at: input, width: 30, height: 20)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(
            inputs: [input], outputFolder: output, cjpeg: URL(fileURLWithPath: "/usr/bin/false"), exiftool: nil, options: options)
        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
        XCTAssertEqual(result.written, 0)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertTrue(result.failures[0].message.contains("Command failed"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.appendingPathComponent("photo.jpg").path))
    }

    func testBadFileDoesNotAbortRemainingBatch() async throws {
        let temp = try TemporaryDirectory()
        let output = temp.url.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let first = temp.url.appendingPathComponent("first.png")
        let corrupt = temp.url.appendingPathComponent("corrupt.jpg")
        let last = temp.url.appendingPathComponent("last.png")
        try TestImageFactory.make(at: first, width: 30, height: 20)
        try Data("not an image".utf8).write(to: corrupt)
        try TestImageFactory.make(at: last, width: 32, height: 22)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(
            inputs: [first, corrupt, last], outputFolder: output, cjpeg: try TestTools.cjpeg(), exiftool: nil, options: options)

        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }

        XCTAssertEqual(result.written, 2)
        XCTAssertEqual(result.failures.map(\.input), [corrupt])
        XCTAssertEqual(result.skipped, [])
        XCTAssertFalse(result.wasCancelled)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("first.jpg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("last.jpg").path))
    }

    func testCancellationReportsUntouchedInputsAsSkipped() async throws {
        let temp = try TemporaryDirectory()
        let inputs = try (1...3).map { index -> URL in
            let url = temp.url.appendingPathComponent("photo-\(index).png")
            try TestImageFactory.make(at: url, width: 20, height: 20)
            return url
        }
        let output = temp.url.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(inputs: inputs, outputFolder: output, cjpeg: try TestTools.cjpeg(), exiftool: nil, options: options)
        let task = Task {
            await Task.yield()
            return try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
        }
        task.cancel()

        let result = try await task.value

        XCTAssertTrue(result.wasCancelled)
        XCTAssertEqual(result.skipped, inputs)
        XCTAssertEqual(result.processed, 0)
        XCTAssertEqual(result.written, 0)
    }

    func testMetadataIsPreservedWhenNoRemovalIsSelected() async throws {
        let fixture = try await taggedJPEG()
        let result = try await compress(
            input: fixture.input, outputFolder: fixture.temp.url.appendingPathComponent("output"), options: CompressionOptions(),
            exiftool: try TestTools.exiftool())
        let make = try await tag("Make", in: result.output)
        let latitude = try await tag("GPSLatitude", in: result.output)
        XCTAssertEqual(make, "Sony")
        XCTAssertFalse(latitude.isEmpty)
    }

    func testGPSRemovalPreservesOtherEXIF() async throws {
        let fixture = try await taggedJPEG()
        var options = CompressionOptions()
        options.removeGPS = true
        let result = try await compress(
            input: fixture.input, outputFolder: fixture.temp.url.appendingPathComponent("output"), options: options,
            exiftool: try TestTools.exiftool())
        let make = try await tag("Make", in: result.output)
        let latitude = try await tag("GPSLatitude", in: result.output)
        XCTAssertEqual(make, "Sony")
        XCTAssertEqual(latitude, "")
    }

    func testEXIFRemovalRemovesEXIFAndGPS() async throws {
        let fixture = try await taggedJPEG()
        var options = CompressionOptions()
        options.removeEXIF = true
        let result = try await compress(
            input: fixture.input, outputFolder: fixture.temp.url.appendingPathComponent("output"), options: options,
            exiftool: try TestTools.exiftool())
        let make = try await tag("Make", in: result.output)
        let latitude = try await tag("GPSLatitude", in: result.output)
        XCTAssertEqual(make, "")
        XCTAssertEqual(latitude, "")
    }

    func testRemoveAllSkipsMetadataCopy() async throws {
        let fixture = try await taggedJPEG()
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let result = try await compress(
            input: fixture.input, outputFolder: fixture.temp.url.appendingPathComponent("output"), options: options, exiftool: nil)
        let make = try await tag("Make", in: result.output)
        let latitude = try await tag("GPSLatitude", in: result.output)
        XCTAssertEqual(make, "")
        XCTAssertEqual(latitude, "")
    }

    private func compress(
        input: URL,
        outputFolder: URL,
        options: CompressionOptions,
        exiftool: URL? = nil
    ) async throws -> (written: Int, bytes: Int64, output: URL) {
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let job = CompressionJob(
            inputs: [input], outputFolder: outputFolder, cjpeg: try TestTools.cjpeg(), exiftool: exiftool, options: options)
        let result = try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
        let files = try FileManager.default.contentsOfDirectory(at: outputFolder, includingPropertiesForKeys: nil).filter {
            $0.pathExtension.lowercased() == "jpg"
        }
        return (result.written, result.bytes, try XCTUnwrap(files.first))
    }

    private func taggedJPEG() async throws -> (temp: TemporaryDirectory, input: URL) {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Sony sample.jpg")
        try TestImageFactory.make(at: input, width: 80, height: 60, type: .jpeg)
        let result = try await ProcessRunner.run(
            executable: try TestTools.exiftool(),
            arguments: [
                "-overwrite_original", "-Make=Sony", "-GPSLatitude=22.5726", "-GPSLatitudeRef=N", "-GPSLongitude=88.3639",
                "-GPSLongitudeRef=E", input.path,
            ]
        )
        XCTAssertEqual(result.status, 0, result.error)
        return (temp, input)
    }

    private func tag(_ name: String, in file: URL) async throws -> String {
        let result = try await ProcessRunner.run(
            executable: try TestTools.exiftool(), arguments: ["-s", "-s", "-s", "-\(name)", file.path])
        XCTAssertEqual(result.status, 0, result.error)
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
