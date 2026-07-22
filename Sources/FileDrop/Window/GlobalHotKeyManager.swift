import Carbon.HIToolbox
import AppKit
import Combine

/// Registers a single global keyboard shortcut that fires regardless of
/// which app is currently frontmost, and re-registers automatically
/// whenever the user picks a new one in Settings. Carbon's
/// RegisterEventHotKey is used instead of NSEvent's global monitor because
/// the latter can only observe key presses — never actually claim them —
/// and typically needs Input Monitoring permission; the Carbon hotkey API
/// needs neither, which is why it's still the standard way menu bar
/// utilities implement a global shortcut on macOS.
@MainActor
final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let action: () -> Void
    private var cancellable: AnyCancellable?

    init(settings: AppSettings, action: @escaping () -> Void) {
        self.action = action
        register(keyCode: settings.hotKeyCode, modifiers: settings.hotKeyModifiers)

        cancellable = settings.$hotKeyCode
            .combineLatest(settings.$hotKeyModifiers)
            .dropFirst()
            .sink { [weak self] keyCode, modifiers in
                self?.unregister()
                self?.register(keyCode: keyCode, modifiers: modifiers)
            }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
    }

    private func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef); self.hotKeyRef = nil }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef); self.eventHandlerRef = nil }
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, userData in
            guard let eventRef, let userData else { return noErr }
            var receivedID = EventHotKeyID()
            GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &receivedID
            )
            guard receivedID.id == 1 else { return noErr }
            let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { manager.action() }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x46444450), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
