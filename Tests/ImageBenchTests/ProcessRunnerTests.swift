import Foundation
import XCTest
@testable import ImageBench

final class ProcessRunnerTests: XCTestCase {
    func testCapturesStdoutStderrAndExitStatus() async throws {
        let result = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf 'hello'; printf 'warning' >&2; exit 7"]
        )
        XCTAssertEqual(result.status, 7)
        XCTAssertEqual(result.output, "hello")
        XCTAssertEqual(result.error, "warning")
    }

    func testPassesCustomEnvironmentWithoutShellInterpolation() async throws {
        let result = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/usr/bin/env"),
            arguments: [],
            environment: ["IMAGEBENCH_TEST_VALUE": "space and ' quote"]
        )
        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(result.output.contains("IMAGEBENCH_TEST_VALUE=space and ' quote"))
    }

    func testLargeOutputDoesNotDeadlock() async throws {
        let result = try await ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "yes O | head -c 1048576; yes E | head -c 1048576 >&2"]
        )
        XCTAssertEqual(result.status, 0)
        XCTAssertEqual(result.output.utf8.count, 1_048_576)
        XCTAssertEqual(result.error.utf8.count, 1_048_576)
    }

    func testMissingExecutableThrows() async {
        do {
            _ = try await ProcessRunner.run(executable: URL(fileURLWithPath: "/definitely/missing/imagebench-command"), arguments: [])
            XCTFail("Expected launch to fail")
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testCancellationTerminatesLongRunningProcessPromptly() async throws {
        let runner = CancellableProcessRunner()
        let start = ContinuousClock.now
        let task = Task {
            try await runner.run(executable: URL(fileURLWithPath: "/bin/sleep"), arguments: ["10"])
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // Expected.
        }
        XCTAssertLessThan(start.duration(to: .now), .seconds(2))
    }

    func testRunnerCanBeReusedAfterCancellation() async throws {
        let runner = CancellableProcessRunner()
        let cancelled = Task { try await runner.run(executable: URL(fileURLWithPath: "/bin/sleep"), arguments: ["10"]) }
        try await Task.sleep(for: .milliseconds(50))
        cancelled.cancel()
        _ = try? await cancelled.value

        let result = try await runner.run(executable: URL(fileURLWithPath: "/usr/bin/printf"), arguments: ["reused"])
        XCTAssertEqual(result.status, 0)
        XCTAssertEqual(result.output, "reused")
    }
}
