-- Language choice shared by first-run setup and the dedicated Settings page.
-- Selection is a preview; only Apply commits the account-wide preference.
local _, FC = ...
local Picker = FC:NewModule("LanguagePicker")
local UI, L, Locale, Theme, Fonts = FC.UI, FC.L, FC.Locale, FC.Theme, FC.Fonts
local WIDTH, EDGE, BANNER, GAP = 560, 26, 118, 10
local settingsControls = setmetatable({}, { __mode = "k" })

function Picker:CreateSelector(parent, onSelect)
    local selector = CreateFrame("Frame", nil, parent)
    selector.cards = {}
    for _, option in ipairs(Locale.OPTIONS) do
        local card = CreateFrame("Button", nil, selector)
        card.option = option
        card.bg = UI.Texture(card, "BACKGROUND", "panelAlt", 1)
        card.bg:SetAllPoints()
        UI.AddBorder(card, "border")
        card.hover = UI.Texture(card, "HIGHLIGHT", "accent", 0.08)
        card.hover:SetAllPoints()
        UI.SkinFrame(card, "panel", { corner = 10, tint = 0.72 })
        card.check = UI.Icon(card, 18)
        card.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        card.check:SetTexCoord(0, 1, 0, 1)
        card.check:SetPoint("TOPRIGHT", -10, -12)
        Theme:Tint(card.check, "accent")
        card.title = UI.WrappedText(card, "cardTitle", "text")
        card.title:SetPoint("TOPLEFT", 14, -12)
        card.description = UI.WrappedText(card, "secondary", "muted")
        card.description:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -5)
        card:SetScript("OnClick", function() onSelect(option.value) end)
        selector.cards[#selector.cards + 1] = card
    end
    function selector:Refresh(choice, preview)
        self.choice, self.preview = choice, preview or Locale.active
        local strings = Locale:Strings(self.preview)
        for _, card in ipairs(self.cards) do
            local option = card.option
            local selected = option.value == choice
            card.check:SetShown(selected)
            UI.SetBorderColor(card, selected and "accent" or "border")
            card.fcTint = selected and 1.08 or 0.72
            UI.ApplyPanelSkin(card)
            card.title:SetFontObject(Fonts:ForLocale("cardTitle", option.value == "auto" and self.preview or option.value))
            card.description:SetFontObject(Fonts:ForLocale("secondary", self.preview))
            card.title:SetText(option.name or strings[option.label])
            local description = option.value == "auto" and Locale:Name(Locale:Resolve("auto"), strings) or strings[option.label]
            card.description:SetText(description == option.name and "" or description)
            -- Automatic mode may name a Russian client while previewing English.
            if option.value == "auto" and Locale:Resolve("auto") == "ruRU" then
                card.description:SetFontObject(Fonts:ForLocale("secondary", "ruRU"))
            end
        end
    end
    function selector:Layout(width)
        width = math.max(220, width or self:GetWidth())
        local columns = width >= 420 and 2 or 1
        local cw = (width - GAP * (columns - 1)) / columns
        local height = 64
        for _, card in ipairs(self.cards) do
            card.title:SetWidth(cw - 52)
            card.description:SetWidth(cw - 28)
            height = math.max(height, 24 + card.title:GetStringHeight() + 5 + card.description:GetStringHeight())
        end
        for i, card in ipairs(self.cards) do
            card:SetSize(cw, height)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", ((i - 1) % columns) * (cw + GAP), -math.floor((i - 1) / columns) * (height + GAP))
        end
        local total = math.ceil(#self.cards / columns) * (height + GAP) - GAP
        self:SetSize(width, total)
        return total
    end
    return selector
end

function Picker:NeedsReload(choice)
    return Locale:Resolve(choice) ~= Locale.active
end

function Picker:Apply(choice, onboarding)
    if InCombatLockdown() or not Locale:ValidChoice(choice) then return false end
    local reload = self:NeedsReload(choice)
    if reload and type(ReloadUI) ~= "function" then return false end
    if onboarding then FC.db.languageGuidePending = true end
    Locale:SetPreference(choice)
    if self.frame then self.frame:Hide() end
    if reload then
        ReloadUI()
    elseif onboarding then
        FC.Onboarding:Open({ "progress", "share" }, true)
    end
    return true
end

function Picker:Refresh()
    local f = self.frame
    if not f then return end
    local strings = Locale:Strings(self.choice)
    local locale = Locale:Resolve(self.choice)
    for _, entry in ipairs({ { f.title, "title" }, { f.subtitle, "body" }, { f.note, "secondary" },
        { f.step, "meta" }, { f.accept.label, "button" }, { f.cancel.label, "button" } }) do
        entry[1]:SetFontObject(Fonts:ForLocale(entry[2], locale))
    end
    f.title:SetText(strings.LANGUAGE_TITLE)
    f.subtitle:SetText(strings.LANGUAGE_WELCOME_TEXT)
    f.note:SetText(InCombatLockdown() and strings.LANGUAGE_COMBAT or
        (self:NeedsReload(self.choice) and strings.LANGUAGE_RELOAD_NOTE or strings.LANGUAGE_SAVED_NOTE))
    f.step:SetText(self.onboarding and string.format(strings.ONBOARD_STEP, 1, 3) or "")
    f.cancel:SetLabel(strings.CANCEL)
    f.cancel:SetShown(not self.onboarding)
    f.accept:SetLabel(self:NeedsReload(self.choice) and strings.LANGUAGE_APPLY_RELOAD or
        (self.onboarding and strings.CONTINUE or strings.SAVE))
    f.accept:SetDisabled(InCombatLockdown())
    f.selector:Refresh(self.choice, self.choice)
    local shown = FC.Skin:Enabled() and f.banner.art:SetArt(FC.Skin:BannerPath("language"))
    f.banner.art:SetShown(shown and true or false)
    f.banner.fade:SetShown(shown and true or false)
    f.logo:SetShown(not shown)
    self:Layout()
end

function Picker:Layout()
    local f = self.frame
    if not f or self.layingOut then return end
    self.layingOut = true
    f.accept:FitLabel(230, 30)
    f.cancel:FitLabel(190, 30)
    local actionH = math.max(f.accept:GetHeight(), self.onboarding and f.step:GetStringHeight() or f.cancel:GetHeight())
    local top = EDGE + BANNER + 12 + f.title:GetStringHeight() + 10 + f.subtitle:GetStringHeight() + 16
    local footer = EDGE + actionH + 12 + f.note:GetStringHeight() + 16
    local contentHeight = f.selector:Layout(WIDTH - EDGE * 2 - 20)
    f:SetHeight(math.max(top + footer + 130, math.min(760, top + contentHeight + 8 + footer)))
    f.area:ClearAllPoints()
    f.area:SetPoint("TOPLEFT", EDGE, -top)
    f.area:SetPoint("BOTTOMRIGHT", -EDGE, footer)
    f.selector:SetPoint("TOPLEFT", 0, -2)
    f.selector:Layout(math.max(220, f.area:ContentWidth() - 4))
    f.area:SetContentHeight(f.selector:GetHeight() + 4)
    f.note:ClearAllPoints()
    f.note:SetPoint("BOTTOMLEFT", EDGE, EDGE + actionH + 12)
    f.step:SetPoint("BOTTOMLEFT", EDGE, EDGE + (actionH - f.step:GetStringHeight()) / 2)
    UI.FitScale(f, FC.P.appearance.scale)
    self.layingOut = nil
end

function Picker:Build()
    if self.frame then return end
    local f = UI.Panel(UIParent, { name = "ForeverCompanionLanguage", strata = "DIALOG", bgAlpha = 0.99, skin = "window", corner = 24 })
    self.frame = f
    f:SetSize(WIDTH, 640)
    f:SetPoint("CENTER")
    f:SetFrameLevel(40)
    f:EnableMouse(true)
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    f:SetScript("OnHide", function()
        if not self.onboarding and FC.Onboarding:NeedsAsking() then
            FC.Utils.After(0.1, function() FC.Onboarding:OpenWhenReady() end)
        end
    end)
    UI.MakeMovable(f)
    f.accent = UI.AccentLine(f)
    f.banner = CreateFrame("Frame", nil, f)
    f.banner:SetPoint("TOPLEFT", EDGE, -EDGE)
    f.banner:SetPoint("TOPRIGHT", -EDGE, -EDGE)
    f.banner:SetHeight(BANNER)
    f.banner.art = FC.Skin:Art(f.banner, { layer = "BACKGROUND", sublevel = -4 })
    f.banner.fade = FC.Skin:Shade(f.banner, "VERTICAL", 0.05, 0.03, 0.02, 0.75, "BACKGROUND", -1)
    f.banner.fade:SetPoint("BOTTOMLEFT")
    f.banner.fade:SetPoint("BOTTOMRIGHT")
    f.banner.fade:SetHeight(30)
    f.logo = UI.Icon(f.banner, 56)
    f.logo:SetTexture(FC.C.MEDIA .. "Logo")
    f.logo:SetPoint("CENTER")
    f.title = UI.WrappedText(f, "title", "text")
    f.title:SetPoint("TOP", f.banner, "BOTTOM", 0, -12)
    f.title:SetWidth(WIDTH - EDGE * 2)
    f.title:SetJustifyH("CENTER")
    f.subtitle = UI.WrappedText(f, "body", "muted")
    f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.subtitle:SetWidth(WIDTH - 80)
    f.subtitle:SetJustifyH("CENTER")
    f.note = UI.WrappedText(f, "secondary", "muted")
    f.note:SetWidth(WIDTH - EDGE * 2)
    f.step = UI.Text(f, "meta", "muted")
    f.step:SetWidth(200)
    f.accept = UI.Button(f, L.CONTINUE, { width = 140, autoWidth = true, height = 30, style = "primary", onClick = function()
        self:Apply(self.choice, self.onboarding)
    end })
    f.accept:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    f.cancel = UI.Button(f, L.CANCEL, { width = 100, autoWidth = true, height = 30, style = "ghost", onClick = function() f:Hide() end })
    f.cancel:SetPoint("BOTTOMLEFT", EDGE, EDGE)
    f.area = UI.ScrollArea(f)
    f.selector = self:CreateSelector(f.area.content, function(choice)
        self.choice = choice
        self:Refresh()
    end)
    f.area:AutoGutter(function() self:Layout() end)
end

function Picker:IsShown()
    return self.frame and self.frame:IsShown()
end

function Picker:Show(onboarding)
    if self:IsShown() and self.onboarding then return end
    self:Build()
    self.onboarding, self.choice = onboarding == true, Locale:Preference()
    -- Escape cancels a settings preview; first-run setup has an explicit Continue.
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == "ForeverCompanionLanguage" then table.remove(UISpecialFrames, i) end
    end
    if not self.onboarding then tinsert(UISpecialFrames, "ForeverCompanionLanguage") end
    self:Refresh()
    self.frame:Show()
    self.frame.area:ScrollToTop()
end

function Picker:CreateSettingsControl(parent, width)
    local control = CreateFrame("Frame", nil, parent)
    control.current = UI.WrappedText(control, "body", "text")
    control.current:SetPoint("TOPLEFT")
    control.note = UI.WrappedText(control, "secondary", "muted")
    control.selector = self:CreateSelector(control, function(choice)
        control.choice = choice
        control:Refresh(true)
        control:Layout()
        if control.onLayoutChanged then control.onLayoutChanged() end
    end)
    control.apply = UI.Button(control, L.SAVE, { style = "primary", autoWidth = true, width = 140, height = 30, onClick = function()
        self:Apply(control.choice, false)
    end })
    control.open = UI.Button(control, L.LANGUAGE_OPEN_WINDOW, { autoWidth = true, width = 180, height = 30, onClick = function() self:Show(false) end })
    function control:Refresh(keepSelection)
        if not keepSelection then self.choice = Locale:Preference() end
        local current = Locale:Preference()
        self.current:SetFontObject(Fonts:ForLocale("body", Locale:Resolve(current) == "ruRU" and "ruRU" or Locale.active))
        self.current:SetText(string.format(L.LANGUAGE_CURRENT, Locale:Name(current)))
        self.selector:Refresh(self.choice, Locale.active)
        self.note:SetText(InCombatLockdown() and L.LANGUAGE_COMBAT or
            (Picker:NeedsReload(self.choice) and L.LANGUAGE_RELOAD_NOTE or L.LANGUAGE_SETTINGS_NOTE))
        self.apply:SetLabel(Picker:NeedsReload(self.choice) and L.LANGUAGE_APPLY_RELOAD or L.SAVE)
        self.apply:SetDisabled(InCombatLockdown() or (self.choice == current and not Picker:NeedsReload(self.choice)))
    end
    function control:Layout(available)
        local w = math.max(220, available or self:GetWidth())
        self.current:SetWidth(w)
        self.note:SetWidth(w)
        self.selector:SetPoint("TOPLEFT", 0, -(self.current:GetStringHeight() + 16))
        local y = self.current:GetStringHeight() + 16 + self.selector:Layout(w) + 16
        self.note:ClearAllPoints()
        self.note:SetPoint("TOPLEFT", 0, -y)
        y = y + self.note:GetStringHeight() + 14
        self.apply:FitLabel(w, 30)
        self.open:FitLabel(w, 30)
        self.apply:ClearAllPoints()
        self.apply:SetPoint("TOPLEFT", 0, -y)
        self.open:ClearAllPoints()
        self.open:SetPoint("TOPLEFT", 0, -(y + self.apply:GetHeight() + 10))
        self:SetSize(w, y + self.apply:GetHeight() + 10 + self.open:GetHeight() + 8)
        return self:GetHeight()
    end
    settingsControls[control] = true
    control:Refresh()
    return control, control:Layout(width)
end

function Picker:OnEnable()
    local function refresh()
        if self:IsShown() then self:Refresh() end
        for control in pairs(settingsControls) do
            control:Refresh(true); control:Layout()
            if control.onLayoutChanged then control.onLayoutChanged() end
        end
    end
    FC.Bus:On("FONTS_CHANGED", self, refresh)
    FC.Bus:On("THEME_CHANGED", self, refresh)
    FC.Bus:On("LANGUAGE_PREFERENCE_CHANGED", self, function()
        for control in pairs(settingsControls) do
            control:Refresh(); control:Layout()
            if control.onLayoutChanged then control.onLayoutChanged() end
        end
    end)
    FC.Events:Register("PLAYER_REGEN_DISABLED", self, refresh)
    FC.Events:Register("PLAYER_REGEN_ENABLED", self, refresh)
    FC.Events:Register("DISPLAY_SIZE_CHANGED", self, function() self:Layout() end)
end
