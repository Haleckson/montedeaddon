local _, LIB = ...

local L = LIB.Localization

-----------------------
--- Local Functions ---
-----------------------

local function GetInfoTextHeight(config)
	if type(config.height) == "number" then
		return config.height
	end

	if type(config.height) == "string" and LIB.INFO_TEXT_HEIGHTS[config.height] then
		return LIB.INFO_TEXT_HEIGHTS[config.height]
	end

	return LIB.INFO_TEXT_HEIGHTS["default"]
end

local function FormatAboutValue(value, detail)
	if not value then
		return ""
	end

	if detail and detail ~= "" then
		return tostring(value) .. " (" .. tostring(detail) .. ")"
	end

	return tostring(value)
end

local function GetAddonMetadata(addonName, key)
	if not addonName then
		return nil
	end

	return C_AddOns.GetAddOnMetadata(addonName, key)
end

local function ApplyInitializerConfig(initializer, config)
	if config.parentInit and config.parentCondition then
		initializer:SetParentInitializer(config.parentInit, config.parentCondition)
	end

	if config.shownPredicate then
		initializer:AddShownPredicate(config.shownPredicate)
	end

	if config.isNew ~= nil then
		hooksecurefunc(initializer, "InitFrame", function(_, frame)
			if frame.NewFeature then
				frame.NewFeature:SetShown(config.isNew)
			end
		end)
	end
end

local function ApplySettingConfig(setting, config)
	if config.onClick then
		setting:SetValueChangedCallback(config.onClick)
	end
end

local function GetAboutConfig(addonName)
	return {
		addonVersion = GetAddonMetadata(addonName, "Version"),
		addonBuildDate = GetAddonMetadata(addonName, "X-BuildDate"),
		addonAuthor = GetAddonMetadata(addonName, "Author"),
		curseforgeLink = GetAddonMetadata(addonName, "X-Curseforge"),
		wagoLink = GetAddonMetadata(addonName, "X-Wago"),
		githubLink = GetAddonMetadata(addonName, "X-Github")
	}
end

------------------------
--- Public Functions ---
------------------------

--- Adds a button to the settings layout.
---
--- @param layout table The settings layout.
--- @param config table Button text, callback, tooltip, optional visibility settings and isNew badge.
---
--- @return table initializer The button initializer.
function ArcaneWizardLibrary.Settings:AddButton(layout, config)
	local initializer = CreateSettingsButtonInitializer(
		config.name,
		config.buttonText,
		config.onClick,
		config.tooltip,
		true
	)

	ApplyInitializerConfig(initializer, config)

	layout:AddInitializer(initializer)

	return initializer
end

--- Adds a static text row to the settings layout.
---
--- @param layout table The settings layout.
--- @param config table Left/right text and optional height and visibility settings.
---
--- @return table initializer The text row initializer.
function ArcaneWizardLibrary.Settings:AddInfoText(layout, config)
	local initializer = Settings.CreateElementInitializer("ArcaneWizardLibrary_SettingsPanelText", {
		leftText = config.leftText or "",
		rightText = config.rightText or "",
	})

	ApplyInitializerConfig(initializer, config)

	local line = layout:AddInitializer(initializer)

	function line:GetExtent()
		return GetInfoTextHeight(config)
	end

	return initializer
end

--- Adds a freely placed horizontal separator to the settings layout.
---
--- @param layout table The settings layout.
---
--- @return table initializer The separator initializer.
function ArcaneWizardLibrary.Settings:AddSeparator(layout)
	local initializer = Settings.CreateElementInitializer("ArcaneWizardLibrary_SettingsSeparatorTemplate", LIB.SETTINGS_SEPARATOR)
	local line = layout:AddInitializer(initializer)

	function line:GetExtent()
		return LIB.SETTINGS_SEPARATOR.height
	end

	return initializer
end

--- Registers a checkbox in the settings category.
---
--- @param category table The settings category.
--- @param config table Variable binding, label, tooltip, default, optional behavior settings and isNew badge.
---
--- @return table initializer The checkbox initializer.
--- @return table setting The registered setting.
function ArcaneWizardLibrary.Settings:AddCheckbox(category, config)
	local setting = Settings.RegisterAddOnSetting(category, config.settingKey, config.variableName, config.variableTable, Settings.VarType.Boolean, config.name, config.default or false)
	local initializer = Settings.CreateCheckbox(category, setting, config.tooltip)

	ApplyInitializerConfig(initializer, config)
	ApplySettingConfig(setting, config)

	return initializer, setting
end

--- Registers a slider in the settings category.
---
--- @param category table The settings category.
--- @param config table Variable binding, label, range, step, default, optional behavior settings and isNew badge.
---
--- @return table initializer The slider initializer.
--- @return table setting The registered setting.
function ArcaneWizardLibrary.Settings:AddSlider(category, config)
	local setting = Settings.RegisterAddOnSetting(category, config.settingKey, config.variableName, config.variableTable, Settings.VarType.Number, config.name, config.default or 1)
	local options = Settings.CreateSliderOptions(config.minValue or 1, config.maxValue or 10, config.step or 1)

	if config.formatter then
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, config.formatter)
	end

	local initializer = Settings.CreateSlider(category, setting, options, config.tooltip)

	ApplyInitializerConfig(initializer, config)
	ApplySettingConfig(setting, config)

	return initializer, setting
end

--- Registers a combined checkbox and slider.
---
--- @param category table The settings category.
--- @param layout table The settings layout.
--- @param config table Checkbox and slider bindings, labels, defaults, range, optional visibility settings and isNew badge.
---
--- @return table initializer The combined initializer.
--- @return table settingCheckbox The checkbox setting.
--- @return table settingSlider The slider setting.
function ArcaneWizardLibrary.Settings:AddCheckboxSliderCombo(category, layout, config)
	local settingCheckbox = Settings.RegisterAddOnSetting(category, config.checkboxSettingKey, config.checkboxVariableName, config.variableTable, Settings.VarType.Boolean, config.checkboxName, config.checkboxDefault or false)
	local settingSlider = Settings.RegisterAddOnSetting(category, config.sliderSettingKey, config.sliderVariableName, config.variableTable, Settings.VarType.Number, config.sliderName, config.sliderDefault or 1)
	local optionsSlider = Settings.CreateSliderOptions(config.sliderMin or 1, config.sliderMax or 10, config.sliderStep or 1)

	if config.sliderFormatter then
		optionsSlider:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, config.sliderFormatter)
	end

	local initializer = CreateSettingsCheckboxSliderInitializer(settingCheckbox, config.checkboxName, config.checkboxTooltip, settingSlider, optionsSlider, config.sliderName, config.sliderTooltip)
	initializer.GetSetting = function() return settingCheckbox end

	ApplyInitializerConfig(initializer, config)

	layout:AddInitializer(initializer)

	return initializer, settingCheckbox, settingSlider
end

--- Registers a dropdown in the settings category.
---
--- @param category table The settings category.
--- @param config table Variable binding, label, options, default, optional behavior settings and isNew badge.
---
--- @return table initializer The dropdown initializer.
--- @return table setting The registered setting.
function ArcaneWizardLibrary.Settings:AddDropdown(category, config)
	local varType = type(config.default) == "string" and Settings.VarType.String or Settings.VarType.Number
	local setting = Settings.RegisterAddOnSetting(category, config.settingKey, config.variableName, config.variableTable, varType, config.name, config.default)

	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		if config.options then
			for _, opt in ipairs(config.options) do
				container:Add(opt.value, opt.label)
			end
		end
		return container:GetData()
	end

	local initializer = Settings.CreateDropdown(category, setting, GetOptions, config.tooltip)

	ApplyInitializerConfig(initializer, config)
	ApplySettingConfig(setting, config)

	return initializer, setting
end

--- Adds an expandable header section to the settings layout.
---
--- @param layout table The layout object to append the initializer to.
--- @param name string The display name of the header.
---
--- @return table initializer The layout initializer object for the header.
--- @return function isExpandedPredicate A function that returns the current expanded state (boolean).
function ArcaneWizardLibrary.Settings:AddExpandableHeader(layout, name)
	local initializer = CreateFromMixins(SettingsExpandableSectionInitializer)
	local data = { name = name, expanded = false }

	initializer:Init("ArcaneWizardLibrary_SettingsExpandTemplate")
	initializer.data = data
	initializer.GetExtent = ScrollBoxFactoryInitializerMixin.GetExtent

	layout:AddInitializer(initializer)

	return initializer, function() return data.expanded end
end

--- Adds a standard Profiles section to the settings layout.
---
--- @param layout table The layout object to append the initializers to.
--- @param config table Configuration table. Expected keys: useAccountProfile, onSwitchProfile, onDeleteCharacterProfiles.
function ArcaneWizardLibrary.Settings:AddProfilesSection(layout, config)
	local profileModeText = L["settings.profiles.mode.character"]
	local switchButtonText = L["settings.profiles.switch.button.character-to-account"]

	if config.useAccountProfile then
		profileModeText = L["settings.profiles.mode.account"]
		switchButtonText = L["settings.profiles.switch.button.account-to-character"]
	else
		local characterName = UnitName("player")
		if characterName and characterName ~= "" then
			profileModeText = profileModeText .. " (" .. characterName .. ")"
		end
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["settings.profiles.section-header"]))

	self:AddInfoText(layout, {
		leftText  = L["settings.profiles.profile-mode"],
		rightText = profileModeText
	})

	self:AddButton(layout, {
		name       = L["settings.profiles.switch.name"],
		buttonText = switchButtonText,
		tooltip    = L["settings.profiles.switch.tooltip"],
		onClick    = function()
			local confirmText = L["settings.profiles.switch.confirm.character-to-account"]

			if config.useAccountProfile then
				confirmText = L["settings.profiles.switch.confirm.account-to-character"]
			end

			ArcaneWizardLibrary.Dialogs:ShowConfirmDialog(confirmText, config.onSwitchProfile)
		end
	})

	self:AddButton(layout, {
		name       = L["settings.profiles.delete-character-profiles.name"],
		buttonText = L["settings.profiles.delete-character-profiles.button"],
		tooltip    = L["settings.profiles.delete-character-profiles.tooltip"],
		onClick    = function()
			ArcaneWizardLibrary.Dialogs:ShowConfirmDialog(
				L["settings.profiles.delete-character-profiles.confirm"],
				config.onDeleteCharacterProfiles
			)
		end
	})
end

--- Adds a standard About section to the settings layout.
---
--- @param layout table The layout object to append the initializers to.
--- @param addonName string Addon name used to read metadata.
--- @param changelog? ArcaneWizardLibraryChangelogVersion[] Optional changelog versions displayed through an additional button.
function ArcaneWizardLibrary.Settings:AddAboutSection(layout, addonName, changelog)
	assert(layout ~= nil, LIB.CommonData.debugPrefix .. "AddAboutSection layout is required.")
	assert(type(addonName) == "string" and addonName ~= "", LIB.CommonData.debugPrefix .. "AddAboutSection addonName must be a non-empty string.")

	local config = GetAboutConfig(addonName)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["settings.about"]))

	self:AddInfoText(layout, {
		leftText  = L["settings.about.game-version"],
		rightText = FormatAboutValue(ArcaneWizardLibrary.GAME_VERSION, ArcaneWizardLibrary.GAME_FLAVOR),
		height    = "compact"
	})

	self:AddInfoText(layout, {
		leftText  = L["settings.about.addon-version"],
		rightText = FormatAboutValue(config.addonVersion, config.addonBuildDate),
		height    = "compact"
	})

	self:AddInfoText(layout, {
		leftText  = L["settings.about.lib-version"],
		rightText = FormatAboutValue(ArcaneWizardLibrary.ADDON_VERSION, ArcaneWizardLibrary.ADDON_BUILD_DATE),
		height    = "compact"
	})

	self:AddInfoText(layout, {
		leftText  = L["settings.about.author"],
		rightText = config.addonAuthor or ""
	})

	if config.curseforgeLink and config.curseforgeLink ~= "" then
		self:AddButton(layout, {
			name       = L["settings.about.button-curseforge.name"],
			buttonText = L["settings.about.button-curseforge.button"],
			tooltip    = L["settings.about.button-curseforge.tooltip"],
			onClick    = function()
				ArcaneWizardLibrary.Dialogs:ShowLinkDialog(config.curseforgeLink)
			end
		})
	end

	if config.wagoLink and config.wagoLink ~= "" then
		self:AddButton(layout, {
			name       = L["settings.about.button-wago.name"],
			buttonText = L["settings.about.button-wago.button"],
			tooltip    = L["settings.about.button-wago.tooltip"],
			onClick    = function()
				ArcaneWizardLibrary.Dialogs:ShowLinkDialog(config.wagoLink)
			end
		})
	end

	if config.githubLink and config.githubLink ~= "" then
		self:AddButton(layout, {
			name       = L["settings.about.button-github.name"],
			buttonText = L["settings.about.button-github.button"],
			tooltip    = L["settings.about.button-github.tooltip"],
			onClick    = function()
				ArcaneWizardLibrary.Dialogs:ShowLinkDialog(config.githubLink)
			end
		})
	end

	if changelog then
		self:AddButton(layout, {
			name = L["settings.changelog.name"],
			buttonText = L["settings.changelog.button"],
			onClick = function()
				ArcaneWizardLibrary.Frames:OpenChangelog(addonName, changelog)
			end,
			tooltip = L["settings.changelog.tooltip"]
		})
	end
end
