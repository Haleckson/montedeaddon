local C = _G.Chronicle
local TRAINER_TYPES = { available = true, unavailable = true, used = true, header = true }

local session = { ore = 0, herbs = 0, skinning = 0, nodes = 0, started = time() }
local pending
C.gatherSession = session

local function gatheringData()
    if not C.char then return end
    C.char.gathering = C.char.gathering or { ore = {}, herbs = {}, skinning = {},
        oreNodes = 0, herbNodes = 0, skinNodes = 0 }
    C.char.gathering.ore = C.char.gathering.ore or {}
    C.char.gathering.herbs = C.char.gathering.herbs or {}
    C.char.gathering.skinning = C.char.gathering.skinning or {}
    return C.char.gathering
end

local function bagSnapshot()
    local result = {}
    for bag = 0, 5 do
        local slots
        if C_Container and C_Container.GetContainerNumSlots then
            local ok, value = pcall(C_Container.GetContainerNumSlots, bag)
            if ok then slots = value end
        end
        if not slots and GetContainerNumSlots then
            local ok, value = pcall(GetContainerNumSlots, bag)
            if ok then slots = value end
        end
        for slot = 1, tonumber(slots) or 0 do
            local itemID, count, link
            if C_Container and C_Container.GetContainerItemInfo then
                local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if not ok then info = nil end
                if info then itemID, count, link = info.itemID, info.stackCount, info.hyperlink end
            elseif GetContainerItemInfo then
                local _, quantity, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
                count, link = quantity, itemLink
            end
            if not itemID and link then itemID = tonumber(link:match("item:(%d+)")) end
            if itemID then
                local row = result[itemID] or { count = 0, link = link }
                row.count = row.count + (tonumber(count) or 1)
                row.link = row.link or link
                result[itemID] = row
            end
        end
    end
    return result
end

local function gatheringKind(spellID)
    if not spellID then return end
    local name
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        name = info and info.name
    end
    if not name and GetSpellInfo then name = GetSpellInfo(spellID) end
    local originalName = type(name) == "string" and name or ""
    if originalName:find("Kürschn", 1, true) or originalName:find("kürschn", 1, true) then
        return "skinning"
    end
    name = originalName:lower()
    if name:find("mining", 1, true) or name:find("bergbau", 1, true) or
        name:find("abbau", 1, true) then return "ore" end
    if name:find("herb", 1, true) or name:find("kräuter", 1, true) or
        name:find("kraeuter", 1, true) then return "herbs" end
    if name:find("skinning", 1, true) or name:find("kürschn", 1, true) or
        name:find("kuerschn", 1, true) then return "skinning" end
end

function C:IsGatheringMaterial(kind, itemID, savedName)
    itemID = tonumber(itemID) or itemID
    local name, itemType, subType
    if GetItemInfo then
        local ok, itemName, _, _, _, _, itemClass, itemSubType = pcall(GetItemInfo, itemID)
        if ok then name, itemType, subType = itemName, itemClass, itemSubType end
    end
    name = type(name) == "string" and name or savedName
    if kind == "ore" then
        local lower = type(name) == "string" and name:lower() or ""
        return lower:match("erz$") ~= nil or lower:match(" ore$") ~= nil
    end
    if kind == "herbs" or kind == "skinning" then
        local classID, subClassID
        if GetItemInfoInstant then
            local ok, _, _, _, _, itemClassID, itemSubClassID = pcall(GetItemInfoInstant, itemID)
            if ok then classID, subClassID = itemClassID, itemSubClassID end
        end
        if classID and classID ~= 7 then return false end
        if classID == 7 and subClassID == (kind == "herbs" and 9 or 6) then return true end
        if itemType and itemType ~= "Handwerkswaren" and itemType ~= "Trade Goods" then return false end
        local lower = type(subType) == "string" and subType:lower() or ""
        if kind == "herbs" and (lower:find("kräuter", 1, true) or
            lower:find("kraeuter", 1, true) or lower:find("herb", 1, true)) then return true end
        if kind == "skinning" and (lower:find("leder", 1, true) or
            lower:find("leather", 1, true)) then return true end
        if kind == "skinning" then
            local lowerName = type(name) == "string" and name:lower() or ""
            for _, part in ipairs({ "leder", "haut", "fell", "schuppe", "balg",
                "leather", "hide", "pelt", "scale", "scrap" }) do
                if lowerName:find(part, 1, true) then return true end
            end
        end
    end
    return false
end

local function recordGather()
    if not pending or time() - pending.at > 10 then pending = nil; return end
    if not pending.success then return end
    local data = gatheringData()
    if not data then return end
    local after, gained, looted = bagSnapshot(), 0, 0
    for itemID, row in pairs(after) do
        local delta = row.count - (pending.before[itemID] and pending.before[itemID].count or 0)
        if delta > 0 then
            looted = looted + delta
            if C:IsGatheringMaterial(pending.kind, itemID) then
                local entries = data[pending.kind]
                local entry = entries[itemID] or { count = 0, best = 0, name = "", link = row.link }
                entry.count = entry.count + delta
                entry.best = math.max(entry.best, delta)
                entry.link = row.link or entry.link
                entry.name = (GetItemInfo and GetItemInfo(itemID)) or entry.name or ("Gegenstand " .. itemID)
                entry.lastSeen = time()
                entries[itemID] = entry
                gained = gained + delta
            end
        end
    end
    if looted > 0 then
        if pending.kind == "ore" then data.oreNodes = (data.oreNodes or 0) + 1
        elseif pending.kind == "herbs" then data.herbNodes = (data.herbNodes or 0) + 1
        else data.skinNodes = (data.skinNodes or 0) + 1 end
        session[pending.kind] = session[pending.kind] + gained
        session.nodes = session.nodes + 1
        C:Fire("DATA_CHANGED", "gathering")
        pending = nil
    end
end

local trainerSessionScanned = false
local trainerCapturePending = false
local trainerSavedFilters
local WEAPON_SKILLS = {
    ["Einhandäxte"] = true, ["Zweihandäxte"] = true,
    ["Einhandschwerter"] = true, ["Zweihandschwerter"] = true,
    ["Einhandstreitkolben"] = true, ["Zweihandstreitkolben"] = true,
    ["Dolche"] = true, ["Stangenwaffen"] = true, ["Stäbe"] = true,
    ["Bogen"] = true, ["Armbrüste"] = true, ["Schusswaffen"] = true,
    ["Wurfwaffen"] = true, ["Faustwaffen"] = true,
    ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
    ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
    ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
    ["Daggers"] = true, ["Polearms"] = true, ["Staves"] = true,
    ["Bows"] = true, ["Crossbows"] = true, ["Guns"] = true,
    ["Thrown"] = true, ["Fist Weapons"] = true,
}
local function trainerPosition()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return end
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not mapID then return end
    local positionOK, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not positionOK or not position then return end
    local x, y
    if position.GetXY then x, y = position:GetXY()
    else x, y = position.x, position.y end
    if type(x) == "number" and type(y) == "number" and x > 0 and y > 0 then
        return mapID, math.floor(x * 1000 + .5) / 10, math.floor(y * 1000 + .5) / 10
    end
end
local function scanTrainer()
    if not C.char or not GetNumTrainerServices or not GetTrainerServiceInfo then return end
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    local count = tonumber(GetNumTrainerServices()) or 0
    if count == 0 then return end
    C.char.training = C.char.training or { services = {} }
    local training = C.char.training
    training.services = training.services or {}
    local trainerName = (UnitName and UnitName("npc")) or training.trainer or "Klassentrainer"
    local trainerZone = (GetZoneText and GetZoneText()) or training.zone or ""
    local changed = trainerName ~= training.trainer or trainerZone ~= training.zone
    training.trainer, training.zone = trainerName, trainerZone
    training.scanned = time()
    training.visitedTrainers = training.visitedTrainers or {}
    training.weaponServices = training.weaponServices or {}
    if UnitClass then
        local _, class = UnitClass("player")
        training.class = class or training.class
    end
    local weaponCount, classCount = 0, 0
    local classNames = {}
    for _, spell in ipairs(C.GetTrainerCatalogEntries and C:GetTrainerCatalogEntries() or {}) do
        classNames[spell.name] = true
    end
    for index = 1, count do
        local name, second, third, fourth, fifth = GetTrainerServiceInfo(index)
        local serviceType = TRAINER_TYPES[second] and second or (TRAINER_TYPES[third] and third or "unavailable")
        -- Forever uses name, type, icon, level, subtext. Classic uses
        -- name, subtext, type, expanded.
        local rank = TRAINER_TYPES[second] and fifth or second
        if type(rank) ~= "string" or rank == "" or TRAINER_TYPES[rank] then rank = nil end
        if name and name ~= "" and serviceType ~= "header" then
            if WEAPON_SKILLS[name] then weaponCount = weaponCount + 1
            elseif classNames[name] then classCount = classCount + 1 end
            local key = name .. "\031" .. (rank or "")
            if rank then training.services[name .. "\031"] = nil end
            local row = training.services[key] or {}
            local status = serviceType or "unavailable"
            local cost = GetTrainerServiceCost and (tonumber(GetTrainerServiceCost(index)) or 0) or 0
            local level = GetTrainerServiceLevelReq and (tonumber(GetTrainerServiceLevelReq(index)) or 0) or
                (tonumber(fourth) or 0)
            if row.status ~= status or row.cost ~= cost or row.level ~= level or row.rank ~= rank then changed = true end
            row.name, row.rank = name, rank
            if C_TooltipInfo and C_TooltipInfo.GetTrainerService then
                local ok, info = pcall(C_TooltipInfo.GetTrainerService, index)
                if ok and type(info) == "table" then row.spellID = tonumber(info.id) or row.spellID end
            end
            row.icon = GetTrainerServiceIcon and GetTrainerServiceIcon(index) or
                (type(third) == "string" and third ~= serviceType and third or row.icon)
            row.status = status
            row.cost, row.level = cost, level
            row.lastSeen = time()
            if WEAPON_SKILLS[name] then training.services[key] = nil
            else training.services[key] = row end
            if WEAPON_SKILLS[name] then
                local weaponKey = name .. "\031" .. (rank or "")
                local weapon = training.weaponServices[weaponKey] or {}
                weapon.name, weapon.rank, weapon.level = name, rank, level
                weapon.cost, weapon.status, weapon.icon = cost, status, row.icon
                weapon.trainer, weapon.zone, weapon.lastSeen = trainerName, trainerZone, time()
                training.weaponServices[weaponKey] = weapon
            end
        end
    end
    if classCount > 0 or weaponCount > 0 then
        local kind = classCount > 0 and "class" or "weapon"
        local visitKey = kind .. "\031" .. trainerName .. "\031" .. trainerZone
        local visit = training.visitedTrainers[visitKey] or {}
        visit.name, visit.zone, visit.kind = trainerName, trainerZone, kind
        visit.lastSeen = time()
        local mapID, x, y = trainerPosition()
        if mapID then visit.mapID, visit.x, visit.y = mapID, x, y end
        training.visitedTrainers[visitKey] = visit
        changed = true
    end
    trainerSessionScanned = true
    if changed then C:Fire("DATA_CHANGED", "training") end
end

local function restoreTrainerFilters()
    if not trainerSavedFilters or not SetTrainerServiceTypeFilter then return end
    for kind, enabled in pairs(trainerSavedFilters) do
        pcall(SetTrainerServiceTypeFilter, kind, enabled)
    end
    trainerSavedFilters = nil
end

local function captureAllTrainerServices()
    if trainerCapturePending then return end
    trainerCapturePending = true
    if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
        trainerSavedFilters = {}
        for _, kind in ipairs({ "available", "unavailable", "used" }) do
            local ok, enabled = pcall(GetTrainerServiceTypeFilter, kind)
            if ok then
                trainerSavedFilters[kind] = enabled
                if not enabled then pcall(SetTrainerServiceTypeFilter, kind, true) end
            end
        end
    end
    local function finish()
        if not trainerCapturePending then return end
        scanTrainer()
        restoreTrainerFilters()
        trainerCapturePending = false
    end
    if C_Timer and C_Timer.After then C_Timer.After(.35, finish) else finish() end
end

local hookedLevelDisplays = setmetatable({}, { __mode = "k" })
local suppressLevelUntil = 0
local function levelDisplayTime()
    return GetTime and GetTime() or 0
end
local function suppressBlizzardLevelDisplay()
    for _, name in ipairs({ "LevelUpDisplay", "LevelUpDisplayFrame", "LevelUpDisplayLevelFrame",
        "LevelUpDisplaySpellFrame" }) do
        local display = _G[name]
        if display then
            if display.UnregisterEvent then
                pcall(display.UnregisterEvent, display, "PLAYER_LEVEL_UP")
            end
            if not hookedLevelDisplays[display] and display.HookScript then
                local ok = pcall(display.HookScript, display, "OnShow", function(self)
                    if suppressLevelUntil > 0 and levelDisplayTime() <= suppressLevelUntil and self.Hide then
                        self:Hide()
                    end
                end)
                if ok then hookedLevelDisplays[display] = true end
            end
            if suppressLevelUntil > 0 and levelDisplayTime() <= suppressLevelUntil and
                display.IsShown and display:IsShown() and display.Hide then display:Hide() end
        end
    end
end

-- Some clients create the level-up text in a differently named frame. During
-- the short level-up window, find its distinctive text and hide that owner.
local function suppressUnnamedLevelDisplay()
    if not UIParent or not UIParent.GetChildren then return end
    local frames, index = { UIParent }, 1
    while frames[index] and index <= 6000 do
        local frame = frames[index]
        index = index + 1
        local shown, visible
        if frame.IsShown then shown, visible = pcall(frame.IsShown, frame) end
        if frame == UIParent or (shown and visible) then
            if frame.GetChildren then
                for _, child in ipairs({ frame:GetChildren() }) do
                    frames[#frames + 1] = child
                end
            end
        end
        if frame ~= UIParent and shown and visible and frame.GetRegions then
            local regions = { frame:GetRegions() }
            for _, region in ipairs(regions) do
                if region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText then
                    local ok, value = pcall(region.GetText, region)
                    if ok and type(value) == "string" and
                        (value:find("Ihr seid auf", 1, true) or
                         value:find("You have reached", 1, true)) then
                        local parent = frame.GetParent and frame:GetParent()
                        local owner = parent and parent ~= UIParent and parent ~= WorldFrame and parent or frame
                        if owner.Hide then owner:Hide() end
                        return
                    end
                end
            end
        end
    end
end

local blizzardLevelWatcher = CreateFrame("Frame")
blizzardLevelWatcher:SetScript("OnUpdate", function(self, elapsed)
    if suppressLevelUntil > 0 and levelDisplayTime() <= suppressLevelUntil then
        suppressBlizzardLevelDisplay()
        self.levelScanElapsed = (self.levelScanElapsed or 0) + (elapsed or 0)
        if self.levelScanElapsed >= .2 then
            self.levelScanElapsed = 0
            suppressUnnamedLevelDisplay()
        end
    end
end)
blizzardLevelWatcher:RegisterEvent("PLAYER_LOGIN")
blizzardLevelWatcher:RegisterEvent("PLAYER_LEVEL_UP")
blizzardLevelWatcher:RegisterEvent("ADDON_LOADED")
blizzardLevelWatcher:SetScript("OnEvent", function(_, event, addon)
    if event == "PLAYER_LEVEL_UP" then
        suppressLevelUntil = levelDisplayTime() + 10
    end
    suppressBlizzardLevelDisplay()
    if (event == "PLAYER_LOGIN" or event == "PLAYER_LEVEL_UP") and C_Timer and C_Timer.After then
        for _, delay in ipairs({ .05, .3, 1, 3 }) do
            C_Timer.After(delay, suppressBlizzardLevelDisplay)
        end
    end
end)

local levelNotice
local function showLevelNotice(level, spells, nextLevel, demo)
    if not UIParent then return end
    suppressBlizzardLevelDisplay()
    if not levelNotice then
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(540, 250)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -205)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(false)
        local rule = frame:CreateTexture(nil, "ARTWORK")
        rule:SetTexture("Interface\\Buttons\\WHITE8X8")
        rule:SetVertexColor(.8, .62, .2, .55)
        rule:SetPoint("TOPLEFT", 24, -14)
        rule:SetPoint("TOPRIGHT", -24, -14)
        rule:SetHeight(C:RuleThickness())
        local titleRule = frame:CreateTexture(nil, "ARTWORK")
        titleRule:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleRule:SetVertexColor(.8, .62, .2, .42)
        titleRule:SetPoint("TOPLEFT", 24, -103)
        titleRule:SetPoint("TOPRIGHT", -24, -103)
        titleRule:SetHeight(C:RuleThickness())
        local lowerRule = frame:CreateTexture(nil, "ARTWORK")
        lowerRule:SetTexture("Interface\\Buttons\\WHITE8X8")
        lowerRule:SetVertexColor(.8, .62, .2, .32)
        lowerRule:SetPoint("BOTTOMLEFT", 24, 14)
        lowerRule:SetPoint("BOTTOMRIGHT", -24, 14)
        lowerRule:SetHeight(C:RuleThickness())
        local caption = frame:CreateFontString(nil, "OVERLAY")
        caption:SetFont(C:FontPath(), 12)
        caption:SetTextColor(.9, .86, .78)
        caption:SetPoint("TOP", 0, -31)
        frame.caption = caption
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(C:FontPath(), 31)
        title:SetTextColor(1, .82, .1)
        title:SetPoint("TOP", 0, -50)
        title:SetWidth(500)
        title:SetJustifyH("CENTER")
        frame.title = title
        frame.spellRows = {}
        local footer = frame:CreateFontString(nil, "OVERLAY")
        footer:SetFont(C:FontPath(), 11)
        footer:SetTextColor(.75, .7, .6)
        footer:SetPoint("BOTTOM", 0, 27)
        footer:SetWidth(490)
        footer:SetJustifyH("CENTER")
        frame.footer = footer
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            local t = self.elapsed
            if t >= 8 then self:Hide(); return end
            local alpha = t < .2 and math.min(1, t / .2) or
                (t > 7 and math.max(0, 8 - t) or 1)
            self:SetAlpha(alpha)
        end)
        frame:Hide()
        levelNotice = frame
    end
    local count = math.min(#(spells or {}), 4)
    levelNotice:SetHeight(158 + math.max(1, count) * 54)
    for index = 1, math.max(1, count) do
        local row = levelNotice.spellRows[index]
        if not row then
            row = CreateFrame("Frame", nil, levelNotice)
            row:SetSize(490, 48)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(40, 40)
            row.icon:SetPoint("LEFT", 2, 0)
            row.name = row:CreateFontString(nil, "OVERLAY")
            row.name:SetFont(C:FontPath(), 17)
            row.name:SetTextColor(1, .82, .1)
            row.name:SetPoint("TOPLEFT", 54, -2)
            row.name:SetWidth(425)
            row.name:SetJustifyH("LEFT")
            row.status = row:CreateFontString(nil, "OVERLAY")
            row.status:SetFont(C:FontPath(), 11)
            row.status:SetTextColor(.35, .95, .45)
            row.status:SetPoint("TOPLEFT", 55, -27)
            row.status:SetWidth(420)
            row.status:SetJustifyH("LEFT")
            levelNotice.spellRows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 25, -115 - (index - 1) * 54)
        local spell = spells and spells[index]
        row.icon:SetTexture(spell and spell.icon or "Interface\\Icons\\INV_Misc_Book_09")
        row.name:SetText(spell and spell.title or C:LocalizeDisplay("Keine neuen Klassenfähigkeiten"))
        row.status:SetText(spell and spell.status or
            (nextLevel and (C:LocalizeDisplay("Nächste Freischaltung: Stufe ") .. nextLevel) or
                C:LocalizeDisplay("Auf dieser Stufe ist nichts Neues verfügbar.")))
        row:Show()
    end
    for index = math.max(1, count) + 1, #levelNotice.spellRows do
        levelNotice.spellRows[index]:Hide()
    end
    levelNotice.elapsed = 0
    levelNotice.caption:SetText(C:LocalizeDisplay("Du hast erreicht"))
    levelNotice.title:SetText(C:L("level") .. " " .. tostring(level))
    levelNotice.footer:SetText(demo and C:LocalizeDisplay("DEMO · Es werden keine Daten gespeichert.") or
        (#(spells or {}) > 4 and ("+" .. (#spells - 4) .. C:LocalizeDisplay(" weitere Fähigkeiten beim Trainer")) or
            C:LocalizeDisplay("Angebote und Preise beim Klassentrainer prüfen.")))
    levelNotice:SetAlpha(0)
    levelNotice:Show()
end

local function notifyNewTrainerSpells(level)
    local training = C.char and C.char.training or { services = {} }
    level = tonumber(level)
    if not level then return end
    training.notifiedLevels = training.notifiedLevels or {}
    if training.notifiedLevels[level] then return end
    local spells, seen = {}, {}
    local candidates = C.GetTrainerCatalogEntries and C:GetTrainerCatalogEntries() or {}
    for _, spell in ipairs(candidates) do
        if tonumber(spell.level) == level then
            local known = false
            if IsSpellKnown then
                local ok, result = pcall(IsSpellKnown, spell.spellID)
                known = ok and result or false
            end
            local title = spell.name .. (spell.rank and " " .. spell.rank or "")
            if not seen[title] then
                spells[#spells + 1] = { title = title, icon = spell.icon,
                    status = known and C:LocalizeDisplay("Jetzt nutzbar") or
                        C:LocalizeDisplay("Beim Klassentrainer lernen") }
                seen[title] = true
            end
        end
    end
    for _, spell in pairs(training.services or {}) do
        if type(spell) == "table" and tonumber(spell.level) == level and spell.status ~= "used" then
            local title = spell.name .. (spell.rank and spell.rank ~= "" and " " .. spell.rank or "")
            if not seen[title] then
                spells[#spells + 1] = { title = title, icon = spell.icon,
                    status = C:LocalizeDisplay("Beim Klassentrainer lernen") }
                seen[title] = true
            end
        end
    end
    training.notifiedLevels[level] = true
    if #spells == 0 then
        local nextLevel
        for _, spell in ipairs(candidates) do
            local required = tonumber(spell.level)
            if required and required > level and (not nextLevel or required < nextLevel) then
                nextLevel = required
            end
        end
        C:Print("Stufe " .. level .. ": Keine neuen Klassenzauber" ..
            (nextLevel and ". Nächste Katalog-Freischaltung: Stufe " .. nextLevel .. "." or "."))
        showLevelNotice(level, {}, nextLevel)
        return
    end
    table.sort(spells, function(a, b) return a.title < b.title end)
    local names = {}
    for _, spell in ipairs(spells) do names[#names + 1] = spell.title end
    local summary = table.concat(names, ", ", 1, math.min(#names, 5))
    if #names > 5 then summary = summary .. " und " .. (#names - 5) .. " weitere" end
    C:Print("Stufe " .. level .. ": Neue Klassenzauber laut Katalog: " .. summary ..
        ". Im Trainerfenster siehst du, welche davon der Klassentrainer anbietet.")
    showLevelNotice(level, spells)
end

function C:ShowLevelNoticeDemo()
    showLevelNotice(22, {
        { title = self:LocalizeDisplay("Skorpidstich"),
            icon = "Interface\\Icons\\ability_hunter_criticalshot",
            status = self:LocalizeDisplay("Neue Fähigkeit · beim Trainer lernen") },
        { title = self:LocalizeDisplay("Mal des Jägers") .. " " .. self:LocalizeDisplay("Rang 2"),
            icon = "Interface\\Icons\\ability_hunter_snipershot",
            status = self:LocalizeDisplay("Neuer Rang · beim Trainer lernen") },
    }, nil, true)
end

C:On("CHARACTER_LEVEL_UP", function(level)
    if C_Timer and C_Timer.After then
        C_Timer.After(.5, function() notifyNewTrainerSpells(level) end)
    else
        notifyNewTrainerSpells(level)
    end
end)

local tracker = CreateFrame("Frame")
for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "BAG_UPDATE_DELAYED",
    "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED" }) do pcall(tracker.RegisterEvent, tracker, event) end
tracker:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if ... == "player" then pending = nil end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" then return end
        local kind = gatheringKind(spellID)
        if not kind then return end
        if event == "UNIT_SPELLCAST_START" or not pending or pending.kind ~= kind then
            pending = { kind = kind, before = bagSnapshot(), at = time(), success = false }
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then pending.success = true end
    elseif event == "BAG_UPDATE_DELAYED" then
        recordGather()
    elseif event == "TRAINER_CLOSED" then
        trainerCapturePending = false
        restoreTrainerFilters()
        trainerSessionScanned = false
    elseif event == "TRAINER_SHOW" then
        captureAllTrainerServices()
    elseif event == "TRAINER_UPDATE" then
        if not trainerCapturePending then
            if C_Timer and C_Timer.After then C_Timer.After(.2, scanTrainer) else scanTrainer() end
        end
    end
end)

