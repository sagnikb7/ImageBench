import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class CompressorBattleTests: XCTestCase {
    func testSixFormatDirectoryScansAndCompressesEveryImage() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Mixed Camera Roll")
        let output = temp.url.appendingPathComponent("Compressed")
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures: [(String, UTType)] = [
            ("camera.JPG", .jpeg),
            ("portrait.jpeg", .jpeg),
            ("transparent.png", .png),
            ("scan.tiff", .tiff),
            ("legacy.bmp", .bmp),
            ("single-frame.gif", .gif),
        ]
        for (name, type) in fixtures {
            try TestImageFactory.make(at: input.appendingPathComponent(name), width: 48, height: 32, type: type)
        }

        let scanned = try CompressionInputScanner.scan(folder: input)
        let result = try await compress(inputs: scanned, outputFolder: output)

        XCTAssertEqual(scanned.count, 6)
        XCTAssertEqual(result.written, 6)
        XCTAssertEqual(result.failures, [])
        XCTAssertEqual(result.skipped, [])
        let outputs = try jpegFiles(in: output)
        XCTAssertEqual(outputs.count, 6)
        for file in outputs {
            XCTAssertEqual(try TestImageFactory.dimensions(of: file), CGSize(width: 48, height: 32), file.lastPathComponent)
        }
    }

    func testTextDocumentsAndUnsupportedMediaAreIgnoredBesideImages() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Messy Project Folder")
        let output = temp.url.appendingPathComponent("Output")
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        for name in ["notes.txt", "README.md", "settings.json", "vector.svg", "document.pdf", "clip.mov", "archive.zip"] {
            try Data("not an image".utf8).write(to: input.appendingPathComponent(name))
        }
        for (name, type) in [("one.jpg", UTType.jpeg), ("two.png", .png), ("three.tif", .tiff)] {
            try TestImageFactory.make(at: input.appendingPathComponent(name), width: 36, height: 24, type: type)
        }

        let scanned = try CompressionInputScanner.scan(folder: input)
        let result = try await compress(inputs: scanned, outputFolder: output)

        XCTAssertEqual(scanned.map(\.lastPathComponent), ["one.jpg", "three.tif", "two.png"])
        XCTAssertEqual(result.written, 3)
        XCTAssertEqual(result.failures, [])
        XCTAssertEqual(try jpegFiles(in: output).count, 3)
    }

    func testCorruptSupportedFilesAreReportedWhileHealthyFilesContinue() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Partially Damaged")
        let output = temp.url.appendingPathComponent("Output")
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        let healthyOne = input.appendingPathComponent("before.png")
        let corruptJPEG = input.appendingPathComponent("looks-valid.jpg")
        let corruptWebP = input.appendingPathComponent("broken.webp")
        let healthyTwo = input.appendingPathComponent("after.tiff")
        try TestImageFactory.make(at: healthyOne, width: 30, height: 20, type: .png)
        try Data("plain text with a jpeg extension".utf8).write(to: corruptJPEG)
        try Data().write(to: corruptWebP)
        try TestImageFactory.make(at: healthyTwo, width: 31, height: 21, type: .tiff)

        let scanned = try CompressionInputScanner.scan(folder: input)
        let result = try await compress(inputs: scanned, outputFolder: output)

        XCTAssertEqual(scanned.count, 4)
        XCTAssertEqual(result.written, 2)
        XCTAssertEqual(Set(result.failures.map { $0.input.lastPathComponent }), Set(["looks-valid.jpg", "broken.webp"]))
        XCTAssertTrue(result.failures.allSatisfy { $0.message.contains("Could not decode") })
        XCTAssertEqual(result.skipped, [])
        XCTAssertEqual(try jpegFiles(in: output).count, 2)
    }

    func testNestedFoldersUnicodeQuotesAndDuplicateStemsRemainCollisionSafe() async throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Family Library")
        let output = input.appendingPathComponent("ImageBench Output")
        let firstAlbum = input.appendingPathComponent("Album A")
        let secondAlbum = input.appendingPathComponent("Album B")
        try FileManager.default.createDirectory(at: firstAlbum, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondAlbum, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let first = firstAlbum.appendingPathComponent("Sam's 여행 photo.png")
        let second = secondAlbum.appendingPathComponent("Sam's 여행 photo.jpg")
        try TestImageFactory.make(at: first, width: 42, height: 28, type: .png)
        try TestImageFactory.make(at: second, width: 42, height: 28, type: .jpeg)
        try TestImageFactory.make(at: output.appendingPathComponent("old-result.jpg"), width: 10, height: 10, type: .jpeg)

        let scanned = try CompressionInputScanner.scan(folder: input, excluding: [output])
        let result = try await compress(inputs: scanned, outputFolder: output)

        XCTAssertEqual(scanned.count, 2)
        XCTAssertEqual(result.written, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("Sam's 여행 photo.jpg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("Sam's 여행 photo_2.jpg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("old-result.jpg").path))
    }

    func testUppercaseHEICAndHEIFAreHandledWhenEncoderIsAvailable() async throws {
        let writableTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        guard writableTypes.contains(UTType.heic.identifier) else { throw XCTSkip("HEIC encoding is unavailable on this Mac") }
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("Apple Photos")
        let output = temp.url.appendingPathComponent("Output")
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        try TestImageFactory.make(at: input.appendingPathComponent("IMG_0001.HEIC"), width: 44, height: 33, type: .heic)
        try TestImageFactory.make(at: input.appendingPathComponent("IMG_0002.HEIF"), width: 45, height: 34, type: .heic)

        let result = try await compress(inputs: CompressionInputScanner.scan(folder: input), outputFolder: output)

        XCTAssertEqual(result.written, 2)
        XCTAssertEqual(result.failures, [])
        XCTAssertEqual(try jpegFiles(in: output).count, 2)
    }

    private func compress(inputs: [URL], outputFolder: URL) async throws -> CompressionBatchResult {
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        var options = CompressionOptions()
        options.removeAllMetadata = true
        let job = CompressionJob(inputs: inputs, outputFolder: outputFolder, cjpeg: try TestTools.cjpeg(), exiftool: nil, options: options)
        _ = try CompressionPreflight.run(job: job)
        return try await CompressorEngine.run(job: job, runner: CancellableProcessRunner()) { _, _, _ in }
    }

    private func jpegFiles(in folder: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "jpg" }
    }
}
