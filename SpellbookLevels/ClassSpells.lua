SBL_ClassSpells = {}
function SBL_ClassSpells.Create(lists, Clone, ClassBaseCost)
local function SpellKnown(id)
    if not id then return nil end
    local SB = C_SpellBook
    local tries = { SB and SB.IsSpellKnown, IsPlayerSpell, IsSpellKnown }
    local result
    for i = 1, 3 do
        local fn = tries[i]
        if fn then
            local ok, r = pcall(fn, id)
            if ok and type(r) == "boolean" then
                if r then return true end
                result = false
            end
        end
    end
    return result   -- nil if this client cannot answer
end

-- Every spell you know in the game's own spellbook: name, rank text ("Rank 3", "Passive"...), id, icon, tab.
local function ScanSpellbook()
    local out, SB = {}, C_SpellBook
    if not (SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemName) then
        return out
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    pcall(function()
        for line = 1, SB.GetNumSpellBookSkillLines() do
            local info = SB.GetSpellBookSkillLineInfo(line)
            if info then
                for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local name, sub = SB.GetSpellBookItemName(slot, bank)
                    if name then
                        local ii = SB.GetSpellBookItemInfo and SB.GetSpellBookItemInfo(slot, bank)
                        local future = ii and Enum and Enum.SpellBookItemType and ii.itemType == Enum.SpellBookItemType.FutureSpell
                        local id = ii and (ii.spellID or ii.actionID)
                        local known=SpellKnown(id)
                        -- The client can briefly retain FutureSpell after a successful purchase.
                        -- A positive player-spell answer takes precedence over that display flag.
                        if known==true then future=false end
                        local actualSpell=ii and Enum and Enum.SpellBookItemType and ii.itemType==Enum.SpellBookItemType.Spell
                        if (not sub or sub == "") and id and C_Spell and C_Spell.GetSpellSubtext then
                            local okSub, value = pcall(C_Spell.GetSpellSubtext, id)
                            if okSub and type(value) == "string" then sub = value end
                        end
                        local learnedLevel = 0
                        if id and C_Spell and C_Spell.GetSpellLevelLearned then
                            local okLevel, levelValue = pcall(C_Spell.GetSpellLevelLearned, id)
                            if okLevel and type(levelValue) == "number" then learnedLevel = levelValue end
                        end
                        -- Forever exposes FutureSpell entries in the player's spellbook.  Keep them: they are
                        -- exactly the spells this addon needs to show before the player visits a trainer.
                        -- Trainer scans later merge in the authoritative training price/rank information.
                        if future or actualSpell or known ~= false then
                            out[#out + 1] = {
                                name = name, rank = sub or "", line = info.name, lineIdx = line,
                                id = id,
                                icon = (ii and ii.iconID) or (SB.GetSpellBookItemTexture and SB.GetSpellBookItemTexture(slot, bank)),
                                level = learnedLevel,
                                future = future and true or nil,
                            }
                        end
                    end
                end
            end
        end
    end)
    return out
end

-- The class list shown in the book: trainer data (levels, prices) merged with what you already know.
-- Ranks the trainer doesn't name are numbered by level; a spell is "learned" up to the rank you know.
local function BuildClassEntries()
    local book = ScanSpellbook()
    local byName, byAny, groups, out = {}, {}, {}, {}
    local knownUnranked={}
    -- Future ranks must never replace the highest learned rank.
    for _, b in ipairs(book) do
        byAny[b.name] = b
        if not b.future then
            local old = byName[b.name]
            local rank = tonumber((b.rank or ""):match("(%d+)")) or 0
            local oldRank = old and tonumber((old.rank or ""):match("(%d+)")) or 0
            if not old or rank > oldRank or (rank == oldRank and b.level > old.level) then
                byName[b.name] = b
            end
        end
    end
    for _, e in ipairs(lists.class) do
        groups[e.name] = groups[e.name] or {}
        table.insert(groups[e.name], e)
    end
    for name in pairs(groups) do
        if C_Spell and C_Spell.GetSpellInfo then
            local okInfo,info=pcall(C_Spell.GetSpellInfo,name)
            local id=okInfo and info and info.spellID
            if id and SpellKnown(id)==true then
                local sub,level="",0
                if C_Spell.GetSpellSubtext then
                    local ok,value=pcall(C_Spell.GetSpellSubtext,id)
                    if ok and type(value)=="string" then
                        sub=value
                        if value=="" then knownUnranked[name]=id end
                    end
                end
                if C_Spell.GetSpellLevelLearned then
                    local ok,value=pcall(C_Spell.GetSpellLevelLearned,id)
                    if ok and type(value)=="number" then level=value end
                end
                local old=byName[name]
                local rank=tonumber(sub:match("(%d+)")) or 0
                local oldRank=old and tonumber((old.rank or ""):match("(%d+)")) or 0
                if not old or rank>oldRank or (rank==oldRank and level>(old.level or 0)) then
                    byName[name]={name=name,rank=sub,id=id,level=level,icon=info.iconID,
                        line=old and old.line,lineIdx=old and old.lineIdx}
                end
            end
        end
    end
    for name, g in pairs(groups) do
        table.sort(g, function(a, b) return (a.level or 0) < (b.level or 0) end)
        local b = byName[name]
        local knownRank = b and tonumber((b.rank or ""):match("(%d+)"))
        local topLearned, unlearnedSeen = 0, 0
        local built = {}
        for i, e in ipairs(g) do
            local c = Clone(e)
            local learned = false
            local entryRank = tonumber((c.rank or ""):match("(%d+)"))
            if b then
                if entryRank and knownRank then
                    learned = entryRank <= knownRank
                elseif (b.level or 0) > 0 and (c.level or 0) > 0 then
                    -- Saved trainer rows often omit rank. The live learned spell's
                    -- training level identifies which of those rows are already known.
                    learned = c.level <= b.level
                elseif #g == 1 and not entryRank then
                    -- Forever can report Rank 1 for a single-rank ability while its
                    -- training-level API returns zero. The saved trainer row has no rank.
                    -- A learned book entry is sufficient only if no future rank exists.
                    local hasFuture=false
                    for _,candidate in ipairs(book) do
                        if candidate.name==name and candidate.future and candidate.id~=b.id then hasFuture=true; break end
                    end
                    learned=not hasFuture
                else
                    learned = e.learned == true
                end
            end
            -- Trainer spell IDs identify the purchased rank without relying on the selected tab.
            -- A negative answer must not undo higher-rank inference: old ranks can be replaced.
            if e.recipeID and SpellKnown(e.recipeID)==true then learned=true; c.id=e.recipeID end
            -- A single, unranked ability (Ghost Wolf, for example) has no rank
            -- ambiguity. Ask the player-spell API even if its book page isn't active.
            -- Never use a name lookup to mark an unknown higher rank as learned.
            if not entryRank and #g == 1 and C_Spell and C_Spell.GetSpellInfo then
                local okInfo, info = pcall(C_Spell.GetSpellInfo, name)
                local id = okInfo and info and info.spellID
                local sub = ""
                if id and C_Spell.GetSpellSubtext then
                    local okSub, value = pcall(C_Spell.GetSpellSubtext, id)
                    if okSub then sub = value or "" end
                end
                if id and not sub:match("%d+") then
                    local known = SpellKnown(id)
                    if known==true then learned=true elseif known==false and not b and not (e.recipeID and learned) then learned=false end
                    if learned then c.id = id end
                end
            end
            -- Cached/generated Rank 1 labels and duplicate trainer rows must not turn
            -- a positively-known, live unranked ability into an available upgrade.
            if knownUnranked[name] then
                learned=true; c.id=knownUnranked[name]; c.rank=""
            end
            if c.rank == "" then
                if learned then
                    c.rank = knownRank and (b.rank or "") or c.rank   -- show the spellbook's own rank text
                elseif b or #g > 1 then
                    unlearnedSeen = unlearnedSeen + 1
                    c.rank = "Rank " .. ((knownRank or 0) + unlearnedSeen)
                end
            end
            local metadata = b or byAny[name]
            if metadata then
                c.id = learned and (c.id or (b and b.id)) or nil
                c.icon, c.tree, c.lineIdx = c.icon or metadata.icon, c.tree or metadata.line, metadata.lineIdx
            end
            c.learned = learned and true or nil
            if not c.learned and (not c.cost or c.cost <= 0) then
                c.cost = ClassBaseCost(c.level)
                c.costEstimated = c.cost > 0
            end
            if c.learned then topLearned = i end
            built[i] = c
        end
        for i, c in ipairs(built) do
            if not c.learned or i == topLearned then out[#out + 1] = c end   -- like the spellbook: highest learned rank only
        end
    end
    for _, b in ipairs(book) do
        if not groups[b.name] then
            local lvl = b.level or 0
            out[#out + 1] = { name = b.name, rank = b.rank or "", level = lvl,
                              cost = b.future and ClassBaseCost(lvl) or 0,
                              learned = not b.future, id = b.id, icon = b.icon,
                              tree = b.line, lineIdx = b.lineIdx, dataOrigin = "Live spellbook",
                              costEstimated = b.future and ClassBaseCost(lvl) > 0 }
        end
    end
    return out
end


return SpellKnown, ScanSpellbook, BuildClassEntries
end
