local function UpdateAreaName(entry)
    local areaLabel = entry.WhereYouAtAreaName
    if not areaLabel then
        areaLabel = entry:CreateFontString(nil, "ARTWORK")
        entry.WhereYouAtAreaName = areaLabel

        areaLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        areaLabel:SetHeight(15)
        areaLabel:SetJustifyH("LEFT")
        areaLabel:SetJustifyV("MIDDLE")
        areaLabel:SetWordWrap(false)
        areaLabel:SetPoint("LEFT", entry.ActivityName, "RIGHT", 8, 0)
        areaLabel:SetPoint("RIGHT", entry.DataDisplay, "LEFT", -8, 0)
    end

    areaLabel:SetTextColor(entry.ActivityName:GetTextColor())
    areaLabel:Hide()

    local leaderInfo = C_LFGList.GetSearchResultLeaderInfo(entry.resultID)
    local areaName = leaderInfo and leaderInfo.areaName

    if not areaName or areaName == "" then
        return
    end

    areaLabel:SetText(areaName)
    areaLabel:Show()
end

local hookInstalled = false

local function InstallHook()
    if hookInstalled or type(LFGBrowseSearchEntry_Update) ~= "function" then
        return
    end

    hooksecurefunc("LFGBrowseSearchEntry_Update", UpdateAreaName)
    hookInstalled = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", InstallHook)

InstallHook()
