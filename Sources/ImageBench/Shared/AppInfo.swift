import Foundation

struct AppInfo: Equatable, Sendable {
    static let repositoryURL = URL(string: "https://github.com/sagnikb7/ImageBench")!
    static let issuesURL = repositoryURL.appendingPathComponent("issues")

    let name: String
    let version: String
    let build: String

    init(infoDictionary: [String: Any]?) {
        name =
            infoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleName"] as? String
            ?? "ImageBench"
        version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development"
        build = infoDictionary?["CFBundleVersion"] as? String ?? "local"
    }

    static var current: AppInfo { AppInfo(infoDictionary: Bundle.main.infoDictionary) }
    var versionLine: String { "Version \(version) (\(build))" }
}
