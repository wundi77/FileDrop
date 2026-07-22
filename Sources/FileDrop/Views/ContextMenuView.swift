import SwiftUI
import AppKit

// MARK: - Right-click detection

private struct RightClickCatcher: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> RightClickView {
        let view = RightClickView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: RightClickView, context: Context) {
        nsView.action = action
    }

    final class RightClickView: NSView {
        var action: (() -> Void)?

        // Without this, the very first right-click after the strip slides in
        // (the window is never key/active yet) gets swallowed instead of
        // reaching rightMouseDown — same fix as MultiItemDragHandle.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func rightMouseDown(with event: NSEvent) {
            action?()
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            // Only intercept right-clicks; let everything else pass through.
            guard let event = NSApp.currentEvent, event.type == .rightMouseDown || event.type == .rightMouseUp else {
                return nil
            }
            return super.hitTest(point)
        }
    }
}

extension View {
    func onRightClick(perform action: @escaping () -> Void) -> some View {
        overlay(RightClickCatcher(action: action))
    }
}

// MARK: - Context menu card

struct ContextMenuView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    let fileID: UUID

    var body: some View {
        VStack(spacing: 0) {
            item("Löschen") {
                store.removeFile(fileID)
            }
            item(copyLabel) {
                store.copyToPasteboard(fileID)
                store.closeContextMenu()
            }
            item("Im Finder anzeigen") {
                store.revealInFinder(fileID)
                store.closeContextMenu()
            }
            item("Öffnen mit …") {
                let url = store.files.first(where: { $0.id == fileID })?.url
                store.closeContextMenu()
                if let url {
                    OpenWithMenu.show(for: url)
                }
            }
        }
        .padding(5)
        .frame(width: 176)
        // Without this, the surrounding ZStack (sized by its own flexible
        // Color.clear "click outside to dismiss" catcher) proposes its own
        // near-full-strip width down to this view, and the menu items'
        // .frame(maxWidth: .infinity) backgrounds happily stretch to fill
        // it — this pins the card to its own intrinsic size regardless of
        // what the parent proposes.
        .fixedSize(horizontal: true, vertical: false)
        .background(.regularMaterial)
        .background(palette.headerBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.contextMenu, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.contextMenu, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 12)
    }

    private func item(_ title: String, action: @escaping () -> Void) -> some View {
        ContextMenuItem(title: title, palette: palette, action: action)
    }

    private var copyLabel: String {
        let selected = store.selectedIDs
        return selected.contains(fileID) && selected.count > 1 ? "Auswahl kopieren" : "Kopieren"
    }
}

private struct ContextMenuItem: View {
    let title: String
    let palette: PanelPalette
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Text(title)
            .font(.system(size: 12.5))
            .foregroundColor(isHovering ? .white : palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? palette.accent : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .onHover { isHovering = $0 }
    }
}
