import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class FileSupportTests: XCTestCase {
    func testSupportedExtensionsAreCaseInsensitive() {
        for ext in ["jpg", "JPEG", "Png", "HEIC", "heif", "tif", "TIFF", "Bmp", "GIF", "WebP"] {
            XCTAssertTrue(ImageFileSupport.supportsCompressionInput(URL(fileURLWithPath: "/tmp/photo.\(ext)")), ext)
        }
        for ext in ["svg", "pdf", "raw", "txt", ""] {
            XCTAssertFalse(ImageFileSupport.supportsCompressionInput(URL(fileURLWithPath: "/tmp/photo.\(ext)")), ext)
        }
    }

    func testFormatPreservingToolsAcceptOnlyTheirAdvertisedFormats() {
        for ext in ["jpg", "JPEG", "png", "HEIC", "heif"] {
            let url = URL(fileURLWithPath: "/tmp/photo.\(ext)")
            XCTAssertTrue(ImageFileSupport.supportsFormatPreservingOutput(url), ext)
            XCTAssertNotNil(ImageFileSupport.formatPreservingContentType(for: url), ext)
        }
        for ext in ["tiff", "bmp", "gif", "webp", "txt"] {
            let url = URL(fileURLWithPath: "/tmp/photo.\(ext)")
            XCTAssertFalse(ImageFileSupport.supportsFormatPreservingOutput(url), ext)
            XCTAssertNil(ImageFileSupport.formatPreservingContentType(for: url), ext)
        }
        XCTAssertEqual(ImageFileSupport.formatPreservingContentTypes, [.jpeg, .png, .heic])
    }

    func testImageSelectionSkipsUnreadableCandidates() throws {
        let temp = try TemporaryDirectory()
        let corrupt = temp.url.appendingPathComponent("broken.jpg")
        let valid = temp.url.appendingPathComponent("valid.png")
        try Data("not an image".utf8).write(to: corrupt)
        try TestImageFactory.make(at: valid, width: 12, height: 8, type: .png)

        let selection = ImageSelectionValidator.firstFormatPreservingImage(in: [corrupt, valid])

        XCTAssertEqual(selection?.url, valid)
        XCTAssertNotNil(selection?.preview)
    }

    func testUniqueOutputPreservesExistingFilesAndFindsFirstGap() throws {
        let temp = try TemporaryDirectory()
        for name in ["photo.jpg", "photo_2.jpg", "photo_3.jpg"] {
            XCTAssertTrue(FileManager.default.createFile(atPath: temp.url.appendingPathComponent(name).path, contents: Data(name.utf8)))
        }
        XCTAssertEqual(ImageFileSupport.uniqueOutput(in: temp.url, stem: "photo", extension: "jpg").lastPathComponent, "photo_4.jpg")
        XCTAssertEqual(try String(contentsOf: temp.url.appendingPathComponent("photo.jpg"), encoding: .utf8), "photo.jpg")
    }

    func testFileSizeForMissingAndExistingFiles() throws {
        let temp = try TemporaryDirectory()
        let file = temp.url.appendingPathComponent("data.bin")
        try Data(repeating: 7, count: 1234).write(to: file)
        XCTAssertEqual(ImageFileSupport.fileSize(file), 1234)
        XCTAssertEqual(ImageFileSupport.fileSize(temp.url.appendingPathComponent("missing")), 0)
    }

    func testShellQuotingHandlesSpacesQuotesAndEmptyStrings() {
        XCTAssertEqual("".shellQuoted, "''")
        XCTAssertEqual("plain".shellQuoted, "'plain'")
        XCTAssertEqual("Sam's Photos/file.jpg".shellQuoted, "'Sam'\\''s Photos/file.jpg'")
    }
}
