--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- addon framework (container, dependency injection, client detection, base services)
local Lib = LibStub("LibMasterAddons-1.0");

-- prepare storage
if (not PM_Data) then PM_Data = {}; end
if (not PM_Logs) then PM_Logs = {}; end
if (not PM_BucketList) then PM_BucketList = {}; end
if (not PM_ReagentWatchList) then PM_ReagentWatchList = {}; end
if (not PM_CharacterSettings) then PM_CharacterSettings = {}; end
if (not PM_Specializations) then PM_Specializations = {}; end
if (not PM_Skills) then PM_Skills = {}; end

-- create addon container: expansion flags (isVanilla, isBcc, ..., isSod,
-- is*AtLeast, expansionId), CreateModel/CreateService/CreateView, GetService,
-- NewView, HandleEvent, Log, GenerateString and the built-in log, locale,
-- timer and ui services come from the library
local addon = Lib:CreateAddon({
    id = "ProfessionMaster",
    name = "Profession Master",
    shortcut = "|cffDA8CFF[PM]|r ",
    storagePrefix = "PM",
});
ProfessionMasterAddon = addon;

-- logo in the portrait ring of the Forever windows (the toc keeps the small
-- icon for the addon list)
addon.portraitIcon = [[Interface\AddOns\ProfessionMaster\icons\pm-logo.png]];

-- determine if the expansion dropdown should be shown: only clients with more
-- than one data set (classic era and wow forever have exactly one)
addon.hasExpansion = addon.isSod or addon.isBccAtLeast;

-- TradeBoard host api version this ProfessionMaster build talks to. TradeBoard
-- bumps its `hostApiVersion` only on breaking structural changes; the versions
-- must match EXACTLY — on a mismatch the whole integration stays disabled and
-- the professions view shows an update hint (see version-badge-panel).
addon.RequiredTradeBoardApi = 1;

--- Check whether the loaded TradeBoard's host api matches exactly. A mismatch
--- (user updated only one of the two addons; old TradeBoards carry no
--- hostApiVersion at all) disables the trade integration completely.
function addon:IsTradeBoardCompatible()
    local tradeBoard = _G.tradeBoard;
    return tradeBoard ~= nil and tradeBoard.hostApiVersion == self.RequiredTradeBoardApi;
end

--- Get the main window the player used last: the classic professions
--- overview (default) or the database view.
function addon:GetMainView()
    if (PM_CharacterSettings.lastMainView == "database" and self.databaseView) then
        return self.databaseView;
    end
    return self.professionsView;
end

--- Show or hide the main window used last (slash command, minimap button).
function addon:ToggleMainView()
    local view = self:GetMainView();
    if (view) then
        view:ToggleVisibility();
    end
end

--- Switch between the professions overview and the database view; each
--- window closes the other on show and remembers itself for the next opening.
-- @param name "professions" or "database".
function addon:SwitchMainView(name)
    self:Log("Addon", "SwitchMainView", "Switched main window to %s", tostring(name));
    if (name == "database") then
        self.databaseView:Show();
    else
        self.professionsView:Show();
    end
end

--- Check settings.
function addon:CheckSettings()
    -- check settings
    if (not PM_Settings) then
        PM_Settings = {};
    end

    if (not PM_Settings.minimapButton) then
        PM_Settings.minimapButton = {
            hide = false
        };
    end
    if (PM_Settings.respondToWho == nil) then
        PM_Settings.respondToWho = true;
    end
    if (PM_Settings.tooltipShowPlayers == nil or PM_Settings.tooltipShowPlayers == true) then
        PM_Settings.tooltipShowPlayers = "always";
    elseif (PM_Settings.tooltipShowPlayers == false) then
        PM_Settings.tooltipShowPlayers = "shift";
    end
    if (PM_Settings.tooltipShowReagentFor == nil) then
        PM_Settings.tooltipShowReagentFor = "shift";
    elseif (PM_Settings.tooltipShowReagentFor == true) then
        PM_Settings.tooltipShowReagentFor = "always";
    elseif (PM_Settings.tooltipShowReagentFor == false) then
        PM_Settings.tooltipShowReagentFor = "shift";
    end
    if (PM_Settings.tooltipShowPlayerProfessions == nil or PM_Settings.tooltipShowPlayerProfessions == true) then
        PM_Settings.tooltipShowPlayerProfessions = "always";
    elseif (PM_Settings.tooltipShowPlayerProfessions == false) then
        PM_Settings.tooltipShowPlayerProfessions = "shift";
    end
    if (PM_Settings.tooltipShowGatheringNodes == nil or PM_Settings.tooltipShowGatheringNodes == true) then
        PM_Settings.tooltipShowGatheringNodes = "always";
    elseif (PM_Settings.tooltipShowGatheringNodes == false) then
        PM_Settings.tooltipShowGatheringNodes = "shift";
    end
    if (PM_Settings.shareCooldowns == nil) then
        PM_Settings.shareCooldowns = true;
    end
    if (PM_Settings.cooldownNotification == nil) then
        PM_Settings.cooldownNotification = "both";
    end
    if (PM_Settings.backgroundMissingReagents == nil) then
        PM_Settings.backgroundMissingReagents = 0.4;
    end
    if (PM_Settings.backgroundCooldowns == nil) then
        PM_Settings.backgroundCooldowns = 0.4;
    end
    if (PM_Settings.watchedCooldowns == nil) then
        PM_Settings.watchedCooldowns = {};
    end
    if (PM_Settings.autoScanPrices == nil) then
        PM_Settings.autoScanPrices = false;
    end

    -- keep the tbc content phase on the anniversary phase live today (phase 2
    -- since 2026-05-14, phase 3 since 2026-08-27; later phases get their dates
    -- once confirmed). Without the advance a phase seeded at install time
    -- stayed behind forever and hid all recipes of newer phases. A phase
    -- chosen by hand in the settings is never touched.
    if (self.isBcc and not PM_Settings.bccPhaseManual) then
        local today = tonumber(date("!%Y%m%d"));
        PM_Settings.bccPhase = (today >= 20260827) and 3 or 2;
    end
end

-- own addon loaded: settings and eagerly started services
addon:OnLoaded(function()
    addon:CheckSettings();
    addon:GetService("commands");
    -- chat service must start eagerly: it registers the chat message
    -- filters ([PM: ...] link rewrite) and hyperlink tooltip hooks;
    -- before, it only started implicitly via the removed welcome message
    addon:GetService("chat");
    addon:GetService("message");
    addon:GetService("player");
    -- link service must start eagerly: it listens to the hidden channel and
    -- the battle.net friend list for characters of linked accounts
    addon:GetService("link");
    addon:GetService("own-professions");
    addon:GetService("inventory");
    addon:GetService("bank");
    addon:GetService("mail");
    addon:GetService("auction");
    -- price scan must start eagerly: it attaches the scan button and the
    -- optional auto scan to the auction house events
    addon:GetService("auction-scan");
    addon:GetService("startup");
end);

-- hide the main windows in combat
addon:OnCombatStart(function()
    if (addon.professionsView and addon.professionsView.visible) then
        addon.professionsView:Hide();
    end
    if (addon.databaseView and addon.databaseView.visible) then
        addon.databaseView:Hide();
    end
end);

-- publish addon
_G.professionMaster = addon;
