--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view: settings page of the linked accounts (trust list, link state)
local LinkedAccountsView = _G.professionMaster:CreateView("linked-accounts");

-- row layout constants
local ROW_HEIGHT = 40;
local REMOVE_BUTTON_SIZE = 18;

--- Register the linked accounts subpage under the given settings category.
-- @param parentCategory The modern Settings category object (or nil on legacy clients).
-- @param parentName The legacy Interface Options parent panel name.
function LinkedAccountsView:Register(parentCategory, parentName)
    local localeService = self:GetService("locale");
    local uiService = self:GetService("ui");
    local linkService = self:GetService("link");
    local view = self;

    -- create options subpanel
    local panel = CreateFrame("Frame");
    panel.name = localeService:Get("SettingsLinkedAccountsTitle");
    self.panel = panel;

    -- add title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 16, -16);
    title:SetText(localeService:Get("SettingsLinkedAccountsTitle"));

    -- add description (what the list does, what gets shared, mutual trust)
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    description:SetPoint("RIGHT", panel, "RIGHT", -16, 0);
    description:SetJustifyH("LEFT");
    description:SetSpacing(2);
    description:SetText(localeService:Get("SettingsLinkedAccountsDescription"));

    -- add row: label, character name edit box, add button
    local addLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
    addLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16);
    addLabel:SetText(localeService:Get("SettingsLinkedAccountsCharacterName"));

    local nameBox = uiService:CreateEditBox(panel, 200);
    nameBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -4);
    nameBox.editBox:SetMaxLetters(40);
    self.nameBox = nameBox;

    local addButton = uiService:CreateFlatButton(panel, localeService:Get("SettingsLinkedAccountsAdd"), function()
        view:AddCharacter();
    end);
    addButton:SetHeight(22);
    addButton:SetWidth(90);
    addButton:SetPoint("LEFT", nameBox, "RIGHT", 6, 0);
    nameBox.editBox:SetScript("OnEnterPressed", function()
        view:AddCharacter();
    end);
    nameBox.editBox:SetScript("OnKeyDown", function(box, key)
        if (key == "ESCAPE") then
            box:ClearFocus();
        end
    end);

    -- feedback line next to the add button (own character, duplicate)
    local feedback = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    feedback:SetPoint("LEFT", addButton, "RIGHT", 8, 0);
    feedback:SetJustifyH("LEFT");
    self.feedback = feedback;

    -- empty list hint
    local emptyText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    emptyText:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 6, -16);
    emptyText:SetText(localeService:Get("SettingsLinkedAccountsEmpty"));
    self.emptyText = emptyText;

    -- create scroll frame filling the remaining panel area
    local scrollParent, scrollChild, scrollFrame = uiService:CreateScrollFrame(panel);
    scrollParent:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", -4, -12);
    scrollParent:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16);
    self.scrollParent = scrollParent;
    self.scrollChild = scrollChild;
    self.rows = {};

    -- keep the scroll child width in sync with the scroll frame
    scrollChild:SetWidth(scrollFrame:GetWidth());
    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);

    -- render on show and whenever the link state changes while shown
    panel:SetScript("OnShow", function()
        feedback:SetText("");
        view:Render();
    end);
    linkService:AddChangeListener(function()
        if (panel:IsVisible()) then
            view:Render();
        end
    end);

    -- register the subpage in interface options
    if (Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory) then
        Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name);
    elseif (InterfaceOptions_AddCategory) then
        panel.parent = parentName;
        InterfaceOptions_AddCategory(panel);
    end
    self.addon:Log("LinkedAccountsView", "Register", "registered linked accounts subpage");
end

--- Add the character of the edit box to the trust list.
function LinkedAccountsView:AddCharacter()
    local localeService = self:GetService("locale");
    local name = self.nameBox:GetText() or "";
    local added, reason = self:GetService("link"):AddTrustedCharacter(name);
    if (added) then
        self.nameBox:SetText("");
        self.nameBox.editBox:ClearFocus();
        self.feedback:SetText("");
        self:Render();
        return;
    end

    -- explain why nothing was added
    if (reason == "own") then
        self.feedback:SetText("|cffff6060" .. localeService:Get("SettingsLinkedAccountsErrorOwn"));
    elseif (reason == "exists") then
        self.feedback:SetText("|cffff6060" .. localeService:Get("SettingsLinkedAccountsErrorExists"));
    else
        self.feedback:SetText("");
    end
end

--- Create a single trust list row inside the scroll child.
function LinkedAccountsView:CreateRow()
    local view = self;
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local row = CreateFrame("Frame", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(ROW_HEIGHT);
    row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });

    -- remove button (clear of the scroll bar)
    local removeButton = uiService:CreateFlatSquareButton(row, "X", function()
        if (row.entry) then
            view:GetService("link"):RemoveTrustedCharacter(row.entry.name);
            view:Render();
        end
    end, REMOVE_BUTTON_SIZE);
    removeButton:SetNormalFontObject("GameFontHighlightSmall");
    removeButton:SetPoint("RIGHT", row, "RIGHT", -32, 0);
    uiService:BindTooltip(removeButton, localeService:Get("SettingsLinkedAccountsRemoveTooltip"));
    row.removeButton = removeButton;

    -- character name on the first line
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("TOPLEFT", 8, -5);
    nameText:SetPoint("RIGHT", removeButton, "LEFT", -6, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    row.nameText = nameText;

    -- link state on the second line
    local stateText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    stateText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3);
    stateText:SetPoint("RIGHT", removeButton, "LEFT", -6, 0);
    stateText:SetJustifyH("LEFT");
    stateText:SetWordWrap(false);
    row.stateText = stateText;

    return row;
end

--- Rebuild the trust list rows.
function LinkedAccountsView:Render()
    if (not self.scrollChild) then
        return;
    end
    local localeService = self:GetService("locale");
    local entries = self:GetService("link"):GetTrustedEntries();

    -- hint instead of an empty list
    self.emptyText:SetShown(#entries == 0);
    self.scrollParent:SetShown(#entries > 0);

    -- render rows using a pool
    for index, entry in ipairs(entries) do
        local row = self.rows[index];
        if (not row) then
            row = self:CreateRow();
            self.rows[index] = row;
        end
        row.entry = entry;

        -- position and stripe
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT));
        row:SetPoint("RIGHT", self.scrollChild, "RIGHT", 0, 0);
        local shade = (index % 2 == 0) and 0.12 or 0;
        row:SetBackdropColor(shade, shade, shade, shade > 0 and 0.6 or 0);

        -- name in white, the link state below it: waiting (grey), linked
        -- (green), online (bright green with the current character)
        row.nameText:SetText("|cffffffff" .. entry.displayName);
        local parts = {};
        if (entry.onlineCharacter) then
            table.insert(parts, "|cff00ee00" .. localeService:Get("SettingsLinkedAccountsStatusOnline", entry.onlineCharacter) .. "|r");
        elseif (entry.linked) then
            table.insert(parts, "|cff71d5ff" .. localeService:Get("SettingsLinkedAccountsStatusLinked") .. "|r");
        else
            table.insert(parts, "|cff999999" .. localeService:Get("SettingsLinkedAccountsStatusPending") .. "|r");
        end
        if (entry.linked) then
            table.insert(parts, localeService:Get("SettingsLinkedAccountsCharacters", entry.characterCount));
        end
        if (entry.lastSync and entry.lastSync > 0) then
            table.insert(parts, localeService:Get("SettingsLinkedAccountsLastSync", date("%Y-%m-%d %H:%M", entry.lastSync)));
        end
        row.stateText:SetText(table.concat(parts, "  |cff666666|||r  "));
        row:Show();
    end

    -- hide unused rows
    for index = #entries + 1, #self.rows do
        self.rows[index]:Hide();
        self.rows[index].entry = nil;
    end
    self.scrollChild:SetHeight(math.max(1, #entries * ROW_HEIGHT));
end
