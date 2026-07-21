# FileDrop

> **Branch `design-experimente`:** Dieses Experiment ersetzt das frei
> schwebende Glas-Panel durch einen bildschirmbreiten Streifen, der per
> Menüleisten-Klick von oben unter der Menüleiste herausfährt. Der stabile
> Panel-Stand ist als Tag `v1.0-stable` auf `main` gesichert.

Eine macOS-Zwischenablage für Dateien: ein dunkler, deutlich transparenter
Streifen über die komplette Bildschirmbreite (ein Sechstel der
Bildschirmhöhe, direkt unter der Menüleiste, ohne Rand oder Fensterschatten)
sammelt per Drag & Drop abgelegte Dateien in einer einzelnen horizontalen Reihe.

Der ursprüngliche Design-Handoff liegt in
[`design/handoff/README.md`](design/handoff/README.md); die dort enthaltenen
`.dc.html`-Dateien sind interaktive Design-Referenzen (HTML-Prototypen), kein
produktiver Code. Das Streifen-Konzept dieses Branches weicht bewusst davon ab.

## Funktionen

- Ein Klick aufs Menüleisten-Icon fährt den Streifen animiert von oben
  herein bzw. wieder hinaus (er gleitet unter der Menüleiste hervor)
- Eine einzelne, horizontale Kachelreihe mit echten Vorschaubildern (via
  QuickLookThumbnailing, wie in Finder); fällt auf das generische
  Dateityp-Icon zurück, wenn QuickLook keine Vorschau erzeugen kann. Bei
  mehr Dateien als in eine Bildschirmbreite passen, scrollt die Reihe
  horizontal
- Unter jeder Kachel steht die Dateigröße; Hover zeigt den Dateinamen als
  Tooltip unterhalb der Kachel
- Mehrfachauswahl nur per Shift-Klick (additiv); ein einfacher Klick
  markiert/wählt nichts aus, sondern dient nur dem Klick-und-Ziehen selbst
- Rechtsklick-Kontextmenü (Löschen, Kopieren, Im Finder anzeigen), erscheint
  direkt unterhalb der angeklickten Kachel in kompakter Breite (eigenes,
  von der Streifenhöhe unabhängiges Fenster); schließt sich bei Klick an
  beliebiger Stelle außerhalb
- Drag & Drop zum Sammeln von Dateien und Ordnern; Ordnergröße wird rekursiv
  im Hintergrund berechnet. Dateien/Ordner lassen sich per Ziehen aus dem
  Streifen wieder heraus in Finder/andere Apps ablegen — als echte Kopie mit
  Original-Namen, der Ausgangs-Eintrag bleibt in der Ablage erhalten. Sind
  mehrere Dateien markiert und eine davon wird gezogen, wird die gesamte
  Auswahl als Paket kopiert (wie im Finder), mit einem roten Zähler-Badge
  auf dem gezogenen Icon
- Rechts im Streifen: Zähler (Anzahl + Gesamtgröße) und die vier
  Aktions-Buttons — Ausgewählte löschen, Alle auswählen, AirDrop, ZIP-Export
  auf den Schreibtisch (nutzt `/usr/bin/zip`); alle wirken nur auf die
  aktuell markierten Dateien und tun bei leerer Auswahl nichts
- Menüleisten-Icon per Rechtsklick: Menü mit „Beim Start automatisch laden"
  (Haken zeigt an, ob aktiviert; über `SMAppService`) und „Beenden"

Im Streifen-Konzept entfallen gegenüber dem Panel-Stand: Grid/Listen-Umschalter
(es gibt nur die eine Reihe), Minimieren auf die Kopfzeile, Hell/Dunkel-Umschalter
(der Streifen ist fest dunkel) und das Verschieben des Fensters.

## Projektstruktur

```
Sources/FileDrop/
  FileDropApp.swift        App-Einstiegspunkt (SwiftUI App, kein Fenster-Scene)
  AppDelegate.swift         Menüleisten-Icon, Activation Policy
  Models/                   ClipboardFile, ClipboardStore (State), ThumbnailLoader
  Theme/                    Farbtoken
  Views/                    Streifen (StripView), Kontextmenü, Drop-Overlay, Tooltips
  Window/                   Borderless NSPanel + Controller (Slide-Animation),
                             separates Panel für das Kontextmenü
design/handoff/             Original-Design-Handoff (Referenz, nicht Teil der App)
Resources/AppIcon.iconset/  Festes App-Icon (alle .iconset-Größen), wird bei jedem
                             Build unverändert übernommen
build.sh                     Baut ein fertiges FileDrop.app-Bundle
```

## Entwicklung (ohne Bundle)

Voraussetzung: Xcode-Kommandozeilentools (Swift 5.10+, macOS 13+).

```sh
swift build
swift run
```

Die App läuft als Accessory-App ohne Dock-Icon; der Streifen fährt beim
Start am oberen Bildschirmrand herein und lässt sich über das
Menüleisten-Icon ein-/ausfahren.

## Fertiges App-Bundle bauen

```sh
./build.sh          # baut build/FileDrop.app
./build.sh --run     # baut und startet die App danach direkt
```

Der Build-Schritt:
1. kompiliert im Release-Modus (`swift build -c release`),
2. packt das feste Icon aus `Resources/AppIcon.iconset/` per `iconutil` zu
   `AppIcon.icns` (dasselbe Icon bei jedem Build, kein Neu-Zeichnen),
3. baut daraus `build/FileDrop.app` (Info.plist, Executable, Icon) und
   signiert es ad-hoc, damit Gatekeeper es ohne Warnung startet.

`build/` ist generiert und nicht Teil des Repos (siehe `.gitignore`).
