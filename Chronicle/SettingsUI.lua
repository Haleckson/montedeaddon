local C = _G.Chronicle
local bg = "Interface\\Buttons\\WHITE8X8"
local gold = {1, .82, .1}
local cream = {.96, .91, .78}
local muted = {.72, .65, .52}
local frame, intro, sidebar, content, categoryButtons, rows
local activeCategory = "overview"

local categories = {
    {"overview", "Übersicht", "Alle Funktionen"},
    {"display", "Allgemein", "Oberfläche & Start"},
    {"classes", "Klassen", "Questbuch"},
    {"rares", "Rares", "Fundorte & Beute"},
    {"navigation", "Seitenmenü", "Navigation"},
}
local groupOrder = {"ANZEIGE", "KLASSEN", "RARES", "REISE", "WISSEN", "SAMMLUNG", "CHARAKTER"}
local categoryInfo = {
    overview = {"Alle Funktionen", "Schalte Chronicle-Funktionen ein oder aus."},
    display = {"Allgemein", "Anzeige und Hinweise im Spiel."},
    classes = {"Klassen", "Darstellung deiner Klassenquests."},
    rares = {"Rares", "Fundorte, Beute und Stufenfilter."},
    navigation = {"Seitenmenü", "Wähle die Kapitel für die linke Navigation."},
}

local function label(parent, size, color)
    local value = parent:CreateFontString(nil, "OVERLAY")
    value:SetFont(C:FontPath(), size)
    value:SetTextColor(unpack(color))
    value:SetJustifyH("LEFT")
    return value
end

local function setting(key, fallback)
    local settings = C.db and C.db.settings
    if not settings or settings[key] == nil then return fallback end
    return settings[key]
end

local function apply()
    if C.RefreshNavigation then C:RefreshNavigation() end
    if C.UpdateMinimapButtonVisibility then C:UpdateMinimapButtonVisibility() end
    C.showSuspiciousMoney = setting("showSuspiciousMoney", false) == true
end

local function options()
    local result = {}
    for _, page in ipairs(C:GetConfigurablePages()) do
        local key = page.key
        result[#result + 1] = {
            category = "navigation", group = page.group,
            title = C:L(key), detail = "Im Seitenmenü anzeigen",
            value = C:IsPageVisible(key),
            action = function()
                local settings = C.db.settings
                settings.hiddenPages = settings.hiddenPages or {}
                settings.hiddenPages[key] = C:IsPageVisible(key) and true or nil
                apply()
            end,
        }
    end
    local switches = {
        {"display", "ANZEIGE", "Minimap-Symbol", "Chronicle an der Minimap anzeigen", "showMinimapButton", true},
        {"display", "ANZEIGE", "Willkommenshinweis", "Beim Einloggen eine kurze Begrüßung anzeigen", "showWelcome", true},
        {"display", "ANZEIGE", "Auffällige Goldbuchungen", "Verdächtige Nullwerte nach dem Login anzeigen", "showSuspiciousMoney", false},
        {"classes", "KLASSEN", "Abgeschlossene Klassenquests", "Erledigte Einträge im Questbuch ausblenden", "classHideCompleted", false},
        {"rares", "RARES", "Rare-Koordinaten", "Fundorte und Kartenpositionen anzeigen", "rareShowCoordinates", true},
        {"rares", "RARES", "Mögliche Beute", "Gegenstände im Rare-Detail anzeigen", "rareShowLoot", true},
    }
    for _, option in ipairs(switches) do
        local key, fallback = option[5], option[6]
        result[#result + 1] = {
            category = option[1], group = option[2], title = option[3], detail = option[4],
            value = setting(key, fallback) == true,
            action = function()
                C.db.settings[key] = not (setting(key, fallback) == true)
                apply()
            end,
        }
    end
    result[#result + 1] = {
        category = "rares", group = "RARES", title = "Rare-Stufenbereich",
        detail = "Abstand zur eigenen Stufe · klicken zum Wechseln",
        valueText = "±" .. tostring(setting("rareLevelRange", 5)) .. " STUFEN  ›",
        action = function()
            local current = tonumber(setting("rareLevelRange", 5)) or 5
            C.db.settings.rareLevelRange = current == 5 and 10 or current == 10 and 20 or 5
        end,
    }
    return result
end

local function createHeading()
    local heading = CreateFrame("Frame", nil, content)
    heading.isHeading = true
    heading.text = label(heading, 11, gold)
    heading.text:SetPoint("LEFT", 1, 0)
    heading.rule = heading:CreateTexture(nil, "ARTWORK")
    heading.rule:SetTexture(bg)
    heading.rule:SetVertexColor(.43, .29, .11, .65)
    heading.rule:SetPoint("LEFT", heading.text, "RIGHT", 13, 0)
    heading.rule:SetPoint("RIGHT", heading, "RIGHT", -1, 0)
    heading.rule:SetHeight(C:RuleThickness())
    return heading
end

local function createOptionRow()
    local row = CreateFrame("Button", nil, content, "BackdropTemplate")
    row:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetTexture(bg)
    row.accent:SetPoint("TOPLEFT", 1, -2)
    row.accent:SetPoint("BOTTOMLEFT", 1, 2)
    row.accent:SetWidth(3)
    row.name = label(row, 15, cream)
    row.name:SetPoint("TOPLEFT", 17, -10)
    row.detail = label(row, 11, muted)
    row.detail:SetPoint("TOPLEFT", 17, -32)
    row.track = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.track:SetPoint("RIGHT", row, "RIGHT", -15, 0)
    row.track:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
    row.state = label(row.track, 11, cream)
    row.state:SetJustifyH("CENTER")
    row.knob = row.track:CreateTexture(nil, "ARTWORK")
    row.knob:SetTexture(bg)
    row.knob:SetSize(22, 22)
    row:SetScript("OnClick", function(self)
        if self.action then self.action(); C:RefreshSettings() end
    end)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(.83, .6, .19, 1)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(.4, .28, .12, .8)
    end)
    return row
end

local function updateRow(row, option, width)
    row:SetWidth(width)
    row:SetHeight(58)
    row:SetBackdropColor(option.value and .065 or .038,
        option.value and .06 or .036, option.value and .052 or .033, 1)
    row:SetBackdropBorderColor(.4, .28, .12, .8)
    row.accent:SetShown(option.value == true)
    row.accent:SetVertexColor(.96, .73, .19, .9)
    row.name:SetText(option.title)
    row.name:SetWidth(width - 165)
    row.detail:SetText(option.detail)
    row.detail:SetWidth(width - 165)
    row.track:SetSize(option.valueText and 122 or 84, 28)
    row.track:SetBackdropColor(option.value and .095 or .04,
        option.value and .08 or .038, option.value and .06 or .035, 1)
    row.track:SetBackdropBorderColor(option.value and .75 or .43,
        option.value and .55 or .31, option.value and .17 or .14, 1)
    row.state:ClearAllPoints()
    row.state:SetText(option.valueText or (option.value and "AN" or "AUS"))
    row.state:SetTextColor(option.value and 1 or .77,
        option.value and .82 or .7, option.value and .15 or .57)
    if option.valueText then
        row.knob:Hide()
        row.state:SetWidth(116)
        row.state:SetPoint("CENTER", row.track, "CENTER", 0, 0)
    else
        row.knob:Show()
        row.knob:ClearAllPoints()
        row.knob:SetPoint(option.value and "RIGHT" or "LEFT", row.track,
            option.value and "RIGHT" or "LEFT", option.value and -3 or 3, 0)
        row.knob:SetVertexColor(option.value and 1 or .55,
            option.value and .82 or .49, option.value and .2 or .4)
        row.state:SetWidth(37)
        row.state:SetPoint(option.value and "LEFT" or "RIGHT", row.track,
            option.value and "LEFT" or "RIGHT", option.value and 8 or -8, 0)
    end
    row.action = option.action
    row:Show()
end

function C:RefreshSettings(width)
    if not frame or not frame:IsShown() then return end
    width = width or frame:GetWidth()
    local paneWidth = width - 243
    intro:SetWidth(width - 8)
    content:SetWidth(paneWidth)
    local all = options()
    local active, switches, visible, pages = 0, 0, 0, 0
    local categoryCounts = {
        display = {0, 0}, classes = {0, 0}, rares = {0, 0},
    }
    for _, option in ipairs(all) do
        if option.category == "navigation" then
            pages = pages + 1
            if option.value then visible = visible + 1 end
        elseif not option.valueText then
            switches = switches + 1
            if option.value then active = active + 1 end
            local counts = categoryCounts[option.category]
            if counts then
                counts[2] = counts[2] + 1
                if option.value then counts[1] = counts[1] + 1 end
            end
        end
    end
    intro.count:SetText(switches .. " FUNKTIONEN  ·  " .. pages .. " MENÜSEITEN")
    for _, button in ipairs(categoryButtons) do
        local selected = button.category == activeCategory
        button:SetBackdropColor(selected and .095 or .038,
            selected and .082 or .036, selected and .061 or .032, 1)
        button:SetBackdropBorderColor(selected and .84 or .26,
            selected and .6 or .19, selected and .17 or .09, 1)
        button.accent:SetShown(selected)
        button.name:SetTextColor(selected and 1 or .87,
            selected and .82 or .79, selected and .1 or .68)
        if button.category == "navigation" then
            button.detail:SetText(visible .. " / " .. pages .. " sichtbar")
        elseif button.category == "overview" then
            button.detail:SetText(active .. " / " .. switches .. " aktiv")
        else
            local counts = categoryCounts[button.category]
            button.detail:SetText(counts[1] .. " / " .. counts[2] .. " aktiv")
        end
    end
    content.title:SetText(categoryInfo[activeCategory][1])
    content.note:SetText(categoryInfo[activeCategory][2])
    if activeCategory == "navigation" then
        content.count:SetText(visible .. " / " .. pages .. " SICHTBAR")
    elseif activeCategory == "overview" then
        content.count:SetText(active .. " / " .. switches .. " AKTIV")
    else
        local counts = categoryCounts[activeCategory]
        content.count:SetText(counts[1] .. " / " .. counts[2] .. " AKTIV")
    end

    local y, used = 78, 0
    local rowWidth = paneWidth - 26
    local columns = activeCategory == "navigation" and paneWidth >= 690 and 2 or 1
    local columnGap = 8
    local itemWidth = columns == 2 and (rowWidth - columnGap) / 2 or rowWidth
    for _, group in ipairs(groupOrder) do
        local members = {}
        for _, option in ipairs(all) do
            local included = activeCategory == "overview" and option.category ~= "navigation" or
                option.category == activeCategory
            if included and option.group == group then members[#members + 1] = option end
        end
        if #members > 0 then
            used = used + 1
            local heading = rows[used]
            if not heading or not heading.isHeading then
                if heading then heading:Hide() end
                heading = createHeading()
                rows[used] = heading
            end
            heading:ClearAllPoints()
            heading:SetPoint("TOPLEFT", content, "TOPLEFT", 13, -y)
            heading:SetSize(rowWidth, 24)
            heading.text:SetText(group)
            heading:Show()
            y = y + 29
            for index, option in ipairs(members) do
                used = used + 1
                local row = rows[used]
                if not row or row.isHeading then
                    if row then row:Hide() end
                    row = createOptionRow()
                    rows[used] = row
                end
                local column = (index - 1) % columns
                local line = math.floor((index - 1) / columns)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", content, "TOPLEFT",
                    13 + column * (itemWidth + columnGap), -y - line * 64)
                updateRow(row, option, itemWidth)
            end
            y = y + math.ceil(#members / columns) * 64 + 5
        end
    end
    for i = used + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(470, y + 14))
    sidebar:SetHeight(content:GetHeight())
    frame:SetHeight(105 + content:GetHeight() + 10)
    if frame:GetParent() then frame:GetParent():SetHeight(frame:GetHeight() + 8) end
end

function C:HideSettings()
    if frame then frame:Hide() end
end

function C:ShowSettings(parent, width)
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:SetPoint("TOPLEFT", 0, 0)
        rows, categoryButtons = {}, {}

        intro = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        intro:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 0)
        intro:SetHeight(87)
        intro:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
        intro:SetBackdropColor(.035, .034, .032, 1)
        intro:SetBackdropBorderColor(.42, .29, .10, .85)
        intro.caption = label(intro, 10, gold)
        intro.caption:SetPoint("TOPLEFT", 19, -12)
        intro.caption:SetText("CHRONICLE  /  EINSTELLUNGEN")
        intro.title = label(intro, 21, cream)
        intro.title:SetPoint("TOPLEFT", 19, -32)
        intro.title:SetText("Chronicle konfigurieren")
        intro.count = label(intro, 10, gold)
        intro.count:SetPoint("TOPLEFT", 20, -65)

        sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -101)
        sidebar:SetWidth(220)
        sidebar:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
        sidebar:SetBackdropColor(.03, .029, .027, 1)
        sidebar:SetBackdropBorderColor(.38, .26, .11, .85)
        sidebar.heading = label(sidebar, 10, gold)
        sidebar.heading:SetPoint("TOPLEFT", 14, -15)
        sidebar.heading:SetText("BEREICHE")
        for i, spec in ipairs(categories) do
            local button = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
            button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -40 - (i-1)*53)
            button:SetSize(200, 47)
            button:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
            button.category = spec[1]
            button.accent = button:CreateTexture(nil, "ARTWORK")
            button.accent:SetTexture(bg)
            button.accent:SetPoint("TOPLEFT", 1, -1)
            button.accent:SetPoint("BOTTOMLEFT", 1, 1)
            button.accent:SetWidth(3)
            button.accent:SetVertexColor(1, .76, .19)
            button.name = label(button, 14, cream)
            button.name:SetPoint("TOPLEFT", 13, -7)
            button.name:SetText(spec[2])
            button.detail = label(button, 11, muted)
            button.detail:SetPoint("TOPLEFT", 13, -27)
            button.detail:SetText(spec[3])
            button:SetScript("OnClick", function(self)
                activeCategory = self.category
                C:RefreshSettings()
                local scroll = frame:GetParent() and frame:GetParent():GetParent()
                if scroll and scroll.SetVerticalScroll then scroll:SetVerticalScroll(0) end
            end)
            categoryButtons[#categoryButtons + 1] = button
        end
        sidebar.hint = label(sidebar, 10, muted)
        sidebar.hint:SetPoint("BOTTOMLEFT", 14, 55)
        sidebar.hint:SetText("Änderungen werden sofort gespeichert.")
        sidebar.hint:SetWidth(190)
        sidebar.reset = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        C:StyleChronicleButton(sidebar.reset)
        sidebar.reset:SetPoint("BOTTOMLEFT", 12, 15)
        sidebar.reset:SetSize(196, 25)
        sidebar.reset:SetText("Standardwerte")
        sidebar.reset:SetScript("OnClick", function()
            local settings = C.db.settings
            settings.hiddenPages = {}
            settings.showMinimapButton = true
            settings.showWelcome = true
            settings.showSuspiciousMoney = false
            settings.classHideCompleted = false
            settings.rareShowCoordinates = true
            settings.rareShowLoot = true
            settings.rareLevelRange = 5
            apply()
            C:RefreshSettings()
        end)

        content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 234, -101)
        content:SetBackdrop({bgFile = bg, edgeFile = bg, edgeSize = C:RuleThickness()})
        content:SetBackdropColor(.03, .029, .027, 1)
        content:SetBackdropBorderColor(.45, .3, .12, .9)
        content.title = label(content, 19, gold)
        content.title:SetPoint("TOPLEFT", 14, -12)
        content.note = label(content, 12, muted)
        content.note:SetPoint("TOPLEFT", 15, -41)
        content.count = label(content, 10, gold)
        content.count:SetPoint("TOPRIGHT", -16, -17)
        content.count:SetJustifyH("RIGHT")
    end
    frame:SetParent(parent)
    frame:SetWidth(width)
    frame:Show()
    self:RefreshSettings(width)
end
