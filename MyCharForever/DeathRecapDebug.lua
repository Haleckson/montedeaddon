local addonName, MCF = ...
-- v0.12.71: passive, bounded inspection of raw Death Recap event fields.
-- Do not open or populate Blizzard's Death Recap UI on the player's behalf.
-- Never increment death totals here.
local function Secret(v)
    if issecretvalue then
        local ok, result = pcall(issecretvalue, v)
        return not ok or result == true
    end
    return false
end
local function Log(stage, status, count, killer, marked, details)
    if MCF.AddDeathRecapDebug then
        MCF:AddDeathRecapDebug(stage, status, count or "?", killer or "-", marked or 0, details or "")
    end
end
local function SafeString(v)
    if Secret(v) then return "secret" end
    if v == nil then return "nil" end
    if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
        return tostring(v):sub(1,70)
    end
    return type(v)
end
local lastSignature, deathToken, hookedFrame, hookedMixin = nil, 0, nil, false
local function ScanProvider(provider)
    if not provider or Secret(provider) then return "no-provider", 0, nil, 0 end
    local count, rows, marked, killer, guid = "?", 0, 0, nil, nil
    if type(provider.GetSize) == "function" then
        local ok, value = pcall(provider.GetSize, provider)
        if ok and not Secret(value) then count = value end
    end
    local function Visit(d)
        if type(d) ~= "table" or Secret(d) then return end
        rows = rows + 1
        if not Secret(d.causedDeath) and d.causedDeath == true then
            marked = marked + 1
            if not Secret(d.sourceName) and type(d.sourceName) == "string" and d.sourceName ~= "" then
                killer = d.sourceName
                if not Secret(d.sourceGUID) then guid = d.sourceGUID end
            end
        end
    end
    local ok = false
    if type(provider.ForEach) == "function" then ok = pcall(provider.ForEach, provider, Visit) end
    if not ok then return "iteration-unavailable", count, nil, 0 end
    return "read", count, killer, marked, rows, guid
end
local function ReadVisibleRecap(stage)
    local ok, status, count, killer, marked, rows, guid = pcall(function()
        local f = DeathRecapFrame
        if not f or type(f.GetScrollBox) ~= "function" then return "no-frame" end
        local scroll = f:GetScrollBox()
        if not scroll or type(scroll.GetDataProvider) ~= "function" then return "no-scrollbox" end
        return ScanProvider(scroll:GetDataProvider())
    end)
    if not ok then Log(stage,"ui-error",nil,nil,nil,SafeString(status)); return end
    local sig = table.concat({status or "?",SafeString(count),SafeString(killer)},"|")
    if sig ~= lastSignature then
        lastSignature = sig
        Log(stage,status,count,killer,marked,"rows="..SafeString(rows))
    end
    -- Existing behavior retained for users who choose to open Death Recap.
    if killer and MCF.RecordDeathRecapKiller then
        if MCF:RecordDeathRecapKiller(killer,guid) then
            Log("saved","killer-recorded",count,killer,marked,"DeathRecap.causedDeath")
        end
    end
end
-- Read a small selection of raw fields. Each read is protected because the
-- Forever client may mark combat values as secret in some circumstances.
local function Field(d, key)
    local ok, value = pcall(function() return d[key] end)
    if not ok or Secret(value) then return "protected" end
    return SafeString(value)
end
local RAW_FIELDS = {
    "sourceName", "sourceGUID", "destName", "event", "amount",
    "causedDeath", "overkill", "currentHP", "timestamp", "spellID",
    "spellName", "isFatal", "killingBlow", "sourceFlags",
}
-- The raw API does not set causedDeath; the lethal event observed in
-- Forever has positive overkill. Require one unambiguous candidate, belonging
-- to the player's current death, rather than guessing from list order.
local function ScanRawEvents(events, inspect)
    if Secret(events) or type(events) ~= "table" then return "unexpected-"..SafeString(events),nil,0,0 end
    local count, marked, killer, guid = 0, 0, nil, nil
    local numeric, candidates = {}, {}
    for key, value in pairs(events) do
        if type(key) == "number" and type(value) == "table" and not Secret(value) then
            numeric[#numeric + 1] = { key = key, value = value }
        end
    end
    table.sort(numeric, function(a,b) return a.key < b.key end)
    local pending = MCF._pendingMobDeath
    for _, row in ipairs(numeric) do
        local d = row.value
        count = count + 1
        local ok, lethal, name, sourceGUID = pcall(function()
            local overkill = d.overkill
            local fatal = d.causedDeath == true or d.killingBlow == true or d.isFatal == true
            local damage = type(overkill) == "number" and not Secret(overkill) and overkill > 0
            local event = d.event
            local damageEvent = type(event) == "string" and (event:find("_DAMAGE",1,true) ~= nil or event == "ENVIRONMENTAL_DAMAGE")
            local ts = d.timestamp
            local recent = type(ts) == "number" and not Secret(ts) and pending
                and math.abs(ts - pending.time) <= 15
            local destGUID = d.destGUID
            local playerGUID = UnitGUID and UnitGUID("player")
            local destOK = (destGUID == nil or (not Secret(destGUID) and destGUID == playerGUID))
            if (fatal or (damage and damageEvent)) and recent and destOK then
                return true, d.sourceName, d.sourceGUID
            end
            return false
        end)
        if ok and lethal and not Secret(name) and type(name) == "string" and name ~= ""
            and not Secret(sourceGUID) then
            candidates[#candidates + 1] = {name=name,guid=sourceGUID}
        end
    end
    if #candidates == 1 then
        marked = 1
        killer, guid = candidates[1].name, candidates[1].guid
    end
    if inspect then
        Log("raw-schema", "keys", count, nil, marked, table.concat(RAW_FIELDS, ","))
        local picks = {}
        for i = 1, math.min(2,#numeric) do picks[#picks+1] = i end
        for i = math.max(3,#numeric-1),#numeric do
            if i >= 1 then picks[#picks+1] = i end
        end
        for _, i in ipairs(picks) do
            local row = numeric[i]
            local d = row.value
            local parts = {}
            for _, key in ipairs(RAW_FIELDS) do
                local value = Field(d,key)
                if value ~= "nil" then parts[#parts+1] = key.."="..value end
            end
            local output = table.concat(parts," ")
            if output == "" then
                local keys = {}
                pcall(function()
                    for key in pairs(d) do
                        if not Secret(key) then keys[#keys+1] = SafeString(key) end
                    end
                end)
                table.sort(keys)
                output = "availableKeys="..table.concat(keys,",")
            end
            Log("raw-"..SafeString(row.key),"fields",count,nil,0,output:sub(1,230))
            if #output > 230 then Log("raw-"..SafeString(row.key),"more",count,nil,0,output:sub(231,460)) end
        end
    end
    if #candidates > 1 then return "ambiguous-lethal",nil,count,#candidates,nil end
    if not pending then return "no-pending-death",nil,count,marked,nil end
    return "events",killer,count,marked,guid
end

local function DiagnoseDirect(stage, inspect)
    -- C_DeathRecap is distinct from C_DeathInfo (graveyard/respawn APIs).
    -- Probe only a documented/previously observed candidate getter; do not
    -- invoke arbitrary methods or try to reconstruct protected combat data.
    local api = C_DeathRecap
    if type(api) ~= "table" or Secret(api) then
        Log(stage,"no-C_DeathRecap",0,nil,0,"Death Recap API unavailable")
        return
    end
    local names = {}
    local okList = pcall(function()
        for k,v in pairs(api) do
            if type(k)=="string" and type(v)=="function" then names[#names+1]=k end
        end
    end)
    if not okList then Log(stage,"api-protected",0,nil,0,""); return end
    table.sort(names)
    Log(stage,"api-functions",#names,nil,0,table.concat(names,","):sub(1,240))
    local getter = api.GetRecapEvents
    if type(getter) ~= "function" then
        Log(stage,"no-GetRecapEvents",0,nil,0,"No direct getter found")
        return
    end
    local ok, events = pcall(getter)
    if not ok then Log(stage,"getter-error",0,nil,0,SafeString(events)); return end
    local status,killer,count,marked,guid = ScanRawEvents(events, inspect)
    Log(stage,status,count,killer,marked,"direct getter")
    if killer and MCF.RecordDeathRecapKiller then
        if MCF:RecordDeathRecapKiller(killer,guid) then
            Log("saved","direct-killer-recorded",count,killer,marked,"C_DeathRecap.GetRecapEvents (positive overkill/fatal)")
        end
    end
end
local function TryHook()
    local f = DeathRecapFrame
    if f and f ~= hookedFrame then
        hookedFrame = f
        if f.HookScript then
            pcall(f.HookScript,f,"OnShow",function()
                C_Timer.After(0.2,function() ReadVisibleRecap("frame-shown") end)
            end)
        end
        if hooksecurefunc and type(f.BuildDataProvider)=="function" then
            pcall(hooksecurefunc,f,"BuildDataProvider",function()
                C_Timer.After(0,function() ReadVisibleRecap("data-built") end)
            end)
        end
    end
    if not hookedMixin and hooksecurefunc and DeathRecapMixin and type(DeathRecapMixin.BuildDataProvider)=="function" then
        hookedMixin = pcall(hooksecurefunc,DeathRecapMixin,"BuildDataProvider",function()
            C_Timer.After(0,function() ReadVisibleRecap("mixin-data-built") end)
        end)
    end
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_DEAD")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent",function(_,event)
    if event == "PLAYER_DEAD" then
        deathToken = deathToken + 1
        local token = deathToken
        lastSignature = nil
        for _,delay in ipairs({0.5,1.5,3,6}) do
            C_Timer.After(delay,function()
                if token ~= deathToken then return end
                TryHook()
                DiagnoseDirect("death+"..delay, delay == 0.5)
                -- Deliberately no UI opening or BuildDataProvider invocation.
            end)
        end
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2,TryHook)
    else
        TryHook()
    end
end)
C_Timer.After(3,TryHook)
