local _, LIB = ...

local AddonLauncher = LIB.Internal.AddonLauncher

-----------------------
--- Local Functions ---
-----------------------

local function AddTooltipLines(tooltip, tooltipConfig)
	if type(tooltipConfig) == "table" then
		for _, line in ipairs(tooltipConfig) do
			GameTooltip_AddHighlightLine(tooltip, line)
		end
	elseif tooltipConfig and tooltipConfig ~= "" then
		GameTooltip_AddHighlightLine(tooltip, tooltipConfig)
	end
end

local function ShowTooltip(addon, config, tooltip)
	GameTooltip_SetTitle(tooltip, addon.name)

	local version = addon.version
	local buildDate = addon.buildDate
	local metadata

	if version and version ~= "" then
		metadata = tostring(version)

		if buildDate and buildDate ~= "" then
			metadata = metadata .. " (" .. tostring(buildDate) .. ")"
		end
	elseif buildDate and buildDate ~= "" then
		metadata = tostring(buildDate)
	end

	if metadata then
		GameTooltip_AddNormalLine(tooltip, metadata)
	end

	GameTooltip_AddBlankLineToTooltip(tooltip)
	AddTooltipLines(tooltip, config.tooltip)
end

local function HandleClick(addon, config, button)
	if addon.initializationAborted then return end

	if button == "LeftButton" and config.onLeftClick then
		config.onLeftClick()
	elseif button == "RightButton" then
		addon:OpenCategory()
	end
end

--------------------------
--- Internal Functions ---
--------------------------

function AddonLauncher:RegisterMinimapButton(addon, config)
	config = config or {}

	local iconFileName = config.iconFileName or "icon-round.tga"
	local dataBroker = LibStub("LibDataBroker-1.1")
	local dataObject = dataBroker:GetDataObjectByName(addon.name)

	local text = addon.name
	local icon = addon:GetMediaPath(iconFileName)
	local onClick = function(_, button)
		HandleClick(addon, config, button)
	end
	local onTooltipShow = function(tooltip)
		ShowTooltip(addon, config, tooltip)
	end

	if dataObject then
		dataObject.type = "launcher"
		dataObject.text = text
		dataObject.icon = icon
		dataObject.OnClick = onClick
		dataObject.OnTooltipShow = onTooltipShow
	else
		dataObject = dataBroker:NewDataObject(addon.name, {
			type = "launcher",
			text = text,
			icon = icon,
			OnClick = onClick,
			OnTooltipShow = onTooltipShow,
		})
	end

	local minimapButton = LibStub("LibDBIcon-1.0")

	if minimapButton:IsRegistered(addon.name) then
		minimapButton:Refresh(addon.name, config.db)
		return minimapButton
	end

	minimapButton:Register(addon.name, dataObject, config.db)

	return minimapButton
end

function AddonLauncher:CreateCompartmentHandlers(addon, config)
	config = config or {}

	return {
		OnEnter = function(_, button)
			GameTooltip:ClearAllPoints()
			GameTooltip:SetOwner(button, "ANCHOR_LEFT")
			ShowTooltip(addon, config, GameTooltip)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:Hide()
		end,
		OnClick = function(_, button)
			HandleClick(addon, config, button)
		end
	}
end
