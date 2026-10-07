--[[
  Forever Companion - UI/ZoneGuide.lua
  A zone at a glance, with your progress: everything your journal, your
  guild and your characters know about it. It opens for the zone you are
  in (/fc zone, middle-click on the minimap button, the journal) or, from
  the button on the world map, for the zone the map shows, and then
  follows the map while you browse it.

    quests        by quest giver (done / total), then every quest with your
                  progress: done, ready to turn in, in progress, not done
    rares         defeated by this character / known, respawn estimate
    treasure      treasure, secrets, caves and shortcuts you found / known
    flight paths  learned by this character / known
    dungeons      entrances you found / known
    exploration   areas you explored / known
    recipes       vendors that sell recipes (for reference)

  Sections fold with a click on their title, a quest giver with a click on
  its line; finished lines can be hidden. Click a line for a waypoint,
  right-click to open it in the journal.
]]

local _, FC = ...

local Guide = FC:NewModule("ZoneGuide")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Compat = FC.Compat
local Theme = FC.Theme

local WIDTH, HEIGHT = 300, 420
local ROW = 18
local TITLE_ROW = 20
local HEADER_HEIGHT = 60
local INDENT = 14
local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t"
local QUEST_STATUS = {
    done = CHECK,
    ready = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12|t",
    active = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12:12|t",
    open = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:12:12|t",
}
local STATUS_TEXT = { done = "QUEST_STATUS_DONE", ready = "QUEST_STATUS_READY", active = "QUEST_STATUS_ACTIVE", open = "QUEST_STATUS_OPEN" }
local QUEST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local ACHIEVEMENT_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local READY_ICON = "Interface\\GossipFrame\\ActiveQuestIcon"
local FOLDED, UNFOLDED = "Interface\\Buttons\\UI-PlusButton-Up", "Interface\\Buttons\\UI-MinusButton-Up"

------------------------------------------------------------------------
-- What the zone holds
------------------------------------------------------------------------

local FIND_TYPES = { treasure = true, secret = true, cave = true, shortcut = true }
local STATUS_ORDER = { ready = 1, active = 2, open = 3, done = 4 }

local function rareStatus(rec)
    local estimate = FC.Store:RespawnEstimate(rec)
    if estimate and estimate.low then
        return string.format(L.ZONE_RESPAWN, U.FormatDuration(estimate.low), U.FormatDuration(estimate.high))
    end
    local obs = rec.obs or {}
    if obs.d and #obs.d > 0 then return string.format(L.ZONE_KILLED, U.TimeAgo(obs.d[#obs.d])) end
    if obs.s and #obs.s > 0 then return string.format(L.ZONE_SEEN, U.TimeAgo(obs.s[#obs.s])) end
    return ""
end

local function recordRow(rec, right, done)
    local info = UI.Display(rec)
    return {
        icon = info.icon, text = U.Escape(info.title), right = right or "", rec = rec, done = done or nil,
        m = rec.m, x = rec.x, y = rec.y, desaturate = info.rumored,
    }
end

local function progressRight(done, total, right)
    local text = string.format(L.TIP_PROGRESS, done, total)
    if right and right ~= "" then return right .. "  " .. U.Colorize(text, "8c8c8c") end
    return text
end

--- A quest giver and its quests: one foldable line with done / total.
local function questGroup(npcID, npc, given)
    local group = {
        key = "npc:" .. npcID, text = U.Escape(npc.n or ("#" .. npcID)), title = npc.n,
        m = npc.m, x = npc.x, y = npc.y, children = {},
    }
    local done, ready = 0, false
    for _, entry in ipairs(given) do
        group.children[#group.children + 1] = {
            text = U.Escape(entry.title), right = QUEST_STATUS[entry.status] or QUEST_STATUS.open,
            done = entry.status == "done" or nil, status = entry.status, questID = entry.questID,
            m = npc.m, x = npc.x, y = npc.y, title = npc.n, rec = entry.rec,
        }
        if entry.status == "done" then done = done + 1 end
        if entry.status == "ready" then ready = true end
    end
    group.icon = ready and READY_ICON or QUEST_ICON
    group.ready = ready
    group.done = done == #given or nil
    group.right = progressRight(done, #given)
    return group
end

local function sortGroups(groups)
    table.sort(groups, function(a, b)
        if (a.ready or false) ~= (b.ready or false) then return a.ready or false end
        if (a.done or false) ~= (b.done or false) then return not a.done end
        return a.text < b.text
    end)
end

local EMPTY = {}

local function iconOf(category)
    local c = FC.Categories:Get(category)
    return c and c.icon or nil
end

local function sortByStatus(entries)
    table.sort(entries, function(a, b)
        local sa, sb = STATUS_ORDER[a.status] or 5, STATUS_ORDER[b.status] or 5
        if sa ~= sb then return sa < sb end
        return a.title < b.title
    end)
    return entries
end

--- A quest line under a group (a dungeon, "other quests").
local function questRow(questID, status, place)
    local m, x, y
    if place then m, x, y = FC.Reference:QuestPlace(questID) end
    return {
        text = U.Escape(FC.QuestLore:Title(questID)), right = QUEST_STATUS[status] or QUEST_STATUS.open,
        done = status == "done" or nil, status = status, questID = questID, m = m, x = x, y = y,
    }
end

--- Whether a journal find stands within a stone's throw of a point.
local function nearAny(points, m, x, y)
    if not (m and x) then return false end
    for _, p in ipairs(points) do
        if p.m == m and p.x and math.abs(p.x - x) < 0.012 and math.abs(p.y - y) < 0.012 then return true end
    end
    return false
end

--- The zone's sections: { { key, title, rows, done, total } } (only the
--- non-empty ones; recipes have no progress), and the zone's done / total.
--- Your journal, your characters' and your guild's quest knowledge and the
--- reference data all count, each thing once.
function Guide:Collect(mapID, zone)
    local store, chars, Ref = FC.Store, FC.Characters, FC.Reference
    local zref = mapID and Ref.zones[mapID] or EMPTY
    local lists = { rares = {}, finds = {}, travel = {}, dungeons = {}, achievements = {}, explored = {}, recipes = {} }
    local counts = { rares = { 0, 0 }, finds = { 0, 0 }, travel = { 0, 0 }, dungeons = { 0, 0 }, achievements = { 0, 0 }, explored = { 0, 0 } }
    local function add(key, row, done, untracked)
        local list = lists[key]
        list[#list + 1] = row
        local c = counts[key]
        if c and not untracked then
            c[2] = c[2] + 1
            if done then c[1] = c[1] + 1 end
        end
    end

    -- your journal and your guild's
    local seen, questRecords = {}, {}
    local rareNpcs, travelNpcs, findPoints, entrances = {}, {}, {}, {}
    for _, rec in ipairs(mapID and store:ForMap(mapID) or {}) do
        if not seen[rec.id] and store:IsKnown(rec) then
            seen[rec.id] = true
            local t = rec.t
            if t == "rare" or (t == "npc" and rec.cls == "worldboss") then
                local done = chars:Defeated(rec.npc)
                if rec.npc then rareNpcs[rec.npc] = true end
                add("rares", recordRow(rec, rareStatus(rec) .. (done and ("  " .. CHECK) or ""), done), done)
            elseif FIND_TYPES[t] then
                local done = store:IsPersonal(rec)
                findPoints[#findPoints + 1] = rec
                add("finds", recordRow(rec, done and CHECK or U.Colorize(U.ShortName(rec.a), "999999"), done), done)
            elseif t == "travel" then
                local known = chars:KnowsFlightPath(rec.npc)
                if rec.npc then travelNpcs[rec.npc] = true end
                local right = known == true and CHECK or (known == false and U.Colorize(L.ZONE_NOT_LEARNED, "e6a23c") or "")
                add("travel", recordRow(rec, right, known == true), known == true)
            elseif t == "entrance" then
                entrances[#entrances + 1] = rec
            elseif t == "landmark" then
                local done = store:IsPersonal(rec)
                add("explored", recordRow(rec, done and CHECK or "", done), done)
            elseif t == "vendor" and rec.inv then
                local count = 0
                for _, item in ipairs(rec.inv) do if item.rc then count = count + 1 end end
                if count > 0 then add("recipes", recordRow(rec, string.format(L.VENDOR_RECIPES, count))) end
            elseif t == "quest" and rec.q then
                questRecords[#questRecords + 1] = rec
            end
        end
    end

    -- quests, by giver; each quest counts once
    local groups, listed, grouped, questDone, questTotal = {}, {}, {}, 0, 0
    local function countQuest(questID, status)
        if listed[questID] then return end
        listed[questID] = true
        questTotal = questTotal + 1
        if status == "done" then questDone = questDone + 1 end
    end
    local function addGroup(npcID, npc, given)
        local kept = {}
        for _, q in ipairs(given) do
            local r = Ref.quests[q.questID]
            if not (r and r.ev) then kept[#kept + 1] = q end
        end
        if #kept == 0 then return end
        grouped[npcID] = true
        groups[#groups + 1] = questGroup(npcID, npc, kept)
        for _, q in ipairs(kept) do countQuest(q.questID, q.status) end
    end
    -- the givers you met here
    for _, entry in ipairs(FC.QuestLore:QuestNpcsIn(mapID, zone)) do
        addGroup(entry.npcID, entry.npc, FC.QuestLore:QuestsGivenBy(entry.npcID, entry.npc.n))
    end
    -- the givers the reference data knows here
    local others = {}
    for _, questID in ipairs(zref.q or EMPTY) do
        local q = Ref.quests[questID]
        if q and not q.ev and Ref:Fits(q) then
            local giver = Ref:QuestGiver(questID) -- the one of your faction, when each has its own
            if giver and not grouped[giver] then
                local m, x, y = Ref:Place(Ref:Npc(giver))
                if not m then m, x, y = Ref:QuestPlace(questID) end
                local name = Ref:NpcName(giver) or string.format(L.TIP_NPC_ID, giver)
                addGroup(giver, { n = name, m = m, x = x, y = y }, FC.QuestLore:QuestsGivenBy(giver, name))
            elseif not giver and not listed[questID] then
                local status = Compat.GetQuestStatus(questID) or "open"
                others[#others + 1] = { questID = questID, title = FC.QuestLore:Title(questID), status = status }
            end
        end
    end
    -- journal quests here whose giver is not among them
    for _, rec in ipairs(questRecords) do
        if not listed[rec.q] then
            local status = Compat.GetQuestStatus(rec.q) or "open"
            others[#others + 1] = { questID = rec.q, title = rec.n or FC.QuestLore:Title(rec.q), status = status, rec = rec }
        end
    end
    local kept = {}
    for _, entry in ipairs(others) do
        if not listed[entry.questID] then
            kept[#kept + 1] = entry
            countQuest(entry.questID, entry.status)
        end
    end
    if #kept > 0 then
        local group = questGroup("other", { n = L.ZONE_OTHER_QUESTS }, sortByStatus(kept))
        group.text = L.ZONE_OTHER_QUESTS
        -- no creature gives these: each says what starts it (a wanted poster, an
        -- item), and where, when the data knows
        for _, child in ipairs(group.children) do
            child.title = child.rec and child.rec.gv or nil
            local start = not child.title and Ref:QuestStart(child.questID)
            if start then
                child.start = start
                child.m, child.x, child.y = start.m, start.x, start.y
            end
        end
        groups[#groups + 1] = group
    end
    sortGroups(groups)

    -- the reference data: rares and world bosses
    for _, npcs in ipairs({ zref.r or EMPTY, zref.w or EMPTY }) do
        for _, npcID in ipairs(npcs) do
            if not rareNpcs[npcID] then
                rareNpcs[npcID] = true
                local m, x, y = Ref:Place(Ref:Npc(npcID))
                local name = Ref:NpcName(npcID) or string.format(L.TIP_NPC_ID, npcID)
                local done = chars:Defeated(npcID)
                add("rares", {
                    icon = iconOf("rare"), text = U.Escape(name), right = done and CHECK or "", done = done or nil,
                    m = m, x = x, y = y, title = name,
                }, done)
            end
        end
    end
    -- treasure: counted when the game can tell it was looted
    for _, objectID in ipairs(zref.t or EMPTY) do
        local object = Ref.objects[objectID]
        local m, x, y = Ref:Place(object)
        if object and not nearAny(findPoints, m, x, y) then
            local done = object.q and Compat.GetQuestStatus(object.q) == "done"
            local name = object.n or string.format(L.ZONE_OBJECT_ID, objectID)
            add("finds", {
                icon = iconOf("treasure"), text = U.Escape(name), right = done and CHECK or "", done = done or nil,
                m = m, x = x, y = y, title = name,
            }, done, not object.q)
        end
    end
    -- flight paths of your faction
    local faction = Ref:Me().faction
    for _, nodeID in ipairs(zref.fp or EMPTY) do
        local fp = Ref.flightPaths[nodeID]
        if fp and not (fp.f and faction and fp.f ~= faction) and not (fp.npc and travelNpcs[fp.npc]) then
            local known = chars:Me().fp[nodeID] == true
            local m, x, y = Ref:Place(fp)
            local name = fp.n or string.format(L.ZONE_FLIGHT_ID, nodeID)
            add("travel", {
                icon = iconOf("travel"), text = U.Escape(name), right = known and CHECK or U.Colorize(L.ZONE_NOT_LEARNED, "e6a23c"),
                done = known or nil, m = m, x = x, y = y, title = name,
            }, known)
        end
    end
    -- dungeons: their quests you can take, done / total
    local dungeonPoints = {}
    for _, instanceID in ipairs(zref.i or EMPTY) do
        local instance = Ref.instances[instanceID]
        if instance then
            local children, done = {}, 0
            for _, questID in ipairs(instance.q or EMPTY) do
                local q = Ref.quests[questID]
                if q and not q.ev and Ref:Fits(q) then
                    local status = Compat.GetQuestStatus(questID) or "open"
                    children[#children + 1] = questRow(questID, status, true)
                    children[#children].title = children[#children].text
                    if status == "done" then done = done + 1 end
                end
            end
            sortByStatus(children)
            local m, x, y = Ref:Place(instance)
            dungeonPoints[#dungeonPoints + 1] = { m = m, x = x, y = y }
            local name = instance.maps and Compat.GetMapName(instance.maps[1]) or string.format(L.ZONE_DUNGEON_ID, instanceID)
            lists.dungeons[#lists.dungeons + 1] = {
                key = "inst:" .. instanceID, icon = iconOf("entrance"), text = U.Escape(name), title = name,
                right = #children > 0 and progressRight(done, #children) or "", children = #children > 0 and children or nil,
                done = #children > 0 and done == #children or nil, m = m, x = x, y = y,
            }
            counts.dungeons[1] = counts.dungeons[1] + done
            counts.dungeons[2] = counts.dungeons[2] + #children
        end
    end
    -- entrances you found that the reference data does not list
    for _, rec in ipairs(entrances) do
        if not nearAny(dungeonPoints, rec.m, rec.x, rec.y) then
            add("dungeons", recordRow(rec, store:IsPersonal(rec) and CHECK or (rec.inn or "")), nil, true)
        end
    end
    -- achievements of the zone (exploring it among them), with their steps
    for _, achievementID in ipairs(zref.a or EMPTY) do
        local achievement = Compat.GetAchievement(achievementID)
        if achievement then
            local children, stepsDone = {}, 0
            for _, step in ipairs(achievement.criteria) do
                children[#children + 1] = { text = U.Escape(step.text), right = step.completed and CHECK or QUEST_STATUS.open, done = step.completed or nil }
                if step.completed then stepsDone = stepsDone + 1 end
            end
            add("achievements", {
                key = "ach:" .. achievementID, icon = ACHIEVEMENT_ICON, text = U.Escape(achievement.name), title = achievement.name,
                right = #children > 0 and progressRight(stepsDone, #children, achievement.completed and CHECK) or (achievement.completed and CHECK or ""),
                done = achievement.completed or nil, children = #children > 0 and children or nil,
            }, achievement.completed)
        end
    end

    local byName = function(a, b) return a.text < b.text end
    for key, list in pairs(lists) do
        if key ~= "dungeons" and key ~= "achievements" then table.sort(list, byName) end
    end

    local sections = {}
    local function section(key, title, rows, done, total)
        if #rows > 0 then sections[#sections + 1] = { key = key, title = title, rows = rows, done = done, total = total } end
    end
    section("quests", L.ZONE_QUESTS, groups, questDone, questTotal)
    for _, key in ipairs({ "rares", "finds", "travel", "dungeons", "achievements", "explored" }) do
        local c = counts[key]
        section(key, L["ZONE_" .. key:upper()], lists[key], c[1], c[2] > 0 and c[2] or nil)
    end
    section("recipes", L.ZONE_RECIPES, lists.recipes)

    local done, total = 0, 0
    for _, s in ipairs(sections) do
        if s.total then
            done, total = done + s.done, total + s.total
        end
    end
    return sections, done, total
end

------------------------------------------------------------------------
-- Panel
------------------------------------------------------------------------

function Guide:Build()
    if self.frame then return self.frame end
    self.groups = {}
    local frame = UI.Panel(UIParent, { name = "ForeverCompanionZoneGuide", strata = "MEDIUM", bg = "bg", bgAlpha = 0.92, skin = "panel", corner = 8, tint = 0.8 })
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_HEIGHT)
    header.accent = UI.AccentLine(header, 0)
    header.logo = header:CreateTexture(nil, "ARTWORK")
    header.logo:SetTexture(C.MEDIA .. "Logo")
    header.logo:SetSize(18, 18)
    header.logo:SetPoint("TOPLEFT", 10, -10)
    header.zone = UI.Text(header, "cardTitle", "text")
    header.zone:SetPoint("LEFT", header.logo, "RIGHT", 7, 0)
    header.zone:SetPoint("RIGHT", -54, 0)
    header.source = UI.Text(header, "meta", "muted")
    header.source:SetPoint("TOPLEFT", header.logo, "BOTTOMLEFT", 0, -4)
    header.summary = UI.Text(header, "meta", "text")
    header.summary:SetPoint("TOPLEFT", header.source, "BOTTOMLEFT", 0, -3)
    header.summary:SetPoint("RIGHT", -10, 0)
    -- the zone's progress as a thin bar under the summary
    header.track = UI.Texture(header, "ARTWORK", "border", 0.8)
    header.track:SetPoint("BOTTOMLEFT", 10, 7)
    header.track:SetPoint("BOTTOMRIGHT", -10, 7)
    header.track:SetHeight(3)
    header.fill = UI.Texture(header, "OVERLAY", "accent", 1)
    header.fill:SetPoint("TOPLEFT", header.track, "TOPLEFT")
    header.fill:SetPoint("BOTTOMLEFT", header.track, "BOTTOMLEFT")
    header.close = UI.IconButton(header, "Interface\\Buttons\\UI-StopButton", 18, L.CLOSE, function() self:Hide() end)
    header.close:SetPoint("TOPRIGHT", -6, -7)
    header.hideDone = UI.IconButton(header, "Interface\\RaidFrame\\ReadyCheck-Ready", 18, nil, function()
        FC.Config:Set("zoneGuide.hideDone", not FC.P.zoneGuide.hideDone)
    end)
    header.hideDone:SetPoint("RIGHT", header.close, "LEFT", -4, 0)
    header.hideDone:SetScript("OnEnter", function(b)
        UI.ShowTooltip(b, FC.P.zoneGuide.hideDone and L.ZONE_SHOW_DONE or L.ZONE_HIDE_DONE)
    end)
    header.hideDone:SetScript("OnLeave", UI.HideTooltip)
    UI.MakeMovable(frame, header, function(point, relPoint, x, y)
        FC.P.zoneGuide.point = { point, relPoint, x, y }
    end)
    self.header = header

    local area = UI.ScrollArea(frame)
    area:SetPoint("TOPLEFT", 8, -(HEADER_HEIGHT + 4))
    area:SetPoint("BOTTOMRIGHT", -4, 8)
    self.area = area
    local content = area.content

    self.titles = UI.Pool(function()
        local title = CreateFrame("Button", nil, content)
        title:SetHeight(TITLE_ROW)
        title.hover = UI.Texture(title, "HIGHLIGHT", "text", 0.05)
        title.hover:SetAllPoints()
        title.fold = title:CreateTexture(nil, "ARTWORK")
        title.fold:SetSize(12, 12)
        title.fold:SetPoint("LEFT", 2, 0)
        title.label = UI.Text(title, "meta", "accent")
        title.label:SetPoint("LEFT", title.fold, "RIGHT", 5, 0)
        title.count = UI.Text(title, "meta", "muted")
        title.count:SetPoint("RIGHT", -4, 0)
        title.count:SetJustifyH("RIGHT")
        title.line = UI.Divider(title, "border", 0.6)
        title.line:SetPoint("BOTTOMLEFT", 2, 0)
        title.line:SetPoint("BOTTOMRIGHT", -2, 0)
        title:SetScript("OnClick", function(t)
            local collapsed = FC.P.zoneGuide.collapsed
            collapsed[t.key] = not collapsed[t.key] or nil
            self:Refresh()
        end)
        return title
    end, function(title) title.key = nil end)
    self.rows = UI.Pool(function()
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(ROW)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.06)
        row.hover:SetAllPoints()
        row.fold = row:CreateTexture(nil, "ARTWORK")
        row.fold:SetSize(10, 10)
        row.icon = UI.Icon(row, 14)
        row.label = UI.Text(row, "secondary", "text")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetPoint("RIGHT", -92, 0)
        row.right = UI.Text(row, "meta", "muted")
        row.right:SetPoint("RIGHT", -4, 0)
        row.right:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(r, button) Guide:OnRowClick(r.data, button) end)
        row:SetScript("OnEnter", function(r) Guide:RowTooltip(r) end)
        row:SetScript("OnLeave", UI.HideTooltip)
        return row
    end, function(row) row.data = nil end)

    self.empty = UI.WrappedText(content, "secondary", "muted")
    self.empty:SetPoint("TOPLEFT", 4, -8)
    self.empty:SetWidth(WIDTH - 40)
    self.empty:SetText(L.ZONE_EMPTY)

    frame:SetScript("OnShow", function() self:Refresh() end)
    self:Place()
    return frame
end

function Guide:Place()
    local p = FC.P.zoneGuide.point
    self.frame:ClearAllPoints()
    if type(p) == "table" and U.IsAnchor(p[1]) then
        self.frame:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
    else
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -240)
    end
    self.frame:SetScale(FC.P.appearance.scale or 1)
end

function Guide:RowTooltip(row)
    local data = row.data
    if not data then return end
    if data.rec and not data.questID then
        local info = UI.Display(data.rec)
        UI.ShowTooltip(row, U.Escape(info.title), { { UI.MetaLine(info, true), "muted" }, { L.ZONE_ROW_HINT, "muted" } }, info.icon)
    elseif data.children then
        UI.ShowTooltip(row, data.text, { { data.right or "", "muted" }, { L.ZONE_ROW_HINT_GROUP, "muted" } })
    elseif data.questID then
        local lines = { { L[STATUS_TEXT[data.status] or "QUEST_STATUS_OPEN"], "muted" } }
        local start = data.start
        if data.title then
            lines[#lines + 1] = { string.format(L.ZONE_GIVEN_BY, U.Escape(data.title)), "muted" }
        elseif start and start.kind == "object" then
            lines[#lines + 1] = { string.format(L.QUESTLOG_STARTS_OBJECT, U.Escape(start.name or string.format(L.ZONE_OBJECT_ID, start.id))), "muted" }
        elseif start and start.kind == "item" then
            local name = Compat.GetItemName(start.id) or string.format(L.TIP_ITEM_ID, start.id)
            lines[#lines + 1] = { string.format(L.QUESTLOG_STARTS_ITEM, U.Escape(name)), "muted" }
        end
        if data.rec or (data.m and data.x) then lines[#lines + 1] = { L.ZONE_ROW_HINT_NPC, "muted" } end
        UI.ShowTooltip(row, data.text, lines, QUEST_ICON)
    else
        UI.ShowTooltip(row, data.text, { { L.ZONE_ROW_HINT_NPC, "muted" } })
    end
end

function Guide:OnRowClick(data, button)
    if not data then return end
    if data.children and button ~= "RightButton" then
        self.groups[data.key] = not self:GroupOpen(data)
        self:Refresh()
    elseif button == "RightButton" and data.rec then
        FC.MainWindow:ShowDiscovery(data.rec.id)
    elseif data.rec then
        FC.Waypoints:Set(data.rec)
    elseif data.m and data.x then
        FC.Waypoints:Set({ m = data.m, x = data.x, y = data.y, n = data.title })
    end
end

--- A quest giver's quests are open until all of them are done, unless folded by hand.
function Guide:GroupOpen(data)
    local state = self.groups and self.groups[data.key]
    if state == nil then return not data.done end
    return state
end

--- The zone to show: the world map's while following it, else yours.
function Guide:Target()
    if self.mapID then
        return self.mapID, Compat.GetMapName(self.mapID) or L.UNKNOWN_ZONE, true
    end
    local mapID = Compat.GetPlayerMapID()
    local zone = Compat.GetZoneTexts()
    zone = zone ~= "" and zone or (mapID and Compat.GetMapName(mapID)) or L.UNKNOWN_ZONE
    return mapID, zone, false
end

function Guide:DrawRow(data, depth, y, width)
    local row = self.rows:Acquire()
    row.data = data
    row:SetPoint("TOPLEFT", 0, -y)
    row:SetWidth(width - 2)
    local left = 2 + depth * INDENT
    row.fold:ClearAllPoints()
    if data.children then
        row.fold:SetTexture(self:GroupOpen(data) and UNFOLDED or FOLDED)
        row.fold:SetPoint("LEFT", left, 0)
        row.fold:Show()
        left = left + 13
    else
        row.fold:Hide()
    end
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", left, 0)
    UI.SetIcon(row.icon, data.icon or QUEST_ICON)
    row.icon:SetShown(depth == 0)
    if depth > 0 then
        row.label:SetPoint("LEFT", row.icon, "LEFT", 0, 0)
    else
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    end
    row.icon:SetDesaturated(data.desaturate and true or false)
    row.label:SetText(data.text)
    Theme:Paint(row.label, data.done and "muted" or "text")
    row.right:SetText(data.right or "")
    return y + ROW
end

function Guide:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    local mapID, zone, fromMap = self:Target()
    local sections, done, total = self:Collect(mapID, zone)
    local header = self.header
    header.zone:SetText(zone)
    header.source:SetText(fromMap and L.ZONE_FROM_MAP or L.ZONE_HERE)
    local hideDone = FC.P.zoneGuide.hideDone
    header.hideDone:SetActive(hideDone)
    if total > 0 then
        header.summary:SetText(string.format(L.ZONE_PROGRESS, done, total, math.floor(done / total * 100)))
        local width = header.track:GetWidth()
        if not width or width < 10 then width = WIDTH - 22 end
        header.fill:SetWidth(math.max(1, width * done / total))
        header.fill:SetShown(done > 0)
        header.track:Show()
    else
        header.summary:SetText(#sections > 0 and L.ZONE_SUMMARY_INFO or L.ZONE_SUMMARY_NONE)
        header.fill:Hide()
        header.track:Hide()
    end

    self.titles:ReleaseAll()
    self.rows:ReleaseAll()
    local collapsed = FC.P.zoneGuide.collapsed
    local width = self.area:ContentWidth()
    local y, count = 2, 0
    for _, section in ipairs(sections) do
        local title = self.titles:Acquire()
        title.key = section.key
        title:SetPoint("TOPLEFT", 0, -y)
        title:SetWidth(width - 2)
        title.fold:SetTexture(collapsed[section.key] and FOLDED or UNFOLDED)
        title.label:SetText(section.title:upper())
        title.count:SetText(section.total and string.format(L.TIP_PROGRESS, section.done, section.total) or "")
        y = y + TITLE_ROW + 2
        if not collapsed[section.key] then
            for _, data in ipairs(section.rows) do
                if not (hideDone and data.done) then
                    y = self:DrawRow(data, 0, y, width)
                    count = count + 1
                    if data.children and self:GroupOpen(data) then
                        for _, child in ipairs(data.children) do
                            if not (hideDone and child.done) then
                                y = self:DrawRow(child, 1, y, width)
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
        y = y + 6
    end
    self.empty:SetShown(#sections == 0)
    self.area:SetContentHeight(math.max(y, 40))
    return count
end

function Guide:QueueRefresh()
    if self.frame and self.frame:IsShown() then
        U.Debounce("zone-guide", 0.4, function() self:Refresh() end)
    end
end

--- Opens the panel for your zone, or for a map's zone (and follows the map).
function Guide:Show(mapID)
    self:Build()
    self.mapID = mapID
    -- above the world map while it shows the map's zone
    self.frame:SetFrameStrata(mapID and "FULLSCREEN_DIALOG" or "MEDIUM")
    FC.P.zoneGuide.shown = true
    self.frame:Show()
    self:Refresh()
end

function Guide:Hide()
    FC.P.zoneGuide.shown = false
    self.mapID = nil
    if self.frame then self.frame:Hide() end
end

function Guide:Toggle()
    if self.frame and self.frame:IsShown() and not self.mapID then self:Hide() else self:Show() end
end

--- The world map button: this map's zone, or close it when it is already shown.
function Guide:ToggleForMap(mapID)
    if self.frame and self.frame:IsShown() and self.mapID == mapID then
        self:Hide()
    else
        self:Show(mapID)
    end
end

function Guide:OnWorldMapChanged(mapID)
    if self.mapID and mapID and mapID ~= self.mapID and self.frame and self.frame:IsShown() then
        self.mapID = mapID
        self:QueueRefresh()
    end
end

function Guide:OnWorldMapClosed()
    if self.mapID then
        self.mapID = nil
        if self.frame then self.frame:SetFrameStrata("MEDIUM") end
        self:QueueRefresh()
    end
end

function Guide:OnEnable()
    if FC.P.zoneGuide.shown then self:Show() end
    local function refresh() self:QueueRefresh() end
    for _, message in ipairs({ "DISCOVERY_ADDED", "DISCOVERY_UPDATED", "DISCOVERY_REMOVED", "DISCOVERY_STATE", "STORE_RESET", "QUEST_LORE_CHANGED", "QUEST_TITLE_LOADED", "RARE_DEFEATED" }) do
        FC.Bus:On(message, self, refresh)
    end
    FC.Bus:On("ZONE_UPDATED", self, function()
        if FC.P.zoneGuide.autoOpen and not (self.frame and self.frame:IsShown()) and not Compat.GetInstance() then
            self:Show()
        else
            self:QueueRefresh()
        end
    end)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^zoneGuide") or path:find("^appearance%.scale") then
            if self.frame then self:Place() end
            refresh()
        end
    end)
    FC.Events:Register("QUEST_LOG_UPDATE", self, refresh)
    FC.Events:Register("TAXIMAP_CLOSED", self, refresh)
end
