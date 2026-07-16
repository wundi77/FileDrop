import SwiftUI

// The design handoff (design/handoff/) specifies hand-drawn SVG outline icons
// (trash, AirDrop rings, checkbox, zip, grid/list, sun/moon, minus/plus, x).
// For the native build we map each to the closest system-provided SF Symbol —
// this keeps icons crisp at every scale/appearance and matches macOS's own
// vocabulary instead of shipping bespoke vector art.
enum SymbolIcon {
    static let trash = "trash"
    static let selectAll = "checkmark.square"
    static let airdrop = "personalhotspot"
    static let zip = "doc.zipper"
    static let gridView = "square.grid.2x2"
    static let listView = "list.bullet"
    static let sun = "sun.max.fill"
    static let moon = "moon.fill"
    static let minimize = "minus"
    static let restore = "minus"
    static let close = "xmark"
    static let remove = "xmark"
    static let lock = "lock"
    static let delete = "trash"
    static let copy = "doc.on.doc"
    static let revealInFinder = "folder"
}

struct HeaderIconButton: View {
    let systemName: String
    let title: String
    var size: CGFloat = 28
    var iconSize: CGFloat = 13
    let palette: PanelPalette
    var hoverFill: Color?
    var hoverColor: Color?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(isHovering ? (hoverColor ?? palette.text) : palette.subText)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                        .fill(isHovering ? (hoverFill ?? palette.hoverFill) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { isHovering = $0 }
    }
}
