-- ProfessionDB / LibProfessionDB — addon bootstrap.
--
-- The payload of this addon is the LibProfessionDB-1.0 library plus its shipped
-- data files. This file does NOT touch the data; it only wires the optional
-- guild version-check (VersionCheck-1.0) so users can see who has which
-- LibProfessionDB version across the guild, consistent with the rest of the
-- TOG suite.
--
-- VersionCheck-1.0 (and its Ace3 backing) are declared as dependencies in the
-- .toc, so they are loaded before this file. VersionCheck is Classic-only,
-- which lines up with this addon shipping for every flavour except Retail.

local addonName = ...

local _GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = _GetAddOnMetadata(addonName, "Version") or "dev"

-- VersionCheck only needs a table with :GetName() and a .Version field. We use
-- the recognizable project name "LibProfessionDB" (the folder on disk is
-- "ProfessionDB").
local host = { Version = version }
function host:GetName() return "LibProfessionDB" end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local VC = LibStub and LibStub("VersionCheck-1.0", true)
    if VC and VC.Enable then
        VC:Enable(host)
    end
end)
