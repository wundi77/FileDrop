import SwiftUI

struct HeaderView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
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
                    HeaderIconButton(systemName: SymbolIcon.zip, title: "Ausgewählte als ZIP exportieren", palette: palette) {
                        store.exportSelectedAsZip()
                    }
                }
                .padding(.trailing, 10)
                .overlay(Rectangle().fill(palette.divider).frame(width: 1), alignment: .trailing)
                .padding(.trailing, 2)

                HeaderIconButton(
                    systemName: store.viewMode == .grid ? SymbolIcon.listView : SymbolIcon.gridView,
                    title: "Ansicht wechseln",
                    palette: palette
                ) {
                    store.viewMode = store.viewMode == .grid ? .list : .grid
                }

                HeaderIconButton(
                    systemName: store.isDarkMode ? SymbolIcon.sun : SymbolIcon.moon,
                    title: "Darstellung umschalten",
                    palette: palette
                ) {
                    store.isDarkMode.toggle()
                }

                Text(store.countLabel)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(palette.subText)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.leading, 4)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                HeaderIconButton(
                    systemName: store.isMinimized ? "plus" : SymbolIcon.minimize,
                    title: store.isMinimized ? "Fenster wiederherstellen" : "Auf Kopfzeile reduzieren",
                    size: 26,
                    palette: palette
                ) {
                    store.isMinimized.toggle()
                }
                HeaderIconButton(
                    systemName: SymbolIcon.close,
                    title: "Schließen",
                    size: 26,
                    palette: palette,
                    hoverFill: palette.closeHoverFill,
                    hoverColor: palette.danger
                ) {
                    onClose()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .gesture(
            // Pure SwiftUI window drag, replacing an NSViewRepresentable
            // background view that turned out to be a repeat suspect in the
            // corner-transparency saga: this removes the only AppKit-bridged
            // content from the header entirely. A small minimumDistance
            // keeps ordinary clicks on the buttons/text from being
            // swallowed as a (zero-movement) drag.
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    store.onHeaderDragChanged(value.translation)
                }
                .onEnded { _ in
                    store.onHeaderDragEnded()
                }
        )
        .overlay(Rectangle().fill(palette.divider).frame(height: 1), alignment: .bottom)
    }
}
