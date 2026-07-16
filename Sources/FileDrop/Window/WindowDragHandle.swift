import AppKit
import SwiftUI

/// Lets the custom header act as the window's drag handle, replacing the
/// normal titlebar. Placed as a `.background()` behind the header's HStack:
/// SwiftUI hit-tests its own interactive children (buttons, text) first, so
/// only empty space in the header actually starts a window drag.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ nsView: DragHandleView, context: Context) {}

    final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        // Left unset, this plain NSView can pick up an opaque default layer
        // background once it's embedded in the (heavily layer-backed) SwiftUI
        // hierarchy — showing as a square patch behind the header's rounded
        // top corners instead of the panel's transparent background. A
        // single assignment right after `wantsLayer = true` isn't reliable:
        // `.layer` can still be nil at that exact instant (this view isn't
        // in a window yet), so it silently no-ops. Reapply on every layout
        // pass and window attach instead — the same fix that was needed for
        // the vibrancy view's own corner rounding earlier.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyTransparentLayer()
        }

        override func layout() {
            super.layout()
            applyTransparentLayer()
        }

        private func applyTransparentLayer() {
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.isOpaque = false
        }
    }
}
