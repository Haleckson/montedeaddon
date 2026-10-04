# Access path reference data

The Access Paths page records historical Classic quest and key routes. A completed
quest or detected item is evidence of that step only. It does not establish that
the Forever Beta currently requires or grants instance entry.

- Dungeon keys, shortcuts, and boss summons: https://www.wowhead.com/classic/guide/classic-wow-attunements-and-keys-dungeons-raids
- Alliance and Horde Onyxia chains: https://www.wowhead.com/classic/guide/onyxia-onyxias-lair-attunement-drakefire-amulet-wow-classic
- Forever dungeon guide and its beta-data caveat: https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location
- Forever quest records are checked by ID where available. Examples: https://www.wowhead.com/forever/quest=4742 and https://www.wowhead.com/forever/quest=4743

Only quests on the historical access/key chain are included. Ordinary dungeon
quests, class quests, raid loot quests, and server-wide events are outside this
page. The game's quest log is authoritative for active progress and map POIs.
Static English titles are display fallbacks when the client does not supply a
title for an unaccepted quest. No historical route is labeled mandatory in
Forever.

Quest giver waypoint coordinates are a small curated set based on the installed
AzerothCompendium quest catalog (`data/quest_chains.lua` and
`data/quest_followups.lua`). Chronicle does not require that addon at runtime.
Naxxramas quest variants 9121–9123 use the Light's Hope Chapel vicinity in
Eastern Plaguelands as an approximate start point; the quest giver is Archmage
Angela Dosantos. These markers show where to begin a step, not its objective.
Steps without reliable coordinates do not get a guessed waypoint.

Quest and item names are requested from the WoW client by ID when they are not
already cached. The client supplies these names in its own language, which can
differ from the language selected for Chronicle's interface. English catalog
names remain as temporary fallbacks if the server has no data for an ID.

The dungeon overview intentionally shows only historically gated wings or upper
sections: Scarlet Monastery Armory/Cathedral, Scholomance, Upper Blackrock Spire,
and Dire Maul North/West. Shortcut keys, alternate entrances and boss summons
are omitted from that overview. This classification follows the Classic
instance-attunement reference at
https://warcraft.wiki.gg/wiki/Instance_attunement_(Classic).
It is not a claim that a personal key is mandatory on the Forever server:
another player or a lockpicker may be able to open a door, and Forever rules
may differ from Classic.

The expandable objective view uses live quest-log objectives and progress for
accepted quests. For other steps, Chronicle includes short English and German
historical summaries paraphrased from Classic quest records at
https://www.wowhead.com/classic/quest=9121 and the corresponding quest-ID pages.
Those summaries are references, not a claim that the Forever server uses
identical objectives. In the other five interface languages, a missing live
objective currently falls back to the English reference summary.
