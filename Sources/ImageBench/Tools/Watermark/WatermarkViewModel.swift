import AppKit
import SwiftUI

@MainActor
final class WatermarkViewModel: ObservableObject {
    @Published var input: URL?
    @Published var sourcePreview: NSImage?
    @Published var watermarkPreview: NSImage?
    @Published var draft = WatermarkDraft.cleanSlate
    @Published var textColor = Color.white
    @Published var watermarkImageURL: URL?
    @Published private(set) var presets: [Int: WatermarkPreset] = [:]
    @Published var selectedSlot = 1
    @Published var isExporting = false
    @Published var message = ""
    @Published private(set) var lastOutput: URL?

    private let presetStore: WatermarkPresetStore
    private var exportTask: Task<Void, Never>?
    private var presetLoadTask: Task<Void, Never>?
    private var watermarkLoadTask: Task<Void, Never>?
    private var watermarkPreviewTask: Task<Void, Never>?
    private var previewGeneration = 0
    private var hasLoadedPresets = false

    init(presetStore: WatermarkPresetStore = WatermarkPresetStore()) {
        self.presetStore = presetStore
    }

    var canExport: Bool {
        guard input != nil else { return false }
        switch draft.kind {
        case .text: return !draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image: return watermarkImageURL != nil
        }
    }

    func loadPresets() async {
        guard !hasLoadedPresets else { return }
        hasLoadedPresets = true
        presetLoadTask?.cancel()
        do {
            presets = Dictionary(uniqueKeysWithValues: try await presetStore.load().map { ($0.slot, $0) })
            try Task.checkCancellation()
            selectedSlot = 1
            clearEditor()
            if let preset = presets[1] {
                await applyPreset(preset, slot: 1)
                if Task.isCancelled { hasLoadedPresets = false }
            } else {
                message = ""
            }
        } catch is CancellationError {
            hasLoadedPresets = false
        } catch {
            hasLoadedPresets = false
            message = "Saved watermark presets could not be loaded: \(error.localizedDescription)"
        }
    }

    func preparePreview() {
        if watermarkPreview == nil { refreshWatermarkPreview() }
    }

    func chooseInput() {
        guard let url = Panels.chooseFormatPreservingImage(prompt: "Choose a photo to watermark") else { return }
        selectInput(url)
    }

    func selectInput(_ url: URL) {
        guard let selection = ImageSelectionValidator.loadFormatPreservingImage(at: url) else {
            message = "Choose a readable JPEG, PNG, or HEIC image."
            return
        }
        input = selection.url
        sourcePreview = selection.preview
        lastOutput = nil
        message = ""
    }

    func acceptDropped(_ urls: [URL]) -> Bool {
        guard let selection = ImageSelectionValidator.firstFormatPreservingImage(in: urls) else { return false }
        input = selection.url
        sourcePreview = selection.preview
        lastOutput = nil
        message = ""
        return true
    }

    func chooseWatermarkImage() {
        guard let url = Panels.chooseImage(prompt: "Choose a watermark image") else { return }
        presetLoadTask?.cancel()
        watermarkLoadTask?.cancel()
        watermarkPreviewTask?.cancel()
        previewGeneration += 1
        message = "Loading watermark image…"
        watermarkLoadTask = Task {
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try ImageRenderer.preview(ImageRenderer.normalizedImage(at: url), maxDimension: 900)
                }
                let image = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                draft.kind = .image
                watermarkImageURL = url
                watermarkPreview = image
                message = ""
            } catch is CancellationError {
                // A newer image selection owns the editor state.
            } catch {
                message = "Choose a readable watermark image."
            }
        }
    }

    func selectKind(_ kind: WatermarkKind) {
        presetLoadTask?.cancel()
        draft.kind = kind
        refreshWatermarkPreview()
    }

    func updateText() {
        draft.color = watermarkColor(from: textColor)
        if draft.kind == .text { refreshWatermarkPreview(debounced: true) }
    }

    func updatePlacement(x: Double, y: Double) {
        draft.placement = WatermarkPlacement(x: x, y: y).normalized()
    }

    func centerWatermark() {
        draft.placement = WatermarkPlacement(x: 0.5, y: 0.5)
    }

    func selectPreset(slot: Int) {
        presetLoadTask?.cancel()
        selectedSlot = slot
        clearEditor()
        guard let preset = presets[slot] else {
            message = "Preset \(slot) is empty. Start fresh, then export to save it."
            return
        }
        message = "Loading preset \(slot)…"
        presetLoadTask = Task {
            await applyPreset(preset, slot: slot)
        }
    }

    func resetSelectedPreset() async {
        let slot = selectedSlot
        guard presets[slot] != nil else { return }
        presetLoadTask?.cancel()
        do {
            try await presetStore.delete(slot: slot)
            presets.removeValue(forKey: slot)
            clearEditor()
            message = "Preset \(slot) was reset."
        } catch {
            message = "Preset \(slot) could not be reset: \(error.localizedDescription)"
        }
    }

    func resetAllPresets() async {
        presetLoadTask?.cancel()
        do {
            try await presetStore.resetAll()
            presets.removeAll()
            selectedSlot = 1
            clearEditor()
            message = "All watermark presets were reset."
        } catch {
            message = "Watermark presets could not be reset: \(error.localizedDescription)"
        }
    }

    func export() {
        guard let input,
            let contentType = ImageFileSupport.formatPreservingContentType(for: input)
        else { return }
        let panel = NSSavePanel()
        panel.title = "Export watermarked photo"
        panel.nameFieldStringValue = "\(input.displayName)_watermarked.\(input.pathExtension.lowercased())"
        panel.allowedContentTypes = [contentType]
        guard panel.runModal() == .OK, let output = panel.url else { return }

        draft.color = watermarkColor(from: textColor)
        let snapshot = draft.normalized()
        let watermarkURL = watermarkImageURL
        let slot = selectedSlot
        let presetStore = presetStore
        isExporting = true
        message = "Exporting watermarked copy…"
        exportTask = Task {
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try WatermarkEngine.export(
                        input: input,
                        draft: snapshot,
                        imageWatermarkURL: watermarkURL,
                        output: output,
                        type: contentType
                    )
                }
                try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                lastOutput = output
                do {
                    let preset = try await presetStore.save(slot: slot, draft: snapshot, imageSourceURL: watermarkURL)
                    presets[slot] = preset
                    if let cachedURL = try await presetStore.cachedImageURL(for: preset) {
                        watermarkImageURL = cachedURL
                    }
                    message = "Saved \(output.lastPathComponent) and preset \(slot)."
                } catch {
                    message = "Saved \(output.lastPathComponent), but preset \(slot) could not be updated: \(error.localizedDescription)"
                }
            } catch is CancellationError {
                message = "Export cancelled."
            } catch {
                message = error.localizedDescription
            }
            isExporting = false
        }
    }

    func cancel() {
        exportTask?.cancel()
    }

    func revealOutput() {
        guard let lastOutput else { return }
        WorkspaceFileActions.reveal(files: [lastOutput])
    }

    private func refreshWatermarkPreview(debounced: Bool = false) {
        watermarkPreviewTask?.cancel()
        previewGeneration += 1
        let generation = previewGeneration
        draft.color = watermarkColor(from: textColor)
        let snapshot = draft
        let imageURL = watermarkImageURL

        watermarkPreviewTask = Task {
            do {
                if debounced { try await Task.sleep(for: .milliseconds(80)) }
                let worker = Task.detached(priority: .userInitiated) { () throws -> NSImage? in
                    switch snapshot.kind {
                    case .text:
                        return try WatermarkEngine.textPreview(draft: snapshot)
                    case .image:
                        guard let imageURL else { return nil }
                        return try ImageRenderer.preview(ImageRenderer.normalizedImage(at: imageURL), maxDimension: 900)
                    }
                }
                let image = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled, generation == previewGeneration else { return }
                watermarkPreview = image
            } catch is CancellationError {
                // A newer text, color, kind, or preset owns the preview.
            } catch {
                if generation == previewGeneration { watermarkPreview = nil }
            }
        }
    }

    private func clearEditor() {
        watermarkLoadTask?.cancel()
        watermarkPreviewTask?.cancel()
        previewGeneration += 1
        draft = .cleanSlate
        textColor = .white
        watermarkImageURL = nil
        watermarkPreview = nil
    }

    private func applyPreset(_ preset: WatermarkPreset, slot: Int) async {
        do {
            let cachedURL = try await presetStore.cachedImageURL(for: preset)
            try Task.checkCancellation()
            guard selectedSlot == slot else { return }
            watermarkPreviewTask?.cancel()
            previewGeneration += 1
            let generation = previewGeneration
            draft = preset.draft
            textColor = Color(
                red: preset.draft.color.red,
                green: preset.draft.color.green,
                blue: preset.draft.color.blue
            )
            watermarkImageURL = cachedURL
            if let cachedURL {
                let worker = Task.detached(priority: .userInitiated) {
                    try ImageRenderer.preview(
                        ImageRenderer.normalizedImage(at: cachedURL),
                        maxDimension: 900
                    )
                }
                let image = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard selectedSlot == slot, generation == previewGeneration else { return }
                watermarkPreview = image
            } else {
                refreshWatermarkPreview()
            }
            message = "Loaded preset \(slot)."
        } catch is CancellationError {
            // A newer slot selection owns the visible state.
        } catch {
            if selectedSlot == slot { message = error.localizedDescription }
        }
    }

    private func watermarkColor(from color: Color) -> WatermarkColor {
        guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return .white }
        return WatermarkColor(
            red: converted.redComponent,
            green: converted.greenComponent,
            blue: converted.blueComponent
        )
    }
}
