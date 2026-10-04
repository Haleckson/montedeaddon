-- LibItemDB-1.0 — the Auction House scanner (MINOR 25)
--
-- MOVED HERE FROM TOGProfessionMaster (Modules/AHScanner.lua) on 2026-09-14, so the library's own
-- price source (Price/Sources.lua, source id "scan") is self-sufficient on a machine with no
-- third-party price addon installed. Two scans, one store:
--
--   FULL SCAN — one server-side "scan everything" pass that prices every item on the AH at its
--   lowest per-UNIT buyout and writes the result into the realm + faction store. Legacy clients
--   (Era / TBC / Wrath) use `QueryAuctionItems(..., getAll=true)`, which the server throttles to
--   roughly once per 15 minutes PER CLIENT — a budget shared with every other AH addon, which is
--   why auto-scan is opt-in. Modern clients (Cata / MoP) use `C_AuctionHouse.ReplicateItems()`.
--   The returned list is processed in 500-row batches across frames so a multi-thousand-row scan
--   does not hitch.
--
--   TARGETED SCAN — a throttled per-item pass: one browse query per named item, waiting for the
--   result, then the next after the configured delay. For a consumer that wants listings for a
--   short list now (a crafting tab's reagents) rather than the whole house. Results live only for
--   the AH session and are read back with GetScanListings.
--
-- THE ONE PIECE OF ARITHMETIC THAT MATTERS is `ceil(buyout / count)`: an auction is a STACK, and a
-- scanner that compares raw buyouts prices a stack of 20 at twenty times its worth, silently, with
-- every craft in a consumer's profit view then reading as a loss. The cheapest LISTING is not the
-- cheapest ITEM. Pinned by Tests/pricescan_spec.lua.
--
-- Everything the client hands us is feature-detected at call time: `C_AuctionHouse` decides the
-- modern path, and the legacy globals are only touched on the legacy one.

local MAJOR = "LibItemDB-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib or not lib._PriceStore then return end

-- Internal scan state, on the library so the window and the specs can read it. Every field is
-- reset by the same code paths that reset TOGPM's `addon.AH._*` fields.
local S = lib.scan or {}
lib.scan = S

-- Cata Classic, MoP Classic and Retail use the modern C_AuctionHouse API behind AuctionHouseFrame;
-- Vanilla / TBC / Wrath Classic use the legacy AuctionFrame + QueryAuctionItems path. Detected
-- from the API rather than from a version flag, so a backport keeps working.
S.isModernAH = C_AuctionHouse ~= nil
    and type(C_AuctionHouse.SendSearchQuery) == "function"
    and type(C_AuctionHouse.MakeItemKey) == "function"

S.isOpen        = S.isOpen        or false
S.scanning      = S.scanning      or false   -- a targeted scan is running
S.fullScanning  = S.fullScanning  or false   -- a full scan is running
S.fullPending   = S.fullPending   or false   -- modern: ReplicateItems sent, list not yet arrived
S.queue         = S.queue         or {}
S.results       = S.results       or {}      -- targeted: [itemID] = { listings, lowestBuyout, count, scannedAt }
S.fullSeen      = S.fullSeen      or nil     -- full: [itemID] = { count, lowestBuyout, scannedAt }
S.currentItem   = S.currentItem   or nil
S.totalItems    = S.totalItems    or 0
S.scannedItems  = S.scannedItems  or 0
S.opts          = S.opts          or nil
S.lastFullScanAt = S.lastFullScanAt or nil  -- modern self-throttle (legacy asks CanSendAuctionQuery)

local FULL_BATCH   = 500
local FULL_COOLDOWN = 15 * 60

local function after(seconds, fn)
    if C_Timer and C_Timer.After then C_Timer.After(seconds, fn) else fn() end
end

-- Every targeted scan gets a generation number, and every timer the scan arms carries it. A timer
-- from a FINISHED scan then does nothing when it fires. Without this, a scan cancelled by the AH
-- closing leaves its "next item" timer armed (C_Timer.After cannot be cancelled), and if the
-- player reopens the house and starts another scan inside that delay, the stale timer advances
-- the NEW scan -- popping its next item early, or finishing it with "0 of 0 items" while its first
-- query is still in flight. TOGPM's scanner had the same hole through AceTimer; found by this
-- library's own suite, where one example's leftover timer drained the next example's queue.
S.generation = S.generation or 0

local function afterInScan(seconds, fn)
    local gen = S.generation
    after(seconds, function()
        if S.generation == gen then fn() end
    end)
end

local function getItemInfo(itemID)
    local fn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if type(fn) ~= "function" then return nil end
    return fn(itemID)
end

local function isVanilla()
    return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

-- ---------------------------------------------------------------------------
-- Scan delay
-- ---------------------------------------------------------------------------
--- Seconds between targeted-scan queries. The account's `scanDelay` when set; otherwise this
--- client's default — 1.5s on Classic Era, where the server throttle is loose, 3.0s everywhere
--- else, where it is stricter. Independent of this floor every legacy query is also gated on
--- CanSendAuctionQuery() with a 0.5s retry, so a too-short delay stalls rather than drops.
function lib:GetEffectiveScanDelay()
    local override = self:_PriceSettings().scanDelay
    if type(override) == "number" and override > 0 then return override end
    return isVanilla() and 1.5 or 3.0
end

-- ---------------------------------------------------------------------------
-- The scan button on the AH frame
-- ---------------------------------------------------------------------------
local function idleText() return "|cffFF8000ItemDB|r Scan" end

function lib:_UpdateScanButton()
    local b = S.scanBtn
    if not b then return end
    if S.scanning or S.fullScanning then
        b:SetText("Scanning...")
        b:Disable()
        return
    end
    b:SetText(idleText())
    if self:IsAuctionHouseOpen() then b:Enable() else b:Disable() end
end

local function showScanButton(frame)
    if not frame then return end
    local b = S.scanBtn
    if not b then
        b = CreateFrame("Button", "LibItemDBScanButton", frame, "UIPanelButtonTemplate")
        b:SetSize(92, 18)
        b:SetScript("OnClick", function()
            if S.fullScanning or S.scanning then return end
            lib:StartFullScan(false)
            lib:_UpdateScanButton()
        end)
        b:SetScript("OnEnter", function(btn)
            if not GameTooltip then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(idleText(), 1, 1, 1, 1, true)
            GameTooltip:AddLine("Scan the whole Auction House to refresh LibItemDB's own price store.", 0.9, 0.9, 0.9, true)
            GameTooltip:AddLine("Independent of auto-scan: this is a manual one-click scan.", 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        S.scanBtn = b
    end
    b:SetParent(frame)
    b:ClearAllPoints()
    -- The modern AuctionHouseFrame (Mists, Forever) is a PortraitFrameTemplate: its title bar is a
    -- 20-high TitleContainer starting right of the portrait (SharedUIPanelTemplates.xml, forever
    -- tree, TOPLEFT x=58 y=-1). The legacy offset below put the button half under that bar, over
    -- the Browse pane. Centre it in the bar instead; the legacy AuctionFrame has no TitleContainer.
    local title = frame.TitleContainer
    if title then
        b:SetPoint("LEFT", title, "LEFT", 4, 0)
    else
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -15)
    end
    b:SetFrameStrata("HIGH")
    b:Show()
    lib:_UpdateScanButton()
end

S.hookedFrames = S.hookedFrames or {}
local function ensureScanButtonHook()
    for _, name in ipairs({ "AuctionFrame", "AuctionHouseFrame" }) do
        local frame = _G[name]
        if frame and not S.hookedFrames[frame] then
            S.hookedFrames[frame] = true
            frame:HookScript("OnShow", function() showScanButton(frame) end)
            if frame:IsShown() then showScanButton(frame) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Open state
-- ---------------------------------------------------------------------------
--- True while the auction house frame is showing. Events set the flag; the frame is also read
--- directly in case a consumer asks before the first event.
function lib:IsAuctionHouseOpen()
    if S.isOpen then return true end
    if S.isModernAH then
        return AuctionHouseFrame ~= nil and AuctionHouseFrame:IsShown() == true
    end
    return AuctionFrame ~= nil and AuctionFrame:IsShown() == true
end

--- Switch the open auction house to Browse, put `itemName` in the search field and fire the
--- search — the user then sees the live results and acts on them. No aggregation, no buyout.
--- @return boolean fired false when the AH is closed or the name is not a string
function lib:AuctionHouseSearch(itemName)
    if type(itemName) ~= "string" or itemName == "" then return false end
    if not self:IsAuctionHouseOpen() then return false end

    if S.isModernAH then
        local sb = AuctionHouseFrame and AuctionHouseFrame.SearchBar
        if sb then
            if sb.SetSearchText then sb:SetSearchText(itemName)
            elseif sb.SearchBox and sb.SearchBox.SetText then sb.SearchBox:SetText(itemName) end
            if sb.StartSearch then sb:StartSearch()
            elseif sb.OnEnterPressed then sb:OnEnterPressed() end
        end
        return true
    end

    if AuctionFrameTab1 and AuctionFrameTab1.Click then AuctionFrameTab1:Click() end
    if BrowseName and BrowseName.SetText then BrowseName:SetText(itemName) end
    -- Reset the secondary filters so a previous narrow search cannot hide the item.
    if BrowseMinLevel and BrowseMinLevel.SetText then BrowseMinLevel:SetText("") end
    if BrowseMaxLevel and BrowseMaxLevel.SetText then BrowseMaxLevel:SetText("") end
    if IsUsableCheckButton and IsUsableCheckButton.SetChecked then IsUsableCheckButton:SetChecked(false) end
    if ShowOnPlayerCheckButton and ShowOnPlayerCheckButton.SetChecked then ShowOnPlayerCheckButton:SetChecked(false) end
    if BrowseDropDown and UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(BrowseDropDown, -1) end
    if AuctionFrameBrowse_Search then AuctionFrameBrowse_Search()
    elseif BrowseSearchButton and BrowseSearchButton.Click then BrowseSearchButton:Click() end
    return true
end

-- ---------------------------------------------------------------------------
-- Targeted scan
-- ---------------------------------------------------------------------------
--- Scan a list of items, one browse query each. `items` is an array of `{ itemId, itemName }`
--- (the legacy API queries by NAME; an entry with no string name is skipped, and repeats are
--- queried once). `opts.onProgress(scanned, total, item)` fires before each query;
--- `opts.onComplete(reason, results)` when the queue drains, the scan is cancelled, or the AH
--- closes. The library also fires LibItemDB_ScanProgress / LibItemDB_ScanComplete("targeted").
--- @return boolean started
--- @return string|nil reason "scan-in-progress" | "full-scan-in-progress" | "ah-closed" | "no-items"
function lib:StartTargetedScan(items, opts)
    if S.scanning     then return false, "scan-in-progress" end
    if S.fullScanning then return false, "full-scan-in-progress" end
    if not self:IsAuctionHouseOpen() then return false, "ah-closed" end
    if type(items) ~= "table" or #items == 0 then return false, "no-items" end

    S.generation   = S.generation + 1
    S.scanning     = true
    S.queue        = {}
    S.results      = {}
    S.opts         = opts or {}
    S.scannedItems = 0
    self:_UpdateScanButton()

    local seen = {}
    for _, item in ipairs(items) do
        local id, name = item.itemId, item.itemName
        if id and type(name) == "string" and name ~= "" and not seen[id] then
            seen[id] = true
            S.queue[#S.queue + 1] = { itemId = id, itemName = name }
        end
    end
    S.totalItems = #S.queue

    if S.totalItems == 0 then
        S.scanning = false
        self:_UpdateScanButton()
        return false, "no-items"
    end

    self:_PricePrint(("Scanning %d item(s)..."):format(S.totalItems))
    S._scanNext()
    return true
end

--- Internal: pop the next queued item and query it.
function S._scanNext()
    if not S.scanning then return end
    if not lib:IsAuctionHouseOpen() then
        S._finishScan("ah-closed")
        return
    end

    local nextItem = table.remove(S.queue, 1)
    if not nextItem then
        S._finishScan("complete")
        return
    end

    S.currentItem = nextItem
    if S.opts and S.opts.onProgress then
        pcall(S.opts.onProgress, S.scannedItems, S.totalItems, nextItem)
    end
    lib:_PriceFire("LibItemDB_ScanProgress", "targeted", S.scannedItems, S.totalItems, nextItem)

    if S.isModernAH then
        -- The modern search returns empty for an item the client has not cached; force the fetch
        -- and retry shortly.
        if not getItemInfo(nextItem.itemId) then
            table.insert(S.queue, 1, nextItem)
            S.currentItem = nil
            afterInScan(0.5, S._scanNext)
            return
        end
        local itemKey = C_AuctionHouse.MakeItemKey(nextItem.itemId)
        S.currentItemKey = itemKey
        C_AuctionHouse.SendSearchQuery(itemKey, {}, false)
        -- Safety: if neither result event fires, treat as empty and advance.
        local thisItemId = nextItem.itemId
        afterInScan(lib:GetEffectiveScanDelay() + 5, function()
            if S.scanning and S.currentItem and S.currentItem.itemId == thisItemId then
                S._completeCurrentItem({})
            end
        end)
        return
    end

    -- Legacy: a rejected query fires no AUCTION_ITEM_LIST_UPDATE, which would stall the scan
    -- forever, so every query is gated on the client's own "may I?" with a short retry.
    if CanSendAuctionQuery and not CanSendAuctionQuery() then
        table.insert(S.queue, 1, nextItem)
        S.currentItem = nil
        afterInScan(0.5, S._scanNext)
        return
    end
    -- exactMatch=false: some Classic builds return an empty set for an exact query even when
    -- listings exist; the collector filters by name + id anyway.
    QueryAuctionItems(nextItem.itemName, nil, nil, 0, 0, 0, false, false, false, false)
end

--- Internal: store the collected listings for the current item and schedule the next query.
function S._completeCurrentItem(listings)
    if not S.scanning or not S.currentItem then return end
    local current = S.currentItem
    local lowestBuyout
    for _, l in ipairs(listings) do
        local b = l.buyoutPrice
        if b and b > 0 and (not lowestBuyout or b < lowestBuyout) then lowestBuyout = b end
    end
    if current.itemId then
        S.results[current.itemId] = {
            listings     = listings,
            lowestBuyout = lowestBuyout,
            count        = #listings,
            scannedAt    = lib:_PriceNow(),
        }
    end
    S.scannedItems   = S.scannedItems + 1
    S.currentItem    = nil
    S.currentItemKey = nil
    afterInScan(lib:GetEffectiveScanDelay(), S._scanNext)
end

--- Internal: finalise a targeted scan and tell everyone.
function S._finishScan(reason)
    S.generation     = S.generation + 1   -- any timer this scan still has armed is now inert
    S.scanning       = false
    S.currentItem    = nil
    S.currentItemKey = nil
    lib:_UpdateScanButton()

    local found = 0
    for _, r in pairs(S.results) do
        if r.count and r.count > 0 then found = found + 1 end
    end
    lib:_PricePrint(("Scan %s: %d of %d item(s) have listings."):format(
        reason or "complete", found, S.scannedItems or 0))

    -- A targeted scan's lowest buyouts go into the store too: they are the freshest number the
    -- library has for those items, and the full scan writes the same shape.
    for itemId, r in pairs(S.results) do
        if r.lowestBuyout then lib:StoreScannedPrice(itemId, r.lowestBuyout, r.count) end
    end

    if S.opts and S.opts.onComplete then pcall(S.opts.onComplete, reason or "complete", S.results) end
    S.opts = nil
    lib:_PriceFire("LibItemDB_ScanComplete", "targeted", reason or "complete", S.results)
end

--- Cancel a running targeted scan. Safe to call when none is running.
function lib:CancelScan()
    if not S.scanning then return end
    S.queue = {}
    S._finishScan("cancelled")
end

--- The targeted-scan result for an item this AH session, or the full scan's record for it while
--- the AH is open, or nil. Shape: `{ listings?, lowestBuyout, count, scannedAt }`; `count == 0`
--- means the scan ran and found no listings, which is a different fact from never having looked.
function lib:GetScanListings(itemID)
    return S.results[itemID]
        or (self:IsAuctionHouseOpen() and S.fullSeen and S.fullSeen[itemID])
        or nil
end

--- Forget this session's targeted results (the AH closing does this itself).
function lib:ClearScanResults() S.results = {} end

-- ---------------------------------------------------------------------------
-- Full scan
-- ---------------------------------------------------------------------------
-- Dedicated frame for the legacy getAll. During a scan EVERY other frame registered for
-- AUCTION_ITEM_LIST_UPDATE (Blizzard's AH UI, other addons) is silenced so only this frame receives
-- the getAll payload — a competing browse query's event can then never make us process a partial
-- or wrong result set. The frames are restored when the scan ends. Auctionator's FullScan pattern.
local fullScanFrame = S.fullScanFrame or CreateFrame("Frame")
S.fullScanFrame = fullScanFrame
local FULL_SCAN_EVENTS = { "AUCTION_ITEM_LIST_UPDATE", "AUCTION_HOUSE_CLOSED" }

local function fullRegisterEvents()
    S.otherFrames = { GetFramesRegisteredForEvent("AUCTION_ITEM_LIST_UPDATE") }
    for _, f in ipairs(S.otherFrames) do f:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE") end
    FrameUtil.RegisterFrameForEvents(fullScanFrame, FULL_SCAN_EVENTS)
    S.fullEventsRegistered = true
end

-- Only undo what fullRegisterEvents did. The modern (ReplicateItems) scan never registers, and on
-- that client AUCTION_ITEM_LIST_UPDATE does not exist at all: unregistering it raises "Attempt to
-- unregister unknown event" (operator, Forever), which aborted fullStore before a single price was
-- stored -- so every modern full scan was thrown away.
local function fullUnregisterEvents()
    if S.fullEventsRegistered and FrameUtil and FrameUtil.UnregisterFrameForEvents then
        FrameUtil.UnregisterFrameForEvents(fullScanFrame, FULL_SCAN_EVENTS)
    end
    S.fullEventsRegistered = nil
    if S.otherFrames then
        for _, f in ipairs(S.otherFrames) do f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE") end
        S.otherFrames = nil
    end
end

local function fullStore()
    fullUnregisterEvents()
    local n = 0
    local at = lib:_PriceNow()
    S.lastFullScanAt = at
    if S.fullSeen then
        for itemId, rec in pairs(S.fullSeen) do
            rec.scannedAt = at
            if rec.lowestBuyout and lib:StoreScannedPrice(itemId, rec.lowestBuyout, rec.count) then
                n = n + 1
            end
        end
    end
    lib:_PriceRecordScan(n)
    -- S.fullSeen is kept for the AH session so GetScanListings can answer from it; only the flags
    -- reset here.
    S.fullScanning = false
    S.fullPending  = false
    lib:_UpdateScanButton()
    lib:_PricePrint(("Full scan complete -- priced %d item(s)."):format(n))
    lib:_PriceFire("LibItemDB_ScanComplete", "full", "complete", S.fullSeen)
end

-- Fold one listing into the per-item record: per-UNIT price, cheapest kept.
local function fullSee(itemId, buyout, count)
    if itemId and buyout and buyout > 0 and count and count > 0 then
        local unit = math.ceil(buyout / count)
        local rec  = S.fullSeen[itemId]
        if not rec then rec = { count = 0 }; S.fullSeen[itemId] = rec end
        rec.count = rec.count + 1
        if not rec.lowestBuyout or unit < rec.lowestBuyout then rec.lowestBuyout = unit end
    end
end

-- Legacy list processor. GetAuctionItemInfo positional: count=3, buyout=10, itemId=17.
local function fullProcessLegacy()
    local n = GetNumAuctionItems("list") or 0
    S.fullSeen = S.fullSeen or {}
    local function batch(start)
        if not S.fullScanning then return end
        local stop = math.min(start + FULL_BATCH - 1, n)
        for i = start, stop do
            local info = { GetAuctionItemInfo("list", i) }
            fullSee(info[17], info[10] or 0, info[3] or 1)
        end
        if stop < n then
            after(0.01, function() batch(stop + 1) end)
        else
            fullStore()
        end
    end
    batch(1)
end

-- Modern replicate processor. GetReplicateItemInfo is ZERO-indexed while the loop is 1-based;
-- lose the `- 1` and the first listing of every scan vanishes silently.
local function fullProcessModern()
    local n = (C_AuctionHouse and C_AuctionHouse.GetNumReplicateItems and C_AuctionHouse.GetNumReplicateItems()) or 0
    S.fullSeen = S.fullSeen or {}
    local function batch(start)
        if not S.fullScanning then return end
        local stop = math.min(start + FULL_BATCH - 1, n)
        for i = start, stop do
            -- Positional like the legacy read: count is the 3rd return, buyout the 10th, itemID
            -- the 17th (C_AuctionHouse.GetReplicateItemInfo's documented order).
            local info = { C_AuctionHouse.GetReplicateItemInfo(i - 1) }
            fullSee(info[17], info[10] or 0, info[3] or 1)
        end
        if stop < n then
            after(0.01, function() batch(stop + 1) end)
        else
            fullStore()
        end
    end
    batch(1)
end

-- Offline-test seams: the per-unit arithmetic is what every consumer's cost figure rests on.
S._fullProcessLegacy = fullProcessLegacy
S._fullProcessModern = fullProcessModern

fullScanFrame:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_ITEM_LIST_UPDATE" then
        -- The getAll payload — process it exactly once, then stop listening.
        fullScanFrame:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
        fullProcessLegacy()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        -- A scan aborted by the close discards its partial data.
        fullUnregisterEvents()
        S.fullScanning = false
        S.fullSeen     = nil
        lib:_UpdateScanButton()
    end
end)

--- Start a full scan. `auto` (the auto-on-open trigger) keeps the throttle refusal quiet.
--- @return boolean started
--- @return string|nil reason "busy" | "ah-closed" | "no-api" | "throttled"
function lib:StartFullScan(auto)
    if S.fullScanning or S.scanning then return false, "busy" end
    if not self:IsAuctionHouseOpen() then return false, "ah-closed" end

    if S.isModernAH then
        if not (C_AuctionHouse and C_AuctionHouse.ReplicateItems) then return false, "no-api" end
        -- ReplicateItems has no CanSendAuctionQuery-style pre-check, so self-throttle.
        local at = self:_PriceNow()
        if S.lastFullScanAt and (at - S.lastFullScanAt) < FULL_COOLDOWN then
            if not auto then self:_PricePrint("Full scan is on cooldown (~once / 15 min). Using cached prices.") end
            return false, "throttled"
        end
        S.fullSeen     = {}
        S.fullScanning = true
        S.fullPending  = true
        self:_UpdateScanButton()
        C_AuctionHouse.ReplicateItems()
        return true
    end

    -- Legacy: the SECOND return of CanSendAuctionQuery is "can do a getAll right now".
    local _, canGetAll = CanSendAuctionQuery()
    if not canGetAll then
        if not auto then self:_PricePrint("Full scan is on cooldown (getAll allows ~once / 15 min). Try again shortly.") end
        return false, "throttled"
    end
    S.fullSeen     = {}
    S.fullScanning = true
    self:_UpdateScanButton()
    -- Guard against a Classic AH-code error on the getAll result set.
    if ITEM_QUALITY_COLORS and not ITEM_QUALITY_COLORS[-1] then
        ITEM_QUALITY_COLORS[-1] = { r = 0, g = 0, b = 0 }
    end
    fullRegisterEvents()
    QueryAuctionItems("", nil, nil, 0, nil, nil, true, false, nil)
    return true
end

--- Scan state for a consumer that shows "resolving prices…": whether anything is running, which
--- kind, how far through, and when the last full scan finished for this realm + faction.
--- @return table `{ running, kind = "full"|"targeted"|nil, scanned, total, lastScanAt, lastScanCount, auctionHouseOpen }`
function lib:GetScanState()
    local lastAt, lastCount = self:GetLastScan()
    local kind
    if S.fullScanning then kind = "full" elseif S.scanning then kind = "targeted" end
    return {
        running          = kind ~= nil,
        kind             = kind,
        scanned          = S.scannedItems or 0,
        total            = S.totalItems or 0,
        lastScanAt       = lastAt,
        lastScanCount    = lastCount,
        auctionHouseOpen = self:IsAuctionHouseOpen(),
    }
end

function lib:IsScanning()     return S.scanning == true end
function lib:IsFullScanning() return S.fullScanning == true end

-- ---------------------------------------------------------------------------
-- Result collectors
-- ---------------------------------------------------------------------------
-- Legacy (Vanilla / TBC / Wrath). The full scan is handled by fullScanFrame, not here.
local function onAuctionItemListUpdate()
    if not S.scanning or not S.currentItem then return end
    if S.isModernAH then return end

    local current = S.currentItem
    local n = GetNumAuctionItems("list") or 0
    local listings = {}
    local wantNameLower = tostring(current.itemName or ""):lower()
    local wantId = current.itemId

    for i = 1, n do
        -- Classic Era returns 17 values: name(1), count(3), buyoutPrice(10), bidAmount(11),
        -- owner(14), itemId(17). Read positionally; trailing nils are tolerated.
        local name, _, count, _, _, _, _, _, _, buyoutPrice, bidAmount, _, _, owner, _, _, itemId =
            GetAuctionItemInfo("list", i)
        local nameMatches = name and wantNameLower ~= "" and name:lower() == wantNameLower
        local idMatches   = itemId and wantId and itemId == wantId
        if nameMatches or idMatches then
            listings[#listings + 1] = {
                itemName    = name,
                count       = count or 1,
                buyoutPrice = buyoutPrice or 0,
                bidAmount   = bidAmount or 0,
                owner       = owner,
                itemId      = itemId,
            }
        end
    end
    S._completeCurrentItem(listings)
end

-- Modern (Cata / MoP / Retail). Non-commodity results arrive keyed by itemKey…
local function onItemSearchResultsUpdated(itemKey)
    if not S.scanning or not S.currentItem then return end
    if type(itemKey) ~= "table" or itemKey.itemID ~= S.currentItem.itemId then return end

    local quantity = C_AuctionHouse.GetItemSearchResultsQuantity(itemKey) or 0
    local listings = {}
    for i = 1, quantity do
        local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, i)
        if info then
            listings[#listings + 1] = {
                itemName    = S.currentItem.itemName,
                count       = info.quantity or 1,
                buyoutPrice = info.buyoutAmount or 0,
                bidAmount   = info.bidAmount or 0,
                owner       = info.owners and info.owners[1] or nil,
                itemId      = itemKey.itemID,
            }
        end
    end
    S._completeCurrentItem(listings)
end

-- …and commodities (stackables) by itemID, with a unit price and no bid.
local function onCommoditySearchResultsUpdated(itemID)
    if not S.scanning or not S.currentItem then return end
    if type(itemID) ~= "number" or itemID ~= S.currentItem.itemId then return end

    local quantity = C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) or 0
    local listings = {}
    for i = 1, quantity do
        local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
        if info then
            listings[#listings + 1] = {
                itemName    = S.currentItem.itemName,
                count       = info.quantity or 1,
                buyoutPrice = info.unitPrice or 0,
                bidAmount   = 0,
                owner       = info.owner,
                itemId      = itemID,
            }
        end
    end
    S._completeCurrentItem(listings)
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local frame = S.eventFrame or CreateFrame("Frame")
S.eventFrame = frame
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
if S.isModernAH then
    frame:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
    frame:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
    frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
else
    frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
end

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "AUCTION_HOUSE_SHOW" then
        S.isOpen = true
        ensureScanButtonHook()
        lib:_UpdateScanButton()
        lib:_PriceFire("LibItemDB_AuctionHouse", true)
        -- Auto full-scan is OPT-IN (default off): getAll is a shared, ~once-per-15-min,
        -- client-wide budget, and firing it on every AH open would starve a dedicated AH addon's
        -- own scan. The 1s delay lets the AH UI finish initialising first.
        if lib:_PriceSettings().autoScan then
            after(1.0, function()
                if lib:IsAuctionHouseOpen() then lib:StartFullScan(true) end
            end)
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        S.isOpen = false
        if S.scanBtn then S.scanBtn:Hide() end
        if S.scanning then lib:CancelScan() end
        -- Stop an in-flight full scan (its batch loop bails on fullScanning=false) but KEEP
        -- S.fullSeen: the store already has the prices, and the per-session record lets
        -- GetScanListings answer again when the AH reopens inside the getAll cooldown.
        S.fullScanning = false
        S.fullPending  = false
        lib:ClearScanResults()
        lib:_UpdateScanButton()
        lib:_PriceFire("LibItemDB_AuctionHouse", false)
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        onAuctionItemListUpdate()
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
        onItemSearchResultsUpdated(arg1)
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        onCommoditySearchResultsUpdated(arg1)
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if S.fullPending then
            S.fullPending = false
            fullProcessModern()
        end
    end
end)
