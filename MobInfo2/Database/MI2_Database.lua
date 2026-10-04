local _, MI2 = ...
MI2.DatabaseMixin = {}

local HBD = LibStub("HereBeDragons-2.0")

function MI2.DatabaseMixin:Init( db )
    self.db = db
end

local function MI2_Classification2MobType( unitClassification )
    local mobType = 1
    if unitClassification then
        if unitClassification == "rare" then
            mobType = 2
        elseif unitClassification == "worldboss" then
            mobType = 3
        elseif unitClassification == "elite" then
            mobType = 4
        elseif unitClassification == "rareelite" then
            mobType = 6
        else
            mobType = 1
        end
    end
    return mobType
end

function MI2.DatabaseMixin:Get( id, level, unitClassification, valid, decode )
    if id == nil or level == nil then return end

    local _id = tonumber(id)
    if not _id then
        _id = id
        valid = true
    end

    local _level = tonumber(level)
    if _id ~= nil and _level ~= nil then
        local data = self.db.source[_id]
        if data == nil then
            if (valid == true) then return end
            data = {}
            self.db.source[_id] = data
        end

        -- Just set the mobType/Classification, regardless if it was set already
        local mobType = MI2_Classification2MobType(unitClassification)
        if mobType > 1 then self.db.source[_id].t = mobType end

        if valid == nil or (valid and data[_level]) then
            return CreateAndInitFromMixin(MI2.EntryMixin, self, _id, _level, decode)
        end
    else
        error("Get failed, id: "..(id or "nil")..", level: "..(level or "nil"))
    end
end

function MI2.DatabaseMixin:GetFromGUID( guid, level, classification, valid )
    if guid ~= nil and level ~= nil then
        local unitType, _, _, _, _, unitId = strsplit("-", guid)
--        if (unitType == "Creature" or unitType == "Vehicle") and unitId then
        if unitId then
            return self:Get(unitId, level, classification, valid)
        end
    end
end

function MI2.DatabaseMixin:GetFromUnit( unit )
    local guid = UnitGUID(unit)
    if (not issecretvalue or not issecretvalue(guid)) and guid then
        local unitType, _, _, _, _, unitId = strsplit("-", guid)
    --	if (unitType == "Creature" or unitType == "Vehicle") and unitId then
        if unitId then
            return self:Get(unitId, UnitLevel(unit), UnitClassification(unit))
        end
    end
end

-----------------------------------------------------------------------------
-- GetCombinedMob()
--
-- handle combined Mob mode : try to find the other Mobs with same
-- name but differing level, add their data to the tooltip data
--
function MI2.DatabaseMixin:GetCombinedMobFromGUID( guid, level )
    local mob = self:GetFromGUID(guid, level)
    if mob then
        mob.levelInfo = level
        if mob then
            for l = max(level-4,1), level+4, 1 do
                if l ~= level then
                    mob:Union(self:Get(mob.id, l, true))
                end
            end
        end
    end
    return mob
end

-----------------------------------------------------------------------------
-- GetCombinedMob()
--
-- handle combined Mob mode : try to find the other Mobs with same
-- name but differing level, add their data to the tooltip data
--
function MI2.DatabaseMixin:GetCombinedMob( id, level )
    local mob

    for l = max(level-4,1), level+4, 1 do
        local entry = self:Get(id, l, true)
        if entry then
            if mob == nil then
                mob = entry
            else
                mob:Union(entry)
            end
        end
    end
    return mob
end

function MI2.DatabaseMixin:Upgrade9to10(MobInfoDB,upgradeOnly)

    MI2.printf("Upgrading database from version 9 to 10.")

    local version,locale
    if MobInfoDB and MobInfoDB["DatabaseVersion:0"] then
        version = MobInfoDB["DatabaseVersion:0"].ver
        locale = MobInfoDB["DatabaseVersion:0"].loc
    end

    if not version or version ~= 9 then
        MI2.printf("Database does not have correct version.")
        return
    end
    local convertKnownIdsOnly = locale == MI2.Locale

    local db = self.db
    if not self.db then
        return
    end

    local duplicates = {}
    local Name2UnitIds = {}

    for unitId, unitName in pairs(MI2_UnitId2Name) do
        local unitIds = Name2UnitIds[unitName]
        if not unitIds then
            Name2UnitIds[unitName] = tostring(unitId)
        else
            Name2UnitIds[unitName] = Name2UnitIds[unitName] .. "," .. tostring(unitId)
        end
    end
    local numDuplicates = 0
    local numEmpty = 0
    local numTotal = 0
    local numProcessed = 0
    for mobIndex, mobData in pairs(MobInfoDB) do
        if mobIndex ~="DatabaseVersion:0" then
            local _, _, mobName, mobLevel = string.find(mobIndex, "(.+):(.+)$")
            mobLevel = tonumber(mobLevel) or 0
            local unitIds = Name2UnitIds[mobName]

            numTotal = numTotal + 1
            -- if name look up failed, must be a mob that was collected before
            -- id to name feature was added.
            if (unitIds == nil and convertKnownIdsOnly) or string.find(unitIds, ",") then
                if (mobLevel > 0 or mobLevel == -1) and mobName then
                    local mob = nil
                    if db[mobName] and db[mobName][mobLevel] then
                        mob = db[mobName][mobLevel]
                    end
                    if mob == nil then
                        if next(mobData) then
                            local d = db[mobName]
                            if not d then
                                d = {}
                                db[mobName] = d
                            end
                            local l = d[mobLevel]
                            if not l then
                                l = {}
                                d[mobLevel] = l
                            end
                            for key, value in pairs(mobData) do
                                if type(value) == "string" then
                                    l[key] = value:gsub("^0/", "/"):gsub("/0/", "//"):gsub("/0/", "//"):gsub("/0$", "/")
                                end
                            end
                            duplicates[mobName] = unitIds
                            numProcessed = numProcessed + 1
                        else
                            numEmpty = numEmpty + 1
                        end
                    end
                end
            else
                local unitId = tonumber(unitIds)
                if (unitId > 0 and (mobLevel > 0 or mobLevel == -1)) then
                    local mob = nil
                    if db[unitId] and db[unitId][mobLevel] then
                        mob = db[unitId][mobLevel]
                    end

                    -- If for whatever reason the mob already exists, ignore
                    if mob == nil then
                        if next(mobData) then
                            local md = db[unitId]
                            if md == nil then
                                md = {}
                                db[unitId] = md
                            end
                            local unitData = db[unitId][mobLevel]
                            if unitData == nil then
                                unitData = {}
                                db[unitId][mobLevel] = unitData
                            end
                            if unitData then
                                for key, value in pairs(mobData) do
                                    if type(value) == "string" then
                                        unitData[key] = value:gsub("^0/", "/"):gsub("/0/", "//"):gsub("/0/", "//")
                                            :gsub("/0$", "/")
                                    end
                                end
                                numProcessed = numProcessed + 1
                            end
                        else
                            numEmpty = numEmpty + 1
                        end
                    end
                else
                    print((unitId or "~") .. " / " .. (mobLevel or "~"))
                end
            end
        end
    end

    if upgradeOnly == nil or upgradeOnly == false then
        local backup = {}

        for mobIndex, mobData in pairs(MobInfoDB) do
            backup[mobIndex] = mobData
        end

        if db.backup == nil then
            db.backup = {}
        end

        db.backup.v9 = MI2.Encode(backup)
    end

    for n, i in pairs(duplicates) do
        --MI2.printf("  %s = %s", n, i)
        numDuplicates = numDuplicates + 1
    end
    MI2.printf("Total mobs %d, processed: %d, duplicates: %d, empty: %d", numTotal, numProcessed, numDuplicates, numEmpty)
    MI2.printf("Database upgraded from version 9 to 10.")

    MobInfoDB["DatabaseVersion:0"].ver = 10

end

local function MI2_AddLocation(locationDB, npcID, zoneID, mapID, x,  y)
    if npcID == nil then return end

    local sourceData = locationDB[npcID]
    if sourceData == nil then
        sourceData = {}
        locationDB[npcID] = sourceData
    end

    if zoneID ~= nil and zoneID ~= 0 then
        if mapID == nil then
            sourceData["zone"] = {zoneID}
        else
            sourceData["zone"] = {zoneID, mapID}
        end
    end

    if x == nil or y == nil or (x==0 and y==0) then return end

    local locationData = sourceData[mapID]
    if locationData == nil then
        locationData = {}
        sourceData[mapID] = locationData
    end

    local found = false
    for _, c in next,locationData do
        local distance = HBD:GetZoneDistance(mapID,x/100,y/100,mapID,c[1]/100,c[2]/100)
        if distance < 15 then
            found = true
            break
        end
    end
    if not found then
        locationData[#locationData+1] = {x,y}
    end
end

function MI2.DatabaseMixin:Upgrade10to11(upgradeOnly)
    MI2.printf("Upgrading database from version 10 to 11.")
    local db = self.db
    if not self.db then
        return
    end

    if type(db) == "string" then
        db = MI2.Decode(db)
    end

    if (self.db.version or 10) ~= 10 then
        MI2.printf("Database does not have correct version.")
        return
    end

    local character = {}
    local source = {}
    local location = {}

    local function check(npcID, npcLevel)
        local npcData = source[npcID]
        if npcData == nil then
            npcData ={}
            source[npcID] = npcData
        end
        local levelData = npcData[npcLevel]
        if levelData == nil then
            levelData ={}
            npcData[npcLevel] = levelData
        end
        return npcData, levelData
    end

    for mobIndex, mobData in pairs(db) do
        if mobIndex ~= "backup" then
            for mobLevel, mobInfo in pairs(mobData) do

                if upgradeOnly == nil then
                    -- move character data
                    for _,char in next,MI2_CharTable do
                        local c = mobInfo[char]
                        if c ~= nil then
                            local charData = character[char]
                            if charData == nil then
                                charData = {}
                                character[char] = charData
                            end
                            local sourceData = charData[mobIndex]
                            if sourceData == nil then
                                sourceData = {}
                                charData[mobIndex] = sourceData
                            end
                            local fk,lk
                            local _,e,kl,mind,maxd,dps,xp,sc = string.find( c, "(%d*)/(%d*)/(%d*)/(%d*)/(%d*)/(%d*)")
                            if e then
                                _,_,fk,lk = string.find(c, "/(%d*)/(%d*)",e+1)
                            end
                            local charInfo = {}
                            charInfo.kc = tonumber(kl)
                            charInfo.mnd = tonumber(mind)
                            charInfo.mxd = tonumber(maxd)
                            charInfo.dps = tonumber(dps)
                            charInfo.xp = tonumber(xp)
                            charInfo.fk = tonumber(fk)
                            charInfo.lk = tonumber(lk)
                            charInfo.sc = tonumber(sc)
                            sourceData[mobLevel] = charInfo
                        end
                    end
                end

                -- move location data
                if mobInfo.loc then
                    local sourceLocation = location[mobIndex]
                    if sourceLocation == nil then
                        sourceLocation = {}
                        location[mobIndex] = sourceLocation
                    end
                    for mapID, locData in pairs(mobInfo.loc) do
                        for _, ec in next,locData do
                            local _,_,x,y = string.find(ec,"(.*)/(.*)")
                            MI2_AddLocation( location, mobIndex, nil, mapID, tonumber(x),tonumber(y))
                        end
                    end
                end

                if mobInfo.ml then
                    local m = nil
                    local _,e,_,_,_,_,_,z = string.find( mobInfo.ml, "(%d*%.?%d*)/(%d*%.?%d*)/(%d*%.?%d*)/(%d*%.?%d*)/(%d*)/(%d*)")
                    if e ~= nil  and e > 1 then
                        _,_,m = string.find( mobInfo.ml, "/(%d*)", e +1)
                    end
                    z = tonumber(z)
                    if z ~= nil and z ~= 0 then
                        MI2_AddLocation( location, mobIndex, z, tonumber(m) )
                    end
                end

                -- move source data

                -- for now we are creating an entry in the source database even for ones
                -- with only location or character information
                local sourceInfo, levelInfo = check(mobIndex, mobLevel)

                local il = mobInfo.il
                if il and type(il) == "string" then
                    local itemList = {}

                    local _,e, item, amount = string.find( il, "(%d+)[:]?(%d*)" )
                    if e then
                        levelInfo.i = itemList
                    end
                    while e do
                        itemList[tonumber(item)] = tonumber(amount) or 1
                        _,e, item, amount = string.find( il, "/(%d+)[:]?(%d*)", e + 1 )
                    end
                end
                local cl = mobInfo.cl
                if cl and type(cl) == "string" then
                    local currencyList = {}

                    local _,e,currencyID, amount = string.find( cl, "(%d+)[:]?(%d*)" )
                    if e then
                        levelInfo.c = currencyList
                    end
                    while e do
                        currencyList[tonumber(currencyID)] = tonumber(amount) or 1
                        _,e, currencyID, amount = string.find( cl, "/(%d+)[:]?(%d*)", e + 1 )
                    end
                end

                local bi = mobInfo.bi
                if bi and type(bi) == "string" then
                    local _,e,lt,el,cp,iv,cc,_,mt,sc = string.find( bi, "(%d*)/(%d*)/(%d*)/(%d*)/(%d*)/(%d*)/(%d*)/(%d*)")
                    if e then
                        levelInfo.lc = tonumber(lt)
                        levelInfo.ec = tonumber(el)
                        levelInfo.cp = tonumber(cp)
                        levelInfo.iv = tonumber(iv)
                        levelInfo.cc = tonumber(cc)
                        levelInfo.sc = tonumber(sc)
                        if sourceInfo.t == nil and mt ~= nil then
                            sourceInfo.t = tonumber(mt)
                        end
                    end
                end

                local qi = mobInfo.qi
                if qi and type(qi) == "string" then
                    local _,e,r1,r2,r3,r4,r5 = string.find( qi, "(%d*)/(%d*)/(%d*)/(%d*)/(%d*)")
                    if e then
                        levelInfo.q1 = tonumber(r1)
                        levelInfo.q2 = tonumber(r2)
                        levelInfo.q3 = tonumber(r3)
                        levelInfo.q4 = tonumber(r4)
                        levelInfo.q5 = tonumber(r5)
                    end
                end

            end
        end
    end

    if upgradeOnly == nil or upgradeOnly == false then
        local backup = {}

        for mobIndex, mobData in pairs(db) do
            if mobIndex ~= "backup" then
                backup[mobIndex] = mobData
                db[mobIndex] = nil
            end
        end

        if db.backup == nil then
            db.backup = {}
        end

        db.backup.v10 = MI2.Encode(backup)
    end

    db.character = character
    db.source = source
    db.location = location
    db.info = {}
    db.info.version = 11
    db.info.locale = MI2.Locale
    if MobInfoDB and MobInfoDB["DatabaseVersion:0"] and MobInfoDB["DatabaseVersion:0"] .loc then
        db.info.locale = MobInfoDB["DatabaseVersion:0"] .loc
    end

    self.db = db

    MI2.printf("Database upgraded from version 10 to 11.")

end
