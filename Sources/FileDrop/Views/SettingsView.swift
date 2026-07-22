import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject var store: ClipboardStore

    @State private var isRecordingShortcut = false

    private var screens: [NSScreen] { NSScreen.screens }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tastenkombination zum Ein-/Ausblenden")
                    HStack {
                        Button {
                            isRecordingShortcut = true
                        } label: {
                            Text(isRecordingShortcut ? "Drücke eine Tastenkombination …" : ShortcutDisplay.string(keyCode: settings.hotKeyCode, modifiers: settings.hotKeyModifiers))
                                .frame(minWidth: 160)
                        }
                        .background(
                            ShortcutRecorderView(isRecording: $isRecordingShortcut) { keyCode, modifiers in
                                settings.hotKeyCode = keyCode
                                settings.hotKeyModifiers = modifiers
                            }
                            .frame(width: 0, height: 0)
                        )

                        Button("Zurücksetzen") {
                            settings.hotKeyCode = AppSettings.defaultHotKeyCode
                            settings.hotKeyModifiers = AppSettings.defaultHotKeyModifiers
                        }
                    }
                    Text("Muss mindestens eine Zusatztaste enthalten (⌃, ⌥, ⇧ oder ⌘).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Streifenhöhe: \(Int(settings.stripHeightFraction * 100)) % der Bildschirmhöhe")
                    Slider(value: $settings.stripHeightFraction, in: 0.08...0.35)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Standard-Transparenz: \(Int(store.stripOpacity * 100)) %")
                    Slider(value: $store.stripOpacity, in: OpacitySliderView.range)
                }
            }

            Section {
                Picker("Bildschirm", selection: $settings.preferredScreenID) {
                    Text("Automatisch (Hauptbildschirm)").tag(CGDirectDisplayID?.none)
                    ForEach(screens.indices, id: \.self) { index in
                        let screen = screens[index]
                        if let id = screen.directDisplayID {
                            Text(screen.localizedName).tag(CGDirectDisplayID?.some(id))
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
