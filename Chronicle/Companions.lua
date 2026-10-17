local C = _G.Chronicle
local frame = CreateFrame("Frame")
local activeGroupKeys = {}
local pendingInspect, inspectScheduled, lastInspect = nil, false, 0

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if ok then return a, b, c, d, e end
end

local function companions()
    if not C.db then return nil end
    C.db.companions = type(C.db.companions) == "table" and C.db.companions or {}
    return C.db.companions
end

local function observe(unit)
    local store = companions()
    if not store or not safeCall(UnitExists, unit) or not safeCall(UnitIsPlayer, unit) then return false end
    local guid = safeCall(UnitGUID, unit)
    local name, realm = safeCall(UnitName, unit)
    if type(name) ~= "string" or name == "" then return false end
    if guid and guid == safeCall(UnitGUID, "player") then return false end
    local key = type(guid) == "string" and guid ~= "" and guid or (name .. "-" .. (realm or ""))
    local fallbackKey = name .. "-" .. (realm or "")
    local row = store[key] or store[fallbackKey] or { firstSeen = time(), meetings = 0 }
    if key ~= fallbackKey and store[fallbackKey] then store[fallbackKey] = nil end
    local localizedClass, class = safeCall(UnitClass, unit)
    local guild = safeCall(GetGuildInfo, unit)
    local level = tonumber((safeCall(UnitLevel, unit)))
    row.name, row.realm, row.guid = name, realm or row.realm, guid or row.guid
    row.class, row.className = class or row.class, localizedClass or row.className
    if level and level > 0 then row.level = level end
    if type(guild) == "string" and guild ~= "" then row.guild = guild end
    local now = time()
    if not activeGroupKeys[key] and now - (tonumber(row.lastSeen) or 0) > 300 then
        row.meetings = (tonumber(row.meetings) or 0) + 1
    end
    row.lastSeen = now
    row.inGroup = true
    store[key] = row
    return key
end

local function inspectedTalents(unit)
    local snapshot = {}
    local getSpec = C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization or GetInspectSpecialization
    local specID = tonumber((safeCall(getSpec, unit)))
    if specID and specID > 0 then
        snapshot.specID = specID
        local getInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID or
            GetSpecializationInfoByID
        local _, name = safeCall(getInfo, specID)
        if type(name) == "string" and name ~= "" then snapshot.name = name end
    end
    if type(GetTalentTabInfo) == "function" then
        local branches = {}
        for index = 1, 3 do
            local _, name, _, _, points = safeCall(GetTalentTabInfo, index, true, false)
            if type(name) == "string" and name ~= "" and type(points) == "number" then
                branches[#branches + 1] = { name = name, points = points }
            end
        end
        if #branches == 3 then snapshot.branches = branches end
    end
    return (snapshot.name or snapshot.branches) and snapshot or nil
end

local function inspectNext()
    inspectScheduled = false
    if pendingInspect or not C.db or type(NotifyInspect) ~= "function" then return end
    if type(InCombatLockdown) == "function" and safeCall(InCombatLockdown) then return end
    if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then return end
    local now = time()
    if now - lastInspect < 8 then return end
    local raid = safeCall(IsInRaid)
    local prefix, maximum = raid and "raid" or "party", raid and 40 or 4
    local store = companions()
    for index = 1, maximum do
        local unit = prefix .. index
        local guid = safeCall(UnitGUID, unit)
        local row = guid and store[guid]
        if row and row.inGroup and now - (tonumber(row.talentsUpdated) or 0) > 900 and
            (type(CanInspect) ~= "function" or safeCall(CanInspect, unit)) then
            local ok = pcall(NotifyInspect, unit)
            if ok then
                pendingInspect = { guid = guid, unit = unit, started = now }
                lastInspect = now
                if C_Timer and C_Timer.After then
                    C_Timer.After(5, function()
                        if pendingInspect and pendingInspect.guid == guid and pendingInspect.started == now then
                            local row = companions()[guid]
                            if row then row.talentsUpdated = time() end
                            pendingInspect = nil
                            if C_Timer and C_Timer.After then C_Timer.After(3, inspectNext) end
                        end
                    end)
                end
            end
            return
        end
    end
end

local function scheduleInspect()
    if inspectScheduled or not C_Timer or not C_Timer.After then return end
    inspectScheduled = true
    C_Timer.After(3, inspectNext)
end

local function scanGroup()
    local store = companions()
    if not store then return end
    for _, row in pairs(store) do row.inGroup = false end
    local raid = safeCall(IsInRaid)
    local prefix, maximum = raid and "raid" or "party", raid and 40 or 4
    local found = false
    local present = {}
    for index = 1, maximum do
        local key = observe(prefix .. index)
        if key then found = true; present[key] = true end
    end
    activeGroupKeys = present
    if found or next(store) then C:Fire("DATA_CHANGED", "companions") end
    if found then scheduleInspect() end
end

local function updateFromGuild()
    local store = companions()
    if not store then return end
    local count = tonumber((safeCall(GetNumGuildMembers))) or 0
    local changed = false
    for index = 1, math.min(count, 1000) do
        local ok, name, rank, _, level, className, _, _, _, _, _, class, _, _, _, _, _, guid =
            pcall(GetGuildRosterInfo, index)
        if not ok then name = nil end
        if type(name) == "string" then
            local shortName = name:match("^[^-]+") or name
            for _, row in pairs(store) do
                if (guid and row.guid == guid) or (row.name == shortName and (not row.realm or name == shortName or name == row.name .. "-" .. row.realm)) then
                    if tonumber(level) and tonumber(level) > 0 then row.level = tonumber(level) end
                    row.guild = safeCall(GetGuildInfo, "player") or row.guild
                    row.guildRank = rank or row.guildRank
                    row.class = class or row.class
                    row.className = className or row.className
                    row.lastUpdated = time()
                    changed = true
                end
            end
        end
    end
    if changed then C:Fire("DATA_CHANGED", "companions") end
end

local function requestGuildRoster()
    if not safeCall(IsInGuild) then return end
    if C_GuildInfo and type(C_GuildInfo.GuildRoster) == "function" then
        safeCall(C_GuildInfo.GuildRoster)
    else
        safeCall(GuildRoster)
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_LEVEL")
frame:RegisterEvent("UNIT_NAME_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("INSPECT_READY")
frame:SetScript("OnEvent", function(_, event, unit)
    if event == "INSPECT_READY" then
        if pendingInspect and unit == pendingInspect.guid and
            safeCall(UnitGUID, pendingInspect.unit) == unit then
            local row = companions()[unit]
            if row then
                local talents = inspectedTalents(pendingInspect.unit)
                if talents then row.talents = talents end
                row.talentsUpdated = time()
                C:Fire("DATA_CHANGED", "companions")
            end
            pendingInspect = nil
            if C_Timer and C_Timer.After then C_Timer.After(8, inspectNext) end
        end
    elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
        updateFromGuild()
        if event == "PLAYER_GUILD_UPDATE" then requestGuildRoster() end
    elseif event == "UNIT_LEVEL" or event == "UNIT_NAME_UPDATE" then
        if type(unit) == "string" and (unit:match("^party%d+$") or unit:match("^raid%d+$")) then scanGroup() end
    else
        scanGroup()
        if C_Timer and C_Timer.After then C_Timer.After(2, requestGuildRoster) end
    end
end)

local sharedKinds = { dungeon = true, boss = true, quest = true, rare = true, death = true, zone = true, level = true }
C:On("CHRONICLE_EVENT_ADDED", function(entry)
    if type(entry) ~= "table" or not sharedKinds[entry.kind] then return end
    local store = companions()
    if not store then return end
    for key in pairs(activeGroupKeys) do
        local companion = store[key]
        if companion then
            companion.activities = type(companion.activities) == "table" and companion.activities or {}
            local recent = companion.activities[1]
            if not recent or recent.time ~= entry.time or recent.text ~= entry.text then
                C.Util.PushLimited(companion.activities,
                    { time = entry.time, kind = entry.kind, text = entry.text }, 40)
            end
        end
    end
end)
