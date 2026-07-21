import AppKit

/// Borderless, non-activating panel hosting the full-width top strip.
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
        // A native window shadow halos the *entire* rect, not just one
        // edge — with the strip's left/right edges sitting flush against
        // the screen bounds, that reads as an unwanted bright border all
        // the way around. The strip draws its own thin bottom divider
        // instead (see StripView), so no window shadow at all.
        hasShadow = false
        level = .floating
        // The whole content area hosts clickable/draggable file tiles, so the
        // window must not move on any mouse-down inside it — the strip is
        // fixed to the top of the screen anyway.
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }

    /// The slide-in/out animation parks the strip above the visible area
    /// (behind/over the menu bar region). AppKit's default constraining
    /// would clamp such frames back onto the screen, snapping the panel
    /// into place instead of letting it glide — so opt out entirely.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
