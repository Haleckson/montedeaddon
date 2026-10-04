--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local BankService = _G.professionMaster:CreateService("bank");

--- Initialize service.
function BankService:Initialize()
    if (not PM_CharacterSettings.bankCounts) then
        PM_CharacterSettings.bankCounts = {};
    end

    self.bankOpen = false;

    -- containers of the personal bank: the classic clients have the bank
    -- itself (-1) and the bank bags behind the equipped bags (5 to 11); a
    -- client with bank tabs has the reagent bag there, no bank container (-1
    -- is its keyring) and one bag per tab of the character behind it
    local inventoryConstants = (Constants and Constants.InventoryConstants) or {};
    if (inventoryConstants.NumCharacterBankSlots) then
        self.MainBankContainer = nil;
        self.FirstBankBag = NUM_BAG_SLOTS + (inventoryConstants.NumReagentBagSlots or 0) + 1;
        self.LastBankBag = self.FirstBankBag + inventoryConstants.NumCharacterBankSlots - 1;
    else
        self.MainBankContainer = -1;
        self.FirstBankBag = 5;
        self.LastBankBag = 11;
    end

    -- register events
    self:HandleEvent("BANKFRAME_OPENED", function()
        self.bankOpen = true;
        self:ScanBank();
    end);
    self:HandleEvent("BANKFRAME_CLOSED", function()
        self:ScanBank();
        self.bankOpen = false;
    end);
    self:HandleEvent("PLAYERBANKSLOTS_CHANGED", function()
        self:ScanBank();
    end);
    self:HandleEvent("BAG_UPDATE", function(bagId)
        -- rescan when a bank bag changes while bank is open
        if (self.bankOpen and bagId and bagId >= self.FirstBankBag and bagId <= self.LastBankBag) then
            if (not self.bankUpdatePending) then
                self.bankUpdatePending = true;
                C_Timer.After(0.2, function()
                    self.bankUpdatePending = nil;
                    self:ScanBank();
                end);
            end
        end
    end);
end

--- Scan personal bank slots and cache item counts.
-- Only meaningful while the bank frame is open.
function BankService:ScanBank()
    self.addon:Log("BankService", "ScanBank", "scanning personal bank");

    local counts = {};

    -- scan main bank container (-1), which only the classic clients have
    local mainContainer = self.MainBankContainer;
    local mainSlots = mainContainer and C_Container.GetContainerNumSlots(mainContainer) or 0;
    for slot = 1, mainSlots do
        local itemId = C_Container.GetContainerItemID(mainContainer, slot);
        local slotInfo = C_Container.GetContainerItemInfo(mainContainer, slot);
        if (itemId and slotInfo and slotInfo.stackCount) then
            counts[itemId] = (counts[itemId] or 0) + slotInfo.stackCount;
        end
    end

    -- scan bank bags (5-11) or bank tabs
    for bag = self.FirstBankBag, self.LastBankBag do
        local bagSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, bagSlots do
            local itemId = C_Container.GetContainerItemID(bag, slot);
            local slotInfo = C_Container.GetContainerItemInfo(bag, slot);
            if (itemId and slotInfo and slotInfo.stackCount) then
                counts[itemId] = (counts[itemId] or 0) + slotInfo.stackCount;
            end
        end
    end

    -- store in character settings
    PM_CharacterSettings.bankCounts = counts;
    self.addon:Log("BankService", "ScanBank", "bank scan complete, %d unique items cached", self:GetItemCount());

    -- refresh missing reagents
    self:GetService("inventory"):CheckMissingReagents();
end

--- Get cached bank count for an item.
-- @param itemId Item ID to look up.
-- @return Number of items in bank (from last scan).
function BankService:GetItemCount(itemId)
    if (not itemId) then
        -- return total unique item count
        local count = 0;
        for _ in pairs(PM_CharacterSettings.bankCounts or {}) do
            count = count + 1;
        end
        return count;
    end
    return (PM_CharacterSettings.bankCounts or {})[itemId] or 0;
end
