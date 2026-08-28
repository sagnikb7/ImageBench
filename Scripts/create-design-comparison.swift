#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("usage: create-design-comparison.swift <reference> <implementation> <output>\n", stderr)
    exit(2)
}

let referenceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let implementationURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard let reference = NSImage(contentsOf: referenceURL),
      let implementation = NSImage(contentsOf: implementationURL) else {
    fputs("could not load comparison images\n", stderr)
    exit(1)
}

let canvasSize = NSSize(width: 2500, height: 880)
let canvas = NSImage(size: canvasSize)
canvas.lockFocus()
NSColor(calibratedWhite: 0.09, alpha: 1).setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
    .foregroundColor: NSColor.white
]

func draw(_ image: NSImage, label: String, in slot: NSRect) {
    let labelHeight: CGFloat = 42
    let imageSlot = NSRect(x: slot.minX, y: slot.minY, width: slot.width, height: slot.height - labelHeight)
    let scale = min(imageSlot.width / image.size.width, imageSlot.height / image.size.height)
    let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    let rect = NSRect(
        x: imageSlot.midX - size.width / 2,
        y: imageSlot.midY - size.height / 2,
        width: size.width,
        height: size.height
    )
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    NSString(string: label).draw(at: NSPoint(x: slot.minX, y: slot.maxY - 32), withAttributes: titleAttributes)
}

draw(reference, label: "Reference — Gallery Workbench", in: NSRect(x: 20, y: 20, width: 1220, height: 840))
draw(implementation, label: "Implementation — native macOS app", in: NSRect(x: 1260, y: 20, width: 1220, height: 840))

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("could not encode comparison image\n", stderr)
    exit(1)
}
try png.write(to: outputURL)
