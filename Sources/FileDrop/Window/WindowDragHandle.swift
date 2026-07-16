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
    }
}
