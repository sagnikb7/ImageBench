import Foundation

enum CompressionInputScanner {
    private static let knownPackageExtensions: Set<String> = [
        "app", "bundle", "framework", "key", "numbers", "pages", "photolibrary", "photoslibrary", "playground", "rtfd",
        "xcworkspace", "xcodeproj",
    ]

    static func scan(folder: URL, excluding excludedFolders: [URL] = []) throws -> [URL] {
        try Task.checkCancellation()
        guard !CompressionOutputDirectory.isMarked(folder) else { return [] }
        let excludedPaths = Set(excludedFolders.map { $0.standardizedFileURL.path })
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .fileSizeKey]
        guard
            let enumerator = FileManager.default.enumerator(
                at: folder,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
        else { return [] }

        var images: [URL] = []
        while let item = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            let values = try? item.resourceValues(forKeys: keys)
            if values?.isDirectory == true,
                values?.isPackage == true || knownPackageExtensions.contains(item.pathExtension.lowercased())
            {
                // Launch Services does not always classify packages in temporary or external volumes,
                // so known bundle extensions provide a deterministic fallback.
                enumerator.skipDescendants()
                continue
            }
            if values?.isDirectory == true,
                excludedPaths.contains(item.standardizedFileURL.path) || CompressionOutputDirectory.isMarked(item)
            {
                // Skipping descendants prevents prior exports from becoming inputs on a later scan.
                enumerator.skipDescendants()
                continue
            }
            guard values?.isRegularFile == true, ImageFileSupport.supportsCompressionInput(item) else { continue }
            images.append(item)
        }
        return images.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }
}
