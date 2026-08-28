import AppKit
import CoreGraphics
import Foundation
import ImageIO

enum ExifViewerError: LocalizedError, Equatable {
    case unsupportedFormat
    case unreadableFile
    case metadataUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Choose a supported image or RAW camera file."
        case .unreadableFile:
            "This file could not be opened by the image codecs installed on this Mac."
        case .metadataUnavailable:
            "No readable image metadata was found in this file."
        }
    }
}

enum ExifViewerEngine {
    static func inspect(_ url: URL) throws -> ExifInspection {
        guard ExifFileSupport.supports(url) else { throw ExifViewerError.unsupportedFormat }
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw ExifViewerError.unreadableFile }
        guard let rawProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
            throw ExifViewerError.metadataUnavailable
        }
        let properties = stringDictionary(rawProperties)
        guard !properties.isEmpty else { throw ExifViewerError.metadataUnavailable }

        try Task.checkCancellation()
        let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1_400,
                kCGImageSourceShouldCacheImmediately: true,
            ] as CFDictionary
        )
        let preview = thumbnail.map { NSImage(cgImage: $0, size: NSSize(width: $0.width, height: $0.height)) }
        let histogram = try thumbnail.map(histogram(from:)) ?? .empty
        let sections = metadataSections(url: url, source: source, properties: properties)

        return ExifInspection(
            url: url,
            preview: preview,
            histogram: histogram,
            sections: sections,
            isRAW: ExifFileSupport.isRAW(url)
        )
    }

    static func histogram(from image: CGImage) throws -> ExifHistogram {
        let maximumDimension = 320.0
        let scale = min(1, maximumDimension / Double(max(image.width, image.height)))
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { throw ExifViewerError.unreadableFile }

        var red = [Int](repeating: 0, count: 256)
        var green = [Int](repeating: 0, count: 256)
        var blue = [Int](repeating: 0, count: 256)
        var luminance = [Int](repeating: 0, count: 256)
        for row in 0..<height {
            if row.isMultiple(of: 32) { try Task.checkCancellation() }
            for column in 0..<width {
                let offset = (row * width + column) * 4
                guard pixels[offset + 3] > 0 else { continue }
                let r = Int(pixels[offset])
                let g = Int(pixels[offset + 1])
                let b = Int(pixels[offset + 2])
                red[r] += 1
                green[g] += 1
                blue[b] += 1
                let weightedRed = 0.2126 * Double(r)
                let weightedGreen = 0.7152 * Double(g)
                let weightedBlue = 0.0722 * Double(b)
                let luminanceBin = min(255, Int((weightedRed + weightedGreen + weightedBlue).rounded()))
                luminance[luminanceBin] += 1
            }
        }

        let transformed = [luminance, red, green, blue].map { channel in
            channel.map { log1p(Double($0)) }
        }
        let maximum = transformed.flatMap { $0 }.max() ?? 1
        let normalized = transformed.map { channel in channel.map { maximum > 0 ? $0 / maximum : 0 } }
        return ExifHistogram(luminance: normalized[0], red: normalized[1], green: normalized[2], blue: normalized[3])
    }

    private static func metadataSections(
        url: URL,
        source: CGImageSource,
        properties: [String: Any]
    ) -> [ExifMetadataSection] {
        let tiff = nestedDictionary(properties, key: kCGImagePropertyTIFFDictionary)
        let exif = nestedDictionary(properties, key: kCGImagePropertyExifDictionary)
        let exifAux = nestedDictionary(properties, key: kCGImagePropertyExifAuxDictionary)
        let gps = nestedDictionary(properties, key: kCGImagePropertyGPSDictionary)
        let raw = nestedDictionary(properties, key: kCGImagePropertyRawDictionary)

        var sections: [ExifMetadataSection] = []
        let resources = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        sections.append(
            ExifMetadataSection(
                title: "File",
                fields: compactFields([
                    field("Name", url.lastPathComponent),
                    field("Format", fileFormat(url: url, source: source)),
                    field("File Size", resources?.fileSize.map { byteCount(Int64($0)) }),
                    field("Modified", resources?.contentModificationDate?.formatted(date: .abbreviated, time: .shortened)),
                ])
            )
        )

        sections.appendIfNotEmpty(
            title: "Image",
            fields: compactFields([
                dimensionsField(properties),
                megapixelsField(properties),
                field("Bit Depth", number(properties, key: kCGImagePropertyDepth).map { "\(Int($0)) bits" }),
                field("Color Model", value(properties, key: kCGImagePropertyColorModel)),
                field("Color Profile", value(properties, key: kCGImagePropertyProfileName)),
                field("Orientation", orientationDescription(number(properties, key: kCGImagePropertyOrientation))),
                dpiField(properties),
                field("Alpha Channel", bool(properties, key: kCGImagePropertyHasAlpha).map { $0 ? "Yes" : "No" }),
            ])
        )

        sections.appendIfNotEmpty(
            title: "Capture",
            fields: compactFields([
                field("Captured", value(exif, key: kCGImagePropertyExifDateTimeOriginal) ?? value(tiff, key: kCGImagePropertyTIFFDateTime)),
                field("Digitized", value(exif, key: kCGImagePropertyExifDateTimeDigitized)),
                field("Software", value(tiff, key: kCGImagePropertyTIFFSoftware)),
            ])
        )

        sections.appendIfNotEmpty(
            title: "Camera & Lens",
            fields: compactFields([
                field("Camera Make", value(tiff, key: kCGImagePropertyTIFFMake)),
                field("Camera Model", value(tiff, key: kCGImagePropertyTIFFModel)),
                field(
                    "Owner",
                    value(exif, key: kCGImagePropertyExifCameraOwnerName)
                        ?? value(exifAux, key: kCGImagePropertyExifAuxOwnerName)
                ),
                field("Body Serial", value(exif, key: kCGImagePropertyExifBodySerialNumber)),
                field("Lens Make", value(exif, key: kCGImagePropertyExifLensMake)),
                field(
                    "Lens Model",
                    value(exif, key: kCGImagePropertyExifLensModel)
                        ?? value(exifAux, key: kCGImagePropertyExifAuxLensModel)
                ),
                field("Focal Length", number(exif, key: kCGImagePropertyExifFocalLength).map { decimal($0, suffix: " mm") }),
                field("35 mm Equivalent", number(exif, key: kCGImagePropertyExifFocalLenIn35mmFilm).map { decimal($0, suffix: " mm") }),
            ])
        )

        sections.appendIfNotEmpty(
            title: "Exposure",
            fields: compactFields([
                field("Shutter Speed", number(exif, key: kCGImagePropertyExifExposureTime).map(shutterSpeed)),
                field("Aperture", number(exif, key: kCGImagePropertyExifFNumber).map { "ƒ/\(decimal($0))" }),
                field("ISO", isoValue(exif)),
                field("Exposure Bias", number(exif, key: kCGImagePropertyExifExposureBiasValue).map { signedDecimal($0, suffix: " EV") }),
                field("Metering", meteringDescription(number(exif, key: kCGImagePropertyExifMeteringMode))),
                field("Flash", flashDescription(number(exif, key: kCGImagePropertyExifFlash))),
                field("White Balance", whiteBalanceDescription(number(exif, key: kCGImagePropertyExifWhiteBalance))),
            ])
        )

        sections.appendIfNotEmpty(title: "Location", fields: locationFields(gps))
        sections.appendIfNotEmpty(
            title: "Rights & Workflow",
            fields: compactFields([
                field("Description", value(tiff, key: kCGImagePropertyTIFFImageDescription)),
                field("Artist", value(tiff, key: kCGImagePropertyTIFFArtist)),
                field("Copyright", value(tiff, key: kCGImagePropertyTIFFCopyright)),
            ])
        )

        if ExifFileSupport.isRAW(url) {
            var rawFields = [ExifMetadataField(label: "RAW Extension", value: url.pathExtension.uppercased())]
            rawFields.append(contentsOf: flattenedFields(raw).prefix(40))
            for key in makerDictionaryKeys {
                rawFields.append(contentsOf: flattenedFields(nestedDictionary(properties, key: key)).prefix(20))
            }
            sections.append(ExifMetadataSection(title: "RAW & Maker Notes", fields: deduplicated(rawFields)))
        }
        return sections
    }

    private static let makerDictionaryKeys: [CFString] = [
        kCGImagePropertyMakerCanonDictionary,
        kCGImagePropertyMakerNikonDictionary,
        kCGImagePropertyMakerMinoltaDictionary,
        kCGImagePropertyMakerFujiDictionary,
        kCGImagePropertyMakerOlympusDictionary,
        kCGImagePropertyMakerPentaxDictionary,
    ]

    private static func stringDictionary(_ dictionary: CFDictionary) -> [String: Any] {
        stringDictionary(dictionary as NSDictionary)
    }

    private static func stringDictionary(_ value: Any?) -> [String: Any] {
        guard let dictionary = value as? NSDictionary else { return [:] }
        var result: [String: Any] = [:]
        for (key, value) in dictionary {
            result[String(describing: key)] = value
        }
        return result
    }

    private static func nestedDictionary(_ dictionary: [String: Any], key: CFString) -> [String: Any] {
        stringDictionary(dictionary[key as String])
    }

    private static func value(_ dictionary: [String: Any], key: CFString) -> String? {
        formattedValue(dictionary[key as String])
    }

    private static func number(_ dictionary: [String: Any], key: CFString) -> Double? {
        (dictionary[key as String] as? NSNumber)?.doubleValue
    }

    private static func bool(_ dictionary: [String: Any], key: CFString) -> Bool? {
        (dictionary[key as String] as? NSNumber)?.boolValue
    }

    private static func field(_ label: String, _ value: String?) -> ExifMetadataField? {
        guard let value, !value.isEmpty else { return nil }
        return ExifMetadataField(label: label, value: value)
    }

    private static func compactFields(_ fields: [ExifMetadataField?]) -> [ExifMetadataField] {
        fields.compactMap { $0 }
    }

    private static func dimensionsField(_ properties: [String: Any]) -> ExifMetadataField? {
        guard let width = number(properties, key: kCGImagePropertyPixelWidth),
            let height = number(properties, key: kCGImagePropertyPixelHeight)
        else { return nil }
        return ExifMetadataField(label: "Dimensions", value: "\(Int(width)) × \(Int(height)) px")
    }

    private static func megapixelsField(_ properties: [String: Any]) -> ExifMetadataField? {
        guard let width = number(properties, key: kCGImagePropertyPixelWidth),
            let height = number(properties, key: kCGImagePropertyPixelHeight)
        else { return nil }
        return ExifMetadataField(label: "Resolution", value: String(format: "%.1f MP", width * height / 1_000_000))
    }

    private static func dpiField(_ properties: [String: Any]) -> ExifMetadataField? {
        guard let width = number(properties, key: kCGImagePropertyDPIWidth),
            let height = number(properties, key: kCGImagePropertyDPIHeight)
        else { return nil }
        return ExifMetadataField(label: "DPI", value: "\(Int(width.rounded())) × \(Int(height.rounded()))")
    }

    private static func isoValue(_ exif: [String: Any]) -> String? {
        if let values = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [NSNumber], let first = values.first {
            return first.stringValue
        }
        return value(exif, key: kCGImagePropertyExifISOSpeedRatings)
    }

    private static func locationFields(_ gps: [String: Any]) -> [ExifMetadataField] {
        var fields: [ExifMetadataField?] = []
        if let latitude = number(gps, key: kCGImagePropertyGPSLatitude),
            let longitude = number(gps, key: kCGImagePropertyGPSLongitude)
        {
            let latitudeRef = value(gps, key: kCGImagePropertyGPSLatitudeRef) ?? "N"
            let longitudeRef = value(gps, key: kCGImagePropertyGPSLongitudeRef) ?? "E"
            let signedLatitude = latitudeRef.uppercased() == "S" ? -latitude : latitude
            let signedLongitude = longitudeRef.uppercased() == "W" ? -longitude : longitude
            fields.append(field("Coordinates", String(format: "%.6f, %.6f", signedLatitude, signedLongitude)))
        }
        fields.append(field("Altitude", number(gps, key: kCGImagePropertyGPSAltitude).map { decimal($0, suffix: " m") }))
        fields.append(field("GPS Time", value(gps, key: kCGImagePropertyGPSTimeStamp)))
        fields.append(field("Map Datum", value(gps, key: kCGImagePropertyGPSMapDatum)))
        return compactFields(fields)
    }

    private static func flattenedFields(_ dictionary: [String: Any]) -> [ExifMetadataField] {
        dictionary.keys.sorted().compactMap { key in
            field(prettyLabel(key), formattedValue(dictionary[key]))
        }
    }

    private static func formattedValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            string
        case let number as NSNumber:
            number.stringValue
        case let values as [Any]:
            values.compactMap(formattedValue).joined(separator: ", ")
        case let data as Data:
            "\(data.count) bytes"
        case nil:
            nil
        default:
            String(describing: value!)
        }
    }

    private static func prettyLabel(_ key: String) -> String {
        key.replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }

    private static func deduplicated(_ fields: [ExifMetadataField]) -> [ExifMetadataField] {
        var labels = Set<String>()
        return fields.filter { labels.insert($0.label).inserted }
    }

    private static func fileFormat(url: URL, source: CGImageSource) -> String {
        let fileExtension = url.pathExtension.uppercased()
        guard let identifier = CGImageSourceGetType(source) as String? else { return fileExtension }
        return "\(fileExtension) · \(identifier)"
    }

    private static func byteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private static func decimal(_ value: Double, suffix: String = "") -> String {
        let formatted = value.formatted(.number.precision(.fractionLength(0...2)))
        return "\(formatted)\(suffix)"
    }

    private static func signedDecimal(_ value: Double, suffix: String) -> String {
        "\(value >= 0 ? "+" : "")\(decimal(value))\(suffix)"
    }

    private static func shutterSpeed(_ seconds: Double) -> String {
        guard seconds > 0 else { return decimal(seconds, suffix: " s") }
        if seconds < 1 { return "1/\(Int((1 / seconds).rounded())) s" }
        return decimal(seconds, suffix: " s")
    }

    private static func orientationDescription(_ value: Double?) -> String? {
        guard let value else { return nil }
        return [
            1: "Upright", 2: "Mirrored horizontally", 3: "Rotated 180°", 4: "Mirrored vertically",
            5: "Mirrored and rotated left", 6: "Rotated right", 7: "Mirrored and rotated right", 8: "Rotated left",
        ][Int(value)] ?? "Code \(Int(value))"
    }

    private static func meteringDescription(_ value: Double?) -> String? {
        guard let value else { return nil }
        return [0: "Unknown", 1: "Average", 2: "Center-weighted", 3: "Spot", 4: "Multi-spot", 5: "Pattern", 6: "Partial"][Int(value)]
            ?? "Mode \(Int(value))"
    }

    private static func flashDescription(_ value: Double?) -> String? {
        guard let value else { return nil }
        return Int(value) & 1 == 1 ? "Fired" : "Did not fire"
    }

    private static func whiteBalanceDescription(_ value: Double?) -> String? {
        guard let value else { return nil }
        return Int(value) == 0 ? "Auto" : "Manual"
    }
}

private extension Array where Element == ExifMetadataSection {
    mutating func appendIfNotEmpty(title: String, fields: [ExifMetadataField]) {
        guard !fields.isEmpty else { return }
        append(ExifMetadataSection(title: title, fields: fields))
    }
}
