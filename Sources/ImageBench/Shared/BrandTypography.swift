import AppKit
import CoreText
import SwiftUI

enum BrandTypography {
    static let fontName = "ArchivoNarrow-Regular"

    @discardableResult
    static func register() -> Bool {
        registrationSucceeded
    }

    static var wordmarkFont: Font {
        register()
        return .custom(fontName, size: 23, relativeTo: .title2).weight(.bold)
    }

    private static let registrationSucceeded: Bool = {
        if NSFont(name: fontName, size: 12) != nil { return true }

        let resourceName = "ArchivoNarrow[wght]"
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
    }()
}
