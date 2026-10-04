--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel
local BucketListPanel = _G.professionMaster:CreateView("bucket-list-panel");

--- Create bucket list panel frames.
-- @param parentFrame The parent view frame to attach to.
-- @param professionsView Reference to the parent professions view.
function BucketListPanel:Create(parentFrame, professionsView)
    self.professionsView = professionsView;
    self.reagentRows = {};

    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- refresh the requested markers as soon as trade board data changes (only
    -- with a TradeBoard version that has the request host API)
    if (self.addon:IsTradeBoardCompatible()) then
        _G.tradeBoard:OnTradeDataChanged(function()
            if (not self.frame or not self.frame:IsShown()) then return; end
            for _, reagentRow in ipairs(self.reagentRows) do
                if (reagentRow:IsShown()) then
                    self:UpdateCraftButtonVisibility(reagentRow);
                end
            end
        end);
    end

    -- add bucket list frame
    local frame = uiService:CreatePanel(parentFrame);
    if (uiService:IsForever()) then
        -- forever style: inset like the lists, a little lower and shorter
        frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", -302, -8);
        frame:SetPoint("BOTTOMRIGHT", -8, 8);
    else
        frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", -302, 0);
        frame:SetPoint("BOTTOMRIGHT", 0, 0);
    end
    self.frame = frame;

    -- add bucket list scroll frame
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(frame);
    scrollParent:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -35);
    scrollParent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
    scrollParent:SetBackdropColor(0, 0, 0, 0);
    scrollChild:SetWidth(scrollParent:GetWidth());
    self.scrollChild = scrollChild;
    self.scrollElement = scrollElement;

    -- add bucket list title text
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    titleText:SetPoint("TOPLEFT", 13, -15);
    titleText:SetText(localeService:Get("ProfessionsViewBucketList"));

    -- add bucket list clear button
    local clearButton = uiService:CreateFlatSquareButton(frame, "x", function()
        PM_BucketList = {};
        professionsView:CheckBucketList();
        self:GetService("inventory"):CheckMissingReagents();
    end, 20);
    clearButton:SetPoint("TOPRIGHT", -8, -10);
    uiService:BindTooltip(clearButton, localeService:Get("ProfessionsViewClearBucketList"), "ANCHOR_RIGHT");

    -- add bulk search button (left of clear, only if AH addon available)
    local auctionService = self:GetService("auction");
    local canSearchAH = auctionService:CheckMultiSearchAvailable();
    if (canSearchAH) then
        local bulkSearchButton = CreateFrame("Button", nil, frame);
        bulkSearchButton:SetSize(20, 20);
        bulkSearchButton:SetPoint("RIGHT", clearButton, "LEFT", -4, 0);
        self.bulkSearchButton = bulkSearchButton;

        -- add search icon
        local searchIcon = bulkSearchButton:CreateTexture(nil, "ARTWORK");
        searchIcon:SetPoint("TOPLEFT", 2, -2);
        searchIcon:SetPoint("BOTTOMRIGHT", -2, 2);
        searchIcon:SetTexture([[Interface\Icons\INV_Misc_Spyglass_03]]);
        bulkSearchButton.icon = searchIcon;

        -- add border overlay
        local searchBorder = bulkSearchButton:CreateTexture(nil, "OVERLAY");
        searchBorder:SetPoint("TOPLEFT", -1, 1);
        searchBorder:SetPoint("BOTTOMRIGHT", 1, -1);
        searchBorder:SetTexture([[Interface\Buttons\UI-ActionButton-Border]]);
        searchBorder:SetBlendMode("ADD");
        bulkSearchButton.border = searchBorder;

        -- update search button visual state
        bulkSearchButton.UpdateState = function(btn)
            if (auctionService:IsOpen()) then
                btn.border:SetVertexColor(0.2, 0.8, 1.0, 0.8);
                btn.icon:SetDesaturated(false);
            else
                btn.border:SetVertexColor(0.5, 0.5, 0.5, 0.5);
                btn.icon:SetDesaturated(true);
            end
        end;

        -- handle click to search all items
        bulkSearchButton:SetScript("OnClick", function()
            if (not auctionService:IsOpen()) then
                return;
            end

            -- collect all visible item names and ids from bucket list reagents
            local itemNames = {};
            local itemIds = {};
            local seenIds = {};
            for _, row in ipairs(self.reagentRows) do
                if (row:IsShown() and row.craftItemId and not seenIds[row.craftItemId]) then
                    local itemName = C_Item.GetItemNameByID(row.craftItemId);
                    if (not itemName) then
                        itemName = self.addon.compat.GetItemInfo(row.craftItemId);
                    end
                    if (itemName) then
                        seenIds[row.craftItemId] = true;
                        table.insert(itemNames, itemName);
                        table.insert(itemIds, row.craftItemId);
                    end
                end
            end

            -- search for all items
            if (#itemNames > 0) then
                auctionService:SearchForMultiple(itemNames, itemIds);
            end
        end);

        -- tooltip for search button
        bulkSearchButton:SetScript("OnEnter", function(btn)
            btn:UpdateState();
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT");
            if (auctionService:IsOpen()) then
                GameTooltip:SetText(localeService:Get("BulkSearchAH"));
            else
                GameTooltip:SetText(localeService:Get("BulkSearchAHClosed"));
            end
            GameTooltip:Show();
        end);
        bulkSearchButton:SetScript("OnLeave", function()
            GameTooltip:Hide();
        end);

        -- initial state
        bulkSearchButton:UpdateState();
    end
end

--- Handle resize event.
function BucketListPanel:OnSizeChanged()
    if (self.scrollChild and self.scrollElement) then
        self.scrollChild:SetWidth(self.scrollElement:GetWidth());
    end
end

--- Check if bucket list has any items.
-- @return boolean True if bucket list has items.
function BucketListPanel:HasItems()
    for _ in pairs(PM_BucketList) do
        return true;
    end
    return false;
end

--- Show frame.
function BucketListPanel:Show()
    if (self.frame) then
        self.frame:Show();
    end
end

--- Hide frame.
function BucketListPanel:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

--- Refresh bucket list rows.
function BucketListPanel:Refresh()
    -- hide rows
    for _, row in ipairs(self.reagentRows) do
        row:Hide();
    end

    -- get services
    local inventoryService = self:GetService("inventory");
    local skillsService = self:GetService("skills");
    local professionNamesService = self:GetService("profession-names");

    -- scan inventory once
    inventoryService:ScanInventory();

    -- build tree
    local treeRows = self:BuildTree(skillsService, inventoryService);

    -- calculate vertical positions with spacing before root nodes
    local currentTop = 0;
    for i, treeRow in ipairs(treeRows) do
        if (treeRow.isSeparator) then
            currentTop = currentTop + 10;
            treeRow.top = currentTop;
            currentTop = currentTop + 23;
        else
            if (treeRow.isNode and i > 1) then
                currentTop = currentTop + 6;
            end
            treeRow.top = currentTop;
            currentTop = currentTop + 20;
        end
    end

    -- render separator line
    if (not self.separator) then
        local separator = self.scrollChild:CreateTexture(nil, "OVERLAY");
        separator:SetColorTexture(0.4, 0.4, 0.4, 0.6);
        separator:SetHeight(1);
        self.separator = separator;
    end
    self.separator:Hide();

    -- create missing reagents header if not exists
    if (not self.missingReagentsHeader) then
        local header = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.missingReagentsHeader = header;
    end
    self.missingReagentsHeader:Hide();

    -- render tree rows
    local rowIndex = 0;
    local localeService = self:GetService("locale");
    for _, treeRow in ipairs(treeRows) do
        -- handle separator
        if (treeRow.isSeparator) then
            self.separator:ClearAllPoints();
            self.separator:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 10, -treeRow.top);
            self.separator:SetPoint("RIGHT", self.scrollChild, "RIGHT", -30, 0);
            self.separator:Show();

            -- show missing reagents header below separator
            self.missingReagentsHeader:ClearAllPoints();
            self.missingReagentsHeader:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 10, -(treeRow.top + 9));
            self.missingReagentsHeader:SetText(localeService:Get("ProfessionsViewCraftSelf"));
            self.missingReagentsHeader:Show();
        else

        rowIndex = rowIndex + 1;
        if (#self.reagentRows < rowIndex) then
            -- create row frame
            local reagentRow = CreateFrame("Button", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
            reagentRow:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]]
            });

            -- bind row mouse events
            reagentRow:SetScript("OnLeave", function()
                C_Timer.After(0, function()
                    if (not reagentRow:IsVisible()) then return; end
                    local overRow = reagentRow:IsMouseOver();
                    local overButton = reagentRow.craftButton:IsVisible() and reagentRow.craftButton:IsMouseOver();
                    local overAh = reagentRow.ahButton and reagentRow.ahButton:IsVisible() and reagentRow.ahButton:IsMouseOver();
                    local overRequest = reagentRow.requestButton and reagentRow.requestButton:IsVisible() and reagentRow.requestButton:IsMouseOver();
                    self:UpdateReagentRowHoverState(reagentRow);
                    if (not overRow and not overButton and not overAh and not overRequest and GameTooltip:GetOwner() == reagentRow) then
                        GameTooltip:Hide();
                    end
                end);
            end);
            reagentRow:SetScript("OnEnter", function()
                self:UpdateReagentRowHoverState(reagentRow);
                if (reagentRow.itemLink) then
                    GameTooltip:SetOwner(reagentRow, "ANCHOR_LEFT");
                    GameTooltip:SetHyperlink(reagentRow.itemLink);
                    GameTooltip:Show();
                end
            end);

            -- add icon text
            local iconText = reagentRow:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            reagentRow.iconText = iconText;

            -- add amount text
            local amountText = reagentRow:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            amountText:SetPoint("TOPRIGHT", -3, -4);
            amountText:SetJustifyH("RIGHT");
            reagentRow.amountText = amountText;

            -- add amount tooltip overlay (for bank/mail info)
            local amountTooltip = CreateFrame("Frame", nil, reagentRow);
            amountTooltip:SetPoint("TOPLEFT", amountText, "TOPLEFT", 0, 0);
            amountTooltip:SetPoint("BOTTOMRIGHT", amountText, "BOTTOMRIGHT", 0, 0);
            amountTooltip:EnableMouse(true);
            self:GetService("ui"):BindTooltip(amountTooltip, function()
                return reagentRow.sourceTooltipText;
            end, "ANCHOR_RIGHT");
            reagentRow.amountTooltip = amountTooltip;

            -- add ah search button (directly left of amount)
            local ahButton = CreateFrame("Button", nil, reagentRow);
            ahButton:SetSize(14, 14);
            ahButton:SetPoint("RIGHT", amountText, "LEFT", -2, 0);
            local ahIcon = ahButton:CreateTexture(nil, "ARTWORK");
            ahIcon:SetAllPoints();
            ahIcon:SetTexture([[Interface\Icons\INV_Misc_Spyglass_03]]);
            ahButton.icon = ahIcon;
            ahButton:SetScript("OnClick", function()
                if (self:GetService("auction"):IsOpen()) then
                    self:OnAhButtonClicked(reagentRow);
                end
            end);
            ahButton:SetScript("OnEnter", function()
                self:UpdateReagentRowHoverState(reagentRow);
                GameTooltip:SetOwner(ahButton, "ANCHOR_RIGHT");
                local localeService = self:GetService("locale");
                if (self:GetService("auction"):IsOpen()) then
                    GameTooltip:SetText(localeService:Get("BucketListSearchAH"));
                else
                    GameTooltip:SetText(localeService:Get("BucketListSearchAHClosed"));
                end
                GameTooltip:Show();
            end);
            ahButton:SetScript("OnLeave", function()
                C_Timer.After(0, function()
                    self:UpdateReagentRowHoverState(reagentRow);
                    if (reagentRow:IsMouseOver() and reagentRow.itemLink) then
                        GameTooltip:SetOwner(reagentRow, "ANCHOR_LEFT");
                        GameTooltip:SetHyperlink(reagentRow.itemLink);
                        GameTooltip:Show();
                    else
                        GameTooltip:Hide();
                    end
                end);
            end);
            ahButton:Hide();
            reagentRow.ahButton = ahButton;

            -- add craft button (hammer, left of ah button)
            local craftButton = CreateFrame("Button", nil, reagentRow);
            craftButton:SetSize(14, 14);
            craftButton:SetPoint("RIGHT", ahButton, "LEFT", -2, 0);
            local craftIcon = craftButton:CreateTexture(nil, "ARTWORK");
            craftIcon:SetAllPoints();
            craftIcon:SetTexture([[Interface\Icons\INV_Hammer_01]]);
            craftButton.icon = craftIcon;
            local craftText = craftButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            craftText:SetAllPoints();
            craftText:SetJustifyH("CENTER");
            craftText:SetJustifyV("MIDDLE");
            craftText:SetText("x");
            craftText:SetTextColor(1, 0.4, 0.4);
            craftText:Hide();
            craftButton.text = craftText;
            craftButton:SetScript("OnClick", function()
                self:OnCraftButtonClicked(reagentRow);
            end);
            craftButton:SetScript("OnEnter", function()
                self:UpdateReagentRowHoverState(reagentRow);
                GameTooltip:SetOwner(craftButton, "ANCHOR_RIGHT");
                local tooltipKey = "ProfessionsViewCraftSelf";
                if (reagentRow.craftButtonMode == "remove-watch") then
                    tooltipKey = "ProfessionsViewRemoveFromWatchList";
                elseif (reagentRow.craftButtonMode == "remove-bucket") then
                    tooltipKey = "ProfessionsViewRemoveFromBucketList";
                end
                GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
                GameTooltip:Show();
            end);
            craftButton:SetScript("OnLeave", function()
                C_Timer.After(0, function()
                    self:UpdateReagentRowHoverState(reagentRow);
                    if (reagentRow:IsMouseOver() and reagentRow.itemLink) then
                        GameTooltip:SetOwner(reagentRow, "ANCHOR_LEFT");
                        GameTooltip:SetHyperlink(reagentRow.itemLink);
                        GameTooltip:Show();
                    else
                        GameTooltip:Hide();
                    end
                end);
            end);
            craftButton:Hide();
            reagentRow.craftButton = craftButton;

            -- add trade board request button (letter, left of the craft button;
            -- overlaid red when the item is already requested = click removes)
            local requestButton = CreateFrame("Button", nil, reagentRow);
            requestButton:SetSize(14, 14);
            requestButton:SetPoint("RIGHT", craftButton, "LEFT", -2, 0);
            local requestIcon = requestButton:CreateTexture(nil, "ARTWORK");
            requestIcon:SetAllPoints();
            requestIcon:SetTexture([[Interface\Icons\INV_Letter_12]]);
            requestButton.icon = requestIcon;
            requestButton:SetScript("OnClick", function()
                self:OnRequestButtonClicked(reagentRow);
            end);
            requestButton:SetScript("OnEnter", function()
                self:UpdateReagentRowHoverState(reagentRow);
                GameTooltip:SetOwner(requestButton, "ANCHOR_RIGHT");
                local tooltipKey = (self.addon:IsTradeBoardCompatible() and reagentRow.craftItemId and _G.tradeBoard:HasOwnRequest("item", reagentRow.craftItemId))
                    and "TradeBoardEditRequest" or "TradeBoardRequestItem";
                GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
                GameTooltip:Show();
            end);
            requestButton:SetScript("OnLeave", function()
                C_Timer.After(0, function()
                    self:UpdateReagentRowHoverState(reagentRow);
                    if (reagentRow:IsMouseOver() and reagentRow.itemLink) then
                        GameTooltip:SetOwner(reagentRow, "ANCHOR_LEFT");
                        GameTooltip:SetHyperlink(reagentRow.itemLink);
                        GameTooltip:Show();
                    else
                        GameTooltip:Hide();
                    end
                end);
            end);
            requestButton:Hide();
            reagentRow.requestButton = requestButton;

            -- small always-visible marker while the item is requested (hidden
            -- on hover, the red request button shows the state then)
            local requestedIcon = reagentRow:CreateTexture(nil, "ARTWORK");
            requestedIcon:SetSize(12, 12);
            requestedIcon:SetPoint("RIGHT", amountText, "LEFT", -2, 0);
            requestedIcon:SetTexture([[Interface\Icons\INV_Letter_12]]);
            requestedIcon:Hide();
            reagentRow.requestedIcon = requestedIcon;

            -- add item text
            local itemText = reagentRow:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            itemText:SetPoint("BOTTOMRIGHT", requestButton, "BOTTOMLEFT", -6, 0);
            itemText:SetJustifyH("LEFT");
            itemText:SetJustifyV("TOP");
            reagentRow.itemText = itemText;

            -- purple hover glow (border + purple backdrop), kept alive by the row buttons and tooltip overlay
            self:GetService("ui"):AttachHoverGlow(reagentRow, { amountTooltip, ahButton, craftButton, requestButton });

            -- add row
            table.insert(self.reagentRows, reagentRow);
        end

        -- get row
        local reagentRow = self.reagentRows[rowIndex];
        local indent = treeRow.indent;
        local top = treeRow.top;
        reagentRow:ClearAllPoints();
        reagentRow:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 8 + indent * 12, -top);
        reagentRow:SetPoint("BOTTOMRIGHT", self.scrollChild, "TOPRIGHT", -26, -(top + 20));

        -- set background color (nodes stay below the gray hover shades, the
        -- classic style draws every shade from 0.2 on as hover)
        local backgroundColor;
        if (treeRow.isNode) then
            backgroundColor = 0.18;
        elseif (rowIndex % 2 == 0) then
            backgroundColor = 0.08;
        else
            backgroundColor = 0.12;
        end
        reagentRow.bgColor = backgroundColor;
        reagentRow:SetBackdropColor(backgroundColor, backgroundColor, backgroundColor, 0.5);

        -- position icon and item text
        reagentRow.iconText:ClearAllPoints();
        reagentRow.iconText:SetPoint("TOPLEFT", 3, -3);
        reagentRow.itemText:ClearAllPoints();
        reagentRow.itemText:SetPoint("TOPLEFT", 24, -4);
        reagentRow.itemText:SetPoint("BOTTOMRIGHT", reagentRow.requestButton, "BOTTOMLEFT", -6, 0);

        reagentRow:Show();
        reagentRow.itemLink = nil;
        reagentRow.craftButton:Hide();
        reagentRow.isIndented = indent > 0;
        reagentRow.craftItemId = treeRow.itemId;
        reagentRow.isWatchListRoot = treeRow.isWatchListRoot == true;
        reagentRow.isBucketListRoot = treeRow.isBucketListRoot == true;
        reagentRow.bucketSkillId = treeRow.skillId;
        -- indented reagents are self-craftable when a conversion or profession recipe produces them
        reagentRow.canSelfCraft = reagentRow.isIndented and treeRow.canSelfCraft == true;
        reagentRow.craftButtonMode = nil;
        if (reagentRow.isWatchListRoot) then
            reagentRow.craftButtonMode = "remove-watch";
            reagentRow.craftButton.icon:Hide();
            reagentRow.craftButton.text:Show();
        elseif (reagentRow.isBucketListRoot and reagentRow.bucketSkillId) then
            reagentRow.craftButtonMode = "remove-bucket";
            reagentRow.craftButton.icon:Hide();
            reagentRow.craftButton.text:Show();
        elseif (reagentRow.canSelfCraft) then
            reagentRow.craftButtonMode = "toggle-watch";
            reagentRow.craftButton.icon:SetTexture([[Interface\Icons\INV_Hammer_01]]);
            reagentRow.craftButton.icon:Show();
            reagentRow.craftButton.text:Hide();
        else
            reagentRow.craftButton.icon:SetTexture([[Interface\Icons\INV_Hammer_01]]);
            reagentRow.craftButton.icon:Show();
            reagentRow.craftButton.text:Hide();
        end

        -- update amount
        local stocks = treeRow.stocks;
        local amount = treeRow.amount;

        -- the still missing amount prefills the trade board request dialog;
        -- the requested marker is refreshed with the buttons
        reagentRow.missingAmount = math.max((amount or 0) - (stocks or 0), 0);
        self:UpdateCraftButtonVisibility(reagentRow);
        if (amount > 0) then
            if (treeRow.itemId and treeRow.itemId > 0) then
                -- build single-line amount: [mail_icon count]  [bank_icon count]  bags/needed
                local bagStocks = treeRow.bagStocks or stocks;
                local bankStocks = treeRow.bankStocks or 0;
                local mailStocks = treeRow.mailStocks or 0;

                local parts = {};
                local tooltipParts = {};
                local localeService = self:GetService("locale");
                if (mailStocks > 0) then
                    table.insert(parts, "|TInterface\\Minimap\\Tracking\\Mailbox:10|t" .. mailStocks);
                    table.insert(tooltipParts, mailStocks .. " " .. localeService:Get("SourceTooltipMail"));
                end
                if (bankStocks > 0) then
                    table.insert(parts, "|TInterface\\Minimap\\Tracking\\Banker:10|t" .. bankStocks);
                    table.insert(tooltipParts, bankStocks .. " " .. localeService:Get("SourceTooltipBank"));
                end
                table.insert(parts, math.min(bagStocks, amount) .. "/" .. amount);

                reagentRow.amountText:SetText(table.concat(parts, "  "));
                reagentRow.sourceTooltipText = #tooltipParts > 0 and table.concat(tooltipParts, "\n") or nil;
                if (stocks >= amount) then
                    reagentRow.amountText:SetTextColor(0, 1, 0);
                else
                    reagentRow.amountText:SetTextColor(1, 1, 1);
                end
            else
                reagentRow.amountText:SetText(amount);
                reagentRow.amountText:SetTextColor(1, 1, 1);
            end
        else
            reagentRow.amountText:SetText("");
        end

        -- set text style based on node type
        if (treeRow.isNode) then
            reagentRow.itemText:SetFontObject("GameFontNormal");
            reagentRow.amountText:SetFontObject("GameFontNormal");
        else
            reagentRow.itemText:SetFontObject("GameFontHighlightSmall");
            reagentRow.amountText:SetFontObject("GameFontHighlightSmall");
        end

        -- load item or spell info
        local reagentItemId = treeRow.itemId;
        local rowItemAmount = treeRow.itemAmount;
        if (reagentItemId and reagentItemId > 0 and C_Item.DoesItemExistByID(reagentItemId)) then
            local item = Item:CreateFromItemID(reagentItemId);
            if (not item:IsItemEmpty()) then
                pcall(function()
                    item:ContinueOnItemLoad(function()
                        reagentRow.itemLink = item:GetItemLink();
                        reagentRow.iconText:SetText("|T" .. item:GetItemIcon() .. ":16|t");
                        local itemName = "|c" .. professionNamesService:GetItemColor(reagentRow.itemLink) .. item:GetItemName();
                        if (rowItemAmount and rowItemAmount > 1) then
                            itemName = itemName .. "|r x" .. rowItemAmount;
                        end
                        reagentRow.itemText:SetText(itemName);
                    end);
                end);
            end
        elseif (treeRow.skillId) then
            local skillInfo = skillsService:GetSkillById(treeRow.skillId);
            if (skillInfo and skillInfo.skillLink) then
                reagentRow.itemLink = skillInfo.skillLink;
                reagentRow.iconText:SetText("|T" .. (skillInfo.icon or 136243) .. ":16|t");
                local itemName = "|c" .. (skillInfo.itemColor or "FF71D5FF") .. (skillInfo.name or "");
                if (rowItemAmount and rowItemAmount > 1) then
                    itemName = itemName .. "|r x" .. rowItemAmount;
                end
                reagentRow.itemText:SetText(itemName);
            else
                local spellName, _, spellIcon = self.addon.compat.GetSpellInfo(treeRow.skillId);
                if (spellName) then
                    reagentRow.itemLink = "|cFF71D5FF|Henchant:" .. treeRow.skillId .. "|h[" .. spellName .. "]|h|r";
                    reagentRow.iconText:SetText("|T" .. (spellIcon or 136243) .. ":16|t");
                    local itemName = "|cFF71D5FF" .. spellName;
                    if (rowItemAmount and rowItemAmount > 1) then
                        itemName = itemName .. "|r x" .. rowItemAmount;
                    end
                    reagentRow.itemText:SetText(itemName);
                end
            end
        end
    end -- if not separator
    end -- for treeRows

    -- update scroll child height
    self.scrollChild:SetHeight(currentTop + 5);
end

--- Show or hide craft button and AH button for a hovered bucket list row.
-- @param reagentRow Bucket list reagent row.
function BucketListPanel:UpdateCraftButtonVisibility(reagentRow)
    if (not reagentRow or not reagentRow.craftButton) then
        return;
    end

    local isHover = reagentRow:IsMouseOver() or reagentRow.craftButton:IsMouseOver()
        or (reagentRow.ahButton and reagentRow.ahButton:IsMouseOver())
        or (reagentRow.requestButton and reagentRow.requestButton:IsMouseOver());

    -- craft button
    local canShowButton = reagentRow.craftButtonMode ~= nil;
    if (canShowButton and isHover) then
        reagentRow.craftButton:Show();
    else
        reagentRow.craftButton:Hide();
    end

    -- ah button (on hover for indented reagent rows, grayed when AH closed)
    if (reagentRow.ahButton) then
        if (isHover and reagentRow.isIndented and reagentRow.craftItemId) then
            local auctionService = self:GetService("auction");
            reagentRow.ahButton:Show();
            if (auctionService:IsOpen()) then
                reagentRow.ahButton.icon:SetDesaturated(false);
                reagentRow.ahButton.icon:SetAlpha(1);
            else
                reagentRow.ahButton.icon:SetDesaturated(true);
                reagentRow.ahButton.icon:SetAlpha(0.5);
            end
        else
            reagentRow.ahButton:Hide();
        end
    end

    -- trade board request button (on hover; opens the dialog to create or edit
    -- the request) plus the persistent requested marker while not hovering;
    -- only with a TradeBoard version that has the request host API
    if (reagentRow.requestButton) then
        local canRequest = self.addon:IsTradeBoardCompatible()
            and reagentRow.craftItemId ~= nil and reagentRow.craftItemId > 0;
        local requested = canRequest and _G.tradeBoard:HasOwnRequest("item", reagentRow.craftItemId) or false;
        reagentRow.requestButton:SetShown(canRequest and isHover);
        reagentRow.requestedIcon:SetShown(requested and not isHover);
    end
end

--- Update hover visuals for bucket list row and craft button.
-- @param reagentRow Bucket list reagent row.
function BucketListPanel:UpdateReagentRowHoverState(reagentRow)
    if (not reagentRow) then
        return;
    end

    local isHovered = reagentRow:IsMouseOver() or (reagentRow.craftButton and reagentRow.craftButton:IsMouseOver())
        or (reagentRow.ahButton and reagentRow.ahButton:IsMouseOver())
        or (reagentRow.requestButton and reagentRow.requestButton:IsMouseOver());
    if (isHovered) then
        reagentRow:SetBackdropColor(0.2, 0.2, 0.2);
    else
        reagentRow:SetBackdropColor(reagentRow.bgColor, reagentRow.bgColor, reagentRow.bgColor, 0.5);
    end

    self:UpdateCraftButtonVisibility(reagentRow);
end

--- Handle click on AH search button.
-- @param reagentRow Bucket list reagent row.
function BucketListPanel:OnAhButtonClicked(reagentRow)
    if (not reagentRow or not reagentRow.craftItemId) then
        return;
    end

    -- get item name from the item id
    local itemName = C_Item.GetItemNameByID(reagentRow.craftItemId);
    if (not itemName) then
        itemName = self.addon.compat.GetItemInfo(reagentRow.craftItemId);
    end

    if (itemName) then
        self:GetService("auction"):SearchFor(itemName, reagentRow.craftItemId);
    end
end

--- Handle click on the trade board request button in a bucket list row:
--- opens the request dialog prefilled with the missing amount (an existing own
--- request opens in edit mode to change or delete it).
-- @param reagentRow Bucket list reagent row.
function BucketListPanel:OnRequestButtonClicked(reagentRow)
    if (not self.addon:IsTradeBoardCompatible() or not reagentRow or not reagentRow.craftItemId) then
        return;
    end

    GameTooltip:Hide();
    _G.tradeBoard:OpenRequestDialog("item", reagentRow.craftItemId, reagentRow.missingAmount);

    -- reset the hover state: the dialog may open right under the mouse, then
    -- the row never receives a leave event
    reagentRow.craftButton:Hide();
    if (reagentRow.ahButton) then reagentRow.ahButton:Hide(); end
    reagentRow.requestButton:Hide();
    reagentRow.requestedIcon:SetShown(_G.tradeBoard:HasOwnRequest("item", reagentRow.craftItemId));
    if (reagentRow.bgColor) then
        reagentRow:SetBackdropColor(reagentRow.bgColor, reagentRow.bgColor, reagentRow.bgColor, 0.5);
    end
    if (reagentRow.hoverGlowHide) then reagentRow.hoverGlowHide(); end
end

--- Handle click on craft button in bucket list row.
-- @param reagentRow Bucket list reagent row.
function BucketListPanel:OnCraftButtonClicked(reagentRow)
    if (not reagentRow or not reagentRow.craftButtonMode) then
        return;
    end

    local inventoryService = self:GetService("inventory");

    if (not PM_ReagentWatchList) then
        PM_ReagentWatchList = {};
    end

    if (reagentRow.craftButtonMode == "remove-watch") then
        PM_ReagentWatchList[reagentRow.craftItemId] = nil;
    elseif (reagentRow.craftButtonMode == "remove-bucket") then
        PM_BucketList[reagentRow.bucketSkillId] = nil;
        self.professionsView:RefreshActiveTab();
        self.professionsView:CheckBucketList();
        inventoryService:CheckMissingReagents();
        return;
    elseif (PM_ReagentWatchList[reagentRow.craftItemId]) then
        PM_ReagentWatchList[reagentRow.craftItemId] = nil;
    else
        PM_ReagentWatchList[reagentRow.craftItemId] = true;
    end

    inventoryService:CheckMissingReagents();
end

--- Build a flat tree of bucket list nodes and their reagents.
-- @param skillsService Skills service reference.
-- @param inventoryService Inventory service reference.
-- @return Array of { itemId, skillId, amount, stocks, indent, isNode }.
function BucketListPanel:BuildTree(skillsService, inventoryService)
    local directRows = {};
    local derivedRows = {};
    local visited = {};
    local watchedReagents = PM_ReagentWatchList or {};

    -- resolve a node's reagents and produced amount: conversion nodes carry their own
    -- reagents inline, profession nodes resolve them from the skill definition
    local function resolveCraft(node)
        if (node.reagents ~= nil) then
            return node.reagents, node.itemAmount;
        end
        local skillInfo = skillsService:GetSkillById(node.skillId);
        if (skillInfo) then
            return skillInfo.reagents, skillInfo.itemAmount;
        end
        return nil, nil;
    end

    -- collect initial nodes from bucket list
    local currentNodes = {};
    for skillId, skillAmount in pairs(PM_BucketList) do
        local skillInfo = skillsService:GetSkillById(skillId);
        if (skillInfo) then
            table.insert(currentNodes, {
                itemId = skillInfo.itemId,
                skillId = skillId,
                amount = skillAmount,
            });
        end
    end

    -- first pass: direct bucket list items and their reagents
    local nextReagents = {};
    for _, node in ipairs(currentNodes) do
        local stocks = 0;
        if (node.itemId and node.itemId > 0) then
            stocks = inventoryService:GetItemAmount(node.itemId);
        end

        -- resolve reagents and produced amount (conversion nodes carry their own)
        local nodeReagents, nodeItemAmount = resolveCraft(node);

        -- convert to craft units for display
        local displayAmount = node.amount;
        local displayStocks = stocks;
        if (nodeItemAmount and nodeItemAmount > 1) then
            displayAmount = math.ceil(node.amount / nodeItemAmount);
            displayStocks = math.floor(stocks / nodeItemAmount);
        end

        -- add main node row
        table.insert(directRows, {
            itemId = node.itemId,
            skillId = node.skillId,
            amount = displayAmount,
            stocks = displayStocks,
            indent = 0,
            isNode = true,
            isBucketListRoot = true,
            itemAmount = nodeItemAmount,
        });

        -- calculate missing quantity
        local missing;
        if (node.itemId and node.itemId > 0) then
            missing = math.max(0, node.amount - stocks);
        else
            missing = node.amount;
        end

        -- add reagent rows for missing amount
        if (missing > 0) then
            if (nodeReagents) then
                local craftsNeeded = math.ceil(missing / (nodeItemAmount or 1));
                for reagentItemId, reagentPerCraft in pairs(nodeReagents) do
                    local needed = craftsNeeded * reagentPerCraft;
                    local reagentStocks = inventoryService:GetItemAmount(reagentItemId);
                    local reagentMissing = math.max(0, needed - reagentStocks);

                    -- resolve how the player could craft this reagent (conversion first, then profession)
                    local craftInfo = skillsService:GetSelfCraftInfo(reagentItemId);

                    -- always show reagents under parent
                    table.insert(directRows, {
                        itemId = reagentItemId,
                        amount = needed,
                        stocks = reagentStocks,
                        bagStocks = inventoryService:GetBagAmount(reagentItemId),
                        bankStocks = self:GetService("bank"):GetItemCount(reagentItemId),
                        mailStocks = self:GetService("mail"):GetItemCount(reagentItemId),
                        indent = 1,
                        isNode = false,
                        canSelfCraft = craftInfo ~= nil,
                    });

                    -- only promote missing reagents that are watched
                    if (reagentMissing > 0 and craftInfo) then
                        if (watchedReagents[reagentItemId] and not visited[reagentItemId]) then
                            if (not nextReagents[reagentItemId]) then
                                nextReagents[reagentItemId] = { skillId = craftInfo.skillId, reagents = craftInfo.reagents, itemAmount = craftInfo.itemAmount, amount = 0 };
                            end
                            nextReagents[reagentItemId].amount = nextReagents[reagentItemId].amount + needed;
                        end
                    end
                end
            end
        end
    end

    -- subsequent passes: derived craftable reagents
    currentNodes = {};
    for reagentItemId, info in pairs(nextReagents) do
        visited[reagentItemId] = true;
        table.insert(currentNodes, {
            itemId = reagentItemId,
            skillId = info.skillId,
            reagents = info.reagents,
            itemAmount = info.itemAmount,
            amount = info.amount,
        });
    end

    -- check current nodes
    while (#currentNodes > 0) do
        local nextLevel = {};

        for _, node in ipairs(currentNodes) do
            local stocks = 0;
            if (node.itemId and node.itemId > 0) then
                stocks = inventoryService:GetItemAmount(node.itemId);
            end

            -- resolve reagents and produced amount (conversion nodes carry their own)
            local nodeReagents, nodeItemAmount = resolveCraft(node);

            -- convert to craft units for display
            local displayAmount = node.amount;
            local displayStocks = stocks;
            if (nodeItemAmount and nodeItemAmount > 1) then
                displayAmount = math.ceil(node.amount / nodeItemAmount);
                displayStocks = math.floor(stocks / nodeItemAmount);
            end

            table.insert(derivedRows, {
                itemId = node.itemId,
                skillId = node.skillId,
                amount = displayAmount,
                stocks = displayStocks,
                indent = 0,
                isNode = true,
                isWatchListRoot = watchedReagents[node.itemId] == true,
                itemAmount = nodeItemAmount,
            });

            -- calculate missing
            local missing;
            if (node.itemId and node.itemId > 0) then
                missing = math.max(0, node.amount - stocks);
            else
                missing = node.amount;
            end
            if (missing > 0) then
                if (nodeReagents) then
                    local craftsNeeded = math.ceil(missing / (nodeItemAmount or 1));
                    for reagentItemId, reagentPerCraft in pairs(nodeReagents) do
                        local needed = craftsNeeded * reagentPerCraft;
                        local reagentStocks = inventoryService:GetItemAmount(reagentItemId);
                        local reagentMissing = math.max(0, needed - reagentStocks);

                        -- resolve how the player could craft this reagent (conversion first, then profession)
                        local craftInfo = skillsService:GetSelfCraftInfo(reagentItemId);

                        table.insert(derivedRows, {
                            itemId = reagentItemId,
                            amount = needed,
                            stocks = reagentStocks,
                            bagStocks = inventoryService:GetBagAmount(reagentItemId),
                            bankStocks = self:GetService("bank"):GetItemCount(reagentItemId),
                            mailStocks = self:GetService("mail"):GetItemCount(reagentItemId),
                            indent = 1,
                            isNode = false,
                            canSelfCraft = craftInfo ~= nil,
                        });

                        if (reagentMissing > 0 and craftInfo) then
                            if (watchedReagents[reagentItemId] and not visited[reagentItemId]) then
                                if (not nextLevel[reagentItemId]) then
                                    nextLevel[reagentItemId] = { skillId = craftInfo.skillId, reagents = craftInfo.reagents, itemAmount = craftInfo.itemAmount, amount = 0 };
                                end
                                nextLevel[reagentItemId].amount = nextLevel[reagentItemId].amount + needed;
                            end
                        end
                    end
                end
            end
        end

        currentNodes = {};
        for reagentItemId, info in pairs(nextLevel) do
            visited[reagentItemId] = true;
            table.insert(currentNodes, {
                itemId = reagentItemId,
                skillId = info.skillId,
                reagents = info.reagents,
                itemAmount = info.itemAmount,
                amount = info.amount,
            });
        end
    end

    -- combine: direct rows, separator, derived rows
    local treeRows = {};
    for _, row in ipairs(directRows) do
        table.insert(treeRows, row);
    end
    if (#derivedRows > 0) then
        table.insert(treeRows, { isSeparator = true });
        for _, row in ipairs(derivedRows) do
            table.insert(treeRows, row);
        end
    end

    return treeRows;
end
