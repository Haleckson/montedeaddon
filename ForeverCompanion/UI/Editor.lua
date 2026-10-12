--[[
  Forever Companion - UI/Editor.lua
  Quick Capture and the discovery editor.

  Opened by /fc add, the journal's "New discovery" button, the target frame
  button, Alt+Right-click on the world map and "Edit". The form arrives
  prefilled (zone, subzone, coordinates, target, suggested type), so a new
  entry takes a type click, an optional note and Enter.
]]

local _, FC = ...

local Editor = FC:NewModule("Editor")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Theme = FC.Theme
local Categories = FC.Categories

local WIDTH, HEIGHT = 552, 712
local EDGE = 22                   -- clear of the painted frame, with a strip of leather
local CONTENT = WIDTH - 2 * EDGE

function Editor:Build()
    if self.frame then return end
    local frame = UI.Panel(UIParent, { name = "ForeverCompanionEditor", strata = "DIALOG", bgAlpha = 0.99, skin = "window", corner = 20 })
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 120, 20)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    tinsert(UISpecialFrames, "ForeverCompanionEditor")
    frame:Hide()

    frame.accent = UI.AccentLine(frame)
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("TOPRIGHT")
    drag:SetHeight(50)
    UI.MakeMovable(frame, drag)

    frame.title = UI.WrappedText(frame, "header", "text")
    frame.title:SetPoint("TOPLEFT", EDGE + 2, -EDGE)
    frame.title:SetWidth(CONTENT - 34)
    -- on the drag strip, not beside it: a sibling of the strip stands at its
    -- level, and the game gave the strip its clicks (the close did nothing)
    frame.close = UI.IconButton(drag, "Interface\\Buttons\\UI-StopButton", 22, nil, function() self:Close() end)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -EDGE, -(EDGE - 2))

    -- context strip
    local context = UI.Panel(frame, { bg = "panelAlt", bgAlpha = 1, border = "border", shade = false, skin = "panel", corner = 10 })
    context:SetPoint("TOPLEFT", EDGE, -(EDGE + 32))
    context:SetPoint("TOPRIGHT", -EDGE, -(EDGE + 32))
    context:SetHeight(52)
    context.location = UI.Text(context, "secondary", "text")
    context.location:SetPoint("TOPLEFT", 12, -10)
    context.location:SetPoint("RIGHT", -110, 0)
    context.target = UI.Text(context, "meta", "muted")
    context.target:SetPoint("BOTTOMLEFT", 12, 10)
    context.target:SetPoint("RIGHT", -110, 0)
    context.update = UI.Button(context, L.EDITOR_UPDATE_LOCATION, { width = 92, height = 22, style = "ghost", onClick = function()
        self:CaptureLocation()
        self:RenderContext()
        self:Layout()
    end })
    context.update:SetPoint("TOPRIGHT", -8, -6)
    context.link = UI.Checkbox(context, L.EDITOR_LINK_TARGET, function() return self.linkTarget end, function(v)
        self.linkTarget = v
    end)
    context.link:SetPoint("BOTTOMRIGHT", -8, 5)
    self.context = context

    -- type picker
    frame.typeHeader = UI.SectionHeader(frame, L.EDITOR_TYPE)
    frame.typeHeader:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -14)
    frame.typeHeader:SetPoint("RIGHT", context, "RIGHT")
    self.typeButtons = {}
    local columns, gap = 3, 6
    local buttonWidth = (CONTENT - gap * (columns - 1)) / columns
    for i, key in ipairs(Categories.QUICK) do
        local def = Categories:Get(key)
        local button = UI.Button(frame, L[def.label], { width = buttonWidth, height = 28, icon = def.icon, onClick = function() self:SetType(key) end })
        local col, row = (i - 1) % columns, math.floor((i - 1) / columns)
        button:SetPoint("TOPLEFT", frame.typeHeader, "BOTTOMLEFT", col * (buttonWidth + gap), -6 - row * 32)
        button.key = key
        self.typeButtons[#self.typeButtons + 1] = button
    end
    frame.more = UI.Dropdown(frame, nil, function()
        local items = {}
        for _, key in ipairs(Categories.order) do
            local def = Categories:Get(key)
            items[#items + 1] = { value = key, text = L[def.label], icon = def.icon }
        end
        return items
    end, function() return self.type end, function(value) self:SetType(value) end, CONTENT)
    frame.more:SetPoint("TOPLEFT", frame.typeHeader, "BOTTOMLEFT", 0, -6 - 3 * 32)

    -- title and description
    frame.titleLabel = UI.Text(frame, "secondary", "muted")
    frame.titleLabel:SetPoint("TOPLEFT", frame.more, "BOTTOMLEFT", 0, -14)
    frame.titleLabel:SetText(L.EDITOR_TITLE_LABEL)
    frame.error = UI.Text(frame, "meta", "danger")
    frame.error:SetPoint("LEFT", frame.titleLabel, "RIGHT", 10, 0)
    frame.titleBox = UI.EditBox(frame, { width = CONTENT, height = 28, maxLetters = C.LIMITS.TITLE, placeholder = L.EDITOR_TITLE_PLACEHOLDER, onEnter = function() self:Save() end })
    frame.titleBox:SetPoint("TOPLEFT", frame.titleLabel, "BOTTOMLEFT", 0, -5)
    frame.descLabel = UI.Text(frame, "secondary", "muted")
    frame.descLabel:SetPoint("TOPLEFT", frame.titleBox, "BOTTOMLEFT", 0, -12)
    frame.descLabel:SetText(L.EDITOR_DESC_LABEL)
    frame.desc = UI.MultiLineEdit(frame, { width = CONTENT, height = 84, maxLetters = C.LIMITS.DESCRIPTION, placeholder = L.EDITOR_DESC_PLACEHOLDER })
    frame.desc:SetPoint("TOPLEFT", frame.descLabel, "BOTTOMLEFT", 0, -5)

    -- tags
    frame.tagsLabel = UI.Text(frame, "secondary", "muted")
    frame.tagsLabel:SetPoint("TOPLEFT", frame.desc, "BOTTOMLEFT", 0, -12)
    frame.tagsLabel:SetText(L.EDITOR_TAGS_LABEL)
    frame.tags = UI.EditBox(frame, { width = CONTENT, height = 26, maxLetters = 200, placeholder = L.EDITOR_TAGS_PLACEHOLDER })
    frame.tags:SetPoint("TOPLEFT", frame.tagsLabel, "BOTTOMLEFT", 0, -5)
    frame.tagSuggestions = CreateFrame("Frame", nil, frame)
    frame.tagSuggestions:SetPoint("TOPLEFT", frame.tags, "BOTTOMLEFT", 0, -5)
    frame.tagSuggestions:SetSize(CONTENT, 20)
    self.tagChips = UI.Pool(function()
        return UI.Chip(frame.tagSuggestions, "", nil, function(value)
            local current = frame.tags:GetText()
            local tag = value:gsub("^#", "")
            for _, existing in ipairs(U.Split(current, ",")) do
                if U.Lower(existing) == tag then return end
            end
            frame.tags:SetText(current ~= "" and (current .. ", " .. tag) or tag)
        end)
    end)

    -- visibility, icon, color
    frame.visLabel = UI.Text(frame, "secondary", "muted")
    frame.visLabel:SetPoint("TOPLEFT", frame.tagSuggestions, "BOTTOMLEFT", 0, -12)
    frame.visLabel:SetText(L.EDITOR_VISIBILITY)
    frame.visibility = UI.Segmented(frame, {
        { value = "p", text = L.VISIBILITY_PRIVATE, icon = UI.STATUS.private.icon },
        { value = "g", text = L.VISIBILITY_GUILD, icon = C.GUILD_ICON },
    }, function() return self.visibility end, function(v)
        self.visibility = v
        self.visibilityTouched = true
    end, 240)
    frame.visibility:SetPoint("TOPLEFT", frame.visLabel, "BOTTOMLEFT", 0, -5)
    frame.color = UI.ColorSwatch(frame, L.EDITOR_COLOR, function() return self.color or Categories:Get(self.type or "note").color end, function(hex)
        self.color = hex
    end, function() self.color = nil end)
    frame.color:SetPoint("LEFT", frame.visibility, "RIGHT", 24, 0)
    frame.color:SetWidth(CONTENT - 264)

    frame.iconLabel = UI.Text(frame, "secondary", "muted")
    frame.iconLabel:SetPoint("TOPLEFT", frame.visibility, "BOTTOMLEFT", 0, -12)
    frame.iconLabel:SetText(L.EDITOR_ICON)
    self.iconButtons = {}
    local iconSize = 24
    local defaultButton = UI.IconButton(frame, "Interface\\Icons\\INV_Misc_QuestionMark", iconSize, L.EDITOR_ICON_DEFAULT, function() self:SetIcon(nil) end)
    defaultButton:SetPoint("TOPLEFT", frame.iconLabel, "BOTTOMLEFT", 0, -5)
    self.defaultIconButton = defaultButton
    for i, icon in ipairs(Categories.NOTE_ICONS) do
        local button = UI.IconButton(frame, icon, iconSize, nil, function() self:SetIcon(icon) end)
        button:SetPoint("LEFT", defaultButton, "RIGHT", 6 + (i - 1) * (iconSize + 1), 0)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.value = icon
        self.iconButtons[#self.iconButtons + 1] = button
    end

    -- footer
    frame.save = UI.Button(frame, L.SAVE, { style = "primary", width = 120, height = 30, onClick = function() self:Save() end })
    frame.save:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    frame.cancel = UI.Button(frame, L.CANCEL, { width = 100, height = 30, onClick = function() self:Close() end })
    frame.cancel:SetPoint("RIGHT", frame.save, "LEFT", -8, 0)
    frame.hint = UI.WrappedText(frame, "meta", "muted")
    frame.hint:SetPoint("BOTTOMLEFT", EDGE + 2, EDGE + 8)
    frame.hint:SetText(L.EDITOR_HINT)
    -- Keep the title/actions fixed while the form can grow with translated
    -- labels and the user's font size. Every field remains reachable.
    frame.area = UI.ScrollArea(frame)
    local body = frame.area.content
    for _, widget in ipairs({ context, frame.typeHeader, frame.more, frame.titleLabel, frame.error,
        frame.titleBox, frame.descLabel, frame.desc, frame.tagsLabel, frame.tags,
        frame.tagSuggestions, frame.visLabel, frame.visibility, frame.color, frame.iconLabel, defaultButton }) do
        widget:SetParent(body)
    end
    for _, button in ipairs(self.typeButtons) do button:SetParent(body) end
    for _, button in ipairs(self.iconButtons) do button:SetParent(body) end
    for _, label in ipairs({ context.location, context.target, context.link.label, frame.error }) do
        label:SetWordWrap(true)
        if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
    end
    FC.Bus:On("FONTS_CHANGED", self, function() if self.frame and self.frame:IsShown() then self:Layout() end end)
end

function Editor:Layout()
    local f = self.frame
    if not f then return end
    f.save:FitLabel(180, 30); f.cancel:FitLabel(160, 30)
    local footer = math.max(f.save:GetHeight(), f.cancel:GetHeight())
    f.hint:ClearAllPoints()
    f.hint:SetWidth(CONTENT)
    f.hint:SetPoint("BOTTOMLEFT", EDGE, EDGE + footer + 8)
    f.area:ClearAllPoints()
    f.area:SetPoint("TOPLEFT", EDGE, -(EDGE + f.title:GetStringHeight() + 12))
    f.area:SetPoint("BOTTOMRIGHT", -EDGE, EDGE + footer + 8 + f.hint:GetStringHeight() + 12)
    local width = CONTENT - 10
    f.area.content:SetWidth(width)
    local context, side = self.context, math.min(176, width * 0.38)
    context:ClearAllPoints(); context:SetPoint("TOPLEFT", f.area.content, "TOPLEFT"); context:SetWidth(width)
    context.update:FitLabel(side, 26)
    context.link:SetWidth(side)
    context.link.label:SetWidth(side - 24)
    context.link:SetHeight(math.max(24, context.link.label:GetStringHeight() + 4))
    context.location:ClearAllPoints(); context.location:SetPoint("TOPLEFT", 12, -10); context.location:SetWidth(width - side - 32)
    context.target:ClearAllPoints(); context.target:SetPoint("TOPLEFT", context.location, "BOTTOMLEFT", 0, -5); context.target:SetWidth(width - side - 32)
    context:SetHeight(math.max(20 + context.location:GetStringHeight() + 5 + context.target:GetStringHeight(), 20 + context.update:GetHeight() + context.link:GetHeight()))
    f.typeHeader:SetWidth(width)
    local columns, gap = FC.P.fonts.size >= 16 and 2 or 3, 6
    local cell, rowHeight = (width - gap * (columns - 1)) / columns, 30
    for _, b in ipairs(self.typeButtons) do
        b.fcAutoWidth = cell
        b:FitLabel(cell, 30)
        rowHeight = math.max(rowHeight, b:GetHeight())
    end
    for i, b in ipairs(self.typeButtons) do
        b:ClearAllPoints(); b:SetHeight(rowHeight)
        b:SetPoint("TOPLEFT", f.typeHeader, "BOTTOMLEFT", ((i - 1) % columns) * (cell + gap), -6 - math.floor((i - 1) / columns) * (rowHeight + gap))
    end
    f.more:ClearAllPoints()
    f.more:SetPoint("TOPLEFT", f.typeHeader, "BOTTOMLEFT", 0, -6 - math.ceil(#self.typeButtons / columns) * (rowHeight + gap))
    f.more:SetWidth(width); f.more:SetHeight(math.max(28, FC.P.fonts.size + 12)); f.more.button:SetHeight(f.more:GetHeight())
    f.error:ClearAllPoints(); f.error:SetPoint("TOPLEFT", f.titleLabel, "BOTTOMLEFT", 0, -4); f.error:SetWidth(width)
    f.error:SetHeight(0)
    f.error:SetHeight(math.max(1, f.error:GetStringHeight()))
    f.titleBox:ClearAllPoints(); f.titleBox:SetPoint("TOPLEFT", f.error, "BOTTOMLEFT", 0, -5)
    for _, edit in ipairs({ f.titleBox, f.tags }) do edit:SetWidth(width); edit:SetHeight(math.max(28, FC.P.fonts.size + 12)) end
    f.desc:SetWidth(width)
    f.tagSuggestions:SetWidth(width)
    f.tagSuggestions:SetHeight(math.max(20, FC.P.fonts.size + 8))
    f.visibility:SetWidth(width)
    local segment, vh = width / 2, 30
    for i, b in ipairs(f.visibility.buttons) do
        b.fcAutoWidth = segment - 2; b:FitLabel(segment - 2, 30)
        b:ClearAllPoints(); b:SetPoint("LEFT", (i - 1) * segment, 0)
        vh = math.max(vh, b:GetHeight())
    end
    f.visibility:SetHeight(vh)
    f.color:ClearAllPoints(); f.color:SetPoint("TOPLEFT", f.visibility, "BOTTOMLEFT", 0, -12); f.color:SetWidth(width)
    f.color:SetHeight(math.max(26, FC.P.fonts.size + 10))
    f.iconLabel:ClearAllPoints(); f.iconLabel:SetPoint("TOPLEFT", f.color, "BOTTOMLEFT", 0, -12)
    local iconColumns, last = math.floor(width / 28), self.defaultIconButton
    for i, b in ipairs(self.iconButtons) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", self.defaultIconButton, "TOPLEFT", (i % iconColumns) * 28, -math.floor(i / iconColumns) * 28)
        last = b
    end
    local top, bottom = f.area.content:GetTop(), last:GetBottom()
    if top and bottom then f.area:SetContentHeight(top - bottom + 12) end
    UI.FitScale(f, FC.P.appearance.scale)
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

function Editor:SetType(key)
    if not Categories:IsValid(key) then key = "note" end
    self.type = key
    for _, button in ipairs(self.typeButtons) do
        button:SetStyle(button.key == key and "primary" or "secondary")
    end
    self.frame.more:Refresh()
    self.defaultIconButton.icon:SetTexture(Categories:Get(key).icon)
    self.frame.color:Refresh()
    if not self.editing and not self.visibilityTouched then
        self.visibility = FC.Store:DefaultVisibility(key)
        self.frame.visibility:Refresh()
    end
end

function Editor:SetIcon(icon)
    self.icon = icon
    self.defaultIconButton:SetActive(icon == nil)
    for _, button in ipairs(self.iconButtons) do
        button:SetActive(button.value == icon)
    end
end

function Editor:CaptureLocation()
    local context = FC.DiscoveryEngine:GetCaptureContext()
    self.loc = context.loc
    self.target = context.target
    return context
end

function Editor:RenderContext()
    local loc = self.loc or {}
    local parts = {}
    if loc.z then parts[#parts + 1] = loc.z end
    if loc.sz and loc.sz ~= loc.z then parts[#parts + 1] = loc.sz end
    local coords = U.FormatCoords(loc.x, loc.y)
    parts[#parts + 1] = coords or L.EDITOR_NO_COORDS
    if loc.instName then parts[#parts + 1] = loc.instName end
    self.context.location:SetText(table.concat(parts, "  \194\183  "))
    local target = self.target
    if target and target.name then
        local text = string.format(L.EDITOR_TARGET, target.name)
        if target.npcID then text = text .. "  (NPC " .. target.npcID .. ")" end
        self.context.target:SetText(text)
        self.context.link:Show()
    else
        self.context.target:SetText(L.EDITOR_NO_TARGET)
        self.context.link:Hide()
    end
    self.context.link:Refresh()
    self.context.update:SetShown(not self.fixedLocation and not self.editing)
end

function Editor:RenderTagSuggestions()
    self.tagChips:ReleaseAll()
    local x = 0
    local usage = FC.Store:TagUsage()
    local defaults = { L.TAG_SUGGEST_IMPORTANT, L.TAG_SUGGEST_RETURN, L.TAG_SUGGEST_RARE, L.TAG_SUGGEST_WEIRD, L.TAG_SUGGEST_TEST, L.TAG_SUGGEST_RAID }
    local list, seen = {}, {}
    for _, entry in ipairs(usage) do
        if #list < 8 then list[#list + 1] = entry.tag seen[entry.tag] = true end
    end
    for _, tag in ipairs(defaults) do
        if #list < 8 and not seen[tag] then list[#list + 1] = tag end
    end
    for _, tag in ipairs(list) do
        local chip = self.tagChips:Acquire()
        chip:SetChip("#" .. tag, FC.db.tagColors[tag])
        if x + chip:GetWidth() > CONTENT then chip:Hide() break end
        chip:SetPoint("LEFT", x, 0)
        x = x + chip:GetWidth() + 6
    end
end

local function resetForm(self)
    local frame = self.frame
    frame.error:SetText("")
    UI.SetBorderColor(frame.titleBox, "border", 1)
    frame.titleBox:SetText("")
    frame.desc:SetText("")
    frame.tags:SetText("")
    self.color = nil
    self.visibilityTouched = false
    self:SetIcon(nil)
end

------------------------------------------------------------------------
-- Opening
------------------------------------------------------------------------

function Editor:Open()
    UI.FitScale(self.frame, FC.P.appearance.scale)
    self:RenderContext()
    self:RenderTagSuggestions()
    self:Layout()
    UI.FadeIn(self.frame, 0.14)
    self.frame.titleBox:SetFocus()
end

--- Quick capture at the player's position. typeKey optional.
function Editor:OpenNew(typeKey)
    self:Build()
    self.editing = nil
    self.fixedLocation = false
    resetForm(self)
    local context = self:CaptureLocation()
    self.linkTarget = context.target and context.target.npcID and true or false
    self.frame.title:SetText(L.EDITOR_NEW_TITLE)
    self:SetType(typeKey or context.suggested)
    if context.target and context.target.name then
        self.frame.titleBox:SetText(context.target.name)
    elseif context.loc.sz then
        self.frame.titleBox:SetText("")
    end
    self:Open()
    self.frame.titleBox:HighlightText()
end

--- Map note at a clicked position (Alt+Right-click on the world map).
function Editor:OpenAt(mapID, x, y)
    self:Build()
    self.editing = nil
    self.fixedLocation = true
    resetForm(self)
    self.target = nil
    self.linkTarget = false
    self.loc = { m = mapID, x = U.Round(x, 4), y = U.Round(y, 4), z = FC.Compat.GetMapName(mapID) }
    self.frame.title:SetText(L.EDITOR_MAP_NOTE_TITLE)
    self:SetType("note")
    self:Open()
end

function Editor:OpenEdit(rec)
    if not FC.Store:IsMine(rec) then return end
    self:Build()
    self.editing = rec.id
    self.fixedLocation = true
    resetForm(self)
    self.target = nil
    self.linkTarget = false
    self.loc = { m = rec.m, x = rec.x, y = rec.y, z = rec.z, sz = rec.sz, inst = rec["in"], instName = rec.inn }
    self.frame.title:SetText(L.EDITOR_EDIT_TITLE)
    self:SetType(rec.t)
    self.visibility = rec.v
    self.frame.visibility:Refresh()
    self.frame.titleBox:SetText(rec.n or "")
    self.frame.desc:SetText(rec.d or "")
    self.frame.tags:SetText(table.concat(rec.tg or {}, ", "))
    self.color = rec.col
    self.frame.color:Refresh()
    local def = Categories:Get(rec.t)
    self:SetIcon(rec.ic ~= def.icon and rec.ic or nil)
    self:Open()
end

function Editor:Close()
    if self.frame then self.frame:Hide() end
end

------------------------------------------------------------------------
-- Saving
------------------------------------------------------------------------

function Editor:Save()
    local frame = self.frame
    local title = U.CleanText(frame.titleBox:GetText(), C.LIMITS.TITLE)
    if not title or title == "" then
        frame.error:SetText(L.EDITOR_TITLE_REQUIRED)
        self:Layout()
        UI.SetBorderColor(frame.titleBox, "danger", 1)
        frame.titleBox:SetFocus()
        return
    end
    local tags = {}
    for _, tag in ipairs(U.Split(frame.tags:GetText(), ",")) do
        tags[#tags + 1] = U.Lower(tag):gsub("^#", "")
    end
    local def = Categories:Get(self.type)
    local loc = self.loc or {}
    local fields = {
        t = self.type,
        n = title,
        d = U.CleanText(frame.desc:GetText(), C.LIMITS.DESCRIPTION),
        tg = #tags > 0 and tags or nil,
        v = self.visibility or "p",
        ic = self.icon or def.icon,
        col = self.color,
        m = loc.m, x = loc.x, y = loc.y, z = loc.z, sz = loc.sz,
    }
    if loc.inst then
        fields["in"] = loc.inst
        fields.inn = loc.instName
        if self.type ~= "dungeon" then fields.pa = "dungeon:" .. loc.inst end
    end

    if self.editing then
        local changes = {}
        for key, value in pairs(fields) do changes[key] = value end
        for _, key in ipairs({ "d", "tg", "col" }) do
            if fields[key] == nil then changes[key] = false end
        end
        if FC.Store:Update(self.editing, changes, "local") then
            self:Close()
            FC.MainWindow:ShowDiscovery(self.editing)
        end
        return
    end

    local target = self.target
    if self.linkTarget and target and target.npcID then
        fields.npc = target.npcID
        fields.lvl = target.level
        fields.cls = target.classification
    end
    local rec, isNew = FC.Store:Create(fields, { source = "local", personal = true })
    if not rec then
        frame.error:SetText(L.EDITOR_SAVE_FAILED)
        self:Layout()
        return
    end
    if not isNew then
        if not FC.Store:IsMine(rec) then
            FC.Store:MarkSeen(rec.id)
            FC.Store:AddVerification(rec.id, FC.Store.me, U.Now(), "local")
        end
        FC:Print(L.MSG_ALREADY_KNOWN, U.Escape(FC.Locale:RecordText(rec, "n") or "?"))
    end
    self:Close()
    if FC.MainWindow:IsShown() then FC.MainWindow:ShowDiscovery(rec.id) end
end

function Editor:OnInitialize()
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if self.frame and (path == "*" or path:find("^appearance%.scale")) then
            UI.FitScale(self.frame, FC.P.appearance.scale)
        end
    end)
end

Theme:OnChange(Editor, function()
    if Editor.frame and Editor.type then Editor:SetType(Editor.type) end
end)
