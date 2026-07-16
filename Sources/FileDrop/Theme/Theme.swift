import SwiftUI

struct PanelPalette {
    let headerBackground: Color
    let bodyBackground: Color
    let border: Color
    let text: Color
    let subText: Color
    let divider: Color
    let cardFill: Color
    let cardBorder: Color
    let accent: Color
    let danger: Color
    let hoverFill: Color
    let closeHoverFill: Color
}

enum Theme {
    static let light = PanelPalette(
        headerBackground: Color(red: 246 / 255, green: 246 / 255, blue: 248 / 255).opacity(0.72),
        bodyBackground: Color(red: 246 / 255, green: 246 / 255, blue: 248 / 255).opacity(0.9),
        border: Color.black.opacity(0.08),
        text: Color(red: 0x1c / 255, green: 0x1c / 255, blue: 0x1e / 255),
        subText: Color.black.opacity(0.45),
        divider: Color.black.opacity(0.09),
        cardFill: Color.white.opacity(0.55),
        cardBorder: Color.black.opacity(0.06),
        accent: Color(red: 0.30, green: 0.49, blue: 0.94),
        danger: Color(red: 0xd9 / 255, green: 0x36 / 255, blue: 0x2b / 255),
        hoverFill: Color.black.opacity(0.06),
        closeHoverFill: Color(red: 1, green: 0.23, blue: 0.19).opacity(0.12)
    )

    static let dark = PanelPalette(
        headerBackground: Color(red: 30 / 255, green: 30 / 255, blue: 34 / 255).opacity(0.72),
        bodyBackground: Color(red: 30 / 255, green: 30 / 255, blue: 34 / 255).opacity(0.9),
        border: Color.white.opacity(0.08),
        text: Color.white.opacity(0.92),
        subText: Color.white.opacity(0.5),
        divider: Color.white.opacity(0.1),
        cardFill: Color.white.opacity(0.06),
        cardBorder: Color.white.opacity(0.08),
        accent: Color(red: 0.47, green: 0.63, blue: 0.98),
        danger: Color(red: 1, green: 0.545, blue: 0.51),
        hoverFill: Color.white.opacity(0.1),
        closeHoverFill: Color(red: 1, green: 0.353, blue: 0.353).opacity(0.22)
    )

    static func palette(dark: Bool) -> PanelPalette { dark ? Theme.dark : Theme.light }

    enum Radius {
        static let tile: CGFloat = 11
        static let preview: CGFloat = 8
        static let button: CGFloat = 7
        static let contextMenu: CGFloat = 10
    }

    static let panelWidth: CGFloat = 500
    static let bodyMaxHeight: CGFloat = 460
}
