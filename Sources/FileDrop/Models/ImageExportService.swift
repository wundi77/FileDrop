import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ImageExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case png = "PNG"

    var id: String { rawValue }
    var utType: UTType { self == .jpeg ? .jpeg : .png }
    var fileExtension: String { self == .jpeg ? "jpg" : "png" }
}

enum ImageExportService {
    static func isImage(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)??.conforms(to: .image) ?? false
    }

    /// Resizes (if `maxDimension` is set and the image is larger) and
    /// re-encodes each URL into `format`, writing results to the desktop —
    /// same destination/naming scheme as the existing ZIP export. Runs off
    /// the main thread since decoding/re-encoding full-size photos can take
    /// a noticeable moment.
    static func export(urls: [URL], format: ImageExportFormat, maxDimension: CGFloat?, quality: CGFloat) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return }
            var writtenURLs: [URL] = []

            for url in urls {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      var image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }

                if let maxDimension {
                    image = resize(image, maxDimension: maxDimension) ?? image
                }

                let baseName = url.deletingPathExtension().lastPathComponent
                var destination = desktopURL.appendingPathComponent("\(baseName).\(format.fileExtension)")
                var suffix = 1
                while FileManager.default.fileExists(atPath: destination.path) {
                    destination = desktopURL.appendingPathComponent("\(baseName)-\(suffix).\(format.fileExtension)")
                    suffix += 1
                }

                guard let dest = CGImageDestinationCreateWithURL(destination as CFURL, format.utType.identifier as CFString, 1, nil) else { continue }
                CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
                guard CGImageDestinationFinalize(dest) else { continue }
                writtenURLs.append(destination)
            }

            guard !writtenURLs.isEmpty else { return }
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting(writtenURLs)
            }
        }
    }

    // Normalizes to a plain RGBA bitmap rather than trying to preserve the
    // source's exact pixel format — CGContext can't redraw into arbitrary
    // color spaces (indexed/CMYK sources in particular), and every format
    // this handles in practice (JPEG/PNG/HEIC photos) is RGB anyway.
    private static func resize(_ image: CGImage, maxDimension: CGFloat) -> CGImage? {
        let longEdge = CGFloat(max(image.width, image.height))
        guard longEdge > maxDimension else { return image }

        let scale = maxDimension / longEdge
        let newWidth = max(1, Int(CGFloat(image.width) * scale))
        let newHeight = max(1, Int(CGFloat(image.height) * scale))

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }
}
