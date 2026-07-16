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
        // Pragmatic fallback after five rounds of failed corner-rounding
        // attempts (NSVisualEffectView masking, a CAShapeLayer mask, SwiftUI
        // Material, layer.isOpaque, and finally removing the header's
        // NSViewRepresentable drag handle entirely) — square corners sidestep
        // the whole saga, and the native window shadow (re-enabled in
        // FloatingPanel) works cleanly on an actually-rectangular window.
        .background(.regularMaterial)
        .background(palette.bodyBackground)
        .overlay(
            Rectangle()
                .stroke(palette.border, lineWidth: 1)
        )
        .overlay {
            if store.isDraggingOver {
                DropOverlayView(palette: palette, cornerRadius: 0, isDark: store.isDarkMode)
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
