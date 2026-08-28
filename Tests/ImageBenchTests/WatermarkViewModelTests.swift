import AppKit
import Foundation
import XCTest
@testable import ImageBench

@MainActor
final class WatermarkViewModelTests: XCTestCase {
    func testLoadPresetsSelectsAndAppliesSavedSlotOne() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var savedDraft = WatermarkDraft()
        savedDraft.text = "Saved signature"
        savedDraft.opacity = 0.63
        savedDraft.relativeWidth = 0.37
        savedDraft.placement = WatermarkPlacement(x: 0.25, y: 0.7)
        _ = try await store.save(slot: 1, draft: savedDraft, imageSourceURL: nil)
        let model = WatermarkViewModel(presetStore: store)

        await model.loadPresets()

        XCTAssertEqual(model.selectedSlot, 1)
        XCTAssertEqual(model.draft, savedDraft.normalized())
        XCTAssertNil(model.watermarkImageURL)
    }

    func testSelectingEmptySlotClearsPreviouslyLoadedPreset() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var savedDraft = WatermarkDraft()
        savedDraft.kind = .image
        savedDraft.text = "Previous preset"
        savedDraft.opacity = 0.41
        savedDraft.relativeWidth = 0.46
        let source = temp.url.appendingPathComponent("signature.png")
        try TestImageFactory.make(at: source, width: 80, height: 24)
        _ = try await store.save(slot: 1, draft: savedDraft, imageSourceURL: source)
        let model = WatermarkViewModel(presetStore: store)
        await model.loadPresets()

        XCTAssertEqual(model.draft, savedDraft.normalized())
        XCTAssertNotNil(model.watermarkImageURL)
        XCTAssertNotNil(model.watermarkPreview)

        model.selectPreset(slot: 2)

        var cleanSlate = WatermarkDraft()
        cleanSlate.text = ""
        XCTAssertEqual(model.selectedSlot, 2)
        XCTAssertEqual(model.draft, cleanSlate)
        XCTAssertNil(model.watermarkImageURL)
        XCTAssertNil(model.watermarkPreview)
        XCTAssertEqual(model.message, "Preset 2 is empty. Start fresh, then export to save it.")
    }

    func testReturningToWatermarkStudioDoesNotReapplySlotOne() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        var savedDraft = WatermarkDraft()
        savedDraft.text = "Saved signature"
        _ = try await store.save(slot: 1, draft: savedDraft, imageSourceURL: nil)
        let model = WatermarkViewModel(presetStore: store)
        await model.loadPresets()
        model.selectPreset(slot: 3)

        await model.loadPresets()

        XCTAssertEqual(model.selectedSlot, 3)
        XCTAssertEqual(model.draft, .cleanSlate)
    }

    func testSelectingSavedImagePresetSurvivesTheEditorResetPreviewRefresh() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        let source = temp.url.appendingPathComponent("signature.png")
        try TestImageFactory.make(at: source, width: 120, height: 36)
        var imageDraft = WatermarkDraft()
        imageDraft.kind = .image
        _ = try await store.save(slot: 2, draft: imageDraft, imageSourceURL: source)
        let model = WatermarkViewModel(presetStore: store)
        await model.loadPresets()

        model.selectPreset(slot: 2)
        model.updateText()
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(model.selectedSlot, 2)
        XCTAssertEqual(model.draft.kind, .image)
        XCTAssertNotNil(model.watermarkImageURL)
        XCTAssertNotNil(model.watermarkPreview)
        XCTAssertEqual(model.message, "Loaded preset 2.")
    }

    func testResetSelectedPresetClearsOnlyTheActiveSlot() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        _ = try await store.save(slot: 1, draft: WatermarkDraft(), imageSourceURL: nil)
        _ = try await store.save(slot: 2, draft: WatermarkDraft(), imageSourceURL: nil)
        let model = WatermarkViewModel(presetStore: store)
        await model.loadPresets()

        await model.resetSelectedPreset()

        XCTAssertNil(model.presets[1])
        XCTAssertNotNil(model.presets[2])
        XCTAssertEqual(model.draft, .cleanSlate)
        XCTAssertEqual(model.message, "Preset 1 was reset.")
    }

    func testResetAllPresetsReturnsEditorToEmptySlotOne() async throws {
        let temp = try TemporaryDirectory()
        let store = WatermarkPresetStore(rootDirectory: temp.url)
        _ = try await store.save(slot: 2, draft: WatermarkDraft(), imageSourceURL: nil)
        let model = WatermarkViewModel(presetStore: store)
        await model.loadPresets()
        model.selectPreset(slot: 2)

        await model.resetAllPresets()

        XCTAssertTrue(model.presets.isEmpty)
        XCTAssertEqual(model.selectedSlot, 1)
        XCTAssertEqual(model.draft, .cleanSlate)
        XCTAssertEqual(model.message, "All watermark presets were reset.")
    }
}
