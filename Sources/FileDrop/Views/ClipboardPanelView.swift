import SwiftUI
import UniformTypeIdentifiers

struct ClipboardPanelView: View {
    @ObservedObject var store: ClipboardStore
    var onClose: () -> Void

    private var palette: PanelPalette { Theme.palette(dark: store.isDarkMode) }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store, palette: palette, onClose: onClose)
                .background(palette.headerBackground)

            if !store.isMinimized {
                bodyContent
            }
        }
        .frame(width: Theme.panelWidth)
        // Plan B after repeated corner-clipping failures with NSVisualEffectView's
        // .behindWindow blending: SwiftUI's own Material is pure SwiftUI/Core
        // Animation, not a bridged AppKit view fighting the window server's
        // compositing, so it respects clipShape the same way any other SwiftUI
        // layer does — same guarantee that already made the panel's bottom
        // corners work correctly.
        .background(.regularMaterial)
        .background(palette.bodyBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
        .overlay {
            if store.isDraggingOver {
                DropOverlayView(palette: palette, cornerRadius: Theme.Radius.panel - 6, isDark: store.isDarkMode)
            }
        }
        .overlay {
            if let contextID = store.contextMenuFileID, store.files.contains(where: { $0.id == contextID }) {
                ZStack(alignment: .bottomTrailing) {
                    // Catches clicks anywhere outside the menu card itself so
                    // the menu dismisses on a normal click elsewhere, instead
                    // of only via its own item taps.
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { store.closeContextMenu() }

                    ContextMenuView(store: store, palette: palette, fileID: contextID)
                        .padding(18)
                }
                .transition(.opacity)
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 30, x: 0, y: 24)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .preferredColorScheme(store.isDarkMode ? .dark : .light)
        .onDrop(of: [.fileURL], isTargeted: $store.isDraggingOver) { providers in
            handleDrop(providers: providers)
        }
        .overlayPreferenceValue(PanelTooltipPreferenceKey.self) { info in
            if let info {
                PanelTooltipOverlay(info: info, palette: palette)
            }
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        ScrollView {
            Group {
                if store.viewMode == .grid {
                    FileGridView(store: store, palette: palette)
                } else {
                    FileListView(store: store, palette: palette)
                }
            }
            .padding(EdgeInsets(top: 20, leading: 18, bottom: 22, trailing: 18))
        }
        .frame(maxHeight: Theme.bodyMaxHeight)
        .background(palette.bodyBackground)
        .onTapGesture {
            store.closeContextMenu()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var didAccept = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            didAccept = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let directURL = item as? URL {
                    url = directURL
                }
                guard let resolvedURL = url else { return }
                DispatchQueue.main.async {
                    store.addFiles(urls: [resolvedURL])
                }
            }
        }
        return didAccept
    }
}
