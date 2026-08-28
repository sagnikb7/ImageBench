import AppKit
import Foundation

@MainActor
final class SplitterViewModel: ObservableObject {
    @Published var input: URL?
    @Published var preview: NSImage?
    @Published var outputFolder: URL?
    @Published var orientation: SplitOrientation = .horizontal
    @Published var count = 3
    @Published var isRunning = false
    @Published var progressText = ""

    private var task: Task<Void, Never>?

    func chooseInput() {
        guard let url = Panels.chooseFormatPreservingImage(prompt: "Choose an image to split") else { return }
        selectInput(url)
    }

    func selectInput(_ url: URL) {
        guard let selection = ImageSelectionValidator.loadFormatPreservingImage(at: url) else {
            progressText = "Choose a readable JPEG, PNG, or HEIC image."
            return
        }
        apply(selection)
    }

    func acceptDropped(_ urls: [URL]) -> Bool {
        guard let selection = ImageSelectionValidator.firstFormatPreservingImage(in: urls) else { return false }
        apply(selection)
        return true
    }

    func chooseOutput() {
        outputFolder = Panels.chooseFolder(prompt: "Choose a folder for the image parts")
    }

    func split() {
        guard let input, let outputFolder else { return }
        let orientation = orientation
        let count = count
        isRunning = true
        progressText = "Splitting…"
        task = Task {
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try SplitterEngine.split(
                        input: input,
                        outputFolder: outputFolder,
                        orientation: orientation,
                        count: count
                    )
                }
                let outputs = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                progressText = "Saved \(outputs.count) parts to \(outputFolder.lastPathComponent)."
            } catch is CancellationError {
                progressText = "Cancelled."
            } catch {
                progressText = error.localizedDescription
            }
            isRunning = false
        }
    }

    func cancel() {
        task?.cancel()
    }

    func revealOutput() {
        guard let outputFolder else { return }
        WorkspaceFileActions.reveal(folder: outputFolder)
    }

    private func apply(_ selection: SelectedImage) {
        input = selection.url
        preview = selection.preview
        if outputFolder == nil { outputFolder = selection.url.deletingLastPathComponent() }
        progressText = ""
    }
}
