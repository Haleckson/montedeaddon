--[[
  Forever Companion - Core/Compatibility.lua
  The only file that talks to version-dependent WoW APIs.

  WoW: Forever runs the Retail (Mainline 12.x) client while reporting
  interface 16001. Classic-era globals such as GetItemInfo or
  GetMerchantItemInfo are absent, Midnight "secret values" are active, and
  registering an unknown event throws. Everything here is feature-detected:
  the addon never branches on the build or interface number.

  Rules for callers:
    * never call a unit/tooltip API directly; use these wrappers
    * every value returned here is already stripped of secret values
]]

local _, FC = ...

local Compat = {}
FC.Compat = Compat

local U = FC.Utils

------------------------------------------------------------------------
-- Secret values (Midnight restrictions)
------------------------------------------------------------------------

local issecret = _G.issecretvalue

function Compat.IsSecret(value)
    if issecret then
        local ok, result = pcall(issecret, value)
        return ok and result or false
    end
    return false
end

--- Returns value, or nil when the client marks it secret. Must be applied
--- before any comparison, arithmetic or string operation.
function Compat.Safe(value)
    if value == nil then return nil end
    if Compat.IsSecret(value) then return nil end
    return value
end

local function pack(...)
    return { n = select("#", ...), ... }
end
Compat.Pack = pack

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = pack(pcall(fn, ...))
    if not results[1] then return nil end
    for i = 2, results.n do
        results[i] = Compat.Safe(results[i])
    end
    return unpack(results, 2, results.n)
end
Compat.SafeCall = safeCall

function Compat.InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

------------------------------------------------------------------------
-- Map and position
------------------------------------------------------------------------

-- The map the game names as the player's: a continent in some caves.
local function bestPlayerMap()
    if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
    local mapID = safeCall(C_Map.GetBestMapForUnit, "player")
    if type(mapID) == "number" and mapID > 0 then return mapID end
    return nil
end

local function playerPositionOn(mapID)
    local pos = safeCall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not pos then return nil end
    local ok, x, y = pcall(pos.GetXY, pos)
    if not ok then return nil end
    x, y = Compat.Safe(x), Compat.Safe(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    if x <= 0 and y <= 0 then return nil end
    return x, y
end

local mapTypes = {}

--- Cosmic 0, World 1, Continent 2, Zone 3, Dungeon 4, Micro 5, Orphan 6; nil when unknown.
local function mapTypeOf(mapID)
    local known = mapTypes[mapID]
    if known == nil then
        local info = Compat.GetMapInfo(mapID)
        known = info and type(Compat.Safe(info.mapType)) == "number" and info.mapType or false
        mapTypes[mapID] = known
    end
    return known or nil
end

function Compat.GetMapType(mapID)
    if type(mapID) ~= "number" then return nil end
    return mapTypeOf(mapID)
end

local function zoneType()
    return Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
end
Compat.ZONE_MAP_TYPE = zoneType()

--- The zone map under a point of a continent (or world) map, or nil. Some
--- caves and shores belong to no zone map of their own: the game then names
--- the continent as the "best map", and a discovery filed there would never
--- show on the zone map it lies in.
local function zoneMapAt(mapID, x, y)
    if not (C_Map and C_Map.GetMapInfoAtPosition) then return nil end
    local zone = zoneType()
    for _ = 1, 3 do
        local kind = mapTypeOf(mapID)
        if not kind or kind >= zone then return nil end
        local ok, child = pcall(C_Map.GetMapInfoAtPosition, mapID, x, y)
        local childID = ok and type(child) == "table" and Compat.Safe(child.mapID) or nil
        if type(childID) ~= "number" or childID == mapID then return nil end
        local childType = Compat.Safe(child.mapType)
        if childType == zone then return childID end
        if type(childType) ~= "number" or childType > zone then return nil end
        -- a continent under the world map: look once more below it
        local continentID, world = safeCall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
        local _, pos = safeCall(C_Map.GetMapPosFromWorldPos, continentID, world, childID)
        if type(pos) ~= "table" then return nil end
        mapID, x, y = childID, pos:GetXY()
        if type(x) ~= "number" or type(y) ~= "number" then return nil end
    end
    return nil
end

--- The player's map and position on it. When the game only names a
--- continent, the zone under the player is used instead.
function Compat.GetPlayerPosition(mapID)
    local asked = mapID ~= nil
    mapID = mapID or bestPlayerMap()
    if not mapID or not (C_Map and C_Map.GetPlayerMapPosition) then return nil end
    local x, y = playerPositionOn(mapID)
    if not x then return nil end
    if not asked and CreateVector2D then
        local zoneID = zoneMapAt(mapID, x, y)
        local zx, zy
        if zoneID then zx, zy = playerPositionOn(zoneID) end
        if zx and zx >= 0 and zx <= 1 and zy >= 0 and zy <= 1 then return zoneID, zx, zy end
    end
    return mapID, x, y
end

--- The player's map: the zone under the player where the game only names a
--- continent (the map discoveries there are filed on).
function Compat.GetPlayerMapID()
    return (Compat.GetPlayerPosition()) or bestPlayerMap()
end

--- A point of a continent (or world) map as a point of the zone map it lies
--- in: zoneMapID, x, y; nil when the map is a zone already, or no zone is there.
function Compat.ZonePosition(mapID, x, y)
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return nil end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
    local zoneID = zoneMapAt(mapID, x, y)
    if not zoneID then return nil end
    local continentID, world = safeCall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if type(continentID) ~= "number" or type(world) ~= "table" then return nil end
    local _, pos = safeCall(C_Map.GetMapPosFromWorldPos, continentID, world, zoneID)
    if type(pos) ~= "table" or not pos.GetXY then return nil end
    local zx, zy = pos:GetXY()
    zx, zy = Compat.Safe(zx), Compat.Safe(zy)
    if type(zx) ~= "number" or type(zy) ~= "number" or zx < 0 or zx > 1 or zy < 0 or zy > 1 then return nil end
    return zoneID, zx, zy
end

--- The player's world position: north, west (yards) and the instance ID.
function Compat.GetPlayerWorldPosition()
    local north, west, _, instance = Compat.SafeCall(_G.UnitPosition, "player")
    if type(north) ~= "number" or type(west) ~= "number" then return nil end
    return north, west, instance
end

--- World position of a normalized map position: north, west (yards) and instance.
function Compat.GetWorldPosition(mapID, x, y)
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, instance, position = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if not ok or type(position) ~= "table" then return nil end
    local north, west = position:GetXY()
    north, west = Compat.Safe(north), Compat.Safe(west)
    if type(north) ~= "number" or type(west) ~= "number" then return nil end
    return north, west, Compat.Safe(instance)
end

function Compat.GetMinimapViewRadius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local radius = Compat.SafeCall(C_Minimap.GetViewRadius)
        if type(radius) == "number" and radius > 0 then return radius end
    end
    return 200
end

function Compat.GetMapInfo(mapID)
    if not mapID or not (C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok and type(info) == "table" then return info end
    return nil
end

function Compat.GetMapName(mapID)
    local info = Compat.GetMapInfo(mapID)
    return info and info.name or nil
end

function Compat.GetMapWorldSize(mapID)
    if C_Map and C_Map.GetMapWorldSize then
        local w, h = safeCall(C_Map.GetMapWorldSize, mapID)
        if type(w) == "number" and w > 0 then return w, h end
    end
    return nil
end

function Compat.GetZoneTexts()
    local zone = safeCall(GetRealZoneText) or safeCall(GetZoneText) or ""
    local sub = safeCall(GetSubZoneText) or ""
    return zone, sub
end

function Compat.GetInstance()
    if not IsInInstance then return nil end
    local inInstance, instanceType = safeCall(IsInInstance)
    if not inInstance or instanceType == "none" then return nil end
    local name, _, difficultyID, _, _, _, _, instanceID = safeCall(GetInstanceInfo)
    return {
        name = name,
        type = instanceType,
        difficultyID = difficultyID,
        instanceID = instanceID,
    }
end

-- Where an explored piece of a map is asked which areas it holds: its middle
-- first, then four points around it (a piece can hold more than one area).
local EXPLORED_SAMPLES = { { 0.5, 0.5 }, { 0.3, 0.3 }, { 0.7, 0.3 }, { 0.3, 0.7 }, { 0.7, 0.7 } }

--- The areas of a zone map this character has explored, as the game still
--- remembers them: { { areaID, name, x, y } }, x and y being the place of
--- the area on the map (inside the piece of map exploring it uncovered).
--- nil when the client cannot tell; an empty list for a map with nothing
--- explored (or one that is never hidden).
function Compat.GetExploredAreas(mapID)
    local E, M = _G.C_MapExplorationInfo, _G.C_Map
    if type(mapID) ~= "number" or not (E and E.GetExploredMapTextures and E.GetExploredAreaIDsAtPosition) then return nil end
    if not (M and M.GetAreaInfo and M.GetMapArtLayers and CreateVector2D) then return nil end
    local okLayers, layers = pcall(M.GetMapArtLayers, mapID)
    local layer = okLayers and type(layers) == "table" and layers[1]
    if type(layer) ~= "table" then return nil end
    local width, height = Compat.Safe(layer.layerWidth), Compat.Safe(layer.layerHeight)
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then return nil end
    local okTextures, textures = pcall(E.GetExploredMapTextures, mapID)
    if not okTextures or type(textures) ~= "table" then return nil end
    local out, seen = {}, {}
    for _, piece in ipairs(textures) do
        local left, top = Compat.Safe(piece.offsetX), Compat.Safe(piece.offsetY)
        local pieceWidth, pieceHeight = Compat.Safe(piece.textureWidth), Compat.Safe(piece.textureHeight)
        if type(left) == "number" and type(top) == "number" and type(pieceWidth) == "number" and type(pieceHeight) == "number"
            and pieceWidth > 0 and pieceHeight > 0 then
            for _, sample in ipairs(EXPLORED_SAMPLES) do
                local x, y = (left + pieceWidth * sample[1]) / width, (top + pieceHeight * sample[2]) / height
                if x > 0 and x < 1 and y > 0 and y < 1 then
                    local ok, areaIDs = pcall(E.GetExploredAreaIDsAtPosition, mapID, CreateVector2D(x, y))
                    for _, areaID in ipairs(ok and type(areaIDs) == "table" and areaIDs or {}) do
                        areaID = Compat.Safe(areaID)
                        if type(areaID) == "number" and not seen[areaID] then
                            seen[areaID] = true
                            local name = safeCall(M.GetAreaInfo, areaID)
                            if type(name) == "string" and name ~= "" then
                                out[#out + 1] = { areaID = areaID, name = name, x = U.Round(x, 4), y = U.Round(y, 4) }
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end

function Compat.GetZoneChildren(parentMapID)
    local list = {}
    if not (C_Map and C_Map.GetMapChildrenInfo) then return list end
    local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
    local ok, children = pcall(C_Map.GetMapChildrenInfo, parentMapID, zoneType, true)
    if ok and type(children) == "table" then
        for _, child in ipairs(children) do list[#list + 1] = child end
    end
    return list
end

------------------------------------------------------------------------
-- Units
------------------------------------------------------------------------

--- Splits a GUID into its type and numeric id (NPC or object id).
function Compat.ParseGUID(guid)
    guid = Compat.Safe(guid)
    if type(guid) ~= "string" then return nil end
    local unitType, _, _, _, _, id = strsplit("-", guid)
    return unitType, tonumber(id)
end

local SPAWN_CYCLE = 2 ^ 23 -- the spawn time in a creature GUID counts seconds modulo this

--- When a creature spawned (server time) and the layer (zone UID) it lives
--- on, both read from its GUID: Creature-0-server-instance-zone-npc-spawn.
function Compat.GetSpawnInfo(guid)
    guid = Compat.Safe(guid)
    if type(guid) ~= "string" then return nil end
    local unitType, _, _, _, zoneUID, _, spawnUID = strsplit("-", guid)
    if (unitType ~= "Creature" and unitType ~= "Vehicle") or type(spawnUID) ~= "string" or #spawnUID < 6 then return nil end
    local low = tonumber(spawnUID:sub(5), 16)
    if not low then return nil end
    local now = U.Now()
    local spawned = now - (now % SPAWN_CYCLE) + (low % SPAWN_CYCLE)
    if spawned > now then spawned = spawned - SPAWN_CYCLE end
    return spawned, tonumber(zoneUID)
end

--- Returns a table describing a unit, or nil. All fields are secret-safe.
function Compat.GetUnitInfo(unit)
    if not UnitExists or not safeCall(UnitExists, unit) then return nil end
    local guid = safeCall(UnitGUID, unit)
    local unitType, id = Compat.ParseGUID(guid)
    local info = {
        guid = guid,
        guidType = unitType,
        name = safeCall(UnitName, unit),
        level = safeCall(UnitLevel, unit),
        classification = safeCall(UnitClassification, unit),
        creatureType = safeCall(UnitCreatureType, unit),
        isPlayer = safeCall(UnitIsPlayer, unit) and true or false,
        isDead = safeCall(UnitIsDead, unit) and true or false,
    }
    if unitType == "Creature" or unitType == "Vehicle" then
        info.npcID = id
    end
    return info
end

function Compat.GetUnitTooltipLines(unit)
    local lines = {}
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return lines end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return lines end
    for _, line in ipairs(data.lines) do
        local text = Compat.Safe(line.leftText)
        if type(text) == "string" then lines[#lines + 1] = text end
    end
    return lines
end

--- A unit's name as the game shows it: with its surname on Forever.
function Compat.GetUnitDisplayName(unit)
    local name, surname = safeCall(UnitName, unit)
    if type(name) ~= "string" or name == "" then return nil end
    local separator = U.SurnameSeparator()
    if separator and type(surname) == "string" and surname ~= "" then return name .. separator .. surname end
    return name
end

function Compat.GetClassFile()
    local _, classFile = safeCall(UnitClass, "player")
    return classFile or "UNKNOWN"
end

function Compat.GetClassName()
    local className = safeCall(UnitClass, "player")
    return className or "?"
end

--- "rrggbb" of a class ("WARRIOR", "MAGE" ...), or nil for an unknown class.
function Compat.ClassColorHex(classFile)
    if type(classFile) ~= "string" then return nil end
    if C_ClassColor and C_ClassColor.GetClassColor then
        local ok, color = pcall(C_ClassColor.GetClassColor, classFile)
        if ok and type(color) == "table" and color.GetRGB then
            local r, g, b = color:GetRGB()
            if type(r) == "number" then return U.RGBToHex(r, g, b) end
        end
    end
    local colors = _G.RAID_CLASS_COLORS
    local c = type(colors) == "table" and colors[classFile]
    if type(c) == "table" and type(c.r) == "number" then return U.RGBToHex(c.r, c.g, c.b) end
    return nil
end

function Compat.CanAttack(unit)
    return safeCall(_G.UnitCanAttack, "player", unit) and true or false
end

------------------------------------------------------------------------
-- Player movement state
------------------------------------------------------------------------

function Compat.IsIndoors()
    return safeCall(_G.IsIndoors) and true or false
end

function Compat.IsResting()
    return safeCall(_G.IsResting) and true or false
end

--- On a flight path, flying, or in a vehicle: movement that is not exploration.
function Compat.IsTraveling()
    if safeCall(_G.UnitOnTaxi, "player") then return true end
    if safeCall(_G.IsFlying) then return true end
    if safeCall(_G.UnitInVehicle, "player") then return true end
    return false
end

--- Whether the player is moving by their own means: true or false, nil when
--- the client does not say. Standing on a ship or a zeppelin under way is
--- not moving, although the position on the map changes.
function Compat.IsMovingOnFoot()
    local speed = safeCall(_G.GetUnitSpeed, "player")
    if type(speed) ~= "number" then return nil end
    return speed > 0
end

--- Whether the open loot window is a fishing catch (nil when the client
--- does not say).
function Compat.IsFishingLoot()
    if type(_G.IsFishingLoot) ~= "function" then return nil end
    local ok, fishing = pcall(_G.IsFishingLoot)
    if not ok then return nil end
    return Compat.Safe(fishing) and true or false
end

------------------------------------------------------------------------
-- Spells, gossip, readable text, game messages
------------------------------------------------------------------------

function Compat.GetSpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        return (safeCall(C_Spell.GetSpellName, spellID))
    end
    if _G.GetSpellInfo then
        return (safeCall(_G.GetSpellInfo, spellID))
    end
    return nil
end

function Compat.GetGossipText()
    if C_GossipInfo and C_GossipInfo.GetText then
        local text = safeCall(C_GossipInfo.GetText)
        if type(text) == "string" and text ~= "" then return text end
    end
    return nil
end

-- Icons of the gossip window, by texture name: what an option offers.
-- Retail options only carry the icon's file ID; older clients sent a type
-- string instead. File IDs are resolved in game when the client can, the
-- numbers here are the fallback.
local GOSSIP_ICONS = {
    ActiveQuestIcon = { 132048, "quest" },
    AvailableQuestIcon = { 132049, "quest" },
    BankerGossipIcon = { 132050, "banker" },
    BattleMasterGossipIcon = { 132051, "battlemaster" },
    BinderGossipIcon = { 132052, "binder" },
    GossipGossipIcon = { 132053, "gossip" },
    HealerGossipIcon = { 132054, "healer" },
    IncompleteQuestIcon = { 132055, "quest" },
    PetitionGossipIcon = { 132056, "petition" },
    TabardGossipIcon = { 132057, "tabard" },
    TaxiGossipIcon = { 132058, "taxi" },
    TrainerGossipIcon = { 132059, "trainer" },
    VendorGossipIcon = { 132060, "vendor" },
}

local gossipIconKinds, textureProbe

local function fileIDOf(path)
    local id = safeCall(_G.GetFileIDFromPath, path)
    if type(id) == "number" and id > 0 then return id end
    if not CreateFrame then return nil end
    textureProbe = textureProbe or CreateFrame("Frame"):CreateTexture()
    local probe = textureProbe
    if not pcall(probe.SetTexture, probe, path) then return nil end
    id = safeCall(probe.GetTextureFileID, probe)
    if type(id) == "number" and id > 0 then return id end
    return nil
end

local function buildGossipIconKinds()
    gossipIconKinds = {}
    for file, entry in pairs(GOSSIP_ICONS) do
        gossipIconKinds[entry[1]] = entry[2]
        gossipIconKinds["interface\\gossipframe\\" .. file:lower()] = entry[2]
    end
    -- file IDs reported by the client win over the fallback numbers
    for file, entry in pairs(GOSSIP_ICONS) do
        local id = fileIDOf("Interface\\GossipFrame\\" .. file)
        if id then gossipIconKinds[id] = entry[2] end
    end
end

--- What a gossip option offers: "gossip" (plain talk), "quest", a service
--- ("vendor", "trainer", "taxi", "binder", "banker", ...) or "other" for an
--- icon this table does not know.
local function gossipOptionKind(option)
    if not gossipIconKinds then buildGossipIconKinds() end
    local optionType = Compat.Safe(option.type)
    if type(optionType) == "string" and optionType ~= "" then return optionType:lower() end
    for _, key in ipairs({ "overrideIconID", "icon" }) do
        local icon = Compat.Safe(option[key])
        if type(icon) == "string" then
            icon = icon:lower():gsub("/", "\\"):gsub("%.blp$", "")
        end
        if icon ~= nil and gossipIconKinds[icon] then return gossipIconKinds[icon] end
    end
    return "other"
end

--- The open gossip window: greeting text, what each option offers, and the
--- number of quests the NPC has for you (available and in progress).
function Compat.GetGossipInfo()
    local info = { text = Compat.GetGossipText(), kinds = {}, quests = 0 }
    local G = C_GossipInfo
    if not G then return info end
    local ok, options = pcall(G.GetOptions)
    if ok and type(options) == "table" then
        for _, option in ipairs(options) do
            if type(option) == "table" then info.kinds[#info.kinds + 1] = gossipOptionKind(option) end
        end
    end
    for _, count in ipairs({ safeCall(G.GetNumAvailableQuests) or 0, safeCall(G.GetNumActiveQuests) or 0 }) do
        if type(count) == "number" and count > 0 then info.quests = info.quests + count end
    end
    return info
end

--- Title and first page of the text frame (books, plaques, letters).
function Compat.GetReadableText()
    local title = safeCall(_G.ItemTextGetItem)
    local text = safeCall(_G.ItemTextGetText)
    if type(title) ~= "string" or title == "" then return nil end
    return title, type(text) == "string" and text or nil
end

--- Lua pattern from a client format string such as "Discovered: %s".
function Compat.PatternFromGlobal(name)
    local template = _G[name]
    if type(template) ~= "string" then return nil end
    local pattern = template:gsub("%%%d?%$?", "%%"):gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")
    pattern = pattern:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

------------------------------------------------------------------------
-- Items
------------------------------------------------------------------------

Compat.ITEM_CLASS_RECIPE = (Enum and Enum.ItemClass and Enum.ItemClass.Recipe) or 9

function Compat.GetItemInfoInstant(item)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if not fn or not item then return nil end
    local itemID, itemType, subType, _, icon, classID, subClassID = safeCall(fn, item)
    if not itemID then return nil end
    return { itemID = itemID, icon = icon, classID = classID, subClassID = subClassID, itemType = itemType, subType = subType }
end

function Compat.GetItemInfo(item)
    local fn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if not fn or not item then return nil end
    local name, link, quality, _, minLevel, _, _, _, _, icon = safeCall(fn, item)
    if not name then return nil end
    return { name = name, link = link, quality = quality, icon = icon, minLevel = minLevel }
end

--- Item name if the client has it cached (nil otherwise; it loads meanwhile).
function Compat.GetItemName(itemID)
    if C_Item and C_Item.GetItemNameByID then
        local name = safeCall(C_Item.GetItemNameByID, itemID)
        if type(name) == "string" and name ~= "" then return name end
    end
    local info = Compat.GetItemInfo(itemID)
    return info and info.name or nil
end

function Compat.GetItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

function Compat.GetQualityHex(quality)
    if C_Item and C_Item.GetItemQualityColor and quality then
        local r, g, b, hex = safeCall(C_Item.GetItemQualityColor, quality)
        if type(hex) == "string" then return hex:sub(-6) end
        if r then return U.RGBToHex(r, g, b) end
    end
    local colors = _G.ITEM_QUALITY_COLORS
    if colors and quality and colors[quality] then
        local c = colors[quality]
        return U.RGBToHex(c.r, c.g, c.b)
    end
    return "ffffff"
end

function Compat.GetRecipeSubclassName(subClassID)
    if C_Item and C_Item.GetItemSubClassInfo then
        local name = safeCall(C_Item.GetItemSubClassInfo, Compat.ITEM_CLASS_RECIPE, subClassID)
        if type(name) == "string" then return name end
    end
    return nil
end

--- Reads tooltip text of an item link or id. Used for "Requires <Profession> (N)"
--- and "Already known". Returns an array of left-side lines.
function Compat.GetItemTooltipLines(item)
    local lines = {}
    if not C_TooltipInfo then return lines end
    local ok, data
    if type(item) == "number" and C_TooltipInfo.GetItemByID then
        ok, data = pcall(C_TooltipInfo.GetItemByID, item)
    elseif type(item) == "string" and C_TooltipInfo.GetHyperlink then
        ok, data = pcall(C_TooltipInfo.GetHyperlink, item)
    end
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return lines end
    for _, line in ipairs(data.lines) do
        local text = Compat.Safe(line.leftText)
        if type(text) == "string" then lines[#lines + 1] = text end
    end
    return lines
end

--- true / false when the tooltip tells us, nil when unknown.
function Compat.IsRecipeKnown(itemID)
    local known = _G.ITEM_SPELL_KNOWN
    if not known then return nil end
    local lines = Compat.GetItemTooltipLines(itemID)
    if #lines == 0 then return nil end
    for _, text in ipairs(lines) do
        if text == known then return true end
    end
    return false
end

------------------------------------------------------------------------
-- Merchant
------------------------------------------------------------------------

function Compat.GetMerchantUnitInfo()
    return Compat.GetUnitInfo("npc")
end

--- Returns the current merchant's items: { name, itemID, link, icon, numAvailable, classID, subClassID }.
function Compat.GetMerchantItems()
    local items = {}
    local count = safeCall(_G.GetMerchantNumItems) or (C_MerchantFrame and safeCall(C_MerchantFrame.GetNumItems)) or 0
    for index = 1, count do
        local name, icon, numAvailable
        if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
            local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
            if ok and type(info) == "table" then
                name, icon, numAvailable = Compat.Safe(info.name), Compat.Safe(info.texture), Compat.Safe(info.numAvailable)
            end
        elseif _G.GetMerchantItemInfo then
            local n, tex, _, _, avail = safeCall(_G.GetMerchantItemInfo, index)
            name, icon, numAvailable = n, tex, avail
        end
        local link = safeCall(_G.GetMerchantItemLink, index)
        if not link and C_MerchantFrame and C_MerchantFrame.GetItemLink then
            link = safeCall(C_MerchantFrame.GetItemLink, index)
        end
        local itemID = Compat.GetItemIDFromLink(link)
        if itemID then
            local instant = Compat.GetItemInfoInstant(itemID) or {}
            items[#items + 1] = {
                name = name,
                itemID = itemID,
                link = link,
                icon = icon or instant.icon,
                numAvailable = type(numAvailable) == "number" and numAvailable or -1,
                classID = instant.classID,
                subClassID = instant.subClassID,
            }
        end
    end
    return items, count
end

------------------------------------------------------------------------
-- Quests
------------------------------------------------------------------------

--- This character's progress on a quest: "done", "ready" (to turn in),
--- "active" (in the quest log) or "open". nil when the client cannot tell.
function Compat.GetQuestStatus(questID)
    if type(questID) ~= "number" then return nil end
    local Q = C_QuestLog
    local completed = (Q and Q.IsQuestFlaggedCompleted) or _G.IsQuestFlaggedCompleted
    if not completed then return nil end
    if safeCall(completed, questID) then return "done" end
    if Q and Q.ReadyForTurnIn and safeCall(Q.ReadyForTurnIn, questID) then return "ready" end
    if Q and Q.IsOnQuest and safeCall(Q.IsOnQuest, questID) then return "active" end
    if Q and Q.GetLogIndexForQuestID and safeCall(Q.GetLogIndexForQuestID, questID) then return "active" end
    return "open"
end

--- Quests offered and in progress in the open NPC dialog, from the gossip
--- window or the older quest greeting window: { available = {}, active = {} }
--- with { questID, title } entries.
function Compat.GetDialogQuests()
    local result = { available = {}, active = {} }
    local function add(list, questID, title)
        questID, title = Compat.Safe(questID), Compat.Safe(title)
        if type(questID) == "number" and questID > 0 then
            list[#list + 1] = { questID = questID, title = type(title) == "string" and title or nil }
        end
    end
    local G = C_GossipInfo
    if G and G.GetAvailableQuests then
        local ok, quests = pcall(G.GetAvailableQuests)
        if ok and type(quests) == "table" then
            for _, q in ipairs(quests) do if type(q) == "table" then add(result.available, q.questID, q.title) end end
        end
    end
    if G and G.GetActiveQuests then
        local ok, quests = pcall(G.GetActiveQuests)
        if ok and type(quests) == "table" then
            for _, q in ipairs(quests) do if type(q) == "table" then add(result.active, q.questID, q.title) end end
        end
    end
    if #result.available == 0 and _G.GetNumAvailableQuests and _G.GetAvailableQuestInfo then
        for i = 1, safeCall(_G.GetNumAvailableQuests) or 0 do
            local _, _, _, _, questID = safeCall(_G.GetAvailableQuestInfo, i)
            add(result.available, questID, safeCall(_G.GetAvailableTitle, i))
        end
    end
    if #result.active == 0 and _G.GetNumActiveQuests and _G.GetActiveQuestID then
        for i = 1, safeCall(_G.GetNumActiveQuests) or 0 do
            add(result.active, safeCall(_G.GetActiveQuestID, i), safeCall(_G.GetActiveTitle, i))
        end
    end
    return result
end

--- The quest shown in the quest frame (details, progress or reward page).
function Compat.GetShownQuest()
    local questID = safeCall(_G.GetQuestID)
    if type(questID) ~= "number" or questID <= 0 then return nil end
    local title = safeCall(_G.GetTitleText)
    return questID, type(title) == "string" and title ~= "" and title or nil
end

--- A creature's name by NPC ID, from the game's tooltip for a creature
--- link (nil until the client has it; asking also requests it).
function Compat.GetCreatureName(npcID)
    if type(npcID) ~= "number" or not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, "unit:Creature-0-0-0-0-" .. npcID .. "-0000000000")
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" or type(data.lines[1]) ~= "table" then return nil end
    local name = Compat.Safe(data.lines[1].leftText)
    if type(name) ~= "string" or name == "" or name:find("^%?") then return nil end
    -- what the client shows while it fetches the creature is not its name
    if name == _G.RETRIEVING_DATA or name == _G.UNKNOWN then return nil end
    return name
end

--- An achievement: { name, completed, criteria = { { text, completed } } },
--- or nil when the client has no achievements.
function Compat.GetAchievement(achievementID)
    if type(achievementID) ~= "number" or not _G.GetAchievementInfo then return nil end
    local _, name, _, completed = safeCall(_G.GetAchievementInfo, achievementID)
    if type(name) ~= "string" or name == "" then return nil end
    local out = { name = name, completed = completed and true or false, criteria = {} }
    if _G.GetAchievementNumCriteria and _G.GetAchievementCriteriaInfo then
        for i = 1, math.min(safeCall(_G.GetAchievementNumCriteria, achievementID) or 0, 60) do
            local text, _, done = safeCall(_G.GetAchievementCriteriaInfo, achievementID, i)
            if type(text) == "string" and text ~= "" then
                out.criteria[#out.criteria + 1] = { text = text, completed = done and true or false }
            end
        end
    end
    return out
end

--- The quests in your quest log by title: { [title] = questID }.
function Compat.GetQuestLogTitles()
    local out = {}
    local Q = C_QuestLog
    if Q and Q.GetNumQuestLogEntries and Q.GetInfo then
        for i = 1, safeCall(Q.GetNumQuestLogEntries) or 0 do
            local ok, info = pcall(Q.GetInfo, i)
            if ok and type(info) == "table" and not Compat.Safe(info.isHeader) then
                local title, questID = Compat.Safe(info.title), Compat.Safe(info.questID)
                if type(title) == "string" and type(questID) == "number" and questID > 0 then out[title] = questID end
            end
        end
    elseif _G.GetNumQuestLogEntries and _G.GetQuestLogTitle then
        for i = 1, safeCall(_G.GetNumQuestLogEntries) or 0 do
            local title, _, _, isHeader, _, _, _, questID = safeCall(_G.GetQuestLogTitle, i)
            if type(title) == "string" and not isHeader and type(questID) == "number" and questID > 0 then out[title] = questID end
        end
    end
    return out
end

--- The quests a unit's tooltip names: each quest title line with the
--- objective lines under it. { { questID, title, progress = "7/12",
--- completed = true / false / nil } }. A title line carries its quest ID
--- when the client gives one; otherwise the quest log's titles tell it.
function Compat.ReadQuestLines(lines)
    local out = {}
    if type(lines) ~= "table" then return out end
    local types = Enum and Enum.TooltipDataLineType or {}
    local titleType, objectiveType = types.QuestTitle, types.QuestObjective
    local logTitles, current
    for index, line in ipairs(lines) do
        if type(line) == "table" then
            local kind, text = Compat.Safe(line.type), Compat.Safe(line.leftText)
            if objectiveType ~= nil and kind == objectiveType then
                if current then
                    if type(text) == "string" then
                        local done, total = text:match("(%d+)%s*/%s*(%d+)")
                        if done then current.progress = done .. "/" .. total end
                    end
                    local completed = Compat.Safe(line.completed)
                    if completed == false then
                        current.completed = false
                    elseif completed == true and current.completed == nil then
                        current.completed = true
                    end
                end
            elseif index > 1 and type(text) == "string" and text ~= "" and (kind == nil or titleType == nil or kind == titleType) then
                local questID = kind == titleType and Compat.Safe(line.id) or nil
                if type(questID) ~= "number" or questID <= 0 then
                    logTitles = logTitles or Compat.GetQuestLogTitles()
                    questID = logTitles[text]
                end
                if questID then
                    current = { questID = questID, title = text }
                    out[#out + 1] = current
                elseif kind == titleType then
                    current = nil
                end
            end
        end
    end
    return out
end

--- Asks the client to load a quest it has not cached yet (its title arrives
--- with QUEST_DATA_LOAD_RESULT). Each quest is asked for at most every 30 s.
local questRequests = {}
function Compat.RequestQuestData(questID)
    if type(questID) ~= "number" or not (C_QuestLog and C_QuestLog.RequestLoadQuestByID) then return false end
    local now = GetTime()
    if questRequests[questID] and now - questRequests[questID] < 30 then return false end
    questRequests[questID] = now
    return pcall(C_QuestLog.RequestLoadQuestByID, questID)
end

--- Whether the client can be asked for a quest it has not loaded.
function Compat.CanLoadQuests()
    return C_QuestLog ~= nil and type(C_QuestLog.RequestLoadQuestByID) == "function"
end

--- Asks the client to load a quest, without the pause RequestQuestData keeps
--- between two requests for the same quest: for a caller that paces its
--- own requests (QuestHistory). False when the client cannot be asked.
function Compat.LoadQuest(questID)
    if type(questID) ~= "number" or not Compat.CanLoadQuests() then return false end
    questRequests[questID] = GetTime()
    return (pcall(C_QuestLog.RequestLoadQuestByID, questID))
end

function Compat.GetQuestTitle(questID)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = safeCall(C_QuestLog.GetTitleForQuestID, questID)
        if type(title) == "string" and title ~= "" then return title end
    end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetInfo then
        local index = safeCall(C_QuestLog.GetLogIndexForQuestID, questID)
        if index then
            local ok, info = pcall(C_QuestLog.GetInfo, index)
            if ok and type(info) == "table" and Compat.Safe(info.title) then return info.title end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Loot
------------------------------------------------------------------------

--- Returns { { link, itemID, quality, icon, name, isQuestItem, questID, sources = { {guidType, id} } } }.
--- questID is set for items that start a quest.
function Compat.GetLootItems()
    local items = {}
    local count = safeCall(GetNumLootItems) or 0
    for slot = 1, count do
        local link = safeCall(GetLootSlotLink, slot)
        local itemID = Compat.GetItemIDFromLink(link)
        if itemID then
            local icon, name, _, _, quality, _, isQuestItem, questID = safeCall(GetLootSlotInfo, slot)
            local entry = {
                link = link, itemID = itemID, icon = icon, name = name, quality = quality,
                isQuestItem = isQuestItem and true or false,
                questID = type(questID) == "number" and questID > 0 and questID or nil,
                sources = {},
            }
            if GetLootSourceInfo then
                local sourceData = pack(pcall(GetLootSourceInfo, slot))
                if sourceData[1] then
                    for i = 2, sourceData.n, 2 do
                        local guidType, id = Compat.ParseGUID(sourceData[i])
                        if guidType then entry.sources[#entry.sources + 1] = { guidType = guidType, id = id } end
                    end
                end
            end
            items[#items + 1] = entry
        end
    end
    return items
end

------------------------------------------------------------------------
-- Addon messaging
------------------------------------------------------------------------

function Compat.RegisterAddonPrefix(prefix)
    local fn = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or _G.RegisterAddonMessagePrefix
    if not fn then return false end
    local ok, result = pcall(fn, prefix)
    return ok and result ~= false
end

--- Sends an addon message. Returns true on success, false + reason otherwise.
function Compat.SendAddonMessage(prefix, text, channel, target)
    local fn = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or _G.SendAddonMessage
    if not fn then return false, "unavailable" end
    local ok, result = pcall(fn, prefix, text, channel, target)
    if not ok then return false, tostring(result) end
    if result == nil or result == true then return true end
    if type(result) == "number" then
        local enum = Enum and Enum.SendAddonMessageResult
        if (enum and result == enum.Success) or result == 0 then return true end
        if enum and (result == enum.AddonMessageThrottle or result == enum.ChannelThrottle or result == enum.GeneralError) then
            return false, "throttle"
        end
        return false, "code" .. result
    end
    return result ~= false, "failed"
end

--- True while the client blocks addon communication (restricted content).
function Compat.InMessagingLockdown()
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
        local ok, locked = pcall(C_ChatInfo.InChatMessagingLockdown)
        if ok and Compat.Safe(locked) then return true end
    end
    return false
end

function Compat.IsInGuild()
    return safeCall(IsInGuild) and true or false
end

function Compat.GetGuildName()
    return (safeCall(GetGuildInfo, "player"))
end

function Compat.IsInGroup()
    return safeCall(IsInGroup) and true or false
end

function Compat.IsInRaid()
    return safeCall(IsInRaid) and true or false
end

------------------------------------------------------------------------
-- Waypoints and world map
------------------------------------------------------------------------

function Compat.CanSetUserWaypoint(mapID)
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then return false end
    if C_Map.CanSetUserWaypointOnMap then
        return safeCall(C_Map.CanSetUserWaypointOnMap, mapID) and true or false
    end
    return true
end

function Compat.SetUserWaypoint(mapID, x, y)
    if not Compat.CanSetUserWaypoint(mapID) then return false end
    local ok = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)
    return ok
end

function Compat.OpenWorldMap(mapID)
    if OpenWorldMap then
        local ok = pcall(OpenWorldMap, mapID)
        if ok then return true end
    end
    if WorldMapFrame then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then pcall(ToggleWorldMap) end
        if mapID and WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID) end
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Sound, colors, chat, tooltips
------------------------------------------------------------------------

Compat.SOUNDS = { "MAP_PING", "IG_QUEST_LOG_OPEN", "READY_CHECK", "TELL_MESSAGE", "UI_EPICLOOT_TOAST", "IG_MAINMENU_OPTION_CHECKBOX_ON" }

function Compat.PlaySoundKit(name)
    local kit = _G.SOUNDKIT and _G.SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit, "Master") end
end

function Compat.SoundAvailable(name)
    return _G.SOUNDKIT and _G.SOUNDKIT[name] ~= nil
end

--- Opens the Blizzard color picker. callback(r, g, b) is called live and on cancel with the original.
function Compat.OpenColorPicker(r, g, b, callback)
    local picker = _G.ColorPickerFrame
    if not picker then return false end
    local function current()
        if picker.GetColorRGB then return picker:GetColorRGB() end
        return r, g, b
    end
    if picker.SetupColorPickerAndShow then
        pcall(picker.SetupColorPickerAndShow, picker, {
            r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = function() callback(current()) end,
            cancelFunc = function() callback(r, g, b) end,
        })
        return true
    end
    picker.func = function() callback(current()) end
    picker.cancelFunc = function() callback(r, g, b) end
    picker.hasOpacity = false
    if picker.SetColorRGB then picker:SetColorRGB(r, g, b) end
    picker:Show()
    return true
end

--- 12g 34s 56c
function Compat.FormatMoney(copper)
    copper = math.floor(copper or 0)
    local gold, silver, rest = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = U.Colorize(U.FormatNumber(gold) .. "g", "ffd100") end
    if silver > 0 or gold > 0 then parts[#parts + 1] = U.Colorize(silver .. "s", "e6e6e6") end
    parts[#parts + 1] = U.Colorize(rest .. "c", "eda55f")
    return table.concat(parts, " ")
end

function Compat.AddChatFilter(event, fn)
    local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or _G.ChatFrame_AddMessageEventFilter
    if add then pcall(add, event, fn) return true end
    return false
end

--- Puts text into the chat box being typed in, or opens the chat box with
--- it. The Forever client only has the ChatFrameUtil functions; the
--- ChatEdit_ / ChatFrame_ globals belong to older clients.
function Compat.InsertChatLink(text)
    if type(text) ~= "string" or text == "" then return false end
    local insert = (ChatFrameUtil and ChatFrameUtil.InsertLink) or _G.ChatEdit_InsertLink
    if type(insert) == "function" then
        local ok, inserted = pcall(insert, text)
        if ok and inserted then return true end
    end
    local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or _G.ChatFrame_OpenChat
    if type(open) == "function" then return (pcall(open, text)) end
    return false
end

--- Registers a post-call for unit or item tooltips. fn(tooltip, data).
function Compat.HookTooltip(kind, fn)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        local dataType = Enum.TooltipDataType[kind]
        if dataType then
            TooltipDataProcessor.AddTooltipPostCall(dataType, function(tooltip, data)
                FC:SafeCall("tooltip:" .. kind, fn, tooltip, data)
            end)
            return true
        end
    end
    return false
end

--- Returns the unit token shown in a tooltip, if any.
function Compat.GetTooltipUnit(tooltip)
    if TooltipUtil and TooltipUtil.GetDisplayedUnit then
        local _, unit = safeCall(TooltipUtil.GetDisplayedUnit, tooltip)
        return unit
    end
    if tooltip and tooltip.GetUnit then
        local _, unit = safeCall(tooltip.GetUnit, tooltip)
        return unit
    end
    return nil
end

function Compat.GetAddOnLoaded(name)
    local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
    if not fn then return false end
    local ok, loaded = pcall(fn, name)
    return ok and loaded and true or false
end

function Compat.GetScreenPixel()
    local physicalHeight = 768
    if GetPhysicalScreenSize then
        local _, h = GetPhysicalScreenSize()
        if type(h) == "number" and h > 0 then physicalHeight = h end
    end
    return 768 / physicalHeight
end
