local addonName, MCF = ...
-- /mcf perf: numbers for hunting lag. Memory is measured after a garbage collection so that only what the addon
-- really holds is counted. "In window" is the number of frames and regions below the main window (it must stay
-- roughly constant however often the window is redrawn); "retired" counts rows moved out of the window tree.

local function out(msg) print("|cff00ccffMyCharForever|r: " .. msg) end
local function de() return MCF:GetLanguage() == "deDE" end

local function CountTree(f, limit)
    local n = 1
    local function add(...)
        for i = 1, select("#", ...) do
            local c = select(i, ...)
            if c then
                n = n + 1
                if n < limit and c.GetChildren then n = n + CountTree(c, limit - n) - 1 end
            end
        end
    end
    if f.GetRegions then add(f:GetRegions()) end
    if f.GetChildren then
        for i = 1, select("#", f:GetChildren()) do
            local c = select(i, f:GetChildren())
            if c and n < limit then n = n + CountTree(c, limit - n) end
        end
    end
    return n
end

local function size(t) return type(t) == "table" and #t or 0 end

MCF:AddCommand{group = "debug", usage = "/mcf perf", key = "perf",
    de = "Speicher, Fenster-Elemente und Datenmengen des Addons anzeigen (gegen Lag, bitte Ausgabe schicken)",
    en = "Show the addon's memory, window elements and data sizes (for hunting lag)",
    run = function()
        collectgarbage()
        local kb
        if UpdateAddOnMemoryUsage then
            UpdateAddOnMemoryUsage()
            local get = (C_AddOns and C_AddOns.GetAddOnMemoryUsage) or GetAddOnMemoryUsage
            kb = get and get("MyCharForever")
        end
        out(string.format("v%s | %s %.0f KB", tostring(MCF.VERSION), de() and "Speicher" or "memory", kb or 0))
        local win = _G.MyCharForeverFrame
        out(string.format("%s %d | %s %d | %s %d", de() and "Elemente im Fenster" or "in window",
            win and CountTree(win, 20000) or 0, de() and "ausgemustert" or "retired", MCF.perf and MCF.perf.retired or 0,
            de() and "Tooltip-Pool" or "tip pool", size(MCF.tipPool)))
        local db = MyCharForeverDB or {}
        out(string.format("journey %d | events %d | screenshots %d | journal %d | sessions %d | worldDrops %d",
            size(db.journey), size(db.events), size(db.screenshots), size(db.journal), size(db.sessions), size(db.worldDrops)))
        if GetCVar and GetCVar("scriptProfile") == "1" and UpdateAddOnCPUUsage then
            UpdateAddOnCPUUsage()
            local get = (C_AddOns and C_AddOns.GetAddOnCPUUsage) or GetAddOnCPUUsage
            out(string.format("CPU %.0f ms", get and get("MyCharForever") or 0))
        else
            out(de() and "CPU: /console scriptProfile 1, dann /reload" or "CPU: /console scriptProfile 1, then /reload")
        end
    end}
