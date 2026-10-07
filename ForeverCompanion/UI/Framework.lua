--[[
  Forever Companion - UI/Framework.lua
  Reusable, themed building blocks. Nothing in the addon styles a frame by
  hand: everything is built from these components, which paint themselves
  through Theme (colors) and Fonts (typography).

  Components: Panel (FCFrame/FCPanel), Text, Button, IconButton, NavItem (FCTab),
  SearchBox, EditBox, MultiLineEdit, ScrollArea (FCScrollFrame), Tooltip,
  StatusBadge, SectionHeader, Divider, Chip, Pool, plus fade animations.
  Dropdown, Slider, Checkbox, ColorSwatch and menus live in Controls.lua.
]]

local _, FC = ...

local UI = {}
FC.UI = UI

local C = FC.C
local L = FC.L
local U = FC.Utils
local Theme = FC.Theme
local Fonts = FC.Fonts

local WHITE = C.WHITE

------------------------------------------------------------------------
-- Status presentation (icon + text + color; never color alone)
------------------------------------------------------------------------

UI.STATUS = {
    personal = { icon = "Interface\\Icons\\INV_Misc_Spyglass_03", color = "56b4e9", label = "STATUS_PERSONAL" },
    alt = { icon = "Interface\\Icons\\INV_Misc_Head_Human_02", color = "a3b8ef", label = "STATUS_ALT" },
    guild = { icon = C.GUILD_ICON, color = "e69f00", label = "STATUS_GUILD" },
    verified = { icon = C.VERIFIED_ICON, color = "3fbf8f", label = "STATUS_VERIFIED" },
    rumored = { icon = "Interface\\Icons\\INV_Misc_QuestionMark", color = "cc79a7", label = "STATUS_RUMORED" },
    favorite = { icon = C.FAVORITE_ICON, color = "e8c35a", label = "STATUS_FAVORITE" },
    archived = { icon = "Interface\\Icons\\INV_Crate_01", color = "9a9a9a", label = "STATUS_ARCHIVED" },
    private = { icon = "Interface\\Icons\\INV_Misc_Key_14", color = "d9c86a", label = "STATUS_PRIVATE" },
}

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

function UI.AnimationsEnabled()
    return FC.P and FC.P.appearance.animations
end

function UI.Texture(parent, layer, role, alpha, sublevel)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
    tex:SetTexture(WHITE)
    if role then Theme:Paint(tex, role, alpha) end
    return tex
end

function UI.Icon(parent, size, layer)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    tex:SetSize(size, size)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return tex
end

function UI.RoundIcon(parent, size, layer)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    tex:SetSize(size, size)
    if tex.SetMask then
        pcall(tex.SetMask, tex, C.CIRCLE_MASK)
    end
    return tex
end

--- Sets an icon texture; numbers are fileIDs, strings are paths.
function UI.SetIcon(tex, icon, fallback)
    tex:SetTexture(icon or fallback or "Interface\\Icons\\INV_Misc_QuestionMark")
end

------------------------------------------------------------------------
-- Borders (pixel-exact, themed, resized with the border size setting)
------------------------------------------------------------------------

local bordered = setmetatable({}, { __mode = "k" })

function UI.LayoutBorder(frame)
    local border = frame.fcBorder
    if not border then return end
    local size = frame.fcBorderSize or (FC.P and FC.P.appearance.borderSize) or 1
    local px = Theme:Pixel(frame) * size
    -- painted frames and panels (journal style) bring their own edge
    local visible = size > 0 and not frame.fcBorderHidden
    for _, tex in pairs(border) do tex:SetShown(visible) end
    if not visible then return end
    border.top:SetPoint("TOPLEFT")
    border.top:SetPoint("TOPRIGHT")
    border.top:SetHeight(px)
    border.bottom:SetPoint("BOTTOMLEFT")
    border.bottom:SetPoint("BOTTOMRIGHT")
    border.bottom:SetHeight(px)
    border.left:SetPoint("TOPLEFT")
    border.left:SetPoint("BOTTOMLEFT")
    border.left:SetWidth(px)
    border.right:SetPoint("TOPRIGHT")
    border.right:SetPoint("BOTTOMRIGHT")
    border.right:SetWidth(px)
end

function UI.AddBorder(frame, role, alpha, fixedSize)
    local border = frame.fcBorder
    if not border then
        border = {}
        for _, side in ipairs({ "top", "bottom", "left", "right" }) do
            border[side] = frame:CreateTexture(nil, "BORDER", nil, 7)
            border[side]:SetTexture(WHITE)
        end
        frame.fcBorder = border
    end
    frame.fcBorderSize = fixedSize
    for _, tex in pairs(border) do Theme:Paint(tex, role or "border", alpha) end
    UI.LayoutBorder(frame)
    bordered[frame] = true
    return border
end

function UI.SetBorderColor(frame, role, alpha)
    if not frame.fcBorder then return end
    for _, tex in pairs(frame.fcBorder) do Theme:Paint(tex, role, alpha) end
end

function UI.RefreshBorders()
    for frame in pairs(bordered) do UI.LayoutBorder(frame) end
end

------------------------------------------------------------------------
-- Panels
------------------------------------------------------------------------

local panels = setmetatable({}, { __mode = "k" })
local skinnedPanels = setmetatable({}, { __mode = "k" })
local accentLines = setmetatable({}, { __mode = "k" })

-- Painted surfaces of a panel in the journal style: "window" is leather
-- inside a stitched frame with brass corners, "panel" a sheet of parchment.
-- The flat background and border stay for the flat style (and as the
-- fallback when a texture cannot be loaded).
function UI.ApplyPanelSkin(frame)
    local kind = frame.fcSkin
    if not kind then return end
    local Skin = FC.Skin
    local painted = false
    if kind == "window" and Skin:Has("frame") then
        if not frame.fcFrameArt then
            local corner = frame.fcCorner or 26
            frame.fcLeather = Skin:Tiled(frame, "background", { layer = "BACKGROUND", sublevel = -7, tile = 320, inset = math.floor(corner * Skin.ASSETS.frame.bandOuter + 0.5) })
            frame.fcFrameArt = Skin:NineSlice(frame, "frame", { layer = "BORDER", sublevel = 6, corner = corner, center = false })
        end
        painted = true
    elseif kind == "panel" and Skin:Has("panel") then
        if not frame.fcPanelArt then
            frame.fcPanelArt = Skin:NineSlice(frame, "panel", { layer = "BACKGROUND", sublevel = -7, corner = frame.fcCorner or 12 })
        end
        local tint = frame.fcTint or 1
        frame.fcPanelArt:SetVertexColor(tint, tint, tint, frame.fcPanelAlpha or 1)
        painted = true
    end
    for _, art in ipairs({ frame.fcLeather or false, frame.fcFrameArt or false, frame.fcPanelArt or false }) do
        if art then art:SetShown(painted) end
    end
    frame.fcPainted = painted
    frame.bg:SetShown(not painted)
    frame.fcBorderHidden = painted
    UI.LayoutBorder(frame)
    if frame.shade then frame.shade:SetShown(not painted and FC.P and FC.P.appearance.corners == "soft") end
end

--- How far content must keep from the edge of a panel (painted frames are wider).
function UI.PanelInset(frame, flat)
    if frame.fcPainted and frame.fcSkin == "window" then
        return FC.Skin:FrameInset(frame.fcCorner or 26)
    end
    return flat or 1
end

--- The thin accent line on top of windows: only the flat style draws it.
function UI.AccentLine(frame, inset)
    inset = inset or 1
    local line = UI.Texture(frame, "ARTWORK", "accent", 1)
    line:SetPoint("TOPLEFT", inset, -inset)
    line:SetPoint("TOPRIGHT", -inset, -inset)
    line:SetHeight(2)
    accentLines[line] = true
    line:SetShown(not FC.Skin:Enabled())
    return line
end

--- Gives a frame that already has bg (and a border) a painted surface:
--- kind "window" or "panel"; opts.corner, opts.tint, opts.alpha.
function UI.SkinFrame(frame, kind, opts)
    opts = opts or {}
    frame.fcSkin, frame.fcCorner, frame.fcTint, frame.fcPanelAlpha = kind, opts.corner, opts.tint, opts.alpha
    skinnedPanels[frame] = true
    UI.ApplyPanelSkin(frame)
end

--- FCPanel / FCFrame. opts: bg (role), bgAlpha, border (role or false), name, strata,
--- skin ("window" | "panel"), corner (UI size of painted corners), tint (panel brightness)
function UI.Panel(parent, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", opts.name, parent)
    frame.bg = UI.Texture(frame, "BACKGROUND", opts.bg or "panel", opts.bgAlpha or "bg", -8)
    frame.bg:SetAllPoints()
    if opts.border ~= false then
        UI.AddBorder(frame, opts.border or "border")
    end
    if opts.strata then frame:SetFrameStrata(opts.strata) end
    if opts.shade ~= false then
        -- a faint top highlight gives panels depth ("soft" corner style makes it stronger)
        frame.shade = UI.Texture(frame, "BACKGROUND", "text", 0.025, -7)
        frame.shade:SetPoint("TOPLEFT", 1, -1)
        frame.shade:SetPoint("TOPRIGHT", -1, -1)
        frame.shade:SetHeight(24)
        if frame.shade.SetGradient and CreateColor then
            frame.shade:SetTexture(WHITE)
            local ok = pcall(frame.shade.SetGradient, frame.shade, "VERTICAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.035))
            if ok then Theme:Forget(frame.shade) end
        end
        frame.shade:SetShown(FC.P and FC.P.appearance.corners == "soft")
        panels[frame] = true
    end
    if opts.skin then UI.SkinFrame(frame, opts.skin, opts) end
    return frame
end

function UI.Divider(parent, role, alpha)
    local tex = UI.Texture(parent, "ARTWORK", role or "border", alpha or 1)
    tex:SetHeight(1)
    return tex
end

------------------------------------------------------------------------
-- Text
------------------------------------------------------------------------

--- Font string with a typography role and a color role.
function UI.Text(parent, fontRole, colorRole, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFontObject(Fonts:Get(fontRole or "body"))
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    Theme:Paint(fs, colorRole or "text")
    return fs
end

function UI.WrappedText(parent, fontRole, colorRole)
    local fs = UI.Text(parent, fontRole, colorRole)
    fs:SetWordWrap(true)
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
    fs:SetJustifyV("TOP")
    return fs
end

function UI.SectionHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(22)
    frame.label = UI.Text(frame, "meta", "accent")
    frame.label:SetPoint("LEFT")
    frame.label:SetText(text and text:upper() or "")
    frame.line = UI.Divider(frame, "border")
    frame.line:SetPoint("LEFT", frame.label, "RIGHT", 8, 0)
    frame.line:SetPoint("RIGHT")
    function frame:SetText(value) self.label:SetText(value and value:upper() or "") end
    return frame
end

------------------------------------------------------------------------
-- Tooltip (FCTooltip)
------------------------------------------------------------------------

local tooltip

local function ensureTooltip()
    if tooltip then return tooltip end
    tooltip = UI.Panel(UIParent, { name = "ForeverCompanionTooltip", strata = "TOOLTIP", bgAlpha = 0.97, skin = "panel", corner = 10 })
    tooltip:SetClampedToScreen(true)
    tooltip:EnableMouse(false)
    tooltip.accent = UI.AccentLine(tooltip)
    tooltip.icon = UI.Icon(tooltip, 28)
    tooltip.icon:SetPoint("TOPLEFT", 10, -10)
    tooltip.title = UI.Text(tooltip, "cardTitle", "text")
    tooltip.lines = {}
    tooltip:Hide()
    return tooltip
end

--- Shows the addon tooltip. lines: array of { text, colorRole | hex, rightText }
function UI.ShowTooltip(owner, title, lines, icon, anchor)
    if FC.P and FC.P.appearance.tooltipStyle == "blizzard" then
        GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
        GameTooltip:AddLine(title or "", 1, 0.82, 0)
        for _, line in ipairs(lines or {}) do
            local r, g, b = 0.9, 0.9, 0.9
            if line[2] and U.IsValidHex(line[2]) then r, g, b = U.HexToRGB(line[2]) elseif line[2] then r, g, b = Theme:Color(line[2]) end
            if line[3] then
                GameTooltip:AddDoubleLine(line[1], line[3], r, g, b, 1, 1, 1)
            else
                GameTooltip:AddLine(line[1], r, g, b, true)
            end
        end
        GameTooltip:Show()
        return
    end
    local tip = ensureTooltip()
    local width = 220
    local left = 10
    if icon then
        tip.icon:Show()
        UI.SetIcon(tip.icon, icon)
        left = 46
    else
        tip.icon:Hide()
    end
    tip.title:ClearAllPoints()
    tip.title:SetPoint("TOPLEFT", left, -12)
    tip.title:SetText(title or "")
    width = math.max(width, tip.title:GetStringWidth() + left + 16)
    local y = -12 - tip.title:GetStringHeight() - 6
    if icon then y = math.min(y, -44) end
    for i, line in ipairs(lines or {}) do
        local row = tip.lines[i]
        if not row then
            row = { left = UI.WrappedText(tip, "secondary", "muted"), right = UI.Text(tip, "secondary", "text") }
            tip.lines[i] = row
        end
        row.left:ClearAllPoints()
        row.left:SetPoint("TOPLEFT", 10, y)
        row.left:SetWidth(line[3] and 150 or 280)
        row.left:SetText(line[1] or "")
        if line[2] and U.IsValidHex(line[2]) then
            Theme:Forget(row.left)
            row.left:SetTextColor(U.HexToRGB(line[2]))
        else
            Theme:Paint(row.left, line[2] or "muted")
        end
        row.right:ClearAllPoints()
        row.right:SetPoint("TOPRIGHT", -10, y)
        row.right:SetText(line[3] or "")
        row.left:Show()
        row.right:Show()
        local h = math.max(row.left:GetStringHeight(), 12)
        width = math.max(width, math.min(300, row.left:GetStringWidth() + (line[3] and row.right:GetStringWidth() + 30 or 0) + 20))
        y = y - h - 4
    end
    for i = #(lines or {}) + 1, #tip.lines do
        tip.lines[i].left:Hide()
        tip.lines[i].right:Hide()
    end
    tip:SetSize(width, -y + 8)
    tip:ClearAllPoints()
    if anchor == "cursor" then
        local x, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        tip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 16, cy / scale + 8)
    else
        tip:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 0)
    end
    tip:SetScale(FC.P and FC.P.appearance.scale or 1)
    tip:Show()
end

function UI.HideTooltip()
    if tooltip then tooltip:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

--- Attaches a simple title/text tooltip to any frame.
function UI.AttachTooltip(frame, title, text)
    frame:HookScript("OnEnter", function(self)
        local t = type(title) == "function" and title(self) or title
        local body = type(text) == "function" and text(self) or text
        if t then UI.ShowTooltip(self, t, body and { { body } } or nil) end
    end)
    frame:HookScript("OnLeave", UI.HideTooltip)
end

------------------------------------------------------------------------
-- Buttons
------------------------------------------------------------------------

local BUTTON_STYLES = {
    primary = { bg = "accent", bgAlpha = 0.92, border = "accent", text = "bg", outlinedBg = 0.14, outlinedText = "accent" },
    secondary = { bg = "panelAlt", bgAlpha = 1, border = "border", text = "text" },
    ghost = { bg = "panelAlt", bgAlpha = 0, border = false, text = "muted" },
    danger = { bg = "danger", bgAlpha = 0.16, border = "danger", text = "danger" },
}

-- Journal style: every button is the same brass-rimmed leather plate,
-- tinted per style; hover, pressed and disabled come from that texture.
local PLATE_TINT = {
    primary = { 1, 0.96, 0.86 },
    secondary = { 0.78, 0.74, 0.70 },
    danger = { 1, 0.58, 0.50 },
}

local function painted(button)
    return button.fcStyle ~= "ghost" and FC.Skin:Has("button")
end

--- Room the label needs besides its text: the plate's rounded ends and rivets.
local function buttonPadding(button)
    local pad = button.icon and 44 or 28
    if painted(button) then
        local a = FC.Skin.ASSETS.button
        pad = math.ceil(2 * a.left * (button:GetHeight() or 26) / (a.y1 - a.y0)) + 10 + (button.icon and 18 or 0)
    end
    return pad
end

local function fitWidth(button)
    if button.fcAutoWidth then
        button:SetWidth(math.max(button.fcAutoWidth, button.label:GetStringWidth() + buttonPadding(button)))
    end
end

function UI.StyleButton(button)
    local style = BUTTON_STYLES[button.fcStyle] or BUTTON_STYLES.secondary
    if painted(button) then
        if not button.fcPlate then
            button.fcPlate = FC.Skin:Plate(button, "button", { layer = "BACKGROUND", sublevel = 1 })
            button.fcPlateHover = FC.Skin:Plate(button, "button", { layer = "HIGHLIGHT", sublevel = 1 })
            button.fcPlateHover:SetBlendMode("ADD")
            button.fcPlateHover:SetVertexColor(1, 0.86, 0.6, 0.2)
        end
        button.fcPlate:Show()
        button.fcPlateHover:Show()
        local tint = PLATE_TINT[button.fcStyle] or PLATE_TINT.secondary
        local k = button.fcPressed and 0.7 or 1
        button.fcPlate:SetVertexColor(tint[1] * k, tint[2] * k, tint[3] * k, 1)
        button.fcPlate:SetDesaturated(button.fcDisabled)
        button.bg:Hide()
        button.hover:Hide()
        button.fcBorderHidden = true
        if button.fcBorder then UI.LayoutBorder(button) end
        if button.label then Theme:Paint(button.label, button.fcDisabled and "muted" or "text") end
        if button.icon and button.fcTintIcon then Theme:Tint(button.icon, "text") end
    else
        if button.fcPlate then
            button.fcPlate:Hide()
            button.fcPlateHover:Hide()
        end
        button.bg:Show()
        button.hover:Show()
        button.fcBorderHidden = nil
        local outlined = FC.P and FC.P.appearance.buttonStyle == "outlined"
        local bgAlpha, textRole = style.bgAlpha, style.text
        if outlined and style.outlinedBg then
            bgAlpha, textRole = style.outlinedBg, style.outlinedText
        end
        Theme:Paint(button.bg, style.bg, bgAlpha)
        if style.border then
            UI.AddBorder(button, style.border, 1)
        elseif button.fcBorder then
            UI.LayoutBorder(button)
            UI.SetBorderColor(button, "border", 0)
        end
        if button.label then Theme:Paint(button.label, textRole) end
        if button.icon and button.fcTintIcon then Theme:Tint(button.icon, textRole) end
    end
    fitWidth(button)
    button:SetAlpha(button.fcDisabled and 0.45 or 1)
end

--- FCButton. opts: style, width, height, icon, onClick(button, mouseButton), tooltip
function UI.Button(parent, text, opts)
    opts = opts or {}
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(opts.width or 110, opts.height or 26)
    button.fcStyle = opts.style or "secondary"
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetTexture(WHITE)
    button.bg:SetAllPoints()
    button.hover = UI.Texture(button, "HIGHLIGHT", "text", 0.07)
    button.hover:SetAllPoints()
    button.label = UI.Text(button, "button", "text")
    button.label:SetPoint("CENTER")
    button.label:SetText(text or "")
    if opts.icon then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(14, 14)
        button.icon:SetTexture(opts.icon)
        button.fcTintIcon = opts.tintIcon
        if text and text ~= "" then
            button.label:ClearAllPoints()
            button.label:SetPoint("CENTER", 9, 0)
            button.icon:SetPoint("RIGHT", button.label, "LEFT", -6, 0)
        else
            button.icon:SetPoint("CENTER")
        end
    end
    if opts.autoWidth then button.fcAutoWidth = opts.width or 60 end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnMouseDown", function(self)
        if self.fcDisabled then return end
        self.label:SetPoint("CENTER", (self.icon and self.label:GetText() ~= "" and 9 or 0) + 1, -1)
        self.fcPressed = true
        if self.fcPlate then UI.StyleButton(self) end
    end)
    button:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", self.icon and self.label:GetText() ~= "" and 9 or 0, 0)
        self.fcPressed = nil
        if self.fcPlate then UI.StyleButton(self) end
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.fcDisabled then return end
        if opts.onClick then FC:SafeCall("button", opts.onClick, self, mouseButton) end
    end)
    if opts.tooltip then
        UI.AttachTooltip(button, text ~= "" and text or opts.tooltip, text ~= "" and opts.tooltip or nil)
    end
    function button:SetLabel(value)
        self.label:SetText(value or "")
        fitWidth(self)
    end
    function button:SetStyle(style)
        self.fcStyle = style
        UI.StyleButton(self)
    end
    function button:SetDisabled(disabled)
        self.fcDisabled = disabled and true or false
        UI.StyleButton(self)
    end
    UI.StyleButton(button)
    Theme:OnChange(button, UI.StyleButton)
    return button
end

--- FCIconButton: square icon button with hover and an optional active state.
function UI.IconButton(parent, icon, size, tooltipText, onClick)
    local button = CreateFrame("Button", nil, parent)
    size = size or 24
    button:SetSize(size, size)
    button.bg = UI.Texture(button, "BACKGROUND", "panelAlt", 0)
    button.bg:SetAllPoints()
    button.hover = UI.Texture(button, "HIGHLIGHT", "text", 0.09)
    button.hover:SetAllPoints()
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER")
    button.icon:SetSize(size - 8, size - 8)
    button.icon:SetTexture(icon)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
        if self.fcDisabled then return end
        if onClick then FC:SafeCall("iconbutton", onClick, self, mouseButton) end
    end)
    if tooltipText then UI.AttachTooltip(button, tooltipText) end
    function button:SetActive(active)
        self.fcActive = active
        Theme:Paint(self.bg, active and "accent" or "panelAlt", active and 0.22 or 0)
    end
    function button:SetDisabled(disabled)
        self.fcDisabled = disabled
        self:SetAlpha(disabled and 0.35 or 1)
    end
    return button
end

--- Sidebar navigation entry (FCTab): icon, label, count, selected state.
function UI.NavItem(parent, icon, label, onClick)
    local item = CreateFrame("Button", nil, parent)
    item:SetHeight(28)
    item.bg = UI.Texture(item, "BACKGROUND", "panelAlt", 0)
    item.bg:SetAllPoints()
    item.hover = UI.Texture(item, "HIGHLIGHT", "text", 0.05)
    item.hover:SetAllPoints()
    item.bar = UI.Texture(item, "ARTWORK", "accent", 1)
    item.bar:SetPoint("TOPLEFT")
    item.bar:SetPoint("BOTTOMLEFT")
    item.bar:SetWidth(3)
    item.bar:Hide()
    item.icon = UI.Icon(item, 16)
    UI.SetIcon(item.icon, icon)
    item.label = UI.Text(item, "body", "muted")
    item.label:SetPoint("LEFT", item.icon, "RIGHT", 9, 0)
    item.label:SetText(label)
    item.count = UI.Text(item, "meta", "muted")
    item:SetScript("OnClick", function(self)
        if onClick then FC:SafeCall("nav", onClick, self) end
    end)
    function item:SetSelected(selected)
        self.selected = selected
        -- journal style: the selected entry is a parchment bookmark with
        -- inked text, hovering shows a faint one; flat style: a bar and a tint
        local ribbon = FC.Skin:Has("tab")
        if ribbon and not self.ribbon then
            self.ribbon = FC.Skin:Plate(self, "tab", { layer = "BACKGROUND", sublevel = 2 })
            self.ribbonHover = FC.Skin:Plate(self, "tab", { layer = "HIGHLIGHT", sublevel = 2 })
            self.ribbonHover:SetVertexColor(1, 1, 1, 0.22)
        end
        if self.ribbon then
            self.ribbon:SetShown(ribbon and selected)
            self.ribbonHover:SetShown(ribbon and not selected)
        end
        self.hover:SetShown(not ribbon)
        self.bar:SetShown(selected and not ribbon)
        Theme:Paint(self.bg, "panelAlt", (selected and not ribbon) and 1 or 0)
        local inset = ribbon and 20 or 12
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", inset, 0)
        self.label:SetPoint("RIGHT", ribbon and -40 or -34, 0)
        self.count:ClearAllPoints()
        self.count:SetPoint("RIGHT", ribbon and -18 or -10, 0)
        if ribbon and selected then
            local ink = FC.Skin.INK
            Theme:Forget(self.label)
            Theme:Forget(self.count)
            self.label:SetTextColor(ink[1], ink[2], ink[3], 1)
            self.count:SetTextColor(ink[1], ink[2], ink[3], 0.85)
        else
            Theme:Paint(self.label, selected and "text" or "muted")
            Theme:Paint(self.count, "muted")
        end
    end
    Theme:OnChange(item, function(self) self:SetSelected(self.selected) end)
    item:SetSelected(false)
    function item:SetCount(n)
        self.count:SetText(n and n > 0 and U.FormatNumber(n) or "")
    end
    return item
end

--- Small tag chip. Clicking calls onClick(tag); onRemove shows an x.
function UI.Chip(parent, text, colorHex, onClick)
    local chip = CreateFrame("Button", nil, parent)
    chip:SetHeight(18)
    chip.bg = chip:CreateTexture(nil, "BACKGROUND")
    chip.bg:SetTexture(WHITE)
    chip.bg:SetAllPoints()
    chip.label = UI.Text(chip, "meta", "text")
    chip.label:SetPoint("CENTER")
    function chip:SetChip(value, hex)
        self.value = value
        self.label:SetText(value)
        self:SetWidth(self.label:GetStringWidth() + 14)
        if hex and U.IsValidHex(hex) then
            Theme:Forget(self.bg)
            local r, g, b = U.HexToRGB(hex)
            self.bg:SetColorTexture(r, g, b, 0.22)
        else
            Theme:Paint(self.bg, "highlight", 1)
        end
    end
    chip:SetScript("OnClick", function(self, mouseButton)
        if onClick then FC:SafeCall("chip", onClick, self.value, mouseButton, self) end
    end)
    chip:SetChip(text or "", colorHex)
    return chip
end

------------------------------------------------------------------------
-- Status badge (FCStatusBadge)
------------------------------------------------------------------------

function UI.StatusBadge(parent, compact)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetHeight(18)
    badge.bg = badge:CreateTexture(nil, "BACKGROUND")
    badge.bg:SetTexture(WHITE)
    badge.bg:SetAllPoints()
    badge.icon = badge:CreateTexture(nil, "ARTWORK")
    badge.icon:SetSize(12, 12)
    badge.icon:SetPoint("LEFT", 4, 0)
    badge.label = UI.Text(badge, "meta", "text")
    badge.label:SetPoint("LEFT", badge.icon, "RIGHT", 4, 0)
    badge.compact = compact
    function badge:SetStatus(key)
        local style = UI.STATUS[key]
        if not style then
            self:Hide()
            return
        end
        self:Show()
        local r, g, b = U.HexToRGB(style.color)
        self.bg:SetColorTexture(r, g, b, 0.16)
        self.icon:SetTexture(style.icon)
        Theme:Forget(self.label)
        self.label:SetTextColor(r, g, b)
        self.label:SetText(L[style.label])
        if self.compact then
            self.label:Hide()
            self:SetWidth(20)
        else
            self.label:Show()
            self:SetWidth(self.label:GetStringWidth() + 26)
        end
    end
    return badge
end

------------------------------------------------------------------------
-- Edit boxes
------------------------------------------------------------------------

local inputs = setmetatable({}, { __mode = "k" })

--- Journal style: typed text and dropdown values sit in a brass-rimmed well
--- (brighter while typing); flat style: a box with a border. Text keeps
--- clear of the rim through the insets (and box.fcOnSkin(box, rim) for
--- widgets that place their own text).
function UI.ApplyInputSkin(box)
    local on = FC.Skin:Has("input")
    if on and not box.fcWell then
        box.fcWell = FC.Skin:Plate(box, "input", { layer = "BACKGROUND", sublevel = -6 })
    end
    if box.fcWell then
        box.fcWell:SetShown(on)
        local k = box.fcFocused and 1 or 0.86
        box.fcWell:SetVertexColor(k, k, k, 1)
    end
    box.bg:SetShown(not on)
    box.fcBorderHidden = on or nil
    UI.LayoutBorder(box)
    local rim = on and math.ceil(box.fcWell:CapWidth()) + 4 or 0
    if box.SetTextInsets and box.fcInsets then
        box:SetTextInsets(math.max(box.fcInsets[1], rim), math.max(box.fcInsets[2], rim), 0, 0)
    end
    if box.fcOnSkin then box.fcOnSkin(box, rim) end
end

--- Registers a widget with bg + border for the input skin.
function UI.SkinInput(box)
    inputs[box] = true
    UI.ApplyInputSkin(box)
end

local function styleEditBox(box)
    box:SetFontObject(Fonts:Get("body"))
    Theme:Paint(box, "text")
    box:SetAutoFocus(false)
    box.fcInsets = { 8, 8 }
    box:SetTextInsets(8, 8, 0, 0)
    box.bg = UI.Texture(box, "BACKGROUND", "bg", 0.85, -8)
    box.bg:SetAllPoints()
    UI.AddBorder(box, "border")
    box:HookScript("OnEditFocusGained", function(self)
        self.fcFocused = true
        UI.SetBorderColor(self, "accent", 0.8)
        UI.ApplyInputSkin(self)
    end)
    box:HookScript("OnEditFocusLost", function(self)
        self.fcFocused = nil
        UI.SetBorderColor(self, "border", 1)
        UI.ApplyInputSkin(self)
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:HookScript("OnSizeChanged", function(self) UI.ApplyInputSkin(self) end)
    UI.SkinInput(box)
end

function UI.AddPlaceholder(box, text)
    box.placeholder = UI.Text(box, "body", "muted", "ARTWORK")
    box.placeholder:SetPoint("LEFT", 8, 0)
    box.placeholder:SetPoint("RIGHT", -8, 0)
    box.placeholder:SetText(text or "")
    local function update(self)
        self.placeholder:SetShown(self:GetText() == "" and not self:HasFocus())
    end
    box:HookScript("OnTextChanged", update)
    box:HookScript("OnEditFocusGained", update)
    box:HookScript("OnEditFocusLost", update)
    update(box)
end

--- Single-line edit box. opts: width, height, placeholder, maxLetters, onEnter(text), onChange(text, userInput)
function UI.EditBox(parent, opts)
    opts = opts or {}
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(opts.width or 200, opts.height or 26)
    styleEditBox(box)
    if opts.maxLetters then box:SetMaxLetters(opts.maxLetters) end
    if opts.placeholder then UI.AddPlaceholder(box, opts.placeholder) end
    box:SetScript("OnEnterPressed", function(self)
        if opts.onEnter then FC:SafeCall("edit:enter", opts.onEnter, self:GetText(), self) else self:ClearFocus() end
    end)
    if opts.onChange then
        box:HookScript("OnTextChanged", function(self, userInput)
            FC:SafeCall("edit:change", opts.onChange, self:GetText(), userInput)
        end)
    end
    return box
end

--- FCSearchBox: search icon, placeholder, clear button, debounced callback.
function UI.SearchBox(parent, placeholder, onSearch)
    local box = UI.EditBox(parent, { height = 28, placeholder = placeholder, maxLetters = 120 })
    box.icon = box:CreateTexture(nil, "OVERLAY")
    box.icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    box.icon:SetSize(14, 14)
    Theme:Tint(box.icon, "muted")
    box.clear = UI.IconButton(box, "Interface\\Buttons\\UI-StopButton", 18, nil, function()
        box:SetText("")
        box:ClearFocus()
    end)
    box.clear:Hide()
    -- icon, placeholder and clear button move inside the well's rim
    box.fcOnSkin = function(self, rim)
        local left = math.max(9, rim)
        self:SetTextInsets(left + 19, math.max(26, rim + 20), 0, 0)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", left, -1)
        self.placeholder:ClearAllPoints()
        self.placeholder:SetPoint("LEFT", left + 19, 0)
        self.placeholder:SetPoint("RIGHT", -(rim + 8), 0)
        self.clear:ClearAllPoints()
        self.clear:SetPoint("RIGHT", -math.max(4, rim - 2), 0)
    end
    UI.ApplyInputSkin(box)
    local token = 0
    box:HookScript("OnTextChanged", function(self)
        self.clear:SetShown(self:GetText() ~= "")
        token = token + 1
        local mine = token
        C_Timer.After(0.15, function()
            if mine == token and onSearch then FC:SafeCall("search", onSearch, self:GetText()) end
        end)
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

--- Multi-line edit box inside a scroll area. Returns container; container.edit is the EditBox.
function UI.MultiLineEdit(parent, opts)
    opts = opts or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(opts.width or 300, opts.height or 90)
    container.bg = UI.Texture(container, "BACKGROUND", "bg", 0.85)
    container.bg:SetAllPoints()
    UI.AddBorder(container, "border")
    UI.SkinFrame(container, "panel", { corner = 10, tint = 0.62 })
    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT", 8, -6)
    scroll:SetPoint("BOTTOMRIGHT", -8, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(Fonts:Get("body"))
    Theme:Paint(edit, "text")
    edit:SetWidth(scroll:GetWidth() > 0 and scroll:GetWidth() or (opts.width or 300) - 16)
    if opts.maxLetters then edit:SetMaxLetters(opts.maxLetters) end
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnCursorChanged", function(self, _, y, _, height)
        local offset = scroll:GetVerticalScroll()
        local visible = scroll:GetHeight()
        y = -y
        if y < offset then
            scroll:SetVerticalScroll(y)
        elseif y + height > offset + visible then
            scroll:SetVerticalScroll(math.max(0, y + height - visible))
        end
    end)
    edit:HookScript("OnEditFocusGained", function() UI.SetBorderColor(container, "accent", 0.8) end)
    edit:HookScript("OnEditFocusLost", function() UI.SetBorderColor(container, "border", 1) end)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnSizeChanged", function(self, width) edit:SetWidth(width) end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange()
        self:SetVerticalScroll(U.Clamp(self:GetVerticalScroll() - delta * 20, 0, range))
    end)
    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function() edit:SetFocus() end)
    container.edit = edit
    container.scroll = scroll
    if opts.placeholder then
        edit.placeholder = UI.Text(container, "body", "muted", "ARTWORK")
        edit.placeholder:SetPoint("TOPLEFT", 8, -8)
        edit.placeholder:SetText(opts.placeholder)
        local function update(self) self.placeholder:SetShown(self:GetText() == "" and not self:HasFocus()) end
        edit:HookScript("OnTextChanged", update)
        edit:HookScript("OnEditFocusGained", update)
        edit:HookScript("OnEditFocusLost", update)
    end
    function container:SetText(text) edit:SetText(text or "") end
    function container:GetText() return edit:GetText() end
    return container
end

------------------------------------------------------------------------
-- Scroll area with a slim themed scrollbar (FCScrollFrame)
------------------------------------------------------------------------

local function createScrollbar(parent, onScroll)
    local bar = CreateFrame("Slider", nil, parent)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(6)
    bar:SetMinMaxValues(0, 1)
    bar:SetValueStep(1)
    if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(false) end
    bar.track = UI.Texture(bar, "BACKGROUND", "border", 0.35)
    bar.track:SetAllPoints()
    local thumb = bar:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture(WHITE)
    thumb:SetSize(6, 40)
    Theme:Paint(thumb, "muted", 0.55)
    bar:SetThumbTexture(thumb)
    bar.thumb = thumb
    bar:SetScript("OnEnter", function() Theme:Paint(thumb, "accent", 0.8) end)
    bar:SetScript("OnLeave", function() Theme:Paint(thumb, "muted", 0.55) end)
    bar:SetScript("OnValueChanged", function(self, value)
        if self.fcUpdating then return end
        onScroll(value)
    end)
    return bar
end
UI.CreateScrollbar = createScrollbar

--- Scrollable area. Callers put children on area.content and call
--- area:SetContentHeight(h) after layout.
function UI.ScrollArea(parent)
    local area = CreateFrame("Frame", nil, parent)
    local scroll = CreateFrame("ScrollFrame", nil, area)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -10, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    area.scroll, area.content = scroll, content

    local bar = createScrollbar(area, function(value) scroll:SetVerticalScroll(value) end)
    bar:SetPoint("TOPRIGHT", 0, -2)
    bar:SetPoint("BOTTOMRIGHT", 0, 2)
    area.bar = bar

    local function sync()
        local range = scroll:GetVerticalScrollRange()
        bar.fcUpdating = true
        bar:SetMinMaxValues(0, math.max(0, range))
        bar:SetValue(scroll:GetVerticalScroll())
        bar.fcUpdating = false
        local needed = range > 1
        bar:SetShown(needed)
        -- AutoGutter: the bar's lane opens only while there is something to scroll
        if area.fcAutoGutter and needed ~= area.fcGutter then
            area.fcGutter = needed
            scroll:SetPoint("BOTTOMRIGHT", needed and -10 or 0, 0)
        end
    end
    area.Sync = sync
    area.fcGutter = true

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange()
        self:SetVerticalScroll(U.Clamp(self:GetVerticalScroll() - delta * 48, 0, range))
        sync()
    end)
    scroll:SetScript("OnSizeChanged", function(self, width)
        content:SetWidth(width)
        sync()
        -- what was laid out for the old width follows (a resize, the bar's lane)
        if area.fcOnWidth and math.abs(width - (area.fcWidth or 0)) >= 0.5 then
            area.fcWidth = width
            FC:SafeCall("scroll:width", area.fcOnWidth, width)
        end
    end)
    scroll:SetScript("OnScrollRangeChanged", sync)

    function area:SetContentHeight(height)
        content:SetHeight(math.max(1, height))
        C_Timer.After(0, sync)
    end
    function area:ScrollToTop()
        scroll:SetVerticalScroll(0)
        sync()
    end
    function area:ContentWidth()
        local w = scroll:GetWidth()
        return (w and w > 0) and w or 300
    end
    --- Content that fits gets the whole width: the scrollbar's lane opens
    --- only while there is something to scroll. onWidth(width) lays out
    --- again what was laid out for a width (nil when everything is anchored).
    function area:AutoGutter(onWidth)
        self.fcAutoGutter = true
        self.fcOnWidth = onWidth
        sync()
    end
    return area
end

------------------------------------------------------------------------
-- Object pools (prevents frame leaks when views are rebuilt)
------------------------------------------------------------------------

function UI.Pool(create, reset)
    local pool = { active = {}, free = {} }
    function pool:Acquire()
        local obj = table.remove(self.free)
        if not obj then obj = create() end
        self.active[#self.active + 1] = obj
        if obj.Show then obj:Show() end
        return obj
    end
    function pool:ReleaseAll()
        for i = #self.active, 1, -1 do
            local obj = self.active[i]
            if reset then reset(obj) end
            if obj.Hide then obj:Hide() end
            if obj.ClearAllPoints then obj:ClearAllPoints() end
            self.free[#self.free + 1] = obj
            self.active[i] = nil
        end
    end
    return pool
end

------------------------------------------------------------------------
-- Animations
------------------------------------------------------------------------

function UI.FadeIn(frame, duration)
    if not UI.AnimationsEnabled() then
        frame:SetAlpha(1)
        frame:Show()
        return
    end
    if not frame.fcFade then
        local group = frame:CreateAnimationGroup()
        local alpha = group:CreateAnimation("Alpha")
        alpha:SetFromAlpha(0)
        alpha:SetToAlpha(1)
        alpha:SetSmoothing("OUT")
        group:SetScript("OnFinished", function() frame:SetAlpha(1) end)
        frame.fcFade, frame.fcFadeAlpha = group, alpha
    end
    frame.fcFadeAlpha:SetDuration(duration or 0.18)
    frame:SetAlpha(0)
    frame:Show()
    frame.fcFade:Stop()
    frame.fcFade:Play()
end

--- Scales a fixed-size window by the wanted scale, but never so far that
--- it would not fit on the screen (every part stays reachable).
function UI.FitScale(frame, wanted)
    wanted = wanted or 1
    local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if not screenW or screenW <= 0 then screenW = 1920 end
    if not screenH or screenH <= 0 then screenH = 1080 end
    local scale = wanted
    if h > 0 then scale = math.min(scale, (screenH - 20) / h) end
    if w > 0 then scale = math.min(scale, (screenW - 20) / w) end
    frame:SetScale(math.max(0.4, scale))
end

--- Keeps a movable frame fully on screen and stores its position via save(point, relPoint, x, y).
function UI.MakeMovable(frame, handle, save)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    handle = handle or frame
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() frame:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if save then
            local point, _, relPoint, x, y = frame:GetPoint(1)
            save(point, relPoint, x, y)
        end
    end)
end

Theme:OnChange(UI, function()
    local soft = FC.P and FC.P.appearance.corners == "soft"
    for panel in pairs(panels) do
        if panel.shade then panel.shade:SetShown(soft) end
    end
    -- the style may have changed: painted or flat surfaces
    for panel in pairs(skinnedPanels) do UI.ApplyPanelSkin(panel) end
    for box in pairs(inputs) do UI.ApplyInputSkin(box) end
    local flat = not FC.Skin:Enabled()
    for line in pairs(accentLines) do line:SetShown(flat) end
    UI.RefreshBorders()
end)
