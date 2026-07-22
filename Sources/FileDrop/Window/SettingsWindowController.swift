import AppKit
import SwiftUI

/// A plain, regular NSWindow for Settings — the strip itself only knows how
/// to be a borderless auto-hiding panel, and Settings needs the opposite:
/// a normal titled window that stays open and behaves like any other Mac
/// preferences window.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(store: ClipboardStore) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Einstellungen"
        window.contentView = NSHostingView(rootView: SettingsView(store: store))
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
