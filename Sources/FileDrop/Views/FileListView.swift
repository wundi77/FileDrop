import SwiftUI

struct FileListView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette

    var body: some View {
        VStack(spacing: 2) {
            ForEach(store.files) { file in
                FileRowView(store: store, palette: palette, file: file)
            }
        }
    }
}

struct FileRowView: View {
    @ObservedObject var store: ClipboardStore
    let palette: PanelPalette
    let file: ClipboardFile

    @State private var thumbnail: NSImage?

    private var isSelected: Bool { store.selectedIDs.contains(file.id) }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.removeFile(file.id)
            } label: {
                Image(systemName: SymbolIcon.remove)
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(RemoveButtonStyle(palette: palette))
            .frame(width: 18, height: 18)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(palette.cardFill)
                .overlay {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Image(nsImage: file.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(4)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(palette.cardBorder, lineWidth: 1))
                .frame(width: 26, height: 26)
                .task(id: file.id) {
                    thumbnail = await ThumbnailLoader.generate(for: file.url, size: CGSize(width: 52, height: 52))
                }

            Text(file.name)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(palette.text)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(FileSizeFormatter.label(bytes: file.sizeBytes))
                .font(.system(size: 10, design: .monospaced))
                .tracking(0.3)
                .foregroundColor(palette.subText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? palette.hoverFill : Color.clear)
        )
        .contentShape(Rectangle())
        .background(MultiItemDragHandle(file: file, store: store))
        .onRightClick {
            store.openContextMenu(for: file.id)
        }
    }
}
