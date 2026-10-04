--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local AuctionScanService = _G.professionMaster:CreateService("auction-scan");

--- Initialize service.
-- The service scans the whole auction house once (legacy "getAll" query on
-- Vanilla/TBC/Wrath, C_AuctionHouse.ReplicateItems on Cata/MoP) and stores the
-- lowest unit buyout of every item Profession Master can display a price for
-- (crafted items and reagents of the active expansion). The stored prices are
-- the fallback of the auction service when neither Auctionator nor TSM is
-- installed. Only item id, stack size and buyout are read per auction, no item
-- links or item data loads, so even large auction houses are processed in a
-- few frames.
function AuctionScanService:Initialize()
    -- the server allows one full scan (getAll / replicate) every 15 minutes
    self.ScanCooldown = 15 * 60;

    -- auctions processed per frame while a scan result is evaluated
    self.BatchSize = 1000;

    -- limits of the stored offers per item (price levels and units): the
    -- leveling planner needs the quantities behind the cheapest prices, not
    -- every single auction of a flooded market
    self.MaxListingLevels = 40;
    self.MaxListingUnits = 2000;

    -- Cata/MoP use the modern auction house api, and so does every client
    -- without the legacy query function (WoW Forever)
    self.isModern = self.addon.isCataAtLeast or QueryAuctionItems == nil;
    self.inProgress = false;
    self.progress = 0;
    self.listeners = {};

    -- dedicated event frame: it is registered only while a scan runs, so the
    -- list update of the blizzard browse frame can be paused independently of
    -- the addon event dispatcher (see PauseListUpdateListeners)
    local frame = CreateFrame("Frame");
    frame:SetScript("OnEvent", function(_, event)
        self:OnScanEvent(event);
    end);
    self.frame = frame;

    -- an installed price addon makes the own data obsolete
    self:PurgeIfExternalPricesAvailable();

    -- scan button on the auction house frame and optional auto scan
    self:HandleEvent("AUCTION_HOUSE_SHOW", function()
        self:OnAuctionHouseOpen();
    end);
    self:HandleEvent("AUCTION_HOUSE_CLOSED", function()
        self:OnAuctionHouseClose();
    end);
end

--- Get the scanned price table of the current node (realm + faction).
-- @return the node's itemId => unit price table, or nil if the node is not ready.
function AuctionScanService:GetStore()
    local node = self:GetService("player").node;
    if (not node) then
        return nil;
    end

    if (not node.scannedPrices) then
        node.scannedPrices = {};
    end

    return node.scannedPrices;
end

--- Delete the own scan data when Auctionator or TSM is installed.
-- The external addon delivers the prices from now on, the stored table would
-- only waste memory in the saved variables.
function AuctionScanService:PurgeIfExternalPricesAvailable()
    if (not self:GetService("auction"):CheckExternalPricesAvailable()) then
        return;
    end

    local node = self:GetService("player").node;
    if (not node or not node.scannedPrices or next(node.scannedPrices) == nil) then
        return;
    end

    node.scannedPrices = {};
    node.scannedPricesTime = nil;
    self.priceCount = nil;
    self.addon:Log("AuctionScanService", "PurgeIfExternalPricesAvailable", "external price addon found, own scan data deleted");
end

--- Check if at least one scanned price is stored for the current node.
-- Always false while an external price addon is installed (its prices win).
-- @return true if scanned prices are available.
function AuctionScanService:HasPrices()
    if (self:GetService("auction"):CheckExternalPricesAvailable()) then
        return false;
    end

    local store = self:GetStore();
    return store ~= nil and next(store) ~= nil;
end

--- Get the scanned unit price of an item.
-- Ignored while an external price addon is installed (its prices win).
-- @param itemId The item ID.
-- @return price in coppers per unit, or nil if the item was never seen in a scan.
function AuctionScanService:GetPrice(itemId)
    if (not itemId or self:GetService("auction"):CheckExternalPricesAvailable()) then
        return nil;
    end

    local store = self:GetStore();
    return store and store[itemId];
end

--- Get the offers of an item from the last scan: quantities per unit price,
-- cheapest first. Kept even while Auctionator or TSM is installed, those
-- addons only know the lowest price and the leveling planner needs the depth.
-- @param itemId The item ID.
-- @return flat array { unitPrice1, count1, unitPrice2, count2, ... } or nil if the item was not on the auction house.
function AuctionScanService:GetListings(itemId)
    local node = self:GetService("player").node;
    local listings = node and node.scannedListings;
    return listings and itemId and listings[itemId];
end

--- Get the time of the last scan that stored offers.
-- @return unix timestamp, or nil if no scan stored offers yet.
function AuctionScanService:GetListingsTime()
    local node = self:GetService("player").node;
    return node and node.scannedListingsTime;
end

--- Get the number of stored scanned prices (counted lazily, cached until the next scan).
-- @return number of items with a scanned price.
function AuctionScanService:GetPriceCount()
    if (self.priceCount == nil) then
        local count = 0;
        local store = self:GetStore();
        if (store) then
            for _ in pairs(store) do
                count = count + 1;
            end
        end
        self.priceCount = count;
    end

    return self.priceCount;
end

--- Get the time of the last completed scan of the current node.
-- @return unix timestamp, or nil if no scan completed yet.
function AuctionScanService:GetLastScanTime()
    local node = self:GetService("player").node;
    return node and node.scannedPricesTime;
end

--- Check if a scan is currently running.
-- @return true while a scan is in progress.
function AuctionScanService:IsInProgress()
    return self.inProgress;
end

--- Get the seconds until the next full scan is allowed.
-- Legacy clients report the getAll readiness themselves, the own timestamp
-- (per character, like the server-side throttle) only feeds the countdown.
-- @return seconds to wait, 0 if a scan can be started right away.
function AuctionScanService:GetSecondsUntilNextScan()
    local lastScan = PM_CharacterSettings.lastPriceScan or 0;
    local remaining = self.ScanCooldown - (time() - lastScan);

    if (not self.isModern and CanSendAuctionQuery) then
        local _, canGetAll = CanSendAuctionQuery();
        if (canGetAll) then
            return 0;
        end

        -- getAll is blocked although the own timestamp does not know why
        -- (e.g. another addon scanned): wait at least a second and re-check
        return math.max(remaining, 1);
    end

    return math.max(remaining, 0);
end

--- Check if a scan can be started right now.
-- @return true if the auction house is open, no scan runs and the cooldown elapsed.
function AuctionScanService:CanScan()
    if (self.inProgress or not self:GetService("auction"):IsOpen()) then
        return false;
    end

    return self:GetSecondsUntilNextScan() == 0;
end

--- Register a listener called on every scan state change (start, progress, finish, abort).
-- @param callback Function(service).
function AuctionScanService:AddListener(callback)
    table.insert(self.listeners, callback);
end

--- Notify all listeners about a state change.
-- @param progress Optional progress between 0 and 1.
function AuctionScanService:Notify(progress)
    if (progress) then
        self.progress = progress;
    end

    for _, listener in ipairs(self.listeners) do
        listener(self);
    end
end

--- Collect the item ids Profession Master shows prices for.
-- Crafted items and reagents of all cached skills are relevant, everything
-- else on the auction house is skipped while the scan result is evaluated.
function AuctionScanService:BuildRelevantItems()
    local skillsService = self:GetService("skills");
    local relevant = {};
    local count = 0;

    for itemId in pairs(skillsService.allItems or {}) do
        if (not relevant[itemId]) then
            relevant[itemId] = true;
            count = count + 1;
        end
    end

    -- reagents and recipe items also keep their offers (leveling planner)
    local listingItems = {};
    for itemId in pairs(skillsService.allReagents or {}) do
        listingItems[itemId] = true;
        if (not relevant[itemId]) then
            relevant[itemId] = true;
            count = count + 1;
        end
    end
    for itemId in pairs(skillsService.allRecipes or {}) do
        listingItems[itemId] = true;
        if (not relevant[itemId]) then
            relevant[itemId] = true;
            count = count + 1;
        end
    end

    self.relevantItems = relevant;
    self.listingItems = listingItems;
    self.addon:Log("AuctionScanService", "BuildRelevantItems", "%d relevant items", count);
end

--- Start a full auction house scan.
-- @param isAuto true when triggered by the auto scan (no chat hints about cooldown / closed AH).
-- @return true if the scan was started.
function AuctionScanService:StartScan(isAuto)
    local chatService = self:GetService("chat");

    -- the auction house must be open
    if (not self:GetService("auction"):IsOpen()) then
        if (not isAuto) then
            chatService:Write("PriceScanNeedsAuctionHouse");
        end
        return false;
    end

    -- only one scan at a time
    if (self.inProgress) then
        return false;
    end

    -- respect the server-side throttle
    local wait = self:GetSecondsUntilNextScan();
    if (wait > 0) then
        if (not isAuto) then
            chatService:Write("PriceScanCooldown", self:GetService("timer"):FormatTime(wait));
        end
        return false;
    end

    self:BuildRelevantItems();
    self.inProgress = true;
    self.progress = 0;
    PM_CharacterSettings.lastPriceScan = time();
    self.addon:Log("AuctionScanService", "StartScan", "full scan started (%s, auto: %s)", self.isModern and "replicate" or "getAll", tostring(isAuto == true));
    chatService:Write("PriceScanStarted");

    -- request the whole auction house and wait for the result event
    self.frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
    if (self.isModern) then
        self.frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE");
        C_AuctionHouse.ReplicateItems();
    else
        -- the blizzard browse frame would try to render the complete result
        self:PauseListUpdateListeners();
        self.frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
        QueryAuctionItems("", nil, nil, 0, nil, nil, true, false, nil);
    end

    self:Notify(0.1);
    return true;
end

--- Unregister every other frame from the list update while the getAll result arrives.
-- Same approach as Auctionator: the default browse frame would otherwise
-- process tens of thousands of rows. The frames are re-registered in Cleanup.
function AuctionScanService:PauseListUpdateListeners()
    self.pausedFrames = { GetFramesRegisteredForEvent("AUCTION_ITEM_LIST_UPDATE") };
    for _, pausedFrame in ipairs(self.pausedFrames) do
        pausedFrame:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE");
    end
end

--- Re-register the frames paused by PauseListUpdateListeners.
function AuctionScanService:ResumeListUpdateListeners()
    if (not self.pausedFrames) then
        return;
    end

    for _, pausedFrame in ipairs(self.pausedFrames) do
        pausedFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
    end
    self.pausedFrames = nil;
end

--- Handle the events of the scan frame.
-- @param event The event name.
function AuctionScanService:OnScanEvent(event)
    if (event == "AUCTION_ITEM_LIST_UPDATE" or event == "REPLICATE_ITEM_LIST_UPDATE") then
        -- only the first result event belongs to the scan
        self.frame:UnregisterEvent(event);
        self:ProcessResults();
    elseif (event == "AUCTION_HOUSE_CLOSED") then
        self:AbortScan();
    end
end

--- Evaluate the scan result in batches spread over several frames.
-- Keeps the lowest unit buyout of every relevant item; bid-only auctions are ignored.
function AuctionScanService:ProcessResults()
    local total, readInfo, firstIndex, lastIndex;
    if (self.isModern) then
        total = C_AuctionHouse.GetNumReplicateItems();
        readInfo = C_AuctionHouse.GetReplicateItemInfo;
        firstIndex = 0;
        lastIndex = total - 1;
    else
        total = GetNumAuctionItems("list");
        readInfo = function(index)
            return GetAuctionItemInfo("list", index);
        end;
        firstIndex = 1;
        lastIndex = total;
    end

    self.addon:Log("AuctionScanService", "ProcessResults", "processing %d auctions", total);
    self:Notify(0.2);

    local relevant = self.relevantItems;
    local listingItems = self.listingItems;
    local prices = {};
    local listings = {};
    local index = firstIndex;
    local batchSize = self.BatchSize;

    -- one batch per frame until every auction was read
    self.ticker = C_Timer.NewTicker(0, function()
        if (not self.inProgress) then
            return;
        end

        local stop = math.min(index + batchSize - 1, lastIndex);
        for i = index, stop do
            local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemId = readInfo(i);
            if (itemId and relevant[itemId] and buyout and buyout > 0 and count and count > 0) then
                local unitPrice = math.ceil(buyout / count);
                local current = prices[itemId];
                if (not current or unitPrice < current) then
                    prices[itemId] = unitPrice;
                end

                -- units per unit price of reagents and recipes
                if (listingItems[itemId]) then
                    local levels = listings[itemId];
                    if (not levels) then
                        levels = {};
                        listings[itemId] = levels;
                    end
                    levels[unitPrice] = (levels[unitPrice] or 0) + count;
                end
            end
        end
        index = stop + 1;

        -- finished
        if (index > lastIndex) then
            self.ticker:Cancel();
            self.ticker = nil;
            self:FinishScan(prices, total, listings);
            return;
        end

        self:Notify(0.2 + 0.8 * (index - firstIndex) / math.max(total, 1));
    end);
end

--- Store the scan result and refresh the open price views.
-- Prices of items not seen in this scan are kept (last seen price).
-- @param prices Table of itemId => lowest unit buyout of this scan.
-- @param total Number of auctions read.
-- @param listings Table of itemId => { [unitPrice] = units } of this scan.
function AuctionScanService:FinishScan(prices, total, listings)
    local store = self:GetStore();
    local stored = 0;
    local hasExternalPrices = self:GetService("auction"):CheckExternalPricesAvailable();
    for itemId, price in pairs(prices) do
        stored = stored + 1;

        -- an installed price addon delivers the lowest prices, the own table would only be purged again
        if (store and not hasExternalPrices) then
            store[itemId] = price;
        end
    end
    if (store and not hasExternalPrices) then
        self:GetService("player").node.scannedPricesTime = time();
    end
    self.priceCount = nil;
    self:StoreListings(listings);

    self:Cleanup();
    self.addon:Log("AuctionScanService", "FinishScan", "scanned %d auctions, stored %d prices", total, stored);
    self:GetService("chat"):Write("PriceScanFinished", stored, total);
    self:Notify(1);
    self:RefreshPriceViews();
end

--- Store the offers of a scan, replacing those of the previous scan (an item
-- missing now is no longer on the auction house). Each item keeps its
-- cheapest price levels as flat array, bounded by MaxListingLevels and
-- MaxListingUnits.
-- @param listings Table of itemId => { [unitPrice] = units }.
function AuctionScanService:StoreListings(listings)
    local node = self:GetService("player").node;
    if (not node or not listings) then
        return;
    end

    local stored = {};
    local itemCount = 0;
    for itemId, levels in pairs(listings) do
        local unitPrices = {};
        for unitPrice in pairs(levels) do
            unitPrices[#unitPrices + 1] = unitPrice;
        end
        table.sort(unitPrices);

        -- cheapest levels first until one of the limits is reached
        local flat = {};
        local units = 0;
        for levelIndex, unitPrice in ipairs(unitPrices) do
            if (levelIndex > self.MaxListingLevels or units >= self.MaxListingUnits) then
                break;
            end
            flat[#flat + 1] = unitPrice;
            flat[#flat + 1] = levels[unitPrice];
            units = units + levels[unitPrice];
        end
        stored[itemId] = flat;
        itemCount = itemCount + 1;
    end

    node.scannedListings = stored;
    node.scannedListingsTime = time();
    self.addon:Log("AuctionScanService", "StoreListings", "stored offers of %d items", itemCount);
end

--- Abort a running scan (auction house closed).
function AuctionScanService:AbortScan()
    if (not self.inProgress) then
        return;
    end

    self:Cleanup();
    self.addon:Log("AuctionScanService", "AbortScan", "scan aborted, auction house closed");
    self:GetService("chat"):Write("PriceScanAborted");
    self:Notify(0);
end

--- Reset the scan state, stop the batch ticker and restore the paused frames.
function AuctionScanService:Cleanup()
    self.inProgress = false;
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
    self.frame:UnregisterAllEvents();
    self:ResumeListUpdateListeners();
    self.relevantItems = nil;
    self.listingItems = nil;
end

--- Refresh the views showing prices so a finished scan is visible right away.
function AuctionScanService:RefreshPriceViews()
    local professionsView = self.addon.professionsView;
    if (professionsView and professionsView.visible) then
        professionsView:Refresh();
    end

    local inventoryService = self:GetService("inventory");
    if (inventoryService.missingReagentsView and inventoryService.missingReagentsView.visible) then
        inventoryService:CheckMissingReagents();
    end
end

--- Called when the auction house opens: shows the scan button and starts the
--- auto scan when enabled. Both are skipped when Auctionator or TSM maintain
--- the prices anyway.
function AuctionScanService:OnAuctionHouseOpen()
    if (self:GetService("auction"):CheckExternalPricesAvailable()) then
        return;
    end

    -- scan button on the auction house frame (created on first open)
    if (not self.button) then
        self.button = self.addon:NewView("auction-scan-button");
    end
    self.button:Attach();

    if (not PM_Settings.autoScanPrices) then
        return;
    end

    -- give the auction house frame a moment to settle before querying
    C_Timer.After(1, function()
        if (self:CanScan()) then
            self.addon:Log("AuctionScanService", "OnAuctionHouseOpen", "auto scan on auction house open");
            self:StartScan(true);
        end
    end);
end

--- Called when the auction house closes: stops the button countdown.
function AuctionScanService:OnAuctionHouseClose()
    if (self.button) then
        self.button:Detach();
    end
end
