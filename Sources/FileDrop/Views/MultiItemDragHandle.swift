import AppKit
import SwiftUI

/// What to drag: the file URLs (in the order they'll appear as dragging
/// items) and a matching image per URL for the drag's visual.
struct MultiFileDragPayload {
    let urls: [URL]
    let images: [NSImage]
}

/// Replaces SwiftUI's `.onDrag`, which can only ever carry a single item per
/// gesture — there's no way to make it pick up the rest of a multi-selection
/// when you drag one of several selected tiles/rows. This drives a real
/// AppKit multi-item NSDraggingSession instead, which both copies every
/// selected file and gets the native "stack with a count badge" drag visual
/// for free when there's more than one item, and lets us also draw our own
/// small red count badge on the lead image.
///
/// Handles the plain-click case itself too (via `onPlainClick`), rather than
/// coexisting with a separate `.onTapGesture` on the same view — two
/// different mouse-down handlers fighting over the same click risked one of
/// them silently losing.
struct MultiItemDragHandle: NSViewRepresentable {
    let payload: () -> MultiFileDragPayload
    let onPlainClick: () -> Void

    func makeNSView(context: Context) -> DragSourceView {
        let view = DragSourceView()
        view.payload = payload
        view.onPlainClick = onPlainClick
        return view
    }

    func updateNSView(_ nsView: DragSourceView, context: Context) {
        nsView.payload = payload
        nsView.onPlainClick = onPlainClick
    }

    final class DragSourceView: NSView, NSDraggingSource {
        var payload: (() -> MultiFileDragPayload)?
        var onPlainClick: (() -> Void)?

        private var mouseDownEvent: NSEvent?
        private var didStartDrag = false

        override func hitTest(_ point: NSPoint) -> NSView? {
            // Only intercept the left-click/drag events this view actually
            // handles; right-clicks, hover tracking, etc. fall through to
            // the SwiftUI content underneath untouched.
            guard let event = NSApp.currentEvent else { return super.hitTest(point) }
            switch event.type {
            case .leftMouseDown, .leftMouseDragged, .leftMouseUp:
                return super.hitTest(point)
            default:
                return nil
            }
        }

        override func mouseDown(with event: NSEvent) {
            mouseDownEvent = event
            didStartDrag = false
        }

        override func mouseDragged(with event: NSEvent) {
            guard !didStartDrag, let start = mouseDownEvent else { return }
            let dx = event.locationInWindow.x - start.locationInWindow.x
            let dy = event.locationInWindow.y - start.locationInWindow.y
            guard (dx * dx + dy * dy) > 16 else { return } // ~4pt of movement
            didStartDrag = true
            beginDrag(with: event)
        }

        override func mouseUp(with event: NSEvent) {
            if !didStartDrag {
                onPlainClick?()
            }
            mouseDownEvent = nil
            didStartDrag = false
        }

        private func beginDrag(with event: NSEvent) {
            guard let payload = payload?(), !payload.urls.isEmpty else { return }

            let dragSize = NSSize(width: 64, height: 64)
            let anchor = convert(event.locationInWindow, from: nil)
            var items: [NSDraggingItem] = []

            for (index, url) in payload.urls.enumerated() {
                let sourceImage = index < payload.images.count ? payload.images[index] : NSWorkspace.shared.icon(forFile: url.path)
                let content = index == 0
                    ? Self.compose(base: sourceImage, badgeCount: payload.urls.count, size: dragSize)
                    : Self.resize(sourceImage, to: dragSize)

                let stackOffset = CGFloat(min(index, 4)) * 3
                let frame = NSRect(
                    x: anchor.x - dragSize.width / 2 + stackOffset,
                    y: anchor.y - dragSize.height / 2 - stackOffset,
                    width: dragSize.width,
                    height: dragSize.height
                )

                let item = NSDraggingItem(pasteboardWriter: url as NSURL)
                item.setDraggingFrame(frame, contents: content)
                items.append(item)
            }

            beginDraggingSession(with: items, event: event, source: self)
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            .copy
        }

        private static func resize(_ image: NSImage, to size: NSSize) -> NSImage {
            let result = NSImage(size: size)
            result.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
            result.unlockFocus()
            return result
        }

        private static func compose(base: NSImage, badgeCount: Int, size: NSSize) -> NSImage {
            let result = NSImage(size: size)
            result.lockFocus()
            base.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)

            if badgeCount > 1 {
                let diameter = size.width * 0.42
                let rect = NSRect(x: size.width - diameter * 0.8, y: size.height - diameter * 0.8, width: diameter, height: diameter)

                NSColor.white.setFill()
                NSBezierPath(ovalIn: rect.insetBy(dx: -1.5, dy: -1.5)).fill()
                NSColor(red: 0.91, green: 0.20, blue: 0.16, alpha: 1).setFill()
                NSBezierPath(ovalIn: rect).fill()

                let text = "\(badgeCount)" as NSString
                let font = NSFont.boldSystemFont(ofSize: diameter * 0.55)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
                let textSize = text.size(withAttributes: attrs)
                text.draw(
                    at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2),
                    withAttributes: attrs
                )
            }

            result.unlockFocus()
            return result
        }
    }
}
