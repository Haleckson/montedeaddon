--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local MailService = _G.professionMaster:CreateService("mail");

--- Initialize service.
function MailService:Initialize()
    if (not PM_CharacterSettings.mailCounts) then
        PM_CharacterSettings.mailCounts = {};
    end

    -- register events
    self:HandleEvent("MAIL_INBOX_UPDATE", function()
        self:ScanMail();
    end);
    self:HandleEvent("MAIL_CLOSED", function()
        self:ScanMail();
    end);
end

--- Scan mail attachments and cache item counts.
-- Only meaningful while the mailbox is open. COD mail is excluded.
function MailService:ScanMail()
    self.addon:Log("MailService", "ScanMail", "scanning mailbox attachments");

    local counts = {};
    local numItems = GetInboxNumItems();

    for mailIndex = 1, numItems do
        -- skip COD mail (can't take attachments without paying)
        local _, _, _, _, _, CODAmount = GetInboxHeaderInfo(mailIndex);
        if (not CODAmount or CODAmount == 0) then
            -- scan attachments in this mail
            for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
                local itemLink = GetInboxItemLink(mailIndex, attachIndex);
                if (itemLink) then
                    local _, itemId, _, itemCount = GetInboxItem(mailIndex, attachIndex);
                    if (itemId and itemCount and itemCount > 0) then
                        counts[itemId] = (counts[itemId] or 0) + itemCount;
                    end
                end
            end
        end
    end

    -- store in character settings
    PM_CharacterSettings.mailCounts = counts;
    self.addon:Log("MailService", "ScanMail", "mail scan complete, %d unique items cached", self:GetItemCount());

    -- refresh missing reagents
    self:GetService("inventory"):CheckMissingReagents();
end

--- Get cached mail count for an item.
-- @param itemId Item ID to look up.
-- @return Number of items in mail (from last scan).
function MailService:GetItemCount(itemId)
    if (not itemId) then
        -- return total unique item count
        local count = 0;
        for _ in pairs(PM_CharacterSettings.mailCounts or {}) do
            count = count + 1;
        end
        return count;
    end
    return (PM_CharacterSettings.mailCounts or {})[itemId] or 0;
end
