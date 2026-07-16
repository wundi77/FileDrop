import Foundation
import AppKit

struct ClipboardFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var sizeBytes: Int64

    var name: String { url.lastPathComponent }
    var ext: String {
        let e = url.pathExtension
        return e.isEmpty ? "—" : e.uppercased()
    }

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }

    init(url: URL) {
        self.url = url
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        self.sizeBytes = Int64(values?.fileSize ?? 0)
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
