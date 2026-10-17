local C = _G.Chronicle
local bg = "Interface\\Buttons\\WHITE8X8"
local classes = {
    {"WARRIOR", "Krieger", "Warrior", 1, "Tank · Schaden", "Schwere Rüstung, Waffen und Nahkampf"},
    {"PALADIN", "Paladin", "Paladin", 2, "Tank · Heilung · Schaden", "Heiliges Licht, Segen und Nahkampf"},
    {"HUNTER", "Jäger", "Hunter", 3, "Schaden", "Fernkampf und Begleiter"},
    {"ROGUE", "Schurke", "Rogue", 4, "Schaden", "Verstohlenheit und Kombopunkte"},
    {"PRIEST", "Priester", "Priest", 5, "Heilung · Schaden", "Heilig- und Schattenmagie"},
    {"SHAMAN", "Schamane", "Shaman", 7, "Heilung · Schaden", "Totems und Elementarmagie"},
    {"MAGE", "Magier", "Mage", 8, "Schaden", "Arkan-, Feuer- und Frostmagie"},
    {"WARLOCK", "Hexenmeister", "Warlock", 9, "Schaden", "Dämonen, Flüche und Schattenmagie"},
    {"DRUID", "Druide", "Druid", 11, "Tank · Heilung · Schaden", "Tiergestalten und Naturmagie"},
}
local crestTints = {
    WARRIOR={.42,.09,.07}, PALADIN={.37,.19,.26}, HUNTER={.20,.29,.12},
    ROGUE={.34,.29,.10}, PRIEST={.27,.25,.20}, SHAMAN={.10,.21,.34},
    MAGE={.09,.22,.35}, WARLOCK={.23,.16,.32}, DRUID={.19,.27,.09},
}
local frame, hero, selector, classSection, tabs, search, count, rows, empty, prev, next, back
local raceFilter, completedFilter
local classToken, view, query, page, expanded = nil, "quests", "", 1, nil
local openChain, showAllRaces = nil, false
local closedSearchChains = {}
local chapterOpen = false
local PAGE_SIZE = 24

local function font(parent, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(C:FontPath(), size)
    fs:SetTextColor(unpack(color))
    fs:SetJustifyH("LEFT")
    return fs
end

local function classInfo(token)
    for _, info in ipairs(classes) do if info[1] == token then return info end end
    return classes[1]
end

local function color(token)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    return c and {c.r, c.g, c.b} or {1, .82, .1}
end

local function mapName(id)
    if C_Map and C_Map.GetMapInfo and id then
        local ok, info = pcall(C_Map.GetMapInfo, id)
        if ok and info and info.name then return info.name end
    end
    return id and ("Karte #" .. id) or "Ort unbekannt"
end

local function npcName(id)
    local row = C.classNpcCatalog and C.classNpcCatalog[id]
    return row and row[1] or (id and ("NPC #" .. id) or "nicht erfasst")
end

local function questTitle(id, fallback)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, id)
        if ok and type(title) == "string" and title ~= "" then return title end
    end
    return fallback or ("Quest #" .. id)
end

local function completed(id)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, value = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(value)) then
            return value == true
        end
    end
    if IsQuestFlaggedCompleted then
        local ok, value = pcall(IsQuestFlaggedCompleted, id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(value)) then
            return value == true
        end
    end
    for _, record in ipairs(C.char and C.char.quests or {}) do
        if tonumber(record.id) == id and record.status == "completed" then return true end
    end
    return false
end

local function active(id)
    local saved = C.char and C.char.activeQuests
    if saved and (saved[tostring(id)] or saved[id]) then return true end
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, value = pcall(C_QuestLog.IsOnQuest, id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(value)) and
            value == true then return true end
    end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(index)) and
            type(index) == "number" and index > 0 then return true end
    end
    return false
end

local currentRaceBit
local function questState(id, quest, own)
    if not own then return "Im Katalog" end
    if completed(id) then return "Abgeschlossen" end
    if active(id) then return "Im Questlog" end
    local raceBit = currentRaceBit and currentRaceBit()
    if raceBit and quest.ra and quest.ra ~= 0 and
        math.floor(quest.ra / raceBit) % 2 == 0 then return "Anderes Volk" end
    if quest.pre and #quest.pre > 0 then
        local priorDone = false
        for _, prerequisite in ipairs(quest.pre) do
            if completed(prerequisite) or active(prerequisite) then priorDone = true; break end
        end
        if not priorDone then return "Vorquest offen" end
    end
    local level = UnitLevel and UnitLevel("player") or 0
    if level < (quest.rl or quest.lv or 0) then return "Ab Stufe " .. (quest.rl or quest.lv) end
    return "Bereit"
end

local function rewardName(id)
    if C.KnownItemName then
        local known=C:KnownItemName(id)
        if known then return known end
    end
    if C_Item and C_Item.GetItemNameByID then
        local ok, value = pcall(C_Item.GetItemNameByID, id)
        if ok and value then return value end
    end
    if GetItemInfo then
        local ok, value = pcall(GetItemInfo, id)
        if ok and value then return value end
    end
    return "Gegenstand nicht geladen"
end

local function startName(quest)
    if quest.s then return npcName(quest.s) end
    if quest.so then return "Objekt #" .. quest.so end
    if quest.si then return rewardName(quest.si) end
    return nil
end

local function spellName(id, fallback)
    if C_Spell and C_Spell.GetSpellName then
        local ok, value = pcall(C_Spell.GetSpellName, id)
        if ok and value then return value end
    end
    if GetSpellInfo then
        local ok, value = pcall(GetSpellInfo, id)
        if ok and value then return value end
    end
    return fallback or ("Zauber #" .. id)
end

local function rewardLines(quest)
    local lines = {}
    if quest.sp then
        lines[#lines + 1] = "Lehrt: " .. spellName(quest.sp, quest.spn)
        if quest.spd then lines[#lines + 1] = quest.spd end
    end
    for _, item in ipairs(quest.rewardItems or {}) do
        lines[#lines + 1] = "Belohnung: " .. item[2] .. "× " .. rewardName(item[1])
    end
    for _, item in ipairs(quest.rewardChoices or {}) do
        lines[#lines + 1] = "Zur Wahl: " .. item[2] .. "× " .. rewardName(item[1])
    end
    if quest.m and quest.m > 0 then
        local gold = math.floor(quest.m / 10000)
        local silver = math.floor((quest.m % 10000) / 100)
        local copper = quest.m % 100
        lines[#lines + 1] = "Geld: " .. (gold > 0 and gold .. "g " or "") ..
            (silver > 0 and silver .. "s " or "") .. copper .. "c"
    end
    if quest.rep then lines[#lines + 1] = "Wiederholbare Quest" end
    return lines
end

local function matches(...)
    if query == "" then return true end
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value and tostring(value):lower():find(query, 1, true) then return true end
    end
    return false
end

currentRaceBit = function()
    local token = UnitRace and select(2, UnitRace("player"))
    local bits = {Human=1, Orc=2, Dwarf=4, NightElf=8, Scourge=16,
        Undead=16, Tauren=32, Gnome=64, Troll=128}
    return bits[token]
end

local function classQuestChains(info)
    local bit = 2 ^ (info[4] - 1)
    local own = UnitClass and select(2, UnitClass("player")) == classToken
    local raceBit = not showAllRaces and currentRaceBit() or nil
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local factionBits = faction == "Alliance" and {1,4,8,64} or {2,16,32,128}
    local function factionVisible(mask)
        for _, b in ipairs(factionBits) do
            if math.floor(mask / b) % 2 == 1 then return true end
        end
        return false
    end
    local eligible, parent = {}, {}
    for id, quest in pairs(C.classQuestCatalog or {}) do
        if quest.c and math.floor(quest.c / bit) % 2 == 1 and
            (showAllRaces or not quest.ra or quest.ra == 0 or
                (factionVisible(quest.ra) and
                 (not raceBit or math.floor(quest.ra / raceBit) % 2 == 1))) then
            eligible[id], parent[id] = quest, id
        end
    end
    local function root(id)
        while parent[id] ~= id do
            parent[id] = parent[parent[id]]
            id = parent[id]
        end
        return id
    end
    local function link(a, b)
        local left, right = root(a), root(b)
        if left ~= right then parent[math.max(left, right)] = math.min(left, right) end
    end
    for id, quest in pairs(eligible) do
        for _, prerequisite in ipairs(quest.pre or {}) do
            if eligible[prerequisite] then link(id, prerequisite) end
        end
        if quest.nx and eligible[quest.nx] then link(id, quest.nx) end
    end
    local grouped = {}
    for id in pairs(eligible) do
        local key = root(id)
        grouped[key] = grouped[key] or {}
        grouped[key][#grouped[key] + 1] = id
    end
    local depth, visiting = {}, {}
    local function orderDepth(id)
        if depth[id] then return depth[id] end
        if visiting[id] then return 0 end
        visiting[id] = true
        local value = 0
        for _, prerequisite in ipairs(eligible[id].pre or {}) do
            if eligible[prerequisite] then value = math.max(value, orderDepth(prerequisite) + 1) end
        end
        for otherID, other in pairs(eligible) do
            if otherID ~= id and other.nx == id then
                value = math.max(value, orderDepth(otherID) + 1)
            end
        end
        visiting[id] = nil
        depth[id] = value
        return value
    end
    local chains = {}
    for key, ids in pairs(grouped) do
        table.sort(ids, function(a, b)
            local da, db = orderDepth(a), orderDepth(b)
            if da ~= db then return da < db end
            local la, lb = eligible[a].lv or 0, eligible[b].lv or 0
            if la ~= lb then return la < lb end
            return a < b
        end)
        local chain = { key = key, ids = ids, quests = eligible, level = 99,
            lv1 = 99, titleID = ids[#ids], done = 0, active = false, ready = false }
        local spellQuest, itemQuest
        for _, id in ipairs(ids) do
            local quest = eligible[id]
            chain.level = math.min(chain.level, quest.rl or 0)
            chain.lv1 = math.min(chain.lv1, quest.lv or 0)
            if quest.sp then spellQuest = spellQuest or id end
            if quest.rewardChoices or quest.rewardItems then itemQuest = id end
            local state = questState(id, quest, own)
            if state == "Abgeschlossen" then chain.done = chain.done + 1 end
            if state == "Im Questlog" then chain.active = true end
            if state == "Bereit" then chain.ready = true end
        end
        chain.titleID = spellQuest or itemQuest or ids[#ids]
        chains[#chains + 1] = chain
    end
    local same, merged = {}, {}
    table.sort(chains, function(a, b) return a.key < b.key end)
    local function rewardSignature(items)
        local values = {}
        for _, item in ipairs(items or {}) do
            values[#values + 1] = tostring(item[1])
            values[#values + 1] = tostring(item[2])
        end
        return table.concat(values, ",")
    end
    for _, chain in ipairs(chains) do
        if #chain.ids == 1 then
            local q = eligible[chain.ids[1]]
            local signature = table.concat({q.n or "", q.sp or "", q.lv or "",
                rewardSignature(q.rewardItems), rewardSignature(q.rewardChoices)}, "|")
            local first = same[signature]
            if first then
                first.alts = first.alts or {first.ids[1]}
                first.alts[#first.alts + 1] = chain.ids[1]
            else
                same[signature] = chain
                merged[#merged + 1] = chain
            end
        else
            merged[#merged + 1] = chain
        end
    end
    chains = merged
    local here
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, map = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then here = map end
    end
    for _, chain in ipairs(chains) do
        if chain.alts then
            local best, score = chain.alts[1], -1
            for _, id in ipairs(chain.alts) do
                local value = own and (active(id) and 4 or completed(id) and 3 or 0) or 0
                local npc = eligible[id].s and C.classNpcCatalog and C.classNpcCatalog[eligible[id].s]
                if npc and here and npc[2] == here then value = value + 1 end
                if value > score then best, score = id, value end
            end
            chain.ids = {best}
            chain.titleID = best
            chain.done = completed(best) and 1 or 0
            chain.active = active(best)
            chain.ready = questState(best, eligible[best], own) == "Bereit"
        end
    end
    table.sort(chains, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        if a.lv1 ~= b.lv1 then return a.lv1 < b.lv1 end
        return a.key < b.key
    end)
    return chains, own
end

local function build()
    local result = {}
    local info = classInfo(classToken)
    if view == "overview" then
        local lines = {
            {"Rollen", info[5], "Die Möglichkeiten deiner Klasse im Gruppenspiel."},
            {"Spielweise", info[6], "Klassenquests und Lehrer findest du in den anderen Reitern."},
            {"Klassenquests", "Questketten und Belohnungen", "Voraussetzungen und Fortschritt werden mit deinem Questlog abgeglichen."},
            {"Klassenlehrer", "Orte und Kartenmarkierungen", "Lehrer können nach Fraktion und Namen gefunden werden."},
        }
        for i, line in ipairs(lines) do
            result[#result + 1] = {key="overview" .. i, name=line[1], detail=line[2], extra=line[3]}
        end
    elseif view == "trainers" then
        local faction = UnitFactionGroup and UnitFactionGroup("player")
        local factionCode = faction == "Alliance" and "A" or faction == "Horde" and "H" or nil
        for _, trainer in ipairs(C.classTrainerCatalog and C.classTrainerCatalog[classToken] or {}) do
            if not factionCode or trainer[6] == "AH" or trainer[6] == factionCode then
                local zone = mapName(trainer[3])
                if matches(trainer[2], zone, trainer[1]) then
                    result[#result + 1] = {key="trainer" .. trainer[1], name=trainer[2],
                        detail=zone .. string.format(" · %.1f / %.1f", trainer[4], trainer[5]),
                        extra="Klicke, um den Ort auf der Blizzard-Karte zu öffnen.",
                        map=trainer[3], x=trainer[4], y=trainer[5]}
                end
            end
        end
        table.sort(result, function(a,b) return a.name < b.name end)
    else
        local chains, own = classQuestChains(info)
        local settings = C.db and C.db.settings
        local chapterNumber = 0
        for _, chain in ipairs(chains) do
            local titleQuest = chain.quests[chain.titleID]
            local title = questTitle(chain.titleID, titleQuest.n)
            local matching = matches(title, chain.key, chain.level)
            if not matching then
                for _, id in ipairs(chain.ids) do
                    local quest = chain.quests[id]
                    if matches(questTitle(id, quest.n), id, quest.o,
                        quest.s and npcName(quest.s)) then matching = true; break end
                end
            end
            if matching and not (own and chain.done == #chain.ids and
                settings and settings.classHideCompleted) then
                chapterNumber = chapterNumber + 1
                local status = not own and "Katalog" or chain.done == #chain.ids and "Abgeschlossen" or
                    chain.active and "Im Questlog" or chain.ready and "Bereit" or "Noch gesperrt"
                local detail = "Ab Stufe " .. chain.level .. "  ·  " ..
                    chain.done .. " / " .. #chain.ids .. " abgeschlossen"
                local summary = {"|cffffd100INHALT DES KAPITELS|r  ·  " .. #chain.ids .. " Questschritte"}
                local rewards = {}
                for _, id in ipairs(chain.ids) do
                    local quest = chain.quests[id]
                    for _, line in ipairs(rewardLines(quest)) do
                        if not (quest.spd and line == quest.spd) then rewards[#rewards + 1] = line end
                    end
                end
                if #rewards > 0 then summary[#summary + 1] = "|cffffd100BELOHNUNGEN|r" end
                for i = 1, math.min(3, #rewards) do summary[#summary + 1] = rewards[i] end
                if #rewards > 3 then summary[#summary + 1] = "+" .. (#rewards - 3) .. " weitere Belohnungen in den Schritten" end
                local chainKey = "chain" .. chain.key
                result[#result + 1] = {key=chainKey, name=title, detail=detail,
                    extra=table.concat(summary, "\n"), chain=true, level=chain.level,
                    status=status, done=chain.done, steps=#chain.ids, chapter=chapterNumber}
                if openChain == chainKey or (query ~= "" and not closedSearchChains[chainKey]) then
                    for step, id in ipairs(chain.ids) do
                        local quest = chain.quests[id]
                        local giver = startName(quest)
                        local state = questState(id, quest, own)
                        local questDetail = "Stufe " .. tostring(quest.lv or "?")
                        if giver then questDetail = questDetail .. "  ·  Start: " .. giver end
                        local extra = {}
                        local liveText, liveObjective
                        if active(id) and C.API and C.API.QuestText then
                            local ok, first, second = pcall(C.API.QuestText, id)
                            if ok then liveText, liveObjective = first, second end
                        end
                        if type(liveText) == "string" and liveText ~= "" then
                            extra[#extra + 1] = "|cffffd100QUESTTEXT|r\n" .. liveText
                        end
                        if type(liveObjective) == "string" and liveObjective ~= "" then
                            extra[#extra + 1] = "|cffffd100ZIEL|r\n" .. liveObjective
                        elseif quest.o and quest.o ~= "" then
                            extra[#extra + 1] = "|cffffd100ZIEL|r\n" .. quest.o
                        elseif quest.ro and quest.ro ~= "" then
                            extra[#extra + 1] = "|cffffd100ZIEL|r\n" .. quest.ro
                        end
                        if giver then extra[#extra + 1] = "|cffffd100Start:|r " .. giver end
                        if quest.e then extra[#extra + 1] = "|cffffd100Abgabe:|r " .. npcName(quest.e) end
                        if quest.pre and #quest.pre > 0 then
                            local names = {}
                            for _, prerequisite in ipairs(quest.pre) do
                                local prior = C.classQuestCatalog[prerequisite]
                                names[#names + 1] = questTitle(prerequisite, prior and prior.n)
                            end
                            extra[#extra + 1] = "|cffffd100Vorher:|r " .. table.concat(names, ", ")
                        end
                        if quest.nx then
                            local following = C.classQuestCatalog[quest.nx]
                            extra[#extra + 1] = "|cffffd100Danach:|r " .. questTitle(quest.nx, following and following.n)
                        end
                        local rewards = rewardLines(quest)
                        if #rewards > 0 then
                            extra[#extra + 1] = "|cffffd100BELOHNUNGEN|r\n" .. table.concat(rewards, "\n")
                        end
                        local npc = quest.s and C.classNpcCatalog and C.classNpcCatalog[quest.s]
                        result[#result + 1] = {key="quest" .. id,
                            name=questTitle(id, quest.n), detail=questDetail,
                            extra=table.concat(extra, "\n"), map=npc and npc[2],
                            x=npc and npc[3], y=npc and npc[4], quest=true,
                            level=quest.lv or 0, done=completed(id), status=state,
                            step=step, steps=#chain.ids,
                            rewardItems=quest.rewardItems, rewardChoices=quest.rewardChoices,
                            spellID=quest.sp}
                    end
                end
            end
        end
    end
    return result
end

local function refresh(width)
    if not frame or not frame:IsShown() then return end
    width = width or frame:GetWidth()
    local info = classInfo(classToken)
    hero:SetWidth(width - 8)
    hero:SetHeight(chapterOpen and 115 or 87)
    hero.title:SetText(chapterOpen and (view == "quests" and ("Questbuch: " .. info[2]) or
        (info[2] .. " · Klassenwissen")) or "Klassenwissen")
    if chapterOpen then hero.title:SetTextColor(unpack(color(classToken)))
    else hero.title:SetTextColor(1,.82,.1) end
    hero.summary:SetText(chapterOpen and (info[5] .. "  ·  " .. info[6]) or "Neun Klassen  ·  Questketten, Belohnungen und Lehrer")
    hero.summary:SetWidth(width - 270)
    hero.hint:SetShown(not chapterOpen)
    hero.hint:SetText("Banner anklicken, um das Klassenkapitel zu öffnen")
    search:SetShown(chapterOpen)
    back:SetShown(chapterOpen)
    classSection:SetShown(not chapterOpen)
    for _, button in ipairs(tabs) do button:SetShown(chapterOpen) end
    count:SetShown(chapterOpen); prev:SetShown(chapterOpen); next:SetShown(chapterOpen)
    local ownClass = UnitClass and select(2, UnitClass("player")) == classToken
    raceFilter:SetShown(chapterOpen and view == "quests")
    completedFilter:SetShown(chapterOpen and view == "quests" and ownClass)
    raceFilter:SetText(showAllRaces and "Alle Völker: an" or "Alle Völker: aus")
    completedFilter:SetText(C.db and C.db.settings and C.db.settings.classHideCompleted and
        "Abgeschlossene: aus" or "Abgeschlossene: an")
    if not chapterOpen then
        for _, row in ipairs(rows) do row:Hide() end
        if empty then empty:Hide() end
        local cardWidth = (width - 26) / 2
        local gap = 7
        local scrollFrame = frame:GetParent() and frame:GetParent():GetParent()
        local availableHeight = scrollFrame and scrollFrame:GetHeight() or 680
        local cardHeight = math.max(92, math.min(150,
            math.floor((availableHeight - 144 - 4*gap) / 5)))
        for i, button in ipairs(selector) do
            local data = classes[i]
            local n = 0
            local bit = 2 ^ (data[4] - 1)
            for _, quest in pairs(C.classQuestCatalog or {}) do
                if quest.c and math.floor(quest.c / bit) % 2 == 1 then n = n + 1 end
            end
            button:ClearAllPoints()
            local column = (i-1) % 2
            local row = math.floor((i-1) / 2)
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 6 + column*(cardWidth+8), -128 - row*(cardHeight+gap))
            button:SetSize(cardWidth, cardHeight)
            local ownClass = UnitClass and select(2,UnitClass("player")) == data[1]
            local classColor = color(data[1])
            button.classColor = classColor
            button.tint:SetVertexColor(.08,.045,.02);button.tint:SetAlpha(.12)
            button.tint:ClearAllPoints();button.tint:SetAllPoints(button)
            button.banner:SetTexture("Interface\\AddOns\\Chronicle\\ClassBanner_"..data[3])
            button.banner:ClearAllPoints()
            button.banner:SetPoint("TOPLEFT",2,-2)
            button.banner:SetPoint("BOTTOMRIGHT",-2,2)
            button.banner:SetTexCoord(0,1,.115,.885)
            button.artWash:Hide();button.halo:Hide()
            button.icon:Hide();button.divider:Hide()
            button.edge:ClearAllPoints();button.edge:SetPoint("TOPLEFT",1,-1)
            button.edge:SetPoint("BOTTOMLEFT",1,1);button.edge:SetWidth(2)
            button.edge:SetShown(ownClass)
            button.edge:SetVertexColor(classColor[1],classColor[2],classColor[3],1)
            button.topRule:Hide();button.bottomRule:Hide()
            button.kicker:ClearAllPoints();button.kicker:SetPoint("TOPLEFT",22,-11)
            button.kicker:SetText(ownClass and "DEINE KLASSE" or ("KLASSE  " .. string.format("%02d",i)))
            button.kicker:SetTextColor(.15+.85*classColor[1],.15+.85*classColor[2],.15+.85*classColor[3])
            button.own:Hide()
            button.label:ClearAllPoints();button.label:SetPoint("TOPLEFT",22,-49)
            button.label:SetWidth(cardWidth*.52)
            button.label:SetFont(C:FontPath(), 21)
            button.label:SetJustifyH("LEFT")
            button.label:SetTextColor(.22+.78*classColor[1],.22+.78*classColor[2],.22+.78*classColor[3])
            button.role:SetText(data[5])
            button.role:ClearAllPoints();button.role:SetPoint("TOPLEFT",23,-28)
            button.role:SetWidth(cardWidth*.52);button.role:SetJustifyH("LEFT")
            button.meta:ClearAllPoints();button.meta:SetPoint("TOPLEFT",23,-79)
            button.meta:SetText(n .. " KLASSENQUESTS")
            button.meta:SetWidth(cardWidth*.52);button.meta:SetJustifyH("LEFT")
            button:SetBackdropColor(.045,.035,.025,.98)
            button:SetBackdropBorderColor(classColor[1]*(ownClass and .9 or .53),
                classColor[2]*(ownClass and .9 or .53),classColor[3]*(ownClass and .9 or .53),1)
            button:Show()
        end
        frame:SetHeight(128 + math.ceil(#selector/2)*cardHeight +
            (math.ceil(#selector/2)-1)*gap + 8)
        if frame:GetParent() then frame:GetParent():SetHeight(frame:GetHeight()+8) end
        return
    end
    for _,button in ipairs(selector) do button:Hide() end
    local tabY = 137
    local tabWidth = (width - 48) / 3 - 4
    for i, button in ipairs(tabs) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 17 + (i - 1) * (tabWidth + 4), -tabY)
        button:SetSize(tabWidth, 25)
        C:StyleChronicleButton(button,button.mode == view)
    end
    local results = build()
    local ranges = {}
    if view == "quests" then
        local first, size, index = 1, 0, 1
        while index <= #results do
            local last = index
            if results[index].chain then
                while last < #results and results[last + 1].quest do last = last + 1 end
            end
            local blockSize = last - index + 1
            if size > 0 and size + blockSize > PAGE_SIZE then
                ranges[#ranges + 1] = { first, index - 1 }
                first, size = index, 0
            end
            size = size + blockSize
            index = last + 1
        end
        if size > 0 then ranges[#ranges + 1] = { first, #results } end
    else
        for first = 1, #results, PAGE_SIZE do
            ranges[#ranges + 1] = { first, math.min(#results, first + PAGE_SIZE - 1) }
        end
    end
    local pages = math.max(1, #ranges)
    page = math.min(page, pages)
    if view == "quests" then
        local chainCount = 0
        for _, entry in ipairs(results) do if entry.chain then chainCount = chainCount + 1 end end
        count:SetText(chainCount .. " QUESTREIHEN  ·  " .. #results ..
            " SICHTBARE EINTRÄGE  ·  SEITE " .. page .. "/" .. pages)
    else
        count:SetText(#results .. " EINTRÄGE  ·  SEITE " .. page .. "/" .. pages)
    end
    prev:SetEnabled(page > 1); next:SetEnabled(page < pages)
    local y, used = tabY + (view == "quests" and 71 or 37), 0
    if empty then empty:Hide() end
    if #results == 0 then
        if not empty then
            empty = font(frame, 14, {.82,.75,.64})
            empty:SetJustifyH("CENTER")
        end
        empty:ClearAllPoints(); empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -y - 25)
        empty:SetWidth(width - 30)
        empty:SetText("Keine passenden Einträge gefunden.")
        empty:Show(); y = y + 80
    end
    local currentRange = ranges[page] or { 1, 0 }
    for i = currentRange[1], currentRange[2] do
        used = used + 1
        local data = results[i]
        local row = rows[used]
        if not row then
            row = CreateFrame("Button", nil, frame, "BackdropTemplate")
            row:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
            row:SetBackdropColor(.038,.036,.032,.92)
            row:SetBackdropBorderColor(.42,.29,.10,.8)
            row.accent = row:CreateTexture(nil,"ARTWORK")
            row.accent:SetTexture(bg)
            row.timeline = row:CreateTexture(nil,"ARTWORK")
            row.timeline:SetTexture(bg)
            row.stepNumber = font(row,10,{1,.82,.1})
            row.stepNumber:SetJustifyH("CENTER")
            row.kicker = font(row,9,{1,.82,.1})
            row.status = font(row,10,{1,.82,.1})
            row.status:SetJustifyH("RIGHT")
            row.progressTrack = row:CreateTexture(nil,"ARTWORK")
            row.progressTrack:SetTexture(bg)
            row.progressFill = row:CreateTexture(nil,"OVERLAY")
            row.progressFill:SetTexture(bg)
            row.watermark = row:CreateTexture(nil,"BACKGROUND")
            row.watermark:SetTexture("Interface\\AddOns\\Chronicle\\ClassSigil_"..info[3])
            row.watermark:SetPoint("RIGHT",row,"RIGHT",-22,0)
            row.watermark:SetSize(92,92)
            row.icon = row:CreateTexture(nil,"ARTWORK")
            row.icon:SetPoint("TOPLEFT", 7, -7); row.icon:SetSize(42,42)
            row.name = font(row,14,{.96,.91,.78}); row.name:SetPoint("TOPLEFT",58,-8)
            row.detail = font(row,11,{.74,.68,.57}); row.detail:SetPoint("TOPLEFT",58,-29)
            row.extra = font(row,11,{.9,.82,.66}); row.extra:SetPoint("TOPLEFT",58,-56)
            row.extra:SetJustifyV("TOP")
            row.marker = font(row,14,{1,.82,.1}); row.marker:SetPoint("TOPRIGHT",-12,-8)
            row.mapButton = CreateFrame("Button",nil,row,"BackdropTemplate")
            C:StyleChronicleButton(row.mapButton)
            row.mapButton:SetSize(90,22)
            row.mapButton:SetPoint("BOTTOMRIGHT",-10,8)
            row.mapButton:SetText("Karte ›")
            row.mapButton:SetScript("OnClick",function(self)
                if self.mapID and C.OpenBlizzardMap then
                    C:OpenBlizzardMap(self.mapID,self.x,self.y)
                end
            end)
            row.rewardIcons = {}
            row:SetScript("OnClick",function(self)
                if self.mapOnly and self.mapID and C.OpenBlizzardMap then
                    C:OpenBlizzardMap(self.mapID,self.x,self.y)
                elseif self.chain == true then
                    if query ~= "" then
                        closedSearchChains[self.key] = not closedSearchChains[self.key]
                    elseif openChain == self.key then openChain = nil
                    else openChain = self.key end
                    expanded = nil
                    refresh()
                else
                    if expanded == self.key then expanded = nil
                    else expanded = self.key end
                    refresh()
                end
            end)
            row:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(.82,.58,.19,1) end)
            row:SetScript("OnLeave",function(self)
                local c=self.baseColor or {.42,.29,.10}
                self:SetBackdropBorderColor(c[1],c[2],c[3],.85)
            end)
            rows[used]=row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",frame,"TOPLEFT",data.quest and 20 or 4,-y)
        row.icon:ClearAllPoints()
        row.name:ClearAllPoints()
        row.detail:ClearAllPoints()
        row.extra:ClearAllPoints()
        local classColor = color(classToken)
        local stateColors = {
            ["Abgeschlossen"]={.35,.83,.4}, ["Im Questlog"]={.43,.72,1},
            ["Bereit"]={1,.82,.17}, ["Noch gesperrt"]={.66,.59,.48},
            ["Katalog"]={.72,.66,.56}, ["Vorquest offen"]={.66,.59,.48},
        }
        local statusColor = stateColors[data.status] or classColor
        row.baseColor = data.chain and {.63,.46,.20} or {.42,.32,.19}
        row:SetBackdropColor(data.chain and .055 or .038, data.chain and .052 or .036,
            data.chain and .046 or .032, .97)
        row:SetBackdropBorderColor(row.baseColor[1]*.65,row.baseColor[2]*.65,
            row.baseColor[3]*.65,.85)
        row.accent:ClearAllPoints();row.accent:SetPoint("TOPLEFT",1,-1)
        row.accent:SetPoint("BOTTOMLEFT",1,1);row.accent:SetWidth(data.chain and 4 or 2)
        row.accent:SetVertexColor(row.baseColor[1],row.baseColor[2],row.baseColor[3],.9)
        row.watermark:SetShown(data.chain == true)
        row.watermark:SetTexture("Interface\\AddOns\\Chronicle\\ClassSigil_"..info[3])
        row.watermark:SetAlpha(.095)
        row.kicker:ClearAllPoints()
        row.status:ClearAllPoints();row.status:SetPoint("TOPRIGHT",-40,-9)
        row.status:SetWidth(145);row.status:SetText(data.status or "")
        row.status:SetTextColor(statusColor[1],statusColor[2],statusColor[3])
        if data.quest then
            row.timeline:ClearAllPoints();row.timeline:SetPoint("TOPLEFT",21,-2)
            row.timeline:SetPoint("BOTTOMLEFT",21,2);row.timeline:SetWidth(1)
            row.timeline:SetVertexColor(classColor[1],classColor[2],classColor[3],.35)
            row.timeline:Show()
            row.stepNumber:ClearAllPoints();row.stepNumber:SetPoint("TOPLEFT",6,-17)
            row.stepNumber:SetWidth(32);row.stepNumber:SetText(string.format("%02d",data.step or 1))
            row.stepNumber:Show()
            row.icon:SetPoint("TOPLEFT",45,-10);row.icon:SetSize(34,34)
            row.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
            row.kicker:SetPoint("TOPLEFT",89,-7)
            row.kicker:SetText("SCHRITT " .. (data.step or 1) .. " / " .. (data.steps or 1))
            row.name:SetPoint("TOPLEFT",89,-20)
            row.detail:SetPoint("TOPLEFT",89,-42)
            row.extra:SetPoint("TOPLEFT",89,-66)
            row.progressTrack:Hide();row.progressFill:Hide()
        else
            row.timeline:Hide();row.stepNumber:Hide()
            row.icon:SetPoint("TOPLEFT",10,-12);row.icon:SetSize(48,48)
            row.icon:SetTexture("Interface\\AddOns\\Chronicle\\ClassSigil_"..info[3])
            row.kicker:SetPoint("TOPLEFT",70,-9)
            row.kicker:SetText(data.chain and ("KAPITEL " .. string.format("%02d",data.chapter or 1) ..
                "  ·  " .. (data.steps or 1) .. " SCHRITTE") or "CHRONICLE  /  KLASSEN")
            row.name:SetPoint("TOPLEFT",70,-23)
            row.detail:SetPoint("TOPLEFT",70,-48)
            row.extra:SetPoint("TOPLEFT",70,-75)
            if data.chain then
                row.progressTrack:ClearAllPoints();row.progressTrack:SetPoint("BOTTOMLEFT",70,7)
                row.progressTrack:SetSize(math.max(1,width-235),3)
                row.progressTrack:SetVertexColor(.22,.16,.09,.95)
                row.progressFill:ClearAllPoints();row.progressFill:SetPoint("LEFT",row.progressTrack,"LEFT",0,0)
                row.progressFill:SetSize(math.max(1,(width-235)*((data.done or 0)/math.max(1,data.steps or 1))),3)
                row.progressFill:SetVertexColor(.81,.61,.24,1)
                row.progressTrack:Show();row.progressFill:Show()
            else row.progressTrack:Hide();row.progressFill:Hide() end
        end
        row.kicker:Show()
        row.name:SetText(data.name); row.name:SetWidth(width-(data.quest and 270 or 250))
        row.name:SetFont(C:FontPath(),data.chain and 16 or 14)
        row.name:SetTextColor(data.chain and .96 or .96,
            data.chain and .83 or .91,data.chain and .56 or .78)
        row.detail:SetText(data.detail); row.detail:SetWidth(width-(data.quest and 108 or 80))
        row.key,row.mapID,row.x,row.y,row.mapOnly=data.key,data.map,data.x,data.y,view=="trainers"
        row.chain,row.quest=data.chain,data.quest
        local open = (data.chain and (openChain == data.key or
            (query ~= "" and not closedSearchChains[data.key]))) or
            (expanded == data.key and view ~= "trainers")
        row.mapButton:SetShown(open and data.map~=nil)
        row.mapButton.mapID,row.mapButton.x,row.mapButton.y=data.map,data.x,data.y
        row.extra:SetShown(open)
        row.marker:SetText(view=="trainers" and "KARTE ›" or (open and "−" or "+"))
        for _, icon in ipairs(row.rewardIcons) do icon:Hide() end
        local height = data.chain and 76 or data.quest and 64 or 57
        if open then
            local extra = data.extra ~= "" and data.extra or "Keine weiteren Angaben erfasst."
            if data.map then extra=extra.."\nOrt: "..mapName(data.map)..string.format(" · %.1f / %.1f",data.x or 0,data.y or 0) end
            row.extra:SetWidth(width-(data.map and 200 or data.quest and 118 or 86));row.extra:SetText(extra)
            local textHeight = row.extra:GetStringHeight()
            height=math.max(data.chain and 95 or 88,(data.quest and 72 or 82)+textHeight)
            if data.quest then
                local rewards = {}
                if data.spellID then rewards[#rewards + 1] = {kind="spell",id=data.spellID} end
                for _, item in ipairs(data.rewardItems or {}) do
                    rewards[#rewards + 1] = {kind="item",id=item[1],count=item[2]}
                end
                for _, item in ipairs(data.rewardChoices or {}) do
                    rewards[#rewards + 1] = {kind="choice",id=item[1],count=item[2]}
                end
                for index = 1, math.min(8, #rewards) do
                    local icon = row.rewardIcons[index]
                    if not icon then
                        icon = CreateFrame("Button",nil,row)
                        icon:SetSize(27,27)
                        icon.texture = icon:CreateTexture(nil,"ARTWORK")
                        icon.texture:SetAllPoints()
                        icon.count = font(icon,9,{1,.92,.72})
                        icon.count:SetPoint("BOTTOMRIGHT",0,0)
                        icon:SetScript("OnEnter",function(self)
                            if not GameTooltip then return end
                            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
                            local shown
                            if self.kind == "spell" and GameTooltip.SetSpellByID then
                                shown = pcall(GameTooltip.SetSpellByID,GameTooltip,self.id)
                            elseif C.ShowLootItemTooltip then
                                C:ShowLootItemTooltip(self,self.id,rewardName(self.id),
                                    self.kind == "choice" and "Eine Belohnung auswählen" or nil)
                                return
                            end
                            if not shown then
                                GameTooltip:SetText(self.kind == "spell" and spellName(self.id) or rewardName(self.id))
                            end
                            if self.kind == "choice" then GameTooltip:AddLine("Eine Belohnung auswählen",1,.82,.1) end
                            GameTooltip:Show()
                        end)
                        icon:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
                        row.rewardIcons[index] = icon
                    end
                    local reward = rewards[index]
                    icon.kind,icon.id = reward.kind,reward.id
                    local texture
                    if reward.kind == "spell" then
                        texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(reward.id)
                        if not texture and GetSpellTexture then texture = GetSpellTexture(reward.id) end
                    else
                        texture = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(reward.id)
                        if not texture and GetItemIcon then texture = GetItemIcon(reward.id) end
                    end
                    icon.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                    icon.count:SetText(reward.count and reward.count > 1 and tostring(reward.count) or "")
                    icon:ClearAllPoints()
                    icon:SetPoint("TOPLEFT",row,"TOPLEFT",89+(index-1)*33,-(76+textHeight))
                    icon:Show()
                end
                if #rewards > 0 then height=math.max(height,112+textHeight) end
            end
        end
        row:SetSize(width-(data.quest and 28 or 12),height);row:Show();y=y+height+7
    end
    for i=used+1,#rows do rows[i]:Hide() end
    frame:SetHeight(y+12)
    if frame:GetParent() then frame:GetParent():SetHeight(y+20) end
end

function C:HideClassKnowledge() if frame then frame:Hide() end end

function C:ShowClassKnowledge(parent,width)
    if not classToken then classToken=UnitClass and select(2,UnitClass("player")) or "WARRIOR" end
    if not frame then
        frame=CreateFrame("Frame",nil,parent);frame:SetPoint("TOPLEFT",0,0)
        selector,tabs,rows={},{},{}
        hero=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        hero:SetPoint("TOPLEFT",4,0);hero:SetHeight(115)
        hero:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
        hero:SetBackdropColor(.045,.035,.025,.98);hero:SetBackdropBorderColor(.52,.39,.21,.85)
        hero.caption=font(hero,10,{1,.82,.1});hero.caption:SetPoint("TOPLEFT",20,-14)
        hero.caption:SetText("CHRONICLE  /  KLASSEN")
        hero.title=font(hero,23,{.96,.91,.78});hero.title:SetPoint("TOPLEFT",20,-37)
        hero.summary=font(hero,11,{.82,.75,.64});hero.summary:SetPoint("TOPLEFT",21,-72)
        hero.hint=font(hero,10,{.77,.69,.52})
        hero.hint:SetPoint("TOPRIGHT",-20,-14)
        hero.hint:SetJustifyH("RIGHT")
        classSection=font(frame,11,{1,.82,.1})
        classSection:SetPoint("TOPLEFT",frame,"TOPLEFT",20,-105)
        classSection:SetText("KLASSEN  ·  9")
        search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate")
        search:SetSize(220,24);search:SetPoint("TOPRIGHT",-22,-69);search:SetAutoFocus(false)
        search.placeholder=font(search,10,{.72,.65,.52})
        search.placeholder:SetPoint("LEFT",7,0);search.placeholder:SetText("Klassenwissen suchen ...")
        search:SetScript("OnTextChanged",function(self)
            query=self:GetText():lower();page=1;expanded=nil;openChain=nil;closedSearchChains={}
            self.placeholder:SetShown(query=="");refresh()
        end)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        back=CreateFrame("Button",nil,hero,"BackdropTemplate")
        C:StyleChronicleButton(back);back:SetSize(132,24)
        back:SetPoint("TOPRIGHT",-20,-15);back:SetText("‹ Alle Klassen")
        back:SetScript("OnClick",function() chapterOpen=false;expanded=nil;openChain=nil;refresh() end)
        for i,info in ipairs(classes) do
            local button=CreateFrame("Button",nil,frame,"BackdropTemplate")
            button:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
            -- BackdropTemplate draws its background above BACKGROUND textures.
            -- The banner must sit on BORDER, like the profession banners.
            button.banner=button:CreateTexture(nil,"BORDER",nil,0)
            button.tint=button:CreateTexture(nil,"BORDER",nil,2)
            button.tint:SetTexture(bg);button.tint:SetPoint("TOPLEFT",1,-1)
            button.tint:SetSize(129,122)
            button.artWash=button:CreateTexture(nil,"BORDER")
            button.artWash:SetTexture(bg)
            button.halo=button:CreateTexture(nil,"BORDER")
            button.halo:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            button.halo:SetBlendMode("ADD")
            button.edge=button:CreateTexture(nil,"ARTWORK")
            button.edge:SetTexture(bg)
            button.topRule=button:CreateTexture(nil,"ARTWORK")
            button.topRule:SetTexture(bg)
            button.bottomRule=button:CreateTexture(nil,"ARTWORK")
            button.bottomRule:SetTexture(bg)
            button.icon=button:CreateTexture(nil,"ARTWORK")
            button.icon:SetSize(110,110);button.icon:SetPoint("TOPLEFT",10,-7)
            button.icon:SetTexture("Interface\\AddOns\\Chronicle\\ClassSigil_"..info[3])
            button.divider=button:CreateTexture(nil,"ARTWORK")
            button.divider:SetTexture(bg);button.divider:SetVertexColor(.5,.32,.12,.55)
            button.kicker=font(button,9,{1,.82,.1})
            button.own=font(button,9,{1,.82,.1})
            button.own:SetJustifyH("RIGHT")
            button.label=font(button,19,{1,.82,.1});button.label:SetPoint("TOPLEFT",153,-19)
            button.label:SetText(info[2]);
            button.label:SetShadowColor(0,0,0,1);button.label:SetShadowOffset(1,-1)
            button.meta=font(button,11,{.72,.67,.56});button.meta:SetPoint("TOPLEFT",153,-88)
            button.meta:SetShadowColor(0,0,0,1);button.meta:SetShadowOffset(1,-1)
            button.role=font(button,12,{.94,.89,.77});button.role:SetPoint("TOPLEFT",153,-57)
            button:SetScript("OnEnter",function(self)
                local c=self.classColor or {1,.82,.1}
                self:SetBackdropBorderColor(c[1],c[2],c[3],1)
                self.tint:SetAlpha(.24)
                self.halo:SetAlpha(.75)
                if GameTooltip then
                    GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(info[2],1,.82,.1)
                    GameTooltip:AddLine("Klicken: Klassenkapitel öffnen",.87,.81,.69)
                    GameTooltip:Show()
                end
            end)
            button:SetScript("OnLeave",function(self)
                local selected = UnitClass and select(2,UnitClass("player")) == info[1]
                local c=self.classColor or {1,.82,.1}
                local intensity=selected and .9 or .53
                self:SetBackdropBorderColor(c[1]*intensity,c[2]*intensity,c[3]*intensity,1)
                self.tint:SetAlpha(.12)
                self.halo:SetAlpha(1)
                if GameTooltip then GameTooltip:Hide() end
            end)
            button:SetScript("OnClick",function()
                classToken=info[1];chapterOpen=true;view="quests";page=1;expanded=nil;openChain=nil
                search:SetText("");refresh()
            end)
            selector[i]=button
        end
        for i,mode in ipairs({{"quests","Klassenquests"},{"trainers","Lehrer"},{"overview","Überblick"}}) do
            local button=CreateFrame("Button",nil,frame,"BackdropTemplate")
            C:StyleChronicleButton(button);button.mode=mode[1];button:SetText(mode[2])
            button:SetScript("OnClick",function() view=mode[1];page=1;expanded=nil;openChain=nil;refresh() end)
            tabs[i]=button
        end
        raceFilter=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(raceFilter)
        raceFilter:SetSize(158,24)
        raceFilter:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-171)
        raceFilter:SetScript("OnClick",function()
            showAllRaces=not showAllRaces;page=1;expanded=nil;openChain=nil;refresh()
        end)
        completedFilter=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(completedFilter)
        completedFilter:SetSize(168,24)
        completedFilter:SetPoint("LEFT",raceFilter,"RIGHT",8,0)
        completedFilter:SetScript("OnClick",function()
            C.db=C.db or {};C.db.settings=C.db.settings or {}
            C.db.settings.classHideCompleted=not C.db.settings.classHideCompleted
            page=1;expanded=nil;openChain=nil;refresh()
        end)
        count=font(frame,10,{1,.82,.1});count:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-124)
        prev=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(prev);prev:SetSize(90,20);prev:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-111,-118)
        prev:SetText("‹ Zurück");prev:SetScript("OnClick",function() page=math.max(1,page-1);expanded=nil;refresh() end)
        next=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(next);next:SetSize(90,20);next:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-15,-118)
        next:SetText("Weiter ›");next:SetScript("OnClick",function() page=page+1;expanded=nil;refresh() end)
    end
    frame:SetParent(parent);frame:SetWidth(width);frame:Show();refresh(width)
end
