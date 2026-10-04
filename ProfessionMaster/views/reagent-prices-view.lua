--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local ReagentPricesView = _G.professionMaster:CreateView("reagent-prices");

-- row layout constants
local ROW_HEIGHT = 22;
local ICON_SIZE = 18;

-- eye-catching color for overridden prices
local OVERRIDE_COLOR = "ffffa000";

--- Register the reagent prices subpage under the given settings category.
-- @param parentCategory The modern Settings category object (or nil on legacy clients).
-- @param parentName The legacy Interface Options parent panel name.
function ReagentPricesView:Register(parentCategory, parentName)
    local localeService = self:GetService("locale");

    -- create options subpanel
    local panel = CreateFrame("Frame");
    panel.name = localeService:Get("SettingsReagentsTitle");
    self.panel = panel;

    -- add title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 16, -16);
    title:SetText(localeService:Get("SettingsReagentsTitle"));

    -- add description
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    description:SetPoint("RIGHT", panel, "RIGHT", -16, 0);
    description:SetJustifyH("LEFT");
    description:SetText(localeService:Get("SettingsReagentsDescription"));

    -- column headers above the scroll frame
    local itemHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    itemHeader:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 4, -14);
    itemHeader:SetText(localeService:Get("SettingsReagentsColumnItem"));

    local priceHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    priceHeader:SetText(localeService:Get("SettingsReagentsColumnPrice"));

    -- create scroll frame filling the remaining panel area
    local uiService = self:GetService("ui");
    local scrollParent, scrollChild, scrollFrame = uiService:CreateScrollFrame(panel);
    scrollParent:SetPoint("TOPLEFT", itemHeader, "BOTTOMLEFT", -4, -6);
    scrollParent:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16);
    self.scrollChild = scrollChild;
    self.rows = {};

    -- align the price header with the row price column (clear of the scroll bar)
    priceHeader:SetPoint("BOTTOM", itemHeader, "BOTTOM", 0, 0);
    priceHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -28, 0);

    -- keep the scroll child width in sync with the scroll frame
    scrollChild:SetWidth(scrollFrame:GetWidth());
    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);

    -- populate the list when the panel is shown, re-requesting any item still missing;
    -- the reagents of the skill data are only requested here (bind on pickup detection)
    panel:SetScript("OnShow", function()
        self:PreloadItems();
        self:PreloadReagents();
        self:Render();
    end);

    -- register the subpage in interface options
    if (Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory) then
        Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name);
    elseif (InterfaceOptions_AddCategory) then
        panel.parent = parentName;
        InterfaceOptions_AddCategory(panel);
    end

    -- warm the item cache right away so the list is complete on first open
    self.addon:Log("ReagentPricesView", "Register", "registered reagent prices subpage");
    self:PreloadItems();
end

--- Request item data for every vendor price entry and re-render once it arrives.
-- Item:CreateFromItemID triggers the server-side load even for uncached items,
-- which C_Item.DoesItemExistByID would report as non-existent.
function ReagentPricesView:PreloadItems()
    local auctionService = self:GetService("auction");
    self.items = self.items or {};

    for itemId in pairs(auctionService:GetVendorPrices()) do
        self:PreloadItem(itemId);
    end
end

--- Request item data for every reagent of the loaded skill data.
-- Needed to detect bind on pickup drop reagents (bind type is part of the item
-- data); only done once per session when the panel is shown.
function ReagentPricesView:PreloadReagents()
    if (self.reagentsPreloaded) then
        return;
    end
    self.reagentsPreloaded = true;

    local skillsService = self:GetService("skills");
    local count = 0;
    for itemId in pairs(skillsService.allReagents or {}) do
        self:PreloadItem(itemId);
        count = count + 1;
    end
    self.addon:Log("ReagentPricesView", "PreloadReagents", "requested %d reagents for bind on pickup detection", count);
end

--- Request the data of a single item and re-render once it arrives.
-- @param itemId The item ID to load.
function ReagentPricesView:PreloadItem(itemId)
    if (self.items[itemId]) then
        return;
    end

    local item = Item:CreateFromItemID(itemId);
    self.items[itemId] = item;
    if (not item:IsItemEmpty()) then
        pcall(function()
            item:ContinueOnItemLoad(function()
                self:ScheduleRender();
            end);
        end);
    end
end

--- Debounced render request; coalesces async item loads into a single render.
function ReagentPricesView:ScheduleRender()
    if (self.renderScheduled) then
        return;
    end
    self.renderScheduled = true;
    C_Timer.After(0.1, function()
        self.renderScheduled = false;
        self:Render();
    end);
end

--- Create a single reagent row inside the scroll child.
function ReagentPricesView:CreateRow()
    -- capture the view instance so button scripts call it (not the view type)
    local view = self;
    local row = CreateFrame("Button", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(ROW_HEIGHT);
    row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });

    -- item icon
    local icon = row:CreateTexture(nil, "ARTWORK");
    icon:SetSize(ICON_SIZE, ICON_SIZE);
    icon:SetPoint("LEFT", 4, 0);
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    row.icon = icon;

    -- item name (truncated)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    row.nameText = nameText;

    -- price (right-aligned, clear of scroll bar)
    local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    priceText:SetPoint("RIGHT", -28, 0);
    priceText:SetJustifyH("RIGHT");
    row.priceText = priceText;
    nameText:SetPoint("RIGHT", priceText, "LEFT", -6, 0);

    -- hover highlight
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.35, 0.3, 0.15, 0.7);
    end);
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(self.baseR, self.baseG, self.baseB, self.baseA);
    end);

    -- open the edit dialog on click
    row:SetScript("OnClick", function(self)
        view:ShowEditDialog(self.entry);
    end);

    -- purple hover glow (border + purple backdrop)
    self:GetService("ui"):AttachHoverGlow(row);

    return row;
end

--- Rebuild the reagent price rows sorted alphabetically by item name.
function ReagentPricesView:Render()
    if (not self.scrollChild) then
        return;
    end

    local auctionService = self:GetService("auction");
    local professionNamesService = self:GetService("profession-names");
    local vendorPrices = auctionService:GetVendorPrices();

    -- collect only fully loaded items; unloaded ones are skipped and rendered
    -- again once the preload callback fires (never show preliminary item data)
    local entries = {};
    local function addEntry(itemId, defaultPrice, isBindOnPickup)
        local item = self.items and self.items[itemId];
        if (item and not item:IsItemEmpty() and item:IsItemDataCached()) then
            local itemName = item:GetItemName();
            if (itemName) then
                table.insert(entries, {
                    itemId = itemId,
                    defaultPrice = defaultPrice,
                    isBindOnPickup = isBindOnPickup,
                    name = itemName,
                    icon = item:GetItemIcon(),
                    color = professionNamesService:GetItemColor(item:GetItemLink()) or "ffffffff",
                });
            end
        end
    end

    -- vendor reagents with their shipped price
    for itemId, price in pairs(vendorPrices) do
        addEntry(itemId, price, false);
    end

    -- bind on pickup drop reagents of the current expansion (default price 0)
    for itemId in pairs(auctionService:GetDropReagents()) do
        addEntry(itemId, 0, true);
    end

    -- bind on pickup drop reagents first, then alphabetically by item name
    table.sort(entries, function(a, b)
        if (a.isBindOnPickup ~= b.isBindOnPickup) then
            return a.isBindOnPickup;
        end
        return string.lower(a.name) < string.lower(b.name);
    end);

    -- render rows using a pool
    local localeService = self:GetService("locale");
    for index, entry in ipairs(entries) do
        local row = self.rows[index];
        if (not row) then
            row = self:CreateRow();
            self.rows[index] = row;
        end

        -- position and stripe (store base color so hover can restore it)
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT));
        row:SetPoint("RIGHT", self.scrollChild, "RIGHT", 0, 0);
        local shade = (index % 2 == 0) and 0.12 or 0;
        row.baseR, row.baseG, row.baseB = shade, shade, shade;
        row.baseA = shade > 0 and 0.6 or 0;
        row:SetBackdropColor(row.baseR, row.baseG, row.baseB, row.baseA);

        -- resolve the effective price (override wins over the shipped price)
        local override = auctionService:GetVendorPriceOverride(entry.itemId);
        local effectivePrice = override or entry.defaultPrice;
        local priceString = auctionService:FormatPrice(effectivePrice) or "";
        if (override) then
            priceString = "|c" .. OVERRIDE_COLOR .. localeService:Get("SettingsReagentsOverridden") .. "|r " .. priceString;
        elseif (entry.isBindOnPickup) then
            -- bind on pickup without own price: free, marked instead of an empty column
            priceString = "|cff9d9d9d" .. localeService:Get("SettingsReagentsBindOnPickup") .. "|r";
        end

        -- fill the columns
        row.entry = entry;
        row.icon:SetTexture(entry.icon);
        row.nameText:SetText("|c" .. entry.color .. entry.name);
        row.priceText:SetText(priceString);
        row:Show();
    end

    -- hide surplus pooled rows
    for index = #entries + 1, #self.rows do
        self.rows[index]:Hide();
    end

    -- size the scroll child to fit all rows
    self.scrollChild:SetHeight(math.max(#entries * ROW_HEIGHT, 1));
end

--- Lazily build the modal price edit dialog (shared across all rows).
function ReagentPricesView:EnsureDialog()
    if (self.dialog) then
        return self.dialog;
    end

    local localeService = self:GetService("locale");
    local uiService = self:GetService("ui");

    -- dialog sits above the settings window
    local dialog = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
    dialog:SetSize(280, 150);
    dialog:SetPoint("CENTER");
    dialog:SetFrameStrata("FULLSCREEN_DIALOG");
    dialog:SetToplevel(true);
    dialog:EnableMouse(true);
    dialog:SetBackdrop({
        bgFile = [[Interface/Buttons/WHITE8X8]],
        edgeFile = [[Interface/Buttons/WHITE8X8]],
        edgeSize = 1
    });
    dialog:SetBackdropColor(0.05, 0.05, 0.05, 0.98);
    dialog:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.45);
    dialog:Hide();

    -- item icon and name header
    local icon = dialog:CreateTexture(nil, "ARTWORK");
    icon:SetSize(20, 20);
    icon:SetPoint("TOPLEFT", 14, -14);
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    dialog.icon = icon;

    local nameText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0);
    nameText:SetPoint("RIGHT", dialog, "RIGHT", -36, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    dialog.nameText = nameText;

    -- close button
    local closeButton = uiService:CreateFlatCloseButton(dialog, function()
        dialog:Hide();
    end);
    closeButton:SetPoint("TOPRIGHT", -10, -10);

    -- gold / silver / copper input row
    local goldBox = uiService:CreateNumberEditBox(dialog, 64);
    goldBox:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -18);
    dialog.goldBox = goldBox;
    local goldLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    goldLabel:SetPoint("LEFT", goldBox, "RIGHT", 3, 0);
    goldLabel:SetText("|TInterface\\MoneyFrame\\UI-GoldIcon:14|t");

    local silverBox = uiService:CreateNumberEditBox(dialog, 40);
    silverBox:SetPoint("LEFT", goldLabel, "RIGHT", 6, 0);
    dialog.silverBox = silverBox;
    local silverLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    silverLabel:SetPoint("LEFT", silverBox, "RIGHT", 3, 0);
    silverLabel:SetText("|TInterface\\MoneyFrame\\UI-SilverIcon:14|t");

    local copperBox = uiService:CreateNumberEditBox(dialog, 40);
    copperBox:SetPoint("LEFT", silverLabel, "RIGHT", 6, 0);
    dialog.copperBox = copperBox;
    local copperLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    copperLabel:SetPoint("LEFT", copperBox, "RIGHT", 3, 0);
    copperLabel:SetText("|TInterface\\MoneyFrame\\UI-CopperIcon:14|t");

    -- restrict inputs to digits and wire enter/escape
    for _, box in ipairs({ goldBox, silverBox, copperBox }) do
        box.editBox:SetNumeric(true);
        box.editBox:SetMaxLetters(9);
        box.editBox:SetScript("OnEnterPressed", function()
            self:SaveDialog();
        end);
        box.editBox:SetScript("OnEscapePressed", function()
            dialog:Hide();
        end);
    end

    -- save button
    local saveButton = uiService:CreateFlatButton(dialog, localeService:Get("SettingsReagentsSave"), function()
        self:SaveDialog();
    end);
    saveButton:SetSize(110, 24);
    saveButton:SetPoint("BOTTOMLEFT", uiService:GetSideInset(14), uiService:GetBottomInset(14));
    dialog.saveButton = saveButton;

    -- reset-to-default button (shown only when an override exists)
    local resetButton = uiService:CreateFlatButton(dialog, localeService:Get("SettingsReagentsReset"), function()
        if (dialog.itemId) then
            self:GetService("auction"):ClearVendorPriceOverride(dialog.itemId);
        end
        dialog:Hide();
        self:Render();
    end);
    resetButton:SetSize(126, 24);
    resetButton:SetPoint("BOTTOMRIGHT", -uiService:GetSideInset(14), uiService:GetBottomInset(14));
    dialog.resetButton = resetButton;

    self.dialog = dialog;
    return dialog;
end

--- Open the price edit dialog for the given entry.
-- @param entry Row entry with itemId, name, icon, color and defaultPrice.
function ReagentPricesView:ShowEditDialog(entry)
    if (not entry) then
        return;
    end

    local dialog = self:EnsureDialog();
    local auctionService = self:GetService("auction");
    dialog.itemId = entry.itemId;

    -- header
    dialog.icon:SetTexture(entry.icon);
    dialog.nameText:SetText("|c" .. entry.color .. entry.name);

    -- pre-fill inputs with the current effective price
    local override = auctionService:GetVendorPriceOverride(entry.itemId);
    local price = override or entry.defaultPrice or 0;
    dialog.goldBox:SetText(tostring(math.floor(price / 10000)));
    dialog.silverBox:SetText(tostring(math.floor((price % 10000) / 100)));
    dialog.copperBox:SetText(tostring(price % 100));

    -- only offer reset when an override is actually set
    dialog.resetButton:SetShown(override ~= nil);

    dialog:Show();
    dialog:Raise();
    dialog.goldBox.editBox:SetFocus();
end

--- Persist the price currently entered in the dialog.
function ReagentPricesView:SaveDialog()
    local dialog = self.dialog;
    if (not dialog or not dialog.itemId) then
        return;
    end

    -- convert gold/silver/copper inputs into coppers
    local gold = tonumber(dialog.goldBox:GetText()) or 0;
    local silver = tonumber(dialog.silverBox:GetText()) or 0;
    local copper = tonumber(dialog.copperBox:GetText()) or 0;
    local total = gold * 10000 + silver * 100 + copper;

    -- a zero price clears the override back to the shipped default
    self:GetService("auction"):SetVendorPriceOverride(dialog.itemId, total);

    dialog:Hide();
    self:Render();
end
