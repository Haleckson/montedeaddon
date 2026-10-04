local _, A = ...
A.byQuest, A.byItem = {}, {}
for _, book in ipairs(A.books) do
    A.byQuest[book.quest], A.byItem[book.item] = book, book
end

function A.Done(id)
    local fn = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted
    if fn then
        local ok, done = pcall(fn, id)
        return ok and done == true
    end
    return false
end

function A.ItemCount(id, includeBank)
    local fn = C_Item and C_Item.GetItemCount or GetItemCount
    if fn then
        local ok, count = pcall(fn, id, includeBank == true)
        if ok and type(count) == "number" then return count end
    end
    return 0
end

function A.Status(book)
    if A.db.turned[book.quest] then return "Returned" end
    if A.ItemCount(book.item) > 0 then return "Carried" end
    if A.db.looted[book.quest] then return "Looted" end
    if A.db.manual[book.quest] then return "Marked" end
    return "Missing"
end

function A.Zone(map)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
    return info and info.name or ("Map " .. map)
end

function A.Name(book)
    local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
    local name = fn and fn(book.item)
    return name or book.name
end

function A.Counts()
    local found, returned, carried = 0, 0, 0
    for _, book in ipairs(A.books) do
        local status = A.Status(book)
        if status ~= "Missing" then found = found + 1 end
        if status == "Returned" then returned = returned + 1 end
        if status == "Carried" then carried = carried + 1 end
    end
    return found, returned, carried
end

function A.ToggleTrack(book)
    if A.Status(book) == "Returned" then return end
    A.db.tracked[book.quest] = not A.db.tracked[book.quest] or nil
    A.Refresh()
end

function A.Refresh()
    if not A.db then return end
    if A.RefreshUI then A.RefreshUI() end
    if A.RefreshTracker then A.RefreshTracker() end
    if A.frame and A.rewardsFrame and A.ApplyTheme then A.ApplyTheme() end
    if A.provider then A.provider:RefreshAllData() end
end

-- Suggestions concern the pickup itself; travel can still be dangerous at low level.
local easy = {
    [79092]={faction="Alliance", note="A friendly tower with no fight required for Alliance."},
    [79091]={faction="Alliance", note="Inside friendly Ironforge. Horde must pass enemy guards."},
    [79093]={faction="Alliance", note="An inn pickup. Horde should use Westfall and watch the guards."},
    [79095]={faction="Horde", note="Inside friendly Brill. Alliance face hostile guards."},
    [79094]={faction="Horde", note="Inside friendly Orgrimmar. Alliance face hostile guards."},
    [79097]={note="Ratchet is neutral; the book is beside Gazlowe."},
}
local lowLevel = {
    [78142]="Moonbrook has low-level enemies; clear the house before collecting.",
    [78124]="Ruins of Mathystra may require killing nearby enemies.",
    [78149]="Grimtotem Post has enemies around the tent; suitable around level 20.",
    [78145]="Climb the Sludge Fen oil rig. Watch nearby enemies on the approach.",
}
function A.Advice(book)
    if book.uncertain then return "Unknown", "No confirmed Forever location." end
    local entry=easy[book.quest]
    if entry and (not entry.faction or entry.faction == UnitFactionGroup("player")) then
        return "Easy pickup", entry.note .. " Suggested first; travel safety depends on your route."
    end
    if entry then return "Enemy territory", entry.note end
    if lowLevel[book.quest] then return "Low-level option", lowLevel[book.quest] end
    return "Plan carefully", "Higher-level enemies or difficult access may require help, combat or corpse runs."
end

local zoneLevels = {
    [1429]=5,[1455]=1,[1436]=10,[1432]=10,[1420]=5,[1421]=10,
    [1431]=20,[1437]=20,[1417]=30,[1416]=30,[1434]=30,[1435]=35,
    [1418]=35,[1427]=45,[1425]=45,[1428]=50,[1419]=45,[1423]=55,
    [1422]=50,[1439]=12,[1454]=1,[1413]=12,[1442]=18,[1445]=35,
    [1443]=30,[1441]=25,[1444]=40,[1446]=45,[1447]=45,[1452]=55,[1448]=50,
}
local guarded = {[78148]=true,[79949]=true,[79950]=true,[79952]=true,[79953]=true,[81955]=true,[84401]=true}
function A.Difficulty(book)
    if book.quest==0 then return "Easy",0.2,0.85,0.35 end
    if book.uncertain then return "Unknown",1,0.25,0.25 end
    if book.dungeon then return "Hard",0.95,0.16,0.16 end
    local advice=A.Advice(book)
    if advice=="Enemy territory" then return "Hard",0.95,0.16,0.16 end
    if advice=="Easy pickup" then return "Easy",0.2,0.85,0.35 end
    local level=UnitLevel and UnitLevel("player") or 20
    local zoneLevel=zoneLevels[book.map] or 50
    if level < zoneLevel-5 or (guarded[book.quest] and level < zoneLevel+10) then
        return "Hard",0.95,0.16,0.16
    end
    return "Medium",1,0.78,0.15
end

function A.RewardDone(reward)
    if A.db.rewardDone and A.db.rewardDone[reward.count] then return true end
    return A.Done(reward.quest)
end

function A.Scan()
    for _, book in ipairs(A.books) do
        if A.Done(book.quest) then A.db.turned[book.quest] = true end
        if A.ItemCount(book.item, true) > 0 then A.db.looted[book.quest] = true end
        if A.db.turned[book.quest] then A.db.tracked[book.quest] = nil end
    end
    A.Refresh()
end

function A.QueueScan()
    if A.scanPending then return end
    A.scanPending = true
    C_Timer.After(0.2, function()
        A.scanPending = nil
        if A.db then A.Scan() end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, ...)
    local arg1, arg2 = ...
    if event == "ADDON_LOADED" then
        if arg1 == "ForeverLibrary" then
            ForeverLibraryDB = ForeverLibraryDB or {}
            A.db = ForeverLibraryDB
            for _, key in ipairs({"turned", "looted", "tracked", "manual", "rewardDone"}) do
                if type(A.db[key]) ~= "table" then A.db[key] = {} end
            end
            if A.db.showTracker == nil then A.db.showTracker = true end
            if A.db.showPins == nil then A.db.showPins = true end
            for _, name in ipairs({"PLAYER_LOGIN", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "CHAT_MSG_LOOT", "GET_ITEM_INFO_RECEIVED"}) do
                events:RegisterEvent(name)
            end
            SLASH_FOREVERLIBRARY1, SLASH_FOREVERLIBRARY2 = "/books", "/flibrary"
            SlashCmdList.FOREVERLIBRARY = function(msg)
                if msg == "tracker" then A.db.showTracker = not A.db.showTracker; A.Refresh()
                elseif msg == "minimap" then A.ToggleMinimapButton()
                elseif msg == "nav" then LibraryScoutNavigateTracker()
                else A.ToggleWindow() end
            end
            if IsLoggedIn and IsLoggedIn() then A.Scan() end
        elseif arg1 == "Blizzard_WorldMap" and A.db and A.InstallMaps then A.InstallMaps() end
    elseif event == "PLAYER_LOGIN" then
        A.BuildUI()
        A.CreateMinimapButton()
        A.InstallMaps()
        A.Scan()
        if A.RegisterSettings then A.RegisterSettings() end
    elseif event == "QUEST_TURNED_IN" then
        if A.byQuest[arg1] then A.db.turned[arg1],A.db.looted[arg1],A.db.tracked[arg1]=true,true,nil end
        if arg1==78150 then A.db.rewardDone[10]=true end
        if arg1==79536 then A.db.rewardDone[20]=true end
        A.QueueScan()
    elseif event == "CHAT_MSG_LOOT" then
        -- Only self-loot messages count: another party member's link is not evidence.
        local id = tonumber((arg1 or ""):match("item:(%d+)"))
        if id and A.byItem[id] then
            for _, formatString in ipairs({LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE, LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_PUSHED_SELF_MULTIPLE}) do
                local prefix = formatString and formatString:match("^(.-)%%s")
                if prefix and (arg1 or ""):sub(1, #prefix) == prefix then
                    A.db.looted[A.byItem[id].quest] = true
                    break
                end
            end
        end
        A.QueueScan()
    else A.QueueScan() end
end)
