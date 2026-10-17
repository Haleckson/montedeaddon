local addonName, MCF = ...
local function T(key) return MCF:T(key) end

-- World map rendering
--   * Markers (deaths, level-ups, journal, screenshots) are
--     Blizzard MapCanvas pins (MapCanvasDataProviderMixin / MapCanvasPinMixin).
--   * The route itself is NOT drawn with pins. It is ONE plain frame (the
--     "route layer") that is a child of the map canvas (= the scroll child of
--     Blizzard's ScrollContainer) and carries native Line regions. Because it
--     hangs off the canvas, Blizzard's own zoom/pan moves it - no geometry
--     syncing and no OnUpdate polling.

local PIN_TEMPLATE = "MyCharForeverRoutePinTemplate"
local provider
local toggle
local journalButton
local journalFrame

-- Single source of truth for how routes are drawn. Used by the world map route
-- layer AND the standalone Journey Map.
local ROUTE = {
    maxJump           = 0.20,                       -- absolute safety limit for any single connection
    maxTimeGap        = 600,                        -- seconds; logout/long pause starts a new run
    -- Teleport detection works in yards, not map fractions: 0.03 of a city map is a few dozen yards, 0.03 of a big
    -- zone is hundreds. A connection is dropped when it covers at least minJumpYards at more than maxSpeedYps
    -- (mounted travel is about 14 yd/s; a hearthstone or portal jump is hundreds of yards within seconds).
    maxSpeedYps       = 35,
    minJumpYards      = 80,
    fallbackMapYards  = 3500,                       -- map width/height in yards when the game cannot tell
    minStepPx         = 3,                          -- start value of the pixel-distance thinning
    maxSegments       = 450,                        -- cap of Line regions per drawn route
    thickness         = 3,                          -- line thickness in screen units
    hoverThickness    = 12,                         -- generous mouse hit width; visual line stays unchanged
    color             = { 1.00, 0.90, 0.05, 1.00 }, -- r, g, b, a
    -- Frame level of the world map route layer. Blizzard's pin manager owns the levels on the canvas
    -- (seen with /mcflayers): map highlight (additive hover glow) 2009 < route layer < area POI pins 2023.
    layerLevel        = 2015,
}

local function Data(p)
    if MCF.GetJourneyPointData then
        return MCF:GetJourneyPointData(p)
    end

    return {
        time = p.time or p.t,
        mapID = p.mapID or p.m,
        x = p.x,
        y = p.y,
        level = p.level or p.l,
        reason = p.reason or p.r,
        taxi = p.taxi or p.q,
        zone = p.zone,
        subZone = p.subZone,
        title = p.title,
        text = p.text,
    }
end

-- --------------------------------------------------------------------------
-- MapCanvas pin
-- --------------------------------------------------------------------------

MyCharForeverRoutePinMixin = CreateFromMixins(MapCanvasPinMixin)

-- SetPassThroughButtons is a protected function: if the game treats the pin as protected (or we are in
-- combat lockdown) a call from addon code raises ADDON_ACTION_BLOCKED (seen in 1.0.0, from the map's own
-- CheckMouseButtonPassthrough on a pin we acquired). So the pin never calls it in those cases; the only
-- cost is that a right click on such a marker does not zoom the map out.
function MyCharForeverRoutePinMixin:ApplyPassThrough()
    if not self.SetPassThroughButtons then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if self.IsProtected and self:IsProtected() then return end
    self:SetPassThroughButtons("RightButton")
end
-- The map calls this on every acquired pin (MapCanvasPinMixin); same guarded behaviour, same result (right click passes through).
function MyCharForeverRoutePinMixin:CheckMouseButtonPassthrough()
    self:ApplyPassThrough()
end

function MyCharForeverRoutePinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1.0, 1.0)

    self.texture = self:CreateTexture(nil, "OVERLAY")
    self.texture:SetAllPoints()


    self:ApplyPassThrough()

    -- The virtual XML template does not automatically bind arbitrary mixin
    -- mouse methods on every Classic client. Bind them explicitly.
    self:SetScript("OnEnter", function(pin)
        if pin.OnMouseEnter then pin:OnMouseEnter() end
    end)
    self:SetScript("OnLeave", function(pin)
        if pin.OnMouseLeave then pin:OnMouseLeave() end
    end)
    self:SetScript("OnMouseUp", function(pin, button)
        if button == "LeftButton" and pin.kind == "journal" and pin.point then
            GameTooltip:Hide()
            MCF:OpenJournalEntry(pin.point)
        end
    end)
end

-- Single source for every marker's look: texture file and on-screen size.
-- All files share one style (dark badge, gold ring, coloured glyph).
local MARKER_TEXTURE = "Interface\\AddOns\\MyCharForever\\Textures\\Marker%s.png"
local MARKER_STYLE = {
    death      = {name = "Death",      size = 20},
    level      = {name = "LevelUp",    size = 22},
    screenshot = {name = "Screenshot", size = 20},
    journal    = {name = "Journal",    size = 20},
    iconic     = {name = "Iconic",     size = 22},
    pvp        = {name = "PvP",        size = 20},
    hearthstone = {name = "Hearthstone", size = 20},
    drop       = {size = 22}, -- texture depends on the item quality (MCF.WorldDrops.IconFor)
}
local DEFAULT_MARKER_SIZE = 10

-- Same files, also used by the journal calendar.
function MCF.MarkerTexture(name) return string.format(MARKER_TEXTURE, name) end

function MyCharForeverRoutePinMixin:OnAcquired(x, y, kind, point)
    self:SetPosition(x, y)
    self.kind = kind
    self.point = point

    local style = MARKER_STYLE[kind]
    if self.texture then
        self.texture:SetTexCoord(0, 1, 0, 1)
        self.texture:Show()
        self.texture:SetVertexColor(1, 1, 1, 1)
        if kind == "drop" then
            self.texture:SetTexture(MCF.WorldDrops.IconFor(point and point.quality))
        elseif style then
            self.texture:SetTexture(MCF.MarkerTexture(style.name))
        else
            self.texture:SetTexture("Interface\\COMMON\\Indicator-Yellow")
        end
    end
    local size = style and style.size or DEFAULT_MARKER_SIZE
    self:SetSize(size, size)
    self:EnableMouse(true)
end

function MyCharForeverRoutePinMixin:OnReleased()
    self.point = nil
    self.kind = nil

    -- MapCanvas can call the pool reset function before OnLoad has run for
    -- a freshly-created pin. Therefore texture is not guaranteed to exist.
    if self.texture then
        self.texture:SetTexture(nil)
    end

    self:EnableMouse(false)
end

local function LevelScreenshotName(p)
    if not MyCharForeverDB or not p then return nil end
    local best,bestDelta
    for _,shot in ipairs(MyCharForeverDB.screenshots or {}) do
        if shot.reason=="LEVEL_UP" and tonumber(shot.level)==tonumber(p.level) then
            local delta=math.abs((tonumber(shot.time) or 0)-(tonumber(p.time) or 0))
            if not bestDelta or delta<bestDelta then
                best,bestDelta=shot,delta
            end
        end
    end
    -- The level-up screenshot is scheduled ~2 seconds after the journey pin.
    if best and bestDelta and bestDelta<=15 then
        return best.expectedFileName
    end
end

function MyCharForeverRoutePinMixin:OnMouseEnter()
    local p = self.point
    if not p then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if self.kind == "death" then
        GameTooltip:AddLine(T("Death"), 1, 0.2, 0.2)
    elseif self.kind == "level" then
        GameTooltip:AddLine("Level " .. tostring(p.level or "?") .. " reached", 1, 0.82, 0)
    elseif self.kind == "screenshot" then
        GameTooltip:AddLine(T("MyCharForever screenshot"),0.3,0.85,1.0)
        if p.expectedFileName then GameTooltip:AddLine(p.expectedFileName,1,1,1) end
        -- The comment sits right below the file name; without one the tooltip says so instead of staying silent.
        if p.comment and p.comment~="" then
            GameTooltip:AddLine("\""..p.comment.."\"",1,0.82,0.2,true)
        else
            GameTooltip:AddLine(T("No comment"),0.5,0.5,0.5)
        end
    elseif self.kind == "pvp" then
        if p.type == "kill" then GameTooltip:AddLine(T("PvP kill"), 1, 0.82, 0.1) else GameTooltip:AddLine(T("PvP death"), 1, 0.2, 0.2) end
        local bits = {}
        if p.race then bits[#bits + 1] = p.race end
        if p.class then bits[#bits + 1] = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[p.class]) or p.class end
        if p.enemyLevel then bits[#bits + 1] = string.format(T("Level %d"), p.enemyLevel) end
        if #bits > 0 then GameTooltip:AddLine(table.concat(bits, " "), 1, 1, 1) end
    elseif self.kind == "hearthstone" then
        GameTooltip:AddLine(T("Hearthstone used"), 0.47, 0.8, 1)
        if p.data and p.data.useNumber then GameTooltip:AddLine(string.format(T("Use #%d"), p.data.useNumber), 1, 1, 1) end
    elseif self.kind == "drop" then
        GameTooltip:AddLine(T("Notable drop"), 1, 0.82, 0.1)
        if p.link then GameTooltip:AddLine(p.link, 1, 1, 1) end
        if p.sourceName then GameTooltip:AddLine(string.format(T("Found at %s"), p.sourceName), 0.8, 0.8, 0.8) end
    elseif self.kind == "journal" then
        GameTooltip:AddLine(p.title or T("Journal entry"), 1, 0.82, 0.2)
    elseif self.kind == "iconic" then
        GameTooltip:AddLine(p.title or T("Iconic moments"), 1, 0.82, 0.2)
    else
        GameTooltip:AddLine(T("Journey point"), 1, 1, 1)
    end


    if self.kind == "death" and MCF.GetDeathInfo then
        local killer, cause, shotName = MCF:GetDeathInfo(p.time)
        GameTooltip:AddLine(" ")
        if killer then GameTooltip:AddDoubleLine(T("Death killer"), killer, 0.75, 0.75, 0.75, 1, 1, 1) end
        if cause then GameTooltip:AddDoubleLine(T("Death cause"), cause, 0.75, 0.75, 0.75, 1, 1, 1) end
        if not killer and not cause then GameTooltip:AddDoubleLine(T("Death cause"), T("Death cause unknown"), 0.75, 0.75, 0.75, 0.55, 0.55, 0.55) end
        GameTooltip:AddDoubleLine(T("Screenshot"), shotName or T("Death no screenshot"), 0.75, 0.75, 0.75, shotName and 1 or 0.55, shotName and 1 or 0.55, shotName and 1 or 0.55)
    end

    if self.kind == "level" then
        local screenshotName=LevelScreenshotName(p)
        if screenshotName then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(T("Screenshot"),screenshotName,0.75,0.75,0.75,1,1,1)
        end
    end

    if (self.kind == "journal" or self.kind == "iconic") and p.text and p.text ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(p.text, 1, 1, 1, true)
    end

    if p.zone and p.zone ~= "" then
        GameTooltip:AddLine(p.zone, 1, 1, 1)
    end

    if p.subZone and p.subZone ~= "" then
        GameTooltip:AddLine(p.subZone, 0.8, 0.8, 0.8)
    end

    if p.time then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(
            T("Date"),
            date("%d.%m.%Y", p.time),
            0.75, 0.75, 0.75,
            1, 1, 1
        )
        GameTooltip:AddDoubleLine(
            T("Time"),
            date("%H:%M:%S", p.time),
            0.75, 0.75, 0.75,
            1, 1, 1
        )
    end

    if p.x and p.y then
        GameTooltip:AddDoubleLine(
            T("Position"),
            string.format("%.1f, %.1f", p.x * 100, p.y * 100),
            0.75, 0.75, 0.75,
            1, 1, 1
        )
    end

    GameTooltip:Show()
end

function MyCharForeverRoutePinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

-- --------------------------------------------------------------------------
-- Journey points: the one place that decides which points belong on a map
-- --------------------------------------------------------------------------

-- All recorded points of one map, unfiltered. Markers (death, level-up, ...)
-- come from this list so route filters can never hide them.
local function JourneyPointsForMap(mapID)
    local out = {}
    for _, raw in ipairs((MyCharForeverDB and MyCharForeverDB.journey) or {}) do
        local p = Data(raw)
        if p.mapID == mapID and p.x and p.y and not (p.x == 0 and p.y == 0) then
            out[#out + 1] = p
        end
    end
    return out
end

-- Same points, narrowed by the route filters from the settings (level range,
-- current session). Pass `points` if JourneyPointsForMap() was already called.
local function FilteredRoutePoints(mapID, points)
    local st = (MyCharForeverDB and MyCharForeverDB.settings) or {}
    local minLevel, maxLevel = tonumber(st.mapJourneyMinLevel), tonumber(st.mapJourneyMaxLevel)
    local sessionStart = st.showMapCurrentSession and MCF.currentSession and MCF.currentSession.startTime or nil
    local out = {}
    for _, p in ipairs(points or JourneyPointsForMap(mapID)) do
        local lvl, t = tonumber(p.level), tonumber(p.time)
        if (not minLevel or not lvl or lvl >= minLevel)
            and (not maxLevel or not lvl or lvl <= maxLevel)
            and (not sessionStart or (t and t >= sessionStart)) then
            out[#out + 1] = p
        end
    end
    return out
end

-- --------------------------------------------------------------------------
-- Route rendering (shared by the world map layer and the Journey Map)
-- --------------------------------------------------------------------------

-- Normalised points -> runs of pixel coordinates. A new run starts at every
-- jump >= ROUTE.maxJump, so teleports are never connected by a line.
local mapYardsCache = {}
local function MapYards(mapID)
    if not mapID then return ROUTE.fallbackMapYards, ROUTE.fallbackMapYards end
    local c = mapYardsCache[mapID]
    if not c then
        local w, h
        if C_Map and C_Map.GetMapWorldSize then
            local ok, a, b = pcall(C_Map.GetMapWorldSize, mapID)
            if ok then w, h = tonumber(a), tonumber(b) end
        end
        if not w or w <= 0 then w = ROUTE.fallbackMapYards end
        if not h or h <= 0 then h = w end
        c = {w, h}; mapYardsCache[mapID] = c
    end
    return c[1], c[2]
end

local function RouteBreak(prev, p)
    if not prev or not p then return true end
    if prev.taxi or p.taxi then return true end
    local dx, dy = p.x - prev.x, p.y - prev.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local t1, t2 = tonumber(prev.time), tonumber(p.time)
    local dt = (t1 and t2) and math.max(0, t2 - t1) or nil
    if dist >= ROUTE.maxJump then return true end
    if dt and dt > ROUTE.maxTimeGap then return true end
    local w, h = MapYards(p.mapID or prev.mapID)
    local yards = math.sqrt((dx * w) ^ 2 + (dy * h) ^ 2)
    if dt and yards >= ROUTE.minJumpYards and yards / math.max(dt, 1) > ROUTE.maxSpeedYps then return true end
    return false
end

local function BuildRuns(points, W, H)
    local runs, run, prev = {}, nil, nil

    local function StartRun()
        run = {}
        runs[#runs + 1] = run
    end

    for _, p in ipairs(points) do
        if p.taxi then
            run = nil
            prev = nil
        else
            if not run or RouteBreak(prev, p) then StartRun() end
            -- Keep the source point on the pixel point. This lets the same
            -- rendered segment provide its chronological mouseover data.
            run[#run + 1] = { x = p.x * W, y = p.y * H, source = p }
            prev = p
        end
    end
    return runs
end

-- Keeps a point only if it is >= step pixels away from the last kept one.
-- First and last point of a run are always kept.
local function ThinRun(run, step)
    local out, lx, ly = {}, nil, nil
    local last = #run
    for i, q in ipairs(run) do
        if not lx or i == last or (q.x - lx) ^ 2 + (q.y - ly) ^ 2 >= step * step then
            out[#out + 1] = q
            lx, ly = q.x, q.y
        end
    end
    return out
end

-- Thins the runs (doubling the step) until they fit into ROUTE.maxSegments.
local function BuildRouteRuns(points, W, H)
    local runs = BuildRuns(points, W, H)
    local step, thinned = ROUTE.minStepPx, nil
    for _ = 1, 12 do
        thinned = {}
        local segments = 0
        for _, run in ipairs(runs) do
            local t = ThinRun(run, step)
            thinned[#thinned + 1] = t
            segments = segments + #t - 1
        end
        if segments <= ROUTE.maxSegments then break end
        step = step * 2
    end
    return thinned
end

-- Draws runs as native Line regions on `surface` (a frame whose TOPLEFT is the
-- map's 0/0). `pool` holds the reusable Line regions. Returns segments drawn.
local function DrawRouteRuns(surface, pool, runs, thickness)
    local used = 0
    local r, g, b, a = unpack(ROUTE.color)
    for _, run in ipairs(runs) do
        for i = 2, #run do
            used = used + 1
            local l = pool[used]
            if not l then
                l = surface:CreateLine(nil, "ARTWORK")
                l:SetTexture("Interface\\Buttons\\WHITE8X8")
                pool[used] = l
            end
            l:ClearAllPoints()
            l:SetStartPoint("TOPLEFT", surface, run[i - 1].x, -run[i - 1].y)
            l:SetEndPoint("TOPLEFT", surface, run[i].x, -run[i].y)
            l:SetThickness(thickness)
            l:SetVertexColor(r, g, b, a)
            -- Rendering must never depend on optional mouse APIs. Show the line
            -- first, then install hover support defensively. Forever builds can
            -- differ in which Region/Line interaction methods they expose.
            l:Show()
            l._mcfA = run[i - 1].source
            l._mcfB = run[i].source
            l._mcfAX, l._mcfAY = run[i - 1].x, run[i - 1].y
            l._mcfBX, l._mcfBY = run[i].x, run[i].y
            if not l._mcfHoverInstalled then
                local ok = pcall(function()
                    if l.SetHitRectThickness then
                        local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                        local surfaceScale = (surface.GetEffectiveScale and surface:GetEffectiveScale()) or uiScale
                        l:SetHitRectThickness(math.max(thickness, ROUTE.hoverThickness / math.max(0.01, surfaceScale / uiScale)))
                    end
                    if l.SetMouseClickEnabled then l:SetMouseClickEnabled(false) end
                    if l.SetMouseMotionEnabled then l:SetMouseMotionEnabled(true) end
                    if not l.SetScript then error("Line has no SetScript") end
                    local function UpdateJourneyTooltip(self)
                        local a, b = self._mcfA, self._mcfB
                        if not a or not b then return end
                        local f = 0.5
                        if GetCursorPosition and surface.GetLeft and surface.GetTop then
                            local scale = (surface.GetEffectiveScale and surface:GetEffectiveScale()) or 1
                            local cx, cy = GetCursorPosition()
                            local left, top = surface:GetLeft(), surface:GetTop()
                            if cx and cy and left and top and scale and scale > 0 then
                                cx, cy = cx / scale, cy / scale
                                local mx, my = cx - left, top - cy
                                local ax, ay = self._mcfAX or 0, self._mcfAY or 0
                                local bx, by = self._mcfBX or ax, self._mcfBY or ay
                                local dx, dy = bx - ax, by - ay
                                local len2 = dx * dx + dy * dy
                                if len2 > 0 then
                                    f = ((mx - ax) * dx + (my - ay) * dy) / len2
                                    if f < 0 then f = 0 elseif f > 1 then f = 1 end
                                end
                            end
                        end
                        local ta, tb = tonumber(a.time), tonumber(b.time)
                        local when = ta and tb and math.floor(ta + (tb - ta) * f + 0.5) or ta or tb
                        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(T("Journey"), 1, 0.82, 0.1)
                        if when then
                            GameTooltip:AddDoubleLine(T("Date"), date("%d.%m.%Y", when), 0.75,0.75,0.75, 1,1,1)
                            GameTooltip:AddDoubleLine(T("Time"), date("%H:%M:%S", when), 0.75,0.75,0.75, 1,1,1)
                        end
                        local lvl = (f < 0.5 and a.level or b.level) or b.level or a.level
                        if lvl then GameTooltip:AddDoubleLine(T("Level"), tostring(lvl), 0.75,0.75,0.75, 1,1,1) end
                        local zone = (f < 0.5 and (a.subZone or a.zone) or (b.subZone or b.zone)) or b.subZone or b.zone or a.subZone or a.zone
                        if zone and zone ~= "" then GameTooltip:AddLine(zone, 1,1,1) end
                        GameTooltip:Show()
                    end
                    l:SetScript("OnEnter", function(self) self._mcfHovering=true; UpdateJourneyTooltip(self) end)
                    l:SetScript("OnUpdate", function(self) if self._mcfHovering then UpdateJourneyTooltip(self) end end)
                    l:SetScript("OnLeave", function(self) self._mcfHovering=nil; GameTooltip:Hide() end)
                end)
                -- Even if hover is unsupported, never retry every refresh and
                -- never let that disable the actual route renderer.
                l._mcfHoverInstalled = ok and true or "unsupported"
            end
        end
    end
    for i = used + 1, #pool do pool[i]:Hide() end
    return used
end

-- --------------------------------------------------------------------------
-- World map route layer
-- --------------------------------------------------------------------------

local routeLayer
local routeLines = {}

-- ROUTE.thickness is meant as on-screen size. The layer inherits the canvas
-- scale, so compensate for it (otherwise zooming the map scales the line).
local function LayerThickness()
    local ui = UIParent:GetEffectiveScale()
    local s = routeLayer and routeLayer:GetEffectiveScale()
    if not s or s <= 0 or not ui or ui <= 0 then return ROUTE.thickness end
    return ROUTE.thickness * ui / s
end

local function UpdateRouteThickness()
    if not routeLayer or not routeLayer.points then return end
    local t = LayerThickness()
    for _, l in ipairs(routeLines) do l:SetThickness(t) end
end

local function HideRouteLayer()
    if not routeLayer then return end
    routeLayer.points = nil
    routeLayer:Hide()
end

-- (Re)draws the layer's current points at the canvas' current size.
local function DrawRouteLayer(layer)
    local canvas = layer:GetParent()
    local W, H = canvas:GetWidth(), canvas:GetHeight()
    if not W or not H or W <= 1 or H <= 1 then
        -- Canvas size not final yet: show nothing stale, OnSizeChanged calls us again.
        DrawRouteRuns(layer, routeLines, {}, 1)
        layer.drawnW, layer.drawnH = nil, nil
        return
    end
    layer.drawnW, layer.drawnH = W, H
    DrawRouteRuns(layer, routeLines, BuildRouteRuns(layer.points, W, H), LayerThickness())
end

local function EnsureRouteLayer(canvas)
    if not routeLayer then
        routeLayer = CreateFrame("Frame", nil, canvas)
        routeLayer:EnableMouse(false)
        routeLayer:SetScript("OnSizeChanged", function(self)
            local c = self:GetParent()
            if self.points and (c:GetWidth() ~= self.drawnW or c:GetHeight() ~= self.drawnH) then
                DrawRouteLayer(self)
            end
        end)
    elseif routeLayer:GetParent() ~= canvas then
        routeLayer:SetParent(canvas)
    end
    routeLayer:ClearAllPoints()
    routeLayer:SetAllPoints(canvas)
    routeLayer:SetFrameLevel(ROUTE.layerLevel) -- after SetParent, which resets the level
    return routeLayer
end

local function ShowRouteLayer(map, points)
    local canvas = map and map.GetCanvas and map:GetCanvas()
    if not canvas or #points < 2 then
        HideRouteLayer()
        return
    end
    local layer = EnsureRouteLayer(canvas)
    layer.points = points
    layer:Show()
    DrawRouteLayer(layer)
end

-- --------------------------------------------------------------------------
-- Data provider
-- --------------------------------------------------------------------------

local MyCharForeverMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function MyCharForeverMapDataProviderMixin:RemoveAllData()
    local map = self:GetMap()
    if map then
        map:RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end
    HideRouteLayer()
end

-- Called by Blizzard's map when the zoom level changes.
function MyCharForeverMapDataProviderMixin:OnCanvasScaleChanged()
    UpdateRouteThickness()
end

function MyCharForeverMapDataProviderMixin:RefreshAllData()
    self:RemoveAllData()

    if not MyCharForeverDB then return end
    local settings = MyCharForeverDB.settings or {}
    if settings.showMapJourney == nil then settings.showMapJourney = true end
    if settings.showMapLevelUps == nil then settings.showMapLevelUps = true end
    if settings.showMapDeaths == nil then settings.showMapDeaths = true end
    if settings.showMapJournal == nil then settings.showMapJournal = true end

    local map = self:GetMap()
    if not map then return end

    local mapID = map:GetMapID()
    if not mapID then return end

    local points = JourneyPointsForMap(mapID)
    local routePoints = FilteredRoutePoints(mapID, points)

    if settings.showMapJourney then
        ShowRouteLayer(map, routePoints)


    end

    -- Markers are taken from the unfiltered history, so a level-up/death/login
    -- can never disappear because of route filters.
    for _, p in ipairs(points) do
        local kind

        if p.reason == "DEATH" and settings.showMapDeaths then
            kind = "death"
        elseif p.reason and p.reason:match("^LEVEL_") and settings.showMapLevelUps then
            kind = "level"
        end

        if kind then
            map:AcquirePin(PIN_TEMPLATE, p.x, p.y, kind, p)
        end
    end

    if settings.showMapScreenshots ~= false then
        for _, shot in ipairs(MyCharForeverDB.screenshots or {}) do
            if shot.reason == "MANUAL_CHRONICLE" and shot.mapID == mapID and shot.x and shot.y then
                map:AcquirePin(PIN_TEMPLATE, shot.x, shot.y, "screenshot", shot)
            end
        end
    end

    if settings.showMapDrops ~= false then
        for _, drop in ipairs(MyCharForeverDB.worldDrops or {}) do
            if drop.mapID == mapID and drop.x and drop.y then
                map:AcquirePin(PIN_TEMPLATE, drop.x, drop.y, "drop", drop)
            end
        end
    end

    if settings.showMapPvp ~= false and MyCharForeverDB.pvp then
        for _, row in ipairs(MyCharForeverDB.pvp.history or {}) do
            if row.mapID == mapID and row.x and row.y then
                map:AcquirePin(PIN_TEMPLATE, row.x, row.y, "pvp", row)
            end
        end
    end

    -- Hearthstone uses: the HEARTHSTONE events carry the place left behind (explains routes that end abruptly).
    if settings.showMapHearthstone ~= false then
        for _, e in ipairs(MyCharForeverDB.events or {}) do
            if e.type == "HEARTHSTONE" and e.mapID == mapID and e.x and e.y then
                map:AcquirePin(PIN_TEMPLATE, e.x, e.y, "hearthstone", e)
            end
        end
    end

    if settings.showMapJournal then
        for _, entry in ipairs(MyCharForeverDB.journal or {}) do
            -- World drops already have their own pin; their journal entry stays calendar-only.
            -- Iconic moments have their own pin (star) and filter, see below.
            if entry.mapID == mapID and entry.x and entry.y and entry.source ~= "WORLD_DROP" and entry.source ~= "ICONIC" then
                map:AcquirePin(PIN_TEMPLATE, entry.x, entry.y, "journal", entry)
            end
        end
    end

    -- Iconic moments: the automatic journal entry (title + personal line) marks the place; without a journal entry
    -- the screenshot of the moment does (reason ICONIC_<id>).
    if settings.showMapIconic ~= false and MCF:IconicEnabled() then
        local withEntry = {}
        for _, entry in ipairs(MyCharForeverDB.journal or {}) do
            if entry.source == "ICONIC" then
                if entry.iconicID then withEntry[entry.iconicID] = true end
                if entry.mapID == mapID and entry.x and entry.y then map:AcquirePin(PIN_TEMPLATE, entry.x, entry.y, "iconic", entry) end
            end
        end
        for _, shot in ipairs(MyCharForeverDB.screenshots or {}) do
            local id = type(shot.reason) == "string" and shot.reason:match("^ICONIC_(.+)$")
            if id and not withEntry[id] and shot.mapID == mapID and shot.x and shot.y then
                local title = MCF.GetIconicTitle and MCF:GetIconicTitle(id)
                map:AcquirePin(PIN_TEMPLATE, shot.x, shot.y, "iconic", {title = title, zone = shot.zone, subZone = shot.subZone, time = shot.time, level = shot.level})
            end
        end
    end
end

function MCF:RefreshMapJourney()
    if provider then
        provider:RefreshAllData()
    end
end

-- WorldMap geometry diagnostic earlier build
local function MCFFrameInfo(name,obj)
    if not obj then return name..": <nil>" end
    local function N(v) return type(v)=="number" and string.format("%.3f",v) or tostring(v) end
    local function G(fn) local ok,v=pcall(fn); return ok and N(v) or "?" end
    local parent=obj.GetParent and obj:GetParent()
    local pn=parent and parent.GetName and parent:GetName() or tostring(parent)
    return name..
        ": shown="..G(function() return obj:IsShown() end)..
        " size="..G(function() return obj:GetWidth() end).."x"..G(function() return obj:GetHeight() end)..
        " LTRB="..G(function() return obj:GetLeft() end)..","..G(function() return obj:GetTop() end)..","..
                   G(function() return obj:GetRight() end)..","..G(function() return obj:GetBottom() end)..
        " scale="..G(function() return obj:GetScale() end)..
        " eff="..G(function() return obj:GetEffectiveScale() end)..
        " level="..G(function() return obj:GetFrameLevel() end)..
        " strata="..G(function() return obj:GetFrameStrata() end)..
        " parent="..pn
end

local function MCFShowMapDebug(text)
    if not MCFMapDebugFrame then
        local f=CreateFrame("Frame","MCFMapDebugFrame",UIParent,"BackdropTemplate")
        MCF.MakeOpaque(f,4)
        f:SetSize(780,540); f:SetPoint("CENTER"); f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize=14,insets={left=3,right=3,top=3,bottom=3}})
        f:SetBackdropColor(0,0,0,0.97)
        local title=f:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
        title:SetPoint("TOPLEFT",14,-12); title:SetText("MyCharForever Map Debug")
        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3)
        local sf=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",14,-42); sf:SetPoint("BOTTOMRIGHT",-30,14)
        local eb=CreateFrame("EditBox",nil,sf)
        eb:SetMultiLine(true); eb:SetAutoFocus(false); eb:SetFontObject(ChatFontNormal); eb:SetWidth(720)
        sf:SetScrollChild(eb); f.edit=eb
        MCFMapDebugFrame=f
    end
    local eb=MCFMapDebugFrame.edit
    eb:SetText(text); eb:SetCursorPosition(0); eb:HighlightText()
    MCFMapDebugFrame:Show(); eb:SetFocus()
end

function MCF:DumpWorldMapGeometry()
    local m=WorldMapFrame
    local lines={"MyCharForever WorldMap geometry earlier build",""}
    local function add(name,obj) lines[#lines+1]=MCFFrameInfo(name,obj) end
    add("WorldMapFrame",m)
    add("BorderFrame",m and m.BorderFrame)
    add("ScrollContainer",m and m.ScrollContainer)
    add("ScrollContainer.Child",m and m.ScrollContainer and m.ScrollContainer.Child)
    add("Canvas",m and m.GetCanvas and m:GetCanvas())
    add("CanvasContainer",m and m.GetCanvasContainer and m:GetCanvasContainer())
    if m then
        local ok,z=pcall(function() return m:GetCanvasScale() end)
        lines[#lines+1]="GetCanvasScale="..(ok and tostring(z) or "<error>")
        lines[#lines+1]="mapID="..tostring(m.GetMapID and m:GetMapID())
    end
    local c=m and m.GetCanvas and m:GetCanvas()
    if c then
        lines[#lines+1]=""
        lines[#lines+1]="Canvas parent chain:"
        local x=c
        for i=1,8 do
            if not x then break end
            lines[#lines+1]=MCFFrameInfo("["..i.."]",x)
            x=x.GetParent and x:GetParent() or nil
        end
    end
    MCFShowMapDebug(table.concat(lines,"\n"))
    print("|cffffd200MyCharForever:|r Map geometry captured. Ctrl+C in the debug window.")
end

MCF:AddCommand{group="debug",usage="/mcfmapdebug",de="Geometrie der Weltkarte ausgeben",en="Print the world map geometry"}
MCF:AddCommand{group="debug",usage="/mcflayers",de="Frame-Ebenen der Weltkarte ausgeben",en="Print the world map frame levels"}
MCF:AddCommand{group="debug",usage="/mcflayer <Ebene> [Strata]",example="/mcflayer 400 HIGH",de="Ebene der Routenlinie live testen",en="Try another frame level for the route line live"}
SLASH_MCFMAPDEBUG1="/mcfmapdebug"
SlashCmdList.MCFMAPDEBUG=function() MCF:DumpWorldMapGeometry() end

-- /mcflayers: everything that hangs directly on the world map canvas, sorted by
-- frame level. Shows who paints over the route (level, strata, blend mode).
function MCF:DumpMapLayers()
    local m = WorldMapFrame
    local canvas = m and m.GetCanvas and m:GetCanvas()
    if not canvas then
        print("|cffffd200MyCharForever:|r no map canvas")
        return
    end

    local function label(obj)
        if obj == routeLayer then return "MCF route layer" end
        return obj.pinTemplate or (obj.GetName and obj:GetName()) or obj:GetObjectType()
    end
    local function firstBlend(obj)
        for _, r in ipairs({ obj:GetRegions() }) do
            if r.GetBlendMode then return r:GetBlendMode() end
        end
        return "-"
    end

    local groups = {}
    for _, child in ipairs({ canvas:GetChildren() }) do
        local level, strata = child:GetFrameLevel() or 0, child:GetFrameStrata() or "?"
        local name, shown = label(child), child:IsShown() and "shown" or "hidden"
        local key = table.concat({ level, strata, name, shown }, "|")
        local g = groups[key]
        if not g then
            g = { level = level, strata = strata, name = name, shown = shown, n = 0,
                  regions = child:GetNumRegions(), alpha = child:GetAlpha(), blend = firstBlend(child) }
            groups[key] = g
        end
        g.n = g.n + 1
    end

    local list = {}
    for _, g in pairs(groups) do list[#list + 1] = g end
    table.sort(list, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)

    local lines = {
        "MyCharForever canvas children, sorted by frame level",
        string.format("canvas: level=%s strata=%s mapID=%s", tostring(canvas:GetFrameLevel()),
            tostring(canvas:GetFrameStrata()), tostring(m.GetMapID and m:GetMapID())),
        "",
    }
    for _, g in ipairs(list) do
        lines[#lines + 1] = string.format("lvl %-5d %-10s x%-3d %-34s %s regions=%s alpha=%.2f blend=%s",
            g.level, g.strata, g.n, g.name, g.shown, tostring(g.regions), g.alpha, tostring(g.blend))
    end
    local text = table.concat(lines, "\n")
    MCFShowMapDebug(text)
    return text
end

SLASH_MCFLAYERS1 = "/mcflayers"
SlashCmdList.MCFLAYERS = function() MCF:DumpMapLayers() end

-- /mcflayer <level> [strata]: try another frame level / strata for the route
-- layer live, without /reload. Example: /mcflayer 400   or   /mcflayer 400 HIGH
SLASH_MCFLAYER1 = "/mcflayer"
SlashCmdList.MCFLAYER = function(msg)
    if not routeLayer then
        print("|cffffd200MyCharForever:|r route layer does not exist yet (open the map with a drawn route first)")
        return
    end
    local level, strata = tostring(msg or ""):match("^%s*(%d+)%s*(%a*)%s*$")
    if not level then
        print("|cffffd200MyCharForever:|r usage: /mcflayer <level> [strata]   now: level="
            .. tostring(routeLayer:GetFrameLevel()) .. " strata=" .. tostring(routeLayer:GetFrameStrata()))
        return
    end
    if strata ~= "" then routeLayer:SetFrameStrata(strata:upper()) end
    routeLayer:SetFrameLevel(tonumber(level))
    print("|cffffd200MyCharForever:|r route layer level=" .. routeLayer:GetFrameLevel()
        .. " strata=" .. routeLayer:GetFrameStrata())
end

-- --------------------------------------------------------------------------
-- MyCharForever Journey Map
-- Standalone map renderer using the same proven architecture as LoreForever:
-- clipped view -> movable/scalable surface -> map art + native lines on surface.
-- --------------------------------------------------------------------------
local journeyMapFrame
local JM_W, JM_H = 900, 620

local function EnsureJourneyMap()
    if journeyMapFrame then return journeyMapFrame end
    local f=CreateFrame("Frame","MyCharForeverJourneyMapFrame",UIParent,"BackdropTemplate")
    MCF.MakeOpaque(f,4)
    f:SetSize(JM_W,JM_H); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) if not self.mapDragging then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,
        insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0.02,0.02,0.02,1); f:SetBackdropBorderColor(0.45,0.45,0.45,1)
    f:Hide()

    local title=f:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
    title:SetPoint("TOPLEFT",16,-12); title:SetText("MyCharForever - Journey Map")
    f.mapTitle=title
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-3,-3)

    local view=CreateFrame("Frame",nil,f)
    view:SetPoint("TOPLEFT",10,-38); view:SetPoint("BOTTOMRIGHT",-10,10)
    view:SetFrameLevel(f:GetFrameLevel()+1)
    if view.SetClipsChildren then view:SetClipsChildren(true) end
    view:EnableMouse(true); view:EnableMouseWheel(true)
    local bg=view:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.04,0.04,0.04,1)

    local surface=CreateFrame("Frame",nil,view)
    surface:SetPoint("TOPLEFT"); surface:SetSize(1,1); surface:SetFrameLevel(f:GetFrameLevel()+2)
    f.view,f.surface=view,surface
    f.tiles,f.lines={},{}
    f.zoom,f.ox,f.oy=1,0,0

    local function clamp()
        local vw,vh=view:GetWidth(),view:GetHeight()
        local sw,sh=surface:GetWidth(),surface:GetHeight()
        f.ox=math.max(0,math.min(f.ox or 0,math.max(0,sw-vw)))
        f.oy=math.max(0,math.min(f.oy or 0,math.max(0,sh-vh)))
        surface:ClearAllPoints(); surface:SetPoint("TOPLEFT",view,"TOPLEFT",-f.ox,f.oy)
    end
    f.ClampPan=clamp

    local function cursor()
        local x,y=GetCursorPosition()
        local scale=view:GetEffectiveScale() or 1
        local l,t=view:GetLeft(),view:GetTop()
        if not l or not t then return end
        return x/scale-l,t-y/scale
    end

    view:SetScript("OnMouseWheel",function(_,delta)
        if not f.mapID then return end
        local cx,cy=cursor(); if not cx then return end
        local old=f.zoom
        local nz=math.max(1,math.min(6,old*((delta or 0)>0 and 1.25 or 0.8)))
        if math.abs(nz-old)<0.001 then return end
        local u=(f.ox+cx)/(view:GetWidth()*old)
        local v=(f.oy+cy)/(view:GetHeight()*old)
        f.zoom=nz
        f:RefreshJourneyMap()
        f.ox=u*view:GetWidth()*nz-cx
        f.oy=v*view:GetHeight()*nz-cy
        clamp()
    end)
    view:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or f.zoom<=1.001 then return end
        local x,y=cursor(); if x then f.panDrag={x=x,y=y,ox=f.ox,oy=f.oy} end
    end)
    view:SetScript("OnMouseUp",function() f.panDrag=nil end)
    view:SetScript("OnUpdate",function()
        if not f.panDrag then return end
        local x,y=cursor(); if not x then return end
        f.ox=f.panDrag.ox-(x-f.panDrag.x)
        f.oy=f.panDrag.oy-(y-f.panDrag.y)
        clamp()
    end)

    function f:RefreshJourneyMap()
        if not self.mapID then return end
        local W,H=view:GetWidth()*self.zoom,view:GetHeight()*self.zoom
        if W<=1 or H<=1 then return end
        surface:SetSize(W,H)

        local layers=C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(self.mapID)
        local L1=type(layers)=="table" and layers[1]
        local tex=L1 and C_Map.GetMapArtLayerTextures(self.mapID,1)
        local n=0
        if L1 and type(tex)=="table" and (L1.layerWidth or 0)>0 then
            local sx,sy=W/L1.layerWidth,H/L1.layerHeight
            local cols=math.ceil(L1.layerWidth/L1.tileWidth)
            for i,id in ipairs(tex) do
                local t=self.tiles[i]
                if not t then t=surface:CreateTexture(nil,"BORDER"); self.tiles[i]=t end
                t:SetSize(L1.tileWidth*sx,L1.tileHeight*sy)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT",surface,"TOPLEFT",((i-1)%cols)*L1.tileWidth*sx,
                    -math.floor((i-1)/cols)*L1.tileHeight*sy)
                t:SetTexture(id); t:SetAlpha(1); t:Show(); n=i
            end
        end
        for i=n+1,#self.tiles do self.tiles[i]:Hide() end

        DrawRouteRuns(surface,self.lines,BuildRouteRuns(FilteredRoutePoints(self.mapID),W,H),
            ROUTE.thickness*self.zoom)
        clamp()
        local info=C_Map.GetMapInfo and C_Map.GetMapInfo(self.mapID)
        self.mapTitle:SetText("MyCharForever - "..((info and info.name) or "Journey Map"))
    end

    journeyMapFrame=f
    return f
end

function MCF:OpenJourneyMap(mapID)
    local f=EnsureJourneyMap()
    mapID=mapID or (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
        or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if not mapID then return end
    f.mapID=mapID; f.zoom=1; f.ox=0; f.oy=0
    f:Show()
    C_Timer.After(0,function() if f:IsShown() then f:RefreshJourneyMap() end end)
end

local function CurrentMapPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local x,y = pos:GetXY()
    if not x or not y or (x==0 and y==0) then return end
    return mapID,x,y
end

local function FindJournalIndex(entry)
    if not MyCharForeverDB or not entry then return nil end
    for i,e in ipairs(MyCharForeverDB.journal or {}) do
        if e == entry then return i end
    end
end

StaticPopupDialogs["MYCHARFOREVER_DELETE_JOURNAL"]={
    text=MCF.Branded(T("Delete this journal entry permanently?")),
    button1=YES,
    button2=NO,
    OnAccept=function(_,data)
        if not data or not MyCharForeverDB then return end
        local index=FindJournalIndex(data)
        if index then
            table.remove(MyCharForeverDB.journal,index)
            MCF:AddEvent("JOURNAL_DELETE",{title=data.title})
            MCF:RefreshMapJourney()
            if MCF.RefreshUI then MCF:RefreshUI() end
            print("|cff00ccffMyCharForever|r: "..T("Journal entry deleted."))
        end
    end,
    timeout=0,
    whileDead=true,
    hideOnEscape=true,
    preferredIndex=3,
}

function MCF:DeleteJournalEntry(entry)
    if entry then StaticPopup_Show("MYCHARFOREVER_DELETE_JOURNAL",nil,nil,entry) end
end

local function EnsureJournalFrame()
    if journalFrame then return journalFrame end
    local f=MCF.Kit.Window("MyCharForeverJournalFrame",{w=430,h=350,level=700,close=false})
    MCF.Kit.Label(f,T("Title"),18,-40)
    f.titleEdit=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); f.titleEdit:SetSize(380,28); f.titleEdit:SetPoint("TOPLEFT",24,-58); f.titleEdit:SetAutoFocus(false)
    MCF.Kit.Label(f,T("Entry"),18,-94)
    local bg=MCF.Kit.Inset(f); bg:SetPoint("TOPLEFT",16,-112); bg:SetPoint("BOTTOMRIGHT",-16,70)
    f.body=CreateFrame("EditBox",nil,bg); f.body:SetMultiLine(true); f.body:SetAutoFocus(false); f.body:SetFontObject("ChatFontNormal"); f.body:SetTextInsets(8,8,8,8); f.body:SetPoint("TOPLEFT",4,-4); f.body:SetPoint("BOTTOMRIGHT",-4,4); f.body:SetMaxLetters(2000)
    MCF.Kit.TabOrder({f.titleEdit,f.body})
    f.save=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); f.save:SetSize(90,24); f.save:SetPoint("BOTTOMRIGHT",-18,16); f.save:SetText(T("Save"))
    f.cancel=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); f.cancel:SetSize(90,24); f.cancel:SetPoint("RIGHT",f.save,"LEFT",-8,0); f.cancel:SetText(T("Cancel")); f.cancel:SetScript("OnClick",function() f:Hide() end)
    f.delete=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); f.delete:SetSize(90,24); f.delete:SetPoint("BOTTOMLEFT",18,16); f.delete:SetText(T("Delete"))
    f.delete:SetScript("OnClick",function()
        local entry=f.editingEntry
        f:Hide()
        if entry then MCF:DeleteJournalEntry(entry) end
    end)
    f.save:SetScript("OnClick",function()
        local title=f.titleEdit:GetText()
        local body=f.body:GetText()
        if not title or title=="" then title=T("Journal entry") end

        if f.editingEntry then
            -- Preserve the original milestone metadata; only user-authored
            -- title/text are changed.
            f.editingEntry.title=title
            f.editingEntry.text=body
            f.editingEntry.edited=time()
            MCF:AddEvent("JOURNAL_EDIT",{title=title})
            print("|cff00ccffMyCharForever|r: "..T("Journal entry updated."))
        else
            local mapID,x,y=CurrentMapPosition()
            if not mapID then print("|cffff4444MyCharForever: "..T("Current map position unavailable.").."|r"); return end
            local entry={time=time(),level=UnitLevel("player"),mapID=mapID,x=x,y=y,zone=GetZoneText(),subZone=GetSubZoneText(),title=title,text=body}
            table.insert(MyCharForeverDB.journal,entry)
            MCF:AddEvent(T("JOURNAL"),{journalIndex=#MyCharForeverDB.journal,title=entry.title})
            print("|cff00ccffMyCharForever|r: "..T("Journal entry saved."))
        end

        f:Hide()
        MCF:RefreshMapJourney()
        if MCF.RefreshUI then MCF:RefreshUI() end
    end)
    journalFrame=f
    return f
end

function MCF:OpenJournalEntry(entry)
    local f=EnsureJournalFrame()
    f.editingEntry=entry
    if entry then
        f.title:SetText(T("MyCharForever - Edit journal entry"))
        f.titleEdit:SetText(entry.title or "")
        f.body:SetText(entry.text or "")
        f.delete:Show()
    else
        f.title:SetText(T("MyCharForever - New journal entry"))
        f.titleEdit:SetText("")
        f.body:SetText("")
        f.delete:Hide()
    end
    f:Show()
    f.titleEdit:SetFocus()
end

local menuButton
local menuFrame
local menuChecks={}

-- The whole menu (button + panel) shrinks when the map is small (WoW's default is the minimised map), so it
-- does not reach over the map's edge. One place for the limits; the scale is recomputed on show and on resize.
local MENU_SCALE_MIN, MENU_SCALE_MAX = 0.6, 1.0
local MENU_BUTTON_H, MENU_GAP, MENU_MARGIN = 24, 3, 10
local function ApplyMenuScale()
    if not (menuButton and menuFrame) then return end
    local anchor=WorldMapFrame and (WorldMapFrame.ScrollContainer or WorldMapFrame)
    local h=anchor and anchor:GetHeight() or 0
    if not h or h<=0 then return end
    local menuH=menuFrame:GetHeight() or 0
    local scale=(h-MENU_MARGIN-MENU_MARGIN)/(MENU_BUTTON_H+MENU_GAP+menuH)
    scale=math.max(MENU_SCALE_MIN,math.min(MENU_SCALE_MAX,scale))
    menuButton:SetScale(scale)
    menuFrame:SetScale(scale)
end

local function SetVisibilitySetting(key, value)
    MyCharForeverDB.settings[key]=value and true or false
    MCF:RefreshMapJourney()
end

local function SyncMenuChecks()
    if not MyCharForeverDB or not MyCharForeverDB.settings then return end
    local st=MyCharForeverDB.settings
    if menuChecks.path then menuChecks.path:SetChecked(st.showMapJourney ~= false) end
    if menuChecks.levels then menuChecks.levels:SetChecked(st.showMapLevelUps ~= false) end
    if menuChecks.deaths then menuChecks.deaths:SetChecked(st.showMapDeaths ~= false) end
    if menuChecks.journal then menuChecks.journal:SetChecked(st.showMapJournal ~= false) end
    if menuChecks.iconic then menuChecks.iconic:SetChecked(st.showMapIconic ~= false) end
    if menuChecks.screenshots then menuChecks.screenshots:SetChecked(st.showMapScreenshots ~= false) end
    if menuChecks.drops then menuChecks.drops:SetChecked(st.showMapDrops ~= false) end
    if menuChecks.pvp then menuChecks.pvp:SetChecked(st.showMapPvp ~= false) end
    if menuChecks.hearthstone then menuChecks.hearthstone:SetChecked(st.showMapHearthstone ~= false) end
    if menuChecks.sessionOnly then menuChecks.sessionOnly:SetChecked(st.showMapCurrentSession == true) end
end

local function AddMenuCheck(parent, key, label, setting, y, icon)
    local cb=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    cb:SetSize(24,24)
    cb:SetPoint("TOPLEFT",12,y)
    cb:SetHitRectInsets(0,-200,0,0) -- the whole row toggles, not just the box
    local textOffset=3
    if icon then
        -- Same picture as the marker on the map, so the list doubles as a legend.
        local tex=cb:CreateTexture(nil,"ARTWORK")
        tex:SetPoint("LEFT",cb,"RIGHT",3,0)
        if icon.color then
            tex:SetSize(16,4); tex:SetColorTexture(icon.color[1],icon.color[2],icon.color[3],1)
        else
            tex:SetSize(18,18); tex:SetTexture(icon.texture)
        end
        textOffset=26
    end
    cb.text=cb:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    cb.text:SetPoint("LEFT",cb,"RIGHT",textOffset,0)
    cb.text:SetText(label)
    cb:SetScript("OnClick",function(self)
        SetVisibilitySetting(setting,self:GetChecked())
    end)
    menuChecks[key]=cb
end

local function CreateMapMenu()
    if menuButton or not WorldMapFrame then return end

    local anchor=WorldMapFrame.ScrollContainer or WorldMapFrame

    menuButton=CreateFrame("Button",nil,WorldMapFrame,"UIPanelButtonTemplate")
    menuButton:SetSize(120,24)
    menuButton:SetPoint("TOPLEFT",anchor,"TOPLEFT",10,-10)
    menuButton:SetText("MyCharForever")
    menuButton:SetFrameStrata("HIGH")
    menuButton:SetFrameLevel(500)


    -- Same look as the addon windows: dark opaque panel, bronze border, gold section bands.
    local Kit=MCF.Kit
    local W=272
    menuFrame=Kit.Panel(WorldMapFrame,Kit.WINDOW_BG)
    menuFrame:SetSize(W,300) -- real height is set once the content is laid out
    menuFrame:SetPoint("TOPLEFT",menuButton,"BOTTOMLEFT",0,-3)
    menuFrame:SetFrameStrata("DIALOG")
    menuFrame:SetFrameLevel(600)
    MCF.MakeOpaque(menuFrame,4)
    menuFrame:Hide()

    local y=-8
    local function Band(text)
        local b=Kit.Band(menuFrame,nil)
        b:SetPoint("TOPLEFT",8,y); b:SetPoint("TOPRIGHT",-8,y)
        b:SetLabel(text)
        y=y-Kit.BAND_H-6
    end
    local function Check(key,label,setting,icon)
        AddMenuCheck(menuFrame,key,label,setting,y,icon)
        y=y-26
    end

    Band(T("Map display"))
    Check("path",T("Journey Path"),"showMapJourney",{color={1,0.85,0.1}})
    Check("levels",T("Level-Ups"),"showMapLevelUps",{texture=MCF.MarkerTexture("LevelUp")})
    Check("deaths",T("Deaths"),"showMapDeaths",{texture=MCF.MarkerTexture("Death")})
    Check("journal",T("Journal Entries"),"showMapJournal",{texture=MCF.MarkerTexture("Journal")})
    Check("iconic",T("Iconic moments"),"showMapIconic",{texture=MCF.MarkerTexture("Iconic")})
    Check("screenshots",T("Chronicle screenshots"),"showMapScreenshots",{texture=MCF.MarkerTexture("Screenshot")})
    local dropTexture=MCF.WorldDrops and MCF.WorldDrops.IconFor and MCF.WorldDrops.IconFor(4) or "Interface\\COMMON\\Indicator-Yellow"
    Check("drops",T("World Drops"),"showMapDrops",{texture=dropTexture})
    Check("pvp",T("PvP"),"showMapPvp",{texture=MCF.MarkerTexture("PvP")})
    Check("hearthstone",T("Hearthstone"),"showMapHearthstone",{texture=MCF.MarkerTexture("Hearthstone")})
    y=y-6

    Band(T("Map filter"))
    Check("sessionOnly",T("This session only"),"showMapCurrentSession")
    y=y-4

    local rangeLabel=menuFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    rangeLabel:SetPoint("TOPLEFT",16,y-4)
    rangeLabel:SetText(T("Level range"))

    -- "from [ ] to [ ]": typing is exact, the slider below is quick.
    local function RangeEdit(x)
        local e=CreateFrame("EditBox",nil,menuFrame,"InputBoxTemplate")
        e:SetPoint("TOPRIGHT",menuFrame,"TOPRIGHT",x,y)
        e:SetSize(34,22); e:SetAutoFocus(false); e:SetMaxLetters(2); e:SetNumeric(true)
        e:SetFontObject("GameFontHighlightSmall"); e:SetTextColor(1,0.82,0.15); e:SetJustifyH("CENTER")
        return e
    end
    local highEdit=RangeEdit(-16)
    local dash=menuFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    dash:SetPoint("RIGHT",highEdit,"LEFT",-6,0); dash:SetText("-")
    local lowEdit=RangeEdit(-16-34-18)
    y=y-34

    local track=CreateFrame("Frame",nil,menuFrame)
    track:SetPoint("TOPLEFT",20,y)
    track:SetSize(W-40,28)
    local line=track:CreateTexture(nil,"BACKGROUND")
    line:SetColorTexture(0.35,0.35,0.35,1)
    line:SetPoint("LEFT",0,0); line:SetPoint("RIGHT",0,0); line:SetHeight(5)

    local fill=track:CreateTexture(nil,"ARTWORK")
    fill:SetColorTexture(1,0.72,0,0.9)
    fill:SetHeight(6)

    -- Level marks every 10 levels, so the position on the slider can be read at a glance.
    for lvl=10,60,10 do
        local x=(lvl-1)/59*(W-40)
        local tick=track:CreateTexture(nil,"BORDER")
        tick:SetColorTexture(0.6,0.5,0.3,0.9); tick:SetSize(1,9)
        tick:SetPoint("TOP",track,"BOTTOMLEFT",x,4)
        local lbl=track:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
        lbl:SetPoint("TOP",track,"BOTTOMLEFT",x,-6); lbl:SetText(tostring(lvl))
    end
    y=y-28-22

    local function NewHandle()
        -- Large custom handle: much easier to grab than Blizzard's tiny slider thumb.
        local h=CreateFrame("Button",nil,track,"BackdropTemplate")
        h:SetSize(30,38) -- generous mouse target
        h:SetBackdrop({
            bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize=10,
            insets={left=3,right=3,top=3,bottom=3},
        })
        -- The button stays 30 px wide for easy grabbing, but only the
        -- central 15 px are visibly drawn.
        h:SetBackdropColor(0,0,0,0)
        h:SetBackdropBorderColor(0,0,0,0)
        local visual=CreateFrame("Frame",nil,h,"BackdropTemplate")
        visual:SetSize(15,38)
        visual:SetPoint("CENTER")
        visual:SetBackdrop({
            bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize=8,
            insets={left=2,right=2,top=2,bottom=2},
        })
        visual:SetBackdropColor(0.72,0.48,0.02,0.95)
        visual:SetBackdropBorderColor(1.00,0.82,0.20,1.00)
        local bar=visual:CreateTexture(nil,"OVERLAY")
        bar:SetSize(3,26)
        bar:SetPoint("CENTER")
        bar:SetColorTexture(1.00,0.88,0.25,1.00)
        h.visual=visual
        h:RegisterForDrag("LeftButton")
        h:SetScript("OnEnter",function(self)
            self.visual:SetBackdropColor(0.95,0.68,0.06,1)
        end)
        h:SetScript("OnLeave",function(self)
            self.visual:SetBackdropColor(0.72,0.48,0.02,0.95)
        end)
        return h
    end
    local lowHandle=NewHandle()
    local highHandle=NewHandle()

    local MIN_LEVEL,MAX_LEVEL=1,60
    local lowValue,highValue=MIN_LEVEL,MAX_LEVEL
    local dragging

    local function XForLevel(v)
        return ((v-MIN_LEVEL)/(MAX_LEVEL-MIN_LEVEL))*track:GetWidth()
    end
    local function LevelForCursor()
        local scale=track:GetEffectiveScale()
        local cx=GetCursorPosition()/scale
        local left=track:GetLeft() or 0
        local frac=math.max(0,math.min(1,(cx-left)/track:GetWidth()))
        return math.floor(MIN_LEVEL+frac*(MAX_LEVEL-MIN_LEVEL)+0.5)
    end
    local function RefreshRange()
        lowHandle:ClearAllPoints()
        highHandle:ClearAllPoints()
        lowHandle:SetPoint("CENTER",track,"LEFT",XForLevel(lowValue),0)
        highHandle:SetPoint("CENTER",track,"LEFT",XForLevel(highValue),0)
        fill:ClearAllPoints()
        fill:SetPoint("LEFT",track,"LEFT",XForLevel(lowValue),0)
        fill:SetPoint("RIGHT",track,"LEFT",XForLevel(highValue),0)
        if not lowEdit:HasFocus() then lowEdit:SetText(tostring(lowValue)) end
        if not highEdit:HasFocus() then highEdit:SetText(tostring(highValue)) end
    end
    local function SaveRange()
        if not MyCharForeverDB then return end
        MyCharForeverDB.settings=MyCharForeverDB.settings or {}
        MyCharForeverDB.settings.mapJourneyMinLevel=(lowValue==MIN_LEVEL) and nil or lowValue
        MyCharForeverDB.settings.mapJourneyMaxLevel=(highValue==MAX_LEVEL) and nil or highValue
        MCF:RefreshMapJourney()
    end
    local function ApplyRangeText()
        local a,b=tonumber(lowEdit:GetText()),tonumber(highEdit:GetText())
        lowEdit:ClearFocus(); highEdit:ClearFocus()
        if a and b then
            a=math.max(MIN_LEVEL,math.min(MAX_LEVEL,a))
            b=math.max(MIN_LEVEL,math.min(MAX_LEVEL,b))
            if a>b then a,b=b,a end
            lowValue,highValue=a,b
            RefreshRange()
            SaveRange()
        else
            RefreshRange()
        end
    end
    for _,e in ipairs({lowEdit,highEdit}) do
        e:SetScript("OnEnterPressed",ApplyRangeText)
        e:SetScript("OnEditFocusLost",function()
            -- Moving from one field to the other must not apply half an input.
            if not dragging and not lowEdit:HasFocus() and not highEdit:HasFocus() then ApplyRangeText() end
        end)
        e:SetScript("OnEscapePressed",function(self) self:ClearFocus(); RefreshRange() end)
    end
    MCF.Kit.TabOrder({lowEdit,highEdit})

    local function StartDrag(which)
        dragging=which
        track:SetScript("OnUpdate",function()
            local v=LevelForCursor()
            if dragging=="low" then lowValue=math.min(v,highValue)
            else highValue=math.max(v,lowValue) end
            RefreshRange()
        end)
    end
    local function StopDrag()
        dragging=nil
        track:SetScript("OnUpdate",nil)
        SaveRange()
    end
    lowHandle:SetScript("OnDragStart",function() StartDrag("low") end)
    lowHandle:SetScript("OnDragStop",StopDrag)
    highHandle:SetScript("OnDragStart",function() StartDrag("high") end)
    highHandle:SetScript("OnDragStop",StopDrag)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown",function()
        local v=LevelForCursor()
        if math.abs(v-lowValue)<=math.abs(v-highValue) then
            lowValue=math.min(v,highValue)
            StartDrag("low")
        else
            highValue=math.max(v,lowValue)
            StartDrag("high")
        end
        RefreshRange()
    end)
    track:SetScript("OnMouseUp",function() StopDrag() end)

    -- Quick choices: everything / only the current level / the last five levels.
    local function SetRange(a,b)
        a=math.max(MIN_LEVEL,math.min(MAX_LEVEL,a)); b=math.max(a,math.min(MAX_LEVEL,b))
        lowValue,highValue=a,b
        lowEdit:ClearFocus(); highEdit:ClearFocus()
        RefreshRange()
        SaveRange()
    end
    local quick={
        {T("All levels"),function() SetRange(MIN_LEVEL,MAX_LEVEL) end},
        {T("Current level"),function() local l=UnitLevel("player") or MIN_LEVEL; SetRange(l,l) end},
        {T("Last 5 levels"),function() local l=UnitLevel("player") or MIN_LEVEL; SetRange(l-4,l) end},
    }
    local gap=6
    local bw=math.floor((W-24-2*gap)/3)
    for i,q in ipairs(quick) do
        local b=CreateFrame("Button",nil,menuFrame,"UIPanelButtonTemplate")
        b:SetSize(bw,22)
        b:SetPoint("TOPLEFT",12+(i-1)*(bw+gap),y)
        b:SetText(q[1])
        b:SetScript("OnClick",q[2])
    end
    y=y-22-12

    menuFrame.RefreshLevelRange=function()
        local st=MyCharForeverDB and MyCharForeverDB.settings or {}
        lowValue=tonumber(st.mapJourneyMinLevel) or MIN_LEVEL
        highValue=tonumber(st.mapJourneyMaxLevel) or MAX_LEVEL
        lowValue=math.max(MIN_LEVEL,math.min(MAX_LEVEL,lowValue))
        highValue=math.max(lowValue,math.min(MAX_LEVEL,highValue))
        RefreshRange()
    end

    local journal=CreateFrame("Button",nil,menuFrame,"UIPanelButtonTemplate")
    journal:SetSize(W-24,24)
    journal:SetPoint("TOPLEFT",12,y)
    y=y-24-12
    menuFrame:SetHeight(-y)
    ApplyMenuScale()
    journal:SetText(T("+ New Journal Entry"))
    journal:SetScript("OnClick",function()
        menuFrame:Hide()
        MCF:OpenJournalEntry()
    end)

    -- The menu is open by default so the options are seen; collapsing it with the button is remembered (setting mapMenuCollapsed).
    function MCF:OpenMapMenu()
        SyncMenuChecks()
        if menuFrame.RefreshLevelRange then menuFrame.RefreshLevelRange() end
        ApplyMenuScale()
        menuFrame:Show()
    end
    menuButton:SetScript("OnClick",function()
        local settings=MyCharForeverDB and MyCharForeverDB.settings
        if menuFrame:IsShown() then
            menuFrame:Hide()
            if settings then settings.mapMenuCollapsed=true end
        else
            if settings then settings.mapMenuCollapsed=nil end
            MCF:OpenMapMenu()
        end
    end)

    if anchor and anchor.HookScript then
        anchor:HookScript("OnSizeChanged",function()
            ApplyMenuScale()
            menuButton:ClearAllPoints()
            menuButton:SetPoint("TOPLEFT",anchor,"TOPLEFT",10,-10)
            if menuFrame:IsShown() then
                menuFrame:ClearAllPoints()
                menuFrame:SetPoint("TOPLEFT",menuButton,"BOTTOMLEFT",0,-3)
            end
        end)
    end

    SyncMenuChecks()
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")

init:SetScript("OnEvent", function()
    C_Timer.After(1, function()
        if not WorldMapFrame
            or not MapCanvasDataProviderMixin
            or not MapCanvasPinMixin then
            print("|cffff4444MyCharForever: "..T("MapCanvas API unavailable.").."|r")
            return
        end

        CreateMapMenu()

        provider = CreateFromMixins(MyCharForeverMapDataProviderMixin)
        WorldMapFrame:AddDataProvider(provider)

        WorldMapFrame:HookScript("OnShow", function()
            ApplyMenuScale()
            C_Timer.After(0, ApplyMenuScale) -- the map's size is only final after its own OnShow
            SyncMenuChecks()
            local settings=MyCharForeverDB and MyCharForeverDB.settings
            if menuFrame then
                if settings and settings.mapMenuCollapsed then menuFrame:Hide() else MCF:OpenMapMenu() end
            end
        end)

        MCF:RefreshMapJourney()
    end)
end)

-- Live refresh is triggered by Journey.lua after it actually stores a point.
function MCF:RefreshJourneyMapIfVisible()
    if provider and WorldMapFrame and WorldMapFrame:IsShown() then
        provider:RefreshAllData()
    end
end
