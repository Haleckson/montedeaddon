--
-- MI2_Health.lua
--

local _, MI2 = ...
local UnitHealthMax, UnitManaMax = UnitHealthMax, UnitManaMax

-- remember previous font type and font size
local lOldFontId = 0
local lOldFontSize = 0

-- flag to track if statusbar scripts have been registered
local lStatusbarScriptsRegistered = false

function MI2.GetNumText(num, numNax)
	local factor = 1
	if numNax and numNax > 10000 then
		factor = 10
	end
	if num > 10000000*factor then
		return string.format("%.fM", num/1000000)
	end
	if num > 10000*factor then
		return string.format("%.fK", num/1000)
	end
	return num
end

-----------------------------------------------------------------------------
-- MI2_MobHealth_SetFont()
--
-- set new font	for	display	of health /	mana in	target frame
--
local function MI2_MobHealth_SetFont( fontId, fontSize )
	local fontName

	if fontId ~= lOldFontId or fontSize ~= lOldFontSize then
		lOldFontId = fontId
		lOldFontSize = fontSize

		-- select font name	to use
		if	fontId == 1	 then
			fontName = "Fonts\\ARIALN.TTF"  -- NumberFontNormal
		elseif	fontId == 2	 then
			fontName = "Fonts\\FRIZQT__.TTF"	 --	GameFontNormal
		else
			fontName = "Fonts\\MORPHEUS.TTF"	 --	ItemTextFontNormal
		end

		-- set font	for	health and mana	text
		MI2_MobHealthText:SetFont( fontName, fontSize )
		MI2_MobManaText:SetFont( fontName, fontSize )
		MI2_PlayerHealthText:SetFont( fontName, fontSize )
		MI2_PlayerManaText:SetFont( fontName, fontSize )
		MI2_PetHealthText:SetFont( fontName, fontSize )
		MI2_PetManaText:SetFont( fontName, fontSize )

	end

end	 --	of MI2_MobHealth_SetFont()


-----------------------------------------------------------------------------
-- MI2.MobHealth_SetPos()
--
-- set position	and	font for mob health/mana texts
--
function MI2.MobHealth_SetPos( )
	-- Modern clients use a different target-frame/UI model. In WoW Midnight
	-- or Forever, UnitHealth/UnitMana values are also secrets. Disable the
	-- legacy overlay for both Midnight and WoW Forever.
	if MI2.WOW_MODERN then
		MI2_MobHealthFrame:Hide()
		MI2_PlayerHealthFrame:Hide()
		MI2_PetHealthFrame:Hide()
		return
	end

	local TargetFrameHealthBar = _G["TargetFrame"].healthbar
	MI2_MobHealthText:SetParent(TargetFrameHealthBar)
	MI2_MobHealthText:SetPoint("TOP", TargetFrameHealthBar, "CENTER",0, 4.5)

	local TargetFrameManaBar = _G["TargetFrame"].manabar
	MI2_MobManaText:SetParent(TargetFrameManaBar)
	MI2_MobManaText:SetPoint("TOP", TargetFrameManaBar, "CENTER",0, 4)

	local PlayerFrameHealthBar = _G["PlayerFrame"].healthbar
	MI2_PlayerHealthText:SetParent(PlayerFrameHealthBar)
	MI2_PlayerHealthText:SetPoint("TOP", PlayerFrameHealthBar, "CENTER",0, 5)

	local PlayerFrameManaBar = _G["PlayerFrame"].manabar
	MI2_PlayerManaText:SetParent(PlayerFrameManaBar)
	MI2_PlayerManaText:SetPoint("TOP", PlayerFrameManaBar, "CENTER",0, 5)
	MI2_PlayerHealthText:SetScale(0.9)
	MI2_PlayerManaText:SetScale(0.9)

	MI2_PetHealthText:SetParent(PetFrameHealthBar)
	MI2_PetHealthText:SetPoint("TOP", PetFrameHealthBar, "CENTER",0, 5)
	MI2_PetManaText:SetParent(PetFrameManaBar)
	MI2_PetManaText:SetPoint("TOP", PetFrameManaBar, "CENTER",0, 5)
	MI2_PetHealthText:SetScale(0.7)
	MI2_PetManaText:SetScale(0.7)

	-- Hook into statusbar value changes (preserve existing scripts) - only register once
	-- Note: This code only runs on non-modern UIs where UnitHealthMax/UnitManaMax
	-- return real values (no secrets), so we can call them directly.
	if not lStatusbarScriptsRegistered then
		local function RegisterStatusbarScript(statusbar, textElement, unit, valueType)
			local GetMaxValue = valueType == "Health" and UnitHealthMax or UnitManaMax

			statusbar:HookScript("OnValueChanged", function(self, value)
				if UnitIsDeadOrGhost(unit) then
					textElement:SetText("")
					return
				end

				local maxValue = GetMaxValue(unit)
				if value and value > 0 and maxValue and maxValue > 0 then
					local valueText
					if MobInfoConfig.ShowTargetInfo == 1 then
						if MobInfoConfig["Target"..valueType] == 1 then
							valueText = MI2.GetNumText(value, maxValue) .. " / " .. MI2.GetNumText(maxValue)
						end
						if MobInfoConfig[valueType.."Percent"] == 1 then
							local percentValue = 100 * value / maxValue
							if valueText then
								valueText = valueText..string.format(" (%d%%)", ceil(percentValue))
							else
								valueText = string.format("%d%%", ceil(percentValue))
							end
						end
					end
					textElement:SetText(valueText or "")
				end
			end)
		end
		RegisterStatusbarScript(TargetFrameHealthBar, MI2_MobHealthText, "target", "Health")
		RegisterStatusbarScript(TargetFrameManaBar, MI2_MobManaText, "target", "Mana")
--[[	RegisterStatusbarScript(PlayerFrameHealthBar, MI2_PlayerHealthText, "player", "Health")
		RegisterStatusbarScript(PlayerFrameManaBar, MI2_PlayerManaText, "player", "Mana")
		RegisterStatusbarScript(PetFrameHealthBar, MI2_PetHealthText, "pet", "Health")
		RegisterStatusbarScript(PetFrameManaBar, MI2_PetManaText, "pet", "Mana")

--]]		lStatusbarScriptsRegistered = true
	end

	-- update font ID and font size
	MI2_MobHealth_SetFont( MobInfoConfig.TargetFont, MobInfoConfig.TargetFontSize )

	-- update visibility of target frame info
	if MobInfoConfig.ShowTargetInfo == 1 and MobInfoConfig.DisableHealth ~= 2 then
		MI2_MobHealthFrame:Show()
		MI2_PlayerHealthFrame:Show()
		MI2_PetHealthFrame:Show()
	else
		MI2_MobHealthFrame:Hide()
		MI2_PlayerHealthFrame:Hide()
		MI2_PetHealthFrame:Hide()
	end
end	 --	of MI2.MobHealth_SetPos()
