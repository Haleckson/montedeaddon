local _, FLT = ...

-- Verified prerequisite chains adapted from the reference dungeon journal.
-- Steps are required unless marked optional = true (breadcrumbs / story lead-ins);
-- optional steps are displayed but never block the quest status.
FLT.QUEST_PREREQ_CHAINS = {
  -- Added October 2026
  [6922] = {
    { id = 6921, name = "Amongst the Ruins" },
  },
  [1654] = {
    { id = 1653, name = "The Test of Righteousness" },
  },
  [3369] = {
    { id = 6981, name = "The Glowing Shard" },
  },
  [3370] = {
    { id = 6981, name = "The Glowing Shard" },
  },
  [96393] = {
    { id = 96391, name = "Underground Map" },
  },
  [1491] = {
    { id = 865, name = "Raptor Horns" },
  },
  [914] = {
    { id = 870, name = "The Forgotten Pools" },
    { id = 877, name = "The Stagnant Oasis" },
    { id = 880, name = "Altered Beings" },
    { id = 1489, name = "Hamuul Runetotem" },
    { id = 1490, name = "Nara Wildmane" },
  },
  [214] = {
    { id = 65, name = "The Defias Brotherhood" },
    { id = 132, name = "The Defias Brotherhood" },
    { id = 135, name = "The Defias Brotherhood" },
    { id = 141, name = "The Defias Brotherhood" },
    { id = 142, name = "The Defias Brotherhood" },
    { id = 155, name = "The Defias Brotherhood" },
  },
  [166] = {
    { id = 65, name = "The Defias Brotherhood" },
    { id = 132, name = "The Defias Brotherhood" },
    { id = 135, name = "The Defias Brotherhood" },
    { id = 141, name = "The Defias Brotherhood" },
    { id = 142, name = "The Defias Brotherhood" },
    { id = 155, name = "The Defias Brotherhood" },
  },
  -- Alba Fairmoon storyline: only the direct predecessor is enforced; the
  -- earlier Westfall steps are shown as story context without blocking.
  [92753] = {
    { id = 92742, name = "Testing the Wells", optional = true },
    { id = 92744, name = "Murloc Gills", optional = true },
    { id = 92745, name = "The State of the Mines", optional = true },
    { id = 92747, name = "Moonbrook Espionage", optional = true },
    { id = 92748, name = "Explosive Consultation", optional = true },
    { id = 92749, name = "A Dynamite Plan", optional = true },
    { id = 92750, name = "Detonation at a Distance", optional = true },
    { id = 92751, name = "Detonation at a Distance", optional = true },
    { id = 92752, name = "Explosive Consultation" },
  },
  [5724] = {
    { id = 5722, name = "Searching for the Lost Satchel" },
  },
  [5728] = {
    { id = 5726, name = "Hidden Enemies" },
    { id = 5727, name = "Hidden Enemies" },
  },
  [1275] = {
    { id = 3765, name = "The Corruption Abroad", optional = true },
  },
  [6563] = {
    { id = 6562, name = "Trouble in the Deeps", optional = true },
  },
  [6564] = {
    { id = 6562, name = "Trouble in the Deeps" },
  },
  [6565] = {
    { id = 6562, name = "Trouble in the Deeps" },
    { id = 6564, name = "Allegiance to the Old Gods" },
  },
  -- The Stockade
  [378] = {
    { id = 303, name = "The Dark Iron War" },
  },
  [391] = {
    { id = 373, name = "The Unsent Letter" },
    { id = 389, name = "Bazil Thredd" },
  },
  -- Gnomeregan
  [2922] = {
    { id = 2923, name = "Tinkmaster Overspark", optional = true },
  },
  [2924] = {
    { id = 2925, name = "Klockmort's Essentials", optional = true },
  },
  [2930] = {
    { id = 2931, name = "Castpipe's Task", optional = true },
  },
  [2962] = {
    { id = 2927, name = "The Day After", optional = true },
    { id = 2926, name = "Gnogaine" },
  },
  [2947] = {
    { id = 2945, name = "Grime-Encrusted Ring" },
  },
  [2949] = {
    { id = 2945, name = "Grime-Encrusted Ring" },
  },
  [2843] = {
    { id = 2842, name = "Chief Engineer Scooty" },
  },
  -- Excavation Site: Wetlands
  [95647] = {
    { id = 95737, name = "Seeking Caitlin", optional = true },
  },
  [95809] = {
    { id = 95737, name = "Seeking Caitlin", optional = true },
    { id = 95647, name = "Lost in the Thicket Things" },
  },
  [95795] = {
    { id = 95772, name = "Songblade Search" },
  },
  [98824] = {
    { id = 95810, name = "Lost Relic Carry" },
  },
  [98823] = {
    { id = 95664, name = "Elder Knowledge" },
  },
  [95682] = {
    { id = 95663, name = "Dragonmaw Rumors", optional = true },
  },
  -- Scarlet Monastery: Graveyard
  [1113] = {
    { id = 1109, name = "Going, Going, Guano!" },
  },
}

FLT.QUEST_PREREQ_DETAILS = {
  [96391] = { level = 15, requires = 9, objective = "Deliver the Dark Iron Map to Earthseer Farsen in Dun Morogh.", pickup = "Dark Iron Map, dropped by Dark Iron Spies at Ironband's Compound, Dun Morogh", turnin = "Earthseer Farsen, Dun Morogh" },
  [865] = { level = 18, requires = 13, objective = "Gather 5 Intact Raptor Horns and bring them to Mebok Mizzyrix.", pickup = "Mebok Mizzyrix, Ratchet, The Barrens", turnin = "Mebok Mizzyrix, Ratchet, The Barrens" },
  [870] = { level = 13, requires = 10, objective = "Explore the waters of the Forgotten Pools northwest of the Crossroads, then report back.", pickup = "Tonga Runetotem, The Crossroads", turnin = "Tonga Runetotem, The Crossroads" },
  [877] = { level = 16, requires = 10, objective = "Take the Dried Seeds to the Stagnant Oasis and test them at the fissure.", pickup = "Tonga Runetotem, The Crossroads", turnin = "Tonga Runetotem, The Crossroads" },
  [880] = { level = 16, requires = 10, objective = "Bring 8 Altered Snapjaw Shells to Tonga Runetotem.", pickup = "Tonga Runetotem, The Crossroads", turnin = "Tonga Runetotem, The Crossroads" },
  [1489] = { level = 16, requires = 10, objective = "Speak with Hamuul Runetotem on Elder Rise in Thunder Bluff.", pickup = "Tonga Runetotem, The Crossroads", turnin = "Hamuul Runetotem, Elder Rise, Thunder Bluff" },
  [1490] = { level = 16, requires = 10, objective = "Speak with Nara Wildmane in Thunder Bluff.", pickup = "Hamuul Runetotem, Elder Rise, Thunder Bluff", turnin = "Nara Wildmane, Thunder Bluff" },
  [65] = { level = 18, requires = 14, objective = "Talk to Wiley the Black in Lakeshire.", pickup = "Gryan Stoutmantle, Sentinel Hill, Westfall", turnin = "Wiley the Black, Lakeshire, Redridge Mountains" },
  [132] = { level = 18, requires = 14, objective = "Take Wiley's Note back to Gryan Stoutmantle in Westfall.", pickup = "Wiley the Black, Lakeshire, Redridge Mountains", turnin = "Gryan Stoutmantle, Sentinel Hill, Westfall" },
  [135] = { level = 18, requires = 14, objective = "Take Wiley's Note to Master Mathias Shaw in Stormwind.", pickup = "Gryan Stoutmantle, Sentinel Hill, Westfall", turnin = "Master Mathias Shaw, Old Town, Stormwind" },
  [141] = { level = 18, requires = 14, objective = "Take Shaw's Report to Gryan Stoutmantle in Westfall.", pickup = "Master Mathias Shaw, Old Town, Stormwind", turnin = "Gryan Stoutmantle, Sentinel Hill, Westfall" },
  [142] = { level = 18, requires = 14, objective = "Track down the Defias Messenger and bring his message to Gryan Stoutmantle.", pickup = "Gryan Stoutmantle, Sentinel Hill, Westfall", turnin = "Gryan Stoutmantle, Sentinel Hill, Westfall" },
  [155] = { level = 18, requires = 14, objective = "Escort the Defias Traitor until he reveals the Defias hideout.", pickup = "Defias Traitor, Sentinel Hill, Westfall", turnin = "Gryan Stoutmantle, Sentinel Hill, Westfall" },
  [92742] = { level = 12, requires = 9, objective = "Use the Well Water Sample Kit at the Jansen Stead and Molsen Farm wells.", pickup = "Alba Fairmoon, Sentinel Hill inn, Westfall", turnin = "Alba Fairmoon, Sentinel Hill inn, Westfall" },
  [92744] = { level = 12, requires = 9, objective = "Collect 7 Longshore Murloc Gills along the Westfall shoreline.", pickup = "Alba Fairmoon, Westfall", turnin = "Alba Fairmoon, Westfall" },
  [92745] = { level = 14, requires = 9, objective = "Slay 4 Kobold Diggers and 6 Riverpaw Miners.", pickup = "Alba Fairmoon, Westfall", turnin = "Alba Fairmoon, Westfall" },
  [92747] = { level = 16, requires = 9, objective = "Collect 8 Suspicious Industrial Supplies from Moonbrook.", pickup = "Alba Fairmoon, Westfall", turnin = "Alba Fairmoon, Westfall" },
  [92748] = { level = 16, requires = 9, objective = "Travel to Stormwind and find an engineer who can help with explosives.", pickup = "Alba Fairmoon, Westfall", turnin = "Sprite Jumpsprocket, Dwarven District, Stormwind" },
  [92749] = { level = 16, requires = 9, objective = "Obtain 10 Coarse Dynamite.", pickup = "Sprite Jumpsprocket, Dwarven District, Stormwind", turnin = "Sprite Jumpsprocket, Dwarven District, Stormwind" },
  [92750] = { level = 16, requires = 9, objective = "Talk to Stormwind Intelligence about a remote detonator.", pickup = "Sprite Jumpsprocket, Dwarven District, Stormwind", turnin = "Stormwind Intelligence, Stormwind" },
  [92751] = { level = 16, requires = 9, objective = "Bring the Remote Detonator Kit back to Sprite Jumpsprocket.", pickup = "Stormwind Intelligence, Stormwind", turnin = "Sprite Jumpsprocket, Dwarven District, Stormwind" },
  [92752] = { level = 16, requires = 9, objective = "Return to Alba Fairmoon with the completed explosives.", pickup = "Sprite Jumpsprocket, Dwarven District, Stormwind", turnin = "Alba Fairmoon, Westfall" },
  [5726] = { level = 12, requires = 9, objective = "Bring a Lieutenant's Insignia from the Burning Blade in Skull Rock to Thrall.", pickup = "Thrall, Valley of Wisdom, Orgrimmar", turnin = "Thrall, Valley of Wisdom, Orgrimmar" },
  [5727] = { level = 12, requires = 9, objective = "Speak with Neeru Fireblade, then return to Thrall.", pickup = "Thrall, Valley of Wisdom, Orgrimmar", turnin = "Thrall, Valley of Wisdom, Orgrimmar" },
  [3765] = { level = 24, requires = 18, objective = "Travel to Gershala Nightwhisper in Auberdine, Darkshore.", pickup = "Argos Nightwhisper, The Park, Stormwind", turnin = "Gershala Nightwhisper, Auberdine, Darkshore" },
  [5722] = { level = 16, requires = 9, objective = "Find Maur Grimtotem's corpse inside Ragefire Chasm and search it.", pickup = "Rahauro, Elder Rise, Thunder Bluff", turnin = "Maur Grimtotem's corpse, inside Ragefire Chasm" },
  [6562] = { level = 22, requires = 17, objective = "Speak to Je'neu Sancrea in Ashenvale.", pickup = "Tsunaman, Stonetalon Mountains", turnin = "Je'neu Sancrea, Zoram'gar Outpost, Ashenvale" },
  [6564] = { level = 22, requires = 17, objective = "Bring the Damp Note to Je'neu Sancrea in Ashenvale.", pickup = "Damp Note", turnin = "Je'neu Sancrea, Zoram'gar Outpost, Ashenvale" },
  [303] = { level = 30, requires = 25, objective = "Kill 15 Dark Iron Dwarves, 5 Dark Iron Tunnelers, 5 Dark Iron Saboteurs and 5 Dark Iron Demolitionists.", pickup = "Motley Garmason, Dun Modr, Wetlands", turnin = "Motley Garmason, Dun Modr, Wetlands" },
  [373] = { level = 22, requires = 16, objective = "Deliver the Letter to the City Architect to Baros Alexston in Stormwind.", pickup = "An Unsent Letter, dropped by Edwin VanCleef in the Deadmines", turnin = "Baros Alexston, Cathedral Square, Stormwind" },
  [389] = { level = 22, requires = 16, objective = "Speak with Warden Thelwater at the Stockade.", pickup = "Baros Alexston, Cathedral Square, Stormwind", turnin = "Warden Thelwater, the Stockade, Stormwind" },
  [2923] = { level = 26, requires = 20, objective = "Speak with Tinkmaster Overspark in Ironforge.", pickup = "Brother Sarno, Cathedral Square, Stormwind", turnin = "Tinkmaster Overspark, Tinker Town, Ironforge" },
  [2925] = { level = 30, requires = 24, objective = "Speak with Klockmort Spannerspan in Ironforge.", pickup = "Mathiel, Warrior's Terrace, Darnassus", turnin = "Klockmort Spannerspan, Tinker Town, Ironforge" },
  [2931] = { level = 28, requires = 25, objective = "Speak with Master Mechanic Castpipe in Ironforge.", pickup = "Gaxim Rustfizzle, Stonetalon Mountains", turnin = "Master Mechanic Castpipe, Tinker Town, Ironforge" },
  [2927] = { level = 27, requires = 20, objective = "Speak with Ozzie Togglevolt in Kharanos.", pickup = "Gnoarn, Tinker Town, Ironforge", turnin = "Ozzie Togglevolt, Kharanos, Dun Morogh" },
  [2926] = { level = 27, requires = 20, objective = "Use the Empty Leaden Collection Phial on Irradiated Invaders or Pillagers outside Gnomeregan.", pickup = "Ozzie Togglevolt, Kharanos, Dun Morogh", turnin = "Ozzie Togglevolt, Kharanos, Dun Morogh" },
  [2945] = { level = 34, requires = 28, objective = "Clean the Grime-Encrusted Ring at the Sparklematic 5200.", pickup = "Grime-Encrusted Ring, dropped by the Dark Iron Ambassador", turnin = "The Sparklematic 5200, inside Gnomeregan" },
  [2842] = { level = 35, requires = 20, objective = "Speak with Scooty in Booty Bay.", pickup = "Sovik, Valley of Honor, Orgrimmar", turnin = "Scooty, Booty Bay, Stranglethorn Vale" },
  [1109] = { level = 33, requires = 30, objective = "Bring 1 pile of Kraul Guano from Razorfen Kraul.", pickup = "Master Apothecary Faranell, Undercity", turnin = "Master Apothecary Faranell, Undercity" },
  [95737] = { level = 31, requires = 24, objective = "Speak with Caitlin Grassman in Menethil Harbor.", pickup = "Quest giver not recorded yet", turnin = "Caitlin Grassman, Menethil Harbor, Wetlands" },
  [95647] = { level = 31, requires = 24, objective = "Find Ardin Grassman inside the Excavation Site.", pickup = "Caitlin Grassman, Menethil Harbor, Wetlands", turnin = "Ardin Grassman, inside the Excavation Site" },
  [95772] = { level = 31, requires = 24, objective = "Look for Daewyn Songblade in the Excavation Site.", pickup = "Dorin Songblade, Lakeshire, Redridge Mountains", turnin = "Daewyn Songblade's body, inside the Excavation Site" },
  [95810] = { level = 31, requires = 24, objective = "Bring the Titan Relic to Prospector Whelgar.", pickup = "Titan Relic, inside the Excavation Site", turnin = "Prospector Whelgar, Wetlands" },
  [95664] = { level = 31, requires = 24, objective = "Take the Titan Relic to the Elder Rise in Thunder Bluff.", pickup = "Titan Relic, inside the Excavation Site", turnin = "Elder Rise, Thunder Bluff" },
  [95663] = { level = 31, requires = 24, objective = "Meet the Deathstalker Agent above the Dragonmaw camp in the Wetlands.", pickup = "Quest giver not recorded yet", turnin = "Deathstalker Agent, Wetlands" },
}
