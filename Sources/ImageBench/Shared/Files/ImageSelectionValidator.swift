import AppKit
import Foundation

struct SelectedImage {
    let url: URL
    let preview: NSImage
}

enum ImageSelectionValidator {
    static func loadFormatPreservingImage(at url: URL) -> SelectedImage? {
        guard ImageFileSupport.supportsFormatPreservingOutput(url),
            let preview = NSImage(contentsOf: url)
        else { return nil }
        return SelectedImage(url: url, preview: preview)
    }

    static func firstFormatPreservingImage(in urls: [URL]) -> SelectedImage? {
        // Continue past a corrupt file so a valid item later in a multi-file drop still works.
        urls.lazy.compactMap(loadFormatPreservingImage).first
    }
}
