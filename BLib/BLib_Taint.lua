-- BLib_Taint.lua: which of Blizzard's globals an addon has written since login (the taint audit, 2026-10-03,
-- docs/taint-audit-2026-10.md). A global an addon writes keeps that addon's taint, and every read of it by
-- Blizzard's code carries it (BLib's own "StaticPopupDialogs = StaticPopupDialogs or {}" did that to every popup).
--
--   /blib taint on     from the next login, note which globals are Blizzard's (secure) when BLib loads
--   /blib taint        those that are no longer secure, and the addon that wrote each
--   /blib taint off    stop noting
--
-- Off by default: the note is a list of every global name, a few megabytes, wanted only while checking. It needs
-- the client's issecurevariable, which Forever's API documentation does not list (core functions are not there);
-- the command says so if it is missing. The client's own taint log (/console taintLog 1) is the full record.

BLib = BLib or {}
local T = {}
BLib.Taint = T

local secureAtLoad      -- name -> true: the globals that were Blizzard's when BLib loaded

local function Noting() return BLibDB and BLibDB.taintWatch end

function T.Snapshot()
    if type(issecurevariable) ~= "function" then return nil end
    secureAtLoad = {}
    for name in pairs(_G) do
        if type(name) == "string" then
            local ok, secure = pcall(issecurevariable, name)
            if ok and secure then secureAtLoad[name] = true end
        end
    end
    return secureAtLoad
end

-- { { name, by }, ... } sorted by addon then name: the globals that were secure at load and are not now.
function T.Census()
    if type(issecurevariable) ~= "function" then return nil, "this client has no issecurevariable" end
    if not secureAtLoad then return nil, "nothing was noted at login: /blib taint on, then /reload" end
    local list = {}
    for name in pairs(secureAtLoad) do
        local ok, secure, by = pcall(issecurevariable, name)
        if ok and not secure then list[#list + 1] = { name = name, by = tostring(by or "?") } end
    end
    table.sort(list, function(a, b) if a.by ~= b.by then return a.by < b.by end return a.name < b.name end)
    return list
end

function T.Slash(arg)
    local say = function(text) if BLib.Print then BLib.Print("BLib", text) else print("BLib: " .. text) end end
    arg = (arg or ""):lower()
    if arg == "on" or arg == "off" then
        BLibDB = BLibDB or {}
        BLibDB.taintWatch = arg == "on" or nil
        say(arg == "on" and "will note Blizzard's globals from the next login: /reload, play, then /blib taint."
            or "no longer noting.")
        return
    end
    local list, err = T.Census()
    if not list then say("no census: " .. tostring(err) .. ".") return end
    if #list == 0 then say("none of Blizzard's globals noted at login has been written by an addon since.") return end
    say(("%d of Blizzard's globals written by an addon since login:"):format(#list))
    for i = 1, math.min(#list, 40) do say(("  %s  by %s"):format(list[i].name, list[i].by)) end
    if #list > 40 then say(("  ... and %d more"):format(#list - 40)) end
end

-- At BLib's own load, before the addons that need it run, if noting is on. BLibDB is not read yet at file load
-- (saved variables arrive with ADDON_LOADED), so the note is taken then, which is still before BLib's dependants.
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, name)
    if name ~= "BLib" then return end
    self:UnregisterAllEvents()
    if Noting() then T.Snapshot() end
end)
