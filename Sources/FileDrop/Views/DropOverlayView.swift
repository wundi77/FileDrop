import SwiftUI

struct DropOverlayView: View {
    let palette: PanelPalette
    let cornerRadius: CGFloat
    let isDark: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .foregroundColor(palette.accent)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isDark ? Color.black.opacity(0.55) : Color.white.opacity(0.75))
            )
            .overlay(
                Text("Dateien hier ablegen")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.accent)
            )
            .padding(10)
            .allowsHitTesting(false)
    }
}
