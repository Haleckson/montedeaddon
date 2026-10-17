local addonName, MCF = ...
-- Diagnostic-only module. Never modifies gameplay statistics.
local frame = CreateFrame("Frame")
local keys = {"professions", "combat", "dungeons", "other"}
local names = {professions="Professions", combat="Combat", dungeons="Dungeons", other="Other"}
local enabled, logs = {}, {}
local limit = 200
local window, editBox, statusText, detailCheck, craftCheck
local refreshPending = false
local recordChecks, filterChecks = {}, {}
local visible = {professions=true, combat=true, dungeons=true, other=true}
local localeDE = GetLocale and GetLocale() == "deDE"
local function L(de, en) return localeDE and de or en end
local gatherSpells = {[8617]=true, [2366]=true, [2575]=true, [7620]=true}
local pendingGatherUntil = 0
local craftDebug = false
local tradeSkillOpen = false
local lastCraftActionAt = 0
local lastCraftSpell = nil
local craftEvents = {TRADE_SKILL_SHOW=true, TRADE_SKILL_CLOSE=true, TRADE_SKILL_UPDATE=true, TRADE_SKILL_ITEM_CRAFTED_RESULT=true, TRADE_SKILL_ITEM_CRAFTED=true, UNIT_SPELLCAST_FAILED=true, UNIT_SPELLCAST_INTERRUPTED=true}
local detailed = false
local lastLootOpen = 0
local lastLootMessage = ""
local lastLootMessageAt = 0
local professionSkillWords = {"bergbau", "kürschnerei", "kraeuterkunde", "kräuterkunde", "angeln", "fischen", "alchemie", "schmiedekunst", "ingenieurskunst", "lederverarbeitung", "schneiderei", "verzauberkunst", "juwelenschleifen", "inschriftenkunde", "kochen", "erste hilfe", "mining", "skinning", "herbalism", "fishing", "alchemy", "blacksmithing", "engineering", "leatherworking", "tailoring", "enchanting", "jewelcrafting", "inscription", "cooking", "first aid"}
local function IsProfessionSkill(message)
    if type(message) ~= "string" then return false end
    if issecretvalue and issecretvalue(message) then return false end
    local low = string.lower(message)
    for _, word in ipairs(professionSkillWords) do
        if string.find(low, word, 1, true) then return true end
    end
    return false
end
local function ShortLine(line)
    -- Keep original lines untouched in SavedVariables; shorten only the display.
    local stamp, event, rest = line:match("^(%S+ %S+) (%S+)%s*(.*)$")
    if not stamp then return line end
    local spell = rest:match(" | (%d+) |") or rest:match(" | (%d+)$")
    local labels = {UNIT_SPELLCAST_START=L("Sammeln gestartet", "Gather started"), UNIT_SPELLCAST_SUCCEEDED=L("Sammeln erfolgreich", "Gather succeeded"),
      LOOT_OPENED=L("Beutefenster geöffnet", "Loot opened"), CHAT_MSG_LOOT=L("Beute erhalten", "Loot received"),
      CHAT_MSG_SKILL=L("Berufsfertigkeit erhöht", "Profession skill increased"), ENCOUNTER_START="Encounter start", ENCOUNTER_END="Encounter end"}
    local msg = labels[event] or event
    if event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_SKILL" then
        rest = rest:match("^(.-) |") or rest
        return stamp:sub(12) .. " | " .. msg .. " | " .. rest
    end
    if spell then return stamp:sub(12) .. " | " .. msg .. " | Spell " .. spell end
    if event == "LOOT_OPENED" then return stamp:sub(12) .. " | " .. msg end
    return stamp:sub(12) .. " | " .. msg .. (rest ~= "" and " | " .. rest:sub(1,65) or "")
end

local function Safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    if type(v)=="table" then
        local parts, n = {}, 0
        local ok = pcall(function()
            for k, item in pairs(v) do
                n = n + 1
                if n > 12 then parts[#parts+1] = "..."; break end
                if not (issecretvalue and (issecretvalue(k) or issecretvalue(item))) then
                    local value = type(item)=="table" and "<table>" or tostring(item)
                    parts[#parts+1] = tostring(k).."="..string.sub(value,1,60)
                else
                    parts[#parts+1] = "<secret>"
                end
            end
        end)
        if ok then return "{"..table.concat(parts, ", ").."}" end
        return "<unreadable table>"
    end
    local ok, s = pcall(tostring, v)
    if not ok then return "<unreadable>" end
    return string.sub(s, 1, 160)
end
local function DB()
    if type(MCFGatherDebugDB) ~= "table" then MCFGatherDebugDB = {} end
    MCFGatherDebugDB.categories = logs
    MCFGatherDebugDB.craftDebug = craftDebug
    return MCFGatherDebugDB
end
local function Add(category, event, ...)
    if not enabled[category] then return end
    local parts = {}
    for i=1,math.min(select("#", ...), 5) do parts[#parts+1] = Safe(select(i, ...)) end
    local stamp = date and date("%Y-%m-%d %H:%M:%S") or "?"
    local rows = logs[category]
    rows[#rows+1] = stamp .. " " .. event .. " " .. table.concat(parts, " | ")
    if #rows > limit then table.remove(rows, 1) end
    DB()
    if window and window:IsShown() and visible[category] then refreshPending = true end
end
-- External diagnostics can use the existing Combat debug stream.
function MCF:AddDeathRecapDebug(stage, status, count, killer, marked, details)
    Add("combat", "DEATH_RECAP_DIAG", stage, status, count, killer,
        "deadly="..tostring(marked).." "..tostring(details or ""))
end
local function ExportText()
    local lines = {"MyCharForever Debug Center", ""}
    local count = 0
    for _, key in ipairs(keys) do
        if visible[key] then
            local rows = logs[key] or {}
            count = count + #rows
            lines[#lines+1] = "=== " .. names[key] .. " (" .. #rows .. ") ==="
            for _, line in ipairs(rows) do lines[#lines+1] = detailed and line or ShortLine(line) end
            lines[#lines+1] = ""
        end
    end
    return table.concat(lines, "\n"), count
end
local function Refresh()
    if not window then return end
    for _, key in ipairs(keys) do
        if recordChecks[key] then recordChecks[key]:SetChecked(enabled[key] or false) end
        if filterChecks[key] then filterChecks[key]:SetChecked(visible[key] or false) end
    end
    if craftCheck then craftCheck:SetChecked(craftDebug) end
    local output, count = ExportText()
    statusText:SetText(L("Angezeigte Ereignisse: ", "Visible events: ") .. count)
    if not editBox:HasFocus() then
        local oldScroll = window.debugScroll and window.debugScroll:GetVerticalScroll() or 0
        editBox:SetText(output)
        if window.debugScroll then window.debugScroll:SetVerticalScroll(oldScroll) end
    end
end
local function ShowWindow()
    if not window then
        window = CreateFrame("Frame", "MCFDebugCenterWindow", UIParent, "BasicFrameTemplateWithInset")
        MCF.MakeOpaque(window,26)
        window:SetSize(840, 620)
        window:SetScript("OnUpdate", function(self, elapsed)
            self.debugRefreshElapsed = (self.debugRefreshElapsed or 0) + elapsed
            if refreshPending and self.debugRefreshElapsed >= 0.3 then
                self.debugRefreshElapsed = 0
                if not editBox or not editBox:HasFocus() then
                    refreshPending = false
                    Refresh()
                end
            end
        end)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetMovable(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window.TitleText:SetText("MyCharForever - Debug Center")

        local function Heading(text, y)
            local label = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOPLEFT", 22, y)
            label:SetText(text)
        end
        Heading(L("Aufzeichnen folgender Ereignisse", "Record these events"), -38)
        local function AddCheck(key, x, y, isRecording)
            local check = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", x, y)
            local label = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            local labels = {professions=L("Berufe", "Professions"), combat=L("Kampf", "Combat"), dungeons="Dungeons", other=L("Sonstiges", "Other")}
            label:SetText(labels[key])
            check:SetScript("OnClick", function(self)
                if isRecording then enabled[key] = self:GetChecked() and true or false
                else visible[key] = self:GetChecked() and true or false end
                Refresh()
            end)
            if isRecording then recordChecks[key]=check else filterChecks[key]=check end
        end
        for i, key in ipairs(keys) do AddCheck(key, 20 + (i-1)*195, -60, true) end
        Heading(L("Anzeige filtern (unabhängig von der Aufzeichnung)", "Display filters (independent of recording)"), -116)
        for i, key in ipairs(keys) do AddCheck(key, 20 + (i-1)*195, -138, false) end

        statusText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        statusText:SetPoint("TOPLEFT", 22, -186)
        local clearButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        clearButton:SetSize(190, 24)
        clearButton:SetPoint("TOPRIGHT", -22, -180)
        clearButton:SetText(L("Angezeigte Logs leeren", "Clear displayed logs"))
        clearButton:SetScript("OnClick", function()
            for _, key in ipairs(keys) do if visible[key] then logs[key] = {} end end
            DB()
            Refresh()
        end)
        detailCheck = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
        detailCheck:SetPoint("TOPLEFT", 18, -210)
        detailCheck:SetChecked(detailed)
        local detailLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        detailLabel:SetPoint("LEFT", detailCheck, "RIGHT", 3, 0)
        detailLabel:SetText(L("Technische Details anzeigen / kopieren", "Show / copy technical details"))
        detailCheck:SetScript("OnClick", function(self)
            detailed = self:GetChecked() and true or false
            Refresh()
        end)
        craftCheck = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
        craftCheck:SetPoint("TOPLEFT", 18, -244)
        local craftLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        craftLabel:SetPoint("LEFT", craftCheck, "RIGHT", 3, 0)
        craftLabel:SetText(L("Herstellung: Rohdiagnose (nur beim geöffneten Berufsfenster)", "Crafting: raw diagnostics (while profession window is open)"))
        craftCheck:SetScript("OnClick", function(self)
            craftDebug = self:GetChecked() and true or false
            DB()
            Refresh()
        end)
        local hint = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPRIGHT", -22, -218)
        hint:SetText(L("Strg+A / Strg+C zum Kopieren", "Ctrl+A / Ctrl+C to copy"))

        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        window.debugScroll = scroll
        scroll:SetPoint("TOPLEFT", 16, -282)
        scroll:SetPoint("BOTTOMRIGHT", -34, 15)
        editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(760)
        editBox:SetTextInsets(4,4,4,4)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnTextChanged", function(self) MCF.FitEditBox(self, 360) end)
        scroll:SetScrollChild(editBox)
    end
    Refresh()
    window:Show()
    editBox:SetFocus()
    editBox:HighlightText()
end
function MCF:OpenDebugCenter()
    ShowWindow()
end

for _, key in ipairs(keys) do logs[key]={} end
for _, event in ipairs({"TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","TRADE_SKILL_UPDATE","TRADE_SKILL_ITEM_CRAFTED_RESULT","TRADE_SKILL_ITEM_CRAFTED","CHAT_MSG_SYSTEM","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_STOP","LOOT_OPENED","LOOT_READY","LOOT_SLOT_CLEARED","LOOT_CLOSED","CHAT_MSG_LOOT","CHAT_MSG_SKILL","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_DEAD","UNIT_DIED","ENCOUNTER_START","ENCOUNTER_END","ENCOUNTER_LOOT_RECEIVED","LOOT_ROLLS_COMPLETE","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA"}) do
    pcall(function() frame:RegisterEvent(event) end)
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        local db = type(MCFGatherDebugDB)=="table" and MCFGatherDebugDB or {}
        if type(db.categories)=="table" then
            for _, key in ipairs(keys) do
                if type(db.categories[key])=="table" then
                    logs[key]=db.categories[key]
                    while #logs[key]>limit do table.remove(logs[key],1) end
                end
            end
        elseif type(db.events)=="table" then
            logs.professions=db.events
            while #logs.professions>limit do table.remove(logs.professions,1) end
        end
        craftDebug = db.craftDebug == true
        DB()
        return
    end
    if event == "TRADE_SKILL_SHOW" then
        tradeSkillOpen = true
        if craftDebug then Add("professions", event, ...) end
        return
    elseif event == "TRADE_SKILL_CLOSE" then
        if craftDebug then Add("professions", event, ...) end
        tradeSkillOpen = false
        return
    elseif event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" or event == "TRADE_SKILL_ITEM_CRAFTED" then
        if craftDebug and (tradeSkillOpen or GetTime()-lastCraftActionAt < 8) then Add("professions", event, ...) end
        return
    end
    local craftingContext = craftDebug and (tradeSkillOpen or (ProfessionsFrame and ProfessionsFrame.IsShown and ProfessionsFrame:IsShown()))
    if string.find(event,"UNIT_SPELLCAST",1,true) then
        local unit, castGUID, spellID = ...
        if issecretvalue and (issecretvalue(unit) or issecretvalue(spellID)) then return end
        if unit~="player" then return end
        if craftingContext then
            if event ~= "UNIT_SPELLCAST_STOP" then
                Add("professions", "CRAFT_RAW_"..event, ...)
            end
            if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
                lastCraftActionAt = GetTime()
                lastCraftSpell = spellID
            end
            return
        end
        if gatherSpells[spellID] then
            if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
                pendingGatherUntil = GetTime()+8
                Add("professions",event,...)
            end
        else
            Add("combat",event,...)
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        Add("other", event, ...)
    elseif event=="CHAT_MSG_SKILL" then
        local message = ...
        if IsProfessionSkill(message) then Add("professions",event,message) end
    elseif event=="CHAT_MSG_LOOT" or string.find(event,"LOOT_",1,true) then
        local now = GetTime()
        if now <= pendingGatherUntil then
            if event == "LOOT_OPENED" then
                if now - lastLootOpen > 0.3 then Add("professions",event,...); lastLootOpen = now end
            elseif event == "CHAT_MSG_LOOT" then
                local message = ...
                if type(message)=="string" and not (issecretvalue and issecretvalue(message)) then
                    if message ~= lastLootMessage or now - lastLootMessageAt > 1 then
                        Add("professions",event,message)
                        lastLootMessage, lastLootMessageAt = message, now
                    end
                end
            end
        end
        if event=="CHAT_MSG_LOOT" then
            if craftDebug and (craftingContext or GetTime()-lastCraftActionAt < 8) then
                local message = ...
                if type(message)=="string" and not (issecretvalue and issecretvalue(message)) then
                    local lower = string.lower(message)
                    if string.find(lower, "ihr stellt her", 1, true) or string.find(lower, "you create", 1, true) or string.find(lower, "you make", 1, true) then
                        Add("professions", "CRAFT_RAW_"..event, ...)
                    end
                end
            end
            Add("dungeons",event,...)
        end
    elseif event=="ENCOUNTER_START" or event=="ENCOUNTER_END" or event=="ENCOUNTER_LOOT_RECEIVED" or event=="LOOT_ROLLS_COMPLETE" then
        Add("dungeons",event,...)
    elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_DEAD" or event=="UNIT_DIED" then
        Add("combat",event,...)
    else
        Add("other",event,...)
    end
end)
local function Command(msg)
    local action, category = string.lower(msg or ""):match("^%s*(%S*)%s*(%S*)")
    if category=="gather" then category="professions" end
    if category=="" then category="professions" end
    local valid = logs[category] ~= nil
    if action=="craft" then
        if category=="on" or category=="off" then
            craftDebug = category=="on"
            DB(); Refresh()
            print("MyCharForever: crafting raw diagnostics " .. (craftDebug and "ON" or "OFF"))
        else print("MyCharForever: /mcfdebug craft on | off") end
        return
    end
    if action=="show" or action=="" then
        if valid then
            for _, key in ipairs(keys) do visible[key] = (key == category) end
        end
        ShowWindow()
    elseif action=="on" or action=="off" then
        if not valid then print("MyCharForever: category professions | combat | dungeons | other"); return end
        enabled[category]=(action=="on")
        print("MyCharForever: "..names[category].." diagnostics "..string.upper(action))
        Refresh()
    elseif action=="clear" then
        if valid then logs[category]={} else for _, key in ipairs(keys) do logs[key]={} end end
        DB(); Refresh()
        print("MyCharForever: diagnostics cleared.")
    else
        print("MyCharForever: /mcfdebug show | on | off | clear [professions|combat|dungeons|other] ; craft on|off")
    end
end
MCF:AddCommand{group="debug",usage="/mcfdebug show | on | off | clear [Bereich]",example="/mcfdebug clear combat",de="Debug-Center bedienen (Bereiche: professions, combat, dungeons, other)",en="Control the debug center (areas: professions, combat, dungeons, other)"}
MCF:AddCommand{group="debug",usage="/mcfgatherdebug on | off | show | clear",example="/mcfgatherdebug show",de="Sammel-/Berufe-Diagnose steuern",en="Control the gathering/professions diagnostics"}
SLASH_MCF_DEBUGCENTER1="/mcfdebug"
SlashCmdList.MCF_DEBUGCENTER=Command
SLASH_MCF_GATHERDEBUG1="/mcfgatherdebug"
SlashCmdList.MCF_GATHERDEBUG=function(msg)
    local action=string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if action=="on" or action=="off" or action=="clear" or action=="show" then
        Command(action.." professions")
    else
        print("MyCharForever: /mcfgatherdebug on | off | show | clear")
    end
end
