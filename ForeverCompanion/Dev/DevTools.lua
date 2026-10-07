--[[
  Forever Companion - Dev/DevTools.lua
  Developer and QA commands. Everything here requires debug mode
  (/fc debug on), and all generated records carry the `dev` flag: they are
  never shared with the guild and /fc debug clearsample removes them.

    /fc debug on | off | level <1-5> | log [n]
    /fc debug generatedata <n>     random discoveries (scrolling, search, perf)
    /fc debug sample               a small hand-written sample journal
    /fc debug clearsample          remove all developer records
    /fc debug notification <type>  rare | recipe | secret | dungeon | guild | personal
    /fc debug guildmessage         simulate an incoming guild discovery
    /fc debug corruptentry         insert damaged entries and run the repair
    /fc debug perf                 time a full journal query
    /fc debug quests               the completed-quest scan and the quests waiting for a name
]]

local _, FC = ...

local DevTools = {}
FC.DevTools = DevTools

local U = FC.Utils
local L = FC.L
local Categories = FC.Categories

local AUTHORS = { "Gingasul", "Zugzug", "Dotcom", "Ragnar", "Harrydotter", "Mirelle", "Thandor" }
local ADJECTIVES = { "Forgotten", "Hidden", "Whispering", "Ancient", "Crooked", "Silent", "Burning", "Moonlit", "Drowned", "Hollow" }
local NOUNS = { "Watcher", "Grotto", "Trader", "Shrine", "Path", "Cache", "Warden", "Lantern", "Stair", "Idol" }
local TAGS = { "important", "rare-spawn", "weird", "come-back-later", "needs-testing", "raid-prep", "guild-event" }

local function realm()
    return (GetNormalizedRealmName and GetNormalizedRealmName()) or "Dev"
end

local function randomZone()
    local mapID = FC.Compat.GetPlayerMapID()
    local info = mapID and FC.Compat.GetMapInfo(mapID)
    local zones = info and info.parentMapID and FC.Compat.GetZoneChildren(info.parentMapID) or {}
    if #zones == 0 then return mapID or 1, (info and info.name) or "Unknown Zone" end
    local zone = zones[math.random(1, #zones)]
    return zone.mapID, zone.name
end

local function randomTitle()
    return "The " .. ADJECTIVES[math.random(#ADJECTIVES)] .. " " .. NOUNS[math.random(#NOUNS)]
end

function DevTools:Generate(count)
    count = U.Clamp(tonumber(count) or 100, 1, 5000)
    local store = FC.Store
    local now = U.Now()
    local started = debugprofilestop and debugprofilestop() or 0
    for i = 1, count do
        local t = Categories.order[math.random(1, #Categories.order)]
        local mapID, zoneName = randomZone()
        local author = (math.random() < 0.35 and store.me) or (AUTHORS[math.random(#AUTHORS)] .. "-" .. realm())
        local rec = {
            id = "dev:" .. U.ToBase36(now) .. ":" .. i .. ":" .. U.RandomToken(3),
            t = t, n = randomTitle(), d = (math.random() < 0.6) and "Generated test entry. Lorem ipsum dolor sit amet, exploration notes and hints." or nil,
            m = mapID, x = math.random(50, 950) / 1000, y = math.random(50, 950) / 1000, z = zoneName,
            a = author, c = now - math.random(0, 30 * 86400), r = 1, v = (math.random() < 0.85) and "g" or "p",
            tg = (math.random() < 0.4) and { TAGS[math.random(#TAGS)] } or nil,
            dev = true,
        }
        rec.u = rec.c
        if math.random() < 0.3 then
            rec.ver = {}
            for j = 1, math.random(1, 3) do rec.ver[AUTHORS[j] .. "-" .. realm()] = rec.c + j * 600 end
        end
        if t == "rare" then
            rec.npc = 900000 + i
            rec.obs = { d = { now - 7200, now - 3600 }, s = { now - 5820, now - 2280 } }
        elseif t == "vendor" then
            rec.npc = 910000 + i
            rec.inv = { { i = 2589, n = "Linen Cloth" }, { i = 159, n = "Refreshing Spring Water", l = 5 }, { i = 2881, n = "Plans: Runed Copper Breastplate", rc = true, q = 2 } }
        elseif t == "recipe" then
            rec.pr = Categories.PROFESSIONS[math.random(1, #Categories.PROFESSIONS - 1)].key
            rec.sk = math.random(1, 30) * 10
        end
        store:Upsert(rec, "dev")
        if author == store.me or math.random() < 0.2 then store:MarkSeen(rec.id, rec.c, true) end
        if math.random() < 0.08 then store:SetFavorite(rec.id, true) end
    end
    store:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    local elapsed = debugprofilestop and (debugprofilestop() - started) or 0
    FC:Print("Generated %d developer discoveries in %.0f ms.", count, elapsed)
end

function DevTools:Sample()
    local store = FC.Store
    local now = U.Now()
    local mapID, zoneName = randomZone()
    local r = realm()
    local samples = {
        { t = "rare", n = "The Forgotten Watcher", a = "Gingasul-" .. r, x = 0.424, y = 0.681, npc = 990001, d = "Patrols the ridge above the old ruins.", tg = { "rare-spawn" } },
        { t = "vendor", n = "Mysterious Trader", a = "Zugzug-" .. r, x = 0.612, y = 0.228, npc = 990002, d = "Only appears at night.",
          inv = { { i = 2881, n = "Recipe: ???", rc = true, l = 1, q = 2 }, { i = 159, n = "Refreshing Spring Water" } } },
        { t = "cave", n = "Hidden cave behind the waterfall", a = "Dotcom-" .. r, x = 0.335, y = 0.512, d = "Walk along the left ledge, the entrance is behind the falling water.", tg = { "secret", "weird" } },
        { t = "room", n = "Hidden door in the western corridor", a = "Dotcom-" .. r, x = 0.5, y = 0.5, d = "Requires clicking the torch first.", ver = { ["Ragnar-" .. r] = now - 3000, ["Harrydotter-" .. r] = now - 2000 } },
        { t = "recipe", n = "Recipe: Elixir of Shadows", a = "Harrydotter-" .. r, x = 0.71, y = 0.44, pr = "alchemy", sk = 165, src = "Mysterious Trader" },
        { t = "note", n = "Good herb loop starts here", a = store.me, x = 0.2, y = 0.3, v = "p", tg = { "come-back-later" } },
    }
    for i, s in ipairs(samples) do
        s.id = "dev:sample:" .. i
        s.m, s.z = mapID, zoneName
        s.c = now - i * 1800
        s.u, s.r, s.v, s.dev = s.c, 1, s.v or "g", true
        store:Upsert(s, "dev")
    end
    store:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    FC:Print("Loaded %d sample discoveries in %s.", #samples, zoneName)
end

function DevTools:ClearSample()
    local removed = FC.Store:RemoveWhere(function(rec) return rec.dev == true end)
    FC:Print("Removed %d developer discoveries.", removed)
end

function DevTools:SimulateGuildMessage()
    local sender = "Gingasul-" .. realm()
    local mapID, zoneName = randomZone()
    local rec = {
        id = "dev:guild:" .. U.ToBase36(U.Now()), t = "rare", n = randomTitle(), a = sender,
        m = mapID, z = zoneName, x = 0.42, y = 0.67, c = U.Now(), u = U.Now(), r = 1, v = "g", dev = true, npc = 995000 + math.random(1, 999),
    }
    local data = FC.Serializer:Serialize({ rec = rec })
    local frame = FC.C.PROTOCOL .. "N" .. "zz1" .. ":1/1:" .. data
    if #frame > 255 then
        FC:Print("Simulated message is %d bytes (multi-part); sending as chunks.", #frame)
        local size = FC.C.SYNC.CHUNK_DATA
        local total = math.ceil(#data / size)
        for seq = 1, total do
            FC.Comm:Receive(FC.C.PROTOCOL .. "Nzz2:" .. seq .. "/" .. total .. ":" .. data:sub((seq - 1) * size + 1, seq * size), "GUILD", sender)
        end
    else
        FC.Comm:Receive(frame, "GUILD", sender)
    end
    FC:Print("Simulated guild discovery from %s.", sender)
end

function DevTools:CorruptEntry()
    local db = FC.db.discoveries
    db["dev:corrupt:1"] = { id = "dev:corrupt:1", t = "rare", n = 12345 }
    db["dev:corrupt:2"] = "not a table"
    db["dev:corrupt:3"] = { id = "wrong-id", t = "rare", n = "Mismatched", a = "X", c = 1, u = 1, r = 1 }
    db["dev:corrupt:4"] = { id = "dev:corrupt:4", t = "rare", n = "Bad coords", a = "X-" .. realm(), c = 1, u = 1, r = 1, x = 7, y = -2, dev = true }
    local removed = FC.Store:ValidateAll()
    FC.Store:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    FC:Print("Inserted 4 damaged entries; the validator removed %d and repaired the rest (bad coordinates dropped).", removed)
end

function DevTools:Perf()
    if not debugprofilestop then return end
    local started = debugprofilestop()
    local results = FC.Query:Run({ sort = "recent" }, "")
    local fullTime = debugprofilestop() - started
    started = debugprofilestop()
    local search = FC.Query:Run({ sort = "name" }, "the hidden")
    local searchTime = debugprofilestop() - started
    FC:Print("Query: %d records in %.1f ms; search: %d matches in %.1f ms.", #results, fullTime, #search, searchTime)
end

--- Handles "/fc debug ..." (returns true if handled).
function DevTools:Command(args)
    local sub, rest = args:match("^(%S*)%s*(.-)$")
    sub = (sub or ""):lower()
    local P = FC.P
    if sub == "" or sub == "toggle" then
        FC.Config:Set("debug.enabled", not P.debug.enabled)
        FC:Print(P.debug.enabled and L.MSG_DEBUG_ON or L.MSG_DEBUG_OFF)
        return true
    elseif sub == "on" or sub == "off" then
        FC.Config:Set("debug.enabled", sub == "on")
        FC:Print(sub == "on" and L.MSG_DEBUG_ON or L.MSG_DEBUG_OFF)
        return true
    elseif sub == "level" then
        FC.Config:Set("debug.level", U.Clamp(tonumber(rest) or 4, 1, 5))
        FC:Print("Debug level: %s", FC.Log.NAMES[P.debug.level])
        return true
    elseif sub == "log" then
        FC.Log:Dump(tonumber(rest) or 30)
        return true
    end
    if not P.debug.enabled then
        FC:Print(L.MSG_DEBUG_REQUIRED)
        return true
    end
    if sub == "generatedata" or sub == "generate" then
        self:Generate(rest)
    elseif sub == "sample" then
        self:Sample()
    elseif sub == "clearsample" or sub == "clear" then
        self:ClearSample()
    elseif sub == "notification" or sub == "notify" then
        FC.Notifications:Test(rest ~= "" and rest or "rare")
    elseif sub == "guildmessage" then
        self:SimulateGuildMessage()
    elseif sub == "corruptentry" then
        self:CorruptEntry()
    elseif sub == "perf" then
        self:Perf()
    elseif sub == "quests" then
        -- the state of the completed-quest scan and of the name queue, for bug reports
        FC:Print("Completed quests:")
        for _, line in ipairs(FC.QuestHistory:Diagnose()) do DEFAULT_CHAT_FRAME:AddMessage("  " .. line) end
    else
        FC:Print("Debug commands: on, off, level <1-5>, log [n], generatedata <n>, sample, clearsample, notification <type>, guildmessage, corruptentry, perf, quests")
    end
    return true
end
