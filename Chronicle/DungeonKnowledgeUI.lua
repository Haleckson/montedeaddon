local C = _G.Chronicle
local U = C.Util
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, .82, .1 }
local TEXT = { .96, .91, .78 }
local MUTED = { .84, .77, .65 }
local XP_COLOR = { .57, .78, 1 }
local REP_COLOR = { .68, .88, .58 }
local ui = { mode = "bosses", kind = "dungeons", selectedIndex = {}, covers = {}, entries = {}, details = {}, tabs = {} }

local function playerFaction()
    return UnitFactionGroup and UnitFactionGroup("player") or nil
end

local function availableQuests(dungeon)
    local quests = {}
    local faction = playerFaction()
    for _, quest in ipairs(dungeon.quests or {}) do
        if not quest.faction or quest.faction == "Both" or quest.faction == faction then
            quests[#quests + 1] = quest
        end
    end
    return quests
end

local function formatXP(value)
    if not value then return C:L("unavailable") end
    local digits = tostring(value):gsub("[^%d]", "")
    return digits:reverse():gsub("(%d%d%d)(%d)", "%1.%2"):reverse() .. C:L("xpUnit")
end

local function questRewards(quest)
    local summary = quest.rewardSummary or ""
    local xp = quest.liveXPFallback or summary:match("([%d,]+)%s*XP")
    local money = summary:match("(%d+g%s*%d+s%s*%d+c)") or
        summary:match("(%d+g%s*%d+s)") or summary:match("(%d+g)") or
        summary:match("(%d+s%s*%d+c)") or summary:match("(%d+s)") or
        summary:match("(%d+c)")
    local reputation = {}
    for faction, amount in summary:gmatch("([%a%s%-']+)%s+%+(%d+)") do
        faction = faction:match("^%s*(.-)%s*$")
        if faction ~= "" then reputation[#reputation + 1] = faction .. " +" .. amount end
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
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function itemName(id, fallback)
    if id and C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if id and GetItemInfo then
        local ok, name = pcall(GetItemInfo, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return U.SafeText(fallback, C:L("item"))
end

local function itemColor(id, fallbackQuality)
    local quality = fallbackQuality
    if id and GetItemInfo then
        local ok, _, _, value = pcall(GetItemInfo, id)
        if ok and type(value) == "number" then quality = value end
    end
    if id and not quality and C_Item and C_Item.GetItemQualityByID then
        local ok, value = pcall(C_Item.GetItemQualityByID, id)
        if ok and type(value) == "number" then quality = value end
    end
    if id and not quality and C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
    if type(quality) == "number" and GetItemQualityColor then
        local ok, red, green, blue = pcall(GetItemQualityColor, quality)
        if ok and red then return red, green, blue end
    end
    return unpack(TEXT)
end

local function setBossIcon(texture, boss)
    local displayID = boss and
        (C:GetAzerothBossDisplayID(ui.selected, boss.name) or boss.displayID)
    if displayID and SetPortraitTextureFromCreatureDisplayID then
        local ok = pcall(SetPortraitTextureFromCreatureDisplayID, texture, displayID)
        if ok then return end
    end
    texture:SetTexture(boss and boss.customIcon or "Interface\\AddOns\\Chronicle\\BossMedallion")
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
    hero:SetBackdropColor(.16, .105, .052, 1)
    hero:SetBackdropBorderColor(.59, .44, .17, 1)
    C:ApplyMaterial(hero, .3); C:OrnateCorners(hero)
    hero.art = hero:CreateTexture(nil, "ARTWORK", nil, -3)
    hero.art:SetPoint("TOPRIGHT", -5, -5)
    hero.art:SetPoint("BOTTOMRIGHT", -5, 5)
    hero.art:SetAlpha(.48)
    hero.shade = texture(hero, "ARTWORK", .11, .07, .035, .42)
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
    ui.back:SetBackdropColor(.09, .06, .035, .96)
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
    ui.detailMeta = text(parent, 12, GOLD)
    ui.detailBody = text(parent, 13, TEXT)
    ui.detailBody:SetJustifyV("TOP")
    ui.detailExtra = text(parent, 12, MUTED)
    ui.detailExtra:SetJustifyV("TOP")
    ui.detailSection = text(parent, 14, GOLD)
    ui.detailRule = texture(parent, "ARTWORK", .56, .38, .16, .8)
    ui.detailRule:SetHeight(1)
    ui.source = text(parent, 11, MUTED)
    ui.source:SetText(C:LocalizeDisplay("Katalog: Forever Dungeon Journal v1.3.0 von Exehn · Darstellung: Chronicle"))
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
        stat.rule:SetWidth(1)
        ui.rewardStats[index] = stat
    end
    ui.itemsTitle = text(parent, 13, GOLD)
    ui.itemInfoEvents = CreateFrame("Frame")
    ui.itemInfoEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    ui.itemInfoEvents:SetScript("OnEvent", function()
        if ui.parent and ui.selected and ui.hero and ui.hero:IsShown() and
            (ui.mode == "loot" or ui.mode == "bosses") and not ui.itemRefreshPending then
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
    card:SetBackdropColor(.07, .05, .03, 1)
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
    row.band = texture(row, "BACKGROUND", .27, .16, .06, .2)
    row.band:SetAllPoints(row)
    row.accent = texture(row, "ARTWORK", 1, .72, .18, .4)
    row.accent:SetPoint("TOPLEFT", 0, -4); row.accent:SetPoint("BOTTOMLEFT", 0, 4)
    row.accent:SetWidth(2)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(33, 33); row.icon:SetPoint("LEFT", 9, 0)
    row.title = text(row, 14, TEXT)
    row.title:SetPoint("TOPLEFT", 51, -9)
    row.meta = text(row, 11, MUTED)
    row.meta:SetPoint("BOTTOMLEFT", 51, 9)
    row.rule = texture(row, "ARTWORK", .42, .29, .13, .7)
    row.rule:SetPoint("BOTTOMLEFT", 10, 0); row.rule:SetPoint("BOTTOMRIGHT", -4, 0)
    row.rule:SetHeight(1)
    row:SetScript("OnClick", function(self)
        ui.selectedIndex[ui.mode] = self.entryIndex
        C:ShowDungeonKnowledge(ui.parent, ui.width)
    end)
    row:SetScript("OnEnter", function(self)
        if not self.itemID or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        if GameTooltip.SetHyperlink then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.itemID)
            if not ok then GameTooltip:SetText(self.itemName or C:L("item")) end
        else GameTooltip:SetText(self.itemName or C:L("item")) end
        GameTooltip:Show()
    end)
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
    row.title = text(row, 13, TEXT)
    row.title:SetPoint("TOPLEFT", 39, -4)
    row.meta = text(row, 11, MUTED)
    row.meta:SetPoint("TOPLEFT", 39, -24)
    row.rule = texture(row, "ARTWORK", .42, .29, .13, .64)
    row.rule:SetPoint("BOTTOMLEFT", 2, 0); row.rule:SetPoint("BOTTOMRIGHT", -2, 0)
    row.rule:SetHeight(1)
    row:SetScript("OnEnter", function(self)
        if not self.itemID or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        if GameTooltip.SetHyperlink then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.itemID)
            if not ok then GameTooltip:SetText(self.itemName or C:L("item")) end
        else GameTooltip:SetText(self.itemName or C:L("item")) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    ui.details[index] = row
    return row
end

function C:HideDungeonKnowledge()
    if ui.hero then ui.hero:Hide() end
    if ui.back then ui.back:Hide() end
    if ui.listTitle then ui.listTitle:Hide() end
    if ui.detailTitle then ui.detailTitle:Hide() end
    if ui.detailMeta then ui.detailMeta:Hide() end
    if ui.detailBody then ui.detailBody:Hide() end
    if ui.detailExtra then ui.detailExtra:Hide() end
    if ui.detailSection then ui.detailSection:Hide() end
    if ui.detailRule then ui.detailRule:Hide() end
    if ui.source then ui.source:Hide() end
    if ui.mapFrame then ui.mapFrame:Hide() end
    if ui.itemsTitle then ui.itemsTitle:Hide() end
    for _, stat in ipairs(ui.rewardStats or {}) do stat:Hide() end
    for _, button in ipairs(ui.tabs) do button:Hide() end
    for _, button in ipairs(ui.covers) do button:Hide() end
    for _, row in ipairs(ui.entries) do row:Hide() end
    for _, row in ipairs(ui.details) do row:Hide() end
end

local function showHome(parent, width, order, catalog)
    local raid = ui.kind == "raids"
    ui.hero:SetHeight(136)
    ui.hero.caption:SetText(C:LocalizeDisplay(raid and "CHRONICLE  /  RAIDWISSEN" or "CHRONICLE  /  INSTANZWISSEN"))
    ui.hero.caption:Show()
    ui.hero.title:SetText(C:L(raid and "raidsOfJourney" or "hallsOfJourney"))
    ui.hero.meta:SetText(raid and C:LocalizeDisplay("BOSSE  ·  BEUTE") or C:LocalizeDisplay("BOSSE  ·  QUESTS  ·  BEUTE"))
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
            raid and (#(data.bosses or {}) .. " " .. C:L("bosses")) or
            (#(data.bosses or {}) .. " " .. C:L("bosses") .. "    ·    " ..
            (questCount == 0 and ((data.journalSource or data.atlasSource) and C:L("questsUnrecorded") or
                C:L("noFactionQuests")) or questCount .. " " .. C:L("questCount"))))
        card.level:SetText(data.level and (C:L("level") .. " " .. tostring(data.level)) or "ENCOUNTER JOURNAL")
        card:Show()
    end
    parent:SetHeight(157 + math.ceil(#order / 2) * 96 + 8)
end

local function buildEntries(dungeon, mode)
    local rows = {}
    if mode == "bosses" then
        for _, boss in ipairs(dungeon.bosses or {}) do
            rows[#rows + 1] = { title = U.SafeText(boss.name, "Boss"),
                meta = #(boss.loot or {}) .. C:L("lootPieces"),
                icon = boss.rare and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or
                    "Interface\\AddOns\\Chronicle\\BossMedallion", data = boss, boss = boss }
        end
    elseif mode == "map" then
        for _, floor in ipairs(C:GetDungeonMapFloors(ui.selected)) do
            rows[#rows + 1] = { title = floor.name, meta = C:L("dungeonMap"),
                icon = "Interface\\Icons\\INV_Misc_Map_01", data = floor }
        end
    elseif mode == "quests" then
        for _, quest in ipairs(availableQuests(dungeon)) do
            local xp = questRewards(quest)
            rows[#rows + 1] = { title = questName(quest),
                meta = C:L("level") .. " " .. tostring(quest.level or "?") .. "  ·  " .. xp,
                icon = "Interface\\Icons\\INV_Misc_Note_01", data = quest }
        end
    else
        for _, boss in ipairs(dungeon.bosses or {}) do
            for _, item in ipairs(boss.loot or {}) do
                rows[#rows + 1] = { title = itemName(item[1], item[2]),
                    meta = U.SafeText(boss.name, "Boss"), icon = itemIcon(item[1]),
                    itemID = item[1], quality = item[4], data = { item = item, boss = boss } }
            end
        end
    end
    return rows
end

local function buildDetails(parent, x, width, startY, items)
    local used = 0
    for _, info in ipairs(items) do
        used = used + 1
        local row = ensureDetail(parent, used)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", x, -startY - (used - 1) * 43)
        row:SetSize(width, 41)
        row.icon:SetTexture(itemIcon(info.id))
        row.title:SetText(itemName(info.id, info.name))
        row.title:SetTextColor(itemColor(info.id, info.quality))
        row.title:SetWidth(width - 45)
        row.meta:SetText(U.SafeText(info.meta, ""))
        row.meta:SetWidth(width - 45)
        row.itemID, row.itemName = info.id, info.name
        row:Show()
    end
    return used
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
    ui.hero.count:SetText(#(dungeon.bosses or {}) .. " " .. C:L("bosses") ..
        (raid and "" or ("    |    " .. #availableQuests(dungeon) .. " " .. C:L("questCount"))))
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

    local tabWidth = math.floor((width - 16) / (raid and 3 or 4))
    for index, button in ipairs(ui.tabs) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 4 + (raid and (index == 1 and 0 or index == 3 and 1 or 2) or
            (index - 1)) * (tabWidth + 8), -177)
        button:SetSize(tabWidth, 29)
        local active = button.mode == ui.mode
        C:StyleChronicleButton(button, active)
        button.label:SetFont(C:FontPath(), 12)
        button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:SetShown(not raid or index ~= 2)
    end
    ui.listTitle:ClearAllPoints(); ui.listTitle:SetPoint("TOPLEFT", 12, -228)
    ui.listTitle:SetText(C:L(ui.mode == "bosses" and "encounters" or
        (ui.mode == "quests" and "dungeonQuests" or
        (ui.mode == "map" and "dungeonMap" or "lootCatalog"))))
    ui.listTitle:Show()
    local rows = buildEntries(dungeon, ui.mode)
    local selectedIndex = math.min(ui.selectedIndex[ui.mode] or 1, #rows)
    ui.selectedIndex[ui.mode] = selectedIndex
    local selected = rows[selectedIndex]
    for index, info in ipairs(rows) do
        local row = ensureEntry(parent, index)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 5, -257 - (index - 1) * 49)
        row:SetSize(leftWidth, 47)
        row.entryIndex = index
        row.itemID, row.itemName = info.itemID, info.title
        if info.boss then setBossIcon(row.icon, info.boss)
        else row.icon:SetTexture(info.icon) end
        row.title:SetText(info.title); row.title:SetWidth(leftWidth - 59)
        row.meta:SetText(info.meta); row.meta:SetWidth(leftWidth - 59)
        row.band:SetVertexColor(.28, .17, .065, index == selectedIndex and .7 or .13)
        row.accent:SetVertexColor(1, .73, .19, index == selectedIndex and 1 or .3)
        if info.itemID then row.title:SetTextColor(itemColor(info.itemID, info.quality))
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
            ui.mapFrame:SetBackdrop({ bgFile = WHITE,
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 13,
                insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            ui.mapFrame:SetBackdropColor(.08, .055, .033, 1)
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
            local bosses = dungeon.bosses or {}
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
        parent:SetHeight(math.max(680, 270 + #rows * 49))
        return
    end
    ui.detailTitle:ClearAllPoints(); ui.detailTitle:SetPoint("TOPLEFT", rightX, -225)
    ui.detailTitle:SetWidth(rightWidth)
    ui.detailTitle:SetText(selected and selected.title or C:L("noEntries"))
    ui.detailTitle:Show()
    ui.detailMeta:ClearAllPoints(); ui.detailMeta:SetPoint("TOPLEFT", rightX + 1, -264)
    ui.detailMeta:SetWidth(rightWidth); ui.detailMeta:SetText(selected and selected.meta or "")
    ui.detailMeta:Show()
    ui.detailBody:ClearAllPoints(); ui.detailBody:SetPoint("TOPLEFT", rightX + 1, -294)
    ui.detailBody:SetWidth(rightWidth - 8); ui.detailBody:SetHeight(94)
    local questView = ui.mode == "quests"
    local noteLength = questView and selected and #(selected.data.note or "") or 0
    local extraHeight = questView and math.max(70, 44 + math.ceil(noteLength / 67) * 16) or 28
    local sectionY = questView and (393 + extraHeight + 10) or 370
    local itemY = sectionY + (questView and 155 or 35)
    ui.detailExtra:ClearAllPoints()
    ui.detailExtra:SetPoint("TOPLEFT", rightX + 1, questView and -393 or -344)
    ui.detailExtra:SetWidth(rightWidth - 8)
    ui.detailExtra:SetHeight(extraHeight)
    ui.detailSection:ClearAllPoints(); ui.detailSection:SetPoint("TOPLEFT", rightX + 1, -sectionY)
    ui.detailRule:ClearAllPoints()
    ui.detailRule:SetPoint("TOPLEFT", rightX, -sectionY - (questView and 23 or 24))
    ui.detailRule:SetWidth(rightWidth)
    local items = {}
    if selected and ui.mode == "bosses" then
        local boss = selected.data
        ui.detailBody:SetText(C:LocalizeCatalog(U.SafeText(boss.description, C:LocalizeDisplay("Bossbegegnung in ") .. C:LocalizeInstanceName(name) .. ".")))
        ui.detailExtra:SetText(boss.rare and C:L("rareEnemy") or "")
        ui.detailSection:SetText(C:L("bossLoot"))
        for _, item in ipairs(boss.loot or {}) do
            items[#items + 1] = { id = item[1], name = item[2], meta = item[3], quality = item[4] }
        end
    elseif selected and ui.mode == "quests" then
        local quest = selected.data
        ui.detailBody:SetText(C:LocalizeCatalog(U.SafeText(quest.objective, C:L("noObjective"))))
        ui.detailExtra:SetText(C:L("questGiver") .. C:LocalizeCatalog(U.SafeText(quest.pickup, C:L("notRecorded"))) ..
            "\n" .. C:L("turnIn") .. C:LocalizeCatalog(U.SafeText(quest.turnin, C:L("notRecorded"))) ..
            (quest.note and ("\n" .. C:L("hint") .. C:LocalizeCatalog(quest.note)) or ""))
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
            items[#items + 1] = { id = item[1], name = item[2], meta = "Questbelohnung", quality = item[3] }
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
        ui.detailBody:SetText(C:LocalizeDisplay("Beute von ") .. U.SafeText(info.boss.name, "Boss") ..
            C:LocalizeDisplay(" in ") .. C:LocalizeInstanceName(name) .. ".")
        ui.detailExtra:SetText(C:L("equipmentSlot") .. U.SafeText(info.item[3], C:L("notRecorded")))
        ui.detailSection:SetText(C:L("item"))
        items[1] = { id = info.item[1], name = info.item[2], meta = info.item[3], quality = info.item[4] }
    else
        ui.detailBody:SetText(dungeon.preview and
            C:L("previewDetail") or C:L("noSelectionEntries"))
        ui.detailExtra:SetText("")
        ui.detailSection:SetText("")
    end
    ui.detailBody:Show(); ui.detailExtra:Show()
    ui.detailSection:Show(); ui.detailRule:Show()
    local detailCount = buildDetails(parent, rightX, rightWidth, itemY, items)
    ui.source:ClearAllPoints()
    ui.source:SetText(dungeon.journalSource and
        C:LocalizeDisplay("Daten: Encounter Journal des Forever-Clients · Darstellung: Chronicle") or
        dungeon.atlasForeverSource and
        C:LocalizeDisplay("Beutereferenz: AtlasLoot Forever (GPLv2) · tatsächliche Drops können abweichen.") or
        dungeon.atlasSource and
        C:LocalizeDisplay("Referenzkatalog: AtlasLootContinued · Forever-Abweichungen sind möglich.") or questView and
        C:LocalizeDisplay("Erfahrung: Katalogwert; tatsächliche EP können variieren. Quelle: Forever Dungeon Journal v1.3.0 von Exehn.") or
        C:LocalizeDisplay("Katalog: Forever Dungeon Journal v1.3.0 von Exehn · Darstellung: Chronicle"))
    ui.source:SetPoint("TOPLEFT", rightX, -math.max(
        questView and (sectionY + 126) or (itemY + 53), itemY + detailCount * 43 + 10))
    ui.source:SetWidth(rightWidth); ui.source:SetHeight(32); ui.source:Show()
    parent:SetHeight(math.max(560, 270 + #rows * 49,
        questView and (sectionY + 165) or 0, itemY + detailCount * 43 + 43))
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
