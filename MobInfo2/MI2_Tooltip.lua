--
-- MI2_Tooltip.lua
--
-- Tooltip handling functions for the MobInfo AddOn.
--

local _, MI2 = ...
local MI2_White               = MI2.White
local MI2_LightRed            = MI2.LightRed
local MI2_GetUnitBasedMobData = MI2.GetUnitBasedMobData
local MI2_GetNameForId        = MI2.GetNameForId
local MI2_CacheMobInfo        = MI2.CacheMobInfo
local MI2_BuildTooltipMob     = MI2.BuildTooltipMob
local MI2_Unit                = MI2.Unit
local MI2_HideTooltip, MI2_IsUnitClose -- forward declaration
local MI2_FontHeight, MI2_MaxTextWidth, MI2_MaxValWidth, MI2_OffsetX, MI2_OffsetY, MI2_Anchor
local MI2_TooltipOptions = {}
local MI2_MaxNumExtraItems = 10
local MI2_MaxNumLines = 30
local MI2_MaxNumItems = 20
local MI2_IsMoving = 0
local MI2_HideTimer, MI2_Tick, MI2_Skip = 0, 0, 0
local MI2_GameTooltipNumLinesOriginal = 0
local MI2_GameTooltipInfoAvailable = false

local MI2_ListItems = {}

local MI2_GameTooltipCleared
local MI2_GameTooltipSetUnit
local MI2_GameTooltipOnUpdate

-----------------------------------------------------------------------------
-- MI2.InitializeTooltip()
--
-- One time initialization of tooltip, will be called from event "VARIABLES_LOADED"
--
function MI2.InitializeTooltip()
	MI2_TooltipFrame:SetBackdrop( { bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
									edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
									tile = true, tileSize = 24, edgeSize = 12, 
									insets = { left=4, right=4, top=4, bottom=4 } } )
	MI2_TooltipFrame:SetBackdropColor( 0, 0, 0, 0.8 )
	MI2_TooltipFrame:SetBackdropBorderColor( 0.5, 0, 0, 1 )

	MI2_TooltipFrame:SetClampedToScreen( true )

	-- Add GetLeftLine stub for PTR feedback compatibility
	MI2_TooltipFrame.GetLeftLine = function(self, index)
		return nil
	end

	for idx=1,MI2_MaxNumLines do
		local text = _G["MI2TT_Text"..idx]
		local val = _G["MI2TT_Val"..idx]
		text.val = val
	end
	MI2_UpdateAnchor()
	if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, MI2_GameTooltipSetUnit)
		for idx=1, MI2_MaxNumExtraItems do
			local left = "MI2TT_ClassInfo"
			if idx >1 then
				left = MI2_ListItems[idx-1]
			end

			local fS = MI2_TooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontDarkGraySmall")
			fS:SetPoint("TOPLEFT", left, "BOTTOMLEFT", 0,0)
			fS:SetText(" "..QUEST_DASH)
			fS:Hide()
			_G["MI2TT_ExtraInfo"..idx]:SetPoint("TOPLEFT", fS, "TOPRIGHT", -2, 0)

			table.insert(MI2_ListItems,fS)
		end
	else
		GameTooltip:HookScript("OnTooltipSetUnit", MI2_GameTooltipSetUnit)
	end
	GameTooltip:HookScript("OnUpdate", MI2_GameTooltipOnUpdate)
	GameTooltip:HookScript("OnTooltipCleared", MI2_GameTooltipCleared)

	-- override AddLine to do nothing to avoid errors from other addons
	function MI2_TooltipFrame:AddLine(text, r, g, b, wrap)
	end
end


-----------------------------------------------------------------------------
-- MI2_UpdateAnchor()
--
-- Update visibility of tooltip anchor based on whether optiosn window is
-- open and how the show anchor flag is set.
--
function MI2_UpdateAnchor()
	local showAnchor = MI2_OptionsFrame ~= nil and MI2_OptionsFrame:IsVisible() == 1 or (MobInfoConfig.HideAnchor == 0 and MobInfoConfig.UseGameTT == 0) 
	if showAnchor then
		MI2_TooltipAnchor:Show()
	else
		MI2_TooltipAnchor:Hide()
	end

	-- set tooltip anchoring position
	MI2_TooltipFrame:ClearAllPoints()
	if MobInfoConfig.TooltipMode == 1 then
		MI2_TooltipFrame:SetPoint( "BOTTOMLEFT", MI2_TooltipAnchor, "TOPLEFT" )
	elseif MobInfoConfig.TooltipMode == 2 then
		MI2_TooltipFrame:SetPoint( "TOPLEFT", MI2_TooltipAnchor, "BOTTOMLEFT" )
	elseif MobInfoConfig.TooltipMode == 3 then
		MI2_TooltipFrame:SetPoint( "BOTTOMRIGHT", MI2_TooltipAnchor, "TOPRIGHT" )
	elseif MobInfoConfig.TooltipMode == 5 then
		MI2_TooltipFrame:SetPoint( "BOTTOM", MI2_TooltipAnchor, "TOP" )
	elseif MobInfoConfig.TooltipMode == 6 then
		MI2_TooltipFrame:SetPoint( "TOP", MI2_TooltipAnchor, "BOTTOM" )
	else
		MI2_TooltipFrame:SetPoint( "TOPRIGHT", MI2_TooltipAnchor, "BOTTOMRIGHT" )
	end
end -- MI2_UpdateAnchor


-----------------------------------------------------------------------------
-- MI2_TooltipAnchorOnEnter()
--
function MI2_TooltipAnchorOnEnter()
	if MI2_MouseoverIndex and MobInfoConfig.UseGameTT == 0 then
		MI2_IsMoving = 0
		MI2_HideTimer = 9
		MI2_UpdateAnchor()
		MI2_TooltipFrame:SetAlpha(1)
		MI2_TooltipFrame:Show()
	end
end -- MI2_TooltipAnchorOnEnter


-----------------------------------------------------------------------------
-- MI2_TooltipAnchorOnLeave()
--
function MI2_TooltipAnchorOnLeave()
	MI2_HideTimer = 1.4
	local a,_,_,x,y = MI2_TooltipAnchor:GetPoint()
	MobInfoConfig.MIAnchor = {a,x,y}
end -- MI2_TooltipAnchorOnLeave


-----------------------------------------------------------------------------
-- MI2.SetupTooltip()
--
-- Basic setup of tooltip after changing a tooltip configuration option.
--
function MI2.SetupTooltip()
	MI2_TooltipFrame:Hide()
	MI2_MouseoverIndex = nil

	-- initialise the extra tooltip entries
	MI2_OptShowDps:SetChecked( MI2_OptShowDamage:GetChecked() )
	MI2_OptShowImmuns:SetChecked( MI2_OptShowResists:GetChecked() )

	-- build list of tooltip options to be displayed in the tooltip	
	MI2_TooltipOptions = {}
	local children = { MI2_FrmTooltipContent:GetChildren() }
	for idx, child in pairs(children) do
	    local opt = MI2_OPTIONS[child:GetName()]
		if child.GetChecked and child:GetChecked() and opt.data then
			table.insert( MI2_TooltipOptions, opt )
		end
	end

	-- set tooltip font size
	local ttfont = GameFontNormal
	if MobInfoConfig.SmallFont == 1 then
		ttfont = GameFontNormalSmall
	end
	for idx=1,MI2_MaxNumLines do
		_G["MI2TT_Text"..idx]:SetFontObject(ttfont)
		_G["MI2TT_Val"..idx]:SetFontObject(ttfont)
	end
	for idx=1,MI2_MaxNumItems do
		_G["MI2TT_Item"..idx]:SetFontObject(ttfont)
	end

	-- calculate font height and columns width limitations based on font
	local _, fontHeight = MI2TT_Text1:GetFont()
	MI2_FontHeight = fontHeight
	MI2TT_Text1:SetText( "AAAAAA" )
	MI2_MaxTextWidth = MI2TT_Text1:GetWidth()
	MI2_MaxValWidth = MI2_MaxTextWidth * 1.3

	if TipTac_Config then
		TipTac_Config.showTip = (MobInfoConfig.OtherTooltip == 0)
	end
end -- MI2.SetupTooltip


-----------------------------------------------------------------------------
-- MI2_StartTooltipMouseMove()
--
-- Initiate moving the mobinfo tooltip together with mouse movement. The
-- trick it to set the anchor correctly so that when "StartMoving()" is
-- called in "OnUpdate()" the tooltip is at exactly the right position.
--
local function MI2_StartTooltipMouseMove()
	MI2_TooltipFrame:ClearAllPoints()
	if MobInfoConfig.TooltipMode == 1 then
		MI2_Anchor = "BOTTOMLEFT"
		MI2_OffsetX, MI2_OffsetY = 10, 5
	elseif MobInfoConfig.TooltipMode == 2 then
		MI2_Anchor = "TOPLEFT"
		MI2_OffsetX, MI2_OffsetY = 20, -15
	elseif MobInfoConfig.TooltipMode == 3 then
		MI2_Anchor = "BOTTOMRIGHT"
		MI2_OffsetX, MI2_OffsetY = -10, 5
	elseif MobInfoConfig.TooltipMode == 4 then
		MI2_Anchor = "TOPRIGHT"
		MI2_OffsetX, MI2_OffsetY = -5, -15
	elseif MobInfoConfig.TooltipMode == 5 then
		MI2_Anchor = "BOTTOM"
		MI2_OffsetX, MI2_OffsetY = 5, 20
	elseif MobInfoConfig.TooltipMode == 6 then
		MI2_Anchor = "TOP"
		MI2_OffsetX, MI2_OffsetY = 5, -25
	end
	MI2_IsMoving = 1
end -- MI2_StartTooltipMouseMove


-----------------------------------------------------------------------------
-- MI2_MouseMove()
--
-- set position of MobInfo tooltip based on mouse position
--
local function MI2_MouseMove()
	-- calculate position and take into account UI scaling
	local scale = UIParent:GetEffectiveScale()
	local x,y = GetCursorPosition()
	x = (x + MI2_OffsetX) / scale
	y = (y + MI2_OffsetY) / scale
--MI2.midebug("ox="..MI2_OffsetX..", oy="..MI2_OffsetY..", a="..MI2_Anchor..", s="..scale)
	MI2_TooltipFrame:SetPoint( MI2_Anchor, UIParent, "BOTTOMLEFT", x, y )
end -- MI2_MouseMove

-----------------------------------------------------------------------------
-- MI2_UpdateTooltipHealth()
--
-- update health/mana shown within MobInfo tooltip while tooltip is shown
-- for the "mouseover" unit
--
local function MI2_UpdateTooltipHealth()
	if not UnitExists("mouseover") then return end
	local mobData = {}
	MI2_GetUnitBasedMobData( mobData, "mouseover" )

	if MI2TT_Text1:GetText() == MI_TXT_HEALTH then
		MI2TT_Text1.val:SetText(mobData.healthText)
	end
	if MI2TT_Text2:GetText() == MI_TXT_MANA then
		MI2TT_Text2.val:SetText(mobData.manaText)
	end

end -- MI2_UpdateTooltipHealth


-----------------------------------------------------------------------------
-- MI2_TooltipOnUpdate()
--
-- OnUpdate is called periodically (about 20 times per second) by the WoW
-- client. This handler starts and stope moving the tooltip along with the
-- mouse, and also handles tooltip fadeout.
--
function MI2_TooltipOnUpdate( self, time )
	-- half second action ticker : use it to update health/mana in tooltip
	MI2_Tick = MI2_Tick + time
	if MI2_Tick > 0.5 then
		MI2_Tick = 0
		MI2_UpdateTooltipHealth()
		if MI2_IsMoving == 2 then
			MI2_HideTooltip()
		end
	end

	if MI2_IsMoving > 0 then
		MI2_MouseMove()
		if MI2_IsMoving == 1 and not UnitExists("mouseover") then
			MI2_Tick = 0.35
			MI2_IsMoving = 2
		end
	elseif  MI2_HideTimer < 4.0 then
		MI2_HideTimer = MI2_HideTimer - time
		if  MI2_HideTimer < 1.0 then
			MI2_TooltipFrame:SetAlpha( math.max(0,MI2_HideTimer) )
			if MI2_HideTimer < 0.1 then
				MI2_HideTooltip()
			end
		end
	elseif not UnitExists("mouseover") and MI2_HideTimer < 6.0 then
		MI2_HideTimer = 1.4
	end
end -- MI2_TooltipOnUpdate


-----------------------------------------------------------------------------
-- MI2_TooltipMouseoverUnit()
--
function MI2_TooltipMouseoverUnit()
	if MobInfoConfig.UseGameTT == 1 then return end

	if MobInfoConfig.ShowMobInfo == 0 then return  end
	if MobInfoConfig.KeypressMode == 1 and not IsAltKeyDown() then return end
	if UnitIsPlayer("mouseover") then return end
	local unitIsPet = UnitIsUnit("mouseover","pet")
	if (not issecretvalue or not issecretvalue(unitIsPet)) and unitIsPet then return end
	if MobInfoConfig.ShowWhileInCombat == 0 and UnitAffectingCombat("player") then
		return
	end

	local unitType, unitId, unitName, unitLevel, unitGuid = MI2_Unit("mouseover")
	if unitType == "Pet" then return end

	local isMob = not(UnitIsPlayer("mouseover") or UnitIsFriend("player","mouseover") or not UnitCanAttack("player","mouseover"))
	if MI2_GameTooltipNumLinesOriginal == 0 then
		MI2_GameTooltipNumLinesOriginal = GameTooltip:NumLines()
	end
	if MI2_GameTooltipNumLinesOriginal > 0 then
		MI2.CreateTooltip( unitId, unitLevel, "mouseover", isMob, (UnitIsWildBattlePet and UnitIsWildBattlePet("mouseover")) or ( UnitIsBattlePetCompanion and UnitIsBattlePetCompanion("mouseover") ) )
		MI2_HideTimer = 5
	end
end


-----------------------------------------------------------------------------
-- MI2_EntryToString()
--
-- return the correct textual representation for a mob data item
-- conversions are performed depending on the type code of the data item
--
local function MI2_EntryToString( type, data, mobData, unit )
	local value = mobData[data]
	if type == 1 and value then
		return GetMoneyString( value )
	elseif type == 2 and (mobData.minDamage or mobData.maxDamage) then
		return (mobData.minDamage or 0).."-"..(mobData.maxDamage or 0)
	elseif type == 3 and mobData.location then
		local loc = mobData.location
		local z
		if loc.m then
			local mi = C_Map.GetMapInfo(loc.m)
			if mi and mi.name then
				z = mi.name
			end
		end
		if not z and loc.z then z = MI2_ZoneTable[loc.z] end

		if unit or loc.x1 == nil or loc.x2 == nil or loc.y1 == nil or loc.y2 == nil then
			return z
		else
			local x = floor((loc.x1 + loc.x2)/2)
			local y = floor((loc.y1 + loc.y2)/2)
			return z.." ("..x.."/"..y..")"
		end
	elseif type == 4 then
		return mobData.ttItems[data]
	else
		return value
	end
end -- MI2_EntryToString


-----------------------------------------------------------------------------
-- MI2_UpdateGameTooltip()
--
-- Add info about Mob to the standard game tooltip
--
local function MI2_UpdateGameTooltip( mobData, mobName, unit )

	if not unit and mobName ~= nil then
		if GameTooltip:GetOwner() == nil then
			GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
		end
		GameTooltip:ClearLines()
		GameTooltip:AddLine( mobData.levelInfo..mobName )
		GameTooltip:AddLine( " " )
	end

	if mobData.class and MobInfoConfig.ShowClass == 1 then
		local txt = GameTooltipTextLeft2:GetText()
		if txt then
			GameTooltipTextLeft2:SetText( txt.." "..mobData.class )
		end
	end

	local opt, value, itemText
	for idx = 1, MI2_MaxNumLines do
		opt = MI2_TooltipOptions[idx]
		if opt then
			value = MI2_EntryToString( opt.t, opt.data, mobData, unit )
			if value then
				if opt.data == "qualityStr" or opt.data == "loc" then
					GameTooltip:AddLine( opt.text..": "..MI2_White..value )
				else
					GameTooltip:AddDoubleLine( opt.text, MI2_White..value )
				end
			end
		end
	end
	for idx = 1, MI2_MaxNumItems do
		itemText = MI2_EntryToString( 4, idx, mobData )
		if itemText then
			GameTooltip:AddLine( itemText )
		end
	end
	if GameTooltip:NumLines() > 1 and mobData.lowHpAction then
		GameTooltipTextLeft2:SetText( GameTooltipTextLeft2:GetText()..' '..MI2_LightRed..MI2_TXT_MOBRUNS )
	end

	if not unit then
		GameTooltip:Show()
	else
		GameTooltip:AppendText("")
	end
end -- MI2_UpdateGameTooltip


-----------------------------------------------------------------------------
-- MI2_FillTooltipWithData()
--
local function MI2_FillTooltipWithData( mobData, unit )
	local opt, value, entry, itemText
	local extraWidth 

	-- fill in the extra tooltip info
	MI2TT_ExtraInfo1:SetText( mobData.extraInfo[1] or "" )
	MI2TT_ExtraInfo2:SetText( mobData.extraInfo[2] or "" )
	MI2TT_ExtraInfo3:SetText( mobData.extraInfo[3] or "" )
	MI2TT_ExtraInfo4:SetText( mobData.extraInfo[4] or "" )
	MI2TT_ExtraInfo5:SetText( mobData.extraInfo[5] or "" )
	MI2TT_ExtraInfo6:SetText( mobData.extraInfo[6] or "" )
	MI2TT_ExtraInfo7:SetText( mobData.extraInfo[7] or "" )
	MI2TT_ExtraInfo8:SetText( mobData.extraInfo[8] or "" )
	MI2TT_ExtraInfo9:SetText( mobData.extraInfo[9] or "" )
	MI2TT_ExtraInfo10:SetText( mobData.extraInfo[10] or "" )

	for ind, itemData in pairs(mobData.extraItemData) do
		if itemData == Enum.TooltipDataLineType.QuestObjective then
			MI2_ListItems[ind]:SetWidth(14)
			MI2_ListItems[ind]:Show()
			extraWidth = 14
		else
			MI2_ListItems[ind]:SetWidth(1)
			MI2_ListItems[ind]:Hide()
		end		
	end
	
	-- fill the columns
	local numEntries=0
	for idx = 1, MI2_MaxNumLines do
		opt = MI2_TooltipOptions[idx]
		if opt then
			value = MI2_EntryToString( opt.t, opt.data, mobData, unit )
			if value then
				numEntries = numEntries + 1
				entry = _G["MI2TT_Text"..numEntries]
				entry:SetText( opt.text )
				entry.val:SetText( value )
				entry:Show()
				entry.val:Show()
			end
		end
	end

	-- hide all the unused tooltip columns
	for idx = numEntries+1, MI2_MaxNumLines do
		entry = _G["MI2TT_Text"..idx]
		entry:Hide()
		entry.val:Hide()
	end

	-- fill the loot items lines
	for idx = 1, MI2_MaxNumItems do
		entry = _G["MI2TT_Item"..idx]
		itemText = MI2_EntryToString( 4, idx, mobData )
		if itemText then
			entry:SetText( itemText )
			entry:Show()
		else
			entry:Hide()
		end
	end
	
	return numEntries, extraWidth
end -- MI2_FillTooltipWithData


-----------------------------------------------------------------------------
-- MI2_SecureWidth()
--
-- Safe wrapper for GetStringWidth() that returns 0 when the value is a
-- secret number (tainted execution reading unit-sourced text content).
--
local function MI2_SecureWidth( fontString )
	local w = fontString:GetStringWidth()
	if issecretvalue and issecretvalue(w) then return 0 end
	return w
end

-----------------------------------------------------------------------------
-- MI2_UpdateTooltip()
--
-- This will update the contents of the MobInfo Tooltip with the data for
-- a specific given Mob. It includes tooltip content layouting based on
-- the size of the entries
--
local function MI2_UpdateTooltip( mobData, mobName, unit, isPet )
	if MobInfoConfig.UseGameTT == 1 then return end

	-- set mob name/level/type/class
	MI2TT_MobLevel:SetText( mobData.levelInfo )
	MI2TT_MobName:SetText( mobName )
	if (isPet) then
		MI2TT_MobName:SetTextColor( GameTooltipTextLeft1:GetTextColor() )
		MI2_TooltipFrame:SetBackdropBorderColor( GameTooltipTextLeft1:GetTextColor() )
	else
		MI2TT_MobName:SetTextColor( GameTooltip_UnitColor("mouseover") )
		MI2_TooltipFrame:SetBackdropBorderColor( GameTooltip_UnitColor("mouseover") )
	end
	MI2TT_ClassInfo:SetText( mobData.classInfo )
	local nameWidth = MI2_SecureWidth(MI2TT_MobLevel) + MI2_SecureWidth(MI2TT_MobName)
	local classWidth = MI2_SecureWidth(MI2TT_ClassInfo)

	local numEntries, extraItemDataWidth = MI2_FillTooltipWithData( mobData, unit )

	-- arrange tooltip layout 
	local colWidth = {0,0,0,0,0,0}
	local extraWidth = 0
	local ttHeight = MI2_FontHeight
	local right = false
	for idx = 1, numEntries do
		local entry = _G["MI2TT_Text"..idx]
		local txtWidth = MI2_SecureWidth(entry)
		local valWidth = MI2_SecureWidth(entry.val)
		if right and valWidth < MI2_MaxValWidth then
			entry:SetPoint( "TOPLEFT", MI2TT_Col3, "TOPLEFT", 0, ttHeight )
			entry.val:SetPoint( "TOPLEFT", MI2TT_Col4, "TOPLEFT", 0, ttHeight )
			if txtWidth > colWidth[3] then colWidth[3] = txtWidth end
			if valWidth > colWidth[4] then colWidth[4] = valWidth end
			right = false
		else
			ttHeight = ttHeight - MI2_FontHeight
			entry:SetPoint( "TOPLEFT", MI2TT_Col1, "TOPLEFT", 0, ttHeight )
			entry.val:SetPoint( "TOPLEFT", MI2TT_Col2, "TOPLEFT", 0, ttHeight )
			right = valWidth < MI2_MaxValWidth and MobInfoConfig.CompactMode == 1
			if txtWidth > colWidth[1] then colWidth[1] = txtWidth end
			if right then
				if valWidth > colWidth[2] then colWidth[2] = valWidth end
			else
				if valWidth > colWidth[5] then colWidth[5] = valWidth end
			end
		end
	end

	-- align the tooltip columns
	-- use last extra info line for anchoring the mob data columns
	local numExtraLines = #mobData.extraInfo
	if numExtraLines > 0 then
		local above = _G["MI2TT_ExtraInfo"..numExtraLines]
		if #mobData.extraItemData>0 and mobData.extraItemData[numExtraLines] == Enum.TooltipDataLineType.QuestObjective then
			above = MI2_ListItems[numExtraLines]
		end
		MI2TT_Col1:SetPoint( "TOPLEFT", above, "BOTTOMLEFT", 0, -2 )

		for idx = 1, numExtraLines do
			extraWidth = max(extraWidth, MI2_SecureWidth(_G["MI2TT_ExtraInfo"..idx])+(extraItemDataWidth or 0 ))
		end
	else
		MI2TT_Col1:SetPoint( "TOPLEFT", MI2TT_ClassInfo, "BOTTOMLEFT", 0, -2 )
	end
	MI2TT_Col2:SetPoint( "TOPLEFT", MI2TT_Col1, "TOPLEFT", colWidth[1], 0 )
	MI2TT_Col3:SetPoint( "TOPLEFT", MI2TT_Col2, "TOPLEFT", colWidth[2] + 4, 0 )
	MI2TT_Col4:SetPoint( "TOPLEFT", MI2TT_Col3, "TOPLEFT", colWidth[3], 0 )

	-- arrange loot items layout
	MI2TT_Item1:SetPoint( "TOPLEFT", MI2TT_Col1, "BOTTOMLEFT", 0, ttHeight - MI2_FontHeight )
	for idx = 1, MI2_MaxNumItems do
		local entry = _G["MI2TT_Item"..idx]
		if entry:IsShown() then
			ttHeight = ttHeight - MI2_FontHeight
			local txtWidth = MI2_SecureWidth(entry)
			if txtWidth > colWidth[6] then colWidth[6] = txtWidth end
		end
	end

	-- set tooltip width and height
	ttHeight = -ttHeight + 26 + MI2_FontHeight + (numExtraLines * MI2_FontHeight)
	if mobData.classInfo then
		ttHeight = ttHeight + MI2_FontHeight
	end
	local ttWidth = colWidth[2] + colWidth[3] + colWidth[4]
	if colWidth[5] > ttWidth then ttWidth = colWidth[5] end
	ttWidth = ttWidth + colWidth[1]
	if colWidth[6] > ttWidth then ttWidth = colWidth[6] end
	if nameWidth > ttWidth then ttWidth = nameWidth end
	if classWidth > ttWidth then ttWidth = classWidth end
	ttWidth = max(ttWidth,extraWidth) + 12

	MI2_TooltipFrame:SetWidth( ttWidth )
	MI2_TooltipFrame:SetHeight( ttHeight )
	MI2_TooltipFrame:SetAlpha(1)
	MI2_TooltipFrame:Show()
end -- MI2_UpdateTooltip

-----------------------------------------------------------------------------
-- MI2.CreateTooltip()
--
function MI2.CreateTooltip( id, level, unit, isMob, isPet, unique )

	if id == nil then return end

	local mobDataForTooltip, mobData = MI2_BuildTooltipMob( id, level, unit, isMob, MI2_GameTooltipNumLinesOriginal, unique )

	if unit and isMob
	then
		local unitType, unitId, unitName, unitLevel, unitGuid, unitIsClose, UnitClassification = MI2_Unit(unit)
		MI2_CacheMobInfo(unitGuid, unitName, unitLevel, mobData, unitIsClose, UnitClassification)
		MI2_MouseoverIndex = unitGuid -- must be set after calling MI2.RecordLocation
	end

	local unitName
	if type(id) == "string" then
		unitName = id
	else
		unitName = MI2_GetNameForId(id)
	end

	MI2_HideTimer = 9.0

	if not unit and isMob then
		MI2_UpdateGameTooltip( mobDataForTooltip, unitName )
	else
		-- hide other tooltip if requested
		if MobInfoConfig.OtherTooltip == 1 then
			GameTooltip:Hide()
		end
		-- anchor MobInfo tooltip either at mouse or at anchor frame
		if MobInfoConfig.MouseTooltip == 1 and unit then
			MI2_StartTooltipMouseMove()
		else
			MI2_UpdateAnchor()
		end
		MI2_UpdateTooltip( mobDataForTooltip, unitName, unit, isPet )

		-- hook into PTR issue reporter if available
		if PTR_IssueReporter then
			PTR_IssueReporter.HookIntoTooltip(MI2_TooltipFrame, PTR_IssueReporter.TooltipTypes.unit, id, unitName)
		end
	end
end -- MI2.CreateTooltip


-----------------------------------------------------------------------------
-- MI2.HideTooltip()
--
function MI2.HideTooltip()
	MI2_TooltipFrame:Hide()
	MI2_IsMoving = 0 
	GameTooltip:Hide()
end -- MI2.HideTooltip()
MI2_HideTooltip = MI2.HideTooltip


-----------------------------------------------------------------------------
-- MI2_GameTooltipCleared()
--
MI2_GameTooltipCleared = function()
	MI2_GameTooltipInfoAvailable = nil
	MI2_GameTooltipNumLinesOriginal = 0
end


-----------------------------------------------------------------------------
-- MI2_GameTooltipSetUnit()
--
MI2_GameTooltipSetUnit = function(...)
	local tooltip, tooltipData = ...
	if tooltip == GameTooltip then
		MI2_GameTooltipInfoAvailable = false
	end
end

function MI2.IsUnitClose(unit, level)

	if InCombatLockdown() or UnitAffectingCombat("player") then
		return false
	end

	-- for BOSS we check all distances
	if level == -1 then
		return CheckInteractDistance(unit, 1) or CheckInteractDistance(unit, 2) or CheckInteractDistance(unit, 3) or CheckInteractDistance(unit, 4);
	end
	-- for secret levels, use standard range check
	return CheckInteractDistance(unit,3) -- 7 yards

end
MI2_IsUnitClose = MI2.IsUnitClose

-----------------------------------------------------------------------------
-- MI2_GameTooltipOnUpdate()
--
MI2_GameTooltipOnUpdate = function()

	if MobInfoConfig.UseGameTT == 0 then return end
	-- only when unit is selected and only the first time
	if MI2_GameTooltipInfoAvailable ~= false then return end

	if MobInfoConfig.ShowMobInfo == 0 then return end
	if MobInfoConfig.KeypressMode == 1 and not IsAltKeyDown() then return end

	MI2_GameTooltipInfoAvailable = true
	MI2_GameTooltipNumLinesOriginal	= GameTooltip:NumLines()

	local unit = "mouseover"
	local name = UnitName(unit)
	local level = UnitLevel(unit)
	local guid = UnitGUID(unit)
	if name == nil
	then
		unit = "target"
		name = UnitName(unit)
		level = UnitLevel(unit)
		guid = UnitGUID(unit)
	end

	if name == nil or (issecretvalue and issecretvalue(name)) then return end
	if UnitIsPlayer(unit) then return end
	if MobInfoConfig.ShowWhileInCombat == 0 and UnitAffectingCombat("player") then return end

	local isMob = not(UnitIsPlayer(unit) or UnitIsFriend("player",unit) or not UnitCanAttack("player",unit))
	local mobDataForTooltip, mobData = MI2_BuildTooltipMob( name, level, unit, isMob, MI2_GameTooltipNumLinesOriginal)

	if unit and isMob and (not issecretvalue or not issecretvalue(guid)) and guid
	then
		MI2_CacheMobInfo(guid,name,level,mobData,MI2_IsUnitClose(unit),UnitClassification(unit))
	end

	MI2_UpdateGameTooltip(mobDataForTooltip, name, unit)
end
