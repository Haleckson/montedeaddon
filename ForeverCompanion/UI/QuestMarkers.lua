--[[
  Forever Companion - UI/QuestMarkers.lua
  A marker above the nameplate of every creature one of your active quests
  still needs you to fight (to kill it or loot it); a friendly NPC a quest
  sends you to talk to keeps the game's own marks. Only quests in your quest
  log count, and an objective you have finished stops showing it.

  The game tells us through the unit's tooltip data (quest objective lines,
  with their completion) or, when those are not readable, through
  C_QuestLog.UnitIsRelatedToActiveQuest. When the client keeps both secret
  (combat, restricted content) a marker keeps its last state until the
  answer is readable again.
]]

local _, FC = ...

local Markers = FC:NewModule("QuestMarkers")

local Compat = FC.Compat
local U = FC.Utils

-- the brass exclamation mark (64x128, as tall as two of its widths); the
-- gold diamond stays as the fallback if the client cannot load it
local LEGACY_TEXTURE = FC.C.MEDIA .. "QuestMarker"
local LEGACY_SIZE = 24
local MARK_HEIGHT = 30

Markers.byPlate = {}

--- Whether a nameplate unit is needed by an active quest: true / false, or
--- nil when the client does not say; and the unit's tooltip lines, when
--- readable (they also teach which quests the creature is needed for).
function Compat.IsQuestUnit(unit)
    if Compat.SafeCall(_G.UnitIsPlayer, unit) then return false end
    local answer, lines
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
        local types = Enum and Enum.TooltipDataLineType
        local objectiveType = types and types.QuestObjective
        if ok and type(data) == "table" and type(data.lines) == "table" then
            lines = data.lines
            for _, line in ipairs(objectiveType and lines or {}) do
                if Compat.Safe(line.type) == objectiveType then
                    local completed = Compat.Safe(line.completed)
                    if completed == false then answer = true end
                    if completed == true and answer == nil then answer = false end
                end
            end
        end
    end
    if answer ~= nil then return answer, lines end
    local Q = C_QuestLog
    if Q and Q.UnitIsRelatedToActiveQuest then
        local ok, related = pcall(Q.UnitIsRelatedToActiveQuest, unit)
        related = ok and Compat.Safe(related)
        if related ~= nil then return related and true or false, lines end
    end
    return nil, lines
end

local function plateFor(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and type(plate) == "table" then return plate end
    return nil
end

local function createMarker(plate)
    local marker = CreateFrame("Frame", nil, plate)
    marker.icon = marker:CreateTexture(nil, "OVERLAY")
    marker.icon:SetAllPoints()
    marker.brass = Markers:ApplyTexture(marker.icon)
    local bob = marker:CreateAnimationGroup()
    bob:SetLooping("BOUNCE")
    local move = bob:CreateAnimation("Translation")
    move:SetOffset(0, 3)
    move:SetDuration(0.9)
    move:SetSmoothing("IN_OUT")
    marker.bob = bob
    marker:Hide()
    return marker
end

--- Puts the marker's picture on a texture; true for the brass mark.
function Markers:ApplyTexture(texture)
    if FC.Skin:SetFile(texture, FC.Skin.ASSETS.questMarker.path) then return true end
    texture:SetTexture(LEGACY_TEXTURE)
    return false
end

--- Width and height of the marker at a size setting (1 = 100%).
function Markers:MarkerSize(scale, brass)
    scale = scale or 1
    if brass == false then return LEGACY_SIZE * scale, LEGACY_SIZE * scale end
    return MARK_HEIGHT * scale / 2, MARK_HEIGHT * scale
end

function Markers:Style(marker)
    local P = FC.P.nameplates
    marker:SetSize(self:MarkerSize(P.markerScale, marker.brass))
    marker:ClearAllPoints()
    -- above the head: over the name, which sits at the top of the plate
    marker:SetPoint("BOTTOM", marker:GetParent(), "TOP", 0, 2)
    if FC.UI.AnimationsEnabled() then
        if not marker.bob:IsPlaying() then marker.bob:Play() end
    else
        marker.bob:Stop()
    end
end

--- Markers step aside while you fight (a setting), and come back after.
function Markers:Hidden()
    local P = FC.P.nameplates
    return not P.questMarker or (P.hideInCombat and (self.inCombat or Compat.InCombat()))
end

function Markers:HideAll()
    for _, marker in pairs(self.byPlate) do
        marker:Hide()
        marker.bob:Stop()
    end
end

--- When the client keeps the unit's quest lines to itself: the reference
--- data knows which quests need this creature; one of them in progress in
--- your quest log is enough. nil when there is nothing to go by.
function Markers:ReferenceSays(unit)
    local info = Compat.GetUnitInfo(unit)
    if not info or info.isPlayer or not info.npcID then return nil end
    local quests = FC.Reference:QuestsTargeting(info.npcID)
    if #quests == 0 then return nil end
    for _, questID in ipairs(quests) do
        if Compat.GetQuestStatus(questID) == "active" then return true end
    end
    return false
end

function Markers:Update(unit)
    local plate = plateFor(unit)
    if not plate then return end
    local marker = self.byPlate[plate]
    local needed, lines = Compat.IsQuestUnit(unit)
    if lines then FC.QuestLore:LearnFromUnit(unit, lines) end
    if self:Hidden() then
        if marker then
            marker:Hide()
            marker.bob:Stop()
        end
        return
    end
    if needed == nil then needed = self:ReferenceSays(unit) end
    if needed == nil then return end -- nobody is telling right now
    -- only creatures you fight (unknown counts as yes: the client may hide it)
    if needed and Compat.SafeCall(_G.UnitCanAttack, "player", unit) == false then needed = false end
    if needed then
        if not marker then
            marker = createMarker(plate)
            self.byPlate[plate] = marker
        end
        self:Style(marker)
        marker:Show()
    elseif marker then
        marker:Hide()
        marker.bob:Stop()
    end
end

function Markers:Remove(unit)
    local plate = plateFor(unit)
    local marker = plate and self.byPlate[plate]
    if marker then
        marker:Hide()
        marker.bob:Stop()
    end
end

--- Re-checks every visible nameplate (the quest log changed).
function Markers:UpdateAll()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if type(unit) == "string" then FC:SafeCall("QuestMarkers:Update", self.Update, self, unit) end
    end
end

function Markers:QueueUpdateAll()
    U.Debounce("quest-markers", 0.3, function() self:UpdateAll() end)
end

function Markers:OnEnable()
    local Events = FC.Events
    Events:Register("NAME_PLATE_UNIT_ADDED", self, function(_, _, unit)
        if type(unit) == "string" then self:Update(unit) end
    end)
    Events:Register("NAME_PLATE_UNIT_REMOVED", self, function(_, _, unit)
        if type(unit) == "string" then self:Remove(unit) end
    end)
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN" }) do
        Events:Register(event, self, function() self:QueueUpdateAll() end)
    end
    Events:Register("PLAYER_REGEN_DISABLED", self, function()
        self.inCombat = true
        if FC.P.nameplates.hideInCombat then self:HideAll() end
    end)
    Events:Register("PLAYER_REGEN_ENABLED", self, function()
        self.inCombat = false
        self:QueueUpdateAll()
    end)
    Events:Register("UNIT_QUEST_LOG_CHANGED", self, function(_, _, unit)
        if unit == "player" then self:QueueUpdateAll() end
    end)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^nameplates") or path:find("^appearance%.animations") then
            for _, marker in pairs(self.byPlate) do
                if marker:IsShown() then self:Style(marker) end
            end
            self:QueueUpdateAll()
        end
    end)
end
