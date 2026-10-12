-- Shared, live artwork selector for Map settings and the illustrated gallery.
-- All examples resolve their own style; opening the gallery never changes it.
local _, FC = ...
local Picker = FC:NewModule("PinStylePicker")
local UI, L, Art, Theme = FC.UI, FC.L, FC.PinArt, FC.Theme
local selectors = setmetatable({}, { __mode = "k" })
local SAMPLES = {
    { t = "cave", label = "CAT_CAVE" },
    { t = "rare", label = "PIN_STYLE_SAMPLE_RARE" },
    { t = "treasure", label = "CAT_TREASURE" },
}
local GAP, PAD = 12, 12
local WIDTH, HEIGHT, EDGE = 900, 700, 26

local function makeCard(parent, style, iconSize)
    local card = CreateFrame("Button", nil, parent)
    card.styleID, card.samples = style.id, {}
    card:EnableMouse(true)
    card:RegisterForClicks("LeftButtonUp")
    card.bg = UI.Texture(card, "BACKGROUND", "panelAlt", 1)
    card.bg:SetAllPoints()
    card.hover = UI.Texture(card, "HIGHLIGHT", "accent", 0.09)
    card.hover:SetAllPoints()
    UI.AddBorder(card, "border", 1, 1)
    card.title = UI.WrappedText(card, "body", "text")
    card.title:SetText(L[style.label])
    card.description = UI.WrappedText(card, "secondary", "muted")
    card.description:SetText(L[style.description])
    card.status = UI.Text(card, "meta", "muted")
    card.status:SetJustifyH("CENTER")
    card.check = UI.Icon(card, 16, "OVERLAY")
    card.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    card.check:SetTexCoord(0, 1, 0, 1)
    card.check:SetPoint("TOPRIGHT", -PAD, -PAD)
    Theme:Tint(card.check, "accent")
    for i, sample in ipairs(SAMPLES) do
        local item = { icon = UI.Icon(card, iconSize), label = UI.WrappedText(card, "meta", "muted") }
        item.label:SetText(L[sample.label])
        item.label:SetJustifyH("CENTER")
        card.samples[i] = item
    end
    function card:Refresh()
        self.selected = Art:GetStyle().id == self.styleID
        self.check:SetShown(self.selected)
        self.status:SetText(self.selected and L.PIN_STYLE_SELECTED or L.PIN_STYLE_CHOOSE)
        Theme:Paint(self.status, self.selected and "accent" or "muted")
        UI.SetBorderColor(self, self.selected and "accent" or "border")
        local scale = self:GetEffectiveScale() or 1
        for i, sample in ipairs(SAMPLES) do
            local icon, fallback = Art:IconForStyle(self.styleID, sample, false, iconSize * scale)
            Art:SetIcon(self.samples[i].icon, icon, fallback)
        end
    end
    card:SetScript("OnClick", function(self)
        FC.Config:Set("map.pinArtwork", self.styleID)
    end)
    return card
end

function Picker:CreateSelector(parent, width, large)
    local selector = CreateFrame("Frame", nil, parent)
    selector.cards, selector.large = {}, large
    selector.measure = UI.Text(selector, "meta", "muted")
    selector.measure:Hide()
    local iconSize = large and 48 or 32
    for i, style in ipairs(Art.STYLES) do selector.cards[i] = makeCard(selector, style, iconSize) end

    function selector:Refresh()
        for _, card in ipairs(self.cards) do card:Refresh() end
    end

    function selector:Layout(available)
        local w = math.max(220, available or self:GetWidth())
        local sampleWidth = iconSize + 8
        for _, sample in ipairs(SAMPLES) do
            self.measure:SetText(L[sample.label])
            sampleWidth = math.max(sampleWidth, self.measure:GetStringWidth() + 6)
        end
        local minCardWidth = math.max(234, sampleWidth * #SAMPLES + PAD * 2)
        local columns = math.max(1, math.min(3, math.floor((w + GAP) / (minCardWidth + GAP))))
        local cw = math.floor((w - (columns - 1) * GAP) / columns)
        local sampleColumns = math.max(1, math.min(#SAMPLES, math.floor((cw - PAD * 2) / sampleWidth)))
        local titleH, descH, labelH, statusH = 0, 0, 0, 0
        for _, card in ipairs(self.cards) do
            card:SetWidth(cw)
            card.title:SetWidth(cw - PAD * 2 - 20)
            card.description:SetWidth(cw - PAD * 2)
            card.status:SetWidth(cw - PAD * 2)
            titleH = math.max(titleH, card.title:GetStringHeight())
            descH = math.max(descH, card.description:GetStringHeight())
            statusH = math.max(statusH, card.status:GetStringHeight())
            for _, sample in ipairs(card.samples) do
                sample.label:SetWidth((cw - PAD * 2) / sampleColumns)
                labelH = math.max(labelH, sample.label:GetStringHeight())
            end
        end
        local sampleY = PAD + titleH + 6 + descH + 14
        local sampleRowHeight = iconSize + 5 + labelH + 12
        local height = sampleY + math.ceil(#SAMPLES / sampleColumns) * sampleRowHeight + statusH + PAD
        for i, card in ipairs(self.cards) do
            card:SetHeight(height)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", ((i - 1) % columns) * (cw + GAP), -math.floor((i - 1) / columns) * (height + GAP))
            card.title:SetPoint("TOPLEFT", PAD, -PAD)
            card.description:SetPoint("TOPLEFT", PAD, -(PAD + titleH + 6))
            local sw = (cw - PAD * 2) / sampleColumns
            for j, sample in ipairs(card.samples) do
                local column, row = (j - 1) % sampleColumns, math.floor((j - 1) / sampleColumns)
                local y = sampleY + row * sampleRowHeight
                sample.icon:SetPoint("TOP", card, "TOPLEFT", PAD + (column + 0.5) * sw, -y)
                sample.label:SetPoint("TOPLEFT", PAD + column * sw, -(y + iconSize + 5))
            end
            card.status:SetPoint("BOTTOMLEFT", PAD, PAD)
        end
        self.columns = columns
        local total = math.ceil(#self.cards / columns) * (height + GAP) - GAP
        self:SetSize(w, total)
        return total
    end

    selectors[selector] = true
    selector:SetScript("OnShow", function(self)
        self:Refresh()
        self:Layout()
    end)
    selector:Refresh()
    return selector, selector:Layout(width)
end

function Picker:Layout()
    local f = self.frame
    if not f or self.layingOut then return end
    self.layingOut = true
    local width = f:GetWidth() - EDGE * 2
    local header = f.header
    header:SetPoint("TOPLEFT", EDGE, -EDGE)
    header:SetPoint("TOPRIGHT", -EDGE, -EDGE)
    header.title:SetWidth(width - 72)
    header.subtitle:SetWidth(width - 72)
    local titleH, subH = header.title:GetStringHeight(), header.subtitle:GetStringHeight()
    header:SetHeight(math.max(112, titleH + subH + 38))
    header.title:SetPoint("TOPLEFT", 16, -18)
    header.subtitle:SetPoint("TOPLEFT", 16, -(18 + titleH + 8))
    local path, focusY = FC.Skin:HeaderPath("pinstyles")
    local illustrated = FC.Skin:Enabled() and header.art:SetArt(path, 0.5, focusY)
    header.art:SetShown(illustrated)
    header.shade:SetShown(illustrated)
    f.note:SetWidth(width - 8)
    f.note:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 4, -12)
    f.footer:SetWidth(width - f.close:GetWidth() - 28)
    f.footer:SetPoint("BOTTOMLEFT", EDGE + 4, EDGE + 2)
    local footerH = math.max(f.footer:GetStringHeight(), f.close:GetHeight())
    f.area:SetPoint("TOPLEFT", EDGE + 4, -(EDGE + header:GetHeight() + 24 + f.note:GetStringHeight()))
    f.area:SetPoint("BOTTOMRIGHT", -EDGE - 4, EDGE + footerH + 14)
    local contentWidth = math.max(220, f.area:ContentWidth() - 4)
    f.selector:SetPoint("TOPLEFT", 0, -2)
    f.area:SetContentHeight(f.selector:Layout(contentWidth) + 4)
    UI.FitScale(f, FC.P.appearance.scale)
    self.layingOut = nil
end

function Picker:Build()
    if self.frame then return end
    local f = UI.Panel(UIParent, { name = "ForeverCompanionPinStyles", strata = "DIALOG",
        bgAlpha = 0.99, skin = "window", corner = EDGE })
    self.frame = f
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameLevel(30)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()
    f.header = CreateFrame("Frame", nil, f)
    local header = f.header
    header.art = FC.Skin:Art(header)
    header.shade = FC.Skin:Shade(header, "HORIZONTAL", 0.03, 0.02, 0.01, 0.6)
    header.shade:SetAllPoints()
    header.title = UI.WrappedText(header, "title", "text")
    header.title:SetText(L.PIN_STYLE_TITLE)
    header.subtitle = UI.WrappedText(header, "secondary", "muted")
    header.subtitle:SetText(L.PIN_STYLE_SUBTITLE)
    header.close = UI.IconButton(header, "Interface\\Buttons\\UI-StopButton", 24, L.CLOSE, function() f:Hide() end)
    header.close:SetPoint("TOPRIGHT", -10, -10)
    UI.MakeMovable(f, header)
    f.note = UI.WrappedText(f, "secondary", "muted")
    f.note:SetText(L.PIN_STYLE_NOTE)
    f.footer = UI.WrappedText(f, "meta", "muted")
    f.footer:SetText(L.PIN_STYLE_SAVED)
    f.close = UI.Button(f, L.CLOSE, { autoWidth = true, width = 100, height = 28, onClick = function() f:Hide() end })
    f.close:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    f.area = UI.ScrollArea(f)
    f.selector = self:CreateSelector(f.area.content, WIDTH - EDGE * 2 - 24, true)
    local function reflow()
        FC.Utils.Debounce("pin-styles-layout", 0.05, function()
            if f:IsShown() then self:Layout() end
        end)
    end
    f.area:AutoGutter(reflow)
    -- The painted frame also owns a size hook; preserve it when reflowing.
    f:HookScript("OnSizeChanged", reflow)
    f:SetScript("OnShow", function()
        f.selector:Refresh()
        self:Layout()
    end)
    tinsert(UISpecialFrames, "ForeverCompanionPinStyles")
end

function Picker:Show()
    self:Build()
    self.frame:Show()
    self:Layout()
    self.frame.area:ScrollToTop()
end

function Picker:OnEnable()
    local function refresh()
        for selector in pairs(selectors) do selector:Refresh() end
    end
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path == "map" or path == "map.*" or path == "map.pinArtwork" then refresh() end
    end)
    local function reflow()
        refresh()
        for selector in pairs(selectors) do selector:Layout() end
        self:Layout()
    end
    FC.Bus:On("FONTS_CHANGED", self, reflow)
    FC.Bus:On("THEME_CHANGED", self, reflow)
    FC.Bus:On("PROFILE_CHANGED", self, reflow)
    FC.Events:Register("DISPLAY_SIZE_CHANGED", self, function() self:Layout() end)
end
