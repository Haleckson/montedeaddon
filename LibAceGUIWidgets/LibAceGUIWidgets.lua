-- LibAceGUIWidgets — addon bootstrap.
--
-- The payload of this addon is the LibAceGUIWidgets-1.0 library (shared AceGUI-3.0
-- widget types + styling for the TOG suite). This file does NOT touch the widgets;
-- it only wires the optional guild version-check (VersionCheck-1.0) so users can
-- see who has which LibAceGUIWidgets version across the guild, consistent with the
-- rest of the suite (ItemDB does the same).
--
-- ⚠ THIS USES THE LIBRARY'S OWN HELPER, and it did not until peer review finding 4.
-- `lib:EnableVersionCheck` exists precisely so a consumer does not hand-roll the
-- LibStub lookup + Enable — its own comment says so, naming the addons that had
-- copied the pattern. This file, in the same addon, was hand-rolling it: the
-- reference implementation of the helper was the one consumer not using it.
--
-- Two edges went with the hand-roll, which is why this is a fix and not tidying:
--
--   1. `(C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata` was then CALLED
--      unguarded. On a client with neither spelling that is nil, and calling it is a
--      hard error at file scope — taking the bootstrap down rather than losing a
--      version string. VersionCheck-1.0 writes the guarded form deliberately and its
--      comment names this exact failure. No client anyone runs today is in that state;
--      the point is that this repo held both spellings and the unguarded one was newer.
--   2. The `or "dev"` fallback carries no digits, so VersionCheck's CompareVersion sorts
--      it below every real version — and unlike "LibAceGUIWidgets-v0.3.0" it does NOT trip the
--      dev-build suppression, so a host reporting "dev" would nag against every peer.
--
-- Omitting the version is what the helper documents: it lets VersionCheck read the
-- metadata itself, guarded, in the one place that already gets it right. So this file
-- now makes no metadata call at all.
--
-- THE TOC LINES STAY AS THEY ARE: `## Dependencies: Ace3`, `## OptionalDeps: VersionCheck-1.0`,
-- and VersionCheck's own TOC naming this library back. That pair has run on every client
-- with no warning, and on 2026-09-20 the user said so and had a day's edits to both TOCs
-- reverted: "put the toc's back to the way they were". The `AddOn [LibAceGUIWidgets]
-- failure to load: missing` report that started it was a World of Warcraft: Forever
-- player without v0.2.1 -- the first build whose TOC claims 16001 -- so "missing" meant
-- the folder was not there. It was not a load-order defect and nothing in this file
-- addresses it. Do not re-derive a dependency cycle from these two TOCs and act on it.
-- luacheck: read globals LibAceGUIWidgetsDB
local LIB_NAME = "LibAceGUIWidgets-1.0"

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, name)
	local lib = LibStub and LibStub(LIB_NAME, true)
	-- The player's `/lagw debug` choice (MINOR 39) lives in this addon's SavedVariables, which the
	-- client hands over at our own ADDON_LOADED -- after the library files ran, before anything logs in.
	if event == "ADDON_LOADED" then
		if name ~= "LibAceGUIWidgets" then return end
		self:UnregisterEvent("ADDON_LOADED")
		if lib and type(LibAceGUIWidgetsDB) == "table" then lib._debugOverride = LibAceGUIWidgetsDB.debug end
		return
	end
	self:UnregisterAllEvents()
	if lib and lib.EnableVersionCheck then
		lib:EnableVersionCheck("LibAceGUIWidgets")
	end
end)
