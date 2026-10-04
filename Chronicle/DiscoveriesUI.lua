local C = _G.Chronicle
local U = C.Util
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local GOLD, TEXT, MUTED = { 1, .82, .1 }, { .96, .91, .78 }, { .72, .65, .52 }
local GREEN, BLUE = { .47, .84, .46 }, { .45, .73, .96 }
local icons = {
    ore = "Interface\\Icons\\INV_Ore_Copper_01",
    herbs = "Interface\\Icons\\INV_Misc_Herb_01",
    skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    training = "Interface\\Icons\\INV_Misc_Book_09",
}
local professionArt = { ore = "Mining", herbs = "Herbalism", skinning = "Skinning" }
local ui = { mode = "gather", query = "", trainerFilter = "all",
    gatherFilter = "all", rows = {}, trainerRows = {}, knowledgeRows = {}, knowledgeSelection = {},
    filters = {}, metrics = {}, selection = {},
    trainerCollapsed = { later = true, used = true } }

local function font(parent, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(C:FontPath(), size)
    label:SetTextColor(unpack(color or TEXT))
    label:SetJustifyH("LEFT")
    return label
end

local function panel(frame, red, green, blue)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = BORDER, tile = false, edgeSize = 13,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(red or .16, green or .105, blue or .052, 1)
    frame:SetBackdropBorderColor(.59, .44, .17, 1)
    C:ApplyMaterial(frame, .28)
    C:OrnateCorners(frame)
end

local function openPanel(frame)
    frame:SetBackdrop(nil)
    if frame.chronicleMaterial then frame.chronicleMaterial:Hide() end
    if frame.chronicleCorners then
        for _, mark in ipairs(frame.chronicleCorners) do mark:Hide() end
    end
end

local function resetDisplay()
    for _, row in ipairs(ui.rows) do row:Hide() end
    for _, row in ipairs(ui.trainerRows) do row:Hide() end
    for _, row in ipairs(ui.knowledgeRows) do row:Hide() end
    if ui.knowledgeDossier then ui.knowledgeDossier:Hide() end
    for _, metric in ipairs(ui.metrics) do metric:Hide() end
    for _, filter in ipairs(ui.filters) do filter:Hide() end
    for _, card in ipairs(ui.scoreCards or {}) do card:Hide() end
    for _, button in ipairs(ui.weaponLocations or {}) do button:Hide() end
    if ui.weaponLocationHeading then ui.weaponLocationHeading:Hide() end
    if ui.dossier then ui.dossier:Hide() end
    if ui.empty then ui.empty:Hide() end
    if ui.section then ui.section:Hide() end
    if ui.gatherHeading then ui.gatherHeading:Hide() end
    if ui.gatherCount then ui.gatherCount:Hide() end
    if ui.heroStats then ui.heroStats:Hide() end
end

function C:HideDiscoveries()
    resetDisplay()
    if ui.hero then ui.hero:Hide() end
    if ui.search then ui.search:Hide() end
end

local function addEntry(rows, kind, title, detail, body, target, icon)
    rows[#rows + 1] = { kind = kind, title = title, detail = detail, body = body,
        target = target, icon = icon or icons[kind] }
end

local function gatheringScore(entries, kind)
    local total, types, records = 0, 0, 0
    for itemID, entry in pairs(entries or {}) do
        if type(entry) == "table" and C:IsGatheringMaterial(kind, itemID, entry.name) then
            total = total + (entry.count or 0)
            types = types + 1
            records = records + (entry.best or 0)
        end
    end
    local points = total + types * 25 + records * 3
    local rank = points >= 1200 and "Meister" or
        (points >= 450 and "Kenner" or (points >= 100 and "Entdecker" or "Anfänger"))
    local nextGoal = points < 100 and 100 or (points < 450 and 450 or (points < 1200 and 1200 or 1200))
    local progress = points >= 1200 and 1 or points / nextGoal
    return points, rank, total, types, progress
end

local function gatherEntries()
    local rows = {}
    local data = C.char and C.char.gathering or {}
    for _, kind in ipairs({ "ore", "herbs", "skinning" }) do
        for itemID, entry in pairs(data[kind] or {}) do
            if type(entry) == "table" and C:IsGatheringMaterial(kind, itemID, entry.name) then
                local name = entry.name and entry.name ~= "" and entry.name or (C:LocalizeDisplay("Gegenstand ") .. itemID)
                addEntry(rows, kind, name, (entry.count or 0) .. C:LocalizeDisplay(" gesammelt  •  Bestfund ") ..
                    (entry.best or 0), C:LocalizeDisplay("GESAMMELT") .. "\n" .. (entry.count or 0) .. C:LocalizeDisplay(" Stück") .. "\n\n" ..
                    C:LocalizeDisplay("BESTER FUND") .. "\n" .. (entry.best or 0) .. C:LocalizeDisplay(" Stück") .. "\n\n" ..
                    C:LocalizeDisplay("ZULETZT GEFUNDEN") .. "\n" .. U.Date(entry.lastSeen), nil,
                    (GetItemIcon and GetItemIcon(itemID)) or icons[kind])
                rows[#rows].amount = entry.count or 0
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.amount ~= b.amount then return a.amount > b.amount end
        return a.title < b.title
    end)
    return rows
end

local function trainerEntries()
    local rows = {}
    local training = C.char and C.char.training or {}
    local playerLevel = UnitLevel and (tonumber(UnitLevel("player")) or 0) or 0
    if training.services and not training.normalizedRanks then
        local cleaned = {}
        for _, spell in pairs(training.services) do
            if type(spell) == "table" and spell.name then
                if spell.rank == "available" or spell.rank == "unavailable" or
                    spell.rank == "used" then spell.rank = nil end
                local key = spell.name .. "\031" .. (spell.rank or "")
                if not cleaned[key] or (spell.lastSeen or 0) >= (cleaned[key].lastSeen or 0) then
                    cleaned[key] = spell
                end
            end
        end
        training.services = cleaned
        training.normalizedRanks = true
    end
    local combined, observedByID = {}, {}
    for key, spell in pairs(training.services or {}) do
        combined[key] = spell
        if type(spell) == "table" and spell.spellID then observedByID[spell.spellID] = spell end
    end
    for _, catalog in ipairs(C.GetTrainerCatalogEntries and C:GetTrainerCatalogEntries() or {}) do
        local key = catalog.name .. "\031" .. (catalog.rank or "")
        local observed = observedByID[catalog.spellID] or combined[key]
        if not observed then
            combined[key] = catalog
        elseif observed.spellID == catalog.spellID or observed.name == catalog.name then
            combined[key] = {
                name = catalog.name, rank = catalog.rank or observed.rank,
                level = (tonumber(observed.level) or 0) > 0 and observed.level or catalog.level,
                cost = observed.cost,
                status = observed.status, icon = observed.icon or catalog.icon,
                spellID = catalog.spellID, source = "trainer",
            }
            if observed ~= combined[key] then
                for oldKey, candidate in pairs(combined) do
                    if oldKey ~= key and candidate == observed then combined[oldKey] = nil end
                end
            end
        end
    end
    local highestKnownRank = {}
    for _, spell in pairs(combined) do
        if type(spell) == "table" and spell.name then
            local known = spell.status == "used"
            if spell.spellID and IsSpellKnown then
                local ok, result = pcall(IsSpellKnown, spell.spellID)
                known = known or (ok and result or false)
            end
            local number = spell.rank and tonumber(spell.rank:match("(%d+)"))
            if known and number then
                highestKnownRank[spell.name] = math.max(highestKnownRank[spell.name] or 0, number)
            end
        end
    end
    for _, spell in pairs(combined) do
        if type(spell) == "table" and spell.name then
            local level = tonumber(spell.level) or 0
            local known = false
            if spell.spellID and IsSpellKnown then
                local ok, result = pcall(IsSpellKnown, spell.spellID)
                known = ok and result or false
            end
            local rankNumber = spell.rank and tonumber(spell.rank:match("(%d+)"))
            if rankNumber and rankNumber <= (highestKnownRank[spell.name] or 0) then known = true end
            local kind = (known or spell.status == "used") and "used" or
                (spell.status == "available" and "available" or
                (level > playerLevel and "unavailable" or
                (spell.source == "catalog" and "preview" or "check")))
            local status = kind == "available" and C:LocalizeDisplay("Jetzt lernbar") or
                (kind == "used" and C:LocalizeDisplay("Bekannt") or
                (kind == "check" and "Beim Trainer prüfen" or
                (kind == "preview" and C:LocalizeDisplay("Katalog-Vorschau") or C:LocalizeDisplay("Ab Stufe ") .. level)))
            local price = spell.cost ~= nil and U.Money(spell.cost) or C:LocalizeDisplay("Preis noch nicht erfasst")
            local rank = spell.rank and spell.rank ~= "" and not ({ available = true,
                unavailable = true, used = true })[spell.rank] and " " .. spell.rank or ""
            local detail = status
            if spell.source == "catalog" then
                if kind == "preview" or kind == "used" then detail = detail .. C:LocalizeDisplay("  •  Stufe ") .. level end
            else
                detail = detail .. "  •  " .. price
            end
            addEntry(rows, kind, spell.name .. rank, detail,
                (spell.source == "catalog" and
                    C:LocalizeDisplay("Forever-Zauberkatalog. Ob dieser Zauber beim Klassentrainer angeboten wird, ist noch nicht bestätigt.") or
                    C:LocalizeDisplay("Erfasst bei ") .. U.SafeText(training.trainer, C:LocalizeDisplay("Klassentrainer")) ..
                    C:LocalizeDisplay(" in ") .. U.SafeText(training.zone, C:LocalizeDisplay("unbekanntem Gebiet")) .. ".") ..
                C:LocalizeDisplay("\nLernstufe: ") .. level .. "\n" .. price .. ".", nil,
                spell.icon or icons.training)
            rows[#rows].level, rows[#rows].cost = level, spell.cost
            rows[#rows].spellID = spell.spellID
            rows[#rows].source = spell.source
        end
    end
    local priority = { available = 1, check = 2, preview = 3, unavailable = 4, used = 5 }
    table.sort(rows, function(a, b)
        if (priority[a.kind] or 4) ~= (priority[b.kind] or 4) then
            return (priority[a.kind] or 4) < (priority[b.kind] or 4)
        end
        if a.level ~= b.level then return a.level < b.level end
        return a.title < b.title
    end)
    return rows
end

local function makeMetric(parent, index)
    local card = ui.metrics[index]
    if card then return card end
    card = CreateFrame("Frame", nil, parent)
    card.number = font(card, 23, GOLD); card.number:SetPoint("TOPLEFT", 3, -3)
    card.label = font(card, 10, MUTED); card.label:SetPoint("TOPLEFT", 4, -34)
    card.rule = card:CreateTexture(nil, "ARTWORK")
    card.rule:SetTexture(WHITE); card.rule:SetVertexColor(.36, .25, .1, .75)
    card.rule:SetPoint("BOTTOMLEFT", 2, 1); card.rule:SetPoint("BOTTOMRIGHT", -2, 1)
    card.rule:SetHeight(1)
    ui.metrics[index] = card
    return card
end

local function showMetric(parent, index, x, y, width, number, label)
    local card = makeMetric(parent, index)
    card:ClearAllPoints(); card:SetPoint("TOPLEFT", x, y); card:SetSize(width, 57)
    card.number:SetFont(C:FontPath(), label == "KOSTEN JETZT" and 17 or 23)
    card.number:SetText(tostring(number)); card.label:SetText(C:LocalizeDisplay(label))
    card.number:SetWidth(width - 8); card.label:SetWidth(width - 8)
    card:Show()
end

local function makeFilter(parent, index)
    local button = ui.filters[index]
    if button then return button end
    button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button.label = font(button, 10, TEXT); button.label:SetPoint("CENTER")
    C:StyleChronicleButton(button)
    button:SetScript("OnClick", function(self)
        if ui.mode == "gather" then ui.gatherFilter = self.value
        else ui.trainerFilter = self.value end
        ui.selection[ui.mode] = 1
        C:ShowDiscoveries(ui.parent, ui.width)
    end)
    ui.filters[index] = button
    return button
end

local function showFilters(parent, options, y, width, current)
    local gap = 7
    local buttonWidth = math.floor((width - gap * (#options - 1)) / #options)
    for index, option in ipairs(options) do
        local button = makeFilter(parent, index)
        button.value = option[1]
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 4 + (index - 1) * (buttonWidth + gap), y)
        button:SetSize(buttonWidth, 24)
        button:SetBackdrop({ bgFile = WHITE, edgeFile = BORDER, tile = false, edgeSize = 11,
            insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        local active = option[1] == current
        C:StyleChronicleButton(button, active)
        button.label:SetText(C:LocalizeDisplay(option[2])); button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:Show()
    end
end

local function showSpellTooltip(owner)
    local entry = owner.entry
    if not entry or not entry.spellID or not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
    local shown = false
    if GameTooltip.SetSpellByID then
        shown = pcall(GameTooltip.SetSpellByID, GameTooltip, entry.spellID)
    end
    if not shown and GameTooltip.SetHyperlink then
        shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. entry.spellID)
    end
    if not shown then GameTooltip:SetText(C:LocalizeDisplay(entry.title), 1, .82, .1) end
    GameTooltip:AddLine("Chronicle: " .. C:LocalizeDisplay(entry.detail), .72, .65, .52, true)
    C:ShowLocalizedTooltip()
end

local function hideSpellTooltip(owner)
    if owner.entry and owner.entry.spellID and GameTooltip then GameTooltip:Hide() end
end

local function makeRow(parent, index)
    local row = ui.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, parent)
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetTexture(WHITE); row.highlight:SetAllPoints(row)
    row.highlight:SetVertexColor(.25, .16, .055, .8); row.highlight:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(30, 30); row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetTexCoord(.07, .93, .07, .93)
    row.title = font(row, 12, TEXT); row.title:SetPoint("TOPLEFT", 47, -7)
    row.detail = font(row, 9, MUTED); row.detail:SetPoint("TOPLEFT", 48, -27)
    row.rule = row:CreateTexture(nil, "ARTWORK")
    row.rule:SetTexture(WHITE); row.rule:SetVertexColor(.36, .25, .1, .75)
    row.rule:SetPoint("BOTTOMLEFT", 46, 1); row.rule:SetPoint("BOTTOMRIGHT", -4, 1)
    row.rule:SetHeight(1)
    row:SetScript("OnClick", function(self)
        if self.heading then return end
        ui.selection[ui.mode] = self.index
        C:ShowDiscoveries(ui.parent, ui.width)
    end)
    row:SetScript("OnEnter", showSpellTooltip)
    row:SetScript("OnLeave", hideSpellTooltip)
    ui.rows[index] = row
    return row
end

local function showRows(parent, entries, x, y, width, selected, limit)
    local offset = 0
    for index, entry in ipairs(entries) do
        if index > (limit or 100) then break end
        local row = makeRow(parent, index)
        row.index, row.heading, row.entry = index, entry.heading, entry
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", x, y - offset)
        row:SetSize(width, entry.heading and 30 or 48)
        offset = offset + (entry.heading and 31 or 49)
        row.icon:SetShown(not entry.heading)
        row.icon:SetTexture(entry.icon or icons.training)
        row.title:SetText(C:LocalizeDisplay(entry.title)); row.title:SetWidth(width - (entry.heading and 16 or 59))
        row.title:ClearAllPoints()
        row.title:SetPoint("TOPLEFT", entry.heading and 8 or 47, -7)
        row.detail:SetShown(not entry.heading)
        row.detail:SetText(C:LocalizeDisplay(entry.detail)); row.detail:SetWidth(width - 59)
        row.highlight:SetShown(index == selected and not entry.heading)
        row.title:SetTextColor(unpack((entry.heading or index == selected) and GOLD or TEXT))
        row:Show()
    end
    return offset
end

local function makeDossier(parent)
    if ui.dossier then return ui.dossier end
    local dossier = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel(dossier)
    dossier.caption = font(dossier, 10, GOLD); dossier.caption:SetPoint("TOPLEFT", 18, -17)
    dossier.icon = dossier:CreateTexture(nil, "ARTWORK")
    dossier.icon:SetSize(46, 46); dossier.icon:SetPoint("TOPRIGHT", -18, -17)
    dossier.icon:SetTexCoord(.07, .93, .07, .93)
    dossier.iconTip = CreateFrame("Button", nil, dossier)
    dossier.iconTip:SetAllPoints(dossier.icon)
    dossier.iconTip:SetScript("OnEnter", showSpellTooltip)
    dossier.iconTip:SetScript("OnLeave", hideSpellTooltip)
    dossier.title = font(dossier, 21, TEXT); dossier.title:SetPoint("TOPLEFT", 18, -47)
    dossier.meta = font(dossier, 11, MUTED); dossier.meta:SetPoint("TOPLEFT", 20, -91)
    dossier.rule = dossier:CreateTexture(nil, "ARTWORK")
    dossier.rule:SetTexture(WHITE); dossier.rule:SetVertexColor(.6, .4, .14, .8)
    dossier.rule:SetPoint("TOPLEFT", 18, -119); dossier.rule:SetPoint("TOPRIGHT", -18, -119)
    dossier.rule:SetHeight(1)
    dossier.body = font(dossier, 12, TEXT); dossier.body:SetPoint("TOPLEFT", 20, -140)
    dossier.body:SetJustifyV("TOP")
    dossier.button = CreateFrame("Button", nil, dossier, "BackdropTemplate")
    dossier.button:SetPoint("BOTTOMLEFT", 18, 17); dossier.button:SetPoint("BOTTOMRIGHT", -18, 17)
    dossier.button:SetHeight(26)
    dossier.button:SetBackdrop({ bgFile = WHITE, edgeFile = BORDER, tile = false,
        edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    dossier.button:SetBackdropColor(.24, .15, .052, 1)
    dossier.button:SetBackdropBorderColor(.62, .45, .16, 1)
    dossier.button.label = font(dossier.button, 11, GOLD)
    dossier.button.label:SetPoint("CENTER")
    C:StyleChronicleButton(dossier.button)
    dossier.button:SetScript("OnClick", function(self)
        if self.target then C:ShowPage(self.target) end
    end)
    ui.dossier = dossier
    return dossier
end

local function showDossier(parent, entry, x, y, width, height)
    local dossier = makeDossier(parent)
    dossier:ClearAllPoints(); dossier:SetPoint("TOPLEFT", x, y)
    dossier:SetSize(width, height)
    dossier.caption:SetText(C:LocalizeDisplay(entry.kind == "quests" and "CHRONICLE  /  QUEST" or
        (entry.kind == "places" and "CHRONICLE  /  ENTDECKUNG" or
        (entry.kind == "dungeons" and "CHRONICLE  /  INSTANZ" or
        (entry.kind == "loot" and "CHRONICLE  /  FUNDSTÜCK" or
        (entry.kind == "professions" and "CHRONICLE  /  REZEPT" or
        (entry.kind == "ore" and "CHRONICLE  /  ERZFUND" or
        (entry.kind == "herbs" and "CHRONICLE  /  KRÄUTERFUND" or
        (entry.kind == "skinning" and "CHRONICLE  /  KÜRSCHNERFUND" or "CHRONICLE  /  ZAUBER")))))))))
    dossier.icon:SetTexture(entry.icon or icons.training)
    dossier.iconTip.entry = entry
    dossier.iconTip:SetShown(entry.spellID ~= nil)
    dossier.title:SetFont(C:FontPath(), #entry.title > 28 and 17 or 21)
    dossier.title:SetText(C:LocalizeDisplay(entry.title)); dossier.title:SetWidth(width - 95)
    dossier.meta:SetText(C:LocalizeDisplay(entry.detail)); dossier.meta:SetWidth(width - 37)
    dossier.body:SetText(C:LocalizeDisplay(entry.body or "")); dossier.body:SetWidth(width - 40)
    dossier.button.target = entry.target
    dossier.button.label:SetText(entry.target and C:LocalizeDisplay("Chronicle-Rubrik öffnen") or C:LocalizeDisplay("Aus deinem Journal erfasst"))
    dossier.button:SetShown(entry.target ~= nil)
    dossier:Show()
end

local function showEmpty(parent, x, y, width, title, detail)
    if not ui.empty then
        ui.empty = CreateFrame("Frame", nil, parent)
        ui.empty.title = font(ui.empty, 17, GOLD)
        ui.empty.title:SetPoint("TOPLEFT", 0, -5)
        ui.empty.detail = font(ui.empty, 11, MUTED)
        ui.empty.detail:SetPoint("TOPLEFT", 1, -37)
    end
    ui.empty:ClearAllPoints(); ui.empty:SetPoint("TOPLEFT", x, y)
    ui.empty:SetSize(width, 105)
    ui.empty.title:SetText(C:LocalizeDisplay(title)); ui.empty.detail:SetText(C:LocalizeDisplay(detail))
    ui.empty.detail:SetWidth(width)
    ui.empty:Show()
end

local function filtered(entries, key)
    local result, query = {}, ui.query
    for _, entry in ipairs(entries) do
        local matchesCategory = key == "all" or entry.kind == key or
            (key == "preview" and entry.source == "catalog" and entry.kind ~= "used")
        if matchesCategory and (query == "" or
            entry.title:lower():find(query, 1, true) or entry.detail:lower():find(query, 1, true)) then
            result[#result + 1] = entry
        end
    end
    return result
end

local function showGather(parent, width)
    local data = C.char and C.char.gathering or {}
    local session = C.gatherSession or {}
    local orePoints, oreRank, oreTotal, oreTypes, oreProgress = gatheringScore(data.ore, "ore")
    local herbPoints, herbRank, herbTotal, herbTypes, herbProgress = gatheringScore(data.herbs, "herbs")
    local skinPoints, skinRank, skinTotal, skinTypes, skinProgress = gatheringScore(data.skinning, "skinning")
    local nodes = (data.oreNodes or 0) + (data.herbNodes or 0) + (data.skinNodes or 0)
    local sessionNodes = (session.ore or 0) + (session.herbs or 0) + (session.skinning or 0)
    local elapsed = math.max(1, time() - (session.started or time()))
    local rate = elapsed >= 60 and math.floor((session.nodes or 0) * 3600 / elapsed + .5) or "–"
    ui.heroStats:SetText(nodes .. C:LocalizeDisplay(" SAMMELAKTIONEN    |    ") .. sessionNodes ..
        C:LocalizeDisplay(" STÜCK DIESE SITZUNG    |    ") .. rate .. C:LocalizeDisplay(" AKTIONEN / STUNDE"))
    ui.heroStats:Show()
    ui.hero:SetHeight(112)

    if not ui.scoreCards then ui.scoreCards = {} end
    local cardWidth = math.floor((width - 20) / 3)
    for index, spec in ipairs({ { "ore", "BERGBAU", orePoints, oreRank, oreTotal, oreTypes, oreProgress },
        { "herbs", "KRÄUTERKUNDE", herbPoints, herbRank, herbTotal, herbTypes, herbProgress },
        { "skinning", "KÜRSCHNEREI", skinPoints, skinRank, skinTotal, skinTypes, skinProgress } }) do
        local card = ui.scoreCards[index]
        if not card then
            card = CreateFrame("Button", nil, parent, "BackdropTemplate")
            openPanel(card)
            card.accent = card:CreateTexture(nil, "ARTWORK")
            card.accent:SetTexture(WHITE)
            card.accent:SetPoint("TOPLEFT", 3, -8)
            card.accent:SetPoint("BOTTOMLEFT", 3, 8)
            card.accent:SetWidth(3)
            card.art = card:CreateTexture(nil, "ARTWORK")
            card.art:SetPoint("TOPRIGHT", -5, -1)
            card.name = font(card, 10, GOLD); card.name:SetPoint("TOPLEFT", 15, -16)
            card.rank = font(card, 18, TEXT); card.rank:SetPoint("TOPLEFT", 15, -34)
            card.score = font(card, 9, MUTED); card.score:SetPoint("TOPLEFT", 15, -78)
            card.next = font(card, 10, GOLD); card.next:SetPoint("TOPLEFT", 15, -99)
            card.track = card:CreateTexture(nil, "ARTWORK")
            card.track:SetTexture(WHITE); card.track:SetVertexColor(.25, .18, .09, 1)
            card.track:SetPoint("BOTTOMLEFT", 18, 12); card.track:SetHeight(5)
            card.bar = card:CreateTexture(nil, "OVERLAY")
            card.bar:SetTexture(WHITE); card.bar:SetPoint("BOTTOMLEFT", 18, 12)
            card.bar:SetHeight(5)
            card:SetScript("OnClick", function(self)
                ui.gatherFilter = self.kind
                ui.selection.gather = 1
                C:ShowDiscoveries(ui.parent, ui.width)
            end)
            card:SetScript("OnEnter", function(self)
                self.accent:SetVertexColor(1, .82, .1, 1)
            end)
            card:SetScript("OnLeave", function(self)
                self.accent:SetVertexColor(self.active and 1 or .59,
                    self.active and .72 or .44, .17, self.active and 1 or .5)
            end)
            ui.scoreCards[index] = card
        end
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4 + (index - 1) * (cardWidth + 8), -126)
        card:SetSize(cardWidth, 132)
        card.kind = spec[1]
        card.active = ui.gatherFilter == spec[1]
        card.accent:SetVertexColor(card.active and 1 or .59, card.active and .72 or .44, .17, card.active and 1 or .5)
        card.art:SetTexture("Interface\\AddOns\\Chronicle\\Profession_" .. professionArt[spec[1]])
        local artSize = math.min(132, math.max(62, cardWidth - 212))
        card.art:SetSize(artSize, artSize)
        card.art:SetAlpha(cardWidth >= 300 and .7 or .4)
        card.name:SetText(C:LocalizeDisplay(spec[2])); card.rank:SetText(C:LocalizeDisplay(spec[4]))
        card.score:SetText(spec[3] .. C:LocalizeDisplay(" Punkte    •    ") .. spec[5] .. C:LocalizeDisplay(" Stück    •    ") .. spec[6] .. C:LocalizeDisplay(" Arten"))
        card.score:SetWidth(cardWidth - 30)
        local goal = spec[3] < 100 and 100 or (spec[3] < 450 and 450 or (spec[3] < 1200 and 1200 or nil))
        card.next:SetText(goal and (spec[3] .. " / " .. goal) or C:LocalizeDisplay("MAX. RANG"))
        card.track:SetWidth(cardWidth - 36)
        card.bar:SetWidth(math.max(3, (cardWidth - 36) * spec[7]))
        card.bar:SetVertexColor(spec[1] == "ore" and .88 or (spec[1] == "herbs" and .46 or .72),
            spec[1] == "ore" and .58 or (spec[1] == "herbs" and .77 or .59),
            spec[1] == "ore" and .18 or (spec[1] == "herbs" and .32 or .38), 1)
        card:Show()
    end
    showFilters(parent, { { "all", "Alle Funde" }, { "ore", "Erze" },
        { "herbs", "Kräuter" }, { "skinning", "Kürschnerei" } }, -273, width, ui.gatherFilter)
    ui.search:ClearAllPoints(); ui.search:SetPoint("TOPLEFT", 8, -308)
    ui.search:SetWidth(math.min(340, width - 16)); ui.search:Show()
    local entries = filtered(gatherEntries(), ui.gatherFilter)
    if not ui.gatherHeading then
        ui.gatherHeading = font(parent, 11, GOLD)
        ui.gatherCount = font(parent, 10, MUTED)
        ui.gatherCount:SetJustifyH("RIGHT")
    end
    ui.gatherHeading:ClearAllPoints(); ui.gatherHeading:SetPoint("TOPLEFT", 10, -347)
    ui.gatherHeading:SetText(ui.gatherFilter == "ore" and C:LocalizeDisplay("DEINE ERZFUNDSTÜCKE") or
        (ui.gatherFilter == "herbs" and C:LocalizeDisplay("DEINE KRÄUTERFUNDE") or
        (ui.gatherFilter == "skinning" and C:LocalizeDisplay("DEINE KÜRSCHNERFUNDE") or C:LocalizeDisplay("DEINE FUNDE"))))
    ui.gatherHeading:Show()
    ui.gatherCount:ClearAllPoints(); ui.gatherCount:SetPoint("TOPRIGHT", -12, -347)
    ui.gatherCount:SetText(#entries .. C:LocalizeDisplay(" ARTEN IN DIESER AUSWAHL"))
    ui.gatherCount:Show()
    if #entries == 0 then
        showEmpty(parent, 14, -390, width - 30, "Deine erste Sammelstelle wartet",
            "Nach einem Erz-, Kräuter- oder Kürschnerfund erscheinen hier Menge, Bestfund und Rang.")
        parent:SetHeight(620)
        return
    end
    local selected = math.min(ui.selection.gather or 1, #entries)
    ui.selection.gather = selected
    local listWidth = math.floor(width * .52)
    local listHeight = showRows(parent, entries, 5, -379, listWidth, selected)
    showDossier(parent, entries[selected], listWidth + 16, -379, width - listWidth - 20, 248)
    parent:SetHeight(math.max(620, 385 + listHeight + 36))
end

local function makeTrainerRow(parent, index)
    local row = ui.trainerRows[index]
    if row then return row end
    row = CreateFrame("Button", nil, parent)
    row.band = row:CreateTexture(nil, "BACKGROUND")
    row.band:SetTexture(WHITE); row.band:SetAllPoints(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(27, 27); row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetTexCoord(.07, .93, .07, .93)
    row.title = font(row, 12, TEXT)
    row.title:SetPoint("LEFT", 46, 0)
    row.level = font(row, 11, GOLD)
    row.level:SetJustifyH("RIGHT")
    row.price = font(row, 11, MUTED)
    row.price:SetJustifyH("RIGHT")
    row.count = font(row, 10, MUTED)
    row.count:SetJustifyH("CENTER")
    row.chevron = font(row, 14, GOLD)
    row.chevron:SetPoint("LEFT", 12, 0)
    row.rule = row:CreateTexture(nil, "ARTWORK")
    row.rule:SetTexture(WHITE); row.rule:SetVertexColor(.36, .25, .1, .35)
    row.rule:SetPoint("BOTTOMLEFT", 44, 0); row.rule:SetPoint("BOTTOMRIGHT", -4, 0)
    row.rule:SetHeight(1)
    row:SetScript("OnEnter", function(self)
        self.band:SetVertexColor(.36, .23, .07, .72)
        showSpellTooltip(self)
    end)
    row:SetScript("OnLeave", function(self)
        self.band:SetVertexColor(.16, .1, .045, self.heading and .94 or .26)
        hideSpellTooltip(self)
    end)
    row:SetScript("OnClick", function(self)
        if not self.heading or not self.groupKey then return end
        ui.trainerCollapsed[self.groupKey] = not ui.trainerCollapsed[self.groupKey]
        C:ShowDiscoveries(ui.parent, ui.width)
    end)
    ui.trainerRows[index] = row
    return row
end

local function showTraining(parent, width)
    local all = trainerEntries()
    local counts, nextLevel = { available = 0, check = 0, preview = 0, unavailable = 0, used = 0 }, nil
    for _, entry in ipairs(all) do
        counts[entry.kind] = (counts[entry.kind] or 0) + 1
        if entry.kind == "unavailable" and (not nextLevel or entry.level < nextLevel) then
            nextLevel = entry.level
        end
    end
    showMetric(parent, 1, 9, -106, math.floor((width - 30) / 3), counts.available, "JETZT LERNBAR")
    showMetric(parent, 2, math.floor(width / 3) + 4, -106, math.floor((width - 30) / 3),
        nextLevel and ("Stufe " .. nextLevel) or "–", "NÄCHSTE FREISCHALTUNG")
    showMetric(parent, 3, math.floor(width * 2 / 3), -106, math.floor((width - 30) / 3),
        counts.used, "BEKANNT")
    showFilters(parent, { { "all", "Alle" }, { "available", "Jetzt" },
        { "check", "Prüfen" }, { "preview", "Vorschau" },
        { "unavailable", "Später" }, { "used", "Bekannt" } }, -178, width, ui.trainerFilter)
    ui.search:ClearAllPoints(); ui.search:SetPoint("TOPLEFT", 8, -214)
    ui.search:SetWidth(math.min(340, width - 16)); ui.search:Show()
    local matched = filtered(all, ui.trainerFilter)
    if #matched == 0 then
        showEmpty(parent, 14, -266, width - 30,
            ui.trainerFilter == "check" and "Nichts beim Trainer zu prüfen" or
                "Keine Zauber in dieser Auswahl",
            ui.trainerFilter == "check" and "Unbestätigte Klassenzauber findest du unter Vorschau." or
                (ui.trainerFilter == "preview" and "Alle Katalogeinträge sind bereits bekannt oder beim Trainer bestätigt." or
                "Weitere Angebote ergänzt Chronicle beim Besuch eines Klassentrainers."))
        parent:SetHeight(573)
        return
    end
    local groups = {}
    for _, entry in ipairs(matched) do
        local key, title
        if entry.kind == "available" then key, title = "available", "JETZT LERNBAR"
        elseif entry.kind == "check" then key, title = "check", "BEIM TRAINER PRÜFEN"
        elseif entry.kind == "preview" then key, title = "preview", "KATALOG-VORSCHAU"
        elseif entry.kind == "unavailable" and entry.level == nextLevel then
            key, title = "soon", C:LocalizeDisplay("BALD VERFÜGBAR  ·  STUFE ") .. entry.level
        elseif entry.kind == "unavailable" then key, title = "later", "NOCH NICHT VERFÜGBAR"
        else key, title = "used", "BEREITS BEKANNT" end
        if not groups[key] then
            groups[key] = { title = title, entries = {}, cost = 0, priced = 0 }
        end
        local group = groups[key]
        group.entries[#group.entries + 1] = entry
        if entry.cost then group.cost = group.cost + entry.cost; group.priced = group.priced + 1 end
    end
    local rowIndex, offset = 0, 262
    local levelX = width - 240
    for _, key in ipairs({ "available", "soon", "check", "preview", "later", "used" }) do
        local group = groups[key]
        if group then
        rowIndex = rowIndex + 1
        local heading = makeTrainerRow(parent, rowIndex)
        heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 5, -offset)
        heading:SetSize(width - 10, 28)
        heading.heading, heading.entry, heading.groupKey = true, nil, key
        local expanded = ui.query ~= "" or not ui.trainerCollapsed[key]
        heading.band:SetVertexColor(.16, .1, .045, .94)
        heading.icon:Hide(); heading.rule:Hide(); heading.level:Hide()
        heading.chevron:SetText(expanded and "-" or "+"); heading.chevron:Show()
        heading.title:ClearAllPoints(); heading.title:SetPoint("LEFT", 32, 0)
        heading.title:SetText(C:LocalizeDisplay(group.title)); heading.title:SetTextColor(unpack(GOLD))
        heading.title:SetWidth(levelX - 20)
        heading.count:ClearAllPoints(); heading.count:SetPoint("LEFT", levelX, 0)
        heading.count:SetWidth(100); heading.count:SetText(#group.entries .. C:LocalizeDisplay(" ZAUBER"))
        heading.count:Show()
        heading.price:ClearAllPoints(); heading.price:SetPoint("RIGHT", -9, 0)
        heading.price:SetWidth(105)
        heading.price:SetText(group.priced > 0 and U.Money(group.cost) or C:LocalizeDisplay("PREIS OFFEN"))
        heading:Show()
        offset = offset + 31
        if expanded then
        for _, entry in ipairs(group.entries) do
            rowIndex = rowIndex + 1
            local row = makeTrainerRow(parent, rowIndex)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 5, -offset)
            row:SetSize(width - 10, 37)
            row.heading, row.entry, row.groupKey = false, entry, nil
            row.band:SetVertexColor(.16, .1, .045, .26)
            row.chevron:Hide()
            row.icon:SetTexture(entry.icon or icons.training); row.icon:Show()
            row.title:ClearAllPoints(); row.title:SetPoint("LEFT", 46, 0)
            row.title:SetText(C:LocalizeDisplay(entry.title)); row.title:SetTextColor(unpack(TEXT))
            row.title:SetWidth(levelX - 53)
            row.level:ClearAllPoints(); row.level:SetPoint("LEFT", levelX, 0)
            row.level:SetWidth(100)
            row.level:SetText(entry.level > 0 and (C:LocalizeDisplay("Stufe ") .. entry.level) or C:LocalizeDisplay("Stufe offen"))
            row.level:SetTextColor(unpack(key == "later" and { 1, .46, .34 } or GOLD))
            row.level:Show()
            row.price:ClearAllPoints(); row.price:SetPoint("RIGHT", -9, 0)
            row.price:SetWidth(105)
            row.price:SetText(entry.cost and U.Money(entry.cost) or C:LocalizeDisplay("Preis offen"))
            row.count:Hide(); row.rule:Show(); row:Show()
            offset = offset + 38
        end
        end
        offset = offset + 7
        end
    end
    parent:SetHeight(math.max(613, offset + 18))
end

local function knowledgeRow(parent, index)
    local row = ui.knowledgeRows[index]
    if row then return row end
    row = CreateFrame("Button", nil, parent)
    row.band = row:CreateTexture(nil, "BACKGROUND")
    row.band:SetTexture(WHITE); row.band:SetAllPoints(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(27, 27); row.icon:SetPoint("LEFT", 9, 0)
    row.icon:SetTexCoord(.07, .93, .07, .93)
    row.name = font(row, 12, TEXT); row.name:SetPoint("LEFT", 46, 0)
    row.detail = font(row, 11, MUTED)
    row.detail:SetJustifyH("RIGHT"); row.detail:SetPoint("RIGHT", -13, 0)
    row.rule = row:CreateTexture(nil, "ARTWORK")
    row.rule:SetTexture(WHITE); row.rule:SetVertexColor(.36, .25, .1, .35)
    row.rule:SetPoint("BOTTOMLEFT", 46, 0); row.rule:SetPoint("BOTTOMRIGHT", -5, 0)
    row.rule:SetHeight(1)
    row:SetScript("OnClick", function(self)
        if not self.subject then return end
        ui.knowledgeSelection[ui.mode] = self.subject.name
        C:ShowDiscoveries(ui.parent, ui.width)
    end)
    row:SetScript("OnEnter", function(self)
        if self.subject then self.band:SetVertexColor(.31, .19, .065, .75) end
    end)
    row:SetScript("OnLeave", function(self)
        self.band:SetVertexColor(.16, .1, .045, self.selected and .78 or (self.subject and .26 or .94))
    end)
    ui.knowledgeRows[index] = row
    return row
end

local function markKnowledgeTeacher(teacher)
    if not teacher or not teacher.mapID or not teacher.x or not teacher.y then return end
    if not C_Map or not C_Map.SetUserWaypoint or not UiMapPoint or
        not UiMapPoint.CreateFromCoordinates then
        C:Print(C:LocalizeDisplay("Die Kartenmarkierung ist in diesem Client nicht verfügbar."))
        return
    end
    local ok, point = pcall(UiMapPoint.CreateFromCoordinates,
        teacher.mapID, teacher.x / 100, teacher.y / 100)
    if not ok or not point then return end
    if not pcall(C_Map.SetUserWaypoint, point) then return end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    if ToggleWorldMap and (not WorldMapFrame or not WorldMapFrame:IsShown()) then
        pcall(ToggleWorldMap)
    end
    if WorldMapFrame and WorldMapFrame.SetMapID then
        pcall(WorldMapFrame.SetMapID, WorldMapFrame, teacher.mapID)
    end
end

local function showKnowledgeDossier(parent, width, x, y, mode, subject)
    local dossier = ui.knowledgeDossier
    if not dossier then
        dossier = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        panel(dossier)
        dossier.caption = font(dossier, 10, GOLD)
        dossier.caption:SetPoint("TOPLEFT", 20, -18)
        dossier.title = font(dossier, 23, TEXT)
        dossier.title:SetPoint("TOPLEFT", 20, -47)
        dossier.meta = font(dossier, 11, MUTED)
        dossier.meta:SetPoint("TOPLEFT", 21, -85)
        dossier.rule = dossier:CreateTexture(nil, "ARTWORK")
        dossier.rule:SetTexture(WHITE); dossier.rule:SetVertexColor(.68, .47, .16, .8)
        dossier.rule:SetPoint("TOPLEFT", 20, -111); dossier.rule:SetPoint("TOPRIGHT", -20, -111)
        dossier.rule:SetHeight(1)
        dossier.body = font(dossier, 13, TEXT)
        dossier.body:SetPoint("TOPLEFT", 21, -133)
        dossier.body:SetJustifyV("TOP")
        dossier.icon = dossier:CreateTexture(nil, "ARTWORK")
        dossier.icon:SetSize(43, 43); dossier.icon:SetPoint("TOPRIGHT", -19, -18)
        dossier.icon:SetTexCoord(.07, .93, .07, .93)
        dossier.art = dossier:CreateTexture(nil, "ARTWORK")
        dossier.art:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Alts")
        dossier.art:SetPoint("BOTTOMRIGHT", -8, 4)
        dossier.art:SetSize(220, 220); dossier.art:SetAlpha(.13)
        dossier.action = CreateFrame("Button", nil, dossier, "BackdropTemplate")
        dossier.action:SetPoint("BOTTOMLEFT", 19, 18)
        dossier.action:SetPoint("BOTTOMRIGHT", -19, 18)
        dossier.action:SetHeight(27)
        dossier.action:SetBackdrop({ bgFile = WHITE, edgeFile = BORDER, tile = false,
            edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        dossier.action:SetBackdropColor(.24, .15, .052, 1)
        dossier.action:SetBackdropBorderColor(.62, .45, .16, 1)
        dossier.action.label = font(dossier.action, 11, GOLD)
        dossier.action.label:SetPoint("CENTER")
        dossier.action.label:SetText(C:LocalizeDisplay("Auf der Karte markieren"))
        C:StyleChronicleButton(dossier.action)
        dossier.action:SetScript("OnClick", function(self) markKnowledgeTeacher(self.teacher) end)
        ui.knowledgeDossier = dossier
    end
    dossier:ClearAllPoints(); dossier:SetPoint("TOPLEFT", x, y)
    dossier:SetSize(width, 345)
    dossier.caption:SetText(C:LocalizeDisplay(mode == "teachers" and "CHRONICLE  /  KLASSENLEHRER" or
        "CHRONICLE  /  WAFFENFERTIGKEIT"))
    dossier.title:SetText(C:LocalizeDisplay(subject.name))
    dossier.title:SetWidth(width - 92)
    dossier.icon:SetTexture(mode == "teachers" and "Interface\\Icons\\INV_Misc_Book_09" or
        (subject.icon or icons.training))
    if mode == "teachers" then
        local coordinates = subject.x and subject.y and
            string.format("%.1f, %.1f", subject.x, subject.y) or "Koordinaten beim Besuch erfassen"
        dossier.meta:SetText(U.SafeText(subject.zone, C:LocalizeDisplay("Unbekanntes Gebiet")))
        dossier.body:SetText(C:LocalizeDisplay("ORT") .. "\n" .. U.SafeText(subject.zone, C:LocalizeDisplay("Unbekanntes Gebiet")) ..
            "\n\n" .. C:LocalizeDisplay("KARTENKOORDINATEN") .. "\n" .. coordinates ..
            "\n\n" .. C:LocalizeDisplay("QUELLE") .. "\n" .. (subject.source == "catalog" and C:LocalizeDisplay("Chronicle-Grundbestand") or
            C:LocalizeDisplay("Bei deinem Trainerbesuch erfasst")))
    else
        local level = tonumber(subject.level) or 0
        local price = subject.status == "used" and C:LocalizeDisplay("Bereits erlernt") or
            (subject.cost ~= nil and U.Money(subject.cost) or "Beim Trainer prüfen")
        local status = subject.status == "used" and C:LocalizeDisplay("Bereits erlernt") or
            (subject.status == "available" and "Jetzt beim besuchten Trainer verfügbar" or
            (subject.source == "catalog" and "Katalog-Vorschau" or "Noch nicht verfügbar"))
        dossier.meta:SetText(C:LocalizeDisplay(status))
        dossier.body:SetText(C:LocalizeDisplay("LERNSTUFE") .. "\n" .. (level > 0 and (C:LocalizeDisplay("Stufe ") .. level) or C:LocalizeDisplay("Beim Trainer prüfen")) ..
            "\n\n" .. C:LocalizeDisplay("PREIS") .. "\n" .. (subject.source == "catalog" and subject.status ~= "used" and C:LocalizeDisplay("Ungefähr ") or "") .. C:LocalizeDisplay(price) ..
            "\n\n" .. C:LocalizeDisplay("LEHRER") .. "\n" .. (subject.trainer or C:LocalizeDisplay("Angebot beim Waffenmeister prüfen")))
    end
    dossier.meta:SetWidth(width - 40)
    dossier.body:SetWidth(width - 42)
    dossier.action.teacher = mode == "teachers" and subject or nil
    dossier.action:SetShown(mode == "teachers" and subject.mapID ~= nil and
        subject.x ~= nil and subject.y ~= nil)
    dossier:Show()
end

local function showWeaponLocations(parent, width, x)
    local training = C.char and C.char.training or {}
    local visited = {}
    for _, visit in pairs(training.visitedTrainers or {}) do
        if type(visit) == "table" and visit.kind == "weapon" and visit.name then
            visited[visit.name] = visit
        end
    end
    local masters = C.GetKnowledgeWeaponMasters and C:GetKnowledgeWeaponMasters() or {}
    local present = {}
    for index, master in ipairs(masters) do
        present[master.name] = true
        local visit = visited[master.name]
        if visit and visit.mapID and visit.x and visit.y then masters[index] = visit end
    end
    for name, visit in pairs(visited) do
        if not present[name] and visit.mapID and visit.x and visit.y then
            masters[#masters + 1] = visit
        end
    end
    if #masters == 0 then return 0 end
    if not ui.weaponLocationHeading then
        ui.weaponLocationHeading = font(parent, 11, GOLD)
    end
    ui.weaponLocationHeading:ClearAllPoints()
    ui.weaponLocationHeading:SetPoint("TOPLEFT", x + 8, -615)
    ui.weaponLocationHeading:SetText(C:LocalizeDisplay("WAFFENMEISTER AUF DER KARTE"))
    ui.weaponLocationHeading:Show()
    ui.weaponLocations = ui.weaponLocations or {}
    for index, master in ipairs(masters) do
        local button = ui.weaponLocations[index]
        if not button then
            button = CreateFrame("Button", nil, parent, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button.name = font(button, 11, TEXT)
            button.name:SetPoint("LEFT", 11, 0)
            button.detail = font(button, 10, MUTED)
            button.detail:SetPoint("RIGHT", -24, 0)
            button.detail:SetJustifyH("RIGHT")
            button.arrow = font(button, 12, GOLD)
            button.arrow:SetPoint("RIGHT", -8, 0)
            button.arrow:SetText(">")
            button:SetScript("OnClick", function(self) markKnowledgeTeacher(self.teacher) end)
            ui.weaponLocations[index] = button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", x + 5, -640 - (index - 1) * 35)
        button:SetSize(width - 8, 30)
        button.name:SetText(master.name)
        button.name:SetWidth(math.max(90, width * .47))
        button.detail:SetText(C:LocalizeDisplay(master.zone or "") .. "  " ..
            string.format("%.1f, %.1f", master.x, master.y))
        button.detail:SetWidth(math.max(90, width * .47))
        button.teacher = master
        button:Show()
    end
    return 640 + #masters * 35
end

local function showKnowledge(parent, width, mode)
    local training = C.char and C.char.training or {}
    local rows, groups = {}, {}
    ui.search:ClearAllPoints(); ui.search:SetPoint("TOPLEFT", 8, -108)
    ui.search:SetWidth(math.min(340, width - 16)); ui.search:Show()
    if mode == "teachers" then
        local known = {}
        for _, teacher in ipairs(C.GetKnowledgeTeachers and C:GetKnowledgeTeachers() or {}) do
            known[teacher.name] = teacher
        end
        for _, visit in pairs(training.visitedTrainers or {}) do
            if visit.kind == "class" then
                known[visit.name] = visit
            end
        end
        for _, visit in pairs(known) do
                local query = (visit.name .. " " .. (visit.zone or "")):lower()
                if ui.query == "" or query:find(ui.query, 1, true) then
                    local zone = U.SafeText(visit.zone, "Unbekanntes Gebiet")
                    groups[zone] = groups[zone] or {}
                    groups[zone][#groups[zone] + 1] = visit
                end
        end
        local zones = {}
        for zone in pairs(groups) do zones[#zones + 1] = zone end
        table.sort(zones)
        for _, zone in ipairs(zones) do
            table.sort(groups[zone], function(a, b) return a.name < b.name end)
            rows[#rows + 1] = { heading = true, name = zone, detail = #groups[zone] .. C:LocalizeDisplay(" LEHRER") }
            for _, visit in ipairs(groups[zone]) do
                rows[#rows + 1] = { name = visit.name,
                    detail = visit.x and visit.y and string.format("%.1f, %.1f", visit.x, visit.y) or "Ort noch nicht erfasst",
                    icon = "Interface\\Icons\\INV_Misc_Book_09", subject = visit }
            end
        end
    else
        local currentLevel = UnitLevel and (tonumber(UnitLevel("player")) or 0) or 0
        local categories = { available = {}, preview = {}, later = {}, used = {} }
        local known = {}
        for _, service in ipairs(C.GetKnowledgeWeapons and C:GetKnowledgeWeapons() or {}) do
            known[service.name] = service
        end
        for _, service in pairs(training.weaponServices or {}) do
            if type(service) == "table" and service.name then known[service.name] = service end
        end
        for _, service in pairs(known) do
            if type(service) == "table" and service.name then
                local query = (service.name .. " " .. C:LocalizeDisplay(service.name) .. " " .. (service.trainer or "")):lower()
                if ui.query == "" or query:find(ui.query, 1, true) then
                    local category = service.status == "used" and "used" or
                        (service.status == "available" and "available" or
                        ((tonumber(service.level) or 0) > currentLevel and "later" or
                        (service.status == "preview" and "preview" or "later")))
                    categories[category][#categories[category] + 1] = service
                end
            end
        end
        for _, spec in ipairs({ { "available", "JETZT VERFÜGBAR" },
            { "preview", "BEIM WAFFENMEISTER PRÜFEN" },
            { "later", "NOCH NICHT VERFÜGBAR" }, { "used", "BEREITS ERLERNT" } }) do
            local entries = categories[spec[1]]
            if #entries > 0 then
                table.sort(entries, function(a, b)
                    if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
                    return a.name < b.name
                end)
                rows[#rows + 1] = { heading = true, name = spec[2], detail = #entries .. C:LocalizeDisplay(" FERTIGKEITEN") }
                for _, service in ipairs(entries) do
                    local level = tonumber(service.level) or 0
                    local levelText = level > 0 and (C:LocalizeDisplay("Stufe ") .. level) or C:LocalizeDisplay("Stufe offen")
                    local price = service.status == "used" and C:LocalizeDisplay("Erlernt") or
                        (service.cost ~= nil and U.Money(service.cost) or C:LocalizeDisplay("Preis offen"))
                    if service.source == "catalog" and service.status ~= "used" then price = C:LocalizeDisplay("ca. ") .. price end
                    rows[#rows + 1] = { name = service.name, icon = service.icon or icons.training,
                        detail = levelText .. "   •   " .. price,
                        muted = spec[1] == "later" and level > currentLevel, subject = service }
                end
            end
        end
    end
    local entryCount, groupCount, confirmed = 0, 0, 0
    for _, info in ipairs(rows) do
        if info.heading then groupCount = groupCount + 1
        else
            entryCount = entryCount + 1
            if info.subject and info.subject.source ~= "catalog" then confirmed = confirmed + 1 end
        end
    end
    local metricWidth = math.floor((width - 30) / 3)
    showMetric(parent, 1, 9, -147, metricWidth, entryCount,
        mode == "teachers" and "KLASSENLEHRER" or "WAFFENARTEN")
    showMetric(parent, 2, math.floor(width / 3) + 4, -147, metricWidth, groupCount,
        mode == "teachers" and "GEBIETE" or "GRUPPEN")
    showMetric(parent, 3, math.floor(width * 2 / 3), -147, metricWidth, confirmed,
        "IM SPIEL ERFASST")
    if #rows == 0 then
        showEmpty(parent, 15, -242, width - 30,
            mode == "teachers" and "Noch kein Klassenlehrer besucht" or "Noch kein Waffenmeister besucht",
            "Chronicle erfasst Angebote und Orte automatisch, wenn du den entsprechenden Trainer öffnest.")
        parent:SetHeight(580)
        return
    end
    local selectedName = ui.knowledgeSelection[mode]
    local selected
    for _, info in ipairs(rows) do
        if info.subject and (not selected or info.name == selectedName) then
            selected = info.subject
            if info.name == selectedName then break end
        end
    end
    ui.knowledgeSelection[mode] = selected and selected.name
    local listWidth = math.floor(width * .54)
    local offset = 247
    for index, info in ipairs(rows) do
        local row = knowledgeRow(parent, index)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 5, -offset)
        row:SetSize(listWidth - 5, info.heading and 29 or 38)
        row.subject = info.subject
        row.selected = info.subject == selected
        row.band:SetVertexColor(.16, .1, .045, info.heading and .94 or (row.selected and .78 or .26))
        row.icon:SetShown(not info.heading)
        if not info.heading then row.icon:SetTexture(info.icon) end
        row.name:ClearAllPoints(); row.name:SetPoint("LEFT", info.heading and 14 or 46, 0)
        row.name:SetText(C:LocalizeDisplay(info.name)); row.name:SetTextColor(unpack(info.heading and GOLD or TEXT))
        row.name:SetWidth(listWidth - 195)
        row.detail:SetText(C:LocalizeDisplay(info.detail)); row.detail:SetWidth(145)
        row.rule:SetShown(not info.heading); row:Show()
        offset = offset + (info.heading and 31 or 39)
    end
    if selected then showKnowledgeDossier(parent, width - listWidth - 22,
        listWidth + 12, -247, mode, selected) end
    local locationsBottom = mode == "weapons" and showWeaponLocations(parent,
        width - listWidth - 22, listWidth + 12) or 0
    parent:SetHeight(math.max(620, offset + 25, locationsBottom + 18))
end

function C:ShowDiscoveries(parent, width, mode)
    ui.parent, ui.width = parent, width
    if mode and mode ~= ui.mode then
        ui.mode, ui.query = mode, ""
        if ui.search and ui.search:GetText() ~= "" then
            ui.settingSearch = true
            ui.search:SetText("")
            ui.settingSearch = nil
        end
    end
    resetDisplay()
    if not ui.hero then
        ui.hero = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        ui.hero:SetHeight(92); panel(ui.hero, .16, .105, .052)
        ui.caption = font(ui.hero, 10, GOLD); ui.caption:SetPoint("TOPLEFT", 20, -11)
        ui.title = font(ui.hero, 23, TEXT); ui.title:SetPoint("TOPLEFT", 19, -32)
        ui.detail = font(ui.hero, 10, MUTED); ui.detail:SetPoint("TOPLEFT", 20, -63)
        ui.heroStats = font(ui.hero, 10, GOLD); ui.heroStats:SetPoint("TOPLEFT", 20, -87)
        ui.search = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        ui.search:SetHeight(25); ui.search:SetAutoFocus(false); ui.search:SetMaxLetters(80)
        ui.search:SetScript("OnEscapePressed", ui.search.ClearFocus)
        ui.search:SetScript("OnTextChanged", function(self)
            if ui.settingSearch then return end
            ui.query = self:GetText():lower()
            ui.selection[ui.mode] = 1
            C:ShowDiscoveries(ui.parent, ui.width)
        end)
        ui.searchHint = font(ui.search, 10, MUTED)
        ui.searchHint:SetPoint("LEFT", 7, 0)
        ui.searchHint:SetText(C:L("searchEntries"))
        ui.search:HookScript("OnTextChanged", function(self)
            ui.searchHint:SetShown(self:GetText() == "")
        end)
    end
    ui.hero:ClearAllPoints(); ui.hero:SetPoint("TOPLEFT", 4, 0)
    ui.hero:SetWidth(width); ui.hero:SetHeight(ui.mode == "gather" and 112 or 92); ui.hero:Show()
    local keys = { gather = "gathering", training = "training",
        teachers = "teachers", weapons = "weapons" }
    local descriptions = { gather = "gatherDescription", training = "trainerDescription",
        teachers = "teacherDescription", weapons = "weaponDescription" }
    ui.caption:SetText("CHRONICLE  /  " .. C:L(keys[ui.mode]))
    ui.title:SetText(C:L(keys[ui.mode])); ui.detail:SetText(C:L(descriptions[ui.mode]))
    C:SetHeroMotif(ui.hero, ui.mode == "gather" and "Professions" or "Alts")
    if ui.mode == "gather" then showGather(parent, width)
    elseif ui.mode == "training" then showTraining(parent, width)
    else showKnowledge(parent, width, ui.mode) end
end
