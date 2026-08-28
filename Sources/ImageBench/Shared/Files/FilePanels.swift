import AppKit
import Foundation
import UniformTypeIdentifiers

enum Panels {
    @MainActor static func chooseFolder(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor static func chooseFormatPreservingImage(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = "Choose"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ImageFileSupport.formatPreservingContentTypes
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor static func chooseImage(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = "Choose"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor static func chooseExifImage(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = "Inspect"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ExifFileSupport.contentTypes
        return panel.runModal() == .OK ? panel.url : nil
    }
}
