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

    frame.title = UI.Text(frame, "header", "text")
    frame.title:SetPoint("TOPLEFT", EDGE + 2, -EDGE)
    frame.close = UI.IconButton(frame, "Interface\\Buttons\\UI-StopButton", 22, L.CLOSE, function() self:Close() end)
    frame.close:SetPoint("TOPRIGHT", -EDGE, -(EDGE - 2))

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
                if existing:lower() == tag then return end
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
    frame.hint = UI.Text(frame, "meta", "muted")
    frame.hint:SetPoint("BOTTOMLEFT", EDGE + 2, EDGE + 8)
    frame.hint:SetText(L.EDITOR_HINT)
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
    local defaults = { "important", "come-back-later", "rare-spawn", "weird", "needs-testing", "raid-prep" }
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
        UI.SetBorderColor(frame.titleBox, "danger", 1)
        frame.titleBox:SetFocus()
        return
    end
    local tags = {}
    for _, tag in ipairs(U.Split(frame.tags:GetText(), ",")) do
        tags[#tags + 1] = tag:lower():gsub("^#", "")
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
        return
    end
    if not isNew then
        if not FC.Store:IsMine(rec) then
            FC.Store:MarkSeen(rec.id)
            FC.Store:AddVerification(rec.id, FC.Store.me, U.Now(), "local")
        end
        FC:Print(L.MSG_ALREADY_KNOWN, U.Escape(rec.n or "?"))
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
