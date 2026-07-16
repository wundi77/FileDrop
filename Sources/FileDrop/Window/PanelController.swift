import AppKit
import SwiftUI

@MainActor
final class PanelController {
    let store = ClipboardStore()
    private(set) var panel: FloatingPanel!
    private var hostingView: NSHostingView<ClipboardPanelView>!

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
            onClose: { [weak panel] in panel?.orderOut(nil) },
            onSizeChange: { [weak self] size in self?.resize(to: size) }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = initialRect
        panel.contentView = hostingView

        positionInitialFrame(for: panel)

        self.panel = panel
        self.hostingView = hostingView
    }

    private func positionInitialFrame(for panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - Theme.panelWidth - 24
        let y = visibleFrame.maxY - 80 - 24
        panel.setFrame(NSRect(x: x, y: y, width: Theme.panelWidth, height: 80), display: true)
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
