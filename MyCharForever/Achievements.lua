local addonName, MCF = ...
-- Data-driven, character-local achievements. Hidden achievements are hidden in the
-- UI only, they are not protected: the installed addon is readable by design.
--
-- Single source of truth: tiers, categories, metrics and the CHECK_INTERVAL below
-- are defined once. Descriptions use %s for the target value, so the number lives
-- in `target` only. IDs of released achievements must never change (unlock state is
-- stored by id).

local CHECK_INTERVAL = 60 -- seconds between background checks (announces new unlocks)

MCF.AchievementTiers = {
  order = {"easy", "medium", "hard"},
  easy   = {points = 1,  de = "Leicht", en = "Easy",   color = {0.45, 0.80, 0.45}},
  medium = {points = 3, de = "Mittel", en = "Medium", color = {0.40, 0.65, 1.00}},
  hard   = {points = 5, de = "Schwer", en = "Hard",   color = {1.00, 0.55, 0.15}},
}

-- Single source for the secret reveal prices (UI reads these, never literals).
MCF.SecretCost = {random = 5, targeted = {easy = 6, medium = 8, hard = 10}} -- points to reveal a secret: random, or a chosen one by difficulty
function MCF:SecretCostFor(tier) return MCF.SecretCost.targeted[tier] or MCF.SecretCost.targeted.hard end
-- "6 / 8 / 10" for texts (one source: the table above)
function MCF:SecretCostText()
  local t = MCF.SecretCost.targeted
  return t.easy .. " / " .. t.medium .. " / " .. t.hard
end
MCF.IconicPoints = 2 -- secret points for every iconic moment experienced

local categories = {
  order = {"Adventure", "Quests", "Combat", "Exploration", "Travel", "Wealth", "Dungeons",
           "Professions", "Camping", "Reputation", "Guild", "Social", "Account"},
  Adventure   = {de = "Abenteuer",   en = "Adventure"},
  Quests      = {de = "Quests",      en = "Quests"},
  Combat      = {de = "Kampf",       en = "Combat"},
  Exploration = {de = "Entdeckung",  en = "Exploration"},
  Travel      = {de = "Reisen",      en = "Travel"},
  Wealth      = {de = "Wohlstand",   en = "Wealth"},
  Dungeons    = {de = "Dungeons",    en = "Dungeons"},
  Professions = {de = "Berufe",      en = "Professions"},
  Camping     = {de = "Camping",     en = "Camping"},
  Reputation  = {de = "Ruf",         en = "Reputation"},
  Guild       = {de = "Gilde",       en = "Guild"},
  Social      = {de = "Soziales",    en = "Social"},
  Account     = {de = "Account",     en = "Account"},
}

-- Thresholds used by both a metric and the description text of its achievement (one definition each).
local FAST_LEVEL_MINUTES, SLOW_LEVEL_HOURS = 15, 10
local BROKE_MIN_LEVEL = 10
local QUICK_DEATH_SECONDS = 60
local SHORT_CAREER_SECONDS, SHORT_CAREER_DEATHS = 120, 2 -- deaths within this time after ONE login
local DEATH_STREAK_MINUTES = 10  -- window for the repeated-death condition
local LAST_WORDS_MINUTES = 5     -- window after a journal entry
local SHORT_SESSION_SECONDS = 120 -- sessions shorter than this count as short
local LATE_BLOOMER_LEVEL = 10    -- the level whose arrival time counts (hours are the target)
local STILL_HOURS = 1 -- "Rooted to the Spot": longest uninterrupted stretch without moving
local TRANSMOG_MIN_SLOTS = 8 -- fashion achievement: at least this many equipped slots, all of them transmogrified
local DEATH_SPOT_RADIUS = 0.01 -- fraction of the map (about 1 %)

-- Speed runs: reach a level within a time after the character was created (wall-clock, offline
-- time counts). Only characters recorded from level 1 qualify. One table drives metric,
-- description and the achievement entries.
local SPEED_RUNS = {
  {level = 2,  seconds = 5 * 60,        tier = "medium", de = "Blitzstart",                en = "Lightning Start"},
  {level = 10, seconds = 3 * 3600,      tier = "medium", de = "Level 10 vor dem Mittagessen", en = "Level 10 Before Lunch"},
  {level = 20, seconds = 12 * 3600,     tier = "hard",   de = "Schlaf wird überschätzt",   en = "Sleep Is Overrated"},
  {level = 30, seconds = 24 * 3600,     tier = "hard",   de = "Ein Tag, ein Level 30",     en = "One Day, One Level 30"},
  {level = 60, seconds = 10 * 86400,    tier = "hard",   de = "Urlaubs-Weltrekord",        en = "Vacation World Record"},
}

-- Account achievements count over every character the addon has recorded (MyCharForeverAccountDB.characters).
-- Unlocked once per account, points go into a pool shared by all characters (see pointsBreakdown).
local ACCOUNT_FACTION_RACES = {
  Horde = {Orc = true, Troll = true, Tauren = true, Scourge = true, BloodElf = true, Goblin = true},
  Alliance = {Human = true, Dwarf = true, NightElf = true, Gnome = true, Draenei = true, Worgen = true},
}

local function durationText(seconds, german)
  if seconds < 3600 then
    local m = math.floor(seconds / 60 + 0.5)
    return m .. (german and " Minuten" or " minutes")
  elseif seconds < 2 * 86400 then
    local h = math.floor(seconds / 3600 + 0.5)
    return h .. (german and " Stunden" or " hours")
  end
  local d = math.floor(seconds / 86400 + 0.5)
  return d .. (german and " Tagen" or " days")
end

local definitions = {
  {id="level_10", category="Adventure", tier="easy", metric="level", target=15, de="Aus den Windeln raus", deDesc="Erreiche Level %s.", en="Out of Diapers", enDesc="Reach level %s."},
  {id="level_20", category="Adventure", tier="easy", metric="level", target=25, de="Frischling? Wer, ich?", deDesc="Erreiche Level %s.", en="Rookie? Who, Me?", enDesc="Reach level %s."},
  {id="level_30", category="Adventure", tier="medium", metric="level", target=30, de="Das habe ich schon mal gesehen", deDesc="Erreiche Level %s.", en="Seen It All Before", enDesc="Reach level %s."},
  {id="level_40", category="Adventure", tier="medium", metric="level", target=40, de="Mein Rücken ...", deDesc="Erreiche Level %s.", en="My Aching Back", enDesc="Reach level %s."},
  {id="level_50", category="Adventure", tier="medium", metric="level", target=50, de="Fast Rente", deDesc="Erreiche Level %s.", en="Nearly Retired", enDesc="Reach level %s."},
  {id="level_60", category="Adventure", tier="hard", metric="level", target=60, de="Und jetzt?", deDesc="Erreiche Level %s.", en="Now What?", enDesc="Reach level %s."},
  {id="chronicle_played_10h", category="Adventure", tier="easy", metric="playedHours", target=40, de="Nachtschicht in Azeroth", deDesc="Verbringe %s Stunden in Azeroth.", en="Azeroth Night Shift", enDesc="Spend %s hours in Azeroth."},
  {id="chronicle_played_50h", category="Adventure", tier="medium", metric="playedHours", target=80, de="Ich wohne jetzt hier", deDesc="Verbringe %s Stunden mit deinem Charakter.", en="I Live Here Now", enDesc="Spend %s hours on this character."},
  {id="chronicle_played_100h", category="Adventure", tier="medium", metric="playedHours", target=150, de="Mietvertrag mit dem Wirt", deDesc="Verbringe %s Stunden in dieser Welt.", en="Lease with the Innkeeper", enDesc="Spend %s hours in this world."},
  {id="chronicle_played_250h", category="Adventure", tier="hard", metric="playedHours", target=400, de="Draußen soll es Sonne geben", deDesc="Sammle %s Stunden Spielzeit.", en="They Say the Sun Is Out", enDesc="Accumulate %s hours played."},
  {id="chronicle_sessions_25", category="Adventure", tier="easy", metric="sessions", target=100, de="Nur ganz kurz einloggen", deDesc="Starte %s Spielsitzungen.", en="Just Logging In Briefly", enDesc="Start %s play sessions."},
  {id="chronicle_sessions_100", category="Adventure", tier="medium", metric="sessions", target=250, de="Noch fünf Minuten", deDesc="Starte %s Spielsitzungen.", en="Five More Minutes", enDesc="Start %s play sessions."},
  {id="chronicle_deaths_10", category="Adventure", tier="easy", metric="deaths", target=40, de="Der Boden kennt mich", deDesc="Erlebe %s Tode.", en="The Ground Knows Me", enDesc="Experience %s deaths.", hidden=true},
  {id="chronicle_deaths_50", category="Adventure", tier="medium", metric="deaths", target=100, de="Stammkunde beim Geistheiler", deDesc="Erlebe %s Tode.", en="Spirit Healer Regular", enDesc="Experience %s deaths.", hidden=true},
  {id="chronicle_deaths_100", category="Adventure", tier="hard", metric="deaths", target=250, de="Unsterblich wäre einfacher", deDesc="Erlebe %s Tode.", en="Immortality Would Be Easier", enDesc="Experience %s deaths.", hidden=true},
  {id="chronicle_quests_10", category="Quests", tier="easy", metric="quests", target=40, de="Kannst du kurz ...?", deDesc="Erledige %s Quests.", en="Could You Just...?", enDesc="Complete %s quests."},
  {id="chronicle_quests_50", category="Quests", tier="easy", metric="quests", target=200, de="Botendienst mit Schwert", deDesc="Erledige %s Quests.", en="Armed Courier", enDesc="Complete %s quests."},
  {id="gather_herb_150", category="Professions", tier="easy", metric="gatherHerbs", target=150, de="Grüner Daumen", deDesc="Sammle %s Kräuter.", en="Green Thumb", enDesc="Gather %s herbs."},
  {id="chronicle_quests_300", category="Quests", tier="medium", metric="quests", target=400, de="Noch eine Kleinigkeit", deDesc="Erledige %s Quests.", en="One More Little Favor", enDesc="Complete %s quests."},
  {id="chronicle_quests_600", category="Quests", tier="hard", metric="quests", target=800, de="Der Held der Laufburschen", deDesc="Erledige %s Quests.", en="Hero of Errands", enDesc="Complete %s quests."},
  {id="chronicle_quests_1000", category="Quests", tier="hard", metric="quests", target=1500, de="Azeroths unbezahlter Praktikant", deDesc="Erledige %s Quests.", en="Azeroths Unpaid Intern", enDesc="Complete %s quests."},
  {id="chronicle_kills_25", category="Combat", tier="easy", metric="kills", target=150, de="Die Wildnis hat Beschwerde eingelegt", deDesc="Besiege %s Gegner.", en="The Wilderness Complained", enDesc="Defeat %s enemies."},
  {id="gather_ore_100", category="Professions", tier="easy", metric="gatherOre", target=100, de="Hobby-Bergmann", deDesc="Baue %s Erze ab.", en="Weekend Miner", enDesc="Mine %s ores."},
  {id="chronicle_kills_500", category="Combat", tier="medium", metric="kills", target=750, de="Lokale Bedrohung", deDesc="Besiege %s Gegner.", en="Local Menace", enDesc="Defeat %s enemies."},
  {id="chronicle_kills_1000", category="Combat", tier="medium", metric="kills", target=1500, de="Die Monstergewerkschaft streikt", deDesc="Besiege %s Gegner.", en="Monster Union on Strike", enDesc="Defeat %s enemies."},
  {id="chronicle_kills_2500", category="Combat", tier="hard", metric="kills", target=3500, de="Auf der schwarzen Liste", deDesc="Besiege %s Gegner.", en="On the Blacklist", enDesc="Defeat %s enemies."},
  {id="chronicle_kills_5000", category="Combat", tier="hard", metric="kills", target=7500, de="Endgegner der Wildnis", deDesc="Besiege %s Gegner.", en="The Wilderness Final Boss", enDesc="Defeat %s enemies."},
  {id="chronicle_killtypes_10", category="Combat", tier="easy", metric="killTypes", target=40, de="Was war das denn?", deDesc="Besiege %s verschiedene Gegnertypen.", en="What Was That?", enDesc="Defeat %s enemy types."},
  {id="chronicle_killtypes_40", category="Combat", tier="medium", metric="killTypes", target=60, de="Monster-Bingo", deDesc="Besiege %s verschiedene Gegnertypen.", en="Monster Bingo", enDesc="Defeat %s enemy types."},
  {id="chronicle_killtypes_100", category="Combat", tier="hard", metric="killTypes", target=120, de="Professor für Ungeheuerkunde", deDesc="Besiege %s verschiedene Gegnertypen.", en="Professor of Monstrology", enDesc="Defeat %s enemy types."},
  {id="chronicle_samekill_50", category="Combat", tier="easy", metric="killsSameType", target=200, de="Persönliche Fehde", deDesc="Besiege einen Gegnertyp %s-mal.", en="Personal Vendetta", enDesc="Defeat one enemy type %s times."},
  {id="chronicle_samekill_250", category="Combat", tier="medium", metric="killsSameType", target=400, de="Und täglich grüßt der Murloc", deDesc="Besiege einen Gegnertyp %s-mal.", en="Groundhog Murloc", enDesc="Defeat one enemy type %s times."},
  {id="duels_1", category="Combat", tier="easy", metric="duels", target=10, de="Handschuh geworfen", deDesc="Bestreite %s Duelle.", en="Gauntlet Thrown", enDesc="Fight %s duels."},
  {id="duelwins_10", category="Combat", tier="medium", metric="duelWins", target=15, de="Wer zuerst zuckt, verliert", deDesc="Gewinne %s Duelle.", en="Blink and You Lose", enDesc="Win %s duels."},
  {id="chronicle_zones_5", category="Exploration", tier="easy", metric="zones", target=18, de="Wo bin ich hier gelandet?", deDesc="Besuche %s verschiedene Zonen.", en="Where Am I?", enDesc="Visit %s zones."},
  {id="still_1h", category="Adventure", tier="easy", metric="stillHours", target=STILL_HOURS, de="Wurzeln geschlagen", deDesc="Stehe "..STILL_HOURS.." Stunde am Stück still, ohne dich zu bewegen.", en="Rooted to the Spot", enDesc="Stand still for "..STILL_HOURS.." hour in a row without moving."},
  {id="chronicle_zones_20", category="Exploration", tier="medium", metric="zones", target=28, de="Mein Ruhestein ist kaputt", deDesc="Besuche %s verschiedene Zonen.", en="My Hearthstone Is Broken", enDesc="Visit %s zones."},
  {id="gather_fish_50", category="Professions", tier="easy", metric="gatherFish", target=50, de="Angelschein", deDesc="Fange %s Fische.", en="Fishing License", enDesc="Catch %s fish."},
  {id="chronicle_zones_40", category="Exploration", tier="hard", metric="zones", target=40, de="Ich war wirklich überall", deDesc="Besuche %s verschiedene Zonen.", en="I Have Been Everywhere", enDesc="Visit %s zones."},
  {id="chronicle_subzones_25", category="Exploration", tier="easy", metric="subZones", target=100, de="Hinter jedem Busch", deDesc="Entdecke %s Unterzonen.", en="Behind Every Bush", enDesc="Discover %s subzones."},
  {id="chronicle_subzones_100", category="Exploration", tier="medium", metric="subZones", target=150, de="Verlaufen mit System", deDesc="Entdecke %s Unterzonen.", en="Professionally Lost", enDesc="Discover %s subzones."},
  {id="chronicle_subzones_250", category="Exploration", tier="hard", metric="subZones", target=300, de="Der letzte Winkel", deDesc="Entdecke %s Unterzonen.", en="The Last Corner", enDesc="Discover %s subzones."},
  {id="chronicle_journal_5", category="Exploration", tier="easy", metric="journal", target=20, de="Liebes Tagebuch ...", deDesc="Verfasse %s Journaleinträge.", en="Dear Diary...", enDesc="Write %s journal entries."},
  {id="chronicle_journal_25", category="Exploration", tier="medium", metric="journal", target=40, de="Autobiografie in Arbeit", deDesc="Verfasse %s Journaleinträge.", en="Autobiography in Progress", enDesc="Write %s journal entries."},
  {id="recipe_special_1", category="Professions", tier="medium", metric="specialRecipes", target=1, de="Rezeptjäger", deDesc="Lerne ein Rezept, das du als Weltdrop, im Dungeon oder als Questbelohnung bekommen hast.", en="Recipe Hunter", enDesc="Learn a recipe you got as a world drop, in a dungeon or as a quest reward."},
  {id="chronicle_journal_zones_10", category="Exploration", tier="medium", metric="journalZones", target=15, de="Reisetagebuch eines Verirrten", deDesc="Schreibe in %s verschiedenen Zonen ins Journal.", en="Lost Travelers Diary", enDesc="Write journal entries in %s zones."},
  {id="chronicle_screenshots_10", category="Exploration", tier="easy", metric="screenshots", target=40, de="Beweisfoto oder es zählt nicht", deDesc="Mache %s Chronik-Screenshots.", en="Pics or It Did Not Happen", enDesc="Take %s chronicle screenshots."},
  {id="chronicle_km_10", category="Travel", tier="easy", metric="km", target=75, de="Blasen an den Füßen", deDesc="Lege %s Kilometer am Boden zurück.", en="Blisters on My Feet", enDesc="Travel %s kilometers on the ground."},
  {id="chronicle_km_50", category="Travel", tier="easy", metric="km", target=150, de="Wo ist mein Reittier?", deDesc="Lege %s Kilometer am Boden zurück.", en="Where Is My Mount?", enDesc="Travel %s kilometers on the ground."},
  {id="chronicle_km_150", category="Travel", tier="medium", metric="km", target=350, de="Schuhsohlenverschleiß", deDesc="Lege %s Kilometer am Boden zurück.", en="Worn-Out Soles", enDesc="Travel %s kilometers on the ground."},
  {id="chronicle_km_400", category="Travel", tier="hard", metric="km", target=1200, de="Ich hätte den Greifen nehmen sollen", deDesc="Lege %s Kilometer am Boden zurück.", en="Should Have Taken the Gryphon", enDesc="Travel %s kilometers on the ground."},
  {id="taxi_1", category="Travel", tier="easy", metric="taxiRoutes", target=25, de="Hoch hinaus", deDesc="Nutze %s Flugrouten.", en="Flying High", enDesc="Take %s flight paths."},
  {id="chronicle_taxi_15", category="Travel", tier="medium", metric="taxiRoutes", target=100, de="Bitte Fensterplatz", deDesc="Nutze %s Flugrouten.", en="Window Seat Please", enDesc="Take %s flight paths."},
  {id="chronicle_taxi_60", category="Travel", tier="hard", metric="taxiRoutes", target=500, de="Vielflieger ohne Bonusmeilen", deDesc="Nutze %s Flugrouten.", en="Frequent Flyer No Miles", enDesc="Take %s flight paths."},
  {id="gold_1", category="Wealth", tier="easy", metric="gold", target=10, de="Erstes Gold, erster Größenwahn", deDesc="Besitze %s Gold.", en="First Gold, First Delusions of Grandeur", enDesc="Own %s gold."},
  {id="chronicle_gold_10", category="Wealth", tier="easy", metric="gold", target=40, de="Kleingeld für die Weltrettung", deDesc="Besitze %s Gold.", en="Pocket Change for Saving the World", enDesc="Own %s gold."},
  {id="chronicle_gold_50", category="Wealth", tier="medium", metric="gold", target=75, de="Ich kann mir Reparaturen leisten", deDesc="Besitze %s Gold.", en="I Can Afford Repairs", enDesc="Own %s gold."},
  {id="chronicle_gold_200", category="Wealth", tier="medium", metric="gold", target=250, de="Dagobert von Azeroth", deDesc="Besitze %s Gold.", en="Scrooge of Azeroth", enDesc="Own %s gold."},
  {id="chronicle_gold_1000", category="Wealth", tier="hard", metric="gold", target=1500, de="Gold statt Freunde", deDesc="Besitze %s Gold.", en="Gold Instead of Friends", enDesc="Own %s gold."},
  {id="dungeons_1", category="Dungeons", tier="easy", metric="dungeonVisits", target=8, de="Was ist das für ein Geruch?", deDesc="Betritt Dungeons %s-mal.", en="What Is That Smell?", enDesc="Enter dungeons %s times."},
  {id="dungeons_10", category="Dungeons", tier="medium", metric="dungeonVisits", target=15, de="Fledermaus-Freund", deDesc="Betritt Dungeons %s-mal.", en="Bat Buddy", enDesc="Enter dungeons %s times."},
  {id="chronicle_dungeons_40", category="Dungeons", tier="hard", metric="dungeonVisits", target=50, de="Ich kenne jeden Keller", deDesc="Betritt Dungeons %s-mal.", en="I Know Every Basement", enDesc="Enter dungeons %s times."},
  {id="dungeondone_1", category="Dungeons", tier="easy", metric="dungeonCompletions", target=8, de="Der Boss ist tot, es lebe die Beute", deDesc="Schließe %s Dungeons ab.", en="The Boss Is Dead, Long Live the Loot", enDesc="Complete %s dungeons."},
  {id="dungeondone_10", category="Dungeons", tier="medium", metric="dungeonCompletions", target=15, de="Läuft bei mir", deDesc="Schließe %s Dungeons ab.", en="Rolling Along", enDesc="Complete %s dungeons."},
  {id="dungeondone_30", category="Dungeons", tier="hard", metric="dungeonCompletions", target=40, de="Hausmeister der Verliese", deDesc="Schließe %s Dungeons ab.", en="Janitor of the Depths", enDesc="Complete %s dungeons."},
  {id="bosses_5", category="Dungeons", tier="easy", metric="bosses", target=20, de="Chefs sind auch nur Menschen", deDesc="Besiege %s Dungeon-Bosse.", en="Bosses Are People Too", enDesc="Defeat %s dungeon bosses."},
  {id="bosses_30", category="Dungeons", tier="medium", metric="bosses", target=45, de="Feindliche Übernahme", deDesc="Besiege %s Dungeon-Bosse.", en="Hostile Takeover", enDesc="Defeat %s dungeon bosses."},
  {id="dungeontypes_5", category="Dungeons", tier="medium", metric="dungeonTypes", target=8, de="Rundreise unter Tage", deDesc="Besuche %s verschiedene Dungeons.", en="Underground Tour", enDesc="Visit %s different dungeons."},
  {id="craft_10", category="Professions", tier="easy", metric="craft", target=40, de="Hobbybastler", deDesc="Stelle %s Gegenstände her.", en="Weekend Tinkerer", enDesc="Craft %s items."},
  {id="craft_100", category="Professions", tier="medium", metric="craft", target=150, de="Werkbank-Wahnsinn", deDesc="Stelle %s Gegenstände her.", en="Workbench Madness", enDesc="Craft %s items."},
  {id="craft_1000", category="Professions", tier="hard", metric="craft", target=1500, de="Fließbandarbeiter", deDesc="Stelle %s Gegenstände her.", en="Assembly Line Worker", enDesc="Craft %s items."},
  {id="prof_3", category="Professions", tier="medium", metric="professionCount", target=5, de="Hans Dampf in allen Gassen", deDesc="Beherrsche %s Berufe (Nebenberufe zählen mit).", en="Jack of All Trades, Master of Some", enDesc="Know %s professions (secondary ones count)."},
  {id="skill_75", category="Professions", tier="easy", metric="skill", target=75, de="Lehrling", deDesc="Erreiche Fertigkeit %s in einem Beruf.", en="Apprentice", enDesc="Reach skill %s in a profession."},
  {id="skill_150", category="Professions", tier="medium", metric="skill", target=150, de="Geselle", deDesc="Erreiche Fertigkeit %s in einem Beruf.", en="Journeyman", enDesc="Reach skill %s in a profession."},
  {id="skill_225", category="Professions", tier="medium", metric="skill", target=225, de="Der macht das schon länger", deDesc="Erreiche Fertigkeit %s in einem Beruf.", en="Been Doing This a While", enDesc="Reach skill %s in a profession."},
  {id="skill_300", category="Professions", tier="hard", metric="skill", target=300, de="Fachidiot (als Kompliment)", deDesc="Erreiche Fertigkeit %s in einem Beruf.", en="Domain Expert (As a Compliment)", enDesc="Reach skill %s in a profession."},
  {id="rep_5", category="Reputation", tier="easy", metric="repFactions", target=20, de="Hallo, ich bin neu hier", deDesc="Lerne %s Fraktionen kennen.", en="Hi, I'm New Here", enDesc="Meet %s factions."},
  {id="rep_honored", category="Reputation", tier="medium", metric="repHonored", target=1, de="Man kennt mich hier", deDesc="Erreiche bei einer Fraktion den Ruf Wohlwollend.", en="They Know Me Here", enDesc="Reach Honored with a faction."},
  {id="rep_revered", category="Reputation", tier="hard", metric="repRevered", target=1, de="Freund des Hauses", deDesc="Erreiche bei einer Fraktion den Ruf Respektvoll.", en="Friend of the House", enDesc="Reach Revered with a faction."},
  {id="rep_exalted", category="Reputation", tier="hard", metric="repExalted", target=1, de="Die Fraktion baut mir ein Denkmal", deDesc="Erreiche bei einer Fraktion den Ruf Ehrfürchtig.", en="They're Building Me a Statue", enDesc="Reach Exalted with a faction."},
  {id="guild_joined", category="Guild", tier="easy", metric="guildJoined", target=1, de="Jetzt gehöre ich zu den Coolen", deDesc="Tritt einer Gilde bei.", en="Joined the Cool Kids", enDesc="Join a guild."},
  {id="guild_loyal", category="Guild", tier="medium", metric="guildDays", target=30, de="Treuer Gefährte", deDesc="Gehöre %s Tage lang derselben Gilde an (gezählt ab dem ersten Kontakt des Addons).", en="Loyal Companion", enDesc="Belong to the same guild for %s days (counted from when the addon first saw it)."},
  {id="wave_5", category="Social", tier="easy", metric="wave", target=25, de="Winke, winke", deDesc="Winke %s-mal.", en="Wave, Wave", enDesc="Wave %s times."},
  {id="wave_50", category="Social", tier="medium", metric="wave", target=75, de="Wie die Queen", deDesc="Winke %s-mal.", en="Like the Queen", enDesc="Wave %s times."},
  {id="wave_250", category="Social", tier="hard", metric="wave", target=300, de="Bürgermeister von Azeroth", deDesc="Winke %s-mal.", en="Mayor of Azeroth", enDesc="Wave %s times.", hidden=true},
  {id="presence_1", category="Social", tier="easy", metric="addonUsers", target=1, de="Man erkennt sich", deDesc="Triff andere Spieler, die MyCharForever benutzen (Ziel: %s).", en="Fellow Chroniclers", enDesc="Meet other players who use MyCharForever (goal: %s)."},
  {id="presence_5", category="Social", tier="medium", metric="addonUsers", target=5, de="Addon-Stammtisch", deDesc="Triff andere Spieler, die MyCharForever benutzen (Ziel: %s).", en="Chronicle Meetup", enDesc="Meet other players who use MyCharForever (goal: %s)."},
  {id="presence_20", category="Social", tier="hard", metric="addonUsers", target=20, de="Gilde der Chronisten", deDesc="Triff andere Spieler, die MyCharForever benutzen (Ziel: %s).", en="Guild of Chroniclers", enDesc="Meet other players who use MyCharForever (goal: %s)."},
  {id="wavetargets_5", category="Social", tier="easy", metric="waveTargets", target=20, de="Hallo, Fremder!", deDesc="Winke %s verschiedenen Spielern zu.", en="Hello, Stranger!", enDesc="Wave at %s different players."},
  {id="ench_1", category="Professions", tier="easy", metric="enchantItems", target=1, de="Es funkelt!", deDesc="Trage einen verzauberten Gegenstand.", en="It Sparkles!", enDesc="Wear an enchanted item."},
  {id="ench_5", category="Professions", tier="medium", metric="enchantItems", target=5, de="Magisch veranlagt", deDesc="Trage %s verschiedene verzauberte Gegenstände.", en="Magically Inclined", enDesc="Wear %s different enchanted items."},
  {id="ench_15", category="Professions", tier="hard", metric="enchantItems", target=15, de="Funkelnde Garderobe", deDesc="Trage %s verschiedene verzauberte Gegenstände.", en="Sparkling Wardrobe", enDesc="Wear %s different enchanted items."},
  {id="ench_all", category="Professions", tier="hard", metric="enchantAll", target=1, de="Rundum verzaubert", deDesc="Trage gleichzeitig verzauberte Gegenstände in allen verzauberbaren Plätzen (Brust, Handgelenke, Hände, Füße, Rücken, Waffe).", en="Enchanted Head to Toe", enDesc="Wear enchanted items in every enchantable slot at the same time (chest, wrists, hands, feet, back, weapon)."},
  {id="disenchant_25", category="Professions", tier="medium", metric="disenchants", target=25, de="Staubsauger", deDesc="Entzaubere %s Gegenstände.", en="Dust Collector", enDesc="Disenchant %s items."},
  {id="wavetargets_100", category="Social", tier="hard", metric="waveTargets", target=100, de="Kennt jeden", deDesc="Winke %s verschiedenen Spielern zu.", en="Knows Everyone", enDesc="Wave at %s different players."},
  {id="whisper_1", category="Social", tier="easy", metric="whispersSent", target=10, de="Psst!", deDesc="Sende %s Flüsternachrichten.", en="Psst!", enDesc="Send %s whispers."},
  {id="whisper_25", category="Social", tier="medium", metric="whispersSent", target=40, de="Flüsterer", deDesc="Sende %s Flüsternachrichten.", en="Whisperer", enDesc="Send %s whispers."},
  {id="whisper_100", category="Social", tier="hard", metric="whispersSent", target=150, de="Geheimnisträger", deDesc="Sende %s Flüsternachrichten.", en="Keeper of Secrets", enDesc="Send %s whispers."},
  {id="gather_skin_100", category="Professions", tier="easy", metric="gatherSkins", target=100, de="Kürschner-Blut", deDesc="Ziehe Gegnern %s Felle und Häute ab.", en="Skin in the Game", enDesc="Skin %s hides and pelts from enemies."},
  {id="res_1", category="Social", tier="easy", metric="resCast", target=5, de="Zurück ins Leben", deDesc="Belebe %s andere Spieler wieder.", en="Back to Life", enDesc="Resurrect %s other players."},
  {id="res_10", category="Social", tier="medium", metric="resCast", target=15, de="Lebensretter", deDesc="Belebe %s Spieler wieder.", en="Lifesaver", enDesc="Resurrect %s players."},
  {id="res_50", category="Social", tier="hard", metric="resCast", target=50, de="Engel des Schlachtfelds", deDesc="Belebe %s Spieler wieder.", en="Angel of the Battlefield", enDesc="Resurrect %s players."},
  {id="resrecv_1", category="Social", tier="easy", metric="resReceived", target=5, de="Staub abklopfen, weitermachen", deDesc="Lass dich %s-mal von Spielern wiederbeleben.", en="Dust Yourself Off", enDesc="Be resurrected by players %s times."},
  {id="resrecv_10", category="Social", tier="medium", metric="resReceived", target=15, de="Immer wieder aufgestanden", deDesc="Lass dich %s-mal von Spielern wiederbeleben.", en="Back Up Again", enDesc="Be resurrected by players %s times."},
  {id="group_5", category="Social", tier="easy", metric="groupsJoined", target=20, de="Wir brauchen noch einen!", deDesc="Tritt %s Gruppen bei.", en="We Need One More!", enDesc="Join %s groups."},
  {id="mates_10", category="Social", tier="medium", metric="groupMates", target=15, de="Netzwerker", deDesc="Spiele mit %s verschiedenen Mitspielern in einer Gruppe.", en="Networker", enDesc="Group up with %s different players."},
  {id="dance_10", category="Social", tier="easy", metric="emote:DANCE", target=40, de="Tanzbär", deDesc="Tanze %s-mal.", en="Dancing Bear", enDesc="Dance %s times.", hidden=true},
  {id="chronik_streak_3", category="Adventure", tier="easy", metric="streakDays", target=3, de="Dranbleiben", deDesc="Spiele an %s Tagen hintereinander.", en="Keeping At It", enDesc="Play on %s days in a row."},
  {id="chronik_streak_7", category="Adventure", tier="medium", metric="streakDays", target=7, de="Eine Woche am Stück", deDesc="Spiele an %s Tagen hintereinander.", en="A Week Straight", enDesc="Play on %s days in a row."},
  {id="chronik_streak_30", category="Adventure", tier="hard", metric="streakDays", target=30, de="Gewohnheitstier", deDesc="Spiele an %s Tagen hintereinander.", en="Creature of Habit", enDesc="Play on %s days in a row."},
  {id="chronik_age_30", category="Adventure", tier="easy", metric="charAgeDays", target=30, de="Alter Hase", deDesc="Dein Charakter besteht seit %s Tagen.", en="Old Hand", enDesc="Your character has existed for %s days."},
  {id="chronik_age_100", category="Adventure", tier="medium", metric="charAgeDays", target=100, de="Hundert Tage Azeroth", deDesc="Dein Charakter besteht seit %s Tagen.", en="A Hundred Days of Azeroth", enDesc="Your character has existed for %s days."},
  {id="chronik_age_365", category="Adventure", tier="hard", metric="charAgeDays", target=365, de="Ein Jahr Chronik", deDesc="Dein Charakter besteht seit %s Tagen.", en="A Year of Chronicle", enDesc="Your character has existed for %s days."},
  {id="journal_early", category="Exploration", tier="easy", metric="earlyJournal", target=1, de="Tagebuch ab Tag eins", deDesc="Schreibe einen Journal-Eintrag, solange du höchstens Level 5 bist.", en="Diary From Day One", enDesc="Write a journal entry while you are at most level 5."},
  {id="deathless_5", category="Adventure", tier="medium", metric="deathlessRun", target=5, de="Unberührbar", deDesc="Schließe %s Level hintereinander ohne einen einzigen Tod ab.", en="Untouchable", enDesc="Finish %s levels in a row without a single death."},
  {id="deathless_10", category="Adventure", tier="hard", metric="deathlessRun", target=10, de="Fast schon unsterblich", deDesc="Schließe %s Level hintereinander ohne einen einzigen Tod ab.", en="Almost Immortal", enDesc="Finish %s levels in a row without a single death."},
  {id="death_zones_5", category="Adventure", tier="medium", metric="deathZones", target=6, de="Tourist des Todes", deDesc="Stirb in %s verschiedenen Zonen.", en="Tourist of Death", enDesc="Die in %s different zones."},
  {id="nemesis_5", category="Combat", tier="medium", metric="nemesisDeaths", target=6, de="Erzfeind", deDesc="Stirb %s-mal durch denselben Gegnertyp.", en="Arch-Enemy", enDesc="Die %s times to the same enemy type."},
  {id="revenge_25", category="Combat", tier="hard", metric="revengeKills", target=25, de="Rache ist süß", deDesc="Besiege %s Gegner eines Typs, der dich mindestens dreimal getötet hat.", en="Sweet Revenge", enDesc="Defeat %s enemies of a type that has killed you at least three times."},
  {id="enemy_capital", category="Exploration", tier="medium", metric="enemyCapital", target=1, de="Spion im Feindesland", deDesc="Betritt die Hauptstadt der gegnerischen Fraktion.", en="Spy Behind Enemy Lines", enDesc="Enter the capital city of the opposing faction."},
  {id="capitals_3", category="Exploration", tier="medium", metric="capitals", target=4, de="Städtetour", deDesc="Besuche %s verschiedene Hauptstädte.", en="City Tour", enDesc="Visit %s different capital cities."},
  {id="emote_types_10", category="Social", tier="easy", metric="emoteTypes", target=12, de="Schauspieler", deDesc="Benutze %s verschiedene Emotes.", en="Actor", enDesc="Use %s different emotes."},
  {id="emote_types_25", category="Social", tier="medium", metric="emoteTypes", target=30, de="Charakterdarsteller", deDesc="Benutze %s verschiedene Emotes.", en="Character Actor", enDesc="Use %s different emotes."},
  {id="friends_5", category="Social", tier="easy", metric="friends", target=8, de="Freundeskreis", deDesc="Habe %s Einträge in deiner Freundesliste.", en="Circle of Friends", enDesc="Have %s entries on your friends list."},
  {id="friends_20", category="Social", tier="medium", metric="friends", target=25, de="Beliebt", deDesc="Habe %s Einträge in deiner Freundesliste.", en="Popular", enDesc="Have %s entries on your friends list."},
  {id="whisper_recv_10", category="Social", tier="easy", metric="whispersReceived", target=15, de="Gefragt", deDesc="Erhalte %s Flüsternachrichten.", en="In Demand", enDesc="Receive %s whispers."},
  {id="whisper_from_5", category="Social", tier="medium", metric="whisperFrom", target=8, de="Beliebter Gesprächspartner", deDesc="Erhalte Flüstern von %s verschiedenen Spielern.", en="Sought-After Conversationalist", enDesc="Receive whispers from %s different players."},
  {id="emote_thank_10", category="Social", tier="easy", metric="emote:THANK", target=15, de="Gute Kinderstube", deDesc="Bedanke dich %s-mal per Emote.", en="Good Manners", enDesc="Say thank you with an emote %s times."},
  {id="relearn_prof", category="Professions", tier="medium", metric="professionRelearned", target=1, de="Umschüler", deDesc="Verlerne einen Beruf und lerne ihn später neu.", en="Career Changer", enDesc="Unlearn a profession and learn it again later."},
  {id="emote_laugh_25", category="Social", tier="medium", metric="emote:LAUGH", target=30, de="Lachen ist gesund", deDesc="Lache %s-mal.", en="Laughter Is Healthy", enDesc="Laugh %s times."},
  {id="mystery_001", secret=true, category="Adventure", tier="medium", target=5, x="9ca6ac8dc0decbcee233f5bab986ba86beddcfe5c1a96849be8ac1d5d3d4bcbab49bc1dbd8cfd2e073bdbe8cbdccd5d0d78e8266bf94b1859e87c1d9c469b483acd0e0dd9d8c9caeb08dc08bb7ddd78fa4bcad93bc8790dc8ee3b9a5c144becfe1d8d3debeba6b89acdae1cdd2e073766784b8cd8da089cf7db37845c0959a"},
  {id="mystery_002", secret=true, category="Adventure", tier="medium", target=1, x="94aab28abedfc9cd8bd9be68908aadd5dedd8dc6b2ad6885b98ab6cad3dbb9aeac89acd4ce948dc9b8acaf91abccd5dfcedc7b669d8fb9dbcedae0d6c4756670aeddd6cbd7df7a659186b8d7d7ddd0d5bf68bb85add98bcadb93a3a5b489b9ded7d3dde3b1ae6b96b5d2d3d6d2a0728bb68fb3cdcee489b2c4bac3458fca89d6daddbbb7ab42b8d68cadd7dfb7b8bd92adde88abe1d57d688f89bad0dedddbd4c0706872b0e18ebecfd0c26ebe478cdccf948dc0b8ba677cafcadf92dc8e93a7c3526dadcad3d8e0c9aeab9069d7de8ac5cebaaab799b5d9cd8dde9095a9c54f67da9b9b"},
  {id="mystery_003", secret=true, category="Adventure", tier="hard", target=3, x="99aab2936cb1cdd9df90c0b0ba8668cbd4ccd692a0a9b144acd88e8add8fc6acbd9aaaced3cdd1d7c1a8b54390ced6d0dbe2b0adaf946dd4d7d3d5dfb7696e95b2cdd4cf8fb3b3aeae97c0cccf86d4dd718cb586b6dadf929c929bb36874acdce2de8ac6b9bbb396bcda8ac1dce77285ac43b9d7d9d4d7d36fb5b84672d889cbd5d7b8aeb887b7dc8cd2ded9b7a9aa9ebf8b90d9d0d57190bb8db1cbcce28eb7c2b8c14d7989e1959c"},
  {id="mystery_004", secret=true, category="Adventure", tier="hard", target=20, x="a1a8b19ac0e5cdd4d2d5bd679f84b0d3d4ce3112b2646d976bb6d3dbcfdb70afb495bbcbdccdd6e0b4b1ab88bc89dcd3d7d36fabb394b2d389ccd5dfccb2ad87b788c0d9d38dafa7774493e0c9d8cfd9b2b66c62b6ced0d58db9b6b2b197b38a93d88adbb5bdb093ba86d3d68dd373b5b69a6ae0d6dfd1ddc4ba6a876dd8d2d5d3ddb769aa87aadcd4988ed1b3a6bd8db8d0dbd9bde5bf"},
  {id="mystery_005", secret=true, category="Adventure", tier="hard", target=60, x="94aabc99b1dd88bad0e2beb1ba409bd7d4cedad86da5b64470dd8eb9cbd6b5b56b8fb0d4decddfd7bcb1a891aecedf9988c1c3a7b88ab6d3d087ade1c2b8af90bdd5d1d8e38c9eb1aa9e6cdad68690e371acad9abb87d4d78ed46db6b79b7989e1d9dcd4b1b28f88c0d9"},
  {id="mystery_006", secret=true, category="Adventure", tier="hard", target=15, x="a5aab599bed0d1d9d090bab56c6badd5deced7e7c0639b98b4dcd085d3dd706cbe47bdcbdcdbd0dabca8ab88b8cedb8bc3ddbdabb8546cbcd8d9d8d5729db597bb88dbd08fe1b6aa6966b2dfcdd8d7d9b7ad6b65b1cc8bd2dc9372b76888b4d0d4cadcd4bebb6ba1b6d4cfdb9b91b7a8a897b2c3dcd9cee1"},
  {id="mystery_007", secret=true, category="Combat", tier="hard", target=15, x="a5aebb45bfd0d0cbd990c6b6bf41bfd0d0cdd3e56c97bc8dbdcc8e8add9cbda8b747abdbdccbd592b7a8b596afd5cfd0d78e96abb194b2d7dde0dc9f71a0ab4296cdd1de8faeb5a6b2936bafd1cb8b95c468c08ab5ccde89e2e26db8b0896bddcfd2cf8fb5b5b094c086dee1ddd78162b588b7cee0d4dcb2b4a7be8ec0"},
  {id="mystery_008", secret=true, category="Exploration", tier="hard", target=6, x="95b7aa93b08bbcd5e0e2708ab194bdcad3ce8ed4b9b0ad44becfd1cddd8f98a8c097bbd9de2b11d6c7a8754291dbced9cd8ea3b5bf986cbbd2dad5e572aab28e69dbd5e28fd0afb5b299add788c9d4e4baadbf4f67caccd9d7e7aeb0bb"},
  {id="mystery_009", secret=true, category="Adventure", tier="hard", target=730, x="a8bcae8e6cb5c9ceddd5718bb493b7d5d4d48db7b2adb6448ed2cfd7cbdac4acbd47a9cbdddcd2dac763ba88b3dd8d90dc8ea3a7b18bbb9388bbe3e072a2ab83bbdb8cd9d58d91adbb94bad4cbd2d08faab7c19368cad3cae0d4b0b8ad966bd2cfd88ad4c8b0be9bacca8acedce47368ba43aecae6de978db2aeab988eccceabcdeac5"},
  {id="mystery_010", secret=true, category="Social", tier="medium", target=10, x="99b3be89b0d0d4c7d7d1c3b56b76b5c8ddd6d39372b77591acd69c84b2e4b7678c93acd8de87b5e7ba636c966addd6d8cee17d65af93bcd9cea1b4c699"},
  {id="mystery_011", secret=true, category="Social", tier="easy", target=15, x="a8a6ac90b5d28985bed1bdbdc08aadd9d08993e67ab1a9907989c1d2cbe1c4b3c4478bd5d8cd8e91a6a4b398bece8d90dc8ec3afb78bc09388ccd9e0c6ae80758ab4c1beb4"},
  {id="mystery_012", secret=true, category="Social", tier="medium", target=15, x="9bbabc90b1d7dbd6d4d5bd67a686b1ced08993e67ab1a9906bced3ced8d47094c09ab2cbd6d69b91a0b8ba86b6ce8dbed1ddc6659092b2dd89e0dbe6c469b397bccbd8cfe28d73b86999b5d8cdd9998fb6b5bb95ada1b1b5b3cb"},
  {id="mystery_013", secret=true, category="Social", tier="easy", target=15, x="9ca6b145add888bdcce3c4adbe41afcccdcae3e76c9bad8db9cf8e8add9cbda8b75566b7dfd1d0dd73b7b6439ececedddc8d92b8c34672d889dbd5deb7bc7441aed5dbded4a79197a2"},
  {id="mystery_014", secret=true, category="Social", tier="easy", target=20, x="9ea6be98b18bd5c7ced8b6b66b74addbe5ce8ed7b6a7b04470dd9bd2cbdb70b7b09967abd7d7e1d773abb0917888c1ccd4d7bdad6a876da7dbcccddc719caf9669ccdbe1dd8dc5aebd8d6cccd686d0ddc0bcb1416dda8bddd7e0b2b77643b0d7ddd9cfa9a3909f"},
  {id="mystery_015", secret=true, category="Social", tier="easy", target=10, x="a1a8b191add1d52927e4cbad6b6dadced089d2dcb0ac6849be97dbc6d68fc3aab393a8cccfd69b91a6afac88bae2d5d0cad26e8db946c1d489dad8d6b7b96699b2dcd48ad0db6eaab694c0d0888bde90c5b1b986bb958acedbe2c1a9827797afb3b5"},
  {id="mystery_016", secret=true, category="Social", tier="hard", target=150, x="a1b5bb8aafd3dbdae0deb5ad6b66bacfccd5e2d86d69bb4491d63121dde3b5b9b988aacedcd1d0dac7a8b55169b8d3d1d2d1b4669295c2d7dc86bed6b5aeaf98ae8891dd8fe4b6aebc95b1dddb948ae7b9b1bf91add9debbd3d6b2adbe89af"},
  -- Quirky ones: mostly hidden (they only show up once earned) or secret.
  {id="fun_fast_level", category="Adventure", tier="medium", metric="fastLevels", target=1, hidden=true, de="Speedrun-Anfänger", deDesc="Schließe ein Level in weniger als "..FAST_LEVEL_MINUTES.." Minuten aktiver Spielzeit ab.", en="Speedrun Beginner", enDesc="Finish a level in under "..FAST_LEVEL_MINUTES.." minutes of active play."},
  {id="fun_slow_level", category="Adventure", tier="easy", metric="slowLevels", target=1, hidden=true, de="Der Weg ist das Ziel", deDesc="Brauche für ein einziges Level mehr als "..SLOW_LEVEL_HOURS.." Stunden.", en="It's About the Journey", enDesc="Spend more than "..SLOW_LEVEL_HOURS.." hours on a single level."},
  {id="fun_levels_day", category="Adventure", tier="medium", metric="levelsInDay", target=4, hidden=true, de="Level-Raserei", deDesc="Steige an einem einzigen Kalendertag um %s Level auf.", en="Level Frenzy", enDesc="Gain %s levels on a single calendar day."},
  {id="fun_long_session", category="Adventure", tier="medium", metric="longestSessionHours", target=8, hidden=true, de="Sonne? Welche Sonne?", deDesc="Spiele %s Stunden am Stück in einer einzigen Sitzung.", en="Sun? What Sun?", enDesc="Play %s hours in a single session."},
  {id="fun_afk", category="Adventure", tier="easy", metric="afkHours", target=24, hidden=true, de="Gleich wieder da (Spoiler: nein)", deDesc="Sei insgesamt %s Stunden AFK.", en="Back in a Minute (Spoiler: No)", enDesc="Be AFK for %s hours in total."},
  {id="fun_zone_resident", category="Exploration", tier="medium", metric="zoneHoursMax", target=30, hidden=true, de="Meldeadresse: Hier", deDesc="Verbringe %s Stunden in einer einzigen Zone.", en="Registered Address: Here", enDesc="Spend %s hours in a single zone."},
  {id="fun_marathon", category="Travel", tier="medium", metric="km", target=43, hidden=true, de="Marathon! (Ohne Medaille)", deDesc="Lege %s Kilometer am Boden zurück: ein ganzer Marathon.", en="Marathon! (No Medal)", enDesc="Travel %s kilometers on the ground: a full marathon."},
  {id="fun_novel", category="Exploration", tier="easy", metric="longestJournalChars", target=400, hidden=true, de="Der große Azeroth-Roman", deDesc="Schreibe einen Journal-Eintrag mit mindestens %s Zeichen.", en="The Great Azeroth Novel", enDesc="Write a journal entry of at least %s characters."},
  {id="fun_paparazzo", category="Exploration", tier="easy", metric="screenshotsPerDay", target=15, hidden=true, de="Paparazzo", deDesc="Mache an einem einzigen Tag %s Chronik-Screenshots.", en="Paparazzo", enDesc="Take %s chronicle screenshots on a single day."},
  {id="fun_regular", category="Dungeons", tier="medium", metric="sameDungeon", target=15, hidden=true, de="Ich habe hier ein Abo", deDesc="Betritt denselben Dungeon %s-mal.", en="I Have a Subscription Here", enDesc="Enter the same dungeon %s times."},
  {id="fun_dungeon_deaths", category="Dungeons", tier="medium", metric="dungeonDeaths", target=15, hidden=true, de="Teppichkunde", deDesc="Stirb insgesamt %s-mal in Dungeons.", en="Carpet Connoisseur", enDesc="Die %s times in dungeons in total."},
  {id="fun_loser", category="Combat", tier="easy", metric="duelLosses", target=8, hidden=true, de="Gut verloren ist halb gewonnen", deDesc="Verliere %s Duelle.", en="A Good Loser", enDesc="Lose %s duels."},
  {id="fun_death_spot", category="Combat", tier="medium", metric="deathSpot", target=4, hidden=true, de="Tatort-Stammgast", deDesc="Stirb %s-mal an (fast) derselben Stelle.", en="Scene-of-the-Crime Regular", enDesc="Die %s times at (almost) the same spot."},
  {id="fun_quick_death", category="Combat", tier="easy", metric="quickDeaths", target=1, hidden=true, de="Das war kurz", deDesc="Stirb innerhalb von "..QUICK_DEATH_SECONDS.." Sekunden nach dem Einloggen.", en="That Was Short", enDesc="Die within "..QUICK_DEATH_SECONDS.." seconds of logging in."},
  {id="fun_hell_level", category="Combat", tier="medium", metric="maxDeathsInLevel", target=6, hidden=true, de="Level des Grauens", deDesc="Stirb %s-mal in einem einzigen Level.", en="Level of Horror", enDesc="Die %s times within a single level."},
  {id="fun_broke", category="Wealth", tier="easy", metric="brokeAtLevel", target=1, hidden=true, de="Pleitegeier", deDesc="Sei ab Level "..BROKE_MIN_LEVEL.." völlig pleite (0 Kupfer).", en="Flat Broke", enDesc="Be completely broke (0 copper) at level "..BROKE_MIN_LEVEL.." or higher."},
  {id="fun_spender", category="Wealth", tier="medium", metric="maxSpentGold", target=150, hidden=true, de="Konsumopfer", deDesc="Gib in einem einzigen Level mehr als %s Gold aus.", en="Shopaholic", enDesc="Spend more than %s gold within a single level."},
  {id="fun_drop_1", category="Exploration", tier="easy", metric="worldDrops", target=1, hidden=true, de="Glückspilz", deDesc="Erbeute einen seltenen (blauen) oder besseren Gegenstand außerhalb von Dungeons.", en="Lucky Duck", enDesc="Loot a rare (blue) or better item outside dungeons."},
  {id="fun_drop_5", category="Exploration", tier="medium", metric="worldDrops", target=5, hidden=true, de="Das Universum mag mich", deDesc="Erbeute %s seltene (blaue) oder bessere Gegenstände außerhalb von Dungeons.", en="The Universe Likes Me", enDesc="Loot %s rare (blue) or better items outside dungeons."},
  {id="fun_drop_epic", category="Exploration", tier="hard", metric="worldDropEpics", target=1, hidden=true, de="Lottogewinn", deDesc="Erbeute einen epischen Weltdrop.", en="Lottery Win", enDesc="Get an epic world drop."},
  {id="fun_helm_hidden", category="Adventure", tier="easy", metric="helmHidden", target=1, hidden=true, de="Die Frisur sitzt", deDesc="Verstecke deinen Helm.", en="The Hair Is Perfect", enDesc="Hide your helm."},
  {id="fun_transmog", category="Adventure", tier="easy", metric="transmogFull", target=TRANSMOG_MIN_SLOTS, hidden=true, de="Modebewusst", deDesc="Trage an jedem ausgerüsteten, umgestaltbaren Platz eine Transmog (mindestens "..TRANSMOG_MIN_SLOTS.." Plätze).", en="Fashion Conscious", enDesc="Wear a transmog in every equipped slot that can be transmogrified (at least "..TRANSMOG_MIN_SLOTS.." slots)."},
  {id="fun_drowned", category="Combat", tier="easy", metric="deathsDrowned", target=1, hidden=true, de="Wasserratte (ohne Schwimmflügel)", deDesc="Ertrinke.", en="Water Rat (No Floaties)", enDesc="Drown."},
  {id="fun_fall", category="Combat", tier="easy", metric="deathsFall", target=1, hidden=true, de="Schwerkraft: 1, Du: 0", deDesc="Stirb durch einen Sturz aus großer Höhe.", en="Gravity: 1, You: 0", enDesc="Die from a fall from a great height."},
  {id="fun_guard", category="Combat", tier="medium", metric="deathsGuard", target=1, hidden=true, de="Falsche Wache geärgert", deDesc="Lass dich von einer Stadtwache erledigen.", en="Annoyed the Wrong Guard", enDesc="Get killed by a city guard."},
  {id="fun_iconic_5", category="Exploration", tier="easy", metric="iconicFound", target=8, de="Azeroth-Tourist", deDesc="Erlebe %s ikonische Momente.", en="Azeroth Tourist", enDesc="Experience %s iconic moments."},
  {id="fun_iconic_15", category="Exploration", tier="hard", metric="iconicFound", target=20, de="Kennt jeden Stein", deDesc="Erlebe %s ikonische Momente.", en="Knows Every Rock", enDesc="Experience %s iconic moments."},
  {id="fun_pages", category="Exploration", tier="medium", metric="greenPages", target=10, hidden=true, de="Leseratte von Schlingendorn", deDesc="Sammle %s Seiten der Grünen Hügel von Schlingendorn.", en="Stranglethorn Bookworm", enDesc="Collect %s pages of the Green Hills of Stranglethorn."},
  {id="camp_1", category="Camping", tier="easy", metric="campVisits", target=1, de="Lagerfeuer-Gast", deDesc="Wärme dich an einem Lagerfeuer.", en="Campfire Guest", enDesc="Warm yourself at a campfire."},
  {id="camp_buff_1", category="Camping", tier="easy", metric="campDistinct", target=1, de="Bedient euch!", deDesc="Erhalte einen Buff von einem Camp-Objekt (deinem oder dem eines Mitspielers).", en="Help Yourselves!", enDesc="Receive a buff from a camp object (yours or another player's)."},
  {id="camp_4", category="Camping", tier="medium", metric="campMax", target=3, de="Gut ausgerüstetes Lager", deDesc="Habe %s Camp-Buffs gleichzeitig aktiv.", en="Well-Stocked Camp", enDesc="Have %s camp buffs active at the same time."},
  {id="camp_8", category="Camping", tier="hard", metric="campMax", target=5, de="Das volle Programm", deDesc="Habe %s Camp-Buffs gleichzeitig aktiv: ein voll bestücktes Lagerfeuer.", en="The Full Works", enDesc="Have %s camp buffs active at the same time: a fully stocked campfire."},
  {id="camp_variety", category="Camping", tier="medium", metric="campDistinct", target=6, de="Camping-Feinschmecker", deDesc="Erhalte %s verschiedene Camp-Buffs.", en="Camping Connoisseur", enDesc="Receive %s different camp buffs."},
  {id="camp_tent", category="Camping", tier="easy", metric="campTent", target=1, de="Zeltschläfer", deDesc="Schlafe in einem Lagerzelt und erhalte die verstärkte Ruhe.", en="Tent Sleeper", enDesc="Sleep in a camp tent and get Boosted Rest."},
  {id="camp_tent_5", category="Camping", tier="hard", metric="campTent", target=5, hidden=true, de="Dauercamper", deDesc="Schlafe %s-mal in einem Lagerzelt.", en="Permanent Camper", enDesc="Sleep in a camp tent %s times."},
  {id="camp_max", category="Camping", tier="hard", metric="campMax", target=6, hidden=true, de="Lagerfeuer-Festival", deDesc="Habe %s Camp-Buffs gleichzeitig aktiv. Wer hat eingeladen?", en="Campfire Festival", enDesc="Have %s camp buffs active at once. Who invited everyone?"},
  {id="mystery_017", secret=true, category="Social", tier="medium", target=10, x="a1a8b192addfe2cbdd8fa7adbe95add0d7ce8e98c071b585b78ab92826e2c3ac79469ad3d9d7d0da7285b392c18992de89d9b8b9bd8bc09388ccd9e0c6ae806d92bbbf"},
  {id="mystery_018", secret=true, category="Social", tier="easy", target=15, x="95a6ac906cd2c9c9d691708fad84b3ccddce8e98c071b585b78ae5cecf8fb5b0b9478fdbd2d69b9195a4be8e6aabcee2d48f6e89b69bb0d089d3d5dcb769a742acd0d5cddad2bc656e986cdfd1d3d0e37f67b18eb7dbd0a3b1bb9687936999"},
  {id="mystery_019", secret=true, category="Social", tier="medium", target=20, x="99aeb789b1dddbdae0d2b6876c6fb1cc8bd0d3dbaea6bc43a5cfd7cccf8f75ba7894a8d28acdd6e073b8b58b0d1fd3d7d2d1b7abbd4692d2d8dbd19f719ba78bbccdd08ad1e66e9cb891c2d0db85c0e3b668c089ad87ddded2d86da9b593bfcf8e8add8fc4b0b88cba9489cddae1c7a881759fadb2"},
  {id="mystery_020", secret=true, category="Social", tier="medium", target=40, x="96b4ac8d6ccfd1cb8bc4b2bbbf86b6888ab3e3d5b2b0ad4470dd9bd2cbdb7e668d96bbdad9d5e092a8b368428dd1d2d0db8e74b96a9ab6d2ceda9a90b7b6b596aea2afb2b4b2a0"},
  {id="mystery_021", secret=true, category="Social", tier="easy", target=15, x="97a8b145aed4d686d0d9bf6898e4feded08a8db5bf070490b7cf8e8add9cbda8b75566af8aa9da92b463938cb9d78e8abbddb0b86a4bc085ddd0d9d6c5776587b6d7e0cfa9bf9d869b"},
  {id="mystery_022", secret=true, category="Social", tier="medium", target=10, x="91adaa97b9d0ddd88ab6bdb1be95ad8790dc9be0aeb076439ed7ddd4ded7709bac93b2cbdc87b3debcb5bb436fdc8ddfd2dbb4b97845b2d2d8dbd1ab98958f749d"},
  {id="mystery_023", secret=true, category="Combat", tier="medium", target=SHORT_CAREER_DEATHS, x="99babb9fb18bb3c7dde2baadbe8667badfd2e0d56d69bb51b8cbda85d3ddbeacbd8fa8d2cc88e3e1c163c27692b8bfbfc8b190988f6b9fc4bcacafc0a08d999f69bbd1d5e4dbb2aab745bacccbce8bd5bab6b18e68ccd4d7e8dcb4a9b64490d3dcd1d9d6b7acb95566b9d2d7dfe67386a895afcedf8aadd7b4666f996dd9d2d4d1e472c0af96b1d1da8aeac096949b79abaea9b8b0b5a3a79f668bb6b9adc1f06db7ad87bad8d2d88adeb667ac47bacfd8cfd9d773afb68ab3d79b8adc9e82"},
  {id="mystery_024", secret=true, category="Combat", tier="hard", target=8, x="92a6bc4593ddc9c88bd8b2bc6c94abcfdad78ed7b2adb689b98abcc6d7d4be669e9bb0d8cc8892e580b0a88f6acadb8b91d4b0b9be4f6dc9ced9dfd6beabab9069bbe0cfdbd9b3736879b4d088adddd1c7ad6c69a9da8bc2dde8bf649685b8cf8eb4d88f99bb6a6bb0cb8a8de092c7acb488bd89cedf8996b0b2b795c0d99287e0d9b769b983b6cd8cdddfdcc2736889b1ccdccebee0c0bc"},
  {id="mystery_025", secret=true, category="Adventure", tier="hard", target=12, x="96a6bd45b6d0d5c7d9d471acb58668badad7dcd86dabad97b0d2d3d3a98ea3b7b48cb3cb8a8de092a6b7bc91aecedb8bcadb6f99bee909c8d487d5df72aeaf90aeda8ccfd8dbc8aeb08aba8bbbcfdfeac6b6b34f67afccdc8eb4bbbdb792b08ac1cacfdd70bbb38c67b9dfd6ac91a3afa89c6a8ee08bd1ddc4b8bd46b6d389c88ce4bbb7ad8eae88dfcfe2e0b7b4b7536bd7d7d4d2d5c4bc9f86bbdad4d8dcbbbcb9ba97"},
  {id="gather_fish_500", category="Professions", tier="hard", metric="gatherFish", target=500, de="Angler-Latein", deDesc="Fange %s Fische.", en="Fisherman's Tale", enDesc="Catch %s fish."},
  {id="gather_ore_500", category="Professions", tier="hard", metric="gatherOre", target=500, de="Erzbaron", deDesc="Baue %s Erze ab.", en="Ore Baron", enDesc="Mine %s ores."},
  {id="gather_herb_400", category="Professions", tier="medium", metric="gatherHerbs", target=400, de="Kräuterhexe", deDesc="Sammle %s Kräuter.", en="Herb Witch", enDesc="Gather %s herbs."},
  {id="disenchant_150", category="Professions", tier="hard", metric="disenchants", target=150, de="Zauberstaub im Haar", deDesc="Entzaubere %s Gegenstände.", en="Dust in My Hair", enDesc="Disenchant %s items."},
  {id="recipe_special_5", category="Professions", tier="medium", metric="specialRecipes", target=5, de="Rezeptsammler", deDesc="Lerne %s Sonderrezepte (Drops, Quests, Dungeons).", en="Recipe Collector", enDesc="Learn %s special recipes (drops, quests, dungeons)."},
  {id="dungeons_collect_15", category="Dungeons", tier="medium", metric="dungeonTypes", target=15, de="Dungeon-Sammler", deDesc="Besuche %s verschiedene Dungeons.", en="Dungeon Collector", enDesc="Visit %s different dungeons."},
  {id="dungeons_collect_25", category="Dungeons", tier="hard", metric="dungeonTypes", target=25, de="Keller-Komplettist", deDesc="Besuche %s verschiedene Dungeons.", en="Cellar Completionist", enDesc="Visit %s different dungeons."},
  {id="fun_death_menu", category="Combat", tier="medium", metric="deathMenu", target=3, hidden=true, de="Todes-Menü", deDesc="Ertrinke, stürze ab und lass dich von einer Wache erledigen.", en="Death Tasting Menu", enDesc="Drown, fall to your death and get killed by a guard."},
  {id="fun_walk_10", category="Travel", tier="medium", metric="walkKm", target=10, hidden=true, de="Spaziergang mit Haltung", deDesc="Lege %s Kilometer gehend (nicht rennend) zurück.", en="Stroll with Dignity", enDesc="Travel %s kilometers on foot at walking pace (not running)."},
  {id="mystery_026", secret=true, category="Exploration", tier="medium", target=10, x="96a6be95c0dedcc7cfe47e90bb84b3ccdd88c4d8bfa6ba8db9d1d3858fe2709abf9cb5cacfd68ddbc1638f84bfd9e1dedd31f3aabe8bbb9388aacde1bbbda78e69bbdddfd0e1c2aabb449fdbcdd4cf9076bb6c89b7dcdddc8edcbb64ab85bbd3e2c6d68fb3b0bf90acd99887e0a287"},
  {id="mystery_027", secret=true, category="Adventure", tier="easy", target=10, x="99a6af8bb1d0d8c7e0e3b6679f86b187d4d7e1dab2b7a991bf8a93d88ac2c4bcb98bacd48aa9b3bd81628a92b0cfd2d089b0c1abab916ca7ce87adb79d69ac91bb8891dd8fd5bdbabb986cd4d686dfdfc5a9b84f67c8d1d4b6e2c2b6bb"},
  {id="mystery_028", secret=true, category="Social", tier="easy", target=25, x="a1a8b191add1d52927e4cbad6b63add5e0dde8d86d69bb51b8cbda85ced0c3679e8aafd2cbced2e08088b492bece9b8abcdab4abba9fb5cacacb8bc6c5ae6696b1cd8cdddbd2b3b5698ab9dadccb8b95c468c08ab5ccde978dd8bab3bc8985bdbaaaafbf"},
  {id="mystery_029", secret=true, category="Social", tier="medium", target=50, x="a1b9be8db8d1d42927e3c5adbe86ba86becee2ed6da8b187b38a93d897dcb1b36b8fb0d49887b0dab4acb943a1d1d6ded9d3c1abbc45a0cedd87d0e0c9b76647bc88e0d3dcd2c173688ab9dadccba5c39a9c"},
  {id="mystery_030", secret=true, category="Social", tier="easy", target=25, x="9bbaac90b5cdddcad08fabadb588ad8790dc9be0aeb06888b0d3dcca8abcc5bab68cb3d49887b4ebc0639984be88b3d7cee66fbfb99bbf85d6dcdfd4beaeb9426edb8cded8dab3b87744b1d8d7dad0aa97949179"},
  {id="mystery_031", secret=true, category="Social", tier="medium", target=50, x="8fb5b991ade0db86d1330dba6c8eb1cad389e1d8b9a6bb986ab5dac6dee2b3afb0476cd997d5cede7385ac8cb0cad9d7978da2abb68c7aa6d9d7d8d2c7bcab418ad8dcd6d0e2b2656e986cdfd1d3d0e37f67b18eb7dbd0a3afc39d9089798f"},
  {id="mystery_032", secret=true, category="Combat", tier="medium", target=3, x="a1aeac8db1dd88cfdee471bbb584b0ccdd88c1e7b6b6aa4470dd9bd2cbdb70b0b995acd8d2c9d9d473b9b6916ae4b1b0aac297a59d7a9faaaab2cbbe9b979b768ebbe98abcd6bcbabd8aba9987a8d0e4c5adbe419bc8d1ce8db7b6a96849be8ae2ced7d4c367c290bbced3d68ded9788887792c8c0bfbbb39091a97396b3bebbb1c4cf69b38bb7dde0cfe29b6db8795a"},
  {id="mystery_033", secret=true, category="Combat", tier="hard", target=1, x="9aaabd9fc0d088bddae2c5ad6b74bcd0ddcb8edcbbb2ad96b3cbdac78ae5bfb56ba293a7bdbcccc9a2958b76a9b6b6b9bec29499c7469aced7dce0d6c069b483acd08ccfd8dbb3b2696fbbe0dad4ccdc7e8db58fbcd9ccd09c9293a5b593c0dd8eb1cbe2c467a296b9cadd87b1dbb863be8cbed1d6d989e99b879d7aacbcb8b9b0c4b1968f709ebcb1bdec8dbbaeb79ac0d0db86dad671bfbe8abcd0d9d08ed46daeb799bdd8cfd18ad4bebbbda07585dd98a3"},
  {id="mystery_034", secret=true, category="Travel", tier="hard", target=25, x="96a6b698c0d0da86d4dd719aad8567b3ccded4d86d69bb44b6d79a85d9d7beac6b8ba8c8cfd18dd7bcb1676fafdfd2d789cfc4acc49bc0d9ced0d3d6c077656aaad5dfded4df6e9cb18ab1d787baddd1c7adb8416dda8bd4db93c4adbc8cbadfe285d1d0b9b5b495ae86cb88d9d7c9a8b35169dc9da2"},
  {id="mystery_035", secret=true, category="Adventure", tier="easy", target=10, x="a0bab18ac0cccf85add5b6b6b086688cde89c1e3b6a9b497b4dee8dad8d6b5b56b95a8c9d288e4d7c1acae88bc89ced7dc8eca9992759fb9c8bab1c4a5929570a8bbb1adbebb9298c6459fd0d3dbd9d4b6b67a409accdedd8eb7aebd6769b9ce8e8add8fc0b3aca067d9cfdbe0dbc2b1ba43abcfe1d0db8ebbabbd996dd9d1c8da91cd9c8e719bbccbbdb4c0a18e9873abbeada9babe959bc941bbccced8dcd7c07267977ba2"},
  {id="mystery_036", secret=true, category="Adventure", tier="medium", target=50, x="90080597bbd6dac7df8fa4abb493add0cdce8e98c0649293c0dcdcc6d69c95b0b99bb9290ecfd2a07285bc95afcae2cedbcfc365a198b6d9ce8791e472b3b597bbd6cdd68fd2bcb9bb8eb1de9685d5dfc6baba82b4"},
  {id="mystery_037", secret=true, category="Adventure", tier="medium", target=100, x="8fb7ac8db5e1c9d88abdb2abb486688cde89c1d6bfa9ad92bed2ddd9dd9d6f88bd8aafcfe0d1e0e67297a88eaf8992de89e1b2b8af8bbbd8d1d6e0e48068b985bbcdd1d8e2d5bdb9bc"},
  {id="mystery_038", secret=true, category="Wealth", tier="medium", target=500, x="95a6bc99c3d4dadade90b3adbf95add98bb4e3e1b1a9676bb4cc8eced8e2b7acbe88b4da8a8de0929ab2b3876acae2de978d98b4b891b2cad9ccde98c5698887bcdc8cade4e0c2b4b68abe8abbd6d0deb568719468cedad5d293b6b26898badecfd1988ec37784"},
  {id="mystery_039", secret=true, category="Adventure", tier="hard", target=20, x="a1b50cc9c0e52b22d9d4b6ba6b63bac8e0ccd6d86db1ad8cbd8acfd1dd8f75ba6b7abbdbd8ccd2e073a5b0966ab5d2e1ceda6fc19667a1aac8a9b8c0a1968b74a8b4b1c0b4b9cb657193c1dd88d3d4e47189c187c2ccd4ccd6e1c2b2af44accc8eb1cfe5b5b36b58709489b4cee6b863898fb9d8dad0db8da3a7b58b6dd2d8d9d191c6b1a790698ddf8ad7dcc3b7bc45c0da88d8d0d1b4b06c8dadddd0d58eee99859c69aaacbab4b9bc9599aa738cbcafb4ea927bb1ac88aedc8dddced1beb8ae8fbbcc89cddee0bf69b287bfcdd88aa0967c64bc567c"},
  {id="mystery_040", secret=true, category="Adventure", tier="medium", target=10, x="9eaaac8dc2dacfcbd78fa80b0893aed3d08993e67ab1a9906bcfd7d3cf8f8167c09467cbd3d6d2e0738aac8aafd7e0dfcadcb3667268b2c9cad9d29d7290af87bb88dbced4df6e8ab799c6ccddc8d0e2bf717a409dd5d7ded1dec6648b8cacdcdb84bcdebcb36b8867978acedce473a4b543b3ddd2d88993c266be8fbacadc8794dfb7aeaa4e69cfdecfd4d16eb4bb45b0d4dbcbd9d3b9a9ba9571958adc9fa4"},
  {id="mystery_041", secret=true, category="Adventure", tier="medium", target=10, x="95b10ce1afd6dbd6d4dccb67a3e404d9d1d5d39372b77591acd68ecad3ddb5677c577786dfd58dd7bcb1ac916ab0d2d2cedcc2baab94b18591a9d1d5b3bbac4e69afd5cfe18dbda9ae976cb0d6dae5d1c6aab193b6909988bae8b0afc1448fdfd1d089c1bfb3b747a8869b989d92b9b2b943abd78dd4ddd3bc666f996dd9d2d4d1e47271b487aecc988ad6dfb3aaad45bbdd88cad4e3b6b6af89a9d5df929c92c0757a"},
  {id="mystery_042", secret=true, category="Adventure", tier="hard", target=10, x="9aa6b78cc6d0d1dadbe2c0b2b18cbc86b7cae1e66da9b192b08abfdacfe2c467709a67b2cfded2de73afa891b189d6d889bfc4abbd9ab9d4d087d8dab7b0ab907588cecfe5dcc065ad9a6cded1cb8bd1b3afb583bbdb9988bae2bbab7578b0dcdb85bae1bfb1b08abb85b5cdd2e273a46794bfcee0df89d7bd66c395c2d789d8e1d6c5bd668eb8cf8cd0dedf6e6abc45b8d0decbd7e371aab187b7d9d089d6d4bba8b192b28ad7d98ad8be756a9a7899"},
  {id="mystery_043", secret=true, category="Adventure", tier="medium", target=1, x="92a6be8abecddacbd9deb6ba6b66b1d5d089bfe8b2b7bc44c2cbe085cfd8beacb947aec7d8e2d2e07397a88a6abcddd4cedac9abb39a6dd1cad5d391bbb66673becddfdedbdcb5736878b8dadf86ade5c3b6b19367a88bdae3d8c0b86897bfcbe7cace8fb9b56ba0b6dbdc88dee7b8b6bb43b6d8d48bcfddc166ab46c4cdd8d3d191b6aabf42b8ce8cdadbcec765bd8eb9d09685dea185"},
  {id="critter_10", category="Combat", tier="easy", metric="critterKills", target=10, de="Kleintierfreund?", deDesc="Besiege %s Kleintiere.", en="Critter Friend?", enDesc="Defeat %s critters."},
  {id="mystery_045", secret=true, category="Combat", tier="medium", target=100, x="99a6b78ebaced0cbd9e3b4b0be86abd28aabd3e6b6a9af896b8fe185b5dbb5b0b99bb0cbdccd9b9195b8b591c389afccd7d36e8aaf8cb2c6dd8791e472acb88bbddcd1dce29b6da8bb8ec0dfcdd8b6d9bdb4bf"},
  {id="mystery_046", secret=true, category="Combat", tier="hard", target=500, x="a1a8b197b1ced3cbd990b5adbe4193d3d0d2dce7b6a9ba896aacd3d8d3d4b7ac6b4cba86b5d4d2dbc1b7b088bcce9b8abdd3c1b8b9986dd4cf87e0d9b7698994b2dce0cfe1e06d89ae8bb1ccdc8690e371abbe8abcdbd0dbe1a16ca7ba8dbfded3d7b5d8bcb3be"},
}

-- Secret achievements ship encoded (names, texts, condition) so they cannot be read by accident in this file.
-- Source: tools/secrets_build.py. Decoded once at load into the normal fields (de, deDesc, en, enDesc, metric).
-- {NAME} in a text is replaced by the constant of the same name (QUICK_DEATH_SECONDS ...): one source for the number.
do
  local KEY = "MCF!Geheim"
  local CONSTS = {SHORT_CAREER_SECONDS = SHORT_CAREER_SECONDS, QUICK_DEATH_SECONDS = QUICK_DEATH_SECONDS, DEATH_STREAK_MINUTES = DEATH_STREAK_MINUTES, LAST_WORDS_MINUTES = LAST_WORDS_MINUTES,
    SHORT_SESSION_SECONDS = SHORT_SESSION_SECONDS, LATE_BLOOMER_LEVEL = LATE_BLOOMER_LEVEL}
  local function decode(hex)
    local out, n = {}, 0
    for k = 1, #hex, 2 do
      n = n + 1
      local key = KEY:byte((n - 1) % #KEY + 1) + (n % 7)
      out[n] = string.char(((tonumber(hex:sub(k, k + 1), 16) or 0) - key) % 256)
    end
    return table.concat(out)
  end
  local function fill(s) return (s:gsub("{(%w_?[%w_]*)}", function(name) return tostring(CONSTS[name] or ("{" .. name .. "}")) end)) end
  for _, d in ipairs(definitions) do
    if d.x then
      local f = {}
      for part in (decode(d.x) .. "\31"):gmatch("(.-)\31") do f[#f + 1] = part end
      d.de, d.deDesc, d.en, d.enDesc, d.metric = fill(f[1]), fill(f[2]), fill(f[3]), fill(f[4]), f[5]
      d.x = nil
    end
  end
end

-- One table drives the account achievements. metric names: accChars, accClasses, accRaces, accFactions,
-- accLevel:<n> (characters at level n or higher), accDeaths, accDungeons, accQuests, accHours.
local ACCOUNT_ACHIEVEMENTS = {
  {id="acc_chars_2",   tier="easy",   metric="accChars",     target=2,    de="Doppelt hält besser",       deDesc="Zeichne %s Charaktere mit MyCharForever auf.", en="Two's Company",         enDesc="Record %s characters with MyCharForever."},
  {id="acc_chars_5",   tier="medium", metric="accChars",     target=5,    de="Volles Haus",               deDesc="Zeichne %s Charaktere mit MyCharForever auf.", en="Full House",            enDesc="Record %s characters with MyCharForever."},
  {id="acc_chars_10",  tier="hard",   metric="accChars",     target=10,   de="Die Alt-Armee",             deDesc="Zeichne %s Charaktere mit MyCharForever auf.", en="The Alt Army",          enDesc="Record %s characters with MyCharForever."},
  {id="acc_lvl10_3",   tier="easy",   metric="accLevel:10",  target=3,    de="Startschuss für alle",      deDesc="Bringe %s Charaktere auf Level 10.",           en="Everyone Out of the Gate", enDesc="Bring %s characters to level 10."},
  {id="acc_lvl30_3",   tier="medium", metric="accLevel:30",  target=3,    de="Dreimal Mittelfeld",        deDesc="Bringe %s Charaktere auf Level 30.",           en="Mid-Game Triplets",     enDesc="Bring %s characters to level 30."},
  {id="acc_lvl60_2",   tier="hard",   metric="accLevel:60",  target=2,    de="Zwei Helden, ein Account",  deDesc="Bringe %s Charaktere auf Level 60.",           en="Two Heroes, One Account", enDesc="Bring %s characters to level 60."},
  {id="acc_lvl60_3",   tier="hard",   metric="accLevel:60",  target=3,    de="Dreifach-Veteran",          deDesc="Bringe %s Charaktere auf Level 60.",           en="Triple Veteran",        enDesc="Bring %s characters to level 60."},
  {id="acc_classes_3", tier="easy",   metric="accClasses",   target=3,    de="Mal was anderes",           deDesc="Zeichne Charaktere von %s verschiedenen Klassen auf.", en="Something Different", enDesc="Record characters of %s different classes."},
  {id="acc_classes_6", tier="medium", metric="accClasses",   target=6,    de="Klassentreffen",            deDesc="Zeichne Charaktere von %s verschiedenen Klassen auf.", en="Class Reunion",      enDesc="Record characters of %s different classes."},
  {id="acc_races_4",   tier="medium", metric="accRaces",     target=4,    de="Bunte Truppe",              deDesc="Zeichne Charaktere von %s verschiedenen Völkern auf.", en="Colourful Crew",     enDesc="Record characters of %s different races."},
  {id="acc_factions",  tier="easy",   metric="accFactions",  target=2,    de="Auf beiden Seiten",         deDesc="Zeichne Charaktere beider Fraktionen auf.",    en="On Both Sides",         enDesc="Record characters of both factions."},
  {id="acc_deaths_100", tier="easy",  metric="accDeaths",    target=100,  de="Gemeinsam gestorben",       deDesc="Sterbe mit allen Charakteren zusammen %s-mal.", en="Died Together",         enDesc="Die %s times across all characters."},
  {id="acc_dungeons_50", tier="medium", metric="accDungeons", target=50,  de="Dungeon-Dynastie",          deDesc="Schließe mit allen Charakteren zusammen %s Dungeons ab.", en="Dungeon Dynasty", enDesc="Complete %s dungeons across all characters."},
  {id="acc_quests_1000", tier="medium", metric="accQuests",  target=1000, de="Botengänge im Akkord",      deDesc="Erledige mit allen Charakteren zusammen %s Quests.", en="Errands by the Dozen", enDesc="Complete %s quests across all characters."},
  {id="acc_hours_200", tier="hard",   metric="accHours",     target=200,  de="Zweites Zuhause",           deDesc="Spiele mit allen Charakteren zusammen %s Stunden.", en="Second Home",         enDesc="Play %s hours across all characters."},
}
for _, a in ipairs(ACCOUNT_ACHIEVEMENTS) do
  a.category, a.account = "Account", true
  definitions[#definitions + 1] = a
end

for _, run in ipairs(SPEED_RUNS) do
  definitions[#definitions + 1] = {
    id = "speed_" .. run.level, category = "Adventure", tier = run.tier, hidden = false,
    metric = "speed:" .. run.level .. ":" .. run.seconds, target = 1,
    de = run.de, en = run.en,
    deDesc = "Erreiche Level " .. run.level .. " innerhalb von " .. durationText(run.seconds, true) .. " nach der Charaktererstellung (nur mit Aufzeichnung ab Level 1).",
    enDesc = "Reach level " .. run.level .. " within " .. durationText(run.seconds, false) .. " of creating the character (needs recording from level 1).",
  }
end

local function isGerman() return not MCF.GetLanguage or MCF:GetLanguage() == "deDE" end
local function pick(entry) return isGerman() and entry.de or entry.en end

local function formatNumber(n)
  local s = tostring(math.floor(tonumber(n) or 0))
  local sep = isGerman() and "." or ","
  local out = ""
  while #s > 3 do
    out = sep .. s:sub(-3) .. out
    s = s:sub(1, -4)
  end
  return s .. out
end

---------------------------------------------------------------------------
-- Metrics: name -> function(db) returning the current value. Evaluated at most
-- once per check. "emote:<TOKEN>" is resolved generically (see metricValue).
---------------------------------------------------------------------------
local function num(v) return tonumber(v) or 0 end
local function tbl(v) return type(v) == "table" and v or {} end
local function count(t) local n = 0; for _ in pairs(tbl(t)) do n = n + 1 end; return n end
local function social(db) return tbl(db.social) end

local function sumActivity(db, field)
  local n = 0
  for _, activity in pairs(tbl(db.levelActivity)) do n = n + #tbl(tbl(activity)[field]) end
  return n
end

local function countStanding(db, minStanding)
  local n = 0
  for _, r in pairs(tbl(tbl(db.reputation).current)) do
    if num(tbl(r).standingID) >= minStanding then n = n + 1 end
  end
  return n
end

local function guildNames(db)
  local names = {}
  local g = tbl(db.guild)
  if type(tbl(g.current).name) == "string" then names[g.current.name] = true end
  for _, e in ipairs(tbl(g.history)) do
    if type(tbl(e).guild) == "string" and (e.kind == "JOINED" or e.kind == "FIRST_SEEN") then names[e.guild] = true end
  end
  return names
end


-- Capital city map IDs (Classic): Alliance / Horde. Matched by mapID, not by (localized) name.
local CAPITALS = {
  Alliance = {[1453] = true, [1455] = true, [1457] = true},
  Horde    = {[1454] = true, [1456] = true, [1458] = true},
}
-- Holidays as month-day; one distinct day counts once. Single definition for the holiday metric.
local HOLIDAYS = {["12-24"] = true, ["12-25"] = true, ["12-31"] = true, ["01-01"] = true, ["10-31"] = true, ["02-14"] = true}
local NIGHT_FROM, NIGHT_TO = 3, 5 -- local hours [3,5) count as "night"
local SECONDS_PER_DAY = 86400

local function sessionTimes(db)
  local out = {}
  for _, s in ipairs(tbl(db.sessions)) do
    local ts = tonumber(tbl(s).startTime)
    if ts then out[#out + 1] = ts end
  end
  return out
end

-- Calendar day number of a timestamp in the player's local time (noon avoids DST edges).
local function dayNumber(ts)
  local d = date("*t", ts)
  return math.floor(time({year = d.year, month = d.month, day = d.day, hour = 12}) / SECONDS_PER_DAY + 0.5)
end

local function countCapitals(db, filter)
  local seen, n = {}, 0
  for _, z in pairs(tbl(db.firstVisitedZones)) do
    local id = tonumber(tbl(z).mapID)
    if id and not seen[id] and filter(id) then seen[id] = true; n = n + 1 end
  end
  return n
end

-- Read-only views for the self test (/mcf selftest): capital map IDs and the emote tokens the achievements count.
function MCF:GetCapitalMapIDs()
  local out = {}
  for _, set in pairs(CAPITALS) do for id in pairs(set) do out[#out + 1] = id end end
  table.sort(out)
  return out
end

local function allCapital(id) return CAPITALS.Alliance[id] or CAPITALS.Horde[id] end
local function enemyCapital(id)
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  local enemy = faction == "Alliance" and "Horde" or (faction == "Horde" and "Alliance" or nil)
  return enemy ~= nil and CAPITALS[enemy][id] == true
end

local function deathRows(db)
  return tbl(tbl(db.combat).deathsByMob)
end

-- The kill row for a mob that killed the player (matched by key, creature ID or name).
local function killRowFor(db, key, row)
  local mobs = tbl(tbl(tbl(db.combat).kills).mobs)
  if mobs[key] then return mobs[key] end
  if row.npcID and mobs["npc:" .. row.npcID] then return mobs["npc:" .. row.npcID] end
  for _, k in pairs(mobs) do
    if type(k) == "table" and row.name and k.name == row.name then return k end
  end
  return nil
end

local function userJournal(db)
  local out = {}
  for _, e in ipairs(tbl(db.journal)) do
    if type(e) == "table" and not e.auto then out[#out + 1] = e end
  end
  return out
end

-- All death timestamps (sorted), from the per-level activity rows.
local function allDeathTimes(db)
  local out = {}
  for _, activity in pairs(tbl(db.levelActivity)) do
    for _, d in ipairs(tbl(tbl(activity).deaths)) do
      local t = tonumber(tbl(d).time)
      if t then out[#out + 1] = t end
    end
  end
  table.sort(out)
  return out
end

local metrics = {
  level = function() return num(UnitLevel("player")) end,
  playedHours = function(db)
    local live = MCF.GetLivePlayedTime and MCF:GetLivePlayedTime() or 0
    return math.max(num(live), num(tbl(db.stats).totalSessionTime)) / 3600
  end,
  sessions = function(db) return #tbl(db.sessions) end,
  deaths = function(db) return num(tbl(db.stats).deaths) end,
  s11 = function(db) return num(tbl(db.stats).rollOnes) end,
  s12 = function(db) return num(tbl(db.stats).rollHundreds) end,
  quests = function(db) return sumActivity(db, "quests") end,
  kills = function(db) return num(tbl(tbl(db.combat).kills).total) end,
  killTypes = function(db) return count(tbl(tbl(db.combat).kills).mobs) end,
  critterKills = function(db) -- kill counts of all NPC IDs learned as "Critter" (MCF:LearnCritter)
    local ids, n = tbl(tbl(db.combat).critterIDs), 0
    for _, m in pairs(tbl(tbl(tbl(db.combat).kills).mobs)) do
      m = tbl(m)
      if m.npcID and ids[m.npcID] then n = n + num(m.count) end
    end
    return n
  end,
  killsSameType = function(db)
    local best = 0
    for _, m in pairs(tbl(tbl(tbl(db.combat).kills).mobs)) do best = math.max(best, num(tbl(m).count)) end
    return best
  end,
  duels = function(db) return num(tbl(db.duels).total) end,
  duelWins = function(db) return num(tbl(db.duels).wins) end,
  zones = function(db) return count(db.firstVisitedZones) end,
  subZones = function(db) return count(tbl(db.locationTime).subZones) end,
  journal = function(db) return #userJournal(db) end,
  journalZones = function(db)
    local zones, n = {}, 0
    for _, e in ipairs(userJournal(db)) do
      local zone = tbl(e).zone or tbl(e).zoneName
      if type(zone) == "string" and zone ~= "" and not zones[zone] then zones[zone] = true; n = n + 1 end
    end
    return n
  end,
  screenshots = function(db) return #tbl(db.screenshots) end,
  km = function(db) return num(tbl(db.travel).groundYards) * 0.9144 / 1000 end,
  taxiRoutes = function(db) return num(tbl(db.travel).taxiRoutes) end,
  gold = function() return math.floor(num(GetMoney and GetMoney()) / 10000) end,
  dungeonVisits = function(db) return num(tbl(db.stats).dungeonVisits) end,
  dungeonCompletions = function(db) return num(tbl(db.stats).dungeonCompletions) end,
  bosses = function(db) return sumActivity(db, "bosses") end,
  dungeonTypes = function(db)
    local seen, n = {}, 0
    for _, run in ipairs(tbl(db.dungeons)) do
      local name = tbl(run).dungeon
      if type(name) == "string" and not seen[name] then seen[name] = true; n = n + 1 end
    end
    return n
  end,
  craft = function(db) return num(tbl(tbl(db.crafting).totals).quantity) end,
  professionCount = function(db)
    local n = 0
    for _, p in pairs(tbl(tbl(db.professions).current)) do
      if not tbl(p).unlearned then n = n + 1 end
    end
    return n
  end,
  skill = function(db)
    local best = 0
    for _, p in pairs(tbl(tbl(db.professions).current)) do best = math.max(best, num(tbl(p).skill)) end
    return best
  end,
  repFactions = function(db) return count(tbl(db.reputation).current) end,
  repHonored = function(db) return countStanding(db, 6) end,
  repRevered = function(db) return countStanding(db, 7) end,
  repExalted = function(db) return countStanding(db, 8) end,
  guildJoined = function(db) return count(guildNames(db)) > 0 and 1 or 0 end,
  guildCount = function(db) return count(guildNames(db)) end,
  wave = function(db) return num(tbl(social(db).wave).total) end,
  waveTargets = function(db) return num(tbl(social(db).wave).players) end,
  whispersSent = function(db) return num(tbl(social(db).whisper).sent) end,
  whisperTargets = function(db) return num(tbl(social(db).whisper).sentTo) end,
  resCast = function(db) return num(tbl(social(db).resurrect).cast) end,
  resReceived = function(db) return num(tbl(social(db).resurrect).received) end,
  groupsJoined = function(db) return num(tbl(social(db).group).joined) end,
  groupMates = function(db) return num(tbl(social(db).group).mates) end,
  whispersReceived = function(db) return num(tbl(social(db).whisper).received) end,
  whisperFrom = function(db) return num(tbl(social(db).whisper).receivedFrom) end,
  emoteTypes = function(db) return count(tbl(tbl(social(db).emotes).byToken)) end,
  friends = function()
    local f = C_FriendList and C_FriendList.GetNumFriends
    local ok, n = pcall(function() return f and f() or 0 end)
    return ok and num(n) or 0
  end,
  streakDays = function(db)
    local days, list = {}, {}
    for _, ts in ipairs(sessionTimes(db)) do
      local d = dayNumber(ts)
      if not days[d] then days[d] = true; list[#list + 1] = d end
    end
    table.sort(list)
    local best, run, prev = 0, 0, nil
    for _, d in ipairs(list) do
      run = (prev and d == prev + 1) and run + 1 or 1
      if run > best then best = run end
      prev = d
    end
    return best
  end,
  charAgeDays = function(db)
    local first = num(tbl(db.stats).firstLogin)
    if first <= 0 then first = num(tbl(db.character).created) end
    return first > 0 and math.max(0, math.floor((time() - first) / SECONDS_PER_DAY)) or 0
  end,
  s01 = function(db)
    local n = 0
    for _, ts in ipairs(sessionTimes(db)) do
      local h = tonumber(date("%H", ts))
      if h and h >= NIGHT_FROM and h < NIGHT_TO then n = n + 1 end
    end
    return n
  end,
  s02 = function(db)
    local seen, n = {}, 0
    for _, ts in ipairs(sessionTimes(db)) do
      local md = date("%m-%d", ts)
      local day = HOLIDAYS[md] and (date("%Y-", ts) .. md)
      if day and not seen[day] then seen[day] = true; n = n + 1 end
    end
    return n
  end,
  earlyJournal = function(db)
    local n = 0
    for _, e in ipairs(userJournal(db)) do
      local lvl = tonumber(tbl(e).level)
      if lvl and lvl <= 5 then n = n + 1 end
    end
    return n
  end,
  deathlessRun = function(db)
    local first = num(tbl(db.character).firstSeenLevel)
    local current = num(UnitLevel("player"))
    local best, run = 0, 0
    -- Only completed levels count, and only levels that were tracked from their start.
    for lvl = math.max(1, first) + 1, current - 1 do
      local activity = tbl(db.levelActivity)[lvl]
      if type(activity) == "table" and #tbl(activity.deaths) == 0 then
        run = run + 1
        if run > best then best = run end
      else
        run = 0
      end
    end
    return best
  end,
  deathZones = function(db)
    local zones, n = {}, 0
    for _, activity in pairs(tbl(db.levelActivity)) do
      for _, d in ipairs(tbl(tbl(activity).deaths)) do
        local zone = tbl(d).zone
        if type(zone) == "string" and zone ~= "" and not zones[zone] then zones[zone] = true; n = n + 1 end
      end
    end
    return n
  end,
  nemesisDeaths = function(db)
    local best = 0
    for _, row in pairs(deathRows(db)) do best = math.max(best, num(tbl(row).count)) end
    return best
  end,
  revengeKills = function(db)
    local best = 0
    for key, row in pairs(deathRows(db)) do
      if type(row) == "table" and num(row.count) >= 3 then
        local kills = killRowFor(db, key, row)
        if kills then best = math.max(best, num(kills.count)) end
      end
    end
    return best
  end,
  fastLevels = function(db)
    -- The first tracked level is partial (tracking began mid-level), so it never counts.
    local first, n = num(tbl(db.character).firstSeenLevel), 0
    for lvl, e in pairs(tbl(db.levels)) do
      local d = num(tbl(e).duration)
      if type(lvl) == "number" and lvl > first and tbl(e).completed and d > 0 and d < FAST_LEVEL_MINUTES * 60 then n = n + 1 end
    end
    return n
  end,
  slowLevels = function(db)
    local n = 0
    for _, e in pairs(tbl(db.levels)) do
      if tbl(e).completed and num(tbl(e).duration) > SLOW_LEVEL_HOURS * 3600 then n = n + 1 end
    end
    return n
  end,
  levelsInDay = function(db)
    local perDay, best = {}, 0
    for _, e in pairs(tbl(db.levels)) do
      local ts = tonumber(tbl(e).completed)
      if ts then
        local d = dayNumber(ts)
        perDay[d] = (perDay[d] or 0) + 1
        if perDay[d] > best then best = perDay[d] end
      end
    end
    return best
  end,
  longestSessionHours = function(db)
    local best = 0
    for _, s in ipairs(tbl(db.sessions)) do best = math.max(best, num(tbl(s).duration)) end
    return best / 3600
  end,
  afkHours = function(db) return num(tbl(db.afk).total) / 3600 end,
  zoneHoursMax = function(db)
    local best = 0
    for _, seconds in pairs(tbl(tbl(db.locationTime).zones)) do best = math.max(best, num(seconds)) end
    return best / 3600
  end,
  longestJournalChars = function(db)
    local best = 0
    for _, e in ipairs(userJournal(db)) do
      local text = tbl(e).text
      if type(text) == "string" then
        local _, chars = text:gsub("[^\128-\191]", "") -- count characters, not UTF-8 bytes
        best = math.max(best, chars)
      end
    end
    return best
  end,
  screenshotsPerDay = function(db)
    local perDay, best = {}, 0
    for _, shot in ipairs(tbl(db.screenshots)) do
      local ts = tonumber(tbl(shot).time)
      if ts then
        local d = dayNumber(ts)
        perDay[d] = (perDay[d] or 0) + 1
        if perDay[d] > best then best = perDay[d] end
      end
    end
    return best
  end,
  sameDungeon = function(db)
    local per, best = {}, 0
    for _, run in ipairs(tbl(db.dungeons)) do
      local name = tbl(run).dungeon
      if type(name) == "string" then
        per[name] = (per[name] or 0) + 1
        if per[name] > best then best = per[name] end
      end
    end
    return best
  end,
  dungeonDeaths = function(db)
    local n = 0
    for _, run in ipairs(tbl(db.dungeons)) do n = n + num(tbl(run).deaths) end
    return n
  end,
  duelLosses = function(db) return math.max(0, num(tbl(db.duels).total) - num(tbl(db.duels).wins)) end,
  maxDeathsInLevel = function(db)
    local best = 0
    for _, activity in pairs(tbl(db.levelActivity)) do best = math.max(best, #tbl(tbl(activity).deaths)) end
    return best
  end,
  deathSpot = function(db)
    local deaths = {}
    for _, activity in pairs(tbl(db.levelActivity)) do
      for _, d in ipairs(tbl(tbl(activity).deaths)) do
        if type(d) == "table" and tonumber(d.x) and tonumber(d.y) and d.mapID then deaths[#deaths + 1] = d end
      end
    end
    if #deaths > 1000 then return 0 end
    local best = 0
    for i, a in ipairs(deaths) do
      local near = 0
      for j, b in ipairs(deaths) do
        if a.mapID == b.mapID and math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) <= DEATH_SPOT_RADIUS then near = near + 1 end
      end
      if near > best then best = near end
    end
    return best
  end,
  s04 = function(db)
    local sec = 0
    for key, m in pairs(tbl(tbl(db.locationTime).maps)) do
      if allCapital(tonumber(key)) then sec = sec + num(tbl(m).seconds) end
    end
    return sec / 3600
  end,
  s05 = function(db)
    local times = allDeathTimes(db)
    local best, window = 0, DEATH_STREAK_MINUTES * 60
    for i = 1, #times do
      local n = 0
      for j = i, #times do
        if times[j] - times[i] <= window then n = n + 1 else break end
      end
      if n > best then best = n end
    end
    return best
  end,
  s06 = function(db)
    local window = LAST_WORDS_MINUTES * 60
    for _, d in ipairs(allDeathTimes(db)) do
      for _, e in ipairs(userJournal(db)) do
        local t = tonumber(tbl(e).time)
        if t and d >= t and d - t <= window then return 1 end
      end
    end
    return 0
  end,
  s07 = function(db)
    local best = 0
    for _, lt in pairs(tbl(tbl(db.travel).byLevel)) do best = math.max(best, num(tbl(lt).groundYards)) end
    return best * 0.9144 / 1000
  end,
  s08 = function(db)
    local n = 0
    for _, s in ipairs(tbl(db.sessions)) do
      local d = tonumber(tbl(s).duration)
      if d and d < SHORT_SESSION_SECONDS then n = n + 1 end
    end
    return n
  end,
  s09 = function(db)
    local copper = 0
    for _, g in pairs(tbl(db.goldByLevel)) do copper = copper + num(tbl(g).spent) end
    return math.floor(copper / 10000)
  end,
  s10 = function(db)
    if num(tbl(db.character).firstSeenLevel) ~= 1 or num(UnitLevel("player")) < LATE_BLOOMER_LEVEL then return 0 end
    local sec = 0
    for lvl = 1, LATE_BLOOMER_LEVEL - 1 do sec = sec + num(tbl(tbl(db.levels)[lvl]).duration) end
    return sec / 3600
  end,
  campDistinct = function(db) return count(tbl(db.camping).seen) end,
  campMax = function(db) return num(tbl(db.camping).maxAtOnce) end,
  campVisits = function(db) return num(tbl(db.camping).visits) end,
  campTent = function(db) return num(tbl(db.camping).tent) end,
  iconicFound = function(db)
    local n = 0
    for _, e in pairs(tbl(tbl(db.iconic).moments)) do if num(tbl(e).count) > 0 then n = n + 1 end end
    return n
  end,
  greenPages = function(db) return count(tbl(tbl(tbl(db.iconic).moments).green_pages).set) end,
  deathsDrowned = function(db) return num(tbl(tbl(tbl(db.combat).deathCauses)).drowned) end,
  deathsFall = function(db) return num(tbl(tbl(db.combat).deathCauses).fall) end,
  deathsGuard = function(db) return num(tbl(tbl(db.combat).deathCauses).guard) end,
  quickDeaths = function(db)
    local starts, n = sessionTimes(db), 0
    for _, activity in pairs(tbl(db.levelActivity)) do
      for _, d in ipairs(tbl(tbl(activity).deaths)) do
        local t = tonumber(tbl(d).time)
        if t then
          for _, s in ipairs(starts) do
            if t >= s and t - s <= QUICK_DEATH_SECONDS then n = n + 1; break end
          end
        end
      end
    end
    return n
  end,
  -- Most deaths within SHORT_CAREER_SECONDS after the start of one session.
  s03 = function(db)
    local starts, best = sessionTimes(db), 0
    local times = {}
    for _, activity in pairs(tbl(db.levelActivity)) do
      for _, d in ipairs(tbl(tbl(activity).deaths)) do
        local t = tonumber(tbl(d).time)
        if t then times[#times + 1] = t end
      end
    end
    for _, s in ipairs(starts) do
      local n = 0
      for _, t in ipairs(times) do
        if t >= s and t - s <= SHORT_CAREER_SECONDS then n = n + 1 end
      end
      if n > best then best = n end
    end
    return best
  end,
  brokeAtLevel = function(db)
    for _, day in pairs(tbl(db.goldHistory)) do
      if tonumber(tbl(day).min) == 0 and num(tbl(day).level) >= BROKE_MIN_LEVEL then return 1 end
    end
    return 0
  end,
  maxSpentGold = function(db)
    local best = 0
    for _, g in pairs(tbl(db.goldByLevel)) do best = math.max(best, num(tbl(g).spent)) end
    return math.floor(best / 10000)
  end,
  worldDrops = function(db)
    local n = 0
    local minQuality = tbl(MCF.WorldDrops).defaultMinQuality or 3 -- same threshold the description names (rare / blue)
    for _, e in ipairs(tbl(db.worldDrops)) do
      if type(e) == "table" and not e.test and num(e.quality) >= minQuality then n = n + 1 end
    end
    return n
  end,
  worldDropEpics = function(db)
    local n = 0
    for _, e in ipairs(tbl(db.worldDrops)) do if type(e) == "table" and not e.test and num(e.quality) >= 4 then n = n + 1 end end
    return n
  end,
  helmHidden = function(db)
    for _, rec in pairs(tbl(db.gearByLevel)) do if type(rec) == "table" and rec.helm == false then return 1 end end
    return 0
  end,
  gatherHerbs = function(db) return num(tbl(tbl(tbl(db.gathering).kinds).herbalism).quantity) end,
  gatherOre = function(db) return num(tbl(tbl(tbl(db.gathering).kinds).mining).quantity) end,
  gatherFish = function(db) return num(tbl(tbl(tbl(db.gathering).kinds).fishing).quantity) end,
  gatherSkins = function(db) return num(tbl(tbl(tbl(db.gathering).kinds).skinning).quantity) end,
  enchantItems = function(db) return num(tbl(tbl(db.tracking).enchant).count) end,
  s13 = function(db) local _, span = MCF:GetQuestLogStats(db); return span end,
  s14 = function(db) local sec = MCF:GetQuestLogStats(db); return sec / 86400 end,
  enchantAll = function(db) return tbl(tbl(db.tracking).enchant).allSlots and 1 or 0 end,
  disenchants = function(db) return num(tbl(tbl(tbl(db.gathering).kinds).disenchant).events) end,
  specialRecipes = function(db)
    local n = 0
    for _, e in ipairs(tbl(db.recipes)) do if type(e) == "table" and e.source == "OTHER" then n = n + 1 end end
    return n
  end,
  professionRelearned = function(db)
    local n = 0
    for _, p in pairs(tbl(tbl(db.professions).current)) do n = n + num(tbl(p).relearned) end
    return n
  end,
  stillHours = function(db) return num(tbl(tbl(tbl(db.afk).stationary).longest).seconds) / 3600 end,
  walkKm = function(db) return num(tbl(db.travel).walkYards) * 0.9144 / 1000 end,
  guildDays = function(db)
    local cur = tbl(tbl(db.guild).current)
    local since = num(cur.joinedAt) > 0 and num(cur.joinedAt) or num(cur.firstSeen)
    if since <= 0 then return 0 end
    return math.max(0, math.floor((time() - since) / 86400))
  end,
  deathMenu = function(db)
    local causes, n = tbl(tbl(db.combat).deathCauses), 0
    for _, key in ipairs({"drowned", "fall", "guard"}) do if num(causes[key]) > 0 then n = n + 1 end end
    return n
  end,
  transmogFull = function(db)
    local slotList, best = MCF.TransmogSlots or {}, -1
    local rec
    for lvl, r in pairs(tbl(db.gearByLevel)) do
      if type(r) == "table" and (tonumber(lvl) or 0) > best then best = tonumber(lvl) or 0; rec = r end
    end
    if not rec then return 0 end
    local equipped, shown = 0, 0
    for slotID in pairs(slotList) do
      local e = tbl(rec.slots)[slotID]
      if type(e) == "table" then
        equipped = equipped + 1
        if e.t then shown = shown + 1 end
      end
    end
    return (equipped > 0 and shown == equipped) and shown or 0
  end,
  addonUsers = function(db) return num(tbl(social(db).addonUsers).total) end,
  capitals = function(db) return countCapitals(db, allCapital) end,
  enemyCapital = function(db) return countCapitals(db, enemyCapital) > 0 and 1 or 0 end,
}

local function metricValue(db, cache, name)
  local v = cache[name]
  if v ~= nil then return v end
  local fn = metrics[name]
  if fn then
    v = fn(db)
  else
    local token = name:match("^emote:(%u+)$")
    local lvl, secs = name:match("^speed:(%d+):(%d+)$")
    if lvl then
      lvl, secs = tonumber(lvl), tonumber(secs)
      local created = num(tbl(db.character).created)
      local entry = tbl(tbl(db.levels)[lvl - 1])
      local finished = tonumber(entry.completed)
      local tracked = num(tbl(db.character).firstSeenLevel) == 1 and created > 0
      v = (tracked and finished and finished - created <= secs) and 1 or 0
    else
      v = token and num(tbl(tbl(social(db).emotes).byToken)[token]) or 0
    end
  end
  cache[name] = v
  return v
end

-- Totals over all recorded characters, built once per evaluation. The running character's level is read live
-- (its summary is only refreshed now and then).
local function accountAggregate()
  local adb = MCF.EnsureAccountDB and MCF:EnsureAccountDB() or tbl(MyCharForeverAccountDB)
  local liveKey = MCF.GetCharacterKey and MCF:GetCharacterKey()
  local liveLevel = UnitLevel and UnitLevel("player") or 0
  local agg = {chars = 0, deaths = 0, dungeons = 0, quests = 0, seconds = 0, levels = {}}
  local classes, races, factions = {}, {}, {}
  for key, ch in pairs(tbl(adb.characters)) do
    if type(ch) == "table" then
      agg.chars = agg.chars + 1
      local level = num(ch.level)
      if key == liveKey then level = math.max(level, num(liveLevel)) end
      agg.levels[#agg.levels + 1] = level
      if ch.classFile then classes[ch.classFile] = true end
      if ch.raceFile then
        races[ch.raceFile] = true
        for faction, list in pairs(ACCOUNT_FACTION_RACES) do if list[ch.raceFile] then factions[faction] = true end end
      end
      agg.deaths = agg.deaths + num(ch.deaths)
      agg.dungeons = agg.dungeons + num(ch.dungeonCompletions)
      agg.quests = agg.quests + num(ch.quests)
      agg.seconds = agg.seconds + num(ch.played)
    end
  end
  agg.classes, agg.races, agg.factions = count(classes), count(races), count(factions)
  return agg
end

local function accountValue(agg, name)
  local n = name:match("^accLevel:(%d+)$")
  if n then
    n = tonumber(n)
    local c = 0
    for _, level in ipairs(agg.levels) do if level >= n then c = c + 1 end end
    return c
  end
  if name == "accChars" then return agg.chars
  elseif name == "accClasses" then return agg.classes
  elseif name == "accRaces" then return agg.races
  elseif name == "accFactions" then return agg.factions
  elseif name == "accDeaths" then return agg.deaths
  elseif name == "accDungeons" then return agg.dungeons
  elseif name == "accQuests" then return agg.quests
  elseif name == "accHours" then return math.floor(agg.seconds / 3600)
  end
  return 0
end

-- Unlock records and the shared point pool live in the account database.
local function accountStore()
  local adb = MCF.EnsureAccountDB and MCF:EnsureAccountDB() or nil
  if not adb then return nil end
  adb.achievements = tbl(adb.achievements)
  local a = adb.achievements
  a.unlocked = tbl(a.unlocked)
  a.spent = num(a.spent)
  return a
end

---------------------------------------------------------------------------
-- Evaluation
---------------------------------------------------------------------------
local announceQueue = {}

-- Tamper seal: every unlock record carries a checksum (`k`). A record whose checksum does not match (edited by hand in the
-- SavedVariables) is marked "unverified" and does not count for points. It is a marker against casual editing, not security:
-- the addon is readable, so anybody who reads this code can compute valid checksums.
-- Records from before the seal existed are adopted once (store.sealed), later records without a checksum count as unverified.
local SEAL_SALT = "mcf-1.0.1"
local function sealOf(scope, id, rec)
  local s = scope .. "|" .. id .. "|" .. math.floor(num(rec.time)) .. "|" .. math.floor(num(rec.level)) .. "|" .. (rec.retroactive and 1 or 0) .. "|" .. SEAL_SALT
  local h = 5381
  for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967291 end
  return string.format("%x", h)
end
local function sealNew(scope, id, rec) rec.k = sealOf(scope, id, rec) end
-- true = record is not trustworthy
local function sealBad(store, scope, id, rec)
  if type(rec) ~= "table" then return true end
  if rec.k then return rec.k ~= sealOf(scope, id, rec) end
  if store.sealed then return true end
  sealNew(scope, id, rec)
  return false
end

-- Read-only views of the definitions (the viewer table is generated from them by tools/gen_viewer_defs.py, never copied by hand).
MCF.AchievementDefinitions = definitions
MCF.AchievementCategories = categories

local function build(d, index, value, record, bad)
  local tier = MCF.AchievementTiers[d.tier]
  return {
    id = d.id, order = index,
    category = d.category, categoryName = pick(categories[d.category]),
    tier = d.tier, tierName = pick(tier), tierColor = tier.color, points = tier.points,
    name = pick(d), description = string.format(isGerman() and d.deDesc or d.enDesc, formatNumber(d.target)),
    target = d.target, value = value, progress = math.floor(math.min(value, d.target)),
    unlocked = record, tampered = bad or nil, hidden = d.hidden, secret = d.secret, account = d.account,
  }
end

local function evaluate()
  local db = MyCharForeverDB
  if type(db) ~= "table" then return nil end
  db.achievements = tbl(db.achievements)
  local store = db.achievements
  store.unlocked = tbl(store.unlocked)
  store.revealed = tbl(store.revealed)
  store.spent = num(store.spent)
  -- Schema 2: the 50 progress-clone secrets were replaced by new ones. Their unlock
  -- records and reveals are dropped and all spent points refunded.
  if num(store.schema) < 2 then
    for id in pairs(store.unlocked) do
      if type(id) == "string" and id:match("^secret_") then store.unlocked[id] = nil end
    end
    store.revealed = {}
    store.spent = 0
    store.schema = 2
  end
  -- The very first evaluation records everything already earned silently
  -- (historic counters); later unlocks are announced.
  local retroactive = not store.initialized
  local cache, list = {}, {}
  local acc, accAgg = accountStore(), nil
  local accRetroactive = acc and not acc.initialized
  for index, d in ipairs(definitions) do
    local value, record, target
    if d.account then
      if acc then
        accAgg = accAgg or accountAggregate()
        value = accountValue(accAgg, d.metric)
        record = acc.unlocked[d.id]
        if not record and value >= d.target then
          record = {time = time(), level = UnitLevel("player"), by = MCF.GetCharacterKey and MCF:GetCharacterKey() or nil,
                    retroactive = accRetroactive or nil}
          sealNew("a", d.id, record)
          acc.unlocked[d.id] = record
          if not accRetroactive then announceQueue[#announceQueue + 1] = d end
        end
      else
        value = 0
      end
    else
      value = metricValue(db, cache, d.metric)
      record = store.unlocked[d.id]
      if not record and value >= d.target then
        -- Date records when it was observed, not a fictional past completion date.
        record = {time = time(), level = UnitLevel("player"), retroactive = retroactive or nil}
        sealNew("c", d.id, record)
        store.unlocked[d.id] = record
        if not retroactive then announceQueue[#announceQueue + 1] = d end
      end
    end
    local bad = record and sealBad(d.account and acc or store, d.account and "a" or "c", d.id, record) or false
    list[#list + 1] = build(d, index, value, record, bad)
  end
  store.initialized = true; store.sealed = true
  if acc then acc.initialized = true; acc.sealed = true end

  local catIndex, tierIndex = {}, {}
  for i, c in ipairs(categories.order) do catIndex[c] = i end
  for i, t in ipairs(MCF.AchievementTiers.order) do tierIndex[t] = i end
  table.sort(list, function(a, b)
    if a.category ~= b.category then return catIndex[a.category] < catIndex[b.category] end
    if a.tier ~= b.tier then return tierIndex[a.tier] < tierIndex[b.tier] end
    return a.order < b.order
  end)
  return list
end

-- Points: a character's own achievements and iconic moments, plus the pool of account achievements that all
-- characters share. Revealing a secret is paid from the character's own points first, then from the shared pool.
local function pointsBreakdown(list)
  list = list or MCF:GetAchievements()
  local earned, shared = 0, 0
  for _, a in ipairs(list) do
    if a.unlocked and not a.tampered then
      if a.account then shared = shared + a.points else earned = earned + a.points end
    end
  end
  local store = tbl(tbl(MyCharForeverDB).achievements)
  local iconic = 0
  if MCF.GetIconicFound then iconic = (MCF:GetIconicFound()) * MCF.IconicPoints end
  local acc = accountStore()
  local ownTotal, ownSpent = earned + iconic, num(store.spent)
  local sharedSpent = acc and acc.spent or 0
  return {earned = earned, iconic = iconic, shared = shared,
          ownSpent = ownSpent, sharedSpent = sharedSpent,
          ownAvailable = math.max(0, ownTotal - ownSpent),
          sharedAvailable = math.max(0, shared - sharedSpent)}
end

function MCF:GetSecretPoints(list)
  local p = pointsBreakdown(list)
  local total = p.earned + p.iconic + p.shared
  -- total, available, from own achievements, from iconic moments, spent, from account achievements
  return total, p.ownAvailable + p.sharedAvailable, p.earned, p.iconic, p.ownSpent + p.sharedSpent, p.shared
end

-- One rule for "revealed": a secret achievement is revealed once it was earned or bought with points.
-- The achievement list and the points panel both ask here, so the two can never disagree.
function MCF:IsSecretRevealed(a)
  if type(a)~="table" or not a.secret then return false end
  if a.unlocked then return true end
  local st=MyCharForeverDB and MyCharForeverDB.achievements
  return (type(st)=="table" and type(st.revealed)=="table" and st.revealed[a.id]) and true or false
end
-- Returns revealed, total for the secret achievements in the evaluated list.
function MCF:GetSecretCounts(list)
  local revealed,total=0,0
  for _,a in ipairs(list or {}) do
    if a.secret then total=total+1; if self:IsSecretRevealed(a) then revealed=revealed+1 end end
  end
  return revealed,total
end

-- Reset of one unverified unlock. Nothing is lost that was really earned: if the counter reaches the target the unlock
-- is written again (with a valid seal, original date kept when plausible); otherwise the invented record is removed.
function MCF:ResetTamperedAchievement(id)
  local db = MyCharForeverDB
  if type(db) ~= "table" then return false end
  local d
  for _, def in ipairs(definitions) do if def.id == id then d = def; break end end
  if not d then return false end
  local store, scope, value
  if d.account then
    store, scope = accountStore(), "a"
    if not store then return false end
    value = accountValue(accountAggregate(), d.metric)
  else
    store, scope = tbl(db.achievements), "c"
    store.unlocked = tbl(store.unlocked)
    value = metricValue(db, {}, d.metric)
  end
  local rec = store.unlocked[id]
  if not rec or not sealBad(store, scope, id, rec) then return false end -- only records that really are unverified
  local oldTime = type(rec) == "table" and tonumber(rec.time) or nil
  if value >= d.target then
    local fresh = {time = (oldTime and oldTime > 0 and oldTime <= time()) and oldTime or time(), level = UnitLevel("player"), retroactive = true}
    if d.account then fresh.by = MCF.GetCharacterKey and MCF:GetCharacterKey() or nil end
    sealNew(scope, id, fresh)
    store.unlocked[id] = fresh
  else
    store.unlocked[id] = nil
  end
  if self.RefreshUI then self:RefreshUI() end
  return true
end

function MCF:RevealSecret(id)
  local db=MyCharForeverDB
  if type(db)~="table" then return false,"no-db" end
  local store=tbl(db.achievements)
  store.revealed=tbl(store.revealed)
  local choices={}
  for _,d in ipairs(definitions) do
    if d.secret and not store.revealed[d.id] and not tbl(store.unlocked)[d.id] then
      choices[#choices+1]=d
    end
  end
  local selected
  if id then for _,d in ipairs(choices) do if d.id==id then selected=d;break end end
  else if #choices>0 then selected=choices[math.random(#choices)] end end
  if not selected then return false,"unavailable" end
  local cost=id and MCF:SecretCostFor(selected.tier) or MCF.SecretCost.random
  local p=pointsBreakdown()
  if p.ownAvailable+p.sharedAvailable<cost then return false,"points" end
  store.revealed[selected.id]=true
  store.lastRevealed=selected.id
  local fromOwn=math.min(cost,p.ownAvailable)
  store.spent=num(store.spent)+fromOwn
  if cost>fromOwn then
    local acc=accountStore()
    if acc then acc.spent=acc.spent+(cost-fromOwn) end
  end
  if self.RefreshUI then self:RefreshUI() end
  return true,selected.id,selected
end

-- Achievement toast: one opaque Forever-style notification at a time.
local toastQueue, toastBusy = {}, false
local toast
local toastToken, toastChain = 0, 0
local function ToastSeconds()
  local st = MyCharForeverDB and MyCharForeverDB.settings
  local n = st and tonumber(st.toastSeconds)
  return (n and n >= 1) and n or (MCF.ToastSeconds and MCF.ToastSeconds.default) or 8
end
-- One-time question after the very first popup of each kind (achievement / iconic moment) per character: keep showing them?
-- No answer within ASK_SECONDS counts as "yes" (nothing is switched off by accident). Test popups never ask.
local ASK_SECONDS = 25
local askFrame, pendingAsk
local function AskedTable()
  local ch = MyCharForeverDB and MyCharForeverDB.character
  if not ch then return nil end
  ch.popupAsked = ch.popupAsked or {}
  return ch.popupAsked
end
local function CloseAsk(kind, keep)
  local asked = AskedTable()
  if asked then asked[kind] = true end
  if askFrame then askFrame.kind = nil; askFrame:Hide() end
  if keep then return end
  local st = MyCharForeverDB and MyCharForeverDB.settings
  if not st then return end
  if kind == "moment" then st.iconicPopup = false else st.achievementNotify = false end
  MCF:Notify(isGerman()
    and "Pop-ups ausgeschaltet. Wieder einschalten: Einstellungen > Allgemein."
    or "Popups turned off. Turn them back on: Settings > General.")
end
local function ShowAsk(kind)
  local asked = AskedTable()
  if not asked or asked[kind] then return end
  if not askFrame then
    askFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    askFrame:SetSize(430, 70 + MCF.Kit.BRAND_H)
    askFrame:SetPoint("TOP", UIParent, "TOP", 0, -255) -- below the popup, so a following popup does not cover it
    askFrame:SetFrameStrata("DIALOG")
    MCF.MakeOpaque(askFrame, 4)
    askFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    askFrame:SetBackdropColor(0.09, 0.07, 0.05, 1)
    askFrame:SetBackdropBorderColor(unpack(MCF.Kit.BORDER))
    MCF.Kit.Brand(askFrame)
    askFrame.text = askFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    askFrame.text:SetPoint("TOPLEFT", 14, -10 - MCF.Kit.BRAND_H); askFrame.text:SetWidth(402); askFrame.text:SetJustifyH("LEFT")
    askFrame.yes = CreateFrame("Button", nil, askFrame, "UIPanelButtonTemplate")
    askFrame.yes:SetSize(190, 22); askFrame.yes:SetPoint("BOTTOMLEFT", 14, 10)
    askFrame.no = CreateFrame("Button", nil, askFrame, "UIPanelButtonTemplate")
    askFrame.no:SetSize(190, 22); askFrame.no:SetPoint("BOTTOMRIGHT", -14, 10)
    askFrame.yes:SetScript("OnClick", function() if askFrame.kind then CloseAsk(askFrame.kind, true) end end)
    askFrame.no:SetScript("OnClick", function() if askFrame.kind then CloseAsk(askFrame.kind, false) end end)
  end
  askFrame.kind = kind
  local de = isGerman()
  askFrame.text:SetText(kind == "moment"
    and (de and "Pop-ups für ikonische Momente weiter anzeigen?" or "Keep showing popups for iconic moments?")
    or (de and "Erfolgs-Pop-ups weiter anzeigen?" or "Keep showing achievement popups?"))
  askFrame.yes:SetText(de and "Ja, weiter so" or "Yes, keep them")
  askFrame.no:SetText(de and "Nein, ausschalten" or "No, turn them off")
  askFrame:Show()
  C_Timer.After(ASK_SECONDS, function()
    if askFrame.kind == kind then CloseAsk(kind, true) end
  end)
end
local function AskAfterToast()
  if pendingAsk and not toastBusy and #toastQueue == 0 then local k = pendingAsk; pendingAsk = nil; ShowAsk(k) end
end

-- Rare reminder while a master switch ("achievementsEnabled" / "iconicEnabled") is off: at most one question per REMIND_DAYS
-- and kind, account wide (MyCharForeverAccountDB.reminders[kind] = {last, never}). The first time the switch is seen off only
-- starts the clock, nothing is asked. No answer counts as "keep it off". "Don't ask again" is final until the switch is on once.
local REMIND_DAYS = 30
local REMIND_SECONDS = 30
local REMIND_KINDS = {
  {key = "achievements", enabled = function() return MCF:AchievementsEnabled() end,
   turnOn = function() local st = MyCharForeverDB.settings; st.achievementsEnabled = true; if MCF.ApplyAchievementsSetting then MCF:ApplyAchievementsSetting() end end,
   de = "Erfolge sind ausgeschaltet. Wieder einschalten?", en = "Achievements are turned off. Turn them back on?"},
  {key = "iconic", enabled = function() return MCF:IconicEnabled() end,
   turnOn = function() local st = MyCharForeverDB.settings; st.iconicEnabled = true; if MCF.ApplyIconicSetting then MCF:ApplyIconicSetting() end end,
   de = "Ikonische Momente sind ausgeschaltet. Wieder einschalten?", en = "Iconic moments are turned off. Turn them back on?"},
}
local remindFrame
local function RemindStore()
  local acc = MyCharForeverAccountDB
  if type(acc) ~= "table" then return nil end
  acc.reminders = type(acc.reminders) == "table" and acc.reminders or {}
  return acc.reminders
end
local function CloseRemind(kind, action)
  local store = RemindStore()
  if remindFrame then remindFrame.kind = nil; remindFrame:Hide() end
  if not store then return end
  if action == "on" then
    local k; for _, d in ipairs(REMIND_KINDS) do if d.key == kind then k = d end end
    if k and MyCharForeverDB and MyCharForeverDB.settings then k.turnOn() end
    store[kind] = nil
  elseif action == "never" then
    store[kind] = {last = time(), never = true}
    MCF:Notify(isGerman() and "Okay, ich frage nicht mehr. Einschalten geht jederzeit unter Einstellungen > Allgemein."
      or "Okay, I will not ask again. You can turn it on any time under Settings > General.")
  else
    store[kind] = {last = time()}
  end
  C_Timer.After(5, function() if MCF.CheckSwitchReminders then MCF:CheckSwitchReminders() end end) -- the other kind, if due
end
local function ShowRemind(def)
  if not remindFrame then
    remindFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    remindFrame:SetSize(470, 76 + MCF.Kit.BRAND_H)
    remindFrame:SetPoint("TOP", UIParent, "TOP", 0, -255)
    remindFrame:SetFrameStrata("DIALOG")
    MCF.MakeOpaque(remindFrame, 4)
    remindFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    remindFrame:SetBackdropColor(0.09, 0.07, 0.05, 1)
    remindFrame:SetBackdropBorderColor(unpack(MCF.Kit.BORDER))
    MCF.Kit.Brand(remindFrame)
    remindFrame.text = remindFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    remindFrame.text:SetPoint("TOPLEFT", 14, -10 - MCF.Kit.BRAND_H); remindFrame.text:SetWidth(442); remindFrame.text:SetJustifyH("LEFT")
    local function btn(point, x, action)
      local b = CreateFrame("Button", nil, remindFrame, "UIPanelButtonTemplate")
      b:SetSize(140, 22); b:SetPoint(point, x, 10)
      b:SetScript("OnClick", function() if remindFrame.kind then CloseRemind(remindFrame.kind, action) end end)
      return b
    end
    remindFrame.on = btn("BOTTOMLEFT", 14, "on")
    remindFrame.keep = btn("BOTTOM", 0, "keep")
    remindFrame.never = btn("BOTTOMRIGHT", -14, "never")
  end
  local de = isGerman()
  remindFrame.kind = def.key
  remindFrame.text:SetText(de and def.de or def.en)
  remindFrame.on:SetText(de and "Einschalten" or "Turn on")
  remindFrame.keep:SetText(de and "Aus lassen" or "Keep off")
  remindFrame.never:SetText(de and "Nicht mehr fragen" or "Don't ask again")
  remindFrame:Show()
  C_Timer.After(REMIND_SECONDS, function()
    if remindFrame.kind == def.key then CloseRemind(def.key, "keep") end
  end)
end
-- Looks at both switches; asks for at most one kind per call. `force` (test command) skips the timing and never saves.
function MCF:CheckSwitchReminders(force)
  local store = RemindStore()
  if not store or not MyCharForeverDB or not MyCharForeverDB.settings then return end
  if remindFrame and remindFrame:IsShown() then return end
  if InCombatLockdown and InCombatLockdown() then
    C_Timer.After(60, function() MCF:CheckSwitchReminders() end); return
  end
  for _, def in ipairs(REMIND_KINDS) do
    if def.enabled() then
      store[def.key] = nil
    else
      local r = store[def.key]
      if force then ShowRemind(def); return end
      if not r then
        store[def.key] = {last = time()}
      elseif not r.never and time() - (r.last or 0) >= REMIND_DAYS * 86400 then
        ShowRemind(def); return
      end
    end
  end
end

MCF:AddCommand{group="test", usage="/mcf testremind", example="/mcf testremind",
  de="Zeigt die seltene Rückfrage zu ausgeschalteten Erfolgen bzw. ikonischen Momenten (nur wenn der Schalter aus ist)",
  en="Shows the rare reminder about turned-off achievements / iconic moments (only while the switch is off)",
  key="testremind",
  run=function()
    local anyOff = not MCF:AchievementsEnabled() or not MCF:IconicEnabled()
    if not anyOff then
      MCF:Notify(isGerman() and "Beide Schalter sind an, es gibt nichts zu fragen. Schalte in den Einstellungen einen aus, um die Rückfrage zu sehen."
        or "Both switches are on, nothing to ask. Turn one off in the settings to see the reminder.")
      return
    end
    MCF:CheckSwitchReminders(true)
  end}

local function ShowNextToast()
  if toastBusy or #toastQueue == 0 then return end
  toastBusy = true
  toastChain = toastChain + 1 -- popups right after each other: from the second one on only half the time
  toastToken = toastToken + 1
  local myToken = toastToken
  local d = table.remove(toastQueue, 1)
  if d.moment then
    local st = MyCharForeverDB and MyCharForeverDB.settings
    if not (st and st.achievementSound == false) then MCF.PlaySoundList(MCF.AchievementSounds.moment) end
  end
  if not toast then
    toast = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    toast:SetSize(430, 84)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -145)
    toast:SetFrameStrata("DIALOG")
    MCF.MakeOpaque(toast,4)
    -- Same calm look as the addon windows (dark panel, bronze border); the gold is limited to the title.
    -- Own logo, addon name and "addon achievement" wording keep it apart from official achievements.
    local Kit = MCF.Kit
    toast:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=false, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    toast:SetBackdropColor(0.09, 0.07, 0.05, 1)
    toast:SetBackdropBorderColor(unpack(Kit.BORDER))
    toast.sheen=toast:CreateTexture(nil,"BACKGROUND",nil,-6)
    toast.sheen:SetPoint("TOPLEFT",5,-5); toast.sheen:SetPoint("TOPRIGHT",-5,-5); toast.sheen:SetHeight(24)
    toast.sheen:SetColorTexture(unpack(Kit.BAND))
    toast.logoFrame=CreateFrame("Frame",nil,toast,"BackdropTemplate")
    toast.logoFrame:SetSize(44,44); toast.logoFrame:SetPoint("LEFT",14,-4)
    toast.logoFrame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12, insets={left=2,right=2,top=2,bottom=2}})
    toast.logoFrame:SetBackdropBorderColor(0,0,0,0) -- the round logo has its own ring
    toast.logo=toast.logoFrame:CreateTexture(nil,"ARTWORK")
    toast.logo:SetPoint("TOPLEFT",0,0); toast.logo:SetPoint("BOTTOMRIGHT",0,0)
    toast.logo:SetTexture(MCF.LOGO_PATH)
    toast.brand=toast:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    toast.brand:SetPoint("TOPLEFT",70,-10); toast.brand:SetJustifyH("LEFT")
    toast.title=toast:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    toast.title:SetPoint("TOPLEFT",70,-28); toast.title:SetJustifyH("LEFT"); toast.title:SetTextColor(unpack(Kit.GOLD))
    toast.name=toast:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    toast.name:SetPoint("TOPLEFT",70,-52); toast.name:SetWidth(345); toast.name:SetJustifyH("LEFT"); toast.name:SetWordWrap(false)
    toast.info=toast:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    toast.info:SetPoint("TOPRIGHT",-14,-32); toast.info:SetJustifyH("RIGHT")
    -- Only for iconic moments: what triggered it (own line, the toast gets taller)
    toast.extra=toast:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    toast.extra:SetPoint("TOPLEFT",70,-70); toast.extra:SetWidth(345); toast.extra:SetJustifyH("LEFT"); toast.extra:SetWordWrap(false)
    -- Click: open the achievements tab and show the achievement.
    toast:EnableMouse(true)
    toast:SetScript("OnMouseUp",function(self,button)
      if button == "RightButton" then
        -- right click closes it right away; the next one (if any) follows
        self.token = nil; self:Hide(); toastBusy = false
        if #toastQueue == 0 then toastChain = 0 end
        ShowNextToast(); AskAfterToast()
      elseif button == "LeftButton" and self.achievementId and MCF.OpenAchievements then MCF:OpenAchievements(self.achievementId) end
    end)
  end
  if d.moment then
    -- Iconic moment: no tier, no points; click does nothing special
    toast.achievementId = nil
    toast:SetHeight(d.trigger and 96 or 84)
    toast.brand:SetText(MCF.BRAND_NAME.."  |cffbfae80"..(isGerman() and "Ikonischer Moment" or "Iconic Moment").."|r")
    toast.title:SetText(isGerman() and "Moment festgehalten!" or "Moment captured!")
    toast.name:SetText(pick(d))
    toast.info:SetText("")
    toast.extra:SetText(d.trigger and ("|cffd8d8d8"..d.trigger.."|r") or "")
  else
    toast.achievementId = d.id ~= "test" and d.id or nil
    toast:SetHeight(84)
    local tier=MCF.AchievementTiers[d.tier]
    toast.brand:SetText(MCF.BRAND_NAME.."  |cffbfae80"..(isGerman() and "Addon-Erfolg" or "Addon Achievement").."|r")
    toast.title:SetText(isGerman() and "Erfolg freigeschaltet!" or "Achievement Unlocked!")
    toast.name:SetText(pick(d))
    toast.info:SetText("|cffd8d8d8"..pick(tier).."|r  |cffe0b84a+"..tier.points.." "..(isGerman() and "Punkte" or "points").."|r")
    toast.extra:SetText("")
  end
  do -- first real popup of this kind: ask afterwards (never for tests)
    local kind = d.moment and "moment" or "achievement"
    local asked = AskedTable()
    if not d.test and asked and not asked[kind] then pendingAsk = kind end
  end
  toast:Show()
  toast.token = myToken
  C_Timer.After(toastChain > 1 and math.max(2, ToastSeconds() / 2) or ToastSeconds(),function()
    if toast.token ~= myToken then return end
    toast:Hide(); toastBusy=false
    if #toastQueue == 0 then toastChain = 0 end
    ShowNextToast(); AskAfterToast()
  end)
end

-- Shows a fake achievement popup (nothing is saved, no points). Ignores the "show popups" setting
-- because the point is to look at it.
function MCF:TestAchievementToast(tierName)
  local tier = MCF.AchievementTiers[tierName] and tierName or "hard"
  toastQueue[#toastQueue+1] = {id = "test", tier = tier, test = true,
    de = "Testerfolg: Der Popup-Pionier", en = "Test Achievement: Popup Pioneer"}
  if MCF.PlayAchievementSound then MCF.PlayAchievementSound({{tier = tier}}) end
  ShowNextToast()
end

-- Popup for a first-time iconic moment (setting iconicPopup, default on): name of the moment and what triggered it.
-- Independent of the achievements switch (iconic moments are not achievements). `force` ignores the setting (test).
function MCF:ShowMomentToast(name, trigger, force)
  local st = MyCharForeverDB and MyCharForeverDB.settings
  if not force and st and (st.iconicPopup == false or st.iconicEnabled == false) then return end
  if type(name) ~= "string" or name == "" then return end
  toastQueue[#toastQueue+1] = {moment = true, de = name, en = name, trigger = trigger, test = force and true or nil}
  ShowNextToast()
end

MCF:AddCommand{group="test", usage="/mcf testmoment", example="/mcf testmoment",
  de="Zeigt ein Test-Popup für einen ikonischen Moment (speichert nichts)", en="Shows a test popup for an iconic moment (saves nothing)",
  key="testmoment",
  run=function()
    MCF:ShowMomentToast(isGerman() and "Hogger erlegt" or "Hogger Slain", MCF:IconicTriggerText("kill", "Hogger"), true)
  end}

MCF:AddCommand{group="test", usage="/mcf testachievement [easy|medium|hard]", example="/mcf testachievement medium",
  de="Zeigt ein Test-Erfolgs-Popup (speichert nichts)", en="Shows a test achievement popup (saves nothing)",
  match=function(msg) return msg=="testachievement" or msg:match("^testachievement%s+%a+$")~=nil end,
  run=function(msg) MCF:TestAchievementToast(msg:match("^testachievement%s+(%a+)$")) end}

-- Master switch for purists: with "achievementsEnabled" off nothing is evaluated, announced or shown.
function MCF:AchievementsEnabled()
  local st = MyCharForeverDB and MyCharForeverDB.settings
  return not (st and st.achievementsEnabled == false)
end

-- Short sound with the popup (setting achievementSound, default on). One sound per batch, the same for every tier.
-- Every tier lists candidates in order of preference (SOUNDKIT names, optional numeric fallback); the first one the client
-- knows is played, a tier without any known sound plays nothing. LEVELUP stays reserved for the character level-up.
-- `/mcf sound` plays the candidates one after another so they can be judged by ear (single source: this table).
MCF.AchievementSounds = {
  -- All achievements, whatever the tier: the soft "window closed" click, then the old quest sound as a last resort
  achievement = {{name = "AUCTION_WINDOW_CLOSE"}, {name = "UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST"}, {name = "IG_QUEST_LIST_COMPLETE", id = 878}},
  -- Iconic-moment popup: the countdown-finished signal, then the garrison jingle as a fallback
  moment = {{name = "UI_BATTLEGROUND_COUNTDOWN_FINISHED"}, {name = "UI_GARRISON_TOAST_MISSION_COMPLETE"}, {name = "IG_QUEST_LIST_COMPLETE", id = 878}},
}
local function soundKitOf(def)
  return (_G.SOUNDKIT and _G.SOUNDKIT[def.name]) or def.id
end
local function playKit(kit)
  if kit and PlaySound then pcall(PlaySound, kit, "Master") end
end
function MCF.PlayAchievementSound()
  local st = MyCharForeverDB and MyCharForeverDB.settings
  if st and st.achievementSound == false then return end
  MCF.PlaySoundList(MCF.AchievementSounds.achievement)
end
-- First candidate the client knows wins.
function MCF.PlaySoundList(list)
  for _, def in ipairs(list) do
    local kit = soundKitOf(def)
    if kit then playKit(kit); return end
  end
end

-- /mcf sound [easy|medium|hard|all|<SOUNDKIT name>]: plays the candidates of a tier (1.5 s apart) and prints their names.
local function soundTest(msg)
  local de = isGerman()
  local arg = (msg or ""):match("^sound%s*(.-)%s*$") or ""
  local tiers = (arg == "" or arg == "all") and {"achievement", "moment"} or (MCF.AchievementSounds[arg] and {arg}) or ((arg == "easy" or arg == "medium" or arg == "hard") and {"achievement"})
  local steps = {}
  if tiers then
    for _, t in ipairs(tiers) do
      for _, def in ipairs(MCF.AchievementSounds[t]) do steps[#steps+1] = {tier = t, def = def} end
    end
  else
    local name = arg:upper()
    steps[1] = {tier = "?", def = {name = name}}
  end
  local delay = 0
  for _, step in ipairs(steps) do
    local kit = soundKitOf(step.def)
    local function run()
      if kit then
        MCF:Notify(string.format("%s: %s%s", step.tier, step.def.name, step.def.id and (" (" .. step.def.id .. ")") or ""))
        playKit(kit)
      else
        MCF:Notify(string.format("%s: %s - %s", step.tier, step.def.name, de and "im Client nicht bekannt" or "unknown to this client"))
      end
    end
    if delay == 0 then run() elseif C_Timer and C_Timer.After then C_Timer.After(delay, run) end
    delay = delay + 1.5
  end
end
MCF:AddCommand{group="test", usage="/mcf sound [achievement|moment|all|NAME]", example="/mcf sound moment", key="sound",
  match=function(msg) return msg == "sound" or msg:match("^sound ") ~= nil end,
  de="Erfolgs-Sounds nacheinander abspielen (Stufe, alle, oder ein SOUNDKIT-Name zum Ausprobieren)",
  en="Play the achievement sounds one after another (tier, all, or any SOUNDKIT name to try)",
  run=soundTest}

local function flushAnnouncements()
  if #announceQueue == 0 then return end
  if not MCF:AchievementsEnabled() then wipe(announceQueue); return end
  local db = MyCharForeverDB
  -- Settings: "Show achievement popups". The chat line is optional (Settings), so is the popup.
  local popup = not (db and db.settings and db.settings.achievementNotify == false)
  for _, d in ipairs(announceQueue) do
    local tier = MCF.AchievementTiers[d.tier]
    MCF:Notify(string.format("|cff44ff44%s|r %s (%s, +%d)",
      isGerman() and "Erfolg freigeschaltet:" or "Achievement unlocked:", pick(d), pick(tier), tier.points))
    if popup then toastQueue[#toastQueue+1] = d end
  end
  if popup then MCF.PlayAchievementSound(announceQueue) end
  -- One screenshot per unlock batch (several achievements at once = one picture); the popup is on screen then. The cooldown applies.
  if MCF.AutoMoment then MCF:AutoMoment{reason="ACHIEVEMENT", shotKey="screenshotAchievement", noJournal=true, delay=1} end
  wipe(announceQueue)
  if popup then ShowNextToast() end
  if MCF.RefreshUI then MCF:RefreshUI() end
end

function MCF:GetAchievementEmoteTokens()
  local out, seen = {}, {}
  for _, d in ipairs(definitions) do
    local token = type(d.metric) == "string" and d.metric:match("^emote:(%u+)$")
    if token and not seen[token] then seen[token] = true; out[#out + 1] = token end
  end
  table.sort(out)
  return out
end

function MCF:GetAchievements()
  if not self:AchievementsEnabled() then return {} end
  local list = evaluate()
  flushAnnouncements()
  return list or {}
end

local tamperNoticeShown = false
function MCF:CheckAchievements()
  if not self:AchievementsEnabled() then return end
  local list = evaluate()
  flushAnnouncements()
  -- Friendly one-time notice per session; nothing is punished or deleted.
  if list and not tamperNoticeShown then
    local n = 0
    for _, a in ipairs(list) do if a.tampered then n = n + 1 end end
    if n > 0 then
      tamperNoticeShown = true
      print("|cff00ccffMyCharForever|r: " .. (isGerman()
        and (n .. " Erfolg(e) wurden von Hand verändert und als \"Nicht verifiziert\" markiert. Nicht schlimm, es wird nichts bestraft! Im Erfolge-Reiter kannst du sie per Knopf \"Zurücksetzen\" bereinigen; was du wirklich erreicht hast, bleibt erhalten.")
        or (n .. " achievement(s) were edited by hand and marked \"Unverified\". No worries, nothing is punished! In the Achievements tab you can clean them up with the \"Reset\" button; whatever you really earned is kept.")))
    end
  end
end

function MCF:GetAchievementSummary(list)
  list = list or self:GetAchievements()
  local s = {total = #list, earned = 0, points = 0, pointsTotal = 0, hiddenLeft = 0}
  for _, a in ipairs(list) do
    s.pointsTotal = s.pointsTotal + a.points
    if a.unlocked and not a.tampered then
      s.earned = s.earned + 1
      s.points = s.points + a.points
    elseif a.hidden then
      s.hiddenLeft = s.hiddenLeft + 1
    end
  end
  return s
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
pcall(function() frame:RegisterEvent("PLAYER_LEVEL_UP") end)
local function tick()
  MCF:CheckAchievements()
  C_Timer.After(CHECK_INTERVAL, tick)
end
frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(8, tick)
    C_Timer.After(45, function() MCF:CheckSwitchReminders() end)
  else
    C_Timer.After(2, function()
      if MCF.UpdateAccountCharacterSummary then MCF:UpdateAccountCharacterSummary() end -- account achievements read it
      MCF:CheckAchievements()
    end)
  end
end)
