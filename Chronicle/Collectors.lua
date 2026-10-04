local C = _G.Chronicle
local U = C.Util
local A = C.API
local frame = CreateFrame("Frame")

local events = {
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_LEVEL_UP",
    "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_MONEY",
    "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "MERCHANT_SHOW", "UPDATE_MOUSEOVER_UNIT",
    "PLAYER_TARGET_CHANGED", "NAME_PLATE_UNIT_ADDED",
    "PLAYER_ENTERING_WORLD", "ENCOUNTER_END", "ENCOUNTER_LOOT_RECEIVED", "CHAT_MSG_LOOT", "SKILL_LINES_CHANGED",
    "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE", "PLAYER_TALENT_UPDATE",
    "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "TRAIT_CONFIG_UPDATED",
    "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "TRADE_SKILL_CLOSE",
}
for _, event in ipairs(events) do pcall(frame.RegisterEvent, frame, event) end

local function zoneName()
    return U.SafeText(GetZoneText and GetZoneText(), "Unbekannt")
end

local deathObserved = false
local function observePlayerDamage()
    if not C.char or type(CombatLogGetCurrentEventInfo) ~= "function" then return end
    local _, kind, _, _, sourceName, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15, arg16 = CombatLogGetCurrentEventInfo()
    C:ObserveDeathCombat(kind, sourceName, destGUID, arg12, arg13, arg14, arg15, arg16)
end
local function recordDeath(fromDeathEvent)
    -- PLAYER_DEAD is authoritative even if a missed resurrection event left
    -- the health-event guard set from an earlier death.
    if not C.char or (deathObserved and not fromDeathEvent) then return end
    local now = time()
    local latest = C.char.deaths and C.char.deaths[1]
    -- A reload while dead must not turn the same death into a second entry.
    if latest and type(latest.time) == "number" and now - latest.time < 10 then
        deathObserved = true
        return
    end
    deathObserved = true
    local row = { time = now, zone = zoneName(), subZone = GetSubZoneText and GetSubZoneText() or "", instance = A.InstanceInfo() }
    local combat = C:ConsumeDeathCombat(now)
    if combat then
        row.killer = combat.killer
        row.cause = combat.cause
        row.damage = combat.damage
        row.spellID = combat.spellID
        row.combatLog = combat.combatLog
    end
    U.PushLimited(C.char.deaths, row, 250)
    C.char.stats.deathCount = (C.char.stats.deathCount or 0) + 1
    C:AddEvent("death", "Gestorben in " .. row.zone)
    C:UpdateCharacterSummary()
end

local talentScanQueued
local moneyPollSerial = 0
local function startMoneyPolling()
    if not (C_Timer and C_Timer.After) then return end
    moneyPollSerial = moneyPollSerial + 1
    local serial = moneyPollSerial
    local function poll()
        if serial ~= moneyPollSerial then return end
        if C.char and C.moneyReady then C:SyncMoney(true, true) end
        C_Timer.After(5, poll)
    end
    C_Timer.After(5, poll)
end

local function queueTalentScan()
    if talentScanQueued then return end
    talentScanQueued = true
    local function scan()
        talentScanQueued = nil
        if C.char then C:RefreshTalentSnapshot() end
    end
    if C_Timer and C_Timer.After then C_Timer.After(1, scan) else scan() end
end

function C:SyncMoney(recordChange, notify)
    if not self.char or type(GetMoney) ~= "function" then return nil end
    local ok, current = pcall(GetMoney)
    if not ok or type(current) ~= "number" or current < 0 then return nil end
    local previous = tonumber(self.char.money)
    if previous == current then return current end
    if recordChange and self.moneyReady and previous and previous > 0 and current == 0 then
        local now = time()
        if not self.pendingZeroMoneyAt then self.pendingZeroMoneyAt = now end
        if now - self.pendingZeroMoneyAt < 2 then return previous end
    else
        self.pendingZeroMoneyAt = nil
    end
    if recordChange and self.moneyReady and previous then
        U.PushLimited(self.char.economy, {
            time = time(), delta = current - previous, balance = current, zone = zoneName(),
        }, self.db.settings.maxEconomy or 500)
    end
    self.char.money = current
    self:UpdateCharacterSummary()
    if notify then self:Fire("DATA_CHANGED", "money") end
    return current
end

function C:FinalizeLogin(isReloadingUi)
    if not self.pendingLogin or not self.char then return end
    self.pendingLogin = nil
    if isReloadingUi then
        local previous = self.char.lastLogoutBeforeUIReload
        local logout = self.char.lastLogout
        if type(previous) == "number" and type(logout) == "number" and
            logout > 0 and time() - logout < 120 then
            self.char.lastLogout = previous
        end
        self:Fire("DATA_CHANGED", "session")
        return
    end
    local previous = self.char.lastLogout
    self.char.lastSessionEnd = previous
    self.char.lastLogin = time()
    self.char.lastLogoutBeforeUIReload = nil
    local zone = zoneName()
    self:AddEvent("login", zone == "Unbekannt" and "Abenteuer fortgesetzt" or
        ("Abenteuer fortgesetzt in " .. zone), { awaySince = previous })
    if self.db.settings.showWelcome and self.ShowWelcome then self:ShowWelcome(previous) end
end

local function recordInstance(isReloadingUi)
    if not C.char then return end
    local info = A.InstanceInfo()
    if not info or (info.instanceType ~= "party" and info.instanceType ~= "raid") or
        type(info.name) ~= "string" or info.name == "" then
        C.currentInstanceKey = nil
        return
    end
    local key = tostring(info.id or info.name) .. ":" .. tostring(info.difficultyID or 0)
    C.char.lastInstance = info.name
    if C.currentInstanceKey == key then return end
    C.currentInstanceKey = key
    local now = time()
    local row = C.char.dungeons[info.name] or { entries = 0, firstSeen = now }
    -- Forever kann PLAYER_ENTERING_WORLD auch bei einem UI-Reload auslösen.
    if isReloadingUi or (row.lastSeen and now - row.lastSeen < 30) then return end
    row.entries = (row.entries or 0) + 1
    row.lastSeen, row.difficulty, row.instanceID = now, info.difficulty, info.id
    C.char.dungeons[info.name] = row
    C:AddEvent("dungeon", "Instanz betreten: " .. info.name)
end

local function recordBossLoot(boss, itemID, itemLink, quantity, recipient, source)
    if not C.char or not boss or type(itemLink) ~= "string" or not itemLink:find("|Hitem:", 1, true) then return end
    if type(recipient) ~= "string" or recipient == "" then return end
    local now = time()
    boss.loot = type(boss.loot) == "table" and boss.loot or {}
    local recipientKey = recipient:match("^[^-]+") or recipient
    for _, item in ipairs(boss.loot) do
        if item.id == itemID and (tostring(item.recipient or ""):match("^[^-]+") or item.recipient) == recipientKey and
            now - (item.time or 0) < ((source == "inventory" or item.source == "inventory") and 90 or 5) then return end
    end
    local icon
    if itemID and C_Item and C_Item.GetItemIconByID then
        local ok, value = pcall(C_Item.GetItemIconByID, itemID)
        if ok then icon = value end
    end
    if (not icon or icon == 0) and itemID and GetItemIcon then
        local ok, value = pcall(GetItemIcon, itemID)
        if ok then icon = value end
    end
    table.insert(boss.loot, 1, { id = itemID, link = itemLink, icon = icon,
        count = tonumber(quantity) or 1, recipient = recipient, time = now, source = source or "event" })
    while #boss.loot > 100 do table.remove(boss.loot) end
    C:Fire("DATA_CHANGED", "bossloot")
end

local function recentDefeatedBoss()
    if not C.char then return nil end
    local info = A.InstanceInfo()
    if not info or (info.instanceType ~= "party" and info.instanceType ~= "raid") then return nil end
    local latest, latestTime
    for _, boss in pairs(C.char.bosses or {}) do
        if (boss.kills or 0) > 0 and boss.lastSuccess and time() - boss.lastSuccess <= 150 and
            (not latestTime or boss.lastSuccess > latestTime) then
            latest, latestTime = boss, boss.lastSuccess
        end
    end
    return latest
end

local function normalizedInstanceName(value)
    return tostring(value or ""):lower():gsub("^die ", ""):gsub("^der ", ""):gsub("^das ", "")
end

local function reconstructBossLoot()
    if not C.char then return end
    local recovered = 0
    for _, loot in ipairs(C.char.loot or {}) do
        local lootTime = tonumber(loot.time)
        if lootTime and (tonumber(loot.quality) or 0) >= 3 and type(loot.link) == "string" and
            loot.link:find("|Hitem:", 1, true) then
            local nearest, nearestGap
            for _, boss in pairs(C.char.bosses or {}) do
                local gap = lootTime - (tonumber(boss.lastSuccess) or 0)
                if (tonumber(boss.kills) or 0) > 0 and gap >= -10 and gap <= 150 and
                    normalizedInstanceName(boss.instanceName or boss.zone) == normalizedInstanceName(loot.zone) and
                    (not nearestGap or math.abs(gap) < nearestGap) then
                    nearest, nearestGap = boss, math.abs(gap)
                end
            end
            if nearest then
                nearest.loot = type(nearest.loot) == "table" and nearest.loot or {}
                local exists = false
                for _, item in ipairs(nearest.loot) do
                    if tonumber(item.id) == tonumber(loot.id) and
                        math.abs((tonumber(item.time) or 0) - lootTime) <= 150 then exists = true; break end
                end
                if not exists then
                    table.insert(nearest.loot, 1, { id = loot.id, link = loot.link,
                        count = tonumber(loot.quantity) or 1, recipient = UnitName("player") or "Unbekannt",
                        time = lootTime, source = "reconstructed" })
                    recovered = recovered + 1
                end
            end
        end
    end
    if recovered > 0 then C:Fire("DATA_CHANGED", "bossloot") end
end

local function scanBags(destination, firstBag, lastBag)
    if not C.char or not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return false end
    local availableSlots = 0
    for bag = firstBag, lastBag do
        if destination ~= "bank" or bag == -1 or bag >= 5 then
            availableSlots = availableSlots + A.ContainerSlots(bag)
        end
    end
    if availableSlots == 0 then return false end
    local snapshot = {}
    for bag = firstBag, lastBag do
        if destination ~= "bank" or bag == -1 or bag >= 5 then
            for slot = 1, A.ContainerSlots(bag) do
                local info = A.ContainerItemInfo(bag, slot)
                if info and info.itemID then
                    local key = tostring(info.itemID)
                    local questInfo = A.ContainerQuestInfo(bag, slot)
                    local row = snapshot[key] or { id = info.itemID, link = info.hyperlink, count = 0 }
                    row.count = row.count + (info.stackCount or 1)
                    row.quality = tonumber(info.quality) or row.quality
                    row.sellPrice = A.ItemSellPrice(info.itemID) or row.sellPrice
                    row.isQuestItem = (questInfo and questInfo.isQuestItem) or row.isQuestItem or false
                    row.questID = (questInfo and questInfo.questID) or row.questID
                    snapshot[key] = row
                end
            end
        end
    end
    if destination == "inventory" then
        local previous = C.inventoryBaseline
        if previous and not C.bankOpen then
            for key, row in pairs(snapshot) do
                local old = previous[key]
                local gained = row.count - (old and old.count or 0)
                if gained > 0 then
                    local name = row.link and row.link:match("|h%[([^%]]+)%]|h") or ("Gegenstand #" .. key)
                    U.PushLimited(C.char.loot, {
                        time = time(), link = row.link, name = name, id = row.id,
                        quantity = gained, zone = zoneName(), source = "inventory",
                        quality = row.quality, isQuestItem = row.isQuestItem, questID = row.questID,
                        sellPrice = row.sellPrice,
                    }, C.db.settings.maxLoot or 400)
                    if (tonumber(row.quality) or 0) >= 2 and type(row.link) == "string" then
                        local boss = recentDefeatedBoss()
                        if boss and boss.zone == zoneName() then
                            recordBossLoot(boss, row.id, row.link, gained, UnitName("player"), "inventory")
                        end
                    end
                end
            end
        end
        C.inventoryBaseline = snapshot
    end
    local stored = C.char[destination] or {}
    local changed = false
    for key, row in pairs(snapshot) do
        local old = stored[key]
        if not old or old.count ~= row.count or old.link ~= row.link or
            old.quality ~= row.quality or old.sellPrice ~= row.sellPrice or
            old.isQuestItem ~= row.isQuestItem or old.questID ~= row.questID then
            changed = true
            break
        end
    end
    if not changed then
        for key in pairs(stored) do
            if not snapshot[key] then changed = true; break end
        end
    end
    if changed then
        C.char[destination] = snapshot
        C.char.stats[destination .. "Updated"] = time()
    end
    return true, changed
end

local function recordZone()
    local zone = zoneName()
    if zone == "Unbekannt" then return end
    local sub = GetSubZoneText and GetSubZoneText() or ""
    local firstVisit = C.char.zones[zone] == nil
    local row = C.char.zones[zone] or { firstSeen = time(), visits = 0 }
    if firstVisit or C.char.lastZone ~= zone then row.visits = (row.visits or 0) + 1 end
    row.lastSeen, row.lastSubZone = time(), sub
    C.char.zones[zone] = row
    if firstVisit then C:AddEvent("zone", "Gebiet entdeckt: " .. zone, { subZone = sub }) end
    C.char.lastZone, C.char.lastSubZone = zone, sub
end

local function recordNPC(unit, merchant)
    if not UnitExists(unit) or UnitIsPlayer(unit) then return end
    local name, guid = UnitName(unit), UnitGUID(unit)
    if not name or (type(guid) == "string" and guid:match("^Pet%-")) then return end
    local location = zoneName()
    local sightingKey = guid or (name .. "@" .. location)
    C.seenNPCs = C.seenNPCs or {}
    C.seenRares = C.seenRares or {}
    local row = C.char.npcs[name] or { firstSeen = time(), encounters = 0 }
    row.lastSeen, row.zone, row.guid = time(), location, guid
    row.npcID, row.merchant = U.UnitGUIDID(guid), merchant or row.merchant
    local classification = UnitClassification and UnitClassification(unit)
    row.classification = classification or row.classification
    if not C.seenNPCs[sightingKey] then
        row.encounters = (row.encounters or 0) + 1
        C.seenNPCs[sightingKey] = true
    end
    C.char.npcs[name] = row
    if classification == "rare" or classification == "rareelite" then
        local firstSighting = C.char.rares[name] == nil
        local rare = C.char.rares[name] or { firstSeen = time(), sightings = 0 }
        rare.lastSeen, rare.zone, rare.npcID = time(), row.zone, row.npcID
        rare.classification = classification
        local newSighting = not C.seenRares[sightingKey]
        if newSighting then
            rare.sightings = (rare.sightings or 0) + 1
            C.seenRares[sightingKey] = true
        end
        C.char.rares[name] = rare
        if firstSighting then C:AddEvent("rare", "Seltene Kreatur entdeckt: " .. name, { zone = row.zone, npcID = row.npcID }) end
        if newSighting and not firstSighting then C:Fire("DATA_CHANGED", "rare") end
    end
end

local function scanProfessions()
    local changes = {}
    if not C.char or not GetProfessions or not GetProfessionInfo then return changes end
    local ok, p1, p2, archaeology, fishing, cooking = pcall(GetProfessions)
    if not ok then return changes end
    local indices = { p1, p2, archaeology, fishing, cooking }
    for i = 1, 5 do
        local index = indices[i]
        if index then
            local infoOK, name, icon, rank, maxRank, numSpells, spellOffset, skillLine = pcall(GetProfessionInfo, index)
            if infoOK and name then
                local previous = C.char.professions[name]
                if previous and (previous.rank ~= rank or previous.maxRank ~= maxRank) then
                    changes[#changes + 1] = name .. ": " .. tostring(rank or 0) .. "/" .. tostring(maxRank or 0)
                end
                C.char.professions[name] = { rank = rank, maxRank = maxRank, icon = icon, skillLine = skillLine, numSpells = numSpells, spellOffset = spellOffset, lastSeen = time() }
            end
        end
    end
    return changes
end

local function scanRecipes()
    if not C.char or not C.tradeSkillOpen then return end
    local snapshot = A.KnownRecipes()
    if not snapshot then return end
    local known = C.char.recipes[snapshot.profession] or {}
    local hadRecipes = next(known) ~= nil
    local added = 0
    for id, recipe in pairs(snapshot.recipes) do
        if not known[id] then
            known[id] = { id = recipe.id, name = recipe.name, icon = recipe.icon, firstSeen = time(), lastSeen = time() }
            added = added + 1
        else
            known[id].name, known[id].icon, known[id].lastSeen = recipe.name, recipe.icon, time()
        end
    end
    C.char.recipes[snapshot.profession] = known
    if added > 0 then
        if hadRecipes then C:AddEvent("recipe", "Neue Rezepte erfasst: " .. snapshot.profession .. " (" .. added .. ")")
        else C:Fire("DATA_CHANGED", "recipes") end
    end
end

local recipeScanPending = false
local function queueRecipeScan()
    if C_Timer and C_Timer.After then
        if recipeScanPending then return end
        recipeScanPending = true
        C_Timer.After(.3, function()
            recipeScanPending = false
            scanRecipes()
        end)
    else
        scanRecipes()
    end
end

local function scanActiveQuests(recordNew)
    if not C.char then return end
    local current = A.ActiveQuests()
    if not current then return end
    local previous = C.activeQuestBaseline
    local changed = previous == nil
    if previous then
        for id, quest in pairs(current) do
            local old = previous[id]
            if not old or old.title ~= quest.title or old.level ~= quest.level then changed = true; break end
        end
        if not changed then for id in pairs(previous) do if not current[id] then changed = true; break end end end
    end
    if not changed then return end
    C.activeQuestBaseline = current
    C.char.activeQuests = current
    if recordNew and previous then
        for id, quest in pairs(current) do
            if not previous[id] then
                U.PushLimited(C.char.quests, {
                    time = time(), id = quest.id, title = quest.title,
                    status = "accepted", zone = zoneName(), level = quest.level,
                }, C.db.settings.maxQuests or 500)
                C:AddEvent("quest", "Quest angenommen: " .. quest.title, { questID = quest.id })
            end
        end
    end
    C:Fire("DATA_CHANGED", "quests")
end

local questScanPending = false
local function queueQuestScan(recordNew)
    if C_Timer and C_Timer.After then
        if questScanPending then return end
        questScanPending = true
        C_Timer.After(.25, function()
            questScanPending = false
            scanActiveQuests(recordNew)
        end)
    else
        scanActiveQuests(recordNew)
    end
end

local function eventHandler(_, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon ~= C.name then return end
        C:InitializeAccountDatabase()
        C:Fire("DATABASE_READY")
        return
    end

    if not C.char and not C:BindCharacterDatabase() then return end
    if event == "PLAYER_LOGIN" then
        C:BindCharacterDatabase()
        if not C.char then C:Print("Charakterdaten konnten beim Login nicht gebunden werden."); return end
        recentDamage = nil
        C.moneyReady = nil
        deathObserved = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") or false
        C.pendingZeroMoneyAt = nil
        C:SyncMoney(false, false)
        startMoneyPolling()
        C.pendingLogin = true
        C.inventoryBaseline = nil
        C.seenNPCs, C.seenRares = {}, {}
        recordZone(); C:UpdateCharacterSummary(); scanBags("inventory", 0, 4); scanProfessions(); scanActiveQuests(false)
        reconstructBossLoot()
        queueTalentScan()
    elseif event == "PLAYER_LOGOUT" then
        moneyPollSerial = moneyPollSerial + 1
        if C.char then
            C.char.lastLogoutBeforeUIReload = C.char.lastLogout
            C.char.lastLogout = time()
            local summary = C.db and C.db.characters and C.db.characters[C.characterKey]
            if summary then
                summary.lastSeen = C.char.lastLogout
                summary.money = C.char.money
            end
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...; C:AddEvent("level", "Stufe " .. tostring(level) .. " erreicht"); C:UpdateCharacterSummary()
        C:Fire("CHARACTER_LEVEL_UP", level)
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        recordZone(); C:UpdateCharacterSummary()
    elseif event == "PLAYER_MONEY" then
        C:SyncMoney(true, true)
    elseif event == "PLAYER_GUILD_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        if event == "PLAYER_GUILD_UPDATE" and IsInGuild and not IsInGuild() then
            local summary = C.db.characters[C.characterKey]
            if summary then summary.guild, summary.guildRank = nil, nil end
        else
            C:UpdateCharacterSummary()
        end
        C:Fire("DATA_CHANGED", "guild")
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" or
        event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        queueTalentScan()
    elseif event == "PLAYER_DEAD" then
        recordDeath(true)
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        C:ResetDeathCombat()
        deathObserved = false
    elseif event == "QUEST_TURNED_IN" then
        local questID, xp, money = ...; local title = A.QuestTitle(questID)
        U.PushLimited(C.char.quests, { time = time(), id = questID, title = title, status = "completed", xp = xp, money = money, zone = zoneName() }, C.db.settings.maxQuests)
        if questID then
            C.char.activeQuests[tostring(questID)] = nil
            if C.activeQuestBaseline then C.activeQuestBaseline[tostring(questID)] = nil end
        end
        C:AddEvent("quest", "Quest abgeschlossen: " .. title, { questID = questID })
    elseif event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" then
        queueQuestScan(true)
    elseif event == "BAG_UPDATE_DELAYED" then
        local oldCount = #C.char.loot
        local _, inventoryChanged = scanBags("inventory", 0, 4)
        if C.moneyReady then C:SyncMoney(true, false) end
        if inventoryChanged or #C.char.loot > oldCount then
            C:Fire("DATA_CHANGED", #C.char.loot > oldCount and "loot" or "inventory")
        end
    elseif event == "BANKFRAME_OPENED" then
        C.bankOpen = true
        local function scanOpenedBank()
            if C.bankOpen then
                local _, bankChanged = scanBags("bank", -1, 12)
                if bankChanged then C:Fire("DATA_CHANGED", "bank") end
            end
        end
        if C_Timer and C_Timer.After then C_Timer.After(.3, scanOpenedBank) else scanOpenedBank() end
    elseif event == "BANKFRAME_CLOSED" then C.bankOpen = nil
    elseif event == "MERCHANT_SHOW" then recordNPC("npc", true); C:AddEvent("merchant", "Haendler besucht: " .. U.SafeText(UnitName("npc")))
    elseif event == "UPDATE_MOUSEOVER_UNIT" then recordNPC("mouseover", false)
    elseif event == "PLAYER_TARGET_CHANGED" then recordNPC("target", false)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        if type(unit) == "string" and UnitClassification then
            local classification = UnitClassification(unit)
            if classification == "rare" or classification == "rareelite" then recordNPC(unit, false) end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local _, isReloadingUi = ...
        C:BindCharacterDatabase()
        C:FinalizeLogin(isReloadingUi == true)
        queueQuestScan(false)
        if C_Timer and C_Timer.After then
            C_Timer.After(1, function()
                C:BindCharacterDatabase()
                if not C.moneyReady then C:SyncMoney(false, false); C.moneyReady = true end
                C:Fire("DATA_CHANGED", "database")
                recordInstance(isReloadingUi)
                queueTalentScan()
                if C_Timer and C_Timer.After then
                    C_Timer.After(2, function()
                        if C.char then C:UpdateCharacterSummary(); C:Fire("DATA_CHANGED", "guild") end
                    end)
                end
            end)
        else
            if not C.moneyReady then C:SyncMoney(false, false); C.moneyReady = true end
            recordInstance(isReloadingUi)
            queueTalentScan()
        end
    elseif event == "ENCOUNTER_END" then
        local encounterID, name, difficultyID, groupSize, success = ...
        if not encounterID and (type(name) ~= "string" or name == "") then return end
        local key = tostring(encounterID or name)
        local row = C.char.bosses[key] or { attempts = 0, kills = 0, name = name }
        row.name = U.SafeText(name, row.name)
        row.attempts, row.lastSeen, row.difficultyID, row.groupSize = row.attempts + 1, time(), difficultyID, groupSize
        row.zone = zoneName()
        local instance = A.InstanceInfo()
        if instance and (instance.instanceType == "party" or instance.instanceType == "raid") then
            row.instanceName = instance.name
        end
        if success == 1 then row.kills = row.kills + 1; row.lastSuccess = row.lastSeen end
        C.char.bosses[key] = row; C:AddEvent("boss", (success == 1 and "Boss besiegt: " or "Bossversuch: ") .. row.name)
        if C.pendingBossLoot and C.pendingBossLoot[key] then
            if success == 1 then
                for _, item in ipairs(C.pendingBossLoot[key]) do
                    recordBossLoot(row, item.id, item.link, item.count, item.recipient)
                end
            end
            C.pendingBossLoot[key] = nil
        end
    elseif event == "ENCOUNTER_LOOT_RECEIVED" then
        local encounterID, itemID, itemLink, quantity, recipient = ...
        local key = tostring(encounterID)
        if type(itemLink) ~= "string" and itemID and GetItemInfo then
            local ok, _, link = pcall(GetItemInfo, itemID)
            if ok then itemLink = link end
        end
        local boss = C.char.bosses[key] or recentDefeatedBoss()
        if boss then recordBossLoot(boss, tonumber(itemID), itemLink, quantity, recipient)
        elseif type(itemLink) == "string" and type(recipient) == "string" then
            C.pendingBossLoot = C.pendingBossLoot or {}
            C.pendingBossLoot[key] = C.pendingBossLoot[key] or {}
            table.insert(C.pendingBossLoot[key], { id = tonumber(itemID), link = itemLink,
                count = quantity, recipient = recipient })
        end
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        local boss = recentDefeatedBoss()
        if boss and type(message) == "string" then
            local link = message:match("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r)") or
                message:match("(|cnIQ%d+:|Hitem:.-|h%[.-%]|h|r)") or
                message:match("(|Hitem:.-|h%[.-%]|h)")
            local prefix = link and message:sub(1, message:find(link, 1, true) - 1) or ""
            local recipient = prefix:match("^(.-)%s+erhält") or prefix:match("^(.-)%s+receives")
            if not recipient and (prefix:find("^Ihr ") or prefix:find("^You ")) then
                recipient = UnitName("player")
            end
            if recipient and link then
                recordBossLoot(boss, tonumber(link:match("|Hitem:(%d+)")), link,
                    tonumber(message:match("|h|rx(%d+)")) or 1, recipient)
            end
        end
    elseif event == "SKILL_LINES_CHANGED" then
        local changes = scanProfessions()
        if #changes > 0 then
            C.char.stats.lastSkillUpdate = time()
            C:AddEvent("profession", "Beruf aktualisiert: " .. table.concat(changes, ", "))
        end
    elseif event == "TRADE_SKILL_SHOW" then
        C.tradeSkillOpen = true
        queueRecipeScan()
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
        if C.tradeSkillOpen then queueRecipeScan() end
    elseif event == "TRADE_SKILL_CLOSE" then
        C.tradeSkillOpen = nil
    end
end
frame:SetScript("OnEvent", eventHandler)
