-- FarmCounter UI Module
FarmCounterUI = {}

local ROW_HEIGHT = 55
local FRAME_WIDTH = 280
local MAX_ROWS_VISIBLE = 8
local ICON_SIZE = 32

-- Create the main frame
function FarmCounterUI:CreateMainFrame()
    -- Main frame
    local frame = CreateFrame("Frame", "FarmCounterFrame", UIParent, "BackdropTemplate")
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(300)
    frame:SetPoint("CENTER", UIParent, "CENTER",
        FarmCounter.db.settings.windowPosition.x,
        FarmCounter.db.settings.windowPosition.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })

    -- Title bar (for dragging)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -8)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not FarmCounter.db.settings.windowLocked then
            frame:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        FarmCounter.db.settings.windowPosition.x = x
        FarmCounter.db.settings.windowPosition.y = y
    end)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    title:SetText("|cff00ff00FarmCounter|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        FarmCounter.db.settings.windowVisible = false
    end)

    -- Content area
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 40)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "FarmCounterScrollFrame", content)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 0)

    -- Scroll child (content container)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(FRAME_WIDTH - 50)
    scrollFrame:SetScrollChild(scrollChild)

    -- Scrollbar
    local scrollbar = CreateFrame("Slider", "FarmCounterScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    -- Add Item button
    local addBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 25)
    addBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", -105, 12)
    addBtn:SetText("Add Item")
    addBtn:SetScript("OnClick", function()
        StaticPopup_Show("FARMCOUNTER_ADD_ITEM")
    end)

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(100, 25)
    resetBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 5, 12)
    resetBtn:SetText("Reset Session")
    resetBtn:SetScript("OnClick", function()
        FarmCounter:StartSession()
    end)

    -- Store references
    frame.titleBar = titleBar
    frame.content = content
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    frame.scrollbar = scrollbar
    frame.addBtn = addBtn
    frame.resetBtn = resetBtn
    frame.itemRows = {}

    self.frame = frame

    -- Set initial visibility
    if FarmCounter.db.settings.windowVisible then
        frame:Show()
    else
        frame:Hide()
    end

    -- Start update timer
    self:StartUpdateTimer()
end

-- Create or update item rows
function FarmCounterUI:UpdateDisplay()
    if not self.frame or not self.frame:IsShown() then
        return
    end

    local scrollChild = self.frame.scrollChild
    local items = FarmCounter:GetTrackedItems()

    -- Hide all existing rows
    for _, row in ipairs(self.frame.itemRows) do
        row:Hide()
    end

    -- Create or reuse rows
    local yOffset = 0
    for i, itemID in ipairs(items) do
        local row = self.frame.itemRows[i]

        if not row then
            row = self:CreateItemRow(scrollChild)
            self.frame.itemRows[i] = row
        end

        self:UpdateItemRow(row, itemID)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        row:Show()

        yOffset = yOffset + ROW_HEIGHT
    end

    -- Update scroll range
    local contentHeight = #items * ROW_HEIGHT
    local frameHeight = self.frame.scrollFrame:GetHeight()

    scrollChild:SetHeight(math.max(contentHeight, frameHeight))

    if contentHeight > frameHeight then
        self.frame.scrollbar:SetMinMaxValues(0, contentHeight - frameHeight)
        self.frame.scrollbar:Show()
    else
        self.frame.scrollbar:SetMinMaxValues(0, 0)
        self.frame.scrollbar:Hide()
    end

    -- Adjust frame height based on content
    local numRows = math.min(#items, MAX_ROWS_VISIBLE)
    local newHeight = 40 + (numRows * ROW_HEIGHT) + 40 -- title + content + bottom
    if numRows == 0 then
        newHeight = 150 -- minimum height when empty
    end
    self.frame:SetHeight(newHeight)
end

-- Create a row for an item
function FarmCounterUI:CreateItemRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(FRAME_WIDTH - 50)
    row:SetHeight(ROW_HEIGHT)

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)

    -- Icon border
    local iconBorder = row:CreateTexture(nil, "OVERLAY")
    iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    iconBorder:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)

    -- Focus indicator icon (hidden by default)
    local focusIndicator = row:CreateTexture(nil, "OVERLAY")
    focusIndicator:SetSize(16, 16)
    focusIndicator:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    focusIndicator:SetTexture("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1") -- Star icon
    focusIndicator:Hide()

    -- Item name
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    name:SetJustifyH("LEFT")
    name:SetWidth(150)

    -- Current count
    local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    count:SetJustifyH("LEFT")

    -- Session stats
    local session = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    session:SetPoint("TOPLEFT", count, "BOTTOMLEFT", 0, -2)
    session:SetJustifyH("LEFT")

    -- Focus button (star icon)
    local focusBtn = CreateFrame("Button", nil, row)
    focusBtn:SetSize(20, 20)
    focusBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -18, -2)

    -- Use a simple icon texture
    local focusIcon = focusBtn:CreateTexture(nil, "ARTWORK")
    focusIcon:SetAllPoints(focusBtn)
    focusIcon:SetTexture("Interface\\MINIMAP\\TRACKING\\None")
    focusIcon:SetAlpha(0.5)

    focusBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    focusBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Focus Item")
        GameTooltip:AddLine("Shows progress bar", 1, 1, 1)
        GameTooltip:Show()
    end)
    focusBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    focusBtn.icon = focusIcon

    -- Remove button
    local removeBtn = CreateFrame("Button", nil, row)
    removeBtn:SetSize(16, 16)
    removeBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
    removeBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    removeBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    removeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Remove from tracking")
        GameTooltip:Show()
    end)
    removeBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row.icon = icon
    row.focusIndicator = focusIndicator
    row.name = name
    row.count = count
    row.session = session
    row.focusBtn = focusBtn
    row.removeBtn = removeBtn

    return row
end

-- Update a row with item data
function FarmCounterUI:UpdateItemRow(row, itemID)
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

    -- Get statistics
    local stats = FarmCounter:GetItemStats(itemID)

    if stats then
        -- Current count (separate bags and bank)
        local countText = "|cffffffffBags:|r " .. stats.bagsCount
        if stats.bankCount > 0 then
            countText = countText .. " |cffaaaaaa||r |cffffffffBank:|r " .. stats.bankCount
        end
        row.count:SetText(countText)

        -- Session stats
        local farmedColor = stats.farmed >= 0 and "|cff00ff00" or "|cffff0000"
        local farmedText = stats.farmed >= 0 and "+" .. stats.farmed or stats.farmed

        local perHourText = string.format("%.1f", stats.perHour)
        row.session:SetText("|cffffffffSession:|r " .. farmedColor .. farmedText .. "|r |cffaaaaaa(" .. perHourText .. "/h)|r")
    end

    -- Check if this item is focused
    local isFocused = (FarmCounter.db.focus.itemID == itemID)

    -- Set focus button appearance and handler
    if isFocused then
        -- Focused: Bright icon
        row.focusBtn.icon:SetAlpha(1.0)
        row.focusBtn.icon:SetVertexColor(1, 0.8, 0) -- Gold tint
        row.focusBtn:SetScript("OnClick", function()
            FarmCounter:UnfocusItem()
        end)
        row.focusBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Unfocus Item")
            GameTooltip:AddLine("Currently focused", 0, 1, 0)
            GameTooltip:Show()
        end)
        row.focusBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Show focus indicator icon and adjust name position
        row.focusIndicator:Show()
        row.name:ClearAllPoints()
        row.name:SetPoint("TOPLEFT", row.focusIndicator, "TOPRIGHT", 4, 0)
    else
        -- Not focused: Dim icon
        row.focusBtn.icon:SetAlpha(0.5)
        row.focusBtn.icon:SetVertexColor(1, 1, 1) -- No tint
        row.focusBtn:SetScript("OnClick", function()
            -- Store itemID for the dialog
            FarmCounter.pendingFocusItemID = itemID
            -- Open dialog to choose focus mode
            StaticPopup_Show("FARMCOUNTER_CHOOSE_FOCUS_MODE")
        end)
        row.focusBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Focus Item")
            GameTooltip:AddLine("Session Goal: Track items farmed", 1, 1, 1)
            GameTooltip:AddLine("Free Farm: Track total (bags+bank)", 1, 1, 1)
            GameTooltip:AddLine("Right-click bar to change goal", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        row.focusBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Hide focus indicator icon and reset name position
        row.focusIndicator:Hide()
        row.name:ClearAllPoints()
        row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -2)
    end

    -- Set remove button click handler
    row.removeBtn:SetScript("OnClick", function()
        FarmCounter:RemoveItem(itemID)
    end)
end

-- Start periodic update timer
function FarmCounterUI:StartUpdateTimer()
    -- Update every 5 seconds
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed

        if self.timeSinceLastUpdate >= 5 then
            FarmCounterUI:UpdateDisplay()
            self.timeSinceLastUpdate = 0
        end
    end)
end

-- Static popup for adding items by ID
StaticPopupDialogs["FARMCOUNTER_ADD_ITEM"] = {
    text = "Enter Item ID to track:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    OnShow = function(self)
        -- In Classic Era, EditBox is capitalized
        local editBox = self.EditBox or self.editBox
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        -- In Classic Era, EditBox is capitalized
        local editBox = self.EditBox or self.editBox
        if editBox then
            local itemID = tonumber(editBox:GetText())
            if itemID then
                FarmCounter:AddItem(itemID)
            else
                print("|cffff0000FarmCounter:|r Invalid Item ID. Please enter a number.")
            end
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local itemID = tonumber(self:GetText())
        if itemID then
            FarmCounter:AddItem(itemID)
        else
            print("|cffff0000FarmCounter:|r Invalid Item ID. Please enter a number.")
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static popup to choose focus mode
StaticPopupDialogs["FARMCOUNTER_CHOOSE_FOCUS_MODE"] = {
    text = "Choose Focus Mode:",
    button1 = "Session Goal",
    button2 = "Free Farm",
    button3 = "Cancel",
    OnAccept = function(self)
        -- Button 1: Session mode
        StaticPopup_Show("FARMCOUNTER_SET_SESSION_GOAL")
    end,
    OnCancel = function(self)
        -- Button 2: Free Farm mode
        StaticPopup_Show("FARMCOUNTER_SET_FREEFARM_GOAL")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static popup for setting session goal
StaticPopupDialogs["FARMCOUNTER_SET_SESSION_GOAL"] = {
    text = "Set Session Goal (items to farm this session):",
    button1 = "Set",
    button2 = "Cancel",
    hasEditBox = true,
    OnShow = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            editBox:SetText("100")
            editBox:SetFocus()
            editBox:HighlightText()
        end
    end,
    OnAccept = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            local goal = tonumber(editBox:GetText())
            if goal and goal > 0 then
                local itemID = FarmCounter.pendingFocusItemID
                if itemID then
                    FarmCounter:FocusItem(itemID, goal, "session")
                    FarmCounter.pendingFocusItemID = nil
                end
            else
                print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
            end
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local goal = tonumber(self:GetText())
        if goal and goal > 0 then
            local itemID = FarmCounter.pendingFocusItemID
            if itemID then
                FarmCounter:FocusItem(itemID, goal, "session")
                FarmCounter.pendingFocusItemID = nil
            end
        else
            print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static popup for setting free farm goal
StaticPopupDialogs["FARMCOUNTER_SET_FREEFARM_GOAL"] = {
    text = "Free Farm: How many total items do you want?\n(Counts bags + bank together)",
    button1 = "Set",
    button2 = "Cancel",
    hasEditBox = true,
    OnShow = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            local itemID = FarmCounter.pendingFocusItemID
            if itemID then
                local stats = FarmCounter:GetItemStats(itemID)
                if stats then
                    -- Set default to current + 100
                    editBox:SetText(tostring(stats.currentCount + 100))
                else
                    editBox:SetText("100")
                end
            else
                editBox:SetText("100")
            end
            editBox:SetFocus()
            editBox:HighlightText()
        end
    end,
    OnAccept = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            local goal = tonumber(editBox:GetText())
            if goal and goal > 0 then
                local itemID = FarmCounter.pendingFocusItemID
                if itemID then
                    FarmCounter:FocusItem(itemID, goal, "total")
                    FarmCounter.pendingFocusItemID = nil
                end
            else
                print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
            end
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local goal = tonumber(self:GetText())
        if goal and goal > 0 then
            local itemID = FarmCounter.pendingFocusItemID
            if itemID then
                FarmCounter:FocusItem(itemID, goal, "total")
                FarmCounter.pendingFocusItemID = nil
            end
        else
            print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Initialize UI when addon is loaded
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        FarmCounterUI:CreateMainFrame()
    end
end)
