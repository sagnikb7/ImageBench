import AppKit
import XCTest
@testable import ImageBench

final class BrandTypographyTests: XCTestCase {
    func testArchivoNarrowResourceRegistersForTheWordmark() {
        XCTAssertTrue(BrandTypography.register())
        XCTAssertNotNil(NSFont(name: BrandTypography.fontName, size: 24))
    }
}
