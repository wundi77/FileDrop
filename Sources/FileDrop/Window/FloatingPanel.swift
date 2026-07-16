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
        // Reverted: re-enabling this introduced a faint square smudge at
        // the *bottom* corners too (previously clean), on top of the
        // pre-existing top-corner bug. The native shadow computes its shape
        // from the window's alpha channel, and the rounded rect's own
        // anti-aliased edge is apparently not clean enough for it — the
        // panel's own SwiftUI shadow (which does look right) is what
        // actually renders the drop shadow.
        hasShadow = false
        level = .floating
        // The whole content area hosts clickable/draggable file tiles, so the
        // window must not move on every mouse-down inside it — only the
        // header (via a SwiftUI DragGesture routed through PanelController)
        // should drag the panel.
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }
}
