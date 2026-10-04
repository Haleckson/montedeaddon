--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local AuctionService = _G.professionMaster:CreateService("auction");

--- Initialize service.
function AuctionService:Initialize()
    self.isOpen = false;

    -- api version of Auctionizer that shows its price charts at the mouse
    self.PriceChartApiVersion = 2;

    -- build the runtime vendor price table from the vendor price models
    -- (models/vendor-prices): the toc loads only the files of its client, vanilla
    -- first and later expansions on top; sod shares the vanilla toc and counts
    -- on season of discovery realms only
    self.vendorPrices = {};
    local vendorItemCount = 0;
    for _, suffix in ipairs({ "vanilla", "sod", "bcc", "wrath", "cata", "mop", "forever" }) do
        if (suffix ~= "sod" or self.addon.isSod) then
            self:ApplyVendorPrices(self:GetModel("vendor-prices-" .. suffix));
        end
    end
    for _ in pairs(self.vendorPrices) do
        vendorItemCount = vendorItemCount + 1;
    end
    self.addon:Log("AuctionService", "Initialize", "Loaded %d vendor prices", vendorItemCount);

    -- register events
    self:HandleEvent("AUCTION_HOUSE_SHOW", function()
        self:OnAuctionHouseOpen();
    end);
    self:HandleEvent("AUCTION_HOUSE_CLOSED", function()
        self:OnAuctionHouseClose();
    end);
end

--- Apply the vendor prices of one expansion to the runtime price table.
-- @param vendorPrices Table of itemId => price, false for an item no vendor
--        of this expansion sells any more; nil when the client has no such model.
function AuctionService:ApplyVendorPrices(vendorPrices)
    if (not vendorPrices) then
        return;
    end

    for id, price in pairs(vendorPrices) do
        self.vendorPrices[id] = price or nil;
    end
end

--- Called when the auction house opens.
function AuctionService:OnAuctionHouseOpen()
    self.isOpen = true;
end

--- Called when the auction house closes.
function AuctionService:OnAuctionHouseClose()
    self.isOpen = false;
end

--- Check if the auction house is currently open.
-- @return true if AH is open.
function AuctionService:IsOpen()
    return self.isOpen;
end

--- Search for an item by name in the auction house.
-- Tries the Auctionizer buy tab first, then the Auctionator Shopping tab,
-- then the TSM Browse tab, then the default AH.
-- @param itemName The item name to search for.
-- @param itemId Optional item ID (used for Auctionizer and TSM, which search by item).
function AuctionService:SearchFor(itemName, itemId)
    if (not self.isOpen or not itemName or itemName == "") then
        return;
    end

    self.addon:Log("AuctionService", "SearchFor", "searching for %s", itemName);

    -- try the Auctionizer buy tab first (exact search of the item)
    if (itemId and self:SearchViaAuctionizer(itemId)) then
        return;
    end

    -- try Auctionator Shopping tab
    if (self:SearchViaAuctionator(itemName)) then
        return;
    end

    -- try TSM Browse tab (requires item ID for item link)
    if (itemId and self:SearchViaTSMItemId(itemId)) then
        return;
    end

    -- fall back to default AH search (the modern auction house also runs on
    -- the WoW Forever client, which has no legacy query function)
    if (self.addon.isCataAtLeast or QueryAuctionItems == nil) then
        self:SearchForModern(itemName);
    else
        self:SearchForClassic(itemName);
    end
end

--- Get the public api of Auctionizer when the addon is installed and
--- works with the auction house of this client. The answer is kept once the
--- api is ready: whether the client is supported never changes in a session.
-- @return AuctionizerApi table or nil.
function AuctionService:GetAuctionizerApi()
    if (self.auctionizerApi ~= nil) then
        return self.auctionizerApi or nil;
    end
    local api = _G.AuctionizerApi;
    if (type(api) ~= "table" or (api.Version or 0) < 1 or not api.IsReady()) then
        return nil;
    end
    if (api.IsSupported()) then
        self.auctionizerApi = api;
        self.addon:Log("AuctionService", "GetAuctionizerApi", "Auctionizer found, its prices, searches and shopping list are used first");
    else
        self.auctionizerApi = false;
        self.addon:Log("AuctionService", "GetAuctionizerApi", "Auctionizer is installed but passive on this client");
    end
    return self.auctionizerApi or nil;
end

--- Search an item in the Auctionizer buy tab (exact search of the item).
-- @param itemId The item ID to search for.
-- @return true if Auctionizer took the search (its window is the auction house ui).
function AuctionService:SearchViaAuctionizer(itemId)
    local api = self:GetAuctionizerApi();
    return api ~= nil and api.SearchItem(itemId) == true;
end

--- Hand a list of items to Auctionizer: its shopping list is replaced by
--- them with the amounts the shopping list still misses (bank and mail taken
--- off, at least 1) and its buy tab opens, where the prices of the whole list
--- are one click away.
-- @param itemIds Array of item IDs.
-- @return true if Auctionizer took the list.
function AuctionService:SearchViaAuctionizerList(itemIds)
    local api = self:GetAuctionizerApi();
    if (not api or not itemIds or #itemIds == 0 or not api.IsWindowShown()) then
        return false;
    end

    -- a purchase placed right now keeps the list
    if (not api.ClearShoppingList()) then
        return false;
    end

    local missingReagents = self:GetService("inventory"):GetMissingReagents() or {};
    for _, itemId in ipairs(itemIds) do
        local reagent = missingReagents[itemId];
        local quantity = reagent and ((reagent.missing or 0) - (reagent.bankCount or 0) - (reagent.mailCount or 0)) or 1;
        api.AddToShoppingList(itemId, math.max(1, quantity));
    end
    api.ShowTab("buy");
    self.addon:Log("AuctionService", "SearchViaAuctionizerList", "%d items handed to the Auctionizer shopping list", #itemIds);
    return true;
end

--- Search via Auctionator Shopping tab (exact match).
-- @param itemName The item name to search for.
-- @return true if search was triggered successfully.
function AuctionService:SearchViaAuctionator(itemName)
    if (not Auctionator or not Auctionator.API or not Auctionator.API.v1) then
        return false;
    end

    -- prefer exact search for precise item matching
    if (Auctionator.API.v1.MultiSearchExact) then
        local success = pcall(Auctionator.API.v1.MultiSearchExact, "ProfessionMaster", {itemName});
        if (success) then
            return true;
        end
    end

    -- fallback to regular multi search
    if (Auctionator.API.v1.MultiSearch) then
        local success = pcall(Auctionator.API.v1.MultiSearch, "ProfessionMaster", {itemName});
        if (success) then
            return true;
        end
    end

    return false;
end

--- Search via TSM for a specific item by ID.
-- Uses TSM's ChatEdit_InsertLink hook which triggers item search when TSM AH is visible.
-- @param itemId The item ID to search for.
-- @return true if search was triggered successfully.
function AuctionService:SearchViaTSMItemId(itemId)
    if (not TSM_API or not itemId) then
        return false;
    end

    -- check TSM AH is visible via public API
    local success, visible = pcall(TSM_API.IsUIVisible, "AUCTION");
    if (not success or not visible) then
        return false;
    end

    -- get item link from item ID
    local _, itemLink = self.addon.compat.GetItemInfo(itemId);
    if (not itemLink) then
        return false;
    end

    -- trigger search via ChatEdit_InsertLink which TSM hooks
    return self.addon.compat.ChatEdit_InsertLink(itemLink);
end

--- Search for multiple items by name in the auction house.
-- The items become the Auctionizer shopping list, Auctionator searches
-- them all at once (MultiSearchExact), TSM the first item only.
-- @param itemNames Array of item names to search for.
-- @param itemIds Optional array of item IDs (parallel to itemNames, for Auctionizer and TSM).
function AuctionService:SearchForMultiple(itemNames, itemIds)
    if (not self.isOpen or not itemNames or #itemNames == 0) then
        return;
    end

    -- try the Auctionizer shopping list first
    if (self:SearchViaAuctionizerList(itemIds)) then
        return;
    end

    -- try Auctionator MultiSearchExact (supports multiple terms natively)
    if (Auctionator and Auctionator.API and Auctionator.API.v1) then
        if (Auctionator.API.v1.MultiSearchExact) then
            local success = pcall(Auctionator.API.v1.MultiSearchExact, "ProfessionMaster", itemNames);
            if (success) then
                return;
            end
        end
        if (Auctionator.API.v1.MultiSearch) then
            local success = pcall(Auctionator.API.v1.MultiSearch, "ProfessionMaster", itemNames);
            if (success) then
                return;
            end
        end
    end

    -- try TSM single item search (TSM has no multi-search API)
    if (TSM_API and itemIds and itemIds[1]) then
        local success = self:SearchViaTSMItemId(itemIds[1]);
        if (success) then
            return;
        end
    end

    -- fallback: search for first item only via default AH
    local firstItemId = itemIds and itemIds[1] or nil;
    self:SearchFor(itemNames[1], firstItemId);
end

--- Search in the classic auction house (Vanilla, TBC, Wrath).
-- @param itemName The item name to search for.
function AuctionService:SearchForClassic(itemName)

    -- switch to browse tab
    if (AuctionFrameBrowse and AuctionFrameBrowse:IsVisible() == false) then
        if (AuctionFrameTab1) then
            AuctionFrameTab1:Click();
        end
    end

    -- populate search box and trigger search
    if (BrowseName) then
        BrowseName:SetText(itemName);
        BrowseName:SetFocus();
    end

    -- trigger search
    if (AuctionFrameBrowse_Search) then
        AuctionFrameBrowse_Search();
    elseif (BrowseSearchButton) then
        BrowseSearchButton:Click();
    end
end

--- Search in the modern auction house (Cataclysm, MoP).
-- @param itemName The item name to search for.
function AuctionService:SearchForModern(itemName)
    if (not AuctionHouseFrame) then
        return;
    end

    -- populate search bar and trigger search
    local searchBar = AuctionHouseFrame.SearchBar;
    if (searchBar) then
        local searchBox = searchBar.SearchBox;
        if (searchBox) then
            searchBox:SetText(itemName);

            -- trigger search via enter press handler
            local onEnterPressed = searchBox:GetScript("OnEnterPressed");
            if (onEnterPressed) then
                onEnterPressed(searchBox);
                return;
            end
        end

        -- fallback: click search button if available
        if (searchBar.SearchButton) then
            searchBar.SearchButton:Click();
            return;
        end
    end

    -- fallback: use C_AuctionHouse API directly
    if (C_AuctionHouse and C_AuctionHouse.SendBrowseQuery) then
        C_AuctionHouse.SendBrowseQuery({
            searchString = itemName,
            sorts = {},
            minLevel = 0,
            maxLevel = 0,
            filters = {},
            itemClassFilters = {},
        });
    end
end

--- Check if an external price addon (Auctionizer, Auctionator or TSM) provides prices.
-- @return true if the Auctionizer, Auctionator or TSM price API is installed and accessible.
function AuctionService:CheckExternalPricesAvailable()
    -- Auctionizer first: it works with the auction house of this client
    if (self:GetAuctionizerApi()) then
        return true;
    end

    -- check Auctionator
    if (Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID) then
        return true;
    end

    -- check TSM as fallback
    return TSM_API ~= nil and TSM_API.GetCustomPriceValue ~= nil;
end

--- Check if price data is available (Auctionator, TSM or the own auction house scan).
-- @return true if any price source can deliver prices.
function AuctionService:CheckPricesAvailable()
    if (self:CheckExternalPricesAvailable()) then
        return true;
    end

    -- own auction house scan (see auction-scan service)
    return self:GetService("auction-scan"):HasPrices();
end

--- Check if multi-item AH search is available (Auctionizer shopping list or Auctionator).
-- @return true if Auctionizer is active or the Auctionator multi-search API is present.
function AuctionService:CheckMultiSearchAvailable()
    if (self:GetAuctionizerApi()) then
        return true;
    end
    return Auctionator and Auctionator.API and Auctionator.API.v1 and (Auctionator.API.v1.MultiSearchExact or Auctionator.API.v1.MultiSearch) ~= nil;
end

--- Check if prices are visible for a specific view.
-- @param viewName The view identifier (e.g. "skill-view", "missing-reagents").
-- @return true if prices are available and enabled for the given view.
function AuctionService:CheckPricesVisible(viewName)
    -- ensure table exists
    if (not PM_CharacterSettings.showPrices) then
        PM_CharacterSettings.showPrices = {};
    end

    -- migrate old boolean format to table
    if (type(PM_CharacterSettings.showPrices) ~= "table") then
        PM_CharacterSettings.showPrices = {};
    end

    return self:CheckPricesAvailable() and PM_CharacterSettings.showPrices[viewName] ~= false;
end

--- Set prices visibility for a specific view.
-- @param viewName The view identifier (e.g. "skill-view", "missing-reagents").
-- @param visible Whether prices should be visible.
function AuctionService:SetPricesVisible(viewName, visible)
    -- ensure table exists
    if (not PM_CharacterSettings.showPrices or type(PM_CharacterSettings.showPrices) ~= "table") then
        PM_CharacterSettings.showPrices = {};
    end

    PM_CharacterSettings.showPrices[viewName] = visible;
end

--- Get the vendor price for an item if it is a vendor-buyable reagent.
-- A user-defined override always wins over the shipped price.
-- @param itemId The item ID to check.
-- @return price in coppers per unit, or nil if not a vendor item.
function AuctionService:GetVendorPrice(itemId)
    if (not itemId) then
        return nil;
    end

    -- user overrides take precedence over the shipped prices
    local override = self:GetVendorPriceOverride(itemId);
    if (override) then
        return override;
    end

    return self:GetDefaultVendorPrice(itemId);
end

--- Get the shipped vendor price for an item, ignoring any user override.
-- @param itemId The item ID to check.
-- @return price in coppers per unit, or nil if not a vendor item.
function AuctionService:GetDefaultVendorPrice(itemId)
    if (not itemId) then
        return nil;
    end

    return self.vendorPrices[itemId];
end

--- Get the reagent price override table for the current node (realm + faction).
-- Overrides live in the PM_Data node managed by the player service.
-- @return the node's itemId => price table, or nil if the node is not ready.
function AuctionService:GetNodePriceOverrides()
    local node = self:GetService("player").node;
    if (not node) then
        return nil;
    end

    if (not node.reagentPrices) then
        node.reagentPrices = {};
    end

    return node.reagentPrices;
end

--- Get the user-defined vendor price override for an item (current node only).
-- @param itemId The item ID to check.
-- @return overridden price in coppers per unit, or nil if not overridden.
function AuctionService:GetVendorPriceOverride(itemId)
    if (not itemId) then
        return nil;
    end

    local overrides = self:GetNodePriceOverrides();
    return overrides and overrides[itemId];
end

--- Store a user-defined vendor price override for the current node.
-- A nil or non-positive price clears the override instead.
-- @param itemId The item ID to override.
-- @param price The price in coppers per unit.
function AuctionService:SetVendorPriceOverride(itemId, price)
    if (not itemId) then
        return;
    end

    if (not price or price <= 0) then
        self:ClearVendorPriceOverride(itemId);
        return;
    end

    local overrides = self:GetNodePriceOverrides();
    if (not overrides) then
        return;
    end

    overrides[itemId] = price;
    self.addon:Log("AuctionService", "SetVendorPriceOverride", "item %d overridden with %d copper", itemId, price);
end

--- Remove a user-defined vendor price override for the current node.
-- @param itemId The item ID to reset.
function AuctionService:ClearVendorPriceOverride(itemId)
    if (not itemId) then
        return;
    end

    local overrides = self:GetNodePriceOverrides();
    if (not overrides or not overrides[itemId]) then
        return;
    end

    overrides[itemId] = nil;
    self.addon:Log("AuctionService", "ClearVendorPriceOverride", "item %d reset to default", itemId);
end

--- Get the runtime vendor price table (the vendor price models of the active expansions merged).
-- User overrides are not applied here; query them via GetVendorPriceOverride.
-- @return table of itemId => price in coppers per unit.
function AuctionService:GetVendorPrices()
    return self.vendorPrices;
end

--- Check whether an item is a drop reagent: a bind on pickup reagent of the
-- loaded skill data that nobody can craft (raid / world drops like Primal
-- Nether, Nether Vortex or Blood of Heroes). Crafted items (e.g. Dragonmaw) and
-- self conversions (e.g. Spirit of Harmony) are not drop reagents even if they
-- bind on pickup. The bind type comes from the client item data, so the list
-- follows the current expansion and patch automatically.
-- @param itemId The item ID to check.
-- @return true if drop reagent, false if not, nil if the item data is not loaded yet.
function AuctionService:IsDropReagent(itemId)
    if (not itemId) then
        return nil;
    end

    -- cached answer
    self.dropReagents = self.dropReagents or {};
    local cached = self.dropReagents[itemId];
    if (cached ~= nil) then
        return cached;
    end

    -- the skill indexes must exist, otherwise crafted items could be cached as drops
    local skillsService = self:GetService("skills");
    if (not skillsService.allReagents or not skillsService.allItems) then
        return nil;
    end

    -- must be a reagent that no profession crafts, no self conversion and no vendor item
    if (not skillsService.allReagents[itemId]
        or skillsService.allItems[itemId]
        or (skillsService.conversions or {})[itemId]
        or self:GetDefaultVendorPrice(itemId)) then
        self.dropReagents[itemId] = false;
        return false;
    end

    -- bind type is the 14th return of GetItemInfo (1 = bind on pickup)
    local bindType = select(14, self.addon.compat.GetItemInfo(itemId));
    if (bindType == nil) then
        -- item data not loaded yet: request it so the next lookup succeeds
        if (C_Item and C_Item.RequestLoadItemDataByID) then
            C_Item.RequestLoadItemDataByID(itemId);
        end
        return nil;
    end

    local isDropReagent = (bindType == 1);
    self.dropReagents[itemId] = isDropReagent;
    return isDropReagent;
end

--- Get the drop reagents of the loaded skill data (see IsDropReagent).
-- Only items whose data is already loaded are included; the reagent prices
-- view requests the item data before calling this.
-- @return table of itemId => true.
function AuctionService:GetDropReagents()
    local skillsService = self:GetService("skills");
    local result = {};

    for itemId in pairs(skillsService.allReagents or {}) do
        if (self:IsDropReagent(itemId)) then
            result[itemId] = true;
        end
    end

    return result;
end

--- Get the price for an item (vendor price preferred, then AH price).
-- Checks vendor prices first (fixed cost), then Auctionizer, then Auctionator, then TSM, then
-- the prices of the own auction house scan.
-- @param itemId The item ID to get the price for.
-- @return price in coppers and where it comes from ("vendor", "auctionizer",
--   "auctionator", "tsm", "scan" or "drop"), or nil if no price data available.
function AuctionService:GetItemPrice(itemId)
    -- check vendor price first (always available, fixed cost)
    local vendorPrice = self:GetVendorPrice(itemId);
    if (vendorPrice) then
        return vendorPrice, "vendor";
    end

    -- Auctionizer first: the cheapest auction it saw for the item
    local auctionizerApi = self:GetAuctionizerApi();
    if (auctionizerApi) then
        local price = auctionizerApi.GetPrice(itemId);
        if (price and price > 0) then
            return price, "auctionizer";
        end
    end

    -- try Auctionator
    if (Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID) then
        local success, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "ProfessionMaster", itemId);
        if (success and price and price > 0) then
            return price, "auctionator";
        end
    end

    -- fall back to TSM
    if (TSM_API and TSM_API.GetCustomPriceValue) then
        local itemString = "i:" .. itemId;
        local success, price = pcall(TSM_API.GetCustomPriceValue, "DBMarket", itemString);
        if (success and price and price > 0) then
            return price, "tsm";
        end
    end

    -- fall back to the own auction house scan
    local scanPrice = self:GetService("auction-scan"):GetPrice(itemId);
    if (scanPrice) then
        return scanPrice, "scan";
    end

    -- drop reagents never reach the auction house: free unless the user set a
    -- price for them in the reagent settings (e.g. what the guild charges)
    if (self:IsDropReagent(itemId)) then
        return 0, "drop";
    end

    return nil;
end

--- Check whether a price source of GetItemPrice is an auction house price.
-- @param source The price source.
-- @return boolean
function AuctionService:IsAuctionPriceSource(source)
    return source == "auctionizer" or source == "auctionator" or source == "tsm" or source == "scan";
end

--- Show the price charts of Auctionizer for an item at the mouse (its newest
--- price, the charts of 7 and 30 days); they follow the mouse until
--- HidePriceChart. Only a price that comes from Auctionizer has them.
-- @param itemId The item ID.
-- @param ownerFrame The hovered price; the charts leave with it.
-- @return true when the charts are shown.
function AuctionService:ShowPriceChart(itemId, ownerFrame)
    local api = self:GetAuctionizerApi();
    if (not api or (api.Version or 0) < self.PriceChartApiVersion or not itemId) then
        return false;
    end
    local _, source = self:GetItemPrice(itemId);
    if (source ~= "auctionizer") then
        return false;
    end
    return api.ShowPriceDetails(itemId, ownerFrame) == true;
end

--- Hide the price charts of Auctionizer.
function AuctionService:HidePriceChart()
    local api = self:GetAuctionizerApi();
    if (api and (api.Version or 0) >= self.PriceChartApiVersion) then
        api.HidePriceDetails();
    end
end

--- Get the quiet line for an auction house price without price charts: the
--- price comes from another addon or the own scan, and charts need Auctionizer.
-- @param itemId The item ID.
-- @return text, nil when the price has charts, is no auction house price or nothing is to say.
function AuctionService:GetPriceChartHint(itemId)
    local price, source = self:GetItemPrice(itemId);
    if (not price or source == "auctionizer" or not self:IsAuctionPriceSource(source)) then
        return nil;
    end
    local localeService = self:GetService("locale");

    -- not installed: charts would come with it, except on Cataclysm and
    -- Mists of Pandaria where Auctionizer stays passive
    if (_G.AuctionizerApi == nil) then
        if (self.addon.isCataAtLeast) then
            return nil;
        end
        return localeService:Get("PriceChartWithAuctionizer");
    end

    -- installed, but it never saw the item
    local api = self:GetAuctionizerApi();
    if (api and (api.Version or 0) >= self.PriceChartApiVersion) then
        return localeService:Get("PriceChartNotAvailable");
    end
    return nil;
end

--- Calculate profit for crafting a skill once.
-- Profit = (sell price of crafted item * itemAmount) - (sum of reagent costs).
-- @param skillId The spell ID of the skill.
-- @return profit in coppers (can be negative), or nil if price data is incomplete.
function AuctionService:GetSkillProfit(skillId)
    local skillsService = self:GetService("skills");
    local skillData = skillsService:GetSkillById(skillId);
    if (not skillData) then
        return nil;
    end

    -- get sell price of crafted item
    local itemId = skillData.itemId;
    if (not itemId) then
        return nil;
    end

    local itemPrice = self:GetItemPrice(itemId);
    if (not itemPrice) then
        return nil;
    end

    -- multiply by item amount (some skills craft multiple items)
    local itemAmount = skillData.itemAmount or 1;
    local revenue = itemPrice * itemAmount;

    -- calculate total reagent cost
    local reagents = skillData.reagents;
    if (not reagents) then
        return revenue;
    end

    local totalCost = 0;
    for reagentId, count in pairs(reagents) do
        local reagentPrice = self:GetItemPrice(reagentId);
        if (not reagentPrice) then
            return nil;
        end
        totalCost = totalCost + (reagentPrice * count);
    end

    return revenue - totalCost;
end

--- Format a profit value into a readable gold/silver/copper string.
-- Negative values get a red color and a single minus prefix.
-- @param coppers The profit in coppers (can be negative).
-- @return formatted profit string, or nil if zero/nil.
function AuctionService:FormatProfit(coppers)
    if (not coppers or coppers == 0) then
        return nil;
    end

    -- determine sign and absolute value
    local isNegative = coppers < 0;
    local absolute = math.abs(coppers);

    -- calculate gold, silver, copper
    local gold = math.floor(absolute / 10000);
    local silver = math.floor((absolute % 10000) / 100);
    local copper = absolute % 100;

    -- build formatted string with coin icons
    local parts = {};
    if (gold > 0) then
        table.insert(parts, gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12|t");
    end
    if (silver > 0) then
        table.insert(parts, silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12|t");
    end
    if (copper > 0) then
        table.insert(parts, copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12|t");
    end

    local text = table.concat(parts, " ");

    -- wrap in red color with minus prefix for negative values
    if (isNegative) then
        return "|cffff4040-" .. text .. "|r";
    end

    return text;
end
-- @param coppers The price in coppers.
-- @return formatted price string.
function AuctionService:FormatPrice(coppers)
    if (not coppers or coppers <= 0) then
        return nil;
    end

    -- calculate gold, silver, copper
    local gold = math.floor(coppers / 10000);
    local silver = math.floor((coppers % 10000) / 100);
    local copper = coppers % 100;

    -- build formatted string with coin icons
    local parts = {};
    if (gold > 0) then
        table.insert(parts, gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12|t");
    end
    if (silver > 0) then
        table.insert(parts, silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12|t");
    end
    if (copper > 0) then
        table.insert(parts, copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12|t");
    end

    return table.concat(parts, " ");
end
