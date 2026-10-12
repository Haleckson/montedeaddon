-- Offline, sourced context. Never creates discoveries or changes guild payloads.
local _, FC = ...
local Lore = FC.DiscoveryLoreData
FC.DiscoveryLore = Lore

local function knownName(kind, name, entry, id)
    if not name or name == entry.name then return true end
    local rows = FC.Locale.content[kind] or {}
    for _, alias in ipairs(entry.aliases or {}) do
        if alias == name then return true end
        for _, value in ipairs(rows[alias] or {}) do if value == name then return true end end
    end
    local row = rows[id or entry.name]
    if row then
        for _, value in ipairs(row) do if value == name then return true end end
    end
    return false -- Respect renamed discoveries or a server's reused identifier.
end

function Lore:Get(rec)
    if not rec or rec.del then return nil end
    local entry
    if rec.t == "cave" then
        for _, candidate in pairs(self.caves or {}) do
            local onMap = false
            for _, map in ipairs(candidate.maps) do if map == rec.m then onMap = true; break end end
            if onMap and rec.n then
                local matches = knownName("place", rec.n, candidate)
                -- Older detectors used "Cave near <place>" in any supported
                -- language. Match the entire title, never an arbitrary substring.
                if not matches then
                    local names = {candidate.name}
                    for _, name in ipairs(FC.Locale.content.place[candidate.name] or {}) do names[#names+1] = name end
                    for _, alias in ipairs(candidate.aliases or {}) do
                        names[#names+1] = alias
                        for _, name in ipairs(FC.Locale.content.place[alias] or {}) do names[#names+1] = name end
                    end
                    -- Older Russian builds used this title before the localized
                    -- display templates were revised. Keep existing pins working.
                    for _, name in ipairs(names) do
                        if rec.n == "Пещера у " .. name then matches = true; break end
                    end
                    for _, strings in pairs(FC.Locale.tables) do
                        if strings.AUTO_CAVE_TITLE then
                            for _, name in ipairs(names) do
                                if rec.n == string.format(strings.AUTO_CAVE_TITLE, name) then matches = true; break end
                            end
                        end
                        if matches then break end
                    end
                end
                if matches then entry = candidate; break end
            end
        end
    elseif rec.t == "rare" then
        local id = tonumber(rec.npc)
        entry = self.rares[id]
        if entry and not knownName("npc", rec.n, entry, id) then return nil end
    elseif rec.t == "dungeon" or rec.t == "entrance" then
        local parent = rec.t == "entrance" and rec.pa and FC.Store:Get(rec.pa)
        if parent and (parent.t ~= "dungeon" or parent.del) then parent = nil end
        local id = tonumber(rec["in"] or (parent and parent["in"]))
        local name = rec.inn or (parent and (parent.inn or parent.n)) or (rec.t == "dungeon" and rec.n)
        entry = self.dungeons[id]
        if entry and not knownName("place", name, entry) then entry = nil end
        -- Reference-library IDs and GetInstanceInfo IDs are different namespaces.
        -- Names also allow known dungeons on builds that assign another map ID.
        if not entry and name then
            for _, candidate in pairs(self.dungeons) do
                if knownName("place", name, candidate) then entry = candidate; break end
            end
        end
    end
    if entry then return entry.texts[FC.Locale:Resolve(FC.Locale.active)] or entry.texts.enUS, entry end
end

function Lore:SpokenTitle(entry, rec)
    if rec.t == "rare" then return FC.Locale:ContentName("npc", entry.name, rec.npc) end
    return FC.Locale:Place(entry.name)
end

function Lore:SourceText(entry)
    local lines = {}
    for _, source in ipairs(entry and entry.sources or {}) do
        lines[#lines + 1] = source[1] .. "\n" .. source[2]
    end
    return table.concat(lines, "\n\n")
end
