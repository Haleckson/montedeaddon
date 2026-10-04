--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local CooldownView = _G.professionMaster:CreateView("cooldown");

--- Set background alpha.
function CooldownView:SetBackgroundAlpha(value)
    if (not self.view) then return; end
    self.view:SetBackdropColor(0, 0, 0, value);
    self.view:SetBackdropBorderColor(0.5, 0.5, 0.5, value);
end

--- Show cooldown view.
function CooldownView:Show()
    -- get services
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- check if view created
    if (self.view == nil) then
        self.rows = {};

        -- create view
        local view = uiService:CreateOverlayView("PmCooldownView", 280, 200, localeService:Get("CooldownViewTitle"));
        view:EnableKeyboard();
        self.view = view;
        self:SetBackgroundAlpha(PM_Settings.backgroundCooldowns or 0);

        -- add close button
        local closeButton = uiService:CreateFlatCloseButton(view, function()
            PM_Settings.hideCooldowns = true;
            self:Hide();
        end);
        closeButton:SetHeight(20);
        closeButton:SetWidth(20);
        closeButton:SetPoint("TOPRIGHT", -12, -8);
        closeButton:Hide();

        -- bind hover events
        local onEnter = function()
            self:SetBackgroundAlpha(0.8);
            closeButton:Show();
        end;
        local onLeave = function()
            C_Timer.After(0.05, function()
                if (not view:IsVisible()) then return; end
                if (view:IsMouseOver()) then return; end
                self:SetBackgroundAlpha(PM_Settings.backgroundCooldowns or 0);
                closeButton:Hide();
            end);
        end;

        view:SetScript("OnEnter", onEnter);
        view:SetScript("OnLeave", onLeave);
        closeButton:SetScript("OnEnter", onEnter);
        closeButton:SetScript("OnLeave", onLeave);
    end

    -- refresh content
    self:Refresh();
    self.view:Show();
    self.visible = true;

    -- start ticker for time updates
    self:StartTicker();
end

--- Hide view.
function CooldownView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
        self:StopTicker();
    end
end

--- Toggle visibility.
function CooldownView:Toggle()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end

--- Start periodic refresh ticker.
function CooldownView:StartTicker()
    self:StopTicker();
    self.ticker = C_Timer.NewTicker(1, function()
        if (self.view and self.view:IsShown()) then
            self:RefreshTimes();
        else
            self:StopTicker();
        end
    end);
end

--- Stop periodic refresh ticker.
function CooldownView:StopTicker()
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
end

--- Refresh row times only.
function CooldownView:RefreshTimes()
    local currentTime = time();
    local cooldownService = self:GetService("cooldown");
    local playerService = self:GetService("player");

    for _, row in ipairs(self.rows) do
        if (row:IsShown() and row.expires) then
            local remaining = row.expires - currentTime;
            if (row.expires == 0) then remaining = 0; end
            row.timeText:SetText(self:GetService("timer"):FormatTime(remaining));
        end
    end
end

--- Refresh the watched cooldowns content.
function CooldownView:Refresh()
    if (not self.view) then return; end

    -- get services
    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local cooldownService = self:GetService("cooldown");
    local localeService = self:GetService("locale");
    local currentTime = time();

    -- hide all existing rows
    for _, row in ipairs(self.rows) do
        row:Hide();
    end

    -- build watched entries from stored data
    local entries = {};
    for _, watched in ipairs(PM_Settings.watchedCooldowns) do
        local fullName = playerService:GetLongName(watched.playerName);
        local cooldowns = playerService.node.cooldowns and playerService.node.cooldowns[fullName];
        local expires = cooldowns and cooldowns[watched.spellId] or nil;

        -- get item name and color from skills
        local skill = skillsService:GetSkillById(watched.spellId);
        local itemName;
        local itemColor;
        if (skill and skill.itemId and skill.itemId > 0) then
            local name, _, itemQuality = self.addon.compat.GetItemInfo(skill.itemId);
            itemName = name;
            if (itemQuality and ITEM_QUALITY_COLORS[itemQuality]) then
                itemColor = ITEM_QUALITY_COLORS[itemQuality].hex;
            end
        end
        if (not itemName) then
            itemName = self.addon.compat.GetSpellInfo(watched.spellId) or ("Spell " .. watched.spellId);
        end

        -- determine display name
        local displayName;
        local shortName = playerService:GetShortName(watched.playerName);
        if (playerService:IsCurrentPlayer(watched.playerName)) then
            displayName = localeService:Get("You");
        elseif (playerService.node.own[playerService:GetLongName(watched.playerName)]) then
            displayName = localeService:Get("You") .. " (" .. shortName .. ")";
        else
            displayName = shortName;
        end

        table.insert(entries, {
            playerName = watched.playerName,
            spellId = watched.spellId,
            displayName = displayName,
            itemName = itemName,
            itemColor = itemColor,
            expires = expires or 0,
        });
    end

    -- sort: ready first, then by remaining time
    table.sort(entries, function(a, b)
        local aRemaining = (a.expires == 0) and 0 or (a.expires - currentTime);
        local bRemaining = (b.expires == 0) and 0 or (b.expires - currentTime);
        if (aRemaining <= 0 and bRemaining > 0) then return true; end
        if (bRemaining <= 0 and aRemaining > 0) then return false; end
        return aRemaining < bRemaining;
    end);

    -- render rows
    local rowCount = 0;
    for _, entry in ipairs(entries) do
        rowCount = rowCount + 1;

        if (#self.rows < rowCount) then
            -- create row
            local row = CreateFrame("Button", nil, self.view, BackdropTemplateMixin and "BackdropTemplate");
            local top = 33 + ((rowCount - 1) * 16);
            row:SetPoint("TOPLEFT", self.view, "TOPLEFT", 10, -top);
            row:SetPoint("BOTTOMRIGHT", self.view, "TOPRIGHT", -10, -(top + 18));
            row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });
            row:SetBackdropColor(0, 0, 0, 0);

            -- item + player text (left)
            local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            itemText:SetPoint("LEFT", 6, 0);
            itemText:SetJustifyH("LEFT");
            itemText:SetWordWrap(false);
            row.itemText = itemText;

            -- time text (right)
            local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            timeText:SetPoint("RIGHT", -6, 0);
            timeText:SetJustifyH("RIGHT");
            timeText:SetTextColor(1, 1, 1);
            row.timeText = timeText;

            -- unwatch button (shown on hover)
            local unwatchButton = CreateFrame("Button", nil, row);
            unwatchButton:SetSize(12, 12);
            unwatchButton:SetPoint("RIGHT", timeText, "LEFT", -4, 0);
            local unwatchIcon = unwatchButton:CreateTexture(nil, "ARTWORK");
            unwatchIcon:SetAllPoints();
            unwatchIcon:SetTexture([[Interface\Buttons\UI-StopButton]]);
            unwatchButton:Hide();
            row.unwatchButton = unwatchButton;

            unwatchButton:SetScript("OnEnter", function()
                row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
                GameTooltip:SetOwner(unwatchButton, "ANCHOR_RIGHT");
                GameTooltip:SetText(localeService:Get("UnwatchCooldown"));
                GameTooltip:Show();
            end);
            unwatchButton:SetScript("OnLeave", function()
                GameTooltip:Hide();
                C_Timer.After(0.05, function()
                    if (not row:IsVisible()) then return; end
                    if (not row:IsMouseOver() and not unwatchButton:IsMouseOver()) then
                        row:SetBackdropColor(0, 0, 0, 0);
                        unwatchButton:Hide();
                    end
                end);
            end);
            unwatchButton:SetScript("OnClick", function()
                cooldownService:UnwatchCooldown(row.entryPlayerName, row.entrySpellId);

                -- refresh guild cooldowns panel if visible
                local professionsView = self.addon.professionsView;
                if (professionsView and professionsView.guildCooldownsPanel) then
                    professionsView.guildCooldownsPanel:RefreshRows();
                end

                self:Refresh();
            end);

            -- row hover
            row:SetScript("OnEnter", function()
                row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
                unwatchButton:Show();
            end);
            row:SetScript("OnLeave", function()
                C_Timer.After(0.05, function()
                    if (not row:IsVisible()) then return; end
                    if (not row:IsMouseOver() and not unwatchButton:IsMouseOver()) then
                        row:SetBackdropColor(0, 0, 0, 0);
                        unwatchButton:Hide();
                    end
                end);
            end);

            -- purple hover glow (border + purple backdrop), kept alive by the unwatch button
            self:GetService("ui"):AttachHoverGlow(row, { unwatchButton });

            table.insert(self.rows, row);
        end

        -- update row content
        local row = self.rows[rowCount];
        row.entryPlayerName = entry.playerName;
        row.entrySpellId = entry.spellId;
        row.expires = entry.expires;

        -- position row
        local top = 33 + ((rowCount - 1) * 16);
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.view, "TOPLEFT", 10, -top);
        row:SetPoint("BOTTOMRIGHT", self.view, "TOPRIGHT", -10, -(top + 18));

        -- set text: "ItemName - PlayerName"
        local coloredItemName;
        if (entry.itemColor) then
            coloredItemName = entry.itemColor .. entry.itemName .. "|r";
        else
            coloredItemName = entry.itemName;
        end
        row.itemText:SetText(coloredItemName .. " - " .. entry.displayName);
        row.itemText:SetPoint("RIGHT", row.timeText, "LEFT", -20, 0);

        -- set time
        local remaining = entry.expires - currentTime;
        if (entry.expires == 0) then remaining = 0; end
        row.timeText:SetText(self:GetService("timer"):FormatTime(remaining));

        row.unwatchButton:Hide();
        row:SetBackdropColor(0, 0, 0, 0);
        row:Show();
    end

    -- nothing watched: explain how to watch a cooldown (tab name and the watch
    -- icon of the cooldowns tab inline) instead of showing an empty window
    local contentHeight = rowCount * 16;
    if (rowCount == 0) then
        if (not self.emptyText) then
            local emptyText = self.view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
            emptyText:SetPoint("TOPLEFT", self.view, "TOPLEFT", 12, -33);
            emptyText:SetJustifyH("LEFT");
            emptyText:SetWordWrap(true);
            self.emptyText = emptyText;
        end
        self.emptyText:SetWidth(self.view:GetWidth() - 24);
        self.emptyText:SetText(localeService:Get("CooldownViewEmpty", localeService:Get("TabCooldowns"), "|TInterface\\Minimap\\Tracking\\FlightMaster:14:14|t"));
        self.emptyText:Show();
        contentHeight = math.ceil(self.emptyText:GetStringHeight());
    elseif (self.emptyText) then
        self.emptyText:Hide();
    end

    -- update view height; the classic style keeps a little more room below
    -- the content
    local viewHeight = 33 + contentHeight + (self:GetService("ui"):IsForever() and 14 or 12);
    self.view.minHeight = viewHeight;
    self.view:SetHeight(math.max(viewHeight, 60));
end
