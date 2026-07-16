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

// MARK: - Header tooltip plumbing
//
// The panel clips its whole content to a rounded rect and the file body sits
// right below the header, so a tooltip nested directly under a header button
// would get clipped or painted over. Instead each button publishes its
// hover title + on-screen bounds via a preference; ClipboardPanelView reads
// it once, at the top level (after the panel's own clipShape), and draws the
// bubble unclipped, above everything else.
struct HeaderTooltipInfo {
    let title: String
    let anchor: Anchor<CGRect>
}

struct HeaderTooltipPreferenceKey: PreferenceKey {
    static var defaultValue: HeaderTooltipInfo?
    static func reduce(value: inout HeaderTooltipInfo?, nextValue: () -> HeaderTooltipInfo?) {
        value = nextValue() ?? value
    }
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
        .anchorPreference(key: HeaderTooltipPreferenceKey.self, value: .bounds) { anchor in
            isHovering ? HeaderTooltipInfo(title: title, anchor: anchor) : nil
        }
    }
}

struct HeaderTooltipOverlay: View {
    let info: HeaderTooltipInfo
    let palette: PanelPalette

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy[info.anchor]
            Text(info.title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(palette.headerBackground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.text)
                )
                .fixedSize()
                .position(x: rect.midX, y: rect.maxY + 13)
                .allowsHitTesting(false)
        }
    }
}
