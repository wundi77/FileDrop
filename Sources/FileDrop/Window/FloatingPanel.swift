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
        // The panel is a plain rectangle now (see ClipboardPanelView), so
        // there's no rounded-corner alpha shape for the native shadow to get
        // wrong — it renders a normal, correct soft drop shadow.
        hasShadow = true
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
