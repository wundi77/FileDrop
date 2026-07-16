import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = PanelController()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setUpStatusItem()
        panelController.show()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "tray.full", accessibilityDescription: "FileDrop")
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusItem = item
    }

    // A left click toggles the panel directly, with no menu in the way.
    // A right click still needs a way to quit, so it briefly attaches a menu
    // and triggers it programmatically, then detaches it again — otherwise
    // NSStatusItem shows that menu on every click (left included).
    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showQuitMenu()
        } else {
            togglePanel()
        }
    }

    private func showQuitMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePanel() {
        guard let panel = panelController.panel else {
            panelController.show()
            return
        }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panelController.show()
        }
    }
}
