import AppKit
import Quartz

/// Drives the system Quick Look panel for the space-bar preview shortcut.
/// Used directly rather than through the responder-chain preview-panel
/// protocol, since the strip has no document/window controller of its own —
/// just show/hide the shared panel with an explicit list of URLs to browse.
final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var urls: [URL] = []

    @MainActor
    func toggle(urls: [URL]) {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }
        guard !urls.isEmpty else { return }
        self.urls = urls
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as QLPreviewItem
    }
}
