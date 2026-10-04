local addonName, ns = ...
local pluginKey = "ForeverBooks"
local icon = "Interface\\AddOns\\" .. addonName .. "\\media\\ForeverBooks"
local collectedIcon = "Interface\\RaidFrame\\ReadyCheck-Ready"
local handler, nodes, continents = {}, {}, {}
local HandyNotes

local function say(message)
    print("|cff79d9ffForever Books:|r " .. message)
end

function ns.Refresh()
    if HandyNotes then HandyNotes:SendMessage("HandyNotes_NotifyUpdate", pluginKey) end
end

local function visible(location)
    if ns.db.hideCollected and ns.IsCollected(location.book) then return false end
    if location.kind == "uncertain" and not ns.db.uncertain then return false end
    local faction = ns.books[location.book].faction
    return not ns.db.factionOnly or not faction or faction == UnitFactionGroup("player")
end

local function pinVisible(pin)
    for _, location in ipairs(pin.entries) do
        if visible(location) then return true end
    end
    return false
end

-- HandyNotes expects an iterator yielding coord, UiMapID, texture, scale, alpha.
-- Each request has its own closure so concurrent world/minimap iteration is safe.
function handler:GetNodes2(uiMapID, minimap)
    local list
    if ns.db and ((minimap and ns.db.minimap) or (not minimap and ns.db.world)) then
        list = nodes[uiMapID]
        if not minimap and ns.db.continents then list = list or continents[uiMapID] end
    end
    local index = 0
    return function()
        if not list then return end
        while true do
            index = index + 1
            local pin = list[index]
            if not pin then return end
            if pinVisible(pin) then
                local complete = true
                for _, location in ipairs(pin.entries) do
                    if visible(location) and not ns.IsCollected(location.book) then complete = false end
                end
                return pin.coord, pin.map, complete and collectedIcon or icon, ns.db.scale, ns.db.alpha
            end
        end
    end
end

local lookup = {}
-- In these callbacks self is the HandyNotes PIN, not the plugin handler.
function handler:OnEnter(uiMapID, coord)
    local pin = lookup[uiMapID] and lookup[uiMapID][coord]
    if not pin then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("HandyNotes - Forever Books", 0.47, 0.85, 1)
    local info = C_Map.GetMapInfo(uiMapID)
    GameTooltip:AddLine((info and info.name or tostring(uiMapID)) .. string.format("  %.1f / %.1f", pin.x, pin.y), 1, 1, 1)
    for _, location in ipairs(pin.entries) do
        if visible(location) then
            local b = ns.books[location.book]
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(b.title, 1, 0.82, 0.35, true)
            GameTooltip:AddLine(ns.IsCollected(b.id) and "Gefunden [x]" or "Noch offen [ ]", 0.4, 1, 0.5)
            if b.faction then GameTooltip:AddLine("SoD-Fraktion: " .. b.faction, 0.8, 0.8, 0.8) end
            if location.kind == "reference" then
                GameTooltip:AddLine("Orientierungspunkt – kein exakter Fundort", 1, 0.55, 0.2, true)
            elseif location.kind == "entrance" then
                GameTooltip:AddLine("Zugang – Buch liegt im Höhlensystem", 1, 0.55, 0.2, true)
            elseif location.kind == "uncertain" then
                GameTooltip:AddLine("Forever: unbestätigt", 1, 0.4, 0.4)
            end
            GameTooltip:AddLine(location.description, 0.9, 0.9, 0.9, true)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Weltkarte: Shift-Linksklick zum Abhaken / Rückgängigmachen.", 0.6, 0.85, 1, true)
    GameTooltip:Show()
end

function handler:OnClick(button, down, uiMapID, coord)
    if down or button ~= "LeftButton" or not IsShiftKeyDown() then return end
    local pin = lookup[uiMapID] and lookup[uiMapID][coord]
    if not pin then return end
    local entries = {}
    for _, entry in ipairs(pin.entries) do
        if visible(entry) then entries[#entries + 1] = entry end
    end
    if #entries == 1 then
        local id = entries[1].book
        ns.SetCollected(id, not ns.IsCollected(id))
    elseif #entries > 1 then
        ns.ShowBookPicker(entries)
    end
end

function handler:OnLeave()
    GameTooltip:Hide()
end

local function initialize()
    local ace = LibStub and LibStub("AceAddon-3.0", true)
    HandyNotes = ace and ace:GetAddon("HandyNotes", true)
    if not HandyNotes or not HandyNotes.RegisterPluginDB or not C_Map or not C_Map.GetMapInfo then
        say("Eine passende HandyNotes-Version mit moderner Karten-API wird benötigt.")
        return
    end
    if type(HandyNotes_ForeverBooksDB) ~= "table" then HandyNotes_ForeverBooksDB = {} end
    ns.db = HandyNotes_ForeverBooksDB
    -- Validate saved settings after manual edits or version changes.
    for key, default in pairs(ns.defaults) do
        if type(ns.db[key]) ~= type(default) then ns.db[key] = default end
    end
    if not (ns.db.scale >= 0.5 and ns.db.scale <= 3) then ns.db.scale = ns.defaults.scale end
    if not (ns.db.alpha >= 0.2 and ns.db.alpha <= 1) then ns.db.alpha = ns.defaults.alpha end
    ns.InitTracking()

    local missing = {}
    for _, location in ipairs(ns.locations) do
        local map = location.map
        local info = C_Map.GetMapInfo(map)
        if info then
            -- Round percentage values once; e.g. 48.5/57.6 -> 48505760.
            local coord = math.floor(location.x * 100 + 0.5) * 10000 + math.floor(location.y * 100 + 0.5)
            lookup[map] = lookup[map] or {}
            local pin = lookup[map][coord]
            if not pin then
                pin = { map = map, coord = coord, x = location.x, y = location.y, entries = {} }
                lookup[map][coord] = pin
                nodes[map] = nodes[map] or {}
                nodes[map][#nodes[map] + 1] = pin
                if info.parentMapID == 1414 or info.parentMapID == 1415 then
                    continents[info.parentMapID] = continents[info.parentMapID] or {}
                    table.insert(continents[info.parentMapID], pin)
                end
            end
            table.insert(pin.entries, location)
        else
            missing[map] = true
        end
    end
    HandyNotes:RegisterPluginDB(pluginKey, handler, ns.MakeOptions())
    for map in pairs(missing) do say("Karte " .. map .. " fehlt in diesem Client; zugehörige Pins wurden ausgelassen.") end
    ns.Refresh()

    SLASH_FOREVERBOOKS1 = "/fbooks"
    SLASH_FOREVERBOOKS2 = "/foreverbooks"
    SlashCmdList.FOREVERBOOKS = function(message)
        message = (message or ""):lower():match("^%s*(.-)%s*$")
        if message == "map" then
            say("Aktuelle UiMapID: " .. tostring(C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")))
        elseif message == "status" then
            local _, _, _, interface = GetBuildInfo()
            local count = 0
            for id in pairs(ns.books) do if ns.IsCollected(id) then count = count + 1 end end
            say("Version 1.1.3 | Interface " .. tostring(interface) .. " | " .. count .. "/40 Bücher gefunden.")
        else
            say("Einstellungen: HandyNotes > Plugins > Forever Books. /fbooks map zeigt die Karten-ID; /fbooks status zeigt die Version.")
        end
    end
    return true
end

-- Wait until SavedVariables and HandyNotes/AceAddon initialization are complete.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        if initialize() then self:RegisterEvent("BAG_UPDATE_DELAYED") end
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.ScanBags()
    end
end)
