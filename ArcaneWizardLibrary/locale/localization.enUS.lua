local _, LIB = ...

LIB.Localization = setmetatable({},{__index=function(self,key)
		geterrorhandler()(LIB.CommonData.debugPrefix .. "Missing entry for '" .. tostring(key) .. "'")
		return key
	end})

local L = LIB.Localization

-- Initialization

L["error.character-identity-unavailable"] = "Startup aborted: the player GUID, name or realm is unavailable. Please try /reload."

-- Dialog

L["dialog.link.text"] = "To copy the link press CTRL + C."

-- Changelog

L["changelog.window.title"] = "%s - Changelog"
L["changelog.window.close"] = "Close"
L["settings.changelog.name"] = "Version Notes"
L["settings.changelog.button"] = "Changelog"
L["settings.changelog.tooltip"] = "Opens the changelog window."

-- Profiles

L["settings.profiles.section-header"] = "Profiles"
L["settings.profiles.profile-mode"] = "Active Profile"
L["settings.profiles.mode.account"] = "Account Profile"
L["settings.profiles.mode.character"] = "Character Profile"
L["settings.profiles.switch.name"] = "Switch Profile Type"
L["settings.profiles.switch.tooltip"] = "Switches between the account profile and character profile."
L["settings.profiles.switch.button.account-to-character"] = "Use Character Profile"
L["settings.profiles.switch.button.character-to-account"] = "Use Account Profile"
L["settings.profiles.switch.confirm.account-to-character"] = "This character will use its own character profile after this. This change requires a UI reload. Do you want to continue?"
L["settings.profiles.switch.confirm.character-to-account"] = "This character will use the account profile after this. This change requires a UI reload. Do you want to continue?"
L["settings.profiles.delete-character-profiles.name"] = "Reset Character Profiles"
L["settings.profiles.delete-character-profiles.button"] = "Delete Character Profiles"
L["settings.profiles.delete-character-profiles.tooltip"] = "Deletes all character profiles and sets all characters to the account profile."
L["settings.profiles.delete-character-profiles.confirm"] = "All character profiles will be deleted and all characters will use the account profile after this. Do you want to continue?"

-- About

L["settings.about"] = "About"
L["settings.about.game-version"] = "Game Version"
L["settings.about.addon-version"] = "Addon Version"
L["settings.about.lib-version"] = "Library Version"
L["settings.about.author"] = "Author"
L["settings.about.button-curseforge.name"] = "CurseForge Project Page"
L["settings.about.button-curseforge.tooltip"] = "Opens a popup window with a link to CurseForge."
L["settings.about.button-curseforge.button"] = "CurseForge"
L["settings.about.button-wago.name"] = "Wago Project Page"
L["settings.about.button-wago.tooltip"] = "Opens a popup window with a link to Wago."
L["settings.about.button-wago.button"] = "Wago"
L["settings.about.button-github.name"] = "Feedback & Help"
L["settings.about.button-github.tooltip"] = "Opens a popup window with a link to GitHub."
L["settings.about.button-github.button"] = "GitHub"
