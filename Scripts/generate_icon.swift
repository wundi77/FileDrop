#!/usr/bin/env swift
// Generates a full macOS .iconset (all required PNG sizes) for FileDrop.
// Draws a rounded-squircle glass-blue icon with a tray/drop glyph, matching
// the panel's accent color from Sources/FileDrop/Theme/Theme.swift.
//
// Usage: swift Scripts/generate_icon.swift <output.iconset directory>

import AppKit

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("Usage: generate_icon.swift <output.iconset directory>\n".data(using: .utf8)!)
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let tinted = NSImage(size: size)
        tinted.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: size)
        rect.fill(using: .sourceOver)
        draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
        tinted.unlockFocus()
        return tinted
    }
}

func renderIcon(pixelSize: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    let size = CGFloat(pixelSize)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    let cg = context.cgContext
    cg.saveGState()
    path.addClip()

    // Glass-blue gradient, matching the panel's accent color (Theme.swift).
    let colors = [
        NSColor(red: 0.40, green: 0.60, blue: 0.99, alpha: 1).cgColor,
        NSColor(red: 0.22, green: 0.36, blue: 0.86, alpha: 1).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
        cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    }

    // Subtle glass sheen near the top, echoing the panel's vibrancy highlight.
    NSColor.white.withAlphaComponent(0.16).setFill()
    NSRect(x: 0, y: size * 0.56, width: size, height: size * 0.46).fill()

    cg.restoreGState()

    // Tray/drop glyph, centered, in white — mirrors the menu-bar icon.
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .semibold)
    if let symbol = NSImage(systemSymbolName: "tray.and.arrow.down.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = symbol.tinted(with: .white)
        let glyphSize = tinted.size
        let glyphRect = CGRect(
            x: (size - glyphSize.width) / 2,
            y: (size - glyphSize.height) / 2 - size * 0.015,
            width: glyphSize.width,
            height: glyphSize.height
        )
        tinted.draw(in: glyphRect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in sizes {
    guard let data = renderIcon(pixelSize: entry.pixels) else {
        FileHandle.standardError.write("Fehler beim Rendern von \(entry.name)\n".data(using: .utf8)!)
        exit(1)
    }
    let fileURL = outputDir.appendingPathComponent("\(entry.name).png")
    try data.write(to: fileURL)
}

print("Icon-Set geschrieben nach \(outputDir.path)")
