import AppKit
import Combine
import SwiftUI

@MainActor
final class PanelController {
    let store = ClipboardStore()
    private(set) var panel: FloatingPanel!
    private var hostingView: NSHostingView<ClipboardPanelView>!
    private var cancellable: AnyCancellable?

    func show() {
        if panel == nil {
            setUp()
        }
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    private func setUp() {
        let initialRect = NSRect(x: 0, y: 0, width: Theme.panelWidth, height: 80)
        let panel = FloatingPanel(contentRect: initialRect)

        let contentView = ClipboardPanelView(
            store: store,
            onClose: { [weak panel] in panel?.orderOut(nil) }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = initialRect
        // Without this the hosting view's own layer paints an opaque
        // rectangle behind the SwiftUI content, defeating the panel's
        // transparent, rounded-corner background.
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        positionInitialFrame(for: panel)

        self.panel = panel
        self.hostingView = hostingView

        // The window's frame drives the SwiftUI content's proposed size, so
        // asking the content for its own preferred size via a GeometryReader
        // would just echo the current (stale) frame back. Instead measure the
        // hosting view's natural fitting size after each state change and
        // resize the window to match.
        cancellable = store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.updateSize() }
            }
        updateSize()
        // The very first fittingSize query can land before SwiftUI's initial
        // layout pass has committed; run one more pass on the next tick.
        DispatchQueue.main.async { [weak self] in self?.updateSize() }
    }

    private func positionInitialFrame(for panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - Theme.panelWidth - 24
        let y = visibleFrame.maxY - 80 - 24
        panel.setFrame(NSRect(x: x, y: y, width: Theme.panelWidth, height: 80), display: true)
    }

    private func updateSize() {
        guard let hostingView else { return }
        resize(to: hostingView.fittingSize)
    }

    private func resize(to size: CGSize) {
        guard let panel, size.height > 0 else { return }
        let currentFrame = panel.frame
        let newHeight = ceil(size.height)
        guard abs(currentFrame.height - newHeight) > 0.5 else { return }

        // Keep the top edge anchored so the panel grows/shrinks downward.
        let newOrigin = NSPoint(x: currentFrame.origin.x, y: currentFrame.maxY - newHeight)
        let newFrame = NSRect(origin: newOrigin, size: NSSize(width: Theme.panelWidth, height: newHeight))
        panel.setFrame(newFrame, display: true)
    }
}
