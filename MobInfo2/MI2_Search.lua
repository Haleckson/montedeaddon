--
-- MI2_Search.lua
--
-- MobInfo module to control the Mob database search feature.
-- Search option settings and actual search algorithm are located in here.
--

local _, MI2 = ...

MI2.SlashActions = MI2.SlashActions or {}

local MI2_MaxPlayerLevel = {};
MI2_MaxPlayerLevel[0] = 60;
MI2_MaxPlayerLevel[1] = 70;
MI2_MaxPlayerLevel[2] = 80;
MI2_MaxPlayerLevel[3] = 85;
MI2_MaxPlayerLevel[4] = 90;
MI2_MaxPlayerLevel[5] = 100;
MI2_MaxPlayerLevel[6] = 110;
MI2_MaxPlayerLevel[7] = 120;
MI2_MaxPlayerLevel[8] = 60
MI2_MaxPlayerLevel[9] = 70
MI2_MaxPlayerLevel[10] = 80
MI2_MaxPlayerLevel[11] = 90

--
-- start up defaults for search options settings
local MI2_SearchOptions = {}
MI2_SearchOptions.MinLevel = 1
MI2_SearchOptions.MaxLevel = MI2_MaxPlayerLevel[GetExpansionLevel()]
MI2_SearchOptions.Normal = true
MI2_SearchOptions.Elite = false
MI2_SearchOptions.Boss = false
MI2_SearchOptions.Rare = false
MI2_SearchOptions.RareElite = false
MI2_SearchOptions.MinLoots = 0
MI2_SearchOptions.MaxLoots = 9999
MI2_SearchOptions.MobName = ""
MI2_SearchOptions.ItemName = ""
MI2_SearchOptions.CompactResult = 1
MI2_SearchOptions.ListMode = "Mobs"
MI2_SearchOptions.SortMode = "profit"

local MI2_SearchResultList = {}
local MI2_SearchList = {}
local MI2_ItemsIdxList = {}
local MI2_SearchMode = 0
local MI2_SearchCount = 0
MI2.NumMobsFound = 0

-----------------------------------------------------------------------------
-- MI2_DisplaySearchResult()
--
-- Display the result of a search in the search results scrollable list.
-- The mobs to be displayed depend on the current list scroll position.
--
local function MI2_DisplaySearchResult( resultType )
	-- update slider and get slider position
	FauxScrollFrame_Update( MI2_SearchResultSlider, MI2.NumMobsFound, 15, 14 );
	local sliderPos = FauxScrollFrame_GetOffset(MI2_SearchResultSlider)

	if resultType then
		MI2_TxtSearchCount:SetText( MI2.SubWhite.."("..MI2.NumMobsFound.." "..resultType..")" )
	end

	-- update 15 search result lines with correct search result data
	local resultLine
	for i = 1, 15 do
		if 	(i + sliderPos) <= MI2.NumMobsFound then
			resultLine = _G[ "MI2_SearchResult"..i.."Index" ]
			resultLine:SetText( i + sliderPos )
			resultLine = _G[ "MI2_SearchResult"..i.."Value" ]
			resultLine:SetText( MI2_SearchResultList[i + sliderPos].val )
			resultLine = _G[ "MI2_SearchResult"..i.."Name" ]
			local mobName = MI2_SearchResultList[i + sliderPos].idx
			local mobType = MI2_SearchResultList[i + sliderPos].type
			if mobType then
				if mobType == 2 then                                                                   
					mobName = mobName.."!"     -- rare
				elseif mobType == 3 then
					mobName = mobName.."++"    -- BOSS
				elseif mobType == 4 then                                                                   
					mobName = mobName.."+"     -- Elite
				elseif mobType == 6 then                                                                   
					mobName = mobName.."+!"    -- rare Elite
				end
			elseif MI2_SearchResultList[i + sliderPos].col then
				mobName = MI2_SearchResultList[i + sliderPos].col..mobName
			end
			resultLine:SetText( mobName )
		else
			resultLine = _G[ "MI2_SearchResult"..i.."Index" ]
			resultLine:SetText( "" )
			resultLine = _G[ "MI2_SearchResult"..i.."Value" ]
			resultLine:SetText( "" )
			resultLine = _G[ "MI2_SearchResult"..i.."Name" ]
			resultLine:SetText( "" )
		end
	end
end  -- MI2_DisplaySearchResult()

-----------------------------------------------------------------------------
-- MI2_SearchForItems()
--
-- Search for all items matching the item name entered in the search dialog.
-- Display the list of items in the result list control (if requested).
--
local function MI2_SearchForItems( searchString, enterItemsIntoList )
	MI2_ItemsIdxList = {}
	MI2.NumMobsFound = 0
	if enterItemsIntoList then
		MI2_SearchResultList = {}
	end

	local function process(id)
		local itemFound = true
		local itemName, itemText, itemColor = MI2.GetLootItem( id )
		if searchString ~= "*" then
			itemFound = string.find( string.lower(itemName), searchString ) ~= nil
		end
		if itemFound then
			if enterItemsIntoList then
				MI2.NumMobsFound = MI2.NumMobsFound + 1
				MI2_SearchResultList[MI2.NumMobsFound] = { idx = itemText, val = "", col = itemColor, ID = id }
			end
			MI2_ItemsIdxList[id] = 1
		end
	end

	if searchString ~= "" or enterItemsIntoList then
		searchString = string.lower(searchString)
		MI2_ItemsIdxList[-1] = 1
		for id in pairs(MI2_ItemNameTable[MI2.Locale]) do
			process(id)
		end
		for id in pairs(MI2_ItemNameTable) do
			if MI2_ItemsIdxList[id] == nil and type(id) == "number" then
				process(id)
			end
		end

	end

	MI2_DisplaySearchResult( "Items" )
end -- MI2_SearchForItems()

-----------------------------------------------------------------------------
-- Check a given Mob against the current search criteria. Return the
-- mob data if the mob matches the criteria, or return nil if the Mob
-- does not match.
--
local function MI2_CheckMob( mobName, mobLevel )
	local levelOk, lootsOk, typeOk, itemsOK, mobData
	local nameOk = true

	-- check name and level of Mob
	if MI2_SearchOptions.MobName ~= "" then
		nameOk = string.find(string.lower(mobName),string.lower(MI2_SearchOptions.MobName),1,true) ~= nil
	end

	if nameOk and mobName ~= ""	then
		levelOk = mobLevel >= MI2_SearchOptions.MinLevel and mobLevel <= MI2_SearchOptions.MaxLevel
		levelOk = levelOk or (mobLevel == -1) or (mobLevel == -2)
	end

	-- check mob data related search conditions	
	if levelOk then
		mobData = MI2_GetMobData(mobName, mobLevel, nil, false)
		if mobData then
			lootsOk = ((mobData.loots or 0)>= MI2_SearchOptions.MinLoots) and ((mobData.loots or 0)<= MI2_SearchOptions.MaxLoots)
			-- secret-level mobs bypass the type filter (same as the level filter bypass above)
			typeOk = (mobLevel == -2)
				or (MI2_SearchOptions.Normal and (mobData.mobType == 1 or mobData.mobType == 0 or not mobData.mobType))
				or (MI2_SearchOptions.Elite     and mobData.mobType == 4)
				or (MI2_SearchOptions.Boss      and mobData.mobType == 3)
				or (MI2_SearchOptions.Rare      and mobData.mobType == 2)
				or (MI2_SearchOptions.RareElite and mobData.mobType == 6)
		end
		if lootsOk and typeOk then
			if MI2_ItemsIdxList[-1] and mobData.itemList then
				for idx, val in pairs(mobData.itemList) do
					itemsOK = MI2_ItemsIdxList[idx] ~= nil
					if itemsOK then break end
				end
				if not itemsOK then mobData = nil end
			end
		else
			mobData = nil
		end
	end

	return mobData
end

-----------------------------------------------------------------------------
-- MI2_CalculateRank()
--
-- Calculate ranking and corresponding actual value for a given mob.
-- Ranking depends on search mode. For search mode "profit" ranking is
-- based on the mobs total profit value plus bonus points for rare loot
-- items. For search mode "itemCount" ranking is identical to the overall
-- items count for the loot items being searched for (in this mode
-- rank and value are identical).
--
local function MI2_CalculateRank( mobData, mobLevel, sortMode )
	local rank, value, valueString = 0, 0, ""

	if sortMode == "profit" then
		-- calculate rank based on mob level and loot items quality
		local bonusFactor = max(mobLevel, 1) / 20

		if (mobData.loots or 0) > 0 then
			value = (mobData.copper or 0) + (mobData.itemValue or 0)
			rank = value + ((mobData.r3 or 0) * 200 * bonusFactor) + ((mobData.r4 or 0) * 1000 * bonusFactor) + ((mobData.r5 or 0) * 2000 * bonusFactor)
			rank = ceil( rank / mobData.loots )
			valueString = GetMoneyString( ceil(value / mobData.loots) )
		end
	elseif sortMode == "item" and mobData.itemList then
		for idx, val in pairs(mobData.itemList) do
			local itemFound = MI2_ItemsIdxList[idx] ~= nil
			if itemFound then  rank = rank + val  end
			rank = rank + val
		end
		valueString = rank.."  "
	end

	return rank, valueString
end -- MI2_CalculateRank()

-----------------------------------------------------------------------------
-- MI2_SearchForMobs()
--
-- Search through a limited number of Mobs. Think function is meant to be
-- called repeatedly (in the background) to incrementally build the overall
-- search result list.
--
local function MI2_SearchForMobs( searchLimit )
	local searchCount = 0
	for mobIndex, mobInfo in next, MI2_SearchList do
		local mobName = mobInfo[1]
		local mobLevel = mobInfo[2]
		MI2_SearchList[mobIndex] = nil

		searchCount = searchCount + 1
		MI2_SearchCount = MI2_SearchCount + 1

		local mobData = MI2_CheckMob( mobName, mobLevel )

		-- if mob is identified as belonging into the search result its
		-- search result sorting position is calculated based on a ranking
		-- value which in turn is based on the search mode
		if mobData then
			local rank, value = MI2_CalculateRank( mobData, mobLevel, MI2_SearchOptions.SortMode )
			MI2.NumMobsFound = MI2.NumMobsFound + 1
			-- insert mob at correct sorted position and store all info we need for printing the result list
			MI2_SearchResultList[MI2.NumMobsFound] = { idx=mobIndex, val=value, rank=rank, id = mobName, level = mobLevel }
			if mobData.mobType and mobData.mobType > 1 then
				MI2_SearchResultList[MI2.NumMobsFound].type = mobData.mobType
			end
		end

		if searchCount > searchLimit then
			return false
		end
	end
	return true
end -- MI2_SearchForMobs()


-----------------------------------------------------------------------------
-- MI2_UpdateSearchResultList()
--
-- Update contents of search result list according to current search options
-- settings. This includes starting a new search run, sorting the result and
-- displaying the result in the scrollable result list.
--
local function MI2_UpdateSearchResultList( updateItems )
	if updateItems then
		local enterItemsIntoList = MI2_SearchOptions.ListMode == "Items"
		MI2_SearchForItems( MI2_SearchOptions.ItemName, enterItemsIntoList )
	end
	if MI2_SearchOptions.ListMode == "Mobs" then
		-- (re)start search for entire mob database
		MI2_SearchCount = 0
		MI2_SearchMode = 1

		MI2_SearchList = {}
		for k,v in next, MI2.Database.db.source do
			local n = k
			if type(k) ~= "string" then
				n = MI2.GetNameForId(k)
			end
			if n then
				for l in next, v do
					if type(l) == "number" then
						local label = l == -2 and (n..":SECRET") or (n..":"..l)
						MI2_SearchList[label] = {n,l}
					end
				end
			end
		end

		-- initialise search result list  
		MI2_SearchResultList = {}
		MI2.NumMobsFound = 0

		-- search first 500 database records right away
		MI2_SearchForMobs( 500 )
	end

	MI2_DisplaySearchResult( MI2_SearchOptions.ListMode )
end -- MI2_UpdateSearchResultList()


-----------------------------------------------------------------------------
-- MI2_SearchOptionsOnShow()
--
-- OnShow event handler for search options page
-- Write current search option settings into the search option controls.
-- Validate all values and update colors accordingly.
-- Allow Search only if all search options are valid.
--
function MI2_SearchOptionsOnShow()
	MI2_OptSearchMinLoots:SetMaxLetters( 4 )
	MI2_OptSearchMaxLoots:SetMaxLetters( 4 )
	MI2_OptSearchMinLoots:SetWidth( 36 )
	MI2_OptSearchMaxLoots:SetWidth( 36 )
	MI2_OptSearchMinLevel:SetText( tostring(MI2_SearchOptions.MinLevel) )
	MI2_OptSearchMaxLevel:SetText( tostring(MI2_SearchOptions.MaxLevel) )
	MI2_OptSearchMinLoots:SetText( tostring(MI2_SearchOptions.MinLoots) )
	MI2_OptSearchMaxLoots:SetText( tostring(MI2_SearchOptions.MaxLoots) )
	MI2_OptSearchMobName:SetText( MI2_SearchOptions.MobName )
	MI2_OptSearchItemName:SetText( MI2_SearchOptions.ItemName )

	if not MI2_SearchOptions.Normal then
		MI2_OptSearchNormal:SetChecked( false )
	else
		MI2_OptSearchNormal:SetChecked( true )
	end
	if not MI2_SearchOptions.Elite then
		MI2_OptSearchElite:SetChecked( false )
	else
		MI2_OptSearchElite:SetChecked( true )
	end
	if not MI2_SearchOptions.Boss then
		MI2_OptSearchBoss:SetChecked( false )
	else
		MI2_OptSearchBoss:SetChecked( true )
	end
	if not MI2_SearchOptions.Rare then
		MI2_OptSearchRare:SetChecked( false )
	else
		MI2_OptSearchRare:SetChecked( true )
	end
	if not MI2_SearchOptions.RareElite then
		MI2_OptSearchRareElite:SetChecked( false )
	else
		MI2_OptSearchRareElite:SetChecked( true )
	end

	MI2_UpdateSearchResultList()
end -- MI2_SearchOptionsOnShow()


-----------------------------------------------------------------------------
-- MI2_ValidateSearchOptions()
--
-- Validate all values and update colors accordingly.
-- Allow Search only if all search options are valid.
--
local function MI2_ValidateSearchOptions(self)
	if MI2_SearchOptions.MinLevel < 1 then
		MI2_SearchOptions.MinLevel = 1
		if self:GetText() == "0" then
			self:SetText( "1" )
		end
	end
	if MI2_SearchOptions.MaxLevel < 1 then
		MI2_SearchOptions.MaxLevel = 1
		if self:GetText() == "0" then
			self:SetText( "1" )
		end
	end
end -- MI2_ValidateSearchOptions()


-----------------------------------------------------------------------------
-- MI2_SearchCheckboxClicked()
--
-- OnClicked event handler for checkboxes on search options page
-- Store the checkbox state in the corresponding search options variable.
--
function MI2_SearchCheckboxClicked(self)
	local checkboxName = self:GetName()
	local optionName = string.sub( checkboxName, 14 )
	local optionValue = self:GetChecked() or false

	MI2_SearchOptions[optionName] = optionValue
	MI2_UpdateSearchResultList()
end -- MI2_SearchCheckboxClicked()


-----------------------------------------------------------------------------
-- MI2_SearchValueChanged()
--
-- OnChar event handler for editbox controls on search options page
-- This handler is called whenever the contents of an EditBox control changes.
-- It gets the new value and stores it in the corresponding search options
-- variable
--
function MI2_SearchValueChanged(self)
	local editboxName = self:GetName()
	local optionName = string.sub( editboxName, 14 )
	local optionValue = tonumber(self:GetText()) or 0

	if MI2_SearchOptions[optionName] ~= optionValue then
		MI2_SearchOptions[optionName] = optionValue
		MI2_ValidateSearchOptions(self)
		MI2_UpdateSearchResultList()
	end
end -- MI2_SearchValueChanged()


-----------------------------------------------------------------------------
-- MI2_SearchTextChanged()
--
-- OnChar event handler for textual editbox controls on search options page
-- This handler is called whenever the contents of an EditBox control changes.
-- It gets the new value and stores it in the corresponding search options
-- variable
--
function MI2_SearchTextChanged(self)
	local editboxName = self:GetName()
	local optionName = string.sub( editboxName, 14 )

	if MI2_SearchOptions[optionName] ~= self:GetText() then
		MI2_SearchOptions[optionName] = self:GetText()
		MI2_UpdateSearchResultList( true )
	end
end -- MI2_SearchTextChanged()

-----------------------------------------------------------------------------
-- MI2.SlashActions.SortByValue()
--
-- Sort the search result list by mob profit
--
function MI2.SlashActions.SortByValue()
	MI2_SearchOptions.SortMode = "profit"
	MI2_UpdateSearchResultList()
end -- end of MI2_SlashAction_SortByValue()


-----------------------------------------------------------------------------
-- MI2.SlashActions.SortByItem()
--
-- Sort the search result list by mob item count
--
function MI2.SlashActions.SortByItem()
	MI2_SearchOptions.SortMode = "item"
	MI2_UpdateSearchResultList()
end -- end of MI2_SlashAction_SortByItem()


-----------------------------------------------------------------------------
-- MI2_SearchResult_Update()
--
-- Update contents of search results list based on current scroll bar
-- position. Update tooltip for selected mob if tooltip is visible.
--
function MI2_SearchResult_Update()
	FauxScrollFrame_Update( MI2_SearchResultSlider, MI2.NumMobsFound, 15, 14 );
	MI2_DisplaySearchResult()
end -- end of MI2_SearchResult_Update()

function MI2_SearchWayPoint(self)
	local sliderPos = FauxScrollFrame_GetOffset(MI2_SearchResultSlider)
	local selection = tonumber(string.sub(self:GetName(), 17)) + sliderPos
	if selection <= MI2.NumMobsFound then
		if MI2_SearchOptions.ListMode == "Mobs" then
			local info = MI2_SearchResultList[selection]
			if info then
				local mobData = MI2_GetMobData(info.id, info.level)

				if TomTom and mobData and mobData.location then
					TomTom:AddWaypoint(mobData.location.m, (mobData.location.x1+mobData.location.x2)/200, (mobData.location.y1+mobData.location.y2)/200,
					{
						title = info.id,
						from = "MobInfo2",
						persistent = false,
						minimap = true,
						world = true
					})
				end
			end
		end
	end
end

-----------------------------------------------------------------------------
-- MI2_ShowSearchResultTooltip()
--
-- Show mob tooltip for search result mob currently under mouse cursor.
--
function MI2_ShowSearchResultTooltip(self)
	local sliderPos = FauxScrollFrame_GetOffset(MI2_SearchResultSlider)
	local selection = tonumber(string.sub(self:GetName(), 17)) + sliderPos

	if selection <= MI2.NumMobsFound then
		if MI2_SearchOptions.ListMode == "Mobs" then
			local mob = MI2_SearchResultList[selection]
			-- create Mob data tooltip with full location info
			MI2.CreateTooltip( mob.id, mob.level, nil, true, false )
		elseif MI2_SearchOptions.ListMode == "Items" then
			local item = Item:CreateFromItemID(MI2_SearchResultList[selection].ID )
			if item:IsItemEmpty() then return 0	end

			item:ContinueOnItemLoad(function()
			  GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
			  local itemName = MI2_SearchResultList[selection].idx
			  GameTooltip:SetText( MI2_SearchResultList[selection].col..itemName )
			  MI2.BuildItemDataTooltip( GameTooltip, MI2_SearchResultList[selection].ID )
			  GameTooltip:Show()
			end)
		end
	end
end  -- end of MI2_ShowSearchResultTooltip()


-----------------------------------------------------------------------------
-- MI2_HideSearchResultTooltip()
--
function MI2_HideSearchResultTooltip()
	MI2.HideTooltip()
end -- MI2_HideSearchResultTooltip()


-----------------------------------------------------------------------------
-- MI2_SearchTab_OnClick()
--
-- The "OnClick" event handler for the TAB buttons on the search result list.
-- These TAB buttons switch the list content between two modes: mob list
-- and item list
--
function MI2_SearchTab_OnClick(self)
	PanelTemplates_Tab_OnClick( self, MI2_SearchResultFrame )
	local selected = MI2_SearchResultFrame.selectedTab
	if selected == 1 then
		MI2_OptSortByValue:Enable()
		MI2_OptSortByItem:Enable()
		if MI2.NumMobsFound > 0 then
			MI2_OptDeleteSearch:Enable()
		else
			MI2_OptDeleteSearch:Disable()
		end
		MI2_SearchOptions.ListMode = "Mobs"
		MI2_UpdateSearchResultList( true )
	elseif selected == 2 then
		MI2_OptSortByValue:Disable()
		MI2_OptSortByItem:Disable()
		MI2_OptDeleteSearch:Disable()
		MI2_SearchOptions.ListMode = "Items"
		MI2_UpdateSearchResultList( true )
	end
end -- MI2_SearchTab_OnClick()

-----------------------------------------------------------------------------
-- MI2_SearchOnUpdate()
--
-- OnUpdate is called periodically (about 45 times per second) by the WoW
-- client.
--
function MI2_SearchOnUpdate( time )
	if MI2_SearchMode == 1 then
		local finished = MI2_SearchForMobs( 750 )
		if ( finished ) then
			MI2_SearchMode = 0
			if MI2.NumMobsFound > 1 then
				table.sort( MI2_SearchResultList, function(a,b) return (a.rank > b.rank) end  )
			end
			MI2_DisplaySearchResult( MI2_SearchOptions.ListMode )
		else
			MI2_TxtSearchCount:SetText( MI2.SubWhite.."(searching..."..MI2_SearchCount..")" )
		end
	end
end

-----------------------------------------------------------------------------
-- MI2.DeleteSearchResultMobs()
--
-- Delete all Mobs in the search result list from the MobInfo database.
-- This function is called when the user confirms the delete.
--
function MI2.DeleteSearchResultMobs()
	for _, val in pairs(MI2_SearchResultList) do
		MI2.DeleteMobData( val.id, val.level )
	end
	MI2.chattext( "search result deleted : "..MI2.NumMobsFound.." Mobs" )
	MI2_UpdateSearchResultList()
end -- MI2.DeleteSearchResultMobs()
