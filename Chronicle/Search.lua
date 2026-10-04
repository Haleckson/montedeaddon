local C = _G.Chronicle
local U = C.Util

local function contains(value, query)
    return tostring(value or ""):lower():find(query, 1, true) ~= nil
end

local function add(results, kind, title, detail, timestamp)
    results[#results + 1] = { kind = C:LocalizeDisplay(kind), title = title,
        detail = C:LocalizeDisplay(detail or ""), time = timestamp or 0 }
end

function C:Search(query)
    query = U.Trim(query):lower()
    local results = {}
    if query == "" or not self.char then return results end
    for _, e in ipairs(self.char.events) do if contains(e.text, query) or contains(e.kind, query) then add(results, "Chronik", C:LocalizeEventText(e.text), e.kind, e.time) end end
    for _, g in ipairs(self.char.goals) do if contains(g.text, query) then add(results, "Ziel", C:LocalizeGoalText(g.text), g.done and "Erledigt" or "Offen", g.updated) end end
    for _, n in ipairs(self.char.notes) do if contains(n.text, query) or contains(n.category, query) then add(results, "Notiz", n.text, n.category, n.updated) end end
    for _, q in ipairs(self.char.quests) do if contains(q.title, query) then add(results, "Quest", q.title, q.status == "accepted" and "Angenommen" or "Abgeschlossen", q.time) end end
    for _, q in pairs(self.char.activeQuests or {}) do if contains(q.title, query) then add(results, "Quest", q.title, "Aktuell", 0) end end
    for name, z in pairs(self.char.zones) do if U.IsKnownZone(name) and contains(name, query) then add(results, "Gebiet", name, tostring(z.visits or 1) .. C:LocalizeDisplay(" Besuche"), z.lastSeen) end end
    for _, l in ipairs(self.char.loot) do if U.LootVisible(l) and (contains(l.name, query) or contains(l.link, query)) then add(results, "Beute", l.link or l.name, "x" .. tostring(l.quantity or 1), l.time) end end
    for name, n in pairs(self.char.npcs) do if U.IsWorldNPC(n) and contains(name, query) then add(results, n.merchant and "Haendler" or "NPC", name, n.zone or "", n.lastSeen) end end
    for name, r in pairs(self.char.rares) do if contains(name, query) then add(results, "Rare", name, r.zone or "", r.lastSeen) end end
    for name, p in pairs(self.char.professions) do if contains(name, query) then add(results, "Beruf", name, tostring(p.rank or 0) .. "/" .. tostring(p.maxRank or 0), p.lastSeen) end end
    for profession, recipes in pairs(self.char.recipes) do
        for _, recipe in pairs(recipes) do
            if contains(recipe.name, query) or contains(profession, query) then
                add(results, "Rezept", U.SafeText(recipe.name, "Rezept #" .. tostring(recipe.id)), profession, recipe.lastSeen)
            end
        end
    end
    for name, dungeon in pairs(self.char.dungeons) do
        if contains(name, query) or contains(dungeon.difficulty, query) then
            add(results, "Dungeon", name, tostring(dungeon.entries or 1) .. C:LocalizeDisplay(" Besuche | ") .. U.SafeText(dungeon.difficulty, ""), dungeon.lastSeen)
        end
    end
    for _, boss in pairs(self.char.bosses) do
        if contains(boss.name, query) then
            add(results, "Boss", U.SafeText(boss.name), tostring(boss.kills or 0) .. C:LocalizeDisplay(" Siege / ") .. tostring(boss.attempts or 0) .. C:LocalizeDisplay(" Versuche"), boss.lastSeen)
        end
        for _, item in ipairs(boss.loot or {}) do
            if contains(item.link, query) or contains(item.recipient, query) or contains(boss.name, query) then
                add(results, "Bossbeute", U.SafeText(item.link, "Gegenstand #" .. tostring(item.id or "?")),
                    U.SafeText(boss.name) .. " | " .. U.SafeText(item.recipient), item.time)
            end
        end
    end
    for _, death in ipairs(self.char.deaths) do
        if contains(death.zone, query) or contains(death.subZone, query) then
            add(results, "Tod", U.SafeText(death.zone), U.SafeText(death.subZone, ""), death.time)
        end
    end
    for _, entry in ipairs(self.char.economy) do
        if C.showSuspiciousMoney or not U.IsLogoutMoneyGlitch(self.char, entry) then
            local delta = tonumber(entry.delta) or 0
            local title = C:LocalizeDisplay("Goldaenderung ") .. (delta >= 0 and "+" or "-") .. U.Money(math.abs(delta))
            local detail = U.SafeText(entry.zone, "") .. C:LocalizeDisplay(" | Stand: ") .. U.Money(entry.balance)
            local plainTitle = "Goldaenderung " .. (delta >= 0 and "+" or "-") .. U.Money(math.abs(delta), true)
            local plainDetail = U.SafeText(entry.zone, "") .. " | Stand: " .. U.Money(entry.balance, true)
            if contains(plainTitle, query) or contains(plainDetail, query) then add(results, "Gold", title, detail, entry.time) end
        end
    end
    for key, alt in pairs(self.db and self.db.characters or {}) do
        local surname = U.Trim(alt.surname)
        local fullName = U.SafeText(alt.name, key) .. (surname ~= "" and " " .. surname or "")
        local title = fullName .. " - " .. U.SafeText(alt.realm, "")
        local talent = type(alt.talents) == "table" and alt.talents or nil
        local detail = C:LocalizeDisplay("Stufe ") .. tostring(alt.level or 0) .. " " .. U.SafeText(alt.className, alt.class or "") ..
            " | " .. U.SafeText(alt.zone, "") .. " | " .. U.SafeText(alt.guild, "") ..
            " | " .. (talent and U.SafeText(talent.name, talent.loadout or "") or "")
        if contains(title, query) or contains(detail, query) then add(results, "Charakter", title, detail, alt.lastSeen) end
        if talent and type(talent.learned) == "table" then
            for _, learned in ipairs(talent.learned) do
                if contains(learned.name, query) then
                    add(results, "Talent", U.SafeText(learned.name), fullName .. C:LocalizeDisplay(" | Rang ") .. tostring(learned.rank or 1),
                        talent.updated)
                end
            end
        end
    end
    for _, source in ipairs({ { label = "Inventar", items = self.char.inventory }, { label = "Bank", items = self.char.bank } }) do
        for _, item in pairs(source.items or {}) do
            local title = U.SafeText(item.link, "Gegenstand #" .. tostring(item.id or "?"))
            if contains(title, query) or contains(item.id, query) then
                add(results, source.label, title, "x" .. tostring(item.count or 1), 0)
            end
        end
    end
    table.sort(results, function(a, b) return a.time > b.time end)
    return results
end
