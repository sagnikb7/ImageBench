import Foundation

@MainActor
final class ExifViewerViewModel: ObservableObject {
    @Published private(set) var input: URL?
    @Published private(set) var inspection: ExifInspection?
    @Published private(set) var isLoading = false
    @Published var message = ""

    private var inspectionTask: Task<Void, Never>?
    private var inspectionGeneration = 0

    func chooseInput() {
        guard let url = Panels.chooseExifImage(prompt: "Choose an image or RAW file") else { return }
        selectInput(url)
    }

    func acceptDropped(_ urls: [URL]) -> Bool {
        guard let url = urls.first(where: ExifFileSupport.supports) else { return false }
        selectInput(url)
        return true
    }

    func selectInput(_ url: URL) {
        guard ExifFileSupport.supports(url) else {
            message = "Choose a supported image or RAW camera file."
            return
        }
        inspectionTask?.cancel()
        inspectionGeneration += 1
        let generation = inspectionGeneration
        input = url
        inspection = nil
        isLoading = true
        message = "Reading metadata and building histogram…"
        inspectionTask = Task {
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try ExifViewerEngine.inspect(url)
                }
                let result = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                try Task.checkCancellation()
                guard generation == inspectionGeneration else { return }
                inspection = result
                if result.preview == nil {
                    message = "Metadata loaded. A preview is unavailable through this Mac's installed camera codecs."
                } else {
                    message = "Loaded \(result.fieldCount) metadata fields."
                }
            } catch is CancellationError {
                // A newer selection owns the visible inspection.
            } catch {
                guard generation == inspectionGeneration else { return }
                message = error.localizedDescription
            }
            if generation == inspectionGeneration {
                isLoading = false
            }
        }
    }

    func revealInput() {
        guard let input else { return }
        WorkspaceFileActions.reveal(files: [input])
    }
}
