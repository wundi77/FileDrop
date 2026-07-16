# FileDrop

Eine schwebende macOS-Zwischenablage für Dateien: per Drag & Drop gesammelte
Dateien liegen in einem frei platzierbaren Glas-Panel, das dauerhaft über dem
Desktop schwebt — mit eigener Kopfzeile statt der normalen macOS-Titelleiste.

Die Optik- und Verhaltensvorgaben stammen aus dem Design-Handoff in
[`design/handoff/README.md`](design/handoff/README.md) (Variante 1a,
Glas/Vibrancy). Die dort enthaltenen `.dc.html`-Dateien sind interaktive
Design-Referenzen (HTML-Prototypen), kein produktiver Code — dieses
Repository enthält die native SwiftUI/AppKit-Umsetzung.

## Funktionen

- Grid- und Listenansicht der gesammelten Dateien
- Mehrfachauswahl per einfachem Klick (kein Modifier nötig, additiv, bleibt markiert)
- Rechtsklick-Kontextmenü (Bild sperren, Löschen, Kopieren, Im Finder anzeigen)
- Drag & Drop zum Sammeln von Dateien; einzelne Dateien lassen sich per Ziehen
  aus dem Panel wieder heraus in Finder/andere Apps ablegen
- Nur die Kopfzeile bewegt das Fenster (per Drag) — der Dateibereich ist rein
  für Auswahl/Drag-out reserviert
- Minimieren auf die Kopfzeile
- Hell/Dunkel-Umschalter
- Tooltips für alle Kopfzeilen-Icons (Hover zeigt die jeweilige Funktion)
- Menüleisten-Icon zum Ein-/Ausblenden des Panels

Papierkorb-, AirDrop- und ZIP-Buttons in der Kopfzeile sind aktuell
Platzhalter ohne Funktion (siehe Design-Handoff).

## Projektstruktur

```
Sources/FileDrop/
  FileDropApp.swift        App-Einstiegspunkt (SwiftUI App, kein Fenster-Scene)
  AppDelegate.swift         Menüleisten-Icon, Activation Policy
  Models/                   ClipboardFile, ClipboardStore (State)
  Theme/                    Farbtoken (hell/dunkel), Vibrancy-Blur
  Views/                    Header, Grid-/Listenansicht, Kontextmenü, Drop-Overlay
  Window/                   Borderless NSPanel + Controller
design/handoff/             Original-Design-Handoff (Referenz, nicht Teil der App)
Scripts/generate_icon.swift  Zeichnet das App-Icon (alle .iconset-Größen)
build.sh                     Baut ein fertiges FileDrop.app-Bundle
```

## Entwicklung (ohne Bundle)

Voraussetzung: Xcode-Kommandozeilentools (Swift 5.10+, macOS 13+).

```sh
swift build
swift run
```

Die App läuft als Accessory-App ohne Dock-Icon; das Panel erscheint beim
Start oben rechts auf dem Hauptbildschirm und lässt sich über das
Menüleisten-Icon ein-/ausblenden.

## Fertiges App-Bundle bauen

```sh
./build.sh          # baut build/FileDrop.app
./build.sh --run     # baut und startet die App danach direkt
```

Der Build-Schritt:
1. kompiliert im Release-Modus (`swift build -c release`),
2. erzeugt bei jedem Lauf frisch ein App-Icon (`Scripts/generate_icon.swift`
   zeichnet alle `.iconset`-Größen, `iconutil` packt sie zu `AppIcon.icns`),
3. baut daraus `build/FileDrop.app` (Info.plist, Executable, Icon) und
   signiert es ad-hoc, damit Gatekeeper es ohne Warnung startet.

`build/` ist generiert und nicht Teil des Repos (siehe `.gitignore`).
