--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local ExportView = _G.professionMaster:CreateView("export");

--- Refresh the export text based on the selected guild and format.
function ExportView:RefreshExport()
    -- check if guild is selected
    if (not self.selectedGuild or self.selectedGuild == "") then
        self.exportText = "";
        self.editBox:SetText("");
        return;
    end

    -- build and display export string via service
    local exportService = self:GetService("export");
    self.exportText = exportService:BuildExport(self.selectedGuild, self.selectedFormat);
    self.editBox:SetText(self.exportText);
    self.editBox:SetCursorPosition(0);
end

--- Show export view.
function ExportView:Show()
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local playerService = self:GetService("player");

    -- check if view created
    if (self.view == nil) then
        -- create view
        local view = uiService:CreateView("PmExport", 700, 500, localeService:Get("ExportViewTitle"), true, true);
        uiService:SetViewPortrait(view, [[Interface\Icons\Inv_scroll_03]]);
        view:EnableKeyboard();
        view:SetScript("OnKeyDown", function(_, key)
            if (key == "ESCAPE") then
                self:Hide();
            end
        end);
        self.view = view;

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(view, function()
            self:Hide();
        end);
        closeButton:SetHeight(22);
        closeButton:SetWidth(22);
        closeButton:SetPoint("TOPRIGHT", -12, -8);

        -- add guild label
        local guildLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        -- the whole row hangs on this label; in the forever style it starts
        -- right of the portrait ring (same x as the tab strips)
        guildLabel:SetPoint("TOPLEFT", uiService:IsForever() and 60 or 12, -40);
        guildLabel:SetText(localeService:Get("ExportGuildLabel"));

        -- build guild items for dropdown
        local guildItems = {};
        for guildName, _ in pairs(playerService.node.guilds) do
            table.insert(guildItems, { value = guildName, text = guildName });
        end

        -- sort guild names alphabetically
        table.sort(guildItems, function(a, b) return a.text < b.text; end);

        -- create guild dropdown
        local guildDropdown = uiService:CreateDropdown(view, 200, guildItems, function(value)
            self.selectedGuild = value;
            self:RefreshExport();
        end);
        guildDropdown:SetPoint("LEFT", guildLabel, "RIGHT", 8, 0);
        self.guildDropdown = guildDropdown;

        -- pre-select current guild if available
        if (playerService.guildName and #guildItems > 0) then
            self.selectedGuild = playerService.guildName;
            guildDropdown:SetValue(playerService.guildName);
        elseif (#guildItems > 0) then
            self.selectedGuild = guildItems[1].value;
            guildDropdown:SetValue(guildItems[1].value);
        end

        -- add format label
        local formatLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        formatLabel:SetPoint("LEFT", guildDropdown, "RIGHT", 20, 0);
        formatLabel:SetText(localeService:Get("ExportFormatLabel"));

        -- build format items for dropdown
        local formatItems = {
            -- { value = "discord", text = localeService:Get("ExportFormatDiscordBot") },
            { value = "list", text = localeService:Get("ExportFormatList") }
        };

        -- create format dropdown
        local formatDropdown = uiService:CreateDropdown(view, 140, formatItems, function(value)
            self.selectedFormat = value;
            self:RefreshExport();
        end);
        formatDropdown:SetPoint("LEFT", formatLabel, "RIGHT", 8, 0);
        self.formatDropdown = formatDropdown;

        -- pre-select list format
        self.selectedFormat = "list";
        formatDropdown:SetValue("list");

        -- forever style: dark panel behind the text, the rock background is
        -- too light for the small export text
        local textParent = view;
        if (uiService:IsForever()) then
            local textPanel = uiService:CreatePanel(view);
            textPanel:SetPoint("TOPLEFT", 12, -66);
            textPanel:SetPoint("BOTTOMRIGHT", -12, 30);
            textPanel:SetBackdropColor(0, 0, 0, 0.7);
            textParent = textPanel;
            uiService:StyleForeverListBackground(textPanel);
        end

        -- add scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, textParent, "UIPanelScrollFrameTemplate");
        if (textParent == view) then
            scrollFrame:SetPoint("TOPLEFT", 12, -70);
            scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12);
        else
            scrollFrame:SetPoint("TOPLEFT", 6, -6);
            scrollFrame:SetPoint("BOTTOMRIGHT", -22, 6);
            uiService:StyleForeverScrollBar(scrollFrame);
        end
        self.scrollFrame = scrollFrame;

        -- add edit box for selectable/copyable text
        local editBox = CreateFrame("EditBox", nil, scrollFrame);
        editBox:SetMultiLine(true);
        editBox:SetAutoFocus(false);
        editBox:SetFontObject(GameFontHighlightSmall);
        editBox:SetWidth(scrollFrame:GetWidth() - 10);
        editBox:SetScript("OnEscapePressed", function()
            editBox:ClearFocus();
        end);
        editBox:SetScript("OnTextChanged", function(_, userInput)
            if (userInput) then
                -- prevent user edits, restore original text
                editBox:SetText(self.exportText or "");
                editBox:SetCursorPosition(0);
            end
        end);
        scrollFrame:SetScrollChild(editBox);
        self.editBox = editBox;

        -- keep selectable text width in sync when the view is resized
        view:HookScript("OnSizeChanged", function()
            if (self.scrollFrame and self.editBox) then
                self.editBox:SetWidth(math.max(self.scrollFrame:GetWidth() - 10, 1));
            end
        end);

    else
        -- update guild dropdown items on re-open
        local guildItems = {};
        for guildName, _ in pairs(playerService.node.guilds) do
            table.insert(guildItems, { value = guildName, text = guildName });
        end

        -- sort guild names alphabetically
        table.sort(guildItems, function(a, b) return a.text < b.text; end);
        self.guildDropdown:SetItems(guildItems);

        -- pre-select current guild if no selection
        if (not self.selectedGuild and playerService.guildName) then
            self.selectedGuild = playerService.guildName;
            self.guildDropdown:SetValue(playerService.guildName);
        end
    end

    -- refresh export data
    self:RefreshExport();

    -- show view
    self.view:Show();
    self.visible = true;
end

--- Hide view.
function ExportView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
    end
end

--- Toggle visibility.
function ExportView:ToggleVisibility()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end
