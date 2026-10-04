-- BLib_List.lua
-- A list that can hold thousands of rows. BLib.MakeScrollFrame builds every
-- row it shows, which is fine for a settings page and not for an auction
-- house: an empty browse returns about 5,000 item keys. This one keeps only
-- the rows on screen and redraws them as it scrolls. Written for
-- Countinghouse and moved here in 1.8.0 so Forgemaster's lists match it.
-- Depends on: BLib_Compat.lua, BLib_Core.lua
--
--   local list = BLib.MakeList(parent, width, height, t, columns, opts)
--   list:SetData(items)   list:Refresh()   list:GetSelected()
--
-- columns: { key, title, width, justify = "LEFT"|"RIGHT",
--            fill = true (takes whatever width the others leave; one column),
--            text = function(item) -> string,
--            icon = function(item) -> texture (a 16px icon instead of text),
--            sort = function(item) -> comparable value (clickable header),
--            defaultDesc = bool (the first click on its header sorts high first) }
-- opts:    { rowHeight, onClick(item, mouseButton), onDoubleClick(item),
--            onEnter(row, item), defaultSort = key, defaultDesc = bool,
--            onSort(key, desc)         after a header click re-sorts,
--            emptyText, noHeader = bool, noSelect = bool,
--            buildRow(row, list)       once per row, to add widgets of its own,
--            drawRow(row, item, list)  on every redraw, after the cells,
--            onReorder(from, to)       rows can be dragged; the item at data
--                                      index `from` should end up at `to` }

BLib = BLib or {}

local HEADER_H = 20
local BAR_W    = 8
local GAP      = 6
local LEFT_PAD = 4

local function SetVC(tex, c, a)
    tex:SetVertexColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), a or BLib.CA(c))
end

-- Fixed widths as given; the fill column gets the rest of the row.
local function ColumnWidths(columns, rowW)
    local used, fill = LEFT_PAD, nil
    for i, col in ipairs(columns) do
        if col.fill then
            fill = i
        else
            used = used + col.width
        end
        used = used + GAP
    end
    local widths = {}
    for i, col in ipairs(columns) do
        widths[i] = col.width or 0
    end
    if fill then widths[fill] = math.max(20, rowW - used) end
    return widths
end

function BLib.MakeList(parent, width, height, t, columns, opts)
    opts = opts or {}
    local rowH = opts.rowHeight or 20
    local headerH = opts.noHeader and 0 or HEADER_H
    local list = CreateFrame("Frame", nil, parent)
    list:SetSize(width, height)
    BLib.MakeBg(list, t.panelBg)
    BLib.ApplyBorder(list, list, t.border)

    list.data, list.offset = {}, 0
    list.columns = columns
    list.sortKey, list.sortDesc = opts.defaultSort, opts.defaultDesc or false

    local rowW = width - 2 - BAR_W - 2
    local widths = ColumnWidths(columns, rowW)
    list.widths = widths

    -- -------------------------------------------------- header
    list.headers = {}
    if not opts.noHeader then
        local header = CreateFrame("Frame", nil, list)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(HEADER_H)
        SetVC(BLib.MakeBg(header, t.headerBg), t.headerBg)

        local x = LEFT_PAD
        for i, col in ipairs(columns) do
            local h = CreateFrame("Button", nil, header)
            h:SetPoint("LEFT", header, "LEFT", x, 0)
            h:SetSize(widths[i], HEADER_H)
            h.label = BLib.MakeFS(h, BLib.FONT_SM, t.subText)
            h.label:SetAllPoints()
            h.label:SetJustifyH(col.justify or "LEFT")
            h.col = col
            if col.sort then
                h:SetScript("OnClick", function()
                    if list.sortKey == col.key then
                        list.sortDesc = not list.sortDesc
                    else
                        list.sortKey, list.sortDesc = col.key, col.defaultDesc or false
                    end
                    list:Sort()
                    list:Refresh()
                    if opts.onSort then opts.onSort(list.sortKey, list.sortDesc) end
                end)
                h:SetScript("OnEnter", function() BLib.SetTC(h.label, t.accent) end)
                h:SetScript("OnLeave", function() list:DrawHeaders() end)
            end
            list.headers[#list.headers + 1] = h
            x = x + widths[i] + GAP
        end
    end

    function list:DrawHeaders()
        for _, h in ipairs(self.headers) do
            local text = h.col.title or ""
            if self.sortKey == h.col.key and h.col.sort then
                text = text .. (self.sortDesc and " v" or " ^")
                BLib.SetTC(h.label, t.text)
            else
                BLib.SetTC(h.label, t.subText)
            end
            h.label:SetText(text)
        end
    end

    -- -------------------------------------------------- rows
    local maxRows = math.max(1, math.floor((height - headerH - 2) / rowH))
    local visible = maxRows
    list.rows = {}

    local function RowTop(i)
        return -1 - headerH - (i - 1) * rowH
    end

    for i = 1, maxRows do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 1, RowTop(i))
        row:SetSize(rowW, rowH)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        row.sel = row:CreateTexture(nil, "BACKGROUND")
        BLib.SolidBase(row.sel)
        row.sel:SetAllPoints()
        SetVC(row.sel, t.accent, 0.18)
        row.sel:Hide()

        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        BLib.SolidBase(row.hl)
        row.hl:SetAllPoints()
        SetVC(row.hl, t.buttonHover, 0.6)

        row.cells = {}
        local cx = LEFT_PAD
        for c, col in ipairs(columns) do
            if col.icon then
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(rowH - 4, rowH - 4)
                icon:SetPoint("LEFT", row, "LEFT", cx, 0)
                row.cells[c] = icon
            else
                local fs = BLib.MakeFS(row, BLib.FONT_SM, t.text)
                fs:SetPoint("LEFT", row, "LEFT", cx, 0)
                fs:SetSize(widths[c], rowH)
                fs:SetJustifyH(col.justify or "LEFT")
                fs:SetWordWrap(false)
                row.cells[c] = fs
            end
            row.cells[c].x = cx
            cx = cx + widths[c] + GAP
        end

        row:SetScript("OnClick", function(self, button)
            if not self.item then return end
            if not opts.noSelect then
                list.selected = self.item
                list:Refresh()
            end
            if opts.onClick then opts.onClick(self.item, button) end
        end)
        if opts.onDoubleClick then
            row:SetScript("OnDoubleClick", function(self)
                if self.item then opts.onDoubleClick(self.item) end
            end)
        end
        row:SetScript("OnEnter", function(self)
            if self.item and opts.onEnter then opts.onEnter(self, self.item) end
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip:IsOwned(row) then GameTooltip:Hide() end
        end)
        if opts.buildRow then opts.buildRow(row, list) end
        list.rows[i] = row
    end

    list.empty = BLib.MakeFS(list, BLib.FONT_MD, t.subText)
    list.empty:SetPoint("TOP", list, "TOP", 0, -headerH - 30)
    list.empty:SetWidth(width - 40)

    -- -------------------------------------------------- scrollbar
    local track = CreateFrame("Frame", nil, list)
    track:SetPoint("TOPRIGHT", list, "TOPRIGHT", -2, -1 - headerH - 2)
    track:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -2, 2)
    track:SetWidth(BAR_W)
    SetVC(BLib.MakeBg(track, t.frameBg), t.frameBg)
    local thumb = CreateFrame("Frame", nil, track)
    thumb:SetWidth(BAR_W)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    BLib.SolidBase(thumbTex)
    thumbTex:SetAllPoints()
    SetVC(thumbTex, t.border)
    thumb:EnableMouse(true)
    track:EnableMouse(true)

    local function MaxOffset()
        return math.max(0, #list.data - visible)
    end

    function list:SetOffset(v)
        self.offset = math.max(0, math.min(MaxOffset(), math.floor(v + 0.5)))
        self:Refresh()
    end

    local function DrawThumb()
        local total = #list.data
        if total <= visible then
            track:Hide()
            return
        end
        track:Show()
        -- A track anchored top and bottom has no height until the list has
        -- been laid out; worked out from the rows until then.
        local trackH = track:GetHeight()
        if not trackH or trackH <= 0 then trackH = visible * rowH - 3 end
        local thumbH = math.max(16, trackH * visible / total)
        local pos = (trackH - thumbH) * list.offset / MaxOffset()
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -pos)
    end

    local function OffsetFromCursor(grab)
        local _, y = GetCursorPosition()
        y = y / track:GetEffectiveScale()
        local top, trackH = track:GetTop(), track:GetHeight()
        local thumbH = thumb:GetHeight()
        if not top or trackH <= thumbH then return list.offset end
        local frac = (top - y - grab) / (trackH - thumbH)
        return math.max(0, math.min(1, frac)) * MaxOffset()
    end

    thumb:SetScript("OnMouseDown", function()
        -- How far below the thumb's top it was grabbed, so it does not jump.
        local _, y = GetCursorPosition()
        local grab = (thumb:GetTop() or 0) - y / track:GetEffectiveScale()
        thumb:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                thumb:SetScript("OnUpdate", nil)
                return
            end
            list:SetOffset(OffsetFromCursor(grab))
        end)
    end)
    track:SetScript("OnMouseDown", function()
        list:SetOffset(OffsetFromCursor(thumb:GetHeight() / 2))
    end)

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        self:SetOffset(self.offset - delta * 3)
    end)

    -- -------------------------------------------------- dragging to reorder
    if opts.onReorder then
        local marker = list:CreateTexture(nil, "OVERLAY")
        BLib.SolidBase(marker)
        marker:SetHeight(2)
        SetVC(marker, t.accent)
        marker:Hide()

        -- The gap the cursor is nearest: 1 is above the first item, #data + 1
        -- below the last.
        local function SlotAtCursor()
            local _, y = GetCursorPosition()
            y = y / list:GetEffectiveScale()
            local top = list:GetTop()
            if not top then return nil end
            local pos = (top - 1 - headerH - y) / rowH
            local shown = math.min(visible, #list.data - list.offset)
            pos = math.max(0, math.min(shown, math.floor(pos + 0.5)))
            return list.offset + pos + 1
        end

        local function DragUpdate(_, elapsed)
            local slot = SlotAtCursor()
            if not slot then return end
            -- Held against the top or bottom edge, the list scrolls.
            list.dragTick = (list.dragTick or 0) + elapsed
            if list.dragTick > 0.12 then
                list.dragTick = 0
                if slot <= list.offset + 1 and list.offset > 0 then
                    list:SetOffset(list.offset - 1)
                elseif slot > list.offset + visible and list.offset < MaxOffset() then
                    list:SetOffset(list.offset + 1)
                end
            end
            local i = slot - list.offset
            marker:ClearAllPoints()
            marker:SetPoint("TOPLEFT", list, "TOPLEFT", 1, RowTop(i) + 1)
            marker:SetPoint("TOPRIGHT", list, "TOPLEFT", 1 + rowW, RowTop(i) + 1)
            marker:Show()
        end

        for _, row in ipairs(list.rows) do
            row:RegisterForDrag("LeftButton")
            row:SetScript("OnDragStart", function(self)
                if not self.index then return end
                list.dragFrom = self.index
                list:SetScript("OnUpdate", DragUpdate)
            end)
            row:SetScript("OnDragStop", function()
                list:SetScript("OnUpdate", nil)
                marker:Hide()
                local from, slot = list.dragFrom, SlotAtCursor()
                list.dragFrom = nil
                if not (from and slot) then return end
                local to = slot > from and slot - 1 or slot
                if to ~= from then opts.onReorder(from, to) end
            end)
        end
    end

    -- -------------------------------------------------- data
    function list:Sort()
        local key = self.sortKey
        local col
        for _, c in ipairs(columns) do
            if c.key == key then col = c end
        end
        if not (col and col.sort) then return end
        local desc = self.sortDesc
        local get = col.sort
        table.sort(self.data, function(a, b)
            local va, vb = get(a), get(b)
            if va == vb then return false end
            if va == nil then return false end
            if vb == nil then return true end
            if desc then return va > vb end
            return va < vb
        end)
    end

    function list:SetData(items, keepOffset)
        self.data = items or {}
        self:Sort()
        if not keepOffset then self.offset = 0 end
        self.offset = math.min(self.offset, MaxOffset())
        -- Keep a selection only if the same item is still in the list.
        local found = false
        for _, item in ipairs(self.data) do
            if item == self.selected then found = true break end
        end
        if not found then self.selected = nil end
        self:Refresh()
    end

    function list:GetSelected()
        return self.selected
    end

    function list:SetSelected(item)
        self.selected = item
        self:Refresh()
    end

    function list:SetEmptyText(text)
        self.emptyText = text
        self:Refresh()
    end

    -- Shrinks the list to its rows, between `least` (default 1) and `most`
    -- rows (default and at most what it was made to hold), and returns the
    -- height it took. For a list that should not be mostly empty space.
    function list:FitRows(most, least)
        most = math.min(most or maxRows, maxRows)
        local n = math.max(least or 1, math.min(#self.data, most))
        visible = n
        self:SetHeight(headerH + n * rowH + 2)
        -- Shrunk to a row or two, the "nothing here" text sits in them rather
        -- than below the list, where it ran into whatever came next.
        self.empty:ClearAllPoints()
        self.empty:SetPoint("TOP", self, "TOP", 0, -headerH - (n < 3 and 4 or 30))
        self.offset = math.min(self.offset, MaxOffset())
        self:Refresh()
        return self:GetHeight()
    end

    function list:RowHeight()
        return rowH
    end

    function list:Refresh()
        self:DrawHeaders()
        for i, row in ipairs(self.rows) do
            local index = self.offset + i
            local item = i <= visible and self.data[index] or nil
            row.item = item
            row.index = item and index or nil
            if item then
                for c, col in ipairs(columns) do
                    local cell = row.cells[c]
                    if col.icon then
                        cell:SetTexture(col.icon(item))
                    else
                        cell:SetText(col.text and col.text(item) or "")
                    end
                end
                row.sel:SetShown(item == self.selected)
                if opts.drawRow then opts.drawRow(row, item, self) end
                row:Show()
            else
                row:Hide()
            end
        end
        self.empty:SetText(#self.data == 0 and (self.emptyText or opts.emptyText or "") or "")
        DrawThumb()
    end

    list:Refresh()
    return list
end
