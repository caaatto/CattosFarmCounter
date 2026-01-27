# FarmCounter

Ein WoW Classic Era Addon zum Tracken von gefarmten Items mit Echtzeit-Statistiken.

## Features

- **Tracking-Fenster**: Zeigt alle getrackten Items mit Live-Statistiken
  - Aktueller Inventar-Bestand
  - Gefarmt diese Session (+X)
  - Items pro Stunde
- **Minimap-Icon**: Praktisches Icon an der Minimap zum schnellen Zugriff
  - Left-Click: Tracking-Fenster ein-/ausblenden
  - Right-Click: Einstellungen öffnen
- **Item ID Anzeige**: Zeigt Item IDs in allen Tooltips an
- **Einfaches Hinzufügen**: Shift+Click auf Items in deinen Taschen
- **Session-Tracking**: Automatischer Start beim Login, manueller Reset möglich
- **Einstellungs-Panel**: Vollständiges Interface Options Panel

## Installation

1. Entpacke den Ordner in: `World of Warcraft\_classic_era_\Interface\AddOns\`
2. Stelle sicher dass der Ordner `FarmCounter` heißt
3. **(Optional)** Installiere LibDataBroker-1.1 und LibDBIcon-1.0 für Minimap-Icon Support
   - Viele Addons enthalten diese Libraries bereits
   - Funktioniert auch ohne diese Libraries, nur ohne Minimap-Icon
4. Starte WoW Classic Era
5. Aktiviere das Addon im Charakter-Auswahlbildschirm

## Benutzung

### Items Tracken

**Methode 1: Item ID eingeben** (Empfohlen)
```
/fc add <itemID>
```
Beispiel: `/fc add 13468` (Black Lotus)

**Methode 2: Shift+Click**
- Öffne deine Taschen
- Halte Shift gedrückt und klicke auf ein Item
- Das Item wird zum Tracking hinzugefügt

**Methode 3: Über Einstellungen**
- Das Einstellungs-Panel zeigt alle aktuell getrackten Items

**Item entfernen:**
```
/fc remove <itemID>
```
Beispiel: `/fc remove 13468`

### Befehle

```
/fc help             - Zeigt alle Befehle
/fc add <itemID>     - Item zum Tracking hinzufügen
/fc remove <itemID>  - Item aus Tracking entfernen
/fc show             - Zeigt das Tracking-Fenster
/fc hide             - Versteckt das Tracking-Fenster
/fc reset            - Setzt die Session-Statistiken zurück
/fc config           - Öffnet die Einstellungen
```

Aliase: `/farmcounter` = `/fc`

### Minimap-Icon

Ein praktisches Icon an der Minimap (wenn LibDBIcon installiert ist):

- **Left-Click**: Tracking-Fenster ein-/ausblenden
- **Right-Click**: Einstellungen öffnen
- **Tooltip**: Zeigt Version und Hilfe

Das Icon kann in den Einstellungen versteckt werden.

### Tracking-Fenster

Das Tracking-Fenster zeigt für jedes Item:
- **Icon und Name** in Qualitätsfarbe
- **Inventar**: Aktuelle Anzahl im Inventar (inkl. Bank)
- **Session**: Gefarmt seit Session-Start (+/- Anzahl) und Items/Stunde

**Fenster-Funktionen:**
- **Verschieben**: Ziehe die Titelleiste
- **Minimieren**: Klick auf [-] Button
- **Schließen**: Klick auf [X] Button
- **Item entfernen**: Klick auf [-] Button beim Item
- **Session Reset**: Klick auf "Reset Session" Button

### Einstellungen

Öffne mit `/fc config` oder über Interface Options → AddOns → FarmCounter:

- **Show Tracking Window**: Tracking-Fenster ein-/ausblenden
- **Lock Window Position**: Fenster-Position fixieren
- **Show Minimap Icon**: Minimap-Icon ein-/ausblenden
- **Tracked Items**: Liste aller getrackten Items
  - Remove: Item aus Tracking entfernen
- **Reset Session**: Session-Statistiken zurücksetzen
- **Remove All Items**: Alle Items aus Tracking entfernen

## Session-Tracking

### Was ist eine Session?

Eine Session startet:
- Beim Login/Reload (`/reload`)
- Bei manuellem Reset (`/fc reset` oder Button)

Die Session speichert:
- **Start-Anzahl**: Wie viele Items du beim Session-Start hattest
- **Start-Zeit**: Wann die Session gestartet wurde

### Berechnungen

- **Gefarmt**: `Aktuelle Anzahl - Start-Anzahl`
- **Items/Stunde**: `Gefarmt / Verstrichene Zeit in Stunden`

**Beispiel:**
```
Session Start: 10:00 Uhr, 20 Goldener Sansam
Aktuelle Zeit: 12:30 Uhr, 50 Goldener Sansam

Gefarmt: 50 - 20 = +30
Zeit: 2.5 Stunden
Items/h: 30 / 2.5 = 12.0/h
```

## Item IDs

Das Addon zeigt automatisch Item IDs in allen Item-Tooltips an:
- Fahre über ein Item
- Am Ende des Tooltips siehst du: "Item ID: 12345"
- Praktisch zum Nachschlagen oder für andere Addons

## Dateien

```
FarmCounter/
├── FarmCounter.toc    # Addon Metadaten
├── Core.lua           # Hauptlogik, Events, Tracking-System
├── UI.lua             # Tracking-Fenster GUI
├── Config.lua         # Einstellungs-Panel
├── Tooltip.lua        # Item ID Tooltip-Hook
├── Plan.md            # Entwicklungsplan
└── README.md          # Diese Datei
```

## Technische Details

### SavedVariables

Das Addon speichert Daten in `FarmCounterDB`:

```lua
FarmCounterDB = {
    trackedItems = {
        [itemID] = {
            startCount = number,    -- Anzahl beim Session-Start
            startTime = number,     -- GetTime() beim Start
            enabled = boolean       -- Tracking aktiv
        }
    },
    settings = {
        windowPosition = {x, y},    -- Fenster-Position
        windowVisible = boolean,    -- Fenster sichtbar
        windowLocked = boolean,     -- Position fixiert
        frameScale = number         -- Fenster-Skalierung
    },
    minimap = {
        hide = boolean              -- Minimap-Icon versteckt
        -- (Position wird automatisch von LibDBIcon gespeichert)
    }
}
```

### Events

- `ADDON_LOADED` - Addon-Initialization
- `PLAYER_LOGIN` - Session-Start, UI-Erstellung
- `BAG_UPDATE` - UI-Update bei Inventar-Änderungen

### APIs (Classic Era kompatibel)

- `GetItemCount(itemID, true)` - Item-Anzahl (inkl. Bank)
- `GetItemInfo(itemID)` - Item-Informationen
- `GetTime()` - Aktuelle Spielzeit für Berechnungen
- `GetContainerItemLink(bag, slot)` - Item-Link aus Tasche

## Tipps

1. **Item IDs finden**: Fahre über ein Item - das Addon zeigt die Item ID im Tooltip
2. **Mehrere Items tracken**: Du kannst beliebig viele Items gleichzeitig tracken
3. **Session Reset**: Nutze Reset wenn du eine neue Farm-Session startest
4. **Bank-Items**: Das Addon zählt auch Items in der Bank mit
5. **Negative Werte**: Wenn du Items verkaufst/benutzt, wird die Differenz negativ angezeigt
6. **Fenster-Position**: Das Addon merkt sich die Fenster-Position automatisch

### Beliebte Farm-Items (Classic Era)

```bash
/fc add 13468  # Black Lotus
/fc add 13467  # Icecap
/fc add 13465  # Mountain Silversage
/fc add 13466  # Plaguebloom
/fc add 13463  # Dreamfoil
/fc add 12808  # Essence of Undeath
/fc add 12803  # Living Essence
/fc add 7076   # Essence of Earth
/fc add 7080   # Essence of Water
/fc add 7082   # Essence of Air
/fc add 7078   # Essence of Fire
/fc add 12364  # Huge Emerald
/fc add 12361  # Blue Sapphire
/fc add 12799  # Large Opal
/fc add 12800  # Azerothian Diamond
```

## Support

- Version: 0.1.0
- Autor: Catto
- Kompatibel mit: WoW Classic Era (1.14.x)
- Interface Version: 11404
- Optional: LibDataBroker-1.1, LibDBIcon-1.0 (für Minimap-Icon)

## Bekannte Einschränkungen

- Items müssen im Cache sein (einmal angesehen worden sein)
- Bank-Items werden nur gezählt wenn Bank offen war
- Items in der Post werden nicht gezählt

## Credits

Entwickelt für WoW Classic Era mit Liebe zum Detail.
