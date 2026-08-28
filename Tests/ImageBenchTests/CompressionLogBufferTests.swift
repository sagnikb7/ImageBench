import XCTest
@testable import ImageBench

final class CompressionLogBufferTests: XCTestCase {
    func testPreservesExactLineOrderAndDropsEmptyUpdates() {
        var buffer = CompressionLogBuffer()

        buffer.append("  first command  ")
        buffer.append("\n")
        buffer.append("second result")

        XCTAssertEqual(buffer.text, "first command\nsecond result")
    }

    func testResetReusesBufferWithoutRetainingOldOutput() {
        var buffer = CompressionLogBuffer()
        buffer.append("old run")

        buffer.reset()
        buffer.append("new run")

        XCTAssertEqual(buffer.text, "new run")
    }
}
