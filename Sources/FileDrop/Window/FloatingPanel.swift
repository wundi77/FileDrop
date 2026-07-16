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
        // The rounded panel draws its own soft SwiftUI shadow; AppKit's native
        // window shadow is a hard-edged rectangle that ignores the rounded
        // corners and shows through as a square outline behind them.
        hasShadow = false
        level = .floating
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }
}
