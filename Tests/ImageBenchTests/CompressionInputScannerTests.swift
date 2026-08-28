import Foundation
import XCTest
@testable import ImageBench

final class CompressionInputScannerTests: XCTestCase {
    func testRecursivelyFindsSupportedImagesAndSortsNaturally() throws {
        let temp = try TemporaryDirectory()
        let nested = temp.url.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        for relative in [
            "photo10.JPG", "photo2.jpeg", "Nested/photo1.PNG", "Nested/camera.HEIC", "Nested/scan.TIFF", "Nested/icon.BMP",
            "Nested/animation.GIF", "Nested/modern.WEBP",
        ] {
            let file = temp.url.appendingPathComponent(relative)
            try Data("fixture".utf8).write(to: file)
        }
        try Data("ignored".utf8).write(to: temp.url.appendingPathComponent("notes.txt"))

        let results = try CompressionInputScanner.scan(folder: temp.url)
        XCTAssertEqual(results.count, 8)
        XCTAssertEqual(
            Set(results.map { $0.pathExtension.lowercased() }), Set(["jpg", "jpeg", "png", "heic", "tiff", "bmp", "gif", "webp"]))
        let root = temp.url.standardizedFileURL
        let topLevelNames = results.filter { $0.deletingLastPathComponent().standardizedFileURL == root }.map(\.lastPathComponent)
        XCTAssertEqual(topLevelNames, ["photo2.jpeg", "photo10.JPG"])
    }

    func testSkipsHiddenFilesAndPackageDescendants() throws {
        let temp = try TemporaryDirectory()
        try Data("hidden".utf8).write(to: temp.url.appendingPathComponent(".secret.jpg"))
        let package = temp.url.appendingPathComponent("Library.photoslibrary")
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        try Data("inside package".utf8).write(to: package.appendingPathComponent("inside.jpg"))
        let visible = temp.url.appendingPathComponent("visible.jpg")
        try Data("visible".utf8).write(to: visible)
        XCTAssertEqual(try CompressionInputScanner.scan(folder: temp.url).map(\.standardizedFileURL), [visible.standardizedFileURL])
    }

    func testExcludesOutputFolderAndAllDescendants() throws {
        let temp = try TemporaryDirectory()
        let input = temp.url.appendingPathComponent("input.jpg")
        let output = temp.url.appendingPathComponent("ImageBench Output")
        try FileManager.default.createDirectory(at: output.appendingPathComponent("nested"), withIntermediateDirectories: true)
        try Data().write(to: input)
        try Data().write(to: output.appendingPathComponent("old-output.jpg"))
        try Data().write(to: output.appendingPathComponent("nested/another.jpg"))
        XCTAssertEqual(
            try CompressionInputScanner.scan(folder: temp.url, excluding: [output]).map(\.standardizedFileURL), [input.standardizedFileURL])
    }

    func testCancellationIsObservedBeforeWalkingLargeTree() async throws {
        let temp = try TemporaryDirectory()
        try Data().write(to: temp.url.appendingPathComponent("image.jpg"))
        let task = Task {
            try CompressionInputScanner.scan(folder: temp.url)
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
