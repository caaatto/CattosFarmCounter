-- FarmCounter Configuration Module
FarmCounterConfig = {}

local ROW_HEIGHT = 30
local MAX_VISIBLE_ITEMS = 10

-- Create the config panel
function FarmCounterConfig:CreateConfigPanel()
    -- Main config frame
    local panel = CreateFrame("Frame", "FarmCounterConfigPanel", UIParent)
    panel.name = "FarmCounter"
    panel:Hide()

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ff00FarmCounter|r Configuration")

    -- Version
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("Version " .. FarmCounter.version)

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(600)
    desc:SetJustifyH("LEFT")
    desc:SetText("Track farmed items with real-time statistics. Shift+Click items in your bags to start tracking them.")

    -- Window Settings Section
    local windowHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    windowHeader:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    windowHeader:SetText("|cffffd700Window Settings|r")

    -- Show Window checkbox
    local showWindowCheck = CreateFrame("CheckButton", "FarmCounterShowWindowCheck", panel, "UICheckButtonTemplate")
    showWindowCheck:SetPoint("TOPLEFT", windowHeader, "BOTTOMLEFT", 0, -8)
    _G[showWindowCheck:GetName() .. "Text"]:SetText("Show Tracking Window")
    showWindowCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        FarmCounter.db.settings.windowVisible = checked

        if FarmCounterUI and FarmCounterUI.frame then
            if checked then
                FarmCounterUI.frame:Show()
            else
                FarmCounterUI.frame:Hide()
            end
        end
    end)

    -- Lock Window checkbox
    local lockWindowCheck = CreateFrame("CheckButton", "FarmCounterLockWindowCheck", panel, "UICheckButtonTemplate")
    lockWindowCheck:SetPoint("TOPLEFT", showWindowCheck, "BOTTOMLEFT", 0, -4)
    _G[lockWindowCheck:GetName() .. "Text"]:SetText("Lock Window Position")
    lockWindowCheck:SetScript("OnClick", function(self)
        FarmCounter.db.settings.windowLocked = self:GetChecked()
    end)

    -- Show Minimap Icon checkbox
    local showMinimapCheck = CreateFrame("CheckButton", "FarmCounterShowMinimapCheck", panel, "UICheckButtonTemplate")
    showMinimapCheck:SetPoint("TOPLEFT", lockWindowCheck, "BOTTOMLEFT", 0, -4)
    _G[showMinimapCheck:GetName() .. "Text"]:SetText("Show Minimap Icon")
    showMinimapCheck:SetScript("OnClick", function(self)
        FarmCounter:ToggleMinimapIcon()
    end)

    -- Focus Bar Section Header
    local focusBarHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    focusBarHeader:SetPoint("TOPLEFT", showMinimapCheck, "BOTTOMLEFT", 0, -16)
    focusBarHeader:SetText("|cffffd700Focus Bar Settings|r")

    -- Show Focus Bar checkbox
    local showFocusBarCheck = CreateFrame("CheckButton", "FarmCounterShowFocusBarCheck", panel, "UICheckButtonTemplate")
    showFocusBarCheck:SetPoint("TOPLEFT", focusBarHeader, "BOTTOMLEFT", 0, -4)
    _G[showFocusBarCheck:GetName() .. "Text"]:SetText("Show Focus Bar")
    showFocusBarCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        FarmCounter.db.focus.barVisible = checked

        if FarmCounterFocusBar and FarmCounterFocusBar.frame then
            if checked and FarmCounter.db.focus.itemID then
                FarmCounterFocusBar.frame:Show()
                FarmCounterFocusBar:Update()
            else
                FarmCounterFocusBar.frame:Hide()
            end
        end
    end)

    -- Lock Focus Bar checkbox
    local lockFocusBarCheck = CreateFrame("CheckButton", "FarmCounterLockFocusBarCheck", panel, "UICheckButtonTemplate")
    lockFocusBarCheck:SetPoint("TOPLEFT", showFocusBarCheck, "BOTTOMLEFT", 0, -4)
    _G[lockFocusBarCheck:GetName() .. "Text"]:SetText("Lock Focus Bar Position")
    lockFocusBarCheck:SetScript("OnClick", function(self)
        FarmCounter.db.focus.barLocked = self:GetChecked()
    end)

    -- Add Item Section
    local addItemHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    addItemHeader:SetPoint("TOPLEFT", lockFocusBarCheck, "BOTTOMLEFT", 0, -20)
    addItemHeader:SetText("|cffffd700Add Item by ID|r")

    -- Item ID input label
    local addItemLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    addItemLabel:SetPoint("TOPLEFT", addItemHeader, "BOTTOMLEFT", 0, -8)
    addItemLabel:SetText("Item ID:")

    -- Item ID input box
    local addItemEditBox = CreateFrame("EditBox", "FarmCounterAddItemEditBox", panel, "InputBoxTemplate")
    addItemEditBox:SetSize(100, 20)
    addItemEditBox:SetPoint("LEFT", addItemLabel, "RIGHT", 10, 0)
    addItemEditBox:SetAutoFocus(false)
    addItemEditBox:SetMaxLetters(8)
    addItemEditBox:SetNumeric(true)
    addItemEditBox:SetScript("OnEnterPressed", function(self)
        local itemID = tonumber(self:GetText())
        if itemID then
            FarmCounter:AddItem(itemID)
            self:SetText("")
            self:ClearFocus()
        else
            print("|cffff0000FarmCounter:|r Invalid Item ID. Please enter a number.")
        end
    end)
    addItemEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Add button
    local addItemButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addItemButton:SetSize(80, 22)
    addItemButton:SetPoint("LEFT", addItemEditBox, "RIGHT", 10, 0)
    addItemButton:SetText("Add Item")
    addItemButton:SetScript("OnClick", function()
        local itemID = tonumber(addItemEditBox:GetText())
        if itemID then
            FarmCounter:AddItem(itemID)
            addItemEditBox:SetText("")
            addItemEditBox:ClearFocus()
        else
            print("|cffff0000FarmCounter:|r Invalid Item ID. Please enter a number.")
        end
    end)

    -- Help text
    local addItemHelp = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    addItemHelp:SetPoint("TOPLEFT", addItemLabel, "BOTTOMLEFT", 0, -4)
    addItemHelp:SetText("|cffaaaaaa(Hover over items to see their ID in the tooltip)|r")

    -- Tracked Items Section
    local itemsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    itemsHeader:SetPoint("TOPLEFT", addItemHelp, "BOTTOMLEFT", 0, -16)
    itemsHeader:SetText("|cffffd700Tracked Items|r")

    -- Items list container
    local itemsContainer = CreateFrame("Frame", nil, panel)
    itemsContainer:SetPoint("TOPLEFT", itemsHeader, "BOTTOMLEFT", 0, -8)
    itemsContainer:SetSize(600, MAX_VISIBLE_ITEMS * ROW_HEIGHT)

    -- Scroll frame for items
    local scrollFrame = CreateFrame("ScrollFrame", "FarmCounterConfigScrollFrame", itemsContainer)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetSize(580, MAX_VISIBLE_ITEMS * ROW_HEIGHT)

    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(560)
    scrollFrame:SetScrollChild(scrollChild)

    -- Scrollbar
    local scrollbar = CreateFrame("Slider", "FarmCounterConfigScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    -- No items label (shown when no items tracked)
    local noItemsLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    noItemsLabel:SetPoint("TOPLEFT", 10, -10)
    noItemsLabel:SetText("|cffaaaaaa(No items tracked. Use 'Add Item by ID' above or Shift+Click items in your bags.)|r")

    -- Actions Section
    local actionsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    actionsHeader:SetPoint("TOPLEFT", itemsContainer, "BOTTOMLEFT", 0, -20)
    actionsHeader:SetText("|cffffd700Actions|r")

    -- Reset Session button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPLEFT", actionsHeader, "BOTTOMLEFT", 0, -8)
    resetBtn:SetSize(150, 25)
    resetBtn:SetText("Reset Session")
    resetBtn:SetScript("OnClick", function()
        FarmCounter:StartSession()
    end)

    -- Remove All Items button
    local removeAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    removeAllBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    removeAllBtn:SetSize(150, 25)
    removeAllBtn:SetText("Remove All Items")
    removeAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("FARMCOUNTER_REMOVE_ALL")
    end)

    -- Store references
    panel.showWindowCheck = showWindowCheck
    panel.lockWindowCheck = lockWindowCheck
    panel.showMinimapCheck = showMinimapCheck
    panel.showFocusBarCheck = showFocusBarCheck
    panel.lockFocusBarCheck = lockFocusBarCheck
    panel.addItemEditBox = addItemEditBox
    panel.scrollFrame = scrollFrame
    panel.scrollChild = scrollChild
    panel.scrollbar = scrollbar
    panel.noItemsLabel = noItemsLabel
    panel.itemRows = {}

    -- Refresh function
    panel.refresh = function()
        FarmCounterConfig:RefreshConfigPanel()
    end

    self.panel = panel

    -- Add to Interface Options (with fallback for different WoW versions)
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        -- Retail API
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        -- Manual registration fallback
        if not INTERFACEOPTIONS_ADDONCATEGORIES then
            INTERFACEOPTIONS_ADDONCATEGORIES = {}
        end
        table.insert(INTERFACEOPTIONS_ADDONCATEGORIES, panel)
    end
end

-- Refresh the config panel with current settings
function FarmCounterConfig:RefreshConfigPanel()
    if not self.panel then return end

    local panel = self.panel

    -- Update checkboxes
    panel.showWindowCheck:SetChecked(FarmCounter.db.settings.windowVisible)
    panel.lockWindowCheck:SetChecked(FarmCounter.db.settings.windowLocked)
    panel.showMinimapCheck:SetChecked(not FarmCounter.db.minimap.hide)
    panel.showFocusBarCheck:SetChecked(FarmCounter.db.focus.barVisible)
    panel.lockFocusBarCheck:SetChecked(FarmCounter.db.focus.barLocked)

    -- Update tracked items list
    self:UpdateItemsList()
end

-- Update the tracked items list
function FarmCounterConfig:UpdateItemsList()
    if not self.panel then return end

    local panel = self.panel
    local scrollChild = panel.scrollChild
    local items = FarmCounter:GetTrackedItems()

    -- Hide all existing rows
    for _, row in ipairs(panel.itemRows) do
        row:Hide()
    end

    -- Show/hide no items label
    if #items == 0 then
        panel.noItemsLabel:Show()
    else
        panel.noItemsLabel:Hide()

        -- Create or reuse rows
        local yOffset = 0
        for i, itemID in ipairs(items) do
            local row = panel.itemRows[i]

            if not row then
                row = self:CreateItemRow(scrollChild)
                panel.itemRows[i] = row
            end

            self:UpdateItemRow(row, itemID)
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()

            yOffset = yOffset + ROW_HEIGHT
        end
    end

    -- Update scroll range
    local contentHeight = #items * ROW_HEIGHT
    local frameHeight = panel.scrollFrame:GetHeight()

    scrollChild:SetHeight(math.max(contentHeight, frameHeight))

    if contentHeight > frameHeight then
        panel.scrollbar:SetMinMaxValues(0, contentHeight - frameHeight)
        panel.scrollbar:Show()
    else
        panel.scrollbar:SetMinMaxValues(0, 0)
        panel.scrollbar:Hide()
    end
end

-- Create a row for displaying a tracked item
function FarmCounterConfig:CreateItemRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(560)
    row:SetHeight(ROW_HEIGHT)

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)

    -- Item name
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetJustifyH("LEFT")
    name:SetWidth(350)

    -- Stats (current count)
    local stats = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stats:SetPoint("LEFT", name, "RIGHT", 10, 0)
    stats:SetJustifyH("LEFT")

    -- Remove button
    local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    removeBtn:SetSize(70, 22)
    removeBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    removeBtn:SetText("Remove")

    row.icon = icon
    row.name = name
    row.stats = stats
    row.removeBtn = removeBtn

    return row
end

-- Update a row with item data
function FarmCounterConfig:UpdateItemRow(row, itemID)
    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)

    if not itemName then
        return
    end

    -- Set icon
    row.icon:SetTexture(itemTexture)

    -- Set name with quality color
    local r, g, b = GetItemQualityColor(itemRarity or 0)
    row.name:SetText(itemName)
    row.name:SetTextColor(r, g, b)

    -- Set stats
    local itemStats = FarmCounter:GetItemStats(itemID)
    if itemStats then
        row.stats:SetText("|cffaaaaaa(Current: " .. itemStats.currentCount .. ")|r")
    end

    -- Remove button
    row.removeBtn:SetScript("OnClick", function()
        FarmCounter:RemoveItem(itemID)
        FarmCounterConfig:UpdateItemsList()
    end)
end

-- Open the config panel
function FarmCounterConfig:OpenConfig()
    if not self.panel then return end

    -- Refresh the panel first
    self:RefreshConfigPanel()

    -- Try to open via InterfaceOptions if available
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel) -- Call twice for proper focus
    elseif Settings and Settings.OpenToCategory then
        -- Retail API
        Settings.OpenToCategory(self.panel.name or "FarmCounter")
    else
        -- Fallback: Show panel as standalone window
        self.panel:SetParent(UIParent)
        self.panel:SetPoint("CENTER", UIParent, "CENTER")
        self.panel:Show()

        -- Add a close button if it doesn't exist
        if not self.panel.closeButton then
            local closeBtn = CreateFrame("Button", nil, self.panel, "UIPanelCloseButton")
            closeBtn:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", -5, -5)
            closeBtn:SetScript("OnClick", function()
                self.panel:Hide()
            end)
            self.panel.closeButton = closeBtn
        end
    end
end

-- Static popup for removing all items
StaticPopupDialogs["FARMCOUNTER_REMOVE_ALL"] = {
    text = "Remove all tracked items?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        FarmCounter.db.trackedItems = {}
        print("|cff00ff00FarmCounter:|r All items removed from tracking.")

        if FarmCounterUI and FarmCounterUI.UpdateDisplay then
            FarmCounterUI:UpdateDisplay()
        end

        if FarmCounterConfig and FarmCounterConfig.UpdateItemsList then
            FarmCounterConfig:UpdateItemsList()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Initialize config panel
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        FarmCounterConfig:CreateConfigPanel()
    end
end)
