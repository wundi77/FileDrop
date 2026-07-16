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

// MARK: - Tooltip plumbing
//
// The panel clips its whole content to a rounded rect and the scrollable file
// body clips its own overflow, so a tooltip nested directly under a header
// button or a file tile gets clipped or painted over (header buttons: cut by
// the panel's rounded corner; file tiles in the top row: cut by the
// ScrollView's own edge). Instead each hoverable control publishes its hover
// title + on-screen bounds via a preference; ClipboardPanelView reads it
// once, at the top level (after clipShape/ScrollView), and draws the bubble
// unclipped, above everything else.
struct PanelTooltipInfo {
    let title: String
    let anchor: Anchor<CGRect>
    /// Whether the bubble should render above or below the anchored control.
    let placement: PanelTooltipPlacement
}

enum PanelTooltipPlacement {
    case above
    case below
}

struct PanelTooltipPreferenceKey: PreferenceKey {
    static var defaultValue: PanelTooltipInfo?
    static func reduce(value: inout PanelTooltipInfo?, nextValue: () -> PanelTooltipInfo?) {
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
        .anchorPreference(key: PanelTooltipPreferenceKey.self, value: .bounds) { anchor in
            isHovering ? PanelTooltipInfo(title: title, anchor: anchor, placement: .below) : nil
        }
    }
}

extension View {
    /// Publishes `title` as a panel-level tooltip (see PanelTooltipPreferenceKey)
    /// while `isActive` is true, rendered above the view's bounds.
    func fileTooltip(_ title: String, isActive: Bool) -> some View {
        anchorPreference(key: PanelTooltipPreferenceKey.self, value: .bounds) { anchor in
            isActive ? PanelTooltipInfo(title: title, anchor: anchor, placement: .above) : nil
        }
    }
}

struct PanelTooltipOverlay: View {
    let info: PanelTooltipInfo
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
                .position(x: rect.midX, y: info.placement == .below ? rect.maxY + 13 : rect.minY - 13)
                .allowsHitTesting(false)
        }
    }
}
