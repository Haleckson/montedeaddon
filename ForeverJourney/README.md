# Forever Journey

**Forever Journey** is a personal character journal for **World of Warcraft: Forever**.

Instead of being another statistics dashboard, Forever Journey records the story of your character: places discovered, levels reached, quests completed, professions developed, deaths encountered, personal memories, and other meaningful moments along the way.

## Features

### Overview

A compact summary of your current journey:

- Character portrait, race, class, and level
- Total played time
- Completed quests
- Current money
- Recorded deaths
- Total recorded events
- Chronicle start date
- Recent journey events

### Chronicle

A chronological journal of recorded events.

Events are grouped by date and can include:

- Level ups
- New zone discoveries
- Dungeon and instance entries
- Deaths
- Quest milestones
- Learned professions
- Profession skill milestones
- Manual memories created by the player

Chronicle also supports:

- Favorite stars on memories
- Editing and deleting manual memories
- Multi-select filtering by event type
- Favorites-only filtering
- Combining Favorites with one or more event-type filters

### Manual Memories

You can add your own memories directly from the Chronicle.

A manual memory contains:

- A title
- An optional note
- The current date and time
- The current location

Manual memories can be edited or deleted later. Automatic journey events remain read-only.

### Favorites

Any Chronicle memory can be marked as a favorite.

Favorite state is persistent and is used by:

- The Favorites-only Chronicle filter
- The Memorable Moments section in History

### History

A retrospective view of your character's journey.

Depending on when Forever Journey was installed, History can contain:

- Recovered character state from before the journal started
- First recorded discoveries
- Level milestones
- Quest milestones
- Profession milestones
- Memorable Moments selected with favorite stars
- Journey summary

## Recovered History

Forever Journey does **not** invent historical dates.

If the addon is installed on an existing character, it can recover information that is still available through the game API, such as:

- Current level
- Completed quest count
- Played time
- Money
- Professions

This information is displayed as a recovered snapshot rather than as fabricated historical events.

From the moment Forever Journey starts recording, new events are stored normally in the Chronicle.

If the addon is installed on a new character, the History begins naturally from the start without creating a recovered archive.

## Quest Milestones

Forever Journey records quest milestones every 50 completed quests:

- 50
- 100
- 150
- 200
- and so on

Milestones that were already passed before the addon started recording are not recreated retroactively.

## Profession Tracking

Forever Journey records:

- Newly learned professions
- Profession skill milestones every 75 skill points

Existing professions at the moment the journal starts are treated as part of the character baseline and do not generate fake historical events.

## Death Memories

Deaths are recorded as part of your journey.

When the client exposes additional Death Recap information, Forever Journey can enrich a death memory with details such as:

- Killer
- Ability or spell
- Damage information
- Environmental cause

Supported environmental causes can include:

- Falling
- Drowning
- Fatigue
- Fire
- Lava
- Slime

Available detail depends on the information provided by the game client.

## Minimap Launcher

Forever Journey adds a small journal launcher around the minimap.

- **Left Click** — open or close the journal
- **Drag** — move the launcher around the minimap

The launcher position is saved between sessions.

## Slash Commands

Open or close the journal:

    /fj open

Show available diagnostic commands:

    /fj

Diagnostic commands are primarily intended for troubleshooting and development.

## Saved Data

Forever Journey uses WoW SavedVariables.

Journey data:

- Persists between game sessions
- Is stored separately for each character
- Survives `/reload`
- Survives a full client restart

Manual memories and favorite state are stored together with the rest of the character's memories in schema v3.

## Localization

Currently supported:

- English
- Russian

## Compatibility

Tested with:

- **World of Warcraft: Forever**
- Client: `1.60.1.70170`
- Interface: `16001`

## Version

Current beta:

    0.1.0-beta.3

## Beta Status

Forever Journey is currently in beta.

The current beta focuses on:

- Reliable journey recording
- Persistent character history
- Honest recovered history
- Core quest and profession milestones
- Manual journal memories
- Favorites and Memorable Moments
- Chronicle filtering and navigation
- A complete Overview / Chronicle / History journal experience

## Known Limitations

- Exact chronology from before addon installation cannot be reconstructed when the game API does not expose it.
- Recovered History is therefore a snapshot, not a fabricated timeline.
- Quest milestones already passed before recording begins are not recreated retroactively.
- Existing professions are treated as baseline history.
- Profession milestone tracking begins after the profession baseline has been established.
- Detailed Death Recap information depends on client API availability.
- Previously recorded NPC names are preserved as historical data and may remain in the client language in which they were originally captured.

## Feedback

Forever Journey is an early beta.

Bug reports, compatibility issues, and feedback about the journal experience are welcome.
