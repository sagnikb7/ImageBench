import AppKit
import Foundation

@MainActor
final class AspectFillerViewModel: ObservableObject {
    @Published var input: URL?
    @Published var preview: NSImage?
    @Published var preset: AspectPreset = .square
    @Published var customWidth = 3.0
    @Published var customHeight = 2.0
    @Published var fillStyle: FillStyle = .blur
    @Published var isRendering = false
    @Published var isExporting = false
    @Published var message = ""
    @Published private(set) var sourceDimensions: CGSize?

    private var previewTask: Task<Void, Never>?
    private var exportTask: Task<Void, Never>?
    private var previewGeneration = 0
    private let previewRenderer = AspectFillerPreviewRenderer()

    func chooseInput() {
        guard let url = Panels.chooseFormatPreservingImage(prompt: "Choose an image to fit") else { return }
        selectInput(url)
    }

    func selectInput(_ url: URL) {
        guard let selection = ImageSelectionValidator.loadFormatPreservingImage(at: url) else {
            message = "Choose a readable JPEG, PNG, or HEIC image."
            return
        }
        input = selection.url
        sourceDimensions = selection.preview.size
        refreshPreview()
    }

    func acceptDropped(_ urls: [URL]) -> Bool {
        guard let selection = ImageSelectionValidator.firstFormatPreservingImage(in: urls) else { return false }
        input = selection.url
        sourceDimensions = selection.preview.size
        refreshPreview()
        return true
    }

    var sourceRatioDescription: String {
        guard let sourceDimensions, sourceDimensions.width > 0, sourceDimensions.height > 0 else {
            return "Add an image to see its current aspect ratio."
        }
        let width = Int(sourceDimensions.width.rounded())
        let height = Int(sourceDimensions.height.rounded())
        let divisor = greatestCommonDivisor(width, height)
        let ratio = Double(width) / Double(height)
        return
            "Current image: \(width) × \(height) • \(width / divisor):\(height / divisor) • \(ratio.formatted(.number.precision(.fractionLength(2))))"
    }

    private func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
        var a = abs(lhs)
        var b = abs(rhs)
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return max(1, a)
    }

    func refreshPreview(debounced: Bool = false) {
        previewTask?.cancel()
        previewGeneration += 1
        let generation = previewGeneration
        guard let input else {
            preview = nil
            isRendering = false
            return
        }
        let ratio = preset.ratio(customWidth: customWidth, customHeight: customHeight)
        let style = fillStyle
        isRendering = true
        previewTask = Task {
            do {
                if debounced {
                    try await Task.sleep(for: .milliseconds(120))
                }
                let result = try await previewRenderer.preview(input: input, targetRatio: ratio, style: style)
                guard !Task.isCancelled, generation == previewGeneration else { return }
                preview = result
                message = ""
            } catch is CancellationError {
                // A newer preview owns the visible loading state.
            } catch {
                if generation == previewGeneration { message = error.localizedDescription }
            }
            if generation == previewGeneration { isRendering = false }
        }
    }

    func export() {
        guard let input,
            let contentType = ImageFileSupport.formatPreservingContentType(for: input)
        else { return }
        let panel = NSSavePanel()
        panel.title = "Export filled image"
        panel.nameFieldStringValue = "\(input.displayName)_filled.\(input.pathExtension.lowercased())"
        panel.allowedContentTypes = [contentType]
        guard panel.runModal() == .OK, let output = panel.url else { return }

        let ratio = preset.ratio(customWidth: customWidth, customHeight: customHeight)
        let style = fillStyle
        isExporting = true
        message = "Exporting…"
        exportTask = Task {
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    let composed = try AspectFillerEngine.compose(input: input, targetRatio: ratio, style: style)
                    try ImageRenderer.writeAtomically(
                        composed,
                        to: output,
                        type: contentType,
                        quality: 0.97,
                        protecting: input
                    )
                }
                try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                message = "Saved \(output.lastPathComponent)."
            } catch is CancellationError {
                message = "Export cancelled."
            } catch {
                message = error.localizedDescription
            }
            isExporting = false
        }
    }

    func cancelExport() {
        exportTask?.cancel()
    }
}
