import Foundation
import XCTest
@testable import ImageBench

final class CompressionOutputDirectoryTests: XCTestCase {
    func testConcurrentReservationsNeverShareAnOutputFolder() async throws {
        let temp = try TemporaryDirectory()
        let root = temp.url
        let folders = try await withThrowingTaskGroup(of: URL.self) { group in
            for _ in 0..<20 {
                group.addTask { try CompressionOutputDirectory.reserve(in: root) }
            }
            var result: [URL] = []
            for try await folder in group { result.append(folder) }
            return result
        }
        XCTAssertEqual(Set(folders).count, 20)
        XCTAssertTrue(folders.allSatisfy(CompressionOutputDirectory.isMarked))
    }

    func testDanglingSymlinkIsNotReplacedByOutputReservation() throws {
        let temp = try TemporaryDirectory()
        let link = temp.url.appendingPathComponent("compressed_output")
        let missing = temp.url.appendingPathComponent("missing")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: missing)
        let output = try CompressionOutputDirectory.reserve(in: temp.url)
        XCTAssertEqual(output.lastPathComponent, "compressed_output_1")
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), missing.path)
    }
}
