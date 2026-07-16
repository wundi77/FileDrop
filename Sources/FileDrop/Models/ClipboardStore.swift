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

    func clearAll() {
        files.removeAll()
        selectedIDs.removeAll()
        contextMenuFileID = nil
        hoveredFileID = nil
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

    func toggleLock(_ id: UUID) {
        guard let idx = files.firstIndex(where: { $0.id == id }) else { return }
        files[idx].isLocked.toggle()
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
}
