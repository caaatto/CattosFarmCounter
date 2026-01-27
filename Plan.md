# FarmCounter Addon - Entwicklungsplan

## Übersicht
Ein WoW Classic Addon zum Tracken von gefarmten Items mit Live-Statistiken.

## Kernfunktionen

### 1. Haupt-Tracking-Fenster
- **Kleines, bewegbares Fenster** das immer sichtbar ist
- **Anzeige pro getracktem Item:**
  - Item Icon
  - Item Name
  - Aktuelle Anzahl im Inventar
  - Session-Farmed (seit Login/Reset)
  - Items pro Stunde
- **Features:**
  - Drag & Drop zum Verschieben
  - Minimierbar/Versteckbar
  - Scrollbar bei vielen Items

### 2. Item-Tracking System
- **Hinzufügen von Items:**
  - Shift+Click auf Item im Bag zum Tracken
  - Oder über Einstellungspanel
- **Entfernen von Items:**
  - Button im Tracking-Fenster
  - Über Einstellungspanel
- **Automatische Zählung:**
  - BAG_UPDATE Event listener
  - Zählt alle Items über alle Bags

### 3. Session-Tracking
- **Start der Session:**
  - Beim Login/Reload
  - Manueller Reset-Button
- **Berechnungen:**
  - Delta = Aktuelle Menge - Start Menge
  - Items/Stunde = Delta / Verstrichene Zeit
- **Anzeige:**
  - Farmed dieses Session (+X)
  - X/Stunde

### 4. Tooltip-Erweiterung
- **Item ID Anzeige:**
  - In allen Item-Tooltips
  - Format: "Item ID: 12345"
  - Unaufdringlich am Ende des Tooltips

### 5. Einstellungen/Optionen
- **Interface Options Integration:**
  - Addon-Panel in Interface Options
- **Einstellungen:**
  - Hauptfenster zeigen/verstecken
  - Fenster-Lock (Position fixieren)
  - Session Reset Button
  - Liste aller getrackten Items mit Remove-Buttons
- **SavedVariables:**
  - Fenster-Position
  - Getrackte Items
  - Einstellungen

## Dateistruktur

```
FarmCounter/
├── FarmCounter.toc          # Addon Metadaten
├── Core.lua                 # Hauptlogik, Initialization, Events
├── UI.lua                   # Tracking-Fenster GUI
├── Config.lua               # Einstellungs-Panel
├── Tooltip.lua              # Item ID Tooltip Hook
└── Plan.md                  # Dieser Plan
```

## Implementierungsschritte

### Phase 1: Grundgerüst
1. TOC-Datei erstellen
2. Core.lua mit Addon-Initialization
3. SavedVariables Setup

### Phase 2: Item Tracking Backend
1. Item-Zählung im Inventar (GetItemCount)
2. BAG_UPDATE Event Handler
3. Datenstruktur für getrackte Items
4. Session-Tracking Logik

### Phase 3: UI - Tracking-Fenster
1. Frame erstellen (bewegbar)
2. Item-Liste anzeigen
3. Icons und Text formatieren
4. Update-Funktion für Live-Daten

### Phase 4: Item Hinzufügen/Entfernen
1. Shift+Click Handler für Bags
2. Add/Remove Funktionen
3. UI-Buttons

### Phase 5: Tooltip Integration
1. GameTooltip Hook
2. Item ID anzeigen

### Phase 6: Config Panel
1. Interface Options Panel
2. Einstellungen UI
3. Tracked Items Liste mit Remove

### Phase 7: Polish
1. Fehlerbehandlung
2. Performance-Optimierung
3. UI-Verfeinerungen

## Technische Details

### Events
- `ADDON_LOADED` - Initialization
- `PLAYER_LOGIN` - Session Start
- `BAG_UPDATE` - Item Count Update
- `MODIFIER_STATE_CHANGED` - Shift-Click Detection

### APIs
- `GetItemCount(itemID)` - Item-Anzahl
- `GetItemInfo(itemID)` - Item-Infos
- `GetItemIcon(itemID)` - Item-Icon
- `GetTime()` - Zeit für Items/Stunde
- `CreateFrame()` - UI-Erstellung

### SavedVariables
```lua
FarmCounterDB = {
    trackedItems = {
        [itemID] = {
            startCount = number,
            startTime = number,
            enabled = boolean
        }
    },
    settings = {
        windowPosition = {x, y},
        windowVisible = boolean,
        windowLocked = boolean
    }
}
```

## UI-Mockup (Text)

```
╔═══════════════════════════════════╗
║ FarmCounter              [_][X]   ║
╠═══════════════════════════════════╣
║ [icon] Goldener Sansam            ║
║        Inventar: 47               ║
║        Session: +12 (24/h)        ║
║                              [X]  ║
╟───────────────────────────────────╢
║ [icon] Schwarzer Lotus            ║
║        Inventar: 3                ║
║        Session: +1 (2/h)          ║
║                              [X]  ║
╟───────────────────────────────────╢
║              [Reset Session]      ║
╚═══════════════════════════════════╝
```

## Priorität
1. Core-Funktionalität (Tracking Backend)
2. Basis-UI (Anzeige)
3. Item hinzufügen (Shift+Click)
4. Tooltip Item ID
5. Config Panel
6. UI-Verfeinerungen
