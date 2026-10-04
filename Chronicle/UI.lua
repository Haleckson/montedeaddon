local C = _G.Chronicle
local U = C.Util
local BACKGROUND = "Interface\\Buttons\\WHITE8X8"
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local DIALOG_BACKGROUND = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DIALOG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local GOLD, TEXT, MUTED = { 1, .82, .1 }, { .96, .91, .78 }, { .72, .65, .52 }
local SURFACE = { .105, .071, .045 }
local HERO_SURFACE = { .16, .105, .052 }

local function setFont(fs, size, color)
    fs:SetFont(C:FontPath(), size or 12)
    fs:SetTextColor(unpack(color or TEXT))
end

local function backdrop(frame, red, green, blue, alpha)
    frame:SetBackdrop({ bgFile = BACKGROUND, edgeFile = BORDER, tile = false, edgeSize = 13, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    -- All sections share the same warm material; individual colors remain subtle tints.
    red, green, blue = red or SURFACE[1], green or SURFACE[2], blue or SURFACE[3]
    frame:SetBackdropColor(red * .72 + SURFACE[1] * .28,
        green * .72 + SURFACE[2] * .28,
        blue * .72 + SURFACE[3] * .28, alpha or .98)
    frame:SetBackdropBorderColor(.59, .44, .17, 1)
    if frame.chronicleActionStyle then
        local active = red > .14
        frame:SetBackdropColor(active and .22 or .09, active and .14 or .06, .035, .96)
        frame:SetBackdropBorderColor(.76, .56, .19, 1)
    end
end

function C:StyleChronicleButton(button, active)
    button.chronicleActionStyle = true
    button:SetBackdrop({ bgFile = BACKGROUND, edgeFile = BORDER, tile = false,
        edgeSize = 11, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    button:SetBackdropColor(active and .22 or .09, active and .14 or .06, .035, .96)
    button:SetBackdropBorderColor(.76, .56, .19, 1)
    if button.GetNormalTexture and button:GetNormalTexture() then button:GetNormalTexture():Hide() end
    if button.GetPushedTexture and button:GetPushedTexture() then button:GetPushedTexture():Hide() end
    if button.GetHighlightTexture and button:GetHighlightTexture() then button:GetHighlightTexture():Hide() end
    if button.GetDisabledTexture and button:GetDisabledTexture() then button:GetDisabledTexture():Hide() end
    local label = button.label or (button.GetFontString and button:GetFontString())
    if not label then
        label = button:CreateFontString(nil, "OVERLAY")
        label:SetPoint("CENTER")
        button:SetFontString(label)
    end
    label:SetFont(C:FontPath(), 11)
    label:SetTextColor(unpack(GOLD))
    if not button.chronicleActionHover then
        button:HookScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, .82, .29, 1)
        end)
        button:HookScript("OnLeave", function(self)
            self:SetBackdropBorderColor(.76, .56, .19, 1)
        end)
        button.chronicleActionHover = true
    end
end

function C:OrnateCorners(frame)
    if frame.chronicleCorners then
        for _, mark in ipairs(frame.chronicleCorners) do mark:Show() end
        return
    end
    frame.chronicleCorners = {}
    local corners = {
        { "TOPLEFT", 9, -9, 11, 1 }, { "TOPLEFT", 9, -9, 1, 11 },
        { "TOPRIGHT", -9, -9, 11, 1 }, { "TOPRIGHT", -9, -9, 1, 11 },
        { "BOTTOMLEFT", 9, 9, 11, 1 }, { "BOTTOMLEFT", 9, 9, 1, 11 },
        { "BOTTOMRIGHT", -9, 9, 11, 1 }, { "BOTTOMRIGHT", -9, 9, 1, 11 },
    }
    for _, corner in ipairs(corners) do
        local mark = frame:CreateTexture(nil, "ARTWORK")
        mark:SetTexture(BACKGROUND)
        mark:SetVertexColor(.78, .54, .19, .8)
        mark:SetSize(corner[4], corner[5])
        mark:SetPoint(corner[1], corner[2], corner[3])
        frame.chronicleCorners[#frame.chronicleCorners + 1] = mark
    end
end

function C:ApplyMaterial(frame, alpha)
    if not frame.chronicleMaterial then
        local texture = frame:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\AddOns\\Chronicle\\JournalSurface")
        texture:SetPoint("TOPLEFT", 4, -4)
        texture:SetPoint("BOTTOMRIGHT", -4, 4)
        texture:SetVertexColor(.6, .55, .48)
        frame.chronicleMaterial = texture
    end
    frame.chronicleMaterial:SetAlpha(alpha or .25)
    frame.chronicleMaterial:Show()
end

local function openSurface(frame)
    frame:SetBackdrop(nil)
    if frame.chronicleMaterial then frame.chronicleMaterial:Hide() end
    if frame.chronicleCorners then
        for _, mark in ipairs(frame.chronicleCorners) do mark:Hide() end
    end
end

local function heroBackdrop(frame)
    backdrop(frame, HERO_SURFACE[1], HERO_SURFACE[2], HERO_SURFACE[3], 1)
    C:ApplyMaterial(frame, .32)
    C:OrnateCorners(frame)
end

function C:SetHeroMotif(frame, motifName, alpha)
    if not frame.motifClip then
        frame.motifClip = CreateFrame("Frame", nil, frame)
        frame.motifClip:SetClipsChildren(true)
        frame.motif = frame.motifClip:CreateTexture(nil, "ARTWORK")
        frame.motif:SetPoint("CENTER", frame.motifClip, "CENTER", 0, -1)
    end
    local clipHeight = math.min(104, math.max(44, (frame:GetHeight() or 92) - 12))
    frame.motifClip:ClearAllPoints()
    frame.motifClip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    frame.motifClip:SetSize(math.min(142, clipHeight + 24), clipHeight)
    frame.motif:SetSize(clipHeight + 28, clipHeight + 28)
    frame.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_" .. motifName)
    frame.motif:SetAlpha(alpha or .42)
    frame.motifClip:Show()
end

local window = CreateFrame("Frame", "ChronicleMainFrame", UIParent, "BackdropTemplate")
C.frame = window
window:SetSize(960, 650); window:SetPoint("CENTER"); window:SetFrameStrata("HIGH"); window:SetClampedToScreen(true)
window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
window:SetResizable(true)
if window.SetResizeBounds then window:SetResizeBounds(920, 600, 1500, 950)
elseif window.SetMinResize and window.SetMaxResize then
    window:SetMinResize(920, 600); window:SetMaxResize(1500, 950)
end
window:SetScript("OnDragStart", function(self) if not C.API.IsInCombat() then self:StartMoving() end end)
window:SetScript("OnDragStop", window.StopMovingOrSizing)
window:SetBackdrop({ bgFile = DIALOG_BACKGROUND, edgeFile = DIALOG_BORDER, tile = true,
    tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
window:SetBackdropColor(.32, .25, .17, 1)
window:SetBackdropBorderColor(.82, .73, .52, 1)
window:Hide()
if UISpecialFrames then table.insert(UISpecialFrames, "ChronicleMainFrame") end

local resizeHandles = {}
local function createResizeHandle(direction, point, relativePoint, x, y, width, height)
    local handle = CreateFrame("Button", nil, window)
    handle:SetPoint(point, window, relativePoint, x or 0, y or 0)
    handle:SetSize(width, height); handle:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    handle:SetFrameLevel(window:GetFrameLevel() + 20)
    handle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not C.API.IsInCombat() then window:StartSizing(direction) end
    end)
    handle:SetScript("OnMouseUp", function()
        window:StopMovingOrSizing()
        if C.db and C.db.settings then
            C.db.settings.windowWidth = math.floor(window:GetWidth() + .5)
            C.db.settings.windowHeight = math.floor(window:GetHeight() + .5)
        end
        if C.Refresh then C:Refresh() end
    end)
    resizeHandles[#resizeHandles + 1] = handle
    return handle
end
local topResize = createResizeHandle("TOP", "TOPLEFT", "TOPLEFT", 18, 2, 924, 8)
topResize:SetPoint("TOPRIGHT", window, "TOPRIGHT", -18, 2)
local bottomResize = createResizeHandle("BOTTOM", "BOTTOMLEFT", "BOTTOMLEFT", 18, -2, 924, 8)
bottomResize:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -18, -2)
local leftResize = createResizeHandle("LEFT", "TOPLEFT", "TOPLEFT", -2, -18, 8, 614)
leftResize:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", -2, 18)
local rightResize = createResizeHandle("RIGHT", "TOPRIGHT", "TOPRIGHT", 2, -18, 8, 614)
rightResize:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 2, 18)
createResizeHandle("TOPLEFT", "TOPLEFT", "TOPLEFT", -2, 2, 18, 18)
createResizeHandle("TOPRIGHT", "TOPRIGHT", "TOPRIGHT", 2, 2, 18, 18)
createResizeHandle("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMLEFT", -2, -2, 18, 18)
local resizeGrip = createResizeHandle("BOTTOMRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, -1, 22, 22)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

local headerPanel = CreateFrame("Frame", nil, window, "BackdropTemplate")
headerPanel:SetPoint("TOPLEFT", 17, -17); headerPanel:SetPoint("TOPRIGHT", -17, -17)
headerPanel:SetHeight(71)
backdrop(headerPanel, .16, .105, .045, 1)
C:ApplyMaterial(headerPanel, .28)
C:OrnateCorners(headerPanel)

local lotus = headerPanel:CreateTexture(nil, "ARTWORK")
lotus:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
lotus:SetSize(66, 66); lotus:SetPoint("TOPLEFT", 7, 0)
local title = headerPanel:CreateFontString(nil, "OVERLAY")
title:SetPoint("TOPLEFT", 81, -10); setFont(title, 24, GOLD); title:SetText(C.displayName)
local subtitle = headerPanel:CreateFontString(nil, "OVERLAY")
subtitle:SetPoint("TOPLEFT", 82, -42); setFont(subtitle, 10, MUTED)
subtitle:SetText("VERSION " .. C.version .. "  |  " .. C:L("subtitle"))
local close = CreateFrame("Button", nil, window, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -9, -9)
close:SetFrameLevel(headerPanel:GetFrameLevel() + 1)

local search = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
search:SetSize(235, 25); search:SetPoint("TOPRIGHT", -52, -33); search:SetAutoFocus(false); search:SetMaxLetters(80)
search:SetFrameLevel(headerPanel:GetFrameLevel() + 1)
if search.SetTextInsets then search:SetTextInsets(23, 5, 0, 0) end
search:SetScript("OnEscapePressed", search.ClearFocus)
local searchIcon = search:CreateTexture(nil, "ARTWORK")
searchIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
searchIcon:SetSize(14, 14); searchIcon:SetPoint("LEFT", 7, 0)
searchIcon:SetTexCoord(.1, .9, .1, .9); searchIcon:SetAlpha(.75)
local searchHint = search:CreateFontString(nil, "ARTWORK"); searchHint:SetPoint("LEFT", 24, 0); setFont(searchHint, 11, MUTED); searchHint:SetText(C:L("search"))
search:SetScript("OnTextChanged", function(self) searchHint:SetShown(self:GetText() == "") end)

do
local languageButton = CreateFrame("Button", nil, window, "BackdropTemplate")
C:StyleChronicleButton(languageButton)
languageButton:SetPoint("RIGHT", search, "LEFT", -9, 0)
languageButton:SetSize(129, 27)
languageButton.flag = languageButton:CreateTexture(nil, "ARTWORK")
languageButton.flag:SetSize(29, 29)
languageButton.flag:SetPoint("LEFT", 5, 0)
local languageButtonLabel = languageButton:GetFontString()
languageButtonLabel:ClearAllPoints()
languageButtonLabel:SetPoint("LEFT", languageButton, "LEFT", 38, 0)
languageButtonLabel:SetJustifyH("LEFT")
local languageMenu = CreateFrame("Frame", nil, languageButton, "BackdropTemplate")
languageMenu:SetPoint("TOPRIGHT", languageButton, "BOTTOMRIGHT", 0, -4)
languageMenu:SetSize(153, #C.languages * 27 + 8)
languageMenu:SetFrameStrata("DIALOG")
languageMenu:SetFrameLevel(window:GetFrameLevel() + 30)
backdrop(languageMenu, .105, .073, .044, 1)
languageMenu:Hide()
local function updateLanguageButton()
    local current = C:FlagCode(C:GetLanguage())
    languageButton.flag:SetTexture("Interface\\AddOns\\Chronicle\\Flag_" .. current)
    for _, language in ipairs(C.languages) do
        if language.code == current then languageButton:SetText(language.name .. "  v"); return end
    end
    languageButton:SetText(C:L("language") .. "  v")
end
languageButton:SetScript("OnClick", function()
    languageMenu:SetShown(not languageMenu:IsShown())
end)
languageButton:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(C:L("language"))
    GameTooltip:AddLine(C:L("gameLanguageNotice"), .85, .79, .66, true)
    -- WoW's tooltip font does not necessarily match the selected addon language.
    if GameTooltipTextLeft1 then GameTooltipTextLeft1:SetFont(C:FontPath(), 12) end
    if GameTooltipTextLeft2 then GameTooltipTextLeft2:SetFont(C:FontPath(), 11) end
    C:ShowLocalizedTooltip()
end)
languageButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
for index, language in ipairs(C.languages) do
    local option = CreateFrame("Button", nil, languageMenu)
    option:SetSize(145, 26)
    option:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 27)
    option:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    option.flag = option:CreateTexture(nil, "ARTWORK")
    option.flag:SetTexture("Interface\\AddOns\\Chronicle\\Flag_" .. language.code)
    option.flag:SetSize(29, 29)
    option.flag:SetPoint("LEFT", 3, 0)
    option.label = option:CreateFontString(nil, "OVERLAY")
    option.label:SetPoint("LEFT", 38, 0)
    setFont(option.label, 11, TEXT)
    if language.code == "ruRU" then option.label:SetFont("Fonts\\FRIZQT___CYR.TTF", 11) end
    option.label:SetText(language.name)
    option:SetScript("OnClick", function()
        C:SetLanguage(language.code)
        languageMenu:Hide()
    end)
end
updateLanguageButton()
C.UpdateLanguageButton = updateLanguageButton
end

local sidebar = CreateFrame("Frame", nil, window, "BackdropTemplate")
sidebar:SetPoint("TOPLEFT", 18, -88); sidebar:SetPoint("BOTTOMLEFT", 18, 18); sidebar:SetWidth(190); backdrop(sidebar, .105, .073, .044, 1)
C:ApplyMaterial(sidebar, .2)
sidebar.scroll = CreateFrame("ScrollFrame", nil, sidebar)
sidebar.scroll:SetPoint("TOPLEFT", 3, -4); sidebar.scroll:SetPoint("BOTTOMRIGHT", -3, 4)
sidebar.content = CreateFrame("Frame", nil, sidebar.scroll)
sidebar.content:SetSize(184, 1); sidebar.scroll:SetScrollChild(sidebar.content)
sidebar.scroll:EnableMouseWheel(true)
sidebar.scroll:SetScript("OnMouseWheel", function(self, delta)
    local maximum = math.max(0, sidebar.content:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 58)))
end)
local content = CreateFrame("Frame", nil, window, "BackdropTemplate")
content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0); content:SetPoint("BOTTOMRIGHT", -18, 18); backdrop(content, .16, .105, .045, 1)
C:ApplyMaterial(content, .28)

local contentTopWash = content:CreateTexture(nil, "BORDER")
contentTopWash:SetTexture(BACKGROUND); contentTopWash:SetVertexColor(.29, .17, .075, 0)
contentTopWash:SetPoint("TOPLEFT", 4, -4); contentTopWash:SetPoint("TOPRIGHT", -4, -4)
contentTopWash:SetHeight(108)
local contentBottomRule = content:CreateTexture(nil, "BORDER")
contentBottomRule:SetTexture(BACKGROUND); contentBottomRule:SetVertexColor(.42, .29, .13, .45)
contentBottomRule:SetPoint("BOTTOMLEFT", 18, 13); contentBottomRule:SetPoint("BOTTOMRIGHT", -18, 13)
contentBottomRule:SetHeight(1)

local titleRule = content:CreateTexture(nil, "ARTWORK")
titleRule:SetTexture(BACKGROUND); titleRule:SetVertexColor(.47, .34, .13, .9)
titleRule:SetPoint("TOPLEFT", 19, -42); titleRule:SetPoint("TOPRIGHT", -19, -42); titleRule:SetHeight(1)

local pageTitle = content:CreateFontString(nil, "OVERLAY"); pageTitle:SetPoint("TOPLEFT", 20, -16); setFont(pageTitle, 20, GOLD)
local backButton = CreateFrame("Button", nil, content, "BackdropTemplate")
C:StyleChronicleButton(backButton)
backButton:SetPoint("TOPRIGHT", -42, -11); backButton:SetSize(82, 23); backButton:SetText(C:L("back")); backButton:Hide()
local moneyToggle = CreateFrame("Button", nil, content, "BackdropTemplate")
C:StyleChronicleButton(moneyToggle)
moneyToggle:SetPoint("TOPRIGHT", -42, -11); moneyToggle:SetSize(165, 23); moneyToggle:Hide()
local scroll = CreateFrame("ScrollFrame", "ChronicleContentScrollFrame", content, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 18, -49); scroll:SetPoint("BOTTOMRIGHT", -29, 52)
local scrollChild = CreateFrame("Frame", nil, scroll); scrollChild:SetSize(680, 1); scroll:SetScrollChild(scrollChild)
local pageMotif = content:CreateTexture(nil, "BORDER", nil, 1)
pageMotif:SetSize(330, 330)
pageMotif:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -38, 38)
pageMotif:SetVertexColor(1, 1, 1)
pageMotif:SetAlpha(.1)
local motifArt = {
    overview = "Overview", goals = "Goals", timeline = "Timeline", quests = "Quests",
    gathering = "Professions", training = "Alts",
    zones = "Zones", npcs = "NPCs", dungeons = "Dungeons", attunements = "Dungeons", loot = "Loot",
    professions = "Professions", alts = "Alts", inventory = "Inventory",
    economy = "Economy", deaths = "Deaths", notes = "Notes", stats = "Stats",
}
local body = scrollChild:CreateFontString(nil, "ARTWORK"); body:SetPoint("TOPLEFT", 4, 0); body:SetWidth(630); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); setFont(body, 13, TEXT)
local availableContentWidth
local simpleEmpty
local function showSimpleEmpty(titleText, detailText, iconPath, motifName)
    if not simpleEmpty then
        simpleEmpty = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        simpleEmpty:SetPoint("TOPLEFT", 4, 0)
        simpleEmpty.motif = simpleEmpty:CreateTexture(nil, "ARTWORK")
        simpleEmpty.motif:SetSize(270, 270); simpleEmpty.motif:SetPoint("BOTTOMRIGHT", -12, 8)
        simpleEmpty.motif:SetAlpha(.2)
        simpleEmpty.icon = simpleEmpty:CreateTexture(nil, "ARTWORK")
        simpleEmpty.icon:SetSize(56, 56)
        simpleEmpty.leftFlourish = simpleEmpty:CreateTexture(nil, "ARTWORK")
        simpleEmpty.rightFlourish = simpleEmpty:CreateTexture(nil, "ARTWORK")
        for _, flourish in ipairs({ simpleEmpty.leftFlourish, simpleEmpty.rightFlourish }) do
            flourish:SetTexture(BACKGROUND)
            flourish:SetVertexColor(.62, .4, .16, .75)
            flourish:SetSize(100, 1)
        end
        simpleEmpty.title = simpleEmpty:CreateFontString(nil, "OVERLAY")
        setFont(simpleEmpty.title, 20, TEXT); simpleEmpty.title:SetJustifyH("CENTER")
        simpleEmpty.detail = simpleEmpty:CreateFontString(nil, "OVERLAY")
        setFont(simpleEmpty.detail, 12, MUTED); simpleEmpty.detail:SetJustifyH("CENTER")
    end
    local width = availableContentWidth()
    simpleEmpty:ClearAllPoints(); simpleEmpty:SetPoint("TOPLEFT", 4, -132)
    simpleEmpty:SetWidth(width)
    simpleEmpty:SetHeight(math.max(220, math.min(500, (scroll:GetHeight() or 450) - 140)))
    backdrop(simpleEmpty, .12, .075, .046, .98)
    C:ApplyMaterial(simpleEmpty, .27)
    C:OrnateCorners(simpleEmpty)
    pageMotif:Hide()
    simpleEmpty.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_" .. motifName)
    simpleEmpty.icon:SetTexture(iconPath)
    local center = math.floor((width - 215) / 2) + 7
    local verticalOffset = math.max(0, math.floor((simpleEmpty:GetHeight() - 250) / 2))
    local ornateMedallion = motifName == "Notes" or motifName == "Goals"
    simpleEmpty.icon:SetSize(ornateMedallion and 94 or 56, ornateMedallion and 94 or 56)
    simpleEmpty.icon:ClearAllPoints(); simpleEmpty.icon:SetPoint("TOP", simpleEmpty, "TOPLEFT", center,
        (ornateMedallion and -35 or -41) - verticalOffset)
    simpleEmpty.leftFlourish:SetShown(ornateMedallion)
    simpleEmpty.rightFlourish:SetShown(ornateMedallion)
    if ornateMedallion then
        simpleEmpty.leftFlourish:ClearAllPoints()
        simpleEmpty.leftFlourish:SetPoint("TOPLEFT", simpleEmpty, "TOPLEFT", center - 166, -81 - verticalOffset)
        simpleEmpty.rightFlourish:ClearAllPoints()
        simpleEmpty.rightFlourish:SetPoint("TOPLEFT", simpleEmpty, "TOPLEFT", center + 66, -81 - verticalOffset)
    end
    simpleEmpty.title:ClearAllPoints(); simpleEmpty.title:SetPoint("TOP", simpleEmpty, "TOPLEFT", center,
        (ornateMedallion and -148 or -112) - verticalOffset)
    simpleEmpty.title:SetWidth(width - 220); simpleEmpty.title:SetText(C:LocalizeDisplay(titleText))
    simpleEmpty.detail:ClearAllPoints(); simpleEmpty.detail:SetPoint("TOP", simpleEmpty, "TOPLEFT", center,
        (ornateMedallion and -193 or -151) - verticalOffset)
    simpleEmpty.detail:SetWidth(width - 235); simpleEmpty.detail:SetText(C:LocalizeDisplay(detailText))
    simpleEmpty:Show(); body:Hide()
    scrollChild:SetHeight(132 + simpleEmpty:GetHeight() + 12)
end
availableContentWidth = function()
    return math.max(630, math.floor((scroll:GetWidth() or 650) - 18))
end
local function updateContentWidth()
    local width = availableContentWidth()
    scrollChild:SetWidth(width + 8); body:SetWidth(width)
    return width
end

local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
input:SetPoint("BOTTOMLEFT", 21, 17); input:SetSize(500, 27); input:SetAutoFocus(false); input:SetMaxLetters(240)
local action = CreateFrame("Button", nil, content, "BackdropTemplate"); action:SetPoint("LEFT", input, "RIGHT", 7, 0); action:SetSize(105, 25)
C:StyleChronicleButton(action)
local cancelEdit = CreateFrame("Button", nil, content, "BackdropTemplate")
C:StyleChronicleButton(cancelEdit)
cancelEdit:SetPoint("LEFT", action, "RIGHT", 5, 0); cancelEdit:SetSize(68, 25); cancelEdit:SetText(C:L("cancel")); cancelEdit:Hide()

local pages = {
    { key = "overview", label = "Wo war ich?", group = "REISE", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "goals", label = "Ziele", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath" },
    { key = "timeline", label = "Abenteuer", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "quests", label = "Quests", icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { key = "zones", label = "Gebiete", icon = "Interface\\Icons\\Spell_Nature_EarthBind" },
    { key = "npcs", label = "NPC & Händler", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
    { key = "dungeons", label = "Dungeons & Bosse", icon = "Interface\\Icons\\INV_Misc_Key_03" },
    { key = "gathering", label = "Sammeln", group = "WISSEN", icon = "Interface\\Icons\\INV_Misc_Herb_01" },
    { key = "training", label = "Trainer", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "teachers", label = "Lehrerorte", icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { key = "weapons", label = "Waffenfertigkeiten", icon = "Interface\\Icons\\INV_Sword_04" },
    { key = "dungeonknowledge", label = "Instanzwissen", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "raidknowledge", label = "Raidwissen", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { key = "attunements", label = "Zugangswege", icon = "Interface\\AddOns\\Chronicle\\KeyMedallion" },
    { key = "loot", label = "Beute & Rares", group = "SAMMLUNG", icon = "Interface\\Icons\\INV_Box_01" },
    { key = "professions", label = "Berufe & Rezepte", icon = "Interface\\Icons\\Trade_LeatherWorking" },
    { key = "alts", label = "Charaktere", group = "CHARAKTER", icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01" },
    { key = "inventory", label = "Inventar & Bank", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { key = "economy", label = "Gold & Wirtschaft", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
    { key = "deaths", label = "Death Journal", icon = "Interface\\AddOns\\Chronicle\\DeathMedallion" },
    { key = "notes", label = "Notizen", icon = "Interface\\Icons\\INV_Misc_Note_05" },
    { key = "stats", label = "Statistiken", icon = "Interface\\Icons\\Achievement_General" },
}
local buttons, quickTabs, goalRows, noteRows, altRows, inventoryRows, selected, editingNote = {}, {}, {}, {}, {}, {}, "overview", nil
local chapterHero
local inventoryFilters, inventoryFilter = {}, "all"
local economyHero, economyIntro, economyDayRows, economyEntryRows = nil, nil, {}, {}
C.economyExpandedGroups = C.economyExpandedGroups or {}
local statsHero, statsHeaders, statsCards = nil, {}, {}
local professionHero, professionCards, professionHeaders, recipeCards = nil, {}, {}, {}
local latestRecipeHeader, latestRecipeCards = nil, {}
local lootHero, lootRows, rareHeader, rareRows = nil, {}, nil, {}
local lootFilters, lootFilter, lootSearch, lootSearchHint = {}, "all", nil, nil
local overviewHero, overviewStats, overviewHeaders, overviewGoals, overviewEvents = nil, {}, {}, {}, {}
local timelineHero, timelineFilters, timelineDays, timelineCards, timelineMore, timelineEmpty = nil, {}, {}, {}, nil, nil
local timelineFilter, timelineLimit = "all", 100
local timelineExpanded = {}
local questHero, questSearch, questSearchHint, questHeaders = nil, nil, nil, {}
local questCards, questTabs, questView = {}, {}, "active"
local questZoneHeaders = {}
local questZoneExpanded = {}
local questHistoryButtons, questHistoryFilter = {}, "all"
local questReadyButton, questReadyFilter = nil, false
local zoneHero, zoneSearch, zoneSearchHint, zoneCards = nil, nil, nil, {}
local zoneSortButtons, zoneSort = {}, "recent"
local zoneEmpty = nil
local npcHero, npcSearch, npcSearchHint, npcCards, npcEmpty, npcMore = nil, nil, nil, {}, nil, nil
local npcTabs, npcTab, npcSort = {}, "all", "recent"
local npcSortButtons = {}
local npcLimit = 80
local dungeonHero, dungeonSearch, dungeonSearchHint, dungeonCards, dungeonEmpty = nil, nil, nil, {}, nil
local dungeonTabs, dungeonTab = {}, "instances"
local deathHero, deathStats, deathCards, deathEmpty = nil, {}, {}, nil
local selectedAltKey, renderAltDetail, showAltDetail, selectedDetailTab = nil, nil, nil, "profile"
local detailHero, detailTabs, detailHeaders, detailCards = nil, {}, {}, {}
detailCards.memories = {}

function C:CharacterDisplayName(character, fallback)
    local name = U.SafeText(character.name, fallback)
    local surname = U.Trim(character.surname)
    return surname ~= "" and (name .. " " .. surname) or name
end

local function hideGoalRows()
    for _, row in ipairs(goalRows) do row:Hide() end
end

local function hideNoteRows()
    for _, row in ipairs(noteRows) do row:Hide() end
end

local function hideAltRows()
    for _, row in ipairs(altRows) do row:Hide() end
end

local function hideAltDetail()
    if detailHero then detailHero:Hide() end
    if detailHero and detailHero.surnameEditor then detailHero.surnameEditor:Hide() end
    if detailHero and detailHero.surnameSave then detailHero.surnameSave:Hide() end
    for _, widget in ipairs(detailTabs) do widget:Hide() end
    for _, widget in ipairs(detailHeaders) do widget:Hide() end
    for _, widget in ipairs(detailCards) do widget:Hide() end
    for _, widget in ipairs(detailCards.memories) do widget:Hide() end
end

local function hideInventoryRows()
    for _, row in ipairs(inventoryRows) do row:Hide() end
    for _, row in ipairs(inventoryFilters.groupRows or {}) do row:Hide() end
    for _, button in ipairs(inventoryFilters) do button:Hide() end
    for _, tile in ipairs(inventoryFilters.overview or {}) do tile:Hide() end
    if inventoryFilters.detail then inventoryFilters.detail:Hide() end
    if inventoryFilters.highlight then inventoryFilters.highlight:Hide() end
end

local function hideEconomyRows()
    if economyHero then economyHero:Hide() end
    if economyIntro then economyIntro:Hide() end
    if economyHero and economyHero.detailPanel then economyHero.detailPanel:Hide() end
    for _, row in ipairs(economyDayRows) do row:Hide() end
    for _, row in ipairs(economyEntryRows) do row:Hide() end
end

local function hideStatsRows()
    if statsHero then statsHero:Hide() end
    for _, row in ipairs(statsHeaders) do row:Hide() end
    for _, row in ipairs(statsCards) do row:Hide() end
end

local function hideProfessionRows()
    if professionHero then professionHero:Hide() end
    for _, row in ipairs(professionCards) do row:Hide() end
    for _, row in ipairs(professionHeaders) do row:Hide() end
    if professionHeaders.empty then professionHeaders.empty:Hide() end
    if professionHeaders.dossier then professionHeaders.dossier:Hide() end
    for _, row in ipairs(recipeCards) do row:Hide() end
    if latestRecipeHeader then latestRecipeHeader:Hide() end
    for _, row in ipairs(latestRecipeCards) do row:Hide() end
end

local function hideLootRows()
    if lootHero then lootHero:Hide() end
    if lootHero and lootHero.emptyGallery then
        for _, panel in ipairs(lootHero.emptyGallery) do panel:Hide() end
    end
    if rareHeader then rareHeader:Hide() end
    for _, row in ipairs(lootRows) do row:Hide() end
    for _, row in ipairs(rareRows) do row:Hide() end
    for _, button in ipairs(lootFilters) do button:Hide() end
    if lootSearch then lootSearch:Hide() end
end

local function hideOverviewRows()
    if overviewHero then
        overviewHero:Hide()
        for _, dot in ipairs(overviewHero.routeDots or {}) do dot:Hide() end
    end
    for _, widget in ipairs(overviewStats) do widget:Hide() end
    for _, widget in ipairs(overviewHeaders) do widget:Hide() end
    for _, widget in ipairs(overviewGoals) do widget:Hide() end
    for _, widget in ipairs(overviewEvents) do widget:Hide() end
end

local function hideTimelineRows()
    if timelineHero then
        timelineHero:Hide()
        if timelineHero.dossier then timelineHero.dossier:Hide() end
    end
    if timelineMore then timelineMore:Hide() end
    if timelineEmpty then timelineEmpty:Hide() end
    for _, widget in ipairs(timelineFilters) do widget:Hide() end
    for _, widget in ipairs(timelineDays) do widget:Hide() end
    for _, widget in ipairs(timelineCards) do widget:Hide() end
end

local function hideQuestRows()
    if questHero then questHero:Hide() end
    if questHero and questHero.dossier then questHero.dossier:Hide() end
    if questSearch then questSearch:Hide() end
    if questReadyButton then questReadyButton:Hide() end
    for _, widget in ipairs(questHeaders) do widget:Hide() end
    for _, widget in ipairs(questZoneHeaders) do widget:Hide() end
    for _, widget in ipairs(questHistoryButtons) do widget:Hide() end
    for _, widget in ipairs(questCards) do widget:Hide() end
    for _, widget in ipairs(questTabs) do widget:Hide() end
end

local function hideZoneRows()
    if zoneHero then zoneHero:Hide() end
    if zoneSearch then zoneSearch:Hide() end
    if zoneEmpty then zoneEmpty:Hide() end
    for _, widget in ipairs(zoneCards) do widget:Hide() end
    for _, widget in ipairs(zoneSortButtons) do widget:Hide() end
end

local function hideNPCRows()
    if npcHero then npcHero:Hide() end
    if npcHero and npcHero.profile then npcHero.profile:Hide() end
    if npcSearch then npcSearch:Hide() end
    if npcEmpty then npcEmpty:Hide() end
    if npcMore then npcMore:Hide() end
    if npcHero and npcHero.sectionHeader then npcHero.sectionHeader:Hide() end
    if npcHero and npcHero.sectionCount then npcHero.sectionCount:Hide() end
    for _, widget in ipairs(npcCards) do widget:Hide() end
    for _, widget in ipairs(npcTabs) do widget:Hide() end
    for _, widget in ipairs(npcSortButtons) do widget:Hide() end
end

local function hideDungeonRows()
    if dungeonHero then dungeonHero:Hide() end
    if dungeonHero and dungeonHero.bossChapter then dungeonHero.bossChapter:Hide() end
    if dungeonHero and dungeonHero.bossListHeader then dungeonHero.bossListHeader:Hide() end
    if dungeonSearch then dungeonSearch:Hide() end
    if dungeonEmpty then dungeonEmpty:Hide() end
    for _, widget in ipairs(dungeonCards) do widget:Hide() end
    for _, widget in ipairs(dungeonTabs) do widget:Hide() end
end

local function hideDeathRows()
    if deathHero then deathHero:Hide() end
    if deathHero and deathHero.section then deathHero.section:Hide() end
    if deathHero and deathHero.memorial then deathHero.memorial:Hide() end
    if deathHero and deathHero.dayHeaders then
        for _, heading in ipairs(deathHero.dayHeaders) do heading:Hide() end
    end
    if deathEmpty then deathEmpty:Hide() end
    for _, widget in ipairs(deathStats) do widget:Hide() end
    for _, widget in ipairs(deathCards) do widget:Hide() end
end

local function talentLabel(character)
    local talent = type(character.talents) == "table" and character.talents or nil
    if not talent then return C:LocalizeDisplay("nicht erfasst") end
    if type(talent.branches) == "table" and #talent.branches == 3 then
        local first, second, third = talent.branches[1], talent.branches[2], talent.branches[3]
        local counts = tostring(first.points or 0) .. "/" .. tostring(second.points or 0) .. "/" .. tostring(third.points or 0)
        local maximum = math.max(first.points or 0, second.points or 0, third.points or 0)
        local leaders = 0
        for _, branch in ipairs(talent.branches) do if branch.points == maximum then leaders = leaders + 1 end end
        local name = maximum == 0 and C:LocalizeDisplay("Keine Talente") or leaders > 1 and C:LocalizeDisplay("Hybrid") or
            ((first.points == maximum and first.name) or (second.points == maximum and second.name) or third.name)
        return C:LocalizeDisplay(name) .. " " .. counts
    end
    local total = tonumber(talent.totalPoints)
    if talent.traitsRead and total then
        return total > 0 and (total .. C:LocalizeDisplay(" Talentpunkte")) or C:LocalizeDisplay("Noch keine Talentpunkte")
    end
    if type(talent.loadout) == "string" and talent.loadout ~= "" and talent.loadout ~= character.className then
        return talent.loadout
    end
    if type(talent.name) == "string" and talent.name ~= "" and
        talent.name ~= character.className and talent.name ~= character.class then return talent.name end
    return C:LocalizeDisplay("Talentdaten nicht erfasst")
end

local function talentBranchText(character)
    local talent = type(character.talents) == "table" and character.talents or nil
    if not talent or type(talent.branches) ~= "table" or #talent.branches ~= 3 then return C:LocalizeDisplay("Zweige: nicht erfasst") end
    local parts = {}
    for _, branch in ipairs(talent.branches) do
        parts[#parts + 1] = C:LocalizeDisplay(U.SafeText(branch.name)) .. " " .. tostring(branch.points or 0)
    end
    return C:LocalizeDisplay("Zweige: ") .. table.concat(parts, "  |  ")
end

local function showChapterHero(caption, titleText, detailText, statsText, iconPath, accentColor)
    if not chapterHero then
        chapterHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        chapterHero:SetHeight(112)
        chapterHero.accent = chapterHero:CreateTexture(nil, "ARTWORK"); chapterHero.accent:Hide()
        chapterHero.accent:SetTexture(BACKGROUND)
        chapterHero.accent:SetPoint("TOPLEFT", 4, -4)
        chapterHero.accent:SetPoint("BOTTOMLEFT", 4, 4); chapterHero.accent:SetWidth(4)
        chapterHero.caption = chapterHero:CreateFontString(nil, "OVERLAY")
        chapterHero.caption:SetPoint("TOPLEFT", 20, -12); setFont(chapterHero.caption, 10, GOLD)
        chapterHero.title = chapterHero:CreateFontString(nil, "OVERLAY")
        chapterHero.title:SetPoint("TOPLEFT", 19, -32); setFont(chapterHero.title, 23, TEXT)
        chapterHero.detail = chapterHero:CreateFontString(nil, "OVERLAY")
        chapterHero.detail:SetPoint("TOPLEFT", 20, -63); setFont(chapterHero.detail, 10, MUTED)
        chapterHero.rule = chapterHero:CreateTexture(nil, "ARTWORK")
        chapterHero.rule:SetTexture(BACKGROUND)
        chapterHero.rule:SetPoint("TOPLEFT", 19, -82)
        chapterHero.rule:SetPoint("TOPRIGHT", -106, -82); chapterHero.rule:SetHeight(1)
        chapterHero.stats = chapterHero:CreateFontString(nil, "OVERLAY")
        chapterHero.stats:SetPoint("TOPLEFT", 20, -91); setFont(chapterHero.stats, 11, GOLD)
        chapterHero.icon = chapterHero:CreateTexture(nil, "ARTWORK")
        chapterHero.icon:SetSize(50, 50); chapterHero.icon:SetPoint("TOPRIGHT", -26, -18)
    end
    chapterHero:ClearAllPoints(); chapterHero:SetPoint("TOPLEFT", 4, 0)
    chapterHero:SetWidth(availableContentWidth()); heroBackdrop(chapterHero)
    local motifName = caption:find("NOTIZEN") and "Notes" or
        (caption:find("ZIELE") and "Goals" or
        (caption:find("CHARAKTERE") and "Alts" or "Inventory"))
    C:SetHeroMotif(chapterHero, motifName)
    chapterHero.accent:SetVertexColor(accentColor[1], accentColor[2], accentColor[3])
    chapterHero.rule:SetVertexColor(accentColor[1], accentColor[2], accentColor[3], .75)
    chapterHero.caption:SetText(C:LocalizeDisplay(caption)); chapterHero.title:SetText(C:LocalizeDisplay(titleText))
    chapterHero.detail:SetText(C:LocalizeDisplay(detailText)); chapterHero.stats:SetText(C:LocalizeDisplay(statsText))
    chapterHero.icon:Hide()
    chapterHero:EnableMouse(false)
    chapterHero:SetScript("OnEnter", nil); chapterHero:SetScript("OnLeave", nil)
    chapterHero:Show(); body:Hide()
end

local function showNoteRows()
    local width = availableContentWidth()
    local notes = C.char.notes
    showChapterHero("CHRONICLE  /  NOTIZEN", "Deine Gedanken",
        "Persönliche Erinnerungen und Pläne", #notes .. C:LocalizeDisplay(" NOTIZEN"),
        "Interface\\AddOns\\Chronicle\\NotesMedallion", { .8, .6, .23 })
    if #notes == 0 then
        showSimpleEmpty("Noch keine Notizen", "Schreibe unten deine erste Erinnerung auf.",
            "Interface\\AddOns\\Chronicle\\NotesMedallion", "Notes")
        return
    end
    body:Hide()
    for i, note in ipairs(notes) do
        local row = noteRows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetSize(630, 104); row:SetPoint("TOPLEFT", 4, -132 - (i - 1) * 108)
            openSurface(row)
            row.accent = row:CreateTexture(nil, "ARTWORK"); row.accent:Hide()
            row.accent:SetTexture(BACKGROUND); row.accent:SetVertexColor(.8, .6, .23)
            row.accent:SetPoint("TOPLEFT", 4, -4); row.accent:SetPoint("BOTTOMLEFT", 4, 4)
            row.accent:SetWidth(3)
            row.caption = row:CreateFontString(nil, "OVERLAY")
            row.caption:SetPoint("TOPLEFT", 10, -9); setFont(row.caption, 11, GOLD)
            row.text = row:CreateFontString(nil, "OVERLAY")
            row.text:SetPoint("TOPLEFT", 10, -29); row.text:SetWidth(460)
            row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP"); setFont(row.text, 12, TEXT)
            row.edit = CreateFrame("Button", nil, row, "BackdropTemplate")
            C:StyleChronicleButton(row.edit)
            row.edit:SetSize(68, 23); row.edit:SetPoint("TOPRIGHT", -7, -9); row.edit:SetText(C:LocalizeDisplay("Bearb.")); row.edit.noteRow = row
            row.edit:SetScript("OnClick", function(self)
                editingNote = self.noteRow.note
                input:SetText(editingNote.text); input:SetFocus()
                action:SetText(C:LocalizeDisplay("Aendern")); cancelEdit:Show()
            end)
            row.delete = CreateFrame("Button", nil, row, "BackdropTemplate")
            C:StyleChronicleButton(row.delete)
            row.delete:SetSize(68, 23); row.delete:SetPoint("TOPRIGHT", -7, -38); row.delete:SetText(C:LocalizeDisplay("Entf.")); row.delete.noteRow = row
            row.delete:SetScript("OnClick", function(self)
                if editingNote == self.noteRow.note then editingNote = nil; input:SetText(""); cancelEdit:Hide(); action:SetText(C:LocalizeDisplay("Speichern")) end
                C:DeleteNote(self.noteRow.note)
            end)
            noteRows[i] = row
        end
        row.note = note
        row:SetWidth(width); row.text:SetWidth(width - 170)
        row.caption:SetText(U.SafeText(note.category, C:LocalizeDisplay("Allgemein")) .. "  -  " .. U.Date(note.updated or note.created))
        row.text:SetText(U.SafeText(note.text, ""))
        row:Show()
    end
    for i = #notes + 1, #noteRows do noteRows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, 132 + #notes * 108 + 4))
end

local function showGoalRows()
    local width = availableContentWidth()
    local goals = C.char.goals
    local done = 0
    for _, goal in ipairs(goals) do if goal.done then done = done + 1 end end
    showChapterHero("CHRONICLE  /  ZIELE", "Deine nächsten Schritte",
        "Was du auf deiner Reise erreichen möchtest",
        (#goals - done) .. C:LocalizeDisplay(" OFFEN     |     ") .. done .. C:LocalizeDisplay(" ERLEDIGT"),
        "Interface\\AddOns\\Chronicle\\GoalsMedallion", { .93, .66, .2 })
    if #goals == 0 then
        showSimpleEmpty("Noch keine Ziele", "Lege unten dein erstes persönliches Ziel an.",
            "Interface\\AddOns\\Chronicle\\GoalsMedallion", "Goals")
        return
    end
    body:Hide()
    for i, goal in ipairs(goals) do
        local row = goalRows[i]
        if not row then
            row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            row:SetSize(630, 38); row:SetPoint("TOPLEFT", 4, -132 - (i - 1) * 42)
            openSurface(row)
            row.accent = row:CreateTexture(nil, "ARTWORK"); row.accent:Hide()
            row.accent:SetTexture(BACKGROUND)
            row.accent:SetPoint("TOPLEFT", 4, -4); row.accent:SetPoint("BOTTOMLEFT", 4, 4)
            row.accent:SetWidth(3)
            row.goalIndex = i
            row.mark = row:CreateFontString(nil, "OVERLAY")
            row.mark:SetPoint("LEFT", 10, 0); setFont(row.mark, 16, GOLD)
            row.label = row:CreateFontString(nil, "OVERLAY")
            row.label:SetPoint("LEFT", 38, 0); row.label:SetWidth(505)
            row.label:SetJustifyH("LEFT"); setFont(row.label, 12, TEXT)
            row.delete = CreateFrame("Button", nil, row, "BackdropTemplate")
            C:StyleChronicleButton(row.delete)
            row.delete:SetSize(64, 23); row.delete:SetPoint("RIGHT", -7, 0)
            row.delete:SetText(C:LocalizeDisplay("Entf.")); row.delete.goalRow = row
            row.delete:SetScript("OnClick", function(self) C:DeleteGoal(self.goalRow.goalIndex) end)
            row:SetScript("OnClick", function(self) C:ToggleGoal(self.goalIndex) end)
            row:SetScript("OnEnter", function(self)
                if GameTooltip then GameTooltip:SetOwner(self, "ANCHOR_CURSOR"); GameTooltip:SetText(C:LocalizeDisplay("Ziel als erledigt/offen markieren")); C:ShowLocalizedTooltip() end
            end)
            row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            goalRows[i] = row
        end
        row.goalIndex = i
        row:SetWidth(width); row.label:SetWidth(width - 125)
        row.mark:SetText(goal.done and "[x]" or "[ ]")
        row.accent:SetVertexColor(goal.done and .35 or .95, goal.done and .7 or .66,
            goal.done and .44 or .18)
        row.label:SetText(goal.text)
        row.label:SetTextColor(unpack(goal.done and MUTED or TEXT))
        row:Show()
    end
    for i = #goals + 1, #goalRows do goalRows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, 132 + #goals * 42 + 4))
end

local function showAltRows()
    local width = availableContentWidth()
    local classArt = {
        WARRIOR = "Interface\\Icons\\Ability_Warrior_BattleShout",
        PALADIN = "Interface\\Icons\\Spell_Holy_SealOfProtection",
        HUNTER = "Interface\\Icons\\Ability_Hunter_BeastTaming",
        ROGUE = "Interface\\Icons\\Ability_Stealth",
        PRIEST = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        SHAMAN = "Interface\\Icons\\Spell_Nature_Lightning",
        MAGE = "Interface\\Icons\\Spell_Frost_FrostBolt02",
        WARLOCK = "Interface\\Icons\\Spell_Shadow_DeathCoil",
        DRUID = "Interface\\Icons\\Spell_Nature_Regeneration",
    }
    local chronicleSigils = {
        WARRIOR = "Interface\\AddOns\\Chronicle\\ClassSigil_Warrior",
        PALADIN = "Interface\\AddOns\\Chronicle\\ClassSigil_Paladin",
        HUNTER = "Interface\\AddOns\\Chronicle\\ClassSigil_Hunter",
        ROGUE = "Interface\\AddOns\\Chronicle\\ClassSigil_Rogue",
        PRIEST = "Interface\\AddOns\\Chronicle\\ClassSigil_Priest",
        DRUID = "Interface\\AddOns\\Chronicle\\ClassSigil_Druid",
        SHAMAN = "Interface\\AddOns\\Chronicle\\ClassSigil_Shaman",
        MAGE = "Interface\\AddOns\\Chronicle\\ClassSigil_Mage",
        WARLOCK = "Interface\\AddOns\\Chronicle\\ClassSigil_Warlock",
    }
    local classEpithets = {
        WARRIOR = "EHRE IM STAHL", PALADIN = "HÜTER DES LICHTS",
        HUNTER = "SPUREN DER WILDNIS", ROGUE = "SCHATTEN UND KLINGEN",
        PRIEST = "STIMME DES LICHTS", SHAMAN = "RUF DER ELEMENTE",
        MAGE = "WEGE DES ARKANEN", WARLOCK = "PAKT DER SCHATTEN",
        DRUID = "WANDEL DER NATUR",
    }
    local characters = U.SortedPairsByTime(C.db.characters)
    local accountGold = 0
    for _, entry in ipairs(characters) do accountGold = accountGold + (tonumber(entry.value.money) or 0) end
    if selectedAltKey and C.db.characters[selectedAltKey] then
        hideAltRows(); backButton:Show()
        showAltDetail(selectedAltKey)
        return
    end
    selectedAltKey = nil; backButton:Hide()
    showChapterHero("CHRONICLE  /  CHARAKTERE", "Deine Gefährten",
        "Alle Charaktere und ihre Erinnerungen auf einen Blick",
        tostring(#characters) .. C:LocalizeDisplay(" CHARAKTERE     |     ") .. U.Money(accountGold) .. C:LocalizeDisplay(" GESAMTGOLD"),
        "Interface\\Icons\\INV_Shirt_GuildTabard_01", { .9, .67, .23 })
    if #characters == 0 then
        showSimpleEmpty("Noch keine Charaktere erfasst",
            "Dein erster Charakter erscheint nach dem nächsten Login hier.",
            "Interface\\Icons\\INV_Shirt_GuildTabard_01", "Alts")
        return
    end
    for i, entry in ipairs(characters) do
        local a = entry.value
        local journal = C.db.characterData and C.db.characterData[entry.key]
        if type(journal) ~= "table" and entry.key == C.characterKey then journal = C.char end
        local card = altRows[i]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            card:SetSize(630, 244); card:SetPoint("TOPLEFT", 4, -132 - (i - 1) * 254)
            openSurface(card)
            card:EnableMouse(true)
            card:SetScript("OnEnter", function(self)
                self.hover:Show()
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetText(self.tooltipName or C:LocalizeDisplay("Charakter"))
                GameTooltip:AddLine(C:LocalizeDisplay(self.tooltipProfessions or "Berufe: nicht erfasst"), 1, .82, .1, true)
                GameTooltip:AddLine(C:LocalizeDisplay("Klicken fuer Charakterdetails"), .8, .8, .8)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self.hover:Hide()
                if GameTooltip then GameTooltip:Hide() end
            end)
            card:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    selectedAltKey, selectedDetailTab = self.characterKey, "profile"
                    C:ShowPage("alts")
                end
            end)
            card.header = card:CreateTexture(nil, "BACKGROUND")
            card.header:SetTexture(BACKGROUND); card.header:SetPoint("TOPLEFT", 4, -4)
            card.header:SetPoint("TOPRIGHT", -4, -4); card.header:SetHeight(74)
            card.headerRule = card:CreateTexture(nil, "ARTWORK")
            card.headerRule:SetTexture(BACKGROUND)
            card.headerRule:SetPoint("TOPLEFT", 76, -73)
            card.headerRule:SetPoint("TOPRIGHT", -15, -73); card.headerRule:SetHeight(1)
            card.classSeal = card:CreateTexture(nil, "ARTWORK")
            card.classSeal:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            card.classSeal:SetBlendMode("ADD")
            card.classSeal:SetSize(122, 122); card.classSeal:SetPoint("TOPRIGHT", -19, -88)
            card.classMark = card:CreateTexture(nil, "BACKGROUND")
            card.classMark:SetSize(66, 66); card.classMark:SetPoint("CENTER", card.classSeal, "CENTER")
            card.classCaption = card:CreateFontString(nil, "OVERLAY")
            card.classCaption:SetPoint("TOPRIGHT", -25, -86); card.classCaption:SetWidth(150)
            card.classCaption:SetJustifyH("RIGHT"); setFont(card.classCaption, 10, GOLD)
            card.hover = card:CreateTexture(nil, "BACKGROUND")
            card.hover:SetTexture(BACKGROUND); card.hover:SetAllPoints(card)
            card.hover:SetVertexColor(1, .73, .28, .045); card.hover:Hide()
            card.accent = card:CreateTexture(nil, "ARTWORK"); card.accent:Hide()
            card.accent:SetTexture(BACKGROUND); card.accent:SetPoint("TOPLEFT", 4, -4)
            card.accent:SetPoint("BOTTOMLEFT", 4, 4); card.accent:SetWidth(4)
            card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
            card.iconFrame:SetSize(56, 56); card.iconFrame:SetPoint("TOPLEFT", 12, -12)
            backdrop(card.iconFrame, .14, .092, .054, 1)
            card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(48, 48); card.icon:SetPoint("CENTER", card.iconFrame, "CENTER")
            card.kicker = card:CreateFontString(nil, "OVERLAY")
            card.kicker:SetPoint("TOPLEFT", 78, -8); setFont(card.kicker, 9, GOLD)
            card.kicker:SetJustifyH("LEFT")
            card.name = card:CreateFontString(nil, "OVERLAY")
            card.name:SetPoint("TOPLEFT", 77, -22); card.name:SetWidth(395)
            card.name:SetJustifyH("LEFT"); setFont(card.name, 21, GOLD)
            card.realm = card:CreateFontString(nil, "OVERLAY")
            card.realm:SetPoint("TOPRIGHT", -15, -51); card.realm:SetWidth(155)
            card.realm:SetJustifyH("RIGHT"); setFont(card.realm, 10, MUTED)
            card.level = card:CreateFontString(nil, "OVERLAY")
            card.level:SetPoint("TOPRIGHT", -15, -20); card.level:SetWidth(155)
            card.level:SetJustifyH("RIGHT"); setFont(card.level, 19, GOLD)
            card.identity = card:CreateFontString(nil, "OVERLAY")
            card.identity:SetPoint("TOPLEFT", 77, -52); card.identity:SetWidth(430)
            card.identity:SetJustifyH("LEFT"); setFont(card.identity, 11, TEXT)
            card.journeyCaption = card:CreateFontString(nil, "OVERLAY")
            card.journeyCaption:SetPoint("TOPLEFT", 16, -84); setFont(card.journeyCaption, 10, GOLD)
            card.journeyCaption:SetText(C:LocalizeDisplay("AUF DER REISE"))
            card.recordCaption = card:CreateFontString(nil, "OVERLAY")
            card.recordCaption:SetPoint("TOPLEFT", 327, -84); setFont(card.recordCaption, 10, GOLD)
            card.recordCaption:SetText(C:LocalizeDisplay("CHRONIK & KÖNNEN"))
            card.location = card:CreateFontString(nil, "OVERLAY")
            card.location:SetPoint("TOPLEFT", 16, -104); card.location:SetWidth(290)
            card.location:SetJustifyH("LEFT"); setFont(card.location, 11, TEXT)
            card.lastSeen = card:CreateFontString(nil, "OVERLAY")
            card.lastSeen:SetPoint("TOPLEFT", 16, -123); card.lastSeen:SetWidth(290)
            card.lastSeen:SetJustifyH("LEFT"); setFont(card.lastSeen, 11, MUTED)
            card.guild = card:CreateFontString(nil, "OVERLAY")
            card.guild:SetPoint("TOPLEFT", 16, -142); card.guild:SetWidth(290)
            card.guild:SetJustifyH("LEFT"); setFont(card.guild, 11, TEXT)
            card.gold = card:CreateFontString(nil, "OVERLAY")
            card.gold:SetPoint("TOPLEFT", 327, -104); card.gold:SetWidth(282)
            card.gold:SetJustifyH("LEFT"); setFont(card.gold, 11, GOLD)
            card.counts = card:CreateFontString(nil, "OVERLAY")
            card.counts:SetPoint("TOPLEFT", 327, -123); card.counts:SetWidth(282)
            card.counts:SetJustifyH("LEFT"); setFont(card.counts, 11, TEXT)
            card.professions = card:CreateFontString(nil, "OVERLAY")
            card.professions:SetPoint("TOPLEFT", 327, -142); card.professions:SetWidth(282)
            card.professions:SetJustifyH("LEFT"); setFont(card.professions, 11, MUTED)
            card.talents = card:CreateFontString(nil, "OVERLAY")
            card.talents:SetPoint("TOPLEFT", 327, -161); card.talents:SetWidth(282)
            card.talents:SetJustifyH("LEFT"); setFont(card.talents, 11, TEXT)
            card.talentBranches = card:CreateFontString(nil, "OVERLAY")
            card.talentBranches:SetPoint("TOPLEFT", 16, -184); card.talentBranches:SetWidth(600)
            card.talentBranches:SetJustifyH("LEFT"); setFont(card.talentBranches, 11, GOLD)
            card.rule = card:CreateTexture(nil, "ARTWORK")
            card.rule:SetTexture(BACKGROUND); card.rule:SetVertexColor(.46, .34, .16, .8)
            card.rule:SetPoint("TOPLEFT", 16, -205); card.rule:SetPoint("TOPRIGHT", -16, -205); card.rule:SetHeight(1)
            card.memoryCaption = card:CreateFontString(nil, "OVERLAY")
            card.memoryCaption:SetPoint("TOPLEFT", 16, -211); setFont(card.memoryCaption, 9, GOLD)
            card.memoryCaption:SetText(C:LocalizeDisplay("LETZTE ERINNERUNG"))
            card.memory = card:CreateFontString(nil, "OVERLAY")
            card.memory:SetPoint("TOPLEFT", 16, -224); card.memory:SetWidth(594)
            card.memory:SetJustifyH("LEFT"); card.memory:SetJustifyV("TOP"); setFont(card.memory, 11, TEXT)
            card.openHint = card:CreateFontString(nil, "OVERLAY")
            card.openHint:SetPoint("TOPRIGHT", -16, -222)
            card.openHint:SetWidth(160); card.openHint:SetJustifyH("RIGHT")
            setFont(card.openHint, 9, MUTED)
            card.openHint:SetText(C:LocalizeDisplay("CHRONIK ÖFFNEN  >"))
            altRows[i] = card
        end
        local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[a.class]
        card:SetWidth(width)
        card.name:SetWidth(width - 285); card.identity:SetWidth(width - 285)
        local secondColumn = math.floor(width / 2) + 12
        for _, field in ipairs({ card.gold, card.counts, card.professions, card.talents }) do
            field:ClearAllPoints()
        end
        card.recordCaption:ClearAllPoints(); card.recordCaption:SetPoint("TOPLEFT", secondColumn, -84)
        card.gold:SetPoint("TOPLEFT", secondColumn, -104)
        card.counts:SetPoint("TOPLEFT", secondColumn, -123)
        card.professions:SetPoint("TOPLEFT", secondColumn, -142)
        card.talents:SetPoint("TOPLEFT", secondColumn, -161)
        card.location:SetWidth(math.floor(width / 2) - 26)
        card.lastSeen:SetWidth(math.floor(width / 2) - 26)
        card.guild:SetWidth(math.floor(width / 2) - 26)
        card.gold:SetWidth(width - secondColumn - 16); card.counts:SetWidth(width - secondColumn - 16)
        card.professions:SetWidth(width - secondColumn - 16); card.talents:SetWidth(width - secondColumn - 16)
        card.talentBranches:SetWidth(width - 30); card.memory:SetWidth(width - 205)
        card.kicker:SetWidth(width - 275)
        card.accent:SetVertexColor(classColor and classColor.r or .92,
            classColor and classColor.g or .68, classColor and classColor.b or .23, 1)
        card.headerRule:SetVertexColor(classColor and classColor.r or .92,
            classColor and classColor.g or .68, classColor and classColor.b or .23, .65)
        local customSigil = chronicleSigils[a.class]
        card.classSeal:SetVertexColor(classColor and classColor.r or .92,
            classColor and classColor.g or .68, classColor and classColor.b or .23, .22)
        card.classMark:SetTexture(customSigil or classArt[a.class] or "Interface\\Icons\\INV_Misc_Book_09")
        card.classMark:ClearAllPoints()
        if customSigil then
            card.classMark:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 4)
        else
            card.classMark:SetPoint("CENTER", card.classSeal, "CENTER")
        end
        card.classMark:SetSize(customSigil and 220 or 66, customSigil and 220 or 66)
        card.classMark:SetDesaturated(customSigil ~= nil)
        card.classMark:SetVertexColor(customSigil and .58 or 1,
            customSigil and .39 or 1, customSigil and .22 or 1)
        card.classMark:SetAlpha(customSigil and .22 or .16)
        card.classSeal:SetShown(width >= 850 and not customSigil)
        card.classMark:SetShown(width >= 850)
        card.classCaption:SetText(string.upper(U.SafeText(a.className, a.class)))
        card.classCaption:SetTextColor(classColor and classColor.r or .92,
            classColor and classColor.g or .68, classColor and classColor.b or .23)
        card.classCaption:SetShown(width >= 850 and not customSigil)
        card.journeyCaption:SetText(C:LocalizeDisplay("AUF DER REISE"))
        card.recordCaption:SetText(C:LocalizeDisplay("CHRONIK & KÖNNEN"))
        card.memoryCaption:SetText(C:LocalizeDisplay("LETZTE ERINNERUNG"))
        card.openHint:SetText(C:LocalizeDisplay("CHRONIK ÖFFNEN  >"))
        card.iconFrame:SetBackdropBorderColor(classColor and classColor.r or .92,
            classColor and classColor.g or .68, classColor and classColor.b or .23, .9)
        card.header:SetVertexColor(classColor and classColor.r or .6,
            classColor and classColor.g or .4, classColor and classColor.b or .17, .14)
        card.name:SetTextColor(classColor and classColor.r or 1,
            classColor and classColor.g or .82, classColor and classColor.b or .1)
        card.kicker:SetTextColor(classColor and classColor.r or 1,
            classColor and classColor.g or .82, classColor and classColor.b or .1)
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[a.class]
        if coords then
            card.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            card.icon:SetTexCoord(unpack(coords))
        else
            card.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
            card.icon:SetTexCoord(0, 1, 0, 1)
        end
        card.kicker:SetText((entry.key == C.characterKey and C:LocalizeDisplay("AKTUELLER HELD") or
            (C:LocalizeDisplay("GEFÄHRTE ") .. string.format("%02d", i))) .. "   •   " ..
            C:LocalizeDisplay(classEpithets[a.class] or "DEINE CHRONIK"))
        card.name:SetText(C:CharacterDisplayName(a, entry.key))
        card.level:SetText(C:LocalizeDisplay("STUFE ") .. tostring(a.level or 0))
        card.characterKey = entry.key
        card.tooltipName = C:CharacterDisplayName(a, entry.key)
        card.realm:SetText(U.SafeText(a.realm, ""))
        card.identity:SetText(C:LocalizeDisplay(U.SafeText(a.raceName, "")) ..
            " " .. C:LocalizeDisplay(U.SafeText(a.className, a.class)) .. "  |  " .. C:LocalizeDisplay(U.SafeText(a.faction, "")))
        card.location:SetText(C:LocalizeDisplay("Ort: ") .. U.SafeText(a.zone))
        card.lastSeen:SetText(C:LocalizeDisplay("Zuletzt: ") .. (type(a.lastSeen) == "number" and a.lastSeen > 0 and U.Date(a.lastSeen, true) or C:LocalizeDisplay("nicht erfasst")))
        card.guild:SetText(C:LocalizeDisplay("Gilde: ") .. U.SafeText(a.guild, C:LocalizeDisplay("nicht erfasst")) ..
            (a.guildRank and a.guildRank ~= "" and " (" .. a.guildRank .. ")" or ""))
        card.gold:SetText(C:LocalizeDisplay("Gold: ") .. U.Money(a.money))
        card.talents:SetText(C:LocalizeDisplay("Skillung: ") .. talentLabel(a))
        card.talentBranches:SetText(talentBranchText(a))
        if type(journal) == "table" then
            local openGoals = 0
            for _, goal in ipairs(journal.goals or {}) do if not goal.done then openGoals = openGoals + 1 end end
            card.counts:SetText(C:LocalizeDisplay("Quests ") .. U.Count(journal.activeQuests) .. C:LocalizeDisplay("  |  Ziele ") .. openGoals .. C:LocalizeDisplay("  |  Notizen ") .. #(journal.notes or {}))
            local professions = {}
            for name, profession in pairs(journal.professions or {}) do
                professions[#professions + 1] = C:LocalizeDisplay(name) .. " " .. tostring(profession.rank or 0) .. "/" .. tostring(profession.maxRank or 0)
            end
            table.sort(professions)
            card.professions:SetText(C:LocalizeDisplay("Berufe: ") .. (#professions > 0 and
                (professions[1] .. (#professions > 1 and "  +" .. (#professions - 1) or "")) or C:LocalizeDisplay("nicht erfasst")))
        card.tooltipProfessions = C:LocalizeDisplay("Berufe: ") .. (#professions > 0 and table.concat(professions, ", ") or C:LocalizeDisplay("nicht erfasst"))
            local memory = journal.events and journal.events[1]
            card.memory:SetText(memory and C:LocalizeEventText(U.SafeText(memory.text)) or C:LocalizeDisplay("nicht erfasst"))
        else
            card.counts:SetText(C:LocalizeDisplay("Quests –  |  Ziele –  |  Notizen –"))
            card.professions:SetText(C:LocalizeDisplay("Berufe: nicht erfasst"))
            card.tooltipProfessions = C:LocalizeDisplay("Berufe: nicht erfasst")
            card.memory:SetText(C:LocalizeDisplay("Weitere Daten beim naechsten Login dieses Charakters."))
        end
        card:Show()
    end
    for i = #characters + 1, #altRows do altRows[i]:Hide() end
    scrollChild:SetHeight(math.max(1, 132 + #characters * 254))
end

local function showInventoryRows()
    body:Hide()
    local width = availableContentWidth()
    local bagKinds, bankKinds = 0, 0
    for _ in pairs(C.char.inventory or {}) do bagKinds = bagKinds + 1 end
    for _ in pairs(C.char.bank or {}) do bankKinds = bankKinds + 1 end
    showChapterHero("CHRONICLE  /  BESITZ", "Das Besitzarchiv",
        "Fundstücke deiner Reise aus Inventar und Bank",
        bagKinds .. C:LocalizeDisplay(" IM INVENTAR     |     ") .. bankKinds .. C:LocalizeDisplay(" IN DER BANK"),
        "Interface\\Icons\\INV_Misc_Bag_10", { .89, .62, .22 })
    for _, tile in ipairs(inventoryFilters.overview or {}) do tile:Hide() end
    local filterWidth = math.floor((width - 36) / 4)
    local listWidth = math.floor(width * .54)
    local used, groupUsed, offset = 0, 0, 165
    local firstVisible, selectedVisible
    local function showInventoryTooltip(owner, title, detail, link)
        if not GameTooltip then return end
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        if type(link) == "string" and link ~= "" then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            if ok then
                C:ShowLocalizedTooltip()
                return
            end
        end
        GameTooltip:SetText(C:LocalizeDisplay(title or "Besitzarchiv"), 1, .82, .1)
        if detail then GameTooltip:AddLine(C:LocalizeDisplay(detail), .83, .76, .61, true) end
        C:ShowLocalizedTooltip()
    end
    chapterHero:EnableMouse(true)
    chapterHero:SetScript("OnEnter", function(self)
        showInventoryTooltip(self, "Das Besitzarchiv",
            "Gespeicherter Stand von Inventar und Bank. Die Bank wird beim Öffnen im Spiel erfasst.")
    end)
    chapterHero:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    local filterOptions = {
        { key = "all", label = "Alle" }, { key = "quest", label = "Quest" },
        { key = "green", label = "Grün+" }, { key = "sell", label = "Verkäuflich" },
    }
    for index, option in ipairs(filterOptions) do
        local button = inventoryFilters[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button:SetSize(145, 27)
            button:SetPoint("TOPLEFT", 4 + (index - 1) * 157, -127)
            button.label = button:CreateFontString(nil, "OVERLAY")
            button.label:SetPoint("CENTER"); setFont(button.label, 11, TEXT)
            button:SetScript("OnClick", function(self)
                inventoryFilter = self.filterKey
                inventoryFilters.selectedItem = nil
                showInventoryRows()
                scroll:SetVerticalScroll(0)
            end)
            button:SetScript("OnEnter", function(self)
                showInventoryTooltip(self, self.tooltipTitle, self.tooltipDetail)
            end)
            button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            inventoryFilters[index] = button
        end
        button.filterKey = option.key
        button.tooltipTitle = C:LocalizeDisplay(option.label)
        button.tooltipDetail = option.key == "all" and "Alle erfassten Gegenstände zeigen." or
            option.key == "quest" and "Nur Questgegenstände zeigen." or
            option.key == "green" and "Nur Gegenstände ab ungewöhnlicher Qualität zeigen." or
            "Nur Gegenstände mit erfasstem Händlerwert zeigen."
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 4 + (index - 1) * (filterWidth + 12), -127)
        button:SetWidth(filterWidth)
        button.label:SetText(C:LocalizeDisplay(option.label))
        local active = inventoryFilter == option.key
        backdrop(button, active and .26 or .075, active and .17 or .057, active and .065 or .037, 1)
        button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:Show()
    end
    local function row(kind, height)
        used = used + 1
        local frame = inventoryRows[used]
        if not frame then
            frame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            frame:SetWidth(width)
            inventoryRows[used] = frame
        end
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", 4, -offset)
        frame:SetWidth(width)
        frame:SetHeight(height)
        frame:Show()
        if kind ~= "tile" then
            offset = offset + height + (kind == "section" and 8 or 4)
        end
        return frame
    end
    local function section(title, snapshot, updated)
        local items, total, allCount = {}, 0, 0
        for _, item in pairs(snapshot or {}) do
            if type(item) == "table" then
                allCount = allCount + 1
                local quality = tonumber(item.quality) or
                    tonumber(type(item.link) == "string" and item.link:match("|cnIQ(%d+):")) or 0
                local price = tonumber(item.sellPrice)
                if price == nil and C.API.ItemSellPrice then
                    price = C.API.ItemSellPrice(item.id)
                    if price ~= nil then item.sellPrice = price end
                end
                local visible = inventoryFilter == "all" or
                    (inventoryFilter == "quest" and item.isQuestItem) or
                    (inventoryFilter == "green" and quality >= 2) or
                    (inventoryFilter == "sell" and price and price > 0)
                if visible then
                    items[#items + 1] = item
                    total = total + (tonumber(item.count) or 0)
                end
            end
        end
        table.sort(items, function(a, b)
            local aq, bq = tonumber(a.quality) or 0, tonumber(b.quality) or 0
            if a.isQuestItem ~= b.isQuestItem then return a.isQuestItem == true end
            if aq ~= bq then return aq > bq end
            local an = tostring(a.link or a.id or "")
            local bn = tostring(b.link or b.id or "")
            return an < bn
        end)
        local function itemGroup(item)
            if item.isQuestItem then return "quest" end
            local quality = tonumber(item.quality) or
                tonumber(type(item.link) == "string" and item.link:match("|cnIQ(%d+):")) or 0
            if quality >= 3 then return "rare" end
            if quality >= 2 then return "valuable" end
            return "travel"
        end
        local groupCounts = {}
        for _, item in ipairs(items) do
            local key = itemGroup(item)
            groupCounts[key] = (groupCounts[key] or 0) + 1
        end
        local heading = row("section", 62)
        if not heading.title then
            heading.title = heading:CreateFontString(nil, "OVERLAY")
            heading.title:SetPoint("TOPLEFT", 14, -9); setFont(heading.title, 16, GOLD)
            heading.summary = heading:CreateFontString(nil, "OVERLAY")
            heading.summary:SetPoint("TOPLEFT", 15, -32); heading.summary:SetWidth(600)
            heading.summary:SetJustifyH("LEFT"); setFont(heading.summary, 11, TEXT)
        end
        openSurface(heading)
        heading:EnableMouse(true)
        heading:SetScript("OnMouseUp", nil)
        heading.title:Show(); heading.summary:Show()
        if heading.icon then
            heading.icon:Hide(); heading.itemName:Hide(); heading.itemMeta:Hide()
            heading.itemPrice:Hide(); heading.count:Hide()
        end
        if heading.qualityRule then heading.qualityRule:Hide() end
        if heading.separator then heading.separator:Hide() end
        if heading.selectionShade then heading.selectionShade:Hide() end
        if heading.hoverShade then heading.hoverShade:Hide() end
        heading:SetScript("OnEnter", function(self)
            showInventoryTooltip(self, self.sectionTitle, self.sectionTooltip)
        end)
        heading:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        heading:SetWidth(listWidth)
        heading.title:SetText(C:LocalizeDisplay(title))
        heading.sectionTitle = C:LocalizeDisplay(title)
        heading.sectionTooltip = #items .. C:LocalizeDisplay(" verschiedene Gegenstände, ") .. total ..
            C:LocalizeDisplay(" Stück. Stand: ") .. (updated and U.Date(updated, true) or C:LocalizeDisplay("noch nicht erfasst"))
        heading.summary:SetWidth(listWidth - 30)
        heading.summary:SetText(#items .. (inventoryFilter ~= "all" and C:LocalizeDisplay(" von ") .. allCount or "") ..
            C:LocalizeDisplay(" verschiedene Gegenstaende  |  ") .. total .. C:LocalizeDisplay(" Stueck  |  Stand: ") ..
            (updated and U.Date(updated, true) or C:LocalizeDisplay("noch nicht erfasst")))
        if #items == 0 then
            local placeholder = row("item", 38)
            if not placeholder.itemName then
                placeholder.itemName = placeholder:CreateFontString(nil, "OVERLAY")
            end
            placeholder.itemName:ClearAllPoints(); placeholder.itemName:SetPoint("LEFT", 15, 0)
            setFont(placeholder.itemName, 11, MUTED)
            openSurface(placeholder)
            placeholder:SetWidth(listWidth)
            placeholder:EnableMouse(true)
            placeholder:SetScript("OnMouseUp", nil)
            if placeholder.title then placeholder.title:Hide(); placeholder.summary:Hide() end
            if placeholder.icon then
                placeholder.icon:Hide(); placeholder.itemMeta:Hide(); placeholder.itemPrice:Hide(); placeholder.count:Hide()
            end
            if placeholder.qualityRule then placeholder.qualityRule:Hide() end
            if placeholder.separator then placeholder.separator:Hide() end
            if placeholder.selectionShade then placeholder.selectionShade:Hide() end
            if placeholder.hoverShade then placeholder.hoverShade:Hide() end
            placeholder.itemName:Show(); placeholder.itemName:SetText(updated and
                (inventoryFilter == "all" and C:LocalizeDisplay("Keine Gegenstaende erfasst.") or C:LocalizeDisplay("Keine passenden Gegenstaende.")) or
                (title == "Bank" and C:LocalizeDisplay("Noch kein Stand erfasst. Bank zum Erfassen oeffnen.") or
                    C:LocalizeDisplay("Noch kein Inventarstand erfasst.")))
            placeholder:SetScript("OnEnter", function(self)
                showInventoryTooltip(self, self.emptyTitle, self.emptyDetail)
            end)
            placeholder:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            placeholder.emptyTitle = C:LocalizeDisplay(title) .. C:LocalizeDisplay(": keine passenden Gegenstände")
            placeholder.emptyDetail = updated and "Wähle einen anderen Filter." or
                (title == "Bank" and "Öffne die Bank im Spiel, um ihren Inhalt zu erfassen." or
                    "Beim nächsten Inventarstand werden hier Gegenstände gezeigt.")
        end
        local tileWidth = listWidth
        local lastGroup, chapterNumber
        for index, item in ipairs(items) do
            local group = itemGroup(item)
            if group ~= lastGroup then
                chapterNumber = (chapterNumber or 0) + 1
                groupUsed = groupUsed + 1
                local groups = inventoryFilters.groupRows
                if not groups then groups = {}; inventoryFilters.groupRows = groups end
                local groupRow = groups[groupUsed]
                if not groupRow then
                    groupRow = CreateFrame("Frame", nil, scrollChild)
                    groupRow:SetHeight(31); groupRow:EnableMouse(true)
                    groupRow.label = groupRow:CreateFontString(nil, "OVERLAY")
                    groupRow.label:SetPoint("LEFT", 8, 0); setFont(groupRow.label, 11, GOLD)
                    groupRow.rule = groupRow:CreateTexture(nil, "ARTWORK")
                    groupRow.rule:SetTexture(BACKGROUND)
                    groupRow.rule:SetPoint("LEFT", groupRow.label, "RIGHT", 11, 0)
                    groupRow.rule:SetPoint("RIGHT", -48, 0); groupRow.rule:SetHeight(1)
                    groupRow.count = groupRow:CreateFontString(nil, "OVERLAY")
                    groupRow.count:SetPoint("RIGHT", -7, 0)
                    groupRow.count:SetJustifyH("RIGHT"); setFont(groupRow.count, 10, MUTED)
                    groupRow:SetScript("OnEnter", function(self)
                        showInventoryTooltip(self, self.groupTitle, self.groupHint)
                    end)
                    groupRow:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
                    groups[groupUsed] = groupRow
                end
                local groupTitle = group == "quest" and "QUESTRELIKTE" or
                    group == "rare" and "BESONDERE FUNDE" or
                    group == "valuable" and "WERTVOLLE FUNDSTÜCKE" or "REISEGEPÄCK"
                groupRow:ClearAllPoints(); groupRow:SetPoint("TOPLEFT", 4, -offset)
                groupRow:SetWidth(listWidth)
                groupRow.label:SetText(string.format("%02d", chapterNumber) .. "  /  " .. C:LocalizeDisplay(groupTitle))
                groupRow.count:SetText(tostring(groupCounts[group]))
                groupRow.rule:SetVertexColor(group == "quest" and .8 or .45,
                    group == "quest" and .56 or .36, .18, .65)
                groupRow.groupTitle = C:LocalizeDisplay(groupTitle)
                groupRow.groupHint = groupCounts[group] .. C:LocalizeDisplay(" verschiedene Gegenstände in ") .. C:LocalizeDisplay(title)
                groupRow:Show()
                offset = offset + 36
                lastGroup = group
            end
            local itemRow = row("tile", 58)
            itemRow:ClearAllPoints()
            itemRow:SetPoint("TOPLEFT", 4, -offset)
            itemRow:SetWidth(tileWidth)
            itemRow:SetHeight(58)
            if not itemRow.icon then
                itemRow.icon = itemRow:CreateTexture(nil, "ARTWORK")
                itemRow.icon:SetSize(38, 38); itemRow.icon:SetPoint("LEFT", 12, 0)
            end
            if not itemRow.separator then
                itemRow.separator = itemRow:CreateTexture(nil, "ARTWORK")
                itemRow.separator:SetTexture(BACKGROUND)
                itemRow.separator:SetPoint("BOTTOMLEFT", 61, 0)
                itemRow.separator:SetPoint("BOTTOMRIGHT", -8, 0)
                itemRow.separator:SetHeight(1)
            end
            if not itemRow.selectionShade then
                itemRow.selectionShade = itemRow:CreateTexture(nil, "BACKGROUND")
                itemRow.selectionShade:SetTexture(BACKGROUND)
                itemRow.selectionShade:SetAllPoints(itemRow)
                itemRow.selectionShade:SetVertexColor(.85, .53, .16, .08)
            end
            if not itemRow.hoverShade then
                itemRow.hoverShade = itemRow:CreateTexture(nil, "BACKGROUND")
                itemRow.hoverShade:SetTexture(BACKGROUND)
                itemRow.hoverShade:SetAllPoints(itemRow)
                itemRow.hoverShade:SetVertexColor(1, .77, .29, .055)
            end
            if not itemRow.itemName then
                itemRow.itemName = itemRow:CreateFontString(nil, "OVERLAY")
            end
            itemRow.itemName:ClearAllPoints(); itemRow.itemName:SetPoint("TOPLEFT", 61, -9)
            itemRow.itemName:SetWidth(480)
            itemRow.itemName:SetJustifyH("LEFT"); setFont(itemRow.itemName, 13, TEXT)
            if not itemRow.itemMeta then
                itemRow.itemMeta = itemRow:CreateFontString(nil, "OVERLAY")
                itemRow.itemMeta:SetPoint("TOPLEFT", 61, -35); itemRow.itemMeta:SetWidth(480)
                itemRow.itemMeta:SetJustifyH("LEFT"); setFont(itemRow.itemMeta, 10, MUTED)
            end
            if not itemRow.itemPrice then
                itemRow.itemPrice = itemRow:CreateFontString(nil, "OVERLAY")
                itemRow.itemPrice:SetPoint("TOPLEFT", 61, -52); itemRow.itemPrice:SetWidth(480)
                itemRow.itemPrice:SetJustifyH("LEFT"); setFont(itemRow.itemPrice, 10, MUTED)
            end
            if not itemRow.count then
                itemRow.count = itemRow:CreateFontString(nil, "OVERLAY")
                itemRow.count:SetPoint("TOPRIGHT", -12, -11); itemRow.count:SetWidth(55)
                itemRow.count:SetJustifyH("RIGHT"); setFont(itemRow.count, 13, GOLD)
            end
            itemRow:SetBackdrop(nil)
            itemRow:EnableMouse(true)
            if itemRow.title then itemRow.title:Hide(); itemRow.summary:Hide() end
            local quality = tonumber(item.quality) or tonumber(type(item.link) == "string" and item.link:match("|cnIQ(%d+):")) or 1
            local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            itemRow.separator:SetVertexColor(.46, .32, .15, .7)
            itemRow.separator:Show()
            itemRow.hoverShade:Hide()
            itemRow.icon:Show(); itemRow.itemName:Show(); itemRow.itemMeta:Show()
            itemRow.itemPrice:Hide(); itemRow.count:Show()
            local icon
            if C_Item and C_Item.GetItemIconByID then
                local ok, value = pcall(C_Item.GetItemIconByID, item.id)
                if ok then icon = value end
            elseif GetItemIcon then
                local ok, value = pcall(GetItemIcon, item.id)
                if ok then icon = value end
            end
            itemRow.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local name = type(item.link) == "string" and item.link:match("|h%[([^%]]+)%]|h") or nil
            itemRow.itemTitle = U.SafeText(name, "Gegenstand #" .. tostring(item.id or "?"))
            itemRow.itemName:SetText(itemRow.itemTitle)
            itemRow.itemName:SetWidth(tileWidth - 135)
            itemRow.itemMeta:SetWidth(tileWidth - 85); itemRow.itemPrice:SetWidth(tileWidth - 85)
            itemRow.itemName:SetTextColor(color and color.r or .94, color and color.g or .90, color and color.b or .8)
            itemRow.count:SetTextColor(item.isQuestItem and 1 or (color and color.r or 1),
                item.isQuestItem and .76 or (color and color.g or .82),
                item.isQuestItem and .3 or (color and color.b or .1))
            itemRow.itemMeta:SetText(item.isQuestItem and C:LocalizeDisplay("QUESTGEGENSTAND") or
                (quality >= 4 and C:LocalizeDisplay("EPISCH") or quality >= 3 and C:LocalizeDisplay("SELTEN") or
                    quality >= 2 and C:LocalizeDisplay("UNGEWÖHNLICH") or C:LocalizeDisplay("GEGENSTAND")))
            local price = tonumber(item.sellPrice)
            if price == nil and C.API.ItemSellPrice then
                price = C.API.ItemSellPrice(item.id)
                if price ~= nil then item.sellPrice = price end
            end
            if price == nil then
                itemRow.itemPrice:SetText(C:LocalizeDisplay("Verkaufspreis nicht verfügbar"))
            elseif price == 0 then
                itemRow.itemPrice:SetText(C:LocalizeDisplay("Nicht beim Händler verkaufbar"))
            else
                itemRow.itemPrice:SetText(C:LocalizeDisplay("Verkauf: ") .. U.Money(price) .. C:LocalizeDisplay("/St.  |  Stapel: ") ..
                    U.Money(price * (tonumber(item.count) or 0)))
            end
            itemRow.count:SetText("x" .. tostring(item.count or 0))
            if not firstVisible then
                firstVisible = { item = item, source = title, updated = updated }
                if not inventoryFilters.selectedItem then inventoryFilters.selectedItem = item end
            end
            if inventoryFilters.selectedItem == item then
                selectedVisible = { item = item, source = title, updated = updated }
                itemRow.selectionShade:Show()
            else
                itemRow.selectionShade:Hide()
            end
            itemRow.itemData = item
            itemRow.sourceName = title
            itemRow.link = item.link
            itemRow:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    inventoryFilters.selectedItem = self.itemData
                    showInventoryRows()
                end
            end)
            itemRow:SetScript("OnEnter", function(self)
                self.hoverShade:Show()
                showInventoryTooltip(self, self.itemTitle,
                    "Klicken: im Besitzdossier anzeigen", self.link)
            end)
            itemRow:SetScript("OnLeave", function(self)
                self.hoverShade:Hide()
                if GameTooltip then GameTooltip:Hide() end
            end)
            offset = offset + 63
        end
        offset = offset + 15
    end
    section("Inventar", C.char.inventory, C.char.stats.inventoryUpdated)
    section("Bank", C.char.bank, C.char.stats.bankUpdated)
    local chosen = selectedVisible or firstVisible
    local dossier = inventoryFilters.detail
    if not dossier then
        dossier = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        dossier:SetHeight(320); dossier:EnableMouse(true)
        dossier.motif = dossier:CreateTexture(nil, "ARTWORK", nil, -2)
        dossier.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Inventory")
        dossier.motif:SetPoint("BOTTOMRIGHT", -9, 8)
        dossier.motif:SetSize(220, 220); dossier.motif:SetAlpha(.1)
        dossier.rule = dossier:CreateTexture(nil, "ARTWORK")
        dossier.rule:SetTexture(BACKGROUND)
        dossier.rule:SetPoint("TOPLEFT", 17, -103)
        dossier.rule:SetPoint("TOPRIGHT", -17, -103); dossier.rule:SetHeight(1)
        dossier.icon = dossier:CreateTexture(nil, "ARTWORK")
        dossier.icon:SetPoint("TOPLEFT", 19, -32); dossier.icon:SetSize(62, 62)
        local function label(name, x, y, size, color)
            local fs = dossier:CreateFontString(nil, "OVERLAY")
            fs:SetPoint("TOPLEFT", x, -y); fs:SetJustifyH("LEFT")
            setFont(fs, size, color); dossier[name] = fs
        end
        label("caption", 20, 11, 10, GOLD)
        label("name", 91, 34, 19, TEXT)
        label("rarity", 92, 65, 10, MUTED)
        label("quantityCaption", 20, 119, 10, GOLD)
        label("quantity", 20, 136, 19, TEXT)
        label("sourceCaption", 20, 170, 10, GOLD)
        label("source", 20, 187, 12, TEXT)
        label("seenCaption", 20, 220, 10, GOLD)
        label("seen", 20, 237, 12, TEXT)
        label("vendorCaption", 20, 270, 10, GOLD)
        label("vendor", 20, 287, 12, TEXT)
        dossier:SetScript("OnEnter", function(self)
            showInventoryTooltip(self, self.tooltipTitle,
                "Ausgewähltes Fundstück aus " .. (self.tooltipSource or "deinem Besitz") ..
                ". Wähle links einen anderen Gegenstand.", self.tooltipLink)
        end)
        dossier:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        inventoryFilters.detail = dossier
    end
    dossier:ClearAllPoints()
    dossier:SetPoint("TOPLEFT", listWidth + 20, -312)
    dossier:SetWidth(width - listWidth - 16)
    heroBackdrop(dossier)
    if chosen then
        local item = chosen.item
        inventoryFilters.selectedItem = item
        local quality = tonumber(item.quality) or
            tonumber(type(item.link) == "string" and item.link:match("|cnIQ(%d+):")) or 1
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        local name = type(item.link) == "string" and item.link:match("|h%[([^%]]+)%]|h") or nil
        local icon
        if C_Item and C_Item.GetItemIconByID then
            local ok, value = pcall(C_Item.GetItemIconByID, item.id)
            if ok then icon = value end
        elseif GetItemIcon then
            local ok, value = pcall(GetItemIcon, item.id)
            if ok then icon = value end
        end
        dossier.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        dossier.tooltipTitle = U.SafeText(name, "Gegenstand #" .. tostring(item.id or "?"))
        dossier.tooltipSource = chosen.source
        dossier.tooltipLink = item.link
        dossier.caption:SetText(C:LocalizeDisplay("BESITZDOSSIER  /  ") .. string.upper(C:LocalizeDisplay(chosen.source)))
        dossier.name:SetText(U.SafeText(name, C:LocalizeDisplay("Gegenstand #") .. tostring(item.id or "?")))
        dossier.name:SetWidth(width - listWidth - 125)
        dossier.name:SetTextColor(color and color.r or .96, color and color.g or .9, color and color.b or .76)
        dossier.rarity:SetText(item.isQuestItem and C:LocalizeDisplay("QUESTGEGENSTAND") or
            (quality >= 4 and C:LocalizeDisplay("EPISCH") or quality >= 3 and C:LocalizeDisplay("SELTEN") or
                quality >= 2 and C:LocalizeDisplay("UNGEWÖHNLICH") or C:LocalizeDisplay("GEGENSTAND")))
        dossier.rule:SetVertexColor(item.isQuestItem and 1 or (color and color.r or .6),
            item.isQuestItem and .7 or (color and color.g or .45),
            item.isQuestItem and .2 or (color and color.b or .2), .8)
        dossier.quantityCaption:SetText(C:LocalizeDisplay("IM BESITZ"))
        dossier.quantity:SetText(tostring(item.count or 0) .. C:LocalizeDisplay(" STÜCK"))
        dossier.sourceCaption:SetText(C:LocalizeDisplay("AUFBEWAHRUNG"))
        dossier.source:SetText(C:LocalizeDisplay(chosen.source))
        dossier.seenCaption:SetText(C:LocalizeDisplay("ZULETZT ERFASST"))
        dossier.seen:SetText(chosen.updated and U.Date(chosen.updated, true) or C:LocalizeDisplay("nicht erfasst"))
        dossier.vendorCaption:SetText(C:LocalizeDisplay("HÄNDLERWERT"))
        local price = tonumber(item.sellPrice)
        dossier.vendor:SetText(price and price > 0 and U.Money(price * (tonumber(item.count) or 0)) or
            C:LocalizeDisplay("Nicht beim Händler verkaufbar"))
        dossier:Show()
    else
        dossier:Hide()
    end
    local featured, featuredQuality
    for _, entry in ipairs(C.char.loot or {}) do
        if type(entry) == "table" then
            local quality = tonumber(entry.quality) or
                tonumber(type(entry.link) == "string" and entry.link:match("|cnIQ(%d+):")) or 0
            if quality >= 3 and (not featured or quality > featuredQuality or
                (quality == featuredQuality and (tonumber(entry.time) or 0) > (tonumber(featured.time) or 0))) then
                featured, featuredQuality = entry, quality
            end
        end
    end
    local highlight = inventoryFilters.highlight
    if not highlight then
        highlight = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        highlight:SetHeight(132); highlight:EnableMouse(true)
        highlight.motif = highlight:CreateTexture(nil, "ARTWORK", nil, -2)
        highlight.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Loot")
        highlight.motif:SetPoint("BOTTOMRIGHT", -8, 4)
        highlight.motif:SetSize(118, 118); highlight.motif:SetAlpha(.11)
        highlight.icon = highlight:CreateTexture(nil, "ARTWORK")
        highlight.icon:SetPoint("TOPLEFT", 17, -42); highlight.icon:SetSize(47, 47)
        highlight.caption = highlight:CreateFontString(nil, "OVERLAY")
        highlight.caption:SetPoint("TOPLEFT", 17, -12); setFont(highlight.caption, 10, GOLD)
        highlight.name = highlight:CreateFontString(nil, "OVERLAY")
        highlight.name:SetPoint("TOPLEFT", 78, -42)
        highlight.name:SetJustifyH("LEFT"); setFont(highlight.name, 15, TEXT)
        highlight.rarity = highlight:CreateFontString(nil, "OVERLAY")
        highlight.rarity:SetPoint("TOPLEFT", 79, -67); setFont(highlight.rarity, 10, MUTED)
        highlight.detail = highlight:CreateFontString(nil, "OVERLAY")
        highlight.detail:SetPoint("TOPLEFT", 18, -101)
        highlight.detail:SetJustifyH("LEFT"); setFont(highlight.detail, 11, TEXT)
        highlight.rule = highlight:CreateTexture(nil, "ARTWORK")
        highlight.rule:SetTexture(BACKGROUND)
        highlight.rule:SetPoint("TOPLEFT", 18, -96)
        highlight.rule:SetPoint("TOPRIGHT", -18, -96); highlight.rule:SetHeight(1)
        highlight:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(.9, .69, .29, 1)
            showInventoryTooltip(self, self.tooltipTitle, self.tooltipDetail, self.link)
        end)
        highlight:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(.59, .44, .17, 1)
            if GameTooltip then GameTooltip:Hide() end
        end)
        highlight:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then C:ShowPage("loot") end
        end)
        inventoryFilters.highlight = highlight
    end
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", listWidth + 20, -165)
    highlight:SetWidth(width - listWidth - 16)
    heroBackdrop(highlight)
    if featured then
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[featuredQuality]
        local icon
        if C_Item and C_Item.GetItemIconByID then
            local ok, value = pcall(C_Item.GetItemIconByID, featured.id)
            if ok then icon = value end
        elseif GetItemIcon then
            local ok, value = pcall(GetItemIcon, featured.id)
            if ok then icon = value end
        end
        highlight.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        highlight.rule:SetVertexColor(color and color.r or .3,
            color and color.g or .5, color and color.b or 1, .65)
        highlight.caption:SetText(C:LocalizeDisplay("HIGHLIGHT-LOOT  /  ") ..
            (featuredQuality >= 5 and C:LocalizeDisplay("LEGENDÄR") or featuredQuality >= 4 and C:LocalizeDisplay("EPISCH") or C:LocalizeDisplay("SELTEN")))
        highlight.name:SetText(U.SafeText(featured.name,
            type(featured.link) == "string" and featured.link:match("|h%[([^%]]+)%]|h") or C:LocalizeDisplay("Fundstück")))
        highlight.name:SetWidth(width - listWidth - 115)
        highlight.name:SetTextColor(color and color.r or .3,
            color and color.g or .5, color and color.b or 1)
        highlight.rarity:SetText("x" .. tostring(featured.quantity or 1) .. "  |  " ..
            U.SafeText(featured.zone, C:LocalizeDisplay("Unbekannter Ort")))
        highlight.detail:SetText(C:LocalizeDisplay("Gefunden: ") .. U.Date(featured.time, true) .. C:LocalizeDisplay("   •   Beute öffnen >"))
        highlight.detail:SetWidth(width - listWidth - 40)
        highlight.link = featured.link
        highlight.tooltipTitle = U.SafeText(featured.name, "Besonderer Fund")
        highlight.tooltipDetail = "Klicken: Beute & Rares öffnen"
    else
        highlight.icon:SetTexture("Interface\\Icons\\INV_Box_01")
        highlight.rule:SetVertexColor(.42, .34, .22, .7)
        highlight.caption:SetText(C:LocalizeDisplay("HIGHLIGHT-LOOT"))
        highlight.name:SetText(C:LocalizeDisplay("Noch kein besonderer Fund"))
        highlight.name:SetTextColor(unpack(TEXT))
        highlight.rarity:SetText(C:LocalizeDisplay("Ab seltener Qualität (blau)"))
        highlight.detail:SetText(C:LocalizeDisplay("Dein nächster Fund bekommt hier seinen Platz."))
        highlight.link = nil
        highlight.tooltipTitle = "Highlight-Loot"
        highlight.tooltipDetail = "Hier erscheint dein hochwertigster erfasster Fund ab blauer Qualität. Klicken: Beute & Rares öffnen."
    end
    highlight.icon:SetAlpha(featured and 1 or .35)
    highlight:Show()
    for i = used + 1, #inventoryRows do inventoryRows[i]:Hide() end
    for i = groupUsed + 1, #(inventoryFilters.groupRows or {}) do inventoryFilters.groupRows[i]:Hide() end
    scrollChild:SetHeight(math.max(650, offset))
end

local function showLootRows()
    body:Hide()
    local width = availableContentWidth()
    local entries, allLootCount = {}, 0
    local query = lootSearch and U.Trim(lootSearch:GetText()):lower() or ""
    local function matches(text)
        return query == "" or tostring(text or ""):lower():find(query, 1, true) ~= nil
    end
    for _, entry in ipairs(C.char.loot or {}) do
        if U.LootVisible(entry) then
            allLootCount = allLootCount + 1
            local quality = tonumber(entry.quality) or tonumber(type(entry.link) == "string" and entry.link:match("|cnIQ(%d+):")) or 0
            local eligible = lootFilter == "all" or (lootFilter == "quest" and entry.isQuestItem) or
                (lootFilter == "green" and quality >= 2)
            if eligible and (matches(entry.name) or matches(entry.zone) or matches(entry.link)) then
                entries[#entries + 1] = entry
            end
        end
    end
    table.sort(entries, function(a, b) return (tonumber(a.time) or 0) > (tonumber(b.time) or 0) end)
    local grouped, byItem = {}, {}
    for _, entry in ipairs(entries) do
        local key = tostring(entry.id or "?") .. "|" .. tostring(entry.name or "?")
        local group = byItem[key]
        if not group then
            group = {}
            for field, value in pairs(entry) do group[field] = value end
            group.occurrences = 0
            group.totalQuantity = 0
            group.firstTime = entry.time
            byItem[key] = group
            grouped[#grouped + 1] = group
        end
        group.occurrences = group.occurrences + 1
        group.totalQuantity = group.totalQuantity + (tonumber(entry.quantity) or 1)
        group.firstTime = entry.time or group.firstTime
        if group.sellPrice == nil then group.sellPrice = entry.sellPrice end
    end
    entries = grouped
    local featured, featuredValue = nil, 0
    for _, entry in ipairs(entries) do
        local price = tonumber(entry.sellPrice)
        if price == nil and C.API.ItemSellPrice then price = C.API.ItemSellPrice(entry.id) end
        entry.sellPrice = price
        local total = (price or 0) * entry.totalQuantity
        if total > featuredValue then featured, featuredValue = entry, total end
    end
    local rareCount = U.Count(C.char.rares)

    if not lootHero then
        lootHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        lootHero:SetPoint("TOPLEFT", 4, 0); lootHero:SetHeight(105); heroBackdrop(lootHero)
        lootHero.accent = lootHero:CreateTexture(nil, "ARTWORK"); lootHero.accent:Hide(); lootHero.accent:SetTexture(BACKGROUND); lootHero.accent:SetVertexColor(.2, .78, .32, 1)
        lootHero.accent:SetPoint("TOPLEFT", 4, -4); lootHero.accent:SetPoint("BOTTOMLEFT", 4, 4); lootHero.accent:SetWidth(4)
        lootHero.caption = lootHero:CreateFontString(nil, "OVERLAY"); lootHero.caption:SetPoint("TOPLEFT", 20, -14); setFont(lootHero.caption, 11, GOLD)
        lootHero.caption:SetText(C:LocalizeDisplay("DEINE FUNDSTÜCKE"))
        lootHero.summary = lootHero:CreateFontString(nil, "OVERLAY"); lootHero.summary:SetPoint("TOPLEFT", 19, -36); setFont(lootHero.summary, 25, TEXT)
        lootHero.summary:SetJustifyH("LEFT")
        lootHero.detail = lootHero:CreateFontString(nil, "OVERLAY"); lootHero.detail:SetPoint("TOPLEFT", 21, -73); setFont(lootHero.detail, 11, MUTED)
        lootHero.detail:SetJustifyH("LEFT")
        lootHero.divider = lootHero:CreateTexture(nil, "ARTWORK"); lootHero.divider:SetTexture(BACKGROUND)
        lootHero.divider:SetVertexColor(.52, .36, .13, .7)
        lootHero.divider:SetPoint("TOP", lootHero, "TOP", 0, -14)
        lootHero.divider:SetPoint("BOTTOM", lootHero, "BOTTOM", 0, 14); lootHero.divider:SetWidth(1)
        lootHero.featureLabel = lootHero:CreateFontString(nil, "OVERLAY")
        lootHero.featureLabel:SetPoint("TOPLEFT", lootHero, "TOP", 20, -15); setFont(lootHero.featureLabel, 10, GOLD)
        lootHero.featureLabel:SetText(C:LocalizeDisplay("WERTVOLLSTER FUND IM FILTER"))
        lootHero.featureName = lootHero:CreateFontString(nil, "OVERLAY")
        lootHero.featureName:SetPoint("TOPLEFT", lootHero, "TOP", 20, -36)
        lootHero.featureName:SetPoint("TOPRIGHT", -100, -36); lootHero.featureName:SetJustifyH("LEFT"); setFont(lootHero.featureName, 16, TEXT)
        lootHero.featureValue = lootHero:CreateFontString(nil, "OVERLAY")
        lootHero.featureValue:SetPoint("TOPLEFT", lootHero, "TOP", 20, -70); setFont(lootHero.featureValue, 12, GOLD)
        lootHero.icon = lootHero:CreateTexture(nil, "ARTWORK"); lootHero.icon:SetTexture("Interface\\Icons\\INV_Box_01")
        lootHero.icon:SetSize(62, 62); lootHero.icon:SetPoint("RIGHT", -23, 0); lootHero.icon:SetAlpha(.85)
        lootHero.featureHotspot = CreateFrame("Button", nil, lootHero)
        lootHero.featureHotspot:SetPoint("TOPLEFT", lootHero, "TOP", 5, -5)
        lootHero.featureHotspot:SetPoint("BOTTOMRIGHT", lootHero, "BOTTOMRIGHT", -5, 5)
        lootHero.featureHotspot:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            if self.rareName then
                GameTooltip:AddLine(self.rareName, .78, .46, 1)
                GameTooltip:AddLine(C:LocalizeDisplay("Gebiet: ") .. U.SafeText(self.zone), .92, .85, .7)
                GameTooltip:AddLine(C:LocalizeDisplay("Erste Sichtung: ") .. U.Date(self.firstSeen), .72, .65, .52)
                GameTooltip:AddLine(C:LocalizeDisplay("Letzte Sichtung: ") .. U.Date(self.lastSeen), .72, .65, .52)
                GameTooltip:AddLine(C:LocalizeDisplay("Begegnungen: ") .. self.occurrences, .92, .85, .7)
                C:ShowLocalizedTooltip()
                return
            end
            local native = false
            if self.link and GameTooltip.SetHyperlink then
                local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
                native = ok and GameTooltip:NumLines() > 0
            end
            if not native then GameTooltip:AddLine(self.itemName or C:LocalizeDisplay("Wertvollster Fund"), 1, .82, .1) end
            if self.itemName then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Chronicle: " .. self.quantity .. C:LocalizeDisplay(" Stück aus ") .. self.occurrences .. C:LocalizeDisplay(" Funden"), .95, .76, .3)
                GameTooltip:AddLine(C:LocalizeDisplay("Händlerwert: ") .. U.Money(self.unitPrice) .. C:LocalizeDisplay("/St.  •  Gesamt: ") .. U.Money(self.totalPrice), .95, .76, .3)
                GameTooltip:AddLine(C:LocalizeDisplay("Erster Fund: ") .. U.Date(self.firstSeen, true), .72, .65, .52)
                GameTooltip:AddLine(C:LocalizeDisplay("Letzter Fund: ") .. U.Date(self.lastSeen, true) .. C:LocalizeDisplay(" in ") .. U.SafeText(self.zone), .72, .65, .52, true)
            else
                GameTooltip:AddLine(C:LocalizeDisplay(self.emptyRare and "Noch keine seltene Kreatur entdeckt." or
                    "In diesem Filter ist noch kein verkäuflicher Fund erfasst."), .72, .65, .52, true)
            end
            C:ShowLocalizedTooltip()
        end)
        lootHero.featureHotspot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    lootHero:SetWidth(width)
    lootHero.caption:SetText(C:LocalizeDisplay("DEINE FUNDSTÜCKE"))
    C:SetHeroMotif(lootHero, "Loot", .3)
    lootHero.motifClip:SetShown(width >= 850)
    lootHero.icon:Hide()
    lootHero.summary:SetWidth(math.max(220, width / 2 - 40))
    lootHero.detail:SetWidth(math.max(220, width / 2 - 40))
    lootHero.summary:SetText(lootFilter == "rares" and rareCount .. C:LocalizeDisplay(" seltene Kreaturen") or allLootCount .. C:LocalizeDisplay(" Beutefunde"))
    lootHero.detail:SetText(lootFilter == "rares" and C:LocalizeDisplay("Begegnungen deiner Reise") or rareCount .. C:LocalizeDisplay(" seltene Kreaturen entdeckt"))
    lootHero.featureHotspot.rareName = nil
    lootHero.featureHotspot.emptyRare = lootFilter == "rares"
    if lootFilter == "rares" then
        local recentName, recent
        for name, rare in pairs(C.char.rares or {}) do
            if not recent or (tonumber(rare.lastSeen) or 0) > (tonumber(recent.lastSeen) or 0) then
                recentName, recent = name, rare
            end
        end
        lootHero.featureLabel:SetText(C:LocalizeDisplay("ZULETZT GESICHTET"))
        lootHero.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
        lootHero.featureName:SetText(recentName or C:LocalizeDisplay("Noch keine seltene Spur"))
        lootHero.featureValue:SetText(recent and (U.SafeText(recent.zone) .. "  •  " .. (recent.sightings or 1) .. C:LocalizeDisplay(" Begegnungen")) or "")
        local hotspot = lootHero.featureHotspot
        hotspot.link, hotspot.itemName = nil, nil
        hotspot.rareName, hotspot.zone = recentName, recent and recent.zone
        hotspot.firstSeen, hotspot.lastSeen = recent and recent.firstSeen, recent and recent.lastSeen
        hotspot.occurrences = recent and (recent.sightings or 1) or nil
    elseif featured then
        lootHero.featureLabel:SetText(C:LocalizeDisplay("WERTVOLLSTER FUND IM FILTER"))
        local icon
        if C_Item and C_Item.GetItemIconByID then local ok, value = pcall(C_Item.GetItemIconByID, featured.id); if ok then icon = value end
        elseif GetItemIcon then local ok, value = pcall(GetItemIcon, featured.id); if ok then icon = value end end
        lootHero.icon:SetTexture(icon or "Interface\\Icons\\INV_Box_01")
        lootHero.featureName:SetText(U.SafeText(featured.name, C:LocalizeDisplay("Fundstück")))
        lootHero.featureValue:SetText(C:LocalizeDisplay("Händlerwert: ") .. U.Money(featuredValue))
        local hotspot = lootHero.featureHotspot
        hotspot.link, hotspot.itemName, hotspot.unitPrice, hotspot.totalPrice = featured.link, featured.name, featured.sellPrice, featuredValue
        hotspot.quantity, hotspot.occurrences = featured.totalQuantity, featured.occurrences
        hotspot.firstSeen, hotspot.lastSeen, hotspot.zone = featured.firstTime, featured.time, featured.zone
    else
        lootHero.featureLabel:SetText(C:LocalizeDisplay("WERTVOLLSTER FUND IM FILTER"))
        lootHero.icon:SetTexture("Interface\\Icons\\INV_Box_01")
        lootHero.featureName:SetText(C:LocalizeDisplay("Noch kein verkäuflicher Fund"))
        lootHero.featureValue:SetText("")
        lootHero.featureHotspot.itemName = nil
        lootHero.featureHotspot.link = nil
    end
    lootHero:Show()

    local filterLabels = {
        { "all", "Alle" }, { "quest", "Quest" }, { "green", "Grün+" }, { "rares", "Rares" },
    }
    local filterWidth = math.floor((width - 234) / 4)
    for index, option in ipairs(filterLabels) do
        local button = lootFilters[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate"); button:SetHeight(27)
            C:StyleChronicleButton(button)
            button.label = button:CreateFontString(nil, "OVERLAY"); button.label:SetPoint("CENTER"); setFont(button.label, 11, TEXT)
            button:SetScript("OnClick", function(self)
                lootFilter = self.filterKey
                showLootRows(); scroll:SetVerticalScroll(0)
            end)
            lootFilters[index] = button
        end
        button.filterKey = option[1]
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 4 + (index - 1) * (filterWidth + 9), -118)
        button:SetWidth(filterWidth); button.label:SetText(C:LocalizeDisplay(option[2]))
        local active = lootFilter == option[1]
        backdrop(button, active and .27 or .075, active and .17 or .055, active and .055 or .034, 1)
        button.label:SetTextColor(unpack(active and GOLD or TEXT)); button:Show()
    end
    if not lootSearch then
        lootSearch = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        lootSearch:SetAutoFocus(false); lootSearch:SetMaxLetters(80); lootSearch:SetHeight(27)
        lootSearchHint = lootSearch:CreateFontString(nil, "ARTWORK")
        lootSearchHint:SetPoint("LEFT", 7, 0); setFont(lootSearchHint, 10, MUTED)
        lootSearchHint:SetText(C:LocalizeDisplay("Beute suchen ..."))
        lootSearch:SetScript("OnTextChanged", function(self)
            lootSearchHint:SetShown(self:GetText() == "")
            showLootRows(); scroll:SetVerticalScroll(0)
        end)
        lootSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        lootSearch:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    end
    lootSearch:ClearAllPoints(); lootSearch:SetPoint("TOPRIGHT", scrollChild, "TOPLEFT", width + 4, -118)
    lootSearchHint:SetText(C:LocalizeDisplay("Beute suchen ..."))
    lootSearch:SetWidth(190); lootSearch:Show()
    if allLootCount == 0 and rareCount == 0 and query == "" and lootFilter == "all" then
        if not lootHero.emptyGallery then
            lootHero.emptyGallery = {}
            local panels = {
                { number = "01 / BEUTEARCHIV", title = "Der nächste Fund wartet", detail = "Questgegenstände und Beute ab ungewöhnlicher Qualität erhalten hier ihren Platz in deiner Chronik.", footer = "Funde werden während deiner Reise automatisch festgehalten.", icon = "Interface\\Icons\\INV_Box_01" },
                { number = "02 / SELTENE BEGEGNUNGEN", title = "Noch keine seltene Spur", detail = "Sobald dir eine seltene Kreatur begegnet, erzählt dieses Journal von Ort und Zeitpunkt der Entdeckung.", footer = "Jede Begegnung wird zu einem Kapitel deiner Reise.", icon = "Interface\\Icons\\Ability_Hunter_BeastCall" },
            }
            for index, data in ipairs(panels) do
                local panel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                panel:SetHeight(430); heroBackdrop(panel)
                panel.number = panel:CreateFontString(nil, "OVERLAY")
                panel.number:SetPoint("TOPLEFT", 22, -22); setFont(panel.number, 11, GOLD)
                panel.title = panel:CreateFontString(nil, "OVERLAY")
                panel.title:SetPoint("TOPLEFT", 21, -58); panel.title:SetPoint("TOPRIGHT", -22, -58)
                panel.title:SetJustifyH("LEFT"); setFont(panel.title, 23, TEXT)
                panel.rule = panel:CreateTexture(nil, "ARTWORK"); panel.rule:SetTexture(BACKGROUND)
                panel.rule:SetVertexColor(.77, .54, .19, .75)
                panel.rule:SetPoint("TOPLEFT", 22, -104); panel.rule:SetPoint("TOPRIGHT", -22, -104); panel.rule:SetHeight(1)
                panel.detail = panel:CreateFontString(nil, "OVERLAY")
                panel.detail:SetPoint("TOPLEFT", 22, -125); panel.detail:SetPoint("TOPRIGHT", -24, -125)
                panel.detail:SetJustifyH("LEFT"); setFont(panel.detail, 12, MUTED)
                panel.art = panel:CreateTexture(nil, "ARTWORK")
                panel.art:SetTexture(data.icon); panel.art:SetSize(160, 160)
                panel.art:SetPoint("BOTTOMRIGHT", -36, 62); panel.art:SetAlpha(.18)
                panel.footer = panel:CreateFontString(nil, "OVERLAY")
                panel.footer:SetPoint("BOTTOMLEFT", 22, 24); panel.footer:SetPoint("BOTTOMRIGHT", -22, 24)
                panel.footer:SetJustifyH("LEFT"); setFont(panel.footer, 11, GOLD)
                panel.sourceText = data
                lootHero.emptyGallery[index] = panel
            end
        end
        local panelWidth = math.floor((width - 14) / 2)
        for index, panel in ipairs(lootHero.emptyGallery) do
            panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", 4 + (index - 1) * (panelWidth + 10), -158)
            panel.number:SetText(C:LocalizeDisplay(panel.sourceText.number))
            panel.title:SetText(C:LocalizeDisplay(panel.sourceText.title))
            panel.detail:SetText(C:LocalizeDisplay(panel.sourceText.detail))
            panel.footer:SetText(C:LocalizeDisplay(panel.sourceText.footer))
            panel:SetWidth(panelWidth); panel:Show()
        end
        for _, row in ipairs(lootRows) do row:Hide() end
        if rareHeader then rareHeader:Hide() end
        for _, row in ipairs(rareRows) do row:Hide() end
        scrollChild:SetHeight(610)
        return
    elseif lootHero.emptyGallery then
        for _, panel in ipairs(lootHero.emptyGallery) do panel:Hide() end
    end
    local offset = 158
    if lootFilter ~= "rares" and #entries == 0 then
        local row = lootRows[1]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); row:SetHeight(54)
            lootRows[1] = row
        end
        if not row.empty then
            row.empty = row:CreateFontString(nil, "OVERLAY")
            row.empty:SetPoint("LEFT", 16, 0); setFont(row.empty, 11, MUTED)
        end
        openSurface(row)
        if row.icon then row.icon:Hide(); row.name:Hide(); row.meta:Hide(); row.count:Hide(); row.badge:Hide(); row.separator:Hide(); row.hoverShade:Hide() end
        row:SetHeight(54); row:EnableMouse(false)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(listWidth)
        row.empty:SetText(query ~= "" and C:LocalizeDisplay("Keine passenden Beutefunde.") or C:LocalizeDisplay("Noch keine Beutefunde für diesen Filter."))
        row:EnableMouse(false); row:Show()
        offset = offset + 62
    end
    local visibleLoot = lootFilter == "rares" and {} or entries
    for index, entry in ipairs(visibleLoot) do
        local row = lootRows[index]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); row:SetHeight(56)
            lootRows[index] = row
        end
        row:SetHeight(56); row:EnableMouse(true); row:SetBackdrop(nil)
        if not row.icon then
            row.hoverShade = row:CreateTexture(nil, "BACKGROUND"); row.hoverShade:SetTexture(BACKGROUND)
            row.hoverShade:SetAllPoints(row); row.hoverShade:SetVertexColor(1, .72, .22, .055); row.hoverShade:Hide()
            row.separator = row:CreateTexture(nil, "ARTWORK"); row.separator:SetTexture(BACKGROUND)
            row.separator:SetVertexColor(.45, .32, .15, .7)
            row.separator:SetPoint("BOTTOMLEFT", 12, 0); row.separator:SetPoint("BOTTOMRIGHT", -12, 0); row.separator:SetHeight(1)
            row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(36, 36); row.icon:SetPoint("LEFT", 12, 0)
            row.name = row:CreateFontString(nil, "OVERLAY"); row.name:SetPoint("TOPLEFT", 60, -8); row.name:SetJustifyH("LEFT"); setFont(row.name, 13, TEXT)
            row.meta = row:CreateFontString(nil, "OVERLAY"); row.meta:SetPoint("BOTTOMLEFT", 60, 9); row.meta:SetJustifyH("LEFT"); setFont(row.meta, 10, MUTED)
            row.count = row:CreateFontString(nil, "OVERLAY"); row.count:SetPoint("RIGHT", -14, 4); row.count:SetWidth(65); row.count:SetJustifyH("RIGHT"); setFont(row.count, 14, GOLD)
            row.badge = row:CreateFontString(nil, "OVERLAY"); row.badge:SetPoint("BOTTOMRIGHT", -14, 9); row.badge:SetWidth(180); row.badge:SetJustifyH("RIGHT"); setFont(row.badge, 11, GOLD)
            row:SetScript("OnEnter", function(self)
                self.hoverShade:Show()
                if self.link and GameTooltip then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
                    if ok then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Chronicle: " .. self.occurrences .. C:LocalizeDisplay(" Funde, ") .. self.totalQuantity .. C:LocalizeDisplay(" Stück"), .95, .76, .3)
                        if self.sellPrice == nil then
                            GameTooltip:AddLine(C:LocalizeDisplay("Händlerwert: noch nicht verfügbar"), .72, .65, .52)
                        elseif self.sellPrice == 0 then
                            GameTooltip:AddLine(C:LocalizeDisplay("Nicht beim Händler verkäuflich"), .72, .65, .52)
                        else
                            GameTooltip:AddLine(C:LocalizeDisplay("Händlerwert: ") .. U.Money(self.sellPrice) .. C:LocalizeDisplay("/St.  •  Gesamt: ") .. U.Money(self.sellPrice * self.totalQuantity), .95, .76, .3)
                        end
                        GameTooltip:AddLine(C:LocalizeDisplay("Erster Fund: ") .. U.Date(self.firstLootTime, true), .72, .65, .52)
                        GameTooltip:AddLine(C:LocalizeDisplay("Letzter Fund: ") .. U.Date(self.lootTime, true) .. C:LocalizeDisplay(" in ") .. U.SafeText(self.zone), .95, .76, .3, true)
                        C:ShowLocalizedTooltip()
                    end
                end
            end)
            row:SetScript("OnLeave", function(self) self.hoverShade:Hide(); GameTooltip:Hide() end)
        end
        if row.empty then row.empty:Hide() end
        row.icon:Show(); row.name:Show(); row.meta:Show(); row.count:Show(); row.badge:Show(); row.separator:Show()
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(width)
        local icon
        if C_Item and C_Item.GetItemIconByID then local ok, value = pcall(C_Item.GetItemIconByID, entry.id); if ok then icon = value end
        elseif GetItemIcon then local ok, value = pcall(GetItemIcon, entry.id); if ok then icon = value end end
        local quality = tonumber(entry.quality) or tonumber(type(entry.link) == "string" and entry.link:match("|cnIQ(%d+):")) or 1
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        local name = type(entry.link) == "string" and entry.link:match("|h%[([^%]]+)%]|h") or entry.name
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(U.SafeText(name, C:LocalizeDisplay("Gegenstand #") .. tostring(entry.id or "?")))
        row.name:SetTextColor(color and color.r or .96, color and color.g or .91, color and color.b or .78)
        row.name:SetWidth(width - 165); row.meta:SetWidth(width - 165)
        local sellPrice = tonumber(entry.sellPrice)
        row.meta:SetText(U.Date(entry.time, true) .. "   •   " .. C:LocalizeDisplay(U.SafeText(entry.zone)) ..
            (entry.occurrences > 1 and "   •   " .. entry.occurrences .. C:LocalizeDisplay(" Funde") or "") ..
            (entry.isQuestItem and C:LocalizeDisplay("   •   Questgegenstand") or ""))
        row.count:SetText("x" .. tostring(entry.totalQuantity))
        row.badge:SetText(sellPrice == nil and C:LocalizeDisplay("Wert unbekannt") or
            (sellPrice == 0 and C:LocalizeDisplay("Nicht verkäuflich") or C:LocalizeDisplay("Händler: ") .. U.Money(sellPrice * entry.totalQuantity)))
        if sellPrice and sellPrice > 0 then row.badge:SetTextColor(.96, .85, .6)
        else row.badge:SetTextColor(.56, .52, .44) end
        row.link, row.lootTime, row.firstLootTime, row.zone = entry.link, entry.time, entry.firstTime, entry.zone
        row.occurrences, row.totalQuantity = entry.occurrences, entry.totalQuantity
        row.sellPrice = sellPrice
        row.colorR, row.colorG, row.colorB = color and color.r, color and color.g, color and color.b
        row:Show(); offset = offset + 58
    end
    for index = math.max(#visibleLoot, lootFilter ~= "rares" and #entries == 0 and 1 or 0) + 1, #lootRows do lootRows[index]:Hide() end

    if not rareHeader then
        rareHeader = CreateFrame("Frame", nil, scrollChild)
        rareHeader:SetHeight(39)
        rareHeader.title = rareHeader:CreateFontString(nil, "OVERLAY"); rareHeader.title:SetPoint("LEFT", 8, 2); setFont(rareHeader.title, 16, GOLD); rareHeader.title:SetText(C:LocalizeDisplay("Seltene Begegnungen"))
        rareHeader.count = rareHeader:CreateFontString(nil, "OVERLAY"); rareHeader.count:SetPoint("RIGHT", -10, 2); setFont(rareHeader.count, 10, MUTED)
        rareHeader.rule = rareHeader:CreateTexture(nil, "ARTWORK"); rareHeader.rule:SetTexture(BACKGROUND); rareHeader.rule:SetVertexColor(.72, .43, .93, .9)
        rareHeader.rule:SetPoint("BOTTOMLEFT", 8, 0); rareHeader.rule:SetPoint("BOTTOMRIGHT", -8, 0); rareHeader.rule:SetHeight(1)
    end
    rareHeader:ClearAllPoints(); rareHeader:SetPoint("TOPLEFT", 4, -offset); rareHeader:SetWidth(width); rareHeader.count:SetText(rareCount .. C:LocalizeDisplay(" ENTDECKT"))
    local showRares = lootFilter == "all" or lootFilter == "rares"
    rareHeader:SetShown(showRares)
    if showRares then offset = offset + 48 end
    local rares = {}
    if showRares then
        for _, wrapped in ipairs(U.SortedPairsByTime(C.char.rares)) do
            if matches(wrapped.key) or matches(wrapped.value.zone) then rares[#rares + 1] = wrapped end
        end
    end
    if showRares and #rares == 0 then
        local row = rareRows[1]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); row:SetHeight(54); openSurface(row)
            rareRows[1] = row
        end
        if not row.text then
            row.text = row:CreateFontString(nil, "OVERLAY"); row.text:SetPoint("LEFT", 16, 0); setFont(row.text, 11, MUTED)
        end
        if row.icon then row.icon:Hide(); row.name:Hide(); row.meta:Hide(); row.sightings:Hide(); row.separator:Hide(); row.hoverShade:Hide() end
        openSurface(row)
        row:SetHeight(54); row:EnableMouse(false)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(width)
        row.text:SetText(query ~= "" and C:LocalizeDisplay("Keine passende seltene Kreatur.") or C:LocalizeDisplay("Noch keine seltene Kreatur entdeckt."))
        row:Show(); offset = offset + 62
    elseif showRares then
        for index, wrapped in ipairs(rares) do
            local rare = wrapped.value
            local row = rareRows[index]
            if not row then
                row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); row:SetHeight(56)
                rareRows[index] = row
            end
            if not row.icon then
                row.hoverShade = row:CreateTexture(nil, "BACKGROUND"); row.hoverShade:SetTexture(BACKGROUND)
                row.hoverShade:SetAllPoints(row); row.hoverShade:SetVertexColor(.72, .43, .93, .07); row.hoverShade:Hide()
                row.separator = row:CreateTexture(nil, "ARTWORK"); row.separator:SetTexture(BACKGROUND)
                row.separator:SetVertexColor(.52, .34, .59, .7)
                row.separator:SetPoint("BOTTOMLEFT", 12, 0); row.separator:SetPoint("BOTTOMRIGHT", -12, 0); row.separator:SetHeight(1)
                row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot"); row.icon:SetSize(36, 36); row.icon:SetPoint("LEFT", 12, 0)
                row.name = row:CreateFontString(nil, "OVERLAY"); row.name:SetPoint("TOPLEFT", 60, -8); setFont(row.name, 13, { .78, .46, 1 })
                row.meta = row:CreateFontString(nil, "OVERLAY"); row.meta:SetPoint("BOTTOMLEFT", 60, 9); setFont(row.meta, 10, MUTED)
                row.sightings = row:CreateFontString(nil, "OVERLAY"); row.sightings:SetPoint("RIGHT", -16, 0); row.sightings:SetWidth(180); row.sightings:SetJustifyH("RIGHT"); setFont(row.sightings, 11, TEXT)
            end
            if row.text then row.text:Hide() end
            row:SetHeight(56); row:SetBackdrop(nil)
            row.icon:Show(); row.name:Show(); row.meta:Show(); row.sightings:Show(); row.separator:Show()
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(width)
            row.name:SetWidth(width - 255); row.meta:SetWidth(width - 255)
            row.name:SetText(wrapped.key); row.meta:SetText(U.SafeText(rare.zone) .. C:LocalizeDisplay("   •   zuerst ") .. U.Date(rare.firstSeen, true) .. C:LocalizeDisplay("   •   zuletzt ") .. U.Date(rare.lastSeen, true))
            row:EnableMouse(true)
            row.tooltipName, row.tooltipZone, row.firstSeen, row.lastSeen, row.sightingCount = wrapped.key, rare.zone, rare.firstSeen, rare.lastSeen, rare.sightings or 1
            row:SetScript("OnEnter", function(self)
                self.hoverShade:Show()
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.tooltipName, .78, .46, 1)
                GameTooltip:AddLine(C:LocalizeDisplay("Gebiet: ") .. U.SafeText(self.tooltipZone), .92, .85, .7)
                GameTooltip:AddLine(C:LocalizeDisplay("Erste Sichtung: ") .. (self.firstSeen and U.Date(self.firstSeen) or "nicht erfasst"), .72, .65, .52)
                GameTooltip:AddLine(C:LocalizeDisplay("Letzte Sichtung: ") .. (self.lastSeen and U.Date(self.lastSeen) or "nicht erfasst"), .72, .65, .52)
                GameTooltip:AddLine(C:LocalizeDisplay("Sichtungen: ") .. self.sightingCount, .92, .85, .7)
                C:ShowLocalizedTooltip()
            end)
            row:SetScript("OnLeave", function(self) self.hoverShade:Hide(); GameTooltip:Hide() end)
            row.sightings:SetText((rare.classification == "rareelite" and C:LocalizeDisplay("ELITE  •  ") or "") .. (rare.sightings or 1) .. C:LocalizeDisplay(" Sichtungen")); row:Show(); offset = offset + 58
        end
    end
    local usedRareRows = showRares and math.max(1, #rares) or 0
    for index = usedRareRows + 1, #rareRows do rareRows[index]:Hide() end
    scrollChild:SetHeight(math.max(1, offset + 10))
end

local function showOverviewRows()
    body:Hide()
    local width = availableContentWidth()
    local character = C.char
    local stats = U.Statistics(character)
    local sessionEnd = tonumber(character.lastSessionEnd) or 0
    if sessionEnd == 0 and tonumber(character.lastLogout) and tonumber(character.lastLogin) and
        character.lastLogout > 0 and character.lastLogout <= character.lastLogin then
        sessionEnd = character.lastLogout
    end
    local lastSession = sessionEnd > 0 and U.Date(sessionEnd, true) or "noch nicht erfasst"
    local zone = U.SafeText(character.lastZone, "Unbekannt")
    local playerName = U.SafeText(UnitName("player"), "Abenteurer")
    if not overviewHero then
        overviewHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        overviewHero:SetPoint("TOPLEFT", 4, 0); overviewHero:SetHeight(160)
        heroBackdrop(overviewHero)
        overviewHero.accent = overviewHero:CreateTexture(nil, "ARTWORK"); overviewHero.accent:Hide()
        overviewHero.accent:SetTexture(BACKGROUND); overviewHero.accent:SetVertexColor(1, .72, .18, 1)
        overviewHero.accent:SetPoint("TOPLEFT", 4, -4); overviewHero.accent:SetPoint("BOTTOMLEFT", 4, 4); overviewHero.accent:SetWidth(4)
        overviewHero.caption = overviewHero:CreateFontString(nil, "OVERLAY")
        overviewHero.caption:SetPoint("TOPLEFT", 20, -13); setFont(overviewHero.caption, 10, GOLD)
        overviewHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  DEINE REISE"))
        overviewHero.title = overviewHero:CreateFontString(nil, "OVERLAY")
        overviewHero.title:SetPoint("TOPLEFT", 19, -35); overviewHero.title:SetJustifyH("LEFT"); setFont(overviewHero.title, 26, TEXT)
        overviewHero.zone = overviewHero:CreateFontString(nil, "OVERLAY")
        overviewHero.zone:SetPoint("TOPLEFT", 21, -77); overviewHero.zone:SetJustifyH("LEFT"); setFont(overviewHero.zone, 12, GOLD)
        overviewHero.meta = overviewHero:CreateFontString(nil, "OVERLAY")
        overviewHero.meta:SetPoint("TOPLEFT", 21, -99); overviewHero.meta:SetJustifyH("LEFT"); setFont(overviewHero.meta, 10, MUTED)
        overviewHero.money = overviewHero:CreateFontString(nil, "OVERLAY")
        overviewHero.money:SetPoint("BOTTOMLEFT", 21, 16); overviewHero.money:SetJustifyH("LEFT"); setFont(overviewHero.money, 11, TEXT)
        overviewHero.rule = overviewHero:CreateTexture(nil, "ARTWORK")
        overviewHero.rule:SetTexture(BACKGROUND); overviewHero.rule:SetVertexColor(.58, .39, .14, .85)
        overviewHero.rule:SetPoint("BOTTOMLEFT", 20, 37); overviewHero.rule:SetPoint("BOTTOMRIGHT", -20, 37); overviewHero.rule:SetHeight(1)
        overviewHero.icon = overviewHero:CreateTexture(nil, "ARTWORK")
        overviewHero.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
        overviewHero.icon:SetSize(58, 58); overviewHero.icon:SetPoint("TOPRIGHT", -22, -22)
    end
    overviewHero:SetWidth(width)
    C:SetHeroMotif(overviewHero, "Overview")
    overviewHero.motifClip:ClearAllPoints()
    overviewHero.motifClip:SetPoint("TOPRIGHT", overviewHero, "TOPRIGHT", -5, -4)
    overviewHero.motifClip:SetSize(160, 152)
    overviewHero.motif:SetSize(160, 160)
    overviewHero.motif:SetAlpha(.46)
    overviewHero.icon:Hide()
    local summary = C.db.characters and C.db.characters[C.characterKey]
    overviewHero.title:SetText(C:LocalizeDisplay("Die Chronik von ") .. (summary and C:CharacterDisplayName(summary, playerName) or playerName))
    overviewHero.title:SetWidth(width - 185)
    overviewHero.zone:SetText(C:LocalizeDisplay("STUFE ") .. tostring(UnitLevel("player") or 0) .. "   •   " ..
        (summary and U.SafeText(summary.className, C:LocalizeDisplay("Abenteurer")) or C:LocalizeDisplay("Abenteurer")) .. "   •   " .. zone)
    overviewHero.zone:SetWidth(width - 185)
    overviewHero.meta:SetText(C:LocalizeDisplay("Letzte Sitzung: ") .. lastSession ..
        (character.lastInstance and character.lastInstance ~= "" and C:LocalizeDisplay("   •   Instanz: ") .. character.lastInstance or ""))
    overviewHero.meta:SetWidth(width - 185)
    overviewHero.rule:Hide()
    overviewHero.money:SetText(C:LocalizeDisplay("DEIN VERMÖGEN   ") .. U.Money(GetMoney and GetMoney() or character.money))
    overviewHero:Show()

    local railWidth = math.max(205, math.min(250, math.floor(width * .26)))
    local mainWidth = width - railWidth - 28
    local railX = mainWidth + 24
    local function chapter(index, title, action, target, x, y, sectionWidth)
        local item = overviewHeaders[index]
        if not item then
            item = CreateFrame("Button", nil, scrollChild)
            item:SetHeight(29)
            item.title = item:CreateFontString(nil, "OVERLAY")
            item.title:SetPoint("TOPLEFT", 0, 0); setFont(item.title, 16, GOLD)
            item.action = item:CreateFontString(nil, "OVERLAY")
            item.action:SetPoint("TOPRIGHT", 0, -5); item.action:SetJustifyH("RIGHT")
            setFont(item.action, 9, MUTED)
            item:SetScript("OnClick", function(self) C:ShowPage(self.targetPage) end)
            item:SetScript("OnEnter", function(self) self.title:SetTextColor(1, .94, .58) end)
            item:SetScript("OnLeave", function(self) self.title:SetTextColor(unpack(GOLD)) end)
            overviewHeaders[index] = item
        end
        item:ClearAllPoints(); item:SetPoint("TOPLEFT", 12 + x, -y)
        item:SetWidth(sectionWidth - 12)
        item.title:SetText(C:LocalizeDisplay(title)); item.action:SetText(C:LocalizeDisplay(action))
        item.targetPage = target; item:Show()
    end
    chapter(1, "Dein nächster Schritt", "ZIELE ÖFFNEN", "goals", 0, 179, mainWidth)
    chapter(2, "Deine Reisespur", "ABENTEUER ÖFFNEN", "timeline", 0, 390, mainWidth)
    chapter(3, "Deine Reise in Zahlen", "", "stats", railX, 179, railWidth)
    for index = 4, #overviewHeaders do overviewHeaders[index]:Hide() end

    local goals = {}
    for _, goal in ipairs(character.goals or {}) do
        if not goal.done then goals[#goals + 1] = goal end
    end
    local steps = {
        { "01  /  DEIN MEILENSTEIN", #goals > 0 and U.SafeText(goals[1].text) or "Schreib dein nächstes Ziel auf",
            #goals > 0 and "DEIN WEG DURCH AZEROTH" or "EIN ZIEL GIBT DEINER REISE RICHTUNG", "goals", 22, 218, 78, 21 },
        { "02  /  IM QUESTLOG", stats.activeQuests > 0 and (stats.activeQuests .. C:LocalizeDisplay(" aktive Quests")) or "Die Welt wartet auf dich",
            stats.activeQuests > 0 and "DEINE NÄCHSTEN AUFGABEN" or "ENTDECKE DEINE NÄCHSTE GESCHICHTE",
            stats.activeQuests > 0 and "quests" or "zones", 22, 310, 56, 14 },
    }
    for index, step in ipairs(steps) do
        local entry = overviewGoals[index]
        if not entry then
            entry = CreateFrame("Button", nil, scrollChild)
            entry.kicker = entry:CreateFontString(nil, "OVERLAY")
            entry.kicker:SetPoint("TOPLEFT", 0, 0); setFont(entry.kicker, 10, GOLD)
            entry.headline = entry:CreateFontString(nil, "OVERLAY")
            entry.headline:SetPoint("TOPLEFT", 0, -22); entry.headline:SetJustifyH("LEFT")
            setFont(entry.headline, step[8], TEXT)
            entry.caption = entry:CreateFontString(nil, "OVERLAY")
            entry.caption:SetPoint("BOTTOMLEFT", 0, 3); setFont(entry.caption, 9, MUTED)
            entry:SetScript("OnClick", function(self) C:ShowPage(self.targetPage) end)
            entry:SetScript("OnEnter", function(self) self.headline:SetTextColor(1, .9, .55) end)
            entry:SetScript("OnLeave", function(self) self.headline:SetTextColor(unpack(TEXT)) end)
            overviewGoals[index] = entry
        end
        entry:ClearAllPoints(); entry:SetPoint("TOPLEFT", step[5], -step[6])
        entry:SetSize(mainWidth - 42, step[7])
        entry.kicker:SetText(C:LocalizeDisplay(step[1])); entry.headline:SetText(C:LocalizeGoalText(C:LocalizeDisplay(step[2])))
        entry.headline:SetWidth(mainWidth - 65)
        entry.caption:SetText(C:LocalizeDisplay(step[3])); entry.targetPage = step[4]
        entry:Show()
    end
    for index = #steps + 1, #overviewGoals do overviewGoals[index]:Hide() end

    local values = {
        { stats.zones, "ENTDECKTE GEBIETE", "zones" },
        { stats.activeQuests, "AKTIVE QUESTS", "quests" },
        { stats.openGoals, "OFFENE ZIELE", "goals" },
        { stats.memories, "ERINNERUNGEN", "timeline" },
    }
    for index, value in ipairs(values) do
        local note = overviewStats[index]
        if not note then
            note = CreateFrame("Button", nil, scrollChild)
            note.number = note:CreateFontString(nil, "OVERLAY")
            note.number:SetPoint("TOPLEFT", 0, 0); setFont(note.number, 30, GOLD)
            note.label = note:CreateFontString(nil, "OVERLAY")
            note.label:SetPoint("TOPLEFT", 54, -14); setFont(note.label, 10, MUTED)
            note:SetScript("OnClick", function(self) C:ShowPage(self.targetPage) end)
            note:SetScript("OnEnter", function(self) self.number:SetTextColor(1, .94, .58) end)
            note:SetScript("OnLeave", function(self) self.number:SetTextColor(unpack(GOLD)) end)
            overviewStats[index] = note
        end
        note:ClearAllPoints(); note:SetPoint("TOPLEFT", railX + 12, -(220 + (index - 1) * 60))
        note:SetSize(railWidth - 20, 54)
        note.number:SetText(value[1]); note.label:SetText(C:LocalizeDisplay(value[2]))
        note.label:SetWidth(railWidth - 82)
        note.targetPage = value[3]; note:Show()
    end
    for index = #values + 1, #overviewStats do overviewStats[index]:Hide() end

    local seenOverviewEvents, eventUsed, loginIncluded = {}, 0, false
    local kindLabels = {
        quest = "QUEST", zone = "GEBIET", profession = "BERUF", recipe = "REZEPT",
        rare = "RARE", boss = "BOSS", dungeon = "INSTANZ", level = "STUFE",
        goal = "ZIEL", note = "NOTIZ", login = "REISE", merchant = "HÄNDLER", death = "TOD",
    }
    for _, event in ipairs(character.events or {}) do
        local eventKey = tostring(event.kind or "") .. "\031" .. tostring(event.text or "") .. "\031" ..
            tostring(math.floor((tonumber(event.time) or 0) / 60))
        local noise = event.text == "Gebiet entdeckt: Unbekannt" or
            event.text == "Berufe und Fertigkeiten aktualisiert" or
            event.text == "Abenteuer fortgesetzt in Unbekannt" or
            (event.kind == "login" and loginIncluded)
        if not noise and not seenOverviewEvents[eventKey] then
            seenOverviewEvents[eventKey] = true
            if event.kind == "login" then loginIncluded = true end
            eventUsed = eventUsed + 1
            if eventUsed > 5 then break end
            local entry = overviewEvents[eventUsed]
            if not entry then
                entry = CreateFrame("Button", nil, scrollChild)
                overviewEvents[eventUsed] = entry
            end
            if not entry.number then
                entry.number = entry:CreateFontString(nil, "OVERLAY")
                entry.number:SetPoint("LEFT", 5, 0); setFont(entry.number, 18, GOLD)
                entry.date = entry:CreateFontString(nil, "OVERLAY")
                entry.date:SetPoint("TOPLEFT", 72, -3); setFont(entry.date, 9, GOLD)
                entry.kind = entry:CreateFontString(nil, "OVERLAY")
                entry.kind:SetPoint("TOPRIGHT", -3, -3); entry.kind:SetJustifyH("RIGHT")
                setFont(entry.kind, 9, MUTED)
                entry.text = entry.text or entry:CreateFontString(nil, "OVERLAY")
                entry.text:ClearAllPoints(); entry.text:SetPoint("TOPLEFT", 72, -22)
                entry.text:SetJustifyH("LEFT"); setFont(entry.text, 12, TEXT)
                entry.node = entry:CreateTexture(nil, "ARTWORK")
                entry.node:SetTexture(BACKGROUND); entry.node:SetVertexColor(1, .72, .18, .9)
                entry.node:SetSize(5, 5); entry.node:SetPoint("LEFT", 48, 0)
                entry:SetScript("OnClick", function() C:ShowPage("timeline") end)
                entry:SetScript("OnEnter", function(self) self.text:SetTextColor(1, .9, .55) end)
                entry:SetScript("OnLeave", function(self) self.text:SetTextColor(unpack(TEXT)) end)
                overviewEvents[eventUsed] = entry
            end
            entry:ClearAllPoints(); entry:SetPoint("TOPLEFT", 24, -(430 + (eventUsed - 1) * 50))
            entry:SetSize(mainWidth - 40, 47)
            entry.number:Show(); entry.date:Show(); entry.kind:Show(); entry.node:Show()
            entry.text:ClearAllPoints(); entry.text:SetPoint("TOPLEFT", 72, -22)
            entry.number:SetText(string.format("%02d", eventUsed))
            entry.date:SetText(U.Date(event.time, true))
            entry.kind:SetText(C:LocalizeDisplay(kindLabels[event.kind] or "CHRONIK"))
            entry.text:SetText(C:LocalizeEventText(U.SafeText(event.text)))
            entry.text:SetWidth(mainWidth - 125)
            entry:Show()
        end
    end
    eventUsed = math.min(5, eventUsed)
    if eventUsed == 0 then
        local entry = overviewEvents[1]
        if not entry then
            entry = CreateFrame("Button", nil, scrollChild)
            entry.text = entry:CreateFontString(nil, "OVERLAY")
            entry.text:SetPoint("LEFT", 0, 0); setFont(entry.text, 12, MUTED)
            entry:SetScript("OnClick", function() C:ShowPage("timeline") end)
            overviewEvents[1] = entry
        end
        entry:ClearAllPoints(); entry:SetPoint("TOPLEFT", 24, -430)
        entry:SetSize(mainWidth - 40, 47)
        entry.text:SetText(C:LocalizeDisplay("Deine nächsten Erinnerungen erscheinen hier."))
        if entry.number then entry.number:Hide() end
        if entry.date then entry.date:Hide() end
        if entry.kind then entry.kind:Hide() end
        if entry.node then entry.node:Hide() end
        entry:Show(); eventUsed = 1
    end
    for index = eventUsed + 1, #overviewEvents do overviewEvents[index]:Hide() end

    overviewHero.routeDots = overviewHero.routeDots or {}
    local routeCount = math.max(1, (eventUsed - 1) * 50 + 24)
    local dotsNeeded = math.min(44, math.floor(routeCount / 7))
    for index = 1, dotsNeeded do
        local dot = overviewHero.routeDots[index]
        if not dot then
            dot = scrollChild:CreateTexture(nil, "ARTWORK")
            dot:SetTexture(BACKGROUND); dot:SetSize(2, 2)
            overviewHero.routeDots[index] = dot
        end
        local progress = (index - 1) / math.max(1, dotsNeeded - 1)
        local curveX = 76 + math.sin(progress * 7.5) * 8
        dot:ClearAllPoints(); dot:SetPoint("TOPLEFT", curveX, -(443 + progress * routeCount))
        dot:SetVertexColor(.94, .66, .21, .36)
        dot:Show()
    end
    for index = dotsNeeded + 1, #overviewHero.routeDots do overviewHero.routeDots[index]:Hide() end
    scrollChild:SetHeight(math.max(710, 440 + eventUsed * 50))
end

local timelineKinds = {
    quest = { "Quest", "quests", "Interface\\Icons\\INV_Misc_Note_01", { 1, .72, .18 } },
    goal = { "Ziel", "quests", "Interface\\Icons\\Ability_Hunter_MarkedForDeath", { 1, .72, .18 } },
    zone = { "Gebiet", "travel", "Interface\\Icons\\Spell_Nature_EarthBind", { .38, .72, .95 } },
    login = { "Reise", "travel", "Interface\\Icons\\INV_Misc_Book_09", { .38, .72, .95 } },
    dungeon = { "Instanz", "travel", "Interface\\Icons\\INV_Misc_Key_03", { .38, .72, .95 } },
    boss = { "Boss", "travel", "Interface\\Icons\\INV_Misc_Head_Dragon_01", { .78, .46, 1 } },
    rare = { "Seltene Kreatur", "travel", "Interface\\Icons\\Ability_Hunter_SniperShot", { .78, .46, 1 } },
    death = { "Tod", "travel", "Interface\\AddOns\\Chronicle\\DeathMedallion", { .9, .36, .36 } },
    level = { "Stufe", "travel", "Interface\\Icons\\INV_Misc_Book_09", { .38, .72, .95 } },
    profession = { "Beruf", "professions", "Interface\\Icons\\Trade_LeatherWorking", { .96, .57, .18 } },
    recipe = { "Rezept", "professions", "Interface\\Icons\\INV_Scroll_03", { .96, .57, .18 } },
    merchant = { "Händler", "other", "Interface\\Icons\\INV_Misc_Coin_01", { .74, .66, .51 } },
    note = { "Notiz", "other", "Interface\\Icons\\INV_Misc_Note_05", { .74, .66, .51 } },
}

local function activeTimelineQuest(event)
    if not event or event.kind ~= "quest" or type(event.text) ~= "string" then return nil end
    local title = event.text:match("^Quest angenommen: (.+)$") or event.text:match("^Quest abgeschlossen: (.+)$")
    if not title then return nil end
    local active = (C.API.ActiveQuests and C.API.ActiveQuests()) or C.char.activeQuests or {}
    local savedID = event.details and tonumber(event.details.questID)
    if savedID and active[tostring(savedID)] and active[tostring(savedID)].title == title then return savedID end
    local match
    for _, quest in pairs(active) do
        if quest.title == title then
            if match then return nil end -- Identical titles cannot be assigned safely without an ID.
            match = tonumber(quest.id)
        end
    end
    return match
end

local function openTimelineQuest(event)
    local questID = activeTimelineQuest(event)
    if not questID then
        C:Print("Diese Quest ist nicht mehr im aktuellen Questlog oder lässt sich nicht eindeutig zuordnen.")
        return
    end
    if QuestMapFrame_OpenToQuestDetails then
        local ok = pcall(QuestMapFrame_OpenToQuestDetails, questID)
        if ok then return end
    end
    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        local ok = pcall(C_QuestLog.SetSelectedQuest, questID)
        if ok then
            if ToggleQuestLog then pcall(ToggleQuestLog) end
            return
        end
    end
    if GetQuestLogIndexByID and QuestLog_SetSelection then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and index and index > 0 then
            if ToggleQuestLog then pcall(ToggleQuestLog) end
            pcall(QuestLog_SetSelection, index)
            return
        end
    end
    C:Print("Das Questlog konnte für diese Quest nicht geöffnet werden.")
end

local function showQuestRows()
    body:Hide()
    local width = availableContentWidth()
    local query = questSearch and U.Trim(questSearch:GetText()):lower() or ""
    local currentQuests = (C.API.ActiveQuests and C.API.ActiveQuests()) or C.char.activeQuests or {}
    local totalActive = 0
    for _ in pairs(currentQuests) do totalActive = totalActive + 1 end
    local totalHistory = #(C.char.quests or {})
    local active, readyCount = {}, 0
    for _, quest in pairs(currentQuests) do
        local ready = false
        if C_QuestLog and C_QuestLog.IsComplete and quest.id then
            local ok, result = pcall(C_QuestLog.IsComplete, quest.id)
            ready = ok and result == true
        end
        if ready then readyCount = readyCount + 1 end
        if (not questReadyFilter or ready) and
            (query == "" or U.SafeText(quest.title):lower():find(query, 1, true)) then
            active[#active + 1] = { id = quest.id, title = quest.title, level = quest.level,
                zone = quest.zone, ready = ready }
        end
    end
    table.sort(active, function(a, b)
        local az, bz = U.SafeText(a.zone, "Weitere Quests"), U.SafeText(b.zone, "Weitere Quests")
        if az ~= bz then return az < bz end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
        return U.SafeText(a.title) < U.SafeText(b.title)
    end)
    local history = {}
    for _, quest in ipairs(C.char.quests or {}) do
        if (questHistoryFilter == "all" or quest.status == questHistoryFilter) and
            (query == "" or U.SafeText(quest.title):lower():find(query, 1, true)) then
            history[#history + 1] = quest
        end
    end
    table.sort(history, function(a, b) return (tonumber(a.time) or 0) > (tonumber(b.time) or 0) end)
    if not questHero then
        questHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        questHero:SetHeight(92)
        questHero.accent = questHero:CreateTexture(nil, "ARTWORK"); questHero.accent:Hide()
        questHero.accent:SetTexture(BACKGROUND); questHero.accent:SetVertexColor(.95, .67, .15)
        questHero.accent:SetPoint("TOPLEFT", 4, -4); questHero.accent:SetPoint("BOTTOMLEFT", 4, 4); questHero.accent:SetWidth(4)
        questHero.caption = questHero:CreateFontString(nil, "OVERLAY")
        questHero.caption:SetPoint("TOPLEFT", 19, -12); setFont(questHero.caption, 10, GOLD)
        questHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  QUESTJOURNAL"))
        questHero.summary = questHero:CreateFontString(nil, "OVERLAY")
        questHero.summary:SetPoint("TOPLEFT", 19, -32); setFont(questHero.summary, 23, TEXT)
        questHero.detail = questHero:CreateFontString(nil, "OVERLAY")
        questHero.detail:SetPoint("TOPLEFT", 20, -63); setFont(questHero.detail, 10, MUTED)
    end
    questHero:ClearAllPoints(); questHero:SetPoint("TOPLEFT", 4, 0); questHero:SetWidth(width); questHero:SetHeight(92)
    heroBackdrop(questHero)
    C:SetHeroMotif(questHero, "Quests")
    questHero.summary:SetText(C:LocalizeDisplay("Deine Abenteuer"))
    questHero.detail:SetText(query ~= "" and (#active .. C:LocalizeDisplay(" aktive und ") .. #history .. C:LocalizeDisplay(" historische Treffer")) or
        (questView == "history" and C:LocalizeDisplay("Angenommene und abgeschlossene Quests deiner Reise") or
            C:LocalizeDisplay("Aufgaben und Ziele, nach Gebieten geordnet")))
    questHero:Show()
    local questDossier = questHero.dossier
    if not questSearch then
        questSearch = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        questSearch:SetHeight(25); questSearch:SetAutoFocus(false); questSearch:SetMaxLetters(80)
        questSearch:SetScript("OnEscapePressed", questSearch.ClearFocus)
        questSearch:SetScript("OnTextChanged", function(self)
            questSearchHint:SetShown(self:GetText() == "")
            if selected == "quests" then showQuestRows() end
        end)
        questSearchHint = questSearch:CreateFontString(nil, "ARTWORK")
        questSearchHint:SetPoint("LEFT", 7, 0); setFont(questSearchHint, 10, MUTED)
        questSearchHint:SetText(C:LocalizeDisplay("Quest suchen ..."))
    end
    local tabWidth = math.floor((width - 12) / 2)
    for index, option in ipairs({ { "active", "Aktiv (" .. totalActive .. ")" },
        { "history", "Historie (" .. totalHistory .. ")" } }) do
        local tab = questTabs[index]
        if not tab then
            tab = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(tab)
            tab:SetHeight(27)
            tab.label = tab:CreateFontString(nil, "OVERLAY")
            tab.label:SetPoint("CENTER"); setFont(tab.label, 11, TEXT)
            tab:SetScript("OnClick", function(self)
                questView = self.viewKey
                showQuestRows(); scroll:SetVerticalScroll(0)
            end)
            questTabs[index] = tab
        end
        tab.viewKey = option[1]
        tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", 4 + (index - 1) * (tabWidth + 8), -104)
        tab:SetWidth(tabWidth)
        backdrop(tab, questView == option[1] and .27 or .075,
            questView == option[1] and .18 or .055, questView == option[1] and .065 or .034, 1)
        tab.label:SetText(option[2]); tab.label:SetTextColor(unpack(questView == option[1] and GOLD or TEXT))
        tab:Show()
    end
    questSearch:ClearAllPoints(); questSearch:SetPoint("TOPLEFT", 8, -143)
    questSearch:SetWidth(math.min(questView == "history" and 260 or 310,
        width - (questView == "history" and 350 or 190))); questSearch:Show()
    if not questReadyButton then
        questReadyButton = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
        C:StyleChronicleButton(questReadyButton)
        questReadyButton:SetHeight(25)
        questReadyButton.label = questReadyButton:CreateFontString(nil, "OVERLAY")
        questReadyButton.label:SetPoint("CENTER"); setFont(questReadyButton.label, 10, TEXT)
        questReadyButton:SetScript("OnClick", function()
            questReadyFilter = not questReadyFilter
            showQuestRows(); scroll:SetVerticalScroll(0)
        end)
    end
    questReadyButton:ClearAllPoints(); questReadyButton:SetPoint("TOPRIGHT", -4, -143)
    questReadyButton:SetWidth(170)
    backdrop(questReadyButton, questReadyFilter and .16 or .075,
        questReadyFilter and .24 or .055, questReadyFilter and .075 or .034, 1)
    questReadyButton.label:SetText(C:LocalizeDisplay("Abgabebereit (") .. readyCount .. ")")
    if questReadyFilter then questReadyButton.label:SetTextColor(.48, .85, .45)
    else questReadyButton.label:SetTextColor(unpack(TEXT)) end
    questReadyButton:SetShown(questView == "active")
    local historyOptions = { { "all", "Alle" }, { "completed", "Abgeschlossen" },
        { "accepted", "Angenommen" } }
    local historyButtonWidth = 106
    for index, option in ipairs(historyOptions) do
        local button = questHistoryButtons[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button:SetHeight(25)
            button.label = button:CreateFontString(nil, "OVERLAY")
            button.label:SetPoint("CENTER"); setFont(button.label, 10, TEXT)
            button:SetScript("OnClick", function(self)
                questHistoryFilter = self.filterKey
                showQuestRows(); scroll:SetVerticalScroll(0)
            end)
            questHistoryButtons[index] = button
        end
        button.filterKey = option[1]
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", -4 - (#historyOptions - index) * (historyButtonWidth + 5), -143)
        button:SetWidth(historyButtonWidth)
        backdrop(button, questHistoryFilter == option[1] and .25 or .075,
            questHistoryFilter == option[1] and .17 or .055,
            questHistoryFilter == option[1] and .06 or .034, 1)
        button.label:SetText(option[2])
        button.label:SetTextColor(unpack(questHistoryFilter == option[1] and GOLD or TEXT))
        button:SetShown(questView == "history")
    end
    local offset, usedHeaders, usedCards, usedZones = 180, 0, 0, 0
    local listWidth = math.floor(width * .49)
    local dossierWidth = width - listWidth - 14
    local entries = questView == "active" and active or history
    local selectedQuest
    for _, quest in ipairs(entries) do
        local key = questView .. ":" .. tostring(quest.id or quest.title) .. ":" .. tostring(quest.time or "")
        if key == C.questSelection then selectedQuest = quest; break end
    end
    if not selectedQuest then
        selectedQuest = entries[1]
        C.questSelection = selectedQuest and (questView .. ":" .. tostring(selectedQuest.id or selectedQuest.title) .. ":" .. tostring(selectedQuest.time or "")) or nil
    end
    if not questDossier then
        questDossier = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        questHero.dossier = questDossier
        questDossier.caption = questDossier:CreateFontString(nil, "OVERLAY")
        questDossier.caption:SetPoint("TOPLEFT", 19, -15); setFont(questDossier.caption, 10, GOLD)
        questDossier.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  QUESTDOSSIER"))
        questDossier.title = questDossier:CreateFontString(nil, "OVERLAY")
        questDossier.title:SetPoint("TOPLEFT", 19, -43); setFont(questDossier.title, 21, TEXT)
        questDossier.title:SetJustifyH("LEFT")
        questDossier.meta = questDossier:CreateFontString(nil, "OVERLAY")
        questDossier.meta:SetPoint("TOPLEFT", 20, -81); setFont(questDossier.meta, 11, MUTED)
        questDossier.meta:SetJustifyH("LEFT")
        questDossier.rule = questDossier:CreateTexture(nil, "ARTWORK")
        questDossier.rule:SetTexture(BACKGROUND); questDossier.rule:SetVertexColor(.57, .39, .15, .85)
        questDossier.rule:SetPoint("TOPLEFT", 19, -111); questDossier.rule:SetPoint("TOPRIGHT", -19, -111)
        questDossier.rule:SetHeight(1)
        questDossier.status = questDossier:CreateFontString(nil, "OVERLAY")
        questDossier.status:SetPoint("TOPLEFT", 20, -130); setFont(questDossier.status, 12, GOLD)
        questDossier.textScroll = CreateFrame("ScrollFrame", nil, questDossier)
        questDossier.textScroll:SetPoint("TOPLEFT", 20, -163)
        questDossier.textScroll:EnableMouseWheel(true)
        questDossier.textScroll:SetScript("OnMouseWheel", function(self, delta)
            self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(),
                self:GetVerticalScroll() - delta * 24)))
        end)
        questDossier.textChild = CreateFrame("Frame", nil, questDossier.textScroll)
        questDossier.textChild:SetSize(100, 1)
        questDossier.textScroll:SetScrollChild(questDossier.textChild)
        questDossier.info = questDossier.textChild:CreateFontString(nil, "OVERLAY")
        questDossier.info:SetPoint("TOPLEFT", 0, 0); setFont(questDossier.info, 12, MUTED)
        questDossier.info:SetJustifyH("LEFT"); questDossier.info:SetJustifyV("TOP")
        questDossier.more = questDossier:CreateFontString(nil, "OVERLAY")
        questDossier.more:SetPoint("BOTTOMRIGHT", -22, 56); setFont(questDossier.more, 9, GOLD)
        questDossier.more:SetText(C:LocalizeDisplay("WEITERLESEN"))
        questDossier.open = CreateFrame("Button", nil, questDossier, "BackdropTemplate")
        C:StyleChronicleButton(questDossier.open)
        questDossier.open:SetPoint("BOTTOMLEFT", 19, 20)
        questDossier.open:SetPoint("BOTTOMRIGHT", -19, 20)
        questDossier.open:SetHeight(30)
        questDossier.open.label = questDossier.open:CreateFontString(nil, "OVERLAY")
        questDossier.open.label:SetPoint("CENTER"); setFont(questDossier.open.label, 11, GOLD)
        questDossier.open.label:SetText(C:LocalizeDisplay("Im WoW-Questlog öffnen"))
        questDossier.open:SetScript("OnClick", function(self)
            if self.questID then
                openTimelineQuest({ kind = "quest", text = "Quest angenommen: " .. self.questTitle,
                    details = { questID = self.questID } })
            end
        end)
    end
    questDossier:ClearAllPoints()
    questDossier:SetPoint("TOPLEFT", 4 + listWidth + 14, -180)
    questDossier:SetSize(dossierWidth, 390)
    heroBackdrop(questDossier)
    questDossier.title:SetWidth(dossierWidth - 40)
    questDossier.meta:SetWidth(dossierWidth - 40)
    questDossier.info:SetWidth(dossierWidth - 55)
    questDossier.title:SetText(selectedQuest and U.SafeText(selectedQuest.title) or C:LocalizeDisplay("Keine Quest ausgewählt"))
    questDossier.meta:SetText(selectedQuest and (U.SafeText(selectedQuest.zone, C:LocalizeDisplay("Unbekanntes Gebiet")) ..
        (selectedQuest.level and (C:LocalizeDisplay("  |  Stufe ") .. selectedQuest.level) or "")) or C:LocalizeDisplay("Dein persönliches Questjournal"))
    local isReady = selectedQuest and selectedQuest.ready
    local isHistory = questView == "history"
    questDossier.status:SetText(not selectedQuest and C:LocalizeDisplay("DEIN WEG BEGINNT HIER") or
        (isHistory and (selectedQuest.status == "completed" and C:LocalizeDisplay("ABGESCHLOSSEN") or C:LocalizeDisplay("ANGENOMMEN")) or
            (isReady and C:LocalizeDisplay("BEREIT ZUR ABGABE") or C:LocalizeDisplay("IN BEARBEITUNG"))))
    questDossier.status:SetTextColor(isReady and .43 or 1, isReady and .84 or .82, isReady and .45 or .1)
    local questInfo = not selectedQuest and "Wähle links eine Quest aus, um ihre Aufzeichnung zu sehen." or
        (isHistory and ("Aufgezeichnet am " .. date("%d.%m.%Y um %H:%M", tonumber(selectedQuest.time) or time()) ..
            "\n\nDiese Erinnerung bleibt in deiner Chronicle erhalten.") or
            "Weitere Details im WoW-Questlog öffnen.")
    if selectedQuest and not isHistory and selectedQuest.id then
        local story, assignment, goals = nil, nil, {}
        if C_QuestLog and C_QuestLog.GetQuestDescription then
            local ok, description = pcall(C_QuestLog.GetQuestDescription, selectedQuest.id)
            if ok and type(description) == "string" and description ~= "" then
                story = description
            end
        end
        if C.API.QuestText then
            local description, narrative = C.API.QuestText(selectedQuest.id)
            if not story and type(description) == "string" and description ~= "" then story = description end
            if type(narrative) == "string" and narrative ~= "" and narrative ~= description then
                assignment = narrative
            end
        end
        if C_QuestLog and C_QuestLog.GetQuestObjectives then
            local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, selectedQuest.id)
            if ok and type(objectives) == "table" and #objectives > 0 then
                for index = 1, math.min(5, #objectives) do
                    local objective = objectives[index]
                    if type(objective) == "table" and objective.text then
                        goals[#goals + 1] = (objective.finished and "✓ " or "• ") .. objective.text
                    end
                end
            end
        end
        if #goals > 0 or story or assignment then
            local parts = {}
            if #goals > 0 then parts[#parts + 1] = "|cffffd100ZIELE|r\n" .. table.concat(goals, "\n") end
            if story then parts[#parts + 1] = "|cffffd100GESCHICHTE|r\n" .. story end
            if assignment then parts[#parts + 1] = "|cffffd100AUFTRAG|r\n" .. assignment end
            questInfo = table.concat(parts, "\n\n")
        end
    end
    questDossier.info:SetText(questInfo)
    local textHeight = math.max(1, questDossier.info:GetStringHeight() or 1)
    local dossierHeight = math.min(390, math.max(260, 225 + textHeight))
    questDossier:SetHeight(dossierHeight)
    questDossier.textScroll:SetPoint("BOTTOMRIGHT", -30, 61)
    questDossier.textChild:SetSize(dossierWidth - 55, textHeight + 5)
    questDossier.textScroll:SetVerticalScroll(0)
    questDossier.more:SetShown(textHeight + 5 > dossierHeight - 224)
    questDossier.open.questID = selectedQuest and not isHistory and tonumber(selectedQuest.id) or nil
    questDossier.open.questTitle = selectedQuest and U.SafeText(selectedQuest.title) or ""
    backdrop(questDossier.open, .22, .14, .055, 1)
    questDossier.open:SetShown(questDossier.open.questID ~= nil)
    questDossier:Show()
    local function section(label, count)
        usedHeaders = usedHeaders + 1
        local row = questHeaders[usedHeaders]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild); row:SetHeight(32)
            row.label = row:CreateFontString(nil, "OVERLAY")
            row.label:SetPoint("LEFT", 8, 0); setFont(row.label, 14, GOLD)
            row.count = row:CreateFontString(nil, "OVERLAY")
            row.count:SetPoint("RIGHT", -10, 0); setFont(row.count, 10, MUTED)
            row.rule = row:CreateTexture(nil, "ARTWORK")
            row.rule:SetTexture(BACKGROUND); row.rule:SetVertexColor(.5, .35, .13, .8)
            row.rule:SetPoint("BOTTOMLEFT", 8, 1); row.rule:SetPoint("BOTTOMRIGHT", -8, 1); row.rule:SetHeight(1)
            questHeaders[usedHeaders] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(listWidth)
        row.label:SetText(label); row.count:SetText(count); row:Show(); offset = offset + 39
    end
    local function zoneHeader(label, count, ready)
        usedZones = usedZones + 1
        local row = questZoneHeaders[usedZones]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetHeight(35); row:EnableMouse(true)
            row.iconPlate = row:CreateTexture(nil, "BACKGROUND")
            row.iconPlate:SetTexture(BACKGROUND)
            row.iconPlate:SetSize(27, 27); row.iconPlate:SetPoint("LEFT", 8, 0)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetTexture("Interface\\Icons\\Spell_Nature_EarthBind")
            row.icon:SetSize(22, 22); row.icon:SetPoint("CENTER", row.iconPlate, "CENTER", 0, 0)
            row.icon:SetTexCoord(.08, .92, .08, .92)
            row.caption = row:CreateFontString(nil, "OVERLAY")
            row.caption:SetPoint("TOPLEFT", 44, -5); setFont(row.caption, 8, MUTED)
            row.caption:SetText(C:LocalizeDisplay("QUESTGEBIET"))
            row.title = row:CreateFontString(nil, "OVERLAY")
            row.title:SetPoint("LEFT", 27, 0); row.title:SetJustifyH("LEFT"); setFont(row.title, 13, GOLD)
            row.count = row:CreateFontString(nil, "OVERLAY")
            row.count:SetPoint("RIGHT", -10, 0); setFont(row.count, 9, MUTED)
            row.toggle = row:CreateFontString(nil, "OVERLAY")
            row.toggle:SetPoint("LEFT", 8, 0)
            row.toggle:SetJustifyH("CENTER"); setFont(row.toggle, 14, GOLD)
            row.accent = row:CreateTexture(nil, "ARTWORK"); row.accent:Hide()
            row.accent:SetTexture(BACKGROUND); row.accent:SetPoint("TOPLEFT", 3, -3)
            row.accent:SetPoint("BOTTOMLEFT", 3, 3); row.accent:SetWidth(3)
            row.lowerRule = row:CreateTexture(nil, "ARTWORK")
            row.lowerRule:SetTexture(BACKGROUND)
            row.lowerRule:SetPoint("BOTTOMLEFT", 8, 1)
            row.lowerRule:SetPoint("BOTTOMRIGHT", -8, 1)
            row.lowerRule:SetHeight(1)
            row:SetScript("OnEnter", function(self)
                self:SetBackdropColor(.24, .15, .06, .55)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.zoneKey or C:LocalizeDisplay("Questgebiet"), 1, .82, .1)
                GameTooltip:AddLine(C:LocalizeDisplay("Klicken zum Auf- oder Zuklappen"), .82, .76, .63)
                C:ShowLocalizedTooltip()
            end)
            row:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0); GameTooltip:Hide()
            end)
            row:SetScript("OnMouseUp", function(self, button)
                if button ~= "LeftButton" then return end
                questZoneExpanded[self.zoneKey] = not (questZoneExpanded[self.zoneKey] ~= false)
                GameTooltip:Hide(); showQuestRows()
            end)
            questZoneHeaders[usedZones] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(listWidth)
        backdrop(row, .13, .087, .045, 1)
        row:SetBackdropColor(0, 0, 0, 0)
        row:SetBackdropBorderColor(0, 0, 0, 0)
        row.iconPlate:Hide(); row.icon:Hide(); row.caption:Hide()
        row.zoneKey = label
        row.caption:SetText(C:LocalizeDisplay("KAPITEL ") .. string.format("%02d", usedZones) .. C:LocalizeDisplay("  /  QUESTGEBIET"))
        row.title:SetText(label); row.title:SetWidth(listWidth - 170)
        row.count:SetText(count .. (count == 1 and C:LocalizeDisplay(" QUEST") or C:LocalizeDisplay(" QUESTS")) ..
            (ready > 0 and ("  •  " .. ready .. C:LocalizeDisplay(" BEREIT")) or ""))
        row.toggle:SetText(questZoneExpanded[label] == false and "+" or "-")
        row.toggle:SetTextColor(unpack(GOLD))
        row.lowerRule:SetVertexColor(ready > 0 and .22 or .5, ready > 0 and .5 or .33,
            ready > 0 and .22 or .12, .55)
        row.accent:SetVertexColor(ready > 0 and .38 or .94, ready > 0 and .82 or .63,
            ready > 0 and .42 or .17)
        row:Show(); offset = offset + 38
    end
    local function card(title, detail, icon, questID, event, completed, level, ready, historyStatus, questRecord)
        usedCards = usedCards + 1
        local row = questCards[usedCards]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetHeight(48); row:EnableMouse(true)
            row.topShade = row:CreateTexture(nil, "BACKGROUND")
            row.topShade:SetTexture(BACKGROUND)
            row.topShade:SetPoint("TOPLEFT", 3, -2); row.topShade:SetPoint("TOPRIGHT", -3, -2)
            row.topShade:SetHeight(43)
            row.accent = row:CreateTexture(nil, "ARTWORK"); row.accent:Hide()
            row.accent:SetTexture(BACKGROUND); row.accent:SetPoint("TOPLEFT", 3, -3)
            row.accent:SetPoint("BOTTOMLEFT", 3, 3); row.accent:SetWidth(3)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(1, 1); row.icon:SetPoint("LEFT", 1, 0); row.icon:Hide()
            row.title = row:CreateFontString(nil, "OVERLAY")
            row.title:SetPoint("TOPLEFT", 28, -8); row.title:SetJustifyH("LEFT"); setFont(row.title, 12, TEXT)
            row.detail = row:CreateFontString(nil, "OVERLAY")
            row.detail:SetPoint("TOPLEFT", 28, -28); row.detail:SetJustifyH("LEFT"); setFont(row.detail, 9, MUTED)
            row.levelPlate = row:CreateTexture(nil, "ARTWORK")
            row.levelPlate:SetTexture(BACKGROUND)
            row.levelPlate:SetPoint("TOPRIGHT", -8, -9); row.levelPlate:SetSize(62, 17)
            row.level = row:CreateFontString(nil, "OVERLAY")
            row.level:SetPoint("CENTER", row.levelPlate, "CENTER", 0, 0)
            row.level:SetJustifyH("CENTER"); setFont(row.level, 10, GOLD)
            row.bottomRule = row:CreateTexture(nil, "ARTWORK")
            row.bottomRule:SetTexture(BACKGROUND)
            row.bottomRule:SetPoint("BOTTOMLEFT", 28, 2); row.bottomRule:SetPoint("BOTTOMRIGHT", -10, 2)
            row.bottomRule:SetHeight(1)
            row:SetScript("OnEnter", function(self)
                self.topShade:SetAlpha(self.isSelected and .5 or .16)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.questTitle or "Quest", 1, .82, .1)
                GameTooltip:AddLine(self.questDetail or "", .85, .77, .63)
                GameTooltip:AddLine(C:LocalizeDisplay("Klicken: Questdossier anzeigen"), .95, .74, .36)
                C:ShowLocalizedTooltip()
            end)
            row:SetScript("OnLeave", function(self)
                self.topShade:SetAlpha(self.isSelected and .5 or 0); GameTooltip:Hide()
            end)
            row:SetScript("OnMouseUp", function(self, button)
                if button ~= "LeftButton" then return end
                GameTooltip:Hide()
                C.questSelection = self.questKey
                showQuestRows()
            end)
            questCards[usedCards] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -offset); row:SetWidth(listWidth)
        local entry = questRecord
        row.questKey = entry and (questView .. ":" .. tostring(entry.id or entry.title) .. ":" .. tostring(entry.time or "")) or nil
        local chosen = row.questKey and row.questKey == C.questSelection
        row.isSelected = chosen
        backdrop(row, chosen and .24 or .105, chosen and .15 or .071, chosen and .055 or .045, chosen and 1 or .92)
        if not chosen then
            row:SetBackdropColor(0, 0, 0, 0)
            row:SetBackdropBorderColor(0, 0, 0, 0)
        end
        row.topShade:SetVertexColor(ready and .08 or .22, ready and .18 or .14,
            ready and .08 or .055, .55)
        row.topShade:SetAlpha(chosen and .5 or 0)
        if historyStatus == "completed" then row.accent:SetVertexColor(.35, .78, .47)
        elseif historyStatus == "accepted" then row.accent:SetVertexColor(.43, .66, .95)
        else row.accent:SetVertexColor(ready and .36 or (completed and .46 or .95),
            ready and .78 or (completed and .6 or .67), ready and .38 or (completed and .35 or .15)) end
        row.title:SetText(title); row.title:SetWidth(listWidth - 110)
        row.detail:SetText(detail:gsub(C:LocalizeDisplay("  |  Questlog öffnen"), "")); row.detail:SetWidth(listWidth - 45)
        row.level:SetText(level and (C:LocalizeDisplay("STUFE ") .. tostring(level)) or
            (historyStatus == "completed" and C:LocalizeDisplay("ERLEDIGT") or historyStatus == "accepted" and C:LocalizeDisplay("ANNAHME") or
                (completed and C:LocalizeDisplay("ARCHIV") or "")))
        row.level:SetTextColor(historyStatus == "completed" and .4 or
            (historyStatus == "accepted" and .51 or (ready and .38 or 1)),
            historyStatus == "completed" and .85 or
            (historyStatus == "accepted" and .72 or (ready and .85 or .82)),
            historyStatus == "completed" and .5 or
            (historyStatus == "accepted" and 1 or (ready and .4 or .1)))
        row.levelPlate:SetVertexColor(ready and .09 or .24, ready and .23 or .15,
            ready and .09 or .045, .95)
        row.levelPlate:Hide()
        row.detail:SetTextColor(ready and .57 or .72, ready and .82 or .65, ready and .52 or .52)
        row.bottomRule:SetVertexColor(ready and .24 or .45, ready and .5 or .32, ready and .22 or .12, .55)
        row.questTitle, row.questDetail, row.questID, row.questEvent = title, detail, questID, event
        row:Show(); offset = offset + 51
    end
    if questView == "active" then
        if questReadyFilter then section("Bereit zur Abgabe", #active .. " Quests") end
        if #active == 0 then card("Keine aktiven Quests", query == "" and "Neue Quests erscheinen hier automatisch." or "Keine Treffer.",
            "Interface\\Icons\\INV_Misc_Note_01", nil, nil, true) end
        local zoneCounts, zoneReady = {}, {}
        for _, quest in ipairs(active) do
            local zone = U.SafeText(quest.zone, "Weitere Quests")
            zoneCounts[zone] = (zoneCounts[zone] or 0) + 1
            if quest.ready then zoneReady[zone] = (zoneReady[zone] or 0) + 1 end
        end
        local lastZone
        for _, quest in ipairs(active) do
            local zone = U.SafeText(quest.zone, "Weitere Quests")
            if zone ~= lastZone then zoneHeader(zone, zoneCounts[zone], zoneReady[zone] or 0); lastZone = zone end
            if questZoneExpanded[zone] ~= false then
                card(U.SafeText(quest.title), quest.ready and "Bereit zur Abgabe  |  Questlog öffnen" or
                    "In Bearbeitung  |  Questlog öffnen",
                    "Interface\\Icons\\INV_Misc_Note_01", tonumber(quest.id), nil, false, quest.level, quest.ready, nil, quest)
            end
        end
    else
        section("Quest-Historie", #history .. " Einträge")
        if #history == 0 then card("Noch keine Quest-Erinnerungen", "Angenommene und abgeschlossene Quests erscheinen hier.",
            "Interface\\Icons\\INV_Misc_Note_01", nil, nil, true) end
        local dayCounts = {}
        for _, quest in ipairs(history) do
            local day = date("%d.%m.%Y", tonumber(quest.time) or time())
            dayCounts[day] = (dayCounts[day] or 0) + 1
        end
        local lastDay
        for index = 1, math.min(150, #history) do
            local quest = history[index]
            local day = date("%d.%m.%Y", tonumber(quest.time) or time())
            if day ~= lastDay then section(day, dayCounts[day] .. " Einträge"); lastDay = day end
            local isActive = quest.id and currentQuests[tostring(quest.id)]
            local title = U.SafeText(quest.title, "Quest #" .. tostring(quest.id or "?"))
            card(title, (quest.status == "completed" and "Abgeschlossen" or "Angenommen") .. "  |  " ..
                date("%H:%M", tonumber(quest.time) or time()) .. "  |  " .. U.SafeText(quest.zone, "Unbekannt"),
                "Interface\\Icons\\INV_Misc_Note_01", isActive and tonumber(quest.id) or nil,
                { kind = "quest", text = "Quest angenommen: " .. title, details = { questID = quest.id } },
                not isActive, nil, nil, quest.status, quest)
        end
    end
    for index = usedHeaders + 1, #questHeaders do questHeaders[index]:Hide() end
    for index = usedZones + 1, #questZoneHeaders do questZoneHeaders[index]:Hide() end
    for index = usedCards + 1, #questCards do questCards[index]:Hide() end
    scrollChild:SetHeight(math.max(710, offset + 10))
end

local function showZoneRows()
    body:Hide()
    local width = availableContentWidth()
    local query = zoneSearch and U.Trim(zoneSearch:GetText()):lower() or ""
    local zones, totalVisits, totalZones = {}, 0, 0
    for name, zone in pairs(C.char.zones or {}) do
        if U.IsKnownZone(name) then
            totalZones = totalZones + 1
            totalVisits = totalVisits + (tonumber(zone.visits) or 1)
            if query == "" or name:lower():find(query, 1, true) or
                U.SafeText(zone.lastSubZone, ""):lower():find(query, 1, true) then
                zones[#zones + 1] = { name = name, data = zone }
            end
        end
    end
    table.sort(zones, function(a, b)
        if zoneSort == "visits" and (a.data.visits or 0) ~= (b.data.visits or 0) then
            return (a.data.visits or 0) > (b.data.visits or 0)
        end
        if zoneSort == "recent" and (a.data.lastSeen or 0) ~= (b.data.lastSeen or 0) then
            return (a.data.lastSeen or 0) > (b.data.lastSeen or 0)
        end
        return a.name < b.name
    end)
    if not zoneHero then
        zoneHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        zoneHero:SetHeight(112)
        zoneHero.accent = zoneHero:CreateTexture(nil, "ARTWORK"); zoneHero.accent:Hide()
        zoneHero.accent:SetTexture(BACKGROUND); zoneHero.accent:SetVertexColor(.35, .72, .91)
        zoneHero.accent:SetPoint("TOPLEFT", 4, -4); zoneHero.accent:SetPoint("BOTTOMLEFT", 4, 4)
        zoneHero.accent:SetWidth(4)
        zoneHero.caption = zoneHero:CreateFontString(nil, "OVERLAY")
        zoneHero.caption:SetPoint("TOPLEFT", 20, -12); setFont(zoneHero.caption, 10, GOLD)
        zoneHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  DEINE REISE"))
        zoneHero.title = zoneHero:CreateFontString(nil, "OVERLAY")
        zoneHero.title:SetPoint("TOPLEFT", 19, -32); setFont(zoneHero.title, 23, TEXT)
        zoneHero.title:SetText(C:LocalizeDisplay("Deine Welt"))
        zoneHero.detail = zoneHero:CreateFontString(nil, "OVERLAY")
        zoneHero.detail:SetPoint("TOPLEFT", 20, -63); setFont(zoneHero.detail, 10, MUTED)
        zoneHero.rule = zoneHero:CreateTexture(nil, "ARTWORK")
        zoneHero.rule:SetTexture(BACKGROUND); zoneHero.rule:SetVertexColor(.57, .39, .16, .8)
        zoneHero.rule:SetPoint("TOPLEFT", 19, -82); zoneHero.rule:SetPoint("TOPRIGHT", -106, -82)
        zoneHero.rule:SetHeight(1)
        zoneHero.stats = zoneHero:CreateFontString(nil, "OVERLAY")
        zoneHero.stats:SetPoint("TOPLEFT", 20, -91); setFont(zoneHero.stats, 11, GOLD)
        zoneHero.icon = zoneHero:CreateTexture(nil, "ARTWORK")
        zoneHero.icon:SetTexture("Interface\\Icons\\Spell_Nature_EarthBind")
        zoneHero.icon:SetSize(50, 50); zoneHero.icon:SetPoint("TOPRIGHT", -26, -18)
    end
    zoneHero:ClearAllPoints(); zoneHero:SetPoint("TOPLEFT", 4, 0); zoneHero:SetWidth(width)
    heroBackdrop(zoneHero)
    C:SetHeroMotif(zoneHero, "Zones")
    zoneHero.icon:Hide()
    zoneHero.detail:SetText(query == "" and (C:LocalizeDisplay("Zuletzt: ") .. U.SafeText(C.char.lastZone, C:LocalizeDisplay("Unbekannt"))) or
        (#zones .. C:LocalizeDisplay(" Treffer für: ") .. query))
    zoneHero.stats:SetText(totalZones .. (totalZones == 1 and C:LocalizeDisplay(" GEBIET") or C:LocalizeDisplay(" GEBIETE")) ..
        "     |     " .. totalVisits .. (totalVisits == 1 and C:LocalizeDisplay(" BESUCH") or C:LocalizeDisplay(" BESUCHE")))
    zoneHero:Show()
    if not zoneSearch then
        zoneSearch = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        zoneSearch:SetHeight(25); zoneSearch:SetAutoFocus(false); zoneSearch:SetMaxLetters(80)
        zoneSearch:SetScript("OnEscapePressed", zoneSearch.ClearFocus)
        zoneSearch:SetScript("OnTextChanged", function(self)
            zoneSearchHint:SetShown(self:GetText() == "")
            if selected == "zones" then showZoneRows() end
        end)
        zoneSearchHint = zoneSearch:CreateFontString(nil, "ARTWORK")
        zoneSearchHint:SetPoint("LEFT", 7, 0); setFont(zoneSearchHint, 10, MUTED)
        zoneSearchHint:SetText(C:LocalizeDisplay("Gebiet suchen ..."))
    end
    zoneSearch:ClearAllPoints(); zoneSearch:SetPoint("TOPLEFT", 8, -127)
    zoneSearch:SetWidth(math.min(270, width - 355)); zoneSearch:Show()
    local sortOptions = { { "recent", "Zuletzt" }, { "visits", "Häufig" }, { "name", "A-Z" } }
    local buttonWidth = 95
    for index, option in ipairs(sortOptions) do
        local button = zoneSortButtons[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button:SetHeight(25)
            button.label = button:CreateFontString(nil, "OVERLAY")
            button.label:SetPoint("CENTER"); setFont(button.label, 10, TEXT)
            button:SetScript("OnClick", function(self)
                zoneSort = self.sortKey; showZoneRows(); scroll:SetVerticalScroll(0)
            end)
            zoneSortButtons[index] = button
        end
        button.sortKey = option[1]
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", -4 - (#sortOptions - index) * (buttonWidth + 5), -127)
        button:SetWidth(buttonWidth)
        backdrop(button, zoneSort == option[1] and .21 or .075,
            zoneSort == option[1] and .13 or .055, zoneSort == option[1] and .055 or .034, 1)
        button.label:SetText(option[2])
        button.label:SetTextColor(unpack(zoneSort == option[1] and GOLD or TEXT))
        button:Show()
    end
    local used = 0
    for index, entry in ipairs(zones) do
        used = used + 1
        local card = zoneCards[used]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild)
            card:SetHeight(164); card:EnableMouse(true)
            card.hover = card:CreateTexture(nil, "BACKGROUND")
            card.hover:SetTexture(BACKGROUND); card.hover:SetAllPoints(card)
            card.hover:SetVertexColor(.35, .23, .09, .14); card.hover:Hide()
            card.rule = card:CreateTexture(nil, "ARTWORK")
            card.rule:SetTexture(BACKGROUND); card.rule:SetVertexColor(.42, .29, .12, .8)
            card.rule:SetPoint("BOTTOMLEFT", 12, 0)
            card.rule:SetPoint("BOTTOMRIGHT", -12, 0); card.rule:SetHeight(1)
            card.number = card:CreateFontString(nil, "OVERLAY")
            card.number:SetPoint("TOPLEFT", 13, -37); setFont(card.number, 28, GOLD)
            card.caption = card:CreateFontString(nil, "OVERLAY")
            card.caption:SetPoint("TOPLEFT", 70, -10); setFont(card.caption, 10, GOLD)
            card.caption:SetJustifyH("LEFT")
            card.title = card:CreateFontString(nil, "OVERLAY")
            card.title:SetPoint("TOPLEFT", 69, -33)
            card.title:SetJustifyH("LEFT"); setFont(card.title, 23, TEXT)
            card.statRule = card:CreateTexture(nil, "ARTWORK")
            card.statRule:SetTexture(BACKGROUND)
            card.statRule:SetVertexColor(.48, .33, .14, .7)
            card.statRule:SetPoint("TOPLEFT", 70, -97)
            card.statRule:SetPoint("TOPRIGHT", -15, -97)
            card.statRule:SetHeight(1)
            card.firstLabel = card:CreateFontString(nil, "OVERLAY")
            card.firstLabel:SetPoint("TOPLEFT", 70, -110); setFont(card.firstLabel, 9, MUTED)
            card.firstLabel:SetText(C:LocalizeDisplay("ERSTER BESUCH"))
            card.first = card:CreateFontString(nil, "OVERLAY")
            card.first:SetPoint("TOPLEFT", 70, -129); setFont(card.first, 12, GOLD)
            card.first:SetJustifyH("LEFT")
            card.lastLabel = card:CreateFontString(nil, "OVERLAY")
            card.lastLabel:SetPoint("TOPLEFT", 340, -110); setFont(card.lastLabel, 9, MUTED)
            card.lastLabel:SetText(C:LocalizeDisplay("LETZTER BESUCH"))
            card.last = card:CreateFontString(nil, "OVERLAY")
            card.last:SetPoint("TOPLEFT", 340, -129); setFont(card.last, 12, GOLD)
            card.last:SetJustifyH("LEFT")
            card.sub = card:CreateFontString(nil, "OVERLAY")
            card.sub:SetPoint("TOPLEFT", 70, -70); setFont(card.sub, 11, MUTED)
            card.sub:SetJustifyH("LEFT")
            card:SetScript("OnEnter", function(self)
                self.hover:Show()
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.zoneName or C:LocalizeDisplay("Gebiet"), 1, .82, .1)
                GameTooltip:AddLine(C:LocalizeDisplay("Besuche: ") .. tostring(self.visitCount or 1), 1, .82, .1)
                GameTooltip:AddLine(C:LocalizeDisplay("Erstbesuch: ") .. (self.firstSeen and U.Date(self.firstSeen) or "nicht erfasst"), .8, .75, .64)
                GameTooltip:AddLine(C:LocalizeDisplay("Zuletzt: ") .. (self.lastSeen and U.Date(self.lastSeen) or "nicht erfasst"), .8, .75, .64)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self.hover:Hide(); GameTooltip:Hide()
            end)
            zoneCards[used] = card
        end
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -171 - (index - 1) * 174)
        card:SetWidth(width)
        card.number:SetText(string.format("%02d", index))
        card.title:SetWidth(width - 90)
        card.title:SetText(entry.name)
        local visits = tonumber(entry.data.visits) or 1
        card.caption:SetText("CHRONICLE  /  GEBIET  •  " .. visits ..
            (visits == 1 and C:LocalizeDisplay(" BESUCH") or C:LocalizeDisplay(" BESUCHE")))
        card.first:SetWidth(245); card.last:SetWidth(math.max(120, width - 355))
        card.sub:SetWidth(width - 90)
        card.first:SetText(tonumber(entry.data.firstSeen) and tonumber(entry.data.firstSeen) > 0 and
            U.Date(entry.data.firstSeen, true) or C:LocalizeDisplay("nicht erfasst"))
        card.last:SetText(tonumber(entry.data.lastSeen) and tonumber(entry.data.lastSeen) > 0 and
            U.Date(entry.data.lastSeen, true) or C:LocalizeDisplay("nicht erfasst"))
        card.sub:SetText(U.SafeText(entry.data.lastSubZone, C:LocalizeDisplay("Kein Untergebiet erfasst")))
        card.zoneName, card.visitCount = entry.name, entry.data.visits or 1
        card.firstSeen, card.lastSeen = entry.data.firstSeen, entry.data.lastSeen
        card:Show()
    end
    for index = used + 1, #zoneCards do zoneCards[index]:Hide() end
    if #zones == 0 then
        if not zoneEmpty then
            zoneEmpty = scrollChild:CreateFontString(nil, "OVERLAY")
            zoneEmpty:SetPoint("TOPLEFT", 14, -181); setFont(zoneEmpty, 12, MUTED)
            zoneEmpty:SetText(C:LocalizeDisplay("Keine Gebiete gefunden."))
        end
        zoneEmpty:Show()
    elseif zoneEmpty then zoneEmpty:Hide() end
    scrollChild:SetHeight(math.max(230, 171 + #zones * 174 + 12))
end

local function showNPCRows()
    body:Hide()
    local width = availableContentWidth()
    local query = npcSearch and U.Trim(npcSearch:GetText()):lower() or ""
    local entries, allCount, merchantCount = {}, 0, 0
    for name, npc in pairs(C.char.npcs or {}) do
        if U.IsWorldNPC(npc) then
            allCount = allCount + 1
            if npc.merchant then merchantCount = merchantCount + 1 end
            if (npcTab == "all" or (npcTab == "merchants" and npc.merchant) or
                (npcTab == "others" and not npc.merchant)) and
                (query == "" or name:lower():find(query, 1, true) or
                    U.SafeText(npc.zone, ""):lower():find(query, 1, true)) then
                entries[#entries + 1] = { name = name, data = npc }
            end
        end
    end
    table.sort(entries, function(a, b)
        if npcSort == "encounters" and (a.data.encounters or 0) ~= (b.data.encounters or 0) then
            return (a.data.encounters or 0) > (b.data.encounters or 0)
        end
        if npcSort == "recent" and (a.data.lastSeen or 0) ~= (b.data.lastSeen or 0) then
            return (a.data.lastSeen or 0) > (b.data.lastSeen or 0)
        end
        return a.name < b.name
    end)
    if not npcHero then
        npcHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        npcHero:SetHeight(112)
        npcHero.accent = npcHero:CreateTexture(nil, "ARTWORK"); npcHero.accent:Hide()
        npcHero.accent:SetTexture(BACKGROUND); npcHero.accent:SetVertexColor(.82, .58, .22)
        npcHero.accent:SetPoint("TOPLEFT", 4, -4); npcHero.accent:SetPoint("BOTTOMLEFT", 4, 4)
        npcHero.accent:SetWidth(4)
        npcHero.caption = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.caption:SetPoint("TOPLEFT", 20, -12); setFont(npcHero.caption, 10, GOLD)
        npcHero.caption:SetJustifyH("LEFT")
        npcHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  BEGEGNUNGEN"))
        npcHero.title = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.title:SetPoint("TOPLEFT", 19, -32); setFont(npcHero.title, 23, TEXT)
        npcHero.title:SetJustifyH("LEFT")
        npcHero.title:SetText(C:LocalizeDisplay("Gesichter deiner Reise"))
        npcHero.detail = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.detail:SetPoint("TOPLEFT", 20, -63); setFont(npcHero.detail, 10, MUTED)
        npcHero.detail:SetJustifyH("LEFT")
        npcHero.rule = npcHero:CreateTexture(nil, "ARTWORK")
        npcHero.rule:SetTexture(BACKGROUND); npcHero.rule:SetVertexColor(.55, .37, .15, .8)
        npcHero.rule:SetPoint("TOPLEFT", 19, -184); npcHero.rule:SetPoint("TOPRIGHT", -19, -184)
        npcHero.rule:SetHeight(1)
        npcHero.stats = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.stats:SetPoint("TOPLEFT", 20, -105); setFont(npcHero.stats, 33, GOLD)
        npcHero.stats:SetJustifyH("LEFT")
        npcHero.npcCountLabel = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.npcCountLabel:SetPoint("TOPLEFT", 23, -151)
        setFont(npcHero.npcCountLabel, 9, MUTED)
        npcHero.npcCountLabel:SetText(C:LocalizeDisplay("BEKANNTE NPCS"))
        npcHero.merchantCount = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.merchantCount:SetPoint("TOPLEFT", 207, -105)
        setFont(npcHero.merchantCount, 33, GOLD)
        npcHero.merchantLabel = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.merchantLabel:SetPoint("TOPLEFT", 210, -151)
        setFont(npcHero.merchantLabel, 9, MUTED)
        npcHero.merchantLabel:SetText(C:LocalizeDisplay("HÄNDLER"))
        npcHero.divider = npcHero:CreateTexture(nil, "ARTWORK")
        npcHero.divider:SetTexture(BACKGROUND); npcHero.divider:SetVertexColor(.48, .32, .13, .8)
        npcHero.divider:SetPoint("TOP", 0, -13); npcHero.divider:SetPoint("BOTTOM", 0, 13)
        npcHero.divider:SetWidth(1)
        npcHero.latestLabel = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.latestLabel:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -2)
        setFont(npcHero.latestLabel, 10, GOLD); npcHero.latestLabel:SetText(C:LocalizeDisplay("AUSGEWÄHLTER KONTAKT"))
        npcHero.latestLabel:SetJustifyH("LEFT")
        npcHero.latestName = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.latestName:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -27)
        npcHero.latestName:SetJustifyH("LEFT"); setFont(npcHero.latestName, 22, TEXT)
        npcHero.latestPlace = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.latestPlace:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -63)
        setFont(npcHero.latestPlace, 11, MUTED); npcHero.latestPlace:SetJustifyH("LEFT")
        npcHero.latestMeta = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.latestMeta:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -87)
        setFont(npcHero.latestMeta, 12, GOLD); npcHero.latestMeta:SetJustifyH("LEFT")
        npcHero.firstLabel = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.firstLabel:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -129)
        setFont(npcHero.firstLabel, 9, MUTED); npcHero.firstLabel:SetText(C:LocalizeDisplay("ERSTMALS"))
        npcHero.firstDate = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.firstDate:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 20, -147)
        setFont(npcHero.firstDate, 11, GOLD)
        npcHero.lastLabel = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.lastLabel:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 215, -129)
        setFont(npcHero.lastLabel, 9, MUTED); npcHero.lastLabel:SetText(C:LocalizeDisplay("ZULETZT"))
        npcHero.lastDate = npcHero:CreateFontString(nil, "OVERLAY")
        npcHero.lastDate:SetPoint("TOPLEFT", npcHero.divider, "TOPRIGHT", 215, -147)
        setFont(npcHero.lastDate, 11, GOLD)
    end
    npcHero:ClearAllPoints(); npcHero:SetPoint("TOPLEFT", 4, 0); npcHero:SetWidth(width)
    npcHero:SetHeight(112)
    heroBackdrop(npcHero)
    C:SetHeroMotif(npcHero, "NPCs", .18)
    npcHero.motifClip:SetShown(width >= 850)
    npcHero.detail:SetText(query == "" and C:LocalizeDisplay("Bekannte NPCs und Händler deiner Reise") or
        (#entries .. C:LocalizeDisplay(" Treffer für: ") .. query))
    npcHero.stats:SetText(string.format("%02d", allCount))
    npcHero.merchantCount:SetText(string.format("%02d", merchantCount))
    npcHero.rule:ClearAllPoints(); npcHero.rule:SetPoint("TOPLEFT", 19, -100)
    npcHero.rule:SetPoint("TOPRIGHT", -19, -100)
    local overviewX = math.floor(width / 2) + 20
    npcHero.stats:ClearAllPoints(); npcHero.stats:SetPoint("TOPLEFT", overviewX, -28)
    npcHero.npcCountLabel:ClearAllPoints(); npcHero.npcCountLabel:SetPoint("TOPLEFT", overviewX + 3, -75)
    npcHero.merchantCount:ClearAllPoints(); npcHero.merchantCount:SetPoint("TOPLEFT", overviewX + 205, -28)
    npcHero.merchantLabel:ClearAllPoints(); npcHero.merchantLabel:SetPoint("TOPLEFT", overviewX + 208, -75)
    npcHero.divider:Hide()
    npcHero.latestLabel:Hide(); npcHero.latestName:Hide(); npcHero.latestPlace:Hide()
    npcHero.latestMeta:Hide(); npcHero.firstLabel:Hide(); npcHero.firstDate:Hide()
    npcHero.lastLabel:Hide(); npcHero.lastDate:Hide()
    npcHero.title:SetWidth(math.max(280, math.floor(width / 2) - 34))
    npcHero.detail:SetWidth(math.max(280, math.floor(width / 2) - 34))
    npcHero.latestName:SetWidth(math.max(180, math.floor(width / 2) - 78))
    npcHero.latestPlace:SetWidth(math.max(180, math.floor(width / 2) - 78))
    npcHero.latestMeta:SetWidth(math.max(180, math.floor(width / 2) - 78))
    local latestName, latestNPC
    for name, npc in pairs(C.char.npcs or {}) do
        if U.IsWorldNPC(npc) and (not latestNPC or (tonumber(npc.lastSeen) or 0) > (tonumber(latestNPC.lastSeen) or 0)) then
            latestName, latestNPC = name, npc
        end
    end
    local chosen = C.npcSelectedName and C.char.npcs[C.npcSelectedName]
    if not chosen or not U.IsWorldNPC(chosen) then
        C.npcSelectedName, chosen = latestName, latestNPC
    end
    npcHero:Show()
    local tabs = { { "all", "Alle (" .. allCount .. ")" },
        { "merchants", "Händler (" .. merchantCount .. ")" },
        { "others", "Andere (" .. (allCount - merchantCount) .. ")" } }
    local tabWidth = math.floor((width - 16) / 3)
    for index, option in ipairs(tabs) do
        local tab = npcTabs[index]
        if not tab then
            tab = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(tab)
            tab:SetHeight(26)
            tab.label = tab:CreateFontString(nil, "OVERLAY")
            tab.label:SetPoint("CENTER"); setFont(tab.label, 10, TEXT)
            tab:SetScript("OnClick", function(self)
                npcTab = self.tabKey; npcLimit = 80
                showNPCRows(); scroll:SetVerticalScroll(0)
            end)
            npcTabs[index] = tab
        end
        tab.tabKey = option[1]
        tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", 4 + (index - 1) * (tabWidth + 6), -116)
        tab:SetWidth(tabWidth)
        backdrop(tab, npcTab == option[1] and .22 or .075,
            npcTab == option[1] and .13 or .055, npcTab == option[1] and .055 or .034, 1)
        tab.label:SetText(option[2])
        tab.label:SetTextColor(unpack(npcTab == option[1] and GOLD or TEXT))
        tab:Show()
    end
    if not npcSearch then
        npcSearch = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        npcSearch:SetHeight(25); npcSearch:SetAutoFocus(false); npcSearch:SetMaxLetters(80)
        npcSearch:SetScript("OnEscapePressed", npcSearch.ClearFocus)
        npcSearch:SetScript("OnTextChanged", function(self)
            npcSearchHint:SetShown(self:GetText() == "")
            if selected == "npcs" then npcLimit = 80; showNPCRows() end
        end)
        npcSearchHint = npcSearch:CreateFontString(nil, "ARTWORK")
        npcSearchHint:SetPoint("LEFT", 7, 0); setFont(npcSearchHint, 10, MUTED)
        npcSearchHint:SetText(C:LocalizeDisplay("Name oder Gebiet suchen ..."))
    end
    npcSearch:ClearAllPoints(); npcSearch:SetPoint("TOPLEFT", 8, -153)
    npcSearch:SetWidth(math.min(270, width - 355)); npcSearch:Show()
    local sortOptions = { { "recent", "Zuletzt" }, { "encounters", "Häufig" }, { "name", "A-Z" } }
    local sortWidth = 95
    for index, option in ipairs(sortOptions) do
        local button = npcSortButtons[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button:SetHeight(25)
            button.label = button:CreateFontString(nil, "OVERLAY")
            button.label:SetPoint("CENTER"); setFont(button.label, 10, TEXT)
            button:SetScript("OnClick", function(self)
                npcSort = self.sortKey; showNPCRows(); scroll:SetVerticalScroll(0)
            end)
            npcSortButtons[index] = button
        end
        button.sortKey = option[1]
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", -4 - (#sortOptions - index) * (sortWidth + 5), -153)
        button:SetWidth(sortWidth)
        backdrop(button, npcSort == option[1] and .22 or .075,
            npcSort == option[1] and .13 or .055, npcSort == option[1] and .055 or .034, 1)
        button.label:SetText(option[2])
        button.label:SetTextColor(unpack(npcSort == option[1] and GOLD or TEXT))
        button:Show()
    end
    if not npcHero.sectionHeader then
        npcHero.sectionHeader = scrollChild:CreateFontString(nil, "OVERLAY")
        npcHero.sectionHeader:SetPoint("TOPLEFT", 9, -197); setFont(npcHero.sectionHeader, 15, GOLD)
        npcHero.sectionCount = scrollChild:CreateFontString(nil, "OVERLAY")
        npcHero.sectionCount:SetPoint("TOPLEFT", 360, -201); setFont(npcHero.sectionCount, 10, MUTED)
    end
    local sharedZone = #entries > 0 and entries[1].data.zone
    for _, entry in ipairs(entries) do
        if entry.data.zone ~= sharedZone then sharedZone = nil; break end
    end
    if not U.IsKnownZone(sharedZone) then sharedZone = nil end
    npcHero.sectionHeader:SetText(sharedZone and (C:LocalizeDisplay("Begegnungen in ") .. sharedZone) or
        (npcTab == "merchants" and C:LocalizeDisplay("Händler deiner Reise") or
            npcTab == "others" and C:LocalizeDisplay("Begegnungen deiner Reise") or C:LocalizeDisplay("Deine Begegnungschronik")))
    npcHero.sectionCount:SetText(#entries .. C:LocalizeDisplay(" EINTRÄGE"))
    npcHero.sectionHeader:Show(); npcHero.sectionCount:Show()
    local listWidth = math.floor((width - 20) * .52)
    npcHero.sectionHeader:SetWidth(listWidth - 100)
    npcHero.sectionCount:ClearAllPoints()
    npcHero.sectionCount:SetPoint("TOPLEFT", listWidth - 80, -201)
    if not npcHero.profile then
        local profile = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        npcHero.profile = profile
        profile:SetHeight(450)
        profile.caption = profile:CreateFontString(nil, "OVERLAY")
        profile.caption:SetPoint("TOPLEFT", 18, -14); setFont(profile.caption, 10, GOLD)
        profile.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  KONTAKTDOSSIER"))
        profile.name = profile:CreateFontString(nil, "OVERLAY")
        profile.name:SetPoint("TOPLEFT", 18, -36); setFont(profile.name, 22, TEXT)
        profile.name:SetJustifyH("LEFT")
        profile.place = profile:CreateFontString(nil, "OVERLAY")
        profile.place:SetPoint("TOPLEFT", 19, -69); setFont(profile.place, 11, MUTED)
        profile.kind = profile:CreateFontString(nil, "OVERLAY")
        profile.kind:SetPoint("TOPLEFT", 19, -88); setFont(profile.kind, 10, GOLD)
        profile.stage = CreateFrame("Frame", nil, profile, "BackdropTemplate")
        profile.stage:SetPoint("TOPLEFT", 14, -112)
        profile.stage:SetHeight(229)
        profile.fallback = profile.stage:CreateTexture(nil, "ARTWORK")
        profile.fallback:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
        profile.fallback:SetSize(160, 160)
        profile.fallback:SetPoint("CENTER", profile.stage, "CENTER")
        profile.fallback:SetAlpha(.13)
        local modelOK, model = pcall(CreateFrame, "PlayerModel", nil, profile)
        if modelOK and model then
            profile.model = model
            profile.model:SetPoint("TOPLEFT", profile.stage, "TOPLEFT", 3, -3)
            profile.model:SetPoint("BOTTOMRIGHT", profile.stage, "BOTTOMRIGHT", -3, 3)
        end
        profile.rule = profile:CreateTexture(nil, "ARTWORK")
        profile.rule:SetTexture(BACKGROUND); profile.rule:SetVertexColor(.57, .39, .16, .8)
        profile.rule:SetPoint("TOPLEFT", 18, -347)
        profile.rule:SetPoint("TOPRIGHT", -18, -347)
        profile.rule:SetHeight(1)
        profile.firstLabel = profile:CreateFontString(nil, "OVERLAY")
        profile.firstLabel:SetPoint("TOPLEFT", 19, -362); setFont(profile.firstLabel, 9, MUTED)
        profile.firstLabel:SetText(C:LocalizeDisplay("ERSTE BEGEGNUNG"))
        profile.firstDate = profile:CreateFontString(nil, "OVERLAY")
        profile.firstDate:SetPoint("TOPLEFT", 19, -379); setFont(profile.firstDate, 12, GOLD)
        profile.lastLabel = profile:CreateFontString(nil, "OVERLAY")
        profile.lastLabel:SetPoint("TOPRIGHT", -23, -362); setFont(profile.lastLabel, 9, MUTED)
        profile.lastLabel:SetText(C:LocalizeDisplay("LETZTE BEGEGNUNG"))
        profile.lastDate = profile:CreateFontString(nil, "OVERLAY")
        profile.lastDate:SetPoint("TOPRIGHT", -23, -379); setFont(profile.lastDate, 12, GOLD)
        profile.encounters = profile:CreateFontString(nil, "OVERLAY")
        profile.encounters:SetPoint("BOTTOMLEFT", 19, 17); setFont(profile.encounters, 11, TEXT)
    end
    local profile = npcHero.profile
    profile:ClearAllPoints(); profile:SetPoint("TOPLEFT", 4 + listWidth + 12, -197)
    profile:SetWidth(width - listWidth - 16)
    heroBackdrop(profile)
    profile.stage:SetWidth(profile:GetWidth() - 28)
    backdrop(profile.stage, .045, .031, .021, 1)
    profile.stage:SetBackdropBorderColor(.39, .28, .12, 1)
    profile.name:SetWidth(profile:GetWidth() - 36)
    profile.name:SetText(C.npcSelectedName or C:LocalizeDisplay("Noch kein Kontakt"))
    profile.place:SetText(chosen and U.SafeText(chosen.zone, C:LocalizeDisplay("Unbekannter Ort")) or "")
    profile.kind:SetText(chosen and (chosen.merchant and "HÄNDLER" or
        (chosen.classification == "rare" or chosen.classification == "rareelite") and C:LocalizeDisplay("SELTENER KONTAKT") or
        C:LocalizeDisplay("BEGEGNUNG")) or "")
    profile.firstDate:SetText(chosen and U.Date(chosen.firstSeen or chosen.lastSeen, true) or "")
    profile.lastDate:SetText(chosen and U.Date(chosen.lastSeen, true) or "")
    profile.encounters:SetText(chosen and (tostring(chosen.encounters or 1) .. C:LocalizeDisplay(" Begegnungen aufgezeichnet")) or "")
    local modelID = chosen and tonumber(chosen.npcID)
    if profile.model and modelID and modelID > 0 and profile.modelNPCID ~= modelID then
        if profile.model.SetCreature then
            local ok = pcall(profile.model.SetCreature, profile.model, modelID)
            if ok then profile.modelNPCID = modelID end
        end
        if profile.model.SetPortraitZoom then pcall(profile.model.SetPortraitZoom, profile.model, 1) end
        if profile.model.SetFacing then pcall(profile.model.SetFacing, profile.model, .25) end
    end
    if profile.model and modelID and modelID > 0 and profile.model.SetUnit then
        for _, unit in ipairs({ "target", "mouseover", "npc" }) do
            if UnitExists(unit) and U.UnitGUIDID(UnitGUID(unit)) == modelID then
                pcall(profile.model.SetUnit, profile.model, unit)
                break
            end
        end
    end
    if profile.model then profile.model:SetShown(modelID ~= nil and modelID > 0) end
    profile:Show()
    local used = 0
    for index = 1, math.min(#entries, npcLimit) do
        local entry = entries[index]
        used = used + 1
        local card = npcCards[used]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            card:SetHeight(68); card:EnableMouse(true)
            card.hover = card:CreateTexture(nil, "BACKGROUND")
            card.hover:SetTexture(BACKGROUND)
            card.hover:SetAllPoints(card)
            card.hover:SetVertexColor(.35, .23, .09, .17)
            card.hover:Hide()
            card.rule = card:CreateTexture(nil, "ARTWORK")
            card.rule:SetTexture(BACKGROUND)
            card.rule:SetVertexColor(.42, .29, .12, .8)
            card.rule:SetPoint("BOTTOMLEFT", 12, 0)
            card.rule:SetPoint("BOTTOMRIGHT", -12, 0)
            card.rule:SetHeight(1)
            card.accent = card:CreateTexture(nil, "ARTWORK"); card.accent:Hide()
            card.accent:SetTexture(BACKGROUND)
            card.accent:SetPoint("TOPLEFT", 3, -8); card.accent:SetPoint("BOTTOMLEFT", 3, 8)
            card.accent:SetWidth(2)
            card.number = card:CreateFontString(nil, "OVERLAY")
            card.number:SetPoint("LEFT", 16, 0); setFont(card.number, 24, GOLD)
            card.indexRule = card:CreateTexture(nil, "ARTWORK")
            card.indexRule:SetTexture(BACKGROUND)
            card.indexRule:SetVertexColor(.58, .39, .15, .7)
            card.indexRule:SetPoint("TOPLEFT", 57, -12)
            card.indexRule:SetPoint("BOTTOMLEFT", 57, 12)
            card.indexRule:SetWidth(1)
            card.connector = card:CreateTexture(nil, "ARTWORK")
            card.connector:SetTexture(BACKGROUND)
            card.connector:SetVertexColor(.57, .39, .16, .85)
            card.connector:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 35, 0)
            card.connector:SetSize(1, 8)
            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(30, 30); card.icon:SetPoint("RIGHT", -17, 0)
            card.caption = card:CreateFontString(nil, "OVERLAY")
            card.caption:SetPoint("TOPRIGHT", -63, -16); setFont(card.caption, 9, MUTED)
            card.name = card:CreateFontString(nil, "OVERLAY")
            card.name:SetPoint("TOPLEFT", 68, -12); card.name:SetJustifyH("LEFT")
            setFont(card.name, 16, GOLD)
            card.zone = card:CreateFontString(nil, "OVERLAY")
            card.zone:SetPoint("TOPLEFT", 69, -41); setFont(card.zone, 10, TEXT)
            card.meta = card:CreateFontString(nil, "OVERLAY")
            card.meta:SetPoint("TOPRIGHT", -63, -42); setFont(card.meta, 10, MUTED)
            card:SetScript("OnEnter", function(self)
                self.hover:Show()
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.npcName or "NPC", 1, .82, .1)
                GameTooltip:AddLine(C:LocalizeDisplay(self.isMerchant and "Händler" or "Begegnung"), .8, .74, .62)
                GameTooltip:AddLine(C:LocalizeDisplay("Ort: ") .. U.SafeText(self.npcZone, "Unbekannt"), .8, .74, .62)
                GameTooltip:AddLine(C:LocalizeDisplay("Begegnungen: ") .. tostring(self.encounters or 1), .8, .74, .62)
                GameTooltip:AddLine(C:LocalizeDisplay("Erstmals: ") .. (self.firstSeen and U.Date(self.firstSeen) or "nicht erfasst"), .8, .74, .62)
                GameTooltip:AddLine(C:LocalizeDisplay("Zuletzt: ") .. (self.lastSeen and U.Date(self.lastSeen) or "nicht erfasst"), .8, .74, .62)
                GameTooltip:AddLine(C:LocalizeDisplay("Klicken: Kontakt im Dossier anzeigen"), 1, .76, .29)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self.hover:SetShown(self.selected)
                GameTooltip:Hide()
            end)
            card:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    C.npcSelectedName = self.npcName
                    GameTooltip:Hide()
                    showNPCRows()
                end
            end)
            npcCards[used] = card
        end
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -225 - (index - 1) * 72)
        card:SetWidth(listWidth)
        card.connector:Hide(); card.indexRule:Hide(); card.accent:Hide()
        card.selected = C.npcSelectedName == entry.name
        card:SetBackdrop(nil)
        card.hover:SetShown(card.selected)
        card.rule:SetVertexColor(card.selected and .76 or .42,
            card.selected and .52 or .29, card.selected and .19 or .12, .8)
        card.number:SetText(string.format("%02d", index))
        local distinguished = entry.data.merchant or entry.data.classification == "rare" or
            entry.data.classification == "rareelite"
        card.icon:SetShown(distinguished)
        if distinguished then
            card.icon:SetTexture(entry.data.merchant and "Interface\\Icons\\INV_Misc_Coin_01" or
                "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        card.caption:ClearAllPoints(); card.caption:SetPoint("TOPRIGHT", distinguished and -63 or -18, -16)
        card.meta:ClearAllPoints(); card.meta:SetPoint("TOPRIGHT", distinguished and -63 or -18, -42)
        card.caption:SetText(entry.data.merchant and "HÄNDLER" or
            ((entry.data.classification == "rare" or entry.data.classification == "rareelite") and
                C:LocalizeDisplay("SELTENE BEGEGNUNG") or C:LocalizeDisplay("BEGEGNUNG")))
        card.name:SetText(entry.name); card.name:SetWidth(math.max(160, listWidth - 190))
        card.zone:SetText(sharedZone and (C:LocalizeDisplay("Erstmals ") .. U.Date(entry.data.firstSeen or entry.data.lastSeen, true)) or
            U.SafeText(entry.data.zone, C:LocalizeDisplay("Unbekannter Ort")))
        card.meta:SetText(tostring(entry.data.encounters or 1) .. C:LocalizeDisplay(" Begegnungen"))
        card.npcName, card.npcZone, card.encounters = entry.name, entry.data.zone, entry.data.encounters
        card.firstSeen, card.lastSeen, card.isMerchant = entry.data.firstSeen, entry.data.lastSeen, entry.data.merchant
        card:Show()
    end
    for index = used + 1, #npcCards do npcCards[index]:Hide() end
    if #entries == 0 then
        if not npcEmpty then
            npcEmpty = scrollChild:CreateFontString(nil, "OVERLAY")
            npcEmpty:SetPoint("TOPLEFT", 14, -235); setFont(npcEmpty, 12, MUTED)
            npcEmpty:SetText(C:LocalizeDisplay("Keine Begegnungen gefunden."))
        end
        npcEmpty:Show()
    elseif npcEmpty then npcEmpty:Hide() end
    local height = math.max(650, 225 + used * 72)
    if #entries > npcLimit then
        if not npcMore then
            npcMore = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(npcMore)
            npcMore:SetHeight(32)
            npcMore.label = npcMore:CreateFontString(nil, "OVERLAY")
            npcMore.label:SetPoint("CENTER"); setFont(npcMore.label, 11, GOLD)
            npcMore:SetScript("OnClick", function()
                npcLimit = npcLimit + 80; showNPCRows()
            end)
        end
        npcMore:ClearAllPoints(); npcMore:SetPoint("TOPLEFT", 4, -height - 5)
        npcMore:SetWidth(width); backdrop(npcMore, .12, .08, .035, 1)
        npcMore.label:SetText(C:LocalizeDisplay("Weitere Begegnungen anzeigen (") .. used .. " / " .. #entries .. ")")
        npcMore:Show(); height = height + 43
    elseif npcMore then npcMore:Hide() end
    scrollChild:SetHeight(math.max(230, height + 10))
end

C.dungeonInstanceArtByName, C.dungeonInstanceArtByMap = {}, {}
C.dungeonInstanceArtReady = false
function C:NormalizeInstanceName(name)
    return tostring(name or ""):gsub("^[Dd]ie ", ""):gsub("^[Dd]er ", ""):gsub("^[Dd]as ", "")
end
function C:RefreshDungeonInstanceArt()
    if self.dungeonInstanceArtReady or not EJ_GetInstanceByIndex then return end
    local oldTier = EJ_GetCurrentTier and EJ_GetCurrentTier()
    local ok = pcall(function()
        local tiers = EJ_GetNumTiers and EJ_GetNumTiers() or 1
        for tier = 1, math.max(1, tiers) do
            if EJ_SelectTier then EJ_SelectTier(tier) end
            for _, isRaid in ipairs({ false, true }) do
                for index = 1, 100 do
                    local instanceID, name, _, background, buttonImage, loreImage, _, _, _, _, mapID =
                        EJ_GetInstanceByIndex(index, isRaid)
                    if not instanceID then break end
                    local art = (background and background ~= 0 and background) or
                        (loreImage and loreImage ~= 0 and loreImage) or buttonImage
                    if art and art ~= 0 then
                        self.dungeonInstanceArtByName[self:NormalizeInstanceName(name)] = art
                        if mapID and mapID ~= 0 then self.dungeonInstanceArtByMap[mapID] = art end
                    end
                end
            end
        end
    end)
    if oldTier and EJ_SelectTier then pcall(EJ_SelectTier, oldTier) end
    self.dungeonInstanceArtReady = ok and next(self.dungeonInstanceArtByName) ~= nil
end

local function showDungeonRows()
    body:Hide()
    if dungeonTab == "instances" then C:RefreshDungeonInstanceArt() end
    if dungeonHero and dungeonHero.bossListHeader then dungeonHero.bossListHeader:Hide() end
    local width = availableContentWidth()
    local query = dungeonSearch and U.Trim(dungeonSearch:GetText()):lower() or ""
    local stats = U.Statistics(C.char)
    local entries = {}
    if dungeonTab == "instances" then
        for name, value in pairs(C.char.dungeons or {}) do
            if query == "" or name:lower():find(query, 1, true) or
                C:LocalizeInstanceName(name):lower():find(query, 1, true) then
                entries[#entries + 1] = { name = name, data = value }
            end
        end
    elseif dungeonTab == "bosses" then
        for key, value in pairs(C.char.bosses or {}) do
            local name = U.SafeText(value.name, "Boss #" .. tostring(key))
            if query == "" or name:lower():find(query, 1, true) or
                U.SafeText(value.zone, ""):lower():find(query, 1, true) then
                entries[#entries + 1] = { name = name, data = value }
            end
        end
    else
        for _, boss in pairs(C.char.bosses or {}) do
            for _, item in ipairs(boss.loot or {}) do
                local name = item.link and item.link:match("|h%[(.-)%]|h") or "Gegenstand"
                if query == "" or name:lower():find(query, 1, true) or
                    U.SafeText(boss.name, ""):lower():find(query, 1, true) or
                    U.SafeText(item.recipient, ""):lower():find(query, 1, true) then
                    entries[#entries + 1] = { name = name, data = { lastSeen = item.time },
                        bossName = boss.name, item = item }
                end
            end
        end
    end
    table.sort(entries, function(a, b)
        if (a.data.lastSeen or 0) ~= (b.data.lastSeen or 0) then
            return (a.data.lastSeen or 0) > (b.data.lastSeen or 0)
        end
        return a.name < b.name
    end)
    pageMotif:SetShown(#entries > 1 and dungeonTab == "instances")
    if not dungeonHero then
        dungeonHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        dungeonHero:SetHeight(152)
        dungeonHero.accent = dungeonHero:CreateTexture(nil, "ARTWORK"); dungeonHero.accent:Hide()
        dungeonHero.accent:SetTexture(BACKGROUND); dungeonHero.accent:SetVertexColor(.84, .4, .27)
        dungeonHero.accent:SetPoint("TOPLEFT", 4, -4); dungeonHero.accent:SetPoint("BOTTOMLEFT", 4, 4)
        dungeonHero.accent:SetWidth(4)
        dungeonHero.caption = dungeonHero:CreateFontString(nil, "OVERLAY")
        dungeonHero.caption:SetPoint("TOPLEFT", 20, -12); setFont(dungeonHero.caption, 10, GOLD)
        dungeonHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  INSTANZEN"))
        dungeonHero.title = dungeonHero:CreateFontString(nil, "OVERLAY")
        dungeonHero.title:SetPoint("TOPLEFT", 19, -39); setFont(dungeonHero.title, 28, TEXT)
        dungeonHero.title:SetText(C:LocalizeDisplay("Deine Herausforderungen"))
        dungeonHero.detail = dungeonHero:CreateFontString(nil, "OVERLAY")
        dungeonHero.detail:SetPoint("TOPLEFT", 20, -80); setFont(dungeonHero.detail, 12, MUTED)
        dungeonHero.rule = dungeonHero:CreateTexture(nil, "ARTWORK")
        dungeonHero.rule:SetTexture(BACKGROUND); dungeonHero.rule:SetVertexColor(.6, .32, .2, .8)
        dungeonHero.rule:SetPoint("TOPLEFT", 19, -109); dungeonHero.rule:SetPoint("TOPRIGHT", -20, -109)
        dungeonHero.rule:SetHeight(1)
        dungeonHero.counters = {}
        local icons = { "Interface\\AddOns\\Chronicle\\KeyMedallion", "Interface\\AddOns\\Chronicle\\KeyMedallion", "Interface\\AddOns\\Chronicle\\BossMedallion" }
        for index = 1, 3 do
            local icon = dungeonHero:CreateTexture(nil, "ARTWORK")
            icon:SetTexture(icons[index]); icon:SetSize(18, 18)
            icon:SetTexCoord(0, 1, 0, 1)
            local label = dungeonHero:CreateFontString(nil, "OVERLAY")
            setFont(label, 10, GOLD); label:SetJustifyH("LEFT")
            dungeonHero.counters[index] = { icon = icon, label = label }
        end
        dungeonHero.icon = dungeonHero:CreateTexture(nil, "ARTWORK")
        dungeonHero.icon:SetTexture("Interface\\Icons\\INV_Misc_Key_03")
        dungeonHero.icon:SetSize(60, 60); dungeonHero.icon:SetPoint("TOPRIGHT", -24, -24)
    end
    dungeonHero:ClearAllPoints(); dungeonHero:SetPoint("TOPLEFT", 4, 0)
    dungeonHero:SetWidth(width); heroBackdrop(dungeonHero)
    C:SetHeroMotif(dungeonHero, dungeonTab == "loot" and "Loot" or
        (dungeonTab == "bosses" and "Deaths" or "Dungeons"))
    dungeonHero.caption:SetText(C:LocalizeDisplay(dungeonTab == "loot" and "CHRONICLE  /  BOSSBEUTE" or
        (dungeonTab == "bosses" and "CHRONICLE  /  BOSSE" or "CHRONICLE  /  INSTANZEN")))
    dungeonHero.title:SetText(dungeonTab == "loot" and C:LocalizeDisplay("Die Beute deiner Siege") or
        (dungeonTab == "bosses" and C:LocalizeDisplay("Die Chronik deiner Siege") or C:LocalizeDisplay("Deine Herausforderungen")))
    dungeonHero.icon:SetTexture(dungeonTab == "loot" and "Interface\\Icons\\INV_Box_01" or
        (dungeonTab == "bosses" and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or "Interface\\Icons\\INV_Misc_Key_03"))
    dungeonHero.icon:Hide()
    dungeonHero.detail:SetText(query == "" and (dungeonTab == "loot" and C:LocalizeDisplay("Fundstücke aus deinen Bossbegegnungen") or
        (dungeonTab == "bosses" and C:LocalizeDisplay("Jeder Kampf ein Kapitel deiner Reise") or C:LocalizeDisplay("Instanzen, Bosskämpfe und Siege deiner Reise"))) or
        (#entries .. C:LocalizeDisplay(" Treffer für: ") .. query))
    local values = { stats.dungeons .. " INSTANZEN", stats.dungeonVisits .. " BESUCHE", stats.bossKills .. " BOSSSIEGE" }
    local counterWidth = math.floor((width - 40) / 3)
    for index, counter in ipairs(dungeonHero.counters) do
        local x = 20 + (index - 1) * counterWidth
        counter.icon:ClearAllPoints(); counter.icon:SetPoint("TOPLEFT", x, -119)
        counter.icon:SetShown(index ~= 1)
        counter.label:ClearAllPoints()
        if index == 1 then counter.label:SetPoint("TOPLEFT", x, -122)
        else counter.label:SetPoint("LEFT", counter.icon, "RIGHT", 6, 0) end
        counter.label:SetWidth(counterWidth - 25); counter.label:SetText(values[index])
    end
    dungeonHero:Show()
    local tabs = { { "instances", "Instanzen (" .. stats.dungeons .. ")" },
        { "bosses", "Bosse (" .. stats.bosses .. ")" }, { "loot", "Bossbeute (" .. #entries .. ")" } }
    local lootCount = 0
    for _, boss in pairs(C.char.bosses or {}) do lootCount = lootCount + #(boss.loot or {}) end
    tabs[3][2] = "Bossbeute (" .. lootCount .. ")"
    local tabWidth = math.floor((width - 20) / 3)
    for index, option in ipairs(tabs) do
        local tab = dungeonTabs[index]
        if not tab then
            tab = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(tab)
            tab:SetHeight(36)
            tab.label = tab:CreateFontString(nil, "OVERLAY")
            tab.label:SetPoint("CENTER"); setFont(tab.label, 11, TEXT)
            tab:SetScript("OnClick", function(self)
                dungeonTab = self.tabKey; showDungeonRows(); scroll:SetVerticalScroll(0)
            end)
            dungeonTabs[index] = tab
        end
        tab.tabKey = option[1]
        tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", 4 + (index - 1) * (tabWidth + 8), -167)
        tab:SetWidth(tabWidth)
        backdrop(tab, dungeonTab == option[1] and .26 or .075,
            dungeonTab == option[1] and .14 or .055, dungeonTab == option[1] and .055 or .034, 1)
        tab.label:SetText(option[2])
        tab.label:SetTextColor(unpack(dungeonTab == option[1] and GOLD or TEXT))
        tab:Show()
    end
    if not dungeonSearch then
        dungeonSearch = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        dungeonSearch:SetHeight(27); dungeonSearch:SetAutoFocus(false); dungeonSearch:SetMaxLetters(80)
        dungeonSearch:SetScript("OnEscapePressed", dungeonSearch.ClearFocus)
        dungeonSearch:SetScript("OnTextChanged", function(self)
            dungeonSearchHint:SetShown(self:GetText() == "")
            if selected == "dungeons" then showDungeonRows() end
        end)
        dungeonSearchHint = dungeonSearch:CreateFontString(nil, "ARTWORK")
        dungeonSearchHint:SetPoint("LEFT", 7, 0); setFont(dungeonSearchHint, 10, MUTED)
        dungeonSearchHint:SetText(C:LocalizeDisplay("Instanz oder Boss suchen ..."))
    end
    dungeonSearch:ClearAllPoints(); dungeonSearch:SetPoint("TOPLEFT", 8, -209)
    dungeonSearch:SetWidth(math.min(300, width - 20)); dungeonSearch:Show()
    if dungeonTab == "bosses" and #entries > 0 then
        local heading = dungeonHero.bossListHeader
        if not heading then
            heading = CreateFrame("Frame", nil, scrollChild)
            heading.title = heading:CreateFontString(nil, "OVERLAY")
            setFont(heading.title, 14, GOLD)
            heading.title:SetPoint("TOPLEFT", 0, -2)
            heading.count = heading:CreateFontString(nil, "OVERLAY")
            setFont(heading.count, 9, MUTED)
            heading.count:SetPoint("TOPRIGHT", 0, -5)
            heading.rule = heading:CreateTexture(nil, "ARTWORK")
            heading.rule:SetTexture(BACKGROUND)
            heading.rule:SetVertexColor(.58, .39, .15, .75)
            heading.rule:SetPoint("BOTTOMLEFT", 0, 0)
            heading.rule:SetPoint("BOTTOMRIGHT", 0, 0)
            heading.rule:SetHeight(1)
            dungeonHero.bossListHeader = heading
        end
        heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 16, -243)
        heading:SetSize(width - 24, 27)
        heading.title:SetText(C:LocalizeDisplay("Bosschronik"))
        heading.count:SetText(#entries .. C:LocalizeDisplay(" BEGEGNUNGEN"))
        heading:Show()
    end
    local cardWidth = math.floor((width - 12) / 2)
    local stageHeight = math.max(285, math.min(380, (scroll:GetHeight() or 500) - 255))
    local used = 0
    for index, entry in ipairs(entries) do
        used = used + 1
        local card = dungeonCards[used]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            card:SetHeight(122); card:EnableMouse(true)
            card.instanceArt = card:CreateTexture(nil, "ARTWORK", nil, -8)
            card.instanceArt:SetPoint("BOTTOMRIGHT", -5, 5)
            card.instanceArt:SetTexCoord(0, 1, .08, .92)
            card.instanceArt:Hide()
            card.motif = card:CreateTexture(nil, "ARTWORK")
            card.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Dungeons")
            card.motif:SetPoint("BOTTOMRIGHT", -10, 4)
            card.motif:SetSize(300, 300); card.motif:SetAlpha(.2)
            card.motif:Hide()
            card.featureRule = card:CreateTexture(nil, "ARTWORK")
            card.featureRule:SetTexture(BACKGROUND)
            card.featureRule:SetVertexColor(.58, .39, .15, .8)
            card.featureRule:SetPoint("TOPLEFT", 20, -76)
            card.featureRule:SetPoint("TOPRIGHT", -20, -76)
            card.featureRule:SetHeight(1); card.featureRule:Hide()
            card.accent = card:CreateTexture(nil, "ARTWORK"); card.accent:Hide()
            card.accent:SetTexture(BACKGROUND)
            card.accent:SetPoint("TOPLEFT", 3, -3); card.accent:SetPoint("BOTTOMLEFT", 3, 3)
            card.accent:SetWidth(3)
            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(36, 36); card.icon:SetPoint("TOPRIGHT", -12, -12)
            card.medallion = card:CreateTexture(nil, "ARTWORK")
            card.medallion:SetTexture("Interface\\AddOns\\Chronicle\\KeyMedallion")
            card.medallion:SetSize(94, 94); card.medallion:Hide()
            card.leftFlourish = card:CreateTexture(nil, "ARTWORK")
            card.leftFlourish:SetTexture(BACKGROUND); card.leftFlourish:SetVertexColor(.62, .4, .16, .7)
            card.leftFlourish:SetHeight(1); card.leftFlourish:Hide()
            card.rightFlourish = card:CreateTexture(nil, "ARTWORK")
            card.rightFlourish:SetTexture(BACKGROUND); card.rightFlourish:SetVertexColor(.62, .4, .16, .7)
            card.rightFlourish:SetHeight(1); card.rightFlourish:Hide()
            card.bottomFlourish = card:CreateTexture(nil, "ARTWORK")
            card.bottomFlourish:SetTexture(BACKGROUND); card.bottomFlourish:SetVertexColor(.62, .4, .16, .65)
            card.bottomFlourish:SetHeight(1); card.bottomFlourish:Hide()
            card.caption = card:CreateFontString(nil, "OVERLAY")
            card.caption:SetPoint("TOPLEFT", 14, -11); setFont(card.caption, 9, MUTED)
            card.ordinal = card:CreateFontString(nil, "OVERLAY")
            setFont(card.ordinal, 20, GOLD); card.ordinal:Hide()
            card.name = card:CreateFontString(nil, "OVERLAY")
            card.name:SetPoint("TOPLEFT", 14, -31); card.name:SetJustifyH("LEFT")
            setFont(card.name, 14, GOLD)
            card.visitCount = card:CreateFontString(nil, "OVERLAY")
            card.visitCount:SetPoint("TOPLEFT", 22, -108)
            setFont(card.visitCount, 38, GOLD); card.visitCount:Hide()
            card.visitLabel = card:CreateFontString(nil, "OVERLAY")
            card.visitLabel:SetPoint("TOPLEFT", 91, -132)
            setFont(card.visitLabel, 11, MUTED); card.visitLabel:Hide()
            card.openHint = card:CreateFontString(nil, "OVERLAY")
            card.openHint:SetPoint("TOPLEFT", 23, -153)
            setFont(card.openHint, 10, GOLD)
            card.openHint:SetText(C:LocalizeDisplay("BOSSKAPITEL ÖFFNEN  ›"))
            card.openHint:Hide()
            card.main = card:CreateFontString(nil, "OVERLAY")
            card.main:SetPoint("TOPLEFT", 14, -65); card.main:SetJustifyH("LEFT"); setFont(card.main, 11, TEXT)
            card.detail = card:CreateFontString(nil, "OVERLAY")
            card.detail:SetPoint("TOPLEFT", 14, -87); card.detail:SetJustifyH("LEFT"); setFont(card.detail, 10, MUTED)
            card.lootShade = card:CreateTexture(nil, "BACKGROUND"); card.lootShade:SetTexture(BACKGROUND)
            card.lootShade:SetAllPoints(card); card.lootShade:SetVertexColor(1, .72, .22, .055); card.lootShade:Hide()
            card.lootRule = card:CreateTexture(nil, "ARTWORK"); card.lootRule:SetTexture(BACKGROUND)
            card.lootRule:SetVertexColor(.46, .33, .17, .75)
            card.lootRule:SetPoint("BOTTOMLEFT", 12, 0); card.lootRule:SetPoint("BOTTOMRIGHT", -12, 0)
            card.lootRule:SetHeight(1); card.lootRule:Hide()
            card.milestoneRule = card:CreateTexture(nil, "ARTWORK")
            card.milestoneRule:SetTexture(BACKGROUND); card.milestoneRule:SetVertexColor(.58, .39, .15, .8)
            card.milestoneRule:SetPoint("TOPLEFT", 22, -108)
            card.milestoneRule:SetPoint("TOPRIGHT", -22, -108); card.milestoneRule:SetHeight(1)
            card.milestones = {}
            for milestoneIndex = 1, 3 do
                local label = card:CreateFontString(nil, "OVERLAY"); setFont(label, 9, MUTED)
                label:SetJustifyH("LEFT")
                local value = card:CreateFontString(nil, "OVERLAY"); setFont(value, 13, GOLD)
                value:SetJustifyH("LEFT")
                card.milestones[milestoneIndex] = { label = label, value = value }
            end
            card:SetScript("OnEnter", function(self)
                if self.lootRow then self.lootShade:Show()
                else self:SetBackdropBorderColor(.95, .65, .25, 1) end
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                if self.itemLink then
                    local shown = pcall(GameTooltip.SetHyperlink, GameTooltip, self.itemLink)
                    if not shown then GameTooltip:AddLine(self.entryName or C:LocalizeDisplay("Bossbeute"), 1, .82, .1) end
                    GameTooltip:AddLine(C:LocalizeDisplay("Erhalten von: ") .. (self.recipient or "?"), .9, .84, .72)
                    GameTooltip:AddLine(C:LocalizeDisplay("Boss: ") .. (self.bossName or "?"), .75, .7, .6)
                    if self.itemSource == "reconstructed" then
                        GameTooltip:AddLine(C:LocalizeDisplay("Aus Inventarfund und Bosszeit rekonstruiert"), .72, .65, .52)
                    end
                else
                    GameTooltip:AddLine(self.entryName or C:LocalizeDisplay("Instanz"), 1, .82, .1)
                    GameTooltip:AddLine(self.tooltipMain or "", .9, .84, .72)
                    GameTooltip:AddLine(self.tooltipDetail or "", .75, .7, .6)
                    if self.chapterName then GameTooltip:AddLine(C:LocalizeDisplay("Klicken: Bosskapitel öffnen"), 1, .75, .28) end
                end
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                if self.lootRow then self.lootShade:Hide()
                else self:SetBackdropBorderColor(.59, .44, .17, 1) end
                GameTooltip:Hide()
            end)
            card:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and self.chapterName then
                    GameTooltip:Hide()
                    C:OpenDungeonChapter(self.chapterName, self.chapterData)
                end
            end)
            dungeonCards[used] = card
        end
        local featured = #entries == 1
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4 + column * (cardWidth + 8), -246 - row * 132)
        card:SetWidth(featured and width or cardWidth)
        card:SetHeight(featured and dungeonTab == "instances" and 245 or (featured and 190 or 122))
        card.motif:SetShown(featured)
        card.motif:SetSize(featured and 185 or 300, featured and 185 or 300)
        card.motif:SetAlpha(featured and .16 or .2)
        card.featureRule:SetShown(featured)
        local messageWidth = math.max(330, width - 280)
        local messageCenter = math.floor(messageWidth / 2) + 10
        card.icon:ClearAllPoints()
        if featured then card.icon:SetPoint("TOP", card, "TOPLEFT", messageCenter, -43)
        else card.icon:SetPoint("TOPRIGHT", -12, -12) end
        card.icon:SetSize(featured and 62 or 36, featured and 62 or 36)
        card.medallion:SetShown(featured and dungeonTab == "instances")
        card.icon:SetShown(dungeonTab ~= "instances")
        card.medallion:ClearAllPoints(); card.medallion:SetPoint("TOP", card, "TOPLEFT", messageCenter, -35)
        card.leftFlourish:SetShown(featured); card.rightFlourish:SetShown(featured)
        card.bottomFlourish:SetShown(featured)
        card.leftFlourish:ClearAllPoints(); card.leftFlourish:SetPoint("TOPLEFT", 64, -82)
        card.leftFlourish:SetWidth(math.max(25, messageCenter - 120))
        card.rightFlourish:ClearAllPoints(); card.rightFlourish:SetPoint("TOPLEFT", messageCenter + 57, -82)
        card.rightFlourish:SetWidth(math.max(25, messageWidth - messageCenter - 95))
        card.bottomFlourish:ClearAllPoints(); card.bottomFlourish:SetPoint("BOTTOM", card, "BOTTOMLEFT", messageCenter, 48)
        card.bottomFlourish:SetWidth(160)
        card.caption:ClearAllPoints(); card.caption:SetPoint("TOPLEFT", featured and 20 or 14, featured and -17 or -11)
        card.name:ClearAllPoints()
        if featured then card.name:SetPoint("TOP", card, "TOPLEFT", messageCenter, -143)
        else card.name:SetPoint("TOPLEFT", 14, -31) end
        card.name:SetJustifyH(featured and "CENTER" or "LEFT")
        setFont(card.name, featured and 25 or 14, GOLD)
        card.main:ClearAllPoints()
        if featured then card.main:SetPoint("TOP", card, "TOPLEFT", messageCenter, -218)
        else card.main:SetPoint("TOPLEFT", 14, -65) end
        card.main:SetJustifyH(featured and "CENTER" or "LEFT")
        card.detail:ClearAllPoints()
        if featured then card.detail:SetPoint("TOP", card, "TOPLEFT", messageCenter, -248)
        else card.detail:SetPoint("TOPLEFT", 14, -87) end
        card.detail:SetJustifyH(featured and "CENTER" or "LEFT")
        card.featureRule:ClearAllPoints()
        card.featureRule:SetPoint("TOPLEFT", 20, -196)
        card.featureRule:SetPoint("TOPRIGHT", featured and -(width - messageWidth) or -20, -196)
        if featured then
            card.medallion:Hide(); card.icon:Show()
            card.icon:ClearAllPoints(); card.icon:SetPoint("TOPLEFT", 22, -43); card.icon:SetSize(50, 50)
            card.leftFlourish:Hide(); card.rightFlourish:Hide(); card.bottomFlourish:Hide()
            card.caption:ClearAllPoints(); card.caption:SetPoint("TOPLEFT", 22, -15)
            card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 88, -43)
            card.name:SetJustifyH("LEFT"); setFont(card.name, 23, GOLD)
            card.featureRule:ClearAllPoints()
            card.featureRule:SetPoint("TOPLEFT", 22, -106); card.featureRule:SetPoint("TOPRIGHT", -22, -106)
            card.main:ClearAllPoints(); card.main:SetPoint("TOPLEFT", 23, -122)
            card.main:SetJustifyH("LEFT")
            card.detail:ClearAllPoints(); card.detail:SetPoint("TOPLEFT", 23, -148)
            card.detail:SetJustifyH("LEFT")
        end
        local isBoss = dungeonTab == "bosses"
        local isLoot = dungeonTab == "loot"
        local expedition = featured and dungeonTab == "instances"
        card.visitCount:SetShown(expedition)
        card.visitLabel:SetShown(expedition)
        card.openHint:SetShown(expedition)
        if expedition then
            card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 22, -53)
            card.visitCount:SetText(string.format("%02d", tonumber(entry.data.entries) or 0))
            local difficulty = U.SafeText(entry.data.difficulty, "")
            card.visitLabel:SetText(C:LocalizeDisplay("BESUCHE") .. (difficulty ~= "" and ("  ·  " .. difficulty) or ""))
            card.milestoneRule:ClearAllPoints()
            card.milestoneRule:SetPoint("TOPLEFT", 22, -175)
            card.milestoneRule:SetPoint("TOPRIGHT", -22, -175)
        end
        local instanceArt = dungeonTab == "instances" and
            (C:GetPackagedInstanceArt(entry.name) or
            C.dungeonInstanceArtByMap[tonumber(entry.data.instanceID)] or
            C.dungeonInstanceArtByName[C:NormalizeInstanceName(entry.name)]) or nil
        if dungeonTab == "instances" then
            card.icon:Hide()
        end
        if instanceArt then
            card.instanceArt:ClearAllPoints()
            card.instanceArt:SetPoint("TOPLEFT", card, "TOPLEFT", math.floor(card:GetWidth() * .4), -5)
            card.instanceArt:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 5)
        end
        C:SetSoftInstanceArt(card.instanceArt, instanceArt,
            math.max(1, card:GetWidth() - math.floor(card:GetWidth() * .4) - 5),
            { top = .08, bottom = .92, alpha = .8, fadeFraction = .6, subLevel = -7 })
        card.motif:SetShown(featured and not instanceArt)
        card.lootRow = isLoot or isBoss
        card.ordinal:SetShown(isBoss)
        card.lootShade:Hide(); card.lootRule:SetShown(isLoot); card.caption:Show()
        card.featureRule:SetShown(featured and not expedition)
        local kills = tonumber(entry.data.kills) or 0
        if featured then
            backdrop(card, .105, .071, .045, 1)
            C:ApplyMaterial(card, .16)
            C:OrnateCorners(card)
        else
            openSurface(card)
        end
        card.accent:SetVertexColor(isBoss and (kills > 0 and .35 or .85) or .52,
            isBoss and (kills > 0 and .8 or .35) or .68,
            isBoss and (kills > 0 and .44 or .3) or .95)
        local lootIcon
        if isLoot and entry.item.id then
            if C_Item and C_Item.GetItemIconByID then
                local ok, value = pcall(C_Item.GetItemIconByID, entry.item.id)
                if ok then lootIcon = value end
            end
            if not lootIcon and GetItemIcon then
                local ok, value = pcall(GetItemIcon, entry.item.id)
                if ok then lootIcon = value end
            end
        end
        card.icon:SetTexture(isLoot and (lootIcon or "Interface\\AddOns\\Chronicle\\BossLootMedallion") or
            (isBoss and "Interface\\AddOns\\Chronicle\\BossMedallion" or "Interface\\AddOns\\Chronicle\\KeyMedallion"))
        card.caption:SetText(isLoot and C:LocalizeDisplay("BOSSBEUTE") or (isBoss and
            (kills > 0 and C:LocalizeDisplay("BOSS BESIEGT") or C:LocalizeDisplay("BOSSVERSUCH")) or C:LocalizeDisplay("INSTANZ BESUCHT")))
        if expedition then
            card.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  INSTANZ BESUCHT"))
        end
        card.name:SetText(dungeonTab == "instances" and C:LocalizeInstanceName(entry.name) or entry.name)
        card.name:SetWidth(instanceArt and (featured and math.floor(width * .56) or cardWidth - 120) or
            (featured and messageWidth or cardWidth - 75))
        local main = isLoot and (C:LocalizeDisplay("Erhalten von: ") .. U.SafeText(entry.item.recipient, C:LocalizeDisplay("Unbekannt"))) or
            (isBoss and (kills .. C:LocalizeDisplay(" Siege  |  ") .. tostring(entry.data.attempts or 0) .. C:LocalizeDisplay(" Versuche")) or
            (tostring(entry.data.entries or 0) .. C:LocalizeDisplay(" Besuche") ..
                (entry.data.difficulty and entry.data.difficulty ~= "" and
                    ("  |  " .. entry.data.difficulty) or "")))
        local detail = isLoot and (U.SafeText(entry.bossName, "Boss") .. "  |  " .. U.Date(entry.item.time, true) ..
            (entry.item.source == "reconstructed" and C:LocalizeDisplay("  •  rekonstruiert") or "")) or
            ((isBoss and U.SafeText(entry.data.zone, C:LocalizeDisplay("Unbekannt")) or C:LocalizeDisplay("Erstmals: ") ..
            (entry.data.firstSeen and U.Date(entry.data.firstSeen, true) or C:LocalizeDisplay("nicht erfasst"))) ..
            "  |  " .. (entry.data.lastSeen and U.Date(entry.data.lastSeen, true) or C:LocalizeDisplay("nicht erfasst")))
        card.main:SetText(main); card.main:SetWidth(featured and messageWidth or cardWidth - 26)
        card.detail:SetText(detail); card.detail:SetWidth(featured and messageWidth or cardWidth - 26)
        card.main:SetShown(not expedition); card.detail:SetShown(not expedition)
        card.milestoneRule:SetShown(expedition)
        if expedition then
            local instanceWins = 0
            local instanceName = tostring(entry.name or ""):lower():gsub("^die ", ""):gsub("^der ", ""):gsub("^das ", "")
            for _, boss in pairs(C.char.bosses or {}) do
                local bossPlace = tostring(boss.instanceName or boss.zone or ""):lower():gsub("^die ", ""):gsub("^der ", ""):gsub("^das ", "")
                if bossPlace == instanceName then
                    instanceWins = instanceWins + (tonumber(boss.kills) or 0)
                end
            end
            card.instanceWins = instanceWins
            local labels = { "ERSTER BESUCH", "LETZTER BESUCH", "BOSS-SIEGE" }
            local values = {
                entry.data.firstSeen and U.Date(entry.data.firstSeen, true) or "nicht erfasst",
                entry.data.lastSeen and U.Date(entry.data.lastSeen, true) or "nicht erfasst",
                tostring(instanceWins),
            }
            local milestoneWidth = math.floor((width - 44) / 3)
            for milestoneIndex, milestone in ipairs(card.milestones) do
                local x = 22 + (milestoneIndex - 1) * milestoneWidth
                milestone.label:ClearAllPoints(); milestone.label:SetPoint("TOPLEFT", x, -191)
                milestone.label:SetWidth(milestoneWidth - 12); milestone.label:SetText(C:LocalizeDisplay(labels[milestoneIndex])); milestone.label:Show()
                milestone.value:ClearAllPoints(); milestone.value:SetPoint("TOPLEFT", x, -213)
                milestone.value:SetWidth(milestoneWidth - 12); milestone.value:SetText(values[milestoneIndex]); milestone.value:Show()
            end
        else
            for _, milestone in ipairs(card.milestones) do milestone.label:Hide(); milestone.value:Hide() end
        end
        card.entryName, card.tooltipMain, card.tooltipDetail = entry.name,
            expedition and (main .. "  |  " .. tostring(card.instanceWins or 0) .. C:LocalizeDisplay(" Boss-Siege")) or main, detail
        card.itemLink = isLoot and entry.item.link or nil
        card.recipient = isLoot and entry.item.recipient or nil
        card.bossName = isLoot and entry.bossName or nil
        card.itemSource = isLoot and entry.item.source or nil
        card.chapterName = dungeonTab == "instances" and entry.name or nil
        card.chapterData = dungeonTab == "instances" and entry.data or nil
        if isLoot then
            card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -246 - (index - 1) * 62)
            card:SetWidth(width); card:SetHeight(58); card:SetBackdrop(nil)
            if card.chronicleMaterial then card.chronicleMaterial:Hide() end
            if card.chronicleCorners then
                for _, mark in ipairs(card.chronicleCorners) do mark:Hide() end
            end
            card.motif:Hide(); card.featureRule:Hide(); card.medallion:Hide()
            card.leftFlourish:Hide(); card.rightFlourish:Hide(); card.bottomFlourish:Hide()
            card.milestoneRule:Hide(); card.accent:Hide(); card.caption:Hide()
            card.icon:Show(); card.icon:ClearAllPoints(); card.icon:SetPoint("LEFT", 12, 0); card.icon:SetSize(38, 38)
            card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 62, -8)
            card.name:SetWidth(width - 280); card.name:SetJustifyH("LEFT"); setFont(card.name, 13, TEXT)
            local quality = tonumber(type(entry.item.link) == "string" and entry.item.link:match("|cnIQ(%d+):"))
            local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
            if color then card.name:SetTextColor(color.r, color.g, color.b) end
            card.detail:ClearAllPoints(); card.detail:SetPoint("BOTTOMLEFT", 62, 9)
            card.detail:SetWidth(width - 280); card.detail:SetJustifyH("LEFT"); setFont(card.detail, 10, MUTED)
            card.main:ClearAllPoints(); card.main:SetPoint("BOTTOMRIGHT", -16, 9)
            card.main:SetWidth(200); card.main:SetJustifyH("RIGHT"); setFont(card.main, 10, GOLD)
        end
        if isBoss then
            card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -278 - (index - 1) * 62)
            card:SetWidth(width); card:SetHeight(58); card:SetBackdrop(nil)
            if card.chronicleMaterial then card.chronicleMaterial:Hide() end
            if card.chronicleCorners then
                for _, mark in ipairs(card.chronicleCorners) do mark:Hide() end
            end
            card.motif:Hide(); card.featureRule:Hide(); card.medallion:Hide()
            card.leftFlourish:Hide(); card.rightFlourish:Hide(); card.bottomFlourish:Hide()
            card.milestoneRule:Hide(); card.accent:Hide(); card.caption:Hide(); card.icon:Hide()
            card.lootRule:Show()
            card.ordinal:ClearAllPoints(); card.ordinal:SetPoint("LEFT", 13, 0)
            card.ordinal:SetWidth(37); card.ordinal:SetText(string.format("%02d", index))
            card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 62, -7)
            card.name:SetWidth(width - 280); card.name:SetJustifyH("LEFT")
            setFont(card.name, 14, kills > 0 and GOLD or TEXT)
            card.detail:ClearAllPoints(); card.detail:SetPoint("BOTTOMLEFT", 62, 9)
            card.detail:SetWidth(width - 280); card.detail:SetJustifyH("LEFT"); setFont(card.detail, 10, MUTED)
            card.main:ClearAllPoints(); card.main:SetPoint("RIGHT", -16, 0)
            card.main:SetWidth(200); card.main:SetJustifyH("RIGHT"); setFont(card.main, 11, GOLD)
        end
        card:Show()
    end
    for index = used + 1, #dungeonCards do dungeonCards[index]:Hide() end
    local chapterHeight = 0
    if dungeonHero.bossChapter then dungeonHero.bossChapter:Hide() end
    if #entries == 0 then
        if not dungeonEmpty then
            dungeonEmpty = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            dungeonEmpty.accent = dungeonEmpty:CreateTexture(nil, "ARTWORK"); dungeonEmpty.accent:Hide()
            dungeonEmpty.accent:SetTexture(BACKGROUND); dungeonEmpty.accent:SetVertexColor(.82, .44, .26)
            dungeonEmpty.accent:SetPoint("TOPLEFT", 3, -3); dungeonEmpty.accent:SetPoint("BOTTOMLEFT", 3, 3)
            dungeonEmpty.accent:SetWidth(3)
            dungeonEmpty.motif = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Dungeons")
            dungeonEmpty.motif:SetPoint("BOTTOMRIGHT", -9, 8)
            dungeonEmpty.motif:SetSize(300, 300); dungeonEmpty.motif:SetAlpha(.28)
            dungeonEmpty.icon = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.icon:SetSize(62, 62)
            dungeonEmpty.medallion = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.medallion:SetTexture("Interface\\AddOns\\Chronicle\\KeyMedallion")
            dungeonEmpty.medallion:SetSize(94, 94)
            dungeonEmpty.leftFlourish = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.leftFlourish:SetTexture(BACKGROUND); dungeonEmpty.leftFlourish:SetVertexColor(.62, .4, .16, .7)
            dungeonEmpty.leftFlourish:SetHeight(1)
            dungeonEmpty.rightFlourish = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.rightFlourish:SetTexture(BACKGROUND); dungeonEmpty.rightFlourish:SetVertexColor(.62, .4, .16, .7)
            dungeonEmpty.rightFlourish:SetHeight(1)
            dungeonEmpty.bottomFlourish = dungeonEmpty:CreateTexture(nil, "ARTWORK")
            dungeonEmpty.bottomFlourish:SetTexture(BACKGROUND); dungeonEmpty.bottomFlourish:SetVertexColor(.62, .4, .16, .65)
            dungeonEmpty.bottomFlourish:SetHeight(1)
            dungeonEmpty.title = dungeonEmpty:CreateFontString(nil, "OVERLAY")
            setFont(dungeonEmpty.title, 25, TEXT); dungeonEmpty.title:SetJustifyH("CENTER")
            dungeonEmpty.detail = dungeonEmpty:CreateFontString(nil, "OVERLAY")
            setFont(dungeonEmpty.detail, 12, MUTED); dungeonEmpty.detail:SetJustifyH("CENTER")
        end
        dungeonEmpty:ClearAllPoints(); dungeonEmpty:SetPoint("TOPLEFT", 4, -246)
        dungeonEmpty:SetWidth(width)
        dungeonEmpty:SetHeight(stageHeight)
        openSurface(dungeonEmpty)
        local messageWidth = math.max(330, width - 280)
        local messageCenter = math.floor(messageWidth / 2) + 10
        dungeonEmpty.icon:ClearAllPoints(); dungeonEmpty.icon:SetPoint("TOP", dungeonEmpty, "TOPLEFT", messageCenter, -43)
        dungeonEmpty.icon:Hide()
        dungeonEmpty.medallion:Show()
        dungeonEmpty.medallion:SetTexture("Interface\\AddOns\\Chronicle\\" ..
            (dungeonTab == "loot" and "BossLootMedallion" or
                (dungeonTab == "bosses" and "BossMedallion" or "KeyMedallion")))
        dungeonEmpty.medallion:ClearAllPoints(); dungeonEmpty.medallion:SetPoint("TOP", dungeonEmpty, "TOPLEFT", messageCenter, -35)
        dungeonEmpty.leftFlourish:ClearAllPoints(); dungeonEmpty.leftFlourish:SetPoint("TOPLEFT", 64, -82)
        dungeonEmpty.leftFlourish:SetWidth(math.max(25, messageCenter - 120))
        dungeonEmpty.rightFlourish:ClearAllPoints(); dungeonEmpty.rightFlourish:SetPoint("TOPLEFT", messageCenter + 57, -82)
        dungeonEmpty.rightFlourish:SetWidth(math.max(25, messageWidth - messageCenter - 95))
        dungeonEmpty.bottomFlourish:ClearAllPoints(); dungeonEmpty.bottomFlourish:SetPoint("BOTTOM", dungeonEmpty, "BOTTOMLEFT", messageCenter, 48)
        dungeonEmpty.bottomFlourish:SetWidth(160)
        dungeonEmpty.title:ClearAllPoints(); dungeonEmpty.title:SetPoint("TOP", dungeonEmpty, "TOPLEFT", messageCenter, -143)
        dungeonEmpty.title:SetWidth(messageWidth)
        dungeonEmpty.detail:ClearAllPoints(); dungeonEmpty.detail:SetPoint("TOP", dungeonEmpty, "TOPLEFT", messageCenter, -218)
        dungeonEmpty.detail:SetWidth(messageWidth - 35)
        dungeonEmpty.motif:SetTexture("Interface\\AddOns\\Chronicle\\Motif_" ..
            (dungeonTab == "loot" and "Loot" or (dungeonTab == "bosses" and "Deaths" or "Dungeons")))
        dungeonEmpty.title:SetText(query ~= "" and C:LocalizeDisplay("Keine Treffer gefunden") or
            (dungeonTab == "instances" and C:LocalizeDisplay("Noch keine Instanz besucht") or
                (dungeonTab == "loot" and C:LocalizeDisplay("Noch keine Bossbeute erfasst") or C:LocalizeDisplay("Noch kein Bosskampf erfasst"))))
        dungeonEmpty.detail:SetText(query ~= "" and C:LocalizeDisplay("Versuche einen anderen Suchbegriff.") or
            (dungeonTab == "instances" and C:LocalizeDisplay("Besuche eine Instanz, um sie automatisch in deiner Chronicle zu erfassen.") or
                (dungeonTab == "loot" and C:LocalizeDisplay("Gegenstände und Empfänger erscheinen hier nach einem erfassten Boss-Sieg.") or
                    C:LocalizeDisplay("Dein erster Bosskampf erscheint hier, sobald WoW ihn meldet."))))
        dungeonEmpty:Show()
    elseif dungeonEmpty then dungeonEmpty:Hide() end
    scrollChild:SetHeight(math.max(330, dungeonTab == "bosses" and (278 + #entries * 62 + 12) or
        dungeonTab == "loot" and (246 + #entries * 62 + 12) or
        (#entries == 1 and (246 + (dungeonTab == "instances" and 245 or 190) + chapterHeight + 27) or
        (246 + math.ceil(#entries / 2) * 132 + 12)),
        #entries == 0 and (246 + dungeonEmpty:GetHeight() + 12) or 0))
end

function C:OpenDungeonChapter(instanceName, instanceData)
    local chapter = self.dungeonChapterWindow
    if not chapter then
        chapter = CreateFrame("Frame", "ChronicleDungeonChapterWindow", UIParent, "BackdropTemplate")
        chapter:SetSize(820, 630)
        chapter:SetPoint("CENTER")
        chapter:SetFrameStrata("DIALOG")
        chapter:SetToplevel(true)
        chapter:SetClampedToScreen(true)
        chapter:EnableMouse(true)
        chapter:SetMovable(true)
        chapter:RegisterForDrag("LeftButton")
        chapter:SetScript("OnDragStart", chapter.StartMoving)
        chapter:SetScript("OnDragStop", chapter.StopMovingOrSizing)
        backdrop(chapter, .075, .049, .029, .98)
        -- The chapter needs its own opaque surface: the main page must not show
        -- through the boss names when this window is open.
        chapter.surface = chapter:CreateTexture(nil, "BACKGROUND")
        chapter.surface:SetTexture(BACKGROUND)
        chapter.surface:SetVertexColor(.075, .049, .029, 1)
        chapter.surface:SetPoint("TOPLEFT", 4, -4)
        chapter.surface:SetPoint("BOTTOMRIGHT", -4, 4)
        self:OrnateCorners(chapter)
        chapter.caption = chapter:CreateFontString(nil, "OVERLAY")
        chapter.caption:SetPoint("TOPLEFT", 25, -20); setFont(chapter.caption, 10, GOLD)
        chapter.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  INSTANZKAPITEL"))
        chapter.title = chapter:CreateFontString(nil, "OVERLAY")
        chapter.title:SetPoint("TOPLEFT", 24, -49); chapter.title:SetWidth(405)
        chapter.title:SetJustifyH("LEFT"); setFont(chapter.title, 26, TEXT)
        chapter.summary = chapter:CreateFontString(nil, "OVERLAY")
        chapter.summary:SetPoint("TOPLEFT", 26, -106); chapter.summary:SetWidth(392)
        setFont(chapter.summary, 11, MUTED)
        chapter.stats = {}
        for index, label in ipairs({ "BESUCHE", "BOSSE", "SIEGE" }) do
            local stat = chapter:CreateFontString(nil, "OVERLAY")
            stat:SetPoint("TOPLEFT", 26 + (index - 1) * 133, -145)
            setFont(stat, 27, GOLD)
            local caption = chapter:CreateFontString(nil, "OVERLAY")
            caption:SetPoint("TOPLEFT", 27 + (index - 1) * 133, -179)
            setFont(caption, 9, MUTED)
            caption:SetText(C:LocalizeDisplay(label))
            chapter.stats[index] = stat
        end
        chapter.art = chapter:CreateTexture(nil, "ARTWORK", nil, -8)
        chapter.art:SetPoint("TOPRIGHT", -18, -13)
        chapter.art:SetSize(425, 198)
        chapter.art:SetTexCoord(0, 1, .08, .92)
        chapter.artFade = {}
        for index = 1, 16 do
            local strip = chapter:CreateTexture(nil, "ARTWORK", nil, -7)
            strip:SetTexture(BACKGROUND)
            strip:SetPoint("TOPLEFT", 377 + (index - 1) * 8, -13)
            strip:SetSize(8, 198)
            strip:SetVertexColor(.075, .049, .029, (1 - (index - 1) / 16) ^ 1.5)
            chapter.artFade[index] = strip
        end
        chapter.rule = chapter:CreateTexture(nil, "ARTWORK")
        chapter.rule:SetTexture(BACKGROUND); chapter.rule:SetVertexColor(.6, .4, .16, .85)
        chapter.rule:SetPoint("TOPLEFT", 24, -220)
        chapter.rule:SetPoint("TOPRIGHT", -24, -220)
        chapter.rule:SetHeight(1)
        chapter.section = chapter:CreateFontString(nil, "OVERLAY")
        chapter.section:SetPoint("TOPLEFT", 25, -232); setFont(chapter.section, 13, GOLD)
        chapter.section:SetText(C:LocalizeDisplay("Bossbegegnungen"))
        chapter.count = chapter:CreateFontString(nil, "OVERLAY")
        chapter.count:SetPoint("TOPRIGHT", -38, -235); setFont(chapter.count, 10, MUTED)
        chapter.close = CreateFrame("Button", nil, chapter, "UIPanelCloseButton")
        chapter.close:SetPoint("TOPRIGHT", -5, -5)
        chapter.close:SetScript("OnClick", function() chapter:Hide() end)
        chapter.scroll = CreateFrame("ScrollFrame", nil, chapter, "UIPanelScrollFrameTemplate")
        chapter.scroll:SetPoint("TOPLEFT", 24, -263)
        chapter.scroll:SetPoint("BOTTOMRIGHT", -43, 24)
        chapter.scrollChild = CreateFrame("Frame", nil, chapter.scroll)
        chapter.scrollChild:SetWidth(730); chapter.scrollChild:SetHeight(1)
        chapter.scroll:SetScrollChild(chapter.scrollChild)
        chapter.rows = {}
        chapter.empty = chapter.scrollChild:CreateFontString(nil, "OVERLAY")
        chapter.empty:SetPoint("TOPLEFT", 4, -16); setFont(chapter.empty, 12, MUTED)
        chapter.empty:SetText(C:LocalizeDisplay("Noch kein Bosskampf in dieser Instanz erfasst."))
        chapter:SetScript("OnHide", function() GameTooltip:Hide() end)
        self.dungeonChapterWindow = chapter
    end
    local bosses = {}
    local normalized = self:NormalizeInstanceName(instanceName)
    for _, boss in pairs(self.char.bosses or {}) do
        if self:NormalizeInstanceName(boss.instanceName or boss.zone) == normalized then
            bosses[#bosses + 1] = boss
        end
    end
    table.sort(bosses, function(a, b)
        return (tonumber(a.lastSeen) or 0) > (tonumber(b.lastSeen) or 0)
    end)
    chapter.title:SetText(instanceName)
    chapter.summary:SetText(C:LocalizeDisplay("Erstmals ") ..
        (tonumber(instanceData.firstSeen) and U.Date(instanceData.firstSeen, true) or C:LocalizeDisplay("nicht erfasst")) ..
        C:LocalizeDisplay("   •   Zuletzt ") ..
        (tonumber(instanceData.lastSeen) and U.Date(instanceData.lastSeen, true) or C:LocalizeDisplay("nicht erfasst")))
    local totalWins = 0
    for _, boss in ipairs(bosses) do totalWins = totalWins + (tonumber(boss.kills) or 0) end
    chapter.stats[1]:SetText(string.format("%02d", tonumber(instanceData.entries) or 0))
    chapter.stats[2]:SetText(string.format("%02d", #bosses))
    chapter.stats[3]:SetText(string.format("%02d", totalWins))
    chapter.count:SetText(#bosses .. C:LocalizeDisplay(" ERFASST"))
    local art = self:GetPackagedInstanceArt(instanceName) or
        self.dungeonInstanceArtByMap[tonumber(instanceData.instanceID)] or
        self.dungeonInstanceArtByName[normalized]
    chapter.art:SetShown(art ~= nil)
    for _, strip in ipairs(chapter.artFade) do strip:SetShown(art ~= nil) end
    if art then chapter.art:SetTexture(art) end
    local columnWidth = 360
    local pairTop, pairHeight = 0, 0
    for index, boss in ipairs(bosses) do
        local row = chapter.rows[index]
        if not row then
            row = CreateFrame("Frame", nil, chapter.scrollChild)
            row:SetHeight(68); row:EnableMouse(true)
            row.number = row:CreateFontString(nil, "OVERLAY")
            row.number:SetPoint("TOPLEFT", 4, -12); setFont(row.number, 19, GOLD)
            row.name = row:CreateFontString(nil, "OVERLAY")
            row.name:SetPoint("TOPLEFT", 48, -9); row.name:SetWidth(300)
            row.name:SetJustifyH("LEFT"); setFont(row.name, 14, TEXT)
            row.meta = row:CreateFontString(nil, "OVERLAY")
            row.meta:SetPoint("TOPLEFT", 49, -36); setFont(row.meta, 10, MUTED)
            row.lootLabel = row:CreateFontString(nil, "OVERLAY")
            row.lootLabel:SetPoint("TOPLEFT", 49, -57); setFont(row.lootLabel, 10, GOLD)
            row.lootItems = {}
            row.rule = row:CreateTexture(nil, "ARTWORK")
            row.rule:SetTexture(BACKGROUND); row.rule:SetVertexColor(.42, .3, .14, .7)
            row.rule:SetPoint("BOTTOMLEFT", 4, 0)
            row.rule:SetPoint("BOTTOMRIGHT", -8, 0); row.rule:SetHeight(1)
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.bossName, 1, .82, .1)
                GameTooltip:AddLine(self.wins .. C:LocalizeDisplay(" Siege  •  ") .. self.attempts .. C:LocalizeDisplay(" Versuche"), .95, .84, .67)
                GameTooltip:AddLine(C:LocalizeDisplay("Zuletzt: ") .. U.Date(self.lastSeen), .72, .65, .52)
                C:ShowLocalizedTooltip()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            chapter.rows[index] = row
        end
        local column = (index - 1) % 2
        if column == 0 and index > 1 then pairTop = pairTop + pairHeight + 12; pairHeight = 0 end
        local rareLoot = {}
        for _, item in ipairs(boss.loot or {}) do
            local link = type(item.link) == "string" and item.link or nil
            local quality = tonumber(item.quality) or tonumber(link and link:match("|cnIQ(%d+):"))
            if not quality and link then
                local info = C.API.ItemInfo(link)
                quality = info and tonumber(info.quality)
            end
            if not quality and link then
                local color = link:match("|cff(%x%x%x%x%x%x)")
                quality = ({ ["0070dd"] = 3, ["a335ee"] = 4, ["ff8000"] = 5,
                    ["e6cc80"] = 6, ["00ccff"] = 7 })[color and color:lower()]
            end
            if quality and quality >= 3 then rareLoot[#rareLoot + 1] = { item = item, quality = quality } end
        end
        local rowHeight = #rareLoot > 0 and (94 + (#rareLoot - 1) * 23) or 70
        pairHeight = math.max(pairHeight, rowHeight)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", column * columnWidth, -pairTop)
        row:SetWidth(columnWidth - 10)
        row:SetHeight(rowHeight)
        row.number:SetText(string.format("%02d", index))
        row.bossName = U.SafeText(boss.name, "Unbekannter Boss")
        row.wins, row.attempts = tonumber(boss.kills) or 0, tonumber(boss.attempts) or 0
        row.lastSeen = boss.lastSeen
        row.name:SetText(row.bossName)
        row.meta:SetText(row.wins .. C:LocalizeDisplay(" Siege  •  ") .. row.attempts .. C:LocalizeDisplay(" Versuche"))
        row.lootLabel:SetText(C:LocalizeDisplay("SELTENE BEUTE  /  ") .. #rareLoot)
        row.lootLabel:SetShown(#rareLoot > 0)
        for lootIndex, entry in ipairs(rareLoot) do
            local button = row.lootItems[lootIndex]
            if not button then
                button = CreateFrame("Button", nil, row)
                button:SetHeight(24); button:SetWidth(290)
                button.iconFallback = button:CreateTexture(nil, "ARTWORK")
                button.iconFallback:SetSize(20, 20)
                button.iconFallback:SetPoint("LEFT", 0, 0)
                button.iconFallback:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                button.icon = button:CreateTexture(nil, "OVERLAY")
                button.icon:SetSize(20, 20)
                button.icon:SetPoint("LEFT", 0, 0)
                button.name = button:CreateFontString(nil, "OVERLAY")
                button.name:SetPoint("LEFT", button.icon, "RIGHT", 7, 0)
                button.name:SetWidth(255); button.name:SetJustifyH("LEFT")
                setFont(button.name, 11, TEXT)
                button:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    local shown = self.itemLink and pcall(GameTooltip.SetHyperlink, GameTooltip, self.itemLink)
                    if not shown then GameTooltip:AddLine(self.itemName or C:LocalizeDisplay("Bossbeute"), 1, .82, .1) end
                    GameTooltip:AddLine(C:LocalizeDisplay("Boss: ") .. (self.bossName or "?"), .75, .7, .6)
                    C:ShowLocalizedTooltip()
                end)
                button:SetScript("OnLeave", function() GameTooltip:Hide() end)
                row.lootItems[lootIndex] = button
            end
            local item = entry.item
            local link = item.link
            local itemID = tonumber(item.id) or tonumber(link and link:match("|Hitem:(%d+)")) or
                tonumber(link and link:match("item:(%d+)"))
            local itemName = link and link:match("|h%[(.-)%]|h") or ("Gegenstand #" .. tostring(item.id or "?"))
            local info = link and C.API.ItemInfo(link)
            local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[entry.quality]
            button.name:SetText(itemName .. ((tonumber(item.count) or 1) > 1 and ("  x" .. item.count) or ""))
            button.name:SetTextColor(color and color.r or 0, color and color.g or .44, color and color.b or 1)
            local icon = info and info.icon
            if (not icon or icon == 0) and itemID and C_Item and C_Item.GetItemIconByID then
                local ok, value = pcall(C_Item.GetItemIconByID, itemID)
                if ok then icon = value end
            end
            if (not icon or icon == 0) and itemID and GetItemIcon then
                local ok, value = pcall(GetItemIcon, itemID)
                if ok then icon = value end
            end
            if (not icon or icon == 0) and itemID and GetItemInfoInstant then
                local ok, _, _, _, _, value = pcall(GetItemInfoInstant, itemID)
                if ok then icon = value end
            end
            if not icon or icon == 0 or icon == "" then
                icon = item.icon or ({
                    [6469] = "Interface\\Icons\\INV_Weapon_Bow_10",
                    [15450] = "Interface\\Icons\\INV_Pants_07",
                })[itemID]
            end
            if type(icon) ~= "string" and type(icon) ~= "number" or icon == 0 or icon == "" then
                if itemID and C_Item and C_Item.RequestLoadItemDataByID then
                    pcall(C_Item.RequestLoadItemDataByID, itemID)
                end
                icon = "Interface\\Icons\\INV_Misc_QuestionMark"
            end
            button.icon:SetTexture(icon)
            button.itemLink, button.itemName, button.bossName = link, itemName, row.bossName
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", 49, -69 - (lootIndex - 1) * 23)
            button:Show()
        end
        for lootIndex = #rareLoot + 1, #row.lootItems do row.lootItems[lootIndex]:Hide() end
        if #rareLoot == 0 then
            if not row.emptyLoot then
                row.emptyLoot = row:CreateFontString(nil, "OVERLAY")
                row.emptyLoot:SetPoint("TOPLEFT", 49, -55); setFont(row.emptyLoot, 10, MUTED)
                row.emptyLoot:SetText(C:LocalizeDisplay("Noch keine seltene Beute erfasst"))
            end
            row.emptyLoot:Show()
        elseif row.emptyLoot then row.emptyLoot:Hide() end
        row:Show()
    end
    for index = #bosses + 1, #chapter.rows do chapter.rows[index]:Hide() end
    chapter.empty:SetShown(#bosses == 0)
    chapter.scrollChild:SetHeight(math.max(70, pairTop + pairHeight + 8))
    chapter.scroll:SetVerticalScroll(0)
    chapter:Show()
    chapter:Raise()
end

local function showTimelineRows()
    body:Hide()
    local width = availableContentWidth()
    local all = C.char.events or {}
    local matching = {}
    for _, event in ipairs(all) do
        local category = timelineKinds[event.kind] or { "Erinnerung", "other", "Interface\\Icons\\INV_Misc_Book_09", { .74, .66, .51 } }
        if timelineFilter == "all" or timelineFilter == category[2] then
            matching[#matching + 1] = { event = event, category = category }
        end
    end
    local display = {}
    local position = 1
    while position <= #matching do
        local first = matching[position]
        local event = first.event
        if event.kind == "quest" and type(event.text) == "string" and
            event.text:match("^Quest angenommen:") then
            local minute = math.floor((tonumber(event.time) or 0) / 60)
            local last = position + 1
            while last <= #matching do
                local nextEvent = matching[last].event
                if nextEvent.kind ~= "quest" or type(nextEvent.text) ~= "string" or
                    not nextEvent.text:match("^Quest angenommen:") or
                    math.floor((tonumber(nextEvent.time) or 0) / 60) ~= minute then break end
                last = last + 1
            end
            if last - position >= 3 then
                local group = { event = event, category = first.category, grouped = true, members = {} }
                for index = position, last - 1 do group.members[#group.members + 1] = matching[index] end
                display[#display + 1] = group
                if timelineExpanded[event] then
                    for _, member in ipairs(group.members) do
                        display[#display + 1] = { event = member.event, category = member.category, child = true }
                    end
                end
                position = last
            else
                display[#display + 1] = first
                position = position + 1
            end
        else
            display[#display + 1] = first
            position = position + 1
        end
    end
    local selectedItem
    for index, item in ipairs(display) do
        if index > timelineLimit then break end
        if item.event == C.timelineSelection and (not not item.child) == (not not C.timelineSelectedChild) then
            selectedItem = item; break
        end
    end
    if not selectedItem then selectedItem = display[1] end
    C.timelineSelection = selectedItem and selectedItem.event or nil
    C.timelineSelectedChild = selectedItem and not not selectedItem.child or nil
    if not timelineHero then
        timelineHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        timelineHero:SetPoint("TOPLEFT", 4, 0); timelineHero:SetHeight(112)
        heroBackdrop(timelineHero)
        timelineHero.accent = timelineHero:CreateTexture(nil, "ARTWORK"); timelineHero.accent:Hide()
        timelineHero.accent:SetTexture(BACKGROUND); timelineHero.accent:SetVertexColor(.9, .63, .16, 1)
        timelineHero.accent:SetPoint("TOPLEFT", 4, -4); timelineHero.accent:SetPoint("BOTTOMLEFT", 4, 4); timelineHero.accent:SetWidth(4)
        timelineHero.caption = timelineHero:CreateFontString(nil, "OVERLAY")
        timelineHero.caption:SetPoint("TOPLEFT", 20, -14); setFont(timelineHero.caption, 11, GOLD)
        timelineHero.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  ABENTEUER"))
        timelineHero.summary = timelineHero:CreateFontString(nil, "OVERLAY")
        timelineHero.summary:SetPoint("TOPLEFT", 20, -37); timelineHero.summary:SetJustifyH("LEFT"); setFont(timelineHero.summary, 24, TEXT)
        timelineHero.detail = timelineHero:CreateFontString(nil, "OVERLAY")
        timelineHero.detail:SetPoint("TOPLEFT", 20, -63); timelineHero.detail:SetJustifyH("LEFT"); setFont(timelineHero.detail, 10, MUTED)
        timelineHero.stats = timelineHero:CreateFontString(nil, "OVERLAY")
        timelineHero.stats:SetPoint("TOPLEFT", 20, -91); setFont(timelineHero.stats, 10, GOLD)
        timelineHero.icon = timelineHero:CreateTexture(nil, "ARTWORK")
        timelineHero.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
        timelineHero.icon:SetSize(58, 58); timelineHero.icon:SetPoint("RIGHT", -22, 0)
    end
    timelineHero:SetWidth(width)
    C:SetHeroMotif(timelineHero, "Timeline")
    timelineHero.icon:Hide()
    timelineHero.summary:SetText(C:LocalizeDisplay("Deine Erinnerungen"))
    timelineHero.detail:SetText(C:LocalizeDisplay("Erlebnisse und Meilensteine deiner Reise"))
    timelineHero.stats:SetText(#all .. C:LocalizeDisplay(" ERINNERUNGEN    |    ") .. #matching .. C:LocalizeDisplay(" ANGEZEIGT") ..
        (all[1] and C:LocalizeDisplay("    |    ZULETZT ") .. U.Date(all[1].time, true) or ""))
    timelineHero:Show()

    local filterOptions = {
        { "all", "Alle" }, { "quests", "Quests & Ziele" }, { "travel", "Reise" },
        { "professions", "Berufe" }, { "other", "Weitere" },
    }
    local gap = 9
    local filterWidth = math.floor((width - gap * 4) / 5)
    for index, option in ipairs(filterOptions) do
        local button = timelineFilters[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate"); button:SetHeight(28)
            C:StyleChronicleButton(button)
            button.label = button:CreateFontString(nil, "OVERLAY"); button.label:SetPoint("CENTER"); setFont(button.label, 10, TEXT)
            button:SetScript("OnClick", function(self)
                timelineFilter = self.filterKey; timelineLimit = 100; C.timelineSelection = nil; C.timelineSelectedChild = nil
                showTimelineRows(); scroll:SetVerticalScroll(0)
            end)
            timelineFilters[index] = button
        end
        local active = timelineFilter == option[1]
        button.filterKey = option[1]
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 4 + (index - 1) * (filterWidth + gap), -127)
        button:SetWidth(filterWidth)
        backdrop(button, active and .26 or .075, active and .17 or .055, active and .055 or .034, 1)
        button.label:SetText(C:LocalizeDisplay(option[2])); button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:Show()
    end

    local listWidth = math.floor(width * .51)
    local offset, usedDays, usedCards, lastDay = 178, 0, 0, nil
    for index = 1, math.min(#display, timelineLimit) do
        local item = display[index]
        local event, category = item.event, item.category
        local eventTime = tonumber(event.time) or time()
        local day = date("%d.%m.%Y", eventTime)
        if day ~= lastDay then
            usedDays = usedDays + 1
            local dayRow = timelineDays[usedDays]
            if not dayRow then
                dayRow = CreateFrame("Frame", nil, scrollChild); dayRow:SetHeight(31)
                dayRow.label = dayRow:CreateFontString(nil, "OVERLAY")
                dayRow.label:SetPoint("LEFT", 10, 1); setFont(dayRow.label, 11, GOLD)
                dayRow.rule = dayRow:CreateTexture(nil, "ARTWORK")
                dayRow.rule:SetTexture(BACKGROUND); dayRow.rule:SetVertexColor(.52, .36, .13, .8)
                dayRow.rule:SetPoint("LEFT", dayRow.label, "RIGHT", 12, 0)
                dayRow.rule:SetPoint("RIGHT", -10, 0); dayRow.rule:SetHeight(1)
                timelineDays[usedDays] = dayRow
            end
            dayRow:ClearAllPoints(); dayRow:SetPoint("TOPLEFT", 4, -offset); dayRow:SetWidth(listWidth)
            dayRow.label:SetText(day); dayRow:Show()
            offset = offset + 36; lastDay = day
        end
        usedCards = usedCards + 1
        local card = timelineCards[usedCards]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            card:SetHeight(52); card:EnableMouse(true)
            card.accent = card:CreateTexture(nil, "ARTWORK"); card.accent:Hide()
            card.accent:SetTexture(BACKGROUND); card.accent:SetPoint("TOPLEFT", 4, -4)
            card.accent:SetPoint("BOTTOMLEFT", 4, 4); card.accent:SetWidth(3)
            card.icon = card:CreateTexture(nil, "ARTWORK"); card.icon:SetSize(30, 30); card.icon:SetPoint("LEFT", 12, 0)
            card.time = card:CreateFontString(nil, "OVERLAY")
            card.time:SetPoint("TOPLEFT", 50, -7); setFont(card.time, 10, GOLD)
            card.kind = card:CreateFontString(nil, "OVERLAY")
            card.kind:SetPoint("TOPRIGHT", -10, -7); card.kind:SetJustifyH("RIGHT"); setFont(card.kind, 10, MUTED)
            card.text = card:CreateFontString(nil, "OVERLAY")
            card.text:SetPoint("TOPLEFT", 50, -25); card.text:SetJustifyH("LEFT"); setFont(card.text, 12, TEXT)
            card.rule = card:CreateTexture(nil, "ARTWORK")
            card.rule:SetTexture(BACKGROUND); card.rule:SetVertexColor(.45, .31, .12, .7)
            card.rule:SetPoint("BOTTOMLEFT", 48, 0); card.rule:SetPoint("BOTTOMRIGHT", -5, 0)
            card.rule:SetHeight(1)
            card:SetScript("OnEnter", function(self)
                self:SetBackdropColor(.2, .13, .05, .66)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(C:LocalizeDisplay(self.eventTitle or "Erinnerung"), self.colorR or 1, self.colorG or .82, self.colorB or .1)
                GameTooltip:AddLine(self.eventDate or "", .72, .65, .52)
                GameTooltip:AddLine(self.eventText or "", .94, .90, .78, true)
                if self.groupMembers then
                    for memberIndex = 1, math.min(8, #self.groupMembers) do
                        GameTooltip:AddLine(C:LocalizeEventText(U.SafeText(self.groupMembers[memberIndex].event.text)), .88, .80, .62, true)
                    end
                    if #self.groupMembers > 8 then
                        GameTooltip:AddLine(C:LocalizeDisplay("Weitere Quests durch Klicken anzeigen."), .72, .65, .52)
                    end
                end
                GameTooltip:AddLine(C:LocalizeDisplay(self.groupEvent and "Klicken: Questserie öffnen oder schließen" or
                    "Klicken: Erinnerung im Dossier anzeigen"), .95, .76, .34)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self:SetBackdropColor(self.isSelected and .22 or 0, self.isSelected and .14 or 0,
                    self.isSelected and .05 or 0, self.isSelected and .9 or 0)
                self:SetBackdropBorderColor(0, 0, 0, 0)
                GameTooltip:Hide()
            end)
            card:SetScript("OnMouseUp", function(self, button)
                if button ~= "LeftButton" then return end
                C.timelineSelection = self.event
                C.timelineSelectedChild = self.isChild
                if self.groupEvent then timelineExpanded[self.groupEvent] = not timelineExpanded[self.groupEvent] end
                GameTooltip:Hide(); showTimelineRows()
            end)
            timelineCards[usedCards] = card
        end
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", item.child and 20 or 4, -offset)
        card:SetWidth(listWidth - (item.child and 16 or 0))
        card.isSelected = item == selectedItem
        backdrop(card, card.isSelected and .22 or 0, card.isSelected and .14 or 0,
            card.isSelected and .05 or 0, card.isSelected and .9 or 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
        card.accent:SetVertexColor(unpack(category[4]))
        card.icon:SetTexture(category[3]); card.time:SetText(date("%H:%M", eventTime))
        card.kind:SetText(item.grouped and C:LocalizeDisplay("QUESTSERIE") or C:LocalizeDisplay(category[1])); card.kind:SetTextColor(unpack(category[4]))
        local label = item.grouped and (#item.members .. C:LocalizeDisplay(" Quests angenommen")) or
            C:LocalizeEventText(U.SafeText(event.text, "Ereignis"))
        card.text:SetText(label); card.text:SetWidth(listWidth - 60 - (item.child and 16 or 0))
        card.eventTitle, card.eventDate, card.eventText = C:LocalizeDisplay(item.grouped and "Questserie" or category[1]), U.Date(eventTime),
            item.grouped and C:LocalizeDisplay("Alle Questnamen bleiben gespeichert.") or C:LocalizeEventText(U.SafeText(event.text, "Ereignis"))
        card.event, card.isChild = event, not not item.child
        card.groupEvent, card.groupMembers = item.grouped and event or nil, item.grouped and item.members or nil
        card.questEvent = not item.grouped and event.kind == "quest" and event or nil
        card.colorR, card.colorG, card.colorB = unpack(category[4])
        card:Show(); offset = offset + 56
    end
    if not timelineHero.dossier then
        local dossier = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        dossier.caption = dossier:CreateFontString(nil, "OVERLAY")
        dossier.caption:SetPoint("TOPLEFT", 18, -17); setFont(dossier.caption, 10, GOLD)
        dossier.icon = dossier:CreateTexture(nil, "ARTWORK")
        dossier.icon:SetSize(44, 44); dossier.icon:SetPoint("TOPRIGHT", -17, -17)
        dossier.icon:SetTexCoord(.07, .93, .07, .93)
        dossier.title = dossier:CreateFontString(nil, "OVERLAY")
        dossier.title:SetPoint("TOPLEFT", 18, -48); dossier.title:SetHeight(56)
        dossier.title:SetJustifyH("LEFT"); dossier.title:SetJustifyV("TOP")
        setFont(dossier.title, 20, TEXT)
        dossier.meta = dossier:CreateFontString(nil, "OVERLAY")
        dossier.meta:SetPoint("TOPLEFT", 19, -115); setFont(dossier.meta, 10, MUTED)
        dossier.rule = dossier:CreateTexture(nil, "ARTWORK")
        dossier.rule:SetTexture(BACKGROUND); dossier.rule:SetVertexColor(.58, .4, .16, .85)
        dossier.rule:SetPoint("TOPLEFT", 18, -142); dossier.rule:SetPoint("TOPRIGHT", -18, -142)
        dossier.rule:SetHeight(1)
        dossier.body = dossier:CreateFontString(nil, "OVERLAY")
        dossier.body:SetPoint("TOPLEFT", 19, -163)
        dossier.body:SetJustifyH("LEFT"); dossier.body:SetJustifyV("TOP")
        setFont(dossier.body, 12, TEXT)
        dossier.action = CreateFrame("Button", nil, dossier, "BackdropTemplate")
        C:StyleChronicleButton(dossier.action)
        dossier.action:SetPoint("BOTTOMLEFT", 18, 17)
        dossier.action:SetPoint("BOTTOMRIGHT", -18, 17)
        dossier.action:SetHeight(26)
        dossier.action.label = dossier.action:CreateFontString(nil, "OVERLAY")
        dossier.action.label:SetPoint("CENTER"); setFont(dossier.action.label, 11, GOLD)
        dossier.action:SetScript("OnClick", function(self)
            if self.groupEvent then
                timelineExpanded[self.groupEvent] = not timelineExpanded[self.groupEvent]
                showTimelineRows()
            elseif self.questEvent then openTimelineQuest(self.questEvent)
            elseif self.targetPage then C:ShowPage(self.targetPage) end
        end)
        timelineHero.dossier = dossier
    end
    local dossier = timelineHero.dossier
    if selectedItem then
        local event, category = selectedItem.event, selectedItem.category
        local dossierWidth = width - listWidth - 20
        dossier:ClearAllPoints(); dossier:SetPoint("TOPLEFT", listWidth + 16, -178)
        dossier:SetSize(dossierWidth, selectedItem.grouped and
            math.min(430, 260 + math.min(#selectedItem.members, 9) * 20) or 255)
        heroBackdrop(dossier)
        dossier.caption:SetText(C:LocalizeDisplay("CHRONICLE  /  ") .. (selectedItem.grouped and C:LocalizeDisplay("QUESTSERIE") or C:LocalizeDisplay(category[1]:upper())))
        dossier.icon:SetTexture(category[3])
        dossier.title:SetWidth(dossierWidth - 88)
        local title = selectedItem.grouped and (#selectedItem.members .. C:LocalizeDisplay(" Quests angenommen")) or
            C:LocalizeEventText(U.SafeText(event.text, "Erinnerung"))
        dossier.title:SetFont(C:FontPath(), #title > 52 and 15 or (#title > 30 and 17 or 20))
        dossier.title:SetText(title)
        dossier.meta:SetWidth(dossierWidth - 36)
        dossier.meta:SetText(U.Date(event.time) .. "   •   " .. C:LocalizeDisplay(category[1]))
        local description
        if selectedItem.grouped then
            local names = {}
            for index, member in ipairs(selectedItem.members) do
                if index > 9 then break end
                names[#names + 1] = "• " .. U.SafeText(member.event.text):gsub("^Quest angenommen: ", "")
            end
            if #selectedItem.members > 9 then names[#names + 1] = C:LocalizeDisplay("… und weitere Aufgaben") end
            description = C:LocalizeDisplay("Diese Aufgaben wurden zusammen angenommen:\n\n") .. table.concat(names, "\n")
        elseif event.kind == "quest" then
            description = C:LocalizeDisplay("Diese Aufgabe ist in deiner Chronik gespeichert. ") ..
                (activeTimelineQuest(event) and C:LocalizeDisplay("Sie steht noch im aktuellen Questlog.") or
                C:LocalizeDisplay("Sie steht nicht mehr im aktuellen Questlog."))
        else
            description = C:LocalizeDisplay("Dieses Ereignis wurde auf deiner Reise automatisch in der Chronik festgehalten.")
        end
        dossier.body:SetWidth(dossierWidth - 38)
        dossier.body:SetText(description)
        dossier.action.groupEvent = selectedItem.grouped and event or nil
        dossier.action.questEvent = not selectedItem.grouped and activeTimelineQuest(event) and event or nil
        dossier.action.targetPage = nil
        if not dossier.action.groupEvent and not dossier.action.questEvent then
            local destinations = { quest = "quests", goal = "goals", zone = "zones", login = "zones",
                dungeon = "dungeons", boss = "dungeons", rare = "loot", death = "deaths",
                level = "stats", profession = "professions", recipe = "professions",
                merchant = "npcs", note = "notes" }
            dossier.action.targetPage = destinations[event.kind]
        end
        dossier.action.label:SetText(dossier.action.groupEvent and
            (timelineExpanded[event] and C:LocalizeDisplay("Questserie einklappen") or C:LocalizeDisplay("Questserie aufklappen")) or
            (dossier.action.questEvent and C:LocalizeDisplay("Im WoW-Questlog öffnen") or C:LocalizeDisplay("Chronicle-Rubrik öffnen")))
        dossier.action:SetShown(dossier.action.groupEvent ~= nil or
            dossier.action.questEvent ~= nil or dossier.action.targetPage ~= nil)
        backdrop(dossier.action, .22, .14, .055, 1)
        dossier:Show()
    else
        dossier:Hide()
    end
    if #matching == 0 then
        if not timelineEmpty then
            timelineEmpty = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            timelineEmpty:SetHeight(58)
            timelineEmpty.text = timelineEmpty:CreateFontString(nil, "OVERLAY")
            timelineEmpty.text:SetPoint("LEFT", 16, 0); setFont(timelineEmpty.text, 11, MUTED)
        end
        timelineEmpty:ClearAllPoints(); timelineEmpty:SetPoint("TOPLEFT", 4, -offset); timelineEmpty:SetWidth(width)
        openSurface(timelineEmpty)
        timelineEmpty.text:SetText(#all == 0 and C:LocalizeDisplay("Noch keine Erinnerungen erfasst.") or C:LocalizeDisplay("Keine Einträge in diesem Filter."))
        timelineEmpty:Show(); offset = offset + 66
    elseif timelineEmpty then
        timelineEmpty:Hide()
    end
    for index = usedDays + 1, #timelineDays do timelineDays[index]:Hide() end
    for index = usedCards + 1, #timelineCards do timelineCards[index]:Hide() end

    if #display > timelineLimit then
        if not timelineMore then
            timelineMore = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(timelineMore)
            timelineMore:SetHeight(34)
            timelineMore.label = timelineMore:CreateFontString(nil, "OVERLAY")
            timelineMore.label:SetPoint("CENTER"); setFont(timelineMore.label, 11, GOLD)
            timelineMore:SetScript("OnClick", function() timelineLimit = timelineLimit + 100; showTimelineRows() end)
        end
        timelineMore:ClearAllPoints(); timelineMore:SetPoint("TOPLEFT", 4, -offset); timelineMore:SetWidth(listWidth)
        backdrop(timelineMore, .12, .08, .035, 1)
        timelineMore.label:SetText(C:LocalizeDisplay("Weitere Erinnerungen anzeigen (") .. math.min(timelineLimit, #display) .. " / " .. #display .. ")")
        timelineMore:Show(); offset = offset + 42
    elseif timelineMore then
        timelineMore:Hide()
    end
    scrollChild:SetHeight(math.max(600, offset + 10))
end

local function showDeathRows()
    body:Hide()
    local width = availableContentWidth()
    local entries, zones = {}, {}
    for _, row in ipairs(C.char.deaths or {}) do
        if type(row) == "table" then
            entries[#entries + 1] = row
            local zone = U.SafeText(row.zone)
            if zone ~= "Unbekannt" then zones[zone] = true end
        end
    end
    table.sort(entries, function(a, b) return (tonumber(a.time) or 0) > (tonumber(b.time) or 0) end)
    local total = math.max(tonumber(C.char.stats and C.char.stats.deathCount) or 0, #entries)
    local last = entries[1]
    local zoneCount = U.Count(zones)
    local listWidth = math.floor(width * .55)

    if not deathHero then
        deathHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        deathHero:SetHeight(184)
        deathHero.caption = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.caption:SetPoint("TOPLEFT", 103, -23); setFont(deathHero.caption, 10, GOLD)
        deathHero.caption:SetText(C:LocalizeDisplay("DER LETZTE FALL"))
        deathHero.eyebrow = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.eyebrow:Hide()
        deathHero.title = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.title:SetPoint("TOPLEFT", 101, -42); setFont(deathHero.title, 29, TEXT)
        deathHero.title:SetJustifyH("LEFT")
        deathHero.detail = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.detail:SetPoint("TOPLEFT", 103, -80); setFont(deathHero.detail, 12, MUTED)
        deathHero.detail:SetJustifyH("LEFT")
        deathHero.icon = deathHero:CreateTexture(nil, "ARTWORK")
        deathHero.icon:SetTexture("Interface\\AddOns\\Chronicle\\DeathMedallion")
        deathHero.icon:SetSize(66, 66)
        deathHero.seal = CreateFrame("Frame", nil, deathHero, "BackdropTemplate")
        deathHero.seal:SetSize(72, 72); deathHero.seal:SetPoint("TOPLEFT", 17, -20)
        deathHero.seal:SetBackdrop(nil)
        deathHero.icon:SetParent(deathHero.seal)
        deathHero.icon:SetPoint("CENTER", deathHero.seal, "CENTER", 0, 0)
        deathHero.icon:SetDrawLayer("ARTWORK", 1)
        deathHero.date = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.date:SetPoint("TOPRIGHT", -20, -43); setFont(deathHero.date, 18, GOLD)
        deathHero.date:SetJustifyH("RIGHT")
        deathHero.time = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.time:SetPoint("TOPRIGHT", -21, -69); setFont(deathHero.time, 10, MUTED)
        deathHero.time:SetJustifyH("RIGHT")
        deathHero.dateCaption = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.dateCaption:SetPoint("TOPRIGHT", -21, -23)
        setFont(deathHero.dateCaption, 10, MUTED)
        deathHero.dateCaption:SetText(C:LocalizeDisplay("ZEITPUNKT"))
        deathHero.dateDivider = deathHero:CreateTexture(nil, "ARTWORK")
        deathHero.dateDivider:SetTexture(BACKGROUND)
        deathHero.dateDivider:SetVertexColor(.57, .39, .18, .7)
        deathHero.dateDivider:SetPoint("TOPRIGHT", -170, -21)
        deathHero.dateDivider:SetSize(1, 73)
        deathHero.cause = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.cause:SetPoint("TOPLEFT", 103, -100); setFont(deathHero.cause, 11, TEXT)
        deathHero.cause:SetJustifyH("LEFT")
        deathHero.summary = deathHero:CreateFontString(nil, "OVERLAY")
        deathHero.summary:SetPoint("BOTTOMLEFT", 19, 9); setFont(deathHero.summary, 10, GOLD)
        deathHero.summary:SetJustifyH("LEFT")
        deathHero.metricRule = deathHero:CreateTexture(nil, "ARTWORK")
        deathHero.metricRule:SetTexture(BACKGROUND)
        deathHero.metricRule:SetVertexColor(.58, .38, .17, .7)
        deathHero.metricRule:SetPoint("TOPLEFT", 18, -128)
        deathHero.metricRule:SetPoint("TOPRIGHT", -18, -128)
        deathHero.metricRule:SetHeight(1)
        deathHero.metrics = {}
        for index, label in ipairs({ C:L("deathCases"), C:L("deathPlaces"), C:L("combatRecords") }) do
            local metric = CreateFrame("Frame", nil, deathHero)
            metric.value = metric:CreateFontString(nil, "OVERLAY")
            metric.value:SetPoint("TOPLEFT", 1, 0); setFont(metric.value, 23, GOLD)
            metric.label = metric:CreateFontString(nil, "OVERLAY")
            metric.label:SetPoint("TOPLEFT", 2, -30); setFont(metric.label, 10, MUTED)
            metric.label:SetText(label)
            deathHero.metrics[index] = metric
        end
        deathHero.section = CreateFrame("Frame", nil, scrollChild)
        deathHero.section:SetHeight(39)
        deathHero.section.title = deathHero.section:CreateFontString(nil, "OVERLAY")
        deathHero.section.title:SetPoint("TOPLEFT", 4, -2); setFont(deathHero.section.title, 19, GOLD)
        deathHero.section.title:SetText(C:LocalizeDisplay("Todeschronik"))
        deathHero.section.count = deathHero.section:CreateFontString(nil, "OVERLAY")
        deathHero.section.count:SetPoint("TOPRIGHT", -4, -9); setFont(deathHero.section.count, 10, MUTED)
        deathHero.section.rule = deathHero.section:CreateTexture(nil, "ARTWORK")
        deathHero.section.rule:SetTexture(BACKGROUND)
        deathHero.section.rule:SetVertexColor(.52, .33, .15, .8)
        deathHero.section.rule:SetPoint("BOTTOMLEFT", 4, 2)
        deathHero.section.rule:SetPoint("BOTTOMRIGHT", -4, 2)
        deathHero.section.rule:SetHeight(1)
        deathHero.section.emblem = deathHero.section:CreateTexture(nil, "ARTWORK")
        deathHero.section.emblem:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
        deathHero.section.emblem:SetSize(18, 18); deathHero.section.emblem:SetPoint("LEFT", 5, 7)
        deathHero.section.title:ClearAllPoints(); deathHero.section.title:SetPoint("TOPLEFT", 29, -2)
        deathHero.dayHeaders = {}
        deathHero:EnableMouse(true)
        deathHero:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then deathHero.selectedIndex = 1; showDeathRows() end
        end)
        deathHero.memorial = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        deathHero.memorial:SetHeight(335)
        local panel = deathHero.memorial
        panel.art = panel:CreateTexture(nil, "BACKGROUND")
        panel.art:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Deaths")
        panel.art:SetSize(245, 245); panel.art:SetPoint("BOTTOMRIGHT", -5, 5)
        panel.art:SetAlpha(.13)
        panel.spine = panel:CreateTexture(nil, "ARTWORK")
        panel.spine:SetTexture(BACKGROUND)
        panel.spine:SetVertexColor(.8, .53, .19, .82)
        panel.spine:SetPoint("TOPLEFT", 4, -17)
        panel.spine:SetPoint("BOTTOMLEFT", 4, 17)
        panel.spine:SetWidth(2)
        panel.caption = panel:CreateFontString(nil, "OVERLAY")
        panel.caption:SetPoint("TOPLEFT", 22, -18); setFont(panel.caption, 10, GOLD)
        panel.caption:SetJustifyH("LEFT")
        panel.title = panel:CreateFontString(nil, "OVERLAY")
        panel.title:SetPoint("TOPLEFT", 21, -43); setFont(panel.title, 29, TEXT)
        panel.title:SetJustifyH("LEFT")
        panel.subZone = panel:CreateFontString(nil, "OVERLAY")
        panel.subZone:SetPoint("TOPLEFT", 23, -80); setFont(panel.subZone, 11, MUTED)
        panel.subZone:SetJustifyH("LEFT")
        panel.rule = panel:CreateTexture(nil, "ARTWORK")
        panel.rule:SetTexture(BACKGROUND); panel.rule:SetVertexColor(.65, .42, .2, .75)
        panel.rule:SetPoint("TOPLEFT", 22, -109); panel.rule:SetPoint("TOPRIGHT", -22, -109)
        panel.rule:SetHeight(1)
        panel.whenLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.whenLabel:SetPoint("TOPLEFT", 23, -126); setFont(panel.whenLabel, 10, GOLD)
        panel.whenLabel:SetText(C:LocalizeDisplay("ZEITPUNKT"))
        panel.when = panel:CreateFontString(nil, "OVERLAY")
        panel.when:SetPoint("TOPLEFT", 23, -146); setFont(panel.when, 12, TEXT)
        panel.when:SetJustifyH("LEFT")
        panel.killerLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.killerLabel:SetPoint("TOPLEFT", 23, -184); setFont(panel.killerLabel, 10, GOLD)
        panel.killerLabel:SetText(C:LocalizeDisplay("GEGNER"))
        panel.killer = panel:CreateFontString(nil, "OVERLAY")
        panel.killer:SetPoint("TOPLEFT", 23, -204); setFont(panel.killer, 12, TEXT)
        panel.killer:SetJustifyH("LEFT")
        panel.causeLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.causeLabel:SetPoint("TOPLEFT", 23, -242); setFont(panel.causeLabel, 10, GOLD)
        panel.causeLabel:SetText(C:LocalizeDisplay("TODESURSACHE"))
        panel.cause = panel:CreateFontString(nil, "OVERLAY")
        panel.cause:SetPoint("TOPLEFT", 23, -262); setFont(panel.cause, 12, TEXT)
        panel.cause:SetJustifyH("LEFT")
        panel.note = panel:CreateFontString(nil, "OVERLAY")
        panel.note:SetPoint("BOTTOMLEFT", 23, 16); setFont(panel.note, 10, MUTED)
        panel.note:SetJustifyH("LEFT")
        panel.hitTitle = panel:CreateFontString(nil, "OVERLAY")
        panel.hitTitle:SetPoint("TOPLEFT", 23, -307); setFont(panel.hitTitle, 11, GOLD)
        panel.hitTitle:SetText(C:LocalizeDisplay("LETZTE TREFFER"))
        panel.hitRows = {}
        for index = 1, 6 do
            local hit = CreateFrame("Frame", nil, panel)
            hit:SetHeight(29)
            hit:SetPoint("TOPLEFT", 23, -335 - (index - 1) * 31)
            hit.time = hit:CreateFontString(nil, "OVERLAY")
            hit.time:SetPoint("LEFT", 0, 0); setFont(hit.time, 10, MUTED)
            hit.name = hit:CreateFontString(nil, "OVERLAY")
            hit.name:SetPoint("LEFT", 72, 0); setFont(hit.name, 11, TEXT)
            hit.amount = hit:CreateFontString(nil, "OVERLAY")
            hit.amount:SetPoint("RIGHT", 0, 0); setFont(hit.amount, 11, GOLD)
            hit.amount:SetJustifyH("RIGHT")
            panel.hitRows[index] = hit
        end
        panel.emptyTitle = panel:CreateFontString(nil, "OVERLAY")
        panel.emptyTitle:SetPoint("TOPLEFT", 23, -263); setFont(panel.emptyTitle, 18, GOLD)
        panel.emptyTitle:SetText(C:LocalizeDisplay("Die Kampfspur fehlt"))
        panel.emptyBody = panel:CreateFontString(nil, "OVERLAY")
        panel.emptyBody:SetPoint("TOPLEFT", 24, -300); setFont(panel.emptyBody, 12, MUTED)
        panel.emptyBody:SetJustifyV("TOP")
        panel.emptyBody:SetText(C:LocalizeDisplay("Für ältere Fälle wurde noch kein Kampflog gespeichert. Ab dem nächsten Tod hält die Chronik Gegner, Fähigkeit und die letzten Treffer fest."))
    end
    deathHero:ClearAllPoints(); deathHero:SetPoint("TOPLEFT", 4, 0)
    deathHero:SetWidth(width); heroBackdrop(deathHero)
    if deathHero.motifClip then deathHero.motifClip:Hide() end
    deathHero.title:SetWidth(width - 300)
    deathHero.detail:SetWidth(width - 300)
    deathHero.cause:SetWidth(width - 300)
    deathHero.title:SetText(last and U.SafeText(last.zone) or C:L("noDeathRecorded"))
    deathHero.date:SetText(last and date("%d.%m.%Y", last.time or time()) or "")
    deathHero.time:SetText(last and (date("%H:%M", last.time or time()) .. C:L("timeSuffix")) or "")
    deathHero.detail:SetText(last and
        U.SafeText(last.subZone, type(last.instance) == "table" and last.instance.name or C:L("placeUnknown")) or
        C:L("deathEmptyDetail"))
    local latestCause = last and U.SafeText(last.cause, "") or ""
    deathHero.cause:SetText(latestCause ~= "" and
        ((U.SafeText(last.killer, "") ~= "" and U.SafeText(last.killer) .. "  ·  " or "") .. latestCause) or "")
    deathHero.summary:SetText("")
    local loggedCount = 0
    for _, entry in ipairs(entries) do
        if type(entry.combatLog) == "table" and #entry.combatLog > 0 then
            loggedCount = loggedCount + 1
        end
    end
    local metricWidth = math.floor((width - 36) / 3)
    for index, metric in ipairs(deathHero.metrics) do
        metric:ClearAllPoints()
        metric:SetPoint("TOPLEFT", deathHero, "TOPLEFT", 19 + (index - 1) * metricWidth, -137)
        metric:SetSize(metricWidth, 43)
        metric.value:SetText(index == 1 and total or index == 2 and zoneCount or loggedCount)
        metric:Show()
    end
    deathHero:Show()

    local selectedIndex = deathHero.selectedIndex or 1
    if selectedIndex > #entries then selectedIndex = #entries end
    deathHero.selectedIndex = selectedIndex
    local selected = entries[selectedIndex]
    local panel = deathHero.memorial
    if selected then
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", 12 + listWidth, -249)
        panel:SetWidth(width - listWidth - 8)
        heroBackdrop(panel)
        panel.caption:SetText(C:L("memorialCase") .. string.format("%02d", selectedIndex))
        panel.title:SetText(U.SafeText(selected.zone))
        panel.title:SetWidth(width - listWidth - 55)
        panel.subZone:SetText(U.SafeText(selected.subZone,
            type(selected.instance) == "table" and selected.instance.name or C:L("placeUnknown")))
        panel.subZone:SetWidth(width - listWidth - 55)
        panel.when:SetText(date("%d.%m.%Y   %H:%M", selected.time or time()))
        panel.killer:SetWidth(width - listWidth - 55)
        panel.cause:SetWidth(width - listWidth - 55)
        local hasCause = U.SafeText(selected.cause, "") ~= ""
        local combatLog = type(selected.combatLog) == "table" and selected.combatLog or {}
        if hasCause then
            panel:SetHeight(367 + math.min(6, #combatLog) * 31)
            panel.emptyTitle:Hide(); panel.emptyBody:Hide()
            panel.killerLabel:SetText(C:LocalizeDisplay("GEGNER"))
            panel.killer:SetText(U.SafeText(selected.killer, C:L("environment")))
            panel.causeLabel:Show(); panel.cause:Show()
            panel.cause:SetText(U.SafeText(selected.cause))
            panel.hitTitle:Show()
            panel.note:SetText(C:L(#combatLog == 0 and "logNotRecorded" or "fatalHits"))
        else
            panel:SetHeight(440)
            panel.emptyTitle:Show(); panel.emptyBody:Show()
            panel.emptyBody:SetWidth(width - listWidth - 65)
            panel.killerLabel:SetText(C:LocalizeDisplay("KAMPFDATEN"))
            panel.killer:SetText(C:LocalizeDisplay("Für diesen Fall nicht gespeichert"))
            panel.causeLabel:Hide(); panel.cause:Hide()
            panel.hitTitle:Hide()
            panel.note:SetText("")
        end
        for index, hitRow in ipairs(panel.hitRows) do
            local hit = hasCause and combatLog[index] or nil
            if hit then
                hitRow:SetWidth(panel:GetWidth() - 47)
                hitRow.time:SetText(date("%H:%M:%S", hit.time or selected.time or time()))
                hitRow.name:SetWidth(panel:GetWidth() - 190)
                hitRow.name:SetText(U.SafeText(hit.killer, C:LocalizeDisplay("Umgebung")) .. " · " ..
                    U.SafeText(hit.cause, C:LocalizeDisplay("Treffer")))
                hitRow.name:SetTextColor(unpack(hit.fatal and GOLD or TEXT))
                hitRow.amount:SetText(tostring(hit.damage or "") .. (hit.fatal and "!" or ""))
                hitRow:Show()
            else
                hitRow:Hide()
            end
        end
        panel.note:SetWidth(width - listWidth - 55)
        panel:Show()
    else panel:Hide() end

    deathHero.section:ClearAllPoints(); deathHero.section:SetPoint("TOPLEFT", 4, -208)
    deathHero.section:SetWidth(width)
    deathHero.section.count:SetText(#entries .. C:LocalizeDisplay(" Einträge"))
    deathHero.section:Show()
    local offset, dayUsed = 249, 0
    if #entries == 0 then
        if not deathEmpty then
            deathEmpty = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            deathEmpty:SetHeight(118)
            deathEmpty.title = deathEmpty:CreateFontString(nil, "OVERLAY")
            deathEmpty.title:SetPoint("TOPLEFT", 20, -26); setFont(deathEmpty.title, 19, GOLD)
            deathEmpty.detail = deathEmpty:CreateFontString(nil, "OVERLAY")
            deathEmpty.detail:SetPoint("TOPLEFT", 20, -66); setFont(deathEmpty.detail, 11, MUTED)
        end
        deathEmpty:ClearAllPoints(); deathEmpty:SetPoint("TOPLEFT", 4, -offset)
        deathEmpty:SetWidth(listWidth); openSurface(deathEmpty)
        deathEmpty.title:SetText(C:LocalizeDisplay("Deine Chronik wartet"))
        deathEmpty.detail:SetText(C:LocalizeDisplay("Beim nächsten Tod werden Ort und Zeitpunkt hier festgehalten."))
        deathEmpty:Show(); offset = offset + 132
    elseif deathEmpty then deathEmpty:Hide() end

    local previousDay
    for index = 1, #entries do
        local row = entries[index]
        local timestamp = tonumber(row.time) or time()
        local day = date("%d.%m.%Y", timestamp)
        if day ~= previousDay then
            dayUsed = dayUsed + 1
            local heading = deathHero.dayHeaders[dayUsed]
            if not heading then
                heading = CreateFrame("Frame", nil, scrollChild)
                heading:SetHeight(30)
                heading.date = heading:CreateFontString(nil, "OVERLAY")
                heading.date:SetPoint("LEFT", 82, 0); setFont(heading.date, 11, GOLD)
                heading.date:SetJustifyH("LEFT")
                heading.rule = heading:CreateTexture(nil, "ARTWORK")
                heading.rule:SetTexture(BACKGROUND)
                heading.rule:SetVertexColor(.45, .3, .15, .65)
                heading.rule:SetPoint("LEFT", heading.date, "RIGHT", 12, 0)
                heading.rule:SetPoint("RIGHT", -8, 0); heading.rule:SetHeight(1)
                heading.path = heading:CreateTexture(nil, "ARTWORK")
                heading.path:SetTexture("Interface\\AddOns\\Chronicle\\DeathRoute")
                heading.path:SetSize(16, 30); heading.path:SetPoint("LEFT", 48, 0)
                heading.path:SetTexCoord(0, 1, 0, 30 / 256)
                deathHero.dayHeaders[dayUsed] = heading
            end
            heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 4, -offset)
            heading:SetWidth(listWidth); heading.date:SetText(C:LocalizeDisplay("KAPITEL ") .. string.format("%02d", dayUsed) .. "   •   " .. day)
            heading:Show(); offset = offset + 32
            previousDay = day
        end
        local cardIndex = index
        local card = deathCards[cardIndex]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild)
            card:SetHeight(84); card:EnableMouse(true)
            card.hover = card:CreateTexture(nil, "BACKGROUND")
            card.hover:SetTexture(BACKGROUND); card.hover:SetVertexColor(.24, .15, .07, .35)
            card.hover:SetAllPoints(card); card.hover:Hide()
            card.selected = card:CreateTexture(nil, "BACKGROUND")
            card.selected:SetTexture(BACKGROUND); card.selected:SetVertexColor(.3, .18, .07, .32)
            card.selected:SetAllPoints(card); card.selected:Hide()
            card.path = card:CreateTexture(nil, "ARTWORK")
            card.path:SetTexture("Interface\\AddOns\\Chronicle\\DeathRoute")
            card.path:SetSize(16, 84); card.path:SetPoint("LEFT", 48, 0)
            card.marker = card:CreateTexture(nil, "OVERLAY")
            card.marker:SetTexture(BACKGROUND)
            card.marker:SetSize(4, 4); card.marker:SetPoint("LEFT", 54, 0)
            card.number = card:CreateFontString(nil, "OVERLAY")
            card.number:SetPoint("LEFT", 11, 0); setFont(card.number, 22, GOLD)
            card.number:SetJustifyH("LEFT")
            card.zone = card:CreateFontString(nil, "OVERLAY")
            card.zone:SetPoint("TOPLEFT", 82, -17); setFont(card.zone, 17, GOLD)
            card.zone:SetJustifyH("LEFT")
            card.date = card:CreateFontString(nil, "OVERLAY")
            card.date:SetPoint("TOPRIGHT", -12, -19); setFont(card.date, 11, MUTED)
            card.date:SetJustifyH("RIGHT")
            card.detail = card:CreateFontString(nil, "OVERLAY")
            card.detail:SetPoint("TOPLEFT", 83, -48); setFont(card.detail, 11, TEXT)
            card.detail:SetJustifyH("LEFT")
            card.rule = card:CreateTexture(nil, "ARTWORK")
            card.rule:SetTexture(BACKGROUND); card.rule:SetVertexColor(.34, .24, .13, .75)
            card.rule:SetPoint("BOTTOMLEFT", 83, 7); card.rule:SetPoint("BOTTOMRIGHT", -9, 7)
            card.rule:SetHeight(1)
            card:SetScript("OnEnter", function(self)
                self.hover:Show()
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(C:LocalizeDisplay("Tod in ") .. self.zoneText, 1, .75, .3)
                GameTooltip:AddLine(self.dateText, .9, .84, .72)
                if self.detailText ~= "" then GameTooltip:AddLine(self.detailText, .76, .69, .56) end
                if self.killerText ~= "" then GameTooltip:AddLine(C:LocalizeDisplay("Gegner: ") .. self.killerText, 1, .8, .55) end
                GameTooltip:AddLine(C:LocalizeDisplay("Ursache: ") .. self.causeText, .9, .78, .66)
                if self.damageText then GameTooltip:AddLine(C:LocalizeDisplay("Schaden: ") .. self.damageText, .8, .72, .62) end
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self) self.hover:Hide(); GameTooltip:Hide() end)
            card:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    GameTooltip:Hide()
                    deathHero.selectedIndex = self.entryIndex
                    showDeathRows()
                end
            end)
            deathCards[cardIndex] = card
        end
        local zone = U.SafeText(row.zone)
        local subZone = U.SafeText(row.subZone, "")
        local instance = type(row.instance) == "table" and U.SafeText(row.instance.name, "") or ""
        local detail = subZone ~= "" and subZone or (instance ~= "" and instance or "Kein Untergebiet erfasst")
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -offset)
        card:SetWidth(listWidth)
        card.entryIndex = index
        if index == selectedIndex then card.selected:Show() else card.selected:Hide() end
        local routePart = (index - 1) % 4
        card.path:SetTexCoord(0, 1, routePart / 4, (routePart + 1) / 4)
        card.marker:SetVertexColor(1, .75, .28, index == selectedIndex and 1 or .65)
        card.number:SetText(string.format("%02d", index))
        card.number:SetTextColor(index == selectedIndex and 1 or .95,
            index == selectedIndex and .82 or .69, index == selectedIndex and .18 or .25)
        card.zone:SetText(zone); card.zone:SetWidth(math.max(100, listWidth - 194))
        card.date:SetText(date("%H:%M", timestamp))
        local killer = U.SafeText(row.killer, "")
        local cause = U.SafeText(row.cause, "nicht erfasst")
        local summary = detail
        if U.SafeText(row.cause, "") ~= "" then
            summary = (killer ~= "" and killer .. " · " or "") .. cause
        end
        card.detail:SetText(summary); card.detail:SetWidth(math.max(100, listWidth - 114))
        if card.detail.SetWordWrap then card.detail:SetWordWrap(false) end
        card.zoneText, card.dateText, card.detailText = zone, U.Date(timestamp, true), detail
        card.killerText, card.causeText, card.damageText = killer, cause, row.damage and tostring(row.damage) or nil
        card:Show(); offset = offset + 84
    end
    for index = dayUsed + 1, #deathHero.dayHeaders do deathHero.dayHeaders[index]:Hide() end
    for index = #entries + 1, #deathCards do deathCards[index]:Hide() end
    scrollChild:SetHeight(math.max(540, offset + 14,
        selected and (249 + panel:GetHeight() + 20) or 0))
end

local function showEconomyRows()
    body:Hide()
    local width = availableContentWidth()
    local listWidth = math.floor(width * .60)
    local entries, hidden = {}, 0
    for _, entry in ipairs(C.char.economy or {}) do
        if U.IsLogoutMoneyGlitch(C.char, entry) and not C.showSuspiciousMoney then
            hidden = hidden + 1
        elseif #entries < 100 then
            entries[#entries + 1] = entry
        end
    end
    local function plainMoney(value)
        return (U.Money(value):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    local earned, spent, dailyNet = 0, 0, {}
    for _, entry in ipairs(entries) do
        local delta = tonumber(entry.delta) or 0
        if delta > 0 then earned = earned + delta elseif delta < 0 then spent = spent - delta end
        local day = date("%d.%m.%Y", entry.time or time())
        dailyNet[day] = (dailyNet[day] or 0) + delta
    end
    if not economyHero then
        economyHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        economyHero:SetSize(630, 162); economyHero:SetPoint("TOPLEFT", 4, 0)
        heroBackdrop(economyHero)
        economyHero.accent = economyHero:CreateTexture(nil, "ARTWORK"); economyHero.accent:Hide()
        economyHero.accent:SetTexture(BACKGROUND); economyHero.accent:SetVertexColor(1, .72, .20, 1)
        economyHero.accent:SetPoint("TOPLEFT", 4, -4)
        economyHero.accent:SetPoint("BOTTOMLEFT", 4, 4); economyHero.accent:SetWidth(4)
        economyHero.label = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.label:SetPoint("TOPLEFT", 19, -13); setFont(economyHero.label, 11, GOLD)
        economyHero.label:SetText(C:LocalizeDisplay("DEIN VERMÖGEN"))
        economyHero.amount = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.amount:SetPoint("TOPLEFT", 18, -34); economyHero.amount:SetWidth(480)
        economyHero.amount:SetJustifyH("LEFT"); setFont(economyHero.amount, 30, TEXT)
        economyHero.last = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.last:SetPoint("TOPLEFT", 20, -78); economyHero.last:SetWidth(575)
        economyHero.last:SetJustifyH("LEFT"); setFont(economyHero.last, 11, MUTED)
        economyHero.coin = economyHero:CreateTexture(nil, "ARTWORK")
        economyHero.coin:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        economyHero.coin:SetSize(52, 52)
        economyHero.seal = CreateFrame("Frame", nil, economyHero, "BackdropTemplate")
        economyHero.seal:SetSize(64, 64); economyHero.seal:SetPoint("TOPRIGHT", -20, -18)
        backdrop(economyHero.seal, .16, .105, .055, 1)
        economyHero.seal:SetBackdropBorderColor(.8, .57, .22, 1)
        economyHero.coin:SetParent(economyHero.seal)
        economyHero.coin:SetPoint("CENTER", economyHero.seal, "CENTER", 0, 0)
        economyHero.rule = economyHero:CreateTexture(nil, "ARTWORK")
        economyHero.rule:SetTexture(BACKGROUND); economyHero.rule:SetVertexColor(.6, .4, .14, .85)
        economyHero.rule:SetPoint("TOPLEFT", 18, -101); economyHero.rule:SetPoint("TOPRIGHT", -18, -101)
        economyHero.rule:SetHeight(1)
        economyHero.earnedLabel = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.earnedLabel:SetPoint("TOPLEFT", 19, -111); setFont(economyHero.earnedLabel, 9, MUTED)
        economyHero.earnedLabel:SetText(C:LocalizeDisplay("EINNAHMEN IM VERLAUF"))
        economyHero.earned = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.earned:SetPoint("TOPLEFT", 19, -126); setFont(economyHero.earned, 17, TEXT)
        economyHero.spentLabel = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.spentLabel:SetPoint("TOPLEFT", 265, -111); setFont(economyHero.spentLabel, 9, MUTED)
        economyHero.spentLabel:SetText(C:LocalizeDisplay("AUSGABEN IM VERLAUF"))
        economyHero.spent = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.spent:SetPoint("TOPLEFT", 265, -126); setFont(economyHero.spent, 17, TEXT)
        economyHero.netLabel = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.netLabel:SetPoint("TOPRIGHT", -19, -111); setFont(economyHero.netLabel, 9, MUTED)
        economyHero.netLabel:SetJustifyH("RIGHT"); economyHero.netLabel:SetText(C:LocalizeDisplay("BILANZ IM VERLAUF"))
        economyHero.net = economyHero:CreateFontString(nil, "OVERLAY")
        economyHero.net:SetPoint("TOPRIGHT", -19, -126); setFont(economyHero.net, 17, TEXT)
        economyHero.net:SetJustifyH("RIGHT")
        economyHero.detailPanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        local panel = economyHero.detailPanel
        panel:SetHeight(445)
        panel.art = panel:CreateTexture(nil, "ARTWORK")
        panel.art:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Economy")
        panel.art:SetSize(215, 215); panel.art:SetPoint("BOTTOMRIGHT", -5, 5)
        panel.art:SetAlpha(.19)
        panel.spine = panel:CreateTexture(nil, "ARTWORK")
        panel.spine:SetTexture(BACKGROUND); panel.spine:SetVertexColor(.58, .39, .15, .8)
        panel.spine:SetPoint("TOPLEFT", 4, -16); panel.spine:SetPoint("BOTTOMLEFT", 4, 16)
        panel.spine:SetWidth(1)
        panel.seal = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        panel.seal:SetSize(57, 57); panel.seal:SetPoint("TOPRIGHT", -18, -17)
        backdrop(panel.seal, .16, .105, .055, 1)
        panel.icon = panel.seal:CreateTexture(nil, "ARTWORK")
        panel.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        panel.icon:SetSize(47, 47); panel.icon:SetPoint("CENTER", panel.seal, "CENTER", 0, 0)
        panel.caption = panel:CreateFontString(nil, "OVERLAY")
        panel.caption:SetPoint("TOPLEFT", 22, -18); setFont(panel.caption, 10, GOLD)
        panel.caption:SetJustifyH("LEFT")
        panel.amount = panel:CreateFontString(nil, "OVERLAY")
        panel.amount:SetPoint("TOPLEFT", 21, -40); setFont(panel.amount, 28, TEXT)
        panel.amount:SetJustifyH("LEFT")
        panel.kind = panel:CreateFontString(nil, "OVERLAY")
        panel.kind:SetPoint("TOPLEFT", 23, -79); setFont(panel.kind, 11, MUTED)
        panel.kind:SetJustifyH("LEFT")
        panel.rule = panel:CreateTexture(nil, "ARTWORK")
        panel.rule:SetTexture(BACKGROUND); panel.rule:SetVertexColor(.65, .42, .2, .75)
        panel.rule:SetPoint("TOPLEFT", 22, -107); panel.rule:SetPoint("TOPRIGHT", -22, -107)
        panel.rule:SetHeight(1)
        panel.whenLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.whenLabel:SetPoint("TOPLEFT", 23, -125); setFont(panel.whenLabel, 10, GOLD)
        panel.whenLabel:SetText(C:LocalizeDisplay("ZEITPUNKT"))
        panel.when = panel:CreateFontString(nil, "OVERLAY")
        panel.when:SetPoint("TOPLEFT", 23, -145); setFont(panel.when, 12, TEXT)
        panel.when:SetJustifyH("LEFT")
        panel.zoneLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.zoneLabel:SetPoint("TOPLEFT", 23, -182); setFont(panel.zoneLabel, 10, GOLD)
        panel.zoneLabel:SetText(C:LocalizeDisplay("ORT"))
        panel.zone = panel:CreateFontString(nil, "OVERLAY")
        panel.zone:SetPoint("TOPLEFT", 23, -202); setFont(panel.zone, 12, TEXT)
        panel.zone:SetJustifyH("LEFT")
        panel.balanceLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.balanceLabel:SetPoint("TOPLEFT", 23, -240); setFont(panel.balanceLabel, 10, GOLD)
        panel.balanceLabel:SetText(C:LocalizeDisplay("KONTOSTAND DANACH"))
        panel.balance = panel:CreateFontString(nil, "OVERLAY")
        panel.balance:SetPoint("TOPLEFT", 23, -260); setFont(panel.balance, 17, TEXT)
        panel.balance:SetJustifyH("LEFT")
        panel.beforeLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.beforeLabel:SetPoint("TOPLEFT", 23, -302); setFont(panel.beforeLabel, 10, GOLD)
        panel.beforeLabel:SetText(C:LocalizeDisplay("KONTOSTAND ZUVOR"))
        panel.before = panel:CreateFontString(nil, "OVERLAY")
        panel.before:SetPoint("TOPLEFT", 23, -322); setFont(panel.before, 14, TEXT)
        panel.dayLabel = panel:CreateFontString(nil, "OVERLAY")
        panel.dayLabel:SetPoint("TOPLEFT", 23, -362); setFont(panel.dayLabel, 10, GOLD)
        panel.dayLabel:SetText(C:LocalizeDisplay("TAGESBILANZ (ANZEIGE)"))
        panel.day = panel:CreateFontString(nil, "OVERLAY")
        panel.day:SetPoint("TOPLEFT", 23, -382); setFont(panel.day, 14, TEXT)
    end
    economyHero.amount:SetText(U.Money(GetMoney and GetMoney() or C.char.money))
    economyHero:SetWidth(width); economyHero.amount:SetWidth(width - 150)
    C:SetHeroMotif(economyHero, "Economy", .25)
    economyHero.seal:Hide()
    economyHero.last:SetWidth(width - 155)
    economyHero.earned:SetText((earned > 0 and "+" or "") .. plainMoney(earned))
    economyHero.earned:SetTextColor(earned > 0 and .42 or .72, earned > 0 and .88 or .65, earned > 0 and .51 or .52)
    economyHero.spent:SetText((spent > 0 and "-" or "") .. plainMoney(spent))
    economyHero.spent:SetTextColor(spent > 0 and .93 or .72, spent > 0 and .4 or .65, spent > 0 and .35 or .52)
    local netTotal = earned - spent
    economyHero.net:SetText((netTotal > 0 and "+" or (netTotal < 0 and "-" or "")) .. plainMoney(math.abs(netTotal)))
    economyHero.net:SetTextColor(netTotal > 0 and .42 or (netTotal < 0 and .93 or .72),
        netTotal > 0 and .88 or (netTotal < 0 and .4 or .65), netTotal > 0 and .51 or (netTotal < 0 and .35 or .52))
    economyHero.last:SetText(entries[1] and
        (C:LocalizeDisplay("Letzte erfasste Bewegung: ") .. U.Date(entries[1].time, true) .. "  |  " .. U.SafeText(entries[1].zone, C:LocalizeDisplay("Unbekannt"))) or
        C:LocalizeDisplay("Noch keine Geldbewegung erfasst."))
    economyHero:Show()

    if not economyIntro then
        economyIntro = CreateFrame("Frame", nil, scrollChild)
        economyIntro:SetSize(630, 38)
        economyIntro.title = economyIntro:CreateFontString(nil, "OVERLAY")
        economyIntro.title:SetPoint("TOPLEFT", 9, -2); setFont(economyIntro.title, 15, GOLD)
        economyIntro.title:SetText(C:LocalizeDisplay("Kassenbuch"))
        economyIntro.detail = economyIntro:CreateFontString(nil, "OVERLAY")
        economyIntro.detail:SetPoint("TOPRIGHT", -10, -6); economyIntro.detail:SetWidth(410)
        economyIntro.detail:SetJustifyH("RIGHT"); setFont(economyIntro.detail, 10, MUTED)
        economyIntro.rule = economyIntro:CreateTexture(nil, "ARTWORK")
        economyIntro.rule:SetTexture(BACKGROUND); economyIntro.rule:SetVertexColor(.45, .32, .12, .9)
        economyIntro.rule:SetPoint("BOTTOMLEFT", 8, 4)
        economyIntro.rule:SetPoint("BOTTOMRIGHT", -8, 4); economyIntro.rule:SetHeight(1)
    end
    economyIntro:ClearAllPoints(); economyIntro:SetPoint("TOPLEFT", 4, -176)
    economyIntro:SetWidth(width)
    economyIntro.detail:SetText(C:LocalizeDisplay("Letzte ") .. #entries .. C:LocalizeDisplay(" Buchungen") ..
        (hidden > 0 and "  |  " .. hidden .. C:LocalizeDisplay(" Abmeldewerte ausgeblendet") or ""))
    economyIntro:Show()

    economyHero.selectedIndex = math.min(economyHero.selectedIndex or 1, #entries)
    local groups, displayRows = {}, {}
    for index, entry in ipairs(entries) do
        local delta = tonumber(entry.delta) or 0
        local minute = date("%Y%m%d%H%M", entry.time or time())
        local zone = U.SafeText(entry.zone, "Unbekannt")
        local direction = delta > 0 and "income" or (delta < 0 and "expense" or "correction")
        local previous = groups[#groups]
        if previous and previous.minute == minute and previous.zone == zone and previous.direction == direction then
            previous.count = previous.count + 1
            previous.delta = previous.delta + delta
            previous.members[#previous.members + 1] = index
        else
            groups[#groups + 1] = { minute = minute, zone = zone, direction = direction,
                firstIndex = index, first = entry, count = 1, delta = delta,
                key = minute .. "|" .. zone .. "|" .. direction .. "|" .. index,
                members = { index } }
        end
    end
    local selectedGroup
    for _, group in ipairs(groups) do
        if group.count > 1 then
            displayRows[#displayRows + 1] = { entry = group.first, index = group.firstIndex,
                group = group, isGroup = true }
            if C.economyExpandedGroups[group.key] then
                for _, index in ipairs(group.members) do
                    displayRows[#displayRows + 1] = { entry = entries[index], index = index,
                        group = group, isChild = true }
                end
            end
            if economyHero.selectedGroupKey == group.key then selectedGroup = group end
        else
            displayRows[#displayRows + 1] = { entry = group.first, index = group.firstIndex }
        end
    end
    if economyHero.selectedGroupKey and not selectedGroup then economyHero.selectedGroupKey = nil end
    if not economyHero.selectionInitialized and groups[1] and groups[1].count > 1 then
        economyHero.selectedGroupKey = groups[1].key
        selectedGroup = groups[1]
    end
    economyHero.selectionInitialized = true
    local offset, daysUsed, entriesUsed, lastDay = 222, 0, 0, nil
    for _, item in ipairs(displayRows) do
        local entry = item.entry
        local day = date("%d.%m.%Y", entry.time or time())
        if day ~= lastDay then
            daysUsed = daysUsed + 1
            local dayRow = economyDayRows[daysUsed]
            if not dayRow then
                dayRow = CreateFrame("Frame", nil, scrollChild)
                dayRow:SetSize(630, 26)
                dayRow.label = dayRow:CreateFontString(nil, "OVERLAY")
                dayRow.label:SetPoint("LEFT", 10, 0); setFont(dayRow.label, 11, GOLD)
                dayRow.rule = dayRow:CreateTexture(nil, "ARTWORK")
                dayRow.rule:SetTexture(BACKGROUND); dayRow.rule:SetVertexColor(.37, .27, .13, .75)
                dayRow.rule:SetPoint("LEFT", dayRow.label, "RIGHT", 12, 0)
                dayRow.rule:SetPoint("RIGHT", -155, 0); dayRow.rule:SetHeight(1)
                dayRow.net = dayRow:CreateFontString(nil, "OVERLAY")
                dayRow.net:SetPoint("RIGHT", -9, 0); dayRow.net:SetWidth(140)
                dayRow.net:SetJustifyH("RIGHT"); setFont(dayRow.net, 11, GOLD)
                economyDayRows[daysUsed] = dayRow
            end
            dayRow:ClearAllPoints(); dayRow:SetPoint("TOPLEFT", 4, -offset)
            dayRow:SetWidth(listWidth)
            dayRow.label:SetText(day)
            local net = dailyNet[day] or 0
            dayRow.net:SetText((net > 0 and "+" or (net < 0 and "-" or "")) .. plainMoney(math.abs(net)))
            dayRow.net:SetTextColor(net > 0 and .42 or (net < 0 and .93 or .72),
                net > 0 and .88 or (net < 0 and .4 or .65), net > 0 and .51 or (net < 0 and .35 or .52))
            dayRow:Show()
            offset = offset + 30
            lastDay = day
        end
        entriesUsed = entriesUsed + 1
        local transaction = economyEntryRows[entriesUsed]
        if not transaction then
            transaction = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            transaction:SetSize(630, 48); transaction:EnableMouse(true)
            transaction.bg = transaction:CreateTexture(nil, "BACKGROUND")
            transaction.bg:SetTexture(BACKGROUND); transaction.bg:SetVertexColor(.32, .19, .08, .22)
            transaction.bg:SetAllPoints(transaction)
            transaction.bg:Hide()
            transaction.selected = transaction:CreateTexture(nil, "BACKGROUND")
            transaction.selected:SetTexture(BACKGROUND)
            transaction.selected:SetVertexColor(.32, .19, .08, .38)
            transaction.selected:SetAllPoints(transaction); transaction.selected:Hide()
            transaction.rule = transaction:CreateTexture(nil, "ARTWORK")
            transaction.rule:SetTexture(BACKGROUND); transaction.rule:SetVertexColor(.42, .28, .13, .78)
            transaction.rule:SetPoint("BOTTOMLEFT", 11, 1); transaction.rule:SetPoint("BOTTOMRIGHT", -11, 1)
            transaction.rule:SetHeight(1)
            transaction.accent = transaction:CreateTexture(nil, "ARTWORK")
            transaction.accent:SetTexture(BACKGROUND)
            transaction.accent:SetSize(7, 7)
            transaction.accent:SetPoint("LEFT", 17, 0)
            transaction.rail = transaction:CreateTexture(nil, "ARTWORK", nil, -1)
            transaction.rail:SetTexture(BACKGROUND)
            transaction.rail:SetVertexColor(.48, .34, .14, .62)
            transaction.rail:SetPoint("TOPLEFT", 20, 0)
            transaction.rail:SetPoint("BOTTOMLEFT", 20, 0)
            transaction.rail:SetWidth(1)
            transaction.symbol = transaction:CreateTexture(nil, "ARTWORK")
            transaction.symbol:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            transaction.symbol:SetBlendMode("ADD")
            transaction.symbol:SetSize(30, 30); transaction.symbol:SetPoint("LEFT", 16, 0)
            transaction.symbol:Hide()
            transaction.core = transaction:CreateTexture(nil, "OVERLAY")
            transaction.core:SetTexture(BACKGROUND); transaction.core:SetSize(6, 6)
            transaction.core:SetPoint("CENTER", transaction.symbol, "CENTER", 0, 0)
            transaction.core:Hide()
            transaction.time = transaction:CreateFontString(nil, "OVERLAY")
            transaction.time:SetPoint("TOPLEFT", 37, -16); setFont(transaction.time, 11, MUTED)
            transaction.kind = transaction:CreateFontString(nil, "OVERLAY")
            transaction.kind:SetPoint("TOPLEFT", 99, -7); setFont(transaction.kind, 10, TEXT)
            transaction.amount = transaction:CreateFontString(nil, "OVERLAY")
            transaction.amount:SetPoint("TOPRIGHT", -12, -14); transaction.amount:SetWidth(145)
            transaction.amount:SetJustifyH("RIGHT"); setFont(transaction.amount, 16, TEXT)
            transaction.zone = transaction:CreateFontString(nil, "OVERLAY")
            transaction.zone:SetPoint("TOPLEFT", 99, -25); transaction.zone:SetWidth(245)
            transaction.zone:SetJustifyH("LEFT"); setFont(transaction.zone, 10, MUTED)
            transaction.balance = transaction:CreateFontString(nil, "OVERLAY")
            transaction.balance:SetPoint("TOPRIGHT", -15, -31); transaction.balance:SetWidth(320)
            transaction.balance:SetJustifyH("RIGHT"); setFont(transaction.balance, 11, MUTED)
            transaction.balance:Hide()
            transaction:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    if self.groupKey then
                        C.economyExpandedGroups[self.groupKey] = not C.economyExpandedGroups[self.groupKey]
                        economyHero.selectedGroupKey = self.groupKey
                    else
                        economyHero.selectedGroupKey = nil
                    end
                    economyHero.selectedIndex = self.entryIndex
                    showEconomyRows()
                end
            end)
            economyEntryRows[entriesUsed] = transaction
        end
        transaction:ClearAllPoints()
        transaction:SetPoint("TOPLEFT", item.isChild and 18 or 4, -offset)
        transaction:SetWidth(listWidth - (item.isChild and 14 or 0))
        transaction.entryIndex = item.index
        transaction.groupKey = item.isGroup and item.group.key or nil
        local active = item.isGroup and selectedGroup == item.group or
            (not item.isGroup and not selectedGroup and item.index == economyHero.selectedIndex)
        transaction.bg:SetShown(active)
        transaction.selected:Hide()
        local delta = item.isGroup and item.group.delta or (tonumber(entry.delta) or 0)
        local positive, negative = delta > 0, delta < 0
        local red = positive and .42 or (negative and .94 or .72)
        local green = positive and .88 or (negative and .4 or .65)
        local blue = positive and .51 or (negative and .35 or .52)
        transaction.accent:SetVertexColor(active and 1 or red, active and .78 or green,
            active and .25 or blue, item.isChild and .58 or .9)
        transaction.symbol:SetVertexColor(red, green, blue, .75)
        transaction.core:SetVertexColor(red, green, blue, 1)
        transaction.time:SetText(date("%H:%M", entry.time or time()))
        local kind = positive and "EINNAHME" or (negative and "AUSGABE" or "KORREKTUR")
        transaction.kind:SetText(item.isGroup and (item.group.count .. " " ..
            (positive and C:LocalizeDisplay("EINNAHMEN") or (negative and C:LocalizeDisplay("AUSGABEN") or C:LocalizeDisplay("KORREKTUREN")))) or kind)
        transaction.kind:SetTextColor(red, green, blue)
        transaction.amount:SetText((positive and "+" or (negative and "-" or "")) .. plainMoney(math.abs(delta)))
        transaction.amount:SetTextColor(red, green, blue)
        transaction.zone:SetText(U.SafeText(entry.zone, C:LocalizeDisplay("Unbekannt")) ..
            (item.isGroup and (C.economyExpandedGroups[item.group.key] and C:LocalizeDisplay("  ·  zuklappen") or C:LocalizeDisplay("  ·  aufklappen")) or ""))
        transaction.zone:SetWidth(math.max(100, listWidth - 270))
        transaction.balance:SetText(C:LocalizeDisplay("Stand: ") .. U.Money(entry.balance))
        transaction:Show()
        offset = offset + 52
    end
    local selectedIndex = economyHero.selectedIndex or 1
    if selectedIndex > #entries then selectedIndex = #entries end
    economyHero.selectedIndex = selectedIndex
    local selected = selectedGroup and { delta = selectedGroup.delta,
        balance = selectedGroup.first.balance, time = selectedGroup.first.time,
        zone = selectedGroup.zone } or entries[selectedIndex]
    local panel = economyHero.detailPanel
    if selected then
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", 12 + listWidth, -222)
        panel:SetWidth(width - listWidth - 8)
        heroBackdrop(panel)
        local delta = tonumber(selected.delta) or 0
        local positive, negative = delta > 0, delta < 0
        panel.caption:SetText((selectedGroup and C:LocalizeDisplay("SAMMELBUCHUNG  /  ") or C:LocalizeDisplay("GOLDBEWEGUNG  /  ")) ..
            string.format("%03d", selectedIndex))
        panel.amount:SetText((positive and "+" or (negative and "-" or "")) .. plainMoney(math.abs(delta)))
        panel.amount:SetTextColor(positive and .42 or (negative and .94 or .72),
            positive and .88 or (negative and .4 or .65), positive and .51 or (negative and .35 or .52))
        panel.seal:SetBackdropBorderColor(positive and .42 or (negative and .94 or .72),
            positive and .88 or (negative and .4 or .65), positive and .51 or (negative and .35 or .52), 1)
        panel.kind:SetText(selectedGroup and (selectedGroup.count .. " " ..
            (positive and C:LocalizeDisplay("EINNAHMEN") or (negative and C:LocalizeDisplay("AUSGABEN") or C:LocalizeDisplay("KORREKTUREN")))) or
            (positive and C:LocalizeDisplay("EINNAHME") or (negative and C:LocalizeDisplay("AUSGABE") or C:LocalizeDisplay("KORREKTUR"))))
        panel.when:SetText(date("%d.%m.%Y   %H:%M", selected.time or time()))
        panel.zone:SetText(U.SafeText(selected.zone, C:LocalizeDisplay("Unbekannt")))
        panel.zone:SetWidth(width - listWidth - 55)
        panel.balance:SetText(U.Money(selected.balance))
        panel.before:SetText(U.Money((tonumber(selected.balance) or 0) - delta))
        local dayNet = dailyNet[date("%d.%m.%Y", selected.time or time())] or 0
        panel.day:SetText((dayNet > 0 and "+" or (dayNet < 0 and "-" or "")) .. plainMoney(math.abs(dayNet)))
        panel.day:SetTextColor(dayNet > 0 and .42 or (dayNet < 0 and .93 or .72),
            dayNet > 0 and .88 or (dayNet < 0 and .4 or .65), dayNet > 0 and .51 or (dayNet < 0 and .35 or .52))
        panel.seal:Hide()
        panel:Show()
    else panel:Hide() end
    for i = daysUsed + 1, #economyDayRows do economyDayRows[i]:Hide() end
    for i = entriesUsed + 1, #economyEntryRows do economyEntryRows[i]:Hide() end
    if entriesUsed == 0 then
        economyIntro.detail:SetText(C:LocalizeDisplay("Noch keine Buchungen erfasst"))
    end
    scrollChild:SetHeight(math.max(680, offset + 8))
end

local function showStatsRows()
    body:Hide()
    local width = availableContentWidth()
    local statGap = 8
    local stats = U.Statistics(C.char)
    local chapterNumbers = { "01", "02", "03" }
    local targets = {
        ["GEBIETE"] = "zones", ["INSTANZEN"] = "dungeons", ["BESUCHE"] = "dungeons",
        ["TODE"] = "deaths", ["AKTIVE QUESTS"] = "quests", ["ABGESCHLOSSEN"] = "quests",
        ["OFFENE ZIELE"] = "goals", ["ERLEDIGTE ZIELE"] = "goals",
        ["NPCS"] = "npcs", ["HÄNDLER"] = "npcs", ["SELTENE KREATUREN"] = "loot",
        ["BOSSE"] = "dungeons", ["BOSSVERSUCHE"] = "dungeons", ["BOSSSIEGE"] = "dungeons",
        ["BEUTE"] = "loot", ["REZEPTE"] = "professions", ["NOTIZEN"] = "notes",
    }
    if not statsHero then
        statsHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        statsHero:SetSize(630, 150); statsHero:SetPoint("TOPLEFT", 4, 0)
        heroBackdrop(statsHero)
        statsHero.glow = statsHero:CreateTexture(nil, "BACKGROUND")
        statsHero.glow:SetTexture(BACKGROUND); statsHero.glow:SetAllPoints(statsHero)
        statsHero.glow:SetVertexColor(1, .67, .12, .08)
        statsHero.art = statsHero:CreateTexture(nil, "ARTWORK")
        statsHero.art:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Stats")
        statsHero.art:SetSize(150, 150); statsHero.art:SetPoint("TOPRIGHT", -20, 0)
        statsHero.art:SetAlpha(.22)
        statsHero.accent = statsHero:CreateTexture(nil, "ARTWORK"); statsHero.accent:Hide()
        statsHero.accent:SetTexture(BACKGROUND); statsHero.accent:SetVertexColor(1, .72, .20, 1)
        statsHero.accent:SetPoint("TOPLEFT", 4, -4)
        statsHero.accent:SetPoint("BOTTOMLEFT", 4, 4); statsHero.accent:SetWidth(4)
        statsHero.caption = statsHero:CreateFontString(nil, "OVERLAY")
        statsHero.caption:SetPoint("TOPLEFT", 122, -18); setFont(statsHero.caption, 11, GOLD)
        statsHero.caption:SetText(C:LocalizeDisplay("DAS VERMÄCHTNIS DEINER REISE"))
        statsHero.number = statsHero:CreateFontString(nil, "OVERLAY")
        statsHero.number:SetPoint("TOPLEFT", 116, -36); statsHero.number:SetWidth(320)
        statsHero.number:SetJustifyH("LEFT"); setFont(statsHero.number, 52, TEXT)
        statsHero.label = statsHero:CreateFontString(nil, "OVERLAY")
        statsHero.label:SetPoint("TOPLEFT", 122, -96); statsHero.label:SetWidth(390)
        statsHero.label:SetJustifyH("LEFT"); setFont(statsHero.label, 12, MUTED)
        statsHero.icon = statsHero:CreateTexture(nil, "ARTWORK")
        statsHero.icon:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
        statsHero.icon:SetSize(76, 76)
        statsHero.seal = CreateFrame("Frame", nil, statsHero, "BackdropTemplate")
        statsHero.seal:SetSize(90, 90); statsHero.seal:SetPoint("TOPLEFT", 17, -21)
        backdrop(statsHero.seal, .16, .105, .055, 1)
        statsHero.seal:SetBackdropBorderColor(.83, .61, .25, 1)
        statsHero.icon:SetParent(statsHero.seal)
        statsHero.icon:SetPoint("CENTER", statsHero.seal, "CENTER", 0, 0)
        statsHero.summary = statsHero:CreateFontString(nil, "OVERLAY")
        statsHero.summary:SetPoint("BOTTOMLEFT", 21, 15); statsHero.summary:SetWidth(545)
        statsHero.summary:SetJustifyH("LEFT"); setFont(statsHero.summary, 11, TEXT)
        statsHero.rule = statsHero:CreateTexture(nil, "ARTWORK")
        statsHero.rule:SetTexture(BACKGROUND); statsHero.rule:SetVertexColor(.7, .48, .15, .8)
        statsHero.rule:SetPoint("BOTTOMLEFT", 20, 37)
        statsHero.rule:SetPoint("BOTTOMRIGHT", -20, 37); statsHero.rule:SetHeight(1)
    end
    statsHero.number:SetText(tostring(stats.memories))
    statsHero:SetWidth(width)
    C:SetHeroMotif(statsHero, "Stats")
    statsHero.art:Hide()
    statsHero.label:SetText(C:LocalizeDisplay("gesammelte Erinnerungen auf deiner Reise"))
    statsHero.summary:SetText(C:LocalizeDisplay("|cff58a9f5") .. stats.zones .. C:LocalizeDisplay(" Gebiete|r   •   ") ..
        C:LocalizeDisplay("|cffffb82e") .. stats.activeQuests .. C:LocalizeDisplay(" aktive Quests|r   •   ") ..
        C:LocalizeDisplay("|cffc56cff") .. stats.npcs .. C:LocalizeDisplay(" Begegnungen|r"))
    statsHero:Show()

    local offset, headerUsed, cardUsed = 166, 0, 0
    local function section(title, subtitle, color, values, columns)
        columns = columns or 4
        local innerWidth = width - 24
        local featuredWidth = math.floor(innerWidth * .28)
        local compactColumns = width >= 850 and (#values > 4 and 4 or 3) or 2
        local compactWidth = math.floor((innerWidth - featuredWidth - statGap * compactColumns) / compactColumns)
        local compactRows = math.ceil((#values - 1) / compactColumns)
        local sectionHeight = compactRows == 1 and 78 or (compactRows * 62 + (compactRows - 1) * statGap)
        local compactHeight = compactRows == 1 and sectionHeight or 62
        headerUsed = headerUsed + 1
        local heading = statsHeaders[headerUsed]
        if not heading then
            heading = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            heading:SetSize(630, 40)
            heading.title = heading:CreateFontString(nil, "OVERLAY")
            heading.title:SetPoint("TOPLEFT", 118, -8); setFont(heading.title, 17, GOLD)
            heading.chapter = heading:CreateFontString(nil, "OVERLAY")
            heading.chapter:SetPoint("TOPLEFT", 16, -13); setFont(heading.chapter, 10, GOLD)
            heading.subtitle = heading:CreateFontString(nil, "OVERLAY")
            heading.subtitle:SetPoint("TOPRIGHT", -13, -13); heading.subtitle:SetWidth(350)
            heading.subtitle:SetJustifyH("RIGHT"); setFont(heading.subtitle, 10, MUTED)
            heading.rule = heading:CreateTexture(nil, "ARTWORK")
            heading.rule:SetTexture(BACKGROUND)
            heading.rule:SetPoint("TOPLEFT", 10, -37)
            heading.rule:SetPoint("TOPRIGHT", -10, -37); heading.rule:SetHeight(1)
            heading.mark = heading:CreateTexture(nil, "ARTWORK")
            heading.mark:SetTexture(BACKGROUND)
            heading.mark:SetPoint("TOPLEFT", 9, -9); heading.mark:SetSize(3, 22)
            statsHeaders[headerUsed] = heading
        end
        heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 4, -offset)
        heading:SetWidth(width); heading:SetHeight(42)
        heading.title:SetText(C:LocalizeDisplay(title))
        heading.chapter:SetText(C:LocalizeDisplay("KAPITEL ") .. chapterNumbers[headerUsed])
        heading.subtitle:SetText(C:LocalizeDisplay(subtitle)); heading.subtitle:SetShown(width >= 800)
        heading.rule:SetVertexColor(color[1], color[2], color[3], .78)
        heading.mark:SetVertexColor(color[1], color[2], color[3], 1)
        heading:Show(); offset = offset + 47
        for index, value in ipairs(values) do
            cardUsed = cardUsed + 1
            local card = statsCards[cardUsed]
            if not card then
                card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                card:SetSize(147, 96); card:EnableMouse(true)
                card.glow = card:CreateTexture(nil, "BACKGROUND")
                card.glow:SetTexture(BACKGROUND); card.glow:SetAllPoints(card)
                card.accent = card:CreateTexture(nil, "ARTWORK")
                card.accent:SetTexture(BACKGROUND)
                card.accent:SetPoint("BOTTOMLEFT", 4, 2)
                card.accent:SetPoint("BOTTOMRIGHT", -4, 2); card.accent:SetHeight(1)
                card.value = card:CreateFontString(nil, "OVERLAY")
                card.value:SetPoint("TOPLEFT", 15, -16); card.value:SetWidth(120)
                card.value:SetJustifyH("LEFT"); setFont(card.value, 28, TEXT)
                card.label = card:CreateFontString(nil, "OVERLAY")
                card.label:SetPoint("TOPLEFT", 15, -70); card.label:SetWidth(120)
                card.label:SetJustifyH("LEFT"); setFont(card.label, 10, MUTED)
                card:SetScript("OnEnter", function(self)
                    self.glow:SetAlpha(.14)
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:AddLine(self.labelText, 1, .82, .1)
                    GameTooltip:AddLine(C:LocalizeDisplay("Klicken, um die Rubrik zu öffnen"), .75, .69, .57)
                    C:ShowLocalizedTooltip()
                end)
                card:SetScript("OnLeave", function(self)
                    self.glow:SetAlpha(self.featured and .05 or 0)
                    GameTooltip:Hide()
                end)
                card:SetScript("OnMouseUp", function(self, button)
                    if button == "LeftButton" and self.pageTarget then
                        GameTooltip:Hide()
                        C:ShowPage(self.pageTarget)
                    end
                end)
                statsCards[cardUsed] = card
            end
            local featured = index == 1
            local compactIndex = index - 2
            local column = compactIndex % compactColumns
            local row = math.floor(compactIndex / compactColumns)
            local cardWidth = featured and featuredWidth or compactWidth
            local cardHeight = featured and sectionHeight or compactHeight
            local x = featured and 14 or (14 + featuredWidth + statGap + column * (compactWidth + statGap))
            local y = featured and offset or (offset + row * (62 + statGap))
            card:ClearAllPoints(); card:SetPoint("TOPLEFT", x, -y)
            card:SetSize(cardWidth, cardHeight)
            card.value:ClearAllPoints(); card.label:ClearAllPoints()
            if featured then
                card.label:SetPoint("TOPLEFT", 20, compactRows > 1 and -19 or -8)
                if compactRows > 1 then
                    card.value:SetPoint("TOPLEFT", 18, -39)
                else
                    card.value:SetPoint("BOTTOMLEFT", 18, 3)
                end
            else
                card.label:SetPoint("TOPLEFT", 12, -7)
                card.value:SetPoint("BOTTOMLEFT", 11, 6)
            end
            card.value:SetWidth(cardWidth - 27); card.label:SetWidth(cardWidth - 22)
            backdrop(card, .14, .092, .054, 0)
            card:SetBackdropColor(.22, .145, .075, featured and .2 or 0)
            card:SetBackdropBorderColor(0, 0, 0, 0)
            card.accent:SetVertexColor(color[1], color[2], color[3], featured and .65 or .32)
            setFont(card.value, featured and 42 or 27, TEXT)
            card.value:SetText(tostring(value[2] or 0))
            local active = (tonumber(value[2]) or 0) > 0
            card.value:SetTextColor(active and color[1] or .52, active and color[2] or .48,
                active and color[3] or .42)
            card.label:SetText(C:LocalizeDisplay(value[1]))
            card.labelText, card.pageTarget = value[1], targets[value[1]]
            card.glow:SetVertexColor(color[1], color[2], color[3], 1); card.glow:SetAlpha(featured and .05 or 0)
            card.featured = featured
            card.colorR, card.colorG, card.colorB = color[1], color[2], color[3]
            card:Show()
        end
        offset = offset + sectionHeight + 19
    end
    section("Reise", "Die Welt, die du erlebt hast", { .35, .68, .95 }, {
        { "GEBIETE", stats.zones, "Interface\\Icons\\INV_Misc_Map_01" },
        { "INSTANZEN", stats.dungeons, "Interface\\Icons\\INV_Misc_Key_03" },
        { "BESUCHE", stats.dungeonVisits, "Interface\\Icons\\Ability_Mount_RidingHorse" },
        { "TODE", stats.deaths, "Interface\\AddOns\\Chronicle\\DeathMedallion" },
    })
    section("Quests & Pläne", "Deine Aufgaben und Vorhaben", { 1, .72, .18 }, {
        { "AKTIVE QUESTS", stats.activeQuests, "Interface\\Icons\\INV_Misc_Note_01" },
        { "ABGESCHLOSSEN", stats.questCompletions, "Interface\\Icons\\INV_Misc_Note_02" },
        { "OFFENE ZIELE", stats.openGoals, "Interface\\Icons\\Ability_Hunter_MarkedForDeath" },
        { "ERLEDIGTE ZIELE", stats.completedGoals, "Interface\\Icons\\Ability_Rogue_FeignDeath" },
    })
    section("Begegnungen & Sammlung", "Was deine Chronicle bewahrt", { .72, .43, .93 }, {
        { "NPCS", stats.npcs, "Interface\\Icons\\INV_Misc_GroupNeedMore" },
        { "HÄNDLER", stats.merchants, "Interface\\Icons\\INV_Misc_Coin_01" },
        { "SELTENE KREATUREN", stats.rares, "Interface\\Icons\\Ability_Hunter_SniperShot" },
        { "BOSSE", stats.bosses, "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
        { "BOSSVERSUCHE", stats.bossAttempts, "Interface\\Icons\\Ability_DualWield" },
        { "BOSSSIEGE", stats.bossKills, "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
        { "BEUTE", stats.loot, "Interface\\Icons\\INV_Box_01" },
        { "REZEPTE", stats.recipes, "Interface\\Icons\\INV_Scroll_03" },
        { "NOTIZEN", stats.notes, "Interface\\Icons\\INV_Misc_Note_05" },
    }, 3)
    for index = headerUsed + 1, #statsHeaders do statsHeaders[index]:Hide() end
    for index = cardUsed + 1, #statsCards do statsCards[index]:Hide() end
    scrollChild:SetHeight(math.max(1, offset + 10))
end

local professionIcons = {
    ["Erste Hilfe"] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Kochkunst"] = "Interface\\Icons\\INV_Misc_Food_15",
    ["Kürschnerei"] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    ["Lederverarbeitung"] = "Interface\\Icons\\Trade_LeatherWorking",
    ["Angeln"] = "Interface\\Icons\\Trade_Fishing",
    ["Bergbau"] = "Interface\\Icons\\Trade_Mining",
    ["Kräuterkunde"] = "Interface\\Icons\\Trade_Herbalism",
    ["Alchemie"] = "Interface\\Icons\\Trade_Alchemy",
    ["Schmiedekunst"] = "Interface\\Icons\\Trade_BlackSmithing",
    ["Ingenieurskunst"] = "Interface\\Icons\\Trade_Engineering",
    ["Schneiderei"] = "Interface\\Icons\\Trade_Tailoring",
    ["Verzauberkunst"] = "Interface\\Icons\\Trade_Engraving",
}

local function showProfessionRows()
    body:Hide()
    local width = availableContentWidth()
    local names, totalRecipes, latestRecipes = {}, 0, {}
    for name in pairs(C.char.professions or {}) do names[#names + 1] = name end
    local secondaryProfessions = { ["Erste Hilfe"] = true, ["Kochkunst"] = true, ["Angeln"] = true }
    table.sort(names, function(left, right)
        local leftSecondary = secondaryProfessions[left] and true or false
        local rightSecondary = secondaryProfessions[right] and true or false
        if leftSecondary ~= rightSecondary then return not leftSecondary end
        return left < right
    end)
    local selectedName = professionHeaders.selectedName
    if not selectedName or not (C.char.professions and C.char.professions[selectedName]) then selectedName = names[1] end
    professionHeaders.selectedName = selectedName
    for professionName, recipes in pairs(C.char.recipes or {}) do
        for _, recipe in pairs(recipes) do
            totalRecipes = totalRecipes + 1
            latestRecipes[#latestRecipes + 1] = {
                name = U.SafeText(recipe.name, "Rezept #" .. tostring(recipe.id or "?")),
                profession = professionName,
                icon = recipe.icon,
                id = tonumber(recipe.id),
                learned = tonumber(recipe.firstSeen) or 0,
            }
        end
    end
    table.sort(latestRecipes, function(left, right)
        if left.learned == right.learned then return left.name < right.name end
        return left.learned > right.learned
    end)

    if not professionHero then
        professionHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        professionHero:SetPoint("TOPLEFT", 4, 0); professionHero:SetHeight(106)
        heroBackdrop(professionHero)
        professionHero.accent = professionHero:CreateTexture(nil, "ARTWORK"); professionHero.accent:Hide()
        professionHero.accent:SetTexture(BACKGROUND); professionHero.accent:SetVertexColor(1, .72, .18, 1)
        professionHero.accent:SetPoint("TOPLEFT", 4, -4); professionHero.accent:SetPoint("BOTTOMLEFT", 4, 4); professionHero.accent:SetWidth(4)
        professionHero.title = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.title:SetPoint("TOPLEFT", 20, -15); setFont(professionHero.title, 11, GOLD)
        professionHero.title:SetText(C:LocalizeDisplay("DEIN HANDWERK"))
        professionHero.summary = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.summary:SetPoint("TOPLEFT", 19, -36); setFont(professionHero.summary, 25, TEXT)
        professionHero.detail = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.detail:SetPoint("TOPLEFT", 21, -72); setFont(professionHero.detail, 11, MUTED)
        professionHero.divider = professionHero:CreateTexture(nil, "ARTWORK")
        professionHero.divider:SetTexture(BACKGROUND); professionHero.divider:SetVertexColor(.52, .36, .13, .7)
        professionHero.divider:SetPoint("TOP", professionHero, "TOP", 0, -14)
        professionHero.divider:SetPoint("BOTTOM", professionHero, "BOTTOM", 0, 14); professionHero.divider:SetWidth(1)
        professionHero.selectedLabel = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.selectedLabel:SetPoint("TOPLEFT", professionHero, "TOP", 20, -15); setFont(professionHero.selectedLabel, 10, GOLD)
        professionHero.selectedTitle = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.selectedTitle:SetPoint("TOPLEFT", professionHero, "TOP", 20, -34)
        professionHero.selectedTitle:SetPoint("TOPRIGHT", -105, -34); professionHero.selectedTitle:SetJustifyH("LEFT"); setFont(professionHero.selectedTitle, 17, TEXT)
        professionHero.selectedProgress = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.selectedProgress:SetPoint("TOPLEFT", professionHero, "TOP", 20, -61)
        professionHero.selectedProgress:SetPoint("TOPRIGHT", -105, -61); professionHero.selectedProgress:SetJustifyH("LEFT"); setFont(professionHero.selectedProgress, 10, MUTED)
        professionHero.selectedRecipes = professionHero:CreateFontString(nil, "OVERLAY")
        professionHero.selectedRecipes:SetPoint("TOPLEFT", professionHero, "TOP", 20, -80)
        professionHero.selectedRecipes:SetPoint("TOPRIGHT", -105, -80); professionHero.selectedRecipes:SetJustifyH("LEFT"); setFont(professionHero.selectedRecipes, 10, MUTED)
        professionHero.icon = professionHero:CreateTexture(nil, "ARTWORK")
        professionHero.icon:SetTexture("Interface\\Icons\\Trade_LeatherWorking")
        professionHero.icon:SetSize(62, 62); professionHero.icon:SetPoint("RIGHT", -23, 0); professionHero.icon:SetAlpha(.85)
    end
    professionHero:SetWidth(width)
    professionHero.title:SetText(C:LocalizeDisplay("DEIN HANDWERK"))
    C:SetHeroMotif(professionHero, "Professions", .3)
    professionHero.motifClip:SetShown(width >= 850)
    professionHero.icon:Hide()
    professionHero.summary:SetText(#names .. C:LocalizeDisplay(" Berufe   |   ") .. totalRecipes .. C:LocalizeDisplay(" Rezepte"))
    local lastProfessionSeen = tonumber(C.char.stats.lastSkillUpdate) or 0
    for _, name in ipairs(names) do
        lastProfessionSeen = math.max(lastProfessionSeen, tonumber(C.char.professions[name].lastSeen) or 0)
    end
    professionHero.detail:SetText(C:LocalizeDisplay("Berufsstand erfasst: ") .. (lastProfessionSeen > 0 and U.Date(lastProfessionSeen) or C:LocalizeDisplay("noch nicht erfasst")))
    if selectedName then
        local selected = C.char.professions[selectedName]
        local rank, maximum = tonumber(selected.rank) or 0, tonumber(selected.maxRank) or 0
        local count, newest = 0, nil
        for _, recipe in pairs(C.char.recipes and C.char.recipes[selectedName] or {}) do
            count = count + 1
            if not newest or (tonumber(recipe.firstSeen) or 0) > (tonumber(newest.firstSeen) or 0) then newest = recipe end
        end
        professionHero.selectedLabel:SetText(C:LocalizeDisplay("AUSGEWÄHLTER BERUF"))
        professionHero.selectedTitle:SetText(C:LocalizeDisplay(selectedName))
        professionHero.selectedProgress:SetText(rank .. " / " .. maximum .. C:LocalizeDisplay(" Fertigkeit  •  ") .. math.max(0, maximum - rank) .. C:LocalizeDisplay(" Punkte bis zum Limit"))
        professionHero.selectedRecipes:SetText(count > 0 and (count .. C:LocalizeDisplay(" Rezepte  •  Zuletzt: ") .. U.SafeText(newest.name, C:LocalizeDisplay("Unbekannt"))) or C:LocalizeDisplay("Keine Rezepte für diesen Beruf erfasst"))
        professionHero.icon:SetTexture(selected.icon or professionIcons[selectedName] or "Interface\\Icons\\INV_Misc_QuestionMark")
    else
        professionHero.selectedLabel:SetText(C:LocalizeDisplay("BERUFSDOSSIER"))
        professionHero.selectedTitle:SetText(C:LocalizeDisplay("Noch kein Beruf erfasst"))
        professionHero.selectedProgress:SetText("")
        professionHero.selectedRecipes:SetText("")
    end
    professionHero:Show()

    local offset, used, headerUsed = 122, 0, 0
    local gap = 12
    local cardWidth = width
    local recipeWidth = math.floor((width - gap) / 2)
    local lastGroup
    for index, name in ipairs(names) do
        local group = secondaryProfessions[name] and "secondary" or "primary"
        if group ~= lastGroup then
            headerUsed = headerUsed + 1
            local heading = professionHeaders[headerUsed]
            if not heading then
                heading = CreateFrame("Frame", nil, scrollChild)
                heading:SetHeight(35)
                heading.title = heading:CreateFontString(nil, "OVERLAY")
                heading.title:SetPoint("LEFT", 8, 1); setFont(heading.title, 15, GOLD)
                heading.count = heading:CreateFontString(nil, "OVERLAY")
                heading.count:SetPoint("RIGHT", -10, 1); setFont(heading.count, 10, MUTED)
                heading.rule = heading:CreateTexture(nil, "ARTWORK")
                heading.rule:SetTexture(BACKGROUND); heading.rule:SetVertexColor(.55, .39, .13, .8)
                heading.rule:SetPoint("BOTTOMLEFT", 8, 0)
                heading.rule:SetPoint("BOTTOMRIGHT", -8, 0); heading.rule:SetHeight(1)
                professionHeaders[headerUsed] = heading
            end
            heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 4, -offset)
            heading:SetWidth(width)
            heading.title:SetText(group == "primary" and C:LocalizeDisplay("I  /  Handwerkswege") or C:LocalizeDisplay("II  /  Nebenkünste"))
            local count = 0
            for _, candidate in ipairs(names) do
                if (not not secondaryProfessions[candidate]) == (group == "secondary") then
                    count = count + 1
                end
            end
            heading.count:SetText(count .. C:LocalizeDisplay(" BERUFE"))
            heading:Show(); offset = offset + 45
            lastGroup = group
        end
        used = used + 1
        local card = professionCards[used]
        if not card then
            card = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            card:SetHeight(74)
            card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            card.hoverShade = card:CreateTexture(nil, "BACKGROUND"); card.hoverShade:SetTexture(BACKGROUND)
            card.hoverShade:SetAllPoints(card); card.hoverShade:SetVertexColor(1, .72, .22, .055); card.hoverShade:Hide()
            card.separator = card:CreateTexture(nil, "ARTWORK"); card.separator:SetTexture(BACKGROUND)
            card.separator:SetVertexColor(.48, .34, .16, .7)
            card.separator:SetPoint("BOTTOMLEFT", 16, 0); card.separator:SetPoint("BOTTOMRIGHT", -16, 0); card.separator:SetHeight(1)
            card.selectedRule = card:CreateTexture(nil, "ARTWORK"); card.selectedRule:SetTexture(BACKGROUND)
            card.selectedRule:SetVertexColor(.95, .72, .27, .95)
            card.selectedRule:SetPoint("TOPLEFT", 4, -7); card.selectedRule:SetPoint("BOTTOMLEFT", 4, 7); card.selectedRule:SetWidth(2)
            card.icon = card:CreateTexture(nil, "ARTWORK"); card.icon:SetSize(42, 42); card.icon:SetPoint("TOPLEFT", 16, -10)
            card.name = card:CreateFontString(nil, "OVERLAY"); card.name:SetPoint("TOPLEFT", 76, -12); setFont(card.name, 16, GOLD)
            card.rank = card:CreateFontString(nil, "OVERLAY"); card.rank:SetPoint("TOPRIGHT", -17, -12); setFont(card.rank, 18, TEXT)
            card.barBg = card:CreateTexture(nil, "ARTWORK"); card.barBg:SetTexture(BACKGROUND); card.barBg:SetVertexColor(.16, .13, .09, 1)
            card.barBg:SetPoint("BOTTOMLEFT", 16, 8); card.barBg:SetPoint("BOTTOMRIGHT", -16, 8); card.barBg:SetHeight(3)
            card.bar = card:CreateTexture(nil, "OVERLAY"); card.bar:SetTexture(BACKGROUND); card.bar:SetVertexColor(.91, .66, .22, 1)
            card.bar:SetPoint("LEFT", card.barBg, "LEFT", 0, 0); card.bar:SetHeight(3)
            card.percent = card:CreateFontString(nil, "OVERLAY"); card.percent:SetPoint("TOPLEFT", 76, -37); setFont(card.percent, 11, MUTED)
            card:SetScript("OnEnter", function(self)
                self.hoverShade:Show()
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(C:LocalizeDisplay(self.professionName or "Beruf"), 1, .82, .1)
                GameTooltip:AddLine(self.rankText or "", .96, .91, .78)
                GameTooltip:AddLine(self.recipeCountText or "", .72, .65, .52)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(C:LocalizeDisplay("Linksklick: Berufsdossier  |  Rechtsklick: Berufsfenster"), .9, .84, .68, true)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self.hoverShade:Hide()
                GameTooltip:Hide()
            end)
            card:SetScript("OnClick", function(self, button)
                if button ~= "RightButton" then
                    professionHeaders.selectedName = self.professionName
                    showProfessionRows()
                    return
                end
                local profession = C.char and C.char.professions and C.char.professions[self.professionName]
                local offset = profession and tonumber(profession.spellOffset)
                local spellName
                if offset and GetSpellBookItemName then
                    local ok, found = pcall(GetSpellBookItemName, offset + 1, BOOKTYPE_PROFESSION or "professions")
                    if ok and type(found) == "string" and found ~= "" then spellName = found end
                end
                if CastSpellByName then
                    pcall(CastSpellByName, spellName or self.professionName)
                elseif offset and CastSpell then
                    pcall(CastSpell, offset + 1, BOOKTYPE_PROFESSION or "professions")
                end
            end)
            professionCards[used] = card
        end
        local p = C.char.professions[name] or {}
        local rank, maximum = tonumber(p.rank) or 0, tonumber(p.maxRank) or 0
        local ratio = maximum > 0 and math.min(1, rank / maximum) or 0
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4, -offset); card:SetWidth(cardWidth)
        card.professionName = name
        card.rankText = C:LocalizeDisplay("Fertigkeit: ") .. rank .. " / " .. maximum .. "  (" .. math.floor(ratio * 100 + .5) .. "%)"
        card.recipeCountText = U.Count(C.char.recipes and C.char.recipes[name]) .. C:LocalizeDisplay(" erfasste Rezepte")
        card.icon:SetTexture(p.icon or professionIcons[name] or "Interface\\Icons\\INV_Misc_QuestionMark")
        card.name:SetText(C:LocalizeDisplay(name)); card.rank:SetText(rank .. " / " .. maximum)
        local recipeCount = U.Count(C.char.recipes and C.char.recipes[name])
        card.percent:SetText(math.floor(ratio * 100 + .5) .. C:LocalizeDisplay("% gemeistert") ..
            (maximum > rank and C:LocalizeDisplay("   •   Noch ") .. (maximum - rank) .. C:LocalizeDisplay(" Punkte bis ") .. maximum or
                C:LocalizeDisplay("   •   Diese Ausbildungsstufe gemeistert")) .. "   •   " .. recipeCount .. C:LocalizeDisplay(" Rezepte"))
        card.selectedRule:SetShown((professionHeaders.selectedName or names[1]) == name)
        card.bar:SetWidth(math.max(1, (cardWidth - 32) * ratio)); card:Show()
        offset = offset + 82
    end
    offset = offset + 5
    for i = used + 1, #professionCards do professionCards[i]:Hide() end

    local recipeUsed = 0
    local recipeNames = {}
    for _, professionName in ipairs(names) do
        if U.Count(C.char.recipes and C.char.recipes[professionName]) > 0 then
            recipeNames[#recipeNames + 1] = professionName
        end
    end
    for _, professionName in ipairs(recipeNames) do
        local recipes = {}
        for _, recipe in pairs(C.char.recipes[professionName] or {}) do
            recipes[#recipes + 1] = U.SafeText(recipe.name, "Rezept #" .. tostring(recipe.id or "?"))
        end
        table.sort(recipes)
        headerUsed = headerUsed + 1
        local heading = professionHeaders[headerUsed]
        if not heading then
            heading = CreateFrame("Frame", nil, scrollChild)
            heading:SetHeight(35)
            heading.title = heading:CreateFontString(nil, "OVERLAY"); heading.title:SetPoint("LEFT", 8, 1); setFont(heading.title, 15, GOLD)
            heading.count = heading:CreateFontString(nil, "OVERLAY"); heading.count:SetPoint("RIGHT", -10, 1); setFont(heading.count, 10, MUTED)
            heading.rule = heading:CreateTexture(nil, "ARTWORK"); heading.rule:SetTexture(BACKGROUND); heading.rule:SetVertexColor(.55, .39, .13, .8)
            heading.rule:SetPoint("BOTTOMLEFT", 8, 0); heading.rule:SetPoint("BOTTOMRIGHT", -8, 0); heading.rule:SetHeight(1)
            professionHeaders[headerUsed] = heading
        end
        heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", 4, -offset); heading:SetWidth(width)
        heading.title:SetText(C:LocalizeDisplay(professionName)); heading.count:SetText(#recipes .. C:LocalizeDisplay(" REZEPTE")); heading:Show(); offset = offset + 45
        for index, recipeName in ipairs(recipes) do
            recipeUsed = recipeUsed + 1
            local recipe = recipeCards[recipeUsed]
            if not recipe then
                recipe = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); recipe:SetHeight(38)
                openSurface(recipe)
                recipe.icon = recipe:CreateTexture(nil, "ARTWORK"); recipe.icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
                recipe.icon:SetSize(24, 24); recipe.icon:SetPoint("LEFT", 9, 0); recipe.icon:SetAlpha(.72)
                recipe.text = recipe:CreateFontString(nil, "OVERLAY"); recipe.text:SetPoint("LEFT", 42, 0); recipe.text:SetPoint("RIGHT", -8, 0)
                recipe.text:SetJustifyH("LEFT"); setFont(recipe.text, 11, TEXT)
                recipeCards[recipeUsed] = recipe
            end
            local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
            recipe:ClearAllPoints(); recipe:SetPoint("TOPLEFT", 4 + column * (recipeWidth + gap), -(offset + row * 45)); recipe:SetWidth(recipeWidth)
            recipe.text:SetText(recipeName); recipe:Show()
        end
        offset = offset + math.ceil(#recipes / 2) * 45 + 10
    end
    if totalRecipes == 0 then
        local emptyPanel = professionHeaders.empty
        if not emptyPanel then
            emptyPanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            emptyPanel:SetHeight(94)
            emptyPanel.caption = emptyPanel:CreateFontString(nil, "OVERLAY")
            emptyPanel.caption:SetPoint("TOPLEFT", 20, -15)
            setFont(emptyPanel.caption, 10, GOLD)
            emptyPanel.caption:SetText(C:LocalizeDisplay("REZEPTARCHIV"))
            emptyPanel.title = emptyPanel:CreateFontString(nil, "OVERLAY")
            emptyPanel.title:SetPoint("TOPLEFT", 19, -36)
            setFont(emptyPanel.title, 18, TEXT)
            emptyPanel.title:SetText(C:LocalizeDisplay("Noch keine Rezepte erfasst"))
            emptyPanel.detail = emptyPanel:CreateFontString(nil, "OVERLAY")
            emptyPanel.detail:SetPoint("TOPLEFT", 20, -70)
            setFont(emptyPanel.detail, 11, MUTED)
            emptyPanel.detail:SetText(C:LocalizeDisplay("Öffne ein Berufsfenster im Spiel, um bekannte Rezepte zu erfassen."))
            emptyPanel.icon = emptyPanel:CreateTexture(nil, "ARTWORK")
            emptyPanel.icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
            emptyPanel.icon:SetPoint("RIGHT", -21, 0)
            emptyPanel.icon:SetSize(52, 52); emptyPanel.icon:SetAlpha(.5)
            professionHeaders.empty = emptyPanel
        end
        emptyPanel:ClearAllPoints(); emptyPanel:SetPoint("TOPLEFT", 4, -offset)
        emptyPanel:SetWidth(width)
        emptyPanel.caption:SetText(C:LocalizeDisplay("REZEPTARCHIV"))
        emptyPanel.title:SetText(C:LocalizeDisplay("Noch keine Rezepte erfasst"))
        emptyPanel.detail:SetText(C:LocalizeDisplay("Öffne ein Berufsfenster im Spiel, um bekannte Rezepte zu erfassen."))
        heroBackdrop(emptyPanel)
        emptyPanel:Show(); offset = offset + 106
    elseif professionHeaders.empty then
        professionHeaders.empty:Hide()
    end
    for i = headerUsed + 1, #professionHeaders do professionHeaders[i]:Hide() end
    for i = recipeUsed + 1, #recipeCards do recipeCards[i]:Hide() end

    if not latestRecipeHeader then
        latestRecipeHeader = CreateFrame("Frame", nil, scrollChild)
        latestRecipeHeader:SetHeight(39)
        latestRecipeHeader.title = latestRecipeHeader:CreateFontString(nil, "OVERLAY")
        latestRecipeHeader.title:SetPoint("LEFT", 8, 2); setFont(latestRecipeHeader.title, 16, GOLD)
        latestRecipeHeader.title:SetText(C:LocalizeDisplay("Zuletzt gelernt"))
        latestRecipeHeader.subtitle = latestRecipeHeader:CreateFontString(nil, "OVERLAY")
        latestRecipeHeader.subtitle:SetPoint("RIGHT", -10, 2); setFont(latestRecipeHeader.subtitle, 10, MUTED)
        latestRecipeHeader.subtitle:SetText(C:LocalizeDisplay("BERUFSÜBERGREIFEND"))
        latestRecipeHeader.rule = latestRecipeHeader:CreateTexture(nil, "ARTWORK")
        latestRecipeHeader.rule:SetTexture(BACKGROUND); latestRecipeHeader.rule:SetVertexColor(1, .55, .08, .9)
        latestRecipeHeader.rule:SetPoint("BOTTOMLEFT", 8, 0); latestRecipeHeader.rule:SetPoint("BOTTOMRIGHT", -8, 0); latestRecipeHeader.rule:SetHeight(1)
    end
    latestRecipeHeader:ClearAllPoints(); latestRecipeHeader:SetPoint("TOPLEFT", 4, -offset)
    latestRecipeHeader.title:SetText(C:LocalizeDisplay("Zuletzt gelernt"))
    latestRecipeHeader.subtitle:SetText(C:LocalizeDisplay("BERUFSÜBERGREIFEND"))
    latestRecipeHeader:SetWidth(width); latestRecipeHeader:Show(); offset = offset + 49

    local latestUsed = math.min(6, #latestRecipes)
    for index = 1, latestUsed do
        local entry = latestRecipes[index]
        local card = latestRecipeCards[index]
        if not card then
            card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate"); card:SetHeight(58)
            card:EnableMouse(true)
            openSurface(card)
            card.accent = card:CreateTexture(nil, "ARTWORK"); card.accent:Hide(); card.accent:SetTexture(BACKGROUND); card.accent:SetVertexColor(1, .55, .08, 1)
            card.accent:SetPoint("TOPLEFT", 4, -4); card.accent:SetPoint("BOTTOMLEFT", 4, 4); card.accent:SetWidth(3)
            card.icon = card:CreateTexture(nil, "ARTWORK"); card.icon:SetSize(34, 34); card.icon:SetPoint("LEFT", 13, 0)
            card.name = card:CreateFontString(nil, "OVERLAY"); card.name:SetPoint("TOPLEFT", 57, -11); card.name:SetPoint("RIGHT", -8, 0)
            card.name:SetJustifyH("LEFT"); setFont(card.name, 12, TEXT)
            card.meta = card:CreateFontString(nil, "OVERLAY"); card.meta:SetPoint("BOTTOMLEFT", 57, 10); card.meta:SetPoint("RIGHT", -8, 0)
            card.meta:SetJustifyH("LEFT"); setFont(card.meta, 10, MUTED)
            card:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(1, .72, .18, 1)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                local native = false
                if self.recipeID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeItemLink and GameTooltip.SetHyperlink then
                    local ok, link = pcall(C_TradeSkillUI.GetRecipeItemLink, self.recipeID)
                    if ok and type(link) == "string" and link ~= "" then
                        local shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                        native = shown and GameTooltip:NumLines() > 0
                    end
                end
                if not native and self.recipeID and GameTooltip.SetSpellByID then
                    local shown = pcall(GameTooltip.SetSpellByID, GameTooltip, self.recipeID)
                    native = shown and GameTooltip:NumLines() > 0
                end
                if not native then
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(self.recipeName or "Rezept", 1, .82, .1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(C:LocalizeDisplay("Beruf: ") .. C:LocalizeDisplay(self.professionName or "Unbekannt"), 1, .82, .1)
                GameTooltip:AddLine(C:LocalizeDisplay("Erstmals erfasst: ") .. (self.learnedAt or "unbekannt"), .72, .65, .52)
                C:ShowLocalizedTooltip()
            end)
            card:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(.59, .44, .17, 1)
                GameTooltip:Hide()
            end)
            latestRecipeCards[index] = card
        end
        local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 4 + column * (recipeWidth + gap), -(offset + row * 66)); card:SetWidth(recipeWidth)
        card.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Scroll_03")
        card.name:SetText(entry.name)
        card.meta:SetText(C:LocalizeDisplay(entry.profession) .. "  •  " .. (entry.learned > 0 and U.Date(entry.learned, true) or C:LocalizeDisplay("Zeitpunkt unbekannt")))
        card.recipeID, card.recipeName, card.professionName = entry.id, entry.name, entry.profession
        card.learnedAt = entry.learned > 0 and U.Date(entry.learned) or C:LocalizeDisplay("unbekannt")
        card:Show()
    end
    for i = latestUsed + 1, #latestRecipeCards do latestRecipeCards[i]:Hide() end
    if latestUsed == 0 then latestRecipeHeader:Hide() else offset = offset + math.ceil(latestUsed / 2) * 66 + 8 end
    scrollChild:SetHeight(math.max(1, offset + 10))
end

local function line(text, color)
    color = color or "fff0d2"; return "|cff" .. color .. tostring(text or "") .. "|r"
end
local function header(text) return "|cffffd119" .. text .. "|r\n" end
local function empty(text) return line(text or "Noch keine Daten aufgezeichnet.", "9c9076") end
local function recent(list, formatter, limit)
    local rows = {}; for i, row in ipairs(list or {}) do if i > (limit or 40) then break end; rows[#rows + 1] = formatter(row, i) end
    return #rows > 0 and table.concat(rows, "\n\n") or empty()
end

renderAltDetail = function(key)
    local a = C.db.characters[key]
    if type(a) ~= "table" then return empty("Charakter nicht mehr vorhanden.") end
    local journal = C.db.characterData and C.db.characterData[key]
    if type(journal) ~= "table" and key == C.characterKey then journal = C.char end
    local talent = type(a.talents) == "table" and a.talents or nil
    local rows = {
        header(C:CharacterDisplayName(a, key) .. " – " .. U.SafeText(a.realm, "")),
        "Stufe " .. tostring(a.level or 0) .. " " .. U.SafeText(a.raceName, "") .. " " ..
            U.SafeText(a.className, a.class) .. "  |  " .. U.SafeText(a.faction, ""),
        "Gilde: " .. U.SafeText(a.guild, "nicht erfasst") ..
            (a.guildRank and a.guildRank ~= "" and "  |  Rang: " .. a.guildRank or ""),
        "Skillung: " .. talentLabel(a) ..
            (talent and talent.loadout and talent.loadout ~= talent.name and "  |  Vorlage: " .. talent.loadout or ""),
        talentBranchText(a),
        "Letzter Ort: " .. U.SafeText(a.zone) .. "  |  Zuletzt: " ..
            (type(a.lastSeen) == "number" and a.lastSeen > 0 and U.Date(a.lastSeen) or "nicht erfasst"),
        "Zuletzt erfasstes Gold: " .. U.Money(a.money),
    }
    if not journal then
        rows[#rows + 1] = "Weitere Daten werden beim naechsten Login dieses Charakters erfasst."
        return table.concat(rows, "\n")
    end
    local goals, quests, professions = {}, {}, {}
    for _, goal in ipairs(journal.goals or {}) do
        if not goal.done and #goals < 12 then goals[#goals + 1] = "[ ] " .. U.SafeText(goal.text) end
    end
    for _, quest in pairs(journal.activeQuests or {}) do
        quests[#quests + 1] = (quest.level and "[" .. quest.level .. "] " or "") .. U.SafeText(quest.title)
    end
    table.sort(quests)
    for name, profession in pairs(journal.professions or {}) do
        professions[#professions + 1] = name .. ": " .. tostring(profession.rank or 0) .. "/" .. tostring(profession.maxRank or 0)
    end
    table.sort(professions)
    rows[#rows + 1] = "\n" .. header("Aktive Quests (" .. #quests .. ")") ..
        (#quests > 0 and table.concat(quests, "\n", 1, math.min(#quests, 30)) or empty("Keine Quests erfasst."))
    rows[#rows + 1] = "\n" .. header("Offene Ziele") .. (#goals > 0 and table.concat(goals, "\n") or empty("Keine offenen Ziele."))
    rows[#rows + 1] = "\n" .. header("Berufe") ..
        (#professions > 0 and table.concat(professions, "\n") or empty("Noch keine Berufe erfasst."))
    if talent and type(talent.learned) == "table" and #talent.learned > 0 then
        local learned = {}
        for i, entry in ipairs(talent.learned) do
            if i > 40 then break end
            learned[#learned + 1] = U.SafeText(entry.name) .. "  " .. tostring(entry.rank or 1)
        end
        rows[#rows + 1] = "\n" .. header("Erfasste Talente (" .. #talent.learned .. ")") .. table.concat(learned, "\n")
    end
    rows[#rows + 1] = "\n" .. header("Inventar & Bank") ..
        "Inventar: " .. U.Count(journal.inventory) .. " Gegenstaende  |  Bank: " .. U.Count(journal.bank) .. " Gegenstaende" ..
        "\nNotizen: " .. #(journal.notes or {}) .. "  |  Tode: " .. #(journal.deaths or {})
    rows[#rows + 1] = "\n" .. header("Letzte Erinnerungen") ..
        recent(journal.events, function(event) return line(U.Date(event.time, true), "d7ae45") .. "  " .. U.SafeText(event.text) end, 10)
    return table.concat(rows, "\n")
end

showAltDetail = function(key)
    local character = C.db.characters[key]
    if type(character) ~= "table" then return end
    local journal = C.db.characterData and C.db.characterData[key]
    if type(journal) ~= "table" and key == C.characterKey then journal = C.char end
    local talent = type(character.talents) == "table" and character.talents or nil
    local width = availableContentWidth()
    local tabWidth = math.floor((width - 36) / 4)
    local twoWidth = math.floor((width - 10) / 2)
    local threeWidth = math.floor((width - 22) / 3)
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[character.class]
    local cr, cg, cb = classColor and classColor.r or 1, classColor and classColor.g or .72,
        classColor and classColor.b or .22
    body:Hide()
    if not detailHero then
        detailHero = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        detailHero:SetSize(630, 248); detailHero:SetPoint("TOPLEFT", 4, 0)
        heroBackdrop(detailHero)
        detailHero.band = detailHero:CreateTexture(nil, "BACKGROUND")
        detailHero.band:SetTexture(BACKGROUND)
        detailHero.band:SetPoint("TOPLEFT", 4, -4); detailHero.band:SetPoint("TOPRIGHT", -4, -4)
        detailHero.band:SetHeight(94)
        detailHero.accent = detailHero:CreateTexture(nil, "ARTWORK"); detailHero.accent:Hide()
        detailHero.accent:SetTexture(BACKGROUND)
        detailHero.accent:SetPoint("TOPLEFT", 4, -4)
        detailHero.accent:SetPoint("BOTTOMLEFT", 4, 4); detailHero.accent:SetWidth(4)
        detailHero.portrait = CreateFrame("Frame", nil, detailHero, "BackdropTemplate")
        detailHero.portrait:SetSize(188, 216)
        detailHero.portrait:SetPoint("TOPRIGHT", -15, -16)
        backdrop(detailHero.portrait, .045, .031, .021, 1)
        detailHero.portrait.sigil = detailHero.portrait:CreateTexture(nil, "ARTWORK")
        detailHero.portrait.sigil:SetSize(100, 100)
        detailHero.portrait.sigil:SetPoint("CENTER", 0, 8)
        detailHero.portrait.caption = detailHero.portrait:CreateFontString(nil, "OVERLAY")
        detailHero.portrait.caption:SetPoint("BOTTOM", 0, 9)
        setFont(detailHero.portrait.caption, 9, MUTED)
        local modelOK, model = pcall(CreateFrame, "PlayerModel", nil, detailHero.portrait)
        if modelOK and model then
            detailHero.portrait.model = model
            model:SetPoint("TOPLEFT", 3, -3)
            model:SetPoint("BOTTOMRIGHT", -3, 3)
        end
        local function heroText(name, x, y, width, size, color)
            local fs = detailHero:CreateFontString(nil, "OVERLAY")
            fs:SetPoint("TOPLEFT", x, -y); fs:SetWidth(width); fs:SetJustifyH("LEFT")
            setFont(fs, size, color); detailHero[name] = fs
        end
        heroText("chapter", 19, 13, 390, 10, GOLD)
        heroText("name", 19, 36, 390, 24, GOLD)
        heroText("identity", 20, 70, 430, 11, TEXT)
        heroText("realm", 450, 15, 160, 10, MUTED)
        detailHero.realm:SetJustifyH("RIGHT")
        detailHero.rule = detailHero:CreateTexture(nil, "ARTWORK")
        detailHero.rule:SetTexture(BACKGROUND)
        detailHero.rule:SetVertexColor(.57, .39, .16, .8)
        detailHero.rule:SetPoint("TOPLEFT", 19, -99)
        detailHero.rule:SetHeight(1)
        heroText("guild", 20, 113, 390, 12, TEXT)
        heroText("location", 20, 137, 390, 11, MUTED)
        heroText("seen", 20, 159, 390, 10, MUTED)
        heroText("spec", 20, 185, 390, 12, GOLD)
        heroText("money", 20, 213, 390, 12, GOLD)
        heroText("branches", 20, 235, 390, 11, TEXT)
        detailHero.bars = {}
        for index = 1, 3 do
            local track = detailHero:CreateTexture(nil, "ARTWORK")
            track:SetTexture(BACKGROUND); track:SetSize(190, 7)
            track:SetPoint("TOPLEFT", 16 + (index - 1) * 145, -201)
            track:SetVertexColor(.27, .22, .15, .95)
            local fill = detailHero:CreateTexture(nil, "OVERLAY")
            fill:SetTexture(BACKGROUND); fill:SetSize(1, 7)
            fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
            detailHero.bars[index] = { track = track, fill = fill }
        end
    end
    detailHero.band:SetVertexColor(cr, cg, cb, .18)
    detailHero:SetWidth(width)
    detailHero.accent:SetVertexColor(cr, cg, cb, 1)
    detailHero.rule:SetWidth(width - 225)
    detailHero.portrait:ClearAllPoints()
    detailHero.portrait:SetPoint("TOPRIGHT", -15, -16)
    detailHero.portrait:SetBackdropColor(.045, .031, .021, 1)
    detailHero.portrait:SetBackdropBorderColor(.57, .39, .16, 1)
    detailHero.portrait.sigil:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    local portraitCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[character.class]
    if portraitCoords then detailHero.portrait.sigil:SetTexCoord(unpack(portraitCoords)) end
    detailHero.portrait.sigil:SetVertexColor(cr, cg, cb, .7)
    local livePortrait = key == C.characterKey and UnitExists("player")
    if detailHero.portrait.model then
        detailHero.portrait.model:SetShown(livePortrait)
        if livePortrait and detailHero.portrait.model.SetUnit then
            pcall(detailHero.portrait.model.SetUnit, detailHero.portrait.model, "player")
            if detailHero.portrait.model.SetPortraitZoom then
                pcall(detailHero.portrait.model.SetPortraitZoom, detailHero.portrait.model, .84)
            end
            if detailHero.portrait.model.SetFacing then
                pcall(detailHero.portrait.model.SetFacing, detailHero.portrait.model, .3)
            end
        end
    end
    detailHero.portrait.sigil:SetShown(not livePortrait)
        detailHero.portrait.caption:SetText(livePortrait and C:LocalizeDisplay("DEIN CHARAKTER") or C:LocalizeDisplay("DEINE KLASSE"))
    detailHero.chapter:SetText(C:LocalizeDisplay("CHRONICLE  /  CHARAKTERPORTRÄT"))
    detailHero.name:SetText(C:CharacterDisplayName(character, key) ..
        (key == C.characterKey and C:LocalizeDisplay("  |cffffd119(aktuell)|r") or ""))
    detailHero.name:SetWidth(width - 240)
    detailHero.name:SetTextColor(unpack(GOLD))
    detailHero.identity:SetWidth(width - 240)
    detailHero.identity:SetText(C:LocalizeDisplay("Stufe ") .. tostring(character.level or 0) .. " " ..
        C:LocalizeDisplay(U.SafeText(character.raceName, "")) .. " " ..
        C:LocalizeDisplay(U.SafeText(character.className, character.class)) ..
        "  |  " .. C:LocalizeDisplay(U.SafeText(character.faction, "")))
    detailHero.realm:SetText(U.SafeText(character.realm, ""))
    detailHero.realm:Hide()
    detailHero.guild:SetText(C:LocalizeDisplay("Gilde: ") .. U.SafeText(character.guild, C:LocalizeDisplay("nicht erfasst")) ..
        (character.guildRank and character.guildRank ~= "" and "  |  " .. character.guildRank or ""))
    detailHero.location:SetText(C:LocalizeDisplay("Ort: ") .. U.SafeText(character.zone))
    detailHero.money:ClearAllPoints(); detailHero.money:SetPoint("TOPLEFT", 20, -213)
    detailHero.money:SetWidth(width - 240)
    detailHero.money:SetJustifyH("LEFT")
    detailHero.money:SetText(C:LocalizeDisplay("Gold: ") .. U.Money(character.money))
    detailHero.location:SetWidth(width - 240)
    detailHero.guild:SetWidth(width - 240); detailHero.seen:SetWidth(width - 240)
    detailHero.spec:SetWidth(width - 240); detailHero.branches:SetWidth(width - 240)
    detailHero.seen:SetText(C:LocalizeDisplay("Zuletzt gesehen: ") ..
        (type(character.lastSeen) == "number" and character.lastSeen > 0 and U.Date(character.lastSeen) or C:LocalizeDisplay("nicht erfasst")))
    detailHero.spec:SetText(C:LocalizeDisplay("Skillung: ") .. talentLabel(character))
    detailHero.branches:SetText("")
    local branches = talent and talent.branches
    local totalPoints = talent and tonumber(talent.totalPoints) or 0
    for index, bar in ipairs(detailHero.bars) do
        local branchWidth = (width - 216) / 3
        bar.track:ClearAllPoints()
        bar.track:SetPoint("TOPLEFT", 16 + (index - 1) * (branchWidth + 16), -201)
        bar.track:SetWidth(branchWidth)
        local points = type(branches) == "table" and branches[index] and tonumber(branches[index].points) or nil
        bar.track:Hide()
        bar.fill:Hide()
        if points and points > 0 then
            bar.fill:SetWidth(branchWidth * math.min(1, points / math.max(totalPoints, 1)))
            bar.fill:SetVertexColor(cr, cg, cb, 1)
        end
    end
    detailHero:Show()

    local tabs = {
        { key = "profile", label = "Profil" }, { key = "quests", label = "Quests" },
        { key = "collection", label = "Sammlung" }, { key = "chronicle", label = "Chronik" },
    }
    for index, tab in ipairs(tabs) do
        local button = detailTabs[index]
        if not button then
            button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(button)
            button:SetSize(145, 29)
            button:SetPoint("TOPLEFT", 4 + (index - 1) * 157, -260)
            button.label = button:CreateFontString(nil, "OVERLAY")
            button.label:SetPoint("CENTER"); setFont(button.label, 11, TEXT)
            button:SetScript("OnClick", function(self)
                selectedDetailTab = self.tabKey
                C:ShowPage("alts")
            end)
            detailTabs[index] = button
        end
        button.tabKey = tab.key
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 4 + (index - 1) * (tabWidth + 12), -260)
        button:SetWidth(tabWidth)
        button.label:SetText(C:LocalizeDisplay(tab.label))
        local active = selectedDetailTab == tab.key
        backdrop(button, active and .26 or .075, active and .17 or .057, active and .065 or .037, 1)
        button.label:SetTextColor(unpack(active and GOLD or TEXT))
        button:Show()
    end

    local offset, headerUsed, cardUsed, memoryUsed = 303, 0, 0, 0
    local function section(title, extra)
        headerUsed = headerUsed + 1
        local frame = detailHeaders[headerUsed]
        if not frame then
            frame = CreateFrame("Frame", nil, scrollChild)
            frame:SetSize(630, 32)
            frame.title = frame:CreateFontString(nil, "OVERLAY")
            frame.title:SetPoint("TOPLEFT", 9, -2); setFont(frame.title, 15, GOLD)
            frame.extra = frame:CreateFontString(nil, "OVERLAY")
            frame.extra:SetPoint("TOPRIGHT", -10, -7); frame.extra:SetWidth(300)
            frame.extra:SetJustifyH("RIGHT"); setFont(frame.extra, 10, MUTED)
            frame.rule = frame:CreateTexture(nil, "ARTWORK")
            frame.rule:SetTexture(BACKGROUND); frame.rule:SetVertexColor(.45, .32, .12, .9)
            frame.rule:SetPoint("BOTTOMLEFT", 8, 3)
            frame.rule:SetPoint("BOTTOMRIGHT", -8, 3); frame.rule:SetHeight(1)
            detailHeaders[headerUsed] = frame
        end
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", 4, -offset)
        frame:SetWidth(width)
        frame.title:SetText(C:LocalizeDisplay(title)); frame.extra:SetText(C:LocalizeDisplay(extra or "")); frame:Show()
        offset = offset + 38
    end
    local function card(text, x, y, width, height, r, g, b)
        cardUsed = cardUsed + 1
        local frame = detailCards[cardUsed]
        if not frame then
            frame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            frame.accent = frame:CreateTexture(nil, "ARTWORK"); frame.accent:Hide()
            frame.accent:SetTexture(BACKGROUND)
            frame.accent:SetPoint("BOTTOMLEFT", 9, 1)
            frame.accent:SetPoint("BOTTOMRIGHT", -9, 1); frame.accent:SetHeight(1)
            frame.label = frame:CreateFontString(nil, "OVERLAY")
            frame.label:SetPoint("TOPLEFT", 12, -10)
            frame.label:SetJustifyH("LEFT"); frame.label:SetJustifyV("TOP")
            setFont(frame.label, 11, TEXT)
            detailCards[cardUsed] = frame
        end
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", x, -y)
        frame:SetSize(width, height)
        frame.label:ClearAllPoints()
        frame.label:SetPoint("TOPLEFT", 12, -10)
        frame.label:SetWidth(width - 24)
        frame.label:SetText(C:LocalizeDisplay(text))
        if frame.caption then frame.caption:Hide() end
        if frame.rank then frame.rank:Hide() end
        if frame.badge then frame.badge:Hide() end
        if frame.progress then frame.progress:Hide() end
        setFont(frame.label, 12, TEXT)
        frame.label:SetTextColor(unpack(TEXT))
        frame.accent:SetVertexColor(.38, .27, .12, .8)
        frame.accent:Show()
        frame:SetBackdrop(nil)
        frame:Show()
        return frame
    end
    local questRows, goals, professions = {}, {}, {}
    if journal then
        for _, quest in pairs(journal.activeQuests or {}) do questRows[#questRows + 1] = quest end
        table.sort(questRows, function(a, b)
            local al, bl = tonumber(a.level) or 0, tonumber(b.level) or 0
            if al ~= bl then return al < bl end
            return tostring(a.title or "") < tostring(b.title or "")
        end)
        for _, goal in ipairs(journal.goals or {}) do if not goal.done then goals[#goals + 1] = goal end end
        for name, value in pairs(journal.professions or {}) do
            professions[#professions + 1] = { name = name, value = value }
        end
        table.sort(professions, function(a, b) return a.name < b.name end)
    end
    if selectedDetailTab == "profile" then
        section("Nachname", "Für diesen Charakter eintragen")
        if not detailHero.surnameEditor then
            detailHero.surnameEditor = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            detailHero.surnameEditor:SetSize(250, 27)
            detailHero.surnameEditor:SetAutoFocus(false)
            detailHero.surnameEditor:SetMaxLetters(40)
            detailHero.surnameEditor:SetScript("OnEscapePressed", function(self)
                local entry = C.db.characters[self.characterKey]
                self:SetText(entry and U.Trim(entry.surname) or "")
                self:ClearFocus()
            end)
            detailHero.surnameSave = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            C:StyleChronicleButton(detailHero.surnameSave)
            detailHero.surnameSave:SetSize(100, 25)
            detailHero.surnameSave:SetText(C:LocalizeDisplay("Speichern"))
            local function saveSurname()
                local entry = C.db.characters[detailHero.surnameEditor.characterKey]
                if not entry then return end
                entry.surname = U.Trim(detailHero.surnameEditor:GetText()):gsub("[%c|]", "")
                detailHero.surnameEditor:ClearFocus()
                C:ShowPage("alts")
            end
            detailHero.surnameEditor:SetScript("OnEnterPressed", saveSurname)
            detailHero.surnameSave:SetScript("OnClick", saveSurname)
        end
        detailHero.surnameEditor.characterKey = key
        detailHero.surnameEditor:ClearAllPoints()
        detailHero.surnameEditor:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 16, -offset - 1)
        detailHero.surnameEditor:SetText(U.Trim(character.surname))
        detailHero.surnameEditor:Show()
        detailHero.surnameSave:ClearAllPoints()
        detailHero.surnameSave:SetPoint("LEFT", detailHero.surnameEditor, "RIGHT", 12, 0)
        detailHero.surnameSave:SetText(C:LocalizeDisplay("Speichern"))
        detailHero.surnameSave:Show()
        offset = offset + 45
        section("Dein Charakter", "Auf einen Blick")
        local numbers = {
            { "AKTIVE QUESTS", #questRows }, { "OFFENE ZIELE", #goals },
            { "NOTIZEN", journal and #(journal.notes or {}) or 0 },
        }
        for index, stat in ipairs(numbers) do
            local metric = card(tostring(stat[2]),
                4 + (index - 1) * (threeWidth + 11), offset, threeWidth, 66)
            metric.label:ClearAllPoints()
            metric.label:SetPoint("TOPLEFT", 12, -5)
            setFont(metric.label, 25, GOLD)
            if not metric.caption then
                metric.caption = metric:CreateFontString(nil, "OVERLAY")
                metric.caption:SetPoint("TOPLEFT", 13, -42)
                setFont(metric.caption, 10, MUTED)
            end
            metric.caption:SetText(C:LocalizeDisplay(stat[1])); metric.caption:Show()
        end
        offset = offset + 78
        section("Erlernte Talente", talent and talent.learned and #talent.learned .. C:LocalizeDisplay(" erfasst") or "")
        local learned = talent and type(talent.learned) == "table" and talent.learned or {}
        if #learned == 0 then
            card("Noch keine Talente erfasst.", 4, offset, width, 42)
            offset = offset + 54
        else
            for index, row in ipairs(learned) do
                local talentRow = card(U.SafeText(row.name),
                    4 + ((index - 1) % 2) * (twoWidth + 10), offset + math.floor((index - 1) / 2) * 50,
                    twoWidth, 43)
                talentRow.label:ClearAllPoints()
                talentRow.label:SetPoint("TOPLEFT", 12, -11)
                talentRow.label:SetWidth(twoWidth - 90)
                if not talentRow.rank then
                    talentRow.rank = talentRow:CreateFontString(nil, "OVERLAY")
                    talentRow.rank:SetPoint("TOPRIGHT", -12, -11)
                    talentRow.rank:SetJustifyH("RIGHT")
                    setFont(talentRow.rank, 11, GOLD)
                end
                talentRow.rank:SetText(C:LocalizeDisplay("RANG ") .. tostring(row.rank or 1))
                talentRow.rank:Show()
            end
            offset = offset + math.ceil(#learned / 2) * 50 + 8
        end
        section("Letzte Erinnerung")
        local memory = journal and journal.events and journal.events[1]
        card(memory and ("|cffffd119" .. U.Date(memory.time, true) .. "|r  " .. C:LocalizeEventText(U.SafeText(memory.text))) or
            "Noch keine Erinnerung erfasst.", 4, offset, width, 52)
        offset = offset + 64
    elseif selectedDetailTab == "quests" then
        section("Aktive Quests", #questRows .. C:LocalizeDisplay(" im Questlog"))
        if #questRows == 0 then
            card("Keine aktiven Quests erfasst.", 4, offset, width, 43)
            offset = offset + 53
        else
            for index, quest in ipairs(questRows) do
                local questRow = card(U.SafeText(quest.title, "Quest #" .. tostring(quest.id or "?")),
                    4 + ((index - 1) % 2) * (twoWidth + 10),
                    offset + math.floor((index - 1) / 2) * 53, twoWidth, 46)
                if not questRow.badge then
                    questRow.badge = questRow:CreateFontString(nil, "OVERLAY")
                    questRow.badge:SetPoint("TOPLEFT", 12, -10)
                    setFont(questRow.badge, 16, GOLD)
                end
                questRow.badge:SetText(quest.level and tostring(quest.level) or "—")
                questRow.badge:Show()
                questRow.label:ClearAllPoints()
                questRow.label:SetPoint("TOPLEFT", 52, -13)
                questRow.label:SetWidth(twoWidth - 68)
            end
            offset = offset + math.ceil(#questRows / 2) * 53 + 8
        end
        section("Offene Ziele", #goals .. C:LocalizeDisplay(" geplant"))
        if #goals == 0 then
            card("Noch keine offenen Ziele.", 4, offset, width, 43)
            offset = offset + 53
        else
            for index, goal in ipairs(goals) do
                card("|cffffd119[ ]|r  " .. U.SafeText(goal.text), 4,
                    offset + (index - 1) * 53, width, 46)
            end
            offset = offset + #goals * 53 + 8
        end
    elseif selectedDetailTab == "collection" then
        section("Berufe", #professions .. C:LocalizeDisplay(" erfasst"))
        if #professions == 0 then
            card("Noch keine Berufe erfasst.", 4, offset, width, 43)
            offset = offset + 53
        else
            for index, profession in ipairs(professions) do
                local professionRow = card(U.SafeText(profession.name),
                    4 + ((index - 1) % 2) * (twoWidth + 10),
                    offset + math.floor((index - 1) / 2) * 53, twoWidth, 46)
                professionRow.label:SetWidth(twoWidth - 115)
                if not professionRow.rank then
                    professionRow.rank = professionRow:CreateFontString(nil, "OVERLAY")
                    professionRow.rank:SetPoint("TOPRIGHT", -12, -10)
                    professionRow.rank:SetJustifyH("RIGHT")
                    setFont(professionRow.rank, 11, GOLD)
                end
                local current, maximum = tonumber(profession.value.rank) or 0,
                    tonumber(profession.value.maxRank) or 0
                professionRow.rank:SetText(current .. " / " .. maximum)
                professionRow.rank:Show()
                if not professionRow.progress then
                    professionRow.progress = professionRow:CreateTexture(nil, "ARTWORK")
                    professionRow.progress:SetTexture(BACKGROUND)
                    professionRow.progress:SetPoint("BOTTOMLEFT", 9, 1)
                    professionRow.progress:SetHeight(2)
                end
                professionRow.progress:SetWidth(math.max(1, (twoWidth - 18) * math.min(1, current / math.max(1, maximum))))
                professionRow.progress:SetVertexColor(.88, .62, .18, 1)
                professionRow.progress:Show()
            end
            offset = offset + math.ceil(#professions / 2) * 53 + 8
        end
        section("Besitz & Aufzeichnungen")
        local inventoryCount = journal and U.Count(journal.inventory) or 0
        local bankCount = journal and U.Count(journal.bank) or 0
        for index, metricData in ipairs({
            { inventoryCount, "INVENTAR" }, { bankCount, "BANK" },
            { journal and #(journal.deaths or {}) or 0, "TODE" },
        }) do
            local metric = card(tostring(metricData[1]), 4 + (index - 1) * (threeWidth + 11),
                offset, threeWidth, 66)
            metric.label:ClearAllPoints()
            metric.label:SetPoint("TOPLEFT", 12, -5)
            setFont(metric.label, 25, GOLD)
            if not metric.caption then
                metric.caption = metric:CreateFontString(nil, "OVERLAY")
                metric.caption:SetPoint("TOPLEFT", 13, -42)
                setFont(metric.caption, 10, MUTED)
            end
            metric.caption:SetText(C:LocalizeDisplay(metricData[2])); metric.caption:Show()
        end
        offset = offset + 78
    elseif selectedDetailTab == "chronicle" then
        local events = journal and journal.events or {}
        section("Deine Geschichte", math.min(#events, 50) .. C:LocalizeDisplay(" von ") .. #events .. C:LocalizeDisplay(" Erinnerungen"))
        if #events == 0 then
            card("Deine Geschichte beginnt mit der nächsten erfassten Erinnerung.", 4, offset, width, 46)
            offset = offset + 58
        else
            local lastDay
            for index = 1, math.min(#events, 50) do
                local event = events[index]
                local eventTime = tonumber(event.time) or time()
                local day = date("%d.%m.%Y", eventTime)
                if day ~= lastDay then
                    section(day, index == 1 and "Die jüngsten Kapitel deiner Reise" or "")
                    lastDay = day
                end
                memoryUsed = memoryUsed + 1
                local memory = detailCards.memories[memoryUsed]
                if not memory then
                    memory = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                    memory:SetHeight(58)
                    memory.rail = memory:CreateTexture(nil, "ARTWORK")
                    memory.rail:SetTexture(BACKGROUND)
                    memory.rail:SetPoint("BOTTOMLEFT", 13, 0)
                    memory.rail:SetPoint("BOTTOMRIGHT", -13, 0)
                    memory.rail:SetHeight(1)
                    memory.icon = memory:CreateTexture(nil, "ARTWORK")
                    memory.icon:Hide()
                    memory.time = memory:CreateFontString(nil, "OVERLAY")
                    memory.time:SetPoint("TOPLEFT", 19, -7); setFont(memory.time, 10, MUTED)
                    memory.kind = memory:CreateFontString(nil, "OVERLAY")
                    memory.kind:SetPoint("TOPRIGHT", -19, -7)
                    memory.kind:SetJustifyH("RIGHT"); setFont(memory.kind, 10, GOLD)
                    memory.text = memory:CreateFontString(nil, "OVERLAY")
                    memory.text:SetPoint("TOPLEFT", 19, -27)
                    memory.text:SetJustifyH("LEFT"); setFont(memory.text, 12, TEXT)
                    detailCards.memories[memoryUsed] = memory
                end
                local category = timelineKinds[event.kind] or
                    { "Erinnerung", "other", "Interface\\Icons\\INV_Misc_Book_09", { .74, .66, .51 } }
                memory:ClearAllPoints(); memory:SetPoint("TOPLEFT", 4, -offset)
                memory:SetWidth(width)
                memory:SetBackdrop(nil)
                memory.rail:SetVertexColor(.38, .27, .12, .75)
                memory.time:SetText(date("%H:%M", eventTime))
                memory.kind:SetText(string.upper(C:LocalizeDisplay(category[1])))
                memory.kind:SetTextColor(unpack(category[4]))
                memory.text:SetText(C:LocalizeEventText(U.SafeText(event.text, C:LocalizeDisplay("Erinnerung"))))
                memory.text:SetWidth(width - 40)
                memory:Show()
                offset = offset + 62
            end
            offset = offset + 8
        end
    end
    for index = headerUsed + 1, #detailHeaders do detailHeaders[index]:Hide() end
    for index = cardUsed + 1, #detailCards do detailCards[index]:Hide() end
    for index = memoryUsed + 1, #detailCards.memories do detailCards.memories[index]:Hide() end
    scrollChild:SetHeight(math.max(1, offset + 12))
end

local renderers = {}
function renderers.overview()
    local c = C.char
    local sessionEnd = tonumber(c.lastSessionEnd) or 0
    if sessionEnd == 0 and tonumber(c.lastLogout) and tonumber(c.lastLogin) and
        c.lastLogout > 0 and c.lastLogout <= c.lastLogin then
        sessionEnd = c.lastLogout
    end
    local last = sessionEnd > 0 and U.Date(sessionEnd) or "nicht erfasst"
    local openGoals, nextSteps = 0, {}
    for _, goal in ipairs(c.goals) do
        if not goal.done then
            openGoals = openGoals + 1
            if #nextSteps < 3 then nextSteps[#nextSteps + 1] = "[ ] " .. U.SafeText(goal.text, "") end
        end
    end
    local memories = {}
    for _, event in ipairs(c.events) do
        local noise = event.text == "Gebiet entdeckt: Unbekannt" or
            event.text == "Berufe und Fertigkeiten aktualisiert" or
            event.text == "Abenteuer fortgesetzt in Unbekannt"
        if not noise then memories[#memories + 1] = event end
        if #memories >= 10 then break end
    end
    return header("Willkommen zurueck, " .. U.SafeText(UnitName("player"), "Abenteurer") .. "!") ..
        "Letzte Sitzung: " .. line(last) .. "\nLetzter Ort: " .. line(U.SafeText(c.lastZone)) ..
        (c.lastInstance ~= "" and "\nLetzte Instanz: " .. line(c.lastInstance) or "") ..
        "\nVermoegen: " .. line(U.Money(GetMoney and GetMoney() or c.money)) ..
        "\nOffene Ziele: " .. line(openGoals) .. "\n\n" .. header("Deine naechsten Schritte") ..
        (#nextSteps > 0 and table.concat(nextSteps, "\n") or empty("Noch keine persoenlichen Ziele gesetzt.")) ..
        (openGoals > #nextSteps and "\n" .. line("Weitere Ziele unter Ziele.", "9c9076") or "") ..
        "\n\n" .. header("Letzte Erinnerungen") ..
        recent(memories, function(e) return line(U.Date(e.time, true), "d7ae45") .. "  " .. e.text end, 10)
end
function renderers.goals()
    return recent(C.char.goals, function(g, i) return (g.done and "|cff65a765[Erledigt]|r " or "|cffffd119[Offen]|r ") .. i .. ". " .. g.text end, 100)
end
function renderers.timeline() return recent(C.char.events, function(e) return line(U.Date(e.time), "d7ae45") .. "  " .. line(e.kind, "a89b7e") .. "\n" .. e.text end, 100) end
function renderers.quests()
    local active = {}
    for _, quest in pairs(C.char.activeQuests or {}) do
        active[#active + 1] = (quest.level and ("[" .. quest.level .. "] ") or "") .. U.SafeText(quest.title, "Quest #" .. tostring(quest.id))
    end
    table.sort(active)
    local activeText = #active > 0 and table.concat(active, "\n") or empty("Keine aktiven Quests erfasst.")
    local history = recent(C.char.quests, function(q)
        local status = q.status == "accepted" and "Angenommen" or "Abgeschlossen"
        return line(U.Date(q.time, true), "d7ae45") .. "  " .. line(status, q.status == "accepted" and "ffcc67" or "65a765") .. "  " .. U.SafeText(q.title, "Quest #" .. tostring(q.id)) .. "\n" .. line(q.zone, "9c9076")
    end, 100)
    return header("Aktuelle Quests (" .. #active .. ")") .. activeText .. "\n\n" .. header("Quest-Historie") .. history
end
function renderers.zones()
    local rows = {}
    for _, row in ipairs(U.SortedPairsByTime(C.char.zones)) do
        if U.IsKnownZone(row.key) then
            local zone = row.value
            local first = zone.firstSeen and zone.firstSeen > 0 and U.Date(zone.firstSeen, true) or "nicht erfasst"
            local last = zone.lastSeen and zone.lastSeen > 0 and U.Date(zone.lastSeen, true) or "nicht erfasst"
            rows[#rows + 1] = header(row.key) .. "Besuche: " .. tostring(zone.visits or 1) ..
                "\nErstmals: " .. first .. "  |  Zuletzt: " .. last ..
                (zone.lastSubZone and zone.lastSubZone ~= "" and ("\nUntergebiet: " .. zone.lastSubZone) or "")
        end
    end
    return #rows > 0 and table.concat(rows, "\n\n") or empty()
end
function renderers.npcs()
    local merchants, others = {}, {}
    for _, row in ipairs(U.SortedPairsByTime(C.char.npcs)) do
        local n = row.value
        if U.IsWorldNPC(n) then
            local entry = header(row.key) .. U.SafeText(n.zone) .. "  |  Zuletzt: " .. U.Date(n.lastSeen, true) ..
                "  |  Begegnungen: " .. tostring(n.encounters or 1)
            if n.merchant then merchants[#merchants + 1] = entry else others[#others + 1] = entry end
        end
    end
    return header("Haendler (" .. #merchants .. ")") ..
        (#merchants > 0 and table.concat(merchants, "\n\n") or empty("Noch keinen Haendler besucht.")) ..
        "\n\n" .. header("Andere NPCs (" .. #others .. ")") ..
        (#others > 0 and table.concat(others, "\n\n") or empty("NPCs werden beim Anvisieren gespeichert."))
end
function renderers.dungeons()
    local instances, bosses = {}, {}
    for _, row in ipairs(U.SortedPairsByTime(C.char.dungeons)) do
        local dungeon = row.value
        instances[#instances + 1] = header(row.key) .. "Besuche: " .. tostring(dungeon.entries or 0) ..
            (dungeon.difficulty and dungeon.difficulty ~= "" and "  |  " .. dungeon.difficulty or "") ..
            "\nZuletzt: " .. (dungeon.lastSeen and U.Date(dungeon.lastSeen, true) or "nicht erfasst")
    end
    for _, row in ipairs(U.SortedPairsByTime(C.char.bosses)) do
        local boss = row.value
        bosses[#bosses + 1] = header(U.SafeText(boss.name, "Boss #" .. tostring(row.key))) ..
            "Siege: " .. tostring(boss.kills or 0) .. "  |  Versuche: " .. tostring(boss.attempts or 0) ..
            (boss.zone and boss.zone ~= "" and "\nOrt: " .. boss.zone or "") ..
            "\nZuletzt: " .. (boss.lastSeen and U.Date(boss.lastSeen, true) or "nicht erfasst")
    end
    return header("Instanzen") .. (#instances > 0 and table.concat(instances, "\n\n") or empty("Noch keine Instanz besucht.")) ..
        "\n\n" .. header("Bosse") .. (#bosses > 0 and table.concat(bosses, "\n\n") or empty("Noch kein Bosskampf erfasst."))
end
function renderers.loot()
    local rows = { header("Beute – Questgegenstaende und Gruen+") }
    local visibleLoot = {}
    for _, entry in ipairs(C.char.loot) do if U.LootVisible(entry) then visibleLoot[#visibleLoot + 1] = entry end end
    local lootText = recent(visibleLoot, function(l) return line(U.Date(l.time, true), "d7ae45") .. "  " .. U.SafeText(l.link, l.name) .. " x" .. (l.quantity or 1) .. "\n" .. line(l.zone, "9c9076") end, 100)
    rows[#rows + 1] = lootText; rows[#rows + 1] = "\n" .. header("Rare Journal")
    local rareRows = {}; for _, row in ipairs(U.SortedPairsByTime(C.char.rares)) do
        local rare = row.value
        rareRows[#rareRows + 1] = header(row.key) .. U.SafeText(rare.zone) ..
            "  |  Sichtungen: " .. tostring(rare.sightings or 1) ..
            "\nErstmals: " .. U.Date(rare.firstSeen, true) .. "  |  Zuletzt: " .. U.Date(rare.lastSeen, true)
    end
    rows[#rows + 1] = #rareRows > 0 and table.concat(rareRows, "\n") or empty("Noch keine seltene Kreatur gesehen.")
    return table.concat(rows, "\n")
end
function renderers.professions()
    local rows = { header("Berufe") }
    local professionNames = {}
    for name in pairs(C.char.professions) do professionNames[#professionNames + 1] = name end
    table.sort(professionNames)
    for _, name in ipairs(professionNames) do
        local p = C.char.professions[name]
        rows[#rows + 1] = name .. ": " .. tostring(p.rank or 0) .. "/" .. tostring(p.maxRank or 0)
    end
    if #professionNames == 0 then rows[#rows + 1] = empty("Noch keine Berufe erkannt.") end
    rows[#rows + 1] = "\n" .. header("Erfasste Rezepte")
    local recipeProfessions = {}
    for name in pairs(C.char.recipes) do recipeProfessions[#recipeProfessions + 1] = name end
    table.sort(recipeProfessions)
    for _, name in ipairs(recipeProfessions) do
        local recipes = {}
        for _, recipe in pairs(C.char.recipes[name]) do recipes[#recipes + 1] = U.SafeText(recipe.name, "Rezept #" .. tostring(recipe.id)) end
        table.sort(recipes)
        rows[#rows + 1] = header(name .. " (" .. #recipes .. ")")
        for i = 1, math.min(#recipes, 100) do rows[#rows + 1] = recipes[i] end
        if #recipes > 100 then rows[#rows + 1] = line("Weitere Rezepte über die Suche finden.", "9c9076") end
    end
    if #recipeProfessions == 0 then rows[#rows + 1] = empty("Berufsfenster öffnen, um gelernte Rezepte zu erfassen.") end
    rows[#rows + 1] = "\nLetzte Berufsaenderung: " .. (C.char.stats.lastSkillUpdate and U.Date(C.char.stats.lastSkillUpdate) or "noch keine")
    return table.concat(rows, "\n")
end
function renderers.inventory()
    local function list(snapshot, updated)
        local rows, total = {}, 0
        for _, item in pairs(snapshot or {}) do
            local count = tonumber(item.count) or 0
            total = total + count
            rows[#rows + 1] = U.SafeText(item.link, "Gegenstand #" .. tostring(item.id or "?")) .. " x" .. count
        end
        table.sort(rows)
        local summary = "Verschiedene Gegenstaende: " .. #rows .. "  |  Stueckzahl: " .. total ..
            "\nStand: " .. (updated and U.Date(updated) or "noch nicht erfasst")
        return summary .. "\n" .. (#rows > 0 and table.concat(rows, "\n") or empty())
    end
    return header("Letzter Inventarstand") .. list(C.char.inventory, C.char.stats.inventoryUpdated) ..
        "\n\n" .. header("Letzter Bankstand") .. list(C.char.bank, C.char.stats.bankUpdated)
end
function renderers.economy()
    local balance = GetMoney and GetMoney() or C.char.money
    local history, hidden, shown, lastDay = {}, 0, 0, nil
    for _, entry in ipairs(C.char.economy or {}) do
        if U.IsLogoutMoneyGlitch(C.char, entry) and not C.showSuspiciousMoney then
            hidden = hidden + 1
        elseif shown < 100 then
            shown = shown + 1
            local day = date("%d.%m.%Y", entry.time or time())
            if day ~= lastDay then history[#history + 1] = header(day); lastDay = day end
            local delta = tonumber(entry.delta) or 0
            local kind = delta >= 0 and "Einnahme" or "Ausgabe"
            local kindColor = delta >= 0 and "75c58a" or "e18076"
            history[#history + 1] = line(U.Date(entry.time, true), "d7ae45") .. "   " ..
                line(kind, kindColor) .. "  " .. (delta >= 0 and "+" or "") .. U.Money(delta) ..
                "  |  Stand: " .. U.Money(entry.balance) .. "\n" .. line(U.SafeText(entry.zone, ""), "9c9076")
        end
    end
    return header("Aktuelles Vermoegen") .. U.Money(balance) .. "\n\n" ..
        header("Geldverlauf") ..
        (hidden > 0 and line(hidden .. " fehlerhafte Abmeldewerte ausgeblendet.", "9c9076") .. "\n" or "") ..
        (#history > 0 and ("\n" .. table.concat(history, "\n\n")) or empty("Noch keine Goldaenderung erfasst."))
end
function renderers.deaths() return "" end
function renderers.notes()
    return recent(C.char.notes, function(n, i)
        return line(string.format("%02d  %s", i, U.SafeText(n.category, "Allgemein")), "ffcc67") ..
            "\n" .. line(U.SafeText(n.text, ""), "fff0d2") ..
            "\n" .. line(U.Date(n.updated or n.created), "b5a78a") ..
            "\n" .. line("________________________________________", "6b542a")
    end, 100)
end
function renderers.stats()
    local s = U.Statistics(C.char)
    return header("Deine Chronicle in Zahlen") ..
        header("Reise") .. "Chronik-Eintraege: " .. s.memories ..
        "\nEntdeckte Gebiete: " .. s.zones ..
        "\nVerschiedene Instanzen: " .. s.dungeons ..
        "\nInstanzbesuche: " .. s.dungeonVisits ..
        "\nTode: " .. s.deaths ..
        "\n\n" .. header("Quests & Plaene") .. "Aktuelle Quests: " .. s.activeQuests ..
        "\nQuest-Abschluesse: " .. s.questCompletions ..
        "\nOffene Ziele: " .. s.openGoals ..
        "\nErledigte Ziele: " .. s.completedGoals ..
        "\n\n" .. header("Begegnungen & Sammlung") .. "Bekannte NPCs: " .. s.npcs ..
        "\nDavon Haendler: " .. s.merchants ..
        "\nSeltene Kreaturen: " .. s.rares ..
        "\nVerschiedene Bosse: " .. s.bosses ..
        "\nBossversuche: " .. s.bossAttempts ..
        "\nBoss-Siege: " .. s.bossKills ..
        "\nSichtbare Beuteeintraege: " .. s.loot ..
        "\nBekannte Rezepte: " .. s.recipes ..
        "\nNotizen: " .. s.notes
end

local function showPage(key)
    if not C.char then C:BindCharacterDatabase() end
    if not C.char then C:Print(C:L("noCharacterData")); return end
    updateContentWidth()
    if key == "economy" and C.SyncMoney then C:SyncMoney(true, false) end
    local previousPage = selected
    local previousScroll = scroll:GetVerticalScroll()
    if key ~= "alts" then selectedAltKey = nil end
    selected = key; local info
    for _, page in ipairs(pages) do if page.key == key then info = page break end end
    pageTitle:SetText(info and C:L(info.key) or "Chronicle")
    local art = motifArt[key]
    pageMotif:SetTexture(art and ("Interface\\AddOns\\Chronicle\\Motif_" .. art) or nil)
    pageMotif:SetSize(key == "overview" and 280 or 330, key == "overview" and 280 or 330)
    pageMotif:SetAlpha(key == "overview" and .13 or (key == "alts" and .045 or .1))
    pageMotif:SetShown(art ~= nil and key ~= "deaths" and key ~= "economy" and
        key ~= "stats" and key ~= "inventory" and key ~= "training" and
        key ~= "teachers" and key ~= "weapons")
    if simpleEmpty then simpleEmpty:Hide() end
    if chapterHero then chapterHero:Hide() end
    -- Every navigation page below has a dedicated renderer; avoid building hidden text lists.
    local text = info and "" or (renderers[key] and renderers[key]() or empty())
    hideGoalRows(); hideNoteRows(); hideAltRows(); hideAltDetail(); hideInventoryRows(); hideEconomyRows(); hideStatsRows(); hideProfessionRows(); hideLootRows(); hideOverviewRows(); hideTimelineRows(); hideQuestRows(); hideZoneRows(); hideNPCRows(); hideDungeonRows(); hideDeathRows()
    if C.HideDiscoveries then C:HideDiscoveries() end
    if C.HideDungeonKnowledge then C:HideDungeonKnowledge() end
    if C.HideAttunements then C:HideAttunements() end
    input:Hide(); action:Hide(); cancelEdit:Hide()
    backButton:Hide(); body:Show()
    moneyToggle:SetShown(key == "economy")
    moneyToggle:SetText(C:L(C.showSuspiciousMoney and "hideZeros" or "showZeros"))
    body:SetText(text); scrollChild:SetHeight(math.max(1, body:GetStringHeight() + 12)); scroll:SetVerticalScroll(0)
    if key == "goals" then showGoalRows() end
    if key == "notes" then showNoteRows() end
    if key == "alts" then showAltRows() end
    if key == "inventory" then showInventoryRows() end
    if key == "economy" then showEconomyRows() end
    if key == "stats" then showStatsRows(); scroll:SetVerticalScroll(0) end
    if key == "professions" then showProfessionRows(); scroll:SetVerticalScroll(0) end
    if key == "loot" then showLootRows(); scroll:SetVerticalScroll(0) end
    if key == "overview" then showOverviewRows(); scroll:SetVerticalScroll(0) end
    if key == "timeline" then showTimelineRows(); scroll:SetVerticalScroll(0) end
    if key == "quests" then showQuestRows(); scroll:SetVerticalScroll(0) end
    if key == "zones" then showZoneRows(); scroll:SetVerticalScroll(0) end
    if key == "npcs" then showNPCRows(); scroll:SetVerticalScroll(0) end
    if key == "dungeons" then showDungeonRows(); scroll:SetVerticalScroll(0) end
    if key == "deaths" then showDeathRows(); scroll:SetVerticalScroll(0) end
    if (key == "dungeonknowledge" or key == "raidknowledge") and C.ShowDungeonKnowledge then
        C:ShowDungeonKnowledge(scrollChild, availableContentWidth(), key == "raidknowledge" and "raids" or "dungeons")
        scroll:SetVerticalScroll(0)
    end
    if key == "attunements" and C.ShowAttunements then
        C:ShowAttunements(scrollChild, availableContentWidth())
        scroll:SetVerticalScroll(0)
    end
    if (key == "gathering" or key == "training" or key == "teachers" or key == "weapons") and C.ShowDiscoveries then
        C:ShowDiscoveries(scrollChild, availableContentWidth(),
            key == "gathering" and "gather" or key == "training" and "training" or key)
        scroll:SetVerticalScroll(0)
    end
    input:Hide(); action:Hide(); cancelEdit:Hide()
    if previousPage ~= key then editingNote = nil end
    if key == "goals" then input:Show(); action:Show(); action:SetText(C:L("add")); if previousPage ~= key then input:SetText("") end
    elseif key == "notes" then input:Show(); action:Show(); action:SetText(C:L(editingNote and "change" or "save")); cancelEdit:SetShown(editingNote ~= nil); if previousPage ~= key then input:SetText("") end end
    for pageKey, button in pairs(buttons) do
        local active = pageKey == key
        button:SetEnabled(not active)
        button.selectedBackground:SetShown(active)
        button.selectedAccent:SetShown(active)
        for _, edge in ipairs(button.selectedEdges) do edge:SetShown(active) end
        button.label:SetTextColor(unpack(active and GOLD or TEXT))
    end
    local activeButton = buttons[key]
    if activeButton and activeButton.navOffset then
        local current = sidebar.scroll:GetVerticalScroll()
        local visibleHeight = sidebar.scroll:GetHeight()
        if activeButton.navOffset < current then sidebar.scroll:SetVerticalScroll(activeButton.navOffset)
        elseif activeButton.navOffset + 28 > current + visibleHeight then
            sidebar.scroll:SetVerticalScroll(activeButton.navOffset + 28 - visibleHeight)
        end
    end
    for pageKey, tab in pairs(quickTabs) do
        local active = pageKey == key
        tab.icon:SetAlpha(active and 1 or .9)
        tab.frame:SetVertexColor(active and 1 or .82, active and 1 or .82, active and 1 or .82, 1)
        tab.selected:SetShown(active)
    end
    if previousPage == key then
        scroll:SetVerticalScroll(math.min(previousScroll,
            math.max(0, scrollChild:GetHeight() - scroll:GetHeight())))
    end
end
backButton:SetScript("OnClick", function() selectedAltKey = nil; showPage("alts"); scroll:SetVerticalScroll(0) end)
moneyToggle:SetScript("OnClick", function()
    C.showSuspiciousMoney = not C.showSuspiciousMoney
    showPage("economy")
end)

local navY = 8
C.navSections = {}
for _, page in ipairs(pages) do
    if page.group then
        local section = sidebar.content:CreateFontString(nil, "OVERLAY")
        section:SetPoint("TOPLEFT", 16, -navY - 2)
        setFont(section, 10, MUTED)
        section:SetText(C:L(page.group == "REISE" and "journey" or page.group == "WISSEN" and "knowledge" or
            page.group == "SAMMLUNG" and "collection" or "characterGroup"))
        C.navSections[#C.navSections + 1] = { label = section, key = page.group == "REISE" and "journey" or
            page.group == "WISSEN" and "knowledge" or page.group == "SAMMLUNG" and "collection" or "characterGroup" }
        local rule = sidebar.content:CreateTexture(nil, "ARTWORK")
        rule:SetTexture(BACKGROUND); rule:SetVertexColor(.38, .28, .13, .75)
        rule:SetPoint("TOPLEFT", 91, -navY - 8); rule:SetPoint("TOPRIGHT", -12, -navY - 8); rule:SetHeight(1)
        navY = navY + 21
    end
    local button = CreateFrame("Button", nil, sidebar.content); button:SetSize(172, 28); button:SetPoint("TOPLEFT", 6, -navY)
    button.pageKey = page.key
    button.navOffset = navY
    button.selectedBackground = button:CreateTexture(nil, "BACKGROUND")
    button.selectedBackground:SetTexture(BACKGROUND)
    button.selectedBackground:SetVertexColor(.29, .19, .07, .94)
    button.selectedBackground:SetAllPoints(button)
    button.selectedBackground:Hide()
    button.selectedAccent = button:CreateTexture(nil, "ARTWORK")
    button.selectedAccent:SetTexture(BACKGROUND)
    button.selectedAccent:SetVertexColor(.92, .68, .23, 1)
    button.selectedAccent:SetPoint("TOPLEFT", 1, -3)
    button.selectedAccent:SetPoint("BOTTOMLEFT", 1, 3)
    button.selectedAccent:SetWidth(3)
    button.selectedAccent:Hide()
    button.selectedEdges = {}
    local function selectedEdge(firstPoint, secondPoint, width, height)
        local edge = button:CreateTexture(nil, "ARTWORK")
        edge:SetTexture(BACKGROUND); edge:SetVertexColor(.7, .49, .19, .9)
        edge:SetPoint(firstPoint, button, firstPoint, 1, firstPoint:find("TOP") and -1 or 1)
        edge:SetPoint(secondPoint, button, secondPoint, -1, secondPoint:find("TOP") and -1 or 1)
        if width then edge:SetWidth(width) end
        if height then edge:SetHeight(height) end
        edge:Hide(); button.selectedEdges[#button.selectedEdges + 1] = edge
    end
    selectedEdge("TOPLEFT", "TOPRIGHT", nil, 1)
    selectedEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button.label = button:CreateFontString(nil, "OVERLAY"); button.label:SetPoint("LEFT", 9, 0); setFont(button.label, 11, TEXT); button.label:SetText(C:L(page.key)); C:FitNavLabel(button.label)
    button:SetScript("OnClick", function(self) showPage(self.pageKey) end); buttons[button.pageKey] = button
    navY = navY + 29
end
sidebar.content:SetHeight(navY + 8)

for index, page in ipairs(pages) do
    local tab = CreateFrame("CheckButton", nil, window)
    tab:SetSize(36, 36)
    tab:SetFrameLevel(window:GetFrameLevel() + 25)
    tab.pageKey = page.key
    tab.tooltipLabel = C:L(page.key)
    tab.icon = tab:CreateTexture(nil, "ARTWORK")
    tab.icon:SetTexture(page.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    tab.icon:SetPoint("TOPLEFT", 1, -1); tab.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    tab.icon:SetTexCoord(.07, .93, .07, .93); tab.icon:SetAlpha(.9)
    tab.frame = tab:CreateTexture(nil, "BACKGROUND")
    tab.frame:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
    tab.frame:SetSize(72, 72); tab.frame:SetPoint("TOP", tab, "TOP", 14, 12)
    tab.frame:SetVertexColor(.82, .82, .82, 1)
    tab.selected = tab:CreateTexture(nil, "OVERLAY")
    tab.selected:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
    tab.selected:SetBlendMode("ADD"); tab.selected:SetVertexColor(1, .58, .02, .95)
    tab.selected:SetSize(72, 72); tab.selected:SetPoint("TOP", tab, "TOP", 14, 12); tab.selected:Hide()
    tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    tab:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:AddLine(self.tooltipLabel, 1, .82, .1)
        GameTooltip:AddLine(C:L("openSection"), .85, .79, .66)
        C:ShowLocalizedTooltip()
    end)
    tab:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(self.pageKey == selected and 1 or .9)
        GameTooltip:Hide()
    end)
    tab:SetScript("OnClick", function(self) showPage(self.pageKey) end)
    quickTabs[page.key] = tab
end

local function layoutQuickTabs()
    local count = #pages
    local size = 36
    local windowHeight = window:GetHeight() or 650
    local step = math.max(28, math.min(41, math.floor((windowHeight - 24 - size) / math.max(1, count - 1))))
    local totalHeight = size + (count - 1) * step
    local topInset = math.floor((windowHeight - totalHeight) / 2 + .5)
    for index, page in ipairs(pages) do
        local tab = quickTabs[page.key]
        tab:ClearAllPoints(); tab:SetSize(size, size)
        tab:SetPoint("TOPLEFT", window, "TOPRIGHT", -1, -topInset - (index - 1) * step)
        tab.icon:ClearAllPoints(); tab.icon:SetPoint("TOPLEFT", 1, -1); tab.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    end
end
layoutQuickTabs()
window:SetScript("OnSizeChanged", layoutQuickTabs)

local function submit()
    local value = input:GetText()
    if U.Trim(value) == "" then return end
    if selected == "goals" then C:AddGoal(value)
    elseif selected == "notes" then
        local note = editingNote
        editingNote = nil
        if note then C:UpdateNote(note, value) else C:AddNote(value) end
    end
    input:SetText(""); input:ClearFocus(); showPage(selected)
end
action:SetScript("OnClick", submit); input:SetScript("OnEnterPressed", submit); input:SetScript("OnEscapePressed", input.ClearFocus)
cancelEdit:SetScript("OnClick", function()
    editingNote = nil; input:SetText(""); input:ClearFocus()
    action:SetText(C:L("save")); cancelEdit:Hide()
end)
search:SetScript("OnEnterPressed", function(self)
    local results = C:Search(self:GetText()); selected = "search"; selectedAltKey = nil; pageTitle:SetText(C:L("searchPrefix") .. self:GetText())
    if simpleEmpty then simpleEmpty:Hide() end
    if chapterHero then chapterHero:Hide() end
    hideGoalRows(); hideNoteRows(); hideAltRows(); hideAltDetail(); hideInventoryRows(); hideEconomyRows(); hideStatsRows(); hideProfessionRows(); hideLootRows(); hideOverviewRows(); hideTimelineRows()
    if C.HideDiscoveries then C:HideDiscoveries() end
    backButton:Hide(); moneyToggle:Hide()
    editingNote = nil; cancelEdit:Hide(); body:Show()
    local rows = {}; for i, r in ipairs(results) do
        if i > 100 then break end
        local label = r.kind
        if type(r.time) == "number" and r.time > 0 then label = label .. " – " .. U.Date(r.time, true) end
        rows[#rows + 1] = header(label) .. r.title .. (r.detail ~= "" and "\n" .. line(r.detail, "9c9076") or "")
    end
    body:SetText(#rows > 0 and table.concat(rows, "\n\n") or empty(C:L("noResults"))); scrollChild:SetHeight(math.max(1, body:GetStringHeight() + 12)); input:Hide(); action:Hide(); self:ClearFocus()
    for _, button in pairs(buttons) do
        button:SetEnabled(true)
        button.selectedBackground:Hide()
        button.selectedAccent:Hide()
        for _, edge in ipairs(button.selectedEdges) do edge:Hide() end
        button.label:SetTextColor(unpack(TEXT))
    end
end)

function C:RefreshLanguage()
    subtitle:SetText("VERSION " .. self.version .. "  |  " .. self:L("subtitle"))
    searchHint:SetText(self:L("search"))
    backButton:SetText(self:L("back"))
    cancelEdit:SetText(self:L("cancel"))
    self.UpdateLanguageButton()
    for _, page in ipairs(pages) do
        if buttons[page.key] then
            buttons[page.key].label:SetText(self:L(page.key))
            self:FitNavLabel(buttons[page.key].label)
        end
        if quickTabs[page.key] then quickTabs[page.key].tooltipLabel = self:L(page.key) end
    end
    for _, section in ipairs(self.navSections) do section.label:SetText(self:L(section.key)) end
    self:Refresh()
end
function C:Refresh() if window:IsShown() then showPage(selected == "search" and "overview" or selected) end end
function C:Toggle() if window:IsShown() then window:Hide() else window:Show(); self:Refresh() end end
function C:ShowPage(key)
    if not window:IsShown() then window:Show() end
    showPage(key)
end
function C:ShowWelcome() end -- Zusammenfassung steht auf der Startseite; keine Popup-Flut.
C:On("DATA_CHANGED", function()
    if not window:IsShown() or C.refreshQueued then return end
    if not (C_Timer and C_Timer.After) then C:Refresh(); return end
    C.refreshQueued = true
    C_Timer.After(.05, function()
        C.refreshQueued = nil
        C:Refresh()
    end)
end)
C:On("DATABASE_READY", function()
    local settings = C.db and C.db.settings
    if not settings then return end
    local width = math.max(920, math.min(1500, tonumber(settings.windowWidth) or 960))
    local height = math.max(600, math.min(950, tonumber(settings.windowHeight) or 650))
    window:SetSize(width, height)
    C:RefreshLanguage()
end)

SLASH_CHRONICLE1, SLASH_CHRONICLE2 = "/chronicle", "/chr"
SlashCmdList.CHRONICLE = function(message)
    message = U.Trim(message)
    local command, value = message:match("^(%S+)%s*(.-)$")
    if command == "goal" and value ~= "" then C:AddGoal(value); C:Print("Ziel hinzugefuegt.")
    elseif command == "note" and value ~= "" then
        if C:AddNote(value) then C:Print("Notiz gespeichert.") else C:Print("Notiz konnte nicht gespeichert werden.") end
    elseif command == "notes" or command == "notizen" then C:ShowPage("notes")
    elseif command == "repair" then
        if C:BindCharacterDatabase() then C:Print("Charakterdaten neu gebunden: " .. tostring(C.characterKey)); C:ShowPage("notes")
        else C:Print("Charakterdaten konnten nicht gebunden werden.") end
    elseif command == "debug" then
        C:BindCharacterDatabase()
        local notes = C.char and C.char.notes or {}
        C:Print("Version " .. C.version .. ", gespeicherte Notizen: " .. tostring(#notes))
        C:Print("Datenschluessel: " .. tostring(C.characterKey or C:CharacterKey()))
        C:Print("Gespeicherte Charakterjournale: " .. tostring(C.db and U.Count(C.db.characterData) or 0))
        C:Print("Eigenstaendiger Notizspeicher: " .. tostring(ChronicleNotesDB and C.characterKey and ChronicleNotesDB[C.characterKey] and #ChronicleNotesDB[C.characterKey] or 0))
        if notes[1] then C:Print("Neueste Notiz: " .. tostring(notes[1].text)) end
    elseif command == "questdebug" then
        local questID = tonumber((C.questSelection or ""):match("^active:(%d+):"))
        if not questID then C:Print("Bitte zuerst eine aktive Quest im Questjournal auswählen."); return end
        local index, selection
        if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
            local ok, value = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
            if ok then index = value end
        end
        if not index and GetQuestLogIndexByID then
            local ok, value = pcall(GetQuestLogIndexByID, questID)
            if ok then index = value end
        end
        if GetQuestLogSelection then
            local ok, value = pcall(GetQuestLogSelection)
            if ok then selection = value end
        end
        C:Print("Questdiagnose ID " .. questID .. " | Index " .. tostring(index) ..
            " | Auswahl " .. tostring(selection))
        C:Print("Funktionen: Text=" .. type(GetQuestLogQuestText) ..
            " Auswahl=" .. type(SelectQuestLogEntry) ..
            " ModernIndex=" .. type(C_QuestLog and C_QuestLog.GetLogIndexForQuestID))
        if GetQuestLogQuestText then
            local directOK, directText, directGoal = pcall(GetQuestLogQuestText, index)
            local currentOK, currentText, currentGoal = pcall(GetQuestLogQuestText)
            C:Print("Direkt: " .. tostring(directOK) .. " / " ..
                (type(directText) == "string" and #directText or 0) .. " / " ..
                (type(directGoal) == "string" and #directGoal or 0) ..
                " | Aktuell: " .. tostring(currentOK) .. " / " ..
                (type(currentText) == "string" and #currentText or 0) .. " / " ..
                (type(currentGoal) == "string" and #currentGoal or 0))
        end
        local description, objectives = C.API.QuestText(questID)
        C:Print("Chronicle-Text: " .. (type(description) == "string" and #description or 0) ..
            " / " .. (type(objectives) == "string" and #objectives or 0))
    elseif command == "resetpos" then
        window:ClearAllPoints(); window:SetPoint("CENTER"); window:SetSize(960, 650)
        if C.db and C.db.settings then
            C.db.settings.windowWidth, C.db.settings.windowHeight = 960, 650
        end
        C:Print("Fensterposition und -groesse zurueckgesetzt.")
    elseif command == "help" then C:Print("/chronicle, /chr notes, /chr goal <Text>, /chr note <Text>, /chr repair, /chr debug, /chr questdebug, /chr resetpos")
    else C:Toggle() end
end
