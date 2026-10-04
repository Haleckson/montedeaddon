-- BLib_Data.lua
-- Cross-character inventory and profession data store.
-- Scanning logic, event handling, and query API.
-- Data is stored in BLibDB (declared in BLib.toc).

BLib.Data = {}
local D = BLib.Data

-- C_Container exists on both TBC Anniversary and Mainline. Guarded so a
-- missing namespace degrades instead of erroring at load and taking the whole
-- of BLib.Data down with it. There is deliberately no fallback to the legacy
-- globals: those returned multiple values rather than a table, so falling back
-- would silently produce wrong counts rather than none.
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local HAS_CONTAINER_API    = (GetContainerNumSlots ~= nil and GetContainerItemInfo ~= nil)

-- The bags you carry: the backpack and four bags, and on Mainline the reagent
-- bag after them (Enum.BagIndex.ReagentBag, 5). Reading only 0 to 4 left the
-- reagent bag -- where cloth, leather and herbs go -- out of every count on
-- Forever, and a crafting planner is about little else (2026-09-25).
local LAST_CARRIED_BAG = (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 4

-- The bank. Forever has Mainline's bank of TABS, not TBC's container -1 plus
-- seven bank bags: read from the forever branch of Blizzard's UI source on
-- 2026-09-25, the character's items sit in bank tab containers 6 to 14
-- (Enum.BagIndex.CharacterBankTab_1..9), listed by
-- C_Bank.FetchPurchasedBankTabIDs. There, -1 is the KEYRING and 5 the reagent
-- bag, so the TBC reading counted keys and reagents as banked and never read
-- tabs 7 to 9. TBC's layout stays for a client without tabs.
local TABBED_BANK = (C_Bank and C_Bank.FetchPurchasedBankTabIDs and Enum and Enum.BankType)
    and true or false
local CLASSIC_BANK_CONTAINER = -1
local CLASSIC_FIRST_BANK_BAG = 5
local CLASSIC_LAST_BANK_BAG  = 11

-- Six on TBC; Forever's UI has eight (MAX_GUILDBANK_TABS in its Constants.lua).
-- The guild's own count is asked for first.
local GUILDBANK_SLOTS_PER_TAB = 98

local function GuildBankTabCount()
    if GetNumGuildBankTabs then
        local ok, n = pcall(GetNumGuildBankTabs)
        if ok and tonumber(n) and n > 0 then return n end
    end
    return MAX_GUILDBANK_TABS or 6
end

-- ============================================================
-- HELPERS
-- ============================================================

local function MergeCounts(target, source)
    for itemID, count in pairs(source) do
        target[itemID] = (target[itemID] or 0) + count
    end
end

local function ItemIDFromLink(link)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function GetGuildBankKey()
    local guildName = GetGuildInfo("player")
    if not guildName then return nil end
    return GetRealmName() .. "-" .. guildName
end

-- Forever's UnitName("player") gave "First Surname" as one string until beta
-- build 70009, and the first name and the surname as two values from then on.
-- The key uses the full name either way, so both builds' records match.
local function PlayerName(firstNameOnly)
    local name, surname = UnitName("player")
    if surname and surname ~= "" and not firstNameOnly then
        return name .. " " .. surname
    end
    return name
end

function D:GetPlayerKey()
    return GetRealmName() .. "-" .. PlayerName()
end

-- A record taken out of inventory is kept whole in BLibDB.strandedInventory,
-- under its own key (numbered if that key is there already), where nothing
-- adds it up. Nothing is deleted.
local function SetAside(key)
    local rec = BLibDB.inventory[key]
    if rec == nil then return end
    BLibDB.strandedInventory = BLibDB.strandedInventory or {}
    local aside, slot, n = BLibDB.strandedInventory, key, 1
    while aside[slot] ~= nil do
        n = n + 1
        slot = key .. " #" .. n
    end
    aside[slot] = rec
    BLibDB.inventory[key] = nil
end

-- Until this was fixed, 70009 filed this character under its first name alone.
-- Its bag snapshot is taken again after login, so that one is set aside. Its
-- professions are newer than the full-name record's, so they replace the same
-- professions there.
local function AdoptFirstNameRecord()
    if not (BLibDB and BLibDB.inventory and BLibDB.professions) then return end
    local full  = D:GetPlayerKey()
    local short = GetRealmName() .. "-" .. PlayerName(true)
    if full == short then return end

    SetAside(short)
    local profs = BLibDB.professions[short]
    if profs then
        BLibDB.professions[short] = nil
        BLibDB.professions[full] = BLibDB.professions[full] or {}
        for profName, data in pairs(profs) do
            BLibDB.professions[full][profName] = data
        end
    end
end

-- Every other character played in that window keeps both records until its
-- own next login, and whatever adds up BLibDB.inventory counted it twice:
-- GetAllCounts, and Muster and Satchel, which read the table itself (Muster
-- review M2: 285 Runecloth held, 225 true). So at login a first-name record
-- is set aside whenever a full-name record with the same realm and first
-- name, and not another class, is here too; the full-name one is counted, as
-- the migration above keeps it. Every Forever character has a surname, but
-- first names repeat: of two characters sharing a first name and a class,
-- there is no telling whose the first-name record was, and the full-name
-- record is counted then too. A first-name record with no full-name match is
-- the only record of its character, and stays.
local function SetAsideFirstNameRecords()
    local inventory = BLibDB and BLibDB.inventory
    if type(inventory) ~= "table" then return end
    local stranded = {}
    for short, rec in pairs(inventory) do
        if type(short) == "string" and type(rec) == "table" then
            local prefix = short .. " "
            for key, other in pairs(inventory) do
                if type(key) == "string" and type(other) == "table"
                    and key:sub(1, #prefix) == prefix
                    and (rec.class == nil or other.class == nil or rec.class == other.class) then
                    stranded[#stranded + 1] = short
                    break
                end
            end
        end
    end
    for _, short in ipairs(stranded) do SetAside(short) end
end

-- ============================================================
-- SCANNING
-- ============================================================

local function ScanContainer(bag, results)
    if not HAS_CONTAINER_API then return end
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
        local info = GetContainerItemInfo(bag, slot)
        if info and info.itemID then
            local count = info.stackCount or 1
            results[info.itemID] = (results[info.itemID] or 0) + count
        end
    end
end

function D:ScanBags()
    local results = {}
    for bag = 0, LAST_CARRIED_BAG do
        ScanContainer(bag, results)
    end
    return results
end

-- The containers the character's banked items are in. On Forever, the tabs
-- bought so far; if that list cannot be had, every tab id, since a tab not
-- bought has no slots and adds nothing.
local function BankContainerIDs()
    if TABBED_BANK then
        local ok, ids = pcall(C_Bank.FetchPurchasedBankTabIDs, Enum.BankType.Character)
        if ok and type(ids) == "table" and #ids > 0 then return ids end
        local first = Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1
        local out = {}
        if first then
            for i = 0, 8 do out[#out + 1] = first + i end
        end
        return out
    end

    local out = { CLASSIC_BANK_CONTAINER }
    for bag = CLASSIC_FIRST_BANK_BAG, CLASSIC_LAST_BANK_BAG do out[#out + 1] = bag end
    return out
end

-- The same list, for an addon that moves items out of the bank: Forgemaster's
-- withdraw walked -1 to 11, TBC's bank, which on Forever is the keyring, the
-- reagent bag and six of the nine tabs.
function D:BankContainerIDs()
    return BankContainerIDs()
end

function D:ScanBank()
    local results    = {}
    local stackSizes = {}

    local function ScanContainerWithStacks(bag)
        if not HAS_CONTAINER_API then return end
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local info = GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local count = info.stackCount or 1
                results[info.itemID] = (results[info.itemID] or 0) + count
                -- Track the largest observed stack as a proxy for max stack size
                if count > (stackSizes[info.itemID] or 0) then
                    stackSizes[info.itemID] = count
                end
            end
        end
    end

    for _, bag in ipairs(BankContainerIDs()) do
        ScanContainerWithStacks(bag)
    end

    return results, stackSizes
end

-- For /fm scan: what the bank looks like from here, so a bank that counts
-- nothing can be told from one that was never read.
function D:DescribeBank()
    local ids = BankContainerIDs()
    local slots, items = 0, 0
    for _, bag in ipairs(ids) do
        slots = slots + ((HAS_CONTAINER_API and GetContainerNumSlots(bag)) or 0)
    end
    for _, n in pairs((self:ScanBank())) do items = items + n end
    local account
    if TABBED_BANK and C_Bank.CanViewBank and Enum.BankType.Account then
        local ok, can = pcall(C_Bank.CanViewBank, Enum.BankType.Account)
        account = ok and can or false
    end
    return {
        tabbed = TABBED_BANK, open = self.bankOpen and true or false,
        containers = #ids, slots = slots, items = items, accountViewable = account,
    }
end

-- ============================================================
-- SAVE
-- ============================================================

function D:Save()
    local playerKey  = self:GetPlayerKey()
    local bagCounts  = self:ScanBags()
    local bankCounts = nil
    local hasBank    = false

    local stackSizes = nil
    if self.bankOpen then
        bankCounts, stackSizes = self:ScanBank()
        hasBank    = true
    else
        local existing = BLibDB.inventory[playerKey]
        if existing and existing.bankCounts then
            bankCounts = existing.bankCounts
            hasBank    = existing.hasBank
            stackSizes = existing.stackSizes
        end
    end

    local counts = {}
    MergeCounts(counts, bagCounts)
    if bankCounts then
        MergeCounts(counts, bankCounts)
    end

    local _, className = UnitClass("player")
    local existing = BLibDB.inventory[playerKey]
    local bankTimestamp = (self.bankOpen and time())
        or (existing and existing.bankTimestamp)
        or nil

    local totalBankSlots = existing and existing.totalBankSlots or 0
    if self.bankOpen and HAS_CONTAINER_API then
        totalBankSlots = 0
        for _, bag in ipairs(BankContainerIDs()) do
            totalBankSlots = totalBankSlots + (GetContainerNumSlots(bag) or 0)
        end
    end

    BLibDB.inventory[playerKey] = {
        counts         = counts,
        bagCounts      = bagCounts,
        bankCounts     = bankCounts,
        stackSizes     = stackSizes,
        timestamp      = time(),
        bankTimestamp  = bankTimestamp,
        hasBank        = hasBank,
        class          = className,
        totalBankSlots = totalBankSlots,
    }

    -- Notify registered listeners
    if D.saveListeners then
        for _, fn in ipairs(D.saveListeners) do
            pcall(fn, playerKey, BLibDB.inventory[playerKey])
        end
    end
end

-- ============================================================
-- GUILD BANK SCANNING
-- ============================================================

function D:ScanGuildBank()
    if self.guildScanInProgress then return end
    self.guildScanInProgress = true

    local results    = {}
    local tabsScanned = 0

    local numTabs = GuildBankTabCount()

    local function ScanTab(tab)
        if tab > numTabs then
            local gbKey = GetGuildBankKey()
            if gbKey and tabsScanned > 0 then
                BLibDB.guildBanks[gbKey] = {
                    counts        = results,
                    timestamp     = time(),
                    guildBankTabs = tabsScanned,
                }
            end
            D:Save()
            C_Timer.After(2, function()
                D.guildScanInProgress = false
            end)
            return
        end

        local name, _, isViewable = GetGuildBankTabInfo(tab)
        if isViewable and name and name ~= "" then
            QueryGuildBankTab(tab)
            C_Timer.After(0.5, function()
                for slot = 1, GUILDBANK_SLOTS_PER_TAB do
                    local link = GetGuildBankItemLink(tab, slot)
                    if link then
                        local itemID = ItemIDFromLink(link)
                        local _, count = GetGuildBankItemInfo(tab, slot)
                        if itemID then
                            results[itemID] = (results[itemID] or 0) + (count or 1)
                        end
                    end
                end
                tabsScanned = tabsScanned + 1
                ScanTab(tab + 1)
            end)
        else
            ScanTab(tab + 1)
        end
    end

    ScanTab(1)
end

-- ============================================================
-- LISTENER REGISTRATION
-- Addons can register a function to be called after each Save()
-- e.g. BLib.Data:OnSave(function(playerKey, data) ... end)
-- ============================================================

D.saveListeners = {}

function D:OnSave(fn)
    table.insert(self.saveListeners, fn)
end

-- ============================================================
-- QUERY API
-- ============================================================

function D:GetAllCounts(includeGuildBank, excludedGuildBanks)
    local combined = {}
    for _, charData in pairs(BLibDB.inventory) do
        if charData.counts then
            MergeCounts(combined, charData.counts)
        end
    end
    if includeGuildBank then
        excludedGuildBanks = excludedGuildBanks or {}
        for gbKey, gbData in pairs(BLibDB.guildBanks) do
            if not excludedGuildBanks[gbKey] and gbData.counts then
                MergeCounts(combined, gbData.counts)
            end
        end
    end
    return combined
end

function D:GetCount(itemID, includeGuildBank, excludedGuildBanks)
    return self:GetAllCounts(includeGuildBank, excludedGuildBanks)[itemID] or 0
end

function D:GetBagCounts(playerKey)
    playerKey = playerKey or self:GetPlayerKey()
    local data = BLibDB.inventory[playerKey]
    return data and data.bagCounts or {}
end

function D:GetBankCounts(playerKey)
    playerKey = playerKey or self:GetPlayerKey()
    local data = BLibDB.inventory[playerKey]
    return data and data.bankCounts or {}
end

function D:GetCharSummary()
    local summary = {}
    for key, data in pairs(BLibDB.inventory) do
        table.insert(summary, {
            key       = key,
            timestamp = data.timestamp,
            hasBank   = data.hasBank,
            class     = data.class,
            isGuild   = false,
        })
    end
    for key, data in pairs(BLibDB.guildBanks) do
        table.insert(summary, {
            key           = key,
            timestamp     = data.timestamp,
            guildBankTabs = data.guildBankTabs,
            isGuild       = true,
        })
    end
    return summary
end

function D:GetProfData(charKey, profName)
    charKey = charKey or self:GetPlayerKey()
    if not BLibDB.professions[charKey] then return nil end
    return BLibDB.professions[charKey][profName]
end

function D:GetCharProfessions(charKey)
    charKey = charKey or self:GetPlayerKey()
    local result = {}
    if not BLibDB.professions[charKey] then return result end
    for profName, data in pairs(BLibDB.professions[charKey]) do
        table.insert(result, {
            name     = profName,
            skill    = data.skill,
            maxSkill = data.maxSkill,
            spec     = data.spec,
        })
    end
    return result
end

-- ============================================================
-- EVENTS
-- ============================================================

local dataFrame = CreateFrame("Frame")

-- pcall'd, so an event one client lacks cannot stop the rest registering.
local function Register(event)
    pcall(dataFrame.RegisterEvent, dataFrame, event)
end

Register("PLAYER_LOGIN")
Register("BAG_UPDATE")
Register("PLAYER_LOGOUT")
Register("MAIL_SEND_SUCCESS")
Register("BANKFRAME_OPENED")
Register("BANKFRAME_CLOSED")
Register("PLAYERBANKSLOTS_CHANGED")
Register("GUILDBANKFRAME_OPENED")
Register("GUILDBANKFRAME_CLOSED")
Register("GUILDBANKBAGSLOTS_CHANGED")
-- Mainline opens the bank and the guild bank through the interaction manager.
-- BANKFRAME_OPENED is still documented on Forever and Blizzard's own code
-- still listens for it, but the interaction events are what its bank frame is
-- built on, so both are heard and either one opens.
Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

local interaction = Enum and Enum.PlayerInteractionType or {}
local BANKER_TYPES = {}
for _, name in ipairs({ "Banker", "CharacterBanker", "AccountBanker" }) do
    if interaction[name] then BANKER_TYPES[interaction[name]] = true end
end
local GUILD_BANKER_TYPE = interaction.GuildBanker

local function OpenBank()
    if D.bankOpen then return end
    D.bankOpen = true
    D:Save()
end

local function CloseBank()
    if not D.bankOpen then return end
    D:Save()  -- still open, so this last save takes the bank with it
    D.bankOpen = false
end

-- Items moved while the bank is open: saved two seconds after the last move.
-- On Forever a move into or out of a bank tab is a BAG_UPDATE for that tab,
-- not the PLAYERBANKSLOTS_CHANGED the old bank raised.
local function SaveBankSoon()
    if D.pendingBankSave then return end
    D.pendingBankSave = true
    C_Timer.After(2, function()
        D.pendingBankSave = false
        if D.bankOpen then D:Save() end
    end)
end

dataFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        AdoptFirstNameRecord()
        SetAsideFirstNameRecords()
        C_Timer.After(10, function()
            D.loginComplete = true
            D.lastSave = time()
            D:Save()
        end)

    elseif event == "BAG_UPDATE" then
        if not D.loginComplete then return end
        if D.bankOpen then
            SaveBankSoon()
            return
        end
        -- At most one save every 30 seconds, but a change inside that window
        -- is saved when it ends, not dropped: dropping it lost 11 Light
        -- Leather mailed to an alt, the sender's record still showing them
        -- (2026-09-27).
        if D.pendingSave then return end
        local now = time()
        local wait = 2
        if D.lastSave and (now - D.lastSave) < 30 then wait = math.max(2, 30 - (now - D.lastSave)) end
        D.pendingSave = true
        C_Timer.After(wait, function()
            D.pendingSave = false
            D.lastSave = time()
            D:Save()
        end)

    -- Mail that went out took its attachments for good: saved at once, past
    -- the throttle, so an alt's count cannot go on showing what it sent.
    elseif event == "MAIL_SEND_SUCCESS" then
        if D.loginComplete then
            D.lastSave = time()
            D:Save()
        end

    -- The last word on the bags, whatever the throttle above is waiting for:
    -- SavedVariables are written after this event.
    elseif event == "PLAYER_LOGOUT" then
        if D.loginComplete then D:Save() end

    elseif event == "BANKFRAME_OPENED" then
        OpenBank()

    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        if D.bankOpen then SaveBankSoon() end

    elseif event == "BANKFRAME_CLOSED" then
        CloseBank()

    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW"
        or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local kind = ...
        local shown = event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW"
        if BANKER_TYPES[kind] then
            if shown then OpenBank() else CloseBank() end
        elseif kind and kind == GUILD_BANKER_TYPE then
            D.guildBankOpen = shown
            if not shown then D.guildScanInProgress = false end
        end

    elseif event == "GUILDBANKFRAME_OPENED" then
        D.guildBankOpen = true

    elseif event == "GUILDBANKFRAME_CLOSED" then
        D.guildBankOpen = false
        D.guildScanInProgress = false

    elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
        D:ScanGuildBank()
    end
end)