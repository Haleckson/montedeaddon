-- Config.lua
local ADDON_NAME, FieldJournal = ...
FieldJournal = FieldJournal or {}
FieldJournal.Config = FieldJournal.Config or {}

FieldJournalDB = FieldJournalDB or {}
FieldJournalDB.config = FieldJournalDB.config or {}

-- Debug output is disabled by default for normal players.
-- The saved setting is per-character, matching the rest of FieldJournalDB.
if FieldJournalDB.config.debug == nil then
    FieldJournalDB.config.debug = false
end

FieldJournal.Config.debug = FieldJournalDB.config.debug

local DEFAULT_JOURNAL_SCALE = 1.2

function FieldJournal.Config:GetJournalScale()
    local scale = tonumber(FieldJournalDB.config.journalScale)
    if scale and scale >= 0.8 and scale <= 1.6 then return scale end
    return DEFAULT_JOURNAL_SCALE
end

function FieldJournal.Config:SetJournalScale(scale)
    scale = tonumber(scale)
    if not scale or scale ~= scale or scale < 0.8 or scale > 1.6 then return nil end

    FieldJournalDB.config.journalScale = scale
    return scale
end

function FieldJournal.Config:SetDebug(enabled)
    enabled = enabled and true or false

    FieldJournalDB = FieldJournalDB or {}
    FieldJournalDB.config = FieldJournalDB.config or {}
    FieldJournalDB.config.debug = enabled
    self.debug = enabled

    return enabled
end
