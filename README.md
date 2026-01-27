# FarmCounter

A WoW Classic Era addon for tracking farmed items with real-time statistics.

## Features

- **Tracking Window**: Shows all tracked items with live statistics
  - Current inventory count
  - Farmed this session (+X)
  - Items per hour
- **Focus Bar**: WeakAura-style progress bar for focused items
  - Set farming goals
  - Visual progress indicator
  - Items/hour tracking
- **Minimap Icon**: Quick access icon on minimap
  - Left-Click: Toggle tracking window
  - Right-Click: Open settings
- **Item ID Display**: Shows Item IDs in all tooltips
- **Easy Adding**: Shift+Click items in your bags or use manual ID input
- **Session Tracking**: Automatic start on login, manual reset available
- **Settings Panel**: Full Interface Options integration

## Installation

1. Extract the folder to: `World of Warcraft\_classic_era_\Interface\AddOns\`
2. Make sure the folder is named `FarmCounter`
3. **(Optional)** Install LibDataBroker-1.1 and LibDBIcon-1.0 for Minimap icon support
   - Many addons already include these libraries
   - Works without these libraries, just without minimap icon
4. Start WoW Classic Era
5. Enable the addon in the character selection screen

## Usage

### Tracking Items

**Method 1: Enter Item ID** (Recommended)
```
/fc add <itemID>
```
Example: `/fc add 13468` (Black Lotus)

**Method 2: Shift+Click**
- Open your bags
- Hold Shift and click on an item
- The item will be added to tracking

**Method 3: Via Settings**
- The settings panel shows all currently tracked items

**Remove item:**
```
/fc remove <itemID>
```
Example: `/fc remove 13468`

### Commands

```
/fc help             - Show all commands
/fc add <itemID>     - Add item to tracking
/fc remove <itemID>  - Remove item from tracking
/fc show             - Show tracking window
/fc hide             - Hide tracking window
/fc reset            - Reset session statistics
/fc config           - Open settings
```

Aliases: `/farmcounter` = `/fc`

### Focus Bar

The Focus Bar allows you to focus on a specific item and track progress towards a goal:

**Focusing an item:**
1. Open FarmCounter (`/fc show`)
2. Click the icon button next to an item
3. Set your goal (e.g. 100)
4. Progress bar appears

**Change goal:**
- **Right-Click** on the Focus Bar
- Enter new goal

**Unfocus item:**
- Click **X** on the Focus Bar
- Or click the icon button again on the item

**Move the bar:**
- Simply **Drag & Drop**
- In Config: Enable "Lock Focus Bar Position"

### Minimap Icon

A convenient icon on the minimap (if LibDBIcon is installed):

- **Left-Click**: Toggle tracking window
- **Right-Click**: Open settings
- **Tooltip**: Shows version and help

The icon can be hidden in settings.

### Tracking Window

The tracking window shows for each item:
- **Icon and Name** in quality color
- **Inventory**: Current count in inventory (including bank)
- **Session**: Farmed since session start (+/- amount) and items/hour

**Window Functions:**
- **Move**: Drag the title bar
- **Close**: Click [X] button
- **Remove item**: Click [-] button next to item
- **Focus item**: Click icon button next to item
- **Add item**: Click "Add Item" button
- **Session Reset**: Click "Reset Session" button

### Settings

Open with `/fc config` or via Interface Options → AddOns → FarmCounter:

- **Show Tracking Window**: Toggle tracking window
- **Lock Window Position**: Lock window position
- **Show Minimap Icon**: Toggle minimap icon
- **Show Focus Bar**: Toggle focus bar visibility
- **Lock Focus Bar Position**: Lock focus bar position
- **Add Item by ID**: Input field to add items
- **Tracked Items**: List of all tracked items
  - Remove: Remove item from tracking
- **Reset Session**: Reset session statistics
- **Remove All Items**: Remove all items from tracking

## Session Tracking

### What is a Session?

A session starts:
- On login/reload (`/reload`)
- On manual reset (`/fc reset` or button)

The session saves:
- **Start Count**: How many items you had at session start
- **Start Time**: When the session started

### Calculations

- **Farmed**: `Current Count - Start Count`
- **Items/Hour**: `Farmed / Elapsed Time in Hours`

**Example:**
```
Session Start: 10:00 AM, 20 Golden Sansam
Current Time: 12:30 PM, 50 Golden Sansam

Farmed: 50 - 20 = +30
Time: 2.5 hours
Items/h: 30 / 2.5 = 12.0/h
```

## Item IDs

The addon automatically shows Item IDs in all item tooltips:
- Hover over an item
- At the end of the tooltip you'll see: "Item ID: 12345"
- Useful for lookup or for other addons

## Files

```
FarmCounter/
├── FarmCounter.toc    # Addon metadata
├── Core.lua           # Main logic, events, tracking system
├── UI.lua             # Tracking window GUI
├── FocusBar.lua       # Focus bar GUI
├── Config.lua         # Settings panel
├── Tooltip.lua        # Item ID tooltip hook
├── Plan.md            # Development plan
└── README.md          # This file
```

## Technical Details

### SavedVariables

The addon saves data in `FarmCounterDB`:

```lua
FarmCounterDB = {
    trackedItems = {
        [itemID] = {
            startCount = number,    -- Count at session start
            startTime = number,     -- GetTime() at start
            enabled = boolean       -- Tracking active
        }
    },
    settings = {
        windowPosition = {x, y},    -- Window position
        windowVisible = boolean,    -- Window visible
        windowLocked = boolean,     -- Position locked
        frameScale = number         -- Window scale
    },
    minimap = {
        hide = boolean              -- Minimap icon hidden
        -- (Position automatically saved by LibDBIcon)
    },
    focus = {
        itemID = nil,               -- Currently focused item
        goal = 100,                 -- Goal for focused item
        barPosition = {x, y},       -- Focus bar position
        barVisible = true,          -- Focus bar visible
        barLocked = false          -- Focus bar locked
    }
}
```

### Events

- `ADDON_LOADED` - Addon initialization
- `PLAYER_LOGIN` - Session start, UI creation
- `BAG_UPDATE` - UI update on inventory changes

### APIs (Classic Era compatible)

- `GetItemCount(itemID, true)` - Item count (including bank)
- `GetItemInfo(itemID)` - Item information
- `GetTime()` - Current game time for calculations
- `GetContainerItemLink(bag, slot)` - Item link from bag

## Tips

1. **Find Item IDs**: Hover over an item - the addon shows the Item ID in the tooltip
2. **Track Multiple Items**: You can track as many items as you want simultaneously
3. **Session Reset**: Use reset when starting a new farm session
4. **Bank Items**: The addon counts items in the bank too
5. **Negative Values**: If you sell/use items, the difference will show as negative
6. **Window Position**: The addon automatically remembers the window position

### Popular Farm Items (Classic Era)

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
- Author: Catto
- Compatible with: WoW Classic Era (1.14.x)
- Interface Version: 11404
- Optional: LibDataBroker-1.1, LibDBIcon-1.0 (for Minimap icon)

## Known Limitations

- Items must be in cache (viewed at least once)
- Bank items only counted when bank is open
- Mail items are not counted

## Credits

Developed for WoW Classic Era with attention to detail.
