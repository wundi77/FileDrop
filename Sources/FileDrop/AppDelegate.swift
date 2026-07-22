import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = PanelController()
    private let settingsWindowController = SettingsWindowController()
    private var statusItem: NSStatusItem!
    private var hotKeyManager: GlobalHotKeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setUpStatusItem()
        panelController.show()
        hotKeyManager = GlobalHotKeyManager(settings: AppSettings.shared) { [weak self] in self?.panelController.toggle() }
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

    // A left click slides the strip in/out directly, with no menu in the
    // way. A right click shows the dropdown (launch-at-login, quit); it
    // briefly attaches a menu and triggers it programmatically, then
    // detaches it again — otherwise NSStatusItem shows that menu on every
    // click (left included).
    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            panelController.toggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let launchItem = NSMenuItem(
            title: "Beim Start automatisch laden",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Einstellungen …",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showSettings() {
        settingsWindowController.show(store: panelController.store)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            // Best-effort toggle; nothing user-facing to recover if
            // registration fails (e.g. running an unsigned dev build).
        }
    }

}
