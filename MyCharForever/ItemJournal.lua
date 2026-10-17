local addonName, MCF = ...
-- Automatic journal entries for good equipment you receive from quests and dungeons
-- (world drops have their own entries in WorldDrops.lua).
--   * Dungeon: Dungeons.lua calls MCF:OnDungeonLootMine(loot, dungeonName) once for every item of the run that is yours.
--   * Quest: an item you "receive" in the chat within a few seconds of turning in a quest is the quest reward.
-- Both create a journal entry (auto = true, source QUEST_REWARD / DUNGEON_LOOT) when the item's quality reaches the
-- setting `itemJournalMinQuality` (default blue). The switch is the setting `itemJournal`.
-- Every number lives in MCF.ItemJournal below.

MCF.ItemJournal = {
  defaultMinQuality = 3, -- blue
  questWindow = 6,       -- seconds: an item received this close to a quest turn-in is its reward
  lootDelay = 1,         -- seconds to wait for the quest event after the loot line (the order is not guaranteed)
  dedupe = 60,           -- seconds: the same item is not journaled twice
}
local IJ = MCF.ItemJournal

local function setting(key, default)
  local s = MyCharForeverDB and MyCharForeverDB.settings
  local v = s and s[key]
  if v == nil then return default end
  return v
end

local function minQuality()
  return tonumber(setting("itemJournalMinQuality", nil)) or IJ.defaultMinQuality
end

local function qualityOf(link)
  local W = MCF.WorldDrops
  return W and W.QualityOf and W.QualityOf(link) or nil
end

-- One journal entry for an item; returns it, or nil when it does not qualify or already exists.
function MCF:AddItemJournal(link, sourceKey, title, detail)
  if not setting("itemJournal", true) then return nil end
  local db = MyCharForeverDB
  if type(db) ~= "table" or type(link) ~= "string" then return nil end
  local quality = qualityOf(link)
  if not quality or quality < minQuality() then return nil end
  db.journal = type(db.journal) == "table" and db.journal or {}
  local now = time()
  for i = #db.journal, 1, -1 do
    local e = db.journal[i]
    if now - (e.time or 0) > IJ.dedupe then break end
    if e.itemLink == link then return nil end
  end
  local mapID, x, y
  if MCF.PlayerPosition then mapID, x, y = MCF.PlayerPosition() end
  local comment, invType
  if self.LootComment then comment, invType = self:LootComment(link, quality) end
  local entry = {
    time = now, level = UnitLevel("player"), mapID = mapID, x = x, y = y,
    zone = GetZoneText(), subZone = GetSubZoneText(),
    title = title, text = (comment and (comment .. "\n") or "") .. (detail and detail ~= "" and (detail .. "\n") or "") .. link,
    auto = true, source = sourceKey, itemID = tonumber(link:match("item:(%d+)")), itemLink = link, quality = quality, invType = invType,
  }
  table.insert(db.journal, entry)
  if self.RefreshMapJourney then self:RefreshMapJourney() end
  if self.RefreshUI then self:RefreshUI() end
  return entry
end

local function itemName(link) return link:match("%[(.-)%]") or "?" end

-- Dungeons.lua: `loot` is one entry of the run's loot list (itemLink, boss, quality ...).
function MCF:OnDungeonLootMine(loot, dungeonName)
  if type(loot) ~= "table" or not loot.itemLink then return end
  local detail
  if dungeonName and dungeonName ~= "" then
    detail = loot.boss and string.format(self:T("Item from %s (%s)"), dungeonName, loot.boss)
      or string.format(self:T("Item from %s"), dungeonName)
  end
  self:AddItemJournal(loot.itemLink, "DUNGEON_LOOT", string.format(self:T("Dungeon loot: %s"), itemName(loot.itemLink)), detail)
end

---------------------------------------------------------------------------
-- Quest rewards
---------------------------------------------------------------------------
local lastQuest -- {time = GetTime(), title = ...}
local pushedPatterns

local function isPushedLine(message)
  if type(message) ~= "string" then return nil end
  if not pushedPatterns then
    pushedPatterns = {}
    for _, key in ipairs({"LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE"}) do
      local pat = MCF.LootFormatPattern and MCF.LootFormatPattern(_G[key])
      if pat then pushedPatterns[#pushedPatterns + 1] = pat end
    end
  end
  for _, pat in ipairs(pushedPatterns) do
    if message:match(pat) then
        -- with the colour code: it carries the quality (MCF.WorldDrops.QualityOf reads it)
        return message:match("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h.-|h|r)") or message:match("(|Hitem:.-|h.-|h)")
      end
  end
  return nil
end
IJ.isPushedLine = isPushedLine

local function questTitle(questID)
  if C_QuestLog and C_QuestLog.GetTitleForQuestID and questID then
    local ok, t = pcall(C_QuestLog.GetTitleForQuestID, questID)
    if ok and type(t) == "string" and t ~= "" then return t end
  end
  return nil
end

local function tryQuestReward(link)
  if not lastQuest or math.abs(GetTime() - lastQuest.time) > IJ.questWindow then return end
  local title = lastQuest.title
  MCF:AddItemJournal(link, "QUEST_REWARD", string.format(MCF:T("Quest reward: %s"), itemName(link)),
    title and string.format(MCF:T("Reward for the quest \"%s\""), title) or nil)
end

local frame = CreateFrame("Frame")
for _, e in ipairs({"QUEST_TURNED_IN", "CHAT_MSG_LOOT"}) do pcall(function() frame:RegisterEvent(e) end) end
frame:SetScript("OnEvent", function(_, event, a1)
  if event == "QUEST_TURNED_IN" then
    lastQuest = {time = GetTime(), title = questTitle(a1)}
  else
    if issecretvalue and issecretvalue(a1) then return end
    local link = isPushedLine(a1)
    if link then
      -- the quest event can come a moment after the loot line
      C_Timer.After(IJ.lootDelay, function() pcall(tryQuestReward, link) end)
    end
  end
end)
