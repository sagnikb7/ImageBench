import Foundation

@MainActor
final class DependencyManager: ObservableObject {
    @Published private(set) var cjpegURL: URL?
    @Published private(set) var exiftoolURL: URL?
    @Published private(set) var isInstalling = false
    @Published private(set) var message = "Checking dependencies…"

    var isReady: Bool { cjpegURL != nil && exiftoolURL != nil }

    private var toolsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ImageBench/Tools", isDirectory: true)
    }

    func refreshAndBootstrapIfPossible() async {
        refresh()
        guard !isReady, bundledTool(named: "cjpeg") != nil || bundledTool(named: "exiftool") != nil else { return }
        await install()
    }

    func refresh() {
        cjpegURL = locateCJPEG()
        exiftoolURL = locateExifTool()
        if isReady {
            message = "cjpeg and ExifTool are ready. Processing works offline."
        } else {
            let missing = [cjpegURL == nil ? "cjpeg" : nil, exiftoolURL == nil ? "ExifTool" : nil].compactMap { $0 }
            message = "Missing: \(missing.joined(separator: ", "))."
        }
    }

    func install() async {
        guard !isInstalling else { return }
        isInstalling = true
        message = "Installing dependencies…"
        defer { isInstalling = false }

        do {
            try FileManager.default.createDirectory(at: toolsDirectory, withIntermediateDirectories: true)
            try installBundledTools()
            refresh()
            if isReady { return }

            guard let brew = Self.findExecutable(named: "brew") else {
                message = "No bundled tools or Homebrew were found. Build a release with Scripts/package-app.sh to include offline tools."
                return
            }
            message = "Installing mozjpeg and ExifTool with Homebrew…"
            let result = try await ProcessRunner.run(executable: brew, arguments: ["install", "mozjpeg", "exiftool"])
            guard result.status == 0 else {
                message = "Homebrew install failed: \(result.error.isEmpty ? result.output : result.error)"
                return
            }
            refresh()
        } catch {
            message = "Dependency installation failed: \(error.localizedDescription)"
        }
    }

    private func installBundledTools() throws {
        for name in ["cjpeg", "exiftool"] {
            guard let source = bundledTool(named: name) else { continue }
            let target = toolsDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: source, to: target)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: target.path)
        }
        if let resourceRoot = Bundle.main.resourceURL ?? Bundle.module.resourceURL {
            let candidates = [resourceRoot.appendingPathComponent("lib"), resourceRoot.appendingPathComponent("bin/lib")]
            if let source = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
                let target = toolsDirectory.appendingPathComponent("lib")
                if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
                try FileManager.default.copyItem(at: source, to: target)
            }
        }
    }

    private func locate(named name: String, alternatives: [String]) -> URL? {
        let appInstalled = toolsDirectory.appendingPathComponent(name)
        if FileManager.default.isExecutableFile(atPath: appInstalled.path) { return appInstalled }
        if let bundled = bundledTool(named: name), FileManager.default.isExecutableFile(atPath: bundled.path) { return bundled }
        for candidate in [name] + alternatives {
            if let found = Self.findExecutable(named: candidate) { return found }
        }
        return nil
    }

    private func locateCJPEG() -> URL? {
        let installed = toolsDirectory.appendingPathComponent("cjpeg")
        if FileManager.default.isExecutableFile(atPath: installed.path) { return installed }
        if let bundled = bundledTool(named: "cjpeg"), FileManager.default.isExecutableFile(atPath: bundled.path) { return bundled }
        let fallbacks = [
            URL(fileURLWithPath: "/opt/homebrew/opt/mozjpeg/bin/cjpeg"),
            URL(fileURLWithPath: "/usr/local/opt/mozjpeg/bin/cjpeg"),
        ]
        return fallbacks.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
    }

    private func locateExifTool() -> URL? {
        let installed = toolsDirectory.appendingPathComponent("exiftool")
        if FileManager.default.isExecutableFile(atPath: installed.path) { return installed }
        if let bundled = bundledTool(named: "exiftool"), FileManager.default.isExecutableFile(atPath: bundled.path) { return bundled }
        let fallbacks = [
            URL(fileURLWithPath: "/opt/homebrew/opt/exiftool/bin/exiftool"),
            URL(fileURLWithPath: "/usr/local/opt/exiftool/bin/exiftool"),
        ]
        if let found = fallbacks.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) { return found }
        return Self.findExecutable(named: "exiftool")
    }

    private func bundledTool(named name: String) -> URL? {
        let roots = [Bundle.main.resourceURL, Bundle.module.resourceURL].compactMap { $0 }
        let arch = Self.architecture
        for root in roots {
            for relative in ["bin/\(arch)/\(name)", "bin/\(name)", name] {
                let url = root.appendingPathComponent(relative)
                if FileManager.default.fileExists(atPath: url.path) { return url }
            }
        }
        return nil
    }

    private static var architecture: String {
        #if arch(arm64)
            "arm64"
        #else
            "x86_64"
        #endif
    }

    nonisolated static func findExecutable(named name: String) -> URL? {
        let paths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        return paths.map { URL(fileURLWithPath: $0).appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}
