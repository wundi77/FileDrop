import AppKit
import QuickLookThumbnailing

/// Generates real content previews (actual image content, PDF first page,
/// video frame, …) via the same QuickLook machinery Finder's icon view uses.
/// Falls back to nil — callers keep showing ClipboardFile.icon (the generic
/// file-type icon) — for types QuickLook has no thumbnail for.
enum ThumbnailLoader {
    static func generate(for url: URL, size: CGSize, scale: CGFloat = 2) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                continuation.resume(returning: representation?.nsImage)
            }
        }
    }
}
