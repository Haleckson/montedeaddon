--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]
-- create view
local SkillView = _G.professionMaster:CreateView("skill-view");

-- window layout of the flat style: window size, distance of the lists from
-- the window border, right edge of the players list (from the left) and left
-- edge of the bucket list (from the right), without and with prices
local FlatLayout = {
    width = 480, widthPrices = 570, height = 290,
    side = 12, top = 36, bottom = 44,
    playersRight = 222, bucketLeft = 252, bucketLeftPrices = 336,
    buttonBottom = 10, labelBottom = 14, buttonSide = 12, labelSide = 16,
};

-- the classic style: a larger window, so both lists get a little more room
-- although they keep clear of the frame border; the vertical distances
-- follow the frame art of the client and are filled in on creation
local ForeverLayout = {
    width = 520, widthPrices = 604, height = 330,
    side = 20,
    playersRight = 240, bucketLeft = 274, bucketLeftPrices = 358,
};

--- Show professions view.
-- @param skillRow Skill row.
function SkillView:Show(skillRow, professionsView)
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- get skilla nd skill id
    local skill = skillRow.skill;
    local skillId = skillRow.skillId;

    -- check if view created
    if (self.view == nil) then
        -- define player rows and scroll top
        self.playerRows = {};
        self.reagentRows = {};
        self.playerScrollTop = 0;

        -- create view
        local layout = FlatLayout;

        -- classic style: the lists start below the title and reach down to
        -- the button row, which sits at the height of the other windows
        if (uiService:IsForever()) then
            layout = ForeverLayout;
            layout.top = uiService:GetFrameMargin() * 3 + 28;
            layout.buttonBottom = uiService:GetBottomInset(10);
            layout.labelBottom = uiService:GetBottomInset(14, true);
            layout.buttonSide = uiService:GetSideInset(12);
            layout.labelSide = uiService:GetSideInset(16) + 4;
            layout.bottom = layout.buttonBottom + 30;
        end
        self.layout = layout;
        local view = uiService:CreateView("PmSkill", layout.width, layout.height, "");
        view:EnableKeyboard();
        self.view = view;

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(view, function()
            professionsView:HideSkillView();
        end);
        closeButton:SetHeight(22);
        closeButton:SetWidth(22);
        closeButton:SetPoint("TOPRIGHT", -12, -8);
        uiService:BindTooltip(closeButton, localeService:Get("CloseTooltip"));

        -- add price toggle button (left of close, only if prices available)
        local priceToggleView = self.addon:GetView("price-toggle-button");
        local skillView = self;
        local priceToggleButton = priceToggleView:Create(view, "skill-view", function()
            skillView:RefreshBucketListAmount();
        end);
        priceToggleButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0);
        self.priceToggleButton = priceToggleButton;

        -- show/hide based on Auctionator availability
        if (self:GetService("auction"):CheckPricesAvailable()) then
            priceToggleButton:Show();
        else
            priceToggleButton:Hide();
        end

        -- add players frame
        local playersFrame = uiService:CreatePanel(view);
        playersFrame:SetPoint("TOPLEFT", layout.side, -layout.top);
        playersFrame:SetPoint("BOTTOMRIGHT", view, "BOTTOMLEFT", layout.playersRight, layout.bottom);
        self.playersFrame = playersFrame;

        -- recipe labels pool
        self.recipeLabels = {};

        -- add players label
        local playersLabel = playersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        playersLabel:SetPoint("TOPLEFT", 13, -12);
        playersLabel:SetText(localeService:Get("SkillViewPlayers"));

        -- add players scroll frame 
        local playerScrollFrame, playerScrollChild, playerScrollElement = uiService:CreateScrollFrame(playersFrame);
        playerScrollFrame:SetPoint("TOPLEFT", 7, -32);
        playerScrollFrame:SetPoint("BOTTOMRIGHT", -7, 5);
        playerScrollChild:SetWidth(playerScrollFrame:GetWidth());
        playerScrollElement:SetScript("OnVerticalScroll", function(_, top)
            self.playerScrollTop = top;
            self:RefreshPlayerRows();
        end);
        self.playerScrollFrame = playerScrollFrame;
        self.playerScrollChild = playerScrollChild;
        self.playerScrollElement = playerScrollElement;

        -- add bucket list frame
        local bucketListFrame = uiService:CreatePanel(view);
        bucketListFrame:SetPoint("TOPLEFT", view, "TOPRIGHT", -layout.bucketLeft, -layout.top);
        bucketListFrame:SetPoint("BOTTOMRIGHT", -layout.side, layout.bottom);
        self.bucketListFrame = bucketListFrame;

        -- add bucket list label
        local bucketListLabel = bucketListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        bucketListLabel:SetPoint("TOPLEFT", 13, -12);
        bucketListLabel:SetText(localeService:Get("SkillViewOnBucketList") .. ":");

        -- add bucket list amount
        local bucketListAmountText = bucketListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        bucketListAmountText:SetPoint("LEFT", bucketListLabel, "RIGHT", 8, 0);
        self.bucketListAmountText = bucketListAmountText;

        -- amount plus button
        local amountPlusButton = uiService:CreateFlatSquareButton(bucketListFrame, "+", function()
            -- update amount by item yield
            local skillInfo = self:GetService("skills"):GetSkillById(self.skillId);
            local itemAmount = (skillInfo and skillInfo.itemAmount) or 1;
            PM_BucketList[self.skillId] = self.bucketListAmount + itemAmount;
            self:RefreshBucketListAmount();
            professionsView:CheckBucketList();

            -- check missing ragents
            self:GetService("inventory"):CheckMissingReagents();
        end, 20);
        amountPlusButton:SetPoint("LEFT", bucketListAmountText, "RIGHT", 10, 0);
        uiService:BindTooltip(amountPlusButton, localeService:Get("SkillViewAddToBucketList"));
        self.amountPlusButton = amountPlusButton;

        -- amount minus button
        local amountMinusButton = uiService:CreateFlatSquareButton(bucketListFrame, "-", function()
            -- update amount by item yield
            local skillInfo = self:GetService("skills"):GetSkillById(self.skillId);
            local itemAmount = (skillInfo and skillInfo.itemAmount) or 1;
            if (self.bucketListAmount <= itemAmount) then
                PM_BucketList[self.skillId] = nil;
            else
                PM_BucketList[self.skillId] = self.bucketListAmount - itemAmount;
            end
            self:RefreshBucketListAmount();
            professionsView:CheckBucketList();

            -- check missing ragents
            self:GetService("inventory"):CheckMissingReagents();
        end, 20);
        amountMinusButton:SetPoint("LEFT", amountPlusButton, "RIGHT", 3, 0);
        uiService:BindTooltip(amountMinusButton, localeService:Get("SkillViewRemoveOneFromBucketList"));
        self.amountMinusButton = amountMinusButton;

        -- add clear button
        local clearButton = uiService:CreateFlatSquareButton(bucketListFrame, "x", function()
            -- update amount
            PM_BucketList[self.skillId] = nil;
            self:RefreshBucketListAmount();
            professionsView:CheckBucketList();

            -- check missing ragents
            self:GetService("inventory"):CheckMissingReagents();
        end, 20);
        clearButton:SetPoint("LEFT", amountMinusButton, "RIGHT", 3, 0);
        uiService:BindTooltip(clearButton, localeService:Get("SkillViewRemoveFromBucketList"));
        self.clearButton = clearButton;

        -- create ok button
        local okButton = uiService:CreateFlatButton(view, localeService:Get("SkillViewOk"), function()
            professionsView:HideSkillView();
        end);
        okButton:SetWidth(100);
        okButton:SetHeight(22);
        okButton:SetPoint("BOTTOMRIGHT", -layout.buttonSide, layout.buttonBottom);
    end

    -- update item text and skill id
    self.parentSkillRow = skillRow;
    self.skill = skill;
    self.skillId = skillId;
    local skillInfo = self:GetService("skills"):GetSkillById(skillId);
    local itemAmount = skillInfo and skillInfo.itemAmount;
    local titleName = skill.itemColor and ("|c" .. skill.itemColor .. skill.name) or skill.name;
    if (itemAmount and itemAmount > 1) then
        titleName = titleName .. "|r x" .. itemAmount;
    end

    -- append difficulty colors
    if (skillInfo and skillInfo.difficulty) then
        local d = skillInfo.difficulty;
        titleName = titleName .. "|r - "
            .. "|cffff8040" .. d[1] .. "|r "
            .. "|cffffff00" .. d[2] .. "|r "
            .. "|cff40bf40" .. d[3] .. "|r "
            .. "|cff808080" .. d[4] .. "|r";
    end

    self.view.titleLabel:SetText(self.addon.shortcut .. titleName);
    uiService:SetViewPortrait(self.view, skill.icon);

    -- update recipe labels
    self:RefreshRecipeLabels(skillInfo);

    -- set position
    self.view:ClearAllPoints();
    self.view:SetPoint("CENTER", professionsView.view, "CENTER", 0, 0);

    -- update bucket list amount
    self:RefreshBucketListAmount();

    -- get player names and whisper targets of online players
    local players = skillRow.players or {};
    self.playerNames, self.playerWhisperTargets = self:GetService("player"):CombinePlayerNames(players, nil, nil, nil, true);
    self.playerScrollChild:SetHeight(#self.playerNames * 20);
    self:RefreshPlayerRows();

    -- show view
    self.view:Show();
end

--- Refresh recipe labels based on skill recipes.
function SkillView:RefreshRecipeLabels(skillInfo)
    -- hide all existing recipe labels
    for _, label in ipairs(self.recipeLabels) do
        label:Hide();
    end

    -- hide zones text
    if (self.zonesText) then
        self.zonesText:Hide();
    end

    if (not skillInfo) then return; end

    -- gathering skills: show zone names instead of recipe labels
    if (skillInfo.zones and #skillInfo.zones > 0) then
        if (not self.zonesText) then
            self.zonesText = self.view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
            self.zonesText:SetTextColor(1, 1, 1);
            self.zonesText:SetNonSpaceWrap(false);
            self.zonesText:SetWordWrap(false);
        end
        local skillsService = self:GetService("skills");
        local zoneNames = skillsService.zoneNames or {};
        local zoneTextParts = {};
        for _, zoneId in ipairs(skillInfo.zones) do
            local zoneName = zoneNames[zoneId];
            if (zoneName) then
                table.insert(zoneTextParts, zoneName);
            end
        end
        if (#zoneTextParts > 0) then
            self.zonesText:SetText(table.concat(zoneTextParts, ", "));
            self.zonesText:ClearAllPoints();
            self.zonesText:SetPoint("BOTTOMLEFT", self.layout.labelSide, self.layout.labelBottom);
            self.zonesText:SetPoint("BOTTOMRIGHT", self.view, "BOTTOMRIGHT", -self.layout.labelSide, self.layout.labelBottom);
            self.zonesText:Show();
        end
        return;
    end

    -- source labels: recipe items, trainer, quest, discovery
    local tooltipService = self:GetService("tooltip");
    local sourceLabels = tooltipService:GetSkillSourceLabels(skillInfo);
    if (#sourceLabels == 0) then
        return;
    end

    -- show the sources comma-separated on a single line with individual hover regions
    local skillView = self;
    local offsetX = self.layout.labelSide;
    for index, sourceLabel in ipairs(sourceLabels) do
        do
            local label = self.recipeLabels[index];
            if (not label) then
                -- create new pooled label
                label = CreateFrame("Button", nil, self.view);
                label:SetHeight(14);
                label.text = label:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
                label.text:SetPoint("LEFT", 0, 0);
                label:SetScript("OnLeave", function()
                    GameTooltip:Hide();
                end);
                label:SetScript("OnClick", function(self)
                    if (IsShiftKeyDown() and skillView.addon.compat.ChatEdit_GetActiveWindow() and self.recipe and self.recipe.itemLink) then
                        skillView.addon.compat.ChatEdit_InsertLink(self.recipe.itemLink);
                    end
                end);
                self.recipeLabels[index] = label;
            end

            -- position: inline from left
            label:ClearAllPoints();
            label:SetPoint("BOTTOMLEFT", offsetX, self.layout.labelBottom);

            -- set text (add comma separator for all but last)
            local labelText = sourceLabel.text;
            if (index < #sourceLabels) then
                labelText = labelText .. ",";
            end
            label.text:SetText(labelText);
            label:SetWidth(label.text:GetStringWidth() + 4);

            -- advance horizontal offset
            offsetX = offsetX + label.text:GetStringWidth() + 6;

            -- bind the source tooltip to this label (recipe item or skill source)
            label.source = sourceLabel;
            label.recipe = sourceLabel.recipe;
            label:SetScript("OnEnter", function(self)
                tooltipService:ShowSourceLabelTooltip(self, self.source);
            end);

            label:Show();
        end
    end
end

--- Refresh player rows (pooled).
function SkillView:RefreshPlayerRows()
    -- get services
    local uiService = self:GetService("ui");

    -- get visible range
    local startIndex = math.max(math.floor(self.playerScrollTop / 20) - 1, 1);
    local endIndex = math.min(startIndex + 25, #self.playerNames);
    local visibleCount = math.max(endIndex - startIndex + 1, 0);

    -- ensure pool has enough frames
    if (not self.playerRowPool) then
        self.playerRowPool = {};
    end
    while (#self.playerRowPool < visibleCount) do
        local poolIndex = #self.playerRowPool + 1;
        local row = CreateFrame("Button", nil, self.playerScrollChild, BackdropTemplateMixin and "BackdropTemplate");
        row:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]]
        });

        -- add name text
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        nameText:SetPoint("TOPLEFT", 6, -4);
        nameText:SetPoint("BOTTOMRIGHT", -6, -3);
        nameText:SetJustifyH("LEFT");
        nameText:SetJustifyV("TOP");
        row.nameText = nameText;

        -- online players: click opens an empty whisper to the player
        row:SetScript("OnClick", function()
            if (row.whisperTarget) then
                self.addon.compat.ChatFrame_SendTell(self:GetService("player"):GetWhisperTarget(row.whisperTarget));
            end
        end);
        row:SetScript("OnLeave", function()
            uiService:SetRowColor(row, row.rowIndex or 1);
        end);

        -- purple hover glow (border + purple backdrop)
        uiService:AttachHoverGlow(row);

        self.playerRowPool[poolIndex] = row;
    end

    -- hide all pooled frames
    for _, row in ipairs(self.playerRowPool) do
        row:Hide();
    end

    -- bind pool frames to visible data
    for i = 0, visibleCount - 1 do
        local rowIndex = startIndex + i;
        local row = self.playerRowPool[i + 1];

        -- set background color by data index
        row.rowIndex = rowIndex;
        uiService:SetRowColor(row, rowIndex);

        -- position
        local top = (rowIndex - 1) * 20;
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.playerScrollChild, "TOPLEFT", 0, -top);
        row:SetPoint("BOTTOMRIGHT", self.playerScrollChild, "TOPRIGHT", -28, -(top + 20));

        -- only online players are hoverable and whisperable
        row.whisperTarget = self.playerWhisperTargets and self.playerWhisperTargets[rowIndex] or nil;
        row:EnableMouse(row.whisperTarget ~= nil);

        -- set text and show
        row.nameText:SetText(self.playerNames[rowIndex]);
        row:Show();
    end
end

-- Update bucket list amount.
function SkillView:RefreshBucketListAmount()
    -- get amount and set amount text
    self.bucketListAmount = PM_BucketList[self.skillId] or 0;
    self.bucketListAmountText:SetText(self.bucketListAmount);

    -- set width
    if (self.bucketListAmount >= 100) then
        self.bucketListAmountText:SetWidth(26);
    elseif (self.bucketListAmount >= 10) then
        self.bucketListAmountText:SetWidth(18);
    else
        self.bucketListAmountText:SetWidth(10);
    end

    -- set button visiblity
    if (self.bucketListAmount > 0) then
        self.amountMinusButton:Show();
        self.clearButton:Show();
    else
        self.amountMinusButton:Hide();
        self.clearButton:Hide();
    end

    -- hide rows
    for _, row in ipairs(self.reagentRows) do
        row:Hide();
    end

    -- get skills service
    local skillsService = self:GetService("skills");

    -- get all skills
    local skillInfo = skillsService:GetSkillById(self.skillId);
    if (not skillInfo) then
        return;
    end

    -- get service
    local professionNamesService = self:GetService("profession-names");

    -- get auction service for prices
    local auctionService = self:GetService("auction");

    -- check if prices should be shown (Auctionator available and enabled for this view)
    local hasPrices = auctionService:CheckPricesVisible("skill-view");

    -- adjust view width based on price availability
    local layout = self.layout;
    if (hasPrices) then
        self.view:SetWidth(layout.widthPrices);
        self.bucketListFrame:ClearAllPoints();
        self.bucketListFrame:SetPoint("TOPLEFT", self.view, "TOPRIGHT", -layout.bucketLeftPrices, -layout.top);
        self.bucketListFrame:SetPoint("BOTTOMRIGHT", self.view, "BOTTOMRIGHT", -layout.side, layout.bottom);
    else
        self.view:SetWidth(layout.width);
        self.bucketListFrame:ClearAllPoints();
        self.bucketListFrame:SetPoint("TOPLEFT", self.view, "TOPRIGHT", -layout.bucketLeft, -layout.top);
        self.bucketListFrame:SetPoint("BOTTOMRIGHT", self.view, "BOTTOMRIGHT", -layout.side, layout.bottom);
    end

    -- scan inventory
    local inventoryService = self:GetService("inventory");
    inventoryService:ScanInventory();

    -- show reagents
    local rowAmount = 0;
    if (not skillInfo.reagents) then return; end
    for reagentItemId, reagentAmount in pairs(skillInfo.reagents) do
        rowAmount = rowAmount + 1;
        if (#self.reagentRows < rowAmount) then
            -- create row frame
            local row = CreateFrame("Button", nil, self.bucketListFrame, BackdropTemplateMixin and "BackdropTemplate");
            local top = 36 + ((rowAmount - 1) * 20);
            row:SetPoint("TOPLEFT", self.bucketListFrame, "TOPLEFT", 10, -top);
            row:SetPoint("BOTTOMRIGHT", self.bucketListFrame, "TOPRIGHT", -10, -(top + 20));
            row:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]]
            });

            -- set background color by index
            local uiService = self:GetService("ui");
            local stripeIndex = rowAmount;
            uiService:SetRowColor(row, stripeIndex);

            -- bind row mouse events
            row:SetScript("OnLeave", function()
                -- update background color
                uiService:SetRowColor(row, stripeIndex);

                -- hide item tool tip
                GameTooltip:Hide();
            end);
            row:SetScript("OnEnter", function()
                -- update background color
                row:SetBackdropColor(0.2, 0.2, 0.2);

                -- show item tool tip
                GameTooltip:SetOwner(row, "ANCHOR_LEFT");
                if row.itemLink then GameTooltip:SetHyperlink(row.itemLink); end
                GameTooltip:Show();
            end);

            -- add icon text
            local iconText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            iconText:SetPoint("TOPLEFT", 3, -3);
            row.iconText = iconText;

            -- add amount text
            local amountText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            amountText:SetJustifyH("RIGHT");
            row.amountText = amountText;

            -- add price text
            local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
            priceText:SetJustifyH("RIGHT");
            row.priceText = priceText;

            -- hover over an auction house price: the price charts of
            -- Auctionizer at the mouse, for the price of another addon a
            -- quiet line that charts come with Auctionizer
            local priceHover = CreateFrame("Frame", nil, row);
            priceHover:SetPoint("TOPLEFT", priceText, "TOPLEFT", 0, 4);
            priceHover:SetPoint("BOTTOMRIGHT", priceText, "BOTTOMRIGHT", 0, -4);
            priceHover:EnableMouse(true);
            priceHover:SetScript("OnEnter", function()
                row:SetBackdropColor(0.2, 0.2, 0.2);
                local auctionService = self:GetService("auction");
                if (auctionService:ShowPriceChart(row.priceItemId, priceHover)) then
                    return;
                end
                local hint = auctionService:GetPriceChartHint(row.priceItemId);
                if (hint) then
                    GameTooltip:SetOwner(priceHover, "ANCHOR_RIGHT");
                    GameTooltip:SetText(hint, 0.6, 0.6, 0.6);
                    GameTooltip:Show();
                end
            end);
            priceHover:SetScript("OnLeave", function()
                uiService:SetRowColor(row, stripeIndex);
                GameTooltip:Hide();
                self:GetService("auction"):HidePriceChart();
            end);
            priceHover:Hide();
            row.priceHover = priceHover;

            -- add item text
            local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            itemText:SetJustifyH("LEFT");
            itemText:SetJustifyV("TOP");
            row.itemText = itemText;

            -- purple hover glow (border + purple backdrop), kept alive by the price hover
            self:GetService("ui"):AttachHoverGlow(row, { priceHover });

            -- add row
            table.insert(self.reagentRows, row);
        end

        -- get row
        local row = self.reagentRows[rowAmount];
        row:Show();

        -- update amount
        local inventoryAmount = inventoryService:GetItemAmount(reagentItemId);
        local requiredAmount = self.bucketListAmount * reagentAmount;
        if (requiredAmount > 0) then
            row.amountText:SetText(math.min(inventoryAmount, requiredAmount) .. "/" .. requiredAmount);
        else
            row.amountText:SetText(reagentAmount);
        end
        
        -- set amount color based on inventory
        if (requiredAmount > 0 and inventoryAmount >= requiredAmount) then
            row.amountText:SetTextColor(0, 1, 0);
        else
            row.amountText:SetTextColor(1, 1, 1);
        end

        -- position elements based on price availability
        row.amountText:ClearAllPoints();
        row.priceText:ClearAllPoints();
        row.itemText:ClearAllPoints();
        if (hasPrices) then
            -- price on far right with fixed width, amount left of price
            row.priceText:SetPoint("TOPRIGHT", -3, -5);
            row.priceText:SetWidth(80);
            row.amountText:SetPoint("TOPRIGHT", row.priceText, "TOPLEFT", -4, 1);
            row.itemText:SetPoint("TOPLEFT", 24, -4);
            row.itemText:SetPoint("TOPRIGHT", row.amountText, "TOPLEFT", -4, 0);
        else
            -- amount on far right, no price
            row.amountText:SetPoint("TOPRIGHT", -3, -4);
            row.itemText:SetPoint("TOPLEFT", 24, -4);
            row.itemText:SetPoint("TOPRIGHT", row.amountText, "TOPLEFT", -8, 0);
        end

        -- check if item id known
        if (C_Item.DoesItemExistByID(reagentItemId)) then
            -- get item
            local item = Item:CreateFromItemID(reagentItemId);
            if (not item:IsItemEmpty()) then
                pcall(function() 
                    -- wait until loaded
                    item:ContinueOnItemLoad(function()
                        -- update item
                        row.itemLink = item:GetItemLink();
                        row.iconText:SetText("|T" .. item:GetItemIcon() .. ":16|t");
                        row.itemText:SetText("|c" .. professionNamesService:GetItemColor(row.itemLink) .. item:GetItemName());
                    end);
                end);
            end
        end

        -- show total auction house price based on quantity; only an auction
        -- house price takes the mouse (a vendor price leaves it to the row)
        row.priceItemId = reagentItemId;
        row.priceHover:Hide();
        if (hasPrices) then
            local unitPrice, priceSource = auctionService:GetItemPrice(reagentItemId);
            local displayAmount = (requiredAmount > 0) and requiredAmount or reagentAmount;
            local totalPrice = unitPrice and (unitPrice * displayAmount) or nil;
            local formattedPrice = auctionService:FormatPrice(totalPrice);
            if (formattedPrice) then
                row.priceText:SetText(formattedPrice);
                row.priceText:Show();
                if (auctionService:IsAuctionPriceSource(priceSource)) then
                    row.priceHover:Show();
                end
            else
                row.priceText:SetText("");
                row.priceText:Hide();
            end
        else
            row.priceText:Hide();
        end
    end
end

-- Hide view.
function SkillView:Hide()
    if (self.view) then
        self.view:Hide();
    end
end