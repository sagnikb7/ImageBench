import AppKit
import Foundation

enum WorkspaceFileActions {
    @MainActor static func reveal(folder: URL) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.path)
    }

    @MainActor static func reveal(files: [URL]) {
        let existingFiles = files.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existingFiles.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(existingFiles)
    }

    @MainActor static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
