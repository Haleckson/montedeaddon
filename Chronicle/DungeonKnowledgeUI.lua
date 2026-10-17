local C = _G.Chronicle
local U = C.Util
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, .82, .1 }
local TEXT = { .96, .91, .78 }
local MUTED = { .84, .77, .65 }
local XP_COLOR = { .57, .78, 1 }
local REP_COLOR = { .68, .88, .58 }
local ui = { mode = "bosses", kind = "dungeons", selectedIndex = {}, covers = {}, entries = {},
    details = {}, lootHeaders = {}, lootCollapsed = {}, tabs = {} }
local levelWatcher = CreateFrame("Frame")
levelWatcher:RegisterEvent("PLAYER_LEVEL_UP")
levelWatcher:SetScript("OnEvent", function()
    for _, row in ipairs(ui.entries) do
        if row:IsShown() and row.bossLevelValue then
            row.bossLevel:SetTextColor(C:BossDifficultyColor(row.bossLevelValue))
        end
    end
end)

local function availableQuests(dungeon)
    -- The guide is a catalog, not a list of quests currently available to the
    -- character. Keep the opposite faction visible and label it in the UI.
    return dungeon.quests or {}
end

local function questFactionLabel(quest)
    if quest.faction == "Alliance" then return C:L("questAlliance") end
    if quest.faction == "Horde" then return C:L("questHorde") end
    return nil
end

local function questFactionIcon(quest)
    if quest.faction == "Alliance" then return "Interface\\AddOns\\Chronicle\\FactionAlliance.tga" end
    if quest.faction == "Horde" then return "Interface\\AddOns\\Chronicle\\FactionHorde.tga" end
    return nil
end

local function formatXP(value)
    if value == nil then return C:L("unavailable") end
    local digits = tostring(value):gsub("[^%d]", "")
    local language = C:GetLanguage()
    local separator = (language == "deDE" or language == "esES" or language == "itIT") and "." or ","
    return digits:reverse():gsub("(%d%d%d)(%d)", "%1" .. separator .. "%2"):reverse() .. C:L("xpUnit")
end

local function questRewards(quest)
    local summary = quest.rewardSummary or ""
    local xp = quest.liveXPFallback or summary:match("([%d,]+)%s*XP")
    if quest.id and type(GetQuestLogRewardXP) == "function" then
        local ok, liveXP = pcall(GetQuestLogRewardXP, quest.id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(liveXP)) and
            type(liveXP) == "number" and (liveXP > 0 or (liveXP == 0 and ui.questDataLoaded and ui.questDataLoaded[quest.id])) then
            xp = liveXP
        end
    end
    local money = summary:match("(%d+g%s*%d+s%s*%d+c)") or
        summary:match("(%d+g%s*%d+s)") or summary:match("(%d+g)") or
        summary:match("(%d+s%s*%d+c)") or summary:match("(%d+s)") or
        summary:match("(%d+c)")
    if not money and quest.rewardMoney and quest.rewardMoney > 0 then
        local copper = quest.rewardMoney
        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper % 10000) / 100)
        local rest = copper % 100
        money = (gold > 0 and (gold .. "g ") or "") ..
            (silver > 0 and (silver .. "s ") or "") .. rest .. "c"
    end
    local reputation = {}
    for faction, amount in summary:gmatch("([%a%s%-']+)%s+%+(%d+)") do
        local factionName = faction:match("^%s*(.-)%s*$")
        if factionName ~= "" then reputation[#reputation + 1] = factionName .. " +" .. amount end
    end
    if #reputation == 0 then
        for _, entry in ipairs(quest.rewardReputation or {}) do
            local factionName
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local ok, data = pcall(C_Reputation.GetFactionDataByID, entry[1])
                if ok and data then factionName = data.name end
            end
            reputation[#reputation + 1] = (factionName or (C:L("reputation") .. " #" .. entry[1])) .. " +" .. entry[2]
        end
    end
    return formatXP(xp), money or C:L("unavailable"),
        #reputation > 0 and table.concat(reputation, "\n") or C:L("unavailable")
end

local function text(parent, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(C:FontPath(), size)
    fs:SetTextColor(unpack(color or TEXT))
    fs:SetJustifyH("LEFT")
    return fs
end

local function texture(parent, layer, r, g, b, a)
    local mark = parent:CreateTexture(nil, layer or "ARTWORK")
    mark:SetTexture(WHITE)
    mark:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    return mark
end

local function itemIcon(id)
    if not id then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if C_Item and C_Item.GetItemIconByID then
        local ok, value = pcall(C_Item.GetItemIconByID, id)
        if ok and value then return value end
    end
    if GetItemIcon then
        local ok, value = pcall(GetItemIcon, id)
        if ok and value then return value end
    end
    return "Interface\\Icons\\INV_Misc_Bag_08"
end

local function itemName(id, fallback)
    if C.KnownItemName then
        local known=C:KnownItemName(id,fallback)
        if known then return known end
    end
    if id and C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if id and GetItemInfo then
        local ok, name = pcall(GetItemInfo, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    local reference=id and C.lootItemFacts and C.lootItemFacts[id]
    if reference and type(reference.n)=="string" and reference.n~="" then return reference.n end
    return id and (C:LocalizeDisplay("Gegenstand") .. " #" .. id) or C:L("item")
end

local function hasItemData(item)
    if not item or type(item[1]) ~= "number" or item[1] <= 0 then return false end
    if C.KnownItemName then C:KnownItemName(item[1],item[2]) end
    return true
end

local function questState(id)
    if not id then return "unknown" end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, completed = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
        if ok and not (type(issecretvalue) == "function" and issecretvalue(completed)) and completed then
            return "done"
        end
    end
    for _, record in ipairs(C.char and C.char.quests or {}) do
        if tonumber(record.id) == id and record.status == "completed" then return "done" end
    end
    local active = C.char and C.char.activeQuests
    if active and (active[id] or active[tostring(id)]) then return "active" end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, id)
        if ok and type(index) == "number" and index > 0 then return "active" end
    elseif GetQuestLogIndexByID then
        local ok, index = pcall(GetQuestLogIndexByID, id)
        if ok and type(index) == "number" and index > 0 then return "active" end
    end
    return "open"
end

local function questStateLabel(state)
    if state == "done" then return C:LocalizeDisplay("Abgeschlossen") end
    if state == "active" then return C:LocalizeDisplay("Angenommen") end
    return C:LocalizeDisplay("Nicht abgeschlossen")
end

local function questChainLabel(quest)
    if not quest.chain or #quest.chain < 2 then return nil end
    for step, id in ipairs(quest.chain) do
        if id == quest.id then
            return C:LocalizeDisplay("Questreihe") .. ": " .. step .. " / " .. #quest.chain
        end
    end
    return C:LocalizeDisplay("Questreihe") .. ": " .. #quest.chain .. " " .. C:LocalizeDisplay("Schritte")
end

local function itemSlot(id, fallback)
    local category=C:ItemCategory(id,fallback)
    if category then return category end
    return C:LocalizeDisplay("Kein Ausrüstungsslot")
end

local function itemFallbackSlot(item)
    local value = item[6] or item[3]
    if type(value) == "string" and value:find("|Hitem", 1, true) then return nil end
    return value
end

local function lootMeta(item)
    local slot = itemSlot(item[1], itemFallbackSlot(item))
    if item[5] and item[5] > 0 then return slot .. "  •  ~" .. item[5] .. "%" end
    return slot
end

local lootGroups = { ["Trash"] = true, ["Komplexbeute"] = true, ["Trash Mobs"] = true,
    ["Trash Drops"] = true, ["Class books"] = true,
    ["All bosses"] = true, ["High Priest Shared loot"] = true,
    ["Gemeinsame Raidbeute"] = true }

local function encounterBosses(dungeon)
    local bosses = {}
    for _, boss in ipairs(dungeon.bosses or {}) do
        if not lootGroups[boss.name] then bosses[#bosses + 1] = boss end
    end
    return bosses
end

local function sharedRaidLoot(dungeon)
    if ui.kind ~= "raids" then return {} end
    local bosses = encounterBosses(dungeon)
    if #bosses < 3 then return {} end
    local counts = {}
    for _, boss in ipairs(bosses) do
        local seen = {}
        for _, item in ipairs(boss.loot or {}) do
            local id = item[1]
            if id and not seen[id] then counts[id] = (counts[id] or 0) + 1; seen[id] = true end
        end
    end
    local shared = {}
    local threshold = math.max(3, math.ceil(#bosses / 2))
    for id, count in pairs(counts) do if count >= threshold then shared[id] = true end end
    return shared
end

local function lootGroup(info)
    local itemID = info.id or info.itemID
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local classID
    if itemID and type(instant) == "function" then
        local ok, _, _, _, _, _, value = pcall(instant, itemID)
        if ok and type(value) == "number" then classID = value end
    end
    local fact = itemID and C.lootTooltipFacts and C.lootTooltipFacts[itemID]
    local slot = fact and fact.slot
    if classID == 2 or (not classID and slot and
        (slot == 13 or slot == 17 or slot == 21 or slot == 23 or slot == 25 or slot == 26)) then
        return "weapons", C:LocalizeDisplay("Waffen"), 1
    end
    if slot == 11 or slot == 12 then
        return "jewelry", C:LocalizeDisplay("Schmuck"), 3
    end
    if classID == 4 or (not classID and slot) then
        return "armor", C:LocalizeDisplay("Rüstung"), 2
    end
    local hint = type(info.meta) == "string" and
        (info.meta:match("•%s*(.-)%s*$") or info.meta) or ""
    if not classID then
        local lower = hint:lower()
        if lower:find("waffe", 1, true) or lower:find("weapon", 1, true) or
            lower:find("staff", 1, true) or lower:find("dagger", 1, true) then
            return "weapons", C:LocalizeDisplay("Waffen"), 1
        end
        if lower:find("rüstung", 1, true) or hint:find("Rüstung", 1, true) or
            lower:find("armor", 1, true) or
            lower:find("cloth", 1, true) or lower:find("leather", 1, true) or
            lower:find("mail", 1, true) or lower:find("plate", 1, true) then
            return "armor", C:LocalizeDisplay("Rüstung"), 2
        end
        if lower:find("ring", 1, true) or lower:find("finger", 1, true) or
            lower:find("trinket", 1, true) or lower:find("neck", 1, true) then
            return "jewelry", C:LocalizeDisplay("Schmuck"), 3
        end
    end
    local labels = {
        [0] = { "consumables", "Verbrauchbares", 4 },
        [7] = { "materials", "Materialien", 5 },
        [9] = { "recipes", "Rezepte", 6 },
        [12] = { "quests", "Questgegenstände", 7 },
    }
    local entry = labels[classID]
    if entry then return entry[1], C:LocalizeDisplay(entry[2]), entry[3] end
    return "other", C:LocalizeDisplay("Sonstiges"), 8
end

local function groupedLoot(items)
    local groups, ordered = {}, {}
    for _, info in ipairs(items) do
        local key, title, order = lootGroup(info)
        if info.shared then key, title, order = "shared:" .. key,
            C:LocalizeDisplay("Gemeinsame Beute") .. " · " .. title, order + 10 end
        local group = groups[key]
        if not group then
            group = { key = key, title = title, order = order, items = {} }
            groups[key] = group
            ordered[#ordered + 1] = group
        end
        group.items[#group.items + 1] = info
    end
    table.sort(ordered, function(a, b) return a.order < b.order end)
    return ordered
end

local function itemSourceText(dungeon, itemID)
    local lines, more = {}, 0
    for _, boss in ipairs(dungeon.bosses or {}) do
        for _, item in ipairs(boss.loot or {}) do
            if item[1] == itemID then
                if #lines < 4 then
                    local chance = tonumber(item[5])
                    lines[#lines + 1] = C:LocalizeCatalog(boss.name or "Boss") ..
                        (chance and chance > 0 and
                            ("  ·  ~" .. string.format("%.2f", chance) .. "%") or "")
                else
                    more = more + 1
                end
                break
            end
        end
    end
    if more > 0 then lines[#lines + 1] = "+" .. more end
    return table.concat(lines, "\n")
end

local function itemColor(id, fallbackQuality)
    return C:ItemQualityColor(id,fallbackQuality)
end

local function showItemTooltip(owner)
    if owner.itemID and C.ShowLootItemTooltip then
        C:ShowLootItemTooltip(owner,owner.itemID,owner.itemName,
            owner.itemMeta,owner.itemQuality,nil,owner.itemChance,owner.itemSource)
    end
end

local function setBossIcon(texture, boss)
    texture:SetTexCoord(0, 1, 0, 1)
    local displayID = boss and
        (C:GetBossDisplayID(ui.selected, boss.name) or boss.displayID)
    if displayID and SetPortraitTextureFromCreatureDisplayID then
        local ok = pcall(SetPortraitTextureFromCreatureDisplayID, texture, displayID)
        if ok then return end
    end
    texture:SetTexture(boss and boss.customIcon or "Interface\\AddOns\\Chronicle\\BossMedallion")
end

local function bossRankInfo(instanceName, boss)
    local meta = C:GetBossMetadata(instanceName, boss.name, boss.npcID)
    local level = meta and meta[1] or boss.level
    if type(level) ~= "number" or level < 1 or level > 100 then
        level = type(boss.level) == "number" and boss.level >= 1 and
            boss.level <= 100 and boss.level or nil
    end
    local rank = meta and meta[2] or (boss.rare and 2 or nil)
    return level, rank
end

local function bossRankLabel(rank)
    if rank == 4 then return C:L("bossRare") end
    if rank == 3 then return C:L("bossWorld") end
    if rank == 2 then return C:L("bossRareElite") end
    if rank == 1 then return C:L("bossElite") end
    return nil
end

local function roundMask(owner, target)
    if not owner.CreateMaskTexture or not target.AddMaskTexture then return end
    local mask = owner:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    mask:SetAllPoints(target)
    target:AddMaskTexture(mask)
end

local function bossRankColor(rank)
    if rank == 4 or rank == 2 then return .75, .76, .83 end
    return .96, .68, .16
end

local function bossDragonTexture(rank)
    local name = (rank == 2 and "BossDragon-Rare-Elite") or
        (rank == 4 and "BossDragon-Rare") or "BossDragon-Elite"
    return "Interface\\AddOns\\Chronicle\\DungeonMapArt\\" .. name
end

local function questName(quest)
    if quest.id and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, name = pcall(C_QuestLog.GetTitleForQuestID, quest.id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return U.SafeText(quest.name, C:L("quests"))
end

local function ensureHero(parent)
    if ui.hero then return end
    local hero = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    hero:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    hero:SetBackdropColor(.035, .034, .032, 1)
    hero:SetBackdropBorderColor(.59, .44, .17, 1)
    C:ApplyMaterial(hero, .3); C:OrnateCorners(hero)
    hero.art = hero:CreateTexture(nil, "ARTWORK", nil, -3)
    hero.art:SetPoint("TOPRIGHT", -5, -5)
    hero.art:SetPoint("BOTTOMRIGHT", -5, 5)
    hero.art:SetAlpha(.48)
    hero.shade = texture(hero, "ARTWORK", .06, .058, .054, .32)
    hero.shade:SetPoint("TOPRIGHT", -5, -5)
    hero.shade:SetPoint("BOTTOMRIGHT", -5, 5)
    hero.caption = text(hero, 11, GOLD)
    hero.caption:SetPoint("TOPLEFT", 20, -13)
    hero.title = text(hero, 26, TEXT)
    hero.title:SetPoint("TOPLEFT", 20, -39)
    hero.meta = text(hero, 12, GOLD)
    hero.meta:SetPoint("TOPLEFT", 21, -83)
    hero.description = text(hero, 12, MUTED)
    hero.description:SetPoint("TOPLEFT", 21, -106)
    hero.description:SetJustifyV("TOP")
    hero.count = text(hero, 11, GOLD)
    hero.count:SetPoint("BOTTOMLEFT", 21, 14)
    ui.back = CreateFrame("Button", nil, parent:GetParent():GetParent(), "BackdropTemplate")
    ui.back:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 11, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    ui.back:SetBackdropColor(.038, .036, .032, .96)
    ui.back:SetBackdropBorderColor(.76, .56, .19, 1)
    ui.back:SetSize(221, 27); ui.back:SetPoint("TOPRIGHT", -45, -12)
    ui.back.label = text(ui.back, 11, GOLD)
    ui.back.label:SetPoint("CENTER")
    ui.back.label:SetText(C:L("backOverview"))
    C:StyleChronicleButton(ui.back)
    ui.back:SetScript("OnClick", function()
        ui.selected = nil
        C:ShowDungeonKnowledge(ui.parent, ui.width)
    end)
    ui.hero = hero

    ui.listTitle = text(parent, 14, GOLD)
    ui.detailTitle = text(parent, 22, TEXT)
    ui.detailFaction = parent:CreateTexture(nil, "OVERLAY")
    ui.detailFaction:SetSize(32, 32)
    ui.detailFaction:Hide()
    ui.detailFactionOther = parent:CreateTexture(nil, "OVERLAY")
    ui.detailFactionOther:SetSize(32, 32)
    ui.detailFactionOther:Hide()
    ui.detailMeta = text(parent, 12, GOLD)
    ui.detailBody = text(parent, 13, TEXT)
    ui.detailBody:SetJustifyV("TOP")
    ui.detailExtra = text(parent, 12, MUTED)
    ui.detailExtra:SetJustifyV("TOP")
    ui.detailSection = text(parent, 14, GOLD)
    ui.detailRule = texture(parent, "ARTWORK", .56, .38, .16, .8)
    ui.detailRule:SetHeight(C:RuleThickness())
    ui.source = text(parent, 11, MUTED)
    ui.source:SetText("")
    ui.rewardStats = {}
    for index, spec in ipairs({ { "experienceCatalog", XP_COLOR },
        { "money", GOLD }, { "reputation", REP_COLOR } }) do
        local stat = CreateFrame("Frame", nil, parent)
        stat.value = text(stat, index == 3 and 12 or 19, spec[2])
        stat.value:SetPoint("TOPLEFT", 3, -3)
        stat.value:SetJustifyV("TOP")
        stat.label = text(stat, 10, MUTED)
        stat.label:SetPoint("BOTTOMLEFT", 4, 5)
        stat.localeKey = spec[1]
        stat.label:SetText(C:L(spec[1]))
        stat.rule = texture(stat, "ARTWORK", .55, .39, .17, .7)
        stat.rule:SetPoint("TOPLEFT", 0, 0)
        stat.rule:SetPoint("BOTTOMLEFT", 0, 0)
        stat.rule:SetWidth(C:RuleThickness())
        ui.rewardStats[index] = stat
    end
    ui.itemsTitle = text(parent, 13, GOLD)
    ui.questSearch = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    ui.questSearch:SetHeight(24)
    ui.questSearch:SetAutoFocus(false)
    ui.questSearch:SetMaxLetters(80)
    ui.questSearch:SetScript("OnEscapePressed", ui.questSearch.ClearFocus)
    ui.questSearch:SetScript("OnTextChanged", function(self)
        local query = (self:GetText() or ""):lower()
        if query == (ui.questSearchQuery or "") then return end
        ui.questSearchQuery = query
        ui.selectedIndex.quests = 1
        if ui.parent and ui.selected and ui.mode == "quests" then
            local focused = self:HasFocus()
            C:ShowDungeonKnowledge(ui.parent, ui.width)
            if focused then ui.questSearch:SetFocus() end
        end
    end)
    ui.questSearchHint = text(ui.questSearch, 11, MUTED)
    ui.questSearchHint:SetPoint("LEFT", 8, 0)
    ui.questSearchHint:SetText(C:LocalizeDisplay("Quest suchen ..."))
    ui.questSearch:SetScript("OnEditFocusGained", function() ui.questSearchHint:Hide() end)
    ui.questSearch:SetScript("OnEditFocusLost", function(self)
        ui.questSearchHint:SetShown(self:GetText() == "")
    end)
    ui.questFilters = {}
    ui.questFilterMode = ui.questFilterMode or { faction = 1, status = 1, wing = 1 }
    local filterOptions = {
        faction = { "Alle Fraktionen", "Allianz", "Horde", "Neutral" },
        status = { "Alle Status", "Offen", "Angenommen", "Abgeschlossen" },
        wing = { "Alle Orte", "Dieser Flügel", "Instanzweit" },
    }
    for _, key in ipairs({ "faction", "status", "wing" }) do
        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button.label = text(button, 10, GOLD)
        button.label:SetPoint("CENTER")
        button:SetScript("OnClick", function()
            ui.questFilterMode[key] = ui.questFilterMode[key] % #filterOptions[key] + 1
            ui.selectedIndex.quests = 1
            if ui.parent then C:ShowDungeonKnowledge(ui.parent, ui.width) end
        end)
        button.filterOptions = filterOptions[key]
        C:StyleChronicleButton(button)
        ui.questFilters[key] = button
    end
    ui.itemInfoEvents = CreateFrame("Frame")
    ui.itemInfoEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    ui.itemInfoEvents:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    ui.itemInfoEvents:SetScript("OnEvent", function(_,event,itemID,success)
        if event == "ITEM_DATA_LOAD_RESULT" and not success then return end
        if ui.parent and ui.selected and ui.hero and ui.hero:IsShown() and
            (ui.mode == "loot" or ui.mode == "bosses" or ui.mode == "quests") and not ui.itemRefreshPending then
            ui.itemRefreshPending = true
            if C_Timer and C_Timer.After then
                C_Timer.After(.15, function()
                    ui.itemRefreshPending = false
                    if ui.parent and ui.selected and ui.hero:IsShown() then
                        C:ShowDungeonKnowledge(ui.parent, ui.width)
                    end
                end)
            else
                ui.itemRefreshPending = false
            end
        end
    end)
    ui.questDataLoaded = ui.questDataLoaded or {}
    ui.questDataRequested = ui.questDataRequested or {}
    ui.questInfoEvents = CreateFrame("Frame")
    ui.questInfoEvents:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    ui.questInfoEvents:SetScript("OnEvent", function(_, _, questID, success)
        if not success or not questID or not ui.questDataRequested[questID] then return end
        ui.questDataLoaded[questID] = true
        if ui.parent and ui.selected and ui.mode == "quests" and ui.hero and ui.hero:IsShown() and
            ui.activeQuestID == questID then
            C:ShowDungeonKnowledge(ui.parent, ui.width)
        end
    end)

    for index, spec in ipairs({ { "bosses", "dungeonBossLoot" },
        { "quests", "dungeonQuests" }, { "loot", "allLoot" },
        { "map", "dungeonMap" } }) do
        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button.mode = spec[1]
        button.label = text(button, 12, TEXT)
        button.label:SetPoint("CENTER"); button.label:SetJustifyH("CENTER")
        button.localeKey = spec[2]
        button.label:SetText(C:L(spec[2]))
        C:StyleChronicleButton(button)
        button:SetScript("OnClick", function(self)
            ui.mode = self.mode
            C:ShowDungeonKnowledge(ui.parent, ui.width)
        end)
        ui.tabs[index] = button
    end
end

local function ensureCover(parent, index)
    local card = ui.covers[index]
    if card then return card end
    card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    card:SetBackdropColor(.03, .029, .027, 1)
    card:SetBackdropBorderColor(.5, .36, .15, 1)
    card.art = card:CreateTexture(nil, "ARTWORK")
    card.art:SetPoint("TOPLEFT", 4, -4); card.art:SetPoint("BOTTOMRIGHT", -4, 4)
    card.art:SetTexCoord(.05, .95, .26, .74)
    card.placeholder = card:CreateTexture(nil, "ARTWORK")
    card.placeholder:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Dungeons")
    card.placeholder:SetSize(80, 80)
    card.placeholder:SetPoint("RIGHT", -20, 0)
    card.placeholder:SetAlpha(.18)
    card.shade = card:CreateTexture(nil, "ARTWORK")
    card.shade:SetTexture("Interface\\AddOns\\Chronicle\\CardBottomFade")
    card.shade:SetPoint("BOTTOMLEFT", 4, 4)
    card.shade:SetPoint("BOTTOMRIGHT", -4, 4)
    card.shade:SetHeight(72)
    card.title = text(card, 17, GOLD)
    card.title:SetPoint("BOTTOMLEFT", 15, 27)
    card.title:SetShadowColor(0, 0, 0, 1); card.title:SetShadowOffset(1, -1)
    card.meta = text(card, 11, TEXT)
    card.meta:SetPoint("BOTTOMLEFT", 16, 10)
    card.meta:SetShadowColor(0, 0, 0, 1); card.meta:SetShadowOffset(1, -1)
    card.level = text(card, 11, GOLD)
    card.level:SetPoint("TOPRIGHT", -12, -10); card.level:SetJustifyH("RIGHT")
    card.level:SetShadowColor(0, 0, 0, 1); card.level:SetShadowOffset(1, -1)
    card:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, .76, .23, 1)
    end)
    card:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(.5, .36, .15, 1)
    end)
    card:SetScript("OnClick", function(self)
        ui.selected = self.dungeonName
        ui.mode = "bosses"
        ui.selectedIndex = {}
        C:ShowDungeonKnowledge(ui.parent, ui.width)
    end)
    ui.covers[index] = card
    return card
end

local function ensureEntry(parent, index)
    local row = ui.entries[index]
    if row then return row end
    row = CreateFrame("Button", nil, parent)
    row.band = texture(row, "BACKGROUND", .08, .075, .067, .18)
    row.band:SetAllPoints(row)
    row.accent = texture(row, "ARTWORK", 1, .72, .18, .4)
    row.accent:SetPoint("TOPLEFT", 0, -4); row.accent:SetPoint("BOTTOMLEFT", 0, 4)
    row.accent:SetWidth(2)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(33, 33); row.icon:SetPoint("LEFT", 9, 0)
    row.alliance = row:CreateTexture(nil, "OVERLAY")
    row.alliance:SetTexture("Interface\\AddOns\\Chronicle\\FactionAlliance.tga")
    row.alliance:SetSize(20, 20); row.alliance:SetPoint("RIGHT", -8, 0)
    row.horde = row:CreateTexture(nil, "OVERLAY")
    row.horde:SetTexture("Interface\\AddOns\\Chronicle\\FactionHorde.tga")
    row.horde:SetSize(20, 20); row.horde:SetPoint("RIGHT", -31, 0)
    row.bossFrame = CreateFrame("Frame", nil, row)
    row.bossFrame:SetSize(34, 34)
    row.bossFrame:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
    row.bossFrame:SetFrameLevel(row:GetFrameLevel() + 1)
    row.bossRank = row.bossFrame:CreateTexture(nil, "OVERLAY", nil, 1)
    row.bossRank:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    row.bossRank:SetTexCoord(0, .6, 0, .6)
    row.bossRank:SetSize(53, 53); row.bossRank:SetPoint("CENTER", row.bossFrame, "CENTER")
    row.bossIcon = row.bossFrame:CreateTexture(nil, "ARTWORK")
    row.bossIcon:SetSize(34, 34); row.bossIcon:SetPoint("CENTER", row.bossFrame, "CENTER")
    roundMask(row.bossFrame, row.bossIcon)
    row.bossDragon = row.bossFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    local dragonScale = 34 / 64
    row.bossDragon:SetSize(256 * dragonScale, 128 * dragonScale)
    row.bossDragon:SetPoint("CENTER", row.bossFrame, "CENTER", -54 * dragonScale, -20 * dragonScale)
    row.bossLevelBg = CreateFrame("Frame", nil, row.bossFrame)
    row.bossLevelBg:SetSize(16, 16)
    row.bossLevelBg:SetPoint("CENTER", row.bossFrame, "CENTER", 19.5 * dragonScale, -22 * dragonScale)
    row.bossLevelBg:SetFrameLevel(row.bossFrame:GetFrameLevel() + 2)
    row.bossLevelRing = row.bossLevelBg:CreateTexture(nil, "BORDER")
    row.bossLevelRing:SetAllPoints(row.bossLevelBg)
    row.bossLevelFill = row.bossLevelBg:CreateTexture(nil, "ARTWORK")
    row.bossLevelFill:SetPoint("TOPLEFT", 1.5, -1.5)
    row.bossLevelFill:SetPoint("BOTTOMRIGHT", -1.5, 1.5)
    row.bossLevelFill:SetColorTexture(.05, .04, .03, .95)
    roundMask(row.bossLevelBg, row.bossLevelRing)
    roundMask(row.bossLevelBg, row.bossLevelFill)
    row.bossLevel = row.bossLevelBg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.bossLevel:SetPoint("CENTER", row.bossLevelBg, "CENTER", .5, 0)
    local fontFile, _, fontFlags = row.bossLevel:GetFont()
    if fontFile then row.bossLevel:SetFont(fontFile, 9, fontFlags) end
    row.bossSkull = row.bossLevelBg:CreateTexture(nil, "OVERLAY")
    row.bossSkull:SetSize(10, 10)
    row.bossSkull:SetPoint("CENTER", row.bossLevelBg, "CENTER")
    row.bossSkull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    row.title = text(row, 14, TEXT)
    row.title:SetPoint("TOPLEFT", 72, -9)
    row.meta = text(row, 11, MUTED)
    row.meta:SetPoint("BOTTOMLEFT", 72, 9)
    row.rule = texture(row, "ARTWORK", .42, .29, .13, .7)
    row.rule:SetPoint("BOTTOMLEFT", 10, 0); row.rule:SetPoint("BOTTOMRIGHT", -4, 0)
    row.rule:SetHeight(C:RuleThickness())
    row:SetScript("OnClick", function(self)
        if self.groupKey then
            ui.lootCollapsed[self.groupKey] = not ui.lootCollapsed[self.groupKey]
            ui.selectedIndex.loot = 1
            C:ShowDungeonKnowledge(ui.parent, ui.width)
            return
        end
        ui.selectedIndex[ui.mode] = self.entryIndex
        C:ShowDungeonKnowledge(ui.parent, ui.width)
    end)
    row:SetScript("OnEnter", showItemTooltip)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    ui.entries[index] = row
    return row
end

local function ensureDetail(parent, index)
    local row = ui.details[index]
    if row then return row end
    row = CreateFrame("Frame", nil, parent)
    row:EnableMouse(true)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28); row.icon:SetPoint("TOPLEFT", 2, -5)
    row.qualityLine = texture(row, "ARTWORK", 1, 1, 1, 1)
    row.qualityLine:SetPoint("TOPLEFT", 0, -5)
    row.qualityLine:SetSize(2, 28)
    row.title = text(row, 13, TEXT)
    row.title:SetPoint("TOPLEFT", 39, -4)
    row.meta = text(row, 11, MUTED)
    row.meta:SetPoint("TOPLEFT", 39, -24)
    row.chance = text(row, 11, GOLD)
    row.chance:SetPoint("RIGHT", -4, 0)
    row.chance:SetJustifyH("RIGHT")
    row.rule = texture(row, "ARTWORK", .42, .29, .13, .64)
    row.rule:SetPoint("BOTTOMLEFT", 2, 0); row.rule:SetPoint("BOTTOMRIGHT", -2, 0)
    row.rule:SetHeight(C:RuleThickness())
    row:SetScript("OnEnter", showItemTooltip)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    ui.details[index] = row
    return row
end

local function ensureLootHeader(parent, index)
    local row = ui.lootHeaders[index]
    if row then return row end
    row = CreateFrame("Button", nil, parent)
    row.band = texture(row, "BACKGROUND", .08, .075, .067, .55)
    row.band:SetAllPoints(row)
    row.accent = texture(row, "ARTWORK", .85, .62, .19, .9)
    row.accent:SetPoint("TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", 0, 0)
    row.accent:SetWidth(2)
    row.label = text(row, 12, GOLD)
    row.label:SetPoint("LEFT", 11, 0)
    row:SetScript("OnClick", function(self)
        ui.lootCollapsed[self.groupKey] = not ui.lootCollapsed[self.groupKey]
        C:ShowDungeonKnowledge(ui.parent, ui.width)
    end)
    ui.lootHeaders[index] = row
    return row
end

function C:HideDungeonKnowledge()
    if ui.hero then ui.hero:Hide() end
    if ui.back then ui.back:Hide() end
    if ui.listTitle then ui.listTitle:Hide() end
    if ui.detailTitle then ui.detailTitle:Hide() end
    if ui.detailFaction then ui.detailFaction:Hide() end
    if ui.detailFactionOther then ui.detailFactionOther:Hide() end
    if ui.detailMeta then ui.detailMeta:Hide() end
    if ui.detailBody then ui.detailBody:Hide() end
    if ui.detailExtra then ui.detailExtra:Hide() end
    if ui.detailSection then ui.detailSection:Hide() end
    if ui.detailRule then ui.detailRule:Hide() end
    if ui.source then ui.source:Hide() end
    if ui.mapFrame then ui.mapFrame:Hide() end
    if ui.mapHint then ui.mapHint:Hide() end
    if ui.itemsTitle then ui.itemsTitle:Hide() end
    if ui.questSearch then ui.questSearch:Hide() end
    for _, button in pairs(ui.questFilters or {}) do button:Hide() end
    for _, stat in ipairs(ui.rewardStats or {}) do stat:Hide() end
    for _, button in ipairs(ui.tabs) do button:Hide() end
    for _, button in ipairs(ui.covers) do button:Hide() end
    for _, row in ipairs(ui.entries) do row:Hide() end
    for _, row in ipairs(ui.details) do row:Hide() end
    for _, row in ipairs(ui.lootHeaders) do row:Hide() end
end

local function showHome(parent, width, order, catalog)
    local raid = ui.kind == "raids"
    ui.hero:SetHeight(136)
    ui.hero.caption:SetText(C:LocalizeDisplay(raid and "CHRONICLE  /  RAIDWISSEN" or "CHRONICLE  /  INSTANZWISSEN"))
    ui.hero.caption:Show()
    ui.hero.title:SetText(C:L(raid and "raidsOfJourney" or "hallsOfJourney"))
    ui.hero.meta:SetText(C:LocalizeDisplay("BOSSE  ·  QUESTS  ·  BEUTE"))
    ui.hero.description:SetText("")
    ui.hero.count:SetText(#order .. C:L(raid and "raidsCatalog" or "dungeonsCatalog"))
    ui.back:Hide()
    ui.hero.art:Hide(); ui.hero.shade:Hide()
    C:SetSoftInstanceArt(ui.hero.art, nil)
    C:SetHeroMotif(ui.hero, "Dungeons", .42)
    ui.hero.motifClip:ClearAllPoints()
    ui.hero.motifClip:SetPoint("TOPRIGHT", ui.hero, "TOPRIGHT", -5, -5)
    ui.hero.motifClip:SetPoint("BOTTOMRIGHT", ui.hero, "BOTTOMRIGHT", -5, 5)
    ui.hero.motifClip:SetWidth(174)
    ui.hero.motif:SetSize(174, 174)
    ui.hero.motifClip:Show()
    local gap = 12
    local cardWidth = math.floor((width - gap) / 2)
    for index, name in ipairs(order) do
        local data = catalog[name]
        local card = ensureCover(parent, index)
        local col, row = (index - 1) % 2, math.floor((index - 1) / 2)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 4 + col * (cardWidth + gap), -157 - row * 96)
        card:SetSize(cardWidth, 88)
        card.dungeonName = name
        local art = C:GetPackagedInstanceArt(data.artName or name) or data.icon
        if art == "Interface\\AddOns\\Chronicle\\Motif_Dungeons" then art = nil end
        card.art:SetShown(art ~= nil)
        if art then card.art:SetTexture(art) end
        card.placeholder:SetShown(art == nil)
        card.title:SetText(C:LocalizeInstanceName(name)); card.title:SetWidth(cardWidth - 35)
        local questCount = #availableQuests(data)
        card.meta:SetText(data.preview and C:L("encountersUnrecorded") or
            (#encounterBosses(data) .. " " .. C:L("bosses") .. "    ·    " ..
            (questCount == 0 and C:L("questsUnrecorded") or
                questCount .. " " .. C:L("questCount"))))
        card.level:SetText(data.level and (C:L("level") .. " " .. tostring(data.level)) or "ENCOUNTER JOURNAL")
        card:Show()
    end
    parent:SetHeight(157 + math.ceil(#order / 2) * 96 + 8)
end

local function buildEntries(dungeon, mode)
    local rows = {}
    local shared = sharedRaidLoot(dungeon)
    if mode == "bosses" then
        for _, boss in ipairs(encounterBosses(dungeon)) do
            local level, rank = bossRankInfo(ui.selected, boss)
            local rankLabel = bossRankLabel(rank)
            local levelText = level and tostring(level) or dungeon.level
            rows[#rows + 1] = { title = U.SafeText(boss.name, "Boss"),
                meta = (levelText and (C:L("level") .. " " .. levelText .. "  ·  ") or "") ..
                    (rankLabel and (rankLabel .. "  ·  ") or "") ..
                    (function()
                        local count, seen = 0, {}
                        for _,item in ipairs(boss.loot or {}) do
                            if hasItemData(item) and not seen[item[1]] then
                                count = count + 1
                                seen[item[1]] = true
                            end
                        end
                        return count
                    end)() .. C:L("lootPieces"),
                icon = boss.rare and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or
                    "Interface\\AddOns\\Chronicle\\BossMedallion", data = boss, boss = boss,
                level = level, rank = rank }
        end
        for _, group in ipairs(dungeon.bosses or {}) do
            if lootGroups[group.name] and #(group.loot or {}) > 0 then
                local count, seen = 0, {}
                for _, item in ipairs(group.loot) do
                    if hasItemData(item) and not seen[item[1]] then
                        count = count + 1
                        seen[item[1]] = true
                    end
                end
                local title = group.name == "Komplexbeute" and "Komplexbeute" or
                    (group.name == "Trash" or group.name == "Trash Mobs" or
                    group.name == "Trash Drops") and "Trashbeute" or
                    C:LocalizeDisplay("Gemeinsame Beute")
                rows[#rows + 1] = { title = title,
                    meta = count .. C:L("lootPieces"),
                    icon = "Interface\\Icons\\INV_Misc_Bag_08", data = group }
            end
        end
    elseif mode == "map" then
        for _, floor in ipairs(C:GetDungeonMapFloors(ui.selected)) do
            rows[#rows + 1] = { title = floor.name, meta = C:L("dungeonMap"),
                icon = "Interface\\Icons\\INV_Misc_Map_01", data = floor }
        end
    elseif mode == "quests" then
        for _, quest in ipairs(availableQuests(dungeon)) do
            local title = questName(quest)
            local state = questState(quest.id)
            local factionMode = ui.questFilterMode and ui.questFilterMode.faction or 1
            local statusMode = ui.questFilterMode and ui.questFilterMode.status or 1
            local wingMode = ui.questFilterMode and ui.questFilterMode.wing or 1
            local query = ui.questSearchQuery or ""
            local factionMatches = factionMode == 1 or
                (factionMode == 2 and quest.faction == "Alliance") or
                (factionMode == 3 and quest.faction == "Horde") or
                (factionMode == 4 and not quest.faction)
            local statusMatches = statusMode == 1 or
                (statusMode == 2 and state == "open") or
                (statusMode == 3 and state == "active") or
                (statusMode == 4 and state == "done")
            local wingMatches = wingMode == 1 or
                (wingMode == 2 and not quest.complexWide) or
                (wingMode == 3 and quest.complexWide)
            if (query == "" or title:lower():find(query, 1, true) or
                tostring(quest.id or ""):find(query, 1, true)) and
                factionMatches and statusMatches and wingMatches then
                local factionLabel = questFactionLabel(quest)
                rows[#rows + 1] = { title = title,
                    meta = C:L("level") .. " " .. tostring(quest.level or "?") ..
                        (factionLabel and ("  ·  " .. factionLabel) or "") ..
                        "  ·  " .. questStateLabel(state),
                    icon = "Interface\\Icons\\INV_Misc_Note_01", data = quest }
            end
        end
    else
        local shownShared = {}
        for _, boss in ipairs(dungeon.bosses or {}) do
            for _, item in ipairs(boss.loot or {}) do
                local id = item[1]
                if hasItemData(item) and (not shared[id] or not shownShared[id]) then
                    rows[#rows + 1] = { title = itemName(id, item[2]),
                        meta = (shared[id] and "Gemeinsame Raid-Beute" or U.SafeText(boss.name, "Boss")) ..
                            "  •  " .. lootMeta(item), icon = itemIcon(id),
                        itemID = id, quality = item[4], chance=item[5],source=boss.name,
                        shared = shared[id],
                        data = { item = item, boss = boss } }
                    if shared[id] then shownShared[id] = true end
                end
            end
        end
    end
    if mode == "loot" then
        local grouped = groupedLoot(rows)
        local display = {}
        for _, group in ipairs(grouped) do
            local key = ui.kind .. ":" .. ui.selected .. ":all:" .. group.key
            display[#display + 1] = { title = (ui.lootCollapsed[key] and "+  " or "-  ") .. group.title,
                meta = #group.items .. " " .. C:L("lootPieces"), groupKey = key }
            if not ui.lootCollapsed[key] then
                for _, item in ipairs(group.items) do display[#display + 1] = item end
            end
        end
        return display
    end
    return rows
end

local function buildDetails(parent, x, width, startY, items, groupPrefix)
    local used, headerCount, height = 0, 0, 0
    local groups = groupPrefix and groupedLoot(items) or { { items = items } }
    for _, group in ipairs(groups) do
        local collapsed = false
        if groupPrefix then
            headerCount = headerCount + 1
            local header = ensureLootHeader(parent, headerCount)
            local key = groupPrefix .. ":" .. group.key
            collapsed = ui.lootCollapsed[key] == true
            header.groupKey = key
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", x, -startY - height)
            header:SetSize(width, 27)
            header.label:SetWidth(width - 18)
            header.label:SetText((collapsed and "+  " or "-  ") .. group.title ..
                "  (" .. #group.items .. ")")
            header:Show()
            height = height + 32
        end
        if not collapsed then
            for _, info in ipairs(group.items) do
                used = used + 1
                local row = ensureDetail(parent, used)
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", x, -startY - height)
                row:SetSize(width, 41)
                row.icon:SetTexture(itemIcon(info.id))
                local r, g, b = itemColor(info.id, info.quality)
                row.qualityLine:SetVertexColor(r, g, b, 1)
                row.title:SetText(itemName(info.id, info.name))
                row.title:SetTextColor(r, g, b)
                local chance = tonumber(info.chance)
                row.chance:SetText(chance and chance > 0 and
                    ("~" .. string.format("%.2f", chance) .. "%") or "")
                row.chance:SetWidth(chance and chance > 0 and 72 or 1)
                row.title:SetWidth(width - (chance and chance > 0 and 120 or 45))
                row.meta:SetText(U.SafeText(info.meta, ""))
                row.meta:SetWidth(width - (chance and chance > 0 and 120 or 45))
                row.itemID, row.itemName, row.itemMeta, row.itemQuality =
                    info.id, info.name, info.meta, info.quality
                row.itemChance, row.itemSource = info.chance, info.source
                row:Show()
                height = height + 43
            end
        end
    end
    return used, height
end

local function showDetail(parent, width, catalog)
    local name = ui.selected
    local dungeon = catalog[name]
    local raid = ui.kind == "raids"
    if not dungeon then ui.selected = nil; return end
    C:PopulateInstanceKnowledgeLoot(dungeon)
    local leftWidth = math.max(205, math.floor(width * .36))
    local rightX = leftWidth + 26
    local rightWidth = width - rightX - 5
    ui.hero:SetHeight(160)
    ui.hero.caption:SetText(C:LocalizeDisplay(raid and "CHRONICLE  /  RAIDWISSEN" or "CHRONICLE  /  INSTANZWISSEN"))
    ui.hero.caption:Show()
    ui.back:Show()
    ui.hero.title:SetText(C:LocalizeInstanceName(name))
    ui.hero.title:SetWidth(math.floor(width * .57))
    ui.hero.meta:SetText((dungeon.level and (C:L("level") .. " " .. tostring(dungeon.level)) or
        C:LocalizeDisplay("ENCOUNTER JOURNAL")) .. "    ·    " .. C:LocalizeCatalog(U.SafeText(dungeon.location, "")))
    ui.hero.meta:SetWidth(math.floor(width * .57))
    ui.hero.description:SetText(C:LocalizeCatalog(U.SafeText(dungeon.description,
        dungeon.preview and C:LocalizeDisplay("Begegnungen und Beute sind noch nicht erfasst.") or "")))
    ui.hero.description:SetWidth(math.floor(width * .55))
    ui.hero.description:SetHeight(35)
    local questCount = #availableQuests(dungeon)
    ui.hero.count:SetText(#encounterBosses(dungeon) .. " " .. C:L("bosses") ..
        "    |    " .. (questCount == 0 and C:L("questsUnrecorded") or
            questCount .. " " .. C:L("questCount")))
    ui.hero.art:SetWidth(math.floor(width * .42))
    local heroArt = C:GetPackagedInstanceArt(dungeon.artName or name) or dungeon.icon
    if heroArt == "Interface\\AddOns\\Chronicle\\Motif_Dungeons" then heroArt = nil end
    C:SetSoftInstanceArt(ui.hero.art, heroArt,
        math.floor(width * .42), { left = .05, right = .95, top = .13, bottom = .87,
            alpha = .48, fadeFraction = .64, subLevel = -3 })
    ui.hero.shade:Hide()
    if heroArt then
        if ui.hero.motifClip then ui.hero.motifClip:Hide() end
    else
        C:SetHeroMotif(ui.hero, "Dungeons", .23)
        ui.hero.motifClip:ClearAllPoints()
        ui.hero.motifClip:SetPoint("TOPRIGHT", ui.hero, "TOPRIGHT", -5, -5)
        ui.hero.motifClip:SetPoint("BOTTOMRIGHT", ui.hero, "BOTTOMRIGHT", -5, 5)
        ui.hero.motifClip:SetWidth(174)
        ui.hero.motif:SetSize(174, 174)
        ui.hero.motifClip:Show()
    end

    local tabWidth = math.floor((width - 28) / 4)
    for index, button in ipairs(ui.tabs) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 4 + (index - 1) * (tabWidth + 8), -177)
        button:SetSize(tabWidth, 29)
        local active = button.mode == ui.mode
        C:StyleChronicleButton(button, active)
        button.label:SetFont(C:FontPath(), 12)
        button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:Show()
    end
    local questView = ui.mode == "quests"
    if questView then
        ui.questSearch:ClearAllPoints()
        ui.questSearch:SetPoint("TOPLEFT", 12, -219)
        ui.questSearch:SetWidth(leftWidth - 20)
        ui.questSearch:Show()
        ui.questSearchHint:SetShown(not ui.questSearch:HasFocus() and ui.questSearch:GetText() == "")
        local filterWidth = math.floor((leftWidth - 12) / 3)
        for index, key in ipairs({ "faction", "status", "wing" }) do
            local button = ui.questFilters[key]
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", 6 + (index - 1) * (filterWidth + 4), -249)
            button:SetSize(filterWidth, 23)
            button.label:SetText(C:LocalizeDisplay(button.filterOptions[ui.questFilterMode[key]]))
            button:Show()
        end
    end
    local listOffset = questView and 70 or 0
    ui.listTitle:ClearAllPoints(); ui.listTitle:SetPoint("TOPLEFT", 12, -228 - listOffset)
    ui.listTitle:SetText(C:L(ui.mode == "bosses" and "encounters" or
        (ui.mode == "quests" and "dungeonQuests" or
        (ui.mode == "map" and "dungeonMap" or "lootCatalog"))))
    ui.listTitle:Show()
    local rows = buildEntries(dungeon, ui.mode)
    local selectedIndex = math.min(ui.selectedIndex[ui.mode] or 1, #rows)
    if ui.mode == "loot" and rows[selectedIndex] and rows[selectedIndex].groupKey then
        local first
        for index, entry in ipairs(rows) do
            if entry.itemID then first = index; break end
        end
        selectedIndex = first or 0
    end
    ui.selectedIndex[ui.mode] = selectedIndex
    local selected = rows[selectedIndex]
    for index, info in ipairs(rows) do
        local row = ensureEntry(parent, index)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 5, -257 - listOffset - (index - 1) * 49)
        row:SetSize(leftWidth, 47)
        row.entryIndex = index
        row.groupKey = info.groupKey
        row.itemID, row.itemName, row.itemMeta, row.itemQuality =
            info.itemID, info.title, info.meta, info.quality
        row.itemChance,row.itemSource=info.chance,info.source
        if info.boss then setBossIcon(row.bossIcon, info.boss)
        else row.icon:SetTexture(info.icon) end
        row.icon:SetShown(info.boss == nil and not info.groupKey)
        row.alliance:SetShown(ui.mode == "quests" and info.data and info.data.faction ~= "Horde")
        row.horde:SetShown(ui.mode == "quests" and info.data and info.data.faction ~= "Alliance")
        row.bossFrame:SetShown(info.boss ~= nil)
        if info.boss then
            row.bossRank:SetVertexColor(bossRankColor(info.rank))
            row.bossDragon:SetTexture(bossDragonTexture(info.rank))
            local r, g, b = bossRankColor(info.rank)
            row.bossLevelRing:SetColorTexture(r, g, b, 1)
        end
        row.bossLevelBg:SetShown(info.boss ~= nil and (info.level ~= nil or info.rank == 3))
        row.bossLevelValue = info.boss and info.level or nil
        if row.bossLevelValue then
            row.bossLevel:SetText(tostring(row.bossLevelValue))
            row.bossLevel:SetTextColor(C:BossDifficultyColor(row.bossLevelValue))
        end
        local skull = info.boss and (info.rank == 3 or (info.level and info.level >= 63))
        row.bossSkull:SetShown(skull and true or false)
        row.bossLevel:SetShown(not skull and row.bossLevelValue ~= nil)
        row.title:ClearAllPoints(); row.meta:ClearAllPoints()
        row.title:SetPoint("TOPLEFT", info.groupKey and 17 or 72, -9)
        row.meta:SetPoint("BOTTOMLEFT", info.groupKey and 17 or 72, 9)
        local labelWidth = leftWidth - (info.groupKey and 32 or
            (ui.mode == "quests" and 125 or 80))
        row.title:SetText(info.title); row.title:SetWidth(labelWidth)
        row.meta:SetText(info.meta); row.meta:SetWidth(labelWidth)
        row.band:SetVertexColor(.09, .085, .075, index == selectedIndex and .75 or .16)
        row.accent:SetVertexColor(1, .73, .19, index == selectedIndex and 1 or .3)
        if info.groupKey then row.title:SetTextColor(unpack(GOLD))
        elseif info.itemID then row.title:SetTextColor(itemColor(info.itemID, info.quality))
        else row.title:SetTextColor(unpack(index == selectedIndex and GOLD or TEXT)) end
        row:Show()
    end
    if ui.mode == "map" then
        ui.detailTitle:ClearAllPoints(); ui.detailTitle:SetPoint("TOPLEFT", rightX, -225)
        ui.detailTitle:SetWidth(rightWidth)
        ui.detailTitle:SetText(selected and selected.title or C:L("noEntries"))
        ui.detailTitle:Show()
        if not ui.mapFrame then
            ui.mapFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            ui.mapFrame:EnableMouse(true)
            ui.mapFrame:SetScript("OnMouseUp", function(_, button)
                if button ~= "LeftButton" or not ui.selected then return end
                local floors = C:GetDungeonMapFloors(ui.selected)
                local floor = floors[ui.selectedIndex.map or 1]
                if floor then C:ShowDungeonMapWindow(ui.selected, floor) end
            end)
            ui.mapFrame:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetText(C:L("openLargeMap"))
                GameTooltip:Show()
            end)
            ui.mapFrame:SetScript("OnLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
            ui.mapFrame:SetBackdrop({ bgFile = WHITE,
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 13,
                insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            ui.mapFrame:SetBackdropColor(.03, .029, .027, 1)
            ui.mapFrame:SetBackdropBorderColor(.59, .44, .17, 1)
            if ui.mapFrame.SetClipsChildren then ui.mapFrame:SetClipsChildren(true) end
            ui.mapFrame.tiles = {}
            ui.mapFrame.message = text(ui.mapFrame, 13, MUTED)
            ui.mapFrame.message:SetPoint("CENTER")
            ui.mapFrame.overview = text(ui.mapFrame, 12, MUTED)
            ui.mapFrame.overview:SetPoint("TOPLEFT", 20, -16)
            ui.mapFrame.overview:SetText(C:L("mapSchematic"))
            ui.mapFrame.nodes = {}
            ui.mapFrame.art = ui.mapFrame:CreateTexture(nil, "BACKGROUND")
            ui.mapFrame.art:SetAllPoints(ui.mapFrame)
            ui.mapFrame.art:SetAlpha(.14)
        end
        local frame = ui.mapFrame
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", rightX, -269)
        frame:SetSize(rightWidth, math.min(360, rightWidth * .7))
        if not ui.mapHint then
            ui.mapHint = text(parent, 12, GOLD)
            ui.mapHint:SetJustifyH("CENTER")
        end
        ui.mapHint:ClearAllPoints()
        ui.mapHint:SetPoint("TOP", frame, "BOTTOM", 0, -9)
        ui.mapHint:SetWidth(rightWidth)
        ui.mapHint:SetText(C:L("openLargeMap"))
        ui.mapHint:Show()
        for _, tile in ipairs(frame.tiles) do tile:Hide() end
        for _, node in ipairs(frame.nodes) do node:Hide() end
        frame.overview:Hide(); frame.art:Hide()
        local floor = selected and selected.data
        local layers
        if floor and C_Map and C_Map.GetMapArtLayers then
            local ok, value = pcall(C_Map.GetMapArtLayers, floor.id)
            if ok then layers = value end
        end
        local layer = layers and layers[1]
        local images
        if layer and C_Map.GetMapArtLayerTextures then
            local ok, value = pcall(C_Map.GetMapArtLayerTextures, floor.id, 1)
            if ok then images = value end
        end
        if floor and floor.file then
            local tile = frame.tiles[1]
            if not tile then
                tile = frame:CreateTexture(nil, "ARTWORK")
                frame.tiles[1] = tile
            end
            local imageWidth, imageHeight = floor.width or 1024, floor.height or 683
            local scale = math.min((rightWidth - 8) / imageWidth,
                (frame:GetHeight() - 8) / imageHeight)
            tile:ClearAllPoints(); tile:SetPoint("CENTER", frame, "CENTER")
            tile:SetSize(imageWidth * scale, imageHeight * scale)
            tile:SetTexture(floor.file)
            tile:SetTexCoord(0, math.min(1, imageWidth / (floor.fileWidth or 1024)),
                0, math.min(1, imageHeight / (floor.fileHeight or 1024)))
            tile:Show(); frame.message:Hide()
        elseif layer and images and #images > 0 and layer.layerWidth and layer.layerHeight and
            layer.tileWidth and layer.tileHeight then
            local columns = math.ceil(layer.layerWidth / layer.tileWidth)
            local innerWidth, innerHeight = rightWidth - 8, frame:GetHeight() - 8
            local scale = math.min(innerWidth / layer.layerWidth, innerHeight / layer.layerHeight)
            local mapWidth, mapHeight = layer.layerWidth * scale, layer.layerHeight * scale
            local originX, originY = (rightWidth - mapWidth) / 2, -(frame:GetHeight() - mapHeight) / 2
            for index, imageID in ipairs(images) do
                local tile = frame.tiles[index]
                if not tile then
                    tile = frame:CreateTexture(nil, "ARTWORK")
                    frame.tiles[index] = tile
                end
                local col, row = (index - 1) % columns, math.floor((index - 1) / columns)
                tile:ClearAllPoints()
                tile:SetPoint("TOPLEFT", frame, "TOPLEFT",
                    originX + col * layer.tileWidth * scale,
                    originY - row * layer.tileHeight * scale)
                tile:SetSize(layer.tileWidth * scale, layer.tileHeight * scale)
                tile:SetTexture(imageID)
                tile:Show()
            end
            frame.message:Hide()
        else
            local bosses = encounterBosses(dungeon)
            local art = C:GetPackagedInstanceArt(dungeon.artName or name)
            if art then frame.art:SetTexture(art); frame.art:Show() end
            frame.overview:SetText(C:L("mapSchematic")); frame.overview:Show()
            if #bosses > 0 then
                for index = 1, math.min(#bosses, 10) do
                    local node = frame.nodes[index]
                    if not node then
                        node = CreateFrame("Frame", nil, frame)
                        node.dot = node:CreateTexture(nil, "ARTWORK")
                        node.dot:SetTexture("Interface\\AddOns\\Chronicle\\BossMedallion")
                        node.dot:SetSize(30, 30); node.dot:SetPoint("LEFT", 0, 0)
                        node.label = text(node, 12, GOLD)
                        node.label:SetPoint("LEFT", node.dot, "RIGHT", 6, 0)
                        frame.nodes[index] = node
                    end
                    local column = (index - 1) % 2
                    local row = math.floor((index - 1) / 2)
                    node:ClearAllPoints()
                    node:SetPoint("TOPLEFT", frame, "TOPLEFT",
                        18 + column * ((rightWidth - 30) / 2), -55 - row * 56)
                    node:SetSize((rightWidth - 42) / 2, 42)
                    node.label:SetWidth((rightWidth - 42) / 2 - 39)
                    node.label:SetText(index .. ". " .. U.SafeText(bosses[index].name, "Boss"))
                    node:Show()
                end
                frame.message:Hide()
            else
                frame.message:SetText(C:L("noEntries")); frame.message:Show()
            end
        end
        frame:Show()
        parent:SetHeight(math.max(680, 270 + #rows * 49,
            269 + frame:GetHeight() + 37))
        return
    end
    local faction = questView and selected and selected.data.faction
    local factionIcon = faction and (questFactionIcon(selected.data) or
        "Interface\\AddOns\\Chronicle\\FactionAlliance.tga")
    local twoFactions = faction and faction ~= "Alliance" and faction ~= "Horde"
    ui.detailFaction:SetShown(factionIcon and true or false)
    ui.detailFactionOther:SetShown(twoFactions and true or false)
    if factionIcon then
        ui.detailFaction:SetTexture(factionIcon)
        ui.detailFaction:ClearAllPoints()
        ui.detailFaction:SetPoint("TOPLEFT", rightX, -223)
    end
    if twoFactions then
        ui.detailFactionOther:SetTexture("Interface\\AddOns\\Chronicle\\FactionHorde.tga")
        ui.detailFactionOther:ClearAllPoints()
        ui.detailFactionOther:SetPoint("TOPLEFT", rightX + 34, -223)
    end
    local factionInset = twoFactions and 76 or factionIcon and 40 or 0
    ui.detailTitle:ClearAllPoints(); ui.detailTitle:SetPoint("TOPLEFT", rightX + factionInset, -225)
    ui.detailTitle:SetWidth(rightWidth - factionInset)
    ui.detailTitle:SetText(selected and selected.title or C:L("noEntries"))
    ui.detailTitle:Show()
    ui.detailMeta:ClearAllPoints(); ui.detailMeta:SetPoint("TOPLEFT", rightX + 1, -264)
    ui.detailMeta:SetWidth(rightWidth); ui.detailMeta:SetText(selected and selected.meta or "")
    ui.detailMeta:Show()
    ui.detailBody:ClearAllPoints(); ui.detailBody:SetPoint("TOPLEFT", rightX + 1, -294)
    local liveDescription, liveObjectives
    if questView and selected and C.API and C.API.QuestText then
        liveDescription, liveObjectives = C.API.QuestText(selected.data.id)
    end
    local objectiveText = questView and selected and
        (selected.data.objective or liveObjectives or liveDescription) or ""
    local bodyHeight = questView and math.max(94, math.ceil(#objectiveText / math.max(36, math.floor(rightWidth / 7))) * 17 + 18) or 94
    ui.detailBody:SetWidth(rightWidth - 8); ui.detailBody:SetHeight(bodyHeight)
    local noteLength = questView and selected and #(selected.data.note or "") or 0
    local descriptionLength = questView and selected and liveDescription and
        liveDescription ~= objectiveText and #liveDescription or 0
    local chainLength = questView and selected and questChainLabel(selected.data) and 24 or 0
    local factionHeight = questView and selected and questFactionLabel(selected.data) and 18 or 0
    local extraHeight = questView and (math.max(90,
        90 + chainLength + math.ceil((noteLength + descriptionLength) / math.max(36, math.floor(rightWidth / 7))) * 17) + factionHeight) or 28
    local extraY = questView and (294 + bodyHeight + 5) or 344
    local sectionY = questView and (extraY + extraHeight + 10) or 370
    local itemY = sectionY + (questView and 155 or 35)
    ui.detailExtra:ClearAllPoints()
    ui.detailExtra:SetPoint("TOPLEFT", rightX + 1, -extraY)
    ui.detailExtra:SetWidth(rightWidth - 8)
    ui.detailExtra:SetHeight(extraHeight)
    ui.detailSection:ClearAllPoints(); ui.detailSection:SetPoint("TOPLEFT", rightX + 1, -sectionY)
    ui.detailRule:ClearAllPoints()
    ui.detailRule:SetPoint("TOPLEFT", rightX, -sectionY - (questView and 23 or 24))
    ui.detailRule:SetWidth(rightWidth)
    local items = {}
    if selected and ui.mode == "bosses" then
        local boss = selected.data
        ui.detailBody:SetText(C:LocalizeCatalog(U.SafeText(boss.description,
            lootGroups[boss.name] and C:LocalizeDisplay("Weitere Beute in ") .. C:LocalizeInstanceName(name) .. "." or
            C:LocalizeDisplay("Bossbegegnung in ") .. C:LocalizeInstanceName(name) .. ".")))
        ui.detailExtra:SetText("")
        ui.detailSection:SetText(C:L("bossLoot"))
        local shared = sharedRaidLoot(dungeon)
        local seen = {}
        for _, item in ipairs(boss.loot or {}) do
            if hasItemData(item) and not seen[item[1]] then
                seen[item[1]] = true
                items[#items + 1] = { id = item[1], name = item[2],
                    meta = itemSlot(item[1], itemFallbackSlot(item)), shared = shared[item[1]],
                    quality = item[4], chance = item[5], source = boss.name }
            end
        end
    elseif selected and ui.mode == "quests" then
        local quest = selected.data
        ui.activeQuestID = quest.id
        if quest.id and not ui.questDataRequested[quest.id] and C_QuestLog and C_QuestLog.RequestLoadQuestByID then
            ui.questDataRequested[quest.id] = true
            pcall(C_QuestLog.RequestLoadQuestByID, quest.id)
        end
        ui.detailBody:SetText(C:LocalizeCatalog(U.SafeText(objectiveText, C:L("noObjective"))))
        local factionLabel = questFactionLabel(quest)
        ui.detailExtra:SetText((liveDescription and liveDescription ~= objectiveText and
            (liveDescription .. "\n\n") or "") ..
            (factionLabel and (C:L("questFaction") .. factionLabel .. "\n") or "") ..
            questStateLabel(questState(quest.id)) .. "\n" ..
            (quest.requires and (C:LocalizeDisplay("Mindeststufe") .. ": " .. quest.requires .. "\n") or "") ..
            (questChainLabel(quest) and (questChainLabel(quest) .. "\n") or "") ..
            C:L("questGiver") .. C:LocalizeCatalog(U.SafeText(quest.pickup, C:L("notRecorded"))) ..
            "\n" .. C:L("turnIn") .. C:LocalizeCatalog(U.SafeText(quest.turnin, C:L("notRecorded"))) ..
            (quest.note and ("\n" .. C:L("hint") .. C:LocalizeCatalog(quest.note)) or "") ..
            (quest.complexWide and ("\n" .. C:LocalizeDisplay("Die Quest gehört zum gesamten Instanzkomplex; der genaue Flügel kann abweichen.")) or ""))
        ui.detailSection:SetText(C:L("rewards"))
        local xp, money, reputation = questRewards(quest)
        local values = { xp, money, reputation }
        local statWidth = math.floor((rightWidth - 22) / 3)
        for index, stat in ipairs(ui.rewardStats) do
            stat:ClearAllPoints()
            stat:SetPoint("TOPLEFT", rightX + (index - 1) * (statWidth + 11), -sectionY - 35)
            stat:SetSize(statWidth, 69)
            stat.value:SetWidth(statWidth - 8)
            stat.label:SetWidth(statWidth - 8)
            stat.value:SetText(values[index])
            stat:Show()
        end
        for _, item in ipairs(quest.rewardItems or {}) do
            if hasItemData(item) then
                local category=C:ItemCategory(item[1])
                items[#items + 1] = { id = item[1], name = item[2],
                    meta = category and (category.."  ·  Questbelohnung") or "Questbelohnung",
                    quality = item[3] }
            end
        end
        if #items > 0 then
            ui.itemsTitle:ClearAllPoints()
            ui.itemsTitle:SetPoint("TOPLEFT", rightX + 1, -itemY + 3)
            ui.itemsTitle:SetText(C:L(quest.rewardChoice and "chooseItem" or "items"))
            ui.itemsTitle:Show()
            itemY = itemY + 31
        end
    elseif selected then
        local info = selected.data
        ui.detailBody:SetText(C:LocalizeDisplay("Quellen") .. ":\n" ..
            itemSourceText(dungeon, info.item[1]))
        ui.detailExtra:SetText(C:L("equipmentSlot") .. itemSlot(info.item[1], itemFallbackSlot(info.item)))
        ui.detailSection:SetText(C:L("item"))
        items[1] = { id = info.item[1], name = info.item[2], meta = lootMeta(info.item),
            quality = info.item[4], chance=info.item[5],source=info.boss.name }
    else
        ui.detailBody:SetText(dungeon.preview and
            C:L("previewDetail") or C:L("noSelectionEntries"))
        ui.detailExtra:SetText("")
        ui.detailSection:SetText("")
    end
    ui.detailBody:Show(); ui.detailExtra:Show()
    ui.detailSection:Show(); ui.detailRule:Show()
    local _, detailHeight = buildDetails(parent, rightX, rightWidth,
        itemY, items, selected and ui.mode == "bosses" and
        (ui.kind .. ":" .. name .. ":" .. selected.data.name) or nil)
    ui.source:ClearAllPoints()
    ui.source:SetText(questView and C:L("questExperienceHint") or "")
    ui.source:SetPoint("TOPLEFT", rightX, -math.max(
        questView and (sectionY + 126) or (itemY + 53), itemY + detailHeight + 10))
    ui.source:SetWidth(rightWidth); ui.source:SetHeight(32)
    if questView then ui.source:Show() else ui.source:Hide() end
    parent:SetHeight(math.max(560, 270 + listOffset + #rows * 49,
        questView and (sectionY + 165) or 0, itemY + detailHeight + 43))
end

function C:ShowDungeonKnowledge(parent, width, kind)
    if kind and kind ~= ui.kind then
        ui.kind, ui.selected, ui.mode, ui.selectedIndex = kind, nil, "bosses", {}
    end
    ui.parent, ui.width = parent, width
    self:RefreshInstanceKnowledge()
    ensureHero(parent)
    ui.back.label:SetText(self:L("backOverview"))
    for _, tab in ipairs(ui.tabs) do tab.label:SetText(self:L(tab.localeKey)) end
    for _, stat in ipairs(ui.rewardStats) do stat.label:SetText(self:L(stat.localeKey)) end
    self:HideDungeonKnowledge()
    local raid = ui.kind == "raids"
    local catalog = raid and (self.raidKnowledge or {}) or (self.dungeonKnowledge or {})
    local order = raid and (self.raidKnowledgeOrder or {}) or (self.dungeonKnowledgeOrder or {})
    ui.hero:ClearAllPoints(); ui.hero:SetPoint("TOPLEFT", 4, 0)
    ui.hero:SetWidth(width); ui.hero:Show()
    if ui.selected and catalog[ui.selected] then
        showDetail(parent, width, catalog)
    else
        ui.selected = nil
        showHome(parent, width, order, catalog)
    end
end

function C:FocusDungeonBoss(instanceName, bossName)
    local catalog = ui.kind == "raids" and self.raidKnowledge or self.dungeonKnowledge
    local dungeon = catalog and catalog[instanceName]
    if not dungeon then return end
    for index, boss in ipairs(encounterBosses(dungeon)) do
        if boss.name == bossName then
            ui.selected, ui.mode, ui.selectedIndex.bosses = instanceName, "bosses", index
            if ui.parent then self:ShowDungeonKnowledge(ui.parent, ui.width) end
            return
        end
    end
end
