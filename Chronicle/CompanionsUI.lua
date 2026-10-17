local C = _G.Chronicle
local U = C.Util
local BACKGROUND = "Interface\\Buttons\\WHITE8X8"
local hero, rows, detail = nil, {}, nil
local classSigils = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
    PRIEST = "Priest", SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}
local classColorFallback = {
    WARRIOR = "C79C6E", PALADIN = "F58CBA", HUNTER = "ABD473", ROGUE = "FFF569",
    PRIEST = "FFFFFF", SHAMAN = "0070DE", MAGE = "3FC7EB", WARLOCK = "8788EE", DRUID = "FF7D0A",
}
local function classColor(class)
    local live = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if live and live.r and live.g and live.b then
        return ("%02X%02X%02X"):format(math.floor(live.r * 255 + .5),
            math.floor(live.g * 255 + .5), math.floor(live.b * 255 + .5))
    end
    return classColorFallback[class] or "D1BFA3"
end
local function talentLabel(entry)
    local talents = type(entry.talents) == "table" and entry.talents or nil
    if not talents then return C:LocalizeDisplay("nicht erfasst") end
    local branches = talents.branches
    if type(branches) == "table" and #branches == 3 then
        local counts = tostring(branches[1].points or 0) .. "/" ..
            tostring(branches[2].points or 0) .. "/" .. tostring(branches[3].points or 0)
        local name = talents.name
        if type(name) ~= "string" or name == "" then
            local leader, most = nil, 0
            for _, branch in ipairs(branches) do
                if (branch.points or 0) > most then leader, most = branch.name, branch.points end
            end
            name = leader or C:LocalizeDisplay("Keine Talente")
        end
        return C:LocalizeDisplay(name) .. " " .. counts
    end
    return C:LocalizeDisplay(U.SafeText(talents.name, C:LocalizeDisplay("nicht erfasst")))
end
local eventIcons = {
    boss = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    dungeon = "Interface\\Icons\\INV_Misc_Key_03",
    quest = "Interface\\Icons\\INV_Misc_Note_01",
    zone = "Interface\\Icons\\Spell_Nature_EarthBind",
    rare = "Interface\\Icons\\Ability_Hunter_SniperShot",
    death = "Interface\\AddOns\\Chronicle\\DeathMedallion",
    level = "Interface\\Icons\\INV_Misc_Book_09",
}
local eventLabels = { boss = "BOSS", dungeon = "INSTANZ", quest = "QUEST", zone = "GEBIET",
    rare = "SELTENE KREATUR", death = "TOD", level = "STUFE" }

local function font(widget, size, color)
    widget:SetFont(C:FontPath(), size)
    widget:SetTextColor(unpack(color))
end

local function panel(frame, r, g, b)
    frame:SetBackdrop({ bgFile = BACKGROUND, edgeFile = BACKGROUND, edgeSize = C:RuleThickness() })
    local shade = .027 + math.min(.3, math.max(0, r or 0)) * .12
    frame:SetBackdropColor(shade, shade * .96, shade * .9, .94)
    frame:SetBackdropBorderColor(.42, .29, .10, .85)
end

local function companionAddress(entry)
    return entry.name .. (entry.realm and entry.realm ~= "" and "-" .. entry.realm or "")
end

function C:ShowCompanionDetail(entry)
    if type(entry) ~= "table" then return end
    if not detail then
        detail = CreateFrame("Frame", "ChronicleCompanionWindow", self.frame or UIParent, "BackdropTemplate")
        detail:SetSize(760, 440)
        detail:SetPoint("CENTER")
        detail:SetFrameStrata("DIALOG")
        detail:SetToplevel(true)
        detail:SetClampedToScreen(true)
        detail:EnableMouse(true)
        detail:SetMovable(true)
        detail:RegisterForDrag("LeftButton")
        detail:SetScript("OnDragStart", detail.StartMoving)
        detail:SetScript("OnDragStop", detail.StopMovingOrSizing)
        panel(detail, .09, .06, .035)
        self:ApplyMaterial(detail, .18)
        detail:SetBackdropColor(.03, .029, .027, 1)
        self:OrnateCorners(detail)
        detail.caption = detail:CreateFontString(nil, "OVERLAY")
        detail.caption:SetPoint("TOPLEFT", 92, -21)
        font(detail.caption, 10, {1, .82, .1})
        detail.icon = detail:CreateTexture(nil, "ARTWORK")
        detail.icon:SetSize(60, 60)
        detail.icon:SetPoint("TOPLEFT", 27, -27)
        detail.title = detail:CreateFontString(nil, "OVERLAY")
        detail.title:SetPoint("TOPLEFT", 91, -43)
        detail.title:SetJustifyH("LEFT")
        font(detail.title, 22, {.96, .91, .78})
        detail.meta = detail:CreateFontString(nil, "OVERLAY")
        detail.meta:SetPoint("TOPLEFT", 92, -77)
        detail.meta:SetJustifyH("LEFT")
        font(detail.meta, 12, {.82, .75, .64})
        detail.guild = detail:CreateFontString(nil, "OVERLAY")
        detail.guild:SetPoint("TOPLEFT", 92, -98)
        detail.guild:SetJustifyH("LEFT")
        font(detail.guild, 11, {.82, .75, .64})
        detail.talents = detail:CreateFontString(nil, "OVERLAY")
        detail.talents:SetPoint("TOPLEFT", 92, -118)
        detail.talents:SetJustifyH("LEFT")
        font(detail.talents, 11, {.96, .91, .78})
        detail.summary = detail:CreateFontString(nil, "OVERLAY")
        detail.summary:SetPoint("TOPLEFT", 92, -140)
        detail.summary:SetJustifyH("LEFT")
        font(detail.summary, 10, {1, .82, .1})
        detail.close = CreateFrame("Button", nil, detail, "BackdropTemplate")
        self:StyleChronicleButton(detail.close)
        detail.close:SetSize(88, 25)
        detail.close:SetPoint("TOPRIGHT", -18, -17)
        detail.close:SetScript("OnClick", function() detail:Hide() end)
        detail.rule = detail:CreateTexture(nil, "ARTWORK")
        detail.rule:SetTexture(BACKGROUND)
        detail.rule:SetVertexColor(.58, .39, .14, .9)
        detail.rule:SetPoint("TOPLEFT", 25, -172)
        detail.rule:SetPoint("TOPRIGHT", -25, -172)
        detail.rule:SetHeight(C:RuleThickness())
        detail.heading = detail:CreateFontString(nil, "OVERLAY")
        detail.heading:SetPoint("TOPLEFT", 27, -190)
        font(detail.heading, 14, {1, .82, .1})
        detail.explanation = detail:CreateFontString(nil, "OVERLAY")
        detail.explanation:SetPoint("TOPLEFT", 28, -215)
        font(detail.explanation, 11, {.82, .75, .64})
        detail.scroll = CreateFrame("ScrollFrame", nil, detail, "UIPanelScrollFrameTemplate")
        detail.scroll:SetPoint("TOPLEFT", 25, -244)
        detail.scroll:SetPoint("BOTTOMRIGHT", -42, 87)
        detail.child = CreateFrame("Frame", nil, detail.scroll)
        detail.child:SetSize(670, 1)
        detail.scroll:SetScrollChild(detail.child)
        detail.rows = {}
        detail.whisper = CreateFrame("Button", nil, detail, "BackdropTemplate")
        self:StyleChronicleButton(detail.whisper)
        detail.whisper:SetSize(145, 28)
        detail.whisper:SetPoint("BOTTOMLEFT", 25, 25)
        detail.whisper:SetScript("OnClick", function()
            if self.companionDemo or not detail.entry then return end
            local name = companionAddress(detail.entry)
            if type(ChatFrame_SendTell) == "function" then ChatFrame_SendTell(name)
            elseif type(ChatFrame_OpenChat) == "function" then ChatFrame_OpenChat("/w " .. name .. " ") end
        end)
        detail.invite = CreateFrame("Button", nil, detail, "BackdropTemplate")
        self:StyleChronicleButton(detail.invite)
        detail.invite:SetSize(165, 28)
        detail.invite:SetPoint("LEFT", detail.whisper, "RIGHT", 10, 0)
        detail.invite:SetScript("OnClick", function()
            if self.companionDemo or not detail.entry then return end
            local invite = C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
            if type(invite) == "function" then pcall(invite, companionAddress(detail.entry)) end
        end)
        detail.demoNotice = detail:CreateFontString(nil, "OVERLAY")
        detail.demoNotice:SetPoint("BOTTOMLEFT", 27, 64)
        font(detail.demoNotice, 10, {1, .82, .1})
    end
    detail.entry = entry
    detail.caption:SetText(self:LocalizeDisplay("CHRONICLE  /  REISEGEFÄHRTE"))
    detail.title:SetText(companionAddress(entry))
    detail.title:SetWidth(470)
    detail.icon:SetTexture(classSigils[entry.class] and ("Interface\\AddOns\\Chronicle\\ClassSigil_" .. classSigils[entry.class]) or
        "Interface\\Icons\\INV_Misc_GroupNeedMore")
    detail.meta:SetText(self:LocalizeDisplay("STUFE ") .. tostring(entry.level or "?") .. "   •   " ..
        "|cff" .. classColor(entry.class) ..
        U.SafeText(entry.className, self:LocalizeDisplay("Klasse unbekannt")) .. "|r")
    detail.meta:SetWidth(635)
    detail.guild:SetText(self:LocalizeDisplay("GILDE  ") ..
        U.SafeText(entry.guild, self:LocalizeDisplay("nicht erfasst")))
    detail.guild:SetWidth(635)
    detail.talents:SetText(self:LocalizeDisplay("Skillung: ") .. talentLabel(entry))
    detail.talents:SetWidth(635)
    local latestDungeon
    for _, activity in ipairs(entry.activities or {}) do
        if activity.kind == "dungeon" and type(activity.text) == "string" then
            latestDungeon = activity.text:match(":%s*(.+)$")
            if latestDungeon then break end
        end
    end
    detail.summary:SetText(tostring(entry.meetings or 1) .. " " .. self:LocalizeDisplay("GRUPPENBEGEGNUNGEN") ..
        "   •   " .. (latestDungeon and (self:LocalizeDisplay("Zuletzt gemeinsam: ") ..
            self:LocalizeDisplay(latestDungeon)) or
            (self.companionDemo and self:LocalizeDisplay("DEMO") or
                (self:LocalizeDisplay("Zuletzt gesehen: ") .. U.Date(entry.lastSeen, true)))))
    detail.summary:SetWidth(635)
    detail.close:SetText(self:LocalizeDisplay("SCHLIESSEN"))
    detail.heading:SetText(self:LocalizeDisplay("Eure gemeinsame Chronik"))
    detail.explanation:SetText(self:LocalizeDisplay("Diese Ereignisse wurden aufgezeichnet, während ihr in derselben Gruppe wart."))
    detail.whisper:SetText(self:LocalizeDisplay("FLÜSTERN"))
    detail.invite:SetText(self:LocalizeDisplay("GRUPPE EINLADEN"))
    detail.whisper:SetEnabled(not self.companionDemo)
    detail.invite:SetEnabled(not self.companionDemo)
    detail.whisper:SetAlpha(self.companionDemo and .45 or 1)
    detail.invite:SetAlpha(self.companionDemo and .45 or 1)
    detail.demoNotice:SetText(self:LocalizeDisplay("DEMO: Flüstern und Einladung sind hier deaktiviert."))
    detail.demoNotice:SetShown(self.companionDemo == true)
    local activities = entry.activities or {}
    local hasActivities = #activities > 0
    if not hasActivities then
        activities = { { text = self:LocalizeDisplay("Noch keine gemeinsamen Ereignisse erfasst."), time = nil } }
    end
    detail:SetHeight(math.max(445, math.min(650, 341 + #activities * 64)))
    for index, activity in ipairs(activities) do
        local row = detail.rows[index]
        if not row then
            row = CreateFrame("Frame", nil, detail.child)
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetTexture(BACKGROUND)
            row.highlight:SetAllPoints(row)
            row.highlight:SetVertexColor(.09, .085, .075, .24)
            row.topLink = row:CreateTexture(nil, "ARTWORK")
            row.topLink:SetTexture(BACKGROUND)
            row.topLink:SetVertexColor(.65, .45, .16, .55)
            row.topLink:SetPoint("TOPLEFT", 19, 0)
            row.topLink:SetSize(C:RuleThickness(), 14)
            row.bottomLink = row:CreateTexture(nil, "ARTWORK")
            row.bottomLink:SetTexture(BACKGROUND)
            row.bottomLink:SetVertexColor(.65, .45, .16, .55)
            row.bottomLink:SetPoint("TOPLEFT", 19, -44)
            row.bottomLink:SetSize(C:RuleThickness(), 20)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(30, 30)
            row.icon:SetPoint("LEFT", 5, 0)
            row.kind = row:CreateFontString(nil, "OVERLAY")
            row.kind:SetPoint("TOPLEFT", 48, -7)
            row.kind:SetWidth(470)
            row.kind:SetJustifyH("LEFT")
            font(row.kind, 10, {1, .82, .1})
            row.date = row:CreateFontString(nil, "OVERLAY")
            row.date:SetPoint("TOPRIGHT", -9, -7)
            row.date:SetJustifyH("RIGHT")
            font(row.date, 10, {.82, .75, .64})
            row.text = row:CreateFontString(nil, "OVERLAY")
            row.text:SetPoint("TOPLEFT", 48, -27)
            row.text:SetJustifyH("LEFT")
            font(row.text, 13, {.96, .91, .78})
            row.rule = row:CreateTexture(nil, "ARTWORK")
            row.rule:SetTexture(BACKGROUND)
            row.rule:SetVertexColor(.42, .29, .10, .65)
            row.rule:SetPoint("BOTTOMLEFT", 0, 0)
            row.rule:SetPoint("BOTTOMRIGHT", 0, 0)
            row.rule:SetHeight(C:RuleThickness())
            detail.rows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 64)
        row:SetSize(660, 58)
        local earliest = hasActivities and index == #activities
        row.highlight:SetShown(earliest)
        row.topLink:SetShown(hasActivities and index > 1)
        row.bottomLink:SetShown(hasActivities and index < #activities)
        row.icon:SetTexture(eventIcons[activity.kind] or "Interface\\Icons\\INV_Misc_Note_05")
        row.kind:SetText((earliest and (self:LocalizeDisplay("FRÜHE GEMEINSAME ERINNERUNG") .. "  ·  ") or "") ..
            self:LocalizeDisplay(eventLabels[activity.kind] or "CHRONIK"))
        row.date:SetText(activity.time and U.Date(activity.time, true) or "")
        row.text:SetText(self:LocalizeEventText(activity.text or ""))
        row.text:SetWidth(595)
        row:Show()
    end
    for index = #activities + 1, #detail.rows do detail.rows[index]:Hide() end
    local contentHeight = math.max(1, #activities * 64 - 6)
    detail.child:SetHeight(contentHeight)
    if detail.scroll.ScrollBar then
        detail.scroll.ScrollBar:SetShown(contentHeight > detail:GetHeight() - 331)
    end
    detail.scroll:SetVerticalScroll(0)
    detail:Show()
end

function C:HideCompanions()
    if hero then hero:Hide() end
    for _, row in ipairs(rows) do row:Hide() end
end

function C:ShowCompanions(parent, width)
    local entries = {}
    if self.companionDemo then
        entries = {
            { name = "Arannis", class = "MAGE", level = 32, className = self:LocalizeDisplay("Magier"), guild = "Sternenwacht", meetings = 5, inGroup = true, lastSeen = time(), talents = {name = "Frost", branches = {{points = 0}, {points = 0}, {points = 23}}}, activities = {
                { time = time() - 1200, kind = "boss", text = "Boss besiegt: Edwin VanCleef" },
                { time = time() - 2400, kind = "dungeon", text = "Instanz betreten: Die Todesminen" },
            } },
            { name = "Brakka", class = "WARRIOR", level = 29, className = self:LocalizeDisplay("Krieger"), guild = "Sternenwacht", meetings = 3, lastSeen = time() - 3600, talents = {name = "Waffen", branches = {{points = 20}, {points = 0}, {points = 0}}}, activities = {
                { time = time() - 3600, kind = "quest", text = "Quest abgeschlossen: Die Bruderschaft der Defias" },
            } },
            { name = "Lyra", class = "PRIEST", level = 27, className = self:LocalizeDisplay("Priesterin"), meetings = 2, lastSeen = time() - 86400, talents = {name = "Heilig", branches = {{points = 0}, {points = 18}, {points = 0}}}, activities = {
                { time = time() - 86400, kind = "zone", text = "Gebiet entdeckt: Westfall" },
            } },
            { name = "Thalia", class = "PALADIN", level = 35, className = self:LocalizeDisplay("Paladin"), guild = "Sternenwacht", meetings = 7, lastSeen = time() - 172800, talents = {name = "Schutz", branches = {{points = 0}, {points = 26}, {points = 0}}}, activities = {
                { time = time() - 172800, kind = "boss", text = "Boss besiegt: Arugal" },
                { time = time() - 173100, kind = "dungeon", text = "Instanz betreten: Burg Schattenfang" },
            } },
            { name = "Fenris", class = "HUNTER", level = 31, className = self:LocalizeDisplay("Jäger"), guild = "Waldläufer", meetings = 4, lastSeen = time() - 259200, talents = {name = "Tierherrschaft", branches = {{points = 22}, {points = 0}, {points = 0}}}, activities = {
                { time = time() - 259200, kind = "rare", text = "Seltene Kreatur besiegt: Humar der Rudellord" },
            } },
            { name = "Sylwen", class = "DRUID", level = 28, className = self:LocalizeDisplay("Druidin"), meetings = 3, lastSeen = time() - 345600, talents = {name = "Wiederherstellung", branches = {{points = 0}, {points = 0}, {points = 19}}}, activities = {
                { time = time() - 345600, kind = "quest", text = "Quest abgeschlossen: Eine gemeinsame Reise" },
            } },
            { name = "Vex", class = "ROGUE", level = 30, className = self:LocalizeDisplay("Schurke"), guild = "Nachtklingen", meetings = 2, lastSeen = time() - 432000, talents = {name = "Meucheln", branches = {{points = 21}, {points = 0}, {points = 0}}}, activities = {
                { time = time() - 432000, kind = "dungeon", text = "Instanz betreten: Die Todesminen" },
            } },
            { name = "Nira", class = "WARLOCK", level = 33, className = self:LocalizeDisplay("Hexenmeisterin"), meetings = 1, lastSeen = time() - 518400, talents = {name = "Gebrechen", branches = {{points = 24}, {points = 0}, {points = 0}}}, activities = {
                { time = time() - 518400, kind = "level", text = "Stufe 33 erreicht" },
            } },
        }
    else
        for _, entry in pairs(self.db and self.db.companions or {}) do
            if type(entry) == "table" and type(entry.name) == "string" then entries[#entries + 1] = entry end
        end
    end
    table.sort(entries, function(a, b)
        if (a.inGroup and 1 or 0) ~= (b.inGroup and 1 or 0) then return a.inGroup end
        if (a.lastSeen or 0) ~= (b.lastSeen or 0) then return (a.lastSeen or 0) > (b.lastSeen or 0) end
        return a.name < b.name
    end)
    local totalEntries = #entries
    local query = U.Trim(self.companionQuery or ""):lower()
    if query ~= "" then
        local filtered = {}
        for _, entry in ipairs(entries) do
            local name = companionAddress(entry):lower()
            local guild = U.SafeText(entry.guild, ""):lower()
            if name:find(query, 1, true) or guild:find(query, 1, true) then
                filtered[#filtered + 1] = entry
            end
        end
        entries = filtered
    end

    if not hero then
        hero = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        panel(hero, .12, .075, .035)
        hero.caption = hero:CreateFontString(nil, "OVERLAY")
        hero.caption:SetPoint("TOPLEFT", 20, -14)
        font(hero.caption, 10, {1, .82, .1})
        hero.title = hero:CreateFontString(nil, "OVERLAY")
        hero.title:SetPoint("TOPLEFT", 20, -39)
        hero.title:SetJustifyH("LEFT")
        font(hero.title, 24, {.96, .91, .78})
        hero.detail = hero:CreateFontString(nil, "OVERLAY")
        hero.detail:SetPoint("TOPLEFT", 21, -80)
        hero.detail:SetJustifyH("LEFT")
        font(hero.detail, 12, {.82, .75, .64})
        hero.rule = hero:CreateTexture(nil, "ARTWORK")
        hero.rule:SetTexture(BACKGROUND)
        hero.rule:SetVertexColor(.58, .39, .14, .9)
        hero.rule:SetPoint("BOTTOMLEFT", 18, 18)
        hero.rule:SetPoint("BOTTOMRIGHT", -18, 18)
        hero.rule:SetHeight(C:RuleThickness())
        hero.count = hero:CreateFontString(nil, "OVERLAY")
        hero.count:SetPoint("BOTTOMLEFT", 20, 5)
        font(hero.count, 10, {1, .82, .1})
        hero.demo = CreateFrame("Button", nil, hero, "BackdropTemplate")
        C:StyleChronicleButton(hero.demo)
        hero.demo:SetPoint("TOPRIGHT", -17, -14)
        hero.demo:SetSize(142, 24)
        hero.demo:SetScript("OnClick", function()
            C.companionDemo = not C.companionDemo
            C:Refresh()
        end)
        hero.search = CreateFrame("EditBox", nil, hero, "InputBoxTemplate")
        hero.search:SetAutoFocus(false)
        hero.search:SetMaxLetters(80)
        hero.search:SetSize(225, 24)
        hero.search:SetPoint("TOPRIGHT", -23, -67)
        hero.searchHint = hero.search:CreateFontString(nil, "ARTWORK")
        hero.searchHint:SetPoint("LEFT", 7, 0)
        font(hero.searchHint, 10, {.72, .65, .52})
        hero.search:SetScript("OnTextChanged", function(box)
            hero.searchHint:SetShown(box:GetText() == "")
            C.companionQuery = box:GetText()
            if hero.currentParent then C:ShowCompanions(hero.currentParent, hero.currentWidth) end
        end)
        hero.search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
        hero.search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    end
    hero.currentParent, hero.currentWidth = parent, width
    hero:ClearAllPoints()
    hero:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, 0)
    hero:SetSize(width, 143)
    hero.caption:SetText(self:LocalizeDisplay("CHRONICLE  /  REISEGEFÄHRTEN"))
    hero.title:SetText(self:LocalizeDisplay("Gemeinsam durch Azeroth"))
    hero.title:SetWidth(width - 200)
    hero.detail:SetText(self.companionDemo and self:LocalizeDisplay("DEMO: Beispielgefährten. Es werden keine Daten gespeichert.") or
        self:LocalizeDisplay("Spieler aus deinen Gruppen und Raids. Werte werden bei neuen Begegnungen aktualisiert."))
    hero.detail:SetWidth(width - 300)
    hero.searchHint:SetText(self:LocalizeDisplay("Gefährten suchen ..."))
    hero.searchHint:SetShown(hero.search:GetText() == "")
    hero.count:SetText((query ~= "" and (#entries .. " / " .. totalEntries) or tostring(#entries)) .. " " ..
        self:LocalizeDisplay(self.companionDemo and "BEISPIELGEFÄHRTEN" or "GEFÄHRTEN ERFASST"))
    hero.demo:SetText(self:LocalizeDisplay(self.companionDemo and "DEMO BEENDEN" or "DEMO ANZEIGEN"))
    hero:Show()

    if #entries == 0 then
        local row = rows[1]
        if not row or not row.empty then
            if row then row:Hide() end
            row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            panel(row, .10, .065, .035)
            row.empty = row:CreateFontString(nil, "OVERLAY")
            row.empty:SetPoint("CENTER")
            font(row.empty, 14, {.96, .91, .78})
            rows[1] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -164)
        row:SetSize(width, 120)
        row.empty:SetText(self:LocalizeDisplay(query ~= "" and "Keine Reisegefährten gefunden." or
            "Deine Reisegefährten erscheinen hier, sobald ihr gemeinsam unterwegs seid."))
        row.empty:SetWidth(width - 40)
        row:Show()
        for index = 2, #rows do rows[index]:Hide() end
        parent:SetHeight(340)
        return
    end

    local twoColumns = width >= 850
    local cardWidth = twoColumns and math.floor((width - 12) / 2) or width
    local columns = twoColumns and 2 or 1
    for index, entry in ipairs(entries) do
        local row = rows[index]
        if not row or not row.name then
            if row then row:Hide() end
            row = CreateFrame("Button", nil, parent, "BackdropTemplate")
            panel(row, .095, .058, .03)
            row.hover = row:CreateTexture(nil, "BACKGROUND")
            row.hover:SetTexture(BACKGROUND)
            row.hover:SetAllPoints(row)
            row.hover:SetVertexColor(1, .72, .18, .1)
            row.hover:Hide()
            row:SetScript("OnEnter", function(self)
                self.hover:Show()
                self:SetBackdropBorderColor(.8, .58, .2, 1)
            end)
            row:SetScript("OnLeave", function(self)
                self.hover:Hide()
                self:SetBackdropBorderColor(.42, .29, .10, .85)
            end)
            row:SetScript("OnClick", function(self) C:ShowCompanionDetail(self.entry) end)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(124, 124)
            row.icon:SetPoint("TOPLEFT", 1, 0)
            row.name = row:CreateFontString(nil, "OVERLAY")
            row.name:SetPoint("TOPLEFT", 148, -16)
            row.name:SetJustifyH("LEFT")
            font(row.name, 18, {.98, .94, .84})
            row.meta = row:CreateFontString(nil, "OVERLAY")
            row.meta:SetPoint("TOPLEFT", 149, -44)
            row.meta:SetJustifyH("LEFT")
            font(row.meta, 12, {.82, .75, .64})
            row.guild = row:CreateFontString(nil, "OVERLAY")
            row.guild:SetPoint("TOPLEFT", 149, -68)
            row.guild:SetJustifyH("LEFT")
            font(row.guild, 11, {.96, .91, .78})
            row.talents = row:CreateFontString(nil, "OVERLAY")
            row.talents:SetPoint("TOPLEFT", 149, -87)
            row.talents:SetJustifyH("LEFT")
            row.talents:SetHeight(14)
            font(row.talents, 10, {.88, .8, .64})
            row.event = row:CreateFontString(nil, "OVERLAY")
            row.event:SetPoint("TOPLEFT", 149, -106)
            row.event:SetJustifyH("LEFT")
            row.event:SetJustifyV("TOP")
            row.event:SetHeight(14)
            font(row.event, 10, {.82, .69, .46})
            row.divider = row:CreateTexture(nil, "ARTWORK")
            row.divider:SetTexture(BACKGROUND)
            row.divider:SetVertexColor(.5, .32, .12, .55)
            row.divider:SetPoint("TOPRIGHT", -138, -14)
            row.divider:SetPoint("BOTTOMRIGHT", -138, 14)
            row.divider:SetWidth(C:RuleThickness())
            row.seen = row:CreateFontString(nil, "OVERLAY")
            row.seen:SetPoint("TOPRIGHT", -17, -14)
            row.seen:SetJustifyH("RIGHT")
            font(row.seen, 11, {1, .82, .1})
            row.meetings = row:CreateFontString(nil, "OVERLAY")
            row.meetings:SetPoint("TOPRIGHT", -17, -43)
            row.meetings:SetJustifyH("RIGHT")
            font(row.meetings, 25, {1, .82, .1})
            row.meetingsLabel = row:CreateFontString(nil, "OVERLAY")
            row.meetingsLabel:SetPoint("TOPRIGHT", -17, -75)
            row.meetingsLabel:SetJustifyH("RIGHT")
            font(row.meetingsLabel, 10, {.88, .8, .64})
            row.open = row:CreateFontString(nil, "OVERLAY")
            row.open:SetPoint("BOTTOMRIGHT", -17, 11)
            font(row.open, 11, {1, .82, .1})
            rows[index] = row
        end
        row:ClearAllPoints()
        local column = (index - 1) % columns
        local line = math.floor((index - 1) / columns)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4 + column * (cardWidth + 12), -(160 + line * 136))
        row:SetSize(cardWidth, 124)
        row.entry = entry
        row.icon:SetTexture(classSigils[entry.class] and ("Interface\\AddOns\\Chronicle\\ClassSigil_" .. classSigils[entry.class]) or
            "Interface\\Icons\\INV_Misc_GroupNeedMore")
        row.name:SetText(entry.name .. (entry.realm and entry.realm ~= "" and "-" .. entry.realm or ""))
        row.name:SetWidth(cardWidth - 300)
        row.meta:SetText(self:LocalizeDisplay("STUFE ") .. tostring(entry.level or "?") .. "   •   |cff" ..
            classColor(entry.class) .. U.SafeText(entry.className, self:LocalizeDisplay("Klasse unbekannt")) .. "|r")
        row.meta:SetWidth(cardWidth - 300)
        row.guild:SetText(self:LocalizeDisplay("Gilde: ") .. U.SafeText(entry.guild, self:LocalizeDisplay("nicht erfasst")) ..
            (entry.guildRank and "  •  " .. entry.guildRank or ""))
        row.guild:SetWidth(cardWidth - 300)
        row.talents:SetText(self:LocalizeDisplay("Skillung: ") .. talentLabel(entry))
        row.talents:SetWidth(cardWidth - 300)
        local recent = entry.activities and entry.activities[1]
        row.event:SetText(recent and self:LocalizeEventText(recent.text or "") or
            self:LocalizeDisplay("Noch keine gemeinsamen Ereignisse erfasst."))
        row.event:SetWidth(cardWidth - 300)
        row.meetings:SetText(tostring(entry.meetings or 1))
        row.meetingsLabel:SetText(self:LocalizeDisplay("BEGEGNUNGEN"))
        row.meetingsLabel:SetWidth(116)
        row.open:SetText(self:LocalizeDisplay("ÖFFNEN >"))
        local rosterUpdated = (tonumber(entry.lastUpdated) or 0) > (tonumber(entry.lastSeen) or 0)
        row.seen:SetText(self.companionDemo and self:LocalizeDisplay("DEMO") or entry.inGroup and self:LocalizeDisplay("JETZT IN DEINER GRUPPE") or
            ((rosterUpdated and self:LocalizeDisplay("Gildenstand: ") or self:LocalizeDisplay("Zuletzt gesehen: ")) ..
                U.Date(rosterUpdated and entry.lastUpdated or entry.lastSeen, true)))
        row.seen:SetWidth(120)
        row.seen:SetShown(not self.companionDemo)
        row:Show()
    end
    for index = #entries + 1, #rows do rows[index]:Hide() end
    parent:SetHeight(math.max(340, 170 + math.ceil(#entries / columns) * 136))
end
