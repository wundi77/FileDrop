import AppKit
import Combine
import SwiftUI

@MainActor
final class PanelController {
    let store = ClipboardStore()
    private(set) var panel: FloatingPanel!
    private var hostingView: NSHostingView<StripView>!
    private var contextMenuController: ContextMenuPanelController!
    private let quickLookController = QuickLookController()
    private var contextMenuFileIDCancellable: AnyCancellable?
    private var spaceKeyMonitor: Any?
    /// True while the slide-up animation is running, so a re-toggle during
    /// the animation cleanly flips back to showing instead of racing the
    /// pending orderOut.
    private var isAnimatingOut = false
    /// The strip's current on-screen frame, needed to translate the
    /// right-clicked tile's local rect into a screen position for the
    /// separate context menu panel.
    private var stripScreenFrame: NSRect = .zero
    private var lastContextMenuAnchor: CGRect?

    var isStripVisible: Bool { (panel?.isVisible ?? false) && !isAnimatingOut }

    deinit {
        if let spaceKeyMonitor {
            NSEvent.removeMonitor(spaceKeyMonitor)
        }
    }

    func toggle() {
        if isStripVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            setUp()
        }
        isAnimatingOut = false
        let frames = stripFrames()
        stripScreenFrame = frames.visible
        panel.setFrame(frames.hidden, display: false)
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frames.visible, display: true)
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        isAnimatingOut = true
        store.closeContextMenu()
        let frames = stripFrames()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.26
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(frames.hidden, display: true)
        }, completionHandler: {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isAnimatingOut else { return }
                self.panel.orderOut(nil)
                self.isAnimatingOut = false
            }
        })
    }

    /// Full screen width, one sixth of the screen height, docked directly
    /// below the menu bar. The hidden frame sits entirely above the visible
    /// area, so the slide animation looks like the strip glides out from
    /// under the menu bar.
    private func stripFrames() -> (hidden: NSRect, visible: NSRect) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let height = floor(screen.frame.height * Theme.stripHeightFraction)
        let topY = screen.visibleFrame.maxY
        let visible = NSRect(x: screen.frame.minX, y: topY - height, width: screen.frame.width, height: height)
        let hidden = visible.offsetBy(dx: 0, dy: height)
        return (hidden, visible)
    }

    private func setUp() {
        let frames = stripFrames()
        stripScreenFrame = frames.visible
        let panel = FloatingPanel(contentRect: frames.visible)

        let contextMenuController = ContextMenuPanelController(store: store)

        let hostingView = NSHostingView(rootView: StripView(store: store) { [weak self] anchorRect in
            guard let self else { return }
            self.lastContextMenuAnchor = anchorRect
            self.refreshContextMenu()
        })
        hostingView.frame = NSRect(origin: .zero, size: frames.visible.size)
        hostingView.autoresizingMask = [.width, .height]
        // Keeps the vibrancy material's translucency intact — without an
        // explicit clear/non-opaque layer, the hosting view's own backing
        // can otherwise paint solid rather than letting the blur through.
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView
        self.contextMenuController = contextMenuController

        contextMenuFileIDCancellable = store.$contextMenuFileID
            .sink { [weak self] _ in self?.refreshContextMenu() }

        // SwiftUI has no direct hook for a bare space-bar shortcut here (no
        // text field/button owns first responder), so catch it at the
        // AppKit level instead, scoped to this panel only.
        spaceKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel, event.charactersIgnoringModifiers == " " else {
                return event
            }
            self.toggleQuickLook()
            return nil
        }
    }

    private func toggleQuickLook() {
        let urls = store.selectedURLs.isEmpty ? hoveredURL.map { [$0] } ?? [] : store.selectedURLs
        quickLookController.toggle(urls: urls)
    }

    private var hoveredURL: URL? {
        guard let hoveredFileID = store.hoveredFileID else { return nil }
        return store.files.first(where: { $0.id == hoveredFileID })?.url
    }

    private func refreshContextMenu() {
        contextMenuController.update(
            anchorRect: lastContextMenuAnchor,
            stripScreenFrame: stripScreenFrame,
            fileID: store.contextMenuFileID,
            palette: Theme.dark
        )
    }
}
