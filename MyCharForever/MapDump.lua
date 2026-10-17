local addonName, MCF = ...
-- /mcf mapdump: collects the exploration overlay tiles of the world map (size, offset, texture file IDs) so that
-- the website can draw fully painted zone maps. The game only reports overlays the character has discovered, so the
-- result is merged into the account-wide store: every character and every newly discovered area adds to it.
-- This is a diagnostic, not chronicle data: it is not part of the export and is not tracked per character.

local function de() return MCF:GetLanguage() == "deDE" end
local function out(msg) print("|cff00ccffMyCharForever|r: " .. msg) end

-- uiMapIDs of the zone, continent and city maps that carry exploration overlays or art (same list as Forever Map Fix).
local MAPS = {947,1411,1412,1413,1414,1415,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1427,1428,1429,1430,
    1431,1432,1433,1434,1435,1436,1437,1438,1439,1440,1441,1442,1443,1444,1445,1446,1447,1448,1449,1450,1451,1452,
    1453,1454,1455,1456,1457,1458,1460,1461,2482,2521,2524,2548,2652}

local function Store()
    local a = MCF:EnsureAccountDB()
    a.mapDump = a.mapDump or {}
    return a.mapDump
end

-- Reads every map once and merges new overlays into the store. Returns (new overlays, total overlays, maps seen).
local function Collect()
    local store = Store()
    local added, total, seen = 0, 0, 0
    store.layers = store.layers or {}
    store.overlays = store.overlays or {}
    for _, mapID in ipairs(MAPS) do
        local okL, layers = pcall(C_Map.GetMapArtLayers, mapID)
        if okL and type(layers) == "table" and layers[1] then
            local l = layers[1]
            store.layers[mapID] = string.format("%dx%d tile %dx%d", l.layerWidth or 0, l.layerHeight or 0, l.tileWidth or 0, l.tileHeight or 0)
        end
        local okO, list = pcall(C_MapExplorationInfo.GetExploredMapTextures, mapID)
        if okO and type(list) == "table" then
            seen = seen + 1
            local per = store.overlays[mapID] or {}
            store.overlays[mapID] = per
            for _, o in ipairs(list) do
                local ids = o.fileDataIDs
                if type(ids) == "table" and ids[1] then
                    local key = tostring(ids[1])
                    if not per[key] then
                        added = added + 1
                        per[key] = {w = o.textureWidth, h = o.textureHeight, x = o.offsetX, y = o.offsetY, ids = table.concat(ids, ",")}
                    end
                end
            end
        end
    end
    for _, per in pairs(store.overlays) do for _ in pairs(per) do total = total + 1 end end
    return added, total, seen
end

local function BuildText()
    local store = Store()
    local lines = {"MCFMAPDUMP1 build=" .. tostring(select(4, GetBuildInfo()) or "?")}
    local ids = {}
    for _, m in ipairs(MAPS) do ids[#ids + 1] = m end
    for _, mapID in ipairs(ids) do
        local layer = store.layers and store.layers[mapID]
        local per = store.overlays and store.overlays[mapID]
        if layer or per then
            lines[#lines + 1] = string.format("M %d %s", mapID, layer or "?")
            if per then
                local keys = {}
                for k in pairs(per) do keys[#keys + 1] = tonumber(k) or 0 end
                table.sort(keys)
                for _, k in ipairs(keys) do
                    local o = per[tostring(k)]
                    lines[#lines + 1] = string.format("O %d %s %s %s %s %s", mapID, tostring(o.w), tostring(o.h), tostring(o.x), tostring(o.y), tostring(o.ids))
                end
            end
        end
    end
    return table.concat(lines, "\n")
end

local window, editBox
local function ShowWindow(text)
    if not window then
        window = CreateFrame("Frame", "MyCharForeverMapDumpFrame", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(560, 420)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetMovable(true); window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        if MCF.MakeOpaque then MCF.MakeOpaque(window, 24) end
        window.TitleText:SetText("MyCharForever - Map data")
        window.info = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        window.info:SetPoint("TOPLEFT", 16, -32)
        window.info:SetPoint("TOPRIGHT", -16, -32)
        window.info:SetJustifyH("LEFT")
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -78)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)
        editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(500)
        editBox:SetMaxLetters(0)
        editBox:SetTextInsets(4, 4, 4, 4)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnTextChanged", function(self) MCF.FitEditBox(self, 300) end)
        scroll:SetScrollChild(editBox)
    end
    window.info:SetText(de()
        and "Strg+A, dann Strg+C zum Kopieren und den Text in die Antwort einfügen. Enthält nur Kartendaten, keine Charakter- oder Realmnamen."
        or "Press Ctrl+A, then Ctrl+C, and paste the text into your reply. It contains map data only, no character or realm names.")
    editBox:SetText(text)
    window:Show()
    editBox:SetFocus()
    editBox:HighlightText()
end

MCF:AddCommand{group = "debug", usage = "/mcf mapdump", key = "mapdump",
    de = "Entdeckte Kartenteile auslesen und zum Kopieren anzeigen (für die Karten im Chronik-Viewer, bitte Text schicken)",
    en = "Read the discovered map areas and show them for copying (for the maps in the chronicle viewer)",
    run = function()
        if not (C_Map and C_Map.GetMapArtLayers and C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures) then
            out(de() and "Diese Spielversion bietet die Kartenfunktionen nicht an." or "This game version does not offer the map functions.")
            return
        end
        local added, total, seen = Collect()
        out(string.format(de() and "%d Karten gelesen, %d neue Kartenteile, insgesamt %d gesammelt." or "%d maps read, %d new map areas, %d collected in total.", seen, added, total))
        ShowWindow(BuildText())
    end}
