-- FarmCounter Core
FarmCounter = {}
FarmCounter.version = "0.1.0"

-- Local references for performance
local _G = _G
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetTime = GetTime

-- Default database structure
local defaults = {
    trackedItems = {},
    settings = {
        windowPosition = {x = 0, y = -200},
        windowVisible = true,
        windowLocked = false,
        frameScale = 1.0
    },
    minimap = {
        hide = false
    },
    focus = {
        itemID = nil,
        goal = 100,
        mode = "session",  -- "session" (farmed since session) or "total" (total bags+bank)
        barPosition = {x = 0, y = -150},
        barVisible = true,
        barLocked = false
    },
    bankCache = {}  -- Cache for bank item counts
}

-- Initialize the addon
function FarmCounter:Initialize()
    -- Initialize SavedVariables
    if not FarmCounterDB then
        FarmCounterDB = {}
    end

    -- Merge defaults
    if not FarmCounterDB.trackedItems then
        FarmCounterDB.trackedItems = {}
    end
    if not FarmCounterDB.settings then
        FarmCounterDB.settings = defaults.settings
    end
    if not FarmCounterDB.minimap then
        FarmCounterDB.minimap = defaults.minimap
    end
    if not FarmCounterDB.focus then
        FarmCounterDB.focus = defaults.focus
    end
    if not FarmCounterDB.focus.mode then
        FarmCounterDB.focus.mode = "session"
    end
    if not FarmCounterDB.bankCache then
        FarmCounterDB.bankCache = {}
    end

    self.db = FarmCounterDB

    print("|cff00ff00FarmCounter|r v" .. self.version .. " loaded. Type /farmcounter or /fc for help.")

    -- Initialize minimap icon
    self:InitializeMinimapIcon()
end

-- Initialize minimap icon using LibDBIcon
function FarmCounter:InitializeMinimapIcon()
    -- Check if LibStub and required libraries are available
    if not LibStub then return end

    local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)

    if not LibDataBroker or not LibDBIcon then
        -- Libraries not available, silently continue without minimap icon
        return
    end

    -- Create LibDataBroker object
    local FarmCounterLDB = LibDataBroker:NewDataObject("FarmCounter", {
        type = "data source",
        text = "FarmCounter",
        icon = "Interface\\Icons\\INV_Misc_Bag_10_Green",
        OnClick = function(_, button)
            if button == "LeftButton" then
                -- Toggle main window
                if FarmCounter.db.settings.windowVisible then
                    FarmCounter.db.settings.windowVisible = false
                    if FarmCounterUI and FarmCounterUI.frame then
                        FarmCounterUI.frame:Hide()
                    end
                else
                    FarmCounter.db.settings.windowVisible = true
                    if FarmCounterUI and FarmCounterUI.frame then
                        FarmCounterUI.frame:Show()
                    end
                end
            elseif button == "RightButton" then
                -- Open config
                if FarmCounterConfig and FarmCounterConfig.OpenConfig then
                    FarmCounterConfig:OpenConfig()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:SetText("|cff00ff00FarmCounter|r")
            tooltip:AddLine("v" .. FarmCounter.version, 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffffffffLeft-Click:|r Toggle window")
            tooltip:AddLine("|cffffffffRight-Click:|r Open config")
            tooltip:AddLine("|cffffffffShift-Click:|r Track items in bags")
        end,
    })

    -- Register with LibDBIcon
    LibDBIcon:Register("FarmCounter", FarmCounterLDB, self.db.minimap)

    self.minimapIcon = LibDBIcon
end

-- Toggle minimap icon visibility
function FarmCounter:ToggleMinimapIcon()
    if not self.minimapIcon then return end

    if self.db.minimap.hide then
        self.minimapIcon:Show("FarmCounter")
        self.db.minimap.hide = false
    else
        self.minimapIcon:Hide("FarmCounter")
        self.db.minimap.hide = true
    end
end

-- Start a new session (called on login or manual reset)
function FarmCounter:StartSession()
    local currentTime = GetTime()

    for itemID, data in pairs(self.db.trackedItems) do
        local count = GetItemCount(itemID, true) -- true = include bank
        data.startCount = count
        data.startTime = currentTime
    end

    print("|cff00ff00FarmCounter:|r Session started/reset.")

    if FarmCounterUI and FarmCounterUI.UpdateDisplay then
        FarmCounterUI:UpdateDisplay()
    end
end

-- Add an item to tracking
function FarmCounter:AddItem(itemID)
    if not itemID or itemID == 0 then
        print("|cffff0000FarmCounter:|r Invalid item ID.")
        return false
    end

    -- Check if already tracked
    if self.db.trackedItems[itemID] then
        print("|cffff0000FarmCounter:|r Item is already being tracked.")
        return false
    end

    -- Get item info to verify it exists
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)

    if not itemName then
        print("|cffff0000FarmCounter:|r Could not find item information.")
        return false
    end

    -- Add to tracking
    local currentTime = GetTime()
    local totalCount = GetItemCount(itemID, true)  -- Total (bags + bank)
    local bagsCount = GetItemCount(itemID, false)  -- Bags only
    local bankCount = totalCount - bagsCount  -- Bank = Total - Bags

    self.db.trackedItems[itemID] = {
        startCount = totalCount,
        startTime = currentTime,
        enabled = true
    }

    -- Initialize bank cache for this item
    self.db.bankCache[itemID] = bankCount

    print("|cff00ff00FarmCounter:|r Now tracking " .. itemLink)

    if FarmCounterUI and FarmCounterUI.UpdateDisplay then
        FarmCounterUI:UpdateDisplay()
    end

    return true
end

-- Remove an item from tracking
function FarmCounter:RemoveItem(itemID)
    if not itemID then return false end

    if self.db.trackedItems[itemID] then
        local itemName, itemLink = GetItemInfo(itemID)
        self.db.trackedItems[itemID] = nil

        -- Remove from bank cache as well
        self.db.bankCache[itemID] = nil

        print("|cff00ff00FarmCounter:|r Stopped tracking " .. (itemLink or "item"))

        -- Unfocus if this was the focused item
        if self.db.focus.itemID == itemID then
            self:UnfocusItem()
        end

        if FarmCounterUI and FarmCounterUI.UpdateDisplay then
            FarmCounterUI:UpdateDisplay()
        end

        return true
    end

    return false
end

-- Focus an item (show in focus bar)
function FarmCounter:FocusItem(itemID, goal, mode)
    if not itemID then return false end

    -- Check if item is tracked
    if not self.db.trackedItems[itemID] then
        print("|cffff0000FarmCounter:|r Item must be tracked before focusing.")
        return false
    end

    local itemName, itemLink = GetItemInfo(itemID)
    if not itemName then
        print("|cffff0000FarmCounter:|r Could not find item information.")
        return false
    end

    -- Set focus
    self.db.focus.itemID = itemID
    self.db.focus.goal = goal or self.db.focus.goal or 100
    self.db.focus.mode = mode or self.db.focus.mode or "session"
    self.db.focus.barVisible = true

    local modeText = (self.db.focus.mode == "total") and "Free Farm" or "Session"
    print("|cff00ff00FarmCounter:|r Focused " .. itemLink .. " (Goal: " .. self.db.focus.goal .. ", Mode: " .. modeText .. ")")

    -- Update focus bar
    if FarmCounterFocusBar and FarmCounterFocusBar.Update then
        FarmCounterFocusBar:Update()
        if FarmCounterFocusBar.frame then
            FarmCounterFocusBar.frame:Show()
        end
    end

    -- Update main UI
    if FarmCounterUI and FarmCounterUI.UpdateDisplay then
        FarmCounterUI:UpdateDisplay()
    end

    return true
end

-- Unfocus the current item
function FarmCounter:UnfocusItem()
    if not self.db.focus.itemID then return false end

    local itemName, itemLink = GetItemInfo(self.db.focus.itemID)
    self.db.focus.itemID = nil

    print("|cff00ff00FarmCounter:|r Unfocused " .. (itemLink or "item"))

    -- Hide focus bar
    if FarmCounterFocusBar and FarmCounterFocusBar.frame then
        FarmCounterFocusBar.frame:Hide()
    end

    -- Update main UI
    if FarmCounterUI and FarmCounterUI.UpdateDisplay then
        FarmCounterUI:UpdateDisplay()
    end

    return true
end

-- Get focused item ID
function FarmCounter:GetFocusedItem()
    return self.db.focus.itemID
end

-- Set goal for focused item
function FarmCounter:SetFocusGoal(goal)
    if not self.db.focus.itemID then
        print("|cffff0000FarmCounter:|r No item is currently focused.")
        return false
    end

    goal = tonumber(goal)
    if not goal or goal <= 0 then
        print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
        return false
    end

    self.db.focus.goal = goal
    print("|cff00ff00FarmCounter:|r Goal set to " .. goal)

    -- Update focus bar
    if FarmCounterFocusBar and FarmCounterFocusBar.Update then
        FarmCounterFocusBar:Update()
    end

    return true
end

-- Update bank counts for tracked items (called when bank is opened)
function FarmCounter:UpdateBankCache()
    for itemID, _ in pairs(self.db.trackedItems) do
        local totalCount = GetItemCount(itemID, true)  -- Total (bags + bank)
        local bagsCount = GetItemCount(itemID, false)  -- Bags only
        local bankCount = totalCount - bagsCount  -- Bank = Total - Bags

        self.db.bankCache[itemID] = bankCount
    end

    -- Update UI if visible
    if FarmCounterUI and FarmCounterUI.UpdateDisplay then
        FarmCounterUI:UpdateDisplay()
    end
end

-- Get statistics for an item
function FarmCounter:GetItemStats(itemID)
    local data = self.db.trackedItems[itemID]
    if not data then return nil end

    local totalCount = GetItemCount(itemID, true)  -- Total (bags + bank)
    local bagsCount = GetItemCount(itemID, false)  -- Bags only
    local bankCount = self.db.bankCache[itemID] or 0  -- Use cached bank count
    local currentTime = GetTime()

    local farmed = totalCount - data.startCount
    local elapsedSeconds = currentTime - data.startTime
    local elapsedHours = elapsedSeconds / 3600

    local perHour = 0
    if elapsedHours > 0 then
        perHour = farmed / elapsedHours
    end

    return {
        currentCount = totalCount,
        bagsCount = bagsCount,
        bankCount = bankCount,
        farmed = farmed,
        perHour = perHour,
        elapsedSeconds = elapsedSeconds
    }
end

-- Get all tracked items sorted
function FarmCounter:GetTrackedItems()
    local items = {}

    for itemID, data in pairs(self.db.trackedItems) do
        if data.enabled then
            table.insert(items, itemID)
        end
    end

    -- Sort by item name
    table.sort(items, function(a, b)
        local nameA = GetItemInfo(a)
        local nameB = GetItemInfo(b)
        if nameA and nameB then
            return nameA < nameB
        end
        return a < b
    end)

    return items
end

-- Slash command handler
local function SlashCommandHandler(msg)
    msg = msg:trim()
    local command, args = msg:match("^(%S+)%s*(.*)$")

    if not command then
        command = msg
        args = ""
    end

    command = command:lower()

    if command == "show" then
        FarmCounter.db.settings.windowVisible = true
        if FarmCounterUI and FarmCounterUI.frame then
            FarmCounterUI.frame:Show()
        end
        print("|cff00ff00FarmCounter:|r Window shown.")
    elseif command == "hide" then
        FarmCounter.db.settings.windowVisible = false
        if FarmCounterUI and FarmCounterUI.frame then
            FarmCounterUI.frame:Hide()
        end
        print("|cff00ff00FarmCounter:|r Window hidden.")
    elseif command == "add" then
        local itemID = tonumber(args)
        if itemID then
            FarmCounter:AddItem(itemID)
        else
            print("|cffff0000FarmCounter:|r Usage: /fc add <itemID>")
            print("|cffaaaaaa  Example: /fc add 13468 (Black Lotus)|r")
        end
    elseif command == "remove" or command == "delete" then
        local itemID = tonumber(args)
        if itemID then
            FarmCounter:RemoveItem(itemID)
        else
            print("|cffff0000FarmCounter:|r Usage: /fc remove <itemID>")
            print("|cffaaaaaa  Example: /fc remove 13468|r")
        end
    elseif command == "reset" or command == "session" then
        FarmCounter:StartSession()
    elseif command == "config" or command == "options" then
        if FarmCounterConfig and FarmCounterConfig.OpenConfig then
            FarmCounterConfig:OpenConfig()
        end
    elseif command == "" or command == "help" then
        print("|cff00ff00FarmCounter Commands:|r")
        print("  /fc show - Show tracking window")
        print("  /fc hide - Hide tracking window")
        print("  /fc add <itemID> - Add item to tracking by ID")
        print("  /fc remove <itemID> - Remove item from tracking")
        print("  /fc reset - Reset session statistics")
        print("  /fc config - Open configuration")
        print("  Shift+Click on an item in your bags to track it")
    else
        print("|cffff0000FarmCounter:|r Unknown command. Type /fc help for commands.")
    end
end

SLASH_FARMCOUNTER1 = "/farmcounter"
SLASH_FARMCOUNTER2 = "/fc"
SlashCmdList["FARMCOUNTER"] = SlashCommandHandler

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("BANKFRAME_CLOSED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "FarmCounter" then
            FarmCounter:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        FarmCounter:StartSession()
        -- Hook bag buttons for Shift+Click
        FarmCounter:HookBagButtons()
    elseif event == "BAG_UPDATE" then
        -- Update UI when bags change
        if FarmCounterUI and FarmCounterUI.UpdateDisplay then
            FarmCounterUI:UpdateDisplay()
        end
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BANKFRAME_OPENED" then
        -- Update bank cache when bank contents change or bank is opened
        FarmCounter:UpdateBankCache()
    elseif event == "BANKFRAME_CLOSED" then
        -- Update UI when bank is closed (to ensure display is current)
        if FarmCounterUI and FarmCounterUI.UpdateDisplay then
            FarmCounterUI:UpdateDisplay()
        end
    end
end)

-- Hook bag item buttons for Shift+Click tracking
function FarmCounter:HookBagButtons()
    -- Hook the original function that handles item clicks
    local function HookItemButton(button)
        if not button or button.fcHooked then return end

        button:HookScript("OnClick", function(self, mouseButton)
            if mouseButton == "LeftButton" and IsShiftKeyDown() then
                local bag = self:GetParent():GetID()
                local slot = self:GetID()

                -- Get item link from the bag slot
                local itemLink = GetContainerItemLink(bag, slot)

                if itemLink then
                    -- Extract item ID
                    local itemID = tonumber(itemLink:match("item:(%d+)"))

                    if itemID then
                        FarmCounter:AddItem(itemID)
                    end
                end
            end
        end)

        button.fcHooked = true
    end

    -- Hook all container frame buttons (bags 0-4, plus bank bags)
    for bagID = 0, 4 do
        local bagName = "ContainerFrame" .. (bagID + 1)
        local bagFrame = _G[bagName]

        if bagFrame then
            for slotID = 1, 36 do
                local buttonName = bagName .. "Item" .. slotID
                local button = _G[buttonName]

                if button then
                    HookItemButton(button)
                end
            end
        end
    end

    -- Also hook bank bags (bag IDs 5-11 in Classic)
    for bagID = 5, 11 do
        local bagName = "ContainerFrame" .. (bagID + 1)
        local bagFrame = _G[bagName]

        if bagFrame then
            for slotID = 1, 36 do
                local buttonName = bagName .. "Item" .. slotID
                local button = _G[buttonName]

                if button then
                    HookItemButton(button)
                end
            end
        end
    end
end
