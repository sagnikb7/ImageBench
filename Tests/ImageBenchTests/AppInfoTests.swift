import XCTest
@testable import ImageBench

final class AppInfoTests: XCTestCase {
    func testReadsReleaseBundleValues() {
        let info = AppInfo(infoDictionary: [
            "CFBundleDisplayName": "ImageBench Preview",
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "45",
        ])
        XCTAssertEqual(info.name, "ImageBench Preview")
        XCTAssertEqual(info.versionLine, "Version 1.2.3 (45)")
    }

    func testDevelopmentFallbacksAreHumanReadable() {
        let info = AppInfo(infoDictionary: nil)
        XCTAssertEqual(info.name, "ImageBench")
        XCTAssertEqual(info.versionLine, "Version Development (local)")
    }
}
