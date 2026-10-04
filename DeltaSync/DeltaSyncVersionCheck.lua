-- DeltaSyncVersionCheck.lua -- registers the standalone DeltaSync addon with VersionCheck-1.0.
--
-- Loaded by DeltaSync.toc ONLY, and last. It is not part of the library: a consumer that vendors
-- the library files never lists this one, so only the installed DeltaSync addon announces itself
-- and an embedded copy never reports a version on DeltaSync's behalf.
--
-- VersionCheck-1.0 is a hard `## Dependencies:` of DeltaSync.toc, so the client has loaded it
-- before this file runs. The lookup is still feature-detected, as VersionCheck's README asks, so a
-- missing or older copy is silent rather than a load error.
--
-- The string form of Enable reads `## Version:` from the TOC itself, RAW: an unpackaged checkout
-- reports the literal `DeltaSync-v4.4.1`, which is how VersionCheck recognises a dev build and
-- suppresses its update popup. Do not substitute a friendlier value.
--
-- PLAYER_LOGIN, as ProfessionDB, ItemDB and GuildRoster do: every addon has loaded by then, and it
-- comes before PLAYER_ENTERING_WORLD, where VersionCheck schedules its login broadcast.

local addonName = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	local VC = LibStub and LibStub("VersionCheck-1.0", true)
	if VC and VC.Enable then
		VC:Enable(addonName)
	end
end)
