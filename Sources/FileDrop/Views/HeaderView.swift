import SwiftUI

struct HeaderView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                HStack(spacing: 8) {
                    HeaderIconButton(systemName: SymbolIcon.trash, title: "Alle Dateien löschen", palette: palette) {
                        store.clearAll()
                    }
                    HeaderIconButton(systemName: SymbolIcon.selectAll, title: "Alle auswählen", palette: palette) {
                        store.toggleSelectAll()
                    }
                    HeaderIconButton(systemName: SymbolIcon.airdrop, title: "Über AirDrop teilen", palette: palette) {}
                    HeaderIconButton(systemName: SymbolIcon.zip, title: "Als ZIP packen", palette: palette) {}
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
        .background(WindowDragHandle())
        .overlay(Rectangle().fill(palette.divider).frame(height: 1), alignment: .bottom)
    }
}
