--[[

@author Kurki
@copyright ®2026 Profession Master. All Rights Reserved.

--]]

-- create view
local ProfessionsView = _G.professionMaster:CreateView("professions");

--- Show professions view.
function ProfessionsView:Show()
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- check if view created
    if (self.view == nil) then
        self.skillView = self.addon:NewView("skill-view");
        self.specView = self.addon:NewView("spec-view");

        -- create view
        local view = uiService:CreateView("PmProfessions", 1000, 540, localeService:Get("ProfessionsViewTitle"), false, true);
        view:EnableKeyboard();
        view:SetScript("OnKeyDown", function(_, key)
            -- check escape
            if (key == "ESCAPE") then
                view:SetPropagateKeyboardInput(false);
                if (self.skillViewVisible) then
                    self:HideSkillView();
                elseif (self.specViewVisible) then
                    self:HideSpecView();
                else
                    self:Hide();
                end
            else
                view:SetPropagateKeyboardInput(true);
            end
        end)

        self.view = view;

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(view, function()
            self:Hide();
        end);
        closeButton:SetHeight(22);
        closeButton:SetWidth(22);
        closeButton:SetPoint("TOPRIGHT", -12, -8);
        uiService:BindTooltip(closeButton, localeService:Get("CloseTooltip"));

        -- add settings button (left of close button); the settings open in an own
        -- window, so this view stays open
        local settingsButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\Trade_engineering]], localeService:Get("SettingsTooltip"), function()
            self.addon.settingsView:Open();
        end);
        settingsButton:SetPoint("RIGHT", closeButton, "LEFT", -18, 0);

        -- add help button (left of settings button)
        self.helpView = self.addon:NewView("help");
        local helpButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\Inv_misc_questionmark]], localeService:Get("HelpTooltip"), function()
            self.helpView:ToggleVisibility();
        end);
        helpButton:SetPoint("RIGHT", settingsButton, "LEFT", -8, 0);

        -- add export button (left of help button)
        self.exportView = self.addon:NewView("export");
        local exportButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\Inv_scroll_03]], localeService:Get("ExportTooltip"), function()
            self.exportView:ToggleVisibility();
        end);
        exportButton:SetPoint("RIGHT", helpButton, "LEFT", -8, 0);

        -- add users button (left of export button)
        self.usersView = self.addon:NewView("users");
        local usersButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\INV_Misc_GroupNeedMore]], localeService:Get("MembersWithoutProfessionMasterTitle"), function()
            self.usersView:ToggleVisibility();
        end);
        usersButton:SetPoint("RIGHT", exportButton, "LEFT", -8, 0);

        -- add database button (left of users button): switches to the
        -- database window, which is then reopened next time
        local databaseButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\INV_Misc_Book_09]], localeService:Get("DatabaseTooltip"), function()
            self.addon:SwitchMainView("database");
        end);
        databaseButton:SetPoint("RIGHT", usersButton, "LEFT", -8, 0);

        -- the classic style keeps the window border clear, the flat style
        -- stays as it is
        local sideInset, headerHeight, footerHeight = 12, 60, 30;
        if (uiService:IsForever()) then
            sideInset, headerHeight, footerHeight = uiService:GetForeverInsets();
        end

        -- add footer
        local footerLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft");
        footerLabel:SetPoint("BOTTOMLEFT", sideInset + 4, uiService:IsForever() and (footerHeight - 19) or 10);
        footerLabel:SetText(localeService:Get("ProfessionsViewFooter"));

        -- add content frame
        local contentFrame = CreateFrame("Frame", nil, view, BackdropTemplateMixin and "BackdropTemplate");
        contentFrame:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
        });
        contentFrame:SetBackdropColor(0, 0, 0, 0.5);
        contentFrame:SetPoint("TOPLEFT", sideInset, -headerHeight);
        contentFrame:SetPoint("BOTTOMRIGHT", -sideInset, footerHeight);

        -- bottom border of tab content area
        local contentBorderBottom = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderBottom:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderBottom:SetHeight(1);
        contentBorderBottom:SetPoint("BOTTOMLEFT", 0, 0);
        contentBorderBottom:SetPoint("BOTTOMRIGHT", 0, 0);

        -- left border of tab content area
        local contentBorderLeft = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderLeft:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderLeft:SetWidth(1);
        contentBorderLeft:SetPoint("TOPLEFT", 0, 0);
        contentBorderLeft:SetPoint("BOTTOMLEFT", 0, 0);

        -- right border of tab content area
        local contentBorderRight = contentFrame:CreateTexture(nil, "BORDER");
        contentBorderRight:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        contentBorderRight:SetWidth(1);
        contentBorderRight:SetPoint("TOPRIGHT", 0, 0);
        contentBorderRight:SetPoint("BOTTOMRIGHT", 0, 0);

        self.contentFrame = contentFrame;

        -- tab strip on the content frame: draws the top border with the gap
        -- for the active tab and clips/scrolls the tabs when the window gets
        -- too narrow for them (arrows at the right end)
        local tabStrip = uiService:CreateTabStrip(view, contentFrame, {
            glowTexture = [[Interface\AddOns\ProfessionMaster\textures\tab-glow]],
        });
        self.tabStrip = tabStrip;

        -- create guild tab button
        self.guildTabButton = tabStrip:AddTab(localeService:Get("TabGuild"), function()
            self:SelectTab("guild");
        end);

        -- create own tab button
        self.ownTabButton = tabStrip:AddTab(localeService:Get("TabOwn"), function()
            self:SelectTab("own");
        end);

        -- the requests/offers tabs come from the TradeBoard addon (optional
        -- dependency); only create them when it is loaded with a compatible
        -- host api version, so PM works standalone and mixed addon versions
        -- degrade instead of erroring
        self.tradeBoardEnabled = self.addon:IsTradeBoardCompatible();

        if (self.tradeBoardEnabled) then
            -- create requests tab button
            self.requestsTabButton = tabStrip:AddTab(localeService:Get("TabRequests"), function()
                self:SelectTab("requests");
            end);

            -- create offers tab button
            self.offersTabButton = tabStrip:AddTab(localeService:Get("TabOffers"), function()
                self:SelectTab("offers");
            end);

            -- purple counters with the number of guild requests/offers behind the captions
            -- (host api additions, an older TradeBoard has none)
            if (_G.tradeBoard.OnGuildEntriesChanged) then
                self:UpdateTradeBadges();
                _G.tradeBoard:OnGuildEntriesChanged(function()
                    self:UpdateTradeBadges();
                end);
            end
        end

        -- create cooldowns tab button
        self.cooldownsTabButton = tabStrip:AddTab(localeService:Get("TabCooldowns"), function()
            self:SelectTab("cooldowns");
        end);

        -- create specializations tab button
        local specTabButton = tabStrip:AddTab(localeService:Get("TabSpecializations"), function()
            self:SelectTab("specializations");
        end);
        self.specTabButton = specTabButton;

        -- hide specializations before tbc (no specs exist)
        if (not self.addon.isBccAtLeast) then
            specTabButton:Hide();
        end

        -- create guild professions panel
        self.guildProfessionsPanel = self.addon:NewView("guild-professions-panel");
        self.guildProfessionsPanel:Create(contentFrame, self);

        -- create guild specializations panel
        self.guildSpecializationsPanel = self.addon:NewView("guild-specializations-panel");
        self.guildSpecializationsPanel:Create(contentFrame, self);

        -- create guild cooldowns panel
        self.guildCooldownsPanel = self.addon:NewView("guild-cooldowns-panel");
        self.guildCooldownsPanel:Create(contentFrame, self);

        -- create requests view (WTB) and offers view (WTS), one tab each; the
        -- trade views live in the TradeBoard addon (optional dependency) and are
        -- embedded here instead of opening their own standalone window
        if (self.tradeBoardEnabled) then
            self.requestsView = _G.tradeBoard:NewView("requests-view");
            self.requestsView:Create(contentFrame, self, "request");
            self.offersView = _G.tradeBoard:NewView("requests-view");
            self.offersView:Create(contentFrame, self, "offer");
        end

        -- create own professions panel
        self.ownProfessionsPanel = self.addon:NewView("own-professions-panel");
        self.ownProfessionsPanel:Create(contentFrame, self);

        -- create bucket list panel (outside tabs, always on right side)
        self.bucketListPanel = self.addon:NewView("bucket-list-panel");
        self.bucketListPanel:Create(contentFrame, self);

        -- handle resize
        view:HookScript("OnSizeChanged", function()
            if (self.activeTab == "guild") then
                self.guildProfessionsPanel:OnSizeChanged();
            elseif (self.activeTab == "specializations") then
                self.guildSpecializationsPanel:OnSizeChanged();
            elseif (self.activeTab == "cooldowns") then
                self.guildCooldownsPanel:OnSizeChanged();
            elseif (self.activeTab == "requests") then
                self.requestsView:OnSizeChanged();
            elseif (self.activeTab == "offers") then
                self.offersView:OnSizeChanged();
            elseif (self.activeTab == "own") then
                self.ownProfessionsPanel:OnSizeChanged();
            end
            if (self.bucketListPanel) then
                self.bucketListPanel:OnSizeChanged();
            end
            if (self.resizePending) then
                self.resizePending:Cancel();
            end
            self.resizePending = C_Timer.NewTimer(0.05, function()
                self.resizePending = nil;
                if (self.activeTab == "guild") then
                    self.guildProfessionsPanel:RefreshRows();
                elseif (self.activeTab == "specializations") then
                    self.guildSpecializationsPanel:RefreshRows();
                elseif (self.activeTab == "cooldowns") then
                    self.guildCooldownsPanel:RefreshRows();
                elseif (self.activeTab == "requests") then
                    self.requestsView:RefreshRows();
                elseif (self.activeTab == "offers") then
                    self.offersView:RefreshRows();
                elseif (self.activeTab == "own") then
                    self.ownProfessionsPanel:RefreshRows();
                end
            end);
        end);

        -- add skill view background
        local skillViewBackground = CreateFrame("Button", nil, view, BackdropTemplateMixin and "BackdropTemplate");
        skillViewBackground:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]]
        });
        skillViewBackground:SetBackdropColor(0, 0, 0, 0.8);
        skillViewBackground:SetPoint("TOPLEFT", 1, -1);
        skillViewBackground:SetPoint("BOTTOMRIGHT", -1, 1);
        skillViewBackground:Hide();
        self.skillViewBackground = skillViewBackground;

        -- the forever frame art and the portrait ring dim along with the window
        uiService:AttachDimArt(view, skillViewBackground);

        -- create version badge panel (anchored at top center of view)
        self.versionBadgePanel = self.addon:NewView("version-badge-panel");
        self.versionBadgePanel:Create(view);

        -- select initial tab
        self:SelectTab(PM_CharacterSettings.lastTab or "guild");
    end

    -- the overview is the main window to reopen next time; the database
    -- window closes so only one main window is open
    PM_CharacterSettings.lastMainView = "professions";
    local databaseView = self.addon.databaseView;
    if (databaseView and databaseView.visible) then
        databaseView:Hide();
    end

    -- hide skill view
    self:HideSkillView(true);
    self:HideSpecView();

    -- refresh active tab
    self:RefreshActiveTab();

    -- refresh bucket list
    self:CheckBucketList();

    -- show view
    self.view:Show();
    self.visible = true;

    -- show version outdated badge if applicable
    self.versionBadgePanel:ShowIfOutdated();

    -- one-time hint what the optional TradeBoard addon would add
    self:CheckTradeBoardHint();
end

--- Show the one-time TradeBoard hint while the optional addon is not
--- installed (an installed but incompatible TradeBoard is handled by the
--- version badge instead); dismissing persists account-wide.
function ProfessionsView:CheckTradeBoardHint()
    if (_G.tradeBoard or PM_Settings.tradeBoardHintDismissed) then
        return;
    end
    if (not self.tradeBoardHintPanel) then
        self.tradeBoardHintPanel = self.addon:NewView("trade-board-hint");
        self.tradeBoardHintPanel:Create(self.view);
    end
    self.tradeBoardHintPanel:Show();
end

--- Select tab.
-- @param tabName Tab name: "guild", "specializations", "cooldowns", "requests", "offers", "own".
function ProfessionsView:SelectTab(tabName)
    -- fall back to guild if a trade tab is requested but TradeBoard is not loaded
    -- (e.g. a persisted lastTab pointing at requests/offers)
    if ((tabName == "requests" or tabName == "offers") and not self.tradeBoardEnabled) then
        tabName = "guild";
    end

    self.activeTab = tabName;
    PM_CharacterSettings.lastTab = tabName;

    -- hide all tab content
    self.guildProfessionsPanel:Hide();
    self.guildSpecializationsPanel:Hide();
    self.guildCooldownsPanel:Hide();
    if (self.requestsView) then self.requestsView:Hide(); end
    if (self.offersView) then self.offersView:Hide(); end
    self.ownProfessionsPanel:Hide();

    -- mark the tab button as active (styles, border gap, scroll into view)
    local tabButtons = {
        guild = self.guildTabButton,
        own = self.ownTabButton,
        requests = self.requestsTabButton,
        offers = self.offersTabButton,
        cooldowns = self.cooldownsTabButton,
        specializations = self.specTabButton,
    };
    self.tabStrip:SetActive(tabButtons[tabName]);

    -- show selected tab content
    if (tabName == "guild") then
        self.guildProfessionsPanel:Show();
    elseif (tabName == "specializations") then
        self.guildSpecializationsPanel:Show();
    elseif (tabName == "cooldowns") then
        self.guildCooldownsPanel:Show();
    elseif (tabName == "requests") then
        self.requestsView:Show();
    elseif (tabName == "offers") then
        self.offersView:Show();
    elseif (tabName == "own") then
        self.ownProfessionsPanel:Show();
    end

    -- update bucket list
    self:CheckBucketList();
end

--- Show the number of guild requests/offers as badge on the trade tabs.
function ProfessionsView:UpdateTradeBadges()
    if (not self.tradeBoardEnabled or not _G.tradeBoard.GetGuildEntryCount) then
        return;
    end
    self.tabStrip:SetBadge(self.requestsTabButton, _G.tradeBoard:GetGuildEntryCount("request"));
    self.tabStrip:SetBadge(self.offersTabButton, _G.tradeBoard:GetGuildEntryCount("offer"));
end

--- Refresh the active tab data.
function ProfessionsView:RefreshActiveTab()
    if (self.activeTab == "guild") then
        self.guildProfessionsPanel:Refresh();
    elseif (self.activeTab == "specializations") then
        self.guildSpecializationsPanel:Refresh();
    elseif (self.activeTab == "cooldowns") then
        self.guildCooldownsPanel:Refresh();
    elseif (self.activeTab == "requests") then
        self.requestsView:Refresh();
    elseif (self.activeTab == "offers") then
        self.offersView:Refresh();
    elseif (self.activeTab == "own") then
        self.ownProfessionsPanel:Refresh();
    end
end

--- Show skill view.
function ProfessionsView:ShowSkillView(row)
     self.skillViewBackground:Show();
     self.skillViewBackground:SetFrameLevel(2000);
     self.skillView:Show(row, self);
     self.skillView.view:SetFrameLevel(2001);
     self.skillViewVisible = true;
end

--- Hide skill view.
function ProfessionsView:HideSkillView(supressLoading)
    self.skillViewBackground:Hide();
    self.skillView:Hide();
    self.skillViewVisible = false;

    if (not supressLoading) then
        self:RefreshActiveTab();
    end
end

--- Show spec view.
function ProfessionsView:ShowSpecView(specData)
    self.skillViewBackground:Show();
    self.skillViewBackground:SetFrameLevel(2000);
    self.specView:Show(specData, self);
    self.specView.view:SetFrameLevel(2001);
    self.specViewVisible = true;
end

--- Hide spec view.
function ProfessionsView:HideSpecView()
    self.skillViewBackground:Hide();
    self.specView:Hide();
    self.specViewVisible = false;
end

--- Hide professions view.
function ProfessionsView:Hide()
    if (self.view) then
        self:HideSkillView();
        self.view:Hide();
    end
    self.visible = false;
end

--- Refresh data while view is open. The sync, purge and cache refreshes only
--- know this window, the database window shows the same data and refreshes
--- along with it.
function ProfessionsView:Refresh()
    if (self.addon.databaseView) then
        self.addon.databaseView:Refresh();
    end
    if (not self.visible) then
        return;
    end
    self:RefreshActiveTab();
end

--- Check bucket list visibility (delegate to guild professions panel).
function ProfessionsView:CheckBucketList()
    if (not self.bucketListPanel) then return; end

    local hasBucketList = self.bucketListPanel:HasItems();

    if (hasBucketList) then
        self.bucketListPanel:Show();
        self.bucketListPanel:Refresh();

        -- shrink active panel
        if (self.activeTab == "guild") then
            self.guildProfessionsPanel:SetRightMargin(300);
        elseif (self.activeTab == "specializations") then
            self.guildSpecializationsPanel:SetRightMargin(300);
        elseif (self.activeTab == "cooldowns") then
            self.guildCooldownsPanel:SetRightMargin(300);
        elseif (self.activeTab == "requests") then
            self.requestsView:SetRightMargin(300);
        elseif (self.activeTab == "offers") then
            self.offersView:SetRightMargin(300);
        elseif (self.activeTab == "own") then
            self.ownProfessionsPanel:SetRightMargin(300);
        end
    else
        self.bucketListPanel:Hide();

        -- expand active panel
        if (self.activeTab == "guild") then
            self.guildProfessionsPanel:SetRightMargin(0);
        elseif (self.activeTab == "specializations") then
            self.guildSpecializationsPanel:SetRightMargin(0);
        elseif (self.activeTab == "cooldowns") then
            self.guildCooldownsPanel:SetRightMargin(0);
        elseif (self.activeTab == "requests") then
            self.requestsView:SetRightMargin(0);
        elseif (self.activeTab == "offers") then
            self.offersView:SetRightMargin(0);
        elseif (self.activeTab == "own") then
            self.ownProfessionsPanel:SetRightMargin(0);
        end
    end
end

--- Toggle visibility.
function ProfessionsView:ToggleVisibility()
    -- show view if not visible
    if (not self.visible) then
        self:Show();
        return;
    end

    -- hide view if visible
    self:Hide();
end