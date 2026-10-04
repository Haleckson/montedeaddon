-- $Id: Core.lua 116 2026-09-29 08:04:41Z arithmandar $
local _G = getfenv(0)
local _, private = ...

local LibStub = _G.LibStub

local MAJOR_VERSION = "LibBabble-ItemSet-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Rev: 112 $"):match("%d+"))

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub("LibBabble-3.0"):New(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

private["LibBabble-ItemSet-3.0-LoadingLib"] = lib
