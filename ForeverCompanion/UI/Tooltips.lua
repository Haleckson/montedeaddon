--[[
  Forever Companion - UI/Tooltips.lua
  Reference blocks added to Blizzard tooltips, in the spirit of collection
  addons:

    NPCs    the quests it gives (with your progress: done, ready to turn in,
            in progress, not done), quests you turn in to it, quest items it
            drops, and what the journal knows about it (vendor stock, trainer,
            flight master, rare respawn, bestiary level and loot, notes,
            who found it), plus its NPC ID
    items   the creatures seen dropping it and the vendors seen selling it,
            where journal entries came from; for quest-starting items, the
            quest they start and the creatures that drop them
    rares   how long ago they spawned and the layer they are on (from the GUID)

  Everything shown was seen by one of your characters or shared by your
  guild; the Discovery Fog settings are respected.
]]

local _, FC = ...

local Tooltips = FC:NewModule("Tooltips")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local Compat = FC.Compat
local Categories = FC.Categories

local MAX_QUESTS = 8
local MAX_ENDS = 4
local MAX_TARGETS = 4
local MAX_DROPS = 5
local SECTION = { 0.85, 0.70, 0.36 }
local MUTED = { 0.6, 0.6, 0.6 }
local TEXT = { 0.9, 0.9, 0.9 }

local function icon(path, size)
    return "|T" .. path .. ":" .. (size or 14) .. ":" .. (size or 14) .. "|t"
end

local QUEST_ICON = icon("Interface\\GossipFrame\\AvailableQuestIcon", 12)
-- the addon's mark in front of its first line: small, so the tooltip stays the game's
local LOGO = icon(FC.C.MEDIA .. "Logo", 12)
-- progress on a quest: an icon on the right, the color of the title
local STATUS = {
    done = { right = icon("Interface\\RaidFrame\\ReadyCheck-Ready", 12), color = { 0.5, 0.75, 0.5 } },
    ready = { right = icon("Interface\\GossipFrame\\ActiveQuestIcon", 12), color = { 1, 0.82, 0 } },
    active = { right = icon("Interface\\RaidFrame\\ReadyCheck-Waiting", 12), color = { 1, 0.9, 0.6 } },
    open = { right = icon("Interface\\RaidFrame\\ReadyCheck-NotReady", 12), color = TEXT },
}

local function rgb(c) return c[1], c[2], c[3] end

local function statusRight(status)
    return (STATUS[status] or STATUS.open).right
end

local function progressText(done, total)
    local text = string.format(L.TIP_PROGRESS, done, total)
    local percent = U.Colorize(string.format(L.TIP_PERCENT, total > 0 and math.floor(done / total * 100) or 0), "8c8c8c")
    if done == total then return U.Colorize(text, "59c759") .. "  " .. percent end
    if done == 0 then return U.Colorize(text, "b3b3b3") .. "  " .. percent end
    return U.Colorize(text, "ffd200") .. "  " .. percent
end

------------------------------------------------------------------------
-- Building blocks
------------------------------------------------------------------------

local Block = {}
Block.__index = Block

local function newBlock(tooltip)
    return setmetatable({ tooltip = tooltip, started = false }, Block)
end

--- No header and no empty line: the first line of the block carries the
--- addon's small mark, everything else reads like part of the tooltip.
function Block:Prefix(text)
    if self.started then return text end
    self.started = true
    return LOGO .. " " .. (text:gsub("^%s+", ""))
end

function Block:Line(text, color, wrap)
    text = self:Prefix(text)
    local r, g, b = rgb(color or TEXT)
    self.tooltip:AddLine(text, r, g, b, wrap and true or false)
end

function Block:Pair(left, right, leftColor, rightColor)
    left = self:Prefix(left)
    local r, g, b = rgb(leftColor or TEXT)
    local r2, g2, b2 = rgb(rightColor or TEXT)
    self.tooltip:AddDoubleLine(left, right or " ", r, g, b, r2, g2, b2)
end

function Block:Section(text, right)
    self:Pair(text, right, SECTION, TEXT)
end

--- Your other characters that already did a quest, as a short muted suffix.
local function altsSuffix(questID)
    if not FC.P.tooltips.alts or not questID then return "" end
    local alts = FC.Characters:CompletedBy(questID)
    if #alts == 0 then return "" end
    local names = {}
    for i = 1, math.min(2, #alts) do names[i] = U.Escape(alts[i].name) end
    local text = table.concat(names, ", ") .. (#alts > 2 and (" +" .. (#alts - 2)) or "")
    return "  " .. icon("Interface\\RaidFrame\\ReadyCheck-Ready", 10) .. U.Colorize(text, "8c8c8c")
end

function Block:QuestLine(entry, prefix)
    local style = STATUS[entry.status] or STATUS.open
    local alts = entry.status ~= "done" and altsSuffix(entry.questID) or ""
    local right = statusRight(entry.status)
    if entry.progress then right = U.Colorize(entry.progress, "b3b3b3") .. "  " .. right end
    self:Pair("  " .. (prefix and (prefix .. " ") or "") .. U.Escape(entry.title) .. alts, right, style.color, TEXT)
end

------------------------------------------------------------------------
-- NPC tooltips
------------------------------------------------------------------------

--- The unit a tooltip shows. The unit token is best (level, classification);
--- without one (or when the client keeps it secret), the tooltip's own data
--- still names the GUID and the name on its first line.
local function tooltipUnit(tooltip, data)
    local unit = Compat.GetTooltipUnit(tooltip)
    local info = unit and Compat.GetUnitInfo(unit)
    if info then return info end
    local guid = type(data) == "table" and Compat.Safe(data.guid) or nil
    if type(guid) ~= "string" and Compat.SafeCall(_G.UnitExists, "mouseover") then
        return Compat.GetUnitInfo("mouseover")
    end
    local unitType, id = Compat.ParseGUID(guid)
    if not unitType then return nil end
    local first = type(data.lines) == "table" and data.lines[1]
    local name = type(first) == "table" and Compat.Safe(first.leftText) or nil
    return {
        guid = guid, guidType = unitType, isPlayer = unitType == "Player",
        npcID = (unitType == "Creature" or unitType == "Vehicle") and id or nil,
        name = type(name) == "string" and name ~= "" and name or nil,
    }
end

--- The NPC behind a unit: its ID from the GUID, or, when the client keeps
--- the GUID secret, the only NPC the journal knows under that name.
local function identify(info)
    if info.npcID then return info.npcID end
    local ids = FC.QuestLore:NpcIDsByName(info.name)
    if #ids == 1 then return ids[1] end
    return nil
end

local function questSections(block, npcID, name)
    local P = FC.P.tooltips
    if not P.quests then return end
    local given, done = FC.QuestLore:QuestsGivenBy(npcID, name)
    local listed = {}
    if #given > 0 then
        block:Section(L.TIP_QUESTS, progressText(done, #given))
        for i, entry in ipairs(given) do
            listed[entry.questID] = true
            if i <= MAX_QUESTS then block:QuestLine(entry) end
        end
        if #given > MAX_QUESTS then block:Line("  " .. string.format(L.TIP_MORE, #given - MAX_QUESTS), MUTED) end
    end
    local ends = npcID and FC.QuestLore:QuestsEndedAt(npcID, listed) or {}
    if #ends > 0 then
        block:Section(L.TIP_TURN_IN_HERE)
        for i, entry in ipairs(ends) do
            if i <= MAX_ENDS then block:QuestLine(entry) end
        end
        if #ends > MAX_ENDS then block:Line("  " .. string.format(L.TIP_MORE, #ends - MAX_ENDS), MUTED) end
    end
end

--- The quests a creature is needed for (to kill, loot or talk to), learned
--- from its tooltip and nameplate and kept after the quest is done; live
--- progress ("7/12") from the tooltip on screen.
local function targetSection(block, npcID, live)
    if not FC.P.tooltips.quests or not npcID then return end
    local list = FC.QuestLore:QuestsTargeting(npcID)
    if #list == 0 then return end
    local progress = {}
    for _, q in ipairs(live or {}) do progress[q.questID] = q.progress end
    block:Section(L.TIP_NEEDED_FOR)
    for i, entry in ipairs(list) do
        if i > MAX_TARGETS then
            block:Line("  " .. string.format(L.TIP_MORE, #list - MAX_TARGETS), MUTED)
            break
        end
        entry.progress = progress[entry.questID]
        block:QuestLine(entry)
    end
end

--- An item's icon and name in its quality's color, when the client has it
--- (it is asked for otherwise, and shows next time).
local function itemLabel(itemID)
    local info = Compat.GetItemInfo(itemID)
    if not info then
        if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemID) end
        return nil
    end
    return (info.icon and (icon(info.icon, 14) .. " ") or "") .. U.Colorize(U.Escape(info.name), Compat.GetQualityHex(info.quality))
end

local function moreLine(block, extra)
    block:Line("  " .. string.format(L.TIP_MORE, extra), MUTED)
end

--- What a creature's loot means, from the reference data: quests its loot
--- starts, quest items it drops for quests you can still do, and for rares
--- and bosses their notable drops.
local function lootSections(block, npcID)
    if not npcID then return end
    local P, Ref = FC.P.tooltips, FC.Reference
    if P.questItems then
        local starts = FC.QuestLore:QuestsFromLoot(npcID)
        if #starts > 0 then
            block:Section(L.TIP_LOOT_STARTS)
            for i, entry in ipairs(starts) do
                if i > MAX_TARGETS then moreLine(block, #starts - MAX_TARGETS) break end
                block:QuestLine(entry)
            end
        end
    end
    local npc = Ref:Npc(npcID)
    if not (npc and npc.d) then return end
    if P.questItems then
        local lines = {}
        for _, itemID in ipairs(npc.d) do
            for _, questID in ipairs(Ref.questItems[itemID] or {}) do
                local status = Compat.GetQuestStatus(questID)
                if status ~= "done" and Ref:Fits(Ref.quests[questID]) then
                    lines[#lines + 1] = { itemID = itemID, questID = questID, status = status }
                    break
                end
            end
        end
        if #lines > 0 then
            block:Section(L.TIP_QUEST_LOOT)
            for i, entry in ipairs(lines) do
                if i > MAX_TARGETS then moreLine(block, #lines - MAX_TARGETS) break end
                local style = STATUS[entry.status] or STATUS.open
                local label = itemLabel(entry.itemID) or string.format(L.TIP_ITEM_ID, entry.itemID)
                block:Pair("  " .. label .. U.Colorize("  \226\134\146 ", "999999") .. U.Escape(FC.QuestLore:Title(entry.questID)),
                    statusRight(entry.status), style.color, TEXT)
            end
        end
    end
    if P.sources and (Ref:Is(npcID, "r") or Ref:Is(npcID, "w") or Ref:Is(npcID, "b")) then
        local shown, total = 0, 0
        for _, itemID in ipairs(npc.d) do
            if not Ref.questItems[itemID] then
                total = total + 1
                local label = shown < MAX_DROPS and itemLabel(itemID)
                if label then
                    if shown == 0 then block:Section(L.TIP_DROPS) end
                    block:Line("  " .. label)
                    shown = shown + 1
                end
            end
        end
        if shown > 0 and total > shown then moreLine(block, total - shown) end
    end
end

local function starterSection(block, npcID)
    if not FC.P.tooltips.questItems or not npcID then return end
    local drops = FC.QuestLore:StarterDrops(npcID)
    if #drops == 0 then return end
    block:Section(L.TIP_QUEST_ITEMS)
    for _, drop in ipairs(drops) do
        local itemIcon = Compat.GetItemInfoInstant(drop.itemID)
        local left = "  " .. (itemIcon and itemIcon.icon and icon(itemIcon.icon, 14) .. " " or "") .. U.Escape(drop.name)
        if drop.title then
            local style = STATUS[drop.status] or STATUS.open
            block:Pair(left .. U.Colorize("  \226\134\146 ", "999999") .. U.Escape(drop.title), statusRight(drop.status), style.color, TEXT)
        else
            block:Pair(left, L.TIP_STARTS_QUEST, TEXT, MUTED)
        end
    end
end

local RECORD_ORDER = { rare = 1, npc = 2, vendor = 3, trainer = 4, travel = 5, creature = 6 }

local function recordLines(block, rec)
    local store = FC.Store
    if store:IsRumored(rec) then
        block:Pair(string.format(L.RUMORED_TITLE, Categories:Label(rec.t)), " ", MUTED)
        return
    end
    local t = rec.t
    if t == "vendor" then
        local _, recipes, limited = FC.AutoText:VendorSummary(rec.inv)
        local parts = { string.format(L.VENDOR_ITEMS, rec.inv and #rec.inv or 0) }
        if recipes > 0 then parts[#parts + 1] = string.format(L.VENDOR_RECIPES, recipes) end
        if limited > 0 then parts[#parts + 1] = string.format(L.VENDOR_LIMITED, limited) end
        block:Pair(L.CAT_VENDOR, table.concat(parts, "  \194\183  "), SECTION)
    elseif t == "trainer" then
        local profession = rec.pr and L[Categories:Profession(rec.pr).label] or ""
        block:Pair(L.CAT_TRAINER, profession, SECTION)
    elseif t == "travel" then
        local known = FC.Characters:KnowsFlightPath(rec.npc)
        local right = known == true and L.TIP_FLIGHT_KNOWN or (known == false and U.Colorize(L.TIP_FLIGHT_UNKNOWN, "e6a23c")) or (rec.z or " ")
        block:Pair(L.CAT_TRAVEL, right, SECTION, MUTED)
    elseif t == "rare" or (t == "npc" and rec.cls == "worldboss") then
        local estimate = store:RespawnEstimate(rec)
        local right = " "
        if estimate and estimate.low then
            right = string.format(L.TIP_RESPAWN, U.FormatDuration(estimate.low), U.FormatDuration(estimate.high))
        elseif rec.obs and rec.obs.s and #rec.obs.s > 0 then
            right = string.format(L.TIP_LAST_SEEN, U.TimeAgo(rec.obs.s[#rec.obs.s]))
        end
        block:Pair(t == "rare" and L.CAT_RARE or L.CLASS_worldboss, right, SECTION)
    elseif t == "creature" then
        local level = FC.AutoText.LevelText(rec)
        local kind = rec.ct or L.CAT_CREATURE
        local right = string.format(L.TIP_LEVEL, level) .. " " .. kind
        block:Pair(L.NAV_BESTIARY, right, SECTION)
        if rec.dr and #rec.dr > 0 then
            block:Pair("  " .. L.TIP_LOOT_SEEN, tostring(#rec.dr), MUTED, MUTED)
        end
    elseif t == "npc" then
        block:Pair(L.CAT_NPC, " ", SECTION)
    else
        block:Pair(Categories:Label(t), " ", SECTION)
    end
    local state = store:GetState(rec.id)
    local note = state and state.note
    if note then
        if #note > 90 then note = note:sub(1, 87) .. "..." end
        block:Line("  " .. U.Escape(note), { 0.8, 0.8, 0.8 }, true)
    elseif t == "npc" and rec.d then
        local text = rec.d
        if #text > 90 then text = text:sub(1, 87) .. "..." end
        block:Line("  " .. U.Escape(text), MUTED, true)
    end
end

local function discoveredLine(block, rec)
    -- your own finds need no signature; the guild's say who found them, and
    -- so do your other characters' finds when progress counts per character
    local store = FC.Store
    if store:IsRumored(rec) or (store:IsMine(rec) and store:IsPersonal(rec)) then return end
    local info = UI.Display(rec)
    local style = UI.STATUS[info.status.primary]
    local text = string.format(L.DISCOVERED_BY_AGO, info.author, U.TimeAgo(info.time))
    local count = FC.Store:VerifyCount(rec)
    if count > 1 then text = text .. "  \194\183  " .. string.format(L.CONFIRMED_BY_N, count) end
    local r, g, b = U.HexToRGB(style and style.color or "cccccc")
    block:Line(text, { r, g, b })
end

function Tooltips:OnUnit(tooltip, data)
    local P = FC.P.tooltips
    if not P.unit or tooltip ~= GameTooltip then return end
    local info = tooltipUnit(tooltip, data)
    if not info or info.isPlayer then return end
    local npcID = identify(info)
    if not npcID and not info.name then return end
    -- the quest lines the game put in this tooltip teach what the creature is needed for
    local live = Compat.ReadQuestLines(type(data) == "table" and data.lines or nil)
    if npcID and #live > 0 then FC.QuestLore:LearnTargets(npcID, info.name, live) end
    local block = newBlock(tooltip)

    questSections(block, npcID, info.name)
    targetSection(block, npcID, live)
    starterSection(block, npcID)
    lootSections(block, npcID)

    local records = {}
    for _, rec in ipairs(npcID and FC.Store:ForNpc(npcID) or {}) do
        if FC.Store:IsKnown(rec) then records[#records + 1] = rec end
    end
    table.sort(records, function(a, b) return (RECORD_ORDER[a.t] or 9) < (RECORD_ORDER[b.t] or 9) end)
    for _, rec in ipairs(records) do recordLines(block, rec) end
    if records[1] then discoveredLine(block, records[1]) end

    local rare = info.classification == "rare" or info.classification == "rareelite" or info.classification == "worldboss"
    if P.spawn and rare then
        local spawned, layer = Compat.GetSpawnInfo(info.guid)
        if spawned and rare then block:Pair(L.TIP_SPAWNED, U.TimeAgo(spawned), MUTED, TEXT) end
        if layer and rare then block:Pair(L.TIP_LAYER, tostring(layer), MUTED, MUTED) end
    end
    -- every creature carries its ID, like a reference book would
    if P.npcID and npcID then
        block:Pair(L.FIELD_NPC_ID, tostring(npcID), MUTED, MUTED)
    end
    if block.started then tooltip:Show() end
end

--- A quest title arrived while its NPC's tooltip is open: draw it again.
function Tooltips:RefreshShown()
    local tip = GameTooltip
    if not (tip and tip:IsShown()) then return end
    if tip.RefreshData then
        pcall(tip.RefreshData, tip)
        return
    end
    local unit = Compat.GetTooltipUnit(tip)
    if unit and tip.SetUnit then pcall(tip.SetUnit, tip, unit) end
end

------------------------------------------------------------------------
-- Item tooltips
------------------------------------------------------------------------

function Tooltips:OnItem(tooltip, data)
    local P = FC.P.tooltips
    if not P.item or tooltip ~= GameTooltip then return end
    local itemID = data and Compat.Safe(data.id)
    if type(itemID) ~= "number" then return end
    local block = newBlock(tooltip)

    local starter = P.questItems and FC.QuestLore:ItemStarter(itemID)
    if starter and starter.questID then
        local status = Compat.GetQuestStatus(starter.questID)
        local style = STATUS[status] or STATUS.open
        block:Pair(QUEST_ICON .. " " .. U.Escape(FC.QuestLore:Title(starter.questID)), statusRight(status), style.color, TEXT)
        if #starter.droppers > 0 then
            local names = {}
            for i = 1, math.min(3, #starter.droppers) do names[i] = U.Escape(starter.droppers[i]) end
            local more = #starter.droppers > 3 and (" " .. string.format(L.TIP_MORE, #starter.droppers - 3)) or ""
            block:Pair(L.TIP_DROPPED_BY, table.concat(names, ", ") .. more, MUTED, TEXT)
        end
    end

    if P.questItems then self:ItemQuests(block, itemID, starter) end
    if P.sources then self:ItemSources(block, itemID) end

    local shown = 0
    for _, rec in ipairs(FC.Store:ForItem(itemID)) do
        if FC.Store:IsKnown(rec) and not FC.Store:IsRumored(rec) and shown < 2 then
            local where = rec.z and (rec.z .. (rec.x and (" " .. U.FormatCoords(rec.x, rec.y)) or "")) or ""
            local source = rec.src and string.format(L.SOURCE_FORMAT, rec.src) or Categories:Label(rec.t)
            block:Pair(source, where, TEXT, MUTED)
            shown = shown + 1
        end
    end
    if block.started then tooltip:Show() end
end

local MAX_SOURCES = 4

--- The quests an item starts, is needed for and is a reward of, from the
--- reference data (a starter the journal learned is shown above already).
function Tooltips:ItemQuests(block, itemID, learnedStarter)
    local src = FC.Reference:ItemSources(itemID)
    if src.starts and not (learnedStarter and learnedStarter.questID == src.starts) then
        local status = Compat.GetQuestStatus(src.starts)
        local style = STATUS[status] or STATUS.open
        block:Pair(QUEST_ICON .. " " .. U.Escape(FC.QuestLore:Title(src.starts)), statusRight(status), style.color, TEXT)
    end
    local function list(title, questIDs)
        if #questIDs == 0 then return end
        local entries = {}
        for _, questID in ipairs(questIDs) do
            entries[#entries + 1] = { questID = questID, title = FC.QuestLore:Title(questID), status = Compat.GetQuestStatus(questID) }
        end
        table.sort(entries, function(a, b)
            if (a.status == "done") ~= (b.status == "done") then return b.status == "done" end
            return a.title < b.title
        end)
        block:Section(title)
        for i, entry in ipairs(entries) do
            if i > MAX_TARGETS then moreLine(block, #entries - MAX_TARGETS) break end
            block:QuestLine(entry)
        end
    end
    list(L.TIP_NEEDED_FOR, src.neededFor)
    list(L.TIP_REWARD_OF, src.rewardOf)
end

--- A reference NPC as a source line: name, and the zone it stands in.
local function referenceSource(npcID)
    local Ref = FC.Reference
    local npc = Ref:Npc(npcID)
    local name = Ref:NpcName(npcID) or string.format(L.TIP_NPC_ID, npcID)
    local place = npc and npc.m and Compat.GetMapName(npc.m) or ""
    if npc and npc.x then place = place .. "  " .. U.FormatCoords(npc.x / 100, npc.y / 100) end
    return U.Escape(name), place
end

local function sourcePlace(rec)
    if rec.z and rec.x then return rec.z .. "  " .. U.FormatCoords(rec.x, rec.y) end
    return rec.z or rec.inn or ""
end

--- Where an item comes from, as far as the journal knows: creatures seen
--- dropping it (with their level) and vendors seen selling it.
function Tooltips:ItemSources(block, itemID)
    local drops, sellers = FC.Store:ItemSources(itemID)
    local store = FC.Store
    local function visible(list)
        local out = {}
        for _, rec in ipairs(list) do
            if store:IsKnown(rec) and not store:IsRumored(rec) then out[#out + 1] = rec end
        end
        return out
    end
    drops, sellers = visible(drops), visible(sellers)
    -- the reference data adds the creatures and vendors the journal has not met
    local ref = FC.Reference:ItemSources(itemID)
    local function extra(list, npcIDs)
        local listed = {}
        for _, rec in ipairs(list) do if rec.npc then listed[rec.npc] = true end end
        local out = {}
        for _, npcID in ipairs(npcIDs) do
            if not listed[npcID] then out[#out + 1] = npcID end
        end
        return out
    end
    local refDrops, refSellers = extra(drops, ref.droppers), extra(sellers, ref.sellers)
    local function section(title, recs, npcIDs, line)
        local total = #recs + #npcIDs
        if total == 0 then return end
        block:Section(title)
        local shown = 0
        for _, rec in ipairs(recs) do
            if shown >= MAX_SOURCES then break end
            line(rec)
            shown = shown + 1
        end
        for _, npcID in ipairs(npcIDs) do
            if shown >= MAX_SOURCES then break end
            local name, place = referenceSource(npcID)
            block:Pair("  " .. name, place, TEXT, MUTED)
            shown = shown + 1
        end
        if total > shown then moreLine(block, total - shown) end
    end
    section(L.TIP_DROPPED_BY, drops, refDrops, function(rec)
        local level = rec.lvl and (" " .. U.Colorize(string.format(L.TIP_LEVEL, FC.AutoText.LevelText(rec)), "999999")) or ""
        block:Pair("  " .. U.Escape(rec.n or "?") .. level, sourcePlace(rec), TEXT, MUTED)
    end)
    section(L.TIP_SOLD_BY, sellers, refSellers, function(rec)
        local limited = ""
        for _, item in ipairs(rec.inv or {}) do
            if item.i == itemID and item.l then limited = " " .. U.Colorize(string.format(L.ITEM_LIMITED, item.l), "e6a23c") end
        end
        block:Pair("  " .. U.Escape(rec.n or "?") .. limited, sourcePlace(rec), TEXT, MUTED)
    end)
end

function Tooltips:OnEnable()
    local unitHooked = Compat.HookTooltip("Unit", function(tooltip, data) self:OnUnit(tooltip, data) end)
    FC.Bus:On("QUEST_TITLE_LOADED", self, function()
        U.Debounce("tooltip-quest-titles", 0.25, function() self:RefreshShown() end)
    end)
    if not unitHooked and GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(tooltip) FC:SafeCall("tooltip:unit", self.OnUnit, self, tooltip) end)
    end
    Compat.HookTooltip("Item", function(tooltip, data) self:OnItem(tooltip, data) end)
end
