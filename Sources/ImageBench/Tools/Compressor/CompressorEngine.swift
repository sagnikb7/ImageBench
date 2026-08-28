import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CompressorError: LocalizedError {
    case commandFailed(String)
    case imageDecode(URL)
    case imageWrite(URL)
    case exiftoolRequired

    var errorDescription: String? {
        switch self {
        case .commandFailed(let text): "Command failed: \(text)"
        case .imageDecode(let url): "Could not decode \(url.lastPathComponent)."
        case .imageWrite(let url): "Could not write \(url.lastPathComponent)."
        case .exiftoolRequired: "ExifTool is required for selective metadata removal."
        }
    }
}

enum CompressorEngine {
    static func run(
        job: CompressionJob,
        runner: CancellableProcessRunner,
        update: @MainActor @escaping (_ completed: Int, _ current: String, _ log: String) -> Void
    ) async throws -> CompressionBatchResult {
        var batch = CompressionBatchResult()
        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent("ImageBench-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        for (index, input) in job.inputs.enumerated() {
            if Task.isCancelled {
                batch.wasCancelled = true
                batch.skipped.append(contentsOf: job.inputs[index...])
                break
            }
            await update(index, input.lastPathComponent, "")
            var output: URL?
            var source: URL?
            do {
                source = try makeCJPEGInput(for: input, in: tempRoot)
                let destination = ImageFileSupport.uniqueOutput(in: job.outputFolder, stem: input.displayName, extension: "jpg")
                output = destination
                let arguments = job.options.cjpegArguments + ["-outfile", destination.path, source!.path]
                await update(index, input.lastPathComponent, command(job.cjpeg, arguments))
                let result = try await runner.run(executable: job.cjpeg, arguments: arguments)
                try Task.checkCancellation()
                guard result.status == 0 else {
                    throw CompressorError.commandFailed(result.error.isEmpty ? result.output : result.error)
                }
                if !result.error.isEmpty { await update(index, input.lastPathComponent, result.error) }

                if !job.options.removeAllMetadata {
                    guard let exiftool = job.exiftool else { throw CompressorError.exiftoolRequired }
                    var metadataArgs = ["-overwrite_original", "-TagsFromFile", input.path, "-all:all"]
                    if job.options.removeEXIF {
                        metadataArgs.append("-EXIF:all=")
                    } else if job.options.removeGPS {
                        metadataArgs.append("-GPS:all=")
                    }
                    metadataArgs.append(destination.path)
                    await update(index, input.lastPathComponent, command(exiftool, metadataArgs))
                    let metadataResult = try await runner.run(executable: exiftool, arguments: metadataArgs)
                    try Task.checkCancellation()
                    guard metadataResult.status == 0 else {
                        throw CompressorError.commandFailed(metadataResult.error.isEmpty ? metadataResult.output : metadataResult.error)
                    }
                    if !metadataResult.output.isEmpty { await update(index, input.lastPathComponent, metadataResult.output) }
                }
                let bytes = ImageFileSupport.fileSize(destination)
                batch.successes.append(.init(input: input, output: destination, bytes: bytes))
                await update(
                    index + 1, input.lastPathComponent, "✓ \(destination.lastPathComponent) — \(ByteCountFormatter.string(for: bytes))")
            } catch is CancellationError {
                if let output { try? FileManager.default.removeItem(at: output) }
                batch.wasCancelled = true
                batch.skipped.append(contentsOf: job.inputs[index...])
                await update(index, input.lastPathComponent, "Cancelled — \(batch.skipped.count) file(s) skipped.")
                if let source { try? FileManager.default.removeItem(at: source) }
                break
            } catch {
                if let output { try? FileManager.default.removeItem(at: output) }
                let message = error.localizedDescription
                batch.failures.append(.init(input: input, output: output, message: message))
                await update(index + 1, input.lastPathComponent, "✕ \(input.lastPathComponent) — \(message)")
            }
            if let source { try? FileManager.default.removeItem(at: source) }
        }
        return batch
    }

    static func makeCJPEGInput(for input: URL, in tempRoot: URL) throws -> URL {
        // cjpeg is an encoder, not a JPEG decoder. ImageIO first normalizes every
        // supported source (including camera orientation) to a binary PPM. PPM is
        // intentionally used instead of ImageIO's BMP output because some BMP
        // variants are interpreted by mozjpeg as having zero pixel rows.
        guard let image = CIImage(contentsOf: input, options: [.applyOrientationProperty: true]) else {
            throw CompressorError.imageDecode(input)
        }
        let target = tempRoot.appendingPathComponent(UUID().uuidString).appendingPathExtension("ppm")
        let normalized = image.transformed(by: .init(translationX: -image.extent.minX, y: -image.extent.minY))
        do { try writePPM(try ImageRenderer.cgImage(normalized), to: target) } catch { throw CompressorError.imageWrite(target) }
        return target
    }

    private static func writePPM(_ image: CGImage, to url: URL) throws {
        let width = image.width
        let height = image.height
        let rgbaBytesPerRow = width * 4
        var rgba = [UInt8](repeating: 0, count: rgbaBytesPerRow * height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue
        guard
            let context = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: rgbaBytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else { throw ImageRendererError.render }
        context.interpolationQuality = .none
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw ImageRendererError.destination
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.write(contentsOf: Data("P6\n\(width) \(height)\n255\n".utf8))

        var rgbRow = [UInt8](repeating: 0, count: width * 3)
        for row in 0..<height {
            try Task.checkCancellation()
            let rgbaStart = row * rgbaBytesPerRow
            for column in 0..<width {
                let source = rgbaStart + column * 4
                let destination = column * 3
                rgbRow[destination] = rgba[source]
                rgbRow[destination + 1] = rgba[source + 1]
                rgbRow[destination + 2] = rgba[source + 2]
            }
            try handle.write(contentsOf: Data(rgbRow))
        }
    }

    private static func command(_ executable: URL, _ arguments: [String]) -> String {
        ([executable.path] + arguments).map(\.shellQuoted).joined(separator: " ")
    }
}
