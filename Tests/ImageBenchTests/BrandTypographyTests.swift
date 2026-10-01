import AppKit
import XCTest
@testable import ImageBench

final class BrandTypographyTests: XCTestCase {
    func testBundledDisplayAndReadingFontsRegister() {
        XCTAssertTrue(BrandTypography.register())
        XCTAssertNotNil(NSFont(name: BrandTypography.fontName, size: 24))
        XCTAssertNotNil(NSFont(name: BrandTypography.bodyFontName, size: 13))
    }

    func testWordmarkFitsTheSidebarBesideTheIcon() {
        XCTAssertTrue(BrandTypography.register())
        let font = NSFont(name: BrandTypography.fontName, size: BrandTypography.wordmarkPointSize)!
        let width = ("ImageBench" as NSString).size(withAttributes: [.font: font, .kern: -0.35]).width
        XCTAssertLessThanOrEqual(width, PFLayout.sidebarWidth - 28 - 38 - 10)
    }
}
