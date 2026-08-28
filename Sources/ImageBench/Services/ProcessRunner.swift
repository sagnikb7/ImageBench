import Foundation

struct ProcessResult: Sendable {
    let status: Int32
    let output: String
    let error: String
}

private final class ProcessOutputCapture: @unchecked Sendable {
    let directory: URL
    let outputURL: URL
    let errorURL: URL
    let outputHandle: FileHandle
    let errorHandle: FileHandle

    init() throws {
        // File-backed capture avoids pipe-buffer deadlocks when third-party tools
        // emit large stdout/stderr streams and lets both runners share cleanup.
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("ImageBench-Process-\(UUID().uuidString)")
        outputURL = directory.appendingPathComponent("stdout")
        errorURL = directory.appendingPathComponent("stderr")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard FileManager.default.createFile(atPath: outputURL.path, contents: nil),
            FileManager.default.createFile(atPath: errorURL.path, contents: nil)
        else {
            throw CocoaError(.fileWriteUnknown)
        }
        outputHandle = try FileHandle(forWritingTo: outputURL)
        errorHandle = try FileHandle(forWritingTo: errorURL)
    }

    func result(status: Int32) -> ProcessResult {
        try? outputHandle.close()
        try? errorHandle.close()
        let output = (try? String(contentsOf: outputURL, encoding: .utf8)) ?? ""
        let error = (try? String(contentsOf: errorURL, encoding: .utf8)) ?? ""
        try? FileManager.default.removeItem(at: directory)
        return ProcessResult(status: status, output: output, error: error)
    }

    func discard() {
        try? outputHandle.close()
        try? errorHandle.close()
        try? FileManager.default.removeItem(at: directory)
    }
}

enum ProcessRunner {
    static func run(executable: URL, arguments: [String], environment: [String: String]? = nil) async throws -> ProcessResult {
        let capture = try ProcessOutputCapture()
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            process.environment = environment ?? ProcessInfo.processInfo.environment
            process.standardOutput = capture.outputHandle
            process.standardError = capture.errorHandle
            process.terminationHandler = { process in
                continuation.resume(returning: capture.result(status: process.terminationStatus))
            }
            do {
                try process.run()
            } catch {
                capture.discard()
                continuation.resume(throwing: error)
            }
        }
    }
}

final class CancellableProcessRunner: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancellationRequested = false

    func run(executable: URL, arguments: [String]) async throws -> ProcessResult {
        try Task.checkCancellation()
        let capture = try ProcessOutputCapture()
        let result = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let task = Process()
                task.executableURL = executable
                task.arguments = arguments
                task.standardOutput = capture.outputHandle
                task.standardError = capture.errorHandle
                task.terminationHandler = { [weak self] process in
                    self?.lock.withLock { self?.process = nil }
                    continuation.resume(returning: capture.result(status: process.terminationStatus))
                }
                do {
                    lock.withLock {
                        process = task
                        cancellationRequested = false
                    }
                    try task.run()
                    let shouldTerminate = lock.withLock { cancellationRequested } || Task.isCancelled
                    if shouldTerminate, task.isRunning { task.terminate() }
                } catch {
                    lock.withLock { process = nil }
                    capture.discard()
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            terminate()
        }
        try Task.checkCancellation()
        return result
    }

    func terminate() {
        lock.withLock {
            cancellationRequested = true
            if let process, process.isRunning { process.terminate() }
        }
    }
}

extension NSLock {
    fileprivate func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try body()
    }
}

extension String {
    var shellQuoted: String {
        if isEmpty { return "''" }
        return "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
