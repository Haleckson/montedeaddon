--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel
local GuildCooldownsPanel = _G.professionMaster:CreateView("guild-cooldowns-panel");

--- Create guild cooldowns panel.
-- @param parentFrame The parent content frame.
-- @param professionsView Reference to the parent professions view.
function GuildCooldownsPanel:Create(parentFrame, professionsView)
    self.professionsView = professionsView;
    self.rowPool = {};
    self.groupHeaderPool = {};
    self.entries = {};
    self.scrollTop = 0;
    self.searchText = "";
    self.professionId = 0;

    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- create container frame
    local frame = CreateFrame("Frame", nil, parentFrame);
    frame:SetPoint("TOPLEFT", 5, -2);
    frame:SetPoint("BOTTOMRIGHT", -5, 2);
    frame:Hide();
    self.frame = frame;

    -- close open context menu on tab switch or window close (fires also when hidden via parent)
    frame:SetScript("OnHide", function()
        self:CloseRowContextMenu();
    end);

    -- add search label
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    searchLabel:SetPoint("TOPLEFT", 12, -12);
    searchLabel:SetText(localeService:Get("ProfessionsViewSearch"));
    self.searchLabel = searchLabel;

    -- add search box
    local searchContainer = uiService:CreateEditBox(frame, 100);
    searchContainer:SetPoint("TOPLEFT", 12, -28);
    searchContainer:SetPoint("RIGHT", frame, "RIGHT", -180, 0);
    searchContainer:SetHeight(22);
    self.searchContainer = searchContainer;
    local searchBox = searchContainer.editBox;
    self.searchBox = searchBox;

    searchBox:SetScript("OnTextChanged", function()
        if (self.searchPending) then
            self.searchPending:Cancel();
        end
        self.searchPending = C_Timer.NewTimer(0.2, function()
            self.searchPending = nil;
            self.searchText = string.lower(self:GetService("message"):TrimString(searchBox:GetText()));
            self:RefreshList();
        end);
    end);
    searchBox:SetScript("OnKeyDown", function(_, key)
        if (key == "ESCAPE") then
            professionsView:Hide();
        end
    end);

    -- add profession dropdown
    local professionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    professionLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -170, -12);
    professionLabel:SetText(localeService:Get("ProfessionsViewProfession"));
    self.professionLabel = professionLabel;

    local professionItems = {{ value = 0, text = self:GetProfessionText(0) }};
    local cooldownProfessionIds = self:GetService("cooldown"):GetCooldownProfessionIds();
    local professionIds = self:GetService("profession-names"):GetProfessionIdsToShow();
    for _, professionId in ipairs(professionIds) do
        if (cooldownProfessionIds[professionId]) then
            table.insert(professionItems, { value = professionId, text = self:GetProfessionText(professionId) });
        end
    end

    local professionSelection = uiService:CreateDropdown(frame, 160, professionItems, function(value)
        self.professionId = value;
        self.searchBox:SetFocus();
        self:RefreshList();
    end);
    professionSelection:SetPoint("TOPLEFT", frame, "TOPRIGHT", -172, -28);
    self.professionSelection = professionSelection;

    -- create scroll frame
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(frame);
    scrollParent:SetPoint("TOPLEFT", 4, -56);
    scrollParent:SetPoint("BOTTOMRIGHT", -8, 8);
    scrollChild:SetWidth(scrollParent:GetWidth());
    self.scrollFrame = scrollParent;
    self.scrollChild = scrollChild;
    self.scrollElement = scrollElement;

    scrollElement:SetScript("OnVerticalScroll", function(_, offset)
        self.scrollTop = offset;
        self:CloseRowContextMenu();
        self:RefreshRows();
    end);

    scrollParent:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);

    -- create empty message
    local emptyContainer = CreateFrame("Frame", nil, frame);
    emptyContainer:SetPoint("CENTER", frame, "CENTER", 0, 0);
    emptyContainer:SetSize(400, 30);
    emptyContainer:Hide();
    self.emptyMessage = emptyContainer;

    local emptyTitle = emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    emptyTitle:SetPoint("TOP", emptyContainer, "TOP", 0, 0);
    emptyTitle:SetJustifyH("CENTER");
    emptyTitle:SetTextColor(0.7, 0.7, 0.7, 1);
    emptyTitle:SetText(localeService:Get("NoCooldownsFound"));

    -- create ticker to update remaining times
    self.ticker = nil;
end

--- Get formatted profession text for dropdown.
-- @param professionId Profession ID (0 = all).
-- @return Formatted text with icon.
function GuildCooldownsPanel:GetProfessionText(professionId)
    if (professionId == 0) then
        return "|T133745:16|t " .. self:GetService("locale"):Get("ProfessionsViewAllProfessions");
    end
    local service = self:GetService("profession-names");
    return "|T" .. service:GetProfessionIcon(professionId) .. ":16|t  " .. service:GetProfessionName(professionId);
end

--- Show the panel.
function GuildCooldownsPanel:Show()
    if (self.frame) then
        self.frame:Show();
        self:RefreshList();
        self:StartTicker();
    end
end

--- Hide the panel.
function GuildCooldownsPanel:Hide()
    if (self.frame) then
        self.frame:Hide();
        self:StopTicker();
    end
end

--- Refresh data.
function GuildCooldownsPanel:Refresh()
    self:RefreshList();
end

--- Start the periodic timer to update remaining times.
function GuildCooldownsPanel:StartTicker()
    self:StopTicker();
    self:ScheduleNextTick();
end

--- Schedule the next tick based on the shortest remaining cooldown.
function GuildCooldownsPanel:ScheduleNextTick()
    if (not self.frame or not self.frame:IsShown()) then
        return;
    end

    -- determine minimum remaining time
    local currentTime = time();
    local minRemaining = math.huge;
    if (self.entries) then
        for _, entry in ipairs(self.entries) do
            if (not entry.isGroupHeader and entry.expires and entry.expires > 0) then
                local remaining = entry.expires - currentTime;
                if (remaining > 0 and remaining < minRemaining) then
                    minRemaining = remaining;
                end
            end
        end
    end

    -- choose interval based on shortest cooldown
    local interval;
    if (minRemaining < 120) then
        interval = 1;
    elseif (minRemaining < 180) then
        interval = 30;
    else
        interval = 60;
    end

    self.ticker = C_Timer.NewTimer(interval, function()
        self.ticker = nil;
        if (self.frame and self.frame:IsShown()) then
            self:RefreshRows();
            self:ScheduleNextTick();
        end
    end);
end

--- Stop the periodic timer.
function GuildCooldownsPanel:StopTicker()
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
end

--- Find specialization spell IDs that match a cooldown's item class/subclass.
-- @param skill The skill entry from the skills database.
-- @param professionId The profession ID for this cooldown.
-- @param specializationSpells The specialization spells model.
-- @return Array of matching spec spell IDs, or nil if none match.
function GuildCooldownsPanel:FindMatchingSpecSpellIds(skill, professionId, specializationSpells)
    if (not professionId or not specializationSpells) then
        return nil;
    end

    local specs = specializationSpells[professionId];
    if (not specs or not skill) then
        return nil;
    end

    local itemClassId = skill.classId;
    local itemSubclassId = skill.subclassId;
    local matchingSpecSpellIds = {};

    for _, spec in ipairs(specs) do
        if (spec.matchClassId and itemClassId == spec.matchClassId) then
            if (spec.matchSubclassIds) then
                -- match against specific subclass IDs
                for _, subId in ipairs(spec.matchSubclassIds) do
                    if (itemSubclassId == subId) then
                        table.insert(matchingSpecSpellIds, spec.spellId);
                        break;
                    end
                end
            else
                -- no subclass restriction, class match is sufficient
                table.insert(matchingSpecSpellIds, spec.spellId);
            end
        end
    end

    if (#matchingSpecSpellIds == 0) then
        return nil;
    end

    return matchingSpecSpellIds;
end

--- Resolve online status, alt associations, and specialist flag for a player.
-- @param player The player entry to resolve (modified in-place).
-- @param matchingSpecSpellIds Array of spec spell IDs to check against, or nil.
-- @param professionId The profession ID for specialization lookup.
function GuildCooldownsPanel:ResolvePlayerForCooldown(player, matchingSpecSpellIds, professionId)
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(player.playerName);
    local guildPlayer = playerService:GetRosterEntry(fullName);

    -- determine online and ownership status
    player.isOnline = (guildPlayer and guildPlayer.online) or false;
    player.isCurrentPlayer = playerService:IsCurrentPlayer(player.playerName);
    player.isOwnPlayer = (not player.isCurrentPlayer and playerService:IsOwnPlayer(player.playerName)) or false;

    -- check if player has a matching specialization
    player.isSpecialist = false;
    if (matchingSpecSpellIds and PM_Specializations and PM_Specializations[fullName]) then
        local playerSpecSpellId = PM_Specializations[fullName][professionId];
        if (playerSpecSpellId) then
            for _, matchSpellId in ipairs(matchingSpecSpellIds) do
                if (playerSpecSpellId == matchSpellId) then
                    player.isSpecialist = true;
                    break;
                end
            end
        end
    end

    -- resolve offline non-own players via character set
    player.displaySuffix = nil;
    if (not player.isOnline and not player.isCurrentPlayer and not player.isOwnPlayer) then
        local characterSet = playerService:FindCharacterSet(player.playerName);

        if (characterSet) then
            -- find an online alt in the character set
            local onlineAltName = nil;
            for _, altName in ipairs(characterSet) do
                local altFullName = playerService:GetLongName(altName);
                local altGuildPlayer = playerService:GetRosterEntry(altFullName);
                if (altGuildPlayer and altGuildPlayer.online) then
                    onlineAltName = altName;
                    break;
                end
            end

            if (onlineAltName) then
                -- show online alt name with original player in parentheses
                local isInGuild = (guildPlayer ~= nil);
                player.displaySuffix = isInGuild and playerService:GetShortName(fullName) or "alt";
                player.displayName = playerService:GetShortName(playerService:GetLongName(onlineAltName));
                player.isOnline = true;
            elseif (not guildPlayer) then
                -- player not in guild, find first guild alt from character set
                local guildAltName = nil;
                for _, altName in ipairs(characterSet) do
                    local altFullName = playerService:GetLongName(altName);
                    if (playerService:GetRosterEntry(altFullName)) then
                        guildAltName = altName;
                        break;
                    end
                end

                if (guildAltName) then
                    -- show guild alt name with (alt) suffix
                    player.displaySuffix = "alt";
                    player.displayName = playerService:GetShortName(playerService:GetLongName(guildAltName));
                else
                    -- no guild member in character set: skip
                    player.skipPlayer = true;
                end
            end
        elseif (not guildPlayer) then
            -- no character set and not in guild: skip this player
            player.skipPlayer = true;
        end
    end
end

--- Update visibility of controls based on data state.
-- @param hasAnyCooldowns Whether any cooldown data exists at all.
function GuildCooldownsPanel:UpdateControlVisibility(hasAnyCooldowns)
    if (not hasAnyCooldowns) then
        -- no cooldowns known at all: hide everything except empty message
        self.emptyMessage:Show();
        self.scrollFrame:Hide();
        self.searchLabel:Hide();
        self.searchContainer:Hide();
        self.professionLabel:Hide();
        self.professionSelection:Hide();
    elseif (#self.entries == 0) then
        -- cooldowns exist but search/filter returned no results: keep controls visible
        self.emptyMessage:Show();
        self.scrollFrame:Hide();
        self.searchLabel:Show();
        self.searchContainer:Show();
        self.professionLabel:Show();
        self.professionSelection:Show();
    else
        -- show list and controls
        self.emptyMessage:Hide();
        self.scrollFrame:Show();
        self.searchLabel:Show();
        self.searchContainer:Show();
        self.professionLabel:Show();
        self.professionSelection:Show();
    end
end

--- Build and display the cooldowns list.
-- Groups by item (crafted result), rows are players with their remaining time.
function GuildCooldownsPanel:RefreshList()
    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local cooldownService = self:GetService("cooldown");
    local knownCooldowns = cooldownService:GetKnownCooldowns();
    local specializationSpells = self:GetModel("specialization-spells");

    local cooldownsData = playerService.node.cooldowns or {};
    self.entries = {};

    -- get cooldowns grouped by spellId from service
    local spellGroups = cooldownService:GetCooldownGroups(self.professionId);

    -- build item groups from spell groups
    local itemGroups = {};
    local hasMissingItems = false;

    for spellId, players in pairs(spellGroups) do
        -- get item ID from skills database
        local skill = skillsService:GetSkillById(spellId);
        local itemId = skill and skill.itemId or 0;
        local itemName, itemLink, itemIcon, itemColor;

        -- try to load item info from cache
        if (itemId and itemId > 0) then
            local itemQuality, _;
            itemName, itemLink, itemQuality, _, _, _, _, _, _, itemIcon = self.addon.compat.GetItemInfo(itemId);
            if (itemQuality and ITEM_QUALITY_COLORS[itemQuality]) then
                itemColor = ITEM_QUALITY_COLORS[itemQuality].hex;
            end
            if (not itemName) then
                hasMissingItems = true;
            end
        end

        -- fallback to spell info if item not available yet
        if (not itemName) then
            local spellName, _, spellIcon = self.addon.compat.GetSpellInfo(spellId);
            itemName = spellName or ("Spell " .. spellId);
            itemIcon = spellIcon or 136240;
            itemColor = nil;
        end

        -- find matching specialization spell IDs for this cooldown
        local professionId = knownCooldowns[spellId];
        local matchingSpecSpellIds = self:FindMatchingSpecSpellIds(skill, professionId, specializationSpells);

        -- resolve player status and filter out skipped players
        local resolvedPlayers = {};
        for _, player in ipairs(players) do
            self:ResolvePlayerForCooldown(player, matchingSpecSpellIds, professionId);
            if (not player.skipPlayer) then
                table.insert(resolvedPlayers, player);
            end
        end

        table.insert(itemGroups, {
            spellId = spellId,
            itemName = itemName,
            itemLink = itemLink,
            itemIcon = itemIcon or 136240,
            itemColor = itemColor,
            players = resolvedPlayers,
        });
    end

    -- if items were not cached yet, schedule a delayed refresh
    if (hasMissingItems) then
        C_Timer.After(1, function()
            if (self.frame and self.frame:IsShown()) then
                self:RefreshList();
            end
        end);
    end

    -- sort groups alphabetically by item name
    table.sort(itemGroups, function(a, b)
        return (a.itemName or "") < (b.itemName or "");
    end);

    -- filter by search text and build flat entry list
    local searchText = self.searchText;
    for _, group in ipairs(itemGroups) do
        if (searchText == "" or string.find(string.lower(group.itemName or ""), searchText, 1, true)) then
            -- sort players: you first, then alts, then online, then specialists, then by expires
            table.sort(group.players, function(a, b)
                if (a.isCurrentPlayer ~= b.isCurrentPlayer) then return a.isCurrentPlayer; end
                if (a.isOwnPlayer ~= b.isOwnPlayer) then return a.isOwnPlayer; end
                if (a.isOnline ~= b.isOnline) then return a.isOnline; end
                if (a.isSpecialist ~= b.isSpecialist) then return a.isSpecialist; end
                if (a.expires == 0 and b.expires ~= 0) then return true; end
                if (b.expires == 0 and a.expires ~= 0) then return false; end
                return a.expires < b.expires;
            end);

            -- add group header entry
            table.insert(self.entries, {
                isGroupHeader = true,
                groupName = group.itemName,
                itemIcon = group.itemIcon,
                itemColor = group.itemColor,
                itemLink = group.itemLink,
            });

            -- add player entries
            for _, player in ipairs(group.players) do
                table.insert(self.entries, {
                    playerName = player.playerName,
                    displayName = player.displayName,
                    displaySuffix = player.displaySuffix,
                    expires = player.expires,
                    isOnline = player.isOnline,
                    isSpecialist = player.isSpecialist,
                    isCurrentPlayer = player.isCurrentPlayer,
                    isOwnPlayer = player.isOwnPlayer,
                    itemLink = group.itemLink,
                    spellId = group.spellId,
                });
            end
        end
    end

    -- update scroll child height
    local rowHeight = 20;
    local totalHeight = #self.entries * rowHeight;
    self.scrollChild:SetHeight(totalHeight);

    -- update visibility of controls and empty message
    local hasAnyCooldowns = (next(cooldownsData) ~= nil);
    self:UpdateControlVisibility(hasAnyCooldowns);

    self:RefreshRows();
end

--- Show context menu to watch or unwatch the clicked row's cooldown.
-- @param row The clicked player row.
function GuildCooldownsPanel:ShowRowContextMenu(row)
    local localeService = self:GetService("locale");

    -- create shared menu frame once
    if (not self.contextMenu) then
        self.contextMenu = CreateFrame("Frame", "PmGuildCooldownsContextMenu", UIParent, "UIDropDownMenuTemplate");
    end

    -- snapshot row data, rows are pooled and may be reused while the menu is open
    local playerName = row.entryPlayerName;
    local spellId = row.entrySpellId;
    local isWatched = row.isWatched;

    UIDropDownMenu_Initialize(self.contextMenu, function(_, level)
        -- watch or unwatch entry depending on current state
        local info = UIDropDownMenu_CreateInfo();
        info.notCheckable = true;
        info.text = localeService:Get(isWatched and "UnwatchCooldown" or "WatchCooldown");
        info.func = function()
            local cooldownService = self:GetService("cooldown");
            if (isWatched) then
                cooldownService:UnwatchCooldown(playerName, spellId);
            else
                cooldownService:WatchCooldown(playerName, spellId);
            end
            self:RefreshRows();
        end;
        UIDropDownMenu_AddButton(info, level);

        -- close entry to dismiss the menu
        local closeInfo = UIDropDownMenu_CreateInfo();
        closeInfo.notCheckable = true;
        closeInfo.text = localeService:Get("CloseTooltip");
        closeInfo.func = function()
            CloseDropDownMenus();
        end;
        UIDropDownMenu_AddButton(closeInfo, level);
    end, "MENU");

    ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 0, 0);
end

--- Close the row context menu if it is currently open.
function GuildCooldownsPanel:CloseRowContextMenu()
    if (self.contextMenu and UIDROPDOWNMENU_OPEN_MENU == self.contextMenu) then
        CloseDropDownMenus();
    end
end

--- Refresh visible rows based on scroll position (virtual scrolling).
function GuildCooldownsPanel:RefreshRows()
    if (not self.entries or #self.entries == 0) then
        for _, row in ipairs(self.rowPool) do
            row:Hide();
        end
        for _, row in ipairs(self.groupHeaderPool) do
            row:Hide();
        end
        return;
    end

    -- calculate visible range with buffer rows above and below
    local currentTime = time();
    local playerService = self:GetService("player");
    local rowHeight = 20;
    local visibleRowCount = math.ceil((self.scrollFrame:GetHeight() or 400) / rowHeight) + 4;
    local startIndex = math.max(math.floor(self.scrollTop / rowHeight) - 2, 1);
    local endIndex = math.min(startIndex + visibleRowCount, #self.entries);

    -- hide all rows first
    for _, row in ipairs(self.rowPool) do
        row:Hide();
    end
    for _, row in ipairs(self.groupHeaderPool) do
        row:Hide();
    end

    local rowPoolIndex = 0;
    local headerPoolIndex = 0;

    for i = startIndex, endIndex do
        local entry = self.entries[i];
        local yOffset = -(i - 1) * rowHeight;

        if (entry.isGroupHeader) then
            -- render group header row (item name with icon)
            headerPoolIndex = headerPoolIndex + 1;
            local header = self.groupHeaderPool[headerPoolIndex];
            if (not header) then
                header = CreateFrame("Button", nil, self.scrollChild);
                header:SetHeight(rowHeight);
                local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                headerText:SetPoint("LEFT", 6, 0);
                header.text = headerText;
                header:SetScript("OnEnter", function()
                    if (header.itemLink) then
                        -- tooltip hangs with its top-right corner at the item's top-left
                        GameTooltip:SetOwner(header, "ANCHOR_NONE");
                        GameTooltip:ClearAllPoints();
                        GameTooltip:SetPoint("TOPRIGHT", header, "TOPLEFT", -2, 0);
                        GameTooltip:SetHyperlink(header.itemLink);
                        GameTooltip:Show();
                    end
                end);
                header:SetScript("OnLeave", function()
                    GameTooltip:Hide();
                end);
                self.groupHeaderPool[headerPoolIndex] = header;
            end
            header:ClearAllPoints();
            header:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", -2, yOffset);
            header:SetPoint("RIGHT", self.scrollChild, "RIGHT", 0, 0);
            header.itemLink = entry.itemLink;

            -- display with icon and item quality color
            local displayText;
            if (entry.itemColor) then
                displayText = "|T" .. entry.itemIcon .. ":16|t " .. entry.itemColor .. entry.groupName .. "|r";
            else
                displayText = "|T" .. entry.itemIcon .. ":16|t " .. entry.groupName;
            end
            header.text:SetText(displayText);
            header:Show();
        else
            -- render player row with name and remaining time
            rowPoolIndex = rowPoolIndex + 1;
            local row = self.rowPool[rowPoolIndex];
            if (not row) then
                row = CreateFrame("Button", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
                row:SetBackdrop({
                    bgFile = [[Interface\Buttons\WHITE8x8]]
                });
                row:SetHeight(rowHeight);

                local playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                playerText:SetPoint("TOPLEFT", 22, -3);
                playerText:SetTextColor(1, 1, 1);
                row.playerText = playerText;

                -- watched label (shown for watched cooldowns)
                local watchedLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
                watchedLabel:SetTextColor(0.4, 0.8, 1);
                watchedLabel:SetText("(" .. self:GetService("locale"):Get("Watched") .. ")");
                watchedLabel:SetPoint("LEFT", playerText, "RIGHT", 4, 0);
                watchedLabel:Hide();
                row.watchedLabel = watchedLabel;

                local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                timeText:SetPoint("RIGHT", row, "RIGHT", -6, 0);
                timeText:SetJustifyH("RIGHT");
                row.timeText = timeText;

                -- watch/unwatch button (shown on hover, left of player name)
                local watchButton = CreateFrame("Button", nil, row);
                watchButton:SetSize(14, 14);
                watchButton:SetPoint("LEFT", row, "LEFT", 4, 0);
                local watchIcon = watchButton:CreateTexture(nil, "ARTWORK");
                watchIcon:SetAllPoints();
                watchButton.icon = watchIcon;
                watchButton:Hide();
                row.watchButton = watchButton;

                watchButton:SetScript("OnEnter", function()
                    row:SetBackdropColor(0.2, 0.2, 0.2);
                    GameTooltip:SetOwner(watchButton, "ANCHOR_RIGHT");
                    if (row.isWatched) then
                        GameTooltip:SetText(self:GetService("locale"):Get("UnwatchCooldown"));
                    else
                        GameTooltip:SetText(self:GetService("locale"):Get("WatchCooldown"));
                    end
                    GameTooltip:Show();
                end);
                watchButton:SetScript("OnLeave", function()
                    GameTooltip:Hide();
                    C_Timer.After(0.05, function()
                        if (not row:IsVisible()) then return; end
                        if (not row:IsMouseOver() and not watchButton:IsMouseOver()) then
                            if (row.bgColor) then
                                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
                            end
                            watchButton:Hide();
                        end
                    end);
                end);
                watchButton:SetScript("OnClick", function()
                    local cooldownService = self:GetService("cooldown");
                    if (row.isWatched) then
                        cooldownService:UnwatchCooldown(row.entryPlayerName, row.entrySpellId);
                    else
                        cooldownService:WatchCooldown(row.entryPlayerName, row.entrySpellId);
                    end
                    self:RefreshRows();
                end);

                -- clicking the row opens the watch/unwatch context menu
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp");
                row:SetScript("OnClick", function()
                    self:ShowRowContextMenu(row);
                end);

                row:SetScript("OnEnter", function()
                    row:SetBackdropColor(0.2, 0.2, 0.2);
                    row.watchButton:Show();
                end);
                row:SetScript("OnLeave", function()
                    C_Timer.After(0.05, function()
                        if (not row:IsVisible()) then return; end
                        if (not row:IsMouseOver() and not row.watchButton:IsMouseOver()) then
                            if (row.bgColor) then
                                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
                            end
                            row.watchButton:Hide();
                        end
                    end);
                end);

                -- purple hover glow (border + purple backdrop), kept alive by the watch button
                self:GetService("ui"):AttachHoverGlow(row, { watchButton });

                self.rowPool[rowPoolIndex] = row;
            end

            row:ClearAllPoints();
            row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 3, yOffset);
            row:SetPoint("BOTTOMRIGHT", self.scrollChild, "TOPRIGHT", -28, yOffset - 20);

            -- alternate row background for readability
            local backgroundColor = (i % 2 == 0) and 0.12 or 0.06;
            row.bgColor = backgroundColor;
            row:SetBackdropColor(backgroundColor, backgroundColor, backgroundColor, 0.5);

            row.itemLink = entry.itemLink;
            row.entryPlayerName = entry.playerName;
            row.entrySpellId = entry.spellId;

            -- check watched state
            local cooldownService = self:GetService("cooldown");
            row.isWatched = cooldownService:IsWatched(entry.playerName, entry.spellId);
            if (row.isWatched) then
                row.watchedLabel:Show();
                row.watchButton.icon:SetTexture([[Interface\Buttons\UI-StopButton]]);
            else
                row.watchedLabel:Hide();
                row.watchButton.icon:SetTexture([[Interface\Minimap\Tracking\FlightMaster]]);
            end
            row.watchButton:Hide();

            -- determine display name and color
            local displayName;
            if (entry.isCurrentPlayer) then
                displayName = self:GetService("locale"):Get("You");
                row.playerText:SetTextColor(0, 0.93, 0);          -- green (you)
            elseif (entry.isOwnPlayer) then
                local shortName = playerService:GetShortName(playerService:GetLongName(entry.playerName));
                displayName = self:GetService("locale"):Get("You") .. " (" .. shortName .. ")";
                row.playerText:SetTextColor(0, 0.93, 0);          -- green (your alt)
            elseif (entry.displaySuffix) then
                -- resolved via character set (online alt with original in parentheses)
                displayName = entry.displayName .. " (" .. entry.displaySuffix .. ")";
                if (entry.isSpecialist) then
                    row.playerText:SetTextColor(0.44, 0.84, 1);  -- online specialist (light blue)
                else
                    row.playerText:SetTextColor(1, 1, 1);         -- online player (white)
                end
            elseif (entry.isSpecialist and entry.isOnline) then
                displayName = entry.playerName;
                row.playerText:SetTextColor(0.44, 0.84, 1);      -- online specialist (light blue)
            elseif (entry.isSpecialist) then
                displayName = entry.playerName;
                row.playerText:SetTextColor(0.27, 0.50, 0.60);   -- offline specialist (faded blue)
            elseif (entry.isOnline) then
                displayName = entry.playerName;
                row.playerText:SetTextColor(1, 1, 1);             -- online player (white)
            else
                displayName = entry.playerName;
                row.playerText:SetTextColor(0.6, 0.6, 0.6);      -- offline player (gray)
            end
            row.playerText:SetText(displayName);

            -- calculate remaining time
            local remaining = entry.expires - currentTime;
            if (entry.expires == 0) then
                remaining = 0;
            end
            local timeString = self:GetService("timer"):FormatTime(remaining, true);

            -- color based on state
            if (entry.expires == 0 or remaining <= 0) then
                row.timeText:SetTextColor(0, 1, 0);
            elseif (remaining < 300) then
                row.timeText:SetTextColor(1, 1, 0);
            else
                row.timeText:SetTextColor(1, 1, 1);
            end
            row.timeText:SetText(timeString);
            row:Show();
        end
    end
end

--- Set right margin.
function GuildCooldownsPanel:SetRightMargin(margin)
    if (self.frame) then
        self.frame:SetPoint("BOTTOMRIGHT", -margin, 0);
        self:UpdateResponsiveLayout();
    end
end

--- Handle resize.
function GuildCooldownsPanel:OnSizeChanged()
    self:UpdateResponsiveLayout();
end

--- Update responsive layout based on frame width.
function GuildCooldownsPanel:UpdateResponsiveLayout()
    if (not self.frame) then return; end
    if (self.scrollChild and self.scrollFrame) then
        self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
    end
    self:RefreshRows();
end
