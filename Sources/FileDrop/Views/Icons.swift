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

// MARK: - Context menu anchoring
//
// The context menu used to sit at a fixed offset from the strip's corner,
// which meant it landed nowhere near the tile that was actually right-clicked
// once the strip filled up with more than a couple of files. Instead the
// right-clicked tile publishes its own bounds the same way tooltips do, and
// the strip reads that once, at the top level, to position the menu card
// right next to that tile.
struct ContextMenuAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
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
    /// while `isActive` is true, rendered above or below the view's bounds.
    func fileTooltip(_ title: String, isActive: Bool, placement: PanelTooltipPlacement = .above) -> some View {
        anchorPreference(key: PanelTooltipPreferenceKey.self, value: .bounds) { anchor in
            isActive ? PanelTooltipInfo(title: title, anchor: anchor, placement: placement) : nil
        }
    }
}

struct PanelTooltipOverlay: View {
    let info: PanelTooltipInfo
    let palette: PanelPalette

    // The window is exactly as wide as the panel — there are no pixels past
    // its edge to draw into, so a bubble simply centered on an icon near the
    // left/right edge gets hard-clipped by the window's own frame rather
    // than just visually overlapping something. Since we can't measure the
    // bubble's rendered width before laying it out, clamp its center using a
    // conservative half-width estimate that comfortably covers our longest
    // tooltip strings, keeping it fully inside the panel either way.
    private let estimatedHalfWidth: CGFloat = 115
    private let edgeMargin: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy[info.anchor]
            let panelWidth = proxy.size.width
            let lowerBound = estimatedHalfWidth + edgeMargin
            let upperBound = max(panelWidth - estimatedHalfWidth - edgeMargin, lowerBound)
            let clampedX = min(max(rect.midX, lowerBound), upperBound)

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
                .position(x: clampedX, y: info.placement == .below ? rect.maxY + 13 : rect.minY - 13)
                .allowsHitTesting(false)
        }
    }
}
