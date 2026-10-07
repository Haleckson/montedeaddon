--[[
  Forever Companion - UI/CardList.lua
  Discovery cards (FCCard) and the virtualized list that shows them.

  Only the cards that fit on screen exist as frames; scrolling re-binds
  them to other records. A journal with thousands of entries costs the same
  as one with fifty.

  UI.Display(rec) is the single place that decides how a record is
  presented (title, icon, lines), including the Discovery Fog veil, so the
  journal, map pins, tooltips and notifications never disagree.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Theme = FC.Theme
local Categories = FC.Categories

local HEIGHT = { comfortable = 72, compact = 46 }
local GAP = 4 -- empty strip at the bottom of every row (the card background stops short of it)

--- Presentation data for a record.
function UI.Display(rec)
    local store = FC.Store
    local def = Categories:Get(rec.t)
    local status = store:GetStatus(rec)
    -- who found it and when, as the journal tells it (per character: this character)
    local by, at = store:Credit(rec)
    local info = {
        rec = rec,
        def = def,
        status = status,
        typeLabel = L[def.label],
        zone = rec.z or (rec.m and FC.Compat.GetMapName(rec.m)) or L.UNKNOWN_ZONE,
        subzone = rec.sz,
        coords = U.FormatCoords(rec.x, rec.y),
        author = U.ShortName(by),
        time = at,
        special = def.special,
        recovered = rec.rcv == true, -- read back from the game: its date is not when it was found
    }
    if status.rumored then
        info.title = string.format(L.RUMORED_TITLE, info.typeLabel)
        info.icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        info.description = L.RUMORED_DESC
        info.rumored = true
    else
        info.title = rec.n or "?"
        info.icon = rec.ic or def.icon
        info.description = rec.d
        if rec.t == "vendor" and rec.inv then
            local recipes, limited = 0, 0
            for _, item in ipairs(rec.inv) do
                if item.rc then recipes = recipes + 1 end
                if item.l then limited = limited + 1 end
            end
            local parts = {}
            parts[#parts + 1] = string.format(L.VENDOR_ITEMS, #rec.inv)
            if recipes > 0 then parts[#parts + 1] = string.format(L.VENDOR_RECIPES, recipes) end
            if limited > 0 then parts[#parts + 1] = string.format(L.VENDOR_LIMITED, limited) end
            info.description = table.concat(parts, "  \194\183  ") .. (rec.d and ("  \194\183  " .. rec.d) or "")
        elseif rec.src and not rec.d then
            info.description = string.format(L.SOURCE_FORMAT, rec.src)
        end
    end
    return info
end

--- "Discovered by Name, 3 days ago", or for an entry read back from the game
--- that it was explored before the journal watched.
function UI.DiscoveredLine(info)
    if info.recovered then return string.format(L.DISCOVERED_BY_RECOVERED, info.author) end
    return string.format(L.DISCOVERED_BY_AGO, info.author, U.TimeAgo(info.time))
end

--- "Rare NPC · Ashenvale · 42.3, 67.8"
function UI.MetaLine(info, withAuthor)
    local parts = { info.typeLabel }
    if info.zone then parts[#parts + 1] = info.zone end
    if info.coords and not info.rumored then parts[#parts + 1] = info.coords end
    if withAuthor and info.author then parts[#parts + 1] = string.format(L.BY_AUTHOR, info.author) end
    return table.concat(parts, "  \194\183  ")
end

------------------------------------------------------------------------
-- Card
------------------------------------------------------------------------

local function createCard(parent, owner)
    local card = CreateFrame("Button", nil, parent)
    card.owner = owner
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.bg = UI.Texture(card, "BACKGROUND", "panel", 1)
    card.bg:SetPoint("TOPLEFT", 0, 0)
    card.bg:SetPoint("BOTTOMRIGHT", 0, GAP)
    card.hover = UI.Texture(card, "HIGHLIGHT", "text", 0.045)
    card.hover:SetAllPoints(card.bg)
    card.bar = UI.Texture(card, "ARTWORK", "accent", 1)
    card.bar:SetPoint("TOPLEFT", card.bg)
    card.bar:SetPoint("BOTTOMLEFT", card.bg)
    card.bar:SetWidth(3)

    -- secret styling: gold edge with a slow shimmer
    card.edge = CreateFrame("Frame", nil, card)
    card.edge:SetAllPoints(card.bg)
    UI.AddBorder(card.edge, "secret", 0.75)
    card.glow = UI.Texture(card, "BACKGROUND", "secret", 0.07, -6)
    card.glow:SetAllPoints(card.bg)
    local pulse = card.glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.35)
    fade:SetToAlpha(1)
    fade:SetDuration(1.6)
    fade:SetSmoothing("IN_OUT")
    card.pulse = pulse

    card.iconBorder = card:CreateTexture(nil, "ARTWORK", nil, 1)
    card.iconBorder:SetTexture(C.WHITE)
    card.icon = UI.Icon(card, 36, "ARTWORK")
    card.icon:SetDrawLayer("ARTWORK", 2)

    card.title = UI.Text(card, "cardTitle", "text")
    card.meta = UI.Text(card, "meta", "muted")
    card.desc = UI.Text(card, "secondary", "muted")
    card.time = UI.Text(card, "meta", "muted")
    card.time:SetJustifyH("RIGHT")

    card.fav = card:CreateTexture(nil, "OVERLAY")
    card.fav:SetTexture(C.FAVORITE_ICON)
    card.fav:SetSize(14, 14)
    card.verify = card:CreateTexture(nil, "OVERLAY")
    card.verify:SetTexture(C.VERIFIED_ICON)
    card.verify:SetSize(12, 12)
    card.verifyCount = UI.Text(card, "meta", "success")
    card.badge = UI.StatusBadge(card)

    card:SetScript("OnClick", function(self, mouseButton)
        if not self.rec then return end
        if mouseButton == "RightButton" then
            FC.MainWindow:OpenContextMenu(self.rec)
        elseif IsShiftKeyDown() then
            FC.ChatLinks:Insert(self.rec)
        else
            self.owner:Select(self.rec.id)
        end
    end)
    card:SetScript("OnEnter", function(self)
        if not self.info then return end
        local info = self.info
        local lines = { { UI.MetaLine(info), "muted" } }
        if info.subzone and not info.rumored then lines[#lines + 1] = { info.subzone, "muted" } end
        if info.description then lines[#lines + 1] = { info.description, "text" } end
        lines[#lines + 1] = { UI.DiscoveredLine(info), "accent" }
        local count = FC.Store:VerifyCount(self.rec)
        if count > 1 then lines[#lines + 1] = { string.format(L.CONFIRMED_BY_N, count), UI.STATUS.verified.color } end
        lines[#lines + 1] = { L.CARD_HINT, "muted" }
        UI.ShowTooltip(self, info.title, lines, info.icon)
    end)
    card:SetScript("OnLeave", UI.HideTooltip)
    return card
end

local function layoutCard(card, compact)
    local iconSize = compact and 28 or 38
    card.icon:SetSize(iconSize, iconSize)
    card.icon:ClearAllPoints()
    card.icon:SetPoint("LEFT", card.bg, "LEFT", 12, 0)
    card.iconBorder:ClearAllPoints()
    card.iconBorder:SetPoint("TOPLEFT", card.icon, -1, 1)
    card.iconBorder:SetPoint("BOTTOMRIGHT", card.icon, 1, -1)

    card.time:ClearAllPoints()
    card.time:SetPoint("TOPRIGHT", card.bg, "TOPRIGHT", -12, compact and -8 or -11)
    card.fav:ClearAllPoints()
    card.fav:SetPoint("RIGHT", card.time, "LEFT", -8, 0)

    card.title:ClearAllPoints()
    card.title:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 12, compact and 1 or -1)
    card.title:SetPoint("RIGHT", card.fav, "LEFT", -8, 0)
    card.meta:ClearAllPoints()
    card.meta:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, compact and -4 or -5)
    card.meta:SetPoint("RIGHT", card.bg, "RIGHT", -120, 0)

    card.badge:ClearAllPoints()
    card.badge:SetPoint("BOTTOMRIGHT", card.bg, "BOTTOMRIGHT", -10, compact and 6 or 9)
    card.badge.compact = compact
    card.verifyCount:ClearAllPoints()
    card.verifyCount:SetPoint("RIGHT", card.badge, "LEFT", -8, 0)
    card.verify:ClearAllPoints()
    card.verify:SetPoint("RIGHT", card.verifyCount, "LEFT", -2, 0)

    card.desc:ClearAllPoints()
    card.desc:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -5)
    card.desc:SetPoint("RIGHT", card.verify, "LEFT", -10, 0)
    card.desc:SetShown(not compact)
end

local function bindCard(card, rec, selected)
    card.rec = rec
    local info = UI.Display(rec)
    card.info = info
    local status = info.status
    UI.SetIcon(card.icon, info.icon)
    card.icon:SetDesaturated(info.rumored and true or false)
    card.iconBorder:SetColorTexture(Theme:CategoryColor(rec.t))
    card.title:SetText(U.Escape(info.title))
    if info.rumored then Theme:Paint(card.title, "muted") else Theme:Paint(card.title, "text") end
    card.meta:SetText(UI.MetaLine(info, true))
    local desc = info.description and U.Escape(info.description:gsub("\n", " ")) or ""
    local tags = FC.Store:AllTags(rec)
    if #tags > 0 and not info.rumored then
        local accent = Theme:Hex("accent")
        local tagText = {}
        for i = 1, math.min(3, #tags) do tagText[i] = "#" .. U.Escape(tags[i]) end
        desc = (desc ~= "" and desc .. "   " or "") .. U.Colorize(table.concat(tagText, " "), accent)
    end
    card.desc:SetText(desc)
    card.time:SetText(info.recovered and L.RECOVERED_SHORT or U.ShortAgo(info.time))
    card.fav:SetShown(status.favorite)
    local count = FC.Store:VerifyCount(rec)
    card.verify:SetShown(count > 1)
    card.verifyCount:SetShown(count > 1)
    card.verifyCount:SetText(count > 1 and tostring(count) or "")
    card.badge:SetStatus(status.archived and "archived" or status.primary)

    card.bar:SetShown(selected)
    local sheet = FC.Skin:Enabled()
    Theme:Paint(card.bg, selected and "panelAlt" or "panel", sheet and (selected and 0.92 or 0.42) or 1)
    local special = info.special and not info.rumored
    card.edge:SetShown(special)
    card.glow:SetShown(special)
    if special and UI.AnimationsEnabled() then
        if not card.pulse:IsPlaying() then card.pulse:Play() end
    else
        card.pulse:Stop()
    end
    card:SetAlpha(status.archived and 0.6 or 1)
end

------------------------------------------------------------------------
-- Virtual list
------------------------------------------------------------------------

--- Creates the card list. owner must implement :Select(id) and :IsSelected(id).
function UI.CardList(parent, owner)
    local list = CreateFrame("Frame", nil, parent)
    list.cards = {}
    list.items = {}
    list.offset = 0
    list.owner = owner
    -- nothing a card draws may leave the list (it would cover the footer and the window border)
    if list.SetClipsChildren then list:SetClipsChildren(true) end

    local bar = UI.CreateScrollbar(list, function(value)
        list.offset = math.floor(value + 0.5)
        list:Render()
    end)
    bar:SetPoint("TOPRIGHT", 0, -2)
    bar:SetPoint("BOTTOMRIGHT", 0, 2)
    list.bar = bar

    function list:RowHeight()
        return HEIGHT[FC.P.appearance.cardDensity] or HEIGHT.comfortable
    end

    --- Cards that fit completely. A card that would be cut by the bottom edge
    --- is not shown at all; the last row's empty gap may stay outside.
    function list:VisibleCount()
        return math.max(1, math.floor(((self:GetHeight() or 0) + GAP) / self:RowHeight()))
    end

    function list:EnsureCards()
        local needed = self:VisibleCount()
        for i = #self.cards + 1, needed do
            self.cards[i] = createCard(self, self.owner)
        end
    end

    function list:SetItems(items, keepOffset)
        self.items = items or {}
        if not keepOffset then self.offset = 0 end
        self:Render()
    end

    function list:Render()
        self:EnsureCards()
        local rowHeight = self:RowHeight()
        local visible = self:VisibleCount()
        local maxOffset = math.max(0, #self.items - visible)
        self.offset = U.Clamp(self.offset, 0, maxOffset)
        local compact = FC.P.appearance.cardDensity == "compact"
        for i, card in ipairs(self.cards) do
            local rec = i <= visible and self.items[i + self.offset]
            if rec then
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
                card:SetPoint("RIGHT", self.bar, "LEFT", -6, 0)
                card:SetHeight(rowHeight)
                if card.fcCompact ~= compact then
                    layoutCard(card, compact)
                    card.fcCompact = compact
                end
                bindCard(card, rec, self.owner:IsSelected(rec.id))
                card:Show()
            else
                card.rec = nil
                card.pulse:Stop()
                card:Hide()
            end
        end
        bar.fcUpdating = true
        bar:SetMinMaxValues(0, maxOffset)
        bar:SetValue(self.offset)
        bar.fcUpdating = false
        bar:SetShown(maxOffset > 0)
    end

    function list:ScrollTo(id)
        for index, rec in ipairs(self.items) do
            if rec.id == id then
                local visible = self:VisibleCount()
                if index <= self.offset or index > self.offset + visible then
                    self.offset = math.max(0, index - math.floor(visible / 2))
                end
                self:Render()
                return true
            end
        end
        return false
    end

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        self.offset = self.offset - delta * (IsShiftKeyDown() and 5 or 1)
        self:Render()
    end)
    list:SetScript("OnSizeChanged", function(self) self:Render() end)
    return list
end
