import Combine
import Foundation

@MainActor
final class CompressorViewModel: ObservableObject {
    private static let defaultOutputFolderName = "Compressed Output"

    @Published var inputFolder: URL?
    @Published var outputFolder: URL?
    @Published var images: [URL] = []
    @Published var totalBytes: Int64 = 0
    @Published var preset: CompressionPreset = .archive
    @Published var options = CompressionOptions()
    @Published var isScanning = false
    @Published var isRunning = false
    @Published var progress = 0.0
    @Published var currentFile = ""
    @Published private(set) var log = ""
    @Published var resultMessage = ""
    @Published var batchResult: CompressionBatchResult?

    private var task: Task<Void, Never>?
    private var isOutputFolderUserSelected = false
    private let runner = CancellableProcessRunner()
    private var logBuffer = CompressionLogBuffer()
    private var isLogVisible = false
    private var logPublishTask: Task<Void, Never>?

    init() {
        if let demoPath = ProcessInfo.processInfo.environment["IMAGEBENCH_DEMO_FOLDER"], !demoPath.isEmpty {
            let folder = URL(fileURLWithPath: demoPath, isDirectory: true)
            inputFolder = folder
            outputFolder = Self.defaultOutputFolder(for: folder)
            scan(folder)
        }
    }

    var selectionSummary: String {
        if isScanning { return "Scanning…" }
        return "\(images.count.formatted()) photo\(images.count == 1 ? "" : "s") • \(ByteCountFormatter.string(for: totalBytes))"
    }

    var metadataPolicy: MetadataPolicy {
        get {
            if options.removeAllMetadata { return .removeAll }
            if options.removeEXIF { return .removeEXIF }
            if options.removeGPS { return .removeLocation }
            return .keep
        }
        set {
            options.removeEXIF = newValue == .removeEXIF
            options.removeGPS = newValue == .removeLocation
            options.removeAllMetadata = newValue == .removeAll
        }
    }

    var inputBytesForLastRun: Int64 {
        guard let batchResult else { return 0 }
        return batchResult.successes.reduce(0) { $0 + ImageFileSupport.fileSize($1.input) }
    }

    var outputBytesForLastRun: Int64 { batchResult?.bytes ?? 0 }
    var sizeChangeBytes: Int64 { inputBytesForLastRun - outputBytesForLastRun }
    var sizeChangePercentage: Int {
        guard inputBytesForLastRun > 0 else { return 0 }
        return Int((Double(sizeChangeBytes) / Double(inputBytesForLastRun) * 100).rounded())
    }

    func chooseInput() {
        guard let folder = Panels.chooseFolder(prompt: "Choose an input folder") else { return }
        selectInputFolder(folder)
    }

    func selectInputFolder(_ folder: URL) {
        inputFolder = folder
        if !isOutputFolderUserSelected { outputFolder = Self.defaultOutputFolder(for: folder) }
        scan(folder)
    }

    func acceptDropped(_ urls: [URL]) -> Bool {
        guard !urls.isEmpty else { return false }
        if let folder = urls.first(where: { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }) {
            selectInputFolder(folder)
            return true
        }
        let supported = urls.filter(ImageFileSupport.supportsCompressionInput)
        guard !supported.isEmpty else {
            resultMessage = "Drop a folder or supported image files."
            return false
        }
        task?.cancel()
        images = supported.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        totalBytes = images.reduce(0) { $0 + ImageFileSupport.fileSize($1) }
        inputFolder = images.first?.deletingLastPathComponent()
        if !isOutputFolderUserSelected, let inputFolder { outputFolder = Self.defaultOutputFolder(for: inputFolder) }
        resultMessage = ""
        return true
    }

    func chooseOutput() {
        guard let folder = Panels.chooseFolder(prompt: "Choose an output folder") else { return }
        selectOutputFolder(folder)
    }

    func selectOutputFolder(_ folder: URL) {
        outputFolder = folder
        isOutputFolderUserSelected = true
    }

    func selectPreset(_ newValue: CompressionPreset) {
        preset = newValue
        options.apply(newValue)
        if newValue == .custom {
            options.quality = CompressionOptions.normalizedCustomQuality(options.quality)
        }
    }

    func setCustomQuality(_ quality: Double) {
        options.quality = CompressionOptions.normalizedCustomQuality(Int(quality.rounded()))
    }

    var failedInputs: [URL] { batchResult?.failures.map(\.input) ?? [] }

    func start(cjpeg: URL?, exiftool: URL?, inputs overrideInputs: [URL]? = nil) {
        let selectedInputs = overrideInputs ?? images
        guard let cjpeg, let outputFolder, !selectedInputs.isEmpty else { return }

        let job = CompressionJob(inputs: selectedInputs, outputFolder: outputFolder, cjpeg: cjpeg, exiftool: exiftool, options: options)
        do { _ = try CompressionPreflight.run(job: job) } catch {
            resultMessage = error.localizedDescription
            appendLog("PREFLIGHT ERROR: \(error.localizedDescription)")
            return
        }
        isRunning = true
        progress = 0
        resetLog()
        resultMessage = ""
        batchResult = nil
        task = Task {
            do {
                let result = try await CompressorEngine.run(job: job, runner: runner) { [weak self] completed, current, line in
                    guard let self else { return }
                    if self.currentFile != current { self.currentFile = current }
                    let nextProgress = job.inputs.isEmpty ? 0 : Double(completed) / Double(job.inputs.count)
                    if self.progress != nextProgress { self.progress = nextProgress }
                    self.appendLog(line)
                }
                batchResult = result
                if result.wasCancelled {
                    resultMessage =
                        "Cancelled • \(result.written) succeeded • \(result.failures.count) failed • \(result.skipped.count) skipped"
                } else {
                    resultMessage =
                        "Finished • \(result.written) succeeded • \(result.failures.count) failed • \(ByteCountFormatter.string(for: result.bytes)) output"
                    progress = 1
                }
            } catch is CancellationError {
                resultMessage = "Cancelled. Completed files were kept."
                appendLog("Operation cancelled.")
            } catch {
                resultMessage = error.localizedDescription
                appendLog("ERROR: \(error.localizedDescription)")
            }
            isRunning = false
        }
    }

    func cancel() {
        task?.cancel()
        runner.terminate()
    }

    func retryFailures(cjpeg: URL?, exiftool: URL?) {
        let failures = failedInputs
        guard !failures.isEmpty else { return }
        start(cjpeg: cjpeg, exiftool: exiftool, inputs: failures)
    }

    func revealOutput() {
        guard let outputFolder else { return }
        WorkspaceFileActions.reveal(folder: outputFolder)
    }

    func revealFailures() {
        WorkspaceFileActions.reveal(files: failedInputs)
    }

    func setLogVisible(_ isVisible: Bool) {
        isLogVisible = isVisible
        if isVisible {
            log = logBuffer.text
        } else {
            logPublishTask?.cancel()
            logPublishTask = nil
        }
    }

    private func scan(_ folder: URL) {
        task?.cancel()
        isScanning = true; images = []; totalBytes = 0
        task = Task {
            do {
                let excluded = outputFolder.map { [$0] } ?? []
                let found = try await Task.detached(priority: .userInitiated) {
                    try CompressionInputScanner.scan(folder: folder, excluding: excluded)
                }.value
                guard !Task.isCancelled else { return }
                images = found
                totalBytes = found.reduce(0) { $0 + ImageFileSupport.fileSize($1) }
                if ProcessInfo.processInfo.environment["IMAGEBENCH_DEMO_RESULT"] == "1", !found.isEmpty {
                    let failureInput = found.last!
                    let successfulInputs = found.dropLast()
                    let successes = successfulInputs.map { input in
                        CompressionSuccess(
                            input: input,
                            output: (outputFolder ?? folder).appendingPathComponent(input.displayName).appendingPathExtension("jpg"),
                            bytes: max(1, ImageFileSupport.fileSize(input) * 3 / 5)
                        )
                    }
                    batchResult = CompressionBatchResult(
                        successes: successes,
                        failures: [.init(input: failureInput, output: nil, message: "Demo: source needs attention")],
                        skipped: [],
                        wasCancelled: false
                    )
                    resultMessage = "Demo result for visual QA"
                }
                isScanning = false
            } catch is CancellationError {
                // A newer scan owns the visible state.
            } catch {
                images = []
                totalBytes = 0
                isScanning = false
                resultMessage = "Folder scan failed: \(error.localizedDescription)"
            }
        }
    }

    private static func defaultOutputFolder(for inputFolder: URL) -> URL {
        inputFolder.appendingPathComponent(defaultOutputFolderName, isDirectory: true)
    }

    private func resetLog() {
        logPublishTask?.cancel()
        logPublishTask = nil
        logBuffer.reset()
        log = ""
    }

    private func appendLog(_ line: String) {
        guard logBuffer.append(line), isLogVisible, logPublishTask == nil else { return }
        logPublishTask = Task {
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            log = logBuffer.text
            logPublishTask = nil
        }
    }
}
