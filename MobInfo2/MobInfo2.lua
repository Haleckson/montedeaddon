--
-- MobInfo-2 is a World of Warcraft AddOn that provides you with useful
-- additional information about Mobs (ie. opponents/monsters). It adds
-- new information to the game's Tooltip when you hover with your mouse
-- over a mob. It also adds a numeric display of the Mobs health
-- and mana (current and max) to the Mob target frame.
--
-- MobInfo-2 is the continuation of the original "MobInfo" by Dizzarian,
-- combined with the original "MobHealth2" by Wyv. Both Dizzarian and
-- Wyv sadly no longer play WoW and stopped maintaining their AddOns.
-- I have "inhereted" MobInfo from Dizzarian and MobHealth-2 from Wyv
-- and now continue to update and improve the united result.
--
local ADDON_NAME, MI2 = ...
local MI2_Locale = MI2.Locale
local MI2_EventBus = MI2.EventBus
local MI2_GetNameForId, MI2_CacheMobInfo -- forward declaration

local GetTime               = GetTime
local GetWorldPosFromMapPos = C_Map.GetWorldPosFromMapPos
local UnitPosition          = UnitPosition
local UnitGUID              = UnitGUID
local UnitLevel             = UnitLevel
local UnitHealth            = UnitHealth
local UnitHealthMax         = UnitHealthMax
local UnitPower             = UnitPower
local UnitPowerMax          = UnitPowerMax
local UnitClassification    = UnitClassification
local UnitCreatureType      = UnitCreatureType
local UnitCreatureFamily    = UnitCreatureFamily
local UnitRace              = UnitRace
local UnitClassBase         = UnitClassBase
local UnitIsDead            = UnitIsDead
local UnitXP                = UnitXP
local UnitXPMax             = UnitXPMax
local UnitExists            = UnitExists

local GetSpellBookSkillLineInfo = (C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo) or GetSpellTabInfo

local GetMerchantItemInfo = GetMerchantItemInfo or function(index)
  local info = C_MerchantFrame.GetItemInfo(index);
  if info then
    return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable, info.hasExtendedCost, info.currencyID, info.spellID;
  end
end

-- stub for now to return power
function UnitMana(unitId)
	return UnitPower(unitId)
end

-- stub for now to return power max
function UnitManaMax(unitId)
	return UnitPowerMax(unitId)
end

local MapRects = {}
local TempVec2D = CreateVector2D(0, 0)
function GetPlayerMapPosition(mapID)
	if mapID then
		TempVec2D.x, TempVec2D.y = UnitPosition('player')
		if not TempVec2D.x then return 0, 0 end

		local mapRect = MapRects[mapID]
		if not mapRect then
			local _, pos1 = GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
			local _, pos2 = GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
			if not pos1 or not pos2 then return 0, 0 end

			mapRect = { pos1, pos2 }
			mapRect[2]:Subtract(mapRect[1])
			MapRects[mapID] = mapRect
		end
		TempVec2D:Subtract(mapRect[1])

		return (tonumber(string.format("%.3f", TempVec2D.y / mapRect[2].y * 100))),
			(tonumber(string.format("%.3f", TempVec2D.x / mapRect[2].x * 100)))
	end
	return 0, 0
end

-- library pointers
local libPeriodicTable = LibStub("LibPeriodicTable-3.1")

-- metadata
local MI2_UnitId2NameProtected = MI2.UnitId2NameProtected or {}
-- Free all locale sub-tables that will never be read at runtime.
-- Only the current client locale and "enUS" (fallback) are ever accessed,
-- so we nil the rest immediately to avoid keeping ~10 unused tables in memory.
MI2.UnitId2NameProtected = nil  -- release module-level reference; data held in local only
for locale in next, MI2_UnitId2NameProtected do
    if locale ~= MI2_Locale and locale ~= "enUS" then
        MI2_UnitId2NameProtected[locale] = nil
    end
end
-- If the client is not enUS and a locale-specific table exists, remove every
-- enUS entry that is already translated in the locale table -- those enUS
-- entries can never be reached at runtime because MI2.GetNameForId checks the
-- locale table first, so keeping them just wastes memory.
if MI2_Locale ~= "enUS" then
    local localeTable = MI2_UnitId2NameProtected[MI2_Locale]
    if localeTable then
        local enUSTable = MI2_UnitId2NameProtected["enUS"]
        if enUSTable then
            for id in next, localeTable do
                enUSTable[id] = nil
            end
        end
    end
end
MI2.VersionNum = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

-- debugging
local GREEN = "|cFF33FF99"
local debugging = true
local _, fh = DEFAULT_CHAT_FRAME:GetFont()
local fontHeight = math.ceil(fh) -- avoid bizarre -ve numbers
local icon = "\124TInterface\\Addons\\" .. ADDON_NAME .. "\\icon:" .. fontHeight .. "\124t"
local HEADER = string.format("%s%s%s|r : ", GREEN, icon, ADDON_NAME)
function MI2.printf(...)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(HEADER .. string.format(...))
	end
end

local function printfd(...) if (debugging) then MI2.printf("DEBUG: " .. string.format(...)) end end

-- global vars
MI2.Debug = 0 -- 0=no debug info, 1=activate debug info

MI2.DB_VERSION = 11
MI2.DB_SV = 2
MI2.IMPORT_DB_VERSION = 9
MI2.WOW_INTERFACE_VERSION = select(4, GetBuildInfo())
MI2.WOW_MODERN = MI2.WOW_INTERFACE_VERSION > 120000 or (MI2.WOW_INTERFACE_VERSION > 16000 and MI2.WOW_INTERFACE_VERSION < 20000)

MI2.SummaryFont = {}
MI2.SummaryFont.Normal = GameFontWhiteTiny

function MI2.SummaryFont:GetScale()
	local _, fontHeight = self.Normal:GetFont()
	local _, normalHeight = GameFontNormalSmall:GetFont()
	return fontHeight / normalHeight
end

function MI2.SummaryFont:GetHeight()
	local _, fontHeight = self.Normal:GetFont()
	return fontHeight
end

local MI2_LootingInProgress = false
local MI2_DatabaseLocale
local MI2_XRefItemTable
local MI2_NewCorpseIdx      = 0
local MI2_SpellToSchool     = {}
local MI2_CACHE_SIZE        = 45
local GetSpellName          = GetSpellName or GetSpellBookItemName
local GetDifficultyColor    = GetDifficultyColor or GetQuestDifficultyColor

local miClamContents        = {
	["4655"] = "Giant Clam Meat",
	["5503"] = "Clam Meat",
	["5504"] = "Tangy Clam Meat",
	["7974"] = "Zesty Clam Meat",
	["15924"] = "Soft-shelled Clam Meat",
	["24477"] = "Jaggal Clam Meat",
	["36782"] = "Succulent Clam Meat",
	["62791"] = "Blood Shrimp",
}

local MI2_CollapseList      = {
	[2725] = 2725,
	[2728] = 2725,
	[2730] = 2725,
	[2732] = 2725,
	[2734] = 2725,
	[2735] = 2725,
	[2738] = 2725,
	[2740] = 2725,
	[2742] = 2725,
	[2745] = 2725,
	[2748] = 2725,
	[2749] = 2725,
	[2750] = 2725,
	[2751] = 2725
}

-- MobInfo color constants (all in MI2 namespace)
MI2.Red                  = "|cffff1010"
MI2.Green                = "|cff00ff00"
MI2.Blue                 = "|cff0000ff"
MI2.White                = "|cffffffff"
MI2.Gray                 = "|cff888888"
MI2.Yellow               = "|cffffff00"
MI2.Cyan                 = "|cff00ffff"
MI2.Orange               = "|cffff7000"
MI2.Gold                 = "|cffffcc00"
MI2.Mageta               = "|cffe040ff"
MI2.ItemBlue             = "|cff2060ff"
MI2.LightBlue            = "|cff00e0ff"
MI2.LightGreen           = "|cff60ff60"
MI2.LightRed             = "|cffff5050"
MI2.SubWhite             = "|cffbbbbbb"
MI2.Artifact             = "|cffe6cc80"
MI2.Heirloom             = "|cff00ccff"
local MI2_QualityColor      = { MI2.Gray, MI2.White, MI2.Green, MI2.ItemBlue, MI2.Mageta, MI2.Orange, MI2.Red, MI2.Artifact,
	MI2.Heirloom }

local MI2_Name2UnitIds

local function MI2_InitName2Ids()
	MI2_Name2UnitIds = {}
	for unitId, unitName in next, MI2_UnitId2Name[MI2_Locale] do
		local unitIds = MI2_Name2UnitIds[unitName]
		if not unitIds then
			MI2_Name2UnitIds[unitName] = { unitId }
		else
			unitIds[#unitIds + 1] = unitId
		end
	end

	if MI2_DatabaseLocale == MI2_Locale then
		for unitId, unitName in next, MI2_UnitId2Name do
			if type(unitId) == "number" then
				local unitIds = MI2_Name2UnitIds[unitName]
				if not unitIds then
					MI2_Name2UnitIds[unitName] = { unitId }
				else
					local unitAlreadyDefined = false
					for _, v in next, unitIds do
						unitAlreadyDefined = v == unitId
						if unitAlreadyDefined then break end
					end
					if unitAlreadyDefined == false then
						unitIds[#unitIds + 1] = unitId
					end
				end
			end
		end
	end

	-- Also include protected name table (used for secret-level mobs and
	-- pre-populated names that may never appear in MI2_UnitId2Name)
	local function addProtectedLocale(t)
		if type(t) ~= "table" then return end
		for unitId, unitName in next, t do
			if type(unitId) == "number" and type(unitName) == "string" then
				local unitIds = MI2_Name2UnitIds[unitName]
				if not unitIds then
					MI2_Name2UnitIds[unitName] = { unitId }
				else
					local found = false
					for _, v in next, unitIds do
						if v == unitId then found = true; break end
					end
					if not found then
						unitIds[#unitIds + 1] = unitId
					end
				end
			end
		end
	end
	if MI2_Locale ~= "enUS" then
		addProtectedLocale(MI2_UnitId2NameProtected[MI2_Locale])
	end
	addProtectedLocale(MI2_UnitId2NameProtected["enUS"])
end

function MI2.GetNameForId(id)
	return MI2_UnitId2Name[MI2_Locale][id]
		or MI2_UnitId2Name[id]
		or (MI2_UnitId2NameProtected[MI2_Locale] and MI2_UnitId2NameProtected[MI2_Locale][id])
		or (MI2_UnitId2NameProtected["enUS"] and MI2_UnitId2NameProtected["enUS"][id])
end
MI2_GetNameForId = MI2.GetNameForId

function MI2.GetIdForName(name)
	if MI2_Name2UnitIds == nil then
		MI2_InitName2Ids()
	end

	return MI2_Name2UnitIds[name]
end

-----------------------------------------------------------------------------
-- MI2_GetMobData( nameOrId, level [, unit, combine] )
--
-- Get and return all the data that MobInfo knows about a given mob.
-- This is an externally available interface function that can be
-- called by other AddOns to access MobInfo data. It should be fast,
-- efficient, and easy to use
--
-- The data describing a Mob is returned in table form as described below.
--
-- To identify the mob you must supply its name and level. You can
-- optionally supply a "unitId" to get additional info:
--   nameOrId : name of mob (eg. "Forest Lurker") or the integer number id of
--              the mob (eg. 1195). When name of mob is passed it will return
--              all data recorded for all ids for which the names is the
--              same plus legacy name lookup (in case there are multiple ids
--              recorded for the same name)
--   level : mob level as integer number
--   unit : optional WoW unit identification, should be either "target" or
--          "mouseover"
--   combine: if true, it will returned the combined mob as shown when
--            CombinedMode is turned on. Only valid if nameOrId and level are
--            passed
--
-- Examples:
--    A.   mobData = MI2_GetMobData( "Forest Lurker", 10 )
--    B.   mobData = MI2_GetMobData( "Forest Lurker", 10, "target" )
--    C.   mobData = MI2_GetMobData( 1195, 10, "target", true )
--    D.   mobData = MI2_GetMobData( nil, nil, "target" )
--
-- Return Value:
-- The return value is a LUA table with one table entry for each value that
-- MobInfo can know about a Mob. Note that table entries exist ONLY if the
-- corresponding value has actually been collected for the given Mob.
-- Unrecorded values do NOT exist in the table and thus evaluate to a NIL
-- expression.
--
-- Values you can get without "unitId" (as per Example A above):
--    mobData.id         :  the unique id of the mob
--    mobData.ids        :  in case multiple ids exists it will be a table with all ids
--                          (it could include legacy name as id as well). If ids is returned,
--                          mobData.id is not defined.
--    mobData.healthMax  :  health maximum
--    mobData.xp         :  experience value
--    mobData.kills      :  number of times current player has killed this mob
--    mobData.minDamage  :  minimum damage done by mob
--    mobData.maxDamage  :  maximum damage done by mob
--    mobData.dps        :  dps of Mob against current player
--    mobData.loots      :  number of times this mob has been looted
--    mobData.firstKill  :  first time this mob was killed (epoch with ms)
--    mobData.lastKill   :  first time this mob was killed (ms difference between firstKill)
--    mobData.emptyLoots :  number of times this mob gave empty loot
--    mobData.clothCount :  number of times this mob gave cloth loot
--    mobData.copper     :  total money loot of this mob as copper amount
--    mobData.itemValue  :  total item value loot of this mob as copper amount
--    mobData.mobType    :  mob type for special mobs: 1=normal, 2=rare, 3=worldboss, 4=elite; 6=rareelite
--    mobData.r1         :  number of rarity 1 loot items (grey)
--    mobData.r2         :  number of rarity 2 loot items (white)
--    mobData.r3         :  number of rarity 3 loot items (green)
--    mobData.r4         :  number of rarity 4 loot items (blue)
--    mobData.r5         :  number of rarity 5 loot items (purple)
--    mobData.itemList   :  table that lists all recorded items looted from this mob
--                          table entry index gives WoW item ID,
--                          table entry value gives item amount
--
-- Additional values you will get with "unitId" (as per Example B above):
--    mobData.class      :  class of mob as localized text
--    mobData.healthCur  :  current health of given unit
--    mobData.manaCur    :  current mana of given unit
--    mobData.manaMax    :  maximum mana for given unit
--
-- Code Example:
--
--    local mobData = MI2_GetMobData( "Forest Lurker", 10 )
--
--    if mobData.xp then
--        DEFAULT_CHAT_FRAME:AddMessage( "XP = "..mobData.xp )
--    end
--
--    if mobData.copper and mobData.loots then
--        local avgLoot = mobData.copper / mobData.loots
--        DEFAULT_CHAT_FRAME:AddMessage( "average loot = "..avgLoot )
--    end
--
local function MI2_CopyTableContents(t, shallow)
	local c = {}
	for k, v in pairs(t) do
		if k ~= "db" then
			if type(v) == "table" and not shallow then
				c[k] = MI2_CopyTableContents(v, shallow)
			elseif type(v) ~= "function" then
				c[k] = v
			end
		end
	end
	return c
end

function MI2_GetMobData(nameOrId, level, unit, combine)
	-- Only  return specific mob information when only unit is passed (combine is ignored)
	if unit and nameOrId == nil and level == nil then
		local guid = UnitGUID(unit)
		if (not issecretvalue or not issecretvalue(guid)) and guid then
			local mobData = MI2.Database:GetFromGUID(guid, UnitLevel(unit), UnitClassification(unit))
			if mobData then
				local extMobData = MI2_CopyTableContents(mobData)
				MI2.GetUnitBasedMobData(extMobData, unit)
				return extMobData
			end
		end
	end

	if nameOrId == nil or level == nil then return end

	local delta = 0
	if combine == true then delta = 4 end

	local mobData
	-- legacy name lookup
	if type(nameOrId) == "string" then
		local ids = MI2.GetIdForName(nameOrId)
		-- will return all recorded ids for a given name. If none exists it could
		-- mean none were recorded or the ones recored had a one to one relationship
		-- with the name. In the latter case the mobData will be gathered in the
		-- next loop
		if ids then
			for _, id in next, ids do
				for l = max(level - delta, -2), level + delta, 1 do
					local entry = MI2.Database:Get(id, l, nil, true)
					if entry then
						if mobData then
							mobData:Union(entry)
						else
							mobData = entry
						end
					end
				end
			end
		end
	end

	-- Special handling for secret ones (aka level -2)
	if level == -2 then
		local entry = MI2.Database:Get(nameOrId, level, nil,  true)
		if entry then
			if mobData then
				mobData:Union(entry)
			else
				mobData = entry
			end
		end
	else
		-- Legacy name data or specific numeric id
		for l = max(level - delta, 1), level + delta, 1 do
			local entry = MI2.Database:Get(nameOrId, l, nil,  true)
			if entry then
				if mobData then
					mobData:Union(entry)
				else
					mobData = entry
				end
			end
		end
	end

	if mobData then
		local extMobData = MI2_CopyTableContents(mobData)

		-- if requested add unit data
		-- no check is made of unit matches the nameOrId value at the moment
		if unit then
			MI2.GetUnitBasedMobData(extMobData, unit)
		end
		return extMobData
	end
end

local function MI2_AddMapping(unitId, unitName)
	if MI2_Name2UnitIds == nil then
		MI2_InitName2Ids()
	end

	local name = MI2_GetNameForId(unitId)

	if name == nil or name ~= unitName then
		MI2_UnitId2Name[MI2_Locale][unitId] = unitName

		local unitIds = MI2_Name2UnitIds[unitName]
		if not unitIds then
			MI2_Name2UnitIds[unitName] = { unitId }
		else
			-- if id already in there, bail
			for _, v in next, unitIds do
				if v == unitId then return end
			end
			unitIds[#unitIds + 1] = unitId
		end
	end
end

local function MI2_GetItemInfoForId(id)
	return MI2_ItemNameTable[MI2_Locale][id] or MI2_ItemNameTable[id]
end

local function MI2_GetNameForItem(id)
	local itemString = MI2_GetItemInfoForId(id)
	if itemString then
		local s, e, quality, tier = string.find(itemString, "/(%d+)/?(%d*)")
		if s then
			local itemName = string.sub(itemString, 1, s - 1)
			return itemName
		end
	end
end

local function MI2_CheckOrAddItemInfo(loot)
	if not issecretvalue or not issecretvalue(loot.Name) then
		local itemString = loot.Name .. "/" .. loot.Quality .. "/" .. (loot.Tier or "")
		local itemInfo = MI2_GetItemInfoForId(loot.ID)
		if itemInfo == nil or itemInfo ~= itemString then
			MI2_ItemNameTable[MI2_Locale][loot.ID] = itemString
		end
	end
end

local function MI2_GetCurrencyNameForId(id)
	return MI2_CurrencyNameTable[MI2_Locale][id] or MI2_CurrencyNameTable[id]
end

local function MI2_CheckOrAddCurrency(loot)
	local currencyName = MI2_GetCurrencyNameForId(loot.ID)
	if currencyName == nil or currencyName ~= loot.Name then
		MI2_CurrencyNameTable[MI2_Locale][loot.ID] = loot.Name
	end
end

local MI2_GUID2Data = {}
local MI2_GUID2DataInd = 0

local function MI2_GetMobInfo(guid, checkLevel)
	for _, v in next, MI2_GUID2Data
	do
		-- only return if the level is set as well (if checkLevel is passed).
		-- In some special cases we don't have the level information yet
		-- (recording hits for example)
		if (v.GUID == guid and (checkLevel == nil or not checkLevel or v.level ~= nil))
		then
			return v;
		end
	end
end

local function MI2_GetMobInfoByName(name)
	if not issecretvalue or not issecretvalue(name)
	then
		for _, v in next, MI2_GUID2Data do
			if v.name == name
			then
				return v
			end
		end
	else
		print("trying to get mob with secret name")
	end
end

local function MI2_GetMobInfoById(id, level)
	for _, v in next, MI2_GUID2Data do
		if v.id == id and v.level == level
		then
			return v
		end
	end
end

function MI2.CacheMobInfo(guid, name, level, mobData, unitisClose, unitClassification)
	if guid and (not issecretvalue or not issecretvalue(guid)) then
		if issecretvalue and issecretvalue(name) then
		    name = nil
			print("secret name for guid "..guid)
		end
		local value = MI2_GetMobInfo(guid)
		if value == nil
		then
			value = { GUID = guid, name = name, level = level, data = mobData }
			MI2_GUID2DataInd = MI2_GUID2DataInd + 1
			if MI2_GUID2DataInd > (MI2_CACHE_SIZE * 3)
			then
				MI2_GUID2DataInd = 1
			end

			MI2_GUID2Data[MI2_GUID2DataInd] = value
		else
			-- overwrite/set additional info
			if name then value.name = name end
			if level then value.level = level end
			if mobData then value.data = mobData end
		end

		if unitClassification then
			if unitClassification == "rare" then
				value.mobType = 2
			elseif unitClassification == "worldboss" then
				value.mobType = 3
			elseif unitClassification == "elite" then
				value.mobType = 4
			elseif unitClassification == "rareelite" then
				value.mobType = 6
			else
				value.mobType = 1
			end
		end

		if unitisClose then
			MI2.RecordLocation(guid)
		end

		return value
	end
end
MI2_CacheMobInfo = MI2.CacheMobInfo

local MI2_MobInfo2 = nil

-----------------------------------------------------------------------------
-- initialize MobInfo configuration options
-- this takes into account new options that have been added to MobInfo
-- in the course of developement
--
function MI2.InitOptions(self)
	-- defaults for all MobInfo config options
	local MI2_OptDefaults = {
		ShowHealth = 1,
		ShowMana = 0,
		ShowXp = 1,
		ShowNo2lev = 1,
		ShowKills = 0,
		ShowLoots = 1,
		ShowTotal = 1,
		ShowCoin = 0,
		ShowIV = 0,
		AlwaysResetSummary = 0,
		ShowEmpty = 0,
		ShowCloth = 1,
		ShowDamage = 1,
		ShowDps = 1,
		ShowLocation = 1,
		ShowQuality = 1,
		ShowResists = 1,
		ShowImmuns = 1,
		MouseTooltip = 1,
		SaveBasicInfo = 1,
		KeypressMode = 0,
		SavePlayerHp = 0,
		ShowMobInfo = 1,
		ShowItemInfo = 1,
		ShowTargetInfo = 1,
		ShowMMButton = 1,
		MMButtonPos = 257,
		TooltipMode = 4,
		SmallFont = 1,
		OtherTooltip = 1,
		ShowLowHpAction = 1,
		ShowItems = 1,
		ShowClothSkin = 1,
		TargetFontSize = 10,
		TargetHealth = 1,
		TargetMana = 1,
		HealthPercent = 1,
		ManaPercent = 1,
		HealthPosX = -7,
		HealthPosY = 11,
		ManaPosX = -7,
		ManaPosY = 11,
		TargetFont = 2,
		CompactMode = 1,
		SaveItems = 1,
		SaveCharData = 1,
		ItemsQuality = 2,
		ItemTooltip = 1,
		ItemFilter = "",
		ImportOnlyNew = 1,
		SaveResist = 1,
		ShowItemPrice = 0,
		CombinedMode = 0,
		UseGameTT = 0,
		ShowWhileInCombat = 1,
		HideAnchor = 0,
		ShowIGrey = 0,
		ShowIWhite = 1,
		ShowIGreen = 1,
		ShowIBlue = 1,
		ShowIPurple = 1,
		SaveAllPartyKills = 0,
		ShowClass = 1,
		SaveCompressed = 0
	}

	-- initialize MobInfoConfig
	if not MobInfoConfig then
		MobInfoConfig = {}
	end

	-- make the 2 column layout active by default
	if MobInfoConfig.ShowBlankLines then MobInfoConfig.CompactMode = 1 end
	if MobInfoConfig.MMButtonPos == 20 then MobInfoConfig.MMButtonPos = 356 end

	-- config values that no longer exist
	MobInfoConfig.OptStableMax = nil -- removed in 3.20
	MobInfoConfig.DisableMobInfo = nil -- removed in 3.40
	MobInfoConfig.ShowBlankLines = nil -- removed in 3.40
	MobInfoConfig.ShowCombined = nil -- removed in 3.40

	-- initial defaults for all config options
	for idx, def in pairs(MI2_OptDefaults) do
		if not MobInfoConfig[idx] then
			MobInfoConfig[idx] = def
		end
	end

	-- Use previous stored anchor point location instead of relying on local layout
	if MobInfoConfig.MIAnchor
	then
		pcall(function()
			MI2_TooltipAnchor:SetPoint(MobInfoConfig.MIAnchor[1], nil, MobInfoConfig.MIAnchor[1],
				MobInfoConfig.MIAnchor[2], MobInfoConfig.MIAnchor[3])
		end)
	end

	-- temporary additions for cloth:
	local s = "Tradeskill.Mat.ByType.Cloth"
	local sr = libPeriodicTable:GetSetString(s) .. ",173202,173204" ..
		",193922,193923,193924,193925" .. -- Green items
		",193050"..                   -- Grey items
		",224828" -- Weavercloth

	libPeriodicTable:AddData(s, sr)

	-- temporary additions for skinning:
	local s = "Tradeskill.Gather.Skinning"
	local sr = libPeriodicTable:GetSetString(s) ..
		",193261,193262,201462,172089,172092,172094,172096,172097,173871,175955,175960,176864,176391,176862,176869,181969,182299,187701" ..
		",193208,193210,193211,193213,193214,193215" ..
		",193255,193252,193253,193254" ..                                     -- Green items
		",193222,193223,193224,193216,193217,193218,193259,198837,198975,202016" .. -- Blue items
		",198841,203417" ..                                                   -- Purple items
		",199204,199206" ..                                                   -- Grey items
		",218453," .. -- Grey: Unusable Fragment
		",224780,213612" .. -- Blue: Toughened Thunderous Hide,Viridescent Spores
		",212664,212665,212667,212668,212669" .. -- White: Stormcharged Leather*/**,Gloom Chitin*/**/***
		",218738,218336,218337,218338" .. -- Green: Bizarrely-Shaped Stomach, Kaheti Swarm Chitin, Honed Bone Shards, Bottled Storm
		",212670,212672,212674,225565" .. -- Blue: Thunderous Hide*/**,Sunless Carapace*,Massive Work Flank
		",224781" .. -- Purple: Abyssal Fur
        ",238511,238512,238513,238514" .. -- Void-Tempered Leather */**,Void-Tempered Scales */**
		",238518,238519" .. -- Void-Tempered Hide */**
		",238520,238523,238525" .. -- Void-Tempered Plating *,Carving Canine,Fantastic Fur
		",238528,238529,238530,238625,238626,238627" .. -- Majestic Claw/Hide/Fin,Fine Void-Tempered Hide,Mana-Infused Bone,Manafused Sample
		",238944" -- Torn Material
	libPeriodicTable:AddData(s, sr)

	-- temporary additions for mining:
	s = "Tradeskill.Gather.Mining"
	sr = libPeriodicTable:GetSetString(s) .. ",171828,171829,171840,178114" ..
		",190312,190313,190314,202011,201300" .. -- Blue items
		",201301,203418" ..                    -- Purple items
		",189143,188658,190311,190395,190396,190394".. -- Grey items
		",210930".. -- Bismuth
		",213610,210936".. -- Crystalline Powder,Ironclaw Ore
		",224583,217707".. -- Slab of Slate,Imperfect Null Stone
        ",237364,237359,237362".. -- Brilliant Silver Ore, Refulgant Copper Ore, Umbral Tin Ore
		",237496" -- Igneous Rock Specimen
	-- ",210796" -- Mycobloom
	-- ",210805,210808,210799" -- Blessing Blossum,Arathor's Spear,Luredrop
	-- ",214561,224264,213613,213612,224835" -- Verdant Seed,Deepgrove Petal,Leyline Residue,Viridescent Spores,Deepgrove Roots
	-- ",224265" -- Deepgrove Rose
	libPeriodicTable:AddData(s, sr)

	if not MI2_EventBus:IsSourceRegistered(self) then
		MI2_EventBus:RegisterSource(self, "MobInfo2")
	end
	MI2_MobInfo2 = self
end

-----------------------------------------------------------------------------
-- Obtain and store all unit specific mob data.
--
function MI2.GetUnitBasedMobData(mobData, unitId)
	if unitId and mobData then
		mobData.healthMax = UnitHealthMax(unitId)
		mobData.healthCur = UnitHealth(unitId)
		mobData.manaCur = UnitMana(unitId)
		mobData.manaMax = UnitManaMax(unitId)
		if not issecretvalue or not issecretvalue(mobData.healthCur) then
		    mobData.healthText = MI2.GetNumText(mobData.healthCur, mobData.healthMax) ..
			"/" .. MI2.GetNumText(mobData.healthMax)
		end

		if (not issecretvalue or not issecretvalue(mobData.manaCur)) and mobData.manaMax > 0 then
			mobData.manaText = mobData.manaCur .. "/" .. mobData.manaMax
		end

		local mobType = UnitClassification(unitId)
		if mobType == "rare" then
			mobData.mobType = 2
		elseif mobType == "worldboss" then
			mobData.mobType = 3
		elseif mobType == "elite" then
			mobData.mobType = 4
		elseif mobType == "rareelite" then
			mobData.mobType = 6
		else
			mobData.mobType = 1
		end
	end
end

-----------------------------------------------------------------------------
-- Internal function for accessing a mobData record
-- This function implements a caching mechanism for faster access
-- to database records. The cache stores the last MI2_CACHE_SIZE Mob
-- records.
-- Data returned by "MI2.FetchMobDataFromGUID()" should NOT be modified because
-- modifications are written back into the main database file.
--
function MI2.FetchMobDataFromGUID(guid, level, id, unit)
	-- check local cache first
	local mobInfo = MI2_GetMobInfo(guid)
	local mobData

	if not mobInfo or not mobInfo.data then
		mobInfo = MI2_GetMobInfoById(id, level)
		if not mobInfo or not mobInfo.data then
			mobData = MI2.Database:GetFromGUID(guid, level, UnitClassification(unit))
			if mobData then
				MI2.GetUnitBasedMobData(mobData, unit)
			end
		else
			mobData = mobInfo.data
		end
	else
		return mobInfo.data, true
	end
	return mobData, false
end

-----------------------------------------------------------------------------
-- Remove all char specific data from the given Mob database record.
--
function MI2.RemoveCharData(mobData)
	for key in next, mobData do
		if string.find(key, "^c(%d+)") ~= nil then
			mobData[key] = nil
		end
	end
end

-----------------------------------------------------------------------------
-- Delete data for a specific Mob from database
--
function MI2.DeleteMobData(nameOrId, level)
	if nameOrId and level then
		local mobInfo = MI2_DB.source[nameOrId]
		if mobInfo then
			mobInfo[level] = nil
			local hasLevels = false
			for mobLevel in next, mobInfo do
				if type(mobLevel) == "number" then
					hasLevels = true
					break
				end
			end
			if not hasLevels then
				MI2_DB.source[nameOrId] = nil
				MI2_DB.location[nameOrId] = nil
			end
		end

		for _, charData in next, MI2_DB.character do
			local charMobData = charData[nameOrId]
			if charMobData then
				charMobData[level] = nil
				if next(charMobData) == nil then
					charData[nameOrId] = nil
				end
			end
		end

		local name = nameOrId
		-- in case a string was passed, also delete all data related to all
		-- ids known for the mob
		if type(nameOrId) == "string" then
			local ids = MI2.GetIdForName(nameOrId)
			if ids then
				for _, id in next, ids do
					MI2.DeleteMobData(id, level)
				end
			end
		else
			name = MI2_GetNameForId(nameOrId)
		end

		-- check the cache and remove it
		if name then
			for i, v in next, MI2_GUID2Data do
				if v.name == name and v.level == level
				then
					MI2_GUID2Data[i] = nil
				end
			end
		end
	end
end

-----------------------------------------------------------------------------
-- Set the global MobInfo player name. This is the abbreviated player name
-- that is just an index into the MobInfo player name table, where the real
-- name of the player is stored.
--
local function MI2_SetPlayerName()
	local charName = GetRealmName() .. ':' .. UnitName("player")
	if not MI2_CharTable[charName] then
		MI2_CharTable.charCount = MI2_CharTable.charCount + 1
		MI2_CharTable[charName] = "c" .. MI2_CharTable.charCount
	end
	MI2_PlayerName = MI2_CharTable[charName]

	if type(MI2_DB.character[MI2_PlayerName]) == "string" then
		MI2_DB.character[MI2_PlayerName] = MI2.Decode(MI2_DB.character[MI2_PlayerName])
	end
end

-----------------------------------------------------------------------------
-- Empty oput the mob data cache
--
function MI2.ClearMobCache()
	MI2_GUID2Data = {}
	MI2_GUID2DataInd = 0
end

-----------------------------------------------------------------------------
-- Delete entire Mob database and all related data tables
--
function MI2.DeleteAllMobData()
	MI2_DB = {source={},character={},location={},info={version=MI2.DB_VERSION,locale=MI2_Locale}}
	MobInfoDB = nil
	MI2_CharTable = { charCount = 0 }

	MI2_ItemNameTable = {}
	MI2_ItemNameTable[MI2_Locale] = {}

	MI2_CurrencyNameTable = {}
	MI2_CurrencyNameTable[MI2_Locale] = {}

	MI2_UnitId2Name = {}
	MI2_UnitId2Name[MI2_Locale] = {}

	MI2_XRefItemTable = {}
	MI2_SetPlayerName()
	MI2.ClearMobCache()
	MI2_ZoneTable = { cnt = 1 }
	MI2.Database = CreateAndInitFromMixin(MI2.DatabaseMixin, MI2_DB)
end

-----------------------------------------------------------------------------
-- spits out msg to the chat channel.
--
function MI2.chattext(txt)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(MI2.LightBlue .. "<MI2> " .. txt)
	end
end

-----------------------------------------------------------------------------
-- add debug message to chat channel, handle debug detail level if given
--
function MI2.midebug(txt, dbgLevel)
	if DEFAULT_CHAT_FRAME then
		if dbgLevel then
			if dbgLevel <= MI2.Debug then
				DEFAULT_CHAT_FRAME:AddMessage(MI2.LightBlue .. "[MI2DBG] " .. txt)
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage(MI2.LightBlue .. "<MI2DBG> " .. txt)
		end
	end
end

-----------------------------------------------------------------------------
-- Return the component parts of a mob index: mob name, mob level
--
local function MI2_GetIndexComponents(mobIndex)
	local _, _, mobName, mobLevel = string.find(mobIndex, "(.+):(.+)$")
	mobLevel = tonumber(mobLevel) or 0
	return mobName, mobLevel
end

local function MI2_CheckAndUpgradeToVersion(version)
	if version >= 11 then
		return
	end

	if version == 9 then
		local db = CreateAndInitFromMixin(MI2.DatabaseMixin, MI2_DB)
		db:Upgrade9to10(MobInfoDB)
		MI2_DB = db.db
		version = 10
	end

	if version == 10 then
		local db = CreateAndInitFromMixin(MI2.DatabaseMixin, MI2_DB)
		db:Upgrade10to11()
		MI2_DB = db.db
		MobInfoDB = nil
		version = 11
	end
end

-----------------------------------------------------------------------------
-- Cleanup for MobInfo database. This function corrects bugs in the
-- MobInfo database and applies changes that have been made to the
-- format of the actual database entries.
--
function MI2.CheckAndCleanDatabases()

	MI2_DB = MI2_DB or {}
	
	if MI2_DB.character == nil then MI2_DB.character = {} end
	
	local version = MI2.DB_VERSION
	if MI2_DB.info then
		version = MI2_DB.info.version
		MI2_DatabaseLocale = MI2_DB.info.locale
	else
		if MobInfoDB and MobInfoDB["DatabaseVersion:0"] then
			version = MobInfoDB["DatabaseVersion:0"].ver
			MI2_DatabaseLocale = MobInfoDB["DatabaseVersion:0"].loc
		end
	end

	-- check : mob database version must exist
	if version < 9 then
		StaticPopupDialogs["MOBINFO_SHOWMESSAGE"].text = MI2.Red .. MI_TXT_WRONG_DBVER
		local dialog = StaticPopup_Show("MOBINFO_SHOWMESSAGE", "")
		MI2.DeleteAllMobData()
		return
	end

	-- check mob database locale against WoW client locale (must match)
	if MI2_DatabaseLocale and MI2_DatabaseLocale ~= MI2_Locale then
		StaticPopupDialogs["MOBINFO_SHOWMESSAGE"].text = MI2.Red .. MI_TXT_WRONG_LOC
		local dialog = StaticPopup_Show("MOBINFO_SHOWMESSAGE", "")
		--return
	end

	if version < MI2.DB_VERSION then
		StaticPopupDialogs["MOBINFO_SHOWMESSAGE"].text = MI2.Red .. MI_TXT_UPGRADE_REQUIRED
		local dialog = StaticPopup_Show("MOBINFO_SHOWMESSAGE", "")
	end
	-- Initialise all database tables that do not exist

	MI2_CharTable = MI2_CharTable or { charCount = 0 }

	MI2_UnitId2Name = MI2_UnitId2Name or {}
	MI2_ItemNameTable = MI2_ItemNameTable or {}
	MI2_CurrencyNameTable = MI2_CurrencyNameTable or {}

	MI2_XRefItemTable = MI2_XRefItemTable or {}
	MI2_ZoneTable = MI2_ZoneTable or { cnt = 1 }

	if MI2_UnitId2Name[MI2_Locale] == nil then MI2_UnitId2Name[MI2_Locale] = {} end
	if MI2_ItemNameTable[MI2_Locale] == nil then MI2_ItemNameTable[MI2_Locale] = {} end
	if MI2_CurrencyNameTable[MI2_Locale] == nil then MI2_CurrencyNameTable[MI2_Locale] = {} end

	MI2_SetPlayerName()
	MI2.ClearMobCache()

	MI2_CheckAndUpgradeToVersion(version)
end

function MI2.GetZoneId(zoneName)
	if not zoneName or zoneName == "" then return end

	-- find zone ID if zone is already known
	for id, name in pairs(MI2_ZoneTable) do
		if name == zoneName then
			return id
		end
	end

	-- add unknown zone to table
	MI2_ZoneTable.cnt = MI2_ZoneTable.cnt + 1
	local zoneId = 200 + MI2_ZoneTable.cnt
	MI2_ZoneTable[zoneId] = zoneName

	return zoneId
end

-----------------------------------------------------------------------------
-- Set a new zone as the MI2 current zone. Add the zone to the MI2 zone
-- name table if zone is unknown.
--
function MI2.SetNewZone(zoneName)
	MI2.CurZone = MI2.GetZoneId(zoneName)
end

-----------------------------------------------------------------------------
-- update the cross reference table for fast item lookup
-- The table is indexed by item id and lists all Mobs that drop the item
--
local function MI2_AddItemToXRefTable(unitId, unitLevel, itemId, itemAmount, loots)
	local itemData = MI2_XRefItemTable[itemId]
	if not itemData then
		itemData = {}
		MI2_XRefItemTable[itemId] = itemData
	end
	local unitData = itemData[unitId]
	if not unitData then
		unitData = {}
		itemData[unitId] = unitData
	end
	local levelData = unitData[unitLevel]
	if not levelData then
		levelData = {0,0}
		unitData[unitLevel] = levelData
	end
	levelData[1] = levelData[1] + itemAmount
	levelData[2] = levelData[2] + loots
end

-----------------------------------------------------------------------------
-- build the cross reference table for fast item lookup
-- The table is indexed by item name and lists all Mobs that drop the item.
-- It is needed for quickly generating the "Dropped By" list in item tooltips.
--
function MI2.BuildXRefItemTable()
	MI2_XRefItemTable = {}

	-- use raw data here for speed
	for unitId, unitData in next, MI2.Database.db.source do	
		for unitLevel, levelData in next, unitData do
			if type(unitLevel) == "number" and levelData.i then
				local loots = (levelData.lc or 0) + (levelData.ec or 0)
				for itemID, amount in next, levelData.i do
					MI2_AddItemToXRefTable(unitId, unitLevel, itemID, amount, loots)
				end
			end
		end
	end

	-- Also refresh the name id lookup
	MI2_InitName2Ids()
end

-----------------------------------------------------------------------------
-- Record the current player location as the Mob location. This function is
-- intended to be called when targetting or hovering a Mob.
--
function MI2.RecordLocation(guid)
	if MobInfoConfig.SaveBasicInfo == 1 then
		local mobInfo = MI2_GetMobInfo(guid)
		if mobInfo and not mobInfo.location and mobInfo.level ~= nil then
			local mobData = mobInfo.data
			if mobData == nil then
				mobData = MI2.Database:GetFromGUID(guid, mobInfo.level)
				mobInfo.data = mobData
			end
			if mobData then
				if mobData:AddLocation() then
					mobData:SaveLocations()
				end
			end
		end
	end
end

-----------------------------------------------------------------------------
-- Record for a mob the special action that it performes when low on health.
--
-- Only "run away" is currently recorded (action is 1)
--
function MI2.RecordLowHpAction(name, action)
	if MobInfoConfig.SaveBasicInfo == 1 then
		local target = (MI2.Target.name == name and MI2.Target) or (MI2.LastTargetIdx.name == name and MI2.LastTargetIdx)
		if target then
			local entry = MI2.Database:GetFromGUID(target.guid, target.level)
			if entry then
				entry:SetLowHpAction(action)
			end
		end
	end
end

-----------------------------------------------------------------------------
-- Record kill for a mob based on it's guid or name
--
-- Only "seen" mobs can be recorded, if not "seen" an attempt is made to use
-- it's name and the targetted mob's level to find the mob information from
-- the "seen" cache.
--
-- Note: the newer (12.0+) UNIT_DIED based kill path only provides a guid, no
-- name (unlike the old combat log path). This matters for AoE kills: a
-- single AoE cast can kill several mobs at once even though only one of
-- them was ever targeted/moused-over this session. Without a name we would
-- otherwise fall back to blindly assuming the currently (or last) targeted
-- mob's level, which is wrong whenever the AoE-killed mob is a different
-- mob than the one you have targeted. To reduce that risk, when no name is
-- given we first try to resolve it from the guid's embedded creature id (it
-- may already be known from a previous session or another cached mob), which
-- is usually accurate since AoE kills most commonly hit multiple mobs of the
-- SAME species/level (trash packs).
--
-- Known/accepted imprecision: if the killed mob's creature id has never been
-- seen before (fresh id, no name resolvable) we still fall back to guessing
-- the current/last targeted mob's level. That guess can be wrong when the
-- pack is mixed-level, e.g. an elite escort that is a couple levels higher
-- than the trash around it, or a rogue add that is 1-2 levels lower. In that
-- case the kill gets recorded against the wrong level bucket for that mob id
-- rather than not at all. We accept this trade-off deliberately: recording a
-- kill under a slightly-off level is still far more useful than silently
-- losing the kill entirely (which is what happens if no level can be
-- determined at all, see the "else" branch below). A mismatched guess only
-- ever adds a small extra entry alongside the correct one once the mob is
-- properly targeted/moused-over later; it does not corrupt or overwrite
-- existing data.
--
function MI2.RecordKill(guid, name)
	local mobInfo = MI2_GetMobInfo(guid)
	local mobLevel
	if mobInfo == nil
	then
		if not name then
			local unitId = tonumber(select(6, strsplit("-", guid)), 10)
			name = unitId and MI2_GetNameForId(unitId)
		end

		-- try getting the closed mob info by name in our cache
		mobInfo = name and MI2_GetMobInfoByName(name)

		-- try getting mob data from the database based on destName and current targetted level
		if mobInfo == nil
		then
			mobLevel = MI2.Target.level or MI2.LastTargetIdx.level
		elseif mobInfo then
			mobLevel = mobInfo.level
		end
	else
		mobLevel = mobInfo.level
	end

	if mobLevel
	then
		-- "valid=true" means "only return the entry if it already exists,
		-- never create it". That's safe on clients using legacy combat-log
		-- kill tracking because RecordDamage/RecordHit has already created
		-- the entry. The modern kill path has no per-hit tracking, so a mob
		-- that was never targeted/moused-over
		-- (e.g. one of several mobs killed by a single AoE) may not have an
		-- entry yet; forcing "valid=true" there would silently drop the
		-- kill (confirmed: MI2_AttackedGUIDs correctly matched all three
		-- AoE-killed mobs, RecordKill ran for all three, but only the
		-- targeted mob's entry already existed so only that one was saved).
		--
		-- For modern clients, this means "mobLevel" (when guessed rather than
		-- resolved by name) can create a brand new, previously-unseen
		-- id+level row -- accepted as the better compromise vs. dropping the
		-- kill, see the notes above MI2.RecordKill().
		local entry = MI2.Database:GetFromGUID(guid, mobLevel, nil, not MI2.WOW_MODERN or nil)
		if entry ~= nil then
			if mobInfo then
				if mobInfo.FightStartTime then
					local deltaTime = mobInfo.FightEndTime - mobInfo.FightStartTime
					if deltaTime > 4 then
						entry:SetDps(mobInfo.FightDamage / deltaTime)
					end
				end
				if mobInfo.Damage then
					entry:SetDamage(mobInfo.Damage.Min)
					entry:SetDamage(mobInfo.Damage.Max)
				end
			end
			entry:AddKill()
			return mobLevel
		else
			--			MI2.printf("Not recording kill for %s [%s]", guid, name..":"..mobLevel)
		end
	else
		--		MI2.printf("Not recording kill for %s [%s]", guid, name)
	end
	return nil
end

-----------------------------------------------------------------------------
-- Record data related to a mob killed
--
-- attempts to find correct mob DB index based on situation and killed mob's
-- name (kill msg gives only name, not level)
--
function MI2.RecordKilledXP(name, xp)
	if MobInfoConfig.SaveCharData == 1 then
		local target = (MI2.Target.name == name and MI2.Target) or (MI2.LastTargetIdx.name == name and MI2.LastTargetIdx)
		if target then
			local entry = MI2.Database:GetFromGUID(target.guid, target.level)
			if entry then
				entry:SetXP(xp)
			end
		end
	end
end

-----------------------------------------------------------------------------
-- Record min/max damage value for mob
--
function MI2.RecordDamage(guid, damage)
	if damage > 0 and guid then
		local mobInfo = MI2_CacheMobInfo(guid)
		if mobInfo then
			-- Set damage if damage can be recorded
			if mobInfo.level ~= nil then
				local entry = MI2.Database:GetFromGUID(guid, mobInfo.level)
				if entry ~= nil then
					entry:SetDamage(damage)
				end
			else
				-- store the damage, so it might get processed when mob is
				-- killed
				if not mobInfo.Damage then
					mobInfo.Damage = { Min = damage, Max = damage }
				else
					mobInfo.Damage.Min = min(mobInfo.Damage.Min, damage)
					mobInfo.Damage.Max = max(mobInfo.Damage.Max, damage)
				end
			end
		end
	end
end

-----------------------------------------------------------------------------
-- Record an updated DPS (damage per second)
--
function MI2.RecordHit(guid, damage, spell, school, isPeriodic)
	-- Record the damage for the mob (cache and update if needed). Note that
	-- at this point we only have guid for the mob, not level, name or data
	local mobInfo = MI2_CacheMobInfo(guid)
	if mobInfo then
		--print("MI2.RecordHit("..damage..","..(spell or "")..","..(school or "")..","..(tostring(isPeriodic) or "")..")")
		if not mobInfo.FightStartTime then
			mobInfo.FightStartTime = GetTime() - 1.0
			mobInfo.FightEndTime = GetTime()
			mobInfo.FightDamage = damage
		elseif mobInfo.FightEndTime then
			mobInfo.FightEndTime = GetTime()
			mobInfo.FightDamage = mobInfo.FightDamage + damage
		end

		if spell and school and MI2_SpellSchools[school] then
			MI2_SpellToSchool[spell] = school
		elseif spell then
			school = MI2_SpellToSchool[spell]
		end

--		-- record spell hit data (needed for spell resist calculations)
--		local acronym = MI2_SpellSchools[school]
--		if school and acronym and not isPeriodic and mobInfo.level ~= nil then
--			local mobData = MI2.Database:GetFromGUID(guid, mobInfo.level)
--			if mobData then
--				mobData.resists[acronym .. "Hits"] = (mobData.resists[acronym .. "Hits"] or 0) + 1
--			end
--		end
	end
end

-----------------------------------------------------------------------------
-- MI2.RecordImmunResist()
--
-- Record that the given mob has either resisted a spell or is immune to
-- a spell.
--
function MI2.RecordImmunResist( guid, spell, isResist )
	local mobInfo = MI2_CacheMobInfo(guid)

--	if mobName == MI2.Target.name and MI2.Target.ResOk then
		local mobData = MI2.Database:GetFromGUID(guid, mobInfo.level)
		if mobData then
			local school = MI2_SpellToSchool[spell]
			if school then
				local acronym = MI2_SpellSchools[school]
				if isResist then
					mobData.resists[acronym] = (mobData.resists[acronym] or 0) + 1
				else
					mobData.resists[acronym] = -1
				end
			end
		end
--	end
end -- MI2.RecordImmunResist()

-----------------------------------------------------------------------------
-- Turns a lootname like 1 Gold 3 Silver 40 Copper to total copper 10340
--
local function MI2_LootName2Copper(item)
	local g, s, c = 0, 0, 0
	local money = 0

	local i = string.find(item, MI_TXT_GOLD)
	if i then
		g = tonumber(string.sub(item, 0, i - 1)) or 0
		item = string.sub(item, i + 5, string.len(item))
		money = money + ((g or 0) * COPPER_PER_GOLD)
	end
	i = string.find(item, MI_TXT_SILVER)
	if i then
		s = tonumber(string.sub(item, 0, i - 1)) or 0
		item = string.sub(item, i + 7, string.len(item))
		money = money + ((s or 0) * COPPER_PER_SILVER)
	end
	i = string.find(item, MI_TXT_COPPER)
	if i then
		c = tonumber(string.sub(item, 0, i - 1)) or 0
		money = money + (c or 0)
	end

	return money
end

-----------------------------------------------------------------------------
--
function MI2.FindItemValue(itemLinkOrID)
	local price = select(11, C_Item.GetItemInfo(itemLinkOrID)) or -1

	-- check if built-in MobInfo price table knows the price
	if price == -1 then
		if type(itemLinkOrID) == "string" then
			_, _, itemLinkOrID = string.find(itemLinkOrID, "|Hitem:(%d*):(%d*):(%d*):")
		end
		price = MI2.BasePrices[itemLinkOrID] or 1
	end

	return price
end

-----------------------------------------------------------------------------
-- Returns true if the itemID is normally gathered by the professions
-- or false if not. Errors from LibPeriodicTable are hopefully trapped.
--
local function MI2_ItemIsGatheredBy(itemID, prof)
	if itemID > 0 then
		local ok, result = pcall(libPeriodicTable.ItemInSet, self, itemID, "Tradeskill.Gather." .. prof)
		if ok then
			return result
		else
			MI2.printf(result, " in function MI2_ItemIsGatheredBy")
		end
	end
	return false
end

-----------------------------------------------------------------------------
--
local function MI2_ItemIsTradeMat(itemID, mat)
	if itemID > 0 then
		local ok, result = pcall(libPeriodicTable.ItemInSet, self, itemID, "Tradeskill.Mat.ByType." .. mat)
		if ok then
			return result
		else
			MI2.printf(result, " in function MI2_ItemIsTradeMat")
		end
	end
	return false
end

-----------------------------------------------------------------------------
-- get item ID code for given link or item Id
--
local function MI2_GetItemId(itemLinkOrId)
	if type(itemLinkOrId) == "string" then
		_, _, itemLinkOrId = string.find(itemLinkOrId, "|Hitem:(%d*):(%d*):(%d*):")
	end

	return tonumber(itemLinkOrId) or -1
end

-----------------------------------------------------------------------------
-- get loot ID code for given loot slot number, also return link object
--
local function MI2_GetLootId(slot)
	local link = GetLootSlotLink(slot)
	if link
	then
		return MI2_GetItemId(link)
	end
	return 0
end

local MI2_Loots = {}

local function MI2_PartOfPreviousLoot(guid)
	if MI2_RecentLoots ~= nil
	then
		for _, corpseGUID in pairs(MI2_RecentLoots) do
			if corpseGUID == guid
			then
				return true
			end
		end
	else
		MI2_RecentLoots = {}
	end
	return false
end

-- Used to store the current bag item info when item is locked
-- When opening items that contain loot info, it will be processed and associated
-- to the correct item.
function MI2.ItemLocked(self, event, bagID, slotIndex)

	if MI2_LootingInProgress and slotIndex ~= nil and not (bagID == -1 and slotIndex > 28)
	then
		local locationInfo = { bagID = bagID, slotIndex = slotIndex }
		MI2_ItemInfo = {
			Id = C_Item.GetItemID(locationInfo)
			,
			Name = C_Item.GetItemName(locationInfo)
		}
	end
end

function MI2.ItemUnlocked(self, event, bag, slot)
	MI2_ItemInfo = nil
end

-- Used to ensure we don't mark mob with empty loot during mining, disenchanting etc.
local MI2_MaxLootReadyCount = 0

function MI2.ProcessLootReady()
	-- Keep track of maximum loot count - used in Classic for empty loot when using
	-- a skill
	MI2_MaxLootReadyCount = max(MI2_MaxLootReadyCount, GetNumLootItems())

	MI2_LootingInProgress = true
	-- process all loot slots
	for i = 1, GetNumLootItems()
	do
		local lootLink = GetLootSlotLink(i)
		local _, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questId = GetLootSlotInfo(i)
		local slotType = GetLootSlotType(i)

		local itemID = currencyID
		if itemID == nil
		then
			itemID = MI2_GetLootId(i)
		end

		-- When ProcessLootReady gets called again before LootClosed, the slot might
		-- not contain valid data.
		if itemID ~= -1
		then
			if slotType == 2 --LOOT_SLOT_MONEY / Enum.LootSlotType.Money
			then
				lootQuantity = MI2_LootName2Copper(lootName)
				lootName = "Copper"
				lootQuality = -1
			elseif slotType == 1 --LOOT_SLOT_ITEM / Enum.LootSlotType.Item
			then
				lootQuality = lootQuality + 1
			elseif slotType == 3 --LOOT_SLOT_CURRENCY / Enum.LootSlotType.Currency
			then
				lootQuality = lootQuality + 1
			end

			local sources = { GetLootSourceInfo(i) }

--			print(string.format(" %d - %d of %s [%d mobs] - %d", i, lootQuantity,lootName, #sources/2, itemID))

			for j = 1, #sources, 2
			do
				local guidType, _, _, _, _, unitId = strsplit("-", sources[j])

				if not MI2_PartOfPreviousLoot(sources[j]) or MI2.MI2_TradeskillUsed ~= nil
				then
					local loot = MI2_Loots[itemID]
					local Mobs
					if loot == nil
					then
						loot = {}
						loot.Name = lootName
						loot.Quality = lootQuality
						loot.Quantity = 0
						loot.Type = slotType
						loot.Link = lootLink
						loot.ID = itemID
						loot.Time = GetTime()
						loot.isQuestItem = isQuestItem
						if lootLink then
							-- Midnight uses Quality-12-Tier format (tiers 1-2); encode as tier+10 to distinguish from legacy Quality-Tier format (tiers 1-3)
							local _, _, newTier = string.find(lootLink, "|A:Professions%-ChatIcon%-Quality%-12%-Tier(%d):")
							if newTier then
								loot.Tier = tostring(tonumber(newTier) + 10)
							else
								_, _, loot.Tier = string.find(lootLink, "|A:Professions%-ChatIcon%-Quality%-Tier(%d):")
							end
						end
						MI2_Loots[itemID] = loot
						Mobs = {}
						loot.Mobs = Mobs
					else
						Mobs = loot.Mobs
					end

					local found = Mobs == nil
					if not found then
						for _, mob in pairs(Mobs)
						do
							if mob.GUID == sources[j]
							then
								found = true
								break
							end
						end
					end

					if not found
					then
						local mobQuantity
						if #sources > 2
						then
							mobQuantity = sources[j + 1]
						else
							mobQuantity = lootQuantity
						end

						local mob = {}
						mob.GUID = sources[j]
						mob.Id = tonumber(unitId)
						mob.Level = 0
						mob.Quantity = mobQuantity
						mob.Type = guidType
						mob.isCreature = guidType == "Creature" or guidType == "Vehicle"
						mob.isItem = guidType == "Item"
						if mob.isItem then
							if MI2_ItemInfo ~= nil
							then
								mob.Id = MI2_ItemInfo.Id
								mob.Name = MI2_ItemInfo.Name
							end
						elseif mob.Type == "GameObject" and MI2_GT_Title then
							mob.Name = MI2_GT_Title
							MI2_ItemNameTable[MI2_Locale][mob.Id] = mob.Name.."/0/"
						end

						loot.Quantity = loot.Quantity + mobQuantity
						Mobs[#Mobs + 1] = mob
--						MI2.printf("%dx[%s] for Mob %s added", mobQuantity, lootName, sources[j])
					else
--						MI2.printf("%dx[%s] for Mob %s ignored", lootQuality, lootName, sources[j])
					end
				else
--					MI2.printf(" mob ignored - %s", sources[j])
				end
			end
		end
	end
end

local function MI2_FindMobData(mob)
	local mobInfo = MI2_GetMobInfo(mob.GUID, true)
	-- data not found in cache, meaning that mob got killed without knowing about it
	if mobInfo == nil
	then
		if not mob.isCreature then
			mobInfo = MI2_CacheMobInfo(mob.GUID, mob.Name, 0, {}, false)
		else
			local mobData = nil
			-- find unit by name in the cache and use that
			local UnitId = tonumber(select(6, strsplit('-', mob.GUID)), 10)
			local UnitName = MI2_GetNameForId(UnitId)
			if UnitName and (not issecretvalue or not issecretvalue(UnitName))
			then
				mobInfo = MI2_GetMobInfoByName(UnitName)
				-- find unit and use current target level to find mob info in database
				if mobInfo == nil and MI2.Target.level ~= nil
				then
					mobData = MI2.Database:Get(UnitId, MI2.Target.level, nil, true)
					if mobData and mobData.loots ~= nil
					then
						mob.Level = MI2.Target.level
--						MI2.printf("~~~> %s",UnitName..":"..mobLevel)
					else
						-- Target-level lookup failed; try level -2 (secret level) as fallback
						local secretData = MI2.Database:Get(UnitId, -2, nil, true)
						if secretData then
							mobInfo = MI2_CacheMobInfo(mob.GUID, UnitName, -2, nil, false)
							mob.Level = -2
							if mobInfo and not mobInfo.data then
								mobInfo.data = secretData
							end
						end
--						MI2.printf("!!!> Can't find target %d - %s", UnitId, UnitName .. ":" .. MI2.Target.level)
					end
				elseif mobInfo ~= nil then
					mob.Level = mobInfo.level
--					MI2.printf("---> %s", mobInfo.name..":"..mobInfo.level)
				else
					mobInfo = MI2_CacheMobInfo(mob.GUID, UnitName, -2, nil, false)
					mob.Level = -2
					if mobInfo and not mobInfo.data then
						mobInfo.data = MI2.Database:GetFromGUID(mob.GUID, -2)
					end
--					MI2.printf("...> Can't find target %s %s", mob.GUID, UnitName)
				end
			else
				mobInfo = MI2_CacheMobInfo(mob.GUID, nil, -2, nil, false)
				mob.Level = -2
				if mobInfo and not mobInfo.data then
					mobInfo.data = MI2.Database:GetFromGUID(mob.GUID, -2)
				end
--				MI2.printf("!!!> Can't find target %s", mob.GUID)
			end
		end
	else
		mob.Level = mobInfo.level
	end
	return mobInfo
end

-----------------------------------------------------------------------------
-- enter given corpse ID into list of all corpse IDs
-- a list of corpse IDs is maintained to allow detecting corpse reopening
--
local function MI2_StoreCorpseId(corpseId)
	if not MI2_PartOfPreviousLoot(corpseId)
	then
		MI2_NewCorpseIdx = MI2_NewCorpseIdx + 1
		if MI2_NewCorpseIdx > 100
		then
			MI2_NewCorpseIdx = 1
		end

		MI2_RecentLoots[MI2_NewCorpseIdx] = corpseId
	end
end

function MI2.ProcessLootClosed()
	local entryCache = {}

	-- Get the most recent record for the mob, since this one is used for
	-- written data back to the database. Used caching here, so that the
	-- same object can be used to process multiple loots correctly
	local function process( mob )
		if mob.Id == nil or mob.Level == nil then
			return
		end

		local key = mob.Id..":"..mob.Level
		for k,v in pairs(entryCache) do
			if k == key then
				return v
			end
		end

		local entry
		if mob.isItem then
			entry = MI2.Database:Get(mob.Id, 0)
		else
			-- Legacy combat-log tracking normally creates the entry on damage
			-- or kill. Modern clients may have neither, so create it if missing.
			entry = MI2.Database:GetFromGUID(mob.GUID, mob.Level, nil, not MI2.WOW_MODERN or nil)
		end

		entryCache[key] = entry
		return entry
	end

	if MI2_LootingInProgress
	then
		-- Record empty loot when in Classic, in Retail mobs with no loot cannot
		-- be looted
		-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC (5) not defined in retail
		if (WOW_PROJECT_ID == 2 or WOW_PROJECT_ID == 5) and next(MI2_Loots) == nil
		then
			if MI2_MaxLootReadyCount == 0
			then
--				MI2.printf("Recording empty loot for %s", MI2.Target.name)
				local entry = MI2.Database:GetFromGUID(MI2.Target.guid, MI2.Target.level)
				if entry then
					entry:AddEmptyLoot()

					if MobInfoConfig.SaveBasicInfo == 1
					then
						entry:SaveBasicInfo()
					end
				end
			end
		else
			local looted_corpses = {}
			for itemID, loot in pairs(MI2_Loots)
			do
				if loot.Mobs then
--					MI2.printf("[%s]x%d - %d mobs", loot.Name,loot.Quantity, #loot.Mobs)
					for i, mob in pairs(loot.Mobs)
					do
						if mob.isItem and mob.Id == nil then
							loot.Mobs[i] = nil
						else
							local Corpse = looted_corpses[mob.GUID]
							if not Corpse
							then
								local mobInfo = MI2_FindMobData(mob) -- adds level to mob if missing
								-- lookup failed, we ignore it
								if not mobInfo or not mobInfo.data
								then
--									MI2.printf("Not storing loot for never seen target before - %s", mob.GUID or "nil")
								else

									local entry = process(mob)
									if entry then
										Corpse = {}
										Corpse.gather = MI2.MI2_TradeskillUsed ~= nil
										Corpse.loots = 0
										Corpse.entry = entry
										looted_corpses[mob.GUID] = Corpse
										entry.mobType = mobInfo.mobType
									else
--										MI2.printf("Not storing loot for entry - %s", mob.GUID or "nil")
									end
								end
							end
							if Corpse then
								if loot.Type == 2 --LOOT_SLOT_MONEY / Enum.LootSlotType.Money
								then
									Corpse.entry:AddCopper(mob.Quantity)
									Corpse.loots = Corpse.loots + 1
--									print(string.format("   + %d [%s]",mob.Quantity,mob.Name or "nil"))
								elseif loot.Type == 1 --LOOT_SLOT_ITEM / Enum.LootSlotType.Item
								then
--									print("  LOOT ITEM LOOT")
									if not miClamContents[itemID]
									then
--										print(string.format("   + %d of %s [%s] - %d [%s]", loot.Quantity, loot.Name,mob.Name or "nil", itemID,mob.GUID))
										Corpse.loots = Corpse.loots + 1

										-- record item data within Mob database and in global item table
										-- update cross reference table accordingly
										Corpse.entry:AddItem(loot, mob.Quantity, MI2.MI2_TradeskillUsed ~= nil)

										if MobInfoConfig.SaveItems == 1 and loot.Quality >= MobInfoConfig.ItemsQuality
										then
											MI2_CheckOrAddItemInfo(loot)
											MI2_AddItemToXRefTable(mob.Id, mob.Level, itemID, mob.Quantity, 1)
										end

										-- check for gathered loot i.e. mining, skinning, herbalising a mob
										-- TODO: fix non gathered trash items like "shed fur" returning true here
										if MI2.MI2_TradeskillUsed ~= nil
										then
											Corpse.gather = true
										else
											if MI2_ItemIsTradeMat(itemID, "Cloth") then
												Corpse.cloth = true
											end
										end
									end
								elseif loot.Type == 3 --LOOT_SLOT_CURRENCY / Enum.LootSlotType.Currency
								then
									Corpse.entry:AddCurrency(loot, mob.Quantity)
									MI2_CheckOrAddCurrency(loot)
								end
--								MI2.printf("   %d - %dx[%s]", i, mob.Quantity, mob.Name or "nil")
							end
						end
					end
				end
				MI2_EventBus:Fire(MI2_MobInfo2, "NEW_LOOT", loot)
			end

			for corpseGUID, corpseData in pairs(looted_corpses)
			do
				if corpseData.cloth then
					corpseData.entry:AddCloth()
				end
				if corpseData.gather
				then
					corpseData.entry:AddSkin()
				elseif corpseData.loots > 0
				then
					corpseData.entry:AddLoot()
				else
					corpseData.entry:AddEmptyLoot()
				end
				MI2_StoreCorpseId(corpseGUID)

				if MobInfoConfig.SaveCharData == 1
				then
					corpseData.entry:SaveCharData()
				end
				if MobInfoConfig.SaveBasicInfo == 1
				then
					corpseData.entry:SaveBasicInfo()
				end
				if MobInfoConfig.SaveItems == 1
				then
					corpseData.entry:SaveLootItems()
				end
			end
		end
		MI2_Loots = {}
		MI2.MI2_TradeskillUsed = nil
		MI2_LootingInProgress = false
		MI2_MaxLootReadyCount = 0
	end
end

-----------------------------------------------------------------------------
-- Return item name, item quality color, and quality index
-- for an item given as item ID.
--
function MI2.GetLootItem(itemID, maxLength)
	local itemString = MI2_GetItemInfoForId(itemID)
	if itemString then
		local s, e, quality, tier = string.find(itemString, "/(%d+)/?(%d*)")
		if s then
			local itemName = string.sub(itemString, 1, s - 1)
			itemString = string.sub(itemString, 1, math.min(s - 1, (maxLength or 1000)))
			if maxLength and s >= maxLength then
				itemString = itemString .. "..."
			end
			quality = tonumber(quality) or 1
			tier = tonumber(tier) or 0
			if tier >= 11 then
				-- Midnight format (Quality-12-Tier): tiers 1-2, stored as actual_tier + 10
				itemString = string.format("%s |A:Professions-ChatIcon-Quality-12-Tier%d::::1|a", itemName, tier - 10)
			elseif tier > 0 then
				-- Legacy format (Quality-Tier): tiers 1-3
				itemString = string.format("%s |A:Professions-ChatIcon-Quality-Tier%d::::1|a", itemName, tier)
			end
			return itemName, itemString, MI2_QualityColor[quality] or MI2.LightRed, quality
		else
			return itemString, itemString, MI2.LightRed, 1
		end
	end
	return tostring(itemID), tostring(itemID), MI2.LightRed, 1
end

-----------------------------------------------------------------------------
-- Add one loot item description line to a given list. Item description
-- texts can optionally be shortened. Skinning loot uses skinned counter
-- instead of looted counter.
--
local function MI2_AddOneItemToList(list, mobData, itemID, amount)
	if itemID > 0 then
		local _, text, color, quality = MI2.GetLootItem(itemID, 35)

		-- apply item quality and item name filter
		local filtered = (quality == 1) and (MobInfoConfig.ShowIGrey == 0)
			or (quality == 2) and (MobInfoConfig.ShowIWhite == 0)
			or (quality == 3) and (MobInfoConfig.ShowIGreen == 0)
			or (quality == 4) and (MobInfoConfig.ShowIBlue == 0)
			or (quality > 4) and (MobInfoConfig.ShowIPurple == 0)
		if not filtered and MobInfoConfig.ItemFilter ~= "" then
			filtered = string.find(string.lower(text), string.lower(MobInfoConfig.ItemFilter)) == nil
		end
		if filtered then return end

		if MI2_ItemIsTradeMat(itemID, "Cloth") then
			text = "~ " .. text
		elseif MI2_ItemIsGatheredBy(itemID, "Skinning") then
			text = "* " .. text
		elseif MI2_ItemIsGatheredBy(itemID, "Mining") then
			text = "# " .. text
		elseif MI2_ItemIsGatheredBy(itemID, "Herbalism") then
			text = "+ " .. text
		end

		text = color .. text .. ": " .. amount

		local totalAmount = (mobData.loots or 0) + (mobData.emptyLoots or 0)
		if MI2_ItemIsGatheredBy(itemID, "Skinning") and not MI2_ItemIsTradeMat(itemID, "Cloth") then
			totalAmount = mobData.skinCount
		end
		if totalAmount and totalAmount > 0 then
			text = text .. " (" .. ceil(amount / totalAmount * 100) .. "%)"
		end
		table.insert(list, text)
	end
end

-----------------------------------------------------------------------------
--
local function MI2_AddOneCurrencyToList(list, mobData, currencyID, amount)
	if currencyID > 0
	then
		local text = MI2_GetCurrencyNameForId(currencyID)
		if text
		then
			text = text .. ": " .. amount

			local totalAmount = mobData.loots
			if totalAmount and totalAmount > 0 then
				text = text .. " (" .. ceil(amount / totalAmount * 100) .. "%)"
			end
			table.insert(list, text)
		end
	end
end

-----------------------------------------------------------------------------
-- Build list of loot items for showing them in the mob tooltip.
--
-- Notoriously similar and numerous items that radically increase tooltip
-- size without being of much (if any) interest will be collapsed into
-- just one item (example: "Green Hills of Stranglethorn" pages).
--
local function MI2_BuildItemsList(mobData)
	mobData.ttItems = {}

	if mobData.currencyList
	then
		for currencyID, amount in pairs(mobData.currencyList)
		do
			MI2_AddOneCurrencyToList(mobData.ttItems, mobData, currencyID, amount, true)
		end
	end

	if mobData.itemList
	then
		local sortList = {}
		local collapsedList = {}

		-- build a sortable list of item IDs
		for itemID, amount in pairs(mobData.itemList) do
			local ok = false
			if MI2_ItemIsGatheredBy(itemID, "Skinning") or MI2_ItemIsTradeMat(itemID, "Cloth") then
				if MobInfoConfig.ShowClothSkin == 1 then
					ok = true
				end
			elseif MI2_CollapseList[itemID] then
				-- collapse almost identical items into one item
				itemID = MI2_CollapseList[itemID]
				if not collapsedList[itemID] then
					ok = true
				end
				collapsedList[itemID] = (collapsedList[itemID] or 0) + amount
			else
				ok = true
			end
			if ok then
				table.insert(sortList, itemID)
			end
		end

		-- add collapsed items to sortable list
		for itemID, amount in pairs(collapsedList) do
			mobData.itemList[itemID] = amount
		end

		-- sort items by amount
		table.sort(sortList, function(a, b) return (mobData.itemList[a] > mobData.itemList[b]) end)

		-- add sorted items to tooltip items list
		for _, itemID in pairs(sortList) do
			MI2_AddOneItemToList(mobData.ttItems, mobData, itemID, mobData.itemList[itemID])
		end
	end
end

-----------------------------------------------------------------------------
-- Add the Mob resistances and immunities data to the tooltip.
--
local function MI2_BuildResistString(mobData)
	local resiatances = ""
	local immunities = ""
	local resistData = mobData.resists

	if not resistData then return end
	local shortcut, value
	for shortcut, value in pairs(resistData) do
		if string.len(shortcut) < 3 then
			local hits = tonumber(resistData[shortcut .. "Hits"]) or 1
			if value < 0 then
				if hits < 1 then
					immunities = immunities .. "  " .. MI2_SpellSchools[shortcut]
				else
					immunities = immunities .. "  " .. MI2_SpellSchools[shortcut] .. "(partial)"
				end
			elseif value > 0 then
				resiatances = resiatances .. "  " .. MI2_SpellSchools[shortcut] .. ":" .. ceil((value / hits) * 100) ..
					"%"
			end
		end
	end

	if resiatances ~= "" then
		mobData.resStr = resiatances
	end

	if immunities ~= "" then
		mobData.immStr = immunities
	end
end

-----------------------------------------------------------------------------
-- Build a string representing the loot quality overview for the given mob.
--
local function MI2_BuildQualityString(mobData)
	local quality, chance, idx
	local rt = mobData.loots or 1
	local qualityStr = ""
	for idx = 1, 5 do
		quality = mobData["r" .. idx]
		if quality and quality > 0 then
			chance = ceil(quality / rt * 100.0)
			if chance > 100 then chance = 100 end
			qualityStr = qualityStr .. MI2_QualityColor[idx] .. quality .. "(" .. chance .. "%) "
		end
	end
	if qualityStr ~= "" then
		mobData.qualityStr = qualityStr
	end
end

-----------------------------------------------------------------------------
-- convert a R/G/B color into a a textual WoW excape sequence representation
--
local function MI2_ColorToText(r, g, b, a)
	if not a then a = 1.0 end
	r = 255 * (r + 0.0001)
	g = 255 * (g + 0.0001)
	b = 255 * (b + 0.0001)
	a = 255 * (a + 0.0001)
	return string.format("|c%.2x%.2x%.2x%.2x", a, r, g, b)
end

-----------------------------------------------------------------------------
-- Extract max 4 extra lines from the standard WoW game tooltip.
-- Extra info is anything listed underneath the level/class line, but without
-- the "skinnable" line and without the mob faction name line.
--
local function MI2_BuildExtraInfo(mobData, mobName, mobLevel, numLines)
	local levelLine, previous, checkFaction, isExtraInfo

	for idx = 2, numLines do
		local ttLeft = _G["GameTooltipTextLeft" .. idx]:GetText()
		local ttRight = _G["GameTooltipTextRight" .. idx]:GetText()
		isExtraInfo = false

		-- check for line with faction name
		if ttLeft and checkFaction then
			checkFaction = nil
			if not string.find(mobName, ttLeft) then
				isExtraInfo = true
			end
			-- find the TT line with level info (just checking for level or ??
			-- (this will address ElvUI issue, without checking for ElvUI addon)
		elseif ttLeft and not levelLine then
			local levelInfo
			if mobLevel == 99 then
				levelInfo = "??"
			else
				levelInfo = tostring(mobLevel)
			end
			if not (issecretvalue and issecretvalue(ttLeft)) and string.find(ttLeft, levelInfo) then
				levelLine = idx
				--				checkFaction = true
			end
			-- if previous line exists then it is assumed to be the NPC profession
			if previous then
				mobData.classInfo = previous
			end
		elseif ttLeft == UNIT_SKINNABLE_LEATHER then
			-- the skinnable tag gets added to class info and does not count as extra info
			local color = MI2_ColorToText(GameTooltipTextLeft3:GetTextColor())
			mobData.classInfo = mobData.classInfo .. ", " .. color .. UNIT_SKINNABLE_LEATHER
		else
			isExtraInfo = true
		end
		if ttLeft and isExtraInfo and not (issecretvalue and issecretvalue(ttLeft)) then
			local text = MI2.LightGreen .. ttLeft
			if ttRight and not (issecretvalue and issecretvalue(ttRight)) then
				text = text .. " " .. ttRight
			end
			table.insert(mobData.extraInfo, text)
			if MI2.WOW_MODERN then
				local type = 0
				local tooltipData = GameTooltip:GetTooltipData()
				if tooltipData then
					local data = tooltipData.lines[idx]
					if data then type = data.type or 0 end
				end
				table.insert(mobData.extraItemData, type)
			end
			if #mobData.extraInfo > 9 then break end
		end
		previous = ttLeft
	end

	--mobData.extraInfo = { "AAA", "BBB", "CCC", "DDD" }
end

-----------------------------------------------------------------------------
-- Show vendor sell value of item in item tooltip
-- The info is added to the game tooltip.
--
local function MI2_AddItemPriceToTooltip(tooltip, itemLinkOrID)
	-- optain basic info from WoW UI to know which item is under mouse cursor
	local frame, frameName, parent
	if GetMouseFocus ~= nil
	then
		frame = GetMouseFocus()
		if not frame or frame:IsForbidden() then return end
		frameName = frame:GetName()
		parent = frame:GetParent()
		if not parent then return end
	else
		frame = GetMouseFoci()[1]
		if not frame or frame:IsForbidden() then return end
		parent = frame:GetParent()
		if not parent then return end
		frameName = parent:GetName()
	end

	local link
	local amount = 1
	local price

	if frameName and string.find(frameName, "MerchantItem") then
		if MerchantFrame.selectedTab == 1 then
			link = GetMerchantItemLink(frame:GetID())
			_, _, _, amount = GetMerchantItemInfo(frame:GetID())
		else
			link = GetBuybackItemLink(frame:GetID())
			_, _, _, amount = GetBuybackItemInfo(frame:GetID())
		end
	else
		if frameName and string.find(frameName, "MerchantBuyBackItem") then
			link = GetBuybackItemLink(GetNumBuybackItems())
			_, _, price, amount = GetBuybackItemInfo(GetNumBuybackItems())
		elseif frame.GetSlotAndBagID then
			local bagSlot, bagId = frame:GetSlotAndBagID(frame)
			if bagSlot and bagId then
				local itemInfo = C_Container.GetContainerItemInfo(bagId, bagSlot);
				if itemInfo then
					link = itemInfo.hyperlink
					amount = itemInfo.stackCount
				end
			end
		elseif frameName then
			local _, _, parentName, num = string.find(frameName, "(.+)Item(%d+)")
			if parentName == nil or num == nil then
				if not itemLinkOrID then return end
			else
				local bagId
				local bagSlot = frame:GetID()
				if parentName == "BankFrame" then
					bagId = BANK_CONTAINER
				elseif string.find(parentName, "ContainerFrame") then
					bagId = parent:GetID()
				end
				if bagId ~= nil then
					local itemInfo = C_Container.GetContainerItemInfo(bagId, bagSlot);
					if itemInfo then
						link = itemInfo.hyperlink
						amount = itemInfo.stackCount
					end
				end
			end
		end
	end

	if not (itemLinkOrID and type(itemLinkOrID) == "string") and link then
		itemLinkOrID = link
	end

	if itemLinkOrID and amount then
		-- Use link of item if available - especially for items that are based on level, itemID is not enough.
		price = price or MI2.FindItemValue(itemLinkOrID) * amount
		if price > 0 then
			tooltip:AddDoubleLine(MI2.LightBlue .. MI_TXT_PRICE .. MI2.White .. amount, MI2.White .. GetMoneyString(price))
		end
	end
end

-----------------------------------------------------------------------------
-- Build the additional game tooltip content for a given item Link or ID.
-- If the item is a known loot item this function will add the names of
-- all Mobs that drop the item to the game tooltip. Each Mob name will
-- appear on its own line.
--
function MI2.BuildItemDataTooltip(tooltip, itemLinkOrID)
	local itemId = MI2_GetItemId(itemLinkOrID)
	if itemId <= 0 then return end

	-- add item sell price to item tooltip
	if MobInfoConfig.ShowItemPrice == 1 then
		MI2_AddItemPriceToTooltip(tooltip, itemLinkOrID)
	end

	if MobInfoConfig.ItemTooltip ~= 1 then return end

	-- get the table of all Mobs that drop the item, exit if none
	local itemFound = MI2_XRefItemTable[itemId]
	if not itemFound then return end

	-- Create a list of mobs dropping this item that is indexed by only
	-- the base Mob name. For each Mob calculate the chance to drop.
	-- Create a second list referencing the same data that is indexed
	-- numerically so that it can then be sorted by chance to get.
	local numMobs = 0
	local resultList = {}
	local sortList = {}
	for unitId, itemData in next, itemFound do
		local unitName
		if type(unitId) == "string" then
			unitName = unitId
		else
			unitName = MI2_GetNameForId(unitId)
			if unitName == nil then -- check for container item
				unitName = MI2_GetNameForItem(unitId)
			end
			if unitName == nil then
				unitName = unitId
			end
		end
		for unitLevel, itemInfo in next, itemData do
			local resultData = resultList[unitName]
			if not resultData then
				numMobs = numMobs + 1
				resultData = { name = unitName, loots = 0, count = 0 }
				resultList[unitName] = resultData
				sortList[numMobs] = resultData
			end

			resultData.loots = resultData.loots + itemInfo[2]
			resultData.count = resultData.count + itemInfo[1]
			if resultData.loots > 0 then
				resultData.chance = ceil(100.0 * resultData.count / resultData.loots)
				--if itemData.chance > 100 then itemData.chance = 100 end
				if resultData.loots < 6 then
					resultData.rating = resultData.chance + resultData.loots * 1000
				else
					resultData.rating = resultData.chance + 6000
				end
			else
				resultData.chance = resultData.count
				resultData.rating = resultData.chance
			end
		end
	end

	-- sort list of Mobs by chance to get
	table.sort(sortList, function(a, b) return (a.rating > b.rating) end)

	-- add Mobs to tooltip
	tooltip:AddLine(MI2.LightBlue .. MI_TXT_DROPPED_BY .. numMobs .. " Mobs:")
	if numMobs > 8 then numMobs = 8 end
	for idx = 1, numMobs do
		local data = sortList[idx]
		if data.loots > 0 then
			tooltip:AddDoubleLine(MI2.LightBlue .. "  " .. data.name,
				MI2.White .. data.chance .. "% (" .. data.count .. "/" .. data.loots .. ")")
		else
			tooltip:AddDoubleLine(MI2.LightBlue .. "  " .. data.name, MI2.White .. data.chance)
		end
	end
end

-----------------------------------------------------------------------------
-- build class info text line for mob tooltip, class info includes the "dead"
-- and the "skinnable" tags
-- only used in custom tooltip, since built-in Blizzard tooltip already has
-- most of this info
--
local function MI2_BuildMobClassInfo(mobData, isMob, unit)
	if unit == nil then return end
	local type        = UnitCreatureType(unit) -- beast, demon, undead etc
	local family      = UnitCreatureFamily(unit) -- bear, wolf, wasp etc
	local race        = UnitRace(unit)        -- tauren, orc, etc
	local class       = UnitClassBase(unit)   -- warrior, mage etc

	mobData.class     = class
	mobData.classInfo = nil
	if UnitIsDead(unit) then
		mobData.classInfo = CORPSE
	elseif isMob then
		if family then
			mobData.classInfo = (mobData.classInfo or "") .. family .. " "
		elseif type then
			mobData.classInfo = (mobData.classInfo or "") .. type .. " "
		end
		if type ~= "Critter" then
			if race then
				mobData.classInfo = (mobData.classInfo or "") .. race .. " "
			end
			if mobData.class and MobInfoConfig.ShowClass == 1 then
				mobData.classInfo = (mobData.classInfo or "") .. class .. " "
			end
			if mobData.lowHpAction then
				mobData.classInfo = (mobData.classInfo or "") .. MI2.LightRed .. MI2_TXT_MOBRUNS
			end
		end
	end
end

-----------------------------------------------------------------------------
-- create the mobData record required for showing mob information in the
-- tooltip
--
function MI2.BuildTooltipMob(idOrName, level, unit, isMob, numLines, unique)
	local mobName = idOrName
	if type(idOrName) == "number" then
		mobName = MI2_GetNameForId(idOrName)
	end

	local mobData
	if unit then
		-- check Cache first
		local guid = UnitGUID(unit)
		if (not issecretvalue or not issecretvalue(guid)) and guid then
			local mobInfo = MI2_GetMobInfo(guid, true)
			if mobInfo then mobData = mobInfo.data end
		end
	end

	if not mobData then
		local unitClassification = nil
		if unit then unitClassification = UnitClassification(unit) end

		-- passing classific/ation here, to correct any previous missing classifications
		mobData = MI2.Database:Get(idOrName, level, unitClassification, true)
	end

	local mobDataForTooltip
	if unique == true and mobData then
		mobDataForTooltip = MI2_CopyTableContents(mobData)
	else
		mobDataForTooltip = MI2_GetMobData(mobName, level, unit, MobInfoConfig.CombinedMode == 1)
	end
	if mobDataForTooltip == nil then mobDataForTooltip = {} end
	local levelInfo = mobDataForTooltip.levelInfo or level

	if mobDataForTooltip then MI2.GetUnitBasedMobData(mobDataForTooltip, unit) end

	-- calculate kills to next level
	if (mobDataForTooltip.xp or 0) > 0 then
		if UnitXP("player") == 0 then
			mobDataForTooltip.xp = nil
		else
			-- calculate number of mobs to next level based on mob experience
			local xpCurrent = UnitXP("player") + mobDataForTooltip.xp
			local xpToLevel = UnitXPMax("player") - xpCurrent
			mobDataForTooltip.mob2Level = ceil(abs(xpToLevel / mobDataForTooltip.xp)) + 1
		end
	end

	-- avarage value computation
	local loots = mobDataForTooltip.loots or 1
	if mobDataForTooltip.copper and (loots > 0) then
		mobDataForTooltip.avgCV = ceil(mobDataForTooltip.copper / loots)
	end
	if mobDataForTooltip.itemValue and (loots > 0) then
		mobDataForTooltip.avgIV = ceil(mobDataForTooltip.itemValue / loots)
	end
	if mobDataForTooltip.avgCV or mobDataForTooltip.avgIV then
		mobDataForTooltip.avgTV = (mobDataForTooltip.avgCV or 0) + (mobDataForTooltip.avgIV or 0)
	end
	-- build level info
	if level == -2 then
		levelInfo = "SECRET"
		mobDataForTooltip.mobType = 1
		level = 0
	elseif level == -1 then
		levelInfo = "BOSS"
		mobDataForTooltip.mobType = 3
		level = 99
	elseif mobDataForTooltip.mobType == 2 then
		levelInfo = levelInfo .. "!" -- rare
	elseif mobDataForTooltip.mobType == 3 then
		levelInfo = levelInfo .. "++" -- BOSS
	elseif mobDataForTooltip.mobType == 4 then
		levelInfo = levelInfo .. "+" -- Elite
	elseif mobDataForTooltip.mobType == 6 then
		levelInfo = levelInfo .. "+!" -- rare Elite
	end

	-- PTR Code
	local col = GetDifficultyColor(level)
	mobDataForTooltip.levelInfo = MI2_ColorToText(col.r, col.g, col.b) .. "[" .. levelInfo .. "] "

	-- build various content to be shown in the tooltip
	MI2_BuildMobClassInfo(mobDataForTooltip, isMob, unit)
	MI2_BuildQualityString(mobDataForTooltip)
	MI2_BuildItemsList(mobDataForTooltip)
	if MobInfoConfig.ShowResists == 1 then
		MI2_BuildResistString(mobDataForTooltip)
	end

	mobDataForTooltip.extraInfo = {}
	mobDataForTooltip.extraItemData = {}
	if UnitExists(unit) and MobInfoConfig.UseGameTT == 0 then
		MI2_BuildExtraInfo(mobDataForTooltip, mobName, level, numLines)
	end
	return mobDataForTooltip, mobData
end

-----------------------------------------------------------------------------
-- Scan the spellbook to enter all spells and their spell school into
-- the "MI2_SpellToSchool" conversion table that is needed for resistances
-- and immunities recording.
--
function MI2.ScanSpellbook()
	local spellBookPage = 2

	while spellBookPage > 0 do
		local pageName, texture, offset, numSpells = GetSpellBookSkillLineInfo(spellBookPage)
		if pageName and offset and numSpells then
			for spellIndex = (offset + 1), (offset + numSpells) do
				local spellName = GetSpellName(spellIndex, BOOKTYPE_SPELL)
				if spellName and (not string.find(spellName, ":")) then
					for school in pairs(MI2_SpellSchools) do
						local schoolOK = string.find(pageName, school)
						if schoolOK and string.len(school) > 2 then
							MI2_SpellToSchool[spellName] = school
						end
					end
				end
			end
			spellBookPage = spellBookPage + 1
		else
			spellBookPage = 0
		end
	end
end

function MI2.Unit(unit)
	local guid = UnitGUID(unit)

	if (not issecretvalue or not issecretvalue(guid)) and guid then
		local unitName
		local unitType, _, _, _, _, unitId = strsplit("-", guid)
		unitId = tonumber(unitId, 10)
		if (unitType == "Creature" or unitType == "Vehicle") and unitId then
			unitName = UnitName(unit)
			MI2_AddMapping(unitId, unitName)
		end

		local unitLevel
		if UnitBattlePetLevel then
			unitLevel = UnitBattlePetLevel(unit)
		end
		if not unitLevel or unitLevel == 0 then
			unitLevel = UnitLevel(unit)
		end

		-- if level is a secret value, use -2; if nil, use -1 (BOSS)
		if unitLevel == nil then
			unitLevel = -1
		elseif issecretvalue and issecretvalue(unitLevel) then
			unitLevel = -2
		end

		return unitType, unitId, unitName, unitLevel, guid, MI2.IsUnitClose(unit, unitLevel), UnitClassification(unit)
	end
end

local MI2_TimeOffset = nil
-----------------------------------------------------------------------------
-- returns a unix timestamp in milliseconds
--
function MI2.GetTime()
	-- Init
	if not MI2_TimeOffset then
		MI2_TimeOffset = (GetServerTime() - floor(GetTime())) * 1000
	end

	return MI2_TimeOffset + floor(GetTime() * 1000);
end

-- MI2.PrepareForImport()
--
-- Prepare for importing external MobInfo databases into the main database.
--
function MI2.PrepareForImport()
	local mobDbSize, healthDbSize, itemDbSize = 0, 0, 0

	if MobInfoDB == nil and MI2_DB == nil then return end
	MI2_DB = MI2_DB or {}

	--	external database version number check
	local version = 0
	local locale
	if MI2_DB.info then
		version = MI2_DB.info.version
		locale = MI2_DB.info.locale
	else
		if MobInfoDB and MobInfoDB["DatabaseVersion:0"] then
			version = MobInfoDB["DatabaseVersion:0"].ver
			locale = MobInfoDB["DatabaseVersion:0"].loc
		end
	end

	if version and (version < MI2.IMPORT_DB_VERSION or version > MI2.DB_VERSION) then
		MI2_Import_Status = "BADVER"
		return
	end

	if locale and locale ~= MI2_Locale then
		MI2_Import_Status = "BADLOC"
		return
	end

	MI2.ProcessVariables()

	local levelSum, nameSum = 0, 0

 	-- calculate Mob database size and import signature
	if version == 9 then
		for index in pairs(MobInfoDB) do
			mobDbSize = mobDbSize + 1
			local mobName, mobLevel = MI2_GetIndexComponents( index )
			levelSum = levelSum + mobLevel
			nameSum = nameSum + string.len( mobName )
		end
	else
		local dbSource = MI2_DB

		if version > 10 then
			dbSource = MI2_DB.source
		end
		if dbSource then

			for index,data in pairs(dbSource) do
				mobDbSize = mobDbSize + 1
				if type(index) ~= "string" then
					index = MI2_GetNameForId(index) or ""
				end
				for mobLevel in pairs(data) do
					if type(mobLevel) == "number" then
						levelSum = levelSum + mobLevel
						nameSum = nameSum + string.len( index )
					end
				end
			end
		end
	end

	for index,data in pairs(MI2_ItemNameTable) do
		if type(index) ~= "string" then
			itemDbSize = itemDbSize + 1
		else
			for _ in pairs(data) do
				itemDbSize = itemDbSize + 1
			end
		end
	end

	MI2_Import_Signature = mobDbSize.."_"..healthDbSize.."_"..itemDbSize.."_"..levelSum.."_"..nameSum

	-- store copy of databases to be imported and calculate import status
	MobInfoDB_Import = MobInfoDB
	MI2_DB_Import = MI2_DB
	MI2_CurrencyNameTable_Import = MI2_CurrencyNameTable
	MI2_UnitId2Name_Import = MI2_UnitId2Name
	MI2_ItemNameTable_Import = MI2_ItemNameTable
	MI2_ZoneTable_Import = MI2_ZoneTable

	--MobInfoDB["DatabaseVersion:0"] = nil
	if mobDbSize > 1 then
		MI2_Import_Status = "[V"..version.."] "..(mobDbSize).." Mobs"
	end
end -- MI2.PrepareForImport()
