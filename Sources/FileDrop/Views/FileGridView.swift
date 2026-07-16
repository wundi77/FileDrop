import SwiftUI

struct FileGridView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.files) { file in
                FileTileView(store: store, palette: palette, file: file)
            }
        }
    }
}

struct FileTileView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    let file: ClipboardFile

    private var isSelected: Bool { store.selectedIDs.contains(file.id) }
    private var isHovered: Bool { store.hoveredFileID == file.id }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Theme.Radius.preview, style: .continuous)
                    .fill(palette.cardFill)
                    .overlay(
                        Image(nsImage: file.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.preview, style: .continuous)
                            .stroke(palette.cardBorder, lineWidth: 1)
                    )
                    .aspectRatio(1, contentMode: .fit)

                Button {
                    store.removeFile(file.id)
                } label: {
                    Image(systemName: SymbolIcon.remove)
                        .font(.system(size: 7, weight: .bold))
                }
                .buttonStyle(RemoveButtonStyle(palette: palette))
                .padding(4)
            }

            Text(file.ext)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.4)
                .foregroundColor(palette.subText)
        }
        .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .fill(isSelected ? palette.hoverFill : (isHovered ? palette.hoverFill.opacity(0.6) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .stroke(isSelected ? palette.accent : Color.clear, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            if isHovered {
                Text(file.name)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(palette.headerBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(palette.text)
                    )
                    .fixedSize()
                    .offset(y: -28)
                    .zIndex(30)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.toggleSelect(file.id)
        }
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
