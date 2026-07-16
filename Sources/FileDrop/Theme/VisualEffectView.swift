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
/// corners show through behind the panel's rounded shape unless clipped on
/// the view's own layer. Two things matter here, both learned the hard way:
///  - Don't force `wantsLayer = true` ourselves. NSVisualEffectView already
///    manages its own backing layer for the blur; assigning a fresh one can
///    disconnect that internal blur layer from whatever mask we apply to the
///    (now different) `.layer` we created.
///  - Use an explicit `CAShapeLayer` mask, not `cornerRadius` +
///    `masksToBounds`. The vibrancy backdrop isn't drawn like normal layer
///    content — masksToBounds on it was a no-op in practice, an alpha mask
///    is not.
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
        guard let layer, bounds.width > 0, bounds.height > 0 else { return }
        let shape = CAShapeLayer()
        shape.path = CGPath(roundedRect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        layer.mask = shape
    }
}
