import AppKit

/// Borderless, non-activating panel that floats above the desktop like the
/// design's "eigene, transparente Kopfzeile statt der normalen macOS-Titelleiste".
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        // Re-enabled now that the corner-transparency bug is fixed at its
        // real source (a stray opaque layer, not the window shadow) — a
        // native shadow on a non-opaque window follows the window's actual
        // alpha shape, layering in under the panel's own SwiftUI shadow for
        // a slightly richer drop shadow.
        hasShadow = true
        level = .floating
        // The whole content area hosts clickable/draggable file tiles, so the
        // window must not move on every mouse-down inside it — only the
        // header (via WindowDragHandle) should drag the panel.
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }
}
