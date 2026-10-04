--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local HelpView = _G.professionMaster:CreateView("help");

-- discord invite url
local discordUrl = "https://discord.com/invite/YddUBQ6R55";

-- paypal donation url
local donateUrl = "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=dkplootmaster@withoutascratch.net&lc=US&no_note=0&item_name=Profession-Master&cn=&currency_code=EUR&bn=PP-DonationsBF:btn_donateCC_LG.gif:NonHosted";

--- Show help view.
function HelpView:Show()
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- check if view created
    if (self.view == nil) then
        -- create view
        local view = uiService:CreateToolView("PmHelp", 420, 680, "|cffDA8CFFProfession Master", false);
        view:EnableKeyboard();
        view:SetScript("OnKeyDown", function(frame, key)
            if (key == "ESCAPE") then
                frame:SetPropagateKeyboardInput(false);
                self:Hide();
            else
                frame:SetPropagateKeyboardInput(true);
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

        -- add logo icon
        local logo = view:CreateTexture(nil, "ARTWORK");
        logo:SetSize(48, 48);
        logo:SetPoint("TOPLEFT", 16, -44);
        logo:SetTexture([[Interface\AddOns\ProfessionMaster\icons\pm-logo.png]]);

        -- add addon title next to logo
        local addonTitle = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
        addonTitle:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -4);
        addonTitle:SetTextColor(1, 1, 1);
        addonTitle:SetText("Profession Master " .. localeService:Get("HelpByKurki"));

        -- add version text below title
        local versionText = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        versionText:SetPoint("TOPLEFT", addonTitle, "BOTTOMLEFT", 0, -4);
        versionText:SetTextColor(0.7, 0.7, 0.7);
        versionText:SetText("Version: " .. self.addon.version);

        -- add discord feedback text
        local discordText = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        discordText:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -20);
        discordText:SetPoint("RIGHT", view, "RIGHT", -16, 0);
        discordText:SetJustifyH("LEFT");
        discordText:SetTextColor(0.9, 0.9, 0.9);
        discordText:SetText(localeService:Get("HelpDiscordFeedback"));

        -- add discord button
        local discordButton = uiService:CreateFlatButton(view, localeService:Get("HelpDiscordButton"), function()
            self:ShowLinkDialog("Discord Link", discordUrl);
        end);
        discordButton:SetWidth(140);
        discordButton:SetHeight(24);
        discordButton:SetPoint("TOPLEFT", discordText, "BOTTOMLEFT", 0, -8);

        -- add show log button
        local logButton = uiService:CreateFlatButton(view, localeService:Get("HelpShowLogButton"), function()
            local commandsService = self:GetService("commands");
            if (not commandsService.logsView) then
                commandsService.logsView = self.addon:NewView("logs");
            end
            commandsService.logsView:Show();
        end);
        logButton:SetWidth(140);
        logButton:SetHeight(24);
        logButton:SetPoint("LEFT", discordButton, "RIGHT", 8, 0);

        -- add description header
        local descriptionHeader = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        descriptionHeader:SetPoint("TOPLEFT", discordButton, "BOTTOMLEFT", 0, -20);
        descriptionHeader:SetPoint("RIGHT", view, "RIGHT", -16, 0);
        descriptionHeader:SetJustifyH("LEFT");
        descriptionHeader:SetTextColor(0.85, 0.55, 0.22);
        descriptionHeader:SetText(localeService:Get("HelpHowItWorksTitle"));

        -- add description text
        local descriptionBody = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        descriptionBody:SetPoint("TOPLEFT", descriptionHeader, "BOTTOMLEFT", 0, -6);
        descriptionBody:SetPoint("RIGHT", view, "RIGHT", -16, 0);
        descriptionBody:SetJustifyH("LEFT");
        descriptionBody:SetTextColor(0.8, 0.8, 0.8);
        descriptionBody:SetText(localeService:Get("HelpHowItWorksBody"));

        -- add donate button at the bottom of the window
        local donateButton = uiService:CreateFlatButton(view, localeService:Get("HelpDonateButton"), function()
            self:ShowLinkDialog("PayPal Link", donateUrl);
        end);
        donateButton:SetWidth(200);
        donateButton:SetHeight(24);
        donateButton:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", uiService:GetSideInset(16), uiService:GetBottomInset(12));

        -- add donation text above the button
        local donateText = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        donateText:SetPoint("BOTTOMLEFT", donateButton, "TOPLEFT", 0, 8);
        donateText:SetPoint("RIGHT", view, "RIGHT", -16, 0);
        donateText:SetJustifyH("LEFT");
        donateText:SetTextColor(0.9, 0.9, 0.9);
        donateText:SetText(localeService:Get("HelpDonateText"));

        -- add command entries (anchored from bottom, above the donation text)
        local commands = {
            { cmd = "/pm", desc = localeService:Get("HelpCmdOverviewDesc") },
            { cmd = "/pm database", desc = localeService:Get("HelpCmdDatabaseDesc") },
            { cmd = "/pm reagents", desc = localeService:Get("HelpCmdReagentsDesc") },
            { cmd = "/pm cooldowns", desc = localeService:Get("HelpCmdCooldownsDesc") },
            { cmd = "/pm scan", desc = localeService:Get("HelpCmdScanDesc") },
            { cmd = "/pm minimap", desc = localeService:Get("HelpCmdMinimapDesc") },
            { cmd = "/pm purge", desc = localeService:Get("HelpCmdPurgeDesc") },
            { cmd = "/pm logs", desc = localeService:Get("HelpCmdLogsDesc") },
        };

        -- render commands bottom-up
        local previousAnchor = nil;
        for i = #commands, 1, -1 do
            local entry = commands[i];

            -- description below command
            local cmdDesc = view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
            cmdDesc:SetPoint("RIGHT", view, "RIGHT", -16, 0);
            cmdDesc:SetJustifyH("LEFT");
            cmdDesc:SetTextColor(0.7, 0.7, 0.7);
            cmdDesc:SetText(entry.desc);

            -- command label in gold
            local cmdLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            cmdLabel:SetTextColor(0.83, 0.68, 0.21);
            cmdLabel:SetText(entry.cmd);

            -- anchor from bottom
            if (previousAnchor == nil) then
                cmdDesc:SetPoint("BOTTOMLEFT", donateText, "TOPLEFT", 0, 20);
            else
                cmdDesc:SetPoint("BOTTOMLEFT", previousAnchor, "TOPLEFT", 0, 10);
            end
            cmdLabel:SetPoint("BOTTOMLEFT", cmdDesc, "TOPLEFT", 0, 2);

            -- set anchor for next entry above
            previousAnchor = cmdLabel;
        end

        -- add commands header above commands
        local commandsHeader = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        commandsHeader:SetPoint("BOTTOMLEFT", previousAnchor, "TOPLEFT", 0, 10);
        commandsHeader:SetPoint("RIGHT", view, "RIGHT", -16, 0);
        commandsHeader:SetJustifyH("LEFT");
        commandsHeader:SetTextColor(0.85, 0.55, 0.22);
        commandsHeader:SetText(localeService:Get("HelpCommandsTitle"));
    end

    -- show view
    self.view:Show();
    self.visible = true;
end

--- Show a small dialog with a selectable link (discord, paypal).
function HelpView:ShowLinkDialog(title, url)
    -- get services
    local uiService = self:GetService("ui");

    -- create link dialog once
    if (not self.linkDialog) then
        local dialog = uiService:CreateToolView("PmDiscordLink", 340, 90, title, false);
        dialog:EnableKeyboard();
        dialog:SetScript("OnKeyDown", function(_, key)
            if (key == "ESCAPE") then
                dialog:Hide();
            end
        end);
        self.linkDialog = dialog;

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(dialog, function()
            dialog:Hide();
        end);
        closeButton:SetHeight(18);
        closeButton:SetWidth(18);
        closeButton:SetPoint("TOPRIGHT", -8, -6);

        -- add url edit box
        local editBox = uiService:CreateEditBox(dialog, 308);
        editBox:SetPoint("TOPLEFT", 16, -40);
        dialog.editBox = editBox;
    end

    -- set title and url, focus and highlight the text for copying
    local dialog = self.linkDialog;
    dialog.titleLabel:SetText(title);
    dialog:Show();
    dialog.editBox.editBox:SetText(url);
    dialog.editBox.editBox:SetCursorPosition(0);
    dialog.editBox.editBox:HighlightText();
    dialog.editBox.editBox:SetFocus();
    self.addon:Log("HelpView", "ShowLinkDialog", "link dialog shown: %s", title);
end

--- Hide view.
function HelpView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
    end
end

--- Toggle visibility.
function HelpView:ToggleVisibility()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end
