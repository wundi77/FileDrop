import AppKit

/// "Öffnen mit …" for the context menu. The card itself is a plain SwiftUI
/// view with no native submenu support, so this pops a real NSMenu instead —
/// listing every app the system considers able to open the file, each with
/// its own icon, exactly like Finder's "Open With" submenu.
enum OpenWithMenu {
    static func show(for url: URL) {
        let apps = NSWorkspace.shared.urlsForApplications(toOpen: url)
        guard !apps.isEmpty else { return }

        let menu = NSMenu()
        for appURL in apps {
            let name = FileManager.default.displayName(atPath: appURL.path)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 16, height: 16)

            let menuItem = NSMenuItem(title: name, action: #selector(OpenWithTarget.open(_:)), keyEquivalent: "")
            menuItem.image = icon
            menuItem.representedObject = (fileURL: url, appURL: appURL)
            menuItem.target = OpenWithTarget.shared
            menu.addItem(menuItem)
        }

        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

private final class OpenWithTarget: NSObject {
    static let shared = OpenWithTarget()

    @objc func open(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? (fileURL: URL, appURL: URL) else { return }
        NSWorkspace.shared.open(
            [pair.fileURL],
            withApplicationAt: pair.appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }
}
