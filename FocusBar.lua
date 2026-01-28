-- FarmCounter Focus Bar Module
-- WeakAura-style progress bar for focused item
FarmCounterFocusBar = {}

local BAR_WIDTH = 250
local BAR_HEIGHT = 20
local ICON_SIZE = 32

-- Create the focus bar frame
function FarmCounterFocusBar:CreateFocusBar()
    -- Main frame
    local frame = CreateFrame("Frame", "FarmCounterFocusBarFrame", UIParent, "BackdropTemplate")
    frame:SetSize(BAR_WIDTH + ICON_SIZE + 20, BAR_HEIGHT + 16)
    frame:SetPoint("CENTER", UIParent, "CENTER", FarmCounter.db.focus.barPosition.x, FarmCounter.db.focus.barPosition.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")

    -- Background (subtle, borderless)
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = nil,
        tile = false,
        tileSize = 16,
        edgeSize = 0,
        insets = {
            left = 5,
            right = 2,
            top = 5,
            bottom = 5
        }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)

    -- Drag handlers
    frame:SetScript("OnDragStart", function(self)
        if not FarmCounter.db.focus.barLocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        FarmCounter.db.focus.barPosition.x = x
        FarmCounter.db.focus.barPosition.y = y
    end)

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", frame, "LEFT", 5, 0)

    -- Icon border
    local iconBorder = frame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    iconBorder:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)

    -- Progress bar background
    local barBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    barBg:SetSize(BAR_WIDTH, BAR_HEIGHT)
    barBg:SetPoint("LEFT", icon, "RIGHT", 12, 0)
    barBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = {
            left = 1,
            right = 1,
            top = 1,
            bottom = 1
        }
    })
    barBg:SetBackdropColor(0, 0, 0, 0.7)
    barBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    -- Progress bar fill (StatusBar)
    local progressBar = CreateFrame("StatusBar", nil, barBg)
    progressBar:SetSize(BAR_WIDTH - 4, BAR_HEIGHT - 4)
    progressBar:SetPoint("CENTER", barBg, "CENTER", 0, 0)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    progressBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green

    -- Progress bar spark
    local spark = progressBar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetSize(16, BAR_HEIGHT * 2)
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", progressBar:GetStatusBarTexture(), "RIGHT", 0, 0)

    -- Item name text
    local nameText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", progressBar, "LEFT", 5, 0)
    nameText:SetJustifyH("LEFT")

    -- Progress text (current / goal)
    local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("RIGHT", progressBar, "RIGHT", -5, 0)
    progressText:SetJustifyH("RIGHT")

    -- Stats text (farmed this session, per hour) - below the bar
    local statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsText:SetPoint("TOP", barBg, "BOTTOM", 0, -2)
    statsText:SetJustifyH("CENTER")

    -- Close/Unfocus button
    local unfocusBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    unfocusBtn:SetSize(20, 20)
    unfocusBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    unfocusBtn:SetScript("OnClick", function()
        FarmCounter:UnfocusItem()
    end)
    unfocusBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Unfocus Item")
        GameTooltip:Show()
    end)
    unfocusBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Right-click to set goal
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            StaticPopup_Show("FARMCOUNTER_SET_GOAL")
        end
    end)

    -- Store references
    frame.icon = icon
    frame.progressBar = progressBar
    frame.spark = spark
    frame.nameText = nameText
    frame.progressText = progressText
    frame.statsText = statsText

    self.frame = frame

    -- Set initial visibility
    if FarmCounter.db.focus.itemID and FarmCounter.db.focus.barVisible then
        frame:Show()
        self:Update()
    else
        frame:Hide()
    end

    -- Start update timer
    self:StartUpdateTimer()
end

-- Update the focus bar with current data
function FarmCounterFocusBar:Update()
    if not self.frame then
        return
    end

    local itemID = FarmCounter.db.focus.itemID
    if not itemID then
        self.frame:Hide()
        return
    end

    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if not itemName then
        return
    end

    -- Update icon
    self.frame.icon:SetTexture(itemTexture)

    -- Get stats
    local stats = FarmCounter:GetItemStats(itemID)
    if not stats then
        return
    end

    local goal = FarmCounter.db.focus.goal or 100
    local mode = FarmCounter.db.focus.mode or "session"

    -- Choose current value based on mode
    local current
    if mode == "total" then
        -- Free Farm mode: show total bags + bank
        current = stats.currentCount
    else
        -- Session mode: show farmed this session
        current = stats.farmed
    end

    local percentage = (current / goal) * 100
    percentage = math.min(percentage, 100) -- Cap at 100%

    -- Update progress bar
    self.frame.progressBar:SetMinMaxValues(0, goal)
    self.frame.progressBar:SetValue(current)

    -- Color based on progress
    if percentage >= 100 then
        self.frame.progressBar:SetStatusBarColor(1, 0.8, 0, 1) -- Gold when complete
    elseif percentage >= 75 then
        self.frame.progressBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
    elseif percentage >= 50 then
        self.frame.progressBar:SetStatusBarColor(0.8, 0.8, 0, 1) -- Yellow
    elseif percentage >= 25 then
        self.frame.progressBar:SetStatusBarColor(1, 0.5, 0, 1) -- Orange
    else
        self.frame.progressBar:SetStatusBarColor(0.8, 0, 0, 1) -- Red
    end

    -- Update spark visibility
    if current > 0 and current < goal then
        self.frame.spark:Show()
    else
        self.frame.spark:Hide()
    end

    -- Update item name
    local r, g, b = GetItemQualityColor(itemRarity or 0)
    self.frame.nameText:SetText(itemName)
    self.frame.nameText:SetTextColor(r, g, b)

    -- Update progress text
    local progressStr
    if current >= goal then
        progressStr = "|cff00ff00" .. current .. " / " .. goal .. " (Complete!)|r"
    else
        progressStr = current .. " / " .. goal
    end
    self.frame.progressText:SetText(progressStr)

    -- Update stats text (mode-dependent)
    local perHourText = string.format("%.1f", stats.perHour)
    local statsStr
    if mode == "total" then
        -- Free Farm mode: show bags and bank breakdown
        local bagsText = "|cffffffffBags:|r " .. stats.bagsCount
        local bankText = stats.bankCount > 0 and " |cffaaaaaa||r |cffffffffBank:|r " .. stats.bankCount or ""
        statsStr = "|cffaaaaaa" .. bagsText .. bankText .. " (" .. perHourText .. "/h)|r"
    else
        -- Session mode: show farmed this session
        statsStr = "|cffaaaaaa+" .. stats.farmed .. " this session (" .. perHourText .. "/h)|r"
    end
    self.frame.statsText:SetText(statsStr)

    -- Show frame
    self.frame:Show()
end

-- Start periodic update timer
function FarmCounterFocusBar:StartUpdateTimer()
    -- Update every 2 seconds
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed

        if self.timeSinceLastUpdate >= 2 then
            if FarmCounter.db.focus.itemID then
                FarmCounterFocusBar:Update()
            end
            self.timeSinceLastUpdate = 0
        end
    end)
end

-- Static popup for setting goal (right-click on bar)
StaticPopupDialogs["FARMCOUNTER_SET_GOAL"] = {
    text = "Set Goal for Focused Item:",
    button1 = "Set",
    button2 = "Cancel",
    hasEditBox = true,
    OnShow = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            local mode = FarmCounter.db.focus.mode or "session"
            local modeText = (mode == "total") and " (Free Farm)" or " (Session)"
            self.text:SetText("Set Goal for Focused Item:" .. modeText)
            editBox:SetText(tostring(FarmCounter.db.focus.goal or 100))
            editBox:SetFocus()
            editBox:HighlightText()
        end
    end,
    OnAccept = function(self)
        local editBox = self.EditBox or self.editBox
        if editBox then
            local goal = tonumber(editBox:GetText())
            if goal and goal > 0 then
                FarmCounter:SetFocusGoal(goal)
            else
                print("|cffff0000FarmCounter:|r Invalid goal. Please enter a positive number.")
            end
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local goal = tonumber(self:GetText())
        if goal and goal > 0 then
            FarmCounter:SetFocusGoal(goal)
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
    preferredIndex = 3
}

-- Initialize focus bar when addon is loaded
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        FarmCounterFocusBar:CreateFocusBar()
    end
end)
