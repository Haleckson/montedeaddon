--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local MissingReagentsView = _G.professionMaster:CreateView("missing-reagents");

--- Update the trade board request button and the "(requested)" name marker.
-- @param row Reagent row.
-- @param isHover True while the row (or one of its buttons) is hovered.
function MissingReagentsView:UpdateRequestButton(row, isHover)
    if (not row.requestButton) then
        return;
    end
    local canRequest = self.addon:IsTradeBoardCompatible() and row.itemId ~= nil;
    local requested = canRequest and _G.tradeBoard:HasOwnRequest("item", row.itemId) or false;
    row.requestButton:SetShown(canRequest and isHover);

    -- "(requested)" marker behind the item name (once the name is loaded)
    if (row.baseItemText) then
        local suffix = requested
            and (" |cff44cc44(" .. self:GetService("locale"):Get("TradeBoardRequested") .. ")|r") or "";
        row.itemText:SetText(row.baseItemText .. suffix);
    end
end

--- Set background alpha.
function MissingReagentsView:SetBackgroundAlpha(value)
    if (not self.view) then return; end
    self.view:SetBackdropColor(0, 0, 0, value);
    self.view:SetBackdropBorderColor(0.5, 0.5, 0.5, value);
end

--- Show missing view.
function MissingReagentsView:Show(missingReagents)
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");

    -- check if view created
    if (self.view == nil) then
        -- clear rows
        self.reagentRows = {};

        -- refresh the "(requested)" markers as soon as trade board data
        -- changes (only with a TradeBoard version that has the request host API)
        if (self.addon:IsTradeBoardCompatible()) then
            _G.tradeBoard:OnTradeDataChanged(function()
                if (not self.view or not self.view:IsShown()) then return; end
                for _, row in ipairs(self.reagentRows) do
                    if (row:IsShown()) then
                        self:UpdateRequestButton(row, row:IsMouseOver());
                    end
                end
            end);
        end

        -- create view
        local view = uiService:CreateOverlayView("PmMissingReagents", 250, 200, localeService:Get("MissingReagentsViewTitle"));
        view:EnableKeyboard();
        self.view = view;
        self:SetBackgroundAlpha(PM_Settings.backgroundMissingReagents or 0);

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(view, function()
            self:GetService("inventory"):ToggleMissingReagents();
        end);
        closeButton:SetHeight(20);
        closeButton:SetWidth(20);
        closeButton:SetPoint("TOPRIGHT", -12, -8);
        closeButton:Hide();

        -- add price toggle button (left of close, only if prices available)
        local priceToggleView = self.addon:GetView("price-toggle-button");
        local inventoryService = self:GetService("inventory");
        local priceToggleButton = priceToggleView:Create(view, "missing-reagents", function()
            inventoryService:CheckMissingReagents();
        end);
        priceToggleButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0);
        priceToggleButton:Hide();
        self.priceToggleButton = priceToggleButton;

        -- add bulk search button (left of price toggle, only if AH addon available)
        local auctionService = self:GetService("auction");
        local localeService = self:GetService("locale");
        local canSearchAH = auctionService:CheckMultiSearchAvailable();
        local bulkSearchButton = CreateFrame("Button", nil, view);
        bulkSearchButton:SetSize(18, 18);
        bulkSearchButton:SetPoint("RIGHT", priceToggleButton, "LEFT", -4, 0);
        bulkSearchButton:Hide();
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

            -- collect all visible item names and ids
            local itemNames = {};
            local itemIds = {};
            for _, row in ipairs(self.reagentRows) do
                if (row:IsShown() and row.itemId) then
                    local itemName = C_Item.GetItemNameByID(row.itemId);
                    if (not itemName) then
                        itemName = self.addon.compat.GetItemInfo(row.itemId);
                    end
                    if (itemName) then
                        table.insert(itemNames, itemName);
                        table.insert(itemIds, row.itemId);
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
            GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM");
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

        -- bind events; the price toggle availability is re-checked on every
        -- hover since a price scan can make prices available at runtime
        local onEnter = function()
            self:SetBackgroundAlpha(0.8);
            closeButton:Show();
            if (auctionService:CheckPricesAvailable()) then
                priceToggleButton:Show();
            end
            if (canSearchAH) then
                bulkSearchButton:UpdateState();
                bulkSearchButton:Show();
            end
        end;
        local onLeave = function()
            C_Timer.After(0.05, function()
                if (not view:IsVisible()) then return; end
                if (view:IsMouseOver()) then return; end
                self:SetBackgroundAlpha(PM_Settings.backgroundMissingReagents or 0);
                closeButton:Hide();
                priceToggleButton:Hide();
                bulkSearchButton:Hide();
            end);
        end;

        view:SetScript("OnEnter", onEnter);
        view:SetScript("OnLeave", onLeave);
        closeButton:SetScript("OnEnter", onEnter);
        closeButton:SetScript("OnLeave", onLeave);
        priceToggleButton:HookScript("OnEnter", onEnter);
        priceToggleButton:HookScript("OnLeave", onLeave);
        bulkSearchButton:HookScript("OnEnter", onEnter);
        bulkSearchButton:HookScript("OnLeave", onLeave);
    end

    -- hide rows
    for _, row in ipairs(self.reagentRows) do
        row:Hide();
    end

    -- check if prices should be shown (Auctionator available and enabled for this view)
    local auctionService = self:GetService("auction");
    local hasPrices = auctionService:CheckPricesVisible("missing-reagents");

    -- adjust view width based on price availability
    if (hasPrices) then
        self.view:SetWidth(370);
    else
        self.view:SetWidth(250);
    end

    -- build and sort reagents alphabetically
    local reagentEntries = {};
    for itemId, info in pairs(missingReagents) do
        local itemName = nil;
        if (C_Item.DoesItemExistByID(itemId)) then
            itemName = C_Item.GetItemNameByID(itemId);
            if (not itemName) then
                itemName = self.addon.compat.GetItemInfo(itemId);
            end
        end

        -- support both old format (number) and new format (table)
        local missingAmount, bankCount, mailCount;
        if (type(info) == "table") then
            missingAmount = info.missing;
            bankCount = info.bankCount or 0;
            mailCount = info.mailCount or 0;
        else
            missingAmount = info;
            bankCount = 0;
            mailCount = 0;
        end

        table.insert(reagentEntries, {
            itemId = itemId,
            missingAmount = missingAmount,
            bankCount = bankCount,
            mailCount = mailCount,
            sortName = itemName,
        });
    end
    table.sort(reagentEntries, function(a, b)
        if (a.sortName and b.sortName) then
            local aName = string.lower(a.sortName);
            local bName = string.lower(b.sortName);
            if (aName ~= bName) then
                return aName < bName;
            end
        elseif (a.sortName and not b.sortName) then
            return true;
        elseif (not a.sortName and b.sortName) then
            return false;
        end

        return a.itemId < b.itemId;
    end);

    -- show reagents
    local reagentRowAmount = 0;
    local totalPriceSum = 0;
    local priceRows = {};
    for _, reagentEntry in ipairs(reagentEntries) do
        local itemId = reagentEntry.itemId;
        local missingAmount = reagentEntry.missingAmount;
        reagentRowAmount = reagentRowAmount + 1;
        if (#self.reagentRows < reagentRowAmount) then
            -- create row frame
            local row = CreateFrame("Button", nil, self.view, BackdropTemplateMixin and "BackdropTemplate");
            local top = 33 + ((reagentRowAmount - 1) * 16);
            row:SetPoint("TOPLEFT", self.view, "TOPLEFT", 10, -top);
            row:SetPoint("BOTTOMRIGHT", self.view, "TOPRIGHT", -10, -(top + 18));
            row:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]]
            });
            row:SetBackdropColor(0, 0, 0, 0);

            -- hover highlight and hover button visibility
            row:SetScript("OnEnter", function()
                row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
                row.ahButton:Show();
                local auctionService = self:GetService("auction");
                if (auctionService:IsOpen()) then
                    row.ahButton.icon:SetDesaturated(false);
                    row.ahButton.icon:SetAlpha(1);
                else
                    row.ahButton.icon:SetDesaturated(true);
                    row.ahButton.icon:SetAlpha(0.5);
                end
                self:UpdateRequestButton(row, true);
            end);
            row:SetScript("OnLeave", function()
                C_Timer.After(0.05, function()
                    if (not row:IsVisible()) then return; end
                    if (not row:IsMouseOver() and not row.ahButton:IsMouseOver()
                        and not (row.requestButton and row.requestButton:IsMouseOver())) then
                        row:SetBackdropColor(0, 0, 0, 0);
                        row.ahButton:Hide();
                        self:UpdateRequestButton(row, false);
                        if (GameTooltip:GetOwner() == row.ahButton) then
                            GameTooltip:Hide();
                        end
                    end
                end);
            end);

            -- shift+click to insert item link into chat
            row:SetScript("OnMouseDown", function(_, button)
                if (button == "LeftButton") and IsShiftKeyDown() and row.itemLink then
                    self.addon.compat.ChatEdit_InsertLink(row.itemLink);
                end
            end);

            -- add amount text (right-aligned at row edge)
            local amountText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            amountText:SetJustifyH("RIGHT");
            amountText:SetTextColor(1, 1, 1);
            row.amountText = amountText;

            -- add price text (right of amount, fixed width)
            local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
            priceText:SetJustifyH("RIGHT");
            row.priceText = priceText;

            -- hover over the price: where the units come from and what they
            -- cost, with the price charts of Auctionizer at the mouse for an
            -- auction house price
            local priceHover = CreateFrame("Frame", nil, row);
            priceHover:SetPoint("TOPLEFT", priceText, "TOPLEFT", 0, 2);
            priceHover:SetPoint("BOTTOMRIGHT", priceText, "BOTTOMRIGHT", 0, -2);
            priceHover:EnableMouse(true);
            priceHover:SetScript("OnEnter", function()
                if (row.priceReagent and row.priceText:IsShown()) then
                    self:GetService("tooltip"):ShowPriceSourcesTooltip(priceHover, row.priceReagent, row.baseItemText and (row.baseItemText .. "|r"), priceHover);
                end
            end);
            priceHover:SetScript("OnLeave", function()
                GameTooltip:Hide();
                self:GetService("auction"):HidePriceChart();
            end);
            row.priceHover = priceHover;

            -- add source text (bank/mail icons, left of amount)
            local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            sourceText:SetPoint("RIGHT", amountText, "LEFT", -6, 0);
            sourceText:SetJustifyH("RIGHT");
            sourceText:SetTextColor(1, 1, 1);
            row.sourceText = sourceText;

            -- add source tooltip overlay
            local sourceTooltip = CreateFrame("Frame", nil, row);
            sourceTooltip:SetPoint("TOPLEFT", sourceText, "TOPLEFT", 0, 0);
            sourceTooltip:SetPoint("BOTTOMRIGHT", sourceText, "BOTTOMRIGHT", 0, 0);
            sourceTooltip:EnableMouse(true);
            self:GetService("ui"):BindTooltip(sourceTooltip, function()
                return row.sourceTooltipText;
            end, "ANCHOR_RIGHT");
            row.sourceTooltip = sourceTooltip;

            -- add ah search button (shown on hover, left of source/amount)
            local ahButton = CreateFrame("Button", nil, row);
            ahButton:SetSize(12, 12);
            ahButton:SetPoint("RIGHT", sourceText, "LEFT", -2, 0);
            local ahIcon = ahButton:CreateTexture(nil, "ARTWORK");
            ahIcon:SetAllPoints();
            ahIcon:SetTexture([[Interface\Icons\INV_Misc_Spyglass_03]]);
            ahButton.icon = ahIcon;
            ahButton:SetScript("OnClick", function()
                if (self:GetService("auction"):IsOpen()) then
                    local itemName = C_Item.GetItemNameByID(row.itemId);
                    if (not itemName) then
                        itemName = self.addon.compat.GetItemInfo(row.itemId);
                    end
                    if (itemName) then
                        self:GetService("auction"):SearchFor(itemName, row.itemId);
                    end
                end
            end);
            ahButton:SetScript("OnEnter", function()
                row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
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
                C_Timer.After(0.05, function()
                    if (not row:IsVisible()) then return; end
                    if (not row:IsMouseOver() and not row.ahButton:IsMouseOver()) then
                        row:SetBackdropColor(0, 0, 0, 0);
                        row.ahButton:Hide();
                    end
                    if (GameTooltip:GetOwner() == row.ahButton) then
                        GameTooltip:Hide();
                    end
                end);
            end);
            ahButton:Hide();
            row.ahButton = ahButton;

            -- add trade board request button (letter, left of the ah button;
            -- overlaid red when the item is already requested = click removes)
            local requestButton = CreateFrame("Button", nil, row);
            requestButton:SetSize(12, 12);
            requestButton:SetPoint("RIGHT", ahButton, "LEFT", -2, 0);
            local requestIcon = requestButton:CreateTexture(nil, "ARTWORK");
            requestIcon:SetAllPoints();
            requestIcon:SetTexture([[Interface\Icons\INV_Letter_12]]);
            requestButton.icon = requestIcon;
            requestButton:SetScript("OnClick", function()
                if (not self.addon:IsTradeBoardCompatible() or not row.itemId) then
                    return;
                end
                GameTooltip:Hide();
                -- prefill with the still missing amount; an existing own
                -- request opens in edit mode to change or delete it
                _G.tradeBoard:OpenRequestDialog("item", row.itemId, row.missingAmount);

                -- reset the hover state: the dialog may open right under the
                -- mouse, then the row never receives a leave event
                row:SetBackdropColor(0, 0, 0, 0);
                row.ahButton:Hide();
                self:UpdateRequestButton(row, false);
                if (row.hoverGlowHide) then row.hoverGlowHide(); end
            end);
            requestButton:SetScript("OnEnter", function()
                row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
                self:UpdateRequestButton(row, true);
                GameTooltip:SetOwner(requestButton, "ANCHOR_RIGHT");
                local tooltipKey = (self.addon:IsTradeBoardCompatible() and row.itemId and _G.tradeBoard:HasOwnRequest("item", row.itemId))
                    and "TradeBoardEditRequest" or "TradeBoardRequestItem";
                GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
                GameTooltip:Show();
            end);
            requestButton:SetScript("OnLeave", function()
                C_Timer.After(0.05, function()
                    if (not row:IsVisible()) then return; end
                    if (not row:IsMouseOver() and not row.ahButton:IsMouseOver() and not requestButton:IsMouseOver()) then
                        row:SetBackdropColor(0, 0, 0, 0);
                        row.ahButton:Hide();
                        self:UpdateRequestButton(row, false);
                    end
                    if (GameTooltip:GetOwner() == requestButton) then
                        GameTooltip:Hide();
                    end
                end);
            end);
            requestButton:Hide();
            row.requestButton = requestButton;

            -- add item text (truncated with ellipsis)
            local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            itemText:SetPoint("LEFT", 6, 0);
            itemText:SetPoint("RIGHT", sourceText, "LEFT", -4, 0);
            itemText:SetJustifyH("LEFT");
            itemText:SetWordWrap(false);
            row.itemText = itemText;

            -- purple hover glow (border + purple backdrop), kept alive by the hover buttons and tooltip overlay
            self:GetService("ui"):AttachHoverGlow(row, { ahButton, requestButton, sourceTooltip, priceHover });

            -- add row
            table.insert(self.reagentRows, row);
        end

        -- get row
        local row = self.reagentRows[reagentRowAmount];
        row.itemId = itemId;
        row.missingAmount = missingAmount;
        row.baseItemText = nil;
        row:Show();
        row.ahButton:Hide();
        self:UpdateRequestButton(row, false);

        -- position amount and price based on price availability
        row.amountText:ClearAllPoints();
        row.priceText:ClearAllPoints();
        if (hasPrices) then
            -- price on far right, amount left of price
            row.priceText:SetPoint("RIGHT", -6, -1);
            row.priceText:SetWidth(110);
            row.amountText:SetPoint("RIGHT", row.priceText, "LEFT", -4, 1);
        else
            -- amount on far right, no price
            row.amountText:SetPoint("RIGHT", -6, 0);
            row.priceText:Hide();
        end

        -- update source info (bank/mail icons)
        local sourceParts = {};
        local tooltipParts = {};
        local localeService = self:GetService("locale");
        if (reagentEntry.bankCount > 0) then
            table.insert(sourceParts, "|TInterface\\Minimap\\Tracking\\Banker:10|t" .. reagentEntry.bankCount);
            table.insert(tooltipParts, reagentEntry.bankCount .. " " .. localeService:Get("SourceTooltipBank"));
        end
        if (reagentEntry.mailCount > 0) then
            table.insert(sourceParts, "|TInterface\\Minimap\\Tracking\\Mailbox:10|t" .. reagentEntry.mailCount);
            table.insert(tooltipParts, reagentEntry.mailCount .. " " .. localeService:Get("SourceTooltipMail"));
        end
        row.sourceText:SetText(table.concat(sourceParts, " "));
        row.sourceTooltipText = #tooltipParts > 0 and table.concat(tooltipParts, "\n") or nil;

        -- update missing amount
        row.amountText:SetText(tostring(missingAmount));

        -- price of the missing amount along the offers (bank and mail first, then
        -- vendor or the auction house level by level), the same as the leveling planner
        row.priceReagent = nil;
        if (hasPrices) then
            local reagent = self:GetService("leveling-planner"):PriceReagent(itemId, missingAmount);
            local hasSource = false;
            for _, source in ipairs(reagent.sources) do
                if (source.kind ~= "missing") then
                    hasSource = true;
                end
            end
            if (hasSource) then
                local priceText = self:GetService("tooltip"):FormatSourceCost(reagent.cost);
                if (reagent.hasMissing) then
                    priceText = "|cffff4040?|r " .. priceText;
                elseif (reagent.hasEstimate) then
                    priceText = "~" .. priceText;
                end
                totalPriceSum = totalPriceSum + reagent.cost;
                row.priceReagent = reagent;
                row.priceText:SetText(priceText);
                row.priceText:Show();
                table.insert(priceRows, row);
            else
                row.priceText:SetText("");
                row.priceText:Hide();
            end
        else
            row.priceText:Hide();
        end

        -- check if item id known
        if (C_Item.DoesItemExistByID(itemId)) then
            -- get item
            local item = Item:CreateFromItemID(itemId);
            if (not item:IsItemEmpty()) then
                pcall(function()
                    -- wait until loaded; the "(requested)" marker is appended
                    -- to the base text by UpdateRequestButton
                    item:ContinueOnItemLoad(function()
                        row.itemLink = item:GetItemLink();
                        row.baseItemText = "|c" .. professionNamesService:GetItemColor(row.itemLink) .. item:GetItemName();
                        self:UpdateRequestButton(row, row:IsMouseOver());
                    end);
                end);
            end
        end
    end

    -- show sum row if prices available and more than one reagent
    if (not self.sumRow) then
        -- create sum label
        local sumLabel = self.view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        sumLabel:SetJustifyH("LEFT");
        sumLabel:SetTextColor(1, 0.82, 0);
        self.sumLabel = sumLabel;

        -- create sum price text
        local sumPriceText = self.view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        sumPriceText:SetJustifyH("RIGHT");
        self.sumPriceText = sumPriceText;

        -- hover over the sum: the price of every reagent
        local sumHover = CreateFrame("Frame", nil, self.view);
        sumHover:SetPoint("TOPLEFT", sumPriceText, "TOPLEFT", 0, 2);
        sumHover:SetPoint("BOTTOMRIGHT", sumPriceText, "BOTTOMRIGHT", 0, -2);
        sumHover:EnableMouse(true);
        sumHover:SetScript("OnEnter", function()
            self:ShowSumTooltip(sumHover);
        end);
        sumHover:SetScript("OnLeave", function()
            GameTooltip:Hide();
        end);
        self.sumHover = sumHover;

        self.sumRow = true;
    end

    -- position and show/hide sum row
    local sumHeight = 0;
    if (hasPrices and reagentRowAmount > 1 and totalPriceSum > 0) then
        -- position sum label and price
        local sumTop = 33 + reagentRowAmount * 16 + 6;
        self.sumLabel:ClearAllPoints();
        self.sumLabel:SetPoint("TOPLEFT", self.view, "TOPLEFT", 16, -sumTop);
        self.sumLabel:SetText(localeService:Get("MissingReagentsSumLabel"));
        self.sumLabel:Show();

        self.sumPriceText:ClearAllPoints();
        self.sumPriceText:SetPoint("TOPRIGHT", self.view, "TOPRIGHT", -16, -(sumTop + 1));
        self.sumPriceText:SetText(self:GetService("tooltip"):FormatSourceCost(totalPriceSum));
        self.sumPriceText:Show();
        self.sumHover:Show();
        self.priceRows = priceRows;

        sumHeight = 22;
    else
        self.sumLabel:Hide();
        self.sumPriceText:Hide();
        self.sumHover:Hide();
    end

    -- update view height; the classic style keeps a little more room below
    -- the content
    local viewHeight = 33 + reagentRowAmount * 16 + (uiService:IsForever() and 14 or 12) + sumHeight;
    self.view.minHeight = viewHeight;
    self.view:SetHeight(viewHeight);

    -- show view
    self.view:Show();
    self.visible = true;
end

--- Show the price of every reagent below the sum.
-- @param owner The hovered sum.
function MissingReagentsView:ShowSumTooltip(owner)
    local tooltipService = self:GetService("tooltip");
    GameTooltip:SetOwner(owner, "ANCHOR_NONE");
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", owner, "TOPLEFT", -2, 0);
    GameTooltip:AddLine(self:GetService("locale"):Get("MissingReagentsSumLabel"));

    local total = 0;
    for _, row in ipairs(self.priceRows or {}) do
        local reagent = row.priceReagent;
        if (reagent and row.baseItemText) then
            GameTooltip:AddDoubleLine(row.baseItemText .. "|r", reagent.count .. "x  " .. tooltipService:FormatSourceCost(reagent.cost), 1, 1, 1, 1, 1, 1);
            total = total + reagent.cost;
        end
    end

    GameTooltip:AddLine(" ");
    GameTooltip:AddDoubleLine(self:GetService("locale"):Get("LevelingPlannerSourceTotal"), tooltipService:FormatSourceCost(total), 1, 0.82, 0, 1, 1, 1);
    GameTooltip:Show();
end

-- Hide view.
function MissingReagentsView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
    end
end