-- On-demand diagnostics only: no timer, event handler, or continuous polling.
SLASH_SBLPERF1 = "/sblperf"
SlashCmdList.SBLPERF = function(arg)
    local prefix = "|cff00ff00SpellbookLevels|r: "
    if not GetAddOnCPUUsage or not UpdateAddOnCPUUsage then
        print(prefix .. "Addon CPU profiling is unavailable on this client.")
        return
    end
    if not GetCVar or GetCVar("scriptProfile") ~= "1" then
        print(prefix .. "To measure addons: /console scriptProfile 1, then /reload. Use /sblperf reset, play for 60 seconds with windows closed, then /sblperf.")
        print(prefix .. "After measuring: /console scriptProfile 0, then /reload. Profiling itself adds overhead.")
        return
    end
    if (arg or ""):lower():match("^%s*reset%s*$") then
        if ResetCPUUsage then ResetCPUUsage() end
        print(prefix .. "CPU counters reset. Play for 60 seconds, then run /sblperf.")
        return
    end
    UpdateAddOnCPUUsage()
    local api = C_AddOns or {}
    local count = api.GetNumAddOns or GetNumAddOns
    local info = api.GetAddOnInfo or GetAddOnInfo
    if not count or not info then return end
    local rows = {}
    for i = 1, count() do
        local name = info(i)
        local cpu = GetAddOnCPUUsage(i) or 0
        if name and cpu > 0 then rows[#rows+1] = {name=name, cpu=cpu} end
    end
    table.sort(rows, function(a,b) return a.cpu > b.cpu end)
    print(prefix .. "Top addon CPU totals since the last reset (milliseconds; not FPS):")
    for i = 1, math.min(10, #rows) do
        print(string.format("%d. %s: %.1f ms", i, rows[i].name, rows[i].cpu))
    end
end
