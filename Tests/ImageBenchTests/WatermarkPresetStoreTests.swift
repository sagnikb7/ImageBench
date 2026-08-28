import Foundation
import XCTest
@testable import ImageBench

final class WatermarkPresetStoreTests: XCTestCase {
    func testTextPresetRoundTripsInOneOfFourSlots() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var draft = WatermarkDraft()
        draft.text = "Sagnik © 2026"
        draft.relativeWidth = 0.31
        draft.placement = WatermarkPlacement(x: 0.2, y: 0.8)

        let saved = try await store.save(slot: 4, draft: draft, imageSourceURL: nil)
        let loaded = try await store.load()

        XCTAssertEqual(saved.slot, 4)
        XCTAssertNil(saved.cachedImageFilename)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.draft, draft.normalized())
    }

    func testImagePresetUsesAppManagedCopyAfterOriginalDisappears() async throws {
        let temp = try TemporaryDirectory()
        let sourceDirectory = try TemporaryDirectory()
        let source = sourceDirectory.url.appendingPathComponent("signature.png")
        try TestImageFactory.make(at: source, width: 80, height: 24)
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var draft = WatermarkDraft()
        draft.kind = .image

        let saved = try await store.save(slot: 1, draft: draft, imageSourceURL: source)
        try FileManager.default.removeItem(at: source)
        let cachedResult = try await store.cachedImageURL(for: saved)
        let cached = try XCTUnwrap(cachedResult)

        XCTAssertTrue(FileManager.default.fileExists(atPath: cached.path))
        XCTAssertEqual(try TestImageFactory.dimensions(of: cached), CGSize(width: 80, height: 24))
    }

    func testOverwritingImageSlotRemovesSupersededAsset() async throws {
        let temp = try TemporaryDirectory()
        let sourceDirectory = try TemporaryDirectory()
        let firstSource = sourceDirectory.url.appendingPathComponent("first.png")
        let secondSource = sourceDirectory.url.appendingPathComponent("second.png")
        try TestImageFactory.make(at: firstSource, width: 20, height: 10)
        try TestImageFactory.make(at: secondSource, width: 40, height: 20)
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var draft = WatermarkDraft()
        draft.kind = .image

        let first = try await store.save(slot: 2, draft: draft, imageSourceURL: firstSource)
        let firstCachedResult = try await store.cachedImageURL(for: first)
        let firstCached = try XCTUnwrap(firstCachedResult)
        let second = try await store.save(slot: 2, draft: draft, imageSourceURL: secondSource)
        let secondCachedResult = try await store.cachedImageURL(for: second)
        let secondCached = try XCTUnwrap(secondCachedResult)
        let loaded = try await store.load()

        XCTAssertFalse(FileManager.default.fileExists(atPath: firstCached.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondCached.path))
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.slot, second.slot)
        XCTAssertEqual(loaded.first?.draft, second.draft)
        XCTAssertEqual(loaded.first?.cachedImageFilename, second.cachedImageFilename)
        XCTAssertEqual(try XCTUnwrap(loaded.first?.updatedAt).timeIntervalSince(second.updatedAt), 0, accuracy: 1)
    }

    func testInvalidSlotsAndMissingImageAreRejected() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var imageDraft = WatermarkDraft()
        imageDraft.kind = .image

        do {
            _ = try await store.save(slot: 5, draft: WatermarkDraft(), imageSourceURL: nil)
            XCTFail("Expected invalid slot")
        } catch {
            XCTAssertEqual(error as? WatermarkPresetStoreError, .invalidSlot)
        }
        do {
            _ = try await store.save(slot: 1, draft: imageDraft, imageSourceURL: nil)
            XCTFail("Expected missing image")
        } catch {
            XCTAssertEqual(error as? WatermarkPresetStoreError, .imageRequired)
        }
    }

    func testDeletingPresetDurablyRemovesItsManagedImage() async throws {
        let temp = try TemporaryDirectory()
        let source = temp.url.appendingPathComponent("signature.png")
        try TestImageFactory.make(at: source, width: 80, height: 24)
        let store = WatermarkPresetStore(rootDirectory: temp.url.appendingPathComponent("Presets"))
        var draft = WatermarkDraft()
        draft.kind = .image
        let preset = try await store.save(slot: 3, draft: draft, imageSourceURL: source)
        let cachedResult = try await store.cachedImageURL(for: preset)
        let cached = try XCTUnwrap(cachedResult)

        try await store.delete(slot: 3)

        let loaded = try await store.load()
        XCTAssertTrue(loaded.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cached.path))
    }

    func testResetAllClearsManifestAndEveryManagedImage() async throws {
        let temp = try TemporaryDirectory()
        let source = temp.url.appendingPathComponent("signature.png")
        try TestImageFactory.make(at: source, width: 80, height: 24)
        let store = WatermarkPresetStore(rootDirectory: temp.url.appendingPathComponent("Presets"))
        var imageDraft = WatermarkDraft()
        imageDraft.kind = .image
        _ = try await store.save(slot: 1, draft: imageDraft, imageSourceURL: source)
        _ = try await store.save(slot: 2, draft: WatermarkDraft(), imageSourceURL: nil)

        try await store.resetAll()

        let loaded = try await store.load()
        XCTAssertTrue(loaded.isEmpty)
        let assets = temp.url.appendingPathComponent("Presets/Assets")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: assets.path), [])
    }
}
