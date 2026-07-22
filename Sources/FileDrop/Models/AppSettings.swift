import AppKit
import Combine

/// Persisted, app-wide preferences shown in the Settings window — separate
/// from ClipboardStore, which holds per-session file/selection state that
/// never needs to survive a restart (stripOpacity is the one exception: it
/// persists here because it's genuinely a preference, not session state).
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var stripHeightFraction: Double {
        didSet { UserDefaults.standard.set(stripHeightFraction, forKey: Keys.stripHeightFraction) }
    }

    /// nil means "automatic" — always follow NSScreen.main. Stored as the
    /// screen's CGDirectDisplayID rather than an NSScreen reference, since
    /// the actual NSScreen objects get recreated whenever displays
    /// reconnect.
    @Published var preferredScreenID: CGDirectDisplayID? {
        didSet {
            if let preferredScreenID {
                UserDefaults.standard.set(Int(preferredScreenID), forKey: Keys.preferredScreenID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.preferredScreenID)
            }
        }
    }

    private enum Keys {
        static let stripHeightFraction = "stripHeightFraction"
        static let preferredScreenID = "preferredScreenID"
    }

    private init() {
        let defaults = UserDefaults.standard
        stripHeightFraction = (defaults.object(forKey: Keys.stripHeightFraction) as? Double) ?? (1.0 / 6.0)
        if defaults.object(forKey: Keys.preferredScreenID) != nil {
            preferredScreenID = CGDirectDisplayID(defaults.integer(forKey: Keys.preferredScreenID))
        } else {
            preferredScreenID = nil
        }
    }

    /// The screen to dock the strip to — the user's chosen screen if it's
    /// still connected, otherwise falls back to whichever screen is main.
    var resolvedScreen: NSScreen {
        if let preferredScreenID,
           let match = NSScreen.screens.first(where: { $0.directDisplayID == preferredScreenID }) {
            return match
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }
}

extension NSScreen {
    var directDisplayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
