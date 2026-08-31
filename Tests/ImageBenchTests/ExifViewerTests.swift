import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import ImageBench

final class ExifViewerTests: XCTestCase {
    func testPopularRAWExtensionsAreAcceptedWithoutChangingEditorFormats() {
        for fileExtension in ["dng", "cr2", "cr3", "nef", "arw", "raf", "orf", "rw2", "pef"] {
            XCTAssertTrue(ExifFileSupport.supports(URL(fileURLWithPath: "camera.\(fileExtension)")))
            XCTAssertTrue(ExifFileSupport.isRAW(URL(fileURLWithPath: "camera.\(fileExtension.uppercased())")))
        }
        XCTAssertFalse(ImageFileSupport.supportsFormatPreservingOutput(URL(fileURLWithPath: "camera.nef")))
    }

    func testInspectionGroupsImageCameraExposureAndLocationMetadata() throws {
        let temp = try TemporaryDirectory()
        let url = temp.url.appendingPathComponent("camera.jpg")
        try TestImageFactory.make(
            at: url,
            width: 400,
            height: 300,
            type: .jpeg,
            metadata: [
                kCGImagePropertyTIFFDictionary: [
                    kCGImagePropertyTIFFMake: "ImageBench Camera Co.",
                    kCGImagePropertyTIFFModel: "Workbench 1",
                ],
                kCGImagePropertyExifDictionary: [
                    kCGImagePropertyExifFNumber: 2.8,
                    kCGImagePropertyExifExposureTime: 0.008,
                    kCGImagePropertyExifISOSpeedRatings: [200],
                    kCGImagePropertyExifLensModel: "35 mm Prime",
                ],
                kCGImagePropertyGPSDictionary: [
                    kCGImagePropertyGPSLatitude: 22.5726,
                    kCGImagePropertyGPSLatitudeRef: "N",
                    kCGImagePropertyGPSLongitude: 88.3639,
                    kCGImagePropertyGPSLongitudeRef: "E",
                ],
            ]
        )

        let result = try ExifViewerEngine.inspect(url)

        XCTAssertNotNil(result.preview)
        XCTAssertEqual(result.histogram.red.count, 256)
        XCTAssertTrue(result.sections.contains { $0.title == "Image" && $0.fields.contains { $0.value == "400 × 300 px" } })
        XCTAssertTrue(result.sections.contains { $0.title == "Camera & Lens" })
        XCTAssertTrue(result.sections.contains { $0.title == "Exposure" })
        XCTAssertTrue(result.sections.contains { $0.title == "Location" })
        XCTAssertEqual(result.coordinate, ExifCoordinate(latitude: 22.5726, longitude: 88.3639))
        XCTAssertEqual(result.coordinate?.displayValue, "22.572600, 88.363900")
    }

    func testCoordinateValidationAndGoogleMapsURL() throws {
        XCTAssertNil(ExifCoordinate(latitude: .nan, longitude: 10))
        XCTAssertNil(ExifCoordinate(latitude: 91, longitude: 10))
        XCTAssertNil(ExifCoordinate(latitude: 10, longitude: -181))

        let coordinate = try XCTUnwrap(ExifCoordinate(latitude: -33.8688, longitude: 151.2093))
        let url = try XCTUnwrap(coordinate.googleMapsURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            })

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.path, "/maps/search/")
        XCTAssertEqual(query["api"], "1")
        XCTAssertEqual(query["query"], "-33.868800, 151.209300")
    }

    func testInspectionAppliesSouthernAndWesternGPSReferences() throws {
        let temp = try TemporaryDirectory()
        let url = temp.url.appendingPathComponent("southern-western.jpg")
        try TestImageFactory.make(
            at: url,
            width: 40,
            height: 30,
            type: .jpeg,
            metadata: [
                kCGImagePropertyGPSDictionary: [
                    kCGImagePropertyGPSLatitude: 33.8688,
                    kCGImagePropertyGPSLatitudeRef: "S",
                    kCGImagePropertyGPSLongitude: 70.6693,
                    kCGImagePropertyGPSLongitudeRef: "W",
                ]
            ]
        )

        let result = try ExifViewerEngine.inspect(url)

        XCTAssertEqual(result.coordinate, ExifCoordinate(latitude: -33.8688, longitude: -70.6693))
        XCTAssertTrue(
            result.sections.contains {
                $0.title == "Location"
                    && $0.fields.contains { $0.label == "Coordinates" && $0.value == "-33.868800, -70.669300" }
            }
        )
    }

    func testHistogramUsesBoundedNormalizedChannels() throws {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let context = CGContext(
                data: nil,
                width: 20,
                height: 10,
                bitsPerComponent: 8,
                bytesPerRow: 80,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return XCTFail("Could not create histogram fixture") }
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 10))
        let image = try XCTUnwrap(context.makeImage())

        let histogram = try ExifViewerEngine.histogram(from: image)
        let luminancePeak = try XCTUnwrap(
            histogram.luminance.enumerated().max(by: { $0.element < $1.element })
        )
        let redPeak = try XCTUnwrap(histogram.red.enumerated().max(by: { $0.element < $1.element }))
        let greenPeak = try XCTUnwrap(histogram.green.enumerated().max(by: { $0.element < $1.element }))
        let bluePeak = try XCTUnwrap(histogram.blue.enumerated().max(by: { $0.element < $1.element }))
        let expectedLuminance = Int(
            (0.2126 * Double(redPeak.offset) + 0.7152 * Double(greenPeak.offset)
                + 0.0722 * Double(bluePeak.offset)).rounded()
        )

        XCTAssertEqual(histogram.red.count, 256)
        XCTAssertEqual(histogram.red[255], 1, accuracy: 0.001)
        XCTAssertEqual(luminancePeak.offset, expectedLuminance, accuracy: 1)
        XCTAssertGreaterThan(luminancePeak.element, 0.9)
        XCTAssertTrue(histogram.green.allSatisfy { (0...1).contains($0) })
    }

    func testUnsupportedExtensionFailsBeforeDecode() {
        XCTAssertThrowsError(try ExifViewerEngine.inspect(URL(fileURLWithPath: "/tmp/notes.txt"))) { error in
            XCTAssertEqual(error as? ExifViewerError, .unsupportedFormat)
        }
    }
}
