#!/usr/bin/env swift

import AppKit
import SwiftUI

private struct AppIconArtwork: View {
    let canvasSize: CGFloat

    var body: some View {
        let markSize = canvasSize * 0.805

        ZStack {
            Color.clear
            RoundedRectangle(cornerRadius: markSize * 0.24, style: .continuous)
                .fill(Color(red: 0.94, green: 0.35, blue: 0.16).gradient)
                .frame(width: markSize, height: markSize)
            Image(systemName: "photo.stack.fill")
                .font(.system(size: markSize * 0.43, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: canvasSize, height: canvasSize)
    }
}

@MainActor
private func renderIcon(size: Int, destination: URL) throws {
    let renderer = ImageRenderer(content: AppIconArtwork(canvasSize: CGFloat(size)))
    renderer.proposedSize = ProposedViewSize(width: CGFloat(size), height: CGFloat(size))
    renderer.scale = 1

    guard
        let image = renderer.nsImage,
        let representation = image.tiffRepresentation.flatMap(NSBitmapImageRep.init),
        let data = representation.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    try data.write(to: destination, options: .atomic)
}

@MainActor
private func generateIcons() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let resourceIcon = root.appendingPathComponent("Sources/ImageBench/Resources/AppIcon.png")
    let assetDirectory = root.appendingPathComponent("Packaging/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
    let assets = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1_024),
    ]

    try renderIcon(size: 1_024, destination: resourceIcon)
    for (filename, size) in assets {
        try renderIcon(size: size, destination: assetDirectory.appendingPathComponent(filename))
    }
}

try await MainActor.run {
    try generateIcons()
}
