local _, FLT = ...

-- Dungeon journal registry. Each dungeon lives in its own file under
-- Data\Dungeons\ and registers itself here:
--   FLT.DUNGEON_JOURNAL_DB["Name"] = { level=..., quests={...}, bosses={...} }
-- DungeonData.lua converts these raw tables into FLT.DUNGEONS after all
-- dungeon files are loaded (see the .toc order).
FLT.DUNGEON_JOURNAL_DB = FLT.DUNGEON_JOURNAL_DB or {}
