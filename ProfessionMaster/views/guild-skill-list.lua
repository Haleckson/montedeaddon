--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel
local GuildSkillList = _G.professionMaster:CreateView("guild-skill-list");

--- Create skills list panel frames.
-- @param parentFrame The parent view frame to attach to.
-- @param professionsView Reference to the parent professions view.
function GuildSkillList:Create(parentFrame, professionsView)
    self.professionsView = professionsView;
    self.rowPool = {};
    self.groupHeaderPool = {};
    self.specRowPool = {};
    self.skills = {};
    self.professionId = nil;
    self.scrollTop = 0;
    self.hidePlayerColumn = false;
    self.bucketListSkillAmount = 0;
    self.favoriteSkillAmount = 0;

    -- refresh the "(requested)" markers when trade board data changes (only
    -- with a TradeBoard version that has the request host API)
    if (self.addon:IsTradeBoardCompatible()) then
        _G.tradeBoard:OnTradeDataChanged(function()
            if (self.frame and self.frame:IsShown()) then
                self.forceRefresh = true;
                self:RefreshRows();
            end
        end);
    end

    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- get profession ids (gathering professions excluded from guild tab)
    local professionNamesService = self:GetService("profession-names");
    local professionIds = professionNamesService:GetProfessionIdsToShow();

    -- add skills frame
    local frame = CreateFrame("Frame", nil, parentFrame);
    frame:SetPoint("TOPLEFT", 0, 0);
    frame:SetPoint("BOTTOMRIGHT", 0, 0);
    self.frame = frame;

    -- add item search box
    local itemSearchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemSearchLabel:SetPoint("TOPLEFT", 12, -12);
    itemSearchLabel:SetText(localeService:Get("ProfessionsViewSearch"));
    self.itemSearchLabel = itemSearchLabel;
    local itemSearchContainer = uiService:CreateEditBox(frame, 100);
    itemSearchContainer:SetPoint("TOPLEFT", 12, -28);
    if (professionsView.addon.hasExpansion) then
        itemSearchContainer:SetPoint("RIGHT", frame, "RIGHT", -318, 0);
    else
        itemSearchContainer:SetPoint("RIGHT", frame, "RIGHT", -180, 0);
    end
    itemSearchContainer:SetHeight(22);
    local itemSearch = itemSearchContainer.editBox;
    self.itemSearch = itemSearch;
    self.itemSearchContainer = itemSearchContainer;
    itemSearch:SetScript("OnKeyDown", function(_, key)
        if (key == "ESCAPE") then
            if (professionsView.skillViewVisible) then
                professionsView:HideSkillView();
            else
                professionsView:Hide();
            end
        elseif (key == "ENTER") then
            self.addon.compat.ChatFrame_OpenChat("", nil, nil);
        end
    end)
    itemSearch:SetScript("OnTextChanged", function()
        -- debounce: delay skill filtering by 0.2s
        if (self.searchPending) then
            self.searchPending:Cancel();
        end
        self.searchPending = C_Timer.NewTimer(0.2, function()
            self.searchPending = nil;
            PM_CharacterSettings.lastSearchText = itemSearch:GetText();
            self:AddSkills();
        end);
    end);

    -- add profession selection
    local professionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    professionLabel:SetText(localeService:Get("ProfessionsViewProfession"));
    self.professionLabel = professionLabel;

    -- build profession items for dropdown
    self.professionIds = professionIds;
    local professionSelection = uiService:CreateDropdown(frame, 160, self:BuildProfessionItems(), function(value)
        self:SelectProfession(value);
        self.itemSearch:SetFocus();
        self:AddSkills();
    end);
    if (professionsView.addon.hasExpansion) then
        professionLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -308, -12);
        professionSelection:SetPoint("TOPLEFT", frame, "TOPRIGHT", -310, -28);
    else
        professionLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -170, -12);
        professionSelection:SetPoint("TOPLEFT", frame, "TOPRIGHT", -172, -28);
    end
    self.professionSelection = professionSelection;

    -- add addon selection (only when multiple addons available)
    if (professionsView.addon.hasExpansion) then
        -- add addon selection
        local addonLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        addonLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -140, -12);
        addonLabel:SetText(localeService:Get("ProfessionsViewAddon"));
        self.addonLabel = addonLabel;

        -- build addon items
        local professionNamesService = self:GetService("profession-names");
        local addonItems = professionNamesService:BuildAddonItems(true);

        local addonSelection = uiService:CreateDropdown(frame, 130, addonItems, function(value)
            self:SelectAddon(value);
            self.itemSearch:SetFocus();
            self:AddSkills();
        end);
        addonSelection:SetPoint("TOPLEFT", frame, "TOPRIGHT", -142, -28);
        self.addonSelection = addonSelection;
    end

    -- add category filter dropdown
    local categoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    categoryLabel:SetPoint("TOPLEFT", 12, -58);
    categoryLabel:SetText(localeService:Get("ProfessionsViewCategory"));
    self.categoryLabel = categoryLabel;
    local categorySelection = uiService:CreateDropdown(frame, 150, {
        { value = nil, text = localeService:Get("ProfessionsViewCategoryAll") }
    }, function(value)
        self:SelectCategory(value);
        self:AddSkills();
    end);
    categorySelection:SetPoint("TOPLEFT", 12, -74);
    self.categorySelection = categorySelection;
    self.categoryId = nil;

    -- add subcategory filter dropdown
    local subcategoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    subcategoryLabel:SetPoint("TOPLEFT", 170, -58);
    subcategoryLabel:SetText(localeService:Get("ProfessionsViewSubcategory"));
    self.subcategoryLabel = subcategoryLabel;
    local subcategorySelection = uiService:CreateDropdown(frame, 150, {
        { value = nil, text = localeService:Get("ProfessionsViewSubcategoryAll") }
    }, function(value)
        self:SelectSubcategory(value);
        self:AddSkills();
    end);
    subcategorySelection:SetPoint("TOPLEFT", 170, -74);
    self.subcategorySelection = subcategorySelection;
    self.subcategoryId = nil;
    self.showSubcategory = false;
    subcategoryLabel:Hide();
    subcategorySelection:Hide();

    -- add bucket list icon
    local bucketListIcon = frame:CreateTexture(nil, "OVERLAY");
    bucketListIcon:SetSize(16, 16);
    bucketListIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up");
    bucketListIcon:SetPoint("TOPLEFT", frame, "TOPRIGHT", -56, -107);
    self.bucketListIcon = bucketListIcon;

    -- add specialization area (between search and item list)
    local specArea = CreateFrame("Frame", nil, frame);
    specArea:SetPoint("TOPLEFT", 6, -109);
    specArea:SetPoint("RIGHT", frame, "RIGHT", -8, 0);
    specArea:SetHeight(1);
    specArea:Hide();
    self.specArea = specArea;

    -- add specialization header
    local specHeaderLabel = specArea:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    specHeaderLabel:SetPoint("TOPLEFT", 8, 0);
    specHeaderLabel:SetText(localeService:Get("Specialization"));
    self.specHeaderLabel = specHeaderLabel;

    -- add specialization players header
    local specPlayersHeader = specArea:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    specPlayersHeader:SetPoint("TOPLEFT", 282, 0);
    specPlayersHeader:SetText(localeService:Get("ProfessionsViewPlayers"));
    self.specPlayersHeader = specPlayersHeader;

    -- add skill text (anchored below spec area)
    local skillText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    skillText:SetPoint("TOPLEFT", 12, -109);
    self.skillText = skillText;
    self.skillTextDefaultTop = -109;

    -- add player text
    local playerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    playerText:SetPoint("TOPLEFT", 286, -109);
    playerText:SetText(localeService:Get("ProfessionsViewPlayers"));
    self.playerHeaderText = playerText;
    self.playerHeaderDefaultTop = -109;

    -- create scroll frame
    local scrollFrame, scrollChild, scrollElement = uiService:CreateScrollFrame(frame);
    scrollFrame:SetPoint("TOPLEFT", 6, -122);
    scrollFrame:SetPoint("BOTTOMRIGHT", -8, 8);
    self.scrollFrameDefaultTop = -122;
    scrollElement:SetScript("OnVerticalScroll", function(_, top)
        self.scrollTop = top;
        self:RefreshRows();
    end);
    self.scrollFrame = scrollFrame;
    self.scrollChild = scrollChild;
    self.scrollElement = scrollElement;

    -- add bucket list group text (same bright gold style as the own list group texts)
    local bucketListGroupText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    bucketListGroupText:SetPoint("TOPLEFT", 4, -6);
    bucketListGroupText:SetTextColor(1, 0.84, 0, 1);
    bucketListGroupText:SetText(localeService:Get("ProfessionsViewBucketList"));
    self.bucketListGroupText = bucketListGroupText;

    -- add favorites group text
    local favoritesGroupText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    favoritesGroupText:SetTextColor(1, 0.84, 0, 1);
    favoritesGroupText:SetText(localeService:Get("ProfessionsViewFavorites"));
    self.favoritesGroupText = favoritesGroupText;

    -- add bucket other items text
    local otherGroupText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    otherGroupText:SetTextColor(1, 0.84, 0, 1);
    otherGroupText:SetText(localeService:Get("ProfessionsViewNotOnBucketList"));
    self.otherGroupText = otherGroupText;

    -- add empty state message (centered over the list area); a sibling of the
    -- list frame, so hiding the frame hides every control at once
    local emptyContainer = CreateFrame("Frame", nil, parentFrame);
    emptyContainer:SetPoint("CENTER", frame, "CENTER", 0, 0);
    emptyContainer:SetSize(400, 60);
    emptyContainer:Hide();
    self.emptyMessage = emptyContainer;

    local emptyTitle = emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    emptyTitle:SetPoint("TOP", emptyContainer, "TOP", 0, 0);
    emptyTitle:SetJustifyH("CENTER");
    emptyTitle:SetTextColor(0.7, 0.7, 0.7, 1);
    emptyTitle:SetText(localeService:Get("GuildNoDataTitle"));

    local emptyDescription = emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    emptyDescription:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -8);
    emptyDescription:SetWidth(400);
    emptyDescription:SetJustifyH("CENTER");
    emptyDescription:SetTextColor(0.5, 0.5, 0.5, 1);
    emptyDescription:SetText(localeService:Get("GuildNoDataDescription"));

    -- restore last settings
    self:SelectProfession(PM_CharacterSettings.lastProfession or 0);
    self:SelectAddon(PM_CharacterSettings.lastAddon);
    if (PM_CharacterSettings.lastCategory) then
        self:SelectCategory(PM_CharacterSettings.lastCategory);
        if (PM_CharacterSettings.lastSubcategory) then
            self:SelectSubcategory(PM_CharacterSettings.lastSubcategory);
        end
    end
    if (PM_CharacterSettings.lastSearchText and PM_CharacterSettings.lastSearchText ~= "") then
        self.itemSearch:SetText(PM_CharacterSettings.lastSearchText);
    end
end

--- Handle resize event.
function GuildSkillList:OnSizeChanged()
    if (self.scrollChild and self.scrollFrame) then
        self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
    end
end

--- Set right margin of skills frame for bucket list visibility.
-- @param margin Right margin in pixels.
function GuildSkillList:SetRightMargin(margin)
    if (self.frame) then
        self.frame:SetPoint("BOTTOMRIGHT", -margin, 0);
        self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
    end
end

--- Update responsive layout based on frame width.
function GuildSkillList:UpdateResponsiveLayout()
    if (not self.frame or not self.itemSearchContainer) then return; end
    local frameWidth = self.frame:GetWidth();
    if (frameWidth < 500) then
        self.itemSearchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -10, 0);
        if (self.professionLabel) then self.professionLabel:Hide(); end
        if (self.professionSelection) then self.professionSelection:Hide(); end
        if (self.addonLabel) then self.addonLabel:Hide(); end
        if (self.addonSelection) then self.addonSelection:Hide(); end
        if (self.playerHeaderText) then self.playerHeaderText:Hide(); end
        if (self.specPlayersHeader) then self.specPlayersHeader:Hide(); end
        if (self.bucketListIcon) then self.bucketListIcon:Hide(); end
        self.hidePlayerColumn = true;
    else
        if (self.professionsView.addon.hasExpansion) then
            self.itemSearchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -318, 0);
        else
            self.itemSearchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -180, 0);
        end
        if (self.professionLabel) then self.professionLabel:Show(); end
        if (self.professionSelection) then self.professionSelection:Show(); end
        if (self.addonLabel) then self.addonLabel:Show(); end
        if (self.addonSelection) then self.addonSelection:Show(); end
        if (self.playerHeaderText) then self.playerHeaderText:Show(); end
        if (self.specPlayersHeader) then self.specPlayersHeader:Show(); end
        if (self.bucketListIcon) then self.bucketListIcon:Show(); end
        self.hidePlayerColumn = false;
    end
end

--- Select profession.
-- @param professionId Profession ID.
function GuildSkillList:SelectProfession(professionId)
    self.professionId = professionId;
    PM_CharacterSettings.lastProfession = professionId;
    self.professionSelection:SetValue(professionId);
    self:RefreshCategoryItems();
    self:SelectCategory(nil);
end

--- Select addon.
-- @param addonId Addon ID.
function GuildSkillList:SelectAddon(addonId)
    if (not self.professionsView.addon.hasExpansion) then
        addonId = nil;
    end
    self.addonId = addonId;
    PM_CharacterSettings.lastAddon = addonId;
    if (self.addonSelection) then
        self.addonSelection:SetValue(addonId);
    end
    self:RefreshCategoryItems();
end

--- Select category filter.
function GuildSkillList:SelectCategory(categoryId)
    self.categoryId = categoryId;
    self.subcategoryId = nil;
    PM_CharacterSettings.lastCategory = categoryId;
    PM_CharacterSettings.lastSubcategory = nil;
    if (not self.categorySelection) then
        return;
    end
    self.categorySelection:SetValue(categoryId);
    self:RefreshCategoryItems();
    if (self.subcategorySelection) then
        self.subcategorySelection:SetValue(nil);
        self:RefreshSubcategoryItems();
        local categoryService = self:GetService("category");
        if (categoryId and categoryService:HasSubcategories(self:CollectVisibleSkillData(), categoryId)) then
            self.showSubcategory = true;
            self.subcategoryLabel:Show();
            self.subcategorySelection:Show();
        else
            self.showSubcategory = false;
            self.subcategoryLabel:Hide();
            self.subcategorySelection:Hide();
        end
    end
end

--- Select subcategory filter.
function GuildSkillList:SelectSubcategory(subcategoryId)
    self.subcategoryId = subcategoryId;
    PM_CharacterSettings.lastSubcategory = subcategoryId;
    if (not self.subcategorySelection) then
        return;
    end
    self.subcategorySelection:SetValue(subcategoryId);
end

--- Collect visible skill data for populating dropdowns.
function GuildSkillList:CollectVisibleSkillData()
    local skillsService = self:GetService("skills");
    local professionQueryService = self:GetService("profession-query");
    local categoryService = self:GetService("category");
    local result = {};
    local professionIds;

    if (self.professionId == 0) then
        professionIds = self:GetService("profession-names"):GetProfessionIdsToShow();
    elseif (self.professionId and self.professionId > 0) then
        professionIds = {self.professionId};
    else
        return result;
    end

    -- reuse the previous result while filters and underlying data are unchanged:
    -- selecting a profession or category triggers several dropdown refreshes in a row,
    -- and a full scan over all guild skills is far too expensive to repeat
    local playerService = self:GetService("player");
    local cacheKey = table.concat(professionIds, ",") .. ":" .. tostring(self.addonId)
        .. ":" .. tostring(professionQueryService.indexVersion)
        .. ":" .. tostring(playerService.visibilityVersion);
    if (self.visibleSkillDataKey == cacheKey and self.visibleSkillData) then
        return self.visibleSkillData;
    end

    local skillIndex = professionQueryService.skillIndex;
    for _, professionId in ipairs(professionIds) do
        local profession = skillIndex[professionId];
        if (profession) then
            for skillId, players in pairs(profession) do
                if (#players > 0 and professionQueryService:HasVisibleSkillPlayers(professionId, skillId, players)) then
                    local skillData = skillsService:GetSkillById(skillId);
                    if (skillData and skillData.name) then
                        if (self.addonId == nil or categoryService:MatchesAddon(skillData, self.addonId)) then
                            table.insert(result, {professionId = professionId, skillData = skillData});
                        end
                    end
                end
            end
        end
    end

    -- store for the follow-up refreshes
    self.visibleSkillDataKey = cacheKey;
    self.visibleSkillData = result;
    self.addon:Log("GuildSkillList", "CollectVisibleSkillData", "Collected %d visible skills for profession %s", #result, tostring(self.professionId));

    return result;
end

--- Refresh category dropdown items based on visible skills.
function GuildSkillList:RefreshCategoryItems()
    local categoryService = self:GetService("category");
    local items = categoryService:BuildCategoryItems(self:CollectVisibleSkillData());
    self.categorySelection:SetItems(items);
end

--- Refresh subcategory dropdown items based on visible skills and current category.
function GuildSkillList:RefreshSubcategoryItems()
    local categoryService = self:GetService("category");
    local items = categoryService:BuildSubcategoryItems(self:CollectVisibleSkillData(), self.categoryId);
    self.subcategorySelection:SetItems(items);
end

--- Check if a skill matches the given addon filter.
function GuildSkillList:MatchesAddon(skillData, addonId)
    return self:GetService("category"):MatchesAddon(skillData, addonId);
end

--- Check if a skill matches the currently selected category and subcategory filters.
function GuildSkillList:MatchesCategory(skillData, professionId)
    return self:GetService("category"):MatchesCategory(skillData, professionId, self.categoryId, self.subcategoryId);
end

--- Add skills.
--- Build the items of the profession dropdown: all professions first, then
--- every profession of the client with the dot of the own characters knowing it.
function GuildSkillList:BuildProfessionItems()
    local professionNamesService = self:GetService("profession-names");
    local ownProfessionsService = self:GetService("own-professions");
    local professionItems = {{ value = 0, text = professionNamesService:GetProfessionText(0) }};
    for _, professionId in ipairs(self.professionIds) do
        local ownership = ownProfessionsService:GetProfessionOwnership(professionId);
        table.insert(professionItems, {
            value = professionId,
            text = professionNamesService:GetProfessionText(professionId),
            dot = ownProfessionsService:GetOwnershipColor(ownership),
        });
    end
    return professionItems;
end

--- Rebuild the profession dropdown items so the dots follow the own professions.
function GuildSkillList:RefreshProfessionItems()
    if (not self.professionSelection) then return; end
    self.professionSelection:SetItems(self:BuildProfessionItems());
    self.professionSelection:SetValue(self.professionId or 0);
end

function GuildSkillList:AddSkills()
    local messageService = self:GetService("message");
    local localeService = self:GetService("locale");

    -- show the empty state while nobody besides the own characters has
    -- shared data (no guild, or the only one using the addon there)
    local isEmpty = not self:GetService("profession-query"):HasGuildData();
    if (isEmpty ~= self.isEmpty) then
        self.isEmpty = isEmpty;
        self.addon:Log("GuildSkillList", "AddSkills", "Empty state: %s", tostring(isEmpty));
    end
    self.frame:SetShown(not isEmpty);
    self.emptyMessage:SetShown(isEmpty);
    if (isEmpty) then
        return;
    end
    self:RefreshProfessionItems();

    -- set skill text
    if (self.professionId == 333) then
        self.skillText:SetText(localeService:Get("ProfessionsViewEnchantment"));
    else
        self.skillText:SetText(localeService:Get("ProfessionsViewItem"));
    end

    -- get search parts
    local searchText = string.lower(messageService:TrimString(self.itemSearch:GetText()));
    local searchParts = messageService:SplitString(string.gsub(searchText, "%-", "%%-"), " ");
    for i, part in ipairs(searchParts) do
        searchParts[i] = messageService:TrimString(searchParts[i]);
    end

    -- refresh specialization rows
    self:RefreshSpecializationRows();

    -- check professions
    self.skills = {};

    -- check if all should be shown
    self.bucketListSkillAmount = 0;
    self.favoriteSkillAmount = 0;
    if (self.professionId == 0) then
        local professionIds = self:GetService("profession-names"):GetProfessionIdsToShow();
        for i, professionId in ipairs(professionIds) do
            self:AddFilteredSkills(professionId, self.addonId, searchParts);
        end
    else
        self:AddFilteredSkills(self.professionId, self.addonId, searchParts);
    end

    -- sort skills (skip for All Specializations mode which is pre-ordered)
    if (self.professionId ~= -1) then
        table.sort(self.skills, function(a, b)
            if (a.bucketListAmount and not b.bucketListAmount) then
                return true;
            end
            if (not a.bucketListAmount and b.bucketListAmount) then
                return false;
            end
            if (a.isFavorite and not b.isFavorite) then
                return true;
            end
            if (not a.isFavorite and b.isFavorite) then
                return false;
            end
            return a.skill.name < b.skill.name;
        end);
    end

    -- set group text visibility (shopping list first, favorites second, others last)
    local bucketCount = self.bucketListSkillAmount;
    local favoriteCount = self.favoriteSkillAmount;
    local specialCount = bucketCount + favoriteCount;
    if (bucketCount > 0) then
        self.bucketListGroupText:Show();
    else
        self.bucketListGroupText:Hide();
    end
    if (favoriteCount > 0) then
        self.favoritesGroupText:SetPoint("TOPLEFT", 4, -(bucketCount * 20 + (bucketCount > 0 and 20 or 0) + 6));
        self.favoritesGroupText:Show();
    else
        self.favoritesGroupText:Hide();
    end
    if (specialCount > 0 and specialCount < #self.skills) then
        self.otherGroupText:SetPoint("TOPLEFT", 4, -(specialCount * 20 + (bucketCount > 0 and 20 or 0) + (favoriteCount > 0 and 20 or 0) + 6));
        self.otherGroupText:Show();
    else
        self.otherGroupText:Hide();
    end

    -- set scroll height (player names are computed lazily in RefreshRows)
    local headerHeight = (bucketCount > 0 and 20 or 0) + (favoriteCount > 0 and 20 or 0) + (specialCount > 0 and 20 or 0);
    self.scrollChild:SetHeight(#self.skills * 20 + headerHeight);

    -- force refresh since data changed
    self.lastStartIndex = nil;
    self.lastEndIndex = nil;
    self.forceRefresh = true;
    self:RefreshRows();
end

--- Add filtered skills.
-- @param professionId Profession ID to filter.
-- @param addonId Addon ID to filter (nil for all).
-- @param searchParts Search parts for filtering.
function GuildSkillList:AddFilteredSkills(professionId, addonId, searchParts)
    local skillsService = self:GetService("skills");
    local professionQueryService = self:GetService("profession-query");
    local playerService = self:GetService("player");

    -- get profession data from skill index
    local profession = professionQueryService.skillIndex[professionId];
    if (not profession) then
        return;
    end

    -- filter and insert skills (skip entries without any visible player)
    for skillId, players in pairs(profession) do
        if (#players > 0 and professionQueryService:HasVisibleSkillPlayers(professionId, skillId, players)) then
            local skillData = skillsService:GetSkillById(skillId);
            if (skillData and skillData.name ~= nil) then
                if (addonId == nil or self:MatchesAddon(skillData, addonId)) then
                    if (self:MatchesCategory(skillData, professionId)) then
                        local bucketListAmount = PM_BucketList[skillId];

                        -- favorites group only holds items not already on the shopping list
                        local isFavorite = (not bucketListAmount) and playerService.node.guildFavorites[skillId] ~= nil;

                        -- lowercase the name once instead of per search part
                        local skillValid = true;
                        if (#searchParts > 0) then
                            local lowerName = string.lower(skillData.name);
                            for _, part in ipairs(searchParts) do
                                if (string.len(part) > 0 and string.find(lowerName, part) == nil) then
                                    skillValid = false;
                                    break;
                                end
                            end
                        end

                        if (skillValid) then
                            table.insert(self.skills, {
                                professionId = professionId,
                                skillId = skillId,
                                skill = skillData,
                                players = players,
                                bucketListAmount = bucketListAmount,
                                isFavorite = isFavorite
                            });
                            if (bucketListAmount) then
                                self.bucketListSkillAmount = self.bucketListSkillAmount + 1;
                            elseif (isFavorite) then
                                self.favoriteSkillAmount = self.favoriteSkillAmount + 1;
                            end
                        end
                    end
                end
            end
        end
    end
end

--- Refresh specialization rows above the item list.
function GuildSkillList:RefreshSpecializationRows()
    if (not self.specArea) then return; end

    -- hide all existing spec rows
    for _, row in ipairs(self.specRowPool) do
        row:Hide();
    end

    -- specializations are shown in the dedicated specializations tab
    self.specArea:Hide();
    self:UpdateItemAreaPosition(0);
end

--- Update the item area position based on specialization area height.
-- @param specHeight Height of the specialization area.
function GuildSkillList:UpdateItemAreaPosition(specHeight)
    if (not self.skillText) then return; end
    local offset = specHeight > 0 and (specHeight + 4) or 0;
    local skillTextTop = self.skillTextDefaultTop - offset;
    local playerHeaderTop = self.playerHeaderDefaultTop - offset;
    local scrollFrameTop = self.scrollFrameDefaultTop - offset;

    self.skillText:ClearAllPoints();
    self.skillText:SetPoint("TOPLEFT", 12, skillTextTop);

    self.playerHeaderText:ClearAllPoints();
    self.playerHeaderText:SetPoint("TOPLEFT", 286, playerHeaderTop);

    self.bucketListIcon:ClearAllPoints();
    self.bucketListIcon:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", -56, skillTextTop - 2 + 4);

    self.scrollFrame:ClearAllPoints();
    self.scrollFrame:SetPoint("TOPLEFT", 6, scrollFrameTop);
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -8, 8);

    if (self.scrollChild and self.scrollFrame) then
        self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
    end
end

--- Resolve the trade board subject behind a skill row: the crafted item, or
--- the skill's spell when it creates none (e.g. enchants).
-- @return kind ("item"/"spell") and id, or nil for specialization rows.
function GuildSkillList:GetRequestSubject(skillId)
    if (type(skillId) ~= "number") then
        return nil;
    end
    local skillInfo = self:GetService("skills"):GetSkillById(skillId);
    local itemId = skillInfo and skillInfo.itemId;
    if (itemId and itemId ~= 0) then
        return "item", itemId;
    end
    return "spell", skillId;
end

--- Refresh rows.
function GuildSkillList:RefreshRows()
    -- get visible range based on actual scroll frame height
    local visibleRowCount = math.ceil((self.scrollFrame:GetHeight() or 400) / 20) + 6;
    local startIndex = math.max(math.floor(self.scrollTop / 20) - 3, 1);
    local endIndex = math.min(startIndex + visibleRowCount, #self.skills);
    local visibleCount = endIndex - startIndex + 1;

    -- skip re-render if visible window hasn't changed
    if (startIndex == self.lastStartIndex and endIndex == self.lastEndIndex and not self.forceRefresh) then
        return;
    end
    self.lastStartIndex = startIndex;
    self.lastEndIndex = endIndex;
    self.forceRefresh = nil;

    -- ensure pool has enough frames
    while (#self.rowPool < visibleCount) do
        local poolIndex = #self.rowPool + 1;
        local row = CreateFrame("Button", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
        row:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]]
        });

        -- add item text
        local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        itemText:SetPoint("TOPLEFT", 3, -3);
        itemText:SetWidth(270);
        itemText:SetWordWrap(false);
        itemText:SetJustifyH("LEFT");
        row.itemText = itemText;

        -- add player text
        local playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        playerText:SetPoint("TOPLEFT", 276, -4);
        playerText:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -26, -4);
        playerText:SetJustifyH("LEFT");
        playerText:SetJustifyV("TOP");
        playerText:SetTextColor(1, 1, 1);
        row.playerText = playerText;

        -- add bucket list text
        local bucketListText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        bucketListText:SetPoint("TOPLEFT", row, "TOPRIGHT", -27, -4);
        bucketListText:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, -4);
        bucketListText:SetJustifyH("CENTER");
        bucketListText:SetJustifyV("TOP");
        row.bucketListText = bucketListText;

        -- add favorite toggle (talisman adds; overlaid red the click removes;
        -- shown while the row is hovered, right aligned in the item column;
        -- icon size matches the request letter next to it)
        local favoriteButton = CreateFrame("Button", nil, row);
        favoriteButton:SetSize(20, 20);
        local favoriteStar = favoriteButton:CreateTexture(nil, "OVERLAY");
        favoriteStar:SetSize(16, 16);
        favoriteStar:SetPoint("CENTER", 0, 0);
        favoriteStar:SetTexture("Interface\\Icons\\INV_Jewelry_Talisman_08");
        favoriteButton.star = favoriteStar;
        favoriteButton:Hide();
        row.favoriteButton = favoriteButton;

        -- add request toggle (trade board): the letter icon opens the request
        -- dialog for the row's item; only with a TradeBoard version that has
        -- the request host API
        local requestButton;
        if (self.addon:IsTradeBoardCompatible()) then
            requestButton = CreateFrame("Button", nil, row);
            requestButton:SetSize(20, 20);
            local requestIcon = requestButton:CreateTexture(nil, "OVERLAY");
            requestIcon:SetSize(16, 16);
            requestIcon:SetPoint("CENTER", 0, 0);
            requestIcon:SetTexture("Interface\\Icons\\INV_Letter_12");
            requestButton.icon = requestIcon;
            requestButton:Hide();
            row.requestButton = requestButton;
        end

        -- update the hover icon states (red overlay = click removes) and show
        -- them while the row is hovered
        local function ShowHoverButtons()
            if (row.isSpecialization or not row.skillId) then return; end
            local favorites = self:GetService("player").node.guildFavorites;
            if (favorites[row.skillId]) then
                favoriteButton.star:SetVertexColor(1, 0.35, 0.35);
            else
                favoriteButton.star:SetVertexColor(1, 1, 1);
            end
            favoriteButton:Show();

            if (requestButton) then
                local requestKind = self:GetRequestSubject(row.skillId);
                requestButton:SetShown(requestKind ~= nil);
            end
        end

        -- open the request dialog for the row's item (an existing own request
        -- opens in edit mode to change or delete it)
        if (requestButton) then
            requestButton:SetScript("OnClick", function()
                local requestKind, requestId = self:GetRequestSubject(row.skillId);
                if (not requestKind) then return; end
                GameTooltip:Hide();
                _G.tradeBoard:OpenRequestDialog(requestKind, requestId);

                -- reset the hover state: the dialog may open right under the
                -- mouse, then the row never receives a leave event
                favoriteButton:Hide();
                requestButton:Hide();
                if (row.bgColor) then
                    row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
                end
                if (row.hoverGlowHide) then row.hoverGlowHide(); end
            end);
            requestButton:SetScript("OnEnter", function()
                row:SetBackdropColor(0.2, 0.2, 0.2);
                ShowHoverButtons();
                local requestKind, requestId = self:GetRequestSubject(row.skillId);
                local tooltipKey = (requestKind and _G.tradeBoard:HasOwnRequest(requestKind, requestId))
                    and "TradeBoardEditRequest" or "TradeBoardRequestItem";
                GameTooltip:SetOwner(requestButton, "ANCHOR_RIGHT");
                GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
                GameTooltip:Show();
            end);
            requestButton:SetScript("OnLeave", function()
                GameTooltip:Hide();
                if (row:IsMouseOver()) then return; end
                favoriteButton:Hide();
                requestButton:Hide();
                if (row.bgColor) then
                    row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
                end
            end);
        end

        -- toggle favorite state and re-render the list
        favoriteButton:SetScript("OnClick", function()
            if (row.isSpecialization or not row.skillId) then return; end
            local favorites = self:GetService("player").node.guildFavorites;
            if (favorites[row.skillId]) then
                favorites[row.skillId] = nil;
                self.addon:Log("GuildSkillList", "ToggleFavorite", "Removed skill %s from guild favorites", tostring(row.skillId));
            else
                favorites[row.skillId] = true;
                self.addon:Log("GuildSkillList", "ToggleFavorite", "Added skill %s to guild favorites", tostring(row.skillId));
            end
            GameTooltip:Hide();
            self:AddSkills();
        end);
        favoriteButton:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            local favorites = self:GetService("player").node.guildFavorites;
            local tooltipKey = favorites[row.skillId] and "ProfessionsViewRemoveFromFavorites" or "ProfessionsViewAddToFavorites";
            GameTooltip:SetOwner(favoriteButton, "ANCHOR_RIGHT");
            GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
            GameTooltip:Show();
        end);
        favoriteButton:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            favoriteButton:Hide();
            if (requestButton) then requestButton:Hide(); end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
        end);

        -- bind row mouse event (highlight only; tooltips are per column, see below)
        row:SetScript("OnLeave", function()
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
            if (requestButton) then requestButton:Hide(); end
            GameTooltip:Hide();
        end);
        row:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowHoverButtons();
        end);

        -- handle row mouse click (shared by the row and its column hover regions)
        local function onRowMouseDown(_, button)
            if (button == "LeftButton") and IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow() then
                if (IsControlKeyDown()) then
                    if (self.professionsView.addon.isBccAtLeast and row.skill.skillLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.skillLink);
                    elseif (row.skillId) then
                        local professionName = self:GetService("profession-names"):GetProfessionName(row.professionId);
                        local spellName = self.addon.compat.GetSpellInfo(row.skillId) or row.skill.name;
                        if (spellName) then
                            local linkText = professionName and (professionName .. ": " .. spellName) or spellName;
                            local editbox = GetCurrentKeyBoardFocus();
                            if (editbox) then
                                editbox:Insert("[PM: " .. linkText .. " : " .. row.skillId .. "]");
                            end
                        end
                    end
                else
                    if (row.skill.itemLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.itemLink);
                    elseif (self.professionsView.addon.isBccAtLeast and row.skill.skillLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.skillLink);
                    elseif (row.skillId) then
                        local professionName = self:GetService("profession-names"):GetProfessionName(row.professionId);
                        local spellName = self.addon.compat.GetSpellInfo(row.skillId) or row.skill.name;
                        if (spellName) then
                            local linkText = professionName and (professionName .. ": " .. spellName) or spellName;
                            local editbox = GetCurrentKeyBoardFocus();
                            if (editbox) then
                                editbox:Insert("[PM: " .. linkText .. " : " .. row.skillId .. "]");
                            end
                        end
                    end
                end
            elseif (button == "LeftButton") then
                if (row.isSpecialization) then
                    self.professionsView:ShowSpecView({
                        name = row.skill.name,
                        players = row.skill.players,
                        icon = row.skill.icon,
                        professionId = row.professionId,
                    });
                else
                    self.professionsView:ShowSkillView(row);
                end
            end
        end
        row:SetScript("OnMouseDown", onRowMouseDown);

        -- item hover region (first column): shows the skill tooltip
        local itemHover = CreateFrame("Frame", nil, row);
        itemHover:SetPoint("TOPLEFT", 0, 0);
        itemHover:SetPoint("BOTTOMLEFT", 0, 0);
        itemHover:SetWidth(276);
        itemHover:EnableMouse(true);
        itemHover:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowHoverButtons();
            -- tooltip hangs with its top-right corner at the column's top-left
            GameTooltip:SetOwner(itemHover, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", itemHover, "TOPLEFT", -2, 0);
            self:GetService("tooltip"):ShowTooltip(GameTooltip, row.professionId, row.skillId, row.skill, row.players);
        end);
        itemHover:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
            if (requestButton) then requestButton:Hide(); end
        end);
        itemHover:SetScript("OnMouseDown", onRowMouseDown);
        row.itemHover = itemHover;

        -- right-align the hover icons at the end of the item column (request
        -- toggle outermost with some clearance to the player column, favorite
        -- talisman tight next to it) and keep them clickable above the item
        -- hover region
        if (requestButton) then
            requestButton:SetPoint("RIGHT", row, "LEFT", 268, 0);
            requestButton:SetFrameLevel(itemHover:GetFrameLevel() + 1);
            favoriteButton:SetPoint("RIGHT", requestButton, "LEFT", 0, 0);
        else
            favoriteButton:SetPoint("RIGHT", row, "LEFT", 268, 0);
        end
        favoriteButton:SetFrameLevel(itemHover:GetFrameLevel() + 1);

        -- player hover region (names column): popup with all players, comma
        -- separated and never truncated
        local playerHover = CreateFrame("Frame", nil, row);
        playerHover:SetPoint("TOPLEFT", 276, 0);
        playerHover:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -27, 0);
        playerHover:EnableMouse(true);
        playerHover:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowHoverButtons();
            if (row.players and #row.players > 0) then
                local playerService = self:GetService("player");
                local names = playerService:CombinePlayerNames(row.players, nil, row.professionId, row.skillId);
                -- tooltip hangs below the row with its top-right corner at the
                -- player label's bottom-left
                GameTooltip:SetOwner(playerHover, "ANCHOR_NONE");
                GameTooltip:ClearAllPoints();
                GameTooltip:SetPoint("TOPRIGHT", row.playerText, "BOTTOMLEFT", 0, 2);
                GameTooltip:ClearLines();
                GameTooltip:AddLine(self:GetService("locale"):Get("ProfessionsViewPlayers"), 1, 0.82, 0);
                GameTooltip:AddLine(table.concat(names, ", "), 1, 1, 1, true);
                GameTooltip:Show();
            end
        end);
        playerHover:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
            if (requestButton) then requestButton:Hide(); end
        end);
        playerHover:SetScript("OnMouseDown", onRowMouseDown);
        row.playerHover = playerHover;

        -- purple hover glow (border + purple backdrop), kept alive by the column regions
        local glowRegions = { itemHover, playerHover, favoriteButton };
        if (requestButton) then table.insert(glowRegions, requestButton); end
        self:GetService("ui"):AttachHoverGlow(row, glowRegions);

        self.rowPool[poolIndex] = row;
    end

    -- hide all pooled frames first
    for _, row in ipairs(self.rowPool) do
        row:Hide();
    end

    -- hide all group header labels
    for _, label in ipairs(self.groupHeaderPool) do
        label:Hide();
    end
    local groupHeaderIndex = 0;

    -- services and flags used by every bound row, resolved once per pass
    local uiService = self:GetService("ui");
    local playerService = self:GetService("player");
    local tradeBoardEnabled = self.addon:IsTradeBoardCompatible();
    local requestedText = tradeBoardEnabled and ("|r |cff44cc44(" .. self:GetService("locale"):Get("TradeBoardRequested") .. ")|r") or nil;

    -- bind pool frames to visible data
    local poolUsed = 0;
    for i = 0, visibleCount - 1 do
        local rowIndex = startIndex + i;
        local skillData = self.skills[rowIndex];

        -- calculate top position (each visible group header above adds 20)
        local top = (rowIndex - 1) * 20;
        if (self.bucketListSkillAmount > 0 or self.favoriteSkillAmount > 0) then
            if (skillData.bucketListAmount) then
                top = top + 20;
            elseif (skillData.isFavorite) then
                top = top + 20 + (self.bucketListSkillAmount > 0 and 20 or 0);
            else
                top = top + 20 + (self.bucketListSkillAmount > 0 and 20 or 0) + (self.favoriteSkillAmount > 0 and 20 or 0);
            end
        end

        -- check if this is a group header
        if (skillData.isGroupHeader) then
            groupHeaderIndex = groupHeaderIndex + 1;
            if (not self.groupHeaderPool[groupHeaderIndex]) then
                local label = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                label:SetFont("Fonts\\FRIZQT__.TTF", 10);
                self.groupHeaderPool[groupHeaderIndex] = label;
            end
            local label = self.groupHeaderPool[groupHeaderIndex];
            label:ClearAllPoints();
            label:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, -(top + 6));
            label:SetText(skillData.groupName);
            label:Show();
        else
            poolUsed = poolUsed + 1;
            local row = self.rowPool[poolUsed];
            if (not row) then break; end

            local professionId = skillData.professionId;
            local skillId = skillData.skillId;
            local skill = skillData.skill;
            local bucketListAmount = skillData.bucketListAmount;

            -- set background color by data index
            uiService:SetRowColor(row, rowIndex);

            row:ClearAllPoints();
            row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -top);
            row:SetPoint("BOTTOMRIGHT", self.scrollChild, "TOPRIGHT", -28, -(top + 20));

            -- set item text (skill is already the skill data of this row)
            local itemName = skill.itemColor and ("|c" .. skill.itemColor .. skill.name) or skill.name;
            local itemAmount = skill.itemAmount;
            if (itemAmount and itemAmount > 1) then
                itemName = itemName .. "|r x" .. itemAmount;
            end

            -- own trade board request marker behind the name
            if (tradeBoardEnabled) then
                local requestKind, requestId = self:GetRequestSubject(skillId);
                if (requestKind and _G.tradeBoard:HasOwnRequest(requestKind, requestId)) then
                    itemName = itemName .. requestedText;
                end
            end
            row.itemText:SetText("|T" .. skill.icon .. ":16|t  " .. itemName);

            -- the skill tooltip only shows over the icon and name, not the whole column
            row.itemHover:SetWidth(math.max(24, math.min(276, row.itemText:GetStringWidth() + 8)));

            -- hover icons stay hidden until the row is hovered
            row.favoriteButton:Hide();
            if (row.requestButton) then row.requestButton:Hide(); end

            -- set player text (compute lazily on first display)
            if (self.hidePlayerColumn) then
                row.playerText:Hide();
                row.playerHover:Hide();
            else
                row.playerText:Show();
                row.playerHover:Show();

                -- compute player names on demand and cache result
                if (not skillData.playerNamesText) then
                    local players = skillData.players or (skill and skill.players);
                    if (players) then
                        skillData.playerNamesText = table.concat(playerService:CombinePlayerNames(players, 12, skillData.professionId, skillData.skillId), ", ");
                    else
                        skillData.playerNamesText = "";
                    end
                end
                row.playerText:SetText(skillData.playerNamesText);
            end

            -- set bucket list text
            row.bucketListText:SetText(bucketListAmount);

            -- store data on row
            row.professionId = professionId;
            row.skill = skill;
            row.skillId = skillId;
            row.players = skillData.players or (skill and skill.players);
            row.isSpecialization = skillData.isSpecialization;

            -- show
            row:Show();
        end
    end
end
