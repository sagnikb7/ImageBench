import Foundation

/// Owns automatic export directories and their persistent scan-exclusion marker.
enum CompressionOutputDirectory {
    static let markerName = ".imagebench-compressed-output"

    static func nextAvailable(in parent: URL) -> URL {
        var index = 0
        while true {
            let name = index == 0 ? "compressed_output" : "compressed_output_\(index)"
            let candidate = parent.appendingPathComponent(name, isDirectory: true)
            if !FileManager.default.fileExists(atPath: candidate.path),
                (try? FileManager.default.destinationOfSymbolicLink(atPath: candidate.path)) == nil
            {
                return candidate
            }
            index += 1
        }
    }

    static func reserve(in parent: URL) throws -> URL {
        while true {
            let folder = nextAvailable(in: parent)
            do {
                // Exclusive creation also protects against another app window reserving this name.
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            } catch CocoaError.fileWriteFileExists {
                continue
            }
            do {
                try Data("ImageBench compressed output\n".utf8).write(to: folder.appendingPathComponent(markerName), options: .atomic)
            } catch {
                try? FileManager.default.removeItem(at: folder)
                throw error
            }
            return folder
        }
    }

    static func isMarked(_ folder: URL) -> Bool {
        FileManager.default.fileExists(atPath: folder.appendingPathComponent(markerName).path)
    }
}
