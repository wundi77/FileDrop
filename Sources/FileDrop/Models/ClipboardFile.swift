import Foundation
import AppKit

struct ClipboardFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var sizeBytes: Int64
    let isDirectory: Bool

    var name: String { url.lastPathComponent }

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }

    init(url: URL) {
        self.url = url
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
        self.isDirectory = values?.isDirectory ?? false
        // Folders have no meaningful .fileSizeKey of their own — this stays
        // 0 until ClipboardStore fills in the real, recursively-computed
        // size in the background.
        self.sizeBytes = Int64(values?.fileSize ?? 0)
    }

    /// Item provider for dragging this file out to Finder/other apps.
    ///
    /// `NSItemProvider(contentsOf:)` reads the file's *data* and registers it
    /// under its UTI — for the receiving side that's an anonymous typed data
    /// blob with no name of its own, so Finder invents a generic one from
    /// the type ("PDF-Dokument", "Internet-Adresse", …) and, for folders,
    /// there's no single "data" to read at all, so it falls back to moving
    /// the real folder instead of copying it. Registering the actual NSURL
    /// instead makes it a real reference to the existing file: the original
    /// name is preserved and the drop is a normal copy, not a move.
    func makeDragItemProvider() -> NSItemProvider {
        let provider = NSItemProvider(object: url as NSURL)
        provider.suggestedName = name
        return provider
    }
}

enum FileSizeFormatter {
    static func label(bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1 { return "\(bytes) B" }
        let mb = kb / 1024
        if mb < 1 { return String(format: "%.0f KB", kb) }
        let gb = mb / 1024
        if gb < 1 { return String(format: "%.1f MB", mb) }
        return String(format: "%.1f GB", gb)
    }
}
