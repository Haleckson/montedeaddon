# Chronicle Forever 1.5.255

## Interface and character details

- Updated the interface palette throughout Chronicle. Dark surfaces and subtle selection states replace the remaining brown fills, while gold remains an accent for headings, borders, and controls.
- Redesigned profile and collection counters for clearer alignment and easier reading.
- Equipment rows now show up to three item attributes, excluding armor. Missing item data is requested again as it loads, and currently equipped items can use live tooltip data.
- Added melee and spell hit percentages to the character statistics panel.

## Professions

- Clicking a recorded recipe opens its profession window and selects that recipe after the game's recipe list loads.
- Guarded profession event registration against events unavailable in the current game client.

## Level-up notice

- Kept Chronicle's level-up notice fully on screen and suppressed the game's overlapping level display, including delayed frame loading.
