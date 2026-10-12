--[[
  Forever Companion - Map/MinimapPins.lua
  Small discovery pins on the minimap. They follow the world map's filters
  (only the finds that matter by default, the Discovery Fog, mine / guild),
  rotate with a rotating minimap, respect round and square minimaps and hide
  inside instances, where the client gives no position.

  Positions are compared in world yards: every discovery's map position is
  turned into world coordinates once (cached), a candidate list of nearby
  pins is rebuilt every few seconds, and only those are placed on each
  update, so the cost does not grow with the journal.
]]

local _, FC = ...

local Pins = FC:NewModule("MinimapPins")

local Compat = FC.Compat
local U = FC.Utils

local BASE_SIZE = 10          -- pixels at 100 %: small enough to leave the minimap readable
local MAX_PINS = 40           -- nearest candidates drawn at most
local CANDIDATE_REFRESH = 2   -- seconds between candidate rebuilds
local UPDATE_INTERVAL = 0.05  -- seconds between placements while something moves
local RANGE_FACTOR = 2        -- candidates within this many view radii

Pins.world = {}        -- rec.id -> { m, x, y, instance, north, west } or a temporary retry entry
Pins.candidates = {}
Pins.frames = {}

------------------------------------------------------------------------
-- World positions
------------------------------------------------------------------------

function Pins:WorldOf(rec)
    local cached = self.world[rec.id]
    if cached and cached.m == rec.m and cached.x == rec.x and cached.y == rec.y then
        if cached.north then return cached end
        if GetTime() < (cached.retryAt or 0) then return nil end
    end
    local north, west, instance = Compat.GetWorldPosition(rec.m, rec.x, rec.y)
    if not north then
        -- Map data can be unavailable just after login or zoning. Retry on
        -- the next candidate refresh instead of hiding this record forever.
        self.world[rec.id] = { m = rec.m, x = rec.x, y = rec.y, retryAt = GetTime() + CANDIDATE_REFRESH }
        return nil
    end
    cached = { m = rec.m, x = rec.x, y = rec.y, north = north, west = west, instance = instance }
    self.world[rec.id] = cached
    return cached
end

------------------------------------------------------------------------
-- Candidates
------------------------------------------------------------------------

function Pins:Enabled()
    return FC.P.map.minimap and Minimap ~= nil
end

--- Nearby records that pass the map filters, nearest first. The whole
--- journal is walked every few seconds, so the cheap questions are asked
--- first: a record of a category hidden on the map, or one far away, is
--- dropped before the map filters look at it.
function Pins:RebuildCandidates()
    local list = {}
    self.candidates = list
    self.candidatesAt = GetTime()
    if not self:Enabled() then return end
    local north, west, instance = Compat.GetPlayerWorldPosition()
    if not north then return end
    local range = Compat.GetMinimapViewRadius() * RANGE_FACTOR
    local rangeSquared = range * range
    local map = FC.MapIntegration
    local hiddenGroups, Categories = FC.P.map.hiddenGroups, FC.Categories
    local hiddenType = {} -- category -> whether its map group is hidden (the filters would say no)
    for _, rec in FC.Store:Iterate() do
        if rec.m and rec.x and rec.y and not rec.del then
            local typeKey = Categories:RecordType(rec) or "other"
            local hidden = hiddenType[typeKey]
            if hidden == nil then
                hidden = hiddenGroups[Categories:Get(typeKey).mapGroup] == true
                hiddenType[typeKey] = hidden
            end
            if not hidden then
                local world = self:WorldOf(rec)
                if world and (world.instance == nil or instance == nil or world.instance == instance) then
                    local dn, dw = world.north - north, world.west - west
                    local squared = dn * dn + dw * dw
                    if squared <= rangeSquared then
                        local visible, veiled = map:PassesFilters(rec)
                        if visible then
                            list[#list + 1] = { rec = rec, world = world, veiled = veiled, distance = math.sqrt(squared) }
                        end
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    for i = #list, MAX_PINS + 1, -1 do list[i] = nil end
end

------------------------------------------------------------------------
-- Pins
------------------------------------------------------------------------

local function createPin()
    local C = FC.C
    local pin = CreateFrame("Button", nil, Minimap)
    pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetPoint("CENTER")
    -- The source contains real alpha; do not put a white ring or a filled
    -- square behind it, and do not crop it through a tiny portrait mask.
    pin:SetScript("OnEnter", function(self)
        if self.rec then ForeverCompanionMapPinMixin.ShowDiscoveryTooltip(self, true) end
    end)
    pin:SetScript("OnLeave", function(self) ForeverCompanionMapPinMixin.OnMouseLeave(self) end)
    pin:SetScript("OnHide", function(self) if FC.Narrator then FC.Narrator:Leave(self) end end)
    pin:RegisterForClicks("LeftButtonUp")
    pin:SetScript("OnClick", function(self, button)
        if self.rec then ForeverCompanionMapPinMixin.OnClick(self, button) end
    end)
    pin:Hide()
    return pin
end

function Pins:StylePin(pin, entry)
    local rec = entry.rec
    -- Appearance refreshes also happen for unrelated discoveries. Preserve the
    -- current sentence unless this frame actually changes identity or visibility.
    if FC.Narrator and (pin.rec ~= rec or pin.veiled ~= entry.veiled) then FC.Narrator:Leave(pin) end
    local size = FC.PinArt:PixelSize(pin, BASE_SIZE * (FC.P.map.minimapScale or 1))
    pin:SetSize(math.max(10, size), math.max(10, size))
    pin.icon:SetSize(size, size)
    FC.PinArt:ApplyDiscovery(pin.icon, rec, entry.veiled, size)
    pin:SetAlpha(FC.P.map.iconAlpha or 1)
    pin.rec = rec
    pin.veiled = entry.veiled
    pin.styled = rec
end

--- Minimap offset (pixels, x right, y up) of a world position, or nil when
--- it falls outside the visible minimap.
function Pins:Offset(world, north, west, radius, facing, margin)
    local halfW, halfH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
    if halfW <= 0 or halfH <= 0 then return nil end
    -- west grows to the west and north to the north: east and north are positive screen x and y
    local sx = (west - world.west) / radius
    local sy = (world.north - north) / radius
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        sx, sy = sx * c + sy * s, -sx * s + sy * c
    end
    local mx, my = margin / halfW, margin / halfH
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        if math.abs(sx) > 1 - mx or math.abs(sy) > 1 - my then return nil end
    elseif sx * sx + sy * sy > (1 - math.max(mx, my)) ^ 2 then
        return nil
    end
    return sx * halfW, sy * halfH
end

function Pins:Place()
    local frames = self.frames
    local shown = 0
    local north, west = Compat.GetPlayerWorldPosition()
    if north and self:Enabled() and Minimap:IsShown() then
        local radius = Compat.GetMinimapViewRadius()
        local facing = GetCVar and GetCVar("rotateMinimap") == "1" and Compat.SafeCall(_G.GetPlayerFacing) or nil
        local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
        local width, height = Minimap:GetWidth(), Minimap:GetHeight()
        -- nothing moved, turned, zoomed or changed: the pins are where they belong
        local last = self.lastPlace
        if last and last.north == north and last.west == west and last.facing == facing and last.radius == radius
            and last.shape == shape and last.width == width and last.height == height and last.candidatesAt == self.candidatesAt then
            return
        end
        self.lastPlace = { north = north, west = west, facing = facing, radius = radius, shape = shape, width = width, height = height, candidatesAt = self.candidatesAt }
        local margin = BASE_SIZE * (FC.P.map.minimapScale or 1) / 2
        for _, entry in ipairs(self.candidates) do
            local x, y = self:Offset(entry.world, north, west, radius, facing, margin)
            if x then
                shown = shown + 1
                local pin = frames[shown]
                if not pin then
                    pin = createPin()
                    frames[shown] = pin
                end
                if pin.styled ~= entry.rec or pin.veiled ~= entry.veiled then self:StylePin(pin, entry) end
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", Minimap, "CENTER", x, y)
                pin:Show()
            end
        end
    end
    if shown == 0 then self.lastPlace = nil end
    for i = shown + 1, #frames do
        frames[i]:Hide()
        frames[i].rec, frames[i].styled = nil, nil
    end
    self.shown = shown
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function Pins:Invalidate(full)
    if full then self.world = {} end
    self.candidatesAt = nil
    self.lastPlace = nil
    for _, pin in ipairs(self.frames) do pin.styled = nil end
end

function Pins:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < UPDATE_INTERVAL then return end
    self.elapsed = 0
    if not self:Enabled() then
        if (self.shown or 0) > 0 then self:Place() end
        return
    end
    if not self.candidatesAt or GetTime() - self.candidatesAt >= CANDIDATE_REFRESH then
        self:RebuildCandidates()
    end
    self:Place()
end

function Pins:OnEnable()
    if not Minimap then return end
    local driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed) FC:SafeCall("MinimapPins", self.OnUpdate, self, elapsed) end)
    self.driver = driver
    local function changed(_, rec)
        if type(rec) == "table" and rec.id then self.world[rec.id] = nil end
        self:Invalidate(false)
    end
    for _, message in ipairs({ "DISCOVERY_ADDED", "DISCOVERY_UPDATED", "DISCOVERY_STATE", "PROFILE_CHANGED" }) do
        FC.Bus:On(message, self, changed)
    end
    FC.Bus:On("DISCOVERY_REMOVED", self, function(_, id)
        if id then self.world[id] = nil end
        self:Invalidate(false)
    end)
    FC.Bus:On("STORE_RESET", self, function() self:Invalidate(true) end)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^map") or path:find("^knowledge") or path:find("^discovery%.verify") then
            self:Invalidate(false)
        end
    end)
    FC.Events:Register("ZONE_CHANGED_NEW_AREA", self, function() self:Invalidate(false) end)
    FC.Events:Register("UI_SCALE_CHANGED", self, function() self:Invalidate(false) end)
end
