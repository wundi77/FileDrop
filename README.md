# FileDrop

> **Branch `filedrop-erweiterung`:** Erweitert den seit `main` aktiven
> Streifen-Stand (Tag `v2.0-strip`) um weitere Funktionen (Ablagen/Reiter,
> globaler Shortcut, Cmd+V-Einfügen, Auto-Einklappen, Einstellungsfenster,
> Teilen-Menü, Bildkonvertierung u. a.). Der alte, frei schwebende
> Glas-Panel-Stand ist als Tag `v1.0-stable` gesichert.

Eine macOS-Zwischenablage für Dateien: ein dunkler, in der Transparenz frei
einstellbarer Streifen über die komplette Bildschirmbreite (ein Sechstel der
Bildschirmhöhe, direkt unter der Menüleiste, ohne Rand oder Fensterschatten)
sammelt per Drag & Drop abgelegte Dateien in einer einzelnen horizontalen Reihe.

Der ursprüngliche Design-Handoff liegt in
[`design/handoff/README.md`](design/handoff/README.md); die dort enthaltenen
`.dc.html`-Dateien sind interaktive Design-Referenzen (HTML-Prototypen), kein
produktiver Code. Das Streifen-Konzept dieses Branches weicht bewusst davon ab.

## Funktionen

- Ein Klick aufs Menüleisten-Icon fährt den Streifen animiert von oben
  herein bzw. wieder hinaus (er gleitet unter der Menüleiste hervor); ein
  globaler Tastatur-Shortcut (⌃⌥D, systemweit, unabhängig von der
  Vordergrund-App) macht dasselbe
- Mehrere Ablagen ("Stapel", wie bei Yoink): schmale Reiter-Leiste oben im
  Streifen, jede Ablage hat ihre eigenen Dateien und ihre eigene Auswahl;
  „+" legt eine neue Ablage an, Rechtsklick auf einen Reiter schließt sie
  wieder (mindestens eine bleibt immer bestehen)
- Eine einzelne, horizontale Kachelreihe mit echten Vorschaubildern (via
  QuickLookThumbnailing, wie in Finder); fällt auf das generische
  Dateityp-Icon zurück, wenn QuickLook keine Vorschau erzeugen kann. Bei
  mehr Dateien als in eine Bildschirmbreite passen, scrollt die Reihe
  horizontal
- Unter jeder Kachel steht die Dateigröße; Hover zeigt den Dateinamen als
  Tooltip unterhalb der Kachel
- Mehrfachauswahl nur per Shift-Klick (additiv); ein einfacher Klick
  markiert/wählt nichts aus, sondern dient nur dem Klick-und-Ziehen selbst
- Leertaste bei ausgewählter (oder, falls keine Auswahl besteht, gerade
  gehoverter) Datei öffnet die normale System-Vorschau (Quick Look)
- Cmd+V fügt Dateien direkt aus der Zwischenablage ein, genau wie ein
  Drag & Drop
- Sobald eine Kachel aus dem Streifen heraus gezogen wird, fährt der
  Streifen sofort selbstständig wieder ein (wie bei Yoink) und lässt so
  Platz für den Drop-Zielbereich; die laufende Drag-Session bleibt davon
  unberührt
- Regler rechts oberhalb der Zähler-Anzeige (dünne Linie mit orangem
  Ziehpunkt) stellt die Transparenz des gesamten Streifens frei ein, von
  nahezu deckend bis kaum noch sichtbar; der Wert bleibt über Neustarts
  hinweg erhalten
- Rechtsklick-Kontextmenü (Löschen, Kopieren, Im Finder anzeigen, Öffnen
  mit …), erscheint direkt unterhalb der angeklickten Kachel in kompakter
  Breite (eigenes, von der Streifenhöhe unabhängiges Fenster); schließt sich
  bei Klick an beliebiger Stelle außerhalb. „Kopieren" kopiert bei
  bestehender Mehrfachauswahl die gesamte Auswahl statt nur der
  angeklickten Datei; „Öffnen mit …" zeigt das native App-Auswahlmenü
- Drag & Drop zum Sammeln von Dateien und Ordnern; Ordnergröße wird rekursiv
  im Hintergrund berechnet. Dateien/Ordner lassen sich per Ziehen aus dem
  Streifen wieder heraus in Finder/andere Apps ablegen — als echte Kopie mit
  Original-Namen, der Ausgangs-Eintrag bleibt in der Ablage erhalten. Sind
  mehrere Dateien markiert und eine davon wird gezogen, wird die gesamte
  Auswahl als Paket kopiert (wie im Finder), mit einem roten Zähler-Badge
  auf dem gezogenen Icon
- Rechts im Streifen: Zähler (Anzahl + Gesamtgröße) und die Aktions-Buttons
  — Ausgewählte löschen, Alle auswählen, AirDrop, systemweites Teilen-Menü
  (Mail, Nachrichten, etc. über `NSSharingServicePicker`), Bilder
  verkleinern/konvertieren (JPEG/PNG, optionale Maximalgröße, JPEG-Qualität
  — Ergebnis landet auf dem Schreibtisch) und ZIP-Export auf den
  Schreibtisch (nutzt `/usr/bin/zip`); alle wirken nur auf die aktuell
  markierten Dateien (der Bild-Button nur auf die Bilder darin) und tun bei
  leerer Auswahl nichts
- Menüleisten-Icon per Rechtsklick: Menü mit „Beim Start automatisch laden"
  (Haken zeigt an, ob aktiviert; über `SMAppService`), „Einstellungen …"
  (⌘,) und „Beenden"
- Einstellungsfenster: Streifenhöhe (Anteil der Bildschirmhöhe),
  Standard-Transparenz und Bildschirmwahl bei mehreren Monitoren
  (persistiert über `UserDefaults`, fällt automatisch auf den Hauptbildschirm
  zurück, falls der gewählte Monitor nicht mehr angeschlossen ist)

Im Streifen-Konzept entfallen gegenüber dem Panel-Stand: Grid/Listen-Umschalter
(es gibt nur die eine Reihe), Minimieren auf die Kopfzeile, Hell/Dunkel-Umschalter
(der Streifen ist fest dunkel) und das Verschieben des Fensters.

## Projektstruktur

```
Sources/FileDrop/
  FileDropApp.swift        App-Einstiegspunkt (SwiftUI App, kein Fenster-Scene)
  AppDelegate.swift         Menüleisten-Icon, Activation Policy, globaler Shortcut
  Models/                   ClipboardFile, ClipboardStore (State, inkl. Shelves),
                             AppSettings (persistierte Einstellungen),
                             ImageExportService, ThumbnailLoader
  Theme/                    Farbtoken
  Views/                    Streifen (StripView) inkl. Ablagen-Reiter,
                             Transparenz-Regler, Kontextmenü, Einstellungsfenster,
                             Bild-Export-Popover, Drop-Overlay, Tooltips
  Window/                   Borderless NSPanel + Controller (Slide-Animation),
                             separates Panel für das Kontextmenü,
                             Quick-Look-Anbindung, globaler Hotkey (Carbon),
                             "Öffnen mit …" (natives NSMenu), Einstellungsfenster
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
