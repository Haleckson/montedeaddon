local _, A = ...
ForeverLibraryPinMixin = {}

-- Forever can return plain coordinate tables; other clients return Vector2D.
function A.Coordinates(position)
    if not position then return end
    local x, y
    if type(position.GetXY) == "function" then
        x, y = position:GetXY()
    else
        x, y = position.x, position.y
    end
    if type(x) == "number" and type(y) == "number" then return x, y end
end

function ForeverLibraryPinMixin:OnLoad()
    if self.SetScalingLimits then self:SetScalingLimits(1, 0.85, 1.2) end
end

function ForeverLibraryPinMixin:OnClick(button)
    if self.book.quest==0 then A.Navigate(self.location); return end
    if button == "RightButton" then A.ToggleTrack(self.book)
    else A.Navigate(self.location, self.book) end
end

function ForeverLibraryPinMixin:OnMouseLeave() GameTooltip:Hide() end

function ForeverLibraryPinMixin:OnAcquired(book, location, x, y)
    self.book, self.location = book, location
    self:SetPosition(x, y)
    local tracked = A.db.tracked[book.quest]
    local _,r,g,b=A.Difficulty(book)
    self.Ring:SetVertexColor(r,g,b)
    self.Ring:SetAlpha(tracked and 1 or 0.85)
    self.Icon:SetDesaturated(book.uncertain == true)
    self:SetAlpha(book.uncertain and 0.6 or 1)
end

function ForeverLibraryPinMixin:OnMouseEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(A.Name(self.book), 1, 0.82, 0.35)
    GameTooltip:AddLine(A.Zone(self.location.map) .. string.format("  %.1f, %.1f", self.location.x, self.location.y), 1, 1, 1)
    GameTooltip:AddLine(self.location.note or self.book.note, 0.8, 0.85, 0.9, true)
    local difficulty,r,g,b=A.Difficulty(self.book)
    GameTooltip:AddLine(difficulty.." for your faction and level",r,g,b)
    if self.book.quest==0 then GameTooltip:AddLine("Turn in books and collect your rewards here. Click to navigate.",0.4,0.9,0.9,true)
    else GameTooltip:AddLine(A.Status(self.book) .. "  •  Left-click: navigate  /  Right-click: track", 0.4, 0.9, 0.9, true) end
    if self.book.uncertain then GameTooltip:AddLine("Old SoD position. Forever location is unknown.", 1, 0.5, 0.25, true) end
    GameTooltip:Show()
end

function A.PinVisible(book)
    if A.db.tracked[book.quest] then return true end
    if A.db.pinMode == "tracked" then return false end
    if book.uncertain then return false end
    return A.db.pinMode == "all" or A.Status(book) == "Missing"
end

function A.MapPosition(location, mapID)
    if location.map == mapID then return location.x / 100, location.y / 100 end
    if not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos or not CreateVector2D then return end
    -- Project only onto ancestor maps, never neighboring zones or interior maps.
    local current, ancestor = location.map, false
    for _ = 1, 8 do
        local info = C_Map.GetMapInfo(current)
        current = info and info.parentMapID
        if not current or current == 0 then break end
        if current == mapID then ancestor = true; break end
    end
    if not ancestor then return end
    local continent, world = C_Map.GetWorldPosFromMapPos(location.map, CreateVector2D(location.x / 100, location.y / 100))
    if not world then return end
    local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, mapID)
    if pos then
        local x, y = A.Coordinates(pos)
        if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then return x, y end
    end
end

function A.InstallMaps()
    if A.provider or not WorldMapFrame or not MapCanvasDataProviderMixin or not WorldMapFrame.AddDataProvider then return end
    -- MapCanvas may load on demand. Supply its base methods before acquiring pins.
    for key, value in pairs(MapCanvasPinMixin) do
        if ForeverLibraryPinMixin[key] == nil then ForeverLibraryPinMixin[key] = value end
    end
    local provider = CreateFromMixins(MapCanvasDataProviderMixin)
    function provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate("ForeverLibraryPinTemplate") end
    function provider:RefreshAllData()
        self:RemoveAllData()
        if not A.db or not A.db.showPins then return end
        local mapID = self:GetMap():GetMapID()
        local function Add(book, location)
            local x, y = A.MapPosition(location, mapID)
            if x then self:GetMap():AcquirePin("ForeverLibraryPinTemplate", book, location, x, y) end
        end
        for _, book in ipairs(A.books) do if A.PinVisible(book) then Add(book, book) end end
        local book = A.byQuest[A.alternate.quest]
        if A.PinVisible(book) then Add(book, A.alternate) end
        if A.librarianTarget then
            local target=A.librarianTarget
            Add({quest=0,item=0,name=target.note,note="Turn in books and collect rewards here."},target)
        end
    end
    WorldMapFrame:AddDataProvider(provider)
    A.provider = provider
    if A.UpdateGamepad then
        WorldMapFrame:HookScript("OnShow",A.UpdateGamepad)
        WorldMapFrame:HookScript("OnHide",A.UpdateGamepad)
    end
end

function A.Navigate(location, book)
    A.librarianTarget=not book and location or nil
    local native = false
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local allowed = not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(location.map)
        if allowed then
            local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(location.map, location.x / 100, location.y / 100))
            local point = ok and C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
            if point and point.uiMapID == location.map and point.position then
                local x, y = A.Coordinates(point.position)
                native = x ~= nil and math.abs(x - location.x / 100) < 0.0001 and math.abs(y - location.y / 100) < 0.0001
            end
            if native and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        end
    end
    if book and A.Status(book) ~= "Returned" then A.db.tracked[book.quest] = true end
    A.db.showPins = true
    if C_Map and C_Map.OpenWorldMap then C_Map.OpenWorldMap(location.map)
    elseif WorldMapFrame then WorldMapFrame:Show(); WorldMapFrame:SetMapID(location.map) end
    A.InstallMaps()
    A.Refresh()
    if not native then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffce72Forever Library Scout:|r Book pin shown on the world map. This client did not accept a native navigation waypoint.")
    end
end

function A.Librarian()
    if UnitFactionGroup("player") == "Horde" then return {map=1458, x=73.4, y=33, note="Owen Thadd • Magic Quarter, Undercity"} end
    return {map=1453, x=37.6, y=80.8, note="Garion Wendell • Mage Quarter, Stormwind"}
end
