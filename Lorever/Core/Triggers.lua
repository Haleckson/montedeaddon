local _, ns = ...

-- Turns game events into discoveries.
-- Never reads secret values (Midnight rules): a secret GUID or name is skipped.

local T = {}
ns.Triggers = T

local Lore, P, U = ns.Lore, ns.Progress, ns.U
local idx = Lore.index

local function unlockList(list, quiet)
	if not list then return 0 end
	return P.UnlockAll(list, quiet)
end

-- Zones ---------------------------------------------------------------------

local function currentMaps()
	local maps = {}
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local guard = 0
	while mapID and mapID > 0 and guard < 5 do
		maps[#maps + 1] = mapID
		local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
		mapID = info and info.parentMapID
		guard = guard + 1
	end
	return maps
end

-- The region the player stands in (for the "Here" page), or nil.
function T.CurrentRegion()
	for _, mapID in ipairs(currentMaps()) do
		local list = idx.zoneMap[mapID]
		if list and list[1] then return list[1].entry end
	end
	local zone = GetRealZoneText and GetRealZoneText()
	if zone and not U.IsSecret(zone) then
		local list = idx.zoneName[zone]
		if list and list[1] then return list[1].entry end
	end
end

function T.CheckZone(quiet)
	for _, mapID in ipairs(currentMaps()) do unlockList(idx.zoneMap[mapID], quiet) end
	local zone = GetRealZoneText and GetRealZoneText()
	if zone and not U.IsSecret(zone) then unlockList(idx.zoneName[zone], quiet) end
	T.CheckSubzone(quiet)
	ns.Fire("FL_ZONE", T.CurrentRegion())
end

-- Subzone names in the client's own language, from their AreaIDs: [name] = { part, ... }.
local localSubzones
local function localSubzone(name)
	if not localSubzones then
		localSubzones = {}
		if C_Map and C_Map.GetAreaInfo then
			for area, parts in pairs(idx.subzoneArea) do
				local ok, n = pcall(C_Map.GetAreaInfo, area)
				if ok and n and n ~= "" then
					localSubzones[n] = localSubzones[n] or {}
					for _, part in ipairs(parts) do table.insert(localSubzones[n], part) end
				end
			end
		end
	end
	return localSubzones[name]
end

function T.CheckSubzone(quiet)
	local sub = GetSubZoneText and GetSubZoneText()
	if sub and sub ~= "" and not U.IsSecret(sub) then
		-- Some subzone names carry a stray space ("Bloodvenom Post "): match without it too.
		local trimmed = sub:match("^%s*(.-)%s*$")
		unlockList(idx.subzone[sub] or idx.subzone[trimmed] or localSubzone(sub) or localSubzone(trimmed), quiet)
	end
end

ns.On("ZONE_CHANGED_NEW_AREA", function() T.CheckZone() end)
ns.On("ZONE_CHANGED", function() T.CheckSubzone() end)
ns.On("ZONE_CHANGED_INDOORS", function() T.CheckSubzone() end)

-- Called by the map pin provider whenever the world map shows a map.
-- A zone opens only if the player has explored part of it.
function T.OnMapShown(mapID)
	local list = mapID and idx.openMap[mapID]
	if not list then return end
	local explored = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures
		and C_MapExplorationInfo.GetExploredMapTextures(mapID)
	if explored and #explored > 0 then unlockList(list) end
end

-- Figures ---------------------------------------------------------------------

-- In another language, the game shows a figure's name translated. The first time
-- the reader meets the figure, that name becomes the page's title.
function T.NoteName(unit, npcID)
	if Lore.language == "enUS" or not npcID then return end
	local name = UnitName(unit)
	if not name or U.IsSecret(name) or name == "" then return end
	for _, figure in ipairs(Lore.FiguresForNpc(npcID)) do
		if #(figure.npc or {}) == 1 and ns.db.localNames[figure.id] ~= name then
			ns.db.localNames[figure.id] = name
			Lore.SetLocalName(figure.id, name)
		end
	end
end

-- The reader chose to face a figure (the book button, a right-click): its
-- page is discovered, as when speaking with it.
function T.Meet(npcID)
	if not npcID then return end
	unlockList(idx.interact[npcID])
	unlockList(idx.target[npcID])
end

function T.OnInteract()
	local npcID = U.UnitNpcID("npc")
	T.NoteName("npc", npcID)
	if npcID then
		unlockList(idx.interact[npcID])
		unlockList(idx.target[npcID]) -- speaking with someone also counts as facing them
	end
end

for _, event in ipairs({
	"GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE",
	"MERCHANT_SHOW", "TRAINER_SHOW", "TAXIMAP_OPENED", "BANKFRAME_OPENED",
	"PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}) do
	ns.On(event, T.OnInteract)
end

-- Passing the mouse over a figure also counts, when the option is on.
ns.On("UPDATE_MOUSEOVER_UNIT", function()
	if not ns.db.settings.mouseoverDiscovery then return end
	local npcID = U.UnitNpcID("mouseover")
	T.NoteName("mouseover", npcID)
	if npcID then
		unlockList(idx.interact[npcID])
		unlockList(idx.target[npcID])
	end
end)

ns.On("PLAYER_TARGET_CHANGED", function()
	local npcID = U.UnitNpcID("target")
	T.NoteName("target", npcID)
	if npcID then unlockList(idx.target[npcID]) end
end)

-- Quests, bosses, books --------------------------------------------------------

ns.On("QUEST_TURNED_IN", function(_, questID)
	unlockList(idx.quest[questID])
end)

ns.On("ENCOUNTER_END", function(_, encounterID, _, _, _, success)
	if success == 1 or success == true then unlockList(idx.encounter[encounterID]) end
end)

ns.On("ITEM_TEXT_BEGIN", function()
	local title = ItemTextGetItem and ItemTextGetItem()
	if title and not U.IsSecret(title) then unlockList(idx.book[title]) end
end)

-- Login: catch up on what the character already did ----------------------------

function T.CatchUp()
	local gained = 0
	gained = gained + unlockList(idx.always, true)
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
		for questID, list in pairs(idx.quest) do
			if C_QuestLog.IsQuestFlaggedCompleted(questID) then gained = gained + unlockList(list, true) end
		end
	end
	return gained
end

ns.Listen("FL_LOGIN", function()
	local gained = T.CatchUp()
	if gained > 0 then ns.Fire("FL_CAUGHT_UP", gained) end
	-- The zone you log in to counts as a real discovery, with its toast.
	C_Timer.After(3, function() T.CheckZone() end)
end)
