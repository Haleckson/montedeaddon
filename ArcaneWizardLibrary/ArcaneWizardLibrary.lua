local addonName, LIB = ...

LIB.Internal = LIB.Internal or {}
LIB.Internal.AddonLauncher = {}

ArcaneWizardLibrary = ArcaneWizardLibrary or {}

local AWL = ArcaneWizardLibrary

AWL.Utils = {}
AWL.Dialogs = {}
AWL.Controls = {}
AWL.ScrollFrames = {}
AWL.Settings = {}
AWL.Frames = {}

AWL.ADDON_AUTHOR = C_AddOns.GetAddOnMetadata(addonName, "Author")
AWL.ADDON_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version")
AWL.ADDON_BUILD_DATE = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate")
AWL.ADDON_REVISION = C_AddOns.GetAddOnMetadata(addonName, "X-Revision")

local gameVersion, _, _, interfaceVersion = GetBuildInfo()
AWL.GAME_VERSION = gameVersion

AWL.GAME_TYPE_CLASSIC = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
AWL.GAME_TYPE_TBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
---@diagnostic disable-next-line: undefined-global
AWL.GAME_TYPE_MISTS = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
AWL.GAME_TYPE_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
---@diagnostic disable-next-line: undefined-global
AWL.GAME_TYPE_FOREVER = (WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)

AWL.GAME_FLAVOR = "unknown"

if AWL.GAME_TYPE_CLASSIC then
	AWL.GAME_FLAVOR = "Classic"
elseif AWL.GAME_TYPE_TBC then
	AWL.GAME_FLAVOR = "Burning Crusade - Classic Anniversary Edition"
elseif AWL.GAME_TYPE_MISTS then
	AWL.GAME_FLAVOR = "Mists of Pandaria - Classic"
elseif AWL.GAME_TYPE_FOREVER then
	AWL.GAME_FLAVOR = "Forever"
elseif AWL.GAME_TYPE_RETAIL then
	AWL.GAME_FLAVOR = "Retail"
end
