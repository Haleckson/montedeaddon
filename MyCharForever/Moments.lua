local addonName, MCF = ...
-- Special moments with a comment: first death, coming back after a long break, equipment milestones (first green /
-- blue / epic / legendary per slot), comments for notable loot, leaving or being thrown out of a guild.
-- Everything here is text and small bits of logic; the screenshot + journal entry itself is MCF:AutoMoment (Screenshots.lua).
-- The texts are the single source: the journal entry carries the comment, the website only shows it.
-- Settings (missing = on): screenshotMoments / momentsJournal (first death, comeback), equipJournal (+ screenshotEquip),
-- guildJournal / screenshotGuild (guild leave, shared with join), lootComments (comment line in drop / quest / dungeon entries).

local function de() return MCF.GetLanguage and MCF:GetLanguage() == "deDE" end
local function L(german, english) return de() and german or english end
local function pick(list) return list[math.random(#list)] end
local function setting(key, default)
    local st = MyCharForeverDB and MyCharForeverDB.settings
    if st and st[key] ~= nil then return st[key] end
    return default
end

-- ---------------------------------------------------------------------------------------------------------------
-- Equipment slots: the game has 19 slots; rings and trinkets count as one group each, shirt and tabard are cosmetic.
-- ---------------------------------------------------------------------------------------------------------------
local SLOT_GROUP = {[1] = "head", [2] = "neck", [3] = "shoulder", [5] = "chest", [6] = "waist", [7] = "legs", [8] = "feet",
    [9] = "wrist", [10] = "hands", [11] = "finger", [12] = "finger", [13] = "trinket", [14] = "trinket", [15] = "back",
    [16] = "mainhand", [17] = "offhand", [18] = "ranged"}
local INV_GROUP = {INVTYPE_HEAD = "head", INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_CHEST = "chest",
    INVTYPE_ROBE = "chest", INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs", INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist",
    INVTYPE_HAND = "hands", INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_CLOAK = "back",
    INVTYPE_WEAPON = "mainhand", INVTYPE_2HWEAPON = "mainhand", INVTYPE_WEAPONMAINHAND = "mainhand",
    INVTYPE_SHIELD = "offhand", INVTYPE_HOLDABLE = "offhand", INVTYPE_WEAPONOFFHAND = "offhand",
    INVTYPE_RANGED = "ranged", INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_THROWN = "ranged", INVTYPE_RELIC = "ranged"}

function MCF:SlotGroupOfSlot(slot) return SLOT_GROUP[slot] end
function MCF:SlotGroupOfInvType(invType) return INV_GROUP[invType] end

-- Item link -> equipment slot group (nil for potions, bags, materials ...). Works without a loaded item cache.
function MCF:SlotGroupOfLink(link)
    if type(link) ~= "string" then return nil end
    local ok, _, _, _, equipLoc
    if C_Item and C_Item.GetItemInfoInstant then
        ok, _, _, _, equipLoc = pcall(C_Item.GetItemInfoInstant, link)
    elseif GetItemInfoInstant then
        ok, _, _, _, equipLoc = pcall(GetItemInfoInstant, link)
    end
    if not ok then return nil end
    return INV_GROUP[equipLoc], equipLoc
end

-- Title words: noun + gender (m / f / n / p = plural) for German endings, English noun.
local NOUN = {
    head     = {de = "Helm", g = "m", en = "helm"},
    neck     = {de = "Halsschmuck", g = "m", en = "necklace"},
    shoulder = {de = "Schulterstücke", g = "p", en = "shoulders"},
    chest    = {de = "Brustteil", g = "n", en = "chestpiece"},
    waist    = {de = "Gürtel", g = "m", en = "belt"},
    legs     = {de = "Hose", g = "f", en = "pants"},
    feet     = {de = "Stiefel", g = "p", en = "boots"},
    wrist    = {de = "Armschutz", g = "m", en = "bracers"},
    hands    = {de = "Handschuhe", g = "p", en = "gloves"},
    finger   = {de = "Ring", g = "m", en = "ring"},
    trinket  = {de = "Schmuckstück", g = "n", en = "trinket"},
    back     = {de = "Umhang", g = "m", en = "cloak"},
    mainhand = {de = "Waffe", g = "f", en = "weapon"},
    offhand  = {de = "Nebenhandstück", g = "n", en = "off-hand item"},
    ranged   = {de = "Fernkampfwaffe", g = "f", en = "ranged weapon"},
}
local QUALITY_ADJ = {  -- stem; German endings are added by gender
    [2] = {de = "grün", en = "green"}, [3] = {de = "blau", en = "blue"},
    [4] = {de = "episch", en = "epic"}, [5] = {de = "legendär", en = "legendary"},
}
local FIRST = {m = "Erster", f = "Erste", n = "Erstes", p = "Erste"}
local ENDING = {m = "er", f = "e", n = "es", p = "e"}

-- "Erster epischer Helm" / "First epic helm"
function MCF:EquipMomentTitle(group, quality)
    local n, q = NOUN[group], QUALITY_ADJ[quality]
    if not (n and q) then return nil end
    if de() then return string.format("%s %s%s %s", FIRST[n.g], q.de, ENDING[n.g], n.de) end
    return string.format("First %s %s", q.en, n.en)
end

-- One comment line per slot, two variants each. Neutral enough to fit "I wear it now" and "I found it".
local SLOT_LINES = {
    head = {
        de = {"Ein Helm – die Frisur ist jetzt offiziell gerettet.", "Der Kopf ist endlich besser geschützt als der Geldbeutel."},
        en = {"A helm – my hairstyle is officially saved.", "My head is finally better protected than my wallet."}},
    neck = {
        de = {"Schmuck für den Hals: sieht fein aus und hilft vielleicht sogar.", "Ein Hauch von Eleganz um den Hals."},
        en = {"Something shiny around the neck – elegant, and maybe even useful.", "A touch of class around the neck."}},
    shoulder = {
        de = {"Schulterstücke – breite Schultern machen eben Eindruck.", "Meine Schultern tragen jetzt mehr, als sie tragen sollten."},
        en = {"Shoulders – broad shoulders always leave an impression.", "My shoulders now carry more than they should."}},
    chest = {
        de = {"Das Brustteil: die Mitte des Outfits sitzt endlich.", "Für die Brust gab es etwas Ordentliches – mein Herz freut sich mit."},
        en = {"A chest piece – the centre of the outfit finally sits.", "Something proper for the chest – my heart is happy too."}},
    waist = {
        de = {"Ein Gürtel! Die Hose kann sich entspannen.", "Der Gürtel hält zusammen, was zusammengehört."},
        en = {"A belt – my trousers can finally relax.", "A belt holds together what belongs together."}},
    legs = {
        de = {"Neue Beinkleider – man steht gleich viel sicherer.", "Eine Hose, die endlich nach etwas aussieht."},
        en = {"New legwear – I stand a lot more confidently.", "Trousers that finally look like something."}},
    feet = {
        de = {"Neue Stiefel – jeder Weg fühlt sich gleich kürzer an.", "Die Füße sagen danke."},
        en = {"New boots – every road feels shorter.", "My feet say thank you."}},
    wrist = {
        de = {"Armschutz: klein, aber fein.", "Auch die Handgelenke bekommen etwas – niemand wird vergessen."},
        en = {"Bracers: small, but nice.", "Even the wrists got something – nobody is forgotten."}},
    hands = {
        de = {"Handschuhe – jetzt kann ich zupacken, ohne mir die Finger zu ruinieren.", "Frisch behandschuht ins nächste Abenteuer."},
        en = {"Gloves – now I can get a grip without ruining my fingers.", "Freshly gloved into the next adventure."}},
    finger = {
        de = {"Ein Ring – und nicht mal verlobungsverdächtig.", "Der Finger glänzt jetzt."},
        en = {"A ring – and not even an engagement one.", "My finger sparkles now."}},
    trinket = {
        de = {"Ein Schmuckstück voller Magie – man weiß ja nie, wofür es gut ist.", "Es tickt, summt oder leuchtet – Hauptsache, es wirkt."},
        en = {"A trinket full of magic – who knows what it is good for?", "It ticks, hums or glows – as long as it works."}},
    back = {
        de = {"Ein Umhang – dramatisches Wehen im Wind inklusive.", "Der Rücken ist endlich gedeckt."},
        en = {"A cloak – dramatic fluttering in the wind included.", "My back is finally covered."}},
    mainhand = {
        de = {"Eine neue Waffe – die Welt bekommt es gleich zu spüren.", "Scharf, schwer oder zauberhaft – jedenfalls meine."},
        en = {"A new weapon – the world is about to feel it.", "Sharp, heavy or magical – but mine."}},
    offhand = {
        de = {"Etwas für die Nebenhand – die andere Seite hat jetzt auch einen Job.", "Die Nebenhand ist endlich nicht mehr arbeitslos."},
        en = {"Something for the off-hand – the other side has a job now.", "My off-hand is finally employed."}},
    ranged = {
        de = {"Fernkampf: Jetzt darf ich es aus sicherer Entfernung erledigen.", "Reichweite ist eine Tugend."},
        en = {"Ranged – now I can take care of it from a safe distance.", "Range is a virtue."}},
}

-- Openers by quality: when the item is put on for the first time (EQUIP) and when it just dropped / was rewarded (LOOT).
local OPENER = {
    EQUIP = {
        [2] = {de = {"Das erste Grüne – die Sammlerkarriere beginnt.", "Endlich etwas, das nicht grau und langweilig ist."},
               en = {"The first green – the collector's career begins.", "Finally something that is not grey and boring."}},
        [3] = {de = {"Blau! Jetzt wird es ernst.", "Das erste Blaue. Mein Geldbeutel weint, mein Stolz glänzt."},
               en = {"Blue! Now it is getting serious.", "The first blue one. My wallet weeps, my pride shines."}},
        [4] = {de = {"Episch! Ich muss mich kurz setzen.", "Lila ist das neue Grün – und ich trage es."},
               en = {"Epic! I need to sit down for a moment.", "Purple is the new green – and I am wearing it."}},
        [5] = {de = {"Legendär. Ich wiederhole: LEGENDÄR.", "Orange ist die Farbe der Götter – und jetzt auch meine."},
               en = {"Legendary. I repeat: LEGENDARY.", "Orange is the colour of the gods – and now of mine."}},
    },
    LOOT = {
        [2] = {de = {"Grün! Nicht spektakulär, aber ein Anfang.", "Ein grüner Fund – besser als der Kram von gestern."},
               en = {"Green! Not spectacular, but a start.", "A green find – better than yesterday's junk."}},
        [3] = {de = {"Ein blauer Gegenstand! Der Zufall mag mich heute.", "Blau im Beutel – so darf der Tag gern weitergehen."},
               en = {"A blue item! Luck likes me today.", "Blue in the bag – the day may well go on like this."}},
        [4] = {de = {"Episch! Der Zufall hat heute offenbar Feiertag.", "Lila im Loot. Ich bitte um einen Moment der Stille."},
               en = {"Epic! Luck seems to be on holiday today.", "Purple in the loot. A moment of silence, please."}},
        [5] = {de = {"Legendär?! Ich zwicke mich mal kurz.", "Das Universum hat sich verzählt – zu meinen Gunsten."},
               en = {"Legendary?! Let me pinch myself.", "The universe miscounted – in my favour."}},
    },
}

-- kind: "EQUIP" or "LOOT"; group may be nil (item without an equipment slot).
function MCF:MomentComment(kind, quality, group)
    local op = OPENER[kind] and OPENER[kind][quality]
    if not op then return nil end
    local lang = de() and "de" or "en"
    local text = pick(op[lang])
    local lines = group and SLOT_LINES[group]
    if lines then text = text .. " " .. pick(lines[lang]) end
    return text
end

-- ---------------------------------------------------------------------------------------------------------------
-- First death
-- ---------------------------------------------------------------------------------------------------------------
local FIRST_DEATH = {
    de = {"Das erste Mal tot. Ich nenne es „Erfahrung sammeln“.",
          "Der Geistheiler hat mich zum ersten Mal begrüßt. Er war netter als erwartet.",
          "Erster Tod. Ein Tutorial dafür gab es nicht, aber ich habe es überlebt. Irgendwie."},
    en = {"Dead for the first time. I call it “gaining experience”.",
          "The spirit healer greeted me for the first time. Nicer than expected.",
          "First death. There was no tutorial for it, but I survived. Somehow."},
}

function MCF:OnFirstDeath()
    local db = MyCharForeverDB
    if not db then return end
    for _, e in ipairs(db.journal or {}) do if e.source == "FIRST_DEATH" then return end end
    self:AutoMoment{reason = "FIRST_DEATH", shotKey = "screenshotMoments", journalKey = "momentsJournal", delay = 2, force = true,
        source = "FIRST_DEATH", title = L("Mein erster Tod", "My first death"), text = pick(FIRST_DEATH[de() and "de" or "en"])}
end

-- ---------------------------------------------------------------------------------------------------------------
-- Coming back after a long break
-- ---------------------------------------------------------------------------------------------------------------
local DAY = 86400
local COMEBACK = {  -- from the largest gap down
    {days = 365, de = {"Ein ganzes Jahr! Die Welt hat sich weitergedreht – ich stehe wieder genau hier.", "Nach einem Jahr zurück. Ich tue so, als wäre nie etwas gewesen."},
                 en = {"A whole year! The world kept turning – and here I stand again.", "Back after a year. I will pretend nothing ever happened."}},
    {days = 180, de = {"Ein halbes Jahr! Ich musste erst nachsehen, wo ich eigentlich war.", "Sechs Monate später: Welche Taste war noch mal für den Zauber?"},
                 en = {"Half a year! I had to check where I actually was.", "Six months later: which key was the spell again?"}},
    {days = 30,  de = {"Einen Monat weg. Die Questgeber haben schon Vermisstenanzeigen aufgehängt.", "Ein Monat Funkstille – mein Ruhestein war schon ganz kalt."},
                 en = {"A month away. The quest givers have already put up missing posters.", "A month of silence – my hearthstone had gone cold."}},
    {days = 14,  de = {"Staub auf den Stiefeln und Spinnweben im Rucksack – aber ich bin wieder da.", "Zwei Wochen Pause. Azeroth hat mich vermisst. Oder zumindest meine Quests."},
                 en = {"Dust on my boots and cobwebs in my backpack – but I am back.", "Two weeks off. Azeroth missed me. Or at least my quests."}},
}

local function Away(days)
    if days >= 365 then
        local y = math.floor(days / 365)
        if y == 1 then return L("einem Jahr", "a year") end
        return L(y .. " Jahren", y .. " years")
    elseif days >= 30 then
        local m = math.floor(days / 30.4)
        if m <= 1 then return L("einem Monat", "a month") end
        return L(m .. " Monaten", m .. " months")
    end
    return L(days .. " Tagen", days .. " days")
end

-- previous: the session before the one that just started (table with endTime / startTime / duration), or nil.
function MCF:CheckComeback(previous)
    if type(previous) ~= "table" then return end
    local last = tonumber(previous.endTime) or ((tonumber(previous.startTime) or 0) + (tonumber(previous.duration) or 0))
    if last <= 0 then return end
    local days = math.floor((time() - last) / DAY)
    for _, tier in ipairs(COMEBACK) do
        if days >= tier.days then
            self:AutoMoment{reason = "COMEBACK", shotKey = "screenshotMoments", journalKey = "momentsJournal", delay = 8, force = true,
                source = "COMEBACK", fields = {awayDays = days, comebackTier = tier.days},
                title = L("Zurück nach ", "Back after ") .. Away(days), text = pick(tier[de() and "de" or "en"])}
            return
        end
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- Guild: left or thrown out
-- ---------------------------------------------------------------------------------------------------------------
local LEAVE = {
    de = {"Man trennt sich. Hoffentlich im Guten.", "Neue Wege, neue Abenteuer.", "Der Gildenchat wird mich vermissen. Oder auch nicht."},
    en = {"We part ways. Hopefully on good terms.", "New paths, new adventures.", "The guild chat will miss me. Or maybe not."},
}
local KICK = {
    de = {"Rausgeworfen! Die Tür fiel ins Schloss, und ich stand draußen.", "Man hat mich vor die Tür gesetzt. Ich schiebe es auf Kommunikationsprobleme."},
    en = {"Thrown out! The door closed and I was left outside.", "I was shown the door. I blame communication problems."},
}

local kickedAt, kicker
local function KickPattern()
    local g = _G.ERR_GUILD_REMOVE_SELF
    if type(g) ~= "string" or g == "" then return nil end
    local p = g:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. p .. "$"
end
local kickPattern

local sysFrame = CreateFrame("Frame")
sysFrame:RegisterEvent("CHAT_MSG_SYSTEM")
sysFrame:SetScript("OnEvent", function(_, _, msg)
    if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
    kickPattern = kickPattern or KickPattern()
    if kickPattern then
        local who = msg:match(kickPattern)
        if who then kickedAt = GetTime(); kicker = type(who) == "string" and who or nil end
    end
end)

-- name: guild name; called by Guild.lua once a leave is confirmed.
function MCF:OnGuildLeft(name)
    if type(name) ~= "string" or name == "" then return end
    local kicked = kickedAt and (GetTime() - kickedAt) < 60
    local who = kicked and kicker or nil
    kickedAt, kicker = nil, nil
    if self.AddEvent then pcall(self.AddEvent, self, kicked and "GUILD_KICKED" or "GUILD_LEFT", {guild = name, by = who}) end
    local text = pick((kicked and KICK or LEAVE)[de() and "de" or "en"])
    if who then text = text .. "\n" .. string.format(L("Rausgeworfen von %s.", "Removed by %s."), who) end
    self:AutoMoment{reason = kicked and "GUILD_KICKED" or "GUILD_LEFT", shotKey = "screenshotGuild", journalKey = "guildJournal", force = true,
        source = kicked and "GUILD_KICKED" or "GUILD_LEFT", fields = {guild = name, by = who},
        title = string.format(kicked and L("Aus der Gilde <%s> geworfen", "Thrown out of the guild <%s>")
            or L("Die Gilde <%s> verlassen", "Left the guild <%s>"), name), text = text}
end

-- ---------------------------------------------------------------------------------------------------------------
-- Comment line for notable loot (world drop, quest reward, dungeon loot). Returns text or nil.
-- ---------------------------------------------------------------------------------------------------------------
function MCF:LootComment(link, quality)
    local group, equipLoc = self:SlotGroupOfLink(link)
    if not setting("lootComments", true) then return nil, equipLoc end
    return self:MomentComment("LOOT", quality, group), equipLoc
end

-- ---------------------------------------------------------------------------------------------------------------
-- Rolling a 1 or a 100 for an item (need / greed / disenchant). Only the own rolls from the loot chat lines count,
-- free /roll does not. Counters live in stats.rollOnes / stats.rollHundreds (used by achievements).
-- ---------------------------------------------------------------------------------------------------------------
local ROLL_TEXT = {
    [1] = {de = {"Eine 1. Die Würfel haben gesprochen – und gelacht.", "Eine glatte 1! Statistisch gesehen eine Leistung.", "Ganz unten angekommen: eine 1. Tiefer geht es nicht."},
           en = {"A 1. The dice have spoken – and laughed.", "A flat 1! Statistically, that is an achievement.", "Rock bottom: a 1. It cannot get lower."}},
    [100] = {de = {"Eine glatte 100! Die Würfel lieben mich.", "100! Das Item gehört quasi schon mir.", "Höchstwurf: 100. Ich glaube, die Würfel sind geladen."},
             en = {"A flat 100! The dice love me.", "100! The item is practically mine already.", "Maximum roll: 100. I think the dice are loaded."}},
}

-- Game format string -> pattern with captures in argument order: returns pattern, {roll=n, item=n, who=n}.
local function RollPattern(fmt)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    local order, n, kinds = {}, 0, {}
    local pat = fmt:gsub("%%(%d?)%$?([sd])", function(pos, kind)
        n = n + 1
        local idx = tonumber(pos) or n
        order[idx] = n; kinds[idx] = kind
        return kind == "d" and "\1" or "\2"
    end)
    pat = pat:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
    pat = pat:gsub("\1", "(%%d+)"):gsub("\2", "(.-)")
    return "^" .. pat .. "$", order, kinds
end

local rollPatterns
local function RollPatterns()
    if rollPatterns then return rollPatterns end
    rollPatterns = {}
    for _, key in ipairs({"LOOT_ROLL_ROLLED_NEED", "LOOT_ROLL_ROLLED_GREED", "LOOT_ROLL_ROLLED_DE"}) do
        local pat, order, kinds = RollPattern(_G[key])
        if pat then rollPatterns[#rollPatterns + 1] = {pat = pat, order = order, kinds = kinds} end
    end
    return rollPatterns
end

local lastRoll
function MCF:OnItemRoll(roll, link)
    if roll ~= 1 and roll ~= 100 then return end
    local db = MyCharForeverDB
    if not db then return end
    local key = roll .. ":" .. tostring(link)
    if lastRoll and lastRoll.key == key and GetTime() - lastRoll.t < 5 then return end
    lastRoll = {key = key, t = GetTime()}
    db.stats = db.stats or {}
    local field = roll == 1 and "rollOnes" or "rollHundreds"
    db.stats[field] = (db.stats[field] or 0) + 1
    local name = link and link:match("%[(.-)%]") or "?"
    if self.AddEvent then pcall(self.AddEvent, self, "ITEM_ROLL", {roll = roll, itemLink = link}) end
    self:AutoMoment{reason = roll == 1 and "ROLL_ONE" or "ROLL_HUNDRED", shotKey = "screenshotMoments", journalKey = "momentsJournal",
        delay = 1, force = true, source = roll == 1 and "ROLL_ONE" or "ROLL_HUNDRED", fields = {roll = roll, itemLink = link},
        title = string.format(roll == 1 and L("Eine 1 gewürfelt: %s", "Rolled a 1: %s") or L("Eine 100 gewürfelt: %s", "Rolled a 100: %s"), name),
        text = pick(ROLL_TEXT[roll][de() and "de" or "en"]) .. (link and ("\n" .. link) or "")}
    if self.RefreshUI then self:RefreshUI() end
end

local rollFrame = CreateFrame("Frame")
rollFrame:RegisterEvent("CHAT_MSG_LOOT")
rollFrame:SetScript("OnEvent", function(_, _, msg)
    if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
    local me = UnitName and UnitName("player")
    if not me then return end
    for _, p in ipairs(RollPatterns()) do
        local c = {msg:match(p.pat)}
        if c[1] then
            local roll, link, who
            for idx, pos in pairs(p.order) do
                local kind = p.kinds[idx]
                if kind == "d" then roll = tonumber(c[pos])
                elseif not link and (c[pos] or ""):find("|H", 1, true) then link = c[pos]
                else who = c[pos] end
            end
            -- Own roll only. Some builds print "You" instead of the name.
            if roll and who and (who == me or who == _G.YOU) then pcall(MCF.OnItemRoll, MCF, roll, link) end
            return
        end
    end
end)
