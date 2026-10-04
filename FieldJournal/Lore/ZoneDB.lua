local ADDON_NAME, FieldJournal = ...

FieldJournal_ZoneDB = FieldJournal_ZoneDB or {}

FieldJournal_ZoneDB["Dun Morogh"] = {
    displayName = "Dun Morogh",

    subregions = {
        {
            name = "Amberstill Ranch",
            description = "A snowbound ranch tucked among Dun Morogh’s hills. I found the place surprisingly calm for such a harsh frontier, with signs of steady work and stubborn dwarven endurance.",
        },
        {
            name = "Anvilmar",
            description = "A fortified dwarven outpost in the Coldridge Valley region. From what I observed, it serves as an early staging ground for recruits before they pass into the wider dangers of Dun Morogh.",
        },
        {
            name = "Brewnall Village",
            description = "A small settlement set against the frozen wilds. The village feels weather-worn but lived-in, the sort of place where travelers might pause before pressing deeper into the snow.",
        },
        {
            name = "Chill Breeze Valley",
            description = "A cold valley passage where the wind cuts sharply through the mountain snow. I noticed tracks vanish quickly here, swallowed by drifting powder and bitter air.",
        },
        {
            name = "Coldridge Pass",
            description = "A mountain pass linking Coldridge Valley to the rest of Dun Morogh. I marked it as an important route for travelers leaving the sheltered valley behind.",
        },
        {
            name = "Coldridge Valley",
            description = "A secluded snowy valley in southern Dun Morogh. It is known as a starting frontier for young dwarves and gnomes, though even this sheltered place carries the bite of the mountain wilds.",
        },
        {
            name = "Frostmane Hold",
            description = "A hostile Frostmane troll holding carved into the cold reaches of Dun Morogh. I kept my distance here; the signs of organized troll activity are difficult to miss.",
        },
        {
            name = "Gates of Ironforge",
            description = "The great approach to Ironforge, seat of dwarven power in the mountains. Standing before the gates, I could feel the weight of old stone, old kingdoms, and deeper halls beyond.",
        },
        {
            name = "Gnomeregan",
            description = "The fallen gnomish city lies within Dun Morogh’s mountain domain. Records mark it as a place of technological ruin, contamination, and lingering danger.",
        },
        {
            name = "Gol'Bolar Quarry",
            description = "A dwarven quarry cut into the frozen stone of Dun Morogh. I noted signs of heavy labor here, along with the familiar frontier trouble that seems to gather wherever resources are pulled from the earth.",
        },
        {
            name = "Gol'Bolar Quarry Mine",
            description = "The mine works beneath Gol'Bolar Quarry. The tunnels are close and dim, and I would not recommend entering without a clear path back out.",
        },
        {
            name = "The Grizzled Den",
            description = "A cave den known for wild beasts and rough terrain. I found claw marks, spoor, and enough signs of animal habitation to make lingering inside unwise.",
        },
        {
            name = "Helm's Bed Lake",
            description = "A cold mountain lake set into Dun Morogh’s snowy landscape. Its still waters make it a useful landmark, though the silence around the shore feels heavier than expected.",
        },
        {
            name = "Iceflow Lake",
            description = "A frozen lake region shaped by the bitter climate of Dun Morogh. The open ice and shifting visibility make it easy to understand why travelers rely on landmarks here.",
        },
        {
            name = "Ironband's Compound",
            description = "A dwarven compound in the mountain wilds. It appears to serve as a work site and local foothold over nearby resources.",
        },
        {
            name = "Kharanos",
            description = "A central dwarven settlement along the roads of Dun Morogh. I found it a welcome point of warmth and order between the colder, more dangerous stretches of the region.",
        },
        {
            name = "Misty Pine Refuge",
            description = "A sheltered refuge among snowy pines. Compared to the harsher passes, this place feels quiet, though the surrounding wilds still press close.",
        },
        {
            name = "North Gate Outpost",
            description = "A guarded outpost near the northern mountain routes. Its position suggests a defensive watch over traffic moving through the passes.",
        },
        {
            name = "North Gate Pass",
            description = "A mountain pass leading through Dun Morogh’s northern reaches. I noted the route as narrow, cold, and strategically important for movement through the region.",
        },
        {
            name = "Shimmer Ridge",
            description = "A snowy ridge where light catches strangely across stone and ice. I used the ridge as a landmark, though the exposure makes it a poor place to linger.",
        },
        {
            name = "South Gate Outpost",
            description = "A southern defensive post along Dun Morogh’s road network. The outpost appears to watch the approaches between settlements and the mountain routes beyond.",
        },
        {
            name = "South Gate Pass",
            description = "A southern mountain pass through the snowy highlands. The path is useful, but I would not call it safe; exposure and ambush both seem possible here.",
        },
        {
            name = "Steelgrill's Depot",
            description = "A small depot serving travelers and workers in Dun Morogh. I found it practical rather than grand, the kind of place built around supplies, repairs, and local news.",
        },
        {
            name = "Thunderbrew Distillery",
            description = "A dwarven distillery known in local records. Even in the frozen mountains, the place stands as proof that craft, drink, and stubborn cheer endure.",
        },
        {
            name = "The Tundrid Hills",
            description = "A stretch of cold hills within Dun Morogh’s snowy wilds. I found scattered tracks across the slopes, making the area a useful hunting ground for both predators and field researchers.",
        },
    }
}

FieldJournal_ZoneDB["Elwynn Forest"] = {
    displayName = "Elwynn Forest",

    subregions = {
        {
            name = "Goldshire",
            description = "Goldshire is a central human town in Elwynn Forest and one of the first major settlements many human adventurers visit after Northshire. I found its inn, guards, and crossroads made it feel like the forest's busy heart.",
        },
        {
            name = "Northshire Abbey",
            description = "Northshire Abbey serves as the sheltered beginning for many human recruits. Its stone walls and training grounds give the impression of safety, though the surrounding valley quickly proves that danger waits beyond the abbey's steps.",
        },
        {
            name = "Eastvale Logging Camp",
            description = "Eastvale Logging Camp is a working lumber settlement in eastern Elwynn. The sound of axes and saws carries through the trees, a reminder that Stormwind's strength is built as much by laborers as by soldiers.",
        },
        {
            name = "Westbrook Garrison",
            description = "Westbrook Garrison watches the western approach toward Elwynn's borderlands. I noted the place as a military outpost with good reason to keep its eyes on gnolls, bandits, and the road to Westfall.",
        },
        {
            name = "Tower of Azora",
            description = "The Tower of Azora rises as a mage's landmark in eastern Elwynn. It feels set apart from the farms and roads, a place where scholarship and arcane study stand watch over the forest.",
        },
        {
            name = "Maclure Vineyards",
            description = "Maclure Vineyards is one side of the southern farm rivalry in Elwynn. The vines and fields seem peaceful at first glance, though local quarrels give the place sharper edges than the scenery suggests.",
        },
        {
            name = "Stonefield Farm",
            description = "Stonefield Farm is a human farmstead caught up in family concerns, local work, and the practical troubles of rural Elwynn. I found it a good example of how personal matters and frontier danger often share the same fence line.",
        },
        {
            name = "Mirror Lake Orchard",
            description = "Mirror Lake Orchard lies near the waters and trees of central Elwynn. Its quiet rows and nearby lake make it feel gentler than the roads, though the forest never lets any place remain entirely untouched.",
        },
        {
            name = "Ridgepoint Tower",
            description = "Ridgepoint Tower stands as a watch point over the surrounding terrain. I marked it as one of Elwynn's reminders that even settled forest needs eyes on the horizon.",
        },
        {
            name = "Northshire Vineyards",
            description = "Northshire Vineyards lie within the early training grounds around Northshire. The fields show signs of ordinary work disrupted by the same troubles that test new recruits.",
        },
        {
            name = "Brackwell Pumpkin Patch",
            description = "Brackwell Pumpkin Patch is a southern Elwynn farm site associated with local trouble and Defias activity. The place looks rustic, but I found its fields carried the tension of a farm no longer fully under its owners' control.",
        },
        {
            name = "Jerod's Landing",
            description = "Jerod's Landing sits along Elwynn's waterways, where the forest gives way to the movement of boats, fishers, and murloc danger. I noted the banks carefully; water in Elwynn is rarely just scenery.",
        },
    }
}

if FieldJournal and FieldJournal.Config and FieldJournal.Config.debug then
    print(">>> ZoneDB LOADED <<<")
end

FieldJournal_ZoneDB["Loch Modan"] = {
    displayName = "Loch Modan",

    subregions = {
        {
            name = "Algaz Station",
            description = "Algaz Station sits near the mountain routes linking Loch Modan with neighboring lands. I marked it as a practical dwarven foothold where roads, patrols, and supply concerns meet the high passes.",
        },
        {
            name = "Dun Algaz",
            description = "Dun Algaz is the mountain pass between Loch Modan and the Wetlands. Its stonework and narrow approaches make it feel less like a road and more like a gate carved through Khaz Modan itself.",
        },
        {
            name = "The Farstrider Lodge",
            description = "The Farstrider Lodge is a hunters' lodge in the wilds of Loch Modan. I found it well placed for those who study beasts, test marksmanship, and live close to the forest's habits.",
        },
        {
            name = "Grizzlepaw Ridge",
            description = "Grizzlepaw Ridge is rough bear country marked by slopes, trees, and signs of large predators. The name feels earned; I saw enough tracks and broken brush to keep my weapon close.",
        },
        {
            name = "Ironband's Excavation Site",
            description = "Ironband's Excavation Site is a dwarven archaeological dig in Loch Modan. The site carries the excitement of discovery, but the surrounding dangers make every unearthed relic feel contested.",
        },
        {
            name = "Ironwing Cavern",
            description = "Ironwing Cavern is a cave site associated with the rugged terrain near Ironband's work. Any cavern in Loch Modan deserves caution; stone here often shelters more than echoes.",
        },
        {
            name = "The Loch",
            description = "The central lake gives Loch Modan its name and much of its character. Its waters are beautiful from a distance, though crocolisks and murlocs of other regions have taught me never to trust a shoreline blindly.",
        },
        {
            name = "Mo'grosh Stronghold",
            description = "Mo'grosh Stronghold is an ogre-held position in Loch Modan. The place feels claimed by force, with every path toward it suggesting that visitors are neither expected nor welcome.",
        },
        {
            name = "North Gate Pass",
            description = "North Gate Pass is one of the mountain approaches connecting Loch Modan to Dun Morogh. I noted it as a threshold between the colder dwarven homeland and the greener basin around the loch.",
        },
        {
            name = "Silver Stream Mine",
            description = "Silver Stream Mine is a dwarven mine troubled by Tunnel Rat kobolds. The tunnels show the familiar conflict between those who dig for industry and those who have already made the dark their home.",
        },
        {
            name = "South Gate Pass",
            description = "South Gate Pass forms another important route through the mountains. Like many dwarven roads, it feels sturdy and watched, yet never entirely free from the dangers beyond the stone.",
        },
        {
            name = "South Gate Outpost",
            description = "South Gate Outpost guards travel near the southern mountain routes. I found it a reminder that every reliable road in Khaz Modan is maintained by watchful eyes and armed hands.",
        },
        {
            name = "Stonesplinter Valley",
            description = "Stonesplinter Valley is strongly associated with trogg activity in Loch Modan. The ground feels hostile here, as though the hills themselves have been broken open to let older enemies out.",
        },
        {
            name = "Stonewrought Dam",
            description = "The Stonewrought Dam is a massive dwarven structure holding back the waters of Loch Modan. Standing near it, I felt the scale of dwarven engineering and the danger that would follow if such stone ever failed.",
        },
        {
            name = "Thelsamar",
            description = "Thelsamar is the principal dwarven settlement of Loch Modan. Its inn, guards, and roads give the region a settled heart amid mines, mountains, beasts, and hostile tribes.",
        },
        {
            name = "Stoutlager Inn",
            description = "Stoutlager Inn is the warm social center of Thelsamar. After the wild roads, its hearth and tables make the loch feel less like a frontier and more like a home defended by stubborn dwarves.",
        },
        {
            name = "Twilight Camp",
            description = "Twilight Camp marks a hostile encampment tied to darker cult activity in later records of the region. I would treat any such camp as a warning sign that the loch's dangers can shift with the age.",
        },
        {
            name = "Valley of Kings",
            description = "The Valley of Kings is a monumental dwarven passage marked by great stone figures. It is difficult to pass through without feeling the weight of history watching from the mountainsides.",
        },
    },
}

FieldJournal_ZoneDB["Westfall"] = {
    displayName = "Westfall",

    subregions = {
        {
            name = "Alexston Farmstead",
            description = "Alexston Farmstead is one of Westfall's ruined agricultural sites, touched by Defias activity and the wider collapse of local order. I found the place a stark example of fields left without protection long enough for outlaws to claim them.",
        },
        {
            name = "The Dagger Hills",
            description = "The Dagger Hills rise in southern Westfall, near the broken paths leading toward Moonbrook and the Deadmines. The ground feels harsher here, with every ridge offering a place for bandits or worse to watch the road.",
        },
        {
            name = "The Dead Acre",
            description = "The Dead Acre is a farmstead whose name suits Westfall's wounded condition. I marked it as a place where abandoned work, hostile machines, and dry earth tell the same story.",
        },
        {
            name = "Demont's Place",
            description = "Demont's Place is one of the smaller named holdings scattered across Westfall's farmland. It carries the lonely feeling common to the region, where a name can remain long after safety has gone.",
        },
        {
            name = "The Dust Plains",
            description = "The Dust Plains stretch across Westfall's dry interior. The wind carries grit over the open ground, and I found the land itself seemed tired from years of neglect.",
        },
        {
            name = "Mortwake's Tower/Klaven's Tower",
            description = "This tower is associated with hidden work, rogues, and the sort of secrecy that suits Westfall's shadowed corners. I noted it as a place where a lone structure can hold more danger than its size suggests.",
        },
        {
            name = "Furlbrow's Pumpkin Patch",
            description = "Furlbrow's Pumpkin Patch stands near the road from Elwynn into Westfall. Its fields introduce the traveler to the province's pattern: farms still visible, but peace already stripped away.",
        },
        {
            name = "Gold Coast Quarry",
            description = "Gold Coast Quarry is a worked site along Westfall's coast and a known area of Defias trouble. The quarry stone and nearby surf make it feel exposed, yet the danger there is very human.",
        },
        {
            name = "The Great Sea",
            description = "The Great Sea borders Westfall's western shore. Its waves offer relief from the dust inland, though the coast brings its own hazards in murlocs, crawlers, and deep-water predators.",
        },
        {
            name = "Jangolode Mine",
            description = "Jangolode Mine is a contested mine in Westfall, associated with kobold digging and the struggle over local resources. The tunnels feel like a smaller version of the whole province: valuable, occupied, and difficult to reclaim.",
        },
        {
            name = "The Jansen Stead",
            description = "The Jansen Stead is another rural holding within Westfall's broken farm country. I found its quiet fields carried the same uneasy question as many places here: who is left to defend them?",
        },
        {
            name = "Longshore",
            description = "Longshore lies along Westfall's coastline, where wreckage, murlocs, and sea creatures shape the local danger. The shore looks open, but I would not call it safe.",
        },
        {
            name = "Westfall Lighthouse",
            description = "The Westfall Lighthouse stands on the coast as a maritime landmark. Its presence suggests guidance and warning, both badly needed along a shoreline where the sea and the Defias leave little room for comfort.",
        },
        {
            name = "The Molsen Farm",
            description = "The Molsen Farm is one of Westfall's many named farmsteads caught in the region's decline. I recorded it among the places where the memory of work remains stronger than the signs of prosperity.",
        },
        {
            name = "Moonbrook",
            description = "Moonbrook is a ruined town in southwestern Westfall and a major Defias stronghold. The place feels occupied rather than abandoned, with danger gathering in streets that should have belonged to ordinary folk.",
        },
        {
            name = "Cooper Residence",
            description = "The Cooper Residence is a small holding within Westfall's network of farms and homes. I found it useful to mark because in Westfall, even individual houses can become landmarks in a larger story of loss.",
        },
        {
            name = "Defias Hideout",
            description = "The Defias Hideout marks the hidden power beneath Westfall's surface and the path toward the Deadmines. It is not merely a den of thieves, but the concealed heart of a rebellion that reshaped the province.",
        },
        {
            name = "The Deadmines",
            description = "The Deadmines are the great mine complex beneath Moonbrook and the stronghold tied to Edwin VanCleef's Defias Brotherhood in Classic Alliance questing. I marked it as one of Westfall's deepest wounds, both literally and politically.",
        },
        {
            name = "Moonbrook Schoolhouse",
            description = "The Moonbrook Schoolhouse is a haunting reminder that Moonbrook was once a community rather than a fortress of outlaws. In a place like Westfall, the loss of ordinary buildings can feel heavier than a battlefield.",
        },
        {
            name = "The Raging Chasm",
            description = "The Raging Chasm cuts into Westfall's rougher terrain. I found it a harsh landmark, the sort of broken ground that makes travel slower and ambush easier.",
        },
        {
            name = "Saldean's Farm",
            description = "Saldean's Farm remains one of the better-known farmsteads still tied to local work and survival. The Saldeans' requests show how Westfall's people make do with what can still be gathered from a dangerous land.",
        },
        {
            name = "Sentinel Hill",
            description = "Sentinel Hill is the main Alliance military foothold in Westfall and the center of the People's Militia effort. I found it less a safe town than a stubborn rallying point against everything pressing in from the fields.",
        },
        {
            name = "Sentinel Tower",
            description = "Sentinel Tower rises above the hill as a watchpoint over Westfall's troubles. Its height gives a clear view, though seeing the province's wounds from above does not make them easier to mend.",
        },
        {
            name = "Stendel's Pond",
            description = "Stendel's Pond is a small water landmark in a dry and troubled region. The pond feels quiet compared to the coast, but in Westfall even still water deserves a careful glance.",
        },
    },
}



-- =========================================================
-- DARKSHORE
-- =========================================================

FieldJournal_ZoneDB["Darkshore"] = {
    displayName = "Darkshore",
    levelRange = "11 - 19",
    faction = "Alliance",
    subregions = {
        { name = "Auberdine", description = "Auberdine is the principal Alliance settlement on Darkshore's coast in Classic-era travel. I found it less like a bright port and more like a watchful refuge against sea, ruin, and forest gloom." },
        { name = "Bashal'Aran", description = "Bashal'Aran is an ancient kaldorei ruin north of Auberdine, haunted by sprites and darker influences. Its stones carry the feeling of old sanctity disturbed." },
        { name = "Ameth'Aran", description = "Ameth'Aran is another ruined night elf site along Darkshore, filled with traces of the past and present danger. I marked it as a place where archaeology and survival cannot be separated." },
        { name = "Ruins of Mathystra", description = "The Ruins of Mathystra lie in northern Darkshore, where naga and ancient history crowd the coast. The place feels like a warning from the sea and the past at once." },
        { name = "The Master's Glaive", description = "The Master's Glaive is dominated by a vast ancient weapon and the dark presence surrounding it. I found the ground there oppressive, as if even the soil remembered violence." },
        { name = "Cliffspring River", description = "The Cliffspring River runs through northern Darkshore toward the sea. Its water and banks form a natural route, but the nearby creatures and ruins make careless travel unwise." },
        { name = "Cliffspring Falls", description = "Cliffspring Falls is a high, wet landmark in the northern woods. The sound of falling water offers little comfort when the surrounding forest remains so dim." },
        { name = "Remtravel's Excavation", description = "Remtravel's Excavation is a dwarven dig site along the coast, proof that Darkshore draws scholars as well as soldiers. I found the work brave, though the surrounding land gives little mercy to curiosity." },
        { name = "Grove of the Ancients", description = "The Grove of the Ancients holds a more sacred and ancient character than much of the coast. It feels like one of the few places where the forest still speaks in a calmer voice." },
        { name = "Twilight Shore", description = "Twilight Shore is a stretch of hostile beach tied to cult activity and the sea's darker influence. The camps there make the coast feel watched by more than gulls and murlocs." },
        { name = "The Long Wash", description = "The Long Wash is the coastal approach used by travelers arriving at Darkshore. Its name suits the place: a long, gray threshold between open sea and troubled land." },
        { name = "Mist's Edge", description = "Mist's Edge is a coastal margin where sea air and forest shadow meet. I found visibility unreliable there, and every sound seemed to carry farther than expected." },
    },
}

-- =========================================================
-- SILVERPINE FOREST
-- =========================================================

FieldJournal_ZoneDB["Silverpine Forest"] = {
    displayName = "Silverpine Forest",
    levelRange = "10 - 20",
    faction = "Horde",
    subregions = {
        { name = "The Sepulcher", description = "The Sepulcher is the main Forsaken settlement in Silverpine Forest. It feels less like a town built for comfort and more like a command post dug into a grave-cold frontier." },
        { name = "Ambermill", description = "Ambermill is a Dalaran-aligned human settlement in southern Silverpine. Its arcane defenders make it one of the clearest signs that the forest remains contested by the living." },
        { name = "Pyrewood Village", description = "Pyrewood Village appears as a surviving human settlement by day, but its curse gives it a darker reputation. I recorded it as one of Silverpine's most unsettling places." },
        { name = "Shadowfang Keep", description = "Shadowfang Keep rises over the forest as a stronghold of worgen, shadow, and old noble ruin. Even from outside, the place seems to gather the zone's dread into stone." },
        { name = "The Greymane Wall", description = "The Greymane Wall bars the way to Gilneas at Silverpine's southern edge. Its closed gates make the border feel less like protection and more like a sealed secret." },
        { name = "The Dead Field", description = "The Dead Field is a bleak farmstead area where the name feels earned. I found the silence there heavier than ordinary abandonment." },
        { name = "The Decrepit Ferry", description = "The Decrepit Ferry lies near the water routes of Silverpine, a reminder that travel once crossed these shores more freely. Now the place feels stranded between forest and dark water." },
        { name = "North Tide's Run", description = "North Tide's Run is a murloc-held shoreline settlement along Silverpine's coast. The wet camps and constant croaking make the beach unsafe for any lone traveler." },
        { name = "Fenris Isle", description = "Fenris Isle sits in Lordamere Lake, isolated and grim. Its ruins and undead presence make crossing the water feel like entering a separate pocket of Silverpine's curse." },
        { name = "Deep Elem Mine", description = "Deep Elem Mine is an abandoned mine in Silverpine, now more useful as a den for danger than a place of labor. I marked it as one of the forest's darker interiors." },
    },
}


-- =========================================================
-- RUINS OF LORDAERON
-- WoW Forever dungeon; recommended level 16 - 22.
-- =========================================================

FieldJournal_ZoneDB["Ruins of Lordaeron"] = {
    displayName = "Ruins of Lordaeron",
    levelRange = "16 - 22",
    faction = "Contested",
    subregions = {
        { name = "King's Alley", description = "King's Alley cuts through the eastern side of the ruined capital, where Scourge and monstrous remnants still patrol the old streets. The district feels less abandoned than occupied by everything Lordaeron failed to bury." },
        { name = "Lordaeron Graveyard", description = "Lordaeron Graveyard holds the dead of the fallen kingdom beneath the shadow of fresh Scourge activity. Among the broken stones and old grief, the city's history feels dangerously close to the surface." },
        { name = "Lordamere Overlook", description = "Lordamere Overlook rises above the ruined streets beneath an unnatural fog. Scourge forces patrol its approaches, turning an old vantage point into dangerous ground overlooking what remains of Lordaeron." },
        { name = "Market Street", description = "Market Street runs through the commercial ruins of the old capital, now crowded with undead instead of merchants. Its broken storefronts make the city's destruction feel especially immediate." },
    },
}

-- =========================================================
-- STONETALON MOUNTAINS
-- =========================================================

FieldJournal_ZoneDB["Stonetalon Mountains"] = {
    displayName = "Stonetalon Mountains",
    levelRange = "15 - 25",
    faction = "Contested",
    subregions = {
        { name = "Sun Rock Retreat", description = "Sun Rock Retreat is a Horde outpost set among the Stonetalon ridges. It feels like a hard-won resting place in a zone where cliff, harpy, and company axe all compete for space." },
        { name = "Stonetalon Peak", description = "Stonetalon Peak is a sacred height tied to both night elf and tauren reverence. I found the place solemn, a reminder that these mountains are spiritual ground as well as battlefield." },
        { name = "Windshear Crag", description = "Windshear Crag bears the scars of Venture Company exploitation. Cut earth, smoke, and broken trees make it one of the clearest wounds in the mountains." },
        { name = "Webwinder Path", description = "Webwinder Path winds through hostile ground where beasts and ambushes threaten travelers. The route demands attention with every bend." },
        { name = "Webwinder Hollow", description = "Webwinder Hollow is a dangerous low place within the mountains, holding predators and hostile movement close. I marked it as a poor place to be caught after dark." },
        { name = "The Charred Vale", description = "The Charred Vale is a burned and broken stretch of Stonetalon, harsh even by the zone's standards. It shows what fire and violence can do to a mountain forest." },
        { name = "Mirkfallon Lake", description = "Mirkfallon Lake offers water and open ground within the rugged zone. Its calmer surface contrasts sharply with the contested ridges nearby." },
        { name = "Malaka'jin", description = "Malaka'jin is a troll settlement near the southern reaches of Stonetalon. It marks the zone's connection to wider Horde and tribal movement through Kalimdor." },
        { name = "Sishir Canyon", description = "Sishir Canyon is a rugged pass marked by danger and rough travel. I found the canyon walls made every sound feel close." },
        { name = "Boulderslide Ravine", description = "Boulderslide Ravine is a rocky depression where hostile creatures and difficult footing combine. It is the sort of place where the land itself seems to join the fight." },
    },
}

-- =========================================================
-- REDRIDGE MOUNTAINS
-- =========================================================

FieldJournal_ZoneDB["Redridge Mountains"] = {
    displayName = "Redridge Mountains",
    levelRange = "15 - 25",
    faction = "Contested",
    subregions = {
        { name = "Lakeshire", description = "Lakeshire is the main Alliance settlement of Redridge, built beside Lake Everstill. Its calm water and red hills make it feel peaceful until reports from Stonewatch and the roads begin." },
        { name = "Lake Everstill", description = "Lake Everstill dominates central Redridge and sustains the town's fishing and travel. I found its beauty deceptive, since murlocs and other dangers trouble the banks." },
        { name = "Stonewatch Keep", description = "Stonewatch Keep is the Blackrock orc stronghold in Redridge. The place turns the northern hills into military ground rather than countryside." },
        { name = "Stonewatch Falls", description = "Stonewatch Falls marks the waters near the orc-held heights. Its natural beauty is difficult to enjoy with enemy patrols nearby." },
        { name = "Render's Camp", description = "Render's Camp is tied to Blackrock activity and the wider threat around Stonewatch. I marked it as hostile ground where the orcs' control becomes plain." },
        { name = "Render's Valley", description = "Render's Valley cuts through Redridge's dangerous northern territory. The terrain funnels movement in a way that favors patrols and ambushes." },
        { name = "Render's Rock", description = "Render's Rock is a hard landmark associated with Blackrock presence. It feels like the hills themselves have been made into a fortress approach." },
        { name = "Alther's Mill", description = "Alther's Mill is an abandoned or endangered mill site in Redridge. The place speaks to ordinary industry pushed aside by war and monsters." },
        { name = "Three Corners", description = "Three Corners links Redridge to neighboring lands and roads. It is a useful landmark, though crossroads often collect trouble as easily as travelers." },
        { name = "Redridge Canyons", description = "The Redridge canyons and hills frame the province with red stone and broken paths. I found the terrain beautiful, but it gives many enemies places to hide." },
    },
}

-- =========================================================
-- DUSKWOOD
-- =========================================================

FieldJournal_ZoneDB["Duskwood"] = {
    displayName = "Duskwood",
    levelRange = "10 - 30",
    faction = "Contested",
    subregions = {
        { name = "Darkshire", description = "Darkshire is the main settlement of Duskwood and the stronghold of the Night Watch. Its lamps and guards feel less like comfort and more like defiance against the surrounding dark." },
        { name = "Raven Hill", description = "Raven Hill is a ruined village near the cemetery, heavy with abandonment and dread. I found the silence there almost worse than the undead." },
        { name = "Raven Hill Cemetery", description = "Raven Hill Cemetery is one of Duskwood's most dangerous places, crawling with undead and old grief. The earth itself seems unwilling to keep its dead." },
        { name = "Twilight Grove", description = "Twilight Grove lies at Duskwood's center and is tied to the Emerald Dream portal guarded by dangerous dragons in Classic. The place feels different from the rest of the forest, ancient rather than merely haunted." },
        { name = "The Rotting Orchard", description = "The Rotting Orchard is a corrupted farmstead where worgen and decay crowd the trees. It shows how Duskwood's curse reaches even places once meant for harvest." },
        { name = "The Yorgen Farmstead", description = "The Yorgen Farmstead stands as another haunted remnant of ordinary life overtaken by the forest's darkness. I found it difficult to imagine peace there." },
        { name = "Vul'Gol Ogre Mound", description = "Vul'Gol Ogre Mound is a hostile ogre camp in the Duskwood hills. It broadens the zone's dangers beyond curses and undead into brute frontier violence." },
        { name = "Addle's Stead", description = "Addle's Stead is an abandoned farmstead swallowed by Duskwood's gloom. Its ruined buildings feel like a warning to every settlement still holding out." },
        { name = "Tranquil Gardens Cemetery", description = "Tranquil Gardens Cemetery carries a name more hopeful than its field reality. In Duskwood, even a quiet graveyard must be watched closely." },
        { name = "Manor Mistmantle", description = "Manor Mistmantle is tied to Duskwood's darker local stories and suspicions. The manor's presence adds a noble, decaying weight to the forest's mysteries." },
        { name = "The Hushed Bank", description = "The Hushed Bank lies near the river border, where the forest's silence presses against the water. I recorded it as a place where travel feels exposed despite the trees." },
        { name = "Beggar's Haunt", description = "Beggar's Haunt sits near Duskwood's eastern approach toward Deadwind Pass. Its name suits the desolate feeling of the borderlands." },
    },
}


-- =========================================================
-- ASHENVALE
-- =========================================================
FieldJournal_ZoneDB["Ashenvale"] = {
    displayName = "Ashenvale",
    levelRange = "19 - 30",
    faction = "Contested",
    subregions = {
        { name = "Astranaar", description = "Astranaar is a major night elf settlement in the heart of Ashenvale. I found its lamps and bridges a calm center amid a forest increasingly strained by war." },
        { name = "Maestra's Post", description = "Maestra's Post guards the northern road from Darkshore into Ashenvale. It feels like a frontier watch where every report from the trees matters." },
        { name = "The Zoram Strand", description = "The Zoram Strand is Ashenvale's western coast, where naga and ruins make the shore dangerous. The surf hides more than shells here." },
        { name = "Blackfathom Deeps", description = "Blackfathom Deeps lies beneath old ruins along the coast. Records mark it as a place of ancient power, corruption, and deep water." },
        { name = "Bashal'Aran", description = "Bashal'Aran is a ruined kaldorei site where old stone and hostile creatures share the same shadows. I marked the place as beautiful only from a distance." },
        { name = "Ameth'Aran", description = "Ameth'Aran is another ancient ruin in the forest, heavy with history and danger. The site feels less abandoned than disturbed." },
        { name = "The Ruins of Stardust", description = "The Ruins of Stardust are remnants of old night elf presence within Ashenvale. I found the area quiet in the uneasy way ruins often are." },
        { name = "Raynewood Retreat", description = "Raynewood Retreat is a kaldorei outpost tucked among the trees. It serves as a reminder that Ashenvale is both wilderness and homeland." },
        { name = "Silverwind Refuge", description = "Silverwind Refuge lies near the southeastern forest and the road toward the Barrens. The refuge feels exposed, a small hold of order near contested ground." },
        { name = "Warsong Lumber Camp", description = "Warsong Lumber Camp is a Horde logging operation that scars the forest with axes and smoke. I noted it as one of Ashenvale's clearest wounds." },
        { name = "Satyrnaar", description = "Satyrnaar is a corrupted area associated with satyr activity. The trees there feel watched, and not by anything wholesome." },
        { name = "Felfire Hill", description = "Felfire Hill carries signs of demonic corruption and hostile forces. I would not recommend lingering there without purpose." },
    },
}

-- =========================================================
-- WETLANDS
-- =========================================================
FieldJournal_ZoneDB["Wetlands"] = {
    displayName = "Wetlands",
    levelRange = "20 - 30",
    faction = "Contested",
    subregions = {
        { name = "Menethil Harbor", description = "Menethil Harbor is the main Alliance port on the western coast of the Wetlands. The docks feel like civilization clinging to the edge of a vast marsh." },
        { name = "Dun Algaz", description = "Dun Algaz is the mountain pass linking the Wetlands to Loch Modan. Its tunnels and guarded ways make the border feel hard-won." },
        { name = "The Green Belt", description = "The Green Belt is a stretch of marshland and growth near Menethil's approaches. I found it wet, tangled, and easy to underestimate." },
        { name = "Bluegill Marsh", description = "Bluegill Marsh is murloc-held wetland where water and reeds hide movement. The place sounds alive before anything can be seen." },
        { name = "Sundown Marsh", description = "Sundown Marsh is a low, waterlogged region that earns its name in the heavy light over the reeds. I marked it as dangerous ground for slow travel." },
        { name = "Mosshide Fen", description = "Mosshide Fen is associated with gnoll activity and rough marsh camps. Stolen goods and crude fires make the place feel less empty than the map suggests." },
        { name = "Whelgar's Excavation Site", description = "Whelgar's Excavation Site is a dwarven dig in the marsh. Its tools and trenches stand in sharp contrast to the wet wilderness around it." },
        { name = "Angerfang Encampment", description = "Angerfang Encampment is an orc-held position in the Wetlands. I noted its defenses as proof that old war still has teeth here." },
        { name = "Dragonmaw Gates", description = "The Dragonmaw Gates mark hostile territory tied to orcish strength and old conflict. Passing near them feels like crossing into a war record." },
        { name = "Grim Batol", description = "Grim Batol rises in the eastern Wetlands with a grim reputation. Even from afar, it feels like a place where history has not settled peacefully." },
        { name = "Raptor Ridge", description = "Raptor Ridge is hunting ground for the Wetlands' reptilian predators. The tracks there are sharp and frequent." },
        { name = "The Lost Fleet", description = "The Lost Fleet lies off the coast as wreckage and warning. The sea here keeps its own ledger of failed crossings." },
    },
}

-- =========================================================
-- HILLSBRAD FOOTHILLS
-- =========================================================
FieldJournal_ZoneDB["Hillsbrad Foothills"] = {
    displayName = "Hillsbrad Foothills",
    levelRange = "20 - 31",
    faction = "Contested",
    subregions = {
        { name = "Southshore", description = "Southshore is an Alliance settlement on the coast of Hillsbrad. Its harbor and town walls feel peaceful only until one remembers how close Tarren Mill lies." },
        { name = "Tarren Mill", description = "Tarren Mill is the Forsaken foothold in Hillsbrad. The place carries the cold order of undead administration amid green countryside." },
        { name = "Hillsbrad Fields", description = "Hillsbrad Fields are working human farms spread across the foothills. I found the land fertile, contested, and painfully exposed." },
        { name = "Durnholde Keep", description = "Durnholde Keep is a ruined fortress tied to older wars and prison history. Its stones still feel occupied by conflict." },
        { name = "Azurelode Mine", description = "Azurelode Mine is an active contested mine in Hillsbrad. In the dark below, labor and violence are difficult to separate." },
        { name = "Purgation Isle", description = "Purgation Isle lies off the coast with a haunted reputation. The island feels distant from the mainland's politics, but not from danger." },
        { name = "Nethander Stead", description = "Nethander Stead is one of the rural holdings of Hillsbrad. It shows the ordinary farm life that war and raids threaten to erase." },
        { name = "Darrow Hill", description = "Darrow Hill rises over the countryside with old structures and uneasy paths. I marked it as a place where the terrain gives watchers an advantage." },
        { name = "Western Strand", description = "The Western Strand runs along the coast where murlocs and sea air meet the foothills. The shore is more dangerous than its open view suggests." },
        { name = "Corrahn's Dagger", description = "Corrahn's Dagger is a sharp-featured landmark in the foothills. The land there feels suited to ambush and watch posts." },
    },
}

-- =========================================================
-- THE BARRENS
-- =========================================================
FieldJournal_ZoneDB["The Barrens"] = {
    displayName = "The Barrens",
    levelRange = "10 - 33",
    faction = "Horde",
    subregions = {
        { name = "The Crossroads", description = "The Crossroads is the central Horde hub of the Barrens. From there, the roads stretch in every direction across heat, dust, and danger." },
        { name = "Ratchet", description = "Ratchet is a Steamwheedle Cartel port on the eastern coast. Its docks make the Barrens feel connected to distant seas and less lawful business." },
        { name = "Camp Taurajo", description = "Camp Taurajo is a tauren settlement in the southern Barrens. Its tents and hunters give warmth to an otherwise harsh plain." },
        { name = "Far Watch Post", description = "Far Watch Post watches the road from Durotar into the Barrens. I found it a welcome sign of Horde order near the zone's northern approach." },
        { name = "The Forgotten Pools", description = "The Forgotten Pools are one of the Barrens' precious oases. Water draws life, and in this land that means danger as well as relief." },
        { name = "Lushwater Oasis", description = "Lushwater Oasis is greener than much of the surrounding savanna. Its shade makes it valuable to beasts, travelers, and enemies alike." },
        { name = "Stagnant Oasis", description = "Stagnant Oasis is another water source in the Barrens, less inviting than its name suggests. Still water here rarely means safe water." },
        { name = "Wailing Caverns", description = "Wailing Caverns lies beneath the Barrens and is associated with druidic trouble and strange growth. The entrance feels like the land breathing from below." },
        { name = "Razorfen Kraul", description = "Razorfen Kraul is a thorned quillboar stronghold in the southern Barrens. The brambles themselves seem to warn travelers away." },
        { name = "Razorfen Downs", description = "Razorfen Downs lies near the southern reaches of the Barrens and carries darker associations. I marked it as a place where the land's thorns meet death." },
        { name = "Dreadmist Peak", description = "Dreadmist Peak rises over the Barrens with a hostile reputation. The height gives it a presence visible long before it is reached." },
        { name = "Boulder Lode Mine", description = "Boulder Lode Mine is a contested resource site in the northern Barrens. The mine shows that even in a wide savanna, the underground draws conflict." },
        { name = "Sludge Fen", description = "Sludge Fen is an industrial scar in the Barrens. Smoke, machinery, and foul pools mark it as a place where profit has overridden care." },
        { name = "Bramblescar", description = "Bramblescar is a thorn-choked region tied to quillboar presence. Moving through it feels like entering hostile architecture." },
    },
}

-- =========================================================
-- THOUSAND NEEDLES
-- =========================================================
FieldJournal_ZoneDB["Thousand Needles"] = {
    displayName = "Thousand Needles",
    levelRange = "24 - 35",
    faction = "Contested",
    subregions = {
        { name = "Freewind Post", description = "Freewind Post is a Horde outpost perched high among the mesas. Its lifts and bridges make the height feel like both refuge and risk." },
        { name = "The Great Lift", description = "The Great Lift connects the Barrens to Thousand Needles. Descending into the canyon, I felt the land change from open savanna to stone spires and wind." },
        { name = "Highperch", description = "Highperch is a harpy-held height in Thousand Needles. The name is accurate; danger there comes from above." },
        { name = "Darkcloud Pinnacle", description = "Darkcloud Pinnacle is a Grimtotem-held mesa. Its isolation gives it the feeling of a fortress raised by geography itself." },
        { name = "Splithoof Crag", description = "Splithoof Crag is a rugged area of caves and rocky trails. I marked it as a place where every turn of stone can hide movement." },
        { name = "The Weathered Nook", description = "The Weathered Nook is a sheltered pocket among harsh canyon walls. Its quiet feels temporary, as if the wind merely pauses there." },
        { name = "Camp E'thok", description = "Camp E'thok is a small camp within Thousand Needles' canyon routes. It serves as a point of contact in a land where safe stops are rare." },
        { name = "Shimmering Flats", description = "The Shimmering Flats are a broad saltpan east of the mesas, famous in Classic for racing and engineering activity. The glare makes distance hard to judge." },
        { name = "Mirage Raceway", description = "Mirage Raceway is a neutral racing camp in the Shimmering Flats. Goblin and gnomish rivalry turns the empty salt into noise, speed, and invention." },
        { name = "The Screeching Canyon", description = "The Screeching Canyon carries sound strangely between stone walls. I found it easy to imagine enemies hearing a traveler long before being seen." },
        { name = "Roguefeather Den", description = "Roguefeather Den is associated with harpy activity among the heights. Feathers and bones mark the approach well enough." },
        { name = "Rustmaul Dig Site", description = "Rustmaul Dig Site is a dwarven-style excavation in a harsh canyon land. The work seems small beneath the cliffs, but every dig has a way of waking trouble." },
    },
}
-- =========================================================
-- DUROTAR
-- =========================================================

FieldJournal_ZoneDB["Durotar"] = {
    displayName = "Durotar",
    levelRange = "1 - 10",
    faction = "Horde",

    subregions = {
        { name = "Valley of Trials", description = "The Valley of Trials is the proving ground for young orcs and trolls in southern Durotar. I found its harsh red earth fitting for a first lesson in Horde survival." },
        { name = "The Den", description = "The Den serves as the central shelter and command point within the Valley of Trials. It feels less like comfort and more like a place where new lives are sharpened for the world outside." },
        { name = "Sen'jin Village", description = "Sen'jin Village is a troll settlement on Durotar's coast, close to the Echo Isles and the sea's dangers. Its huts and shore paths carry the sound of both village life and nearby threat." },
        { name = "Echo Isles", description = "The Echo Isles lie off the Durotar coast and are tied closely to the Darkspear trolls. The islands feel beautiful at a distance, though raptors, crawlers, and hostile forces make them far from peaceful." },
        { name = "Razor Hill", description = "Razor Hill is a major Horde outpost along Durotar's road north toward Orgrimmar. I marked it as the practical heart of the region's defense and trade." },
        { name = "Drygulch Ravine", description = "Drygulch Ravine cuts through Durotar's dry stone with the look of a place made for ambush. The land narrows there, and every echo seems worth noting." },
        { name = "Skull Rock", description = "Skull Rock is a cave of ill reputation near Orgrimmar's approaches, associated with dangerous cult activity. I would not enter it without preparation and a ready weapon." },
        { name = "Tiragarde Keep", description = "Tiragarde Keep stands as a hostile human-held ruin on Durotar's coast. Its presence reminds the observer that the Horde's new homeland is still watched by old enemies." },
        { name = "Thunder Ridge", description = "Thunder Ridge is a rugged rise of stone and beasts within Durotar. The ground feels ancient and exposed, shaped by weather, claws, and the stubborn life of the region." },
        { name = "Southfury River", description = "The Southfury River marks a vital boundary and waterway near Durotar. In a land where drinkable water is precious, every river crossing carries both promise and danger." },
        { name = "Orgrimmar", description = "Orgrimmar rises from northern Durotar as the Horde's great orcish capital. Even from beyond its gates, the city gives the impression of a people building permanence out of stone and hardship." },
    },
}

-- =========================================================
-- MULGORE
-- =========================================================

FieldJournal_ZoneDB["Mulgore"] = {
    displayName = "Mulgore",
    levelRange = "1 - 10",
    faction = "Horde",

    subregions = {
        { name = "Red Cloud Mesa", description = "Red Cloud Mesa is the southern training ground of young tauren, sheltered within Mulgore's wide natural walls. I found the land open and calm, though its lessons begin quickly." },
        { name = "Camp Narache", description = "Camp Narache rests within Red Cloud Mesa as the first home of many tauren adventurers. Its tents and teachers give the sense of a people beginning their service in reverence rather than haste." },
        { name = "Bloodhoof Village", description = "Bloodhoof Village is the central tauren settlement of Mulgore, set near Stonebull Lake. The village feels grounded and communal, surrounded by grass, water, and constant signs of the hunt." },
        { name = "Stonebull Lake", description = "Stonebull Lake lies near Bloodhoof Village and serves as one of Mulgore's gentle landmarks. Its water gives the plains a quiet center, though the surrounding wilds remain watchful." },
        { name = "Thunder Bluff", description = "Thunder Bluff rises atop great mesas in northern Mulgore as the tauren capital. Its lifts, bridges, and open sky make it unlike any city of stone or timber I have seen." },
        { name = "Red Rocks", description = "Red Rocks is a spiritually significant area troubled by Bristleback quillboar. The red stone makes the conflict there feel like a wound visible in the earth itself." },
        { name = "Bristleback Ravine", description = "Bristleback Ravine is a hostile quillboar-held stretch of Mulgore. Its broken ground and enemy presence make it one of the first serious tests of tauren defenders." },
        { name = "The Venture Co. Mine", description = "The Venture Co. Mine is a scar of outside greed cut into Mulgore's peaceful valley. I found the place offensive not only for its danger, but for its disregard of the land around it." },
        { name = "The Golden Plains", description = "The Golden Plains roll across Mulgore in wide grass and open wind. The beauty is real, but so are the prowlers, wolves, and swoops that live within it." },
        { name = "The Rolling Plains", description = "The Rolling Plains show Mulgore at its most open, where sky and grass seem to stretch without end. Travel there rewards patience and clear sightlines." },
        { name = "Ravaged Caravan", description = "The Ravaged Caravan marks the cost of travel through even a sheltered homeland. I noted the place as a reminder that Mulgore's peace is guarded, not guaranteed." },
        { name = "Palemane Rock", description = "Palemane Rock is associated with gnoll activity in Mulgore. Its caves and rough ground give hostile bands shelter close enough to trouble the plains." },
        { name = "Bael'dun Digsite", description = "The Bael'dun Digsite is a dwarven excavation site in Mulgore. To tauren eyes, the digging carries the same unease as any force that cuts into sacred ground without listening first." },
    },
}

-- =========================================================
-- TIRISFAL GLADES
-- =========================================================

FieldJournal_ZoneDB["Tirisfal Glades"] = {
    displayName = "Tirisfal Glades",
    levelRange = "1 - 12",
    faction = "Horde",

    subregions = {
        { name = "Deathknell", description = "Deathknell is the Forsaken starting village, a grave-cold place where newly risen undead first take command of their own will. I found it grim, but purposeful." },
        { name = "Shadow Grave", description = "Shadow Grave lies within Deathknell's bounds as a place of awakening and burial both. It is difficult to stand there without feeling the thin line between corpse and citizen." },
        { name = "Brill", description = "Brill is the main Forsaken settlement in western Tirisfal, standing among dead trees and old Lordaeron roads. The town feels practical, wary, and accustomed to grim necessities." },
        { name = "Agamand Mills", description = "Agamand Mills is an overrun farmstead where the dead of a noble family linger as threats. Its fields and buildings show how domestic life in Lordaeron curdled into undeath." },
        { name = "Solliden Farmstead", description = "Solliden Farmstead is one of the ruined holdings near Deathknell. Its decay makes clear that Tirisfal's dangers begin almost as soon as one leaves the grave." },
        { name = "Garren's Haunt", description = "Garren's Haunt is a troubled stretch of Tirisfal associated with undead and local danger. I marked it as one of many places where the past refuses to stay buried." },
        { name = "Scarlet Watch Post", description = "The Scarlet Watch Post is a fortified Scarlet Crusade position in Tirisfal. Its banners and patrols show that living enemies still press hard against Forsaken lands." },
        { name = "Scarlet Monastery", description = "Scarlet Monastery dominates the northeastern glades as a major Scarlet Crusade stronghold. Even from outside, the place carries the weight of zealotry and war." },
        { name = "The Bulwark", description = "The Bulwark guards the dangerous eastern passage toward the Plaguelands. I noted it as a frontier line where Tirisfal's gloom meets threats far worse beyond." },
        { name = "Whispering Shore", description = "The Whispering Shore lies along Tirisfal's cold northern coast, where murlocs and ruins break the grey waterline. The place feels distant from warmth of any kind." },
        { name = "North Coast", description = "The North Coast is a bleak shoreline of debris, fog, and murloc activity. I found the sound of the sea there less comforting than warning." },
        { name = "Undercity", description = "Undercity lies beneath the ruins of Lordaeron as the Forsaken capital. Its presence defines Tirisfal as a land ruled not by the dead mindlessly, but by the dead who remember." },
    },
}

-- =========================================================
-- TELDRASSIL
-- =========================================================

FieldJournal_ZoneDB["Teldrassil"] = {
    displayName = "Teldrassil",
    levelRange = "1 - 11",
    faction = "Alliance",

    subregions = {
        { name = "Aldrassil", description = "Aldrassil rises from Shadowglen as a living center of druidic instruction. From its boughs, young night elves begin to learn that Teldrassil is both a homeland and a world tree still struggling toward balance." },
        { name = "Ban'ethil Barrow Den", description = "Ban'ethil Barrow Den is a sacred underground refuge of sleeping druids that has been invaded by the Gnarlpine. Its chambers feel suspended between the waking forest and the Emerald Dream." },
        { name = "Ban'ethil Hollow", description = "Ban'ethil Hollow lies among the western forest routes where Gnarlpine activity grows more dangerous. The hollow feels like a threshold between traveled paths and the deeper trouble surrounding the barrow den." },
        { name = "The Cleft", description = "The Cleft is a broken, enclosed stretch of Teldrassil's wooded terrain. Its narrow ground and steep natural walls make it feel more secluded than the open paths around Dolanaar." },
        { name = "Dolanaar", description = "Dolanaar is the main settlement along Teldrassil's central road. Sentinels, craftsmen, druids, and travelers gather here before the forest paths divide toward ruins, moonwells, and more dangerous country." },
        { name = "Fel Rock", description = "Fel Rock is a cave north of Dolanaar where grell and darker creatures gather. The presence of Lord Melenas ties the cavern directly to the corruption troubling Teldrassil." },
        { name = "Gnarlpine Hold", description = "Gnarlpine Hold is the furbolgs' strongest foothold in southwestern Teldrassil. Their numbers, totems, and leaders make the place a center of organized hostility rather than another scattered woodland camp." },
        { name = "Lake Al'Ameth", description = "Lake Al'Ameth lies beside Denalan's grove and the timberlings of the surrounding woods. What first appears peaceful becomes an important place to study how deeply sickness has reached into the living land." },
        { name = "The Oracle Glade", description = "The Oracle Glade is a guarded northern grove threatened by Bloodfeather harpies. The Oracle Tree and nearby moonwell give the place spiritual weight beyond its value as a wilderness outpost." },
        { name = "Pools of Arlithrien", description = "The Pools of Arlithrien are a moonwell and sacred landmark on western Teldrassil. Their waters are part of the long effort to understand and tend the great tree." },
        { name = "Rut'theran Village", description = "Rut'theran Village rests beneath Darnassus at the edge of Teldrassil, linking the great tree to Darkshore and the wider world by dock and hippogryph route." },
        { name = "Shadowglen", description = "Shadowglen is the sheltered grove where many young night elves first step into the wider world. Its beauty hides early lessons about wildlife, corruption, and the responsibility of preserving balance." },
        { name = "Shadowthread Cave", description = "Shadowthread Cave is a web-choked hollow claimed by large spiders. The deeper passages are a reminder that Teldrassil's dangers include ordinary predators as well as corruption." },
        { name = "Starbreeze Village", description = "Starbreeze Village was once a quiet night elf settlement, but Gnarlpine furbolgs turned it into a warning. Empty structures and hostile movement make the village proof that Teldrassil's corruption is no distant concern." },
        { name = "The Veiled Sea", description = "The Veiled Sea surrounds Teldrassil and the routes beneath its great boughs. From the edge of the tree, the open water marks the boundary between a sheltered homeland and the wider coasts of Kalimdor." },
        { name = "Wellspring Lake", description = "Wellspring Lake sits in the far north among some of Teldrassil's most troubled wildlife. The water and surrounding woods are beautiful, but the creatures here make the tree's imbalance difficult to ignore." },
        { name = "Wellspring River", description = "Wellspring River winds through northern Teldrassil, carrying travelers past timberlings, spiders, and signs of a forest that is not entirely well." },
    },
}

-- =========================================================
-- ZEPHRAS ISLE
-- =========================================================

FieldJournal_ZoneDB["Zephras Isle"] = {
    displayName = "Zephras Isle",
    levelRange = "1 - 12",
    faction = "Contested",

    subregions = {
        { name = "Thendal Grove", description = "Thendal Grove shelters the first paths walked by young shen'dorei. Great trees, wildlife, windstones, and nearby elemental sites make the grove feel peaceful at first, though signs of Zephras' growing instability are never far away." },
        { name = "Thendal Village", description = "Thendal Village is the sheltered home at the heart of the grove, where new adventurers meet their trainers and elders before venturing farther across Zephras Isle." },
        { name = "Thendal Cave", description = "Thendal Cave lies south of the village and serves as a den for the increasingly aggressive ursera. Its cramped passages are one of the first places young adventurers are asked to face danger away from open ground." },
        { name = "Thendal Standing Stones", description = "The standing stones northeast of Thendal Village mark a place where elemental and arcane forces gather close to the surface. Both the Al'Aketh and the competing Skyborne orders have reasons to watch the site carefully." },
        { name = "Shen'dar Highlands", description = "The Shen'dar Highlands spread south of Thendal as rougher country filled with wildlife, travelers, bandits, and rival magical interests. The roads here mark the transition from a protected starting grove into the wider struggle for Zephras." },
        { name = "Shen'dar Village", description = "Shen'dar Village is an early crossroads for the people of Zephras, where High Order and Windshaper adherents live close enough to cooperate despite their growing disagreements." },
        { name = "Falaath Village", description = "Falaath Village is one of the shen'dorei settlements scattered across Zephras Isle. Its place beyond the earliest roads makes it part of the wider network of communities threatened by the island's instability." },
        { name = "Bandit Hideout", description = "The Bandit Hideout is a refuge for outlaws troubling the Shen'dar Highlands. Its presence makes the roads around the nearby villages less safe than the open sky might suggest." },
        { name = "Windsong Lake", description = "Windsong Lake is a broad body of water set among the uplands of Zephras. The quiet shoreline offers a striking contrast to the magical and political tensions building elsewhere on the island." },
        { name = "Windsong Standing Stones", description = "The Windsong Standing Stones form another old site of power on Zephras Isle. Places like this have become increasingly important as both elemental and arcane forces shift beneath the island." },
        { name = "Windfield Orchard", description = "Windfield Orchard is cultivated ground maintained by the shen'dorei. Its orderly rows are a reminder that Zephras is a home people must feed and maintain, not merely a magical refuge." },
        { name = "Gustberry Lowlands", description = "The Gustberry Lowlands lie below the higher paths of Zephras, where open ground and useful plants draw both travelers and wildlife." },
        { name = "Valanaar", description = "Valanaar is one of Zephras Isle's major settlements and a later hub for those who have proven themselves beyond Shen'dar. From here the island's larger crisis becomes harder to ignore." },
        { name = "Valanaar Skydocks", description = "The Valanaar Skydocks connect the settlement to the aerial travel that makes life in Skywall possible. Their platforms and vessels show how naturally the shen'dorei have adapted to a homeland suspended among the winds." },
        { name = "Fairweather Stables", description = "Fairweather Stables tend the mounts and beasts used by travelers crossing Zephras Isle. The site reflects the practical side of life in a realm where journeys still depend on trained animals as much as magic." },
        { name = "Overlook Standing Stones", description = "The Overlook Standing Stones occupy exposed high ground where the powers shaping Zephras can be studied and contested. The site has become one of several flashpoints between the High Order and Windshapers." },
        { name = "Shrine of Akir", description = "The Shrine of Akir is a major stronghold of the Al'Aketh cult. Its presence gives the cult a spiritual and military center from which to challenge the other shen'dorei across Zephras." },
        { name = "Rohashi Spires", description = "The Rohashi Spires rise from the broken heights of Zephras, where narrow paths and open air make the island's place within Skywall impossible to forget." },
        { name = "Sanctum of Storms", description = "The Sanctum of Storms is an elemental site tied closely to the old powers that shaped life on Zephras. As those powers grow uncertain, places such as the sanctum carry greater weight for the island's future." },
        { name = "Rise of Spirits", description = "The Rise of Spirits is sacred ground used by shaman seeking communion with the elements. The climb separates it from ordinary village life and gives the site the quiet of a place meant for ritual." },
        { name = "Shadowgale Forest", description = "Shadowgale Forest is a darker stretch of woodland where the sheltering character of Thendal gives way to more dangerous wild country." },
        { name = "Nightclaw Cavern", description = "Nightclaw Cavern cuts beneath the island's darker forested reaches. Its enclosed paths make it a natural refuge for creatures and factions that prefer to remain hidden." },
        { name = "Shriekling Den", description = "The Shriekling Den is a hostile hollow within the wilder parts of Zephras Isle. Its name carries well enough through the stone to warn travelers before they enter." },
        { name = "Ruins of Ban'aethal", description = "The Ruins of Ban'aethal preserve the remains of an older place on Zephras Isle. Broken stone among the winds gives the site the feeling of history interrupted rather than peacefully abandoned." },
        { name = "East Pylon Watchtower", description = "The East Pylon Watchtower overlooks one of the great systems that help sustain Zephras Isle. Its purpose has become more urgent as the island's ancient anchors show signs of instability." },
        { name = "West Pylon Watchtower", description = "The West Pylon Watchtower stands guard over the opposite reaches of Zephras' anchoring network. From its height, the vulnerability of an island held aloft by failing magic becomes difficult to dismiss." },
        { name = "Skywall", description = "Skywall is the elemental realm of air that has sheltered the shen'dorei for millennia. Zephras Isle floats within this endless domain, surrounded by winds that are both the people's greatest inheritance and their greatest uncertainty." },
    },
}

