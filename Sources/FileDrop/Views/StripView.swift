import SwiftUI
import UniformTypeIdentifiers

/// Full-width, fixed-height strip docked below the menu bar: one horizontal,
/// scrollable row of file tiles on the left, count label plus the action
/// buttons on the right. Always dark, semi-transparent gray over a blur.
struct StripView: View {
    @ObservedObject var store: ClipboardStore
    /// The right-clicked tile's bounds, in this view's own local top-down
    /// coordinate space, or nil once no tile is anchored. The strip's own
    /// window is too short to draw the menu card inside it (see
    /// ContextMenuPanelController), so this just hands the raw rect out to
    /// AppKit, which positions an independent panel from it.
    var onContextMenuAnchorChange: (CGRect?) -> Void = { _ in }
    /// Fires with the share button's own bounds (in this view's local
    /// top-down coordinate space) and the URLs to share, whenever it's
    /// tapped — PanelController hands the rect straight to
    /// NSSharingServicePicker, whose hosting view is flipped the same way.
    var onShareRequest: (CGRect, [URL]) -> Void = { _, _ in }

    private let palette = Theme.dark
    @State private var shareButtonFrame: CGRect = .zero

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                fileRow(height: proxy.size.height)

                Rectangle()
                    .fill(palette.divider)
                    .frame(width: 1)
                    .padding(.vertical, 14)

                actionArea
            }
            .onPreferenceChange(ContextMenuAnchorPreferenceKey.self) { anchor in
                onContextMenuAnchorChange(anchor.map { proxy[$0] })
            }
            .onPreferenceChange(ShareButtonAnchorPreferenceKey.self) { anchor in
                if let anchor {
                    shareButtonFrame = proxy[anchor]
                }
            }
        }
        .background(
            // Scaling only the tint color leaves the frosted-glass material
            // underneath always at its own fixed opacity, so the strip could
            // never get more than barely-translucent — fading the material
            // itself in the same breath lets the low end of the slider go
            // all the way down to just-barely-there.
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(red: 0.11, green: 0.11, blue: 0.13))
            }
            .opacity(store.stripOpacity)
        )
        .overlay(Rectangle().fill(palette.border).frame(height: 1), alignment: .bottom)
        .overlay {
            if store.isDraggingOver {
                DropOverlayView(palette: palette, cornerRadius: 0, isDark: true)
            }
        }
        .overlay {
            // Catches clicks anywhere outside the menu card itself so it
            // dismisses on a normal click elsewhere, instead of only via its
            // own item taps. The card itself now lives in a separate window,
            // so this only needs to cover clicks elsewhere within the strip.
            if store.contextMenuFileID != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { store.closeContextMenu() }
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
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
    private func fileRow(height: CGFloat) -> some View {
        // Tile square + size label + paddings must fit the strip's height.
        let tileSide = max(height - 74, 56)

        if store.files.isEmpty {
            Text("Dateien hierher ziehen")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.subText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 14) {
                    ForEach(store.files) { file in
                        StripTileView(store: store, palette: palette, file: file, side: tileSide)
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: height)
            }
            .onTapGesture {
                store.closeContextMenu()
            }
        }
    }

    private var actionArea: some View {
        VStack(spacing: 12) {
            OpacitySliderView(value: $store.stripOpacity)
                .frame(width: 136)

            Text(store.countLabel)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(palette.subText)
                .lineLimit(1)
                .fixedSize()

            HStack(spacing: 8) {
                HeaderIconButton(systemName: SymbolIcon.trash, title: "Ausgewählte löschen", palette: palette) {
                    store.removeSelected()
                }
                HeaderIconButton(systemName: SymbolIcon.selectAll, title: "Alle auswählen", palette: palette) {
                    store.toggleSelectAll()
                }
                HeaderIconButton(systemName: SymbolIcon.airdrop, title: "Ausgewählte per AirDrop teilen", palette: palette) {
                    store.shareSelectedViaAirDrop()
                }
                HeaderIconButton(systemName: SymbolIcon.share, title: "Ausgewählte teilen …", palette: palette) {
                    onShareRequest(shareButtonFrame, store.selectedURLs)
                }
                .anchorPreference(key: ShareButtonAnchorPreferenceKey.self, value: .bounds) { $0 }
                HeaderIconButton(systemName: SymbolIcon.zip, title: "Ausgewählte als ZIP exportieren", palette: palette) {
                    store.exportSelectedAsZip()
                }
            }
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
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

struct StripTileView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    let file: ClipboardFile
    let side: CGFloat

    @State private var thumbnail: NSImage?

    private var isSelected: Bool { store.selectedIDs.contains(file.id) }
    private var isHovered: Bool { store.hoveredFileID == file.id }

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Theme.Radius.preview, style: .continuous)
                    .fill(palette.cardFill)
                    .overlay {
                        if let thumbnail {
                            // A resizable .fill-mode image, left to size itself,
                            // grows to cover its proposed space and can overflow
                            // the square — clipShape only clips what's drawn,
                            // not the layout size it reports upward. Measuring
                            // the actual square here and handing the image an
                            // explicit frame pins it down for real.
                            GeometryReader { proxy in
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.preview, style: .continuous))
                        } else {
                            Image(nsImage: file.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(10)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.preview, style: .continuous)
                            .stroke(palette.cardBorder, lineWidth: 1)
                    )
                    .frame(width: side, height: side)
                    .task(id: file.id) {
                        thumbnail = await ThumbnailLoader.generate(for: file.url, size: CGSize(width: 160, height: 160))
                    }

                Button {
                    store.removeFile(file.id)
                } label: {
                    Image(systemName: SymbolIcon.remove)
                        .font(.system(size: 7, weight: .bold))
                }
                .buttonStyle(RemoveButtonStyle(palette: palette))
                .padding(4)
            }

            Text(FileSizeFormatter.label(bytes: file.sizeBytes))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.4)
                .foregroundColor(palette.subText)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .fill(isSelected ? palette.hoverFill : (isHovered ? palette.hoverFill.opacity(0.6) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .stroke(isSelected ? palette.accent : Color.clear, lineWidth: 1.5)
        )
        // The strip sits at the very top of the screen, so the bubble has to
        // open downwards — above the tile there is no window to draw into.
        .fileTooltip(file.name, isActive: isHovered, placement: .below)
        .anchorPreference(key: ContextMenuAnchorPreferenceKey.self, value: .bounds) { anchor in
            store.contextMenuFileID == file.id ? anchor : nil
        }
        .contentShape(Rectangle())
        .overlay(MultiItemDragHandle(file: file, store: store))
        .onHover { hovering in
            store.hoveredFileID = hovering ? file.id : (store.hoveredFileID == file.id ? nil : store.hoveredFileID)
        }
        .onRightClick {
            store.openContextMenu(for: file.id)
        }
    }
}

struct RemoveButtonStyle: ButtonStyle {
    let palette: PanelPalette
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 15, height: 15)
            .background(Circle().fill(isHovering ? Color(red: 0.898, green: 0.278, blue: 0.247) : palette.subText.opacity(0.18)))
            .foregroundColor(isHovering ? .white : palette.subText)
            .onHover { isHovering = $0 }
    }
}
