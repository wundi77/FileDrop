import AppKit
import SwiftUI

/// The context menu card is drawn just below whichever tile was
/// right-clicked. That tile can sit anywhere across the strip's one-sixth-
/// of-the-screen height, including right at its bottom edge — leaving no
/// room *inside the strip's own window* to draw a card several times taller
/// than the sliver of space left below the tile. A second, independent
/// borderless panel isn't bound by the strip's height at all, so it can
/// freely extend into the desktop area underneath.
@MainActor
final class ContextMenuPanelController {
    private let store: ClipboardStore
    private var panel: FloatingPanel?
    private var hostingView: NSHostingView<ContextMenuView>?

    init(store: ClipboardStore) {
        self.store = store
    }

    /// - Parameters:
    ///   - anchorRect: the right-clicked tile's bounds, in the strip's own
    ///     top-down local coordinate space (as produced by resolving the
    ///     tile's `Anchor<CGRect>` against the strip's root `GeometryProxy`).
    ///   - stripScreenFrame: the strip window's current on-screen frame,
    ///     used to translate that local rect into a screen position.
    func update(anchorRect: CGRect?, stripScreenFrame: CGRect, fileID: UUID?, palette: PanelPalette) {
        guard let anchorRect, let fileID else {
            panel?.orderOut(nil)
            return
        }
        show(anchorRect: anchorRect, stripScreenFrame: stripScreenFrame, fileID: fileID, palette: palette)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func show(anchorRect: CGRect, stripScreenFrame: CGRect, fileID: UUID, palette: PanelPalette) {
        let contentView = ContextMenuView(store: store, palette: palette, fileID: fileID)

        let panel: FloatingPanel
        let hostingView: NSHostingView<ContextMenuView>
        if let existingPanel = self.panel, let existingHostingView = self.hostingView {
            panel = existingPanel
            hostingView = existingHostingView
            hostingView.rootView = contentView
        } else {
            hostingView = NSHostingView(rootView: contentView)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            hostingView.layer?.isOpaque = false
            panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 176, height: 100))
            panel.contentView = hostingView
            self.panel = panel
            self.hostingView = hostingView
        }

        let size = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: size)

        // Local top-down coordinates → screen coordinates (AppKit's origin
        // is bottom-left): the strip window's top edge is stripScreenFrame's
        // maxY, and local y grows downward from there.
        let screenX = stripScreenFrame.minX + anchorRect.minX
        let anchorBottomScreenY = stripScreenFrame.maxY - anchorRect.maxY
        let originY = anchorBottomScreenY - size.height - 8

        panel.setFrame(NSRect(x: screenX, y: originY, width: size.width, height: size.height), display: true)
        panel.orderFrontRegardless()
        // Without becoming key, this panel's first click just activates it
        // instead of reaching the SwiftUI tap gesture underneath — the menu
        // items would highlight on hover but never actually fire.
        panel.makeKey()
    }
}
