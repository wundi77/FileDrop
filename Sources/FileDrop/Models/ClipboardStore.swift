import Foundation
import SwiftUI
import AppKit

@MainActor
final class ClipboardStore: ObservableObject {
    @Published var files: [ClipboardFile] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var isDraggingOver: Bool = false
    @Published var hoveredFileID: UUID?
    @Published var contextMenuFileID: UUID?
    /// User-adjustable strip background opacity, from barely-there (0.01) up
    /// to fully opaque (1.0) — see OpacitySliderView. Persisted across
    /// launches since it's a genuine preference, not session state.
    @Published var stripOpacity: Double = (UserDefaults.standard.object(forKey: "stripOpacity") as? Double) ?? 0.16 {
        didSet { UserDefaults.standard.set(stripOpacity, forKey: "stripOpacity") }
    }
    /// Fired the moment a tile drag crosses the drag threshold — lets
    /// PanelController auto-collapse the strip out of the way as soon as a
    /// file starts moving out of it (Yoink-style), before the drag even
    /// reaches another app.
    var onDragWillStart: (() -> Void)?

    var countLabel: String {
        let count = files.count
        let noun = count == 1 ? "Datei" : "Dateien"
        let totalBytes = files.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return "\(count) \(noun) · \(FileSizeFormatter.label(bytes: totalBytes))"
    }

    func addFiles(urls: [URL]) {
        let existing = Set(files.map(\.url))
        let newFiles = urls.filter { !existing.contains($0) }.map(ClipboardFile.init)
        files.append(contentsOf: newFiles)

        for file in newFiles where file.isDirectory {
            computeFolderSize(id: file.id, url: file.url)
        }
    }

    private func computeFolderSize(id: UUID, url: URL) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let size = Self.recursiveSize(of: url)
            DispatchQueue.main.async {
                guard let self, let idx = self.files.firstIndex(where: { $0.id == id }) else { return }
                self.files[idx].sizeBytes = size
            }
        }
    }

    private nonisolated static func recursiveSize(of url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  values.isDirectory != true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }

    func removeFile(_ id: UUID) {
        files.removeAll { $0.id == id }
        selectedIDs.remove(id)
        if contextMenuFileID == id { contextMenuFileID = nil }
        if hoveredFileID == id { hoveredFileID = nil }
    }

    func removeSelected() {
        guard !selectedIDs.isEmpty else { return }
        files.removeAll { selectedIDs.contains($0.id) }
        if let contextMenuFileID, selectedIDs.contains(contextMenuFileID) { self.contextMenuFileID = nil }
        if let hoveredFileID, selectedIDs.contains(hoveredFileID) { self.hoveredFileID = nil }
        selectedIDs.removeAll()
    }

    func toggleSelect(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func toggleSelectAll() {
        let allIDs = Set(files.map(\.id))
        if selectedIDs == allIDs {
            selectedIDs.removeAll()
        } else {
            selectedIDs = allIDs
        }
    }

    func openContextMenu(for id: UUID) {
        contextMenuFileID = id
    }

    func closeContextMenu() {
        contextMenuFileID = nil
    }

    func revealInFinder(_ id: UUID) {
        guard let file = files.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    /// Copies just the one file, unless it's part of a larger current
    /// selection — then the whole selection is copied, matching Finder's
    /// "act on the whole selection" behavior for a right-click within it.
    func copyToPasteboard(_ id: UUID) {
        let ids = selectedIDs.contains(id) ? selectedIDs : [id]
        let urls = files.filter { ids.contains($0.id) }.map(\.url)
        guard !urls.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls.map { $0 as NSURL })
    }

    var selectedURLs: [URL] {
        files.filter { selectedIDs.contains($0.id) }.map(\.url)
    }

    func shareSelectedViaAirDrop() {
        let urls = selectedURLs
        guard !urls.isEmpty else { return }
        NSSharingService(named: .sendViaAirDrop)?.perform(withItems: urls)
    }

    func exportSelectedAsZip() {
        let urls = selectedURLs
        guard !urls.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return }

            let baseName = "FileDrop-Export"
            var destination = desktopURL.appendingPathComponent("\(baseName).zip")
            var suffix = 1
            while FileManager.default.fileExists(atPath: destination.path) {
                destination = desktopURL.appendingPathComponent("\(baseName)-\(suffix).zip")
                suffix += 1
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-j", "-q", destination.path] + urls.map(\.path)

            guard (try? process.run()) != nil else { return }
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return }

            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([destination])
            }
        }
    }
}
