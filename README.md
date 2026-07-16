# FileDrop

Eine schwebende macOS-Zwischenablage für Dateien: per Drag & Drop gesammelte
Dateien liegen in einem frei platzierbaren Glas-Panel, das dauerhaft über dem
Desktop schwebt — mit eigener Kopfzeile statt der normalen macOS-Titelleiste.

Die Optik- und Verhaltensvorgaben stammen aus dem Design-Handoff in
[`design/handoff/README.md`](design/handoff/README.md) (Variante 1a,
Glas/Vibrancy). Die dort enthaltenen `.dc.html`-Dateien sind interaktive
Design-Referenzen (HTML-Prototypen), kein produktiver Code — dieses
Repository enthält die native SwiftUI/AppKit-Umsetzung.

**Abweichung vom Handoff:** Das Panel hat rechteckige statt abgerundete Ecken.
Fünf verschiedene technische Ansätze, die abgerundeten Ecken einer transparenten
`NSPanel` mit Vibrancy-Hintergrund sauber darzustellen, sind an hartnäckigen
AppKit/Core-Animation-Eigenheiten gescheitert (Reste blieben als undurchsichtige
Flecken hinter den runden Ecken sichtbar). Rechteckige Ecken plus ein klassischer
nativer Fensterschatten sind der pragmatische Kompromiss.

## Funktionen

- Grid- und Listenansicht der gesammelten Dateien mit echten Vorschaubildern
  (via QuickLookThumbnailing, wie in Finder — z. B. tatsächliches Bild bei
  Fotos, erste Seite bei PDFs); fällt auf das generische Dateityp-Icon
  zurück, wenn QuickLook keine Vorschau erzeugen kann. Vorschaubilder werden
  immer auf die normale Kachel-/Icon-Größe des Rasters begrenzt, unabhängig
  vom Seitenverhältnis der Originaldatei
- Beide Ansichten zeigen die Dateigröße statt der Typ-Kennung neben/unter
  jeder Datei
- Mehrfachauswahl per einfachem Klick (kein Modifier nötig, additiv, bleibt markiert)
- Rechtsklick-Kontextmenü (Löschen, Kopieren, Im Finder anzeigen); schließt
  sich bei Klick an beliebiger Stelle außerhalb
- Drag & Drop zum Sammeln von Dateien; einzelne Dateien lassen sich per Ziehen
  aus dem Panel wieder heraus in Finder/andere Apps ablegen
- Nur die Kopfzeile bewegt das Fenster (per Drag) — der Dateibereich ist rein
  für Auswahl/Drag-out reserviert
- Minimieren auf die Kopfzeile
- Hell/Dunkel-Umschalter
- Tooltips für alle Kopfzeilen-Icons (Hover zeigt die jeweilige Funktion)
- Menüleisten-Icon: einfacher Klick blendet das Panel direkt ein/aus.
  Rechtsklick zeigt ein Menü mit „Beim Start automatisch laden" (Haken zeigt
  an, ob aktiviert; per Klick umschaltbar, über `SMAppService`) und „Beenden"
- AirDrop-Button teilt die aktuell markierten Dateien über die native
  AirDrop-Freigabe
- ZIP-Button packt die markierten Dateien in ein Archiv auf dem Schreibtisch
  und öffnet es im Finder (nutzt `/usr/bin/zip`, auf jedem Mac vorhanden)

Papierkorb-, AirDrop- und ZIP-Button wirken nur auf die aktuell markierten
Dateien und tun bei leerer Auswahl nichts.

## Projektstruktur

```
Sources/FileDrop/
  FileDropApp.swift        App-Einstiegspunkt (SwiftUI App, kein Fenster-Scene)
  AppDelegate.swift         Menüleisten-Icon, Activation Policy
  Models/                   ClipboardFile, ClipboardStore (State), ThumbnailLoader
  Theme/                    Farbtoken (hell/dunkel)
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
