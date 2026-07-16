import Foundation
import SwiftUI
import AppKit

enum ViewMode {
    case grid
    case list
}

@MainActor
final class ClipboardStore: ObservableObject {
    @Published var files: [ClipboardFile] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var viewMode: ViewMode = .grid
    @Published var isDarkMode: Bool
    @Published var isMinimized: Bool = false
    @Published var isDraggingOver: Bool = false
    @Published var hoveredFileID: UUID?
    @Published var contextMenuFileID: UUID?

    // Window dragging via the header, wired up by PanelController. Plain
    // closures rather than a dependency on NSPanel here, and not @Published
    // — these aren't view state, just a way for the header to reach the
    // window without every view needing a reference to it.
    var onHeaderDragChanged: (CGSize) -> Void = { _ in }
    var onHeaderDragEnded: () -> Void = {}

    init() {
        self.isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

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

    func copyToPasteboard(_ id: UUID) {
        guard let file = files.first(where: { $0.id == id }) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([file.url as NSURL])
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
