-- FarmCounter Tooltip Module
-- Adds Item IDs to item tooltips

local function AddItemIDToTooltip(tooltip)
    -- Get the item link from the tooltip
    local _, itemLink = tooltip:GetItem()

    if itemLink then
        -- Extract item ID from the link
        local itemID = tonumber(itemLink:match("item:(%d+)"))

        if itemID then
            -- Add a line showing the item ID
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine("|cff00ff00Item ID:|r", "|cffffffff" .. itemID .. "|r")
            tooltip:Show()
        end
    end
end

-- Hook all relevant tooltips
GameTooltip:HookScript("OnTooltipSetItem", AddItemIDToTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", AddItemIDToTooltip)

-- Also hook shopping tooltips if they exist (Classic Era has these)
if ShoppingTooltip1 then
    ShoppingTooltip1:HookScript("OnTooltipSetItem", AddItemIDToTooltip)
end
if ShoppingTooltip2 then
    ShoppingTooltip2:HookScript("OnTooltipSetItem", AddItemIDToTooltip)
end
