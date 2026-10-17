local addonName, MCF = ...

local enUS = {
    ["Auto Attack"]="Auto Attack",
    ["Spell"]="Spell",
    ["Defeated mobs:"]="Defeated mobs:",
    ["Defeated mobs: "]="Defeated mobs: ",
    ["Most defeated mob:"]="Most defeated mob:",
    ["Most defeated mob: "]="Most defeated mob: ",
    ["Nemesis:"]="Nemesis:",
    ["Nemesis: "]="Nemesis: ",
    ["none"]="none",
    ["Screenshot shortcut"]="Screenshot shortcut",
    ["Shortcut"]="Shortcut",
    ["Not assigned"]="Not assigned",
    ["Press a key..."]="Press a key...",
    ["unknown"]="unknown",

    ["Damage records:"]="Damage records:",
    ["White"]="White",
    ["Yellow"]="Yellow",
    ["Max white damage:"]="Max white damage:",
    ["Max yellow damage:"]="Max yellow damage:",
    ["Damage dealt:"]="Damage dealt:",
    ["Automatic attacks:"]="Automatic attacks:",
    ["Ability damage:"]="Ability damage:",
    ["Top damage source:"]="Top damage source:",

    ["Month/Year"]="Month/Year",
    ["screenshots"]="screenshots",

    ["3D"]="3D",

    ["Search screenshot comments"]="Search screenshot comments",
    ["LEVEL HISTORY"]="LEVEL HISTORY",
    ["Level history description"]="The current level is shown live. Completed entries describe the journey from the previous level to the displayed level-up.",
    ["in progress"]="in progress",
    ["Current level statistics"]="Live statistics for this level",
    ["Time on current level:"]="Time on current level:",
    ["COMPLETED LEVEL SECTIONS"]="COMPLETED LEVEL SECTIONS",
    ["reached"]="reached",

    ["Gold history info"]="Your character's daily gold development is recorded here. Use the time range and scale controls to inspect shorter periods or the complete history.",
    ["Dungeon web hint"]="|cffffd100Tip:|r On the website (www.mycharforever.com) dungeons, bosses and loot are shown more clearly, with filters.", ["Gold web hint"]="|cffffd100Tip:|r On the website (www.mycharforever.com) income and expenses by category are shown much better.",
    ["Longest in quest log:"]="Longest in quest log:", ["still in the log"]="still in the log",
    ["Dungeon history info"]="Dungeon visits are recorded here with status, duration, party, bosses, loot and deaths where available. Use the filters to narrow the list.",

    ["Reputation"]="Reputation",
    ["REPUTATION PROGRESS"]="REPUTATION PROGRESS",
    ["Reputation milestone description"]="Only reputation milestones are recorded here. A faction appears when first detected; afterwards only standing changes such as Friendly, Honored, Revered or Exalted are stored. Individual reputation gains are not recorded.",
    ["No reputation recorded yet."]="No reputation recorded yet.",
    ["Hated"]="Hated",
    ["Hostile"]="Hostile",
    ["Unfriendly"]="Unfriendly",
    ["Neutral"]="Neutral",
    ["Friendly"]="Friendly",
    ["Honored"]="Honored",
    ["Revered"]="Revered",
    ["Exalted"]="Exalted",
    ["First recorded"]="First recorded",
    ["Profession skill at level-up:"]="Profession skill at level-up:",

    ["Language"]="Language",
    ["Automatic (client language)"]="Automatic (client language)",
    ["German"]="German",
    ["English"]="English",
    ["Take chronicle screenshot"]="Take chronicle screenshot",

    ["January"]="January",
    ["February"]="February",
    ["March"]="March",
    ["April"]="April",
    ["May"]="May",
    ["June"]="June",
    ["July"]="July",
    ["August"]="August",
    ["September"]="September",
    ["October"]="October",
    ["November"]="November",
    ["December"]="December",
    ["Mon"]="Mon",
    ["Tue"]="Tue",
    ["Wed"]="Wed",
    ["Thu"]="Thu",
    ["Fri"]="Fri",
    ["Sat"]="Sat",
    ["Sun"]="Sun",
    ["journal entries"]="journal entries",
    ["Entries on"]="Entries on",
    ["Select a day with journal entries."]="Select a day with journal entries.",

    ["Filename"]="Filename",
    ["Type"]="Type",
    ["Level-Up"]="Level-Up",
    ["Manual"]="Snapshot",
    ["PvP"]="PvP", ["PvP kill"]="Player kill", ["PvP death"]="Killed by a player", ["Level %d"]="Level %d",
    ["Item from %s (%s)"]="Item from %s (%s)", ["Item from %s"]="Item from %s", ["Dungeon loot: %s"]="Dungeon loot: %s",
    ["Quest reward: %s"]="Quest reward: %s", ["Reward for the quest \"%s\""]="Reward for the quest \"%s\"",
    ["Automatic"]="Automatic",
    ["Death"]="Death",
    ["Login"]="Login",
    ["Export filenames only"]="Export filenames only",
    ["Export filenames hint"]="The button shows the filenames as text to copy with Ctrl+C.",
    ["Filename unavailable"]="Filename unavailable",

    ["Journal manual only hint"]="The journal is filled manually. Create entries here, on the world map, or optionally from a manual screenshot.",
    ["New journal entry"]="New entry",
    ["Also create journal entry"]="Also save as journal entry",
    ["Screenshot journal title"]="Chronicle screenshot",

    ["No screenshot filenames recorded."]="No screenshot filenames recorded.",

    ["Screenshots on this level:"]="Screenshots on this level:",
    ["Journal entries on this level:"]="Journal entries on this level:",
    ["Show screenshot files"]="Show screenshot names",
    ["Back to list"]="Back to list",
    ["Filenames selected - press Ctrl+C now."]="Filenames selected - press Ctrl+C now.",
    ["Copied - paste it with Ctrl+V."]="Copied - paste it with Ctrl+V.",
    ["Screenshot files on level"]="Screenshot files on level",
    ["Select filenames and press Ctrl+C."]="Select filenames and press Ctrl+C.",

    ["Gold balance:"]="Gold balance:",
    ["Duels:"]="Duels:",
    ["Wins"]="Wins",
    ["Losses"]="Losses",
    ["Screenshots on level:"]="Screenshots on level:",
    ["Journal entries on level:"]="Journal entries on level:",
    ["New zones discovered:"]="New zones discovered:",
    ["Profession milestones:"]="Profession milestones:",

    ["Reached on: "]="Reached on: ",
    ["Gold earned:"]="Gold earned:",
    ["Looted gold:"]="Looted gold:",
    ["Looted gold total:"]="Looted gold total:", ["recorded since level %d"]="recorded since level %d",
    ["Gold spent:"]="Gold spent:",

    ["ACCOUNT SUMMARY"]="ACCOUNT SUMMARY",
    ["Tracked characters"]="Tracked characters",
    ["Combined /played"]="Combined /played",
    ["Active play time"]="Active play time",
    ["AFK time"]="AFK time",
    ["Deaths"]="Deaths",
    ["Quests"]="Quests",
    ["Dungeon visits"]="Dungeon visits",
    ["Dungeon completions"]="Dungeon completions",
    ["Boss kills"]="Boss kills",
    ["Unique zones"]="Unique zones",
    ["Combined gold"]="Combined gold",
    ["Ground distance"]="Ground distance",
    ["Flight distance"]="Flight distance",
    ["Flight time"]="Flight time",
    ["Sessions"]="Sessions",
    ["Screenshots"]="Screenshots",
    ["Journal entries"]="Journal entries",
    ["RECORDS"]="RECORDS",
    ["Most playtime"]="Most playtime",
    ["Highest character"]="Highest character",
    ["Most quests"]="Most quests",
    ["Most deaths"]="Most deaths",
    ["Richest character"]="Richest character",
    ["Farthest traveler"]="Farthest traveler",
    ["Total /played"]="Total /played",
    ["Gold"]="Gold",
    ["Last seen"]="Last seen",

    ["Characters"]="Characters",
    ["Characters tab description"]="Account-wide summary and records for all characters tracked by MyCharForever.",
    ["CHARACTERS"]="CHARACTERS",
    ["Tracked characters: "]="Tracked characters: ",
    ["Combined /played: "]="Combined /played: ",
    ["Combined deaths: "]="Deaths: ",
    ["Combined quests: "]="Quests: ",
    ["Combined dungeons: "]="Dungeons: ",
    ["No account characters recorded yet."]="No account characters recorded yet.",
    ["Quests: "]="Quests: ",
    ["Gold: "]="Gold: ",
    ["Last seen: "]="Last seen: ",

    ["GUILD"]="GUILD",
    ["Current guild: "]="Current guild: ",
    ["Guild rank: "]="Guild rank: ",
    ["Guild member since: "]="Member since: ",
    ["Guild first recorded: "]="First recorded: ",
    ["No guild membership recorded."]="No guild membership recorded.",
    ["Guild history:"]="Guild history:",
    ["Date / time"]="Date / time",
    ["Event"]="Event",
    ["Guild"]="Guild",
    ["Lvl"]="Lvl",
    ["Joined guild"]="Joined",
    ["Left guild"]="Left",
    ["Guild rank changed"]="Rank changed",
    ["Guild first recorded"]="First recorded",

    ["Apprentice"]="Apprentice",
    ["Journeyman"]="Journeyman",
    ["Expert"]="Expert",
    ["Artisan"]="Artisan",

    ["Professions"]="Professions",
    ["MyCharForever screenshot"]="MyCharForever screenshot",
    ["Show screenshot filenames"]="Show screenshot filenames",
    ["Achievements tab"]="Achievements",
    ["Nav group chronicle"]="Chronicle", ["Nav group progress"]="Progress", ["Nav group adventure"]="Adventure", ["Nav group characters"]="Characters",
    ["PROFESSION PROGRESS"]="PROFESSION PROGRESS",
    ["No crafted items recorded yet."]="No crafted items recorded yet.",
    ["Crafted quantity"]="Crafted quantity",
    ["Crafted items"]="Crafted items",
    ["Profession progress description"]="Milestones in your character's profession development.",
    ["No professions recorded yet."]="No professions recorded yet.",
    ["Skill cap"]="Skill cap",
    ["First recorded"]="First recorded",
    ["skill reached"]="skill reached",
    ["Profession history"]="Profession history",
    ["learned"]="learned",
    ["unlearned"]="unlearned",
    ["Kind mining"]="Mining", ["Kind herbalism"]="Herbalism", ["Kind skinning"]="Skinning", ["Kind fishing"]="Fishing",
    ["Kind disenchant"]="Disenchanting", ["Kind prospecting"]="Prospecting", ["Kind milling"]="Milling",
    ["Gathered resources"]="Gathered resources", ["Disenchanting and similar"]="Disenchanting, prospecting and milling",
    ["Destroyed items"]="Destroyed items", ["Nothing recorded yet."]="Nothing recorded yet.",
    ["Skill per level"]="Skill per level", ["No profession skill recorded yet."]="No profession skill recorded yet. Learn a profession and its skill will be listed here per level.", ["Special recipes"]="Special recipes (drops, quests, vendors)",
    ["No special recipes recorded yet."]="No special recipes recorded yet.", ["Vendor"]="Vendor", ["Found or rewarded"]="Found or rewarded",
    ["relearned"]="learned again",
    ["skill cap increased"]="skill cap increased",
    ["first recorded"]="first recorded",

    ["Equipment"]="EQUIPMENT",

    ["Level details"]="Level details",
    ["Details"]="Details",
    ["Activity:"]="Activity:",
    ["Quests"]="quests",
    ["Deaths"]="deaths",
    ["Dungeons"]="dungeons",

    ["Dungeons on level"]="Dungeons on level",
    ["Show dungeon list"]="Dungeon list",
    ["No dungeon runs recorded on this level."]="No dungeon runs recorded on this level.",

    ["PARTY"]="PARTY",
    ["BOSSES"]="BOSSES",
    ["LOOT"]="LOOT",
    ["Party roster was not recorded for this run."]="Party roster was not recorded for this run.",
    ["All required bosses defeated"]="All required bosses defeated",
    ["All required bosses defeated (recognized retroactively)"]="All required bosses defeated (recognized retroactively)",

    ["Search journal"]="Search journal",
    ["Clear"]="Clear",
    ["No journal entries match your search."]="No journal entries match your search.",

    ["Tip First tracked"]="When MyCharForever first began recording this character.",
    ["Tip Total played"]="Total character playtime reported by WoW via /played.",
    ["Tip AFK"]="Time recorded while WoW marked the character as AFK.",
    ["Tip Stationary"]="Time the character did not move from the spot (standing, crafting, fishing, AFK ...). AFK time is included, because an AFK character does not move either. Recorded since version 0.16.0.",
    ["Tip Longest stationary"]="Longest uninterrupted stretch without moving. A single step does not end it; two seconds of movement in a row do.",
    ["Tip Active play"]="Total /played minus recorded AFK time.",
    ["Tip Current session"]="Time since the current login/session began.",
    ["Tip Time level"]="Tracked active session time spent on the current level.",
    ["Tip Sessions"]="Number of login sessions recorded by MyCharForever.",
    ["Tip Average session"]="Average duration of the recorded sessions.",
    ["Tip Journey points"]="Raw position samples stored internally for reconstructing the travel path.",
    ["Tip Maps movement"]="Number of maps on which journey movement has been recorded.",
    ["Tip Zone changes"]="Number of recorded zone-change events.",
    ["Tip Map path"]="Whether the recorded journey path is currently shown on the world map.",
    ["Tip Timeline"]="Number of chronological events such as logins, quests, deaths and level-ups.",
    ["Tip Journal entries"]="Number of personal journal entries stored for this character.",
    ["Screenshot display hint"]="World of Warcraft does not allow addons to display images or screenshots. The addon therefore only stores the file name, place, time and your comment. The pictures themselves are in your WoW screenshots folder and, as a photo book, on the website (/mcf website).",
    ["Screenshot display hint short"]="Only the entry is shown here. WoW does not allow addons to display the picture itself. It is in your WoW screenshots folder and appears as a photo book on the website.",
    ["Tip Screenshot records"]="Number of screenshot references recorded by the addon; image files themselves remain in WoW's screenshot folder.",
    ["Tip Level snapshots"]="Number of equipment/stat snapshots captured at level milestones.",
    ["Tip Journey tracking"]="Shows whether continuous journey-path recording is enabled.",
    ["Tip Level screenshots"]="Shows whether automatic screenshots at level-up are enabled.",
    ["Tip Database version"]="Internal MyCharForever data-format version.",
    ["Tip Addon version"]="Currently loaded MyCharForever addon version.",
    ["Tip Levelups"]="Number of level-ups observed since tracking began.",
    ["Tip Completed levels"]="Levels for which a complete start-to-finish duration was recorded.",
    ["Tip Average level"]="Average duration of all completely recorded levels.",
    ["Tip Longest level"]="The completely recorded level that took the most time.",
    ["Tip Deaths"]="Total deaths recorded by MyCharForever.",
    ["Tip Duels"]="Recorded duel total, wins and losses.",
    ["Tip Ground distance"]="Estimated distance travelled on the ground from recorded movement samples.",
    ["Tip Flight routes"]="Number of recorded taxi/flight-master routes.",
    ["Tip Flight distance"]="Estimated distance travelled on recorded taxi routes.",
    ["Tip Flight time"]="Total recorded time spent on taxi routes.",
    ["Tip Dungeon visits"]="Number of recorded dungeon entries.",
    ["Tip Dungeon completions"]="Dungeon runs for which MyCharForever detected a completion signal.",
    ["Tip Death rate"]="Recorded deaths divided by total /played hours.",
    ["Tip Money"]="Current money carried by this character.",
    ["Tip Current zone"]="The zone the character is currently in.",
    ["Tip Current subzone"]="The current subzone reported by WoW.",
    ["Tip World time"]="Tracked time spent in the open world.",
    ["Tip Resting time"]="Tracked time spent in resting areas such as inns and cities.",
    ["Tip Dungeon time"]="Tracked time spent inside dungeon instances.",
    ["Tip Raid time"]="Tracked time spent inside raid instances.",
    ["Tip PvP time"]="Tracked time spent inside PvP instances.",

    ["Expert export"]="Expert export", ["Expert export help"]="Choose broad data groups. Journey is simplified by default; enable raw points only when needed.", ["Character and levels"]="Character and levels", ["Adventure and statistics"]="Adventure and statistics", ["Timeline and sessions"]="Timeline and sessions", ["Journal"]="Journal", ["Screenshot references"]="Screenshot references", ["Journey"]="Journey", ["Raw journey points"]="Raw journey points", ["Addon settings"]="Addon settings", ["Create export"]="Create export",

    ["Export packed help"]="Packed chronicle (%.0f KB readable, %.0f KB packed). Click Select all, then Ctrl+C. On the website, paste the whole text into the text box in option B) (\"Paste export here\") and click \"Load\".", ["Packing export"]="Packing export ... %d%%", ["Packing failed"]="Packing failed - the readable text is shown instead.", ["Pack"]="Pack", ["Show readable"]="Show readable",
    ["Preparing export"]="Preparing export ...", ["Export failed"]="Export failed",

    ["Screenshot intro"]="WoW does not let addons show pictures. The screenshots themselves are in your WoW screenshots folder and, as a photo book with level and place, on the website (/mcf website). The export contains all recorded screenshots.",
    ["Manual screenshot info"]="Screenshots you took yourself: with the MyCharForever shortcut or the game's own screenshot key.",
    ["Automatic screenshot info"]="Screenshots the addon took by itself. Use the filter to show only one type.",
    ["Shot tab manual"]="Manual screenshots", ["Shot tab automatic"]="Automatic screenshots", ["Search screenshots"]="Search screenshots (comment, place, file name, type)", ["No screenshots found."]="No screenshots found.",
    ["Shot type"]="Type:", ["Shot all types"]="All types", ["Shot interval"]="Interval", ["Shot equipment"]="Equipment", ["Shot guild"]="Guild", ["Shot other"]="Other", ["Shot dungeon"]="Dungeon completion", ["Shot achievement"]="Achievement", ["At achievement"]="When an addon achievement is unlocked",
    ["Export screenshots"]="Export all screenshots", ["Date"]="Date", ["Start"]="Start", ["End"]="End", ["Low"]="Low", ["High"]="High", ["Change"]="Change",

    ["Screenshots"]="Screenshots", ["No screenshots recorded yet."]="No screenshots recorded yet.",
    ["No comment"]="No comment", ["Export one"]="Export",
    ["Duels: "]="Duels: ", ["Wins"]="Wins", ["Losses"]="Losses",
    ["Ground distance: "]="Ground distance: ", ["Flight routes: "]="Flight routes: ",
    ["Flight distance: "]="Flight distance: ", ["Flight time: "]="Flight time: ",

    ["Export"]="Export", ["Export chronicle"]="Export chronicle",
    ["Select all"]="Select all", ["Open website"]="Open website", ["External link"]="External link", ["External link help"]="This leads to an external website (www.mycharforever.com), where you can paste your export into the chronicle viewer. WoW cannot open web pages itself: copy the address below with Ctrl+C and paste it into your browser. Nothing is sent from the game.",
    ["Map filter"]="Filter", ["Current level"]="Current", ["Last 5 levels"]="Last 5",
    ["Death cause"]="Cause", ["Death killer"]="Killed by", ["Death cause unknown"]="unknown", ["Death no screenshot"]="none",
    ["Cause drowned"]="Drowned", ["Cause fatigue"]="Exhaustion", ["Cause fall"]="Fall damage", ["Cause guard"]="Killed by a guard", ["Cause pvp"]="Killed by a player",
    ["Export all screenshots title"]="Export all recorded screenshots", ["Export screenshot title"]="Export screenshot",
    ["Export all screenshots help"]="Data export for external programs of all recorded screenshots: your own MyCharForever screenshots (with comment) and the normal game screenshots. It does not show any images, only file name, place, time and comment. Click %s, then Ctrl+C to copy it.",
    ["Export screenshot help"]="Data export of this screenshot for external programs. It does not show the image, only file name, place, time and comment. Click %s, then Ctrl+C to copy it.",
    ["Export help"]="Complete machine-readable chronicle. Click Select all, then Ctrl+C. Screenshot image files are referenced by filename and are not embedded in the text.",

    ["Chronicle screenshot"]="Chronicle screenshot", ["Chronicle screenshots"]="Chronicle screenshots",
    ["Save comment"]="Save comment", ["Without comment"]="Without comment",
    ["Screenshot recording disabled"]="Screenshot recording is disabled in the settings",

    ["Screenshot"]="Screenshot",
    ["Active travel time"]="Active travel time",
    ["This session only"]="This session only",
    ["AFK time:"]="AFK time:", ["Stationary time:"]="Stationary time:", ["Stationary time: "]="Stationary time: ", ["Longest stationary stretch: "]="Longest stationary stretch: ", ["Active time:"]="Active time:", ["Average item level:"]="Average item level:", ["Itemlevel:"]="iLvl",
    ["Active play time:"]="Active play time:", ["not recorded"]="not recorded",

    ["Journey recording"]="Journey recording", ["Record journey path"]="Record journey path",
    ["Recording interval"]="Recording interval:", ["seconds short"]="sec",
    ["Journey interval tooltip"]="Determines how often your position is sampled for the journey path. Shorter intervals create a more accurate and continuous-looking path on the map, but store more data. Longer intervals can make the path appear coarser.",
    ["Database"]="DATABASE", ["Estimated SavedVariables size"]="Estimated SavedVariables size",
    ["Journey points short"]="Journey points", ["Events short"]="Events", ["Dungeon runs short"]="Dungeon runs", ["Screenshots short"]="Screenshots",

    ["7D"]="7D", ["30D"]="30D", ["90D"]="90D", ["1Y"]="1Y", ["ALL"]="ALL",
    ["Settings"]="Settings", ["End: "]="End: ", ["Gold: "]="Gold: ",
    ["No gold history recorded yet."]="No gold history recorded yet.",
    ["Milestone fallback"]="Milestone",
    ["Click to open"]="Click to open", ["Drag to move"]="Drag to move",
    ["Chronicle settings"]="Chronicle and screenshot settings",
    ["Show minimap button"]="Show minimap button", ["Screenshots"]="Screenshots",
    ["Enable automatic screenshots"]="Enable automatic screenshots",
    ["At level up"]="At level up", ["At login"]="At login", ["At death"]="At death",
    ["At dungeon completion"]="At dungeon completion",
    ["When equipping quality item"]="Screenshot the first time each quality is equipped in each slot (minimum quality applies)",
    ["Equipment milestone"]="Equipment milestone",
    ["First quality in slot"]="First %s item equipped in slot: %s",
    ["Equipment slot"]="Slot",
    ["Periodic screenshots"]="Take screenshots periodically",
    ["Interval minutes"]="Interval (minutes):", ["Minimum item quality"]="Minimum item quality:",
    ["Uncommon"]="Uncommon", ["Rare"]="Rare", ["Epic"]="Epic", ["Legendary"]="Legendary",

    ["Journey time marker"]="Journey time marker", ["Recorded travel time"]="Recorded travel time",
    ["5 minute markers"]="5 minute markers", ["Level range"]="Level range:",
    ["Apply"]="Apply", ["All levels"]="All levels",
    ["Quest ID"]="Quest ID", ["Quest"]="Quest", ["XP"]="XP", ["Zone"]="Zone",
    ["Copy quest list"]="Copy quest list",
    ["Copy quest list hint"]="Click, then Ctrl+C to copy the complete list.",

    ["Show quest list"]="Show quest list",
    ["Quests on level"]="Quests on level",
    ["Quest list copy hint"]="Selectable text - Ctrl+A / Ctrl+C copies the list.",
    ["Quest list header"]="ID      Quest                                      XP  Zone",
    ["Quest list total"]="%d quests | %d quest XP",
    ["Quest XP:"]="Quest XP:", ["Other XP:"]="Other XP:", ["Required XP:"]="Required XP:",
    ["XP ratio:"]="XP ratio:", ["available for newly tracked levels"]="available for newly tracked levels",

    ["Show quests"]="Show quests", ["Hide quests"]="Hide quests",
    ["Show dungeon runs"]="Show dungeon runs", ["Hide dungeon runs"]="Hide dungeon runs",
    ["Show boss kills"]="Show boss kills", ["Hide boss kills"]="Hide boss kills",
    ["Show deaths"]="Show deaths", ["Hide deaths"]="Hide deaths",
    ["Show zones"]="Show zones", ["Hide zones"]="Hide zones",

    ["Quests completed:"]="Quests completed:", ["Dungeon runs:"]="Dungeon runs:", ["Dungeon completions:"]="Dungeon completions:",
    ["Boss kills:"]="Boss kills:", ["Sessions:"]="Sessions:", ["Zones visited:"]="Zones visited:",
    ["Show details"]="Show details", ["Hide details"]="Hide details",

    ["Time on Level "]="Time on Level ",
    ["Snapshot:"]="Snapshot:", ["Equipment slots:"]="Equipment slots:", ["Money:"]="Money:", ["Screenshot:"]="Screenshot:",
    ["Screenshot file: "]="Screenshot file: ",
    ["EXPLORATION"]="EXPLORATION", ["ARCHIVE / DATA"]="ARCHIVE / DATA", ["MOST TIME SPENT"]="MOST TIME SPENT",
    ["Map path: "]="Map path: ",

    ["CHARACTER"]="CHARACTER", ["PLAYTIME"]="PLAYTIME", ["LEVELING"]="LEVELING", ["JOURNEY"]="JOURNEY", ["ADVENTURE"]="ADVENTURE",
    ["LOCATION TIMES"]="LOCATION TIMES", ["GOLD"]="GOLD", ["DAILY HISTORY"]="DAILY HISTORY",
    ["No completed levels yet."]="No completed levels yet.", ["Deaths / played hour: "]="Deaths / played hour: ",
    ["Current balance: "]="Current balance: ", ["Today's change:"]="Today's change:", ["Today's change: "]="Today's change: ",
    ["Start: "]="Start: ", ["Low: "]="Low: ", ["High: "]="High: ", ["Change: "]="Change: ",

    ["Overview"]="Overview", ["Level-Ups"]="Level-Ups", ["Journal"]="Journal", ["Gold"]="Gold", ["Dungeons"]="Dungeons",
    ["Edit"]="Edit", ["Delete"]="Delete", ["Save"]="Save", ["Cancel"]="Cancel", ["Show"]="Show",
    ["Scale:"]="Scale:", ["Edit Milestones"]="Edit Milestones", ["AUTO"]="AUTO", ["Milestone"]="Milestone",
    ["MyCharForever - Gold Milestones"]="MyCharForever - Gold Milestones",
    ["Configure your own gold goals. Prices are intentionally not predefined."]="Configure your own gold goals. Prices are intentionally not predefined.",
    ["DAILY GOLD BALANCE"]="DAILY GOLD BALANCE", ["Level"]="Level", ["Start"]="Start", ["Low"]="Low", ["High"]="High", ["Change"]="Change",
    ["LEVEL-UP HISTORY"]="LEVEL-UP HISTORY", ["A chronological record of this character's milestones."]="A chronological record of this character's milestones.",
    ["No recorded level-ups yet."]="No recorded level-ups yet.", ["Reached: "]="Reached: ", ["Location: "]="Location: ",
    ["Time for Level "]="Time for Level ", ["Snapshot: YES  |  Equipment slots: "]="Snapshot: YES  |  Equipment slots: ",
    ["Snapshot: no"]="Snapshot: no", ["Screenshot record: "]="Screenshot record: ", ["YES"]="YES", ["no"]="no",
    ["ARCHIVE"]="ARCHIVE", ["Recorded level-ups: "]="Recorded level-ups: ", ["Level snapshots: "]="Level snapshots: ",
    ["Screenshot records: "]="Screenshot records: ", ["JOURNAL"]="JOURNAL", ["Personal notes from this character's journey."]="Personal notes from this character's journey.",
    ["No journal entries yet."]="No journal entries yet.", ["No journal entries yet. Create one from the world map."]="No journal entries yet. Create one from the world map.",
    ["Create one with '+ Journal Entry' on the world map."]="Create one with '+ Journal Entry' on the world map.", ["Journal Entry "]="Journal Entry ",
    ["Current balance:"]="Current balance:", ["Today's change: "]="Today's change: ", ["Gold history starts with this addon version."]="Gold history starts with this addon version.",
    ["Delete selected dungeon run(s) permanently?"]="Delete selected dungeon run(s) permanently?",
    ["MyCharForever - Dungeon Run"]="MyCharForever - Dungeon Run", ["Delete Run"]="Delete Run", ["Unknown Dungeon"]="Unknown Dungeon",
    ["Status: "]="Status: ", ["COMPLETED"]="COMPLETED", ["CLEARED"]="FULLY CLEARED", ["CLEARED SHORT"]="CLEARED", ["Fully cleared"]="Fully cleared", ["Dungeon fully cleared - "]="Dungeon fully cleared - ", ["VISITED"]="VISITED", ["IN PROGRESS"]="IN PROGRESS",
    ["Entered: "]="Entered: ", ["Left: "]="Left: ", ["Duration: "]="Duration: ", ["Deaths: "]="Deaths: ",
    ["Gold at start: "]="Gold at start: ", ["Gold at end: "]="Gold at end: ", ["Gold change: "]="Gold change: ",
    ["Exit: "]="Exit: ", ["Completed: "]="Completed: ", ["Completion signal: "]="Completion signal: ",
    ["BOSSES"]="BOSSES", ["No boss encounters recorded for this run."]="No boss encounters recorded for this run.",
    ["LOOT"]="LOOT", ["MY LOOT"]="MY LOOT", ["GROUP LOOT"]="GROUP LOOT", ["No personal dungeon loot recorded for this run."]="No personal dungeon loot recorded for this run.", ["No other dungeon loot recorded for this run."]="No other dungeon loot recorded for this run.", ["No dungeon loot recorded for this run."]="No dungeon loot recorded for this run.", ["Unknown source"]="Unknown source", ["Item "]="Item ",
    ["All Dungeons"]="All Dungeons", ["All"]="All", ["Completed"]="Completed", ["Visited"]="Visited", ["In Progress"]="In Progress",
    ["DUNGEON HISTORY"]="DUNGEON HISTORY", ["Dungeon:"]="Dungeon:", ["Status:"]="Status:", ["Delete selected"]="Delete selected",
    ["Showing "]="Showing ", [" of "]=" of ", [" runs   |   Completions: "]=" runs   |   Completions: ",
    ["No dungeon runs match the current filters."]="No dungeon runs match the current filters.",
    ["First tracked: "]="First tracked: ", ["Total /played: "]="Total /played: ", ["Current session: "]="Current session: ",
    ["Time this level: "]="Time this level: ", ["Tracked sessions: "]="Tracked sessions: ", ["Average session: "]="Average session: ",
    ["Level-ups tracked: "]="Level-ups tracked: ", ["Completed level records: "]="Completed level records: ",
    ["Average time / completed level: "]="Average time / completed level: ", ["Longest tracked level: "]="Longest tracked level: ",
    ["Journey points: "]="Journey points: ", ["Maps with recorded movement: "]="Maps with recorded movement: ", ["Zone changes: "]="Zone changes: ",
    ["Timeline events: "]="Timeline events: ", ["Journal entries: "]="Journal entries: ", ["Map path: "]="Map path: ", ["shown"]="shown", ["hidden"]="hidden",
    ["Dungeon visits: "]="Dungeon visits: ", ["Dungeon completions detected: "]="Dungeon completions detected: ", ["Current money: "]="Current money: ",
    ["Current zone: "]="Current zone: ", ["Current subzone: "]="Current subzone: ", ["World: "]="World: ", ["Resting areas: "]="Resting areas: ",
    ["Dungeons: "]="Dungeons: ", ["Raids: "]="Raids: ", ["PvP instances: "]="PvP instances: ", ["Journey tracking: "]="Journey tracking: ",
    ["Level-up screenshots: "]="Level-up screenshots: ", ["Database version: "]="Database version: ", ["Addon version: "]="Addon version: ",
    ["ON"]="ON", ["OFF"]="OFF",
    ["Death"]="Death", [" reached"]=" reached", ["Login / session start"]="Login / session start", ["Journal entry"]="Journal entry", ["Journey point"]="Journey point",
    ["Date"]="Date", ["Time"]="Time", ["Position"]="Position", ["Delete this journal entry permanently?"]="Delete this journal entry permanently?",
    ["Title"]="Title", ["Entry"]="Entry", ["MyCharForever - Edit journal entry"]="MyCharForever - Edit journal entry",
    ["MyCharForever - New journal entry"]="MyCharForever - New journal entry", ["Map display"]="Map display", ["Journey Path"]="Journey Path",
    ["Iconic moments"]="Iconic moments", ["Deaths"]="Deaths", ["World Drops"]="World Drops", ["Notable drop"]="Notable drop", ["Found at %s"]="Found at %s", ["Found at %s in %s"]="Found at %s in %s", ["Found in %s"]="Found in %s", ["Notable drop: %s"]="Notable drop: %s", ["Test drop source"]="Test source", ["Test drop added. Remove with /mcf droptest clear"]="Test drop added. Remove with /mcf droptest clear", ["Test drops removed: "]="Test drops removed: ", ["Journal Entries"]="Journal Entries", ["+ New Journal Entry"]="+ New Journal Entry",
    ["Journal entry deleted."]="Journal entry deleted.", ["Journal entry updated."]="Journal entry updated.", ["Journal entry saved."]="Journal entry saved.",
    ["Current map position unavailable."]="Current map position unavailable.", ["MapCanvas API unavailable."]="MapCanvas API unavailable.",
    ["Dungeon entered - "]="Dungeon entered - ", ["Dungeon continued - "]="Dungeon continued - ", ["Dungeon completion detected - "]="Dungeon completion detected - ",
    [" simulated gold days created."]=" simulated gold days created.", ["Simulated gold days removed."]="Simulated gold days removed.",
    ["Manual snapshot saved for level "]="Manual snapshot saved for level ", ["Manual snapshot failed: "]="Manual snapshot failed: ",
    ["Level snapshot failed, but level tracking continues."]="Level snapshot failed, but level tracking continues.", [" reached!"]=" reached!",
    [" loaded."]=" loaded."
}

local deDE = {
    ["Auto Attack"]="Automatischer Angriff",
    ["Spell"]="Zauber",
    ["Defeated mobs:"]="Besiegte Gegner:",
    ["Defeated mobs: "]="Besiegte Gegner: ",
    ["Most defeated mob:"]="Meistbesiegter Gegner:",
    ["Most defeated mob: "]="Meistbesiegter Gegner: ",
    ["Nemesis:"]="Angstgegner:",
    ["Nemesis: "]="Angstgegner: ",
    ["none"]="keiner",
    ["Screenshot shortcut"]="Screenshot-Shortcut",
    ["Shortcut"]="Shortcut",
    ["Not assigned"]="Nicht belegt",
    ["Press a key..."]="Taste drücken...",
    ["unknown"]="unbekannt",

    ["Damage records:"]="Schadensrekorde:",
    ["White"]="Weiß",
    ["Yellow"]="Gelb",
    ["Max white damage:"]="Max. weißer Schaden:",
    ["Max yellow damage:"]="Max. gelber Schaden:",
    ["Damage dealt:"]="Schaden verursacht:",
    ["Automatic attacks:"]="Automatische Angriffe:",
    ["Ability damage:"]="Fähigkeitenschaden:",
    ["Top damage source:"]="Stärkste Schadensquelle:",

    ["Month/Year"]="Monat/Jahr",
    ["screenshots"]="Screenshots",

    ["3D"]="3T",

    ["Search screenshot comments"]="Screenshot-Kommentare durchsuchen",
    ["LEVEL HISTORY"]="LEVEL-CHRONIK",
    ["Level history description"]="Das aktuelle Level wird live angezeigt. Abgeschlossene Einträge beschreiben jeweils den Weg vom vorherigen Level bis zum angezeigten Level-Up.",
    ["in progress"]="läuft",
    ["Current level statistics"]="Live-Statistik für dieses Level",
    ["Time on current level:"]="Zeit auf aktuellem Level:",
    ["COMPLETED LEVEL SECTIONS"]="ABGESCHLOSSENE LEVELABSCHNITTE",
    ["reached"]="erreicht",

    ["Gold history info"]="Hier wird die tägliche Goldentwicklung deines Charakters aufgezeichnet. Über Zeitraum und Skalierung kannst du einzelne Abschnitte oder den gesamten Verlauf betrachten.",
    ["Dungeon web hint"]="|cffffd100Tipp:|r Auf der Webseite (www.mycharforever.com) siehst du Dungeons, Bosse und Beute übersichtlicher, mit Filtern.", ["Gold web hint"]="|cffffd100Tipp:|r Auf der Webseite (www.mycharforever.com) siehst du Einnahmen, Ausgaben und ihre Kategorien deutlich besser dargestellt.",
    ["Longest in quest log:"]="Längste Quest im Questlog:", ["still in the log"]="noch im Questlog",
    ["Dungeon history info"]="Hier werden Dungeonbesuche mit Status, Dauer, Gruppe, Bossen, Beute und Todesfällen erfasst, soweit verfügbar. Über die Filter kannst du die Liste eingrenzen.",

    ["Reputation"]="Ruf",
    ["REPUTATION PROGRESS"]="RUF-ENTWICKLUNG",
    ["Reputation milestone description"]="Hier werden nur Ruf-Meilensteine aufgezeichnet. Eine Fraktion erscheint, sobald sie erstmals erfasst wird; danach werden nur Änderungen der Rufstufe wie Freundlich, Wohlwollend, Respektvoll oder Ehrfürchtig gespeichert. Einzelne Rufpunkte werden nicht protokolliert.",
    ["No reputation recorded yet."]="Noch keine Rufdaten erfasst.",
    ["Hated"]="Hasserfüllt",
    ["Hostile"]="Feindselig",
    ["Unfriendly"]="Unfreundlich",
    ["Neutral"]="Neutral",
    ["Friendly"]="Freundlich",
    ["Honored"]="Wohlwollend",
    ["Revered"]="Respektvoll",
    ["Exalted"]="Ehrfürchtig",
    ["First recorded"]="Erstmals erfasst",
    ["Profession skill at level-up:"]="Berufsstand beim Level-Up:",

    ["Language"]="Sprache",
    ["Automatic (client language)"]="Automatisch (Client-Sprache)",
    ["German"]="Deutsch",
    ["English"]="Englisch",
    ["Take chronicle screenshot"]="Chronik-Screenshot aufnehmen",

    ["January"]="Januar",
    ["February"]="Februar",
    ["March"]="März",
    ["April"]="April",
    ["May"]="Mai",
    ["June"]="Juni",
    ["July"]="Juli",
    ["August"]="August",
    ["September"]="September",
    ["October"]="Oktober",
    ["November"]="November",
    ["December"]="Dezember",
    ["Mon"]="Mo",
    ["Tue"]="Di",
    ["Wed"]="Mi",
    ["Thu"]="Do",
    ["Fri"]="Fr",
    ["Sat"]="Sa",
    ["Sun"]="So",
    ["journal entries"]="Tagebucheinträge",
    ["Entries on"]="Einträge am",
    ["Select a day with journal entries."]="Wähle einen Tag mit Tagebucheinträgen aus.",

    ["Filename"]="Dateiname",
    ["Type"]="Typ",
    ["Level-Up"]="Level-Up",
    ["Manual"]="Schnappschuss",
    ["Hearthstone"]="Ruhestein", ["Hearthstone used"]="Ruhestein benutzt", ["Use #%d"]="Nutzung Nr. %d", ["PvP"]="PvP", ["PvP kill"]="Spielerkill", ["PvP death"]="Von einem Spieler besiegt", ["Level %d"]="Stufe %d",
    ["Item from %s (%s)"]="Gegenstand aus %s (%s)", ["Item from %s"]="Gegenstand aus %s", ["Dungeon loot: %s"]="Dungeon-Beute: %s",
    ["Quest reward: %s"]="Questbelohnung: %s", ["Reward for the quest \"%s\""]="Belohnung für die Quest \"%s\"",
    ["Automatic"]="Automatisch",
    ["Death"]="Tod",
    ["Login"]="Login",
    ["Export filenames only"]="Nur Dateinamen exportieren",
    ["Export filenames hint"]="Der Button zeigt die Dateinamen als Text zum Kopieren mit Strg+C.",
    ["Filename unavailable"]="Dateiname nicht verfügbar",

    ["Journal manual only hint"]="Das Tagebuch füllt sich nur manuell. Einträge kannst du hier, auf der Weltkarte oder optional bei einem manuellen Screenshot erstellen.",
    ["New journal entry"]="Eintrag erstellen",
    ["Also create journal entry"]="Auch als Tagebucheintrag speichern",
    ["Screenshot journal title"]="Chronik-Screenshot",

    ["No screenshot filenames recorded."]="Keine Screenshot-Dateinamen erfasst.",

    ["Screenshots on this level:"]="Screenshots auf diesem Level:",
    ["Journal entries on this level:"]="Tagebucheinträge auf diesem Level:",
    ["Show screenshot files"]="Screenshot-Namen zeigen",
    ["Back to list"]="Zurück zur Liste",
    ["Filenames selected - press Ctrl+C now."]="Dateinamen markiert - jetzt Strg+C drücken.",
    ["Copied - paste it with Ctrl+V."]="Kopiert - mit Strg+V einfügen.",
    ["Screenshot files on level"]="Screenshot-Dateien auf Level",
    ["Select filenames and press Ctrl+C."]="Dateinamen markieren und mit Strg+C kopieren.",

    ["Gold balance:"]="Goldbilanz:",
    ["Duels:"]="Duelle:",
    ["Wins"]="Siege",
    ["Losses"]="Niederlagen",
    ["Screenshots on level:"]="Screenshots auf Level:",
    ["Journal entries on level:"]="Tagebucheinträge auf Level:",
    ["New zones discovered:"]="Neue Zonen entdeckt:",
    ["Profession milestones:"]="Berufs-Meilensteine:",

    ["Reached on: "]="Erreicht am: ",
    ["Gold earned:"]="Gold verdient:",
    ["Looted gold:"]="Gelootetes Gold:",
    ["Looted gold total:"]="Gelootetes Gold gesamt:", ["recorded since level %d"]="erfasst ab Level %d",
    ["Gold spent:"]="Gold ausgegeben:",

    ["ACCOUNT SUMMARY"]="ACCOUNT-GESAMT",
    ["Tracked characters"]="Erfasste Charaktere",
    ["Combined /played"]="Gesamte /played-Zeit",
    ["Active play time"]="Aktive Spielzeit",
    ["AFK time"]="AFK-Zeit",
    ["Deaths"]="Tode",
    ["Quests"]="Quests",
    ["Dungeon visits"]="Dungeonbesuche",
    ["Dungeon completions"]="Abgeschlossene Dungeons",
    ["Boss kills"]="Bosskills",
    ["Unique zones"]="Einzigartige Zonen",
    ["Combined gold"]="Gold (alle Charaktere)",
    ["Ground distance"]="Bodenstrecke",
    ["Flight distance"]="Flugstrecke",
    ["Flight time"]="Flugzeit",
    ["Sessions"]="Sitzungen",
    ["Screenshots"]="Screenshots",
    ["Journal entries"]="Tagebucheinträge",
    ["RECORDS"]="REKORDE",
    ["Most playtime"]="Meiste Spielzeit",
    ["Highest character"]="Höchster Charakter",
    ["Most quests"]="Meiste Quests",
    ["Most deaths"]="Meiste Tode",
    ["Richest character"]="Reichster Charakter",
    ["Farthest traveler"]="Weitester Reisender",
    ["Total /played"]="Gesamt /played",
    ["Gold"]="Gold",
    ["Last seen"]="Zuletzt gesehen",

    ["Characters"]="Chars",
    ["Characters tab description"]="Charakterübergreifende Zusammenfassung und Rekorde aller von MyCharForever erfassten Charaktere.",
    ["CHARACTERS"]="CHARAKTERE",
    ["Tracked characters: "]="Erfasste Charaktere: ",
    ["Combined /played: "]="Gesamte /played-Zeit: ",
    ["Combined deaths: "]="Tode: ",
    ["Combined quests: "]="Quests: ",
    ["Combined dungeons: "]="Dungeons: ",
    ["No account characters recorded yet."]="Noch keine accountweiten Charakterdaten erfasst.",
    ["Quests: "]="Quests: ",
    ["Gold: "]="Gold: ",
    ["Last seen: "]="Zuletzt gesehen: ",

    ["GUILD"]="GILDE",
    ["Current guild: "]="Aktuelle Gilde: ",
    ["Guild rank: "]="Gildenrang: ",
    ["Guild member since: "]="Mitglied seit: ",
    ["Guild first recorded: "]="Erstmals erfasst: ",
    ["No guild membership recorded."]="Keine Gildenmitgliedschaft erfasst.",
    ["Guild history:"]="Gilden-Historie:",
    ["Date / time"]="Datum / Zeit",
    ["Event"]="Ereignis",
    ["Guild"]="Gilde",
    ["Lvl"]="Lvl",
    ["Joined guild"]="Beigetreten",
    ["Left guild"]="Ausgetreten",
    ["Guild rank changed"]="Rang geändert",
    ["Guild first recorded"]="Erstmals erfasst",

    ["Apprentice"]="Lehrling",
    ["Journeyman"]="Geselle",
    ["Expert"]="Experte",
    ["Artisan"]="Fachmann",

    ["Professions"]="Berufe",
    ["MyCharForever screenshot"]="MyCharForever-Screenshot",
    ["Show screenshot filenames"]="Screenshot-Dateinamen anzeigen",
    ["Achievements tab"]="Erfolge",
    ["Nav group chronicle"]="Chronik", ["Nav group progress"]="Fortschritt", ["Nav group adventure"]="Abenteuer", ["Nav group characters"]="Charaktere",
    ["PROFESSION PROGRESS"]="BERUFS-FORTSCHRITT",
    ["No crafted items recorded yet."]="Noch keine hergestellten Gegenstände erfasst.",
    ["Crafted quantity"]="Hergestellt",
    ["Crafted items"]="Hergestellte Items",
    ["Profession progress description"]="Meilensteine in der beruflichen Entwicklung dieses Charakters.",
    ["No professions recorded yet."]="Noch keine Berufe aufgezeichnet.",
    ["Skill cap"]="Fertigkeitslimit",
    ["First recorded"]="Erstmals erfasst",
    ["skill reached"]="Fertigkeit erreicht",
    ["Profession history"]="Berufs-Historie",
    ["learned"]="erlernt",
    ["unlearned"]="verlernt",
    ["Kind mining"]="Bergbau", ["Kind herbalism"]="Kräuterkunde", ["Kind skinning"]="Kürschnerei", ["Kind fishing"]="Angeln",
    ["Kind disenchant"]="Entzaubern", ["Kind prospecting"]="Sondieren", ["Kind milling"]="Mahlen",
    ["Gathered resources"]="Gesammelte Ressourcen", ["Disenchanting and similar"]="Entzaubern, Sondieren und Mahlen",
    ["Destroyed items"]="Zerlegte Gegenstände", ["Nothing recorded yet."]="Noch nichts erfasst.",
    ["Skill per level"]="Fertigkeit pro Level", ["No profession skill recorded yet."]="Noch keine Berufsfertigkeit erfasst. Sobald du einen Beruf erlernst, erscheint hier seine Fertigkeit pro Level.", ["Special recipes"]="Besondere Rezepte (Drops, Quests, Händler)",
    ["No special recipes recorded yet."]="Noch keine besonderen Rezepte erfasst.", ["Vendor"]="Händler", ["Found or rewarded"]="Gefunden oder belohnt",
    ["relearned"]="erneut erlernt",
    ["skill cap increased"]="Fertigkeitslimit erhöht",
    ["first recorded"]="erstmals erfasst",

    ["Equipment"]="AUSRÜSTUNG",

    ["Level details"]="Level-Details",
    ["Details"]="Details",
    ["Activity:"]="Aktivität:",
    ["Quests"]="Quests",
    ["Deaths"]="Tode",
    ["Dungeons"]="Dungeons",

    ["Dungeons on level"]="Dungeons auf Level",
    ["Show dungeon list"]="Dungeonliste",
    ["No dungeon runs recorded on this level."]="Auf diesem Level wurden keine Dungeon-Runs aufgezeichnet.",

    ["PARTY"]="GRUPPE",
    ["BOSSES"]="BOSSE",
    ["LOOT"]="BEUTE",
    ["Party roster was not recorded for this run."]="Die Gruppe wurde für diesen Run noch nicht aufgezeichnet.",
    ["All required bosses defeated"]="Alle erforderlichen Bosse besiegt",
    ["All required bosses defeated (recognized retroactively)"]="Alle erforderlichen Bosse besiegt (nachträglich erkannt)",

    ["Search journal"]="Tagebuch durchsuchen",
    ["Clear"]="Leeren",
    ["No journal entries match your search."]="Keine Tagebucheinträge entsprechen der Suche.",

    ["Tip First tracked"]="Zeitpunkt, an dem MyCharForever diesen Charakter erstmals aufgezeichnet hat.",
    ["Tip Total played"]="Gesamte Charakter-Spielzeit, die WoW über /played meldet.",
    ["Tip AFK"]="Zeit, in der WoW den Charakter als AFK markiert hatte.",
    ["Tip Stationary"]="Zeit, in der sich der Charakter nicht von der Stelle bewegt hat (Stehen, Handwerk, Angeln, AFK ...). Die AFK-Zeit ist darin enthalten, weil ein AFK-Charakter sich ebenfalls nicht bewegt. Erfasst seit Version 0.16.0.",
    ["Tip Longest stationary"]="Längste zusammenhängende Phase ohne Bewegung. Ein einzelner Schritt beendet sie nicht, zwei Sekunden Bewegung am Stück schon.",
    ["Tip Active play"]="Gesamtes /played abzüglich der erfassten AFK-Zeit.",
    ["Tip Current session"]="Zeit seit Beginn der aktuellen Login-Sitzung.",
    ["Tip Time level"]="Erfasste aktive Sitzungszeit auf dem aktuellen Level.",
    ["Tip Sessions"]="Anzahl der von MyCharForever aufgezeichneten Login-Sitzungen.",
    ["Tip Average session"]="Durchschnittliche Dauer der aufgezeichneten Sitzungen.",
    ["Tip Journey points"]="Intern gespeicherte Positionspunkte, aus denen der Reisepfad rekonstruiert wird.",
    ["Tip Maps movement"]="Anzahl der Karten, auf denen Bewegungen für den Reisepfad aufgezeichnet wurden.",
    ["Tip Zone changes"]="Anzahl der aufgezeichneten Zonenwechsel.",
    ["Tip Map path"]="Zeigt, ob der aufgezeichnete Reisepfad aktuell auf der Weltkarte eingeblendet wird.",
    ["Tip Timeline"]="Anzahl chronologischer Ereignisse wie Logins, Quests, Tode und Level-Ups.",
    ["Tip Journal entries"]="Anzahl der persönlichen Tagebucheinträge dieses Charakters.",
    ["Screenshot display hint"]="World of Warcraft erlaubt Addons nicht, Bilder oder Screenshots anzuzeigen. Das Addon speichert deshalb nur Dateiname, Ort, Zeit und deinen Kommentar. Die Bilder selbst findest du im WoW-Screenshot-Ordner und als Fotobuch auf der Website (/mcf website).",
    ["Screenshot display hint short"]="Hier wird nur der Eintrag angezeigt. WoW erlaubt Addons nicht, das Bild selbst zu zeigen. Es liegt im WoW-Screenshot-Ordner und erscheint als Fotobuch auf der Website.",
    ["Tip Screenshot records"]="Anzahl der vom Addon gespeicherten Screenshot-Verweise; die Bilddateien selbst bleiben im WoW-Screenshot-Ordner.",
    ["Tip Level snapshots"]="Anzahl der bei Level-Meilensteinen gespeicherten Ausrüstungs-/Status-Schnappschüsse.",
    ["Tip Journey tracking"]="Zeigt, ob die fortlaufende Aufzeichnung des Reisepfads aktiviert ist.",
    ["Tip Level screenshots"]="Zeigt, ob bei Level-Ups automatisch Screenshots erstellt werden.",
    ["Tip Database version"]="Interne Datenformat-Version von MyCharForever.",
    ["Tip Addon version"]="Aktuell geladene Version von MyCharForever.",
    ["Tip Levelups"]="Anzahl der Level-Ups, die seit Beginn der Aufzeichnung beobachtet wurden.",
    ["Tip Completed levels"]="Level, für die eine vollständige Dauer von Anfang bis Ende aufgezeichnet wurde.",
    ["Tip Average level"]="Durchschnittliche Dauer aller vollständig aufgezeichneten Level.",
    ["Tip Longest level"]="Das vollständig aufgezeichnete Level mit der längsten Dauer.",
    ["Tip Deaths"]="Gesamtzahl der von MyCharForever aufgezeichneten Tode.",
    ["Tip Duels"]="Aufgezeichnete Duelle sowie Siege und Niederlagen.",
    ["Tip Ground distance"]="Geschätzte am Boden zurückgelegte Strecke aus den aufgezeichneten Bewegungsdaten.",
    ["Tip Flight routes"]="Anzahl der aufgezeichneten Flugmeister-/Taxi-Routen.",
    ["Tip Flight distance"]="Geschätzte Strecke auf aufgezeichneten Flugrouten.",
    ["Tip Flight time"]="Gesamte aufgezeichnete Zeit auf Flugmeister-/Taxi-Routen.",
    ["Tip Dungeon visits"]="Anzahl der aufgezeichneten Dungeon-Betretungen.",
    ["Tip Dungeon completions"]="Dungeon-Läufe, bei denen MyCharForever ein Abschluss-Signal erkannt hat.",
    ["Tip Death rate"]="Aufgezeichnete Tode geteilt durch die gesamte /played-Zeit in Stunden.",
    ["Tip Money"]="Aktuell von diesem Charakter mitgeführtes Gold.",
    ["Tip Current zone"]="Zone, in der sich der Charakter aktuell befindet.",
    ["Tip Current subzone"]="Aktuelle von WoW gemeldete Unterzone.",
    ["Tip World time"]="Erfasste Zeit in der offenen Welt.",
    ["Tip Resting time"]="Erfasste Zeit in Ruhebereichen wie Gasthäusern und Städten.",
    ["Tip Dungeon time"]="Erfasste Zeit innerhalb von Dungeon-Instanzen.",
    ["Tip Raid time"]="Erfasste Zeit innerhalb von Raid-Instanzen.",
    ["Tip PvP time"]="Erfasste Zeit innerhalb von PvP-Instanzen.",

    ["Expert export"]="Experten-Export", ["Expert export help"]="Wähle grobe Datenbereiche. Der Reisepfad wird standardmäßig stark vereinfacht; Rohpunkte nur bei Bedarf aktivieren.", ["Character and levels"]="Charakter und Level", ["Adventure and statistics"]="Abenteuer und Statistiken", ["Timeline and sessions"]="Timeline und Sitzungen", ["Journal"]="Tagebuch", ["Screenshot references"]="Screenshot-Referenzen", ["Journey"]="Reisepfad", ["Raw journey points"]="Rohe Reisepunkte", ["Addon settings"]="Addon-Einstellungen", ["Create export"]="Export erstellen",

    ["Export packed help"]="Gepackte Chronik (%.0f KB lesbar, %.0f KB gepackt). Klicke Alles markieren, dann Strg+C. Füge den gesamten Text auf der Website in Variante B) in das Textfeld \"Export hier einfügen\" ein und drücke \"Laden\".", ["Packing export"]="Export wird gepackt ... %d %%", ["Packing failed"]="Packen fehlgeschlagen - stattdessen wird der lesbare Text gezeigt.", ["Pack"]="Packen", ["Show readable"]="Lesbar anzeigen",
    ["Preparing export"]="Export wird vorbereitet ...", ["Export failed"]="Export fehlgeschlagen",

    ["Screenshot intro"]="WoW erlaubt Addons nicht, Bilder anzuzeigen. Die Screenshots selbst liegen in deinem WoW-Screenshot-Ordner und, als Fotobuch mit Level und Ort, auf der Website (/mcf website). Der Export enthält alle erfassten Screenshots.",
    ["Manual screenshot info"]="Screenshots, die du selbst gemacht hast: mit dem MyCharForever-Shortcut oder der normalen Screenshot-Taste des Spiels.",
    ["Automatic screenshot info"]="Screenshots, die das Addon selbst gemacht hat. Mit dem Filter zeigst du nur einen Typ.",
    ["Shot tab manual"]="Manuelle Screenshots", ["Shot tab automatic"]="Automatische Screenshots", ["Search screenshots"]="Screenshots durchsuchen (Kommentar, Ort, Dateiname, Typ)", ["No screenshots found."]="Keine Screenshots gefunden.",
    ["Shot type"]="Typ:", ["Shot all types"]="Alle Typen", ["Shot interval"]="Intervall", ["Shot equipment"]="Ausrüstung", ["Shot guild"]="Gilde", ["Shot other"]="Sonstige", ["Shot dungeon"]="Dungeon-Abschluss", ["Shot achievement"]="Erfolg", ["At achievement"]="Beim Freischalten eines Addon-Erfolgs",
    ["Export screenshots"]="Alle Screenshots exportieren", ["Date"]="Datum", ["Start"]="Start", ["End"]="Ende", ["Low"]="Tief", ["High"]="Hoch", ["Change"]="Änderung",

    ["Screenshots"]="Screenshots", ["No screenshots recorded yet."]="Noch keine Screenshots aufgezeichnet.",
    ["No comment"]="Kein Kommentar", ["Export one"]="Exportieren",
    ["Duels: "]="Duelle: ", ["Wins"]="Siege", ["Losses"]="Niederlagen",
    ["Ground distance:"]="Bodenstrecke:", ["Flight routes:"]="Flugrouten:",
    ["Flight distance:"]="Flugstrecke:", ["Flight time:"]="Flugzeit:", ["Hearthstone uses:"]="Ruhestein-Nutzungen:", ["Hearthstone uses: "]="Ruhestein-Nutzungen: ",
    ["Ground distance: "]="Bodenstrecke: ", ["Flight routes: "]="Flugrouten: ",
    ["Flight distance: "]="Flugstrecke: ", ["Flight time: "]="Flugzeit: ",

    ["Export"]="Export", ["Export chronicle"]="Chronik exportieren",
    ["Select all"]="Alles markieren", ["Open website"]="Zur Website", ["External link"]="Externer Link", ["External link help"]="Das führt auf eine externe Website (www.mycharforever.com), auf der du deinen Export in den Chronik-Viewer einfügen kannst. WoW kann keine Webseiten selbst öffnen: Kopiere die Adresse unten mit Strg+C und füge sie in deinen Browser ein. Aus dem Spiel wird nichts gesendet.",
    ["Map filter"]="Filter", ["Current level"]="Aktuell", ["Last 5 levels"]="Letzte 5",
    ["Death cause"]="Ursache", ["Death killer"]="Getötet von", ["Death cause unknown"]="unbekannt", ["Death no screenshot"]="keiner",
    ["Cause drowned"]="Ertrunken", ["Cause fatigue"]="Erschöpfung", ["Cause fall"]="Fallschaden", ["Cause guard"]="Von einer Wache getötet", ["Cause pvp"]="Von einem Spieler getötet",
    ["Export all screenshots title"]="Alle erfassten Screenshots exportieren", ["Export screenshot title"]="Screenshot exportieren",
    ["Export all screenshots help"]="Datenexport für externe Programme mit allen erfassten Screenshots: deine eigenen MyCharForever-Screenshots (mit Kommentar) und die normalen Spiel-Screenshots. Es werden keine Bilder angezeigt, nur Dateiname, Ort, Zeit und Kommentar. Klicke %s und dann Strg+C, um ihn zu kopieren.",
    ["Export screenshot help"]="Datenexport dieses Screenshots für externe Programme. Das Bild wird nicht angezeigt, nur Dateiname, Ort, Zeit und Kommentar. Klicke %s und dann Strg+C, um ihn zu kopieren.",
    ["Export help"]="Vollständige maschinenlesbare Chronik. Klicke Alles markieren und dann Strg+C. Screenshot-Bilddateien werden über ihren Dateinamen referenziert und sind nicht im Text enthalten.",

    ["Chronicle screenshot"]="Chronik-Screenshot", ["Chronicle screenshots"]="Chronik-Screenshots",
    ["Save comment"]="Kommentar speichern", ["Without comment"]="Ohne Kommentar",
    ["Screenshot recording disabled"]="Screenshot-Aufzeichnung ist in den Einstellungen deaktiviert",

    ["Screenshot"]="Screenshot",
    ["Active travel time"]="Aktive Reisezeit",
    ["This session only"]="Nur diese Session",
    ["AFK time:"]="AFK-Zeit:", ["Stationary time:"]="Zeit ohne Bewegung:", ["Stationary time: "]="Zeit ohne Bewegung: ", ["Longest stationary stretch: "]="Längste Phase ohne Bewegung: ", ["Active time:"]="Aktive Zeit:", ["Average item level:"]="Durchschn. Itemlevel:", ["Itemlevel:"]="iLvl",
    ["Active play time:"]="Aktive Spielzeit:", ["not recorded"]="nicht erfasst",

    ["Journey recording"]="Reiseaufzeichnung", ["Record journey path"]="Reisepfad aufzeichnen",
    ["Recording interval"]="Aufzeichnungsintervall:", ["seconds short"]="Sek.",
    ["Journey interval tooltip"]="Bestimmt, wie häufig deine Position für den Reisepfad gespeichert wird. Kürzere Intervalle erzeugen einen genaueren und durchgängiger wirkenden Pfad auf der Karte, speichern aber mehr Daten. Bei längeren Intervallen kann der Pfad gröber wirken.",
    ["Database"]="DATENBANK", ["Estimated SavedVariables size"]="Geschätzte SavedVariables-Größe",
    ["Journey points short"]="Reisepunkte", ["Events short"]="Ereignisse", ["Dungeon runs short"]="Dungeon-Runs", ["Screenshots short"]="Screenshots",

    ["7D"]="7T", ["30D"]="30T", ["90D"]="90T", ["1Y"]="1J", ["ALL"]="ALLE",
    ["Settings"]="Einstellungen", ["End: "]="Ende: ", ["Gold: "]="Gold: ",
    ["No gold history recorded yet."]="Noch keine Goldhistorie aufgezeichnet.",
    ["Milestone fallback"]="Meilenstein",
    ["Click to open"]="Klicken zum Öffnen", ["Drag to move"]="Ziehen zum Verschieben",
    ["Chronicle settings"]="Chronik- und Screenshot-Einstellungen",
    ["Show minimap button"]="Minimap-Button anzeigen", ["Screenshots"]="Screenshots",
    ["Enable automatic screenshots"]="Automatische Screenshots aktivieren",
    ["At level up"]="Beim Level-Up", ["At login"]="Beim Einloggen", ["At death"]="Beim Tod",
    ["At dungeon completion"]="Beim Dungeon-Abschluss",
    ["When equipping quality item"]="Screenshot beim ersten Anlegen jeder Seltenheitsstufe pro Ausrüstungsplatz (ab Mindestqualität)",
    ["Equipment milestone"]="Ausrüstungs-Meilenstein",
    ["First quality in slot"]="Erstmals %s in diesem Ausrüstungsplatz: %s",
    ["Equipment slot"]="Platz",
    ["Periodic screenshots"]="Regelmäßig Screenshots aufnehmen",
    ["Interval minutes"]="Intervall (Minuten):", ["Minimum item quality"]="Minimale Itemqualität:",
    ["Uncommon"]="Ungewöhnlich", ["Rare"]="Selten", ["Epic"]="Episch", ["Legendary"]="Legendär",

    ["Journey time marker"]="Reisezeit-Marker", ["Recorded travel time"]="Aufgezeichnete Reisezeit",
    ["5 minute markers"]="5-Minuten-Marker", ["Level range"]="Levelbereich:",
    ["Apply"]="Anwenden", ["All levels"]="Alle Level",
    ["Quest ID"]="Quest-ID", ["Quest"]="Quest", ["XP"]="XP", ["Zone"]="Zone",
    ["Copy quest list"]="Questliste kopieren",
    ["Copy quest list hint"]="Klicken, dann Strg+C kopiert die komplette Liste.",

    ["Show quest list"]="Questliste anzeigen",
    ["Quests on level"]="Quests auf Level",
    ["Quest list copy hint"]="Markierbarer Text - Strg+A / Strg+C kopiert die Liste.",
    ["Quest list header"]="ID      Quest                                      XP  Zone",
    ["Quest list total"]="%d Quests | %d Quest-XP",
    ["Quest XP:"]="Quest-XP:", ["Other XP:"]="Sonstige XP:", ["Required XP:"]="Benötigte XP:",
    ["XP ratio:"]="XP-Verteilung:", ["available for newly tracked levels"]="für neu aufgezeichnete Level verfügbar",

    ["Show quests"]="Quests anzeigen", ["Hide quests"]="Quests ausblenden",
    ["Show dungeon runs"]="Dungeon-Runs anzeigen", ["Hide dungeon runs"]="Dungeon-Runs ausblenden",
    ["Show boss kills"]="Bosskills anzeigen", ["Hide boss kills"]="Bosskills ausblenden",
    ["Show deaths"]="Tode anzeigen", ["Hide deaths"]="Tode ausblenden",
    ["Show zones"]="Zonen anzeigen", ["Hide zones"]="Zonen ausblenden",

    ["Quests completed:"]="Quests abgeschlossen:", ["Dungeon runs:"]="Dungeon-Runs:", ["Dungeon completions:"]="Dungeon-Abschlüsse:",
    ["Boss kills:"]="Bosskills:", ["Sessions:"]="Sitzungen:", ["Zones visited:"]="Besuchte Zonen:",
    ["Show details"]="Details anzeigen", ["Hide details"]="Details ausblenden",

    ["Time on Level "]="Zeit auf Level ",
    ["Snapshot:"]="Snapshot:", ["Equipment slots:"]="Ausrüstungsplätze:", ["Money:"]="Gold:", ["Screenshot:"]="Screenshot:",
    ["Screenshot file: "]="Screenshot-Datei: ",
    ["EXPLORATION"]="ERKUNDUNG", ["ARCHIVE / DATA"]="ARCHIV / DATEN", ["MOST TIME SPENT"]="MEISTE ZEIT VERBRACHT",
    ["Map path: "]="Kartenpfad: ",

    ["CHARACTER"]="CHARAKTER", ["PLAYTIME"]="SPIELZEIT", ["LEVELING"]="LEVELN", ["JOURNEY"]="REISE", ["ADVENTURE"]="ABENTEUER",
    ["LOCATION TIMES"]="ZEITAUFTEILUNGEN", ["GOLD"]="GOLD", ["DAILY HISTORY"]="TAGESVERLAUF",
    ["No completed levels yet."]="Noch keine abgeschlossenen Level.",
    ["Deaths / played hour: "]="Tode / Spielstunde: ",
    ["Current balance: "]="Aktueller Stand: ", ["Today's change:"]="Heutige Änderung:",
    ["Today's change: "]="Heutige Änderung: ", ["Start: "]="Start: ", ["Low: "]="Tief: ", ["High: "]="Hoch: ", ["Change: "]="Änderung: ",
    ["Longest tracked level: "]="Längstes erfasstes Level: ",

    ["Overview"]="Übersicht", ["Level-Ups"]="Level-Ups", ["Journal"]="Tagebuch", ["Gold"]="Gold", ["Dungeons"]="Dungeons",
    ["Edit"]="Bearbeiten", ["Delete"]="Löschen", ["Save"]="Speichern", ["Cancel"]="Abbrechen", ["Show"]="Anzeigen",
    ["Scale:"]="Skala:", ["Edit Milestones"]="Meilensteine bearbeiten", ["Milestone"]="Meilenstein",
    ["MyCharForever - Gold Milestones"]="MyCharForever - Gold-Meilensteine",
    ["Configure your own gold goals. Prices are intentionally not predefined."]="Lege deine eigenen Goldziele fest. Preise sind bewusst nicht vorgegeben.",
    ["DAILY GOLD BALANCE"]="TÄGLICHER GOLDSTAND", ["Level"]="Level", ["Start"]="Start", ["Low"]="Tief", ["High"]="Hoch", ["Change"]="Änderung",
    ["LEVEL-UP HISTORY"]="LEVEL-UP-VERLAUF", ["A chronological record of this character's milestones."]="Eine chronologische Aufzeichnung der Meilensteine dieses Charakters.",
    ["No recorded level-ups yet."]="Noch keine Level-Ups aufgezeichnet.", ["Reached: "]="Erreicht: ", ["Location: "]="Ort: ",
    ["Time for Level "]="Zeit für Level ", ["Snapshot: YES  |  Equipment slots: "]="Snapshot: JA  |  Ausrüstungsplätze: ",
    ["Snapshot: no"]="Snapshot: nein", ["Screenshot record: "]="Screenshot-Eintrag: ", ["YES"]="JA", ["no"]="nein",
    ["ARCHIVE"]="ARCHIV", ["Recorded level-ups: "]="Aufgezeichnete Level-Ups: ", ["Level snapshots: "]="Level-Schnappschüsse: ",
    ["Screenshot records: "]="Screenshot-Einträge: ", ["JOURNAL"]="TAGEBUCH", ["Personal notes from this character's journey."]="Persönliche Notizen von der Reise dieses Charakters.",
    ["No journal entries yet."]="Noch keine Tagebucheinträge.", ["No journal entries yet. Create one from the world map."]="Noch keine Tagebucheinträge. Erstelle einen über die Weltkarte.",
    ["Create one with '+ Journal Entry' on the world map."]="Erstelle einen mit '+ Neuer Tagebucheintrag' auf der Weltkarte.", ["Journal Entry "]="Tagebucheintrag ",
    ["Current balance:"]="Aktueller Goldstand:", ["Today's change: "]="Heutige Änderung: ", ["Gold history starts with this addon version."]="Die Goldhistorie beginnt mit dieser Addon-Version.",
    ["Delete selected dungeon run(s) permanently?"]="Ausgewählte Dungeon-Runs dauerhaft löschen?",
    ["MyCharForever - Dungeon Run"]="MyCharForever - Dungeon-Run", ["Delete Run"]="Run löschen", ["Unknown Dungeon"]="Unbekannter Dungeon",
    ["Status: "]="Status: ", ["COMPLETED"]="ABGESCHLOSSEN", ["CLEARED"]="KOMPLETT GERÄUMT", ["CLEARED SHORT"]="GERÄUMT", ["Fully cleared"]="Komplett geräumt", ["Dungeon fully cleared - "]="Dungeon komplett geräumt - ", ["VISITED"]="BESUCHT", ["IN PROGRESS"]="LÄUFT",
    ["Entered: "]="Betreten: ", ["Left: "]="Verlassen: ", ["Duration: "]="Dauer: ", ["Deaths: "]="Tode: ",
    ["Gold at start: "]="Gold zu Beginn: ", ["Gold at end: "]="Gold am Ende: ", ["Gold change: "]="Goldänderung: ",
    ["Exit: "]="Ende: ", ["Completed: "]="Abgeschlossen: ", ["Completion signal: "]="Abschluss-Signal: ",
    ["BOSSES"]="BOSSE", ["No boss encounters recorded for this run."]="Für diesen Run wurden keine Bossbegegnungen aufgezeichnet.",
    ["LOOT"]="BEUTE", ["MY LOOT"]="MEINE BEUTE", ["GROUP LOOT"]="GRUPPENBEUTE", ["No personal dungeon loot recorded for this run."]="Für diesen Run wurde keine eigene Dungeon-Beute eindeutig erkannt.", ["No other dungeon loot recorded for this run."]="Für diesen Run wurde keine weitere Gruppenbeute aufgezeichnet.", ["No dungeon loot recorded for this run."]="Für diesen Run wurde keine Dungeon-Beute aufgezeichnet.", ["Unknown source"]="Unbekannte Quelle", ["Item "]="Gegenstand ",
    ["All Dungeons"]="Alle Dungeons", ["All"]="Alle", ["Completed"]="Abgeschlossen", ["Visited"]="Besucht", ["In Progress"]="Läuft",
    ["DUNGEON HISTORY"]="DUNGEON-VERLAUF", ["Dungeon:"]="Dungeon:", ["Status:"]="Status:", ["Delete selected"]="Auswahl löschen",
    ["Showing "]="Zeige ", [" of "]=" von ", [" runs   |   Completions: "]=" Runs   |   Abschlüsse: ",
    ["No dungeon runs match the current filters."]="Keine Dungeon-Runs entsprechen den aktuellen Filtern.",
    ["First tracked: "]="Erstmals erfasst: ", ["Total /played: "]="Gesamtes /played: ", ["Current session: "]="Aktuelle Sitzung: ",
    ["Time this level: "]="Zeit auf diesem Level: ", ["Tracked sessions: "]="Erfasste Sitzungen: ", ["Average session: "]="Ø Sitzung: ",
    ["Level-ups tracked: "]="Erfasste Level-Ups: ", ["Completed level records: "]="Abgeschlossene Level-Aufzeichnungen: ",
    ["Average time / completed level: "]="Ø Zeit pro abgeschlossenem Level: ", ["Longest tracked level: "]="Längstes erfasstes Level: ",
    ["Journey points: "]="Reisepunkte: ", ["Maps with recorded movement: "]="Karten mit aufgezeichneter Bewegung: ", ["Zone changes: "]="Zonenwechsel: ",
    ["Timeline events: "]="Chronik-Ereignisse: ", ["Journal entries: "]="Tagebucheinträge: ", ["Map path: "]="Kartenpfad: ", ["shown"]="sichtbar", ["hidden"]="ausgeblendet",
    ["Dungeon visits: "]="Dungeon-Besuche: ", ["Dungeon completions detected: "]="Erkannte Dungeon-Abschlüsse: ", ["Current money: "]="Aktuelles Gold: ",
    ["Current zone: "]="Aktuelle Zone: ", ["Current subzone: "]="Aktuelle Unterzone: ", ["World: "]="Welt: ", ["Resting areas: "]="Ruhebereiche: ",
    ["Dungeons: "]="Dungeons: ", ["Raids: "]="Raids: ", ["PvP instances: "]="PvP-Instanzen: ", ["Journey tracking: "]="Reiseaufzeichnung: ",
    ["Level-up screenshots: "]="Level-Up-Screenshots: ", ["Database version: "]="Datenbankversion: ", ["Addon version: "]="Addon-Version: ",
    ["ON"]="AN", ["OFF"]="AUS",
    ["Death"]="Tod", [" reached"]=" erreicht", ["Login / session start"]="Login / Sitzungsstart", ["Journal entry"]="Tagebucheintrag", ["Journey point"]="Reisepunkt",
    ["Date"]="Datum", ["Time"]="Zeit", ["Position"]="Position", ["Delete this journal entry permanently?"]="Diesen Tagebucheintrag dauerhaft löschen?",
    ["Title"]="Titel", ["Entry"]="Eintrag", ["MyCharForever - Edit journal entry"]="MyCharForever - Tagebucheintrag bearbeiten",
    ["MyCharForever - New journal entry"]="MyCharForever - Neuer Tagebucheintrag", ["Map display"]="Kartenanzeige", ["Journey Path"]="Reisepfad",
    ["Iconic moments"]="Ikonische Momente", ["Deaths"]="Tode", ["World Drops"]="Weltdrops", ["Notable drop"]="Besonderer Drop", ["Found at %s"]="Gefunden bei %s", ["Found at %s in %s"]="Gefunden bei %s in %s", ["Found in %s"]="Gefunden in %s", ["Notable drop: %s"]="Besonderer Drop: %s", ["Test drop source"]="Testquelle", ["Test drop added. Remove with /mcf droptest clear"]="Test-Drop hinzugefügt. Entfernen mit /mcf droptest clear", ["Test drops removed: "]="Test-Drops entfernt: ", ["Journal Entries"]="Tagebucheinträge", ["+ New Journal Entry"]="+ Neuer Tagebucheintrag",
    ["Journal entry deleted."]="Tagebucheintrag gelöscht.", ["Journal entry updated."]="Tagebucheintrag aktualisiert.", ["Journal entry saved."]="Tagebucheintrag gespeichert.",
    ["Current map position unavailable."]="Aktuelle Kartenposition nicht verfügbar.", ["MapCanvas API unavailable."]="MapCanvas-API nicht verfügbar.",
    ["Dungeon entered - "]="Dungeon betreten - ", ["Dungeon continued - "]="Dungeon fortgesetzt - ", ["Dungeon completion detected - "]="Dungeon-Abschluss erkannt - ",
    [" simulated gold days created."]=" simulierte Gold-Tage erstellt.", ["Simulated gold days removed."]="Simulierte Gold-Tage entfernt.",
    ["Manual snapshot saved for level "]="Manueller Snapshot gespeichert für Level ", ["Manual snapshot failed: "]="Manueller Snapshot fehlgeschlagen: ",
    ["Level snapshot failed, but level tracking continues."]="Level-Snapshot fehlgeschlagen, die Level-Aufzeichnung läuft weiter.", [" reached!"]=" erreicht!",
    [" loaded."]=" geladen."
}

MCF.ClientLocale = GetLocale and GetLocale() or "enUS"
MCF.Locales = { enUS=enUS, deDE=deDE }

function MCF:GetLanguage()
    local override=MyCharForeverDB and MyCharForeverDB.settings and MyCharForeverDB.settings.language
    if override=="deDE" or override=="enUS" then return override end
    return (MCF.ClientLocale=="deDE") and "deDE" or "enUS"
end

-- Class and race names by their language-independent file names, so the addon language decides the text
-- (the game's own UnitClass/UnitRace return the client language, which may differ from the addon language).
local CLASS_NAMES={
    WARRIOR={"Krieger","Warrior"}, PALADIN={"Paladin","Paladin"}, HUNTER={"Jäger","Hunter"}, ROGUE={"Schurke","Rogue"},
    PRIEST={"Priester","Priest"}, DEATHKNIGHT={"Todesritter","Death Knight"}, SHAMAN={"Schamane","Shaman"}, MAGE={"Magier","Mage"},
    WARLOCK={"Hexenmeister","Warlock"}, MONK={"Mönch","Monk"}, DRUID={"Druide","Druid"}, DEMONHUNTER={"Dämonenjäger","Demon Hunter"},
    EVOKER={"Rufer","Evoker"},
}
local RACE_NAMES={
    Human={"Mensch","Human"}, Orc={"Orc","Orc"}, Dwarf={"Zwerg","Dwarf"}, NightElf={"Nachtelf","Night Elf"},
    Scourge={"Untoter","Undead"}, Tauren={"Tauren","Tauren"}, Gnome={"Gnom","Gnome"}, Troll={"Troll","Troll"},
    Goblin={"Goblin","Goblin"}, BloodElf={"Blutelf","Blood Elf"}, Draenei={"Draenei","Draenei"}, Worgen={"Worgen","Worgen"},
    Pandaren={"Pandaren","Pandaren"}, Nightborne={"Nachtgeborener","Nightborne"}, HighmountainTauren={"Hochbergtauren","Highmountain Tauren"},
    VoidElf={"Leerenelf","Void Elf"}, LightforgedDraenei={"Lichtgeschmiedeter Draenei","Lightforged Draenei"},
    ZandalariTroll={"Zandalaritroll","Zandalari Troll"}, KulTiran={"Kul Tiraner","Kul Tiran"}, DarkIronDwarf={"Dunkeleisenzwerg","Dark Iron Dwarf"},
    Vulpera={"Vulpera","Vulpera"}, MagharOrc={"Mag'har","Mag'har Orc"}, Mechagnome={"Mechagnom","Mechagnome"},
    Dracthyr={"Dracthyr","Dracthyr"}, EarthenDwarf={"Irdener","Earthen"},
}
local function NameFor(map,file,fallback)
    local e=file and map[file]
    if e then return MCF:GetLanguage()=="deDE" and e[1] or e[2] end
    return fallback
end
function MCF:ClassName(classFile,fallback) return NameFor(CLASS_NAMES,classFile,fallback) end
function MCF:RaceName(raceFile,fallback) return NameFor(RACE_NAMES,raceFile,fallback) end

-- Profession names: the game client delivers them in its own language, the addon may be set to another.
-- Keyed by skill line ID (the "id:NNN" part of a profession key); unknown professions keep the client's name.
local PROFESSION_NAMES={
    [164]={"Schmiedekunst","Blacksmithing"}, [165]={"Lederverarbeitung","Leatherworking"}, [171]={"Alchemie","Alchemy"},
    [182]={"Kräuterkunde","Herbalism"}, [186]={"Bergbau","Mining"}, [197]={"Schneiderei","Tailoring"},
    [202]={"Ingenieurskunst","Engineering"}, [333]={"Verzauberkunst","Enchanting"}, [393]={"Kürschnerei","Skinning"},
    [755]={"Juwelenschleifen","Jewelcrafting"}, [773]={"Inschriftenkunde","Inscription"}, [129]={"Erste Hilfe","First Aid"},
    [185]={"Kochkunst","Cooking"}, [356]={"Angeln","Fishing"}, [794]={"Archäologie","Archaeology"},
}
function MCF:ProfessionName(key,fallback)
    local id=type(key)=="string" and tonumber(key:match("^id:(%d+)$"))
    return NameFor(PROFESSION_NAMES,id,fallback)
end

function MCF:T(key)
    local active=MCF.Locales[MCF:GetLanguage()] or enUS
    return active[key] or enUS[key] or key
end

BINDING_HEADER_MYCHARFOREVER="MyCharForever"
BINDING_NAME_MYCHARFOREVER_CHRONICLE_SCREENSHOT=MCF:T("Take chronicle screenshot")

---------------------------------------------------------------------------
-- Slash command registry: the ONE place that knows every command. Files register
-- their commands here; /mcf help prints this list, /mcf <key> dispatches from it.
-- Entry: {usage, example (optional), group = "main"|"test"|"debug", de, en,
--         key (exact match after "/mcf ") or match(msg), run(msg) (optional)}
---------------------------------------------------------------------------
MCF.commands = {}
-- An EditBox has no GetStringHeight in this client: the height of its text is measured with a hidden FontString of the same
-- width and font, so a multi-line EditBox in a ScrollFrame can be sized to its content.
local measureFS
-- Turns a button into the "press a key" shortcut picker for the chronicle screenshot (used by Settings and the welcome window).
-- onChanged() runs after the binding changed.
function MCF:AttachShortcutCapture(button,onChanged)
    local capturing=false
    local function refresh()
        local key=MCF.GetChronicleScreenshotBinding and MCF:GetChronicleScreenshotBinding() or nil
        button:SetText(MCF.FormatBindingKey and MCF:FormatBindingKey(key) or (key or MCF:T("Not assigned")))
    end
    local function stop() capturing=false; button:EnableKeyboard(false); button:SetScript("OnKeyDown",nil); refresh() end
    button:SetScript("OnShow",refresh)
    button:SetScript("OnClick",function(self)
        capturing=true
        self:EnableKeyboard(true)
        self:SetPropagateKeyboardInput(false)
        self:SetText(MCF:T("Press a key..."))
        self:SetScript("OnKeyDown",function(_,key)
            if not capturing then return end
            if key=="ESCAPE" then stop(); return end
            if key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" then return end
            local bind=key
            if IsControlKeyDown and IsControlKeyDown() then bind="CTRL-"..bind end
            if IsShiftKeyDown and IsShiftKeyDown() then bind="SHIFT-"..bind end
            if IsAltKeyDown and IsAltKeyDown() then bind="ALT-"..bind end
            if MCF.SetChronicleScreenshotBinding then MCF:SetChronicleScreenshotBinding(bind) end
            stop()
            if onChanged then onChanged() end
        end)
    end)
    refresh()
    return refresh
end

function MCF.FitEditBox(edit, minHeight)
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "ARTWORK")
        measureFS:SetJustifyH("LEFT"); measureFS:SetJustifyV("TOP"); measureFS:Hide()
    end
    local font, size, flags = edit:GetFont()
    if font then measureFS:SetFont(font, size or 12, flags) else measureFS:SetFontObject(ChatFontNormal) end
    measureFS:SetWidth(math.max(50, (edit:GetWidth() or 400) - 8))
    measureFS:SetText(edit:GetText() or "")
    edit:SetHeight(math.max(minHeight or 100, math.ceil(measureFS:GetStringHeight() or 0) + 20))
end

-- How the addon marks what it shows as coming from itself: coloured name (own popups, dialogs) and the logo file.
MCF.BRAND_NAME = "|cff9fe8ffMyCharForever|r"
MCF.LOGO_PATH = "Interface\\AddOns\\MyCharForever\\MyCharForever_Icon"
-- Standard Blizzard dialogs have no logo slot: the round logo (inline texture) and the name go in front of the text.
function MCF.Branded(text) return "|T" .. MCF.LOGO_PATH .. ":22:22|t " .. MCF.BRAND_NAME .. "\n\n" .. tostring(text or "") end

function MCF:AddCommand(entry) self.commands[#self.commands + 1] = entry end

-- Lives in Localization.lua because that is the first file of the addon (Settings.lua and
-- Screenshots.lua load before Core.lua and need it).
-- Extra windows must never show the game world or other windows through them: the dialog background
-- textures are semi-transparent, so a solid layer goes underneath. `top` leaves the title bar of
-- Blizzard frame templates alone.
function MCF.MakeOpaque(frame,top)
    if not frame or frame.mcfOpaque then return end
    local t=frame:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-(top or 4))
    t:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-4,4)
    t:SetColorTexture(0.08,0.06,0.045,1)
    frame.mcfOpaque=t
end


function MCF:RunCommand(msg)
    for _, c in ipairs(self.commands) do
        if c.run and ((c.match and c.match(msg)) or (c.key and c.key == msg)) then
            c.run(msg)
            return true
        end
    end
    return false
end

function MCF:PrintCommandHelp()
    local de = self:GetLanguage() == "deDE"
    local titles = {
        main  = de and "Befehle" or "Commands",
        test  = de and "Testbefehle" or "Test commands",
        debug = de and "Diagnose" or "Diagnostics",
    }
    print("|cff00ccffMyCharForever|r v" .. tostring(self.VERSION or "?"))
    for _, group in ipairs({"main", "test", "debug"}) do
        local header = false
        for _, c in ipairs(self.commands) do
            if c.group == group and not c.hidden then
                if not header then print("|cffffd200" .. titles[group] .. "|r"); header = true end
                print("  |cff66ccff" .. c.usage .. "|r - " .. (de and c.de or c.en))
                if c.example then print("      " .. (de and "z. B. " or "e.g. ") .. c.example) end
            end
        end
    end
end
