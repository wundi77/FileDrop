# Handoff: Mac Zwischenablage-App — Variante 1a (Glas/Vibrancy)

## Overview
Eine schwebende macOS-Desktop-App, die als flexible Zwischenablage für Dateien dient. Nutzer sammeln Dateien (per Drag & Drop) in einem durchgängigen Raster; das Fenster hat eine eigene, transparente Kopfzeile statt der normalen macOS-Titelleiste.

## About the Design Files
Die Dateien in diesem Paket (`ClipboardPanel.dc.html`, `Mac Zwischenablage-App Layout.dc.html`) sind **Design-Referenzen, gebaut in HTML** — hochauflösende Prototypen, die Optik und Verhalten zeigen, kein produktionsreifer Code zum direkten Kopieren. Aufgabe ist es, dieses Design in der Zielumgebung (z. B. SwiftUI/AppKit für eine native Mac-App, oder Electron/Tauri + Web-Stack) nachzubauen — unter Nutzung der dort etablierten Muster und Bibliotheken. Falls noch keine Umgebung existiert, sollte das für eine native Mac-Zwischenablage sinnvollste Framework (typischerweise SwiftUI mit einem `NSPanel`/borderless Fenster) gewählt werden.

## Fidelity
**High-fidelity.** Farben, Typografie, Abstände und Interaktionen sind final gemeint. Die Vorschau-Kacheln der Dateien sind bewusst Platzhalter (gestreiftes Muster) — hier sollen später echte Thumbnails/Icons der jeweiligen Dateitypen rein.

## Screens / Views
Nur eine Ansicht: das Zwischenablage-Panel selbst, in zwei Zuständen (normal / minimiert) und zwei Layout-Modi (Grid / Liste).

### Panel — Grundlayout
- **Zweck:** Container, in dem gesammelte Dateien liegen; jederzeit sichtbar, schwebt über dem Desktop.
- **Layout:** `display:flex; flex-direction:column`. Breite fix **500px**, Höhe wächst mit Inhalt (Body scrollt ab `max-height: 460px`).
- **Randradius:** 20px. **Schatten:** `0 24px 60px -12px rgba(0,0,0,.28), 0 2px 8px rgba(0,0,0,.08)`.
- **Hintergrund (Glas-Effekt):**
  - Außenrahmen/Kopfzeile: `rgba(246,246,248,0.72)` (Light) / `rgba(30,30,34,0.72)` (Dark), `backdrop-filter: blur(38px) saturate(1.6)`.
  - Body-Bereich (hinter den Datei-Icons) ist **weniger transparent** als die Kopfzeile: `rgba(246,246,248,0.9)` (Light) / `rgba(30,30,34,0.9)` (Dark) — bewusst dunkler/deckender, damit die Icons besser lesbar sind.
  - Rahmenlinie: `1px solid rgba(0,0,0,.08)` (Light) / `rgba(255,255,255,.08)` (Dark).
- **Schrift:** `-apple-system, BlinkMacSystemFont, "SF Pro Text", Helvetica, sans-serif` durchgängig.

### Kopfzeile (Header)
Höhe durch Padding `12px 16px`, unten `1px solid` Trennlinie zum Body. `justify-content: space-between`.

**Linker Cluster** (`display:flex; gap:7px`), von links nach rechts:
1. **Papierkorb-Icon** — Outline-Icon, 20×20 SVG-Box, Klick = alle Dateien löschen (Funktionsplatz).
2. **"Alle auswählen"-Icon** — Outline-Quadrat mit Häkchen, 20×20. Klick: markiert alle Dateien (Toggle — bei erneutem Klick wird die Auswahl aufgehoben, wenn bereits alle markiert sind).
3. **AirDrop-Icon** — drei konzentrische Ringe um Dreieck+Punkt (Signalwellen-Motiv), 20×20. Aktuell ohne Funktion (Platzhalter für spätere AirDrop-Freigabe).
4. **ZIP-Icon** — Dokument-Outline mit Reißverschluss-Motiv in der Mitte, 20×20. Aktuell ohne Funktion (Platzhalter: soll später alle gesammelten Dateien zu einer ZIP packen).
   - Diese vier Buttons sind optisch durch eine vertikale Trennlinie (`1px solid`, Divider-Farbe) vom Rest der Kopfzeile abgesetzt (`padding-right:10px; margin-right:2px; border-right`).
5. **Listen/Grid-Umschalter** — zeigt **das Icon der jeweils anderen Ansicht** (z. B. wenn Grid aktiv ist, wird das Listen-Icon angezeigt, da es das Wechsel-Ziel symbolisiert, und umgekehrt). Klick wechselt zwischen Grid- und Listenansicht der Dateien.
6. **Dark/Light-Umschalter** — Sonne-Icon im Dark Mode (wechselt zu Light), Mond-Icon im Light Mode (wechselt zu Dark). Klick schaltet das gesamte Panel zwischen Hell/Dunkel um.
7. **Zähler-Beschriftung** — Text rechts vom Dark/Light-Icon, Format: `"<Anzahl> Dateien · <Größe>"` (z. B. „14 Dateien · 62,1 MB"). Aktualisiert sich live, wenn Dateien entfernt werden. Größeneinheit wählt automatisch KB/MB/GB. Schriftgröße 11,5px, Gewicht 500, gedämpfte Textfarbe.

**Rechter Cluster** (`display:flex; gap:6px`):
1. **Minus/Plus-Button** — Minus-Icon im Normalzustand: Klick reduziert das Fenster auf nur die Kopfzeile (Body wird ausgeblendet). Zeigt dann ein Plus-Icon; erneuter Klick stellt das Fenster wieder komplett her.
2. **X-Button (Schließen)** — ganz rechts. Schließt die App (in der Demo ohne Funktion hinterlegt — nur Optik).

Alle Kopfzeilen-Buttons: 26–28px große, transparente Kreis/Rundflächen, Hover-Zustand hellt den Hintergrund leicht auf (`rgba(0,0,0,.06)` Light / `rgba(255,255,255,.1)` Dark) und färbt das Icon in die volle Textfarbe ein. Der Schließen-Button färbt sich beim Hover rot (`#d9362b` Light / `#ff8b82` Dark, Hintergrund `rgba(255,59,48,.12)` bzw. `rgba(255,90,90,.22)`).

### Datei-Bereich (Body) — Grid-Ansicht (Standard)
- Padding `20px 18px 22px`, `overflow-y:auto`, `max-height:460px`.
- Raster: **CSS Grid, 4 Spalten**, `gap:16px` — durchgängige Sammlung, **keine Bereichs-Trennlinien oder Abschnittsüberschriften**.
- Jede Kachel:
  - Quadratische Vorschau (`aspect-ratio:1/1`, `border-radius:8px`), Platzhalter-Füllung: diagonales Streifenmuster (`repeating-linear-gradient(135deg, … 0 6px, transparent 6px 12px)`) auf leicht transparentem Untergrund.
  - Kleine Dateityp-Kennung darunter (z. B. „PDF", „JPG"), 9px, fett, Monospace, gedämpfte Farbe — **kein Dateiname sichtbar**, außer im Hover.
  - **Hover:** zeigt eine Tooltip-Sprechblase mit vollem Dateinamen oberhalb der Kachel.
  - **Klick auf Kachel:** wählt die Datei aus (Mehrfachauswahl möglich, kein Modifier nötig) — sichtbar durch farbigen Rand (`1.5px solid`, Akzentfarbe) und leicht abgedunkelten Hintergrund.
  - **Rechtsklick:** öffnet Kontextmenü (siehe unten).
  - **Kleiner X-Button oben rechts an jeder Kachel** (halbtransparenter Kreis, 15px): entfernt genau diese eine Datei aus der Zwischenablage. Hover färbt ihn rot.

### Datei-Bereich — Listenansicht
- Gleiche Body-Logik, aber Zeilen statt Kacheln: `display:flex; flex-direction:column; gap:2px`.
- Jede Zeile: **kleiner X-Button links** (18px Kreis, entfernt die Datei einzeln) → dann kleine quadratische Vorschau (26px) → Dateiname (flex:1, ellipsis bei Überlänge) → Dateityp-Kennung rechtsbündig.
- Zeilen-Hover hellt den Hintergrund leicht auf; ausgewählte Zeilen bekommen einen dezenten Hintergrund.
- Klick/Rechtsklick verhalten sich wie in der Grid-Ansicht.

### Drag & Drop
- Beim Ziehen einer Datei über das Fenster (`dragenter`/`dragover`) erscheint eine gestrichelte Overlay-Fläche (Innenabstand 10px, Randradius wie Panel −6px) mit der Beschriftung **„Dateien hier ablegen"** in Akzentfarbe. Verschwindet bei `dragleave`/`drop`.

### Kontextmenü (Rechtsklick auf eine Datei)
Erscheint unten rechts im Panel als schwebende Karte (`border-radius:10px`, Schatten, Blur-Hintergrund), Einträge von oben nach unten:
1. **Bild sperren** — soll verhindern, dass die Datei versehentlich wieder aus der Zwischenablage gelöscht wird.
2. — Trennlinie —
3. **Löschen**
4. **Kopieren**
5. **Im Finder anzeigen**

Jeder Eintrag: 12,5px Text, Hover füllt die Zeile mit der Akzentfarbe und weißer Schrift. Klick außerhalb oder auf einen Eintrag schließt das Menü.

## Interactions & Behavior
- **Dark/Light:** Umschaltbarer Zustand, betrifft alle Farben (Hintergrund, Text, Icons, Kacheln) im gesamten Panel.
- **Grid ↔ Liste:** Umschaltbarer Zustand, ändert nur die Darstellung der bereits vorhandenen Dateien.
- **Mehrfachauswahl:** Jeder Klick auf eine Datei toggelt ihren ausgewählten Zustand (kein Zurücksetzen bei Klick auf eine andere Datei — echte additive Mehrfachauswahl).
- **"Alle auswählen"-Icon:** wählt alle sichtbaren Dateien aus; bei erneutem Klick (wenn bereits alle ausgewählt sind) hebt es die Auswahl komplett auf.
- **Einzel-Entfernen:** X-Button an jeder Kachel/Zeile entfernt nur diese eine Datei sofort (kein Bestätigungsdialog in der Demo — für die echte App ggf. ergänzen).
- **Minimieren/Maximieren:** Minus-Button blendet den kompletten Body aus, sodass nur die Kopfzeile übrig bleibt (Fenster schrumpft entsprechend in der Höhe); Plus-Button stellt ihn wieder her.
- **Kontextmenü:** öffnet sich an fester Position (unten rechts) bei Rechtsklick auf eine Datei; schließt bei Klick auf einen Eintrag oder außerhalb.
- **Drag & Drop:** nur visuelles Feedback in der Demo — reales Einlesen der gedroppten Dateien muss im Code ergänzt werden.
- **Papierkorb-, AirDrop- und ZIP-Icons:** in der Demo ohne Funktion hinterlegt (reine Platzhalter für spätere Features) — der Papierkorb ist als "alle Dateien löschen" gedacht, AirDrop für Freigabe, ZIP für Export als Archiv.

## State Management
Empfohlene lokale States für die Neuimplementierung:
- `isDarkMode: boolean`
- `viewMode: 'grid' | 'list'`
- `files: { id, name, ext, sizeMB, thumbnailURL? }[]`
- `selectedFileIds: Set<string>`
- `contextMenuTarget: string | null` (welche Datei, falls Menü offen)
- `isMinimized: boolean`
- `isDraggingOver: boolean` (für den Drop-Hinweis)
- Abgeleitet: `fileCount = files.length`, `totalSize = sum(files.sizeMB)` (formatiert als KB/MB/GB)

## Design Tokens

**Farben (Light-Modus, Variante 1a):**
- Panel-Hintergrund (Kopfzeile): `rgba(246,246,248,0.72)`
- Panel-Hintergrund (Body): `rgba(246,246,248,0.9)`
- Rahmen: `rgba(0,0,0,0.08)`
- Text (primär): `#1c1c1e`
- Text (gedämpft): `rgba(0,0,0,0.45)`
- Trennlinie: `rgba(0,0,0,0.09)`
- Kachel-Hintergrund: `rgba(255,255,255,0.55)`
- Akzentfarbe (Auswahl/Hover in Kontextmenü): `oklch(0.58 0.14 250)` (Blauton)
- Rot (Löschen/Schließen-Hover): `#d9362b`

**Farben (Dark-Modus):**
- Panel-Hintergrund (Kopfzeile): `rgba(30,30,34,0.72)`
- Panel-Hintergrund (Body): `rgba(30,30,34,0.9)`
- Text (primär): `rgba(255,255,255,0.92)`
- Text (gedämpft): `rgba(255,255,255,0.5)`
- Akzentfarbe: `oklch(0.72 0.14 250)`
- Rot (Hover): `#ff8b82`

**Typografie:** `-apple-system, BlinkMacSystemFont, "SF Pro Text", Helvetica, sans-serif`. Größen: Header-Icons in 26–28px-Buttons, Zähler-Text 11,5px/500, Tooltip 10,5px/500, Kontextmenü-Einträge 12,5px, Dateiname (Liste) 12,5px/500, Dateityp-Kennung 9–10px Monospace (`ui-monospace, Menlo, monospace`).

**Radien:** Panel 20px, Kacheln 11px, Vorschau-Quadrate 8px, Buttons 6–7px, Kontextmenü 10px.

**Schatten:** Panel `0 24px 60px -12px rgba(0,0,0,.28), 0 2px 8px rgba(0,0,0,.08)`. Kontextmenü `0 12px 32px rgba(0,0,0,.28)`.

**Raster:** 4 Spalten × 3 sichtbare Reihen (weitere Reihen scrollbar), `gap:16px`, Panel-Breite 500px.

## Assets
Keine echten Bilder/Icons von außen eingebunden — alle Icons sind handgezeichnete SVG-Outlines (Papierkorb, AirDrop, Auswählen, ZIP, Grid/Liste, Dark/Light, Minus/Plus, X). Datei-Vorschauen sind Platzhalter (CSS-Streifenmuster) und müssen durch echte Thumbnails/Dateityp-Icons ersetzt werden.

## Files
- `ClipboardPanel.dc.html` — die eigentliche Panel-Komponente mit gesamter Logik (Zustand, Interaktionen, Styling für alle 3 Stil-Varianten: vibrancy/solid/compact).
- `Mac Zwischenablage-App Layout.dc.html` — Übersichtsseite mit allen 3 Varianten nebeneinander; **Variante 1a** (Glas/Vibrancy) ist die hier dokumentierte, finale Richtung.

Hinweis: Diese `.dc.html`-Dateien öffnen sich direkt im Browser (React-basiertes internes Format) und zeigen live das Verhalten — am besten im Browser öffnen, um die Interaktionen (Hover, Klick, Rechtsklick, Drag&Drop) selbst auszuprobieren, bevor die native Umsetzung beginnt.
