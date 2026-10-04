-- Profession skills for SpellbookLevels (account-wide, not per class).
-- Fill this in with /sbl export prof after visiting profession trainers.
-- Fields: name, rank ("" if none), prof (profession name), skill (skill level required),
-- level (character level required, 0 if none), cost (copper).
SBL_PROF = SBL_PROF or {}
SBL_PROF = {
    -- { name = "Example Recipe", rank = "Apprentice", prof = "Blacksmithing", skill = 1, level = 5, cost = 100 },
}
