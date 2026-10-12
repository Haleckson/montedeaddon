--[[
  Forever Companion - UI/Onboarding.lua
  First-run flow: language, then how progress counts (account-wide or per
  character), then sharing. The language screen is shared with Settings.
  The journal starts
  in the painted look; the palette at the top of the journal and
  Settings > Appearance change it.

  The progress question cannot be skipped. Players who went through the
  welcome guide before it existed get that question alone at login, until
  they answered it (the Progress page and Settings > General change the
  answer later).
]]

local _, FC = ...

local Onboarding = FC:NewModule("Onboarding")

local UI = FC.UI
local L = FC.L
local C = FC.C
local U = FC.Utils
local Theme = FC.Theme

local WIDTH, HEIGHT = 560, 480
local BANNER = 118        -- the step's painting (journal style), or the logo
local INSET = 26          -- clear of the painted frame; banner and cards line up

local function optionCard(parent, title, text, icon, onClick)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(WIDTH - 2 * INSET, 64)
    card.bg = UI.Texture(card, "BACKGROUND", "panelAlt", 1)
    card.bg:SetAllPoints()
    UI.AddBorder(card, "border")
    card.hover = UI.Texture(card, "HIGHLIGHT", "text", 0.05)
    card.hover:SetAllPoints()
    card.radio = card:CreateTexture(nil, "ARTWORK")
    card.radio:SetSize(14, 14)
    card.radio:SetPoint("LEFT", 16, 0)
    card.radio:SetTexture(C.WHITE)
    if card.radio.SetMask then pcall(card.radio.SetMask, card.radio, C.CIRCLE_MASK) end
    card.icon = UI.Icon(card, 32)
    card.icon:SetPoint("LEFT", 44, 0)
    UI.SetIcon(card.icon, icon)
    card.title = UI.WrappedText(card, "cardTitle", "text")
    card.title:SetPoint("TOPLEFT", 88, -12)
    card.title:SetWidth(WIDTH - 2 * INSET - 100)
    card.title:SetText(title)
    card.text = UI.WrappedText(card, "secondary", "muted")
    card.text:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -5)
    card.text:SetWidth(WIDTH - 2 * INSET - 100)
    card.text:SetText(text)
    card:SetScript("OnClick", onClick)
    UI.SkinFrame(card, "panel", { corner = 10, tint = 0.72 })
    function card:SetSelected(selected)
        self.fcSelected = selected
        UI.SetBorderColor(self, selected and "accent" or "border", 1)
        Theme:Paint(self.radio, selected and "accent" or "border", 1)
        self.fcTint = selected and 1.08 or 0.72
        UI.ApplyPanelSkin(self)
    end
    Theme:OnChange(card, function(c) c:SetSelected(c.fcSelected) end)
    return card
end

function Onboarding:Build()
    if self.frame then return end
    local frame = UI.Panel(UIParent, { name = "ForeverCompanionOnboarding", strata = "DIALOG", bgAlpha = 0.99, skin = "window", corner = 24 })
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    UI.MakeMovable(frame)
    frame.accent = UI.AccentLine(frame)
    -- the step's painting across the top (journal style); the logo otherwise
    frame.banner = CreateFrame("Frame", nil, frame)
    frame.banner:SetPoint("TOPLEFT", INSET, -INSET)
    frame.banner:SetPoint("TOPRIGHT", -INSET, -INSET)
    frame.banner:SetHeight(BANNER)
    frame.banner.art = FC.Skin:Art(frame.banner, { layer = "BACKGROUND", sublevel = -4 })
    frame.banner.fade = FC.Skin:Shade(frame.banner, "VERTICAL", 0.05, 0.03, 0.02, 0.75, "BACKGROUND", -1)
    frame.banner.fade:SetPoint("BOTTOMLEFT")
    frame.banner.fade:SetPoint("BOTTOMRIGHT")
    frame.banner.fade:SetHeight(30)
    frame.logo = frame:CreateTexture(nil, "ARTWORK")
    frame.logo:SetTexture(C.MEDIA .. "Logo")
    frame.logo:SetSize(56, 56)
    frame.logo:SetPoint("CENTER", frame.banner, "CENTER", 0, 0)
    frame.title = UI.WrappedText(frame, "title", "text")
    frame.title:SetPoint("TOP", frame.banner, "BOTTOM", 0, -12)
    frame.title:SetWidth(WIDTH - 2 * INSET)
    frame.title:SetJustifyH("CENTER")
    frame.subtitle = UI.WrappedText(frame, "body", "muted")
    frame.subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -10)
    frame.subtitle:SetWidth(WIDTH - 80)
    frame.subtitle:SetJustifyH("CENTER")
    frame.step = UI.Text(frame, "meta", "muted")
    frame.step:SetPoint("BOTTOMLEFT", INSET, INSET + 4)
    frame.next = UI.Button(frame, L.CONTINUE, { style = "primary", width = 140, height = 30, autoWidth = true, onClick = function() self:Next() end })
    frame.next:SetPoint("BOTTOMRIGHT", -INSET, INSET - 4)
    frame.skip = UI.Button(frame, L.SKIP, { style = "ghost", width = 90, height = 30, autoWidth = true, onClick = function() self:Finish() end })
    frame.skip:SetPoint("RIGHT", frame.next, "LEFT", -8, 0)
    self.frame = frame

    -- how progress counts (cannot be skipped)
    local progress = CreateFrame("Frame", nil, frame)
    progress:SetPoint("TOPLEFT", INSET, -(INSET + BANNER + 92))
    progress:SetPoint("BOTTOMRIGHT", -INSET, 64)
    progress.label = UI.SectionHeader(progress, L.ONBOARD_PROGRESS_QUESTION)
    progress.label:SetPoint("TOPLEFT")
    progress.label:SetPoint("RIGHT")
    progress.account = optionCard(progress, L.ONBOARD_PROGRESS_ACCOUNT, L.ONBOARD_PROGRESS_ACCOUNT_TEXT, "Interface\\Icons\\INV_Misc_Book_09", function() self:SetProgress("account") end)
    progress.account:SetPoint("TOPLEFT", progress.label, "BOTTOMLEFT", 0, -8)
    progress.character = optionCard(progress, L.ONBOARD_PROGRESS_CHARACTER, L.ONBOARD_PROGRESS_CHARACTER_TEXT, "Interface\\Icons\\INV_Misc_Head_Human_02", function() self:SetProgress("character") end)
    progress.character:SetPoint("TOPLEFT", progress.account, "BOTTOMLEFT", 0, -8)
    self.progressStep = progress

    -- sharing
    local share = CreateFrame("Frame", nil, frame)
    share:SetPoint("TOPLEFT", INSET, -(INSET + BANNER + 92))
    share:SetPoint("BOTTOMRIGHT", -INSET, 64)
    share.label = UI.SectionHeader(share, L.ONBOARD_SHARE_QUESTION)
    share.label:SetPoint("TOPLEFT")
    share.label:SetPoint("RIGHT")
    share.private = optionCard(share, L.ONBOARD_PRIVATE, L.ONBOARD_PRIVATE_TEXT, "Interface\\Icons\\INV_Misc_Key_14", function() self:SetSharing(false) end)
    share.private:SetPoint("TOPLEFT", share.label, "BOTTOMLEFT", 0, -8)
    share.guild = optionCard(share, L.ONBOARD_GUILD, L.ONBOARD_GUILD_TEXT, C.GUILD_ICON, function() self:SetSharing(true) end)
    share.guild:SetPoint("TOPLEFT", share.private, "BOTTOMLEFT", 0, -8)
    self.shareStep = share
    FC.Bus:On("FONTS_CHANGED", self, function() if self.frame and self.frame:IsShown() then self:Layout() end end)
end

function Onboarding:Layout()
    local f = self.frame
    if not f then return end
    local maxStepHeight = 0
    for _, group in ipairs({ self.progressStep, self.shareStep }) do
        group:ClearAllPoints()
        group:SetPoint("TOPLEFT", f.subtitle, "BOTTOMLEFT", -(WIDTH - 2 * INSET - f.subtitle:GetWidth()) / 2, -16)
        group:SetWidth(WIDTH - 2 * INSET)
        group.label:SetHeight(math.max(22, group.label.label:GetStringHeight() + 8))
        local cards = group == self.progressStep and { group.account, group.character } or { group.private, group.guild }
        local h = group.label:GetHeight()
        for _, card in ipairs(cards) do
            card:SetHeight(math.max(64, 24 + card.title:GetStringHeight() + 5 + card.text:GetStringHeight()))
            h = h + 8 + card:GetHeight()
        end
        group:SetHeight(h)
        if group:IsShown() then maxStepHeight = math.max(maxStepHeight, h) end
    end
    f.next:FitLabel(220, 30)
    f.skip:FitLabel(120, 30)
    f.step:SetWidth(140)
    local footer = math.max(f.next:GetHeight(), f.skip:GetHeight(), f.step:GetStringHeight())
    f:SetHeight(INSET + BANNER + 12 + f.title:GetStringHeight() + 10 + f.subtitle:GetStringHeight() + 16 + maxStepHeight + 20 + footer + INSET)
    UI.FitScale(f, FC.P.appearance.scale)
end

function Onboarding:SetSharing(enabled)
    FC.Config:Set("sync.enabled", enabled)
    FC.Config:Set("sync.autoShare", enabled)
    FC.Config:Set("sync.channel", enabled and "GUILD" or "NONE")
    self.shareStep.private:SetSelected(not enabled)
    self.shareStep.guild:SetSelected(enabled)
end

--- The step's painting in the journal style, the logo in the flat style.
function Onboarding:ApplyBanner()
    local frame = self.frame
    local key = self.steps and self.steps[self.stepIndex or 1]
    local journal = FC.Skin:Enabled()
    local shown = journal and frame.banner.art:SetArt(FC.Skin:BannerPath(key or "progress"))
    frame.banner.art:SetShown(shown and true or false)
    frame.banner.fade:SetShown(shown and true or false)
    frame.logo:SetShown(not shown)
end

function Onboarding:SetProgress(mode)
    self.progressChoice = mode
    self.progressStep.account:SetSelected(mode == "account")
    self.progressStep.character:SetSelected(mode == "character")
    self.frame.next:SetDisabled(false)
end

-- The screens of a run: the whole welcome guide, or the progress question alone.
local FULL, PROGRESS_ONLY = { "progress", "share" }, { "progress" }

function Onboarding:ShowStep(index)
    self.stepIndex = index
    local frame = self.frame
    local steps = self.steps
    local key = steps[index]
    self.progressStep:SetShown(key == "progress")
    self.shareStep:SetShown(key == "share")
    local offset = self.withLanguage and 1 or 0
    frame.step:SetText(#steps > 1 and string.format(L.ONBOARD_STEP, index + offset, #steps + offset) or "")
    -- the progress question has to be answered; what comes after it can be skipped
    frame.skip:SetShown(key ~= "progress")
    if index < #steps then
        frame.next:SetLabel(L.CONTINUE)
    else
        frame.next:SetLabel(#steps > 1 and L.ONBOARD_FINISH or L.SAVE)
    end
    frame.next:SetDisabled(false)
    if key == "progress" then
        frame.title:SetText(#steps > 1 and L.ONBOARD_WELCOME or L.ONBOARD_PROGRESS_TITLE)
        frame.subtitle:SetText(#steps > 1 and L.ONBOARD_WELCOME_TEXT or L.ONBOARD_PROGRESS_TEXT)
        local choice = self.progressChoice
        self.progressStep.account:SetSelected(choice == "account")
        self.progressStep.character:SetSelected(choice == "character")
        frame.next:SetDisabled(choice == nil)
    elseif key == "share" then
        frame.title:SetText(L.ONBOARD_SHARE_TITLE)
        frame.subtitle:SetText(L.ONBOARD_SHARE_TEXT)
        local enabled = FC.P.sync.enabled and FC.P.sync.channel ~= "NONE"
        self.shareStep.private:SetSelected(not enabled)
        self.shareStep.guild:SetSelected(enabled)
    end
    self:ApplyBanner()
    self:Layout()
end

function Onboarding:Next()
    if self.steps[self.stepIndex] == "progress" then
        if not self.progressChoice then return end
        FC.Progress:SetMode(self.progressChoice)
    end
    if self.stepIndex < #self.steps then
        self:ShowStep(self.stepIndex + 1)
    else
        self:Finish()
    end
end

function Onboarding:Finish()
    -- skipping is only offered once the progress question is answered
    if not FC.Progress:IsChosen() then return end
    self.frame:Hide()
    if #self.steps > 1 then
        FC.db.onboarded = true
        FC.db.languageGuidePending = nil
        FC:Print(L.ONBOARD_DONE)
    end
    local mode = FC.Progress:Mode() == "character" and L.PROGRESS_MODE_CHARACTER or L.PROGRESS_MODE_ACCOUNT
    FC:Print(L.MSG_PROGRESS_MODE, mode)
end

function Onboarding:Open(steps, withLanguage)
    self:Build()
    self.steps = steps
    self.withLanguage = withLanguage == true
    self.progressChoice = FC.db.progressMode -- nothing is preselected until the player chose once
    UI.FitScale(self.frame, FC.P.appearance.scale)
    self:ShowStep(1)
    UI.FadeIn(self.frame, 0.25)
end

--- The whole welcome guide (also Settings > General > Run the welcome guide).
function Onboarding:Start()
    if self.frame then self.frame:Hide() end
    FC.LanguagePicker:Show(true)
end

--- The progress question alone, for players who had the addon before it asked.
function Onboarding:AskProgress()
    self:Open(PROGRESS_ONLY)
end

function Onboarding:NeedsAsking()
    return FC.db.languageGuidePending or not FC.db.onboarded or not FC.Progress:IsChosen()
end

--- New players get the welcome guide; everyone else who never answered the
--- progress question gets it alone. Never in the middle of a fight.
function Onboarding:OpenWhenReady()
    if not self:NeedsAsking() or (self.frame and self.frame:IsShown()) or FC.LanguagePicker:IsShown() then return end
    if InCombatLockdown() then
        FC.Events:Register("PLAYER_REGEN_ENABLED", self, function()
            FC.Events:Unregister("PLAYER_REGEN_ENABLED", self)
            U.After(2, function() self:OpenWhenReady() end)
        end)
        return
    end
    if FC.db.languageGuidePending or (not FC.db.onboarded and FC.db.languageChosen) then
        self:Open(FULL, true)
    elseif not FC.db.onboarded then self:Start()
    else self:AskProgress() end
end

--- A new character took the name of one the journal knew (the release wipes
--- the beta's characters): asked once, after the guide and out of combat,
--- whether it continues that character's journal or starts fresh. Closing
--- the question any other way continues it.
function Onboarding:AskIdentityWhenReady()
    local Characters = FC.Characters
    if not Characters:NeedsIdentityAnswer() then return end
    if self:NeedsAsking() or (self.frame and self.frame:IsShown()) or FC.LanguagePicker:IsShown() then
        U.After(10, function() self:AskIdentityWhenReady() end)
        return
    end
    if InCombatLockdown() then
        self.identityWaiter = self.identityWaiter or {}
        FC.Events:Register("PLAYER_REGEN_ENABLED", self.identityWaiter, function()
            FC.Events:Unregister("PLAYER_REGEN_ENABLED", self.identityWaiter)
            U.After(2, function() self:AskIdentityWhenReady() end)
        end)
        return
    end
    local name = U.ShortName(FC.Store.me)
    UI.Confirm(L.IDENTITY_TITLE, string.format(L.IDENTITY_TEXT, name, name), L.IDENTITY_FRESH, function()
        Characters:ResolveIdentity(true)
        FC:Print(L.MSG_IDENTITY_FRESH, name)
    end, true, L.IDENTITY_CONTINUE, function()
        Characters:ResolveIdentity(false)
        FC:Print(L.MSG_IDENTITY_CONTINUE, name)
    end)
end

function Onboarding:OnEnable()
    -- a new look (the palette in the journal, Settings) repaints the guide
    FC.Bus:On("THEME_CHANGED", self, function()
        if self.frame and self.frame:IsShown() then self:ApplyBanner() end
    end)
    if FC.Characters:NeedsIdentityAnswer() then
        U.After(6, function() self:AskIdentityWhenReady() end)
    end
    -- players who knew the addon before hear once where the flat themes went
    if FC.db.meta.lookNotice then
        U.After(8, function()
            FC.db.meta.lookNotice = nil
            FC:Print(L.MSG_LOOK_NOTICE)
        end)
    end
    if not self:NeedsAsking() then return end
    U.After(4, function() self:OpenWhenReady() end)
end
