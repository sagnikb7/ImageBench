import AppKit
import CoreText
import SwiftUI

enum BrandTypography {
    static let fontName = "Fraunces-Bold"
    static let wordmarkPointSize: CGFloat = 21
    static let bodyFontName = "Figtree-Regular"

    @discardableResult
    static func register() -> Bool {
        registrationSucceeded
    }

    static var wordmarkFont: Font {
        register()
        return .custom(fontName, size: wordmarkPointSize, relativeTo: .title2)
    }

    static var largeTitle: Font { reading(size: 26, relativeTo: .largeTitle).weight(.bold) }
    static var title2: Font { reading(size: 20, relativeTo: .title2).weight(.semibold) }
    static var title3: Font { reading(size: 17, relativeTo: .title3).weight(.semibold) }
    static var section: Font { reading(size: 14, relativeTo: .headline).weight(.semibold) }
    static var headline: Font { body.weight(.semibold) }
    static var body: Font { reading(size: 13, relativeTo: .body) }
    static var subheadline: Font { reading(size: 12, relativeTo: .subheadline) }
    static var caption: Font { reading(size: 11, relativeTo: .caption) }
    static var caption2: Font { reading(size: 10, relativeTo: .caption2) }

    private static func reading(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        register()
        return .custom(bodyFontName, size: size, relativeTo: style)
    }

    private static let registrationSucceeded: Bool = {
        let displayRegistered = registerResource("Fraunces", fontName: fontName)
        let bodyRegistered = registerResource("Figtree", fontName: bodyFontName)
        return displayRegistered && bodyRegistered
    }()

    private static func registerResource(_ resourceName: String, fontName: String) -> Bool {
        if NSFont(name: fontName, size: 12) != nil { return true }

        let candidates = [
            Bundle.module.url(forResource: resourceName, withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.module.url(forResource: resourceName, withExtension: "ttf"),
        ].compactMap { $0 }

        for url in candidates {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                return true
            }
            if NSFont(name: fontName, size: 12) != nil { return true }
        }
        return false
    }
}
