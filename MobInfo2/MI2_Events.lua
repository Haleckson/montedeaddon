--
-- MI2_Events.lua
--
-- Handlers for all WoW events that MobInfo subscribes to. This includes
-- the main MobInfo OnEvent handler called "MI2_OnEvent()". Event handling
-- is based on a global table of event handlers called "MI2_EventHandlers[]".
-- For each event that MobInfo supports the corresponding handler function
-- is available in the table.
--
-- (this is code restructering work in progress, it has not yet been completed ... )
--

local _, MI2 = ...

-- global variables initialisation
MI2.Target = {}
MI2.LastTargetIdx = {}
MI2.CurZone = 0

-- module-local variables
local MI2_IsNonMobLoot = nil
MI2.MI2_TradeskillUsed = nil

-- local variables declaration and initialisation
local MI2_EventHandlers = { }
local MI2_TT_SetItem
local MI2_OnTooltipSetItem

local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

function MI2.Encode(data)
    local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false}, data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

function MI2.Decode(encoded)
	local compressed = LibDeflate:DecodeForPrint(encoded)
	if not compressed then
		return nil
	end
	local serialized = LibDeflate:DecompressDeflate(compressed)
	local success, data = LibSerialize:Deserialize(serialized)
	if not success then
		return nil
	end
	return data
end

function MI2.ProcessVariables()
	if type(MI2_DB) == "string" then
		MI2_DB = MI2.Decode(MI2_DB)
	end

	if type(MI2_DB.source) == "string" then
		MI2_DB.source = MI2.Decode(MI2_DB.source)
	end

	if type(MI2_DB.location) == "string" then
		MI2_DB.location = MI2.Decode(MI2_DB.location)
	end

	if type(MI2_DB.character) == "string" then
		MI2_DB.character = MI2.Decode(MI2_DB.character)
	end

	if type(MI2_ItemNameTable) == "string" then
		MI2_ItemNameTable = MI2.Decode(MI2_ItemNameTable)
	end
	if type(MI2_UnitId2Name) == "string" then
		MI2_UnitId2Name = MI2.Decode(MI2_UnitId2Name)
	end
	if type(MI2_CurrencyNameTable) == "string" then
		MI2_CurrencyNameTable = MI2.Decode(MI2_CurrencyNameTable)
	end
	if type(MI2_CharTable) == "string" then
		MI2_CharTable = MI2.Decode(MI2_CharTable)
	end
	if type(MI2_ZoneTable) == "string" then
		MI2_ZoneTable = MI2.Decode(MI2_ZoneTable)
	end
	if type(MI2_RecentLoots) == "string" then
		MI2_RecentLoots = MI2.Decode(MI2_RecentLoots)
	end
end

-----------------------------------------------------------------------------
-- MI2_VariablesLoaded()
--
-- main global initialization function, this is called as the handler
-- for the "VARIABLES_LOADED" event
--
local function MI2_VariablesLoaded(self, event, ...)

	if type(MI2_DB) == "string" then
		MI2_DB = MI2.Decode(MI2_DB)
	end

	-- initialize "MobInfoConfig" data structure (main MobInfo config options)
	MI2.InitOptions(self)

	-- register with all AddOn managers that MobInfo attempts to support
	MI2.RegisterWithAddonManagers(self)

	MI2.OptionParse( self, "", {}, nil )

	-- ensure that MobHealthFrame get set correctly (if we have to set it for compatibility)
	if  MobHealthFrame == "MI2"  then
		MobHealthFrame = MI2_MobHealthFrame
	end

	-- setup a confirmation dialog for critical configuration options
	StaticPopupDialogs["MOBINFO_CONFIRMATION"] = {
		button1 = "Ok", --TEXT(OKAY),
		button2 = "Cancel", --TEXT(CANCEL),
		showAlert = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		interruptCinematic = 1
	}
	StaticPopupDialogs["MOBINFO_SHOWMESSAGE"] = {
		button1 = "Ok", --TEXT(OKAY),
		showAlert = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		interruptCinematic = 1
	}

	MI2.ProcessVariables()

	MI2.Database = CreateAndInitFromMixin(MI2.DatabaseMixin, MI2_DB)

	-- checking and cleanup for all databases
	MI2.CheckAndCleanDatabases()

	-- initialize slash commands processing
	MI2.SlashInit()
	-- build cross reference table for fast item tooltips
	MI2.BuildXRefItemTable()

	-- extend the spell school table to list both schools and schortcuts
	local newSchools = {}
	for school, schortcut in pairs(MI2_SpellSchools) do
		newSchools[school] = schortcut
		newSchools[schortcut] = school
	end
	MI2_SpellSchools = newSchools
	MI2_SpellSchools[64] = "ar"
	MI2_SpellSchools[32] = "sh"
	MI2_SpellSchools[16] = "fr"
	MI2_SpellSchools[8] = "na"
	MI2_SpellSchools[4] = "fi"
	MI2_SpellSchools[2] = "ho"

	-- from this point onward process events
	MI2.InitializeEventTable(self)

	MI2.UpdateOptions()
	MI2.InitializeTooltip()
	MI2.SetupTooltip()

	-- register for catching tooltip events
	if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, MI2_OnTooltipSetItem)
	else
		MI2_TT_SetItem = GameTooltip:GetScript("OnTooltipSetItem")
		GameTooltip:SetScript( "OnTooltipSetItem", MI2_OnTooltipSetItem )
	end
end -- MI2_VariablesLoaded()

local function MI2_EventLootReady(self, event, ...)
	MI2.ProcessLootReady()
end -- MI2_EventLootOpened()

-----------------------------------------------------------------------------
-- MI2_EventLootClosed()
--
-- Event handler for WoW event that the loot window has been closed.
-- This is used to catch empty loots when using auto-loot (Shift+RightClick)
-- In this case "LOOT_CLOSED" is the only loot event that fires
--
local function MI2_EventLootClosed(self, event, ...)
	MI2.ProcessLootClosed()
end

----------------------------------------------------------------------------
-- Event handler for the "PLAYER_TARGET_CHANGED" event. This handler will
-- fill the global variable "MI2.Target" with all the data that MobInfo
-- needs to know about the current target.
--
function MI2.OnTargetChanged(self, event, ...)
	local unit = "target"
	local _, unitId, unitName, unitLevel, unitGuid, unitIsClose, UnitClassification = MI2.Unit(unit)

	MI2_IsNonMobLoot = false -- to reset non Mob loot detection

	-- previous target post processing
	if  MI2.Target.mobIndex then
		MI2.LastTargetIdx = CopyTable(MI2.Target)
--		if MobInfoConfig.SaveResist == 1 then
--			local entry = MI2.FetchMobDataFromGUID(MI2.Target.guid, MI2.Target.level)
--			if entry then entry:SaveResistData() end
--		end
	end

	if unitId and unitLevel then
		MI2.Target = { name=unitName, level=unitLevel, guid=unitGuid, id = unitId }

		if  not UnitPlayerControlled(unit)  then
			MI2.Target.mobIndex = unitName..":"..unitLevel

			local mobData, fromCache = MI2.FetchMobDataFromGUID(unitGuid, unitLevel, unitId, unit)
			if not fromCache and mobData
			then
				MI2.CacheMobInfo(unitGuid, unitName, unitLevel, mobData, unitIsClose, UnitClassification)
			else
				if unitIsClose then
					MI2.RecordLocation( unitGuid )
				end
			end
			if unitLevel > 0 and unitLevel < (UnitLevel("player") + 5) then MI2.Target.ResOk = true end
		end
	else
		MI2.Target = {}
	end

	-- update options dialog if shown
    if  MI2_OptionsFrame:IsVisible()  then
		MI2_DbOptionsFrameOnShow()
	end

    MI2.midebug( "new target: idx=[nil], last=["..(MI2.LastTargetIdx.name or "nil").."]", 1 )
end


-- abbreviated list from KarniCrap's lib_Tradskills.lua
-- used without permission o_O

local KarniCrap_tradeskillList = {
	[49383] = "Engineering",		-- skin mob
	[32606] = "Mining",				-- skin mob
-- Herb Gathering
    [32605] = "Herb Gathering",     -- herb mob
	[2366]  = "Herb Gathering", 	-- Apprentice
	[2368]  = "Herb Gathering", 	-- Journeyman
	[3570]  = "Herb Gathering", 	-- Expert
	[11993] = "Herb Gathering", 	-- Artisan
	[28695] = "Herb Gathering", 	-- Master
	[50300] = "Herb Gathering", 	-- Grand Master
	[74519] = "Herb Gathering", 	-- Illustrious
-- Skinning
	[8613]  = "Skinning", 			-- Apprentice
	[8617]  = "Skinning", 			-- Journeyman
	[8618]  = "Skinning",			-- Expert
	[10768] = "Skinning", 			-- Artisan
	[32678] = "Skinning", 			-- Master
	[50305] = "Skinning", 			-- Grand Master
	[74522] = "Skinning", 			-- Illustrious
    [158756] = "Skinning",          -- Draenor Master
    [195125] = "Skinning",          -- Legion Master
	[195258] = "Skinning",          -- Mother's Skinning Knife
}

-----------------------------------------------------------------------------
-- MI2_EventSpellStart()
--
-- handler for event "UNIT_SPELLCAST_START"
-- store the latest info used for determining node info for source
--
local function MI2_EventSpellStart(self, event, caster, spell, id)
	if caster=="player" then
		-- keep track of the tooltip title and first line of text to capture node info
		-- in some cases it might either pick the wrong text (if multiple game objects are close) or
		-- when you move and while for example gathering is 'active' (it will hide the gametooltip)
		MI2_GT_SpellId = id
		MI2_GT_Title = GameTooltipTextLeft1:GetText()

		-- This could be a secret and we will force it to be nil
		if MI2_GT_Title and issecretvalue and issecretvalue(MI2_GT_Title)
		then 
			MI2_GT_Title = nil
		end
	end
end -- MI2_EventSpellStart()

-----------------------------------------------------------------------------
-- MI2_EventSpellSucceeded()
--
-- handler for event "UNIT_SPELLCAST_SUCCEEDED"
-- checks for successfully skinning, mining, or herbalizing a mob
--
local function MI2_EventSpellSucceeded(self, event, caster, spell, id)
	if caster=="player" then
	-- the spell was cast on a mob... is it a tradeskill?
		-- link = GetSpellLink(id)
		-- printfd("%s successfully cast %s (id: %s)", caster or 'nil',link or 'nil',id or 'nil')
		if KarniCrap_tradeskillList[id] then
			--printfd("%s successfully used %s (id: %s) on mob", caster or 'nil',link or 'nil',id or 'nil')
			MI2.MI2_TradeskillUsed = id
		end
	end
end -- MI2_EventSpellSucceeded()

-----------------------------------------------------------------------------
-- MI2.EventCreatureDiesXP()
--
-- event handler for "CHAT_MSG_COMBAT_XP_GAIN" event
-- indicates that a mob died and gave XP points
--
function MI2.EventCreatureDiesXP(self, event, ...)
	local message = ...

	-- Some messages may be secrets
	if issecretvalue and issecretvalue(message) then return end

	local _,_, creature, xp = string.find( message, MI2_ChatScanStrings[3] )
	if creature and xp then
--		MI2.printf("kill event with XP: mob="..creature..", xp="..xp )
		MI2.RecordKilledXP( creature, tonumber(xp) )
	end
end -- MI2.EventCreatureDiesXP()

-----------------------------------------------------------------------------
-- event handler for "CHAT_MSG_MONSTER_EMOTE" event
--
local function MI2_EventMonsterEmote(self, event, ...)
	local message, sender = ...

	-- Some messages may be secrets
	if issecretvalue and issecretvalue(message) then return end

	local s = string.find( message, MI2_CHAT_MOBRUNS )
	if s then
		MI2.RecordLowHpAction( sender, 1 )
	end
end


-----------------------------------------------------------------------------
-- event handler for "ZONE_CHANGED_NEW_AREA" and "ZONE_CHANGED_INDOORS"
-- this is processed for mob location tracking so that we know the zone
--
local function MI2_EventZoneChanged(self, event, ...)
	MI2.SetNewZone( GetZoneText() )
end -- MI2_EventZoneChanged()


-----------------------------------------------------------------------------
-- MI2_Player_Login()
--
-- register the GameTooltip:OnShow event at player login time. This ensures
-- that MobInfo is the (hopefully) last AddOn to hook into this event.
--
local function MI2_Player_Login(self, event, ...)
	-- set current zone
	MI2_EventZoneChanged()

	-- scan spellbook to fill spell to school conversion table
	MI2.ScanSpellbook()

	MI2.chattext( "MobInfo2  "..MI2.VersionNum.."  Loaded,  ".."enter /mi2 or /mobinfo for interface")

	-- collect all the garbage caused by loading the AddOn
	collectgarbage( "collect" )

	-- Handle loot summary persistence: auto-reset or restore
	C_Timer.After(0, function()
		if MobInfoConfig.AlwaysResetSummary ~= 1 then
			local ok, err = pcall(MI2.LoadSummaryDB)
			if not ok then
				MI2_SummaryDB = nil
				MI2.chattext("MobInfo2: summary restore failed (" .. tostring(err) .. "), starting fresh.")
			end
		end
		MI2.RestoreLayoutFromDB()
		if MobInfoConfig.AlwaysResetSummary == 1 then
			MI2_SummaryFrame:OnReset()
			MI2_SummaryDB = nil
		end
	end)
end -- MI2_Player_Login()

-----------------------------------------------------------------------------
-- MI2_Player_Logout()
--
-- Encode MI2_DB on log out
--
local function MI2_Player_Logout(self, event, ...)
	-- Save loot summary before WoW writes SavedVariables
	local ok, err = pcall(MI2.SaveSummaryDB)
	if not ok then
		MI2_SummaryDB = nil
	end

	if MobInfoConfig.SaveCompressed == 1 then
		for k,v in pairs(MI2_DB.character) do
			if type(v) == "table" then
				MI2_DB.character[k] = MI2.Encode(v)
			end
		end
		if type(MI2_DB.source) == "table" then
			MI2_DB.source = MI2.Encode(MI2_DB.source)
		end
		if type(MI2_DB.location) == "table" then
			MI2_DB.location = MI2.Encode(MI2_DB.location)
		end
		if type(MI2_ItemNameTable) == "table" then
			MI2_ItemNameTable = MI2.Encode(MI2_ItemNameTable)
		end
		if type(MI2_UnitId2Name) == "table" then
			MI2_UnitId2Name = MI2.Encode(MI2_UnitId2Name)
		end
		if type(MI2_CurrencyNameTable) == "table" then
			MI2_CurrencyNameTable = MI2.Encode(MI2_CurrencyNameTable)
		end
		if type(MI2_CharTable) == "table" then
			MI2_CharTable = MI2.Encode(MI2_CharTable)
		end
		if type(MI2_ZoneTable) == "table" then
			MI2_ZoneTable = MI2.Encode(MI2_ZoneTable)
		end
		if type(MI2_RecentLoots) == "table" then
			MI2_RecentLoots = MI2.Encode(MI2_RecentLoots)
		end
	end

end -- MI2_Player_Logout()

-----------------------------------------------------------------------------
-- MI2_OnTooltipSetItem
--
-- OnTooltipSetItem event handler for the GameTooltip frame
-- This handler will :
--   * if a known item is hovered add the corresponding item data
--   * call the original handler which it replaces
--
MI2_OnTooltipSetItem = function( ... )
	-- call original WoW event for OnTooltipSetItem
	if MI2_TT_SetItem then
		MI2_TT_SetItem(...)
	end

	if MobInfoConfig.KeypressMode == 1 and not IsAltKeyDown() then  return  end

	local tooltip, tooltipData = ...
	local _, itemLink
	if MobInfoConfig.ShowItemInfo == 1 then
		if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item and tooltip ~= GameTooltip then
			itemLink = tooltipData.hyperlink
			if not itemLink and tooltipData.guid then
				itemLink = C_Item.GetItemLinkByGUID(tooltipData.guid)
			end
		else
			_, itemLink = tooltip:GetItem()
		end
		if itemLink then
			-- add item loot info to item tooltip
			MI2.BuildItemDataTooltip( tooltip, itemLink  )
		end
	end
end -- MI2_OnTooltipSetItem()


-----------------------------------------------------------------------------
-- MI2.InitializeEventTable()
--
-- This function enables (ie. registers) only those events that are
-- needed for the current MobInfo recording options. The general rule is
-- that we only register events if we want to record the data of the event.
--
function MI2.InitializeEventTable(self)
	-- reset all events to their always on flag state
	for eventName, eventInfo in pairs(MI2_EventHandlers) do
		local eventEnabled = eventInfo.always or MobInfoConfig.SaveBasicInfo == 1 
			and (eventInfo.basic
				or MobInfoConfig.SaveCharData == 1 and eventInfo.char
				or MobInfoConfig.SaveItems == 1 and eventInfo.items)
		if eventEnabled then
			self:RegisterEvent( eventName )
		else
			self:UnregisterEvent( eventName )
		end
	end
end -- MI2.InitializeEventTable()


-----------------------------------------------------------------------------
-- MI2_OnEvent()
--
-- MobInfo main event handler function, gets called for all registered events
-- uses table with event handler info
--
function MI2_OnEvent(self, event, ...)	
	--MI2.midebug("event="..event..", a1="..(arg1 or "<nil>")..", a2="..(arg2 or "<nil>")..", a3="..(arg3 or "<nil>")..", a4="..(arg4 or "<nil>"))
	MI2_EventHandlers[event].f(self, event, ...)
end -- MI2_OnEvent

-----------------------------------------------------------------------------
-- MI2_OnCombatLogEvent()
--
-- MobInfo main event handler function, gets called for all registered events
-- uses table with event handler info
--
local MI2_AttackedGUIDs = {}
local function MI2_OnCombatLogEvent(self, event, ...)
	--time, sourceSerial, sourceName, sourceFlags, targetSerial, targetName, targetFlags, targetRaidFlags, spellId, spellName, spellType, amount, overkill, school, resisted, blocked, absorbed, critical, glacing, crushing, isoffhand, isreflected

	local timestamp, subEvent, hideCaster, sourceGUID, sourceName,
	 sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,
	 destRaidFlags, amount_spellId, overkill_spellName, school_spellSchool, resisted_amount,
	 blocked_overkill, absorbed_school, critical_resisted, glancing_blocked, crushing_absorbed,
	 isOffHand_critical,  glancing, crushing, isOffHand = CombatLogGetCurrentEventInfo()
	--MI2.midebug("@event="..subEvent..", sourceGUID="..(sourceGUID or "<nil>")..", sourceName="..(sourceName or "<nil>")..", destGUID="..(destGUID or "<nil>")..", destName="..(destName or "<nil>")..", destFlags="..(destFlags or "<nil>")..", amount_spellid="..(amount_spellId or "<nil>")..", overkill_spellname="..(overkill_spellName or "<nil>")..", school_spellSchool="..(school_spellSchool or "<nil>")..", resisted_amount="..(resisted_amount or "<nil>")..", blocked_overkill="..(blocked_overkill or "<nil>"))

	if destGUID ~= nil
	then
		local guidType = select(1,strsplit("-", destGUID))
		if UnitGUID("player") == destGUID then
			--print(subEvent.." sid:"..(amount_spellId or "~").." ra:"..(tostring(resisted_amount or "~")).." cr:"..(tostring(critical_resisted or "~")))
			local damage
			if subEvent == "SWING_DAMAGE" and not critical_resisted then
				damage = amount_spellId
			elseif (subEvent=="SPELL_PERIODIC_DAMAGE" or subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE") and not isOffHand_critical then
				damage = resisted_amount
			end
			if damage and damage > 0 then
				MI2.RecordDamage( sourceGUID, tonumber(damage) )
			end
		elseif (guidType ~= "Player" and guidType ~= "Pet")
		then
--		    print(subEvent.." sid:"..(amount_spellId or "~").." ra:"..(resisted_amount or "~").." cr:"..(tostring(critical_resisted) or "~"))
			-- When any damage is done by player or player's pet, record the mob
			if ((subEvent=="SPELL_PERIODIC_DAMAGE" or subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE") and (sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet")))
			then
				local damage, sp, sc
				if subEvent == "SWING_DAMAGE" then 
--					print(subEvent.." "..amount_spellId.." / "..(overkill_spellName or '~'))
					damage = amount_spellId
				else
					--print(subEvent.." "..resisted_amount.." / "..(blocked_overkill or '~').." > "..amount_spellId..","..school_spellSchool)
					damage = resisted_amount
					sp = amount_spellId
					sc = school_spellSchool
				end
				if damage and damage > 0 then
					MI2.RecordHit(destGUID, damage, sp, sc, subEvent == "SPELL_PERIODIC_DAMAGE" )
				else
					print("@!@Resists "..(sp or "<nil>").." "..(sc or "<nil>"))
					MI2.RecordImmunResist( destGUID, sp, critical_resisted )
				end
				MI2_AttackedGUIDs[destGUID] = true
			elseif (subEvent=="SPELL_MISSED" and resisted_amount == "IMMUNE") then
			--	print(subEvent)
			--	print("@!@Resists "..(amount_spellId or "<nil>").." "..(school_spellSchool or "<nil>"))
			--	MI2.midebug("@event="..subEvent..", sourceGUID="..(sourceGUID or "<nil>")..", sourceName="..(sourceName or "<nil>")..", destGUID="..(destGUID or "<nil>")..", destName="..(destName or "<nil>")..", destFlags="..(destFlags or "<nil>")..", amount_spellid="..(amount_spellId or "<nil>")..", overkill_spellname="..(overkill_spellName or "<nil>")..", school_spellSchool="..(school_spellSchool or "<nil>")..", resisted_amount="..(resisted_amount or "<nil>")..", blocked_overkill="..(blocked_overkill or "<nil>"))
			elseif (subEvent=="PARTY_KILL" and (MobInfoConfig.SaveAllPartyKills or 0) == 1)
			then
				--MI2.printf("Saved kill for %s - %s by %s", guidType, destName, sourceName)
				MI2_AttackedGUIDs[destGUID] = true
			elseif (subEvent=="UNIT_DIED" and destGUID ~= nil and MI2_AttackedGUIDs[destGUID] == true)
			then
				MI2.RecordKill(destGUID,destName)
				MI2_AttackedGUIDs[destGUID] = nil
			end
		end
	end 
end -- MI2_OnCombatLogEvent

local MI2_UnitLootSeen = {}

local function MI2_RecordEmptyLoot(guid, level)
	local entry = MI2.Database:GetFromGUID(guid, level, nil, true)
	if entry then
		entry:AddEmptyLoot()
		if MobInfoConfig.SaveBasicInfo == 1 then
			entry:SaveBasicInfo()
		end
	end
end

local MI2_EmptyLootCheckTimerScheduled = false
local MI2_PendingEmptyLootKills = {}
local MI2_EmptyLootDelay = 1

local function MI2_SchedulePendingEmptyLootChecks()
	if MI2_EmptyLootCheckTimerScheduled then
		return
	end

	local earliestExpiry
	for _, expiresAt in pairs(MI2_PendingEmptyLootKills) do
		earliestExpiry = not earliestExpiry and expiresAt.expires or math.min(earliestExpiry, expiresAt.expires)
	end

	if earliestExpiry then
		MI2_EmptyLootCheckTimerScheduled = true
		C_Timer.After(math.max(0.01, earliestExpiry - GetTime()), function()
			local now = GetTime()
			for guid, pendingKill in pairs(MI2_PendingEmptyLootKills) do
				if pendingKill.expires <= now then
					MI2_PendingEmptyLootKills[guid] = nil
					MI2_RecordEmptyLoot(guid, pendingKill.level)
				end
			end
			MI2_EmptyLootCheckTimerScheduled = false
			MI2_SchedulePendingEmptyLootChecks()
		end)
	end
end

-- Track a successfully recorded kill for delayed empty-loot detection. The
-- GUID and resolved level are retained only until the grace period expires.
local function MI2_TrackConfirmedKillForLoot(guid, level)
	if MI2_UnitLootSeen[guid] then
		MI2_UnitLootSeen[guid] = nil
	else
		MI2_PendingEmptyLootKills[guid] = {
			level = level,
			expires = GetTime() + MI2_EmptyLootDelay,
		}
		MI2_SchedulePendingEmptyLootChecks()
	end
end

-- MI2_DiedGUIDs tracks GUIDs that we know have died (from PARTY_KILL or
-- UNIT_DIED), independently of MI2_AttackedGUIDs (GUIDs we know were
-- attacked by us/our pet, from UNIT_COMBAT or PARTY_KILL). WoW does not
-- guarantee the relative firing order of PARTY_KILL/UNIT_DIED/UNIT_COMBAT
-- for the same death, so "attacked" and "died" can become known in either
-- order. MI2_TryRecordKill() is called after either fact is learned and
-- only records+clears once both are present, making kill tracking order-
-- independent without deferring processing until combat ends.
local MI2_DiedGUIDs = {}

-- UNIT_DIED and PARTY_KILL can both report one death; keep successful GUIDs
-- marked until combat ends so the second event cannot count the kill twice.
local MI2_RecordedKillGUIDs = {}

-- Record a kill once both attack attribution and death are known, regardless
-- of event order. Suppress duplicate death signals and queue loot tracking
-- only when MI2.RecordKill successfully records the mob.
local function MI2_TryRecordKill(guid)
	if not MI2_AttackedGUIDs[guid] or not MI2_DiedGUIDs[guid] then
		return
	end

	if not MI2_RecordedKillGUIDs[guid] then
		local level = MI2.RecordKill(guid)
		if level then
			MI2_RecordedKillGUIDs[guid] = true
			MI2_TrackConfirmedKillForLoot(guid, level)
		end
	end
	MI2_AttackedGUIDs[guid] = nil
	MI2_DiedGUIDs[guid] = nil
end

local function MI2_OnPlayerRegenEnabled(self, event, ...)
	-- reset theAttackedGUIDs/DiedGUIDs caches - any unresolved entries here (e.g.
	-- attacked without ever seeing a matching death, or vice versa) are just
	-- stale leftovers from this pull and are safe to drop.
	MI2_AttackedGUIDs = {}
	MI2_DiedGUIDs = {}
	MI2_RecordedKillGUIDs = {}
	MI2_UnitLootSeen = {}
end

local function MI2_EventUnitLoot(self, event, unitGUID, hasLoot )
	if (issecretvalue and issecretvalue(unitGUID)) or not unitGUID or not hasLoot then
		return
	end

	-- Consume a pending check, or remember loot arriving before kill.
	if MI2_PendingEmptyLootKills[unitGUID] then
		MI2_PendingEmptyLootKills[unitGUID] = nil
	else
		MI2_UnitLootSeen[unitGUID] = true
	end
end

local function MI2_GuidMatches(firstGuid, secondGuid)
	if issecretvalue and (issecretvalue(firstGuid) or issecretvalue(secondGuid)) then
		return false
	end
	return firstGuid ~= nil and secondGuid ~= nil and firstGuid == secondGuid
end

-----------------------------------------------------------------------------
-- MI2_EventPartyKill()
--
-- Event handler for the PARTY_KILL event. Marks a unit as attacked if the
-- player (or the player's pet) was the killer, or if SaveAllPartyKills is
-- enabled, and always marks it as died (PARTY_KILL always means unitGUID
-- died, regardless of who gets credit as attacker). MI2_TryRecordKill()
-- then records the kill immediately if the attacked fact is already known
-- too (whether from an earlier PARTY_KILL/UNIT_COMBAT/UNIT_THREAT_LIST_UPDATE,
-- or - since order isn't guaranteed - if UNIT_DIED already ran before this).
--
-- Note: killing blows landed by a pet (hunter pet, warlock demon, DK ghoul,
-- etc.) report the pet's GUID as killer, not the player's. We must also
-- check against UnitGUID("pet") to avoid under-counting kills compared to
-- loot, since looting is still possible even when the pet got the last hit.
--
local function MI2_EventPartyKill(self, event, killerGUID, unitGUID)
	local playerGUID = UnitGUID("player")
	local petGUID = UnitGUID("pet")
	local isPlayerKiller = MI2_GuidMatches(killerGUID, playerGUID)
	local isPetKiller = MI2_GuidMatches(killerGUID, petGUID)
	local saveAllKills = (MobInfoConfig.SaveAllPartyKills or 0) == 1

	if (not issecretvalue or not issecretvalue(unitGUID)) and unitGUID then
		MI2_DiedGUIDs[unitGUID] = true
		if isPlayerKiller or isPetKiller or saveAllKills
		then
			MI2_AttackedGUIDs[unitGUID] = true
		end
		MI2_TryRecordKill(unitGUID)
	end
end

-----------------------------------------------------------------------------
-- MI2_MarkAttacked()
--
-- Marks pet-engaged targets from their threat state, and uses the raid
-- combat-state fallback when threat attribution is unavailable. Used by both
-- MI2_EventUnitCombat and MI2_EventUnitThreatListUpdate below,
-- since UNIT_COMBAT (a legacy event tied to combat text) has been observed
-- in practice to sometimes simply not fire at all; UNIT_THREAT_LIST_UPDATE
-- is driven by the core threat system and gives us a second, more reliable
-- trigger for the exact same check, rather than relying on UNIT_COMBAT as
-- the sole source of truth.
--
-- Deliberately NOT restricted to unit=="target": both events fire for
-- whatever unit token is involved (nameplateN, partyN, bossN, etc.), and in
-- AoE pulls it's common to kill several mobs that were never individually
-- targeted. Restricting to "target" would silently drop raid-attacked
-- tracking for every mob besides the one actually targeted, leaving those
-- kills to rely solely on PARTY_KILL's killer-GUID match succeeding.
--
-- Neither event gives us a killer/source GUID (unlike PARTY_KILL), so we use
-- the pet's current target GUID and threat where available. We also exclude
-- player-controlled units (other players/their pets showing up via nameplates
-- etc.).
-- Limitation: In raids, this may record kills from other raid members if
-- they engage the same unit.
--
local function MI2_MarkAttacked(unit, unitGuid)
	if not unitGuid or MI2_AttackedGUIDs[unitGuid] or UnitPlayerControlled(unit) then
		return
	end

	local petThreat = UnitThreatSituation and UnitThreatSituation("pet", unit)
	local petThreatKnown = not issecretvalue or not issecretvalue(petThreat)
	local petHasThreat = petThreatKnown and petThreat ~= nil
	local petTargetGUID = UnitGUID("pettarget")
	local petTargetMatch = MI2_GuidMatches(petTargetGUID, unitGuid)
	local raidInvolvement = IsInRaid() and
		(UnitAffectingCombat("player") or UnitAffectingCombat("pet")) and
		UnitAffectingCombat(unit)

	if petHasThreat or petTargetMatch or raidInvolvement then
		MI2_AttackedGUIDs[unitGuid] = true
		-- unitGuid may already be in MI2_DiedGUIDs if UNIT_DIED/PARTY_KILL for
		-- it fired before we got here - order isn't guaranteed, so resolve now.
		MI2_TryRecordKill(unitGuid)
	end
end

-----------------------------------------------------------------------------
-- MI2_CacheUnitMobInfo()
--
-- Shared "cache this unit's mob name/level/location" logic, used by both
-- MI2_EventUnitCombat and MI2_EventUnitThreatListUpdate below.
--
-- This matters for kill recording, not just tooltips: MI2.RecordKill(guid)
-- can only look up the mob's level from this cache (MI2_GetMobInfo); if it
-- misses, it falls back to guessing the level from MI2.Target/
-- MI2.LastTargetIdx, which is wrong for AoE-killed units that were never
-- our target, or the kill gets silently dropped entirely if no guess is
-- available either. PARTY_KILL/UNIT_DIED never get a live unit token, so
-- they can't populate this cache themselves - only UNIT_COMBAT and
-- UNIT_THREAT_LIST_UPDATE can. Since UNIT_COMBAT alone isn't reliable
-- enough to depend on (see MI2_MarkRaidAttacked), running this from both
-- events maximizes the chance the level is cached by the time a kill
-- actually needs it. It's still not a full guarantee: if attacked only
-- ever gets set via PARTY_KILL for a unit neither event ever fired for,
-- the level-guessing fallback in MI2.RecordKill is the last resort.
--
-- Returns the resolved (possibly updated) unitGuid.
--
local function MI2_CacheUnitMobInfo(unit, unitGuid)
	if UnitPlayerControlled(unit) then
		return unitGuid
	end

	local _, unitId, unitName, unitLevel, guid, unitIsClose, unitClassification = MI2.Unit(unit)
	unitGuid = guid or unitGuid
	if unitGuid then
		local mobData, fromCache = MI2.FetchMobDataFromGUID(unitGuid, unitLevel, unitId, unit)
		if not fromCache and mobData then
			MI2.CacheMobInfo(unitGuid, unitName, unitLevel, mobData, unitIsClose, unitClassification)
		elseif unitIsClose then
			MI2.RecordLocation(unitGuid)
		end
	end
	return unitGuid
end

-----------------------------------------------------------------------------
-- MI2_EventUnitCombat()
--
-- Event handler for UNIT_COMBAT event. Caches the unit and marks it as
-- attacked when pet threat or the raid fallback indicates our involvement.
--
-- Note: COMBAT_LOG_EVENT_UNFILTERED is no longer available as of WoW 12.0,
-- so this method combines with PARTY_KILL, UNIT_DIED, and
-- UNIT_THREAT_LIST_UPDATE for kill tracking.
--
-- Independent of the raid kill-tracking, UNIT_COMBAT also gives us a
-- unit token for whatever unit is fighting - not necessarily our current
-- target. We use that (via MI2_CacheUnitMobInfo) to cache the mob's
-- name/level info the same way we do for mouseover/target (see
-- MI2.CreateTooltip / MI2.OnTargetChanged), since we may never target or
-- hover over this unit otherwise.
--
local function MI2_EventUnitCombat(self, event, unit, flagText, amount, schoolMask)
	-- "softenemy"/"softfriend"/"softinteract" are the reticle/auto-target-scan
	-- soft targets (Dragonflight+), not something the player is necessarily
	-- fighting - just whatever's nearby/faced. Crediting raid-attacked status
	-- off a soft target would be a false positive: the player could be in
	-- combat with something else entirely while merely facing an unrelated
	-- mob that someone else is fighting.
	if not unit or string.sub(unit, 1, 4) == "soft" then return end

	local unitGuid = UnitGUID(unit)
	if issecretvalue and issecretvalue(unitGuid) then
		unitGuid = nil
	end
	if unitGuid and MI2_AttackedGUIDs[unitGuid] then
		return
	end

	unitGuid = MI2_CacheUnitMobInfo(unit, unitGuid)

	MI2_MarkAttacked(unit, unitGuid)
end

-----------------------------------------------------------------------------
-- MI2_EventUnitThreatListUpdate()
--
-- Handler for UNIT_THREAT_LIST_UPDATE. Provides a second, more reliable
-- path (see MI2_MarkAttacked) to mark a unit as attacked, since
-- UNIT_COMBAT alone has been observed to sometimes not fire at all. This
-- event is driven by the core threat system rather than combat text, so it
-- fires whenever the player/pet's threat on a unit actually changes - for
-- whatever unit token that is (nameplateN, partyN, bossN, target, etc.),
-- not just our current target (see MI2_MarkRaidAttacked for why).
--
-- Also runs MI2_CacheUnitMobInfo, same as MI2_EventUnitCombat: since this
-- event may be the only one of the two that ever fires for a given unit,
-- it needs to be able to cache mob name/level on its own too (see
-- MI2_CacheUnitMobInfo for why that matters for kill recording).
--
local function MI2_EventUnitThreatListUpdate(self, event, unit)
	-- see MI2_EventUnitCombat for why soft-target tokens are excluded
	if not unit or string.sub(unit, 1, 4) == "soft" then return end

	local unitGuid = UnitGUID(unit)
	if issecretvalue and issecretvalue(unitGuid) then
		unitGuid = nil
	end
	if unitGuid and MI2_AttackedGUIDs[unitGuid] then
		return
	end

	unitGuid = MI2_CacheUnitMobInfo(unit, unitGuid)

	MI2_MarkAttacked(unit, unitGuid)
end

-----------------------------------------------------------------------------
-- MI2_EventUnitDied()
--
-- Only used for wow version 12 or higher, since COMBAT_LOG_EVENT_UNFILTERED
-- is no longer available. That event allowed to keep track of damage done by
-- the player and when unit died (regardless if it was targetted, aka AOE).
--
-- With version 12, kill attribution instead comes from PARTY_KILL,
-- UNIT_COMBAT, and UNIT_THREAT_LIST_UPDATE (see MI2_MarkRaidAttacked) marking
-- a GUID as attacked, for whatever unit token each fires for - not just
-- "target" (see MI2_MarkRaidAttacked for why AoE/never-targeted kills need
-- that too).
--
-- UNIT_DIED fires for every death, not just ones we caused, so we always
-- mark unitGUID as died here and let MI2_TryRecordKill() decide whether it
-- was also attacked by us - via PARTY_KILL, UNIT_COMBAT, or
-- UNIT_THREAT_LIST_UPDATE, any of which may have fired either before or
-- after this event.
--
local function MI2_EventUnitDied(self, event, unitGUID)
	if (not issecretvalue or not issecretvalue(unitGUID)) and unitGUID then
		MI2_DiedGUIDs[unitGUID] = true
		MI2_TryRecordKill(unitGUID)
	end
end

-----------------------------------------------------------------------------
-- MI2_OnLoad()
--
-- Set up main event handler table and do stuff that must be done before
-- "VARIABLES_LOADED" is called.
--
function MI2_OnLoad(self)
	-- main MobInfo event handler table
	-- "f"=function to call, "always"=event always on flag, "basic"=mob basic info event, 
	-- "items"=item tracking event, "loc"=mob location event, "char"=char specific event
	MI2_EventHandlers = {
		VARIABLES_LOADED = {f=MI2_VariablesLoaded},
		PLAYER_TARGET_CHANGED = {f=MI2.OnTargetChanged, always=1},
		PLAYER_LOGIN = {f=MI2_Player_Login, always=1},
		PLAYER_LOGOUT = {f=MI2_Player_Logout, always=1},
		CHAT_MSG_COMBAT_XP_GAIN = {f=MI2.EventCreatureDiesXP, basic=1},
		ZONE_CHANGED_NEW_AREA = {f=MI2_EventZoneChanged, basic=1},
		ZONE_CHANGED_INDOORS = {f=MI2_EventZoneChanged, basic=1},
		CHAT_MSG_MONSTER_EMOTE = {f=MI2_EventMonsterEmote, basic=1},
		LOOT_READY = {f=MI2_EventLootReady, basic=1, items=1},
		LOOT_CLOSED = {f=MI2_EventLootClosed, basic=1, items=1},

		ITEM_LOCKED = {f=MI2.ItemLocked, basic=1, items=1},
		ITEM_UNLOCKED = {f=MI2.ItemUnlocked, basic=1, items=1},

		UNIT_SPELLCAST_START ={f=MI2_EventSpellStart, char=1},
		UNIT_SPELLCAST_CHANNEL_START ={f=MI2_EventSpellStart, char=1},
		UNIT_SPELLCAST_SUCCEEDED ={f=MI2_EventSpellSucceeded, char=1},
		PLAYER_REGEN_ENABLED = {f=MI2_OnPlayerRegenEnabled, always=1}
	}

	-- COMBAT_LOG_EVENT_UNFILTERED handles damage/kill tracking for older
	-- versions, but it does not provide a live unit token for caching the
	-- mob's name/level. UNIT_COMBAT and UNIT_THREAT_LIST_UPDATE are still
	-- useful here because they let us seed the cache for later loot handling.
	-- Modern clients, including Retail and Forever, use the newer UNIT_DIED
	-- path while still using the same
	-- threat/combat cache hooks.
	if not MI2.WOW_MODERN then
		MI2_EventHandlers.COMBAT_LOG_EVENT_UNFILTERED = {f=MI2_OnCombatLogEvent, always=1}
		MI2_EventHandlers.UNIT_COMBAT = {f=MI2_EventUnitCombat, always=1}
		MI2_EventHandlers.UNIT_THREAT_LIST_UPDATE = {f=MI2_EventUnitThreatListUpdate, always=1}
	else
		-- Provide alternative for capturing kill count without using
		-- COMBAT_LOG_EVENT_UNFILTERED. It might still capture false
		-- kills that you did not participate in, but that would be a
		-- unique circumstance
		MI2_EventHandlers.PARTY_KILL = {f=MI2_EventPartyKill, always=1}
		MI2_EventHandlers.UNIT_LOOT = {f=MI2_EventUnitLoot, always=1}
		MI2_EventHandlers.UNIT_COMBAT = {f=MI2_EventUnitCombat, always=1}
		MI2_EventHandlers.UNIT_THREAT_LIST_UPDATE = {f=MI2_EventUnitThreatListUpdate, always=1}
		MI2_EventHandlers.UNIT_DIED = {f=MI2_EventUnitDied, always=1}
	end

	MI2_ChatScanStrings = {
		[1] = OPEN_LOCK_SELF,
		[2] = SELFKILLOTHER,
		[3] = COMBATLOG_XPGAIN_FIRSTPERSON,
		[4] = COMBATHITSELFOTHER,
		[5] = COMBATHITCRITSELFOTHER,
		[6] = SPELLLOGSELFOTHER,
		[7] = SPELLLOGSCHOOLSELFOTHER,
		[8] = SPELLLOGCRITSELFOTHER,
		[9] = PERIODICAURADAMAGESELFOTHER,
		[10] = COMBATHITOTHEROTHER,
		[11] = COMBATHITCRITOTHEROTHER,
		[12] = SPELLLOGOTHEROTHER,
		[13] = SPELLLOGCRITOTHEROTHER,
		[14] = IMMUNESPELLSELFOTHER,
		[15] = SPELLIMMUNESELFOTHER,
		[16] = SPELLRESISTSELFOTHER,
		[17] = SPELLLOGCRITSCHOOLSELFOTHER,
		[18] = AURAADDEDOTHERHARMFUL, }

	for idx, scanString in pairs(MI2_ChatScanStrings) do
		scanString = string.gsub(scanString, "%(", "%%%(")
		scanString = string.gsub(scanString, "%)", "%%%)")
		scanString = string.gsub(scanString, "(%%s)", "%(%.%+%)")
		scanString = string.gsub(scanString, "(%%%d$s)", "%(%.%+%)")
		scanString = string.gsub(scanString, "(%%d)", "%(%%%d%+%)")
		scanString = string.gsub(scanString, "(%%%d$d)", "%(%%%d%+%)")
		MI2_ChatScanStrings[idx] = scanString
	end

	-- process no other events until "VARIABLES_LOADED"
	self:RegisterEvent("VARIABLES_LOADED")

	-- prepare for importing external database data
	-- this must be done before "VARIABLES_LOADED" overwrites import data
	MI2.PrepareForImport()
	MI2.DeleteAllMobData()

	-- set some stuff that is needed (only) for improved compatibility
	-- to other AddOns wanting to use MobHealth info
	if  not MobHealth_OnEvent  then
		MobHealthFrame = "MI2"
		MobHealth_OnEvent = MI2_OnEvent
	end
end -- MI2_OnLoad()
