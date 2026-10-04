--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local DatabaseView = _G.professionMaster:CreateView("database");

-- widths of the profession column and the item column, the detail panel takes the rest
local LeftColumnWidth = 230;
local ItemColumnWidth = 420;

-- default and minimum window width; the minimum also widens sizes saved
-- before the item column grew, so the detail panel keeps about 300px
local ViewWidth = 1180;
local ViewMinWidth = 1000;
local RowHeight = 20;

-- selection key of the favorites entry above the professions
local FavoritesKey = "favorites";

-- talisman icon shared by all favorite toggles of the addon
local FavoriteIcon = "Interface\\Icons\\INV_Jewelry_Talisman_08";

-- max skill level per game client (vanilla, tbc, wrath, cata, mop)
local MaxSkillLevels = { 300, 375, 450, 525, 600 };

-- round dot next to a profession the own characters know (colored per ownership kind)
local DotTexture = "Interface\\CharacterFrame\\TempPortraitAlphaMask";

--- Show the database view; the classic overview closes so only one main
--- window is open and the database is reopened next time.
function DatabaseView:Show()
    if (self.view == nil) then
        self:Create();
    end

    PM_CharacterSettings.lastMainView = "database";
    local professionsView = self.addon.professionsView;
    if (professionsView and professionsView.visible) then
        professionsView:Hide();
    end

    self:UpdateLayout();
    self:RefreshLists();
    self.view:Show();
    self.visible = true;
end

--- Hide the database view.
function DatabaseView:Hide()
    if (self.view) then
        self.view:Hide();
    end
    self.visible = false;
end

--- Toggle visibility.
function DatabaseView:ToggleVisibility()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end

--- Refresh the lists and the detail while the view is open (sync data, skill
--- names and prices arrive while the window is shown); the scroll positions stay.
function DatabaseView:Refresh()
    if (not self.visible) then
        return;
    end
    self:RefreshLists(true);
end

--- Create the window: search and profession column on the left, item column
--- in the middle, item detail on the right.
function DatabaseView:Create()
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");
    local addon = self.addon;

    -- restore the last state
    self.selectionKey = PM_CharacterSettings.lastDatabaseSelection;
    self.selectedSkillId = PM_CharacterSettings.lastDatabaseSkillId;
    self.history = {};
    self.addonId = PM_CharacterSettings.lastDatabaseAddon;

    -- create view
    local view = uiService:CreateView("PmDatabase", ViewWidth, 540, localeService:Get("DatabaseViewTitle"), false, true, ViewMinWidth, 400);
    uiService:SetViewPortrait(view, [[Interface\Icons\INV_Misc_Book_09]]);
    view:EnableKeyboard();
    view:SetScript("OnKeyDown", function(_, key)
        if (key == "ESCAPE") then
            view:SetPropagateKeyboardInput(false);
            self:Hide();
        else
            view:SetPropagateKeyboardInput(true);
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
    uiService:BindTooltip(closeButton, localeService:Get("CloseTooltip"));

    -- add overview button (left of close button): back to the classic window
    local overviewButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\Inv_misc_book_05]], localeService:Get("DatabaseOverviewTooltip"), function()
        addon:SwitchMainView("professions");
    end);
    overviewButton:SetPoint("RIGHT", closeButton, "LEFT", -18, 0);

    -- add settings button (left of overview button)
    local settingsButton = uiService:CreateHeaderIconButton(view, [[Interface\Icons\Trade_engineering]], localeService:Get("SettingsTooltip"), function()
        addon.settingsView:Open();
    end);
    settingsButton:SetPoint("RIGHT", overviewButton, "LEFT", -8, 0);

    -- forever style: the icon buttons sit bottom right under the panels
    uiService:PlaceHeaderButtonsBottom(view, -2);

    -- classic style: the panels start right below the title and end above
    -- the icon buttons, the footer label sits on the button row like in the
    -- main window; the flat style keeps its distances
    local panelTop, panelBottom, footerBottom = 40, 30, 10;
    if (uiService:IsForever()) then
        local _, _, footerHeight = uiService:GetForeverInsets();
        panelTop = uiService:GetFrameMargin() * 3 + 28;
        panelBottom = footerHeight;
        footerBottom = footerHeight - 19;
    end
    self.panelBottom = panelBottom;

    -- add footer
    local footerLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft");
    footerLabel:SetPoint("BOTTOMLEFT", 16, footerBottom);
    footerLabel:SetText(localeService:Get("ProfessionsViewFooter"));

    -- left panel: search, addon filter and the professions (or the search
    -- results); no tab strip here, so the panels start right below the title
    local leftPanel = uiService:CreatePanel(view);
    leftPanel:SetPoint("TOPLEFT", 12, -panelTop);
    leftPanel:SetPoint("BOTTOMLEFT", 12, panelBottom);
    leftPanel:SetWidth(LeftColumnWidth);
    self.leftPanel = leftPanel;

    -- add search box
    local searchLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    searchLabel:SetPoint("TOPLEFT", 12, -12);
    searchLabel:SetText(localeService:Get("ProfessionsViewSearch"));
    local searchContainer = uiService:CreateEditBox(leftPanel, 100);
    searchContainer:SetPoint("TOPLEFT", 12, -28);
    searchContainer:SetPoint("RIGHT", leftPanel, "RIGHT", -12, 0);
    local searchBox = searchContainer.editBox;
    self.searchBox = searchBox;

    -- debounce: the search replaces the profession column by the found items
    searchBox:SetScript("OnTextChanged", function()
        if (self.searchPending) then
            self.searchPending:Cancel();
        end
        self.searchPending = C_Timer.NewTimer(0.2, function()
            self.searchPending = nil;
            PM_CharacterSettings.lastDatabaseSearchText = searchBox:GetText();
            self:UpdateLayout();
            self:RefreshLists();
        end);
    end);
    searchBox:SetScript("OnKeyDown", function(_, key)
        if (key == "ESCAPE") then
            self:Hide();
        elseif (key == "ENTER") then
            searchBox:ClearFocus();
        end
    end);

    -- add addon filter (only when the client has several expansions)
    local listTop = 58;
    if (addon.hasExpansion) then
        local addonLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        addonLabel:SetPoint("TOPLEFT", 12, -58);
        addonLabel:SetText(localeService:Get("ProfessionsViewAddon"));
        local addonSelection = uiService:CreateDropdown(leftPanel, LeftColumnWidth - 24, professionNamesService:BuildAddonItems(true), function(value)
            self.addonId = value;
            PM_CharacterSettings.lastDatabaseAddon = value;
            self:RefreshLists();
        end);
        addonSelection:SetPoint("TOPLEFT", 12, -74);
        addonSelection:SetValue(self.addonId);
        self.addonSelection = addonSelection;
        listTop = 104;
    else
        self.addonId = nil;
    end

    -- profession list, replaced by the search results while searching
    self.leftList = self:CreateList(leftPanel, listTop, function(entry)
        self:OnLeftEntryClick(entry);
    end);

    -- item panel: the items of the selected profession or the favorites
    local itemPanel = uiService:CreatePanel(view);
    itemPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 6, 0);
    itemPanel:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMRIGHT", 6, 0);
    itemPanel:SetWidth(ItemColumnWidth);
    self.itemPanel = itemPanel;
    self.itemList = self:CreateList(itemPanel, 12, function(entry)
        self:OnItemEntryClick(entry);
    end);

    -- detail panel: the selected item
    local detailPanel = uiService:CreatePanel(view);
    detailPanel:SetPoint("BOTTOMRIGHT", -12, panelBottom);
    self.detailPanel = detailPanel;
    self:CreateDetail(detailPanel);

    -- the detail text wraps by width, re-render it after a resize settled
    view:HookScript("OnSizeChanged", function()
        if (self.resizePending) then
            self.resizePending:Cancel();
        end
        self.resizePending = C_Timer.NewTimer(0.05, function()
            self.resizePending = nil;
            self:RenderDetail();
        end);
    end);

    -- restore search text
    if (PM_CharacterSettings.lastDatabaseSearchText and PM_CharacterSettings.lastDatabaseSearchText ~= "") then
        searchBox:SetText(PM_CharacterSettings.lastDatabaseSearchText);
    end

    self.addon:Log("DatabaseView", "Create", "Database view created");
end

--- Check whether the search replaces the profession column.
function DatabaseView:IsSearchMode()
    return self.searchBox ~= nil and self:GetSearchParts() ~= nil;
end

--- Get the lowercased search parts or nil while the search box is empty.
function DatabaseView:GetSearchParts()
    local messageService = self:GetService("message");
    local searchText = string.lower(messageService:TrimString(self.searchBox:GetText() or ""));
    if (searchText == "") then
        return nil;
    end
    local searchParts = messageService:SplitString(string.gsub(searchText, "%-", "%%-"), " ");
    local parts = {};
    for _, part in ipairs(searchParts) do
        part = messageService:TrimString(part);
        if (string.len(part) > 0) then
            parts[#parts + 1] = part;
        end
    end
    if (#parts == 0) then
        return nil;
    end
    return parts;
end

--- Arrange the columns: while searching the item column disappears and the
--- result list takes its width, the detail panel follows.
function DatabaseView:UpdateLayout()
    local anchor;
    if (self:IsSearchMode()) then
        self.itemPanel:Hide();
        self.leftPanel:SetWidth(LeftColumnWidth + 6 + ItemColumnWidth);
        anchor = self.leftPanel;
    else
        self.itemPanel:Show();
        self.leftPanel:SetWidth(LeftColumnWidth);
        anchor = self.itemPanel;
    end
    self.detailPanel:ClearAllPoints();
    self.detailPanel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0);
    self.detailPanel:SetPoint("BOTTOMRIGHT", self.view, "BOTTOMRIGHT", -12, self.panelBottom);
end

--- Create a pooled row list (column headers, scroll frame, empty message).
-- @param parent Panel the list lives in.
-- @param top Offset of the list from the panel top.
-- @param onClick Callback with the clicked entry.
function DatabaseView:CreateList(parent, top, onClick)
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local list = { rowPool = {}, entries = {}, scrollTop = 0, onClick = onClick, top = top, parent = parent };

    -- column headers above the scroll frame, shown for item lists only
    local itemHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemHeader:SetPoint("TOPLEFT", 12, -top);
    itemHeader:SetText(localeService:Get("ProfessionsViewItem"));
    itemHeader:Hide();
    list.itemHeader = itemHeader;
    local levelingHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    levelingHeader:SetPoint("TOPRIGHT", -36, -top);
    levelingHeader:SetJustifyH("RIGHT");
    levelingHeader:SetText(localeService:Get("ProfessionsViewLeveling"));
    levelingHeader:Hide();
    list.levelingHeader = levelingHeader;

    -- scroll frame
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(parent);
    scrollParent:SetPoint("TOPLEFT", 6, -top);
    scrollParent:SetPoint("BOTTOMRIGHT", -6, 6);
    scrollParent:SetBackdropColor(0, 0, 0, 0);
    scrollChild:SetWidth(scrollParent:GetWidth());
    scrollParent:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
        self:RefreshListRows(list);
    end);
    scrollElement:SetScript("OnVerticalScroll", function(_, offset)
        list.scrollTop = offset;
        self:RefreshListRows(list);
    end);
    list.scrollParent = scrollParent;
    list.scrollChild = scrollChild;
    list.scrollElement = scrollElement;

    -- empty message
    local emptyText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    emptyText:SetPoint("CENTER", scrollParent, "CENTER", 0, 0);
    emptyText:SetTextColor(0.6, 0.6, 0.6, 1);
    emptyText:Hide();
    list.emptyText = emptyText;
    return list;
end

--- Set the entries of a list and render the visible rows.
-- @param list List created by CreateList.
-- @param entries Array of { key, text, levelingText, skillId, professionId, skill }.
-- @param showHeaders True for item lists (item / leveling headers).
-- @param emptyMessage Text shown when there are no entries.
-- @param preserveScroll True to keep the scroll position (data refresh of the same list).
function DatabaseView:SetListEntries(list, entries, showHeaders, emptyMessage, preserveScroll)
    list.entries = entries;
    if (not preserveScroll) then
        list.scrollTop = 0;
        list.scrollElement:SetVerticalScroll(0);
    end

    -- the leveling column only exists when the player knows the profession of an entry
    list.hasLeveling = false;
    for _, entry in ipairs(entries) do
        if (entry.levelingText) then
            list.hasLeveling = true;
            break;
        end
    end

    -- headers take one line above the rows
    local top = list.top + (showHeaders and 18 or 0);
    list.scrollParent:SetPoint("TOPLEFT", 6, -top);
    list.itemHeader:SetShown(showHeaders);
    list.levelingHeader:SetShown(showHeaders and list.hasLeveling);

    list.scrollChild:SetHeight(math.max(#entries * RowHeight, 1));
    if (#entries == 0 and emptyMessage) then
        list.emptyText:SetText(emptyMessage);
        list.emptyText:Show();
    else
        list.emptyText:Hide();
    end
    self:RefreshListRows(list);
end

--- Create one pooled list row (icon and name left, leveling right).
function DatabaseView:CreateListRow(list)
    local uiService = self:GetService("ui");
    local row = CreateFrame("Button", nil, list.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(RowHeight);
    row:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]]
    });

    -- leveling text right aligned, name fills the rest
    local levelingText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    levelingText:SetPoint("RIGHT", -6, 0);
    levelingText:SetJustifyH("RIGHT");
    levelingText:SetWidth(90);
    row.levelingText = levelingText;

    -- availability icon between name and leveling (seasonal or unavailable
    -- recipes), 1px wide while the entry has none so the name keeps its width
    local flagButton = CreateFrame("Button", nil, row);
    flagButton:SetSize(1, 14);
    flagButton:SetPoint("RIGHT", levelingText, "LEFT", -4, 0);
    local flagIcon = flagButton:CreateTexture(nil, "OVERLAY");
    flagIcon:SetAllPoints();
    flagButton.icon = flagIcon;
    row.flagButton = flagButton;
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", 4, 0);
    nameText:SetPoint("RIGHT", flagButton, "LEFT", -4, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    row.nameText = nameText;

    -- ownership dot at the right end of a profession row
    local dot = row:CreateTexture(nil, "OVERLAY");
    dot:SetSize(6, 6);
    dot:SetPoint("RIGHT", -10, 0);
    dot:SetTexture(DotTexture);
    dot:Hide();
    row.dot = dot;

    -- hover: highlight and the skill tooltip left of the row, the own
    -- characters knowing a profession on a profession row
    row:SetScript("OnEnter", function()
        row:SetBackdropColor(0.2, 0.2, 0.2);
        local entry = row.entry;
        if (entry and entry.skill) then
            GameTooltip:SetOwner(row, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
            self:GetService("tooltip"):ShowTooltip(GameTooltip, entry.professionId, entry.skillId, entry.skill, nil);
        elseif (entry and entry.ownership) then
            GameTooltip:SetOwner(row, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
            self:GetService("own-professions"):AddOwnershipTooltipLines(GameTooltip, entry.ownership, entry.altNames);
            GameTooltip:Show();
        end
    end);
    row:SetScript("OnLeave", function()
        GameTooltip:Hide();
        self:SetRowBackground(row);
    end);

    -- click: shift links the item into the chat, otherwise the list callback runs
    local function OnRowMouseDown(_, button)
        local entry = row.entry;
        if (button ~= "LeftButton" or not entry) then
            return;
        end
        if (IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow() and entry.skill) then
            self:InsertSkillLink(entry.skill);
            return;
        end
        list.onClick(entry);
    end
    row:SetScript("OnMouseDown", OnRowMouseDown);

    -- the availability icon explains itself and forwards clicks to the row
    flagButton:SetScript("OnEnter", function()
        row:SetBackdropColor(0.2, 0.2, 0.2);
        local entry = row.entry;
        local text = entry and self:GetService("tooltip"):GetAvailabilityText(entry.availability);
        if (text) then
            GameTooltip:SetOwner(row, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
            GameTooltip:SetText(text, 1, 1, 1);
            GameTooltip:Show();
        end
    end);
    flagButton:SetScript("OnLeave", function()
        GameTooltip:Hide();
        self:SetRowBackground(row);
    end);
    flagButton:SetScript("OnMouseDown", OnRowMouseDown);

    -- purple hover glow
    uiService:AttachHoverGlow(row);
    return row;
end

--- Apply the row background: selected rows purple, the others striped.
function DatabaseView:SetRowBackground(row)
    if (row.selected) then
        row:SetBackdropColor(0.45, 0.25, 0.65, 0.5);
    else
        local shade = ((row.rowIndex or 1) % 2 == 0) and 0.12 or 0.06;
        row:SetBackdropColor(shade, shade, shade, 0.5);
    end
end

--- Render the visible rows of a list from the pool.
function DatabaseView:RefreshListRows(list)
    local tooltipService = self:GetService("tooltip");
    local ownProfessionsService = self:GetService("own-professions");
    local entries = list.entries;
    local rowPool = list.rowPool;
    for _, row in ipairs(rowPool) do
        row:Hide();
    end
    if (#entries == 0) then
        return;
    end

    -- visible window
    local visibleRowCount = math.ceil((list.scrollParent:GetHeight() or 400) / RowHeight) + 4;
    local startIndex = math.max(math.floor(list.scrollTop / RowHeight) - 1, 1);
    local endIndex = math.min(startIndex + visibleRowCount, #entries);
    while (#rowPool < endIndex - startIndex + 1) do
        rowPool[#rowPool + 1] = self:CreateListRow(list);
    end

    for index = startIndex, endIndex do
        local row = rowPool[index - startIndex + 1];
        local entry = entries[index];
        local top = (index - 1) * RowHeight;
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", list.scrollChild, "TOPLEFT", 0, -top);
        row:SetPoint("RIGHT", list.scrollChild, "RIGHT", -28, 0);

        -- reset every field of the recycled row
        row.entry = entry;
        row.rowIndex = index;
        row.selected = (list.selectedKey ~= nil and entry.key == list.selectedKey);
        row.nameText:SetText(entry.text or "");
        row.levelingText:SetText(entry.levelingText or "");
        row.levelingText:SetWidth(list.hasLeveling and 90 or 1);

        -- availability icon of a recipe
        local flagTexture = tooltipService:GetAvailabilityTexture(entry.availability);
        if (flagTexture) then
            row.flagButton.icon:SetTexture(flagTexture);
            row.flagButton.icon:Show();
            row.flagButton:SetWidth(14);
        else
            row.flagButton.icon:Hide();
            row.flagButton:SetWidth(1);
        end

        -- ownership dot of a profession
        local dotColor = ownProfessionsService:GetOwnershipColor(entry.ownership);
        if (dotColor) then
            row.dot:SetVertexColor(dotColor[1], dotColor[2], dotColor[3]);
            row.dot:Show();
        else
            row.dot:Hide();
        end
        self:SetRowBackground(row);
        row:Show();
    end
end

--- Insert the item link (or the skill link on tbc and later) into the chat.
function DatabaseView:InsertSkillLink(skill)
    if (skill.itemLink) then
        self.addon.compat.ChatEdit_InsertLink(skill.itemLink);
    elseif (self.addon.isBccAtLeast and skill.skillLink) then
        self.addon.compat.ChatEdit_InsertLink(skill.skillLink);
    end
end

--- Get the skill level of the current character in a profession, nil when
--- the profession is unknown or already at the max level of the client.
function DatabaseView:GetOwnProfessionLevel(professionId)
    local levels = PM_CharacterSettings.professionLevels;
    local level = levels and levels[professionId];
    if (not level) then
        return nil;
    end
    local addon = self.addon;
    local clientIndex = (addon.isMop and 5) or (addon.isCata and 4) or (addon.isWrath and 3) or (addon.isBcc and 2) or 1;
    if (level >= (MaxSkillLevels[clientIndex] or 300)) then
        return nil;
    end
    return level;
end

--- Build a list entry for a skill: icon and colored name, the leveling text
--- when the character knows the profession.
function DatabaseView:CreateSkillEntry(skillId, skill)
    local professionId = skill.professionId;
    local name = skill.itemColor and ("|c" .. skill.itemColor .. skill.name .. "|r") or skill.name;
    if (skill.itemAmount and skill.itemAmount > 1) then
        name = name .. " x" .. skill.itemAmount;
    end
    local entry = {
        key = skillId,
        skillId = skillId,
        professionId = professionId,
        skill = skill,
        text = "|T" .. (skill.icon or 134400) .. ":16|t  " .. name,
        availability = self:GetService("skills"):GetSkillAvailability(skill),
    };
    local level = self:GetOwnProfessionLevel(professionId);
    if (level) then
        entry.levelingText = self:GetService("skill-sort"):GetLevelingText(skill.difficulty, level);
    end
    return entry;
end

--- Check whether a skill is listed: named, of a shown profession, of the
--- selected addon and learnable at all on this client.
function DatabaseView:IsListedSkill(skill, shownProfessions)
    if (not skill.name or not skill.professionId or not shownProfessions[skill.professionId]) then
        return false;
    end
    if (self:GetService("skills"):IsHiddenSkill(skill)) then
        return false;
    end
    if (self.addonId and not self:GetService("category"):MatchesAddon(skill, self.addonId)) then
        return false;
    end
    return true;
end

--- Get the shown profession ids as a lookup table.
function DatabaseView:GetShownProfessions()
    local shown = {};
    for _, professionId in ipairs(self:GetService("profession-names"):GetProfessionIdsToShow(true)) do
        shown[professionId] = true;
    end
    return shown;
end

--- Sort entries by name (the icon prefix is identical in length per row).
local function SortEntriesByName(entries)
    table.sort(entries, function(a, b)
        return a.skill.name < b.skill.name;
    end);
end

--- Collect the item entries of a profession.
function DatabaseView:CollectProfessionEntries(professionId)
    local skillsService = self:GetService("skills");
    local shown = { [professionId] = true };
    local entries = {};
    for skillId, skill in pairs(skillsService.allSkills) do
        if (self:IsListedSkill(skill, shown)) then
            entries[#entries + 1] = self:CreateSkillEntry(skillId, skill);
        end
    end
    SortEntriesByName(entries);
    return entries;
end

--- Collect the favorite item entries (the addon filter does not apply to favorites).
function DatabaseView:CollectFavoriteEntries()
    local skillsService = self:GetService("skills");
    local favorites = self:GetService("player").node.databaseFavorites;
    local entries = {};
    for skillId, _ in pairs(favorites) do
        local skill = skillsService:GetSkillById(skillId);
        if (skill and skill.name and skill.professionId) then
            entries[#entries + 1] = self:CreateSkillEntry(skillId, skill);
        end
    end
    SortEntriesByName(entries);
    return entries;
end

--- Collect the items of all professions whose name contains every search part.
function DatabaseView:CollectSearchEntries(searchParts)
    local skillsService = self:GetService("skills");
    local shown = self:GetShownProfessions();
    local entries = {};
    for skillId, skill in pairs(skillsService.allSkills) do
        if (self:IsListedSkill(skill, shown)) then
            local lowerName = string.lower(skill.name);
            local matches = true;
            for _, part in ipairs(searchParts) do
                if (string.find(lowerName, part) == nil) then
                    matches = false;
                    break;
                end
            end
            if (matches) then
                entries[#entries + 1] = self:CreateSkillEntry(skillId, skill);
            end
        end
    end
    SortEntriesByName(entries);
    return entries;
end

--- Build the profession column: favorites first, then every profession of the
--- client in alphabetical order, each with the dot of the own characters knowing it.
function DatabaseView:BuildProfessionEntries()
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");
    local ownProfessionsService = self:GetService("own-professions");
    local professionEntries = {};
    for _, professionId in ipairs(professionNamesService:GetProfessionIdsToShow(true)) do
        local ownership, altNames = ownProfessionsService:GetProfessionOwnership(professionId);
        professionEntries[#professionEntries + 1] = {
            key = professionId,
            professionId = professionId,
            name = professionNamesService:GetProfessionName(professionId) or "",
            text = professionNamesService:GetProfessionText(professionId),
            ownership = ownership,
            altNames = altNames,
        };
    end
    table.sort(professionEntries, function(a, b)
        return a.name < b.name;
    end);

    local entries = {
        { key = FavoritesKey, text = "|T" .. FavoriteIcon .. ":16|t  " .. localeService:Get("ProfessionsViewFavorites") },
    };
    for _, entry in ipairs(professionEntries) do
        entries[#entries + 1] = entry;
    end
    return entries;
end

--- Fill the profession column (or the search results) and the item column.
-- @param preserveScroll True to keep the scroll positions (data refresh).
function DatabaseView:RefreshLists(preserveScroll)
    if (not self.view) then
        return;
    end
    local localeService = self:GetService("locale");
    local searchParts = self:GetSearchParts();

    if (searchParts) then
        -- search: the found items replace the professions, no item column
        self.leftList.selectedKey = self.selectedSkillId;
        local entries = self:CollectSearchEntries(searchParts);
        self:SetListEntries(self.leftList, entries, true, localeService:Get("DatabaseViewNoResults"), preserveScroll);
        if (not preserveScroll) then
            self.addon:Log("DatabaseView", "RefreshLists", "Search found %d items", #entries);
        end
    else
        -- professions: validate the remembered selection, default to the first profession
        local professionEntries = self:BuildProfessionEntries();
        local selectionValid = false;
        for _, entry in ipairs(professionEntries) do
            if (entry.key == self.selectionKey) then
                selectionValid = true;
                break;
            end
        end
        if (not selectionValid) then
            self.selectionKey = professionEntries[2] and professionEntries[2].key or FavoritesKey;
            PM_CharacterSettings.lastDatabaseSelection = self.selectionKey;
        end
        self.leftList.selectedKey = self.selectionKey;
        self:SetListEntries(self.leftList, professionEntries, false, nil, preserveScroll);

        -- item column
        local entries;
        if (self.selectionKey == FavoritesKey) then
            entries = self:CollectFavoriteEntries();
        else
            entries = self:CollectProfessionEntries(self.selectionKey);
        end
        self.itemList.selectedKey = self.selectedSkillId;
        self:SetListEntries(self.itemList, entries, true, localeService:Get("DatabaseViewNoResults"), preserveScroll);
    end

    self:RenderDetail();
end

--- Click in the profession column: select a profession (or the favorites),
--- in search mode the clicked item.
function DatabaseView:OnLeftEntryClick(entry)
    if (entry.skillId) then
        self:SelectSkill(entry.skillId);
        self.leftList.selectedKey = entry.skillId;
        self:RefreshListRows(self.leftList);
        return;
    end
    self.selectionKey = entry.key;
    PM_CharacterSettings.lastDatabaseSelection = entry.key;
    self.addon:Log("DatabaseView", "SelectProfession", "Selected %s", tostring(entry.key));
    self:RefreshLists();
end

--- Click in the item column: show the item detail.
function DatabaseView:OnItemEntryClick(entry)
    self:SelectSkill(entry.skillId);
    self.itemList.selectedKey = entry.skillId;
    self:RefreshListRows(self.itemList);
end

--- Select a skill for the detail panel.
function DatabaseView:SelectSkill(skillId)
    if (self.selectedSkillId == skillId and not self.selectedItemId) then
        return;
    end
    self:PushHistory();
    self.selectedItemId = nil;
    self.selectedSkillId = skillId;
    PM_CharacterSettings.lastDatabaseSkillId = skillId;
    self:RenderDetail();
end

--- Select a plain item for the detail panel (a reagent no profession makes:
--- dust, essences, gems from nodes) with its uses instead of a recipe.
function DatabaseView:SelectItem(itemId)
    if (self.selectedItemId == itemId) then
        return;
    end
    self:PushHistory();
    self.selectedItemId = itemId;
    self:RenderDetail();
end

--- Remember the shown detail (skill or item) as a step the back button can undo.
function DatabaseView:PushHistory()
    local history = self.history;
    if (self.selectedItemId) then
        history[#history + 1] = { itemId = self.selectedItemId };
    elseif (self.selectedSkillId) then
        history[#history + 1] = { skillId = self.selectedSkillId };
    else
        return;
    end
    if (#history > 50) then
        table.remove(history, 1);
    end
end

--- Go back to the previously shown skill or item.
function DatabaseView:GoBack()
    local history = self.history;
    local entry = history[#history];
    if (not entry) then
        return;
    end
    history[#history] = nil;
    self.selectedItemId = entry.itemId;
    if (entry.skillId) then
        self.selectedSkillId = entry.skillId;
        PM_CharacterSettings.lastDatabaseSkillId = entry.skillId;
    end
    self.addon:Log("DatabaseView", "GoBack", "Back to %s", tostring(entry.skillId or entry.itemId));

    -- highlight the skill in the lists again when it is listed there
    local listKey = (not entry.itemId) and entry.skillId or nil;
    if (self:IsSearchMode()) then
        self.leftList.selectedKey = listKey;
        self:RefreshListRows(self.leftList);
    else
        self.itemList.selectedKey = listKey;
        self:RefreshListRows(self.itemList);
    end
    self:RenderDetail();
end

--- Create the detail panel: header with icon and name, description, cost,
--- reagents, sources and crafters in a scroll frame, the shopping list
--- controls in a footer bar.
function DatabaseView:CreateDetail(panel)
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- scrollable content above the footer bar
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(panel);
    scrollParent:SetPoint("TOPLEFT", 6, -6);
    scrollParent:SetPoint("BOTTOMRIGHT", -6, 40);
    scrollParent:SetBackdropColor(0, 0, 0, 0);
    scrollChild:SetWidth(scrollParent:GetWidth());
    scrollParent:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);
    self.detailScrollParent = scrollParent;
    self.detailScrollChild = scrollChild;
    self.detailScrollElement = scrollElement;

    -- hint while nothing is selected
    local hintText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    hintText:SetPoint("CENTER", panel, "CENTER", 0, 0);
    hintText:SetTextColor(0.6, 0.6, 0.6, 1);
    hintText:SetText(localeService:Get("DatabaseViewSelectItem"));
    self.detailHint = hintText;

    -- header: big icon, name and profession; hover shows the skill tooltip,
    -- shift click links the item
    local headerButton = CreateFrame("Button", nil, scrollChild);
    headerButton:SetPoint("TOPLEFT", 8, -8);
    headerButton:SetHeight(48);
    headerButton:SetWidth(300);
    headerButton:SetScript("OnEnter", function()
        local skill = self.detailSkill;
        if (not skill and not self.detailItemLink) then return; end
        GameTooltip:SetOwner(headerButton, "ANCHOR_NONE");
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPRIGHT", headerButton, "TOPLEFT", -2, 0);
        if (skill) then
            self:GetService("tooltip"):ShowTooltip(GameTooltip, skill.professionId, self.selectedSkillId, skill, nil);
        else
            GameTooltip:SetHyperlink(self.detailItemLink);
            GameTooltip:Show();
        end
    end);
    headerButton:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);
    headerButton:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton" or not IsShiftKeyDown() or not self.addon.compat.ChatEdit_GetActiveWindow()) then return; end
        if (self.detailSkill) then
            self:InsertSkillLink(self.detailSkill);
        elseif (self.detailItemLink) then
            self.addon.compat.ChatEdit_InsertLink(self.detailItemLink);
        end
    end);
    self.detailHeaderButton = headerButton;

    local icon = scrollChild:CreateTexture(nil, "ARTWORK");
    icon:SetSize(40, 40);
    icon:SetPoint("TOPLEFT", 12, -12);
    self.detailIcon = icon;

    local nameText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    nameText:SetPoint("TOPLEFT", 60, -14);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    self.detailNameText = nameText;

    local professionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    professionText:SetPoint("TOPLEFT", 60, -36);
    professionText:SetJustifyH("LEFT");
    professionText:SetTextColor(0.8, 0.8, 0.8, 1);
    self.detailProfessionText = professionText;

    -- favorite toggle at the right end of the header (talisman: white adds,
    -- red tint removes)
    local favoriteButton = CreateFrame("Button", nil, scrollChild);
    favoriteButton:SetSize(24, 24);
    favoriteButton:SetPoint("TOPRIGHT", -36, -14);
    local favoriteStar = favoriteButton:CreateTexture(nil, "OVERLAY");
    favoriteStar:SetSize(20, 20);
    favoriteStar:SetPoint("CENTER", 0, 0);
    favoriteStar:SetTexture(FavoriteIcon);
    favoriteButton.star = favoriteStar;
    favoriteButton:SetScript("OnClick", function()
        self:ToggleFavorite();
    end);
    uiService:BindTooltip(favoriteButton, function()
        local favorites = self:GetService("player").node.databaseFavorites;
        local key = (self.selectedSkillId and favorites[self.selectedSkillId]) and "ProfessionsViewRemoveFromFavorites" or "ProfessionsViewAddToFavorites";
        return localeService:Get(key);
    end, "ANCHOR_LEFT");
    self.detailFavoriteButton = favoriteButton;

    -- back button left of the favorite toggle: returns to the skill shown
    -- before (clicking through reagents, lists), visible while there is one
    local backButton = uiService:CreateHeaderIconButton(scrollChild, [[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]], localeService:Get("DatabaseViewBack"), function()
        self:GoBack();
    end);
    backButton:SetPoint("RIGHT", favoriteButton, "LEFT", -6, 0);
    self.detailBackButton = backButton;

    -- keep both buttons clickable above the header hover region
    favoriteButton:SetFrameLevel(headerButton:GetFrameLevel() + 1);
    backButton:SetFrameLevel(headerButton:GetFrameLevel() + 1);

    -- description: the tooltip lines of the item
    local descriptionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    descriptionText:SetJustifyH("LEFT");
    descriptionText:SetJustifyV("TOP");
    descriptionText:SetWordWrap(true);
    descriptionText:SetSpacing(2);
    self.detailDescriptionText = descriptionText;

    -- crafting cost
    local costText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    costText:SetJustifyH("LEFT");
    self.detailCostText = costText;

    -- section headers and bodies
    self.detailReagentsHeader = self:CreateDetailHeader(localeService:Get("DatabaseViewReagents"));
    self.reagentRows = {};
    self.detailSourceHeader = self:CreateDetailHeader(localeService:Get("ProfessionsViewSource"));
    local sourceText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    sourceText:SetJustifyH("LEFT");
    sourceText:SetJustifyV("TOP");
    sourceText:SetWordWrap(true);
    sourceText:SetSpacing(2);
    self.detailSourceText = sourceText;
    self.detailPlayersHeader = self:CreateDetailHeader(localeService:Get("SkillViewPlayers"));
    self.playerRows = {};
    self.detailUsesHeader = self:CreateDetailHeader(localeService:Get("DatabaseViewReagentFor"));
    self.skillRows = {};
    local playersEmptyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    playersEmptyText:SetJustifyH("LEFT");
    playersEmptyText:SetTextColor(0.6, 0.6, 0.6, 1);
    playersEmptyText:SetText(localeService:Get("DatabaseViewNoPlayers"));
    self.detailPlayersEmptyText = playersEmptyText;

    -- footer bar: shopping list amount with plus, minus and clear
    local footer = CreateFrame("Frame", nil, panel);
    footer:SetPoint("BOTTOMLEFT", 6, 6);
    footer:SetPoint("BOTTOMRIGHT", -6, 6);
    footer:SetHeight(30);
    self.detailFooter = footer;

    local footerBorder = footer:CreateTexture(nil, "BORDER");
    footerBorder:SetColorTexture(0.5, 0.5, 0.5, 0.5);
    footerBorder:SetHeight(1);
    footerBorder:SetPoint("TOPLEFT", 0, 0);
    footerBorder:SetPoint("TOPRIGHT", 0, 0);

    local bucketListLabel = footer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    bucketListLabel:SetPoint("LEFT", 8, 0);
    bucketListLabel:SetText(localeService:Get("SkillViewOnBucketList") .. ":");

    local bucketListAmountText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    bucketListAmountText:SetPoint("LEFT", bucketListLabel, "RIGHT", 8, 0);
    bucketListAmountText:SetJustifyH("LEFT");
    bucketListAmountText:SetWidth(30);
    self.bucketListAmountText = bucketListAmountText;

    local amountPlusButton = uiService:CreateFlatSquareButton(footer, "+", function()
        self:ChangeBucketListAmount(1);
    end, 20);
    amountPlusButton:SetPoint("LEFT", bucketListAmountText, "RIGHT", 4, 0);
    uiService:BindTooltip(amountPlusButton, localeService:Get("SkillViewAddToBucketList"));

    local amountMinusButton = uiService:CreateFlatSquareButton(footer, "-", function()
        self:ChangeBucketListAmount(-1);
    end, 20);
    amountMinusButton:SetPoint("LEFT", amountPlusButton, "RIGHT", 3, 0);
    uiService:BindTooltip(amountMinusButton, localeService:Get("SkillViewRemoveOneFromBucketList"));
    self.amountMinusButton = amountMinusButton;

    local clearButton = uiService:CreateFlatSquareButton(footer, "x", function()
        self:ChangeBucketListAmount(0);
    end, 20);
    clearButton:SetPoint("LEFT", amountMinusButton, "RIGHT", 3, 0);
    uiService:BindTooltip(clearButton, localeService:Get("SkillViewRemoveFromBucketList"));
    self.clearButton = clearButton;
end

--- Create a gold section header in the detail scroll child.
function DatabaseView:CreateDetailHeader(text)
    local header = self.detailScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    header:SetJustifyH("LEFT");
    header:SetTextColor(1, 0.84, 0, 1);
    header:SetText(text);
    header:Hide();
    return header;
end

--- Hide every detail element before a render.
function DatabaseView:ClearDetail()
    self.detailIcon:Hide();
    self.detailNameText:Hide();
    self.detailProfessionText:Hide();
    self.detailHeaderButton:Hide();
    self.detailFavoriteButton:Hide();
    self.detailBackButton:Hide();
    self.detailDescriptionText:Hide();
    self.detailCostText:Hide();
    self.detailReagentsHeader:Hide();
    for _, row in ipairs(self.reagentRows) do
        row:Hide();
    end
    self.detailSourceHeader:Hide();
    self.detailSourceText:Hide();
    self.detailPlayersHeader:Hide();
    self.detailPlayersEmptyText:Hide();
    for _, row in ipairs(self.playerRows) do
        row:Hide();
    end
    self.detailUsesHeader:Hide();
    for _, row in ipairs(self.skillRows) do
        row:Hide();
    end
    self.detailFooter:Hide();
end

--- Render the detail of a plain item: tooltip text, the nodes it drops from,
--- a free conversion that makes it and the recipes that use it.
function DatabaseView:RenderItemDetail(itemId)
    local skillsService = self:GetService("skills");
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");
    self.detailSkill = nil;
    self.detailItemLink = nil;
    self.detailHint:Hide();

    -- wait for the item data, never show a preliminary name
    local name, link, _, _, _, _, _, _, _, icon = self.addon.compat.GetItemInfo(itemId);
    if (not name or not link) then
        self.detailScrollChild:SetHeight(1);
        if (self.itemRetryId ~= itemId and C_Item.DoesItemExistByID(itemId)) then
            self.itemRetryId = itemId;
            local item = Item:CreateFromItemID(itemId);
            if (not item:IsItemEmpty()) then
                pcall(function()
                    item:ContinueOnItemLoad(function()
                        if (self.visible and self.selectedItemId == itemId) then
                            self:RenderDetail();
                        end
                    end);
                end);
            end
        end
        return;
    end
    self.detailItemLink = link;

    local scrollChild = self.detailScrollChild;
    local contentWidth = math.max(scrollChild:GetWidth() - 12 - 36, 100);

    -- header
    self.detailIcon:SetTexture(icon or 134400);
    self.detailIcon:Show();
    self.detailNameText:SetWidth(contentWidth - 80);
    self.detailNameText:SetText("|c" .. professionNamesService:GetItemColor(link) .. name .. "|r");
    self.detailNameText:Show();
    self.detailProfessionText:SetText("");
    self.detailHeaderButton:SetWidth(math.max(contentWidth - 90, 50));
    self.detailHeaderButton:Show();
    self.detailBackButton:SetShown(#self.history > 0);
    local top = 64;

    -- description from the item tooltip
    local descriptionLines = {};
    for index, line in ipairs(self:GetService("tooltip"):GetHyperlinkTooltipLines(link)) do
        if (index > 1 and line.left ~= "") then
            local text = self:ColorLine(line.left, line.lr, line.lg, line.lb);
            if (line.right) then
                text = text .. "  " .. self:ColorLine(line.right, line.rr, line.rg, line.rb);
            end
            descriptionLines[#descriptionLines + 1] = text;
        end
    end
    if (#descriptionLines > 0) then
        local descriptionText = self.detailDescriptionText;
        descriptionText:ClearAllPoints();
        descriptionText:SetPoint("TOPLEFT", 12, -top);
        descriptionText:SetWidth(contentWidth);
        descriptionText:SetText(table.concat(descriptionLines, "\n"));
        descriptionText:Show();
        top = top + descriptionText:GetStringHeight() + 12;
    end

    -- free conversion anyone can do (essences, motes, crystallized)
    local conversion = skillsService.conversions and skillsService.conversions[itemId];
    if (conversion and conversion.reagents) then
        self.bucketListAmount = 0;
        self.detailReagentsHeader:ClearAllPoints();
        self.detailReagentsHeader:SetPoint("TOPLEFT", 12, -top);
        self.detailReagentsHeader:Show();
        top = top + 20;
        top = self:RenderReagentRows({ reagents = conversion.reagents }, top, contentWidth);
        top = top + 12;
    end

    -- mining nodes the item drops from (secondary node contents)
    local nodeRows = {};
    for oreItemId, contents in pairs(skillsService.nodeContents or {}) do
        for _, content in ipairs(contents) do
            if (content[1] == itemId) then
                local nodeSkillId = skillsService:GetSkillIdByItemId(oreItemId);
                local nodeSkill = nodeSkillId and skillsService:GetSkillById(nodeSkillId);
                if (nodeSkill and nodeSkill.name) then
                    nodeRows[#nodeRows + 1] = { skillId = nodeSkillId, skill = nodeSkill, rightText = content[2] .. "%" };
                end
                break;
            end
        end
    end
    if (#nodeRows > 0) then
        table.sort(nodeRows, function(a, b) return a.skill.name < b.skill.name; end);
        self.detailSourceHeader:SetText(localeService:Get("DatabaseViewFoundIn"));
        self.detailSourceHeader:ClearAllPoints();
        self.detailSourceHeader:SetPoint("TOPLEFT", 12, -top);
        self.detailSourceHeader:Show();
        top = top + 20;
        top = self:RenderSkillRows(nodeRows, top, contentWidth, 0);
        top = top + 12;
    end

    -- recipes that use the item
    local useRows = {};
    -- only recipes of the shown professions (first aid is not tracked)
    local shownProfessions = self:GetShownProfessions();
    for _, skillId in ipairs(skillsService:GetSkillIdsByReagentItemId(itemId) or {}) do
        local skill = skillsService:GetSkillById(skillId);
        if (skill and skill.name and skill.professionId and shownProfessions[skill.professionId]) then
            local professionName = professionNamesService:GetProfessionName(skill.professionId);
            useRows[#useRows + 1] = { skillId = skillId, skill = skill, rightText = professionName and ("|cffaaaaaa" .. professionName .. "|r") or "" };
        end
    end
    if (#useRows > 0) then
        table.sort(useRows, function(a, b) return a.skill.name < b.skill.name; end);
        self.detailUsesHeader:ClearAllPoints();
        self.detailUsesHeader:SetPoint("TOPLEFT", 12, -top);
        self.detailUsesHeader:Show();
        top = top + 20;
        top = self:RenderSkillRows(useRows, top, contentWidth, #nodeRows);
    end

    scrollChild:SetHeight(top + 12);
end

--- Render clickable skill rows (icon and name, a text on the right) and return the next top.
-- @param rows Array of { skillId, skill, rightText }.
-- @param top Top offset of the first row.
-- @param contentWidth Row width.
-- @param poolOffset Number of pooled rows already used above.
function DatabaseView:RenderSkillRows(rows, top, contentWidth, poolOffset)
    local uiService = self:GetService("ui");
    for index, entry in ipairs(rows) do
        local poolIndex = poolOffset + index;
        local row = self.skillRows[poolIndex];
        if (not row) then
            row = self:CreateSkillRow();
            self.skillRows[poolIndex] = row;
        end
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.detailScrollChild, "TOPLEFT", 8, -top);
        row:SetWidth(contentWidth + 8);
        row.rowIndex = index;
        uiService:SetRowColor(row, index);
        row.skillId = entry.skillId;
        row.skill = entry.skill;
        local skill = entry.skill;
        local name = skill.itemColor and ("|c" .. skill.itemColor .. skill.name .. "|r") or skill.name;
        row.itemText:SetText("|T" .. (skill.icon or 134400) .. ":16|t  " .. name);
        row.rightText:SetText(entry.rightText or "");
        row:Show();
        top = top + RowHeight;
    end
    return top;
end

--- Create one clickable skill row of the item detail.
function DatabaseView:CreateSkillRow()
    local uiService = self:GetService("ui");
    local row = CreateFrame("Button", nil, self.detailScrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(RowHeight);
    row:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]]
    });

    local rightText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    rightText:SetPoint("RIGHT", -6, 0);
    rightText:SetJustifyH("RIGHT");
    row.rightText = rightText;

    local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemText:SetPoint("LEFT", 4, 0);
    itemText:SetPoint("RIGHT", rightText, "LEFT", -8, 0);
    itemText:SetJustifyH("LEFT");
    itemText:SetWordWrap(false);
    row.itemText = itemText;

    -- hover: skill tooltip left of the row
    row:SetScript("OnEnter", function()
        row:SetBackdropColor(0.2, 0.2, 0.2);
        if (row.skill) then
            GameTooltip:SetOwner(row, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
            self:GetService("tooltip"):ShowTooltip(GameTooltip, row.skill.professionId, row.skillId, row.skill, nil);
        end
    end);
    row:SetScript("OnLeave", function()
        GameTooltip:Hide();
        uiService:SetRowColor(row, row.rowIndex or 1);
    end);

    -- click: shift links the item, otherwise the skill detail opens
    row:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton" or not row.skillId) then return; end
        if (IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow()) then
            self:InsertSkillLink(row.skill);
        else
            self:SelectSkill(row.skillId);
        end
    end);
    uiService:AttachHoverGlow(row);
    return row;
end

--- Render the detail of the selected skill.
function DatabaseView:RenderDetail()
    if (not self.view) then
        return;
    end
    local skillsService = self:GetService("skills");
    local localeService = self:GetService("locale");
    local skillId = self.selectedSkillId;
    local skill = skillId and skillsService:GetSkillById(skillId);
    self:ClearDetail();

    -- plain items (reagents without a recipe) have their own detail
    if (self.selectedItemId) then
        self:RenderItemDetail(self.selectedItemId);
        return;
    end

    if (not skill or not skill.name) then
        self.detailSkill = nil;
        self.detailItemLink = nil;
        self.detailHint:Show();
        self.detailScrollChild:SetHeight(1);
        return;
    end
    self.detailSkill = skill;
    self.detailItemLink = nil;
    self.detailHint:Hide();

    local scrollChild = self.detailScrollChild;
    local contentWidth = math.max(scrollChild:GetWidth() - 12 - 36, 100);
    local isGathering = skillId >= 9000000;

    -- header
    self.detailIcon:SetTexture(skill.icon or 134400);
    self.detailIcon:Show();
    local name = skill.itemColor and ("|c" .. skill.itemColor .. skill.name .. "|r") or skill.name;
    if (skill.itemAmount and skill.itemAmount > 1) then
        name = name .. " x" .. skill.itemAmount;
    end
    self.detailNameText:SetWidth(contentWidth - 80);
    self.detailNameText:SetText(name);
    self.detailNameText:Show();
    local professionNamesService = self:GetService("profession-names");
    -- untracked professions (first aid) have no icon, show the bare name then
    local professionText = "";
    if (skill.professionId and professionNamesService:GetProfessionIcon(skill.professionId)) then
        professionText = professionNamesService:GetProfessionText(skill.professionId);
    elseif (skill.professionId) then
        professionText = professionNamesService:GetProfessionName(skill.professionId) or "";
    end
    self.detailProfessionText:SetText(professionText);
    self.detailProfessionText:Show();
    -- the header hover region stops before the back and favorite buttons
    self.detailHeaderButton:SetWidth(math.max(contentWidth - 90, 50));
    self.detailHeaderButton:Show();
    self:RefreshFavoriteButton();
    self.detailFavoriteButton:Show();
    self.detailBackButton:SetShown(#self.history > 0);
    local top = 64;

    -- description from the item tooltip
    local descriptionLines = self:GetDescriptionLines(skill, skillId);
    if (#descriptionLines > 0) then
        local descriptionText = self.detailDescriptionText;
        descriptionText:ClearAllPoints();
        descriptionText:SetPoint("TOPLEFT", 12, -top);
        descriptionText:SetWidth(contentWidth);
        descriptionText:SetText(table.concat(descriptionLines, "\n"));
        descriptionText:Show();
        top = top + descriptionText:GetStringHeight() + 12;
    end

    -- gathering skills: the zones instead of reagents and sources
    if (isGathering) then
        local zoneNames = skillsService.zoneNames or {};
        local zoneTextParts = {};
        for _, zoneId in ipairs(skill.zones or {}) do
            if (zoneNames[zoneId]) then
                zoneTextParts[#zoneTextParts + 1] = zoneNames[zoneId];
            end
        end
        if (#zoneTextParts > 0) then
            self.detailSourceHeader:SetText(localeService:Get("DatabaseViewFoundIn"));
            self.detailSourceHeader:ClearAllPoints();
            self.detailSourceHeader:SetPoint("TOPLEFT", 12, -top);
            self.detailSourceHeader:Show();
            top = top + 20;
            local sourceText = self.detailSourceText;
            sourceText:ClearAllPoints();
            sourceText:SetPoint("TOPLEFT", 12, -top);
            sourceText:SetWidth(contentWidth);
            sourceText:SetText(table.concat(zoneTextParts, ", "));
            sourceText:Show();
            top = top + sourceText:GetStringHeight() + 12;
        end
        scrollChild:SetHeight(top + 12);
        return;
    end

    -- crafting cost (only with a price source and prices for every reagent)
    local costText = self:GetCraftingCostText(skill);
    if (costText) then
        self.detailCostText:ClearAllPoints();
        self.detailCostText:SetPoint("TOPLEFT", 12, -top);
        self.detailCostText:SetText(localeService:Get("DatabaseViewCraftingCost") .. ": |cffffffff" .. costText .. "|r");
        self.detailCostText:Show();
        top = top + 24;
    end

    -- reagents
    self.bucketListAmount = PM_BucketList[skillId] or 0;
    if (skill.reagents and next(skill.reagents)) then
        self.detailReagentsHeader:ClearAllPoints();
        self.detailReagentsHeader:SetPoint("TOPLEFT", 12, -top);
        self.detailReagentsHeader:Show();
        top = top + 20;
        top = self:RenderReagentRows(skill, top, contentWidth);
        top = top + 12;
    end

    -- sources: recipe items, trainers, quests, discovery
    local sourceLines = self:GetSourceLines(skill);
    if (#sourceLines > 0) then
        self.detailSourceHeader:SetText(localeService:Get("ProfessionsViewSource"));
        self.detailSourceHeader:ClearAllPoints();
        self.detailSourceHeader:SetPoint("TOPLEFT", 12, -top);
        self.detailSourceHeader:Show();
        top = top + 20;
        local sourceText = self.detailSourceText;
        sourceText:ClearAllPoints();
        sourceText:SetPoint("TOPLEFT", 12, -top);
        sourceText:SetWidth(contentWidth);
        sourceText:SetText(table.concat(sourceLines, "\n"));
        sourceText:Show();
        top = top + sourceText:GetStringHeight() + 12;
    end

    -- players who can craft the item
    self.detailPlayersHeader:ClearAllPoints();
    self.detailPlayersHeader:SetPoint("TOPLEFT", 12, -top);
    self.detailPlayersHeader:Show();
    top = top + 20;
    top = self:RenderPlayerRows(skill, skillId, top, contentWidth);

    scrollChild:SetHeight(top + 12);

    -- shopping list footer
    self.detailFooter:Show();
    self:RefreshBucketListAmount();
end

--- Get the description lines of a skill: the tooltip lines of the crafted
--- item (or of the enchantment), colored per line. Items not yet answered by
--- the client render the detail again once they are loaded.
function DatabaseView:GetDescriptionLines(skill, skillId)
    local tooltipService = self:GetService("tooltip");
    if (skillId >= 9000000) then
        return {};
    end

    -- link to read: the item, on tbc and later the enchantment otherwise
    local link = skill.itemLink;
    if (not link and self.addon.isBccAtLeast) then
        link = skill.skillLink;
    end
    if (not link) then
        -- vanilla enchantments have no link, use the spell description
        return self:GetSpellDescriptionLines(skillId);
    end

    local tooltipLines = tooltipService:GetHyperlinkTooltipLines(link);
    local lines = {};
    for index, line in ipairs(tooltipLines) do
        -- the first line is the name, already shown in the header
        if (index > 1 and line.left ~= "") then
            local text = self:ColorLine(line.left, line.lr, line.lg, line.lb);
            if (line.right) then
                text = text .. "  " .. self:ColorLine(line.right, line.rr, line.rg, line.rb);
            end
            lines[#lines + 1] = text;
        end
    end

    -- item not cached yet: the tooltip stays empty until the client answers
    if (#lines == 0 and skill.itemId and skill.itemId ~= 0 and self.descriptionRetrySkillId ~= skillId) then
        self.descriptionRetrySkillId = skillId;
        local item = Item:CreateFromItemID(skill.itemId);
        if (not item:IsItemEmpty()) then
            pcall(function()
                item:ContinueOnItemLoad(function()
                    if (self.visible and self.selectedSkillId == skillId) then
                        self:RenderDetail();
                    end
                end);
            end);
        end
    end
    return lines;
end

--- Get the spell description of an enchantment as description lines; the
--- description arrives asynchronously and renders the detail again.
function DatabaseView:GetSpellDescriptionLines(skillId)
    local lines = {};
    local description = self.spellDescriptions and self.spellDescriptions[skillId];
    if (description) then
        lines[1] = "|cffffd100" .. description .. "|r";
        return lines;
    end
    self:GetService("tooltip"):GetSpellDescriptionAsync(skillId, function(text)
        if (not text) then return; end
        self.spellDescriptions = self.spellDescriptions or {};
        self.spellDescriptions[skillId] = text;
        if (self.visible and self.selectedSkillId == skillId) then
            self:RenderDetail();
        end
    end);
    return lines;
end

--- Wrap a text into the given text color.
function DatabaseView:ColorLine(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", math.floor((r or 1) * 255 + 0.5), math.floor((g or 1) * 255 + 0.5), math.floor((b or 1) * 255 + 0.5), text);
end

--- Get the formatted crafting cost of one craft, nil without complete prices.
function DatabaseView:GetCraftingCostText(skill)
    local auctionService = self:GetService("auction");
    if (not skill.reagents or not auctionService:CheckPricesAvailable()) then
        return nil;
    end
    local total = 0;
    for reagentItemId, amount in pairs(skill.reagents) do
        local price = auctionService:GetItemPrice(reagentItemId);
        if (not price) then
            return nil;
        end
        total = total + price * amount;
    end
    return auctionService:FormatPrice(total) or "0";
end

--- Get the source lines of a skill: every obtainable recipe item with its
--- sources, then trainers, quests and discovery of the skill itself.
function DatabaseView:GetSourceLines(skill)
    local tooltipService = self:GetService("tooltip");
    local lines = {};

    -- append a block of tooltip lines, blank separators become empty lines
    local function AppendBlock(blockLines)
        local first = true;
        for _, line in ipairs(blockLines) do
            if (line == " ") then
                if (not first) then
                    lines[#lines + 1] = "";
                end
            else
                lines[#lines + 1] = line;
                first = false;
            end
        end
    end

    if (skill.recipes) then
        for _, recipe in ipairs(skill.recipes) do
            if (recipe.name and not recipe.unobtainable) then
                if (#lines > 0) then
                    lines[#lines + 1] = "";
                end
                -- a recipe only sold during a holiday carries the seasonal icon
                local prefix = self:GetService("skills"):IsSeasonalRecipe(recipe) and (tooltipService:GetAvailabilityIcon("seasonal", 14) .. " ") or "";
                lines[#lines + 1] = prefix .. "|c" .. (recipe.itemColor or "FF1EFF00") .. recipe.name .. "|r";
                AppendBlock(tooltipService:GetRecipeSourceLines(recipe));
            end
        end
    end

    local skillLines = tooltipService:GetSkillSourceLines(skill);
    if (#skillLines > 0) then
        if (#lines > 0) then
            lines[#lines + 1] = "";
        end
        AppendBlock(skillLines);
    end
    return lines;
end

--- Render the reagent rows (icon, name, owned of needed) and return the next top.
function DatabaseView:RenderReagentRows(skill, top, contentWidth)
    local inventoryService = self:GetService("inventory");
    local professionNamesService = self:GetService("profession-names");
    local skillsService = self:GetService("skills");
    inventoryService:ScanInventory();

    -- alphabetical once every name is known, by item id until the client has
    -- answered all of them (the rows render again after the last answer)
    local reagentIds = {};
    local reagentNames = {};
    local namesMissing = false;
    for reagentItemId, _ in pairs(skill.reagents) do
        reagentIds[#reagentIds + 1] = reagentItemId;
        local name = self:GetItemName(reagentItemId);
        if (name) then
            reagentNames[reagentItemId] = name;
        else
            namesMissing = true;
        end
    end
    if (namesMissing) then
        table.sort(reagentIds);
    else
        table.sort(reagentIds, function(a, b)
            if (reagentNames[a] == reagentNames[b]) then
                return a < b;
            end
            return reagentNames[a] < reagentNames[b];
        end);
    end

    -- one re-render for the sort order once the missing names arrived
    local selectedSkillId, selectedItemId = self.selectedSkillId, self.selectedItemId;
    local resortScheduled = false;
    local function ScheduleResort()
        if (not namesMissing or resortScheduled) then return; end
        resortScheduled = true;
        C_Timer.After(0.1, function()
            if (self.visible and self.selectedSkillId == selectedSkillId and self.selectedItemId == selectedItemId) then
                self:RenderDetail();
            end
        end);
    end

    for index, reagentItemId in ipairs(reagentIds) do
        local row = self.reagentRows[index];
        if (not row) then
            row = self:CreateReagentRow();
            self.reagentRows[index] = row;
        end
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.detailScrollChild, "TOPLEFT", 8, -top);
        row:SetWidth(contentWidth + 8);
        row.rowIndex = index;
        self:GetService("ui"):SetRowColor(row, index);

        -- reset the recycled row
        row.itemLink = nil;
        row.craftSkillId = nil;
        row.iconText:SetText("");
        row.itemText:SetText("");

        -- owned of needed for the shopping list amount, the plain amount otherwise
        local reagentAmount = skill.reagents[reagentItemId];
        local inventoryAmount = inventoryService:GetItemAmount(reagentItemId);
        local requiredAmount = (self.bucketListAmount or 0) * reagentAmount;
        if (requiredAmount > 0) then
            row.amountText:SetText(math.min(inventoryAmount, requiredAmount) .. "/" .. requiredAmount);
            if (inventoryAmount >= requiredAmount) then
                row.amountText:SetTextColor(0, 1, 0);
            else
                row.amountText:SetTextColor(1, 1, 1);
            end
        else
            row.amountText:SetText(reagentAmount);
            row.amountText:SetTextColor(1, 1, 1);
        end

        -- reagents made by a profession open their own detail on click
        local craftSkillId = skillsService:GetSkillIdByItemId(reagentItemId);
        if (craftSkillId and craftSkillId ~= self.selectedSkillId) then
            row.craftSkillId = craftSkillId;
        end

        -- name and icon arrive with the item data (a cached item answers at once)
        row.reagentItemId = reagentItemId;
        if (C_Item.DoesItemExistByID(reagentItemId)) then
            local item = Item:CreateFromItemID(reagentItemId);
            if (not item:IsItemEmpty()) then
                pcall(function()
                    item:ContinueOnItemLoad(function()
                        if (row.reagentItemId ~= reagentItemId) then return; end
                        row.itemLink = item:GetItemLink();
                        row.iconText:SetText("|T" .. item:GetItemIcon() .. ":16|t");
                        row.itemText:SetText("|c" .. professionNamesService:GetItemColor(row.itemLink) .. item:GetItemName() .. "|r");
                        ScheduleResort();
                    end);
                end);
            end
        end
        row:Show();
        top = top + RowHeight;
    end
    return top;
end

--- Get the name of an item the client already knows, nil until it answered.
function DatabaseView:GetItemName(itemId)
    if (C_Item and C_Item.GetItemNameByID) then
        return C_Item.GetItemNameByID(itemId);
    end
    local name = self.addon.compat.GetItemInfo(itemId);
    return name;
end

--- Create one reagent row of the detail panel.
function DatabaseView:CreateReagentRow()
    local uiService = self:GetService("ui");
    local row = CreateFrame("Button", nil, self.detailScrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(RowHeight);
    row:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]]
    });

    local iconText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    iconText:SetPoint("LEFT", 4, 0);
    row.iconText = iconText;

    local amountText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    amountText:SetPoint("RIGHT", -6, 0);
    amountText:SetJustifyH("RIGHT");
    row.amountText = amountText;

    local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemText:SetPoint("LEFT", 26, 0);
    itemText:SetPoint("RIGHT", amountText, "LEFT", -8, 0);
    itemText:SetJustifyH("LEFT");
    itemText:SetWordWrap(false);
    row.itemText = itemText;

    -- hover: item tooltip left of the row
    row:SetScript("OnEnter", function()
        row:SetBackdropColor(0.2, 0.2, 0.2);
        if (row.itemLink) then
            GameTooltip:SetOwner(row, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
            GameTooltip:SetHyperlink(row.itemLink);
            GameTooltip:Show();
        end
    end);
    row:SetScript("OnLeave", function()
        GameTooltip:Hide();
        uiService:SetRowColor(row, row.rowIndex or 1);
    end);

    -- click: shift links the reagent, otherwise a crafted reagent opens its detail
    row:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        if (IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow()) then
            if (row.itemLink) then
                self.addon.compat.ChatEdit_InsertLink(row.itemLink);
            end
        elseif (row.craftSkillId) then
            self:SelectSkill(row.craftSkillId);
        elseif (row.reagentItemId) then
            self:SelectItem(row.reagentItemId);
        end
    end);

    uiService:AttachHoverGlow(row);
    return row;
end

--- Render the crafter rows (online players open a whisper on click) and return the next top.
function DatabaseView:RenderPlayerRows(skill, skillId, top, contentWidth)
    local playerService = self:GetService("player");
    local uiService = self:GetService("ui");
    local players = self:GetService("profession-query"):GetSkillPlayers(skill.professionId, skillId);
    local playerNames, whisperTargets = {}, {};
    if (players and #players > 0) then
        playerNames, whisperTargets = playerService:CombinePlayerNames(players, nil, skill.professionId, skillId, true);
    end

    if (#playerNames == 0) then
        self.detailPlayersEmptyText:ClearAllPoints();
        self.detailPlayersEmptyText:SetPoint("TOPLEFT", 12, -top);
        self.detailPlayersEmptyText:SetWidth(contentWidth);
        self.detailPlayersEmptyText:Show();
        return top + RowHeight;
    end

    for index, playerName in ipairs(playerNames) do
        local row = self.playerRows[index];
        if (not row) then
            row = CreateFrame("Button", nil, self.detailScrollChild, BackdropTemplateMixin and "BackdropTemplate");
            row:SetHeight(RowHeight);
            row:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]]
            });
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            nameText:SetPoint("LEFT", 6, 0);
            nameText:SetPoint("RIGHT", -6, 0);
            nameText:SetJustifyH("LEFT");
            nameText:SetWordWrap(false);
            row.nameText = nameText;

            -- online players: click opens an empty whisper
            row:SetScript("OnClick", function()
                if (row.whisperTarget) then
                    self.addon.compat.ChatFrame_SendTell(playerService:GetWhisperTarget(row.whisperTarget));
                end
            end);
            row:SetScript("OnLeave", function()
                uiService:SetRowColor(row, row.rowIndex or 1);
            end);
            uiService:AttachHoverGlow(row);
            self.playerRows[index] = row;
        end
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.detailScrollChild, "TOPLEFT", 8, -top);
        row:SetWidth(contentWidth + 8);
        row.rowIndex = index;
        uiService:SetRowColor(row, index);
        row.whisperTarget = whisperTargets and whisperTargets[index] or nil;
        row:EnableMouse(row.whisperTarget ~= nil);
        row.nameText:SetText(playerName);
        row:Show();
        top = top + RowHeight;
    end
    return top;
end

--- Color the favorite toggle by the state of the selected skill.
function DatabaseView:RefreshFavoriteButton()
    local favorites = self:GetService("player").node.databaseFavorites;
    if (self.selectedSkillId and favorites[self.selectedSkillId]) then
        self.detailFavoriteButton.star:SetVertexColor(1, 0.35, 0.35);
    else
        self.detailFavoriteButton.star:SetVertexColor(1, 1, 1);
    end
end

--- Toggle the selected skill in the database favorites.
function DatabaseView:ToggleFavorite()
    local skillId = self.selectedSkillId;
    if (not skillId) then
        return;
    end
    local favorites = self:GetService("player").node.databaseFavorites;
    if (favorites[skillId]) then
        favorites[skillId] = nil;
        self.addon:Log("DatabaseView", "ToggleFavorite", "Removed skill %s from database favorites", tostring(skillId));
    else
        favorites[skillId] = true;
        self.addon:Log("DatabaseView", "ToggleFavorite", "Added skill %s to database favorites", tostring(skillId));
    end
    GameTooltip:Hide();
    self:RefreshFavoriteButton();

    -- the favorites list changes with it
    if (self.selectionKey == FavoritesKey and not self:IsSearchMode()) then
        self:RefreshLists();
    end
end

--- Change the shopping list amount of the selected skill by whole crafts
--- (direction 1 adds, -1 removes, 0 clears).
function DatabaseView:ChangeBucketListAmount(direction)
    local skillId = self.selectedSkillId;
    local skill = self.detailSkill;
    if (not skillId or not skill) then
        return;
    end
    local itemAmount = skill.itemAmount or 1;
    local amount = PM_BucketList[skillId] or 0;
    if (direction > 0) then
        PM_BucketList[skillId] = amount + itemAmount;
    elseif (direction < 0 and amount > itemAmount) then
        PM_BucketList[skillId] = amount - itemAmount;
    else
        PM_BucketList[skillId] = nil;
    end
    self.addon:Log("DatabaseView", "ChangeBucketListAmount", "Skill %s on shopping list: %s", tostring(skillId), tostring(PM_BucketList[skillId]));

    -- the overview shows the shopping list panel, the reagent rows the owned of needed amounts
    local professionsView = self.addon.professionsView;
    if (professionsView and professionsView.bucketListPanel) then
        professionsView:CheckBucketList();
    end
    self:GetService("inventory"):CheckMissingReagents();
    self:RenderDetail();
end

--- Update the shopping list amount and the minus / clear buttons of the footer.
function DatabaseView:RefreshBucketListAmount()
    local amount = PM_BucketList[self.selectedSkillId] or 0;
    self.bucketListAmount = amount;
    self.bucketListAmountText:SetText(amount);
    if (amount > 0) then
        self.amountMinusButton:Show();
        self.clearButton:Show();
    else
        self.amountMinusButton:Hide();
        self.clearButton:Hide();
    end
end
