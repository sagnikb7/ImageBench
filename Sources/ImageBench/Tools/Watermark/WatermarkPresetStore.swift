import Foundation

enum WatermarkPresetStoreError: LocalizedError, Equatable {
    case invalidSlot
    case imageRequired
    case missingCachedImage

    var errorDescription: String? {
        switch self {
        case .invalidSlot: "Watermark presets must use one of the four available slots."
        case .imageRequired: "Choose a watermark image before saving this preset."
        case .missingCachedImage: "The saved watermark image is missing from ImageBench storage."
        }
    }
}

actor WatermarkPresetStore {
    private struct Manifest: Codable {
        let version: Int
        var presets: [WatermarkPreset]
    }

    private let rootDirectory: URL
    private let fileManager: FileManager

    init(rootDirectory: URL = WatermarkPresetStore.defaultDirectory(), fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    func load() throws -> [WatermarkPreset] {
        guard fileManager.fileExists(atPath: manifestURL.path) else { return [] }
        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(Manifest.self, from: data)
        return manifest.presets.filter { (1...4).contains($0.slot) }.sorted { $0.slot < $1.slot }
    }

    func cachedImageURL(for preset: WatermarkPreset) throws -> URL? {
        guard let filename = preset.cachedImageFilename else { return nil }
        let url = assetsDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path) else { throw WatermarkPresetStoreError.missingCachedImage }
        return url
    }

    func save(slot: Int, draft: WatermarkDraft, imageSourceURL: URL?) throws -> WatermarkPreset {
        guard (1...4).contains(slot) else { throw WatermarkPresetStoreError.invalidSlot }
        try ensureDirectories()
        let existing = try load()
        let previous = existing.first { $0.slot == slot }

        var newAssetURL: URL?
        if draft.kind == .image {
            guard let imageSourceURL else { throw WatermarkPresetStoreError.imageRequired }
            let fileExtension = imageSourceURL.pathExtension.isEmpty ? "png" : imageSourceURL.pathExtension.lowercased()
            let filename = "slot-\(slot)-\(UUID().uuidString).\(fileExtension)"
            let destination = assetsDirectory.appendingPathComponent(filename)
            try fileManager.copyItem(at: imageSourceURL, to: destination)
            newAssetURL = destination
        }

        let preset = WatermarkPreset(
            slot: slot,
            draft: draft.normalized(),
            cachedImageFilename: newAssetURL?.lastPathComponent,
            updatedAt: Date()
        )
        var updated = existing.filter { $0.slot != slot }
        updated.append(preset)
        updated.sort { $0.slot < $1.slot }

        do {
            let data = try JSONEncoder.imageBenchPresetEncoder.encode(Manifest(version: 1, presets: updated))
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            if let newAssetURL { try? fileManager.removeItem(at: newAssetURL) }
            throw error
        }

        if let oldFilename = previous?.cachedImageFilename,
            oldFilename != preset.cachedImageFilename
        {
            try? fileManager.removeItem(at: assetsDirectory.appendingPathComponent(oldFilename))
        }
        return preset
    }

    func delete(slot: Int) throws {
        guard (1...4).contains(slot) else { throw WatermarkPresetStoreError.invalidSlot }
        let existing = try load()
        guard let removed = existing.first(where: { $0.slot == slot }) else { return }
        try ensureDirectories()
        try writeManifest(existing.filter { $0.slot != slot })
        if let filename = removed.cachedImageFilename {
            try? fileManager.removeItem(at: assetsDirectory.appendingPathComponent(filename))
        }
    }

    func resetAll() throws {
        try ensureDirectories()
        try writeManifest([])
        guard let assets = try? fileManager.contentsOfDirectory(at: assetsDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for asset in assets {
            try? fileManager.removeItem(at: asset)
        }
    }

    private var manifestURL: URL { rootDirectory.appendingPathComponent("presets.json") }
    private var assetsDirectory: URL { rootDirectory.appendingPathComponent("Assets", isDirectory: true) }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
    }

    private func writeManifest(_ presets: [WatermarkPreset]) throws {
        let data = try JSONEncoder.imageBenchPresetEncoder.encode(Manifest(version: 1, presets: presets))
        try data.write(to: manifestURL, options: .atomic)
    }

    private static func defaultDirectory() -> URL {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("ImageBench/Watermarks", isDirectory: true)
    }
}

extension JSONEncoder {
    fileprivate static var imageBenchPresetEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
