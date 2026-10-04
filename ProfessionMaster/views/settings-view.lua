--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local SettingsView = _G.professionMaster:CreateView("settings");

--- Initialize the settings panel in Interface Options.
function SettingsView:Initialize()
    -- get locale service
    local localeService = self:GetService("locale");

    -- create options panel
    local panel = CreateFrame("Frame");
    panel.name = "Profession Master";

    -- add title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 16, -16);
    title:SetText("Profession Master");

    -- window style of all Master addons (flat or forever) first, applied after a reload
    local uiStyleDropdown = self:GetService("ui"):CreateUiStyleDropdown(panel, "PmSettingsUiStyle");
    uiStyleDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -12);

    -- window scale of all Master addons right of the style, applied while sliding
    local uiScaleSlider = self:GetService("ui"):CreateUiScaleSlider(panel, "PmSettingsUiScale");
    uiScaleSlider:SetPoint("TOPLEFT", uiStyleDropdown, "TOPRIGHT", 56, 0);

    -- show minimap button checkbox; the state is re-read on every show
    -- since the button can also be hidden via ctrl+right-click on the icon
    local minimapCheckbox = CreateFrame("CheckButton", "PmSettingsShowMinimapButton", panel, "InterfaceOptionsCheckButtonTemplate");
    minimapCheckbox:SetPoint("TOPLEFT", uiStyleDropdown, "BOTTOMLEFT", 16, -4);
    minimapCheckbox.Text:SetText(localeService:Get("SettingsShowMinimapButton"));
    minimapCheckbox.Text:SetPoint("LEFT", minimapCheckbox, "RIGHT", 4, 0);
    minimapCheckbox:SetChecked(not PM_Settings.minimapButton.hide);
    minimapCheckbox:SetScript("OnClick", function(checkbox)
        local show = checkbox:GetChecked();
        self:GetService("ui"):SetMinimapIconShown(show);
    end);
    panel:SetScript("OnShow", function()
        minimapCheckbox:SetChecked(not PM_Settings.minimapButton.hide);
    end);

    -- add respond to !who checkbox
    local respondToWhoCheckbox = CreateFrame("CheckButton", "PmSettingsRespondToWho", panel, "InterfaceOptionsCheckButtonTemplate");
    respondToWhoCheckbox:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -8);
    respondToWhoCheckbox.Text:SetText(localeService:Get("SettingsRespondToWho"));
    respondToWhoCheckbox.Text:SetPoint("LEFT", respondToWhoCheckbox, "RIGHT", 4, 0);
    respondToWhoCheckbox:SetChecked(PM_Settings.respondToWho);
    respondToWhoCheckbox:SetScript("OnClick", function(self)
        PM_Settings.respondToWho = self:GetChecked();
    end);

    -- share cooldowns checkbox
    local shareCooldownsCheckbox = CreateFrame("CheckButton", "PmSettingsShareCooldowns", panel, "InterfaceOptionsCheckButtonTemplate");
    shareCooldownsCheckbox:SetPoint("TOPLEFT", respondToWhoCheckbox, "BOTTOMLEFT", 0, -8);
    shareCooldownsCheckbox.Text:SetText(localeService:Get("SettingsShareCooldowns"));
    shareCooldownsCheckbox.Text:SetPoint("LEFT", shareCooldownsCheckbox, "RIGHT", 4, 0);
    shareCooldownsCheckbox:SetChecked(PM_Settings.shareCooldowns);
    shareCooldownsCheckbox:SetScript("OnClick", function(self)
        PM_Settings.shareCooldowns = self:GetChecked();
    end);

    -- auto scan auction house prices checkbox (own price scan, used when
    -- neither Auctionator nor TSM is installed)
    local autoScanPricesCheckbox = CreateFrame("CheckButton", "PmSettingsAutoScanPrices", panel, "InterfaceOptionsCheckButtonTemplate");
    autoScanPricesCheckbox:SetPoint("TOPLEFT", shareCooldownsCheckbox, "BOTTOMLEFT", 0, -8);
    autoScanPricesCheckbox.Text:SetText(localeService:Get("SettingsAutoScanPrices"));
    autoScanPricesCheckbox.Text:SetPoint("LEFT", autoScanPricesCheckbox, "RIGHT", 4, 0);
    autoScanPricesCheckbox:SetChecked(PM_Settings.autoScanPrices);
    autoScanPricesCheckbox:SetScript("OnClick", function(self)
        PM_Settings.autoScanPrices = self:GetChecked();
    end);

    -- cooldown notification dropdown
    local cooldownNotificationModes = {"both", "chat", "never"};
    local cooldownNotificationLabels = {
        ["both"] = localeService:Get("SettingsCooldownNotificationBoth"),
        ["chat"] = localeService:Get("SettingsCooldownNotificationChat"),
        ["never"] = localeService:Get("SettingsCooldownNotificationNever")
    };
    local cooldownNotificationDropdown = self:CreateTooltipDropdown(
        panel, "PmSettingsCooldownNotification",
        localeService:Get("SettingsCooldownNotification"),
        cooldownNotificationModes, cooldownNotificationLabels,
        PM_Settings.cooldownNotification,
        function(value) PM_Settings.cooldownNotification = value; end,
        160
    );
    cooldownNotificationDropdown:SetPoint("TOPLEFT", autoScanPricesCheckbox, "BOTTOMLEFT", -16, -16);

    -- tbc content phase dropdown (tbc client only): skills and items of later,
    -- not yet released phases are hidden everywhere in the addon
    local bccPhaseDropdown = nil;
    if (self.addon.isBcc) then
        local bccPhases = {1, 2, 3, 4, 5};
        local bccPhaseLabels = {
            [1] = localeService:Get("SettingsBccPhase1"),
            [2] = localeService:Get("SettingsBccPhase2"),
            [3] = localeService:Get("SettingsBccPhase3"),
            [4] = localeService:Get("SettingsBccPhase4"),
            [5] = localeService:Get("SettingsBccPhase5")
        };
        bccPhaseDropdown = self:CreateTooltipDropdown(
            panel, "PmSettingsBccPhase",
            localeService:Get("SettingsBccPhase"),
            bccPhases, bccPhaseLabels,
            PM_Settings.bccPhase or 5,
            function(value)
                -- rebuild the skill cache so hidden/revealed skills apply immediately;
                -- a hand picked phase sticks and is no longer advanced automatically
                PM_Settings.bccPhase = value;
                PM_Settings.bccPhaseManual = true;
                self:GetService("skills"):ForceRefreshCache();
            end,
            240
        );
        bccPhaseDropdown:SetPoint("TOPLEFT", cooldownNotificationDropdown, "BOTTOMLEFT", 0, -8);
    end

    -- tooltip settings group header
    local tooltipGroupHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    tooltipGroupHeader:SetPoint("TOPLEFT", bccPhaseDropdown or cooldownNotificationDropdown, "BOTTOMLEFT", 16, -23);
    tooltipGroupHeader:SetText(localeService:Get("SettingsTooltipGroup"));

    -- tooltip mode options
    local tooltipModes = {"always", "shift", "never"};
    local tooltipModeLabels = {
        ["always"] = localeService:Get("SettingsTooltipAlways"),
        ["shift"] = localeService:Get("SettingsTooltipOnShift"),
        ["never"] = localeService:Get("SettingsTooltipNever")
    };

    -- tooltip: player names dropdown
    local tooltipPlayersDropdown = self:CreateTooltipDropdown(
        panel, "PmSettingsTooltipShowPlayers",
        localeService:Get("SettingsTooltipShowPlayers"),
        tooltipModes, tooltipModeLabels,
        PM_Settings.tooltipShowPlayers,
        function(value) PM_Settings.tooltipShowPlayers = value; end
    );
    tooltipPlayersDropdown:SetPoint("TOPLEFT", tooltipGroupHeader, "BOTTOMLEFT", -16, -18);

    -- tooltip: reagents dropdown
    local tooltipReagentForDropdown = self:CreateTooltipDropdown(
        panel, "PmSettingsTooltipShowReagentFor",
        localeService:Get("SettingsTooltipShowReagentFor"),
        tooltipModes, tooltipModeLabels,
        PM_Settings.tooltipShowReagentFor,
        function(value) PM_Settings.tooltipShowReagentFor = value; end
    );
    tooltipReagentForDropdown:SetPoint("LEFT", tooltipPlayersDropdown, "RIGHT", 8, 0);

    -- tooltip: player professions dropdown
    local tooltipPlayerProfessionsDropdown = self:CreateTooltipDropdown(
        panel, "PmSettingsTooltipShowPlayerProfessions",
        localeService:Get("SettingsTooltipShowPlayerProfessions"),
        tooltipModes, tooltipModeLabels,
        PM_Settings.tooltipShowPlayerProfessions,
        function(value) PM_Settings.tooltipShowPlayerProfessions = value; end
    );
    tooltipPlayerProfessionsDropdown:SetPoint("LEFT", tooltipReagentForDropdown, "RIGHT", 8, 0);

    -- tooltip: gathering nodes dropdown
    local tooltipGatheringNodesDropdown = self:CreateTooltipDropdown(
        panel, "PmSettingsTooltipShowGatheringNodes",
        localeService:Get("SettingsTooltipShowGatheringNodes"),
        tooltipModes, tooltipModeLabels,
        PM_Settings.tooltipShowGatheringNodes,
        function(value) PM_Settings.tooltipShowGatheringNodes = value; end
    );
    tooltipGatheringNodesDropdown:SetPoint("LEFT", tooltipPlayerProfessionsDropdown, "RIGHT", 8, 0);

    -- layout settings group header
    local layoutGroupHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    layoutGroupHeader:SetPoint("TOPLEFT", tooltipPlayersDropdown, "BOTTOMLEFT", 16, -24);
    layoutGroupHeader:SetText(localeService:Get("SettingsLayoutGroup"));

    -- background missing reagents slider
    local missingReagentsSlider = self:CreateAlphaSlider(
        panel, "PmSettingsBackgroundMissingReagents",
        localeService:Get("SettingsBackgroundMissingReagents"),
        PM_Settings.backgroundMissingReagents,
        function(value)
            PM_Settings.backgroundMissingReagents = value;
            local inventoryService = self:GetService("inventory");
            if (inventoryService.missingReagentsView) then
                inventoryService.missingReagentsView:SetBackgroundAlpha(value);
            end
        end
    );
    missingReagentsSlider:SetPoint("TOPLEFT", layoutGroupHeader, "BOTTOMLEFT", 0, -18);

    -- background cooldowns slider
    local cooldownsSlider = self:CreateAlphaSlider(
        panel, "PmSettingsBackgroundCooldowns",
        localeService:Get("SettingsBackgroundCooldowns"),
        PM_Settings.backgroundCooldowns,
        function(value)
            PM_Settings.backgroundCooldowns = value;
            local cooldownService = self:GetService("cooldown");
            if (cooldownService.cooldownView) then
                cooldownService.cooldownView:SetBackgroundAlpha(value);
            end
        end
    );
    cooldownsSlider:SetPoint("LEFT", missingReagentsSlider, "RIGHT", 46, 0);

    -- register in interface options
    local category = nil;
    if (Settings and Settings.RegisterCanvasLayoutCategory) then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
        Settings.RegisterAddOnCategory(category);
        self.categoryId = category:GetID();
    elseif (InterfaceOptions_AddCategory) then
        InterfaceOptions_AddCategory(panel);
    end

    -- collect the option pages for the own settings window (see Open); the main
    -- page is always the first one, its tab reads "General" there (the
    -- interface options keep the addon name as category)
    self.pages = { { panel = panel, caption = localeService:Get("SettingsGeneralTab") } };

    -- register the reagent prices subpage under this category
    self.reagentPricesView = self.addon:NewView("reagent-prices");
    self.reagentPricesView:Register(category, panel.name);
    table.insert(self.pages, { panel = self.reagentPricesView.panel });

    -- register the trade board settings subpage when a compatible TradeBoard
    -- addon is loaded (see IsTradeBoardCompatible)
    if (self.addon:IsTradeBoardCompatible() and _G.tradeBoard.GetView and _G.tradeBoard:GetView("settings")) then
        _G.tradeBoard.settingsView = _G.tradeBoard:NewView("settings");
        _G.tradeBoard.settingsView:Register(category, panel.name);
        table.insert(self.pages, { panel = _G.tradeBoard.settingsView.panel });
    end

    -- register the linked accounts subpage (trust list for other accounts)
    self.linkedAccountsView = self.addon:NewView("linked-accounts");
    self.linkedAccountsView:Register(category, panel.name);
    table.insert(self.pages, { panel = self.linkedAccountsView.panel });
end

--- Open the settings in an own addon window.
-- The pages registered in the interface options are re-parented into the window,
-- so the professions window does not have to be closed to change settings. The
-- interface options frame takes a page back whenever it displays it itself.
function SettingsView:Open()
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- create the settings window on first open
    if (self.window == nil) then
        -- title: addon name in the addon color, "- Settings" in white
        local window = uiService:CreateView("PmSettings", 720, 680, "|cffDA8CFFProfession Master|r |cffffffff- " .. localeService:Get("SettingsTooltip") .. "|r", false);
        uiService:SetViewPortrait(window, [[Interface\Icons\Trade_engineering]]);
        window:EnableKeyboard();
        window:SetScript("OnKeyDown", function(frame, key)
            -- close on escape
            if (key == "ESCAPE") then
                frame:SetPropagateKeyboardInput(false);
                self:Close();
            else
                frame:SetPropagateKeyboardInput(true);
            end
        end);
        self.window = window;

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(window, function()
            self:Close();
        end);
        closeButton:SetHeight(22);
        closeButton:SetWidth(22);
        closeButton:SetPoint("TOPRIGHT", -12, -8);
        uiService:BindTooltip(closeButton, localeService:Get("CloseTooltip"));

        -- add the content frame the option pages are hosted in; bottom, left
        -- and right border here, the tab strip draws the top border
        local contentFrame = CreateFrame("Frame", nil, window, BackdropTemplateMixin and "BackdropTemplate");
        contentFrame:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
        });
        contentFrame:SetBackdropColor(0, 0, 0, 0.5);

        -- the classic style keeps the window border clear, the flat style
        -- stays as it is
        local sideInset, headerHeight, footerHeight = 12, 64, 12;
        if (uiService:IsForever()) then
            local side, header, _, plainFooter = uiService:GetForeverInsets();
            sideInset, headerHeight, footerHeight = side, header + 4, plainFooter;
        end
        contentFrame:SetPoint("TOPLEFT", sideInset, -headerHeight);
        contentFrame:SetPoint("BOTTOMRIGHT", -sideInset, footerHeight);
        self.contentFrame = contentFrame;

        local contentBorderBottom = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderBottom:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderBottom:SetHeight(1);
        contentBorderBottom:SetPoint("BOTTOMLEFT", 0, 0);
        contentBorderBottom:SetPoint("BOTTOMRIGHT", 0, 0);
        local contentBorderLeft = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderLeft:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderLeft:SetWidth(1);
        contentBorderLeft:SetPoint("TOPLEFT", 0, 0);
        contentBorderLeft:SetPoint("BOTTOMLEFT", 0, 0);
        local contentBorderRight = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderRight:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderRight:SetWidth(1);
        contentBorderRight:SetPoint("TOPRIGHT", 0, 0);
        contentBorderRight:SetPoint("BOTTOMRIGHT", 0, 0);

        -- tab strip on the content frame, one tab per option page labelled
        -- like its interface options entry (same control as the main windows)
        local tabStrip = uiService:CreateTabStrip(window, contentFrame, {
            glowTexture = [[Interface\AddOns\ProfessionMaster\textures\tab-glow]],
            tabWidth = 150,
        });
        self.tabStrip = tabStrip;
        for index, page in ipairs(self.pages) do
            local pageIndex = index;
            page.button = tabStrip:AddTab(page.caption or page.panel.name, function()
                self:SelectPage(pageIndex);
            end);

            -- the interface options frame re-parents a page when it displays it:
            -- close the own window then instead of showing an empty page
            page.panel:HookScript("OnShow", function(shownPanel)
                if (self.window:IsShown() and shownPanel:GetParent() ~= self.contentFrame) then
                    self:Close();
                end
            end);
        end
    end

    -- show the last selected page and the window
    self:SelectPage(self.activePage or 1);
    self.window:Show();
    self.addon:Log("SettingsView", "Open", "settings window opened on page %d", self.activePage);
end

--- Close the settings window.
function SettingsView:Close()
    if (self.window) then
        self.window:Hide();
    end
end

--- Select an option page: host it in the settings window and hide the others.
-- @param index Index of the page in self.pages.
function SettingsView:SelectPage(index)
    -- fall back to the main page for an unknown index
    if (not self.pages[index]) then
        index = 1;
    end
    self.activePage = index;

    for pageIndex, page in ipairs(self.pages) do
        -- host the selected page in the content frame, hide all others
        if (pageIndex == index) then
            page.panel:SetParent(self.contentFrame);
            page.panel:ClearAllPoints();
            page.panel:SetAllPoints(self.contentFrame);
            page.panel:Show();
        else
            page.panel:Hide();
        end
    end

    -- highlight the tab of the selected page
    local page = self.pages[index];
    if (self.tabStrip and page.button) then
        self.tabStrip:SetActive(page.button);
    end
end

--- Create a tooltip option dropdown with label (flat or game dropdown, see
--- UiService:CreateOptionsDropdown).
function SettingsView:CreateTooltipDropdown(parent, name, label, modes, modeLabels, currentValue, onChange, width)
    return self:GetService("ui"):CreateOptionsDropdown(parent, name, label, modes, modeLabels, currentValue, onChange, width);
end

--- Create an alpha slider (0-80%) with label and value display.
function SettingsView:CreateAlphaSlider(parent, name, label, currentValue, onChange)
    local function FormatPercent(value)
        return math.floor(value + 0.5) .. "%";
    end
    return self:GetService("ui"):CreateOptionsSlider(parent, name, label, 0, 80, 5, math.floor(currentValue * 100 + 0.5), FormatPercent, function(value)
        onChange(value / 100);
    end, 215);
end
