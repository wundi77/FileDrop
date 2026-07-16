import AppKit
import SwiftUI

/// Lets the custom header act as the window's drag handle, replacing the
/// normal titlebar. Placed as a `.background()` behind the header's HStack:
/// SwiftUI hit-tests its own interactive children (buttons, text) first, so
/// only empty space in the header actually starts a window drag.
///
/// Uses NSWindow.performDrag(with:), which hands drag-tracking off to AppKit
/// entirely — a from-scratch SwiftUI DragGesture was tried instead and
/// caused visible jitter, because its translation is measured in the same
/// window's local coordinate space that the drag is simultaneously moving
/// out from under the cursor (a feedback loop). performDrag tracks the
/// mouse at the OS level, independent of the window's own coordinate space.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ nsView: DragHandleView, context: Context) {}

    final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        // A single assignment right after `wantsLayer = true` isn't
        // reliable: `.layer` can still be nil at that instant. Reapply on
        // every layout pass and window attach instead.
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
