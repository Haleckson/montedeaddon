local addonName, MCF = ...
local function T(key) return MCF:T(key) end
MCF.LevelScreenshotDelay = 2 -- seconds between a level-up and its screenshot (the welcome window reminder waits for it as well)

local levelFrame = CreateFrame("Frame")

local EQUIPMENT_SLOTS = {
    {1,"HeadSlot"},{2,"NeckSlot"},{3,"ShoulderSlot"},{4,"ShirtSlot"},
    {5,"ChestSlot"},{6,"WaistSlot"},{7,"LegsSlot"},{8,"FeetSlot"},
    {9,"WristSlot"},{10,"HandsSlot"},{11,"Finger0Slot"},{12,"Finger1Slot"},
    {13,"Trinket0Slot"},{14,"Trinket1Slot"},{15,"BackSlot"},
    {16,"MainHandSlot"},{17,"SecondaryHandSlot"},{18,"RangedSlot"},{19,"TabardSlot"},
}

MCF.EQUIPMENT_SLOTS = EQUIPMENT_SLOTS -- single slot list, also used by GearTracking

local function SafeItemInfo(link)
    -- Forever/Classic clients do not all expose the same item-info globals.
    -- Always keep the itemLink/itemID even when richer metadata is unavailable.
    if type(GetItemInfo) == "function" then
        return GetItemInfo(link)
    end

    if C_Item and type(C_Item.GetItemInfo) == "function" then
        return C_Item.GetItemInfo(link)
    end

    return nil
end

local function CaptureEquipment()
    local equipment = {}

    for _,slot in ipairs(EQUIPMENT_SLOTS) do
        local slotID, slotName = slot[1], slot[2]
        local link = GetInventoryItemLink("player", slotID)

        if link then
            local itemID
            if type(GetInventoryItemID) == "function" then
                itemID = GetInventoryItemID("player", slotID)
            end
            itemID = itemID or tonumber(link:match("item:(%d+)"))

            local name, _, quality, baseItemLevel, _, itemType, itemSubType, _, equipLoc, icon = SafeItemInfo(link)

            local effectiveItemLevel
            if type(GetDetailedItemLevelInfo) == "function" then
                effectiveItemLevel = GetDetailedItemLevelInfo(link)
            elseif C_Item and type(C_Item.GetDetailedItemLevelInfo) == "function" then
                effectiveItemLevel = C_Item.GetDetailedItemLevelInfo(link)
            end

            local curDurability, maxDurability
            if type(GetInventoryItemDurability) == "function" then
                curDurability, maxDurability = GetInventoryItemDurability(slotID)
            end

            local inventoryIcon
            if type(GetInventoryItemTexture) == "function" then
                inventoryIcon = GetInventoryItemTexture("player", slotID)
            end

            equipment[slotName] = {
                slotID = slotID,
                itemID = itemID,
                link = link,
                name = name,
                quality = quality,
                baseItemLevel = baseItemLevel,
                itemLevel = effectiveItemLevel,
                itemType = itemType,
                itemSubType = itemSubType,
                equipLoc = equipLoc,
                icon = icon or inventoryIcon,
                durability = curDurability,
                maxDurability = maxDurability,
            }
        end
    end

    return equipment
end

function MCF:CaptureLevelSnapshot(level, mapID, x, y, previousLevelDuration)
    local snapshot = {
        time = time(), level = level, mapID = mapID, x = x, y = y,
        zone = GetZoneText(), subZone = GetSubZoneText(),
        money = GetMoney(), playedTotal = self.totalPlayed,
        previousLevelDuration = previousLevelDuration,
        equipment = CaptureEquipment(),
        professions = (self.GetProfessionSnapshot and self:GetProfessionSnapshot()) or {},
    }
    local ilvlTotal,ilvlCount=0,0
    for _,item in pairs(snapshot.equipment or {}) do
        local ilvl=tonumber(item.itemLevel) or tonumber(item.baseItemLevel)
        if ilvl and ilvl>0 then ilvlTotal=ilvlTotal+ilvl; ilvlCount=ilvlCount+1 end
    end
    snapshot.averageItemLevel=(ilvlCount>0) and (ilvlTotal/ilvlCount) or nil
    MyCharForeverDB.levelSnapshots[level] = snapshot
    return snapshot
end

-- Screenshots the addon takes itself are marked here, so the SCREENSHOT_SUCCEEDED handler (Screenshots.lua)
-- can tell them from screenshots the player took with the game's own key and does not log them twice.
-- The one place that builds a client screenshot file name (the file type follows the client's setting).
function MCF:ScreenshotFileName(t)
    local fmt=tostring((GetCVar and GetCVar("screenshotFormat")) or "jpeg"):lower()
    local ext=({jpeg="jpg",jpg="jpg",png="png",tga="tga"})[fmt] or "jpg"
    return date("WoWScrnShot_%m%d%y_%H%M%S."..ext,t)
end

MCF.ownShotMarks = {}
function MCF:ConsumeOwnShotMark()
    local now = GetTime()
    local marks = self.ownShotMarks
    while marks[1] and now - marks[1] > 10 do table.remove(marks, 1) end
    if marks[1] then table.remove(marks, 1); return true end
    return false
end

function MCF:LogScreenshot(reason, level, mapID, x, y)
    if reason ~= "GAME" then table.insert(self.ownShotMarks, GetTime()) end
    local entry = {
        time = time(), reason = reason, level = level,
        mapID = mapID, x = x, y = y,
        zone = GetZoneText(), subZone = GetSubZoneText(),
    }
    -- WoW's Screenshot() API does not expose the written filename back to Lua.
    -- Keep the conventional client filename derived from the capture timestamp.
    entry.expectedFileName = self:ScreenshotFileName(entry.time)
    entry.fileNameSource = "requested"
    table.insert(MyCharForeverDB.screenshots, entry)
    self:AddEvent("SCREENSHOT", {reason=reason, level=level, screenshotIndex=#MyCharForeverDB.screenshots})
    return entry
end


MCF.currentLevel = nil
MCF.levelSessionStarted = nil

local function GetPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil, nil, nil
    end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then
        return mapID, nil, nil
    end

    local x, y = pos:GetXY()
    return mapID, x, y
end

function MCF:InitializeLevelTracking()
    local level = UnitLevel("player")
    self.currentLevel = level
    self.levelSessionStarted = GetTime()

    local entry = MyCharForeverDB.levels[level]

    if not entry then
        local mapID, x, y = GetPosition()

        entry = {
            level = level,
            firstSeen = time(),
            reached = nil,
            duration = 0,
            sessions = 0,
            mapID = mapID,
            x = x,
            y = y,
            zone = GetZoneText(),
        }

        MyCharForeverDB.levels[level] = entry
    end

    entry.sessions = (entry.sessions or 0) + 1
    RequestTimePlayed()
end

function MCF:CommitCurrentLevelSession()
    if not self.levelSessionStarted or not self.currentLevel then
        return
    end

    local entry = MyCharForeverDB.levels[self.currentLevel]
    if entry then
        local elapsed = math.max(0, GetTime() - self.levelSessionStarted)
        entry.duration = (entry.duration or 0) + elapsed
    end

    self.levelSessionStarted = nil
end

function MCF:UpdatePlayedTime(totalTime, levelTime)
    local level = UnitLevel("player")
    local entry = MyCharForeverDB.levels[level]
    if not entry then return end

    entry.playedTotalLastSeen = totalTime
    entry.blizzardLevelTime = levelTime
end

function MCF:GetCurrentLevelSessionTime()
    if not self.levelSessionStarted then
        return 0
    end

    return math.max(0, GetTime() - self.levelSessionStarted)
end

function MCF:GetCurrentLevelDuration()
    local level = UnitLevel("player")
    local entry = MyCharForeverDB.levels[level]
    if not entry then return 0 end

    local live = 0
    if self.currentLevel == level then
        live = self:GetCurrentLevelSessionTime()
    end

    return (entry.duration or 0) + live
end


function MCF:CaptureManualCurrentLevelSnapshot()
    local level = UnitLevel("player")
    local mapID, x, y = GetPosition()
    local ok, result = pcall(self.CaptureLevelSnapshot, self, level, mapID, x, y, nil)
    if ok then
        result.manual = true
        result.note = "Manual catch-up snapshot"
        self:AddEvent("MANUAL_LEVEL_SNAPSHOT", { level = level })
        print("|cff00ccffMyCharForever|r: "..T("Manual snapshot saved for level ")..level..".")
    else
        print("|cffff4444MyCharForever|r: "..T("Manual snapshot failed: ")..tostring(result))
    end
end

function MCF:HandleLevelUp(newLevel)
    MyCharForeverDB.stats.levelUps = (MyCharForeverDB.stats.levelUps or 0) + 1
    local oldLevel = newLevel - 1
    local oldEntry = MyCharForeverDB.levels[oldLevel]

    if oldEntry and self.levelSessionStarted then
        local elapsed = math.max(0, GetTime() - self.levelSessionStarted)
        oldEntry.duration = (oldEntry.duration or 0) + elapsed
        oldEntry.completed = time()
        oldEntry.completedAtLevel = newLevel

        if self.totalPlayed then
            oldEntry.playedAtEnd = self.totalPlayed
        end
    end

    local mapID, x, y = GetPosition()
    local newEntry = MyCharForeverDB.levels[newLevel]

    if not newEntry then
        newEntry = {
            level = newLevel,
            reached = time(),
            firstSeen = time(),
            duration = 0,
            sessions = 1,
            mapID = mapID,
            x = x,
            y = y,
            zone = GetZoneText(),
        }
        MyCharForeverDB.levels[newLevel] = newEntry
    else
        newEntry.sessions = (newEntry.sessions or 0) + 1
    end

    self.currentLevel = newLevel
    self.levelSessionStarted = GetTime()
    if self.CaptureLevelXPRequirement then self:CaptureLevelXPRequirement(newLevel) end

    -- Schedule the screenshot BEFORE optional metadata capture. A failure in
    -- equipment/item APIs must never prevent the level-up screenshot.
    if MyCharForeverDB.settings.levelScreenshots then
        C_Timer.After(MCF.LevelScreenshotDelay, function()
            self:LogScreenshot("LEVEL_UP", newLevel, mapID, x, y)
            if type(Screenshot) == "function" then
                local ss=MyCharForeverDB and MyCharForeverDB.settings
        if not ss or ss.screenshotLevelUp~=false then Screenshot() end
            end
        end)
    end

    local snapshotOK, snapshotOrError = pcall(
        self.CaptureLevelSnapshot,
        self,
        newLevel, mapID, x, y,
        oldEntry and oldEntry.duration or nil
    )

    if not snapshotOK then
        self:AddEvent("SNAPSHOT_ERROR", {
            level = newLevel,
            error = tostring(snapshotOrError),
        })
        MCF:LogError("Level snapshot failed: "..tostring(snapshotOrError), nil, "LevelHistory")
        MCF:Notify(T("Level snapshot failed, but level tracking continues."))
    end

    self:AddEvent("LEVEL_UP", {
        newLevel = newLevel,
        previousLevelDuration = oldEntry and oldEntry.duration or nil,
    })

    if self.RecordJourneyPoint then
        self:RecordJourneyPoint("LEVEL_" .. newLevel, true, newLevel)
    end

    RequestTimePlayed()

    MCF:Notify(T("Level").." "..newLevel..T(" reached!"))
end

levelFrame:RegisterEvent("PLAYER_LEVEL_UP")

levelFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        MCF:HandleLevelUp(newLevel)
    end
end)
