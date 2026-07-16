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
            item("Kopieren") {
                store.copyToPasteboard(fileID)
                store.closeContextMenu()
            }
            item("Im Finder anzeigen") {
                store.revealInFinder(fileID)
                store.closeContextMenu()
            }
        }
        .padding(5)
        .frame(minWidth: 176)
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
