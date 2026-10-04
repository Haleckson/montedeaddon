-- BLib_Vendor.lua
-- What vendors charge, learned from every merchant window you open.
--
-- The client only says what a vendor PAYS for an item (GetItemInfo's sell
-- price); what it CHARGES is on the merchant's own list, and only while that
-- window is open. So every merchant is read as it opens, and each item's
-- price per unit is kept account-wide in BLibDB.vendorPrices: threads, dyes,
-- vials, salt and flux, and anything else a vendor sells for gold.
--
--   BLib.VendorPrice(itemID) -> copper per unit, when it was seen, and
--                               whether the vendor had only a limited stock;
--                               nil when no vendor has been seen selling it.
--
-- The LOWEST price seen is kept: reputation discounts make one vendor cheaper
-- than another for the same thread, and the cheapest is what planning should
-- assume. Items bought with currency or other items (hasExtendedCost) are
-- left out: they have no price in gold.
--
-- Forever has no GetMerchantItemInfo (ForeverProbe); C_MerchantFrame.GetItemInfo
-- returns a table, and calls the per-purchase quantity stackCount.

local function Store()
    if not BLibDB then return nil end
    BLibDB.vendorPrices = BLibDB.vendorPrices or {}
    return BLibDB.vendorPrices
end

local function ItemIDAt(i)
    if GetMerchantItemID then
        local ok, id = pcall(GetMerchantItemID, i)
        if ok and tonumber(id) then return tonumber(id) end
    end
    if GetMerchantItemLink then
        local ok, link = pcall(GetMerchantItemLink, i)
        if ok and type(link) == "string" then return tonumber(link:match("item:(%d+)")) end
    end
    return nil
end

local function ReadMerchant()
    local store = Store()
    if not (store and C_MerchantFrame and C_MerchantFrame.GetItemInfo and GetMerchantNumItems) then return end
    local okN, n = pcall(GetMerchantNumItems)
    n = okN and tonumber(n) or 0
    local now = time()
    for i = 1, n do
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
        local id = ok and info and ItemIDAt(i)
        local price = id and tonumber(info.price)
        if price and price > 0 and not info.hasExtendedCost then
            local each = price / math.max(tonumber(info.stackCount) or 1, 1)
            local old = store[id]
            -- Lowest seen wins; the same price seen again refreshes the date.
            -- isPurchasable is false for what you may not buy yet, which is how
            -- a vendor shows a pattern needing more reputation than you have.
            local canBuy = info.isPurchasable ~= false
            if not old or each <= old.p or (canBuy and old.noBuy) then
                -- numAvailable is -1 for unlimited stock; a positive count is a
                -- limited item, which planning should not count on in bulk.
                store[id] = {
                    p = each, t = now, limited = (tonumber(info.numAvailable) or -1) > 0 or nil,
                    noBuy = (not canBuy) or nil,
                }
            end
        end
    end
end

-- Copper per unit, when it was seen (time()), whether stock was limited, and
-- whether the vendor would NOT sell it to you (reputation, usually).
function BLib.VendorPrice(itemID)
    local store = Store()
    local e = store and itemID and store[itemID]
    if not e then return nil end
    return e.p, e.t, e.limited and true or false, e.noBuy and true or false
end

-- Every item a vendor has been seen selling, for addons that match by name.
function BLib.VendorItems()
    return Store() or {}
end

local vendorFrame = CreateFrame("Frame")
vendorFrame:RegisterEvent("MERCHANT_SHOW")
vendorFrame:SetScript("OnEvent", function()
    -- A frame later: the list is filled as the window opens.
    if C_Timer and C_Timer.After then C_Timer.After(0, ReadMerchant) else ReadMerchant() end
end)
