--[[
  Forever Companion - Core/Init.lua
  Namespace, module registry and addon lifecycle.

  Every file receives the private namespace table through `...`. Only one
  global is published on purpose: `ForeverCompanion` (for debugging, the
  addon compartment and other addons that want to integrate).

  Module lifecycle:
    OnInitialize()  - after SavedVariables are loaded and migrated (ADDON_LOADED)
    OnEnable()      - at PLAYER_LOGIN, when the world and unit APIs are usable
    OnLogout()      - at PLAYER_LOGOUT, last chance to write SavedVariables
]]

local ADDON_NAME, FC = ...

_G.ForeverCompanion = FC

FC.name = ADDON_NAME
FC.modules = {}
FC.moduleList = {}
FC.initialized = false
FC.enabled = false

local function readMetadata(field)
    local getter = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    if not getter then return nil end
    local ok, value = pcall(getter, ADDON_NAME, field)
    if ok then return value end
    return nil
end

FC.version = readMetadata("Version") or "0.9.3"

--- Registers a module and returns its table. Modules are initialized in
--- registration order, which follows the TOC order.
function FC:NewModule(name)
    assert(type(name) == "string" and not self.modules[name], "Invalid or duplicate module: " .. tostring(name))
    local module = { moduleName = name }
    self.modules[name] = module
    self.moduleList[#self.moduleList + 1] = module
    self[name] = module
    return module
end

function FC:GetModule(name)
    return self.modules[name]
end

local function errorHandler(err)
    local trace = debugstack and debugstack(2) or ""
    return tostring(err) .. "\n" .. trace
end

--- Calls fn protected. A failing module or handler is reported once and never
--- takes the rest of the addon down with it.
function FC:SafeCall(label, fn, ...)
    local args = { ... }
    local count = select("#", ...)
    local ok, result = xpcall(function() return fn(unpack(args, 1, count)) end, errorHandler)
    if not ok then
        if self.Log then
            self.Log:Error("%s failed: %s", tostring(label), tostring(result))
        end
        return false, result
    end
    return true, result
end

local function runPhase(phase)
    for _, module in ipairs(FC.moduleList) do
        local fn = module[phase]
        if type(fn) == "function" then
            FC:SafeCall(module.moduleName .. ":" .. phase, fn, module)
        end
    end
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:RegisterEvent("PLAYER_LOGOUT")
lifecycle:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        FC:SafeCall("Database:Load", FC.Database.Load, FC.Database)
        runPhase("OnInitialize")
        FC.initialized = true
    elseif event == "PLAYER_LOGIN" then
        if not FC.initialized then return end
        runPhase("OnEnable")
        FC.enabled = true
        if FC.Bus then FC.Bus:Emit("ADDON_READY") end
    elseif event == "PLAYER_LOGOUT" then
        runPhase("OnLogout")
    end
end)
