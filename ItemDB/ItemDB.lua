-- ItemDB / LibItemDB — addon bootstrap.
--
-- The payload of this addon is the LibItemDB-1.0 library plus its shipped data
-- files. This file does NOT touch the data; it only wires the optional guild
-- version-check (VersionCheck-1.0) so users can see who has which LibItemDB
-- version across the guild, consistent with the rest of the TOG suite.
--
-- VersionCheck-1.0 (and its Ace3 backing) are declared as dependencies in the
-- .toc, so they are loaded before this file. VersionCheck ships for every
-- flavour, Retail included; it does not constrain which flavours we ship for.

local addonName = ...

local _GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = _GetAddOnMetadata(addonName, "Version") or "dev"

-- VersionCheck only needs a table with :GetName() and a .Version field. We use
-- the recognizable project name "LibItemDB" (the folder on disk is "ItemDB").
local host = { Version = version }
function host:GetName() return "LibItemDB" end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local VC = LibStub and LibStub("VersionCheck-1.0", true)
    if VC and VC.Enable then
        VC:Enable(host)
    end
end)
