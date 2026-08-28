import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class TemporaryDirectory {
    let url: URL

    init(name: String = #function) throws {
        let safeName = name.replacingOccurrences(of: "/", with: "-")
        url = FileManager.default.temporaryDirectory.appendingPathComponent("ImageBenchTests-\(safeName)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: url) }
}

enum TestImageFactory {
    static func supportsEncoding(_ type: UTType) -> Bool {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else { return false }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let context = CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
            let image = context.makeImage()
        else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }

    static func make(
        at url: URL,
        width: Int,
        height: Int,
        type: UTType? = nil,
        metadata: [CFString: Any] = [:],
        painter: (CGContext, CGRect) -> Void = { context, rect in
            context.setFillColor(CGColor(red: 0.18, green: 0.42, blue: 0.76, alpha: 1))
            context.fill(rect)
        }
    ) throws {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { throw ImageRendererError.render }
        painter(context, CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw ImageRendererError.render }
        let outputType = type ?? ImageFileSupport.contentType(for: url)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, outputType.identifier as CFString, 1, nil) else {
            throw ImageRendererError.destination
        }
        var properties = metadata
        properties[kCGImageDestinationLossyCompressionQuality] = 0.96
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageRendererError.destination }
    }

    static func dimensions(of url: URL) throws -> CGSize {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            throw ImageRendererError.decode
        }
        return CGSize(width: width, height: height)
    }

    static func pixel(in image: CGImage, x: Int, y: Int) throws -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        guard x >= 0, y >= 0, x < image.width, y < image.height else { throw ImageRendererError.render }
        // Bitmap providers are free to use BGRA or alpha-first storage. NSBitmapImageRep
        // interprets that metadata before exposing device-independent color components.
        let representation = NSBitmapImageRep(cgImage: image)
        guard let color = representation.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else {
            throw ImageRendererError.render
        }
        return (
            UInt8((color.redComponent * 255).rounded()),
            UInt8((color.greenComponent * 255).rounded()),
            UInt8((color.blueComponent * 255).rounded()),
            UInt8((color.alphaComponent * 255).rounded())
        )
    }
}

enum TestTools {
    static var architecture: String {
        #if arch(arm64)
            "arm64"
        #else
            "x86_64"
        #endif
    }

    static func cjpeg() throws -> URL {
        try requireExecutable(
            candidates: [
                workspace.appendingPathComponent("Vendor/Tools/\(architecture)/cjpeg"),
                workspace.appendingPathComponent("dist/ImageBench.app/Contents/Resources/bin/\(architecture)/cjpeg"),
                URL(fileURLWithPath: "/opt/homebrew/opt/mozjpeg/bin/cjpeg"),
                URL(fileURLWithPath: "/usr/local/opt/mozjpeg/bin/cjpeg"),
            ], name: "mozjpeg cjpeg")
    }

    static func exiftool() throws -> URL {
        try requireExecutable(
            candidates: [
                workspace.appendingPathComponent("Vendor/Tools/exiftool"),
                workspace.appendingPathComponent("dist/ImageBench.app/Contents/Resources/bin/exiftool"),
                URL(fileURLWithPath: "/opt/homebrew/bin/exiftool"),
                URL(fileURLWithPath: "/usr/local/bin/exiftool"),
            ], name: "ExifTool")
    }

    static var workspace: URL { URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true) }

    private static func requireExecutable(candidates: [URL], name: String) throws -> URL {
        guard let result = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw XCTSkip("\(name) is unavailable; run Scripts/fetch-dependencies.sh for integration tests.")
        }
        return result
    }
}

func XCTAssertApproximately(_ value: UInt8, _ expected: UInt8, tolerance: UInt8 = 5, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertLessThanOrEqual(abs(Int(value) - Int(expected)), Int(tolerance), file: file, line: line)
}
