local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.isReady = false

-- =========================
-- PER-CHARACTER DATABASE INIT
-- =========================
-- FieldJournalDB is per-character because FieldJournal.toc uses:
-- ## SavedVariablesPerCharacter: FieldJournalDB

FieldJournalDB = FieldJournalDB or {}

FieldJournalDB.subjects = FieldJournalDB.subjects or {}
FieldJournalDB.encounters = FieldJournalDB.encounters or {}
FieldJournalDB.zones = FieldJournalDB.zones or {}
FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}
FieldJournalDB.config = FieldJournalDB.config or {}
FieldJournalDB.chronicle = FieldJournalDB.chronicle or {}

FieldJournal_LoreDB = FieldJournal_LoreDB or {}
FieldJournal_ZoneDB = FieldJournal_ZoneDB or {}
FieldJournal_QuestDB = FieldJournal_QuestDB or {}

-- Display names for the native Key Bindings > AddOns entries.
BINDING_HEADER_FIELDJOURNAL = "Field Journal"
BINDING_NAME_FIELDJOURNAL_OBSERVE = "Start Observation"
BINDING_NAME_FIELDJOURNAL_SCOPE = "Observation: Scope"
BINDING_NAME_FIELDJOURNAL_SKETCH = "Observation: Field Sketch"
BINDING_NAME_FIELDJOURNAL_TRAP = "Observation: Set Trap"

-- =========================
-- SLASH COMMAND
-- =========================
SLASH_FIELDJOURNAL1 = "/fj"

SlashCmdList["FIELDJOURNAL"] = function(msg)
    local command = string.lower((msg or ""):match("^%s*(.-)%s*$"))

    if command == "soundtest" then
        local ui = FieldJournal.UI
        if not ui or not ui.PlayJournalSound then
            print("|cff33ff99[Field Journal]|r Sound system is unavailable.")
            return
        end
        print("|cff33ff99[Field Journal]|r Testing open, close, button, and page sounds (build 40).")
        for index, kind in ipairs({ "open", "close", "button", "page" }) do
            local function Test()
                local played, api, id = ui:PlayJournalSound(kind)
                print("|cff33ff99[Field Journal]|r " .. kind .. " (" .. tostring(id) .. "): "
                    .. (played and "accepted via " or "failed: ") .. tostring(api))
            end
            if C_Timer and C_Timer.After then
                C_Timer.After((index - 1) * 0.8, Test)
            else
                Test()
            end
        end
        return
    end

    if command == "menuart" then
        local menu = _G.GameMenuFrame
        if not menu then
            print("|cff33ff99[Field Journal]|r Open the Game Menu once, close it, then use /fj menuart.")
            return
        end
        local found
        local function FindButton(widget, depth)
            if found or not widget or depth > 6 then return end
            if widget.GetObjectType and widget:GetObjectType() == "Button"
                and widget.GetText and (widget:GetText() == "Options" or widget:GetText() == "AddOns") then
                found = widget
                return
            end
            if widget.GetChildren then
                for _, child in ipairs({ widget:GetChildren() }) do FindButton(child, depth + 1) end
            end
        end
        FindButton(menu, 0)
        if not found then
            print("|cff33ff99[Field Journal]|r No Game Menu button was found on this client.")
            return
        end
        local function Asset(texture)
            if not texture then return "none" end
            local atlas = texture.GetAtlas and texture:GetAtlas()
            local path = texture.GetTexture and texture:GetTexture()
            if atlas then return "atlas:" .. atlas end
            return path and ("texture:" .. tostring(path)) or "none"
        end
        print("|cff33ff99[Field Journal]|r Game Menu " .. found:GetText() .. " button:")
        print("normal: " .. Asset(found:GetNormalTexture()))
        print("pressed: " .. Asset(found:GetPushedTexture()))
        print("disabled: " .. Asset(found:GetDisabledTexture()))
        print("highlight: " .. Asset(found:GetHighlightTexture()))
        local regions, seen = {}, {}
        local function ScanRegions(widget, depth)
            if depth > 5 then return end
            if widget.GetRegions then
                for _, region in ipairs({ widget:GetRegions() }) do
                    if region.GetObjectType and region:GetObjectType() == "Texture" then
                        local name = Asset(region)
                        if name ~= "none" and not seen[name] then
                            seen[name] = true
                            regions[#regions + 1] = name
                        end
                    end
                end
            end
            if widget.GetChildren then
                for _, child in ipairs({ widget:GetChildren() }) do
                    ScanRegions(child, depth + 1)
                end
            end
        end
        ScanRegions(found, 0)
        print("button art regions (" .. #regions .. "):")
        for i = 1, math.min(#regions, 15) do print(i .. ". " .. regions[i]) end
        return
    end

    if command == "art" then
        local book = _G.SpellBookFrame or _G.PlayerSpellsFrame
        if not book or not book:IsShown() then
            print("|cff33ff99[Field Journal]|r Open the spellbook, then use /fj art to list its visible page textures.")
            return
        end
        local found = {}
        local function Scan(widget, depth)
            if depth > 8 or not widget or not widget.IsShown or not widget:IsShown() then return end
            if widget.GetRegions then
                for _, region in ipairs({ widget:GetRegions() }) do
                    if region.GetObjectType and region:GetObjectType() == "Texture"
                        and region:IsShown() and region:GetWidth() >= 100 and region:GetHeight() >= 100 then
                        local atlas = region.GetAtlas and region:GetAtlas()
                        local path = atlas or (region.GetTexture and region:GetTexture())
                        if path then
                            found[#found + 1] = {
                                area = region:GetWidth() * region:GetHeight(),
                                name = (atlas and "atlas:" or "texture:") .. tostring(path),
                            }
                        end
                    end
                end
            end
            if widget.GetChildren then
                for _, child in ipairs({ widget:GetChildren() }) do Scan(child, depth + 1) end
            end
        end
        Scan(book, 0)
        table.sort(found, function(a, b) return a.area > b.area end)
        print("|cff33ff99[Field Journal]|r Spellbook large textures (" .. #found .. "):")
        for i = 1, math.min(#found, 10) do print(i .. ". " .. found[i].name) end
        return
    end

    if command == "snapshot" then
        local chronicle = FieldJournal.ChronicleSystem
        local widgets = FieldJournal.UI and FieldJournal.UI.Widgets
        if not chronicle or not chronicle.CaptureTestAppearance
            or not widgets or not widgets.PreviewAppearanceSnapshot then
            print("|cff33ff99[Field Journal]|r Snapshot preview is not ready.")
            return
        end

        local snapshot = chronicle:CaptureTestAppearance()
        if widgets:PreviewAppearanceSnapshot(snapshot) then
            print("|cff33ff99[Field Journal]|r Test portrait captured at level "
                .. tostring(snapshot.level) .. ". No milestone was recorded.")
        else
            print("|cff33ff99[Field Journal]|r Model preview is unavailable on this client.")
        end
        return
    end

    if command == "beta" then
        local compat = FieldJournal.Compat
        local guid = compat and compat:UnitGUID("target")
        local npcID = guid and compat:GetNPCID(guid)
        local name = compat and compat:UnitName("target")
        local subjectID = npcID and FieldJournal.SubjectIndex
            and FieldJournal.SubjectIndex:Get(npcID, GetRealZoneText())
        print("|cff33ff99[Field Journal]|r Build: " .. tostring(select(4, GetBuildInfo()))
            .. "; kill source: " .. (compat and compat.isForever and "PARTY_KILL" or "combat log"))
        print("|cff33ff99[Field Journal]|r Target: " .. (name or "unavailable")
            .. "; NPC ID: " .. (npcID and tostring(npcID) or "unavailable")
            .. "; subject: " .. (subjectID or "unmapped"))
        print("|cff33ff99[Field Journal]|r Zone: " .. (GetRealZoneText() or "unknown")
            .. "; subzone: " .. (GetSubZoneText() or "unknown"))
        return
    end

    if command == "scale" or command:match("^scale%s") then
        local journal = FieldJournal.UI and FieldJournal.UI.JournalFrame
        local config = FieldJournal.Config
        local requested = command:match("^scale%s+([%d%.]+)$")
        if command ~= "scale" and (not requested or not config:SetJournalScale(requested)) then
            print("|cff33ff99[Field Journal]|r Use /fj scale 1.2 (range 0.8 to 1.6).")
            return
        end
        local saved = config:GetJournalScale()
        local applied = journal and journal.ApplyJournalScale and journal:ApplyJournalScale()
        print("|cff33ff99[Field Journal]|r Journal scale: " .. tostring(saved)
            .. (applied and applied < saved and " (limited to fit the screen)" or "")
            .. ". Use /fj scale 0.8 to 1.6 to adjust it.")
        return
    end

    if command == "debug"
        or command == "debug on"
        or command == "debug off"
        or command == "debug status" then

        FieldJournal.Config = FieldJournal.Config or {}

        local enabled = FieldJournal.Config.debug and true or false

        if command == "debug" then
            enabled = not enabled
        elseif command == "debug on" then
            enabled = true
        elseif command == "debug off" then
            enabled = false
        end

        if command ~= "debug status" then
            if FieldJournal.Config.SetDebug then
                enabled = FieldJournal.Config:SetDebug(enabled)
            else
                FieldJournal.Config.debug = enabled
                FieldJournalDB = FieldJournalDB or {}
                FieldJournalDB.config = FieldJournalDB.config or {}
                FieldJournalDB.config.debug = enabled
            end
        end

        print("|cff33ff99[Field Journal]|r Debug output is " .. (enabled and "ON" or "OFF") .. ".")
        return
    end

    if FieldJournal.UI
        and FieldJournal.UI.JournalFrame
        and FieldJournal.UI.JournalFrame.Toggle then

        FieldJournal.UI.JournalFrame:Toggle()
    else
        print("|cffcc0000[FieldJournal]|r Journal UI is not loaded.")
    end
end

-- =========================
-- INITIALIZATION
-- =========================
local function Initialize()
    if FieldJournal.DataManager and FieldJournal.DataManager.Init then
        FieldJournal.DataManager:Init()
    else
        print("|cffcc0000[FieldJournal]|r DataManager missing.")
    end

    if FieldJournal.SubjectIndex and FieldJournal.SubjectIndex.Build then
        FieldJournal.SubjectIndex:Build()
        if FieldJournal.SubjectIndex.RepairSavedSubjects then
            FieldJournal.SubjectIndex:RepairSavedSubjects()
        end
    else
        print("|cffcc0000[FieldJournal]|r SubjectIndex missing.")
    end

    if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.Init then
        FieldJournal.ChronicleSystem:Init()
    else
        print("|cffcc0000[FieldJournal]|r ChronicleSystem missing.")
    end

    FieldJournal.isReady = true

    if FieldJournal.ZoneSystem and FieldJournal.ZoneSystem.Init then
        FieldJournal.ZoneSystem:Init()
    else
        print("|cffcc0000[FieldJournal]|r ZoneSystem missing.")
    end

    if FieldJournal.QuestSystem and FieldJournal.QuestSystem.Init then
        FieldJournal.QuestSystem:Init()
    else
        print("|cffcc0000[FieldJournal]|r QuestSystem missing.")
    end

    if FieldJournal.Events and FieldJournal.Events.Init then
        FieldJournal.Events:Init()
    else
        print("|cffcc0000[FieldJournal]|r Events system missing.")
    end

    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.Init then
        FieldJournal.ObserveSystem:Init()
    end

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r System ready.")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()
    Initialize()
    local config = FieldJournalDB.config
    if config.journalOpenedOnFirstLaunch then return end
    local function OpenFirstPage()
        local journal = FieldJournal.UI and FieldJournal.UI.JournalFrame
        if not journal then return end
        if not journal:IsShown() then
            journal:Show()
            journal:ShowLanding()
        end
        config.journalOpenedOnFirstLaunch = true
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(1, OpenFirstPage)
    else
        OpenFirstPage()
    end
end)
