local _, LIB = ...

---@class ArcaneWizardLibraryAddon
---@field name string
---@field version string|nil
---@field buildDate string|nil
---@field mediaPath string
---@field mainCategoryId number|nil
---@field initializationAborted boolean|nil
---@field GetMediaPath fun(self: ArcaneWizardLibraryAddon, fileName: string|nil): string Returns the addon media path or a media file path below it.
---@field SetMainCategoryId fun(self: ArcaneWizardLibraryAddon, categoryId: number) Stores the Blizzard settings category ID for this addon.
---@field OpenCategory fun(self: ArcaneWizardLibraryAddon): boolean Opens the stored Blizzard settings category when not blocked by combat lockdown.
---@field InitializeOptions fun(self: ArcaneWizardLibraryAddon, config: table): table|nil Initializes and binds this addon's GUID-based option profiles.
---@field IsAccountProfile fun(self: ArcaneWizardLibraryAddon): boolean Returns whether the current character uses account settings.
---@field OpenSettingsOnLoading fun(self: ArcaneWizardLibraryAddon): boolean Opens settings when requested by a profile change.
---@field ToggleProfileMode fun(self: ArcaneWizardLibraryAddon) Switches the profile selection and requests settings after reload.
---@field ResetAllCharacterProfiles fun(self: ArcaneWizardLibraryAddon) Resets character profiles while preserving account settings.
---@field AbortInitialization fun(self: ArcaneWizardLibraryAddon, frame: Frame) Stops startup when the player identity is unavailable.
---@field RegisterMinimapButton fun(self: ArcaneWizardLibraryAddon, config: table): table Registers a LibDataBroker minimap button for this addon.
---@field CreateCompartmentHandlers fun(self: ArcaneWizardLibraryAddon, config: table): table Creates AddonCompartment handler functions for this addon.

local AddonContextMixin = {}

local AddonLauncher = LIB.Internal.AddonLauncher
local profileDefaults = ArcaneWizardLibrary.PROFILE_DEFAULTS

local addonContexts = {}
local addonOptions = {}

local function GetOptions(context)
	local options = addonOptions[context]
	assert(options, LIB.CommonData.debugPrefix .. "Options are not initialized for " .. tostring(context.name) .. ".")
	return options
end

local function SyncOptions(target, defaults, reservedKey)
	for key in pairs(target) do
		if key ~= reservedKey and defaults[key] == nil then
			target[key] = nil
		end
	end

	for key, value in pairs(defaults) do
		if key ~= reservedKey then
			if type(target[key]) ~= type(value) then
				target[key] = type(value) == "table" and ArcaneWizardLibrary.Utils:CopyTable(value) or value
			elseif type(value) == "table" then
				SyncOptions(target[key], value)
			end
		end
	end
end

--- Creates or returns the cached addon context.
---
--- @param addonName string The addon name.
---
--- @return ArcaneWizardLibraryAddon context The addon context.
local function CreateAddonContext(addonName)
	if addonContexts[addonName] then
		return addonContexts[addonName]
	end

	local context = {
		name = addonName,
		version = C_AddOns.GetAddOnMetadata(addonName, "Version"),
		buildDate = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate"),
		mediaPath = "Interface\\AddOns\\" .. addonName .. "\\assets\\"
	}

	setmetatable(context, { __index = AddonContextMixin })
	addonContexts[addonName] = context

	return context
end

--------------------------
--- Addon Context API ---
--------------------------

--- Returns the addon media path or a file path below it.
---
--- @param fileName string|nil The optional file name relative to the addon media path.
---
--- @return string path The addon media path or the requested file path.
function AddonContextMixin:GetMediaPath(fileName)
	if fileName and fileName ~= "" then
		return self.mediaPath .. fileName
	end

	return self.mediaPath
end

--- Initializes GUID-based options after SavedVariables have loaded.
--- On addon version changes, fills defaults and removes obsolete keys from global settings and all profiles.
--- cleanedOptions reports whether existing option tables were synchronized.
---
--- @param config table databaseName, defaults; optional globalDefaults, requireCharacterRealmKey and onOpenSettings.
---
--- @return table|nil result Active settings, global settings and profile metadata; nil if the required identity is unavailable.
function AddonContextMixin:InitializeOptions(config)
	local Utils = ArcaneWizardLibrary.Utils
	local characterGUID = Utils:GetCharacterGUID()

	if not characterGUID or config.requireCharacterRealmKey and not Utils:GetCharacterRealmKey() then
		addonOptions[self] = nil
		return nil
	end

	local createdProfile = false
	local createdProfileKey = false
	local cleanedOptions = false
	local defaults = config.defaults
	local globalDefaults = config.globalDefaults or {}
	local database = _G[config.databaseName]

	if not database then
		database = {}
		_G[config.databaseName] = database
	end

	local createdAccount = not database.account
	local createdGlobal = not database.global
	local versionChanged = self.version and (createdGlobal or database.global.version ~= self.version)

	if createdAccount then
		database.account = Utils:CopyTable(defaults)
	end
	if createdGlobal then
		database.global = Utils:CopyTable(globalDefaults)
	end
	database.profiles = database.profiles or {}
	database.profileKeys = database.profileKeys or {}

	if not database.profiles[characterGUID] then
		database.profiles[characterGUID] = Utils:CopyTable(defaults)
		createdProfile = true
	end

	if versionChanged then
		if not createdGlobal then
			SyncOptions(database.global, globalDefaults, "version")
			cleanedOptions = true
		end
		if not createdAccount then
			SyncOptions(database.account, defaults)
			cleanedOptions = true
		end
		for guid, profile in pairs(database.profiles) do
			if guid ~= characterGUID or not createdProfile then
				SyncOptions(profile, defaults)
				cleanedOptions = true
			end
		end
	end

	if not database.profileKeys[characterGUID] then
		database.profileKeys[characterGUID] = Utils:CopyTable(profileDefaults)
		createdProfileKey = true
	else
		Utils:MergeMissingTableEntries(database.profileKeys[characterGUID], profileDefaults)
	end

	addonOptions[self] = {
		database = database,
		characterGUID = characterGUID,
		onOpenSettings = config.onOpenSettings
	}

	local useAccountProfile = database.profileKeys[characterGUID]["use-account"]
	if self.version then
		database.global.version = self.version
	end

	return {
		characterGUID = characterGUID,
		createdProfile = createdProfile,
		createdProfileKey = createdProfileKey,
		cleanedOptions = cleanedOptions,
		activeProfile = useAccountProfile and "account" or "character",
		settings = useAccountProfile and database.account or database.profiles[characterGUID],
		global = database.global
	}
end

--- Returns whether the current character uses account settings.
---
--- @return boolean useAccountProfile Whether the account profile is selected.
function AddonContextMixin:IsAccountProfile()
	local options = GetOptions(self)
	return options.database.profileKeys[options.characterGUID]["use-account"]
end

--- Opens settings if requested; clears the request only on success.
---
--- @return boolean opened Whether settings were opened.
function AddonContextMixin:OpenSettingsOnLoading()
	local options = GetOptions(self)
	local profileKey = options.database.profileKeys[options.characterGUID]
	if not profileKey["open-settings"] then return false end

	local opened
	if options.onOpenSettings then
		opened = options.onOpenSettings()
	else
		opened = self:OpenCategory()
	end
	if not opened then return false end

	profileKey["open-settings"] = false
	return true
end

--- Switches the profile selection and requests settings to reopen after the caller reloads the UI.
function AddonContextMixin:ToggleProfileMode()
	local options = GetOptions(self)
	local profileKey = options.database.profileKeys[options.characterGUID]

	profileKey["use-account"] = not profileKey["use-account"]
	profileKey["open-settings"] = true
end

--- Clears all character profiles and selections, preserving account and global settings.
--- Requests settings to reopen after the caller reloads the UI.
function AddonContextMixin:ResetAllCharacterProfiles()
	local options = GetOptions(self)
	local database = options.database

	database.profiles = {}
	database.profileKeys = {}
	database.profileKeys[options.characterGUID] = ArcaneWizardLibrary.Utils:CopyTable(profileDefaults)
	database.profileKeys[options.characterGUID]["open-settings"] = true
end

--- Stores the Blizzard settings category ID for this addon.
---
--- @param categoryId number The settings category ID.
function AddonContextMixin:SetMainCategoryId(categoryId)
	self.mainCategoryId = categoryId
end

--- Opens the settings category registered with SetMainCategoryId.
---
--- @return boolean opened False during combat or after initialization was aborted.
function AddonContextMixin:OpenCategory()
	if self.initializationAborted then return false end

	local categoryId = self.mainCategoryId

	assert(categoryId, LIB.CommonData.debugPrefix .. "No Options Category ID defined for " .. tostring(self.name) .. ". The options menu cannot be opened.")

	if not InCombatLockdown() then
		Settings.OpenToCategory(categoryId)
		return true
	end

	return false
end

--- Stops the startup event frame and blocks launcher actions until reload.
--- Does not unload Lua files or disable the addon.
---
--- @param frame Frame The addon's startup event frame.
function AddonContextMixin:AbortInitialization(frame)
	self.initializationAborted = true
	frame:UnregisterAllEvents()
	frame:SetScript("OnEvent", nil)
	print(self.name .. ": " .. LIB.Localization["error.character-identity-unavailable"])
end

--- Registers or refreshes the addon's minimap button.
---
--- @param config table|nil Optional db, iconFileName, tooltip and onLeftClick settings.
---
--- @return table minimapButton The LibDBIcon instance.
function AddonContextMixin:RegisterMinimapButton(config)
	return AddonLauncher:RegisterMinimapButton(self, config)
end

--- Creates the addon's compartment handlers.
---
--- @param config table|nil Optional tooltip and onLeftClick settings.
---
--- @return table handlers The OnEnter, OnLeave and OnClick handlers.
function AddonContextMixin:CreateCompartmentHandlers(config)
	return AddonLauncher:CreateCompartmentHandlers(self, config)
end

------------------------
--- Public Functions ---
------------------------

--- Creates an addon context.
---
--- @param addonName string The addon name.
---
--- @return ArcaneWizardLibraryAddon context The addon context.
function ArcaneWizardLibrary:NewAddon(addonName)
	assert(type(addonName) == "string" and addonName ~= "", LIB.CommonData.debugPrefix .. "No addon name defined.")

	return CreateAddonContext(addonName)
end

--- Returns a registered addon context.
---
--- @param addonName string The addon name.
---
--- @return ArcaneWizardLibraryAddon context The registered addon context.
function ArcaneWizardLibrary:GetAddon(addonName)
	local context = addonContexts[addonName]

	assert(context, LIB.CommonData.debugPrefix .. "addon context is not initialized for " .. tostring(addonName))

	return context
end
