--[[
  Forever Companion - UI/DetailPanel.lua
  Right-hand detail page of the journal: header, action toolbar and a
  scrollable body built from pooled blocks (so re-selecting never leaks
  frames). Sections appear only when they have content: details, description,
  respawn observations, vendor inventory, dungeon hierarchy, related
  discoveries, tags, personal note, guild notes and verification history.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Theme = FC.Theme
local Categories = FC.Categories
local Compat = FC.Compat

local PAD = 16
local TOOL_STEP = 28     -- action button spacing when the panel is wide enough
local TOOL_MIN_STEP = 22 -- below this the toolbar wraps into two rows

local DUNGEON_SECTIONS = {
    { key = "entrance", types = { entrance = true }, label = "DUNGEON_ENTRANCE" },
    { key = "boss", types = { boss = true }, label = "DUNGEON_BOSSES" },
    { key = "npc", types = { npc = true, rare = true, trainer = true, vendor = true, creature = true, travel = true }, label = "DUNGEON_NPCS" },
    { key = "quest", types = { quest = true, questchain = true }, label = "DUNGEON_QUESTS" },
    { key = "secret", types = { secret = true, room = true, cave = true, path = true, treasure = true, object = true, landmark = true }, label = "DUNGEON_SECRETS" },
    { key = "recipe", types = { recipe = true, profession = true }, label = "DUNGEON_RECIPES" },
    { key = "loot", types = { item = true }, label = "DUNGEON_LOOT" },
    { key = "mechanic", types = { mechanic = true }, label = "DUNGEON_MECHANICS" },
    { key = "shortcut", types = { shortcut = true }, label = "DUNGEON_SHORTCUTS" },
    { key = "note", types = { note = true, other = true }, label = "DUNGEON_NOTES" },
}

function UI.DetailPanel(parent)
    local panel = UI.Panel(parent, { bg = "panel", border = "border", skin = "panel", corner = 14 })
    panel.blocks = {}

    -- everything scrolls, the header block too: a short panel (small
    -- window, large UI scale, many filter rows) never draws past its edge
    panel.body = UI.ScrollArea(panel)
    panel.body:SetPoint("TOPLEFT", PAD - 2, -(PAD - 4))
    panel.body:SetPoint("BOTTOMRIGHT", -6, 8)
    -- the same margin on both sides while there is nothing to scroll (the
    -- panel lays out again when its width changes, below)
    panel.body:AutoGutter()
    local head = CreateFrame("Frame", nil, panel.body.content)
    head:SetPoint("TOPLEFT", 2, -4)
    head:SetPoint("RIGHT", panel.body.content, "RIGHT", -6, 0)
    head:SetHeight(1)
    panel.head = head

    ------------------------------------------------------------------
    -- Header
    ------------------------------------------------------------------
    panel.iconBorder = head:CreateTexture(nil, "ARTWORK", nil, 1)
    panel.iconBorder:SetTexture(C.WHITE)
    panel.icon = UI.Icon(head, 46, "ARTWORK")
    panel.icon:SetDrawLayer("ARTWORK", 2)
    panel.icon:SetPoint("TOPLEFT", 0, 0)
    panel.iconBorder:SetPoint("TOPLEFT", panel.icon, -1, 1)
    panel.iconBorder:SetPoint("BOTTOMRIGHT", panel.icon, 1, -1)
    panel.title = UI.WrappedText(head, "header", "text")
    panel.title:SetPoint("TOPLEFT", panel.icon, "TOPRIGHT", 12, 0)
    panel.title:SetPoint("RIGHT", head, "RIGHT", 0, 0)
    panel.title:SetMaxLines(2)
    panel.typeLabel = UI.Text(head, "meta", "accent")
    panel.typeLabel:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -5)
    panel.typeLabel:SetPoint("RIGHT", head, "RIGHT", 0, 0)
    panel.badge = UI.StatusBadge(head)
    panel.badge2 = UI.StatusBadge(head)
    panel.badge3 = UI.StatusBadge(head)
    -- the badges' row: they wrap onto a second line in a narrow panel
    panel.badgeRow = CreateFrame("Frame", nil, head)
    panel.badgeRow:SetPoint("TOPLEFT", panel.icon, "BOTTOMLEFT", 0, -10)
    panel.badgeRow:SetPoint("RIGHT", head, "RIGHT", 0, 0)
    panel.badgeRow:SetHeight(18)

    --- The width the header block may use.
    function panel:HeadWidth()
        local width = self.body:ContentWidth() - 8
        return width > 0 and width or 240
    end

    --- Places the shown badges left to right, wrapping when the panel is narrow.
    function panel:LayoutBadges()
        local available = math.floor(self:HeadWidth())
        local x, y = 0, 0
        for _, badge in ipairs({ self.badge, self.badge2, self.badge3 }) do
            if badge:IsShown() then
                local w = badge:GetWidth()
                if x > 0 and x + w > available then x, y = 0, y + 22 end
                badge:ClearAllPoints()
                badge:SetPoint("TOPLEFT", self.badgeRow, "TOPLEFT", x, -y)
                x = x + w + 6
            end
        end
        self.badgeRow:SetHeight(y + 18)
    end

    -- action toolbar
    panel.toolbar = CreateFrame("Frame", nil, head)
    panel.toolbar:SetPoint("TOPLEFT", panel.badgeRow, "BOTTOMLEFT", -2, -10)
    panel.toolbar:SetPoint("RIGHT", head, "RIGHT", 0, 0)
    panel.toolbar:SetHeight(TOOL_STEP)
    panel.actions = {}
    panel.actionOrder = {}
    local ACTIONS = {
        { key = "map", icon = "Interface\\Icons\\INV_Misc_Map_01", tip = "ACTION_SHOW_MAP" },
        { key = "waypoint", icon = "Interface\\Icons\\Ability_Hunter_Pathfinding", tip = "ACTION_WAYPOINT" },
        { key = "favorite", icon = C.FAVORITE_ICON, tip = "ACTION_FAVORITE" },
        { key = "share", icon = C.GUILD_ICON, tip = "ACTION_SHARE" },
        { key = "link", icon = "Interface\\ChatFrame\\UI-ChatWhisperIcon", tip = "ACTION_LINK" },
        { key = "edit", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01", tip = "ACTION_EDIT" },
        { key = "note", icon = "Interface\\Icons\\INV_Misc_Note_01", tip = "ACTION_NOTE" },
        { key = "tag", icon = "Interface\\Icons\\INV_Misc_Ribbon_01", tip = "ACTION_TAG" },
        { key = "verify", icon = C.VERIFIED_ICON, tip = "ACTION_VERIFY" },
        { key = "archive", icon = "Interface\\Icons\\INV_Crate_01", tip = "ACTION_ARCHIVE" },
        { key = "export", icon = "Interface\\Icons\\INV_Scroll_03", tip = "ACTION_EXPORT" },
        { key = "delete", icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", tip = "ACTION_DELETE" },
    }
    for i, action in ipairs(ACTIONS) do
        local button = UI.IconButton(panel.toolbar, action.icon, TOOL_STEP - 2, L[action.tip], function()
            if panel.rec then FC.MainWindow:RunAction(action.key, panel.rec) end
        end)
        panel.actions[action.key] = button
        panel.actionOrder[i] = button
    end

    --- Fits the action buttons into the panel's width: one row that tightens
    --- a little, or two rows when a single row would get too cramped. The
    --- buttons never reach past the panel border.
    function panel:LayoutToolbar()
        local available = math.floor(self:HeadWidth() + 2)
        if available <= 0 then return end
        local count = #self.actionOrder
        local perRow = count
        local step = math.min(TOOL_STEP, math.floor(available / count))
        if step < TOOL_MIN_STEP then
            perRow = math.ceil(count / 2)
            step = math.min(TOOL_STEP, math.floor(available / perRow))
        end
        local size = step - 2
        for i, button in ipairs(self.actionOrder) do
            button:SetSize(size, size)
            button.icon:SetSize(size - 8, size - 8)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", ((i - 1) % perRow) * step, -math.floor((i - 1) / perRow) * step)
        end
        self.toolbar:SetHeight(math.ceil(count / perRow) * step)
    end
    panel:HookScript("OnSizeChanged", function(self)
        self:LayoutToolbar()
        self:LayoutBadges()
    end)

    panel.headerLine = UI.Divider(head, "border")
    panel.headerLine:SetPoint("TOPLEFT", panel.toolbar, "BOTTOMLEFT", 2, -8)
    panel.headerLine:SetPoint("RIGHT", head, "RIGHT", 0, 0)

    --- Height of the header block (icon, badges, actions, rule), where the
    --- sections begin.
    function panel:HeadHeight()
        local title = 46
        if self.title:IsShown() then
            title = math.max(46, self.title:GetStringHeight() + 5 + 14)
        end
        return title + 10 + self.badgeRow:GetHeight() + 10 + self.toolbar:GetHeight() + 9
    end

    -- empty state
    panel.empty = CreateFrame("Frame", nil, panel)
    panel.empty:SetAllPoints()
    panel.empty.icon = UI.Icon(panel.empty, 40)
    panel.empty.icon:SetPoint("CENTER", 0, 40)
    panel.empty.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    panel.empty.icon:SetAlpha(0.6)
    panel.empty.text = UI.WrappedText(panel.empty, "body", "muted")
    panel.empty.text:SetPoint("TOP", panel.empty.icon, "BOTTOM", 0, -12)
    panel.empty.text:SetWidth(240)
    panel.empty.text:SetJustifyH("CENTER")
    panel.empty.text:SetText(L.DETAIL_EMPTY)

    ------------------------------------------------------------------
    -- Pooled blocks
    ------------------------------------------------------------------
    local content = panel.body.content
    panel.headers = UI.Pool(function() return UI.SectionHeader(content) end)
    panel.kvs = UI.Pool(function()
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(18)
        row.key = UI.Text(row, "secondary", "muted")
        row.key:SetPoint("TOPLEFT")
        row.key:SetWidth(110)
        row.value = UI.WrappedText(row, "secondary", "text")
        row.value:SetPoint("TOPLEFT", 116, 0)
        row.value:SetPoint("RIGHT")
        return row
    end)
    panel.texts = UI.Pool(function()
        local holder = CreateFrame("Frame", nil, content)
        holder.text = UI.WrappedText(holder, "body", "text")
        holder.text:SetPoint("TOPLEFT")
        holder.text:SetPoint("RIGHT")
        return holder
    end, function(holder) Theme:Paint(holder.text, "text") end)
    panel.rows = UI.Pool(function()
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(26)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.05)
        row.hover:SetAllPoints()
        row.icon = UI.Icon(row, 18)
        row.icon:SetPoint("LEFT", 2, 0)
        row.label = UI.Text(row, "secondary", "text")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.label:SetPoint("RIGHT", -70, 0)
        row.right = UI.Text(row, "meta", "muted")
        row.right:SetPoint("RIGHT", -4, 0)
        row.right:SetJustifyH("RIGHT")
        row.star = row:CreateTexture(nil, "OVERLAY")
        row.star:SetTexture(C.FAVORITE_ICON)
        row.star:SetSize(12, 12)
        row.star:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
        row:SetScript("OnClick", function(self, mouseButton)
            if self.onClick then FC:SafeCall("detail-row", self.onClick, self, mouseButton) end
        end)
        row:SetScript("OnEnter", function(self)
            if self.itemID then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                pcall(GameTooltip.SetItemByID, GameTooltip, self.itemID)
                if self.onClick then GameTooltip:AddLine(L.INVENTORY_FLAG_HINT, 0.6, 0.6, 0.6) end
                GameTooltip:Show()
            elseif self.tipTitle then
                UI.ShowTooltip(self, self.tipTitle, self.tipLines)
            end
        end)
        row:SetScript("OnLeave", UI.HideTooltip)
        return row
    end, function(row)
        row.onClick, row.itemID, row.tipTitle, row.tipLines = nil, nil, nil, nil
        row.star:Hide()
        Theme:Paint(row.label, "text")
    end)
    panel.chips = UI.Pool(function()
        return UI.Chip(content, "", nil, function(value, mouseButton, chip)
            if chip.onClick then chip.onClick(value, mouseButton) end
        end)
    end, function(chip) chip.onClick = nil end)
    panel.buttons = UI.Pool(function()
        return UI.Button(content, "", { style = "ghost", height = 22, autoWidth = true, width = 40 })
    end)

    ------------------------------------------------------------------
    -- Layout helpers
    ------------------------------------------------------------------
    local y, width

    local function header(text)
        local h = panel.headers:Acquire()
        h:SetText(text)
        h:SetPoint("TOPLEFT", 0, -y)
        h:SetPoint("RIGHT", content, "RIGHT", -4, 0)
        y = y + 28
    end

    local function kv(key, value)
        if value == nil or value == "" then return end
        local row = panel.kvs:Acquire()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", content, "RIGHT", -4, 0)
        row.key:SetText(key)
        row.value:SetWidth(width - 120)
        row.value:SetText(value)
        local h = math.max(16, row.value:GetStringHeight())
        row:SetHeight(h)
        y = y + h + 5
    end

    local function paragraph(text, colorRole)
        local holder = panel.texts:Acquire()
        holder:SetPoint("TOPLEFT", 0, -y)
        holder:SetPoint("RIGHT", content, "RIGHT", -4, 0)
        holder.text:SetWidth(width - 4)
        holder.text:SetText(text)
        if colorRole then Theme:Paint(holder.text, colorRole) end
        local h = holder.text:GetStringHeight()
        holder:SetHeight(h)
        y = y + h + 8
    end

    local function listRow(icon, label, right, onClick)
        local row = panel.rows:Acquire()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", content, "RIGHT", -4, 0)
        UI.SetIcon(row.icon, icon)
        row.label:SetText(label)
        row.right:SetText(right or "")
        row.onClick = onClick
        y = y + 27
        return row
    end

    local function chipRow(chips, addLabel, onAdd)
        local x = 0
        local rowHeight = 22
        for _, spec in ipairs(chips) do
            local chip = panel.chips:Acquire()
            chip:SetChip(spec.text, spec.color)
            chip.onClick = spec.onClick
            if x + chip:GetWidth() > width - 8 then
                x = 0
                y = y + rowHeight
            end
            chip:SetPoint("TOPLEFT", x, -y)
            x = x + chip:GetWidth() + 6
        end
        if addLabel then
            local button = panel.buttons:Acquire()
            button:SetLabel(addLabel)
            button:SetScript("OnClick", function() FC:SafeCall("chip-add", onAdd) end)
            if x + button:GetWidth() > width - 8 then
                x = 0
                y = y + rowHeight
            end
            button:SetPoint("TOPLEFT", x, -y + 2)
        end
        y = y + rowHeight + 8
    end

    local function actionButton(label, onClick)
        local button = panel.buttons:Acquire()
        button:SetLabel(label)
        button:SetScript("OnClick", function() FC:SafeCall("detail-button", onClick) end)
        button:SetPoint("TOPLEFT", 0, -y)
        y = y + 28
    end

    ------------------------------------------------------------------
    -- Sections
    ------------------------------------------------------------------
    local function detailsSection(rec, info)
        local store = FC.Store
        header(L.SECTION_DETAILS)
        kv(L.FIELD_ZONE, info.zone)
        kv(L.FIELD_SUBZONE, info.subzone)
        -- per character, your finds are this character's own, dated when it found them
        local by, at = store:Credit(rec)
        if not info.rumored then
            kv(L.FIELD_COORDS, info.coords)
            local suffix = by == store.me and L.YOU_SUFFIX or (store:IsMine(rec) and L.ALT_SUFFIX)
            kv(L.FIELD_DISCOVERED_BY, U.ShortName(by) .. (suffix and (" " .. suffix) or ""))
        end
        if rec.rcv then
            -- read back from the game: the date is when the journal learned of it
            kv(L.FIELD_FIRST_DISCOVERED, string.format(L.RECOVERED_DATE, U.FormatDate(at)))
        else
            kv(L.FIELD_FIRST_DISCOVERED, U.FormatDate(at) .. "  (" .. U.TimeAgo(at) .. ")")
        end
        -- when the character you play found it (account-wide: when any of yours did)
        local foundAt = store:FoundAt(rec.id) or (not store:PerCharacter() and (store:GetState(rec.id) or {}).seen)
        if foundAt and by ~= store.me then kv(L.FIELD_PERSONAL_DATE, U.FormatDate(foundAt)) end
        if rec.u and rec.u > rec.c + 60 then kv(L.FIELD_UPDATED, U.TimeAgo(rec.u)) end
        kv(L.FIELD_VISIBILITY, rec.v == "p" and L.VISIBILITY_PRIVATE or L.VISIBILITY_GUILD)
        if info.rumored then return end
        if rec.npc then kv(L.FIELD_NPC_ID, tostring(rec.npc)) end
        if rec.lvl then kv(L.FIELD_LEVEL, FC.AutoText.LevelText(rec)) end
        kv(L.FIELD_CREATURE_TYPE, rec.ct)
        if rec.pts then kv(L.FIELD_SPOTS, tostring(#rec.pts)) end
        if rec.tr then kv(L.FIELD_ROUTE, string.format(L.ROUTE_POINTS, #rec.tr)) end
        if rec.cnt and rec.cnt > 1 then kv(L.FIELD_COUNT, tostring(rec.cnt)) end
        if rec.cls and rec.cls ~= "normal" then kv(L.FIELD_CLASSIFICATION, L["CLASS_" .. rec.cls] or rec.cls) end
        if rec.q then kv(L.FIELD_QUEST_ID, tostring(rec.q)) end
        kv(L.FIELD_QUEST_GIVER, rec.gv and (rec.gv .. (rec.gvi and ("  (" .. rec.gvi .. ")") or "")))
        if rec.it then kv(L.FIELD_ITEM_ID, tostring(rec.it)) end
        kv(L.FIELD_SOURCE, rec.src)
        if rec.pr then
            local prof = Categories:Profession(rec.pr)
            kv(L.FIELD_PROFESSION, "|T" .. prof.icon .. ":14:14:0:0:64:64:5:59:5:59|t " .. L[prof.label])
        end
        if rec.sk then kv(L.FIELD_REQUIRED_SKILL, tostring(rec.sk)) end
        if rec.t == "recipe" and rec.it then
            local known = Compat.IsRecipeKnown(rec.it)
            kv(L.FIELD_KNOWN, known == true and L.KNOWN_YES or (known == false and L.KNOWN_NO or L.KNOWN_UNKNOWN))
        end
        kv(L.FIELD_INSTANCE, rec.inn)
        local state = store:GetState(rec.id)
        if rec.t == "quest" and rec.q then
            -- what the game says, so a quest turned in while the addon was away is done too
            if FC.QuestHistory:IsCompleted(rec.q) then
                local turnedIn = FC.Characters:CompletedAt(rec.q)
                kv(L.FIELD_STATUS, turnedIn and string.format(L.QUEST_DONE_AT, U.FormatDate(turnedIn)) or L.QUEST_DONE)
            elseif state and state.done then
                kv(L.FIELD_STATUS, L.QUEST_DONE_OTHER)
            end
        elseif rec.t == "quest" and state and state.done then
            kv(L.FIELD_STATUS, L.QUEST_DONE)
        end
        if rec.t == "quest" and rec.q then
            local names = {}
            for _, alt in ipairs(FC.Characters:CompletedBy(rec.q)) do names[#names + 1] = U.Escape(alt.name) end
            if #names > 0 then kv(L.FIELD_COMPLETED_BY, table.concat(names, ", ")) end
        end
    end

    local function respawnSection(rec)
        if rec.t ~= "rare" then return end
        header(L.SECTION_RESPAWN)
        local estimate = FC.Store:RespawnEstimate(rec)
        local seenCount = rec.obs and rec.obs.s and #rec.obs.s or 0
        if seenCount > 0 then
            kv(L.FIELD_LAST_SEEN, U.TimeAgo(rec.obs.s[#rec.obs.s]))
        end
        if not estimate then
            paragraph(L.RESPAWN_NONE, "muted")
            return
        end
        local parts = {}
        for i = math.max(1, #estimate.intervals - 5), #estimate.intervals do
            parts[#parts + 1] = U.FormatDuration(estimate.intervals[i])
        end
        kv(L.RESPAWN_OBSERVED, table.concat(parts, ", "))
        if estimate.low then
            kv(L.RESPAWN_ESTIMATE, string.format(L.RESPAWN_RANGE, U.FormatDuration(estimate.low), U.FormatDuration(estimate.high), #estimate.intervals))
        else
            paragraph(string.format(L.RESPAWN_NEED_MORE, C.DISCOVERY.ESTIMATE_MIN_SAMPLES), "muted")
        end
    end

    local function inventorySection(rec)
        if rec.t ~= "vendor" or not rec.inv then return end
        header(string.format(L.SECTION_INVENTORY, #rec.inv))
        local state = FC.Store:GetState(rec.id)
        local flags = state and state.flags or {}
        for _, item in ipairs(rec.inv) do
            local tags = {}
            if item.l then tags[#tags + 1] = string.format(L.ITEM_LIMITED, item.l) end
            if item.rc then tags[#tags + 1] = L.ITEM_RECIPE end
            local instant = Compat.GetItemInfoInstant(item.i)
            local name = item.n or ("item:" .. item.i)
            local hex = item.q and Compat.GetQualityHex(item.q)
            local row = listRow(instant and instant.icon, hex and U.Colorize(U.Escape(name), hex) or U.Escape(name), table.concat(tags, " \194\183 "), function()
                FC.Store:ToggleItemFlag(rec.id, item.i)
            end)
            row.itemID = item.i
            row.star:SetShown(flags[item.i] == true)
        end
    end

    local function dropsSection(rec)
        if not rec.dr then return end
        header(string.format(L.SECTION_DROPS, #rec.dr))
        for _, itemID in ipairs(rec.dr) do
            local details = Compat.GetItemInfo(itemID)
            local instant = Compat.GetItemInfoInstant(itemID)
            local name = details and details.name or ("item:" .. itemID)
            local hex = details and details.quality and Compat.GetQualityHex(details.quality)
            local row = listRow(instant and instant.icon, hex and U.Colorize(U.Escape(name), hex) or U.Escape(name), "")
            row.itemID = itemID
        end
    end

    local QUEST_STATUS_ICONS = {
        done = "Interface\\RaidFrame\\ReadyCheck-Ready",
        ready = "Interface\\GossipFrame\\ActiveQuestIcon",
        active = "Interface\\RaidFrame\\ReadyCheck-Waiting",
        open = "Interface\\GossipFrame\\AvailableQuestIcon",
    }
    local QUEST_STATUS_LABELS = { done = "QUEST_STATUS_DONE", ready = "TIP_READY", active = "TIP_IN_PROGRESS", open = "QUEST_STATUS_OPEN" }

    -- what the quest lore knows about this NPC: quests it gives and takes, quest items it drops
    local function questLoreSection(rec)
        if not rec.npc then return end
        local lore = FC.QuestLore
        local given, done = lore:QuestsGivenBy(rec.npc, rec.n)
        local listed = {}
        if #given > 0 then
            header(string.format(L.SECTION_QUESTS_GIVEN, done, #given))
            for _, entry in ipairs(given) do
                listed[entry.questID] = true
                listRow(QUEST_STATUS_ICONS[entry.status] or QUEST_STATUS_ICONS.open, U.Escape(entry.title), L[QUEST_STATUS_LABELS[entry.status] or "QUEST_STATUS_OPEN"])
            end
        end
        local ends = lore:QuestsEndedAt(rec.npc, listed)
        if #ends > 0 then
            header(L.TIP_TURN_IN_HERE)
            for _, entry in ipairs(ends) do
                listRow(QUEST_STATUS_ICONS[entry.status] or QUEST_STATUS_ICONS.open, U.Escape(entry.title), L[QUEST_STATUS_LABELS[entry.status] or "QUEST_STATUS_OPEN"])
            end
        end
        local drops = lore:StarterDrops(rec.npc)
        if #drops > 0 then
            header(L.TIP_QUEST_ITEMS)
            for _, drop in ipairs(drops) do
                local instant = Compat.GetItemInfoInstant(drop.itemID)
                local row = listRow(instant and instant.icon, U.Escape(drop.name) .. (drop.title and ("  \226\134\146  " .. U.Escape(drop.title)) or ""),
                    drop.status and L[QUEST_STATUS_LABELS[drop.status]] or "")
                row.itemID = drop.itemID
            end
        end
    end

    local function dungeonSection(rec)
        if rec.t ~= "dungeon" then return end
        local children = FC.Store:Children(rec.id)
        header(L.SECTION_DUNGEON)
        if #children == 0 then
            paragraph(L.DUNGEON_EMPTY, "muted")
            return
        end
        for _, section in ipairs(DUNGEON_SECTIONS) do
            local first = true
            for _, child in ipairs(children) do
                if section.types[child.t] and FC.Store:IsKnown(child) then
                    if first then
                        local h = panel.texts:Acquire()
                        h:SetPoint("TOPLEFT", 0, -y)
                        h:SetPoint("RIGHT", content, "RIGHT", -4, 0)
                        h.text:SetWidth(width - 4)
                        h.text:SetText(L[section.label])
                        Theme:Paint(h.text, "muted")
                        h:SetHeight(14)
                        y = y + 18
                        first = false
                    end
                    local childInfo = UI.Display(child)
                    listRow(childInfo.icon, U.Escape(childInfo.title), U.ShortName(child.a), function()
                        FC.MainWindow:ShowDiscovery(child.id)
                    end)
                end
            end
        end
    end

    local function relatedSection(rec)
        local related = {}
        if rec.pa and rec.pa ~= rec.id then
            local parentRec = FC.Store:Get(rec.pa)
            if parentRec then related[#related + 1] = { rec = parentRec, label = L.RELATED_PARENT } end
        end
        if rec.t ~= "dungeon" then
            for _, child in ipairs(FC.Store:Children(rec.id)) do
                related[#related + 1] = { rec = child }
            end
        end
        if rec.it then
            for _, other in ipairs(FC.Store:ForItem(rec.it)) do
                if other.id ~= rec.id then related[#related + 1] = { rec = other } end
            end
        end
        if #related == 0 then return end
        header(L.SECTION_RELATED)
        for i = 1, math.min(#related, 20) do
            local entry = related[i]
            if FC.Store:IsKnown(entry.rec) then
                local childInfo = UI.Display(entry.rec)
                listRow(childInfo.icon, U.Escape(childInfo.title), entry.label or childInfo.typeLabel, function()
                    FC.MainWindow:ShowDiscovery(entry.rec.id)
                end)
            end
        end
    end

    local function tagsSection(rec)
        header(L.SECTION_TAGS)
        local store = FC.Store
        local state = store:GetState(rec.id)
        local personal = {}
        for _, tag in ipairs(state and state.tags or {}) do personal[tag] = true end
        local chips = {}
        for _, tag in ipairs(store:AllTags(rec)) do
            chips[#chips + 1] = {
                text = "#" .. tag,
                color = FC.db.tagColors[tag],
                onClick = function(_, mouseButton)
                    if mouseButton == "RightButton" and personal[tag] then
                        store:RemoveUserTag(rec.id, tag)
                    else
                        FC.MainWindow:SetSearch("tag:" .. tag)
                    end
                end,
            }
        end
        chipRow(chips, "+ " .. L.ADD_TAG, function() FC.MainWindow:RunAction("tag", rec) end)
    end

    local function notesSection(rec)
        local state = FC.Store:GetState(rec.id)
        header(L.SECTION_PERSONAL_NOTE)
        if state and state.note then
            paragraph(U.Escape(state.note), "text")
        else
            paragraph(L.NOTE_EMPTY, "muted")
        end
        actionButton(state and state.note and L.EDIT_NOTE or L.ADD_NOTE, function() FC.MainWindow:RunAction("note", rec) end)

        if rec.v == "g" then
            header(L.SECTION_GUILD_NOTES)
            if rec.gn then
                for i = #rec.gn, 1, -1 do
                    local note = rec.gn[i]
                    paragraph(U.Colorize(U.ShortName(note.a), Theme:Hex("accent")) .. "  " .. U.Colorize(U.TimeAgo(note.t), Theme:Hex("muted")) .. "\n" .. U.Escape(note.x), "text")
                end
            else
                paragraph(L.GUILD_NOTES_EMPTY, "muted")
            end
            actionButton(L.ADD_GUILD_NOTE, function()
                UI.Prompt(L.ADD_GUILD_NOTE, L.GUILD_NOTE_PROMPT, "", function(text)
                    FC.Store:AddGuildNote(rec.id, FC.Store.me, text, U.Now(), "local")
                end, C.LIMITS.GUILD_NOTE)
            end)
        end
    end

    local function verificationSection(rec)
        local store = FC.Store
        header(string.format(L.SECTION_VERIFICATION, store:VerifyCount(rec)))
        local by, at = store:Credit(rec)
        listRow(UI.STATUS.personal.icon, U.ShortName(by), L.VERIFY_DISCOVERED .. " \194\183 " .. U.ShortAgo(at))
        if rec.ver then
            local list = {}
            local perCharacter, myChars = store:PerCharacter(), FC.db.myChars
            for name, ts in pairs(rec.ver) do
                -- per character, your other characters stay out of this journal
                if not (perCharacter and myChars[name] and name ~= store.me) then list[#list + 1] = { name = name, ts = ts } end
            end
            table.sort(list, function(a, b) return a.ts < b.ts end)
            for _, entry in ipairs(list) do
                listRow(C.VERIFIED_ICON, U.ShortName(entry.name), L.VERIFY_CONFIRMED .. " \194\183 " .. U.ShortAgo(entry.ts))
            end
        end
    end

    ------------------------------------------------------------------
    -- Public
    ------------------------------------------------------------------
    function panel:Clear()
        self.rec = nil
        self.headers:ReleaseAll()
        self.kvs:ReleaseAll()
        self.texts:ReleaseAll()
        self.rows:ReleaseAll()
        self.chips:ReleaseAll()
        self.buttons:ReleaseAll()
        self.empty:Show()
        for _, region in ipairs({ self.icon, self.iconBorder, self.title, self.typeLabel, self.badge, self.badge2, self.badge3, self.toolbar, self.headerLine, self.body }) do
            region:Hide()
        end
    end

    function panel:ShowRecord(rec)
        if not rec then return self:Clear() end
        self.rec = rec
        self.empty:Hide()
        for _, region in ipairs({ self.icon, self.iconBorder, self.title, self.typeLabel, self.toolbar, self.headerLine, self.body }) do
            region:Show()
        end
        local info = UI.Display(rec)
        local status = info.status
        UI.SetIcon(self.icon, info.icon)
        self.icon:SetDesaturated(info.rumored and true or false)
        self.iconBorder:SetColorTexture(Theme:CategoryColor(rec.t))
        self.title:SetText(U.Escape(info.title))
        self.typeLabel:SetText(info.typeLabel:upper())
        self.badge:SetStatus(status.primary)
        local extra = {}
        if status.favorite then extra[#extra + 1] = "favorite" end
        if status.private then extra[#extra + 1] = "private" end
        if status.archived then extra[#extra + 1] = "archived" end
        self.badge2:SetStatus(extra[1])
        self.badge3:SetStatus(extra[2])
        self:LayoutBadges()

        local mine = FC.Store:IsMine(rec)
        self.actions.map:SetDisabled(not rec.m)
        self.actions.waypoint:SetDisabled(not (rec.m and rec.x))
        self.actions.favorite:SetActive(status.favorite)
        self.actions.archive:SetActive(status.archived)
        self.actions.share:SetDisabled(not FC.Sync:Enabled() or info.rumored)
        self.actions.edit:SetDisabled(not mine)
        self.actions.verify:SetDisabled(mine or info.rumored or (rec.ver and rec.ver[FC.Store.me]) and true or false)
        self.actions.link:SetDisabled(info.rumored)

        self.headers:ReleaseAll()
        self.kvs:ReleaseAll()
        self.texts:ReleaseAll()
        self.rows:ReleaseAll()
        self.chips:ReleaseAll()
        self.buttons:ReleaseAll()

        self:LayoutToolbar()
        self:LayoutBadges()
        y = self:HeadHeight() + 12
        self.head:SetHeight(y)
        width = self.body:ContentWidth() - 6
        if info.rumored then
            paragraph(L.RUMORED_DETAIL, "muted")
            detailsSection(rec, info)
        else
            if info.description then
                header(L.SECTION_DESCRIPTION)
                paragraph(U.Escape(info.description), "text")
            end
            detailsSection(rec, info)
            respawnSection(rec)
            inventorySection(rec)
            dropsSection(rec)
            questLoreSection(rec)
            dungeonSection(rec)
            relatedSection(rec)
            tagsSection(rec)
            notesSection(rec)
            verificationSection(rec)
        end
        self.body:SetContentHeight(y + 12)
    end

    function panel:Refresh()
        if self.rec then
            local rec = FC.Store:Get(self.rec.id)
            if rec then self:ShowRecord(rec) else self:Clear() end
        end
    end

    panel.body.scroll:HookScript("OnSizeChanged", function()
        if panel.rec and panel:IsVisible() then
            U.Debounce("detail-resize", 0.1, function() panel:Refresh() end)
        end
    end)

    panel:Clear()
    return panel
end
