local ADDON_NAME, GQ = ...

if not strtrim then
    function strtrim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
end

GQ = GQ or {}
_G.GearQuest = GQ

GQ.VERSION = "0.3.2-beta"
GQ.ADDON_NAME = ADDON_NAME
-- WoW Forever: 1–60 Classic+ (no TBC level cap).
GQ.MAX_PLAYER_LEVEL = 60

-- Forever's Interface 16001 client namespaced item APIs (10.2.6+). The old
-- globals can be nil and would crash PLAYER_LOGIN at Equip.lua:PrimeItem.
do
    local item = C_Item
    if item then
        if type(GetItemInfo) ~= "function" and item.GetItemInfo then
            GetItemInfo = item.GetItemInfo
        end
        if type(GetItemInfoInstant) ~= "function" and item.GetItemInfoInstant then
            GetItemInfoInstant = item.GetItemInfoInstant
        end
        if type(GetItemStats) ~= "function" and item.GetItemStats then
            GetItemStats = item.GetItemStats
        end
        if type(GetItemIcon) ~= "function" and (item.GetItemIconByID or item.GetItemIcon) then
            GetItemIcon = item.GetItemIconByID or item.GetItemIcon
        end
        if type(GetItemQualityColor) ~= "function" and item.GetItemQualityColor then
            GetItemQualityColor = item.GetItemQualityColor
        end
        if type(IsEquippableItem) ~= "function" and item.IsEquippableItem then
            IsEquippableItem = item.IsEquippableItem
        end
        if type(GetItemCount) ~= "function" and item.GetItemCount then
            GetItemCount = item.GetItemCount
        end
        if type(GetItemFamily) ~= "function" and item.GetItemFamily then
            GetItemFamily = item.GetItemFamily
        end
    end
    if type(GetItemQualityColor) ~= "function" then
        GetItemQualityColor = function(quality)
            local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
            if c then
                return c.r, c.g, c.b
            end
            return 1, 1, 1
        end
    end
end

-- Forever dropped some Classic events (TRADE_SKILL_UPDATE, CRAFT_*). Registering
-- an unknown event throws and would abort the rest of PLAYER_LOGIN (no minimap).
function GQ.RegisterEvent(frame, event)
    if not frame or not event or type(frame.RegisterEvent) ~= "function" then
        return false
    end
    return pcall(frame.RegisterEvent, frame, event)
end

-- Forever/Midnight can mark tooltip FontString text as a secret string.
-- Comparing or pattern-matching that value while tainted throws.
function GQ.PublicText(value)
    if value == nil then
        return nil
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return nil
        end
    end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and not accessible then
            return nil
        end
    end
    local ok, public = pcall(function()
        return type(value) == "string" and value ~= "" and value or nil
    end)
    if not ok then
        return nil
    end
    return public
end

function GQ:ClampPlayerLevel(level)
    level = tonumber(level) or 1
    level = math.floor(level)
    if level < 1 then
        return 1
    end
    if level > self.MAX_PLAYER_LEVEL then
        return self.MAX_PLAYER_LEVEL
    end
    return level
end

-- Forever can inject SavedVariables into _G while addon code holds a separate
-- empty table if we assign defaults too early. Always read/write _G explicitly.
function GQ:BindSavedVariableGlobals()
    -- Never fabricate empty SavedVariables tables here — that runs before the
    -- client merges WTF data and can shadow saved hunt/obtained keys on reload.
    if type(_G.GearQuestForeverDB) == "table" then
        GearQuestForeverDB = _G.GearQuestForeverDB
    elseif type(GearQuestForeverDB) == "table" then
        _G.GearQuestForeverDB = GearQuestForeverDB
    end
    if type(_G.GearQuestForeverCharDB) == "table" then
        GearQuestForeverCharDB = _G.GearQuestForeverCharDB
    elseif type(GearQuestForeverCharDB) == "table" then
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
end

-- forceCreate: never pass true before SavedVariables have had a chance to load.
function GQ:EnsureSavedVariableDefaults(forceCreate)
    self:BindSavedVariableGlobals()
    if type(GearQuestForeverDB) ~= "table" then
        if not forceCreate then
            return false
        end
        _G.GearQuestForeverDB = {}
        GearQuestForeverDB = _G.GearQuestForeverDB
    end
    if type(GearQuestForeverCharDB) ~= "table" then
        if forceCreate then
            _G.GearQuestForeverCharDB = {}
            GearQuestForeverCharDB = _G.GearQuestForeverCharDB
        end
    end
    GearQuestForeverDB.hunts = GearQuestForeverDB.hunts or {}
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
    return true
end

local svBindFrame = CreateFrame("Frame")
svBindFrame:RegisterEvent("ADDON_LOADED")
pcall(function()
    svBindFrame:RegisterEvent("VARIABLES_LOADED")
end)
svBindFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= GQ.ADDON_NAME then
        return
    end
    GQ:BindSavedVariableGlobals()
end)

local SOURCE_LABELS = {
    world_drop = "World drop",
    rare_npc = "Rare NPC",
    boss_drop = "Boss drop",
    raid_trash = "Raid trash",
    quest_reward = "Quest reward",
    seasonal_quest = "Seasonal quest",
    vendor = "Vendor",
    profession = "Profession",
    auction_house = "Auction House",
    object_drop = "Container",
    special = "Special",
}

local SOURCE_COLORS = {
    world_drop = "|cff66ccff",
    rare_npc = "|cff8899dd",
    boss_drop = "|cffff4444",
    raid_trash = "|cffcc9966",
    quest_reward = "|cff00ff00",
    seasonal_quest = "|cffff8800",
    vendor = "|cffffcc00",
    profession = "|cffcc66ff",
    auction_house = "|cffffa500",
}

local SOURCE_ALIAS = {
    -- Fishing and skinning are professions. The filter checkbox is Profession.
    fishing = "profession",
    skinning = "profession",
    -- Looted from a container. The checkbox id is object_drop.
    container = "object_drop",
    mail = "special",
    pickpocket = "special",
}

function GQ:NormalizeSourceType(sourceType)
    return SOURCE_ALIAS[sourceType] or sourceType
end

function GQ:GetSourceLabel(sourceType)
    sourceType = self:NormalizeSourceType(sourceType)
    return SOURCE_LABELS[sourceType] or sourceType
end

function GQ:GetSourceTag(sourceType)
    sourceType = self:NormalizeSourceType(sourceType)
    local color = SOURCE_COLORS[sourceType] or "|cffcccccc"
    return color .. (SOURCE_LABELS[sourceType] or sourceType) .. "|r"
end

function GQ:PLAYER_LOGIN()
    local function run(label, fn)
        local ok, err = pcall(fn)
        if not ok then
            print("|cffff0000GearQuest|r: " .. label .. " failed: " .. tostring(err))
        end
        return ok
    end

    run("startup", function()
        self:BindSavedVariableGlobals()
        self:EnsureSavedVariableDefaults(true)
        GearQuestForeverDB.suffixLinks = nil
        GearQuestForeverDB.suffixLinksVersion = nil
        self.Preview:MigrateSettings()
        self.Preview:OnPlayerLogin()
        if self.Spec and self.Spec.OnPlayerLogin then
            self.Spec:OnPlayerLogin()
        end
        if self.Data.EnsureActiveHuntClasses then
            self.Data:EnsureActiveHuntClasses()
        end
        self.Data:BuildIndex()
        self.Data:CacheContainerItemLinks()
    end)

    run("Indicator", function() self.Indicator:Init() end)
    run("Log", function() self.Log:Init() end)
    run("spec-ui", function()
        if self.Log and self.Log.UpdateSpecButton then
            self.Log:UpdateSpecButton()
        end
        if C_Timer and C_Timer.After and self.Log and self.Log.UpdateSpecButton then
            C_Timer.After(0.5, function()
                if GQ.Log and GQ.Log.UpdateSpecButton then
                    GQ.Log:UpdateSpecButton()
                end
            end)
        end
    end)
    run("Toast", function() self.Toast:Init() end)
    run("Tracker", function() self.Tracker:Init() end)
    run("Popup", function() self.Popup:Init() end)
    run("PaperDoll", function() self.PaperDoll:Init() end)
    run("Minimap", function() self.Minimap:Init() end)
    run("Commands", function() self.Commands:Init() end)

    local previewNote = self.Preview:IsEnabled() and (" (" .. self:GetPreviewLabel() .. ")") or ""
    print("|cff66ccffGearQuest|r v" .. self.VERSION .. " By Weber8210 loaded" .. previewNote .. ". Right-click a gear slot on your character panel, or |cff00ff00/gq|r.")
    print("|cff66ccffGearQuest|r: Click the minimap icon to open GearQuest.")
    -- Login and /reload only print the welcome lines above. Milestone chat
    -- belongs to a real level-up, and a character already past that level
    -- is marked seen so a later check cannot repeat it.
    run("milestones", function()
        self:RememberMilestonesAlreadyPassed(self:GetEffectiveLevel())
    end)
    if self.Log and self.Log.ScheduleAutoCompletionCheck then
        run("auto-complete", function()
            self.Log:ScheduleAutoCompletionCheck()
        end)
    end
end

function GQ:SyncLevelOverride()
    if not self._playerLevelOverride then
        return
    end
    if self:IsPreviewEnabled() then
        self._playerLevelOverride = nil
        return
    end
    local actual = UnitLevel("player")
    if actual and actual >= self._playerLevelOverride then
        self._playerLevelOverride = nil
    end
end

function GQ:GetEffectiveLevel()
    self:SyncLevelOverride()
    if self._playerLevelOverride and not self:IsPreviewEnabled() then
        return self:ClampPlayerLevel(self._playerLevelOverride)
    end
    return self:ClampPlayerLevel(self.Preview:GetEffectiveLevel())
end

function GQ:RefreshUI(opts)
    opts = opts or {}
    if self._refreshScheduled then
        self._refreshPending = true
        return
    end

    self._refreshScheduled = true
    self._refreshPending = false

    local function finishRefresh()
        self._refreshScheduled = false
        if self._refreshPending then
            self._refreshPending = false
            self:RefreshUI(opts)
        end
    end

    local function runHeavy()
        local function afterIndicatorCache()
            if self.Log and self.Log.frame then
                pcall(function()
                    if self.Log.UpdateContextStatus then
                        self.Log:UpdateContextStatus()
                    end
                end)
                if self.Log.frame:IsShown() then
                    pcall(function()
                        if self.Log.ScheduleListRefresh then
                            self.Log:ScheduleListRefresh()
                        else
                            self.Log:Refresh()
                        end
                    end)
                end
            end

            if self.Popup and self.Popup.container and self.Popup.container:IsShown() then
                pcall(function()
                    if self.Popup.activeSlotName and self.Popup.activeSlotButton then
                        self.Popup:ShowForSlot(self.Popup.activeSlotName, self.Popup.activeSlotButton)
                    else
                        self.Popup:Hide()
                    end
                end)
            end

            if self.Tracker then
                pcall(function()
                    self.Tracker:Refresh()
                end)
            end

            finishRefresh()
        end

        if self.Indicator then
            pcall(function()
                if self.Indicator.RebuildCacheAsync then
                    self.Indicator:RebuildCacheAsync(afterIndicatorCache)
                else
                    self.Indicator:RebuildCache()
                    self.Indicator:RefreshAll()
                    afterIndicatorCache()
                end
            end)
        else
            afterIndicatorCache()
        end
    end

    if self.Log then
        pcall(function()
            if self.Log.UpdateSpecButton then
                self.Log:UpdateSpecButton()
            end
            if self.Log.frame and self.Log.frame:IsShown() and self.Log.UpdateFooterButtons then
                self.Log:UpdateFooterButtons()
            end
        end)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, runHeavy)
    else
        runHeavy()
    end
end

function GQ:MilestoneTables()
    self:BindSavedVariableGlobals()
    GearQuestForeverCharDB.milestones = GearQuestForeverCharDB.milestones or {}
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.milestones = GearQuestForeverDB.settings.milestones or {}
    return GearQuestForeverCharDB.milestones, GearQuestForeverDB.settings.milestones
end

function GQ:MilestoneSeen(key)
    local char, account = self:MilestoneTables()
    if key == "ringSlot1" and (char.ringSlots or account.ringSlots) then
        char.ringSlot1 = true
        account.ringSlot1 = true
    end
    return char[key] or account[key]
end

function GQ:MarkMilestone(key)
    local char, account = self:MilestoneTables()
    char[key] = true
    account[key] = true
end

function GQ:NotifyMilestoneOnce(key, message)
    if self:MilestoneSeen(key) then
        self:MarkMilestone(key)
        return
    end

    self:MarkMilestone(key)
    print(message)
end

-- A character who logs in already past a milestone has had their chance.
-- Record it without printing. Welcome chat is the only login message.
function GQ:RememberMilestonesAlreadyPassed(level)
    level = tonumber(level)
    if not level then
        return
    end

    if level >= 10 then
        self:MarkMilestone("specSwitch")
    end

    local fingerUnlock = 9
    if GQ.Data and GQ.Data.GetSlotUnlockLevel then
        fingerUnlock = GQ.Data:GetSlotUnlockLevel("Finger") or fingerUnlock
    end
    if level >= fingerUnlock then
        self:MarkMilestone("ringSlot1")
    end

    local ringSlot2Level = GQ.Data and GQ.Data.RING_SLOT_2_MILESTONE_LEVEL
    if ringSlot2Level and level >= ringSlot2Level then
        self:MarkMilestone("ringSlot2")
    end
end

function GQ:CheckLevelMilestones(previousLevel, newLevel)
    -- Slot unlock messages — see docs/DATA_RULES.md § Slot unlock & level-up messages.
    -- Only when the player crosses the level. Login must not call this.
    if not newLevel or not previousLevel or newLevel <= previousLevel then
        return
    end

    -- Finger milestones follow this character's hunts, not the Alliance paladin
    -- level-9 band. Horde shaman has no Finger rows until later; do not toast an empty slot.
    local fingerHunts = GQ.Data and GQ.Data.GetTopUpgradesForSlot and GQ.Data:GetTopUpgradesForSlot("Finger", 3)
    local fingerCount = fingerHunts and #fingerHunts or 0
    local fingerUnlock = 9
    if GQ.Data and GQ.Data.GetSlotUnlockLevel then
        fingerUnlock = GQ.Data:GetSlotUnlockLevel("Finger") or fingerUnlock
    end
    if fingerCount > 0 and previousLevel < fingerUnlock and newLevel >= fingerUnlock then
        self:NotifyMilestoneOnce(
            "ringSlot1",
            "|cff66ccffGearQuest|r: You've reached level " .. newLevel .. " — one of your ring slots is now eligible for an upgrade! Open |cff00ff00/gq log|r to browse finger upgrades."
        )
    end
    local ringSlot2Level = GQ.Data and GQ.Data.RING_SLOT_2_MILESTONE_LEVEL
    if fingerCount >= 2 and ringSlot2Level and previousLevel < ringSlot2Level and newLevel >= ringSlot2Level then
        self:NotifyMilestoneOnce(
            "ringSlot2",
            "|cff66ccffGearQuest|r: You've reached level " .. newLevel .. " — your other ring slot is now eligible for an upgrade! Open |cff00ff00/gq log|r to browse finger upgrades."
        )
    end

    -- Level 10: talent specs — log button and /gq spec filter gear lists.
    if newLevel >= 10 and previousLevel < 10 then
        local classFile = GQ:GetEffectiveClass()
        if GQ.Spec and GQ.Spec.HasSpecs and GQ.Spec:HasSpecs(classFile) then
            local defaultLabel = GQ.Spec:GetSpecLabel(GQ.Spec:GetDefaultSpec(classFile), classFile) or "your default spec"
            self:NotifyMilestoneOnce(
                "specSwitch",
                "|cff66ccffGearQuest|r: Congratulations — you've reached level 10! Specializations are now available in GearQuest. Open |cff00ff00/gq log|r to browse spec-specific upgrades; |cff00ff00"
                    .. defaultLabel
                    .. "|r is selected by default."
            )
        end
    end
end

function GQ:PLAYER_LEVEL_UP(_, newLevel)
    local previousLevel = newLevel and (newLevel - 1) or nil
    if newLevel and not self:IsPreviewEnabled() then
        self._playerLevelOverride = newLevel
    end
    if self.Data and self.Data.InvalidateQueryCache then
        self.Data:InvalidateQueryCache()
    end
    self:CheckLevelMilestones(previousLevel, newLevel)
    if self.Log and self.Log.CheckAutoCompletion then
        self.Log:CheckAutoCompletion()
    end
    self:RefreshUI()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        GQ:PLAYER_LOGIN()
    elseif event == "PLAYER_LEVEL_UP" then
        GQ:PLAYER_LEVEL_UP(event, ...)
    end
end)
