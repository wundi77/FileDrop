import SwiftUI
import AppKit

/// Owns the full click-vs-drag decision for a file tile/row as a single
/// AppKit responder, instead of stacking SwiftUI's `.onTapGesture` and
/// `.onDrag` on the same view. Two separate gesture systems on one view
/// fight over the same mouseDown/mouseUp stream — whichever is topmost in
/// the hit-test wins outright, which previously broke both click-to-select
/// and single-file drag at once. Here, mouseDown/mouseDragged/mouseUp are
/// handled by the same view: a plain click (no meaningful movement) doesn't
/// change the selection at all — only Shift-click adds/removes the tile from
/// it. A drag past a small threshold starts a native multi-item dragging
/// session carrying every currently-selected file, so the whole selection
/// moves together, matching Finder.
///
/// Must be attached via `.overlay(...)`, not `.background(...)`: SwiftUI's
/// hosting layer routes real mouseDown/mouseUp only to AppKit views it
/// finds ahead of its own content in z-order (the same reason
/// `RightClickCatcher` works as an overlay). A background sibling still
/// gets asked `hitTest` for incidental things like cursor updates, but
/// never actually receives the click.
struct MultiItemDragHandle: NSViewRepresentable {
    let file: ClipboardFile
    let store: ClipboardStore

    func makeNSView(context: Context) -> DragHandleView {
        let view = DragHandleView()
        view.file = file
        view.store = store
        return view
    }

    func updateNSView(_ nsView: DragHandleView, context: Context) {
        nsView.file = file
        nsView.store = store
    }

    final class DragHandleView: NSView {
        var file: ClipboardFile!
        weak var store: ClipboardStore?

        private var mouseDownLocation: NSPoint = .zero
        private var didStartDrag = false
        private let dragThreshold: CGFloat = 16 // squared distance, ~4pt

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            // Right-clicks are handled by RightClickCatcher's overlay above
            // this view; let those pass through untouched.
            if let event = NSApp.currentEvent, event.type == .rightMouseDown || event.type == .rightMouseUp {
                return nil
            }
            // The per-file remove ("x") button sits in the top-right corner of
            // the tile/row, drawn by SwiftUI above this overlay. Since this
            // view otherwise covers the whole tile to own click-vs-drag
            // detection, it must explicitly yield that corner so the button
            // still receives its own clicks instead of being selected.
            let removeButtonZone = NSRect(x: bounds.width - 32, y: bounds.height - 32, width: 32, height: 32)
            if removeButtonZone.contains(point) {
                return nil
            }
            return super.hitTest(point)
        }

        override func mouseDown(with event: NSEvent) {
            mouseDownLocation = event.locationInWindow
            didStartDrag = false
        }

        override func mouseDragged(with event: NSEvent) {
            guard !didStartDrag else { return }
            let dx = event.locationInWindow.x - mouseDownLocation.x
            let dy = event.locationInWindow.y - mouseDownLocation.y
            guard (dx * dx + dy * dy) > dragThreshold else { return }
            didStartDrag = true
            startDraggingSession(with: event)
        }

        override func mouseUp(with event: NSEvent) {
            guard !didStartDrag else { return }
            // Plain clicks no longer touch the selection at all — only
            // Shift-click marks/unmarks a tile, additively.
            guard event.modifierFlags.contains(.shift) else { return }
            store?.toggleSelect(file.id)
        }

        private func startDraggingSession(with event: NSEvent) {
            guard let store, let file else { return }

            let filesToDrag: [ClipboardFile]
            if store.selectedIDs.contains(file.id), store.selectedIDs.count > 1 {
                filesToDrag = store.files.filter { store.selectedIDs.contains($0.id) }
            } else {
                store.selectedIDs = [file.id]
                filesToDrag = [file]
            }

            var draggingItems: [NSDraggingItem] = []
            let baseFrame = NSRect(origin: .zero, size: bounds.size)
            for (index, draggedFile) in filesToDrag.enumerated() {
                let item = NSDraggingItem(pasteboardWriter: draggedFile.url as NSURL)
                let stackOffset = CGFloat(min(index, 4)) * 3
                let frame = baseFrame.offsetBy(dx: stackOffset, dy: -stackOffset)
                let isPrimary = draggedFile.id == file.id
                item.setDraggingFrame(frame, contents: dragImage(for: draggedFile, badgeCount: isPrimary ? filesToDrag.count : 1))
                draggingItems.append(item)
            }

            beginDraggingSession(with: draggingItems, event: event, source: self)
        }

        private func dragImage(for draggedFile: ClipboardFile, badgeCount: Int) -> NSImage {
            let size = bounds.size.width > 0 && bounds.size.height > 0 ? bounds.size : NSSize(width: 64, height: 64)
            let image = NSImage(size: size)
            image.lockFocus()
            draggedFile.icon.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)

            if badgeCount > 1 {
                let diameter: CGFloat = 20
                let badgeRect = NSRect(x: size.width - diameter - 2, y: size.height - diameter - 2, width: diameter, height: diameter)
                NSColor.white.withAlphaComponent(0.9).setFill()
                NSBezierPath(ovalIn: badgeRect.insetBy(dx: -1.5, dy: -1.5)).fill()
                NSColor.systemRed.setFill()
                NSBezierPath(ovalIn: badgeRect).fill()

                let text = "\(badgeCount)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.white,
                    .font: NSFont.boldSystemFont(ofSize: 11)
                ]
                let textSize = text.size(withAttributes: attrs)
                let textPoint = NSPoint(x: badgeRect.midX - textSize.width / 2, y: badgeRect.midY - textSize.height / 2)
                text.draw(at: textPoint, withAttributes: attrs)
            }

            image.unlockFocus()
            return image
        }
    }
}

extension MultiItemDragHandle.DragHandleView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }
}
