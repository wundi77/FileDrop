import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> RoundedVisualEffectView {
        let view = RoundedVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.cornerRadius = cornerRadius
        return view
    }

    func updateNSView(_ nsView: RoundedVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.cornerRadius = cornerRadius
    }
}

/// .behindWindow blending composites straight against the desktop at the
/// window-server level, bypassing SwiftUI's clipShape entirely — its square
/// corners show through behind the panel's rounded shape unless the view's
/// own layer is rounded. `wantsLayer`/`layer` can still be nil the instant
/// the view is created, so the corner mask is (re-)applied on every layout
/// pass and whenever the view joins a window, instead of relying on a single
/// makeNSView-time assignment.
final class RoundedVisualEffectView: NSVisualEffectView {
    var cornerRadius: CGFloat = 0 {
        didSet { applyCornerMask() }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyCornerMask()
    }

    override func layout() {
        super.layout()
        applyCornerMask()
    }

    private func applyCornerMask() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
    }
}
