--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel
local OwnSkillList = _G.professionMaster:CreateView("own-skill-list");

-- max skill levels per addon per profession
local MAX_SKILL_LEVELS = {
    -- default (most professions)
    default = { [1] = 300, [2] = 375, [3] = 450, [4] = 525, [5] = 600 },
};

-- skill ranks marked on the progress bar: the rank starts at the given level
-- (apprentice starts at 0 and has no tick), ticks above the max level of the
-- running client are not shown
local SkillRankMarks = {
    { level = 75, key = "ProfessionsViewRankJourneyman" },
    { level = 150, key = "ProfessionsViewRankExpert" },
    { level = 225, key = "ProfessionsViewRankArtisan" },
    { level = 300, key = "ProfessionsViewRankMaster" },
    { level = 375, key = "ProfessionsViewRankGrandMaster" },
    { level = 450, key = "ProfessionsViewRankIllustriousGrandMaster" },
    { level = 525, key = "ProfessionsViewRankZenMaster" },
};

-- difficulty filter bounds as indices into the skill difficulty table: { lower (inclusive), upper (exclusive) }
local DifficultyFilterBounds = {
    ["red"] = { nil, 1 },
    ["orange"] = { 1, 2 },
    ["orange-yellow"] = { 1, 3 },
    ["orange-yellow-green"] = { 1, 4 },
    ["orange-yellow-green-grey"] = { 1, nil },
    ["yellow"] = { 2, 3 },
    ["green"] = { 3, 4 },
    ["grey"] = { 4, nil },
};

-- vertical layout below the filter rows. The filter rows put a label 16px
-- above its control and 8px under the control above (row 1: labels -12,
-- controls -28; row 2: labels -58, controls -74). Flat keeps its offsets;
-- forever adds a "Progress" label above the bar as a third row of that
-- grid, the column headers follow 8px under the bar (or take the place of
-- the label row while the bar is hidden)
local FlatLayout = { barTop = -104, headerTop = -136, headerTopNoBar = -104 };
local ForeverLayout = { progressLabelTop = -104, barTop = -120, headerTop = -152, headerTopNoBar = -104 };

-- widths of the filter row below the profession row (see LayoutFilterRow)
local ModeFilterWidth = 100;
local MaxLevelFilterWidth = 72;
local DifficultyFilterWidth = 160;
local CategoryFilterWidth = 150;

--- Get max skill level for a profession and addon.
local function GetMaxSkillLevel(professionId, addonId)
    if (not addonId) then
        return 300;
    end
    local levels = MAX_SKILL_LEVELS[professionId] or MAX_SKILL_LEVELS.default;
    return levels[addonId] or 300;
end

--- Get the addon ID of the currently running game client.
function OwnSkillList:GetCurrentAddonId()
    local addon = self.professionsView.addon;
    if (addon.isMop) then return 5; end
    if (addon.isCata) then return 4; end
    if (addon.isWrath) then return 3; end
    if (addon.isBcc) then return 2; end
    return 1;
end

--- Create own skill list panel.
-- @param parentFrame The parent frame.
-- @param professionsView Reference to the parent professions view.
function OwnSkillList:Create(parentFrame, professionsView)
    self.professionsView = professionsView;
    self.rowPool = {};
    self.groupHeaderPool = {};
    self.skills = {};
    self.professionId = PM_CharacterSettings.lastOwnProfession or 0;
    self.addonId = PM_CharacterSettings.lastOwnAddon;
    self.categoryId = PM_CharacterSettings.lastOwnCategory;
    self.subcategoryId = PM_CharacterSettings.lastOwnSubcategory;
    self.modeId = PM_CharacterSettings.lastOwnMode or "known";
    self.difficultyFilterId = PM_CharacterSettings.lastOwnDifficultyFilter;

    -- max skill filter, nil shows everything (max level of the client)
    self.maxLevelFilter = PM_CharacterSettings.lastOwnMaxLevel;
    if (self.maxLevelFilter and self.maxLevelFilter >= self:GetService("leveling-planner"):GetMaxLevel()) then
        self.maxLevelFilter = nil;
    end
    self.sortColumn = PM_CharacterSettings.lastOwnSortColumn or "leveling";
    self.sortAscending = PM_CharacterSettings.lastOwnSortAscending;
    if (self.sortAscending == nil) then self.sortAscending = false; end
    self.scrollTop = 0;
    self.bucketListSkillAmount = 0;
    self.favoriteSkillAmount = 0;

    -- initialize selected character to current player
    local playerService = self:GetService("player");
    self.selectedCharacter = playerService.current;

    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local addon = professionsView.addon;

    -- add frame
    local frame = CreateFrame("Frame", nil, parentFrame);
    frame:SetPoint("TOPLEFT", 0, 0);
    frame:SetPoint("BOTTOMRIGHT", 0, 0);
    self.frame = frame;

    -- add character dropdown
    local characterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    characterLabel:SetPoint("TOPLEFT", 12, -12);
    characterLabel:SetText(localeService:Get("ProfessionsViewCharacter"));
    self.characterLabel = characterLabel;

    local characterSelection = uiService:CreateDropdown(frame, 160, {}, function(value)
        self.selectedCharacter = value;
        self.professionId = 0;
        PM_CharacterSettings.lastOwnProfession = 0;
        self:RefreshAddonItems();
        self:RefreshCategoryItems();
        self:SelectCategory(nil);
        self:RefreshProgressBar();
        self:AddSkills();
    end);
    characterSelection:SetPoint("TOPLEFT", 12, -28);
    self.characterSelection = characterSelection;

    -- add profession dropdown
    local professionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    professionLabel:SetPoint("TOPLEFT", 180, -12);
    professionLabel:SetText(localeService:Get("ProfessionsViewProfession"));
    self.professionLabel = professionLabel;

    local professionSelection = uiService:CreateDropdown(frame, 160, {}, function(value)
        self.professionId = value;

        -- debug only professions are not remembered for the next session
        if (self:IsDebugProfession(value)) then
            self.addon:Log("OwnSkillList", "SelectProfession", "Selected debug only profession %s", tostring(value));
        else
            PM_CharacterSettings.lastOwnProfession = value;
        end
        self:RefreshAddonItems();
        self:RefreshCategoryItems();
        self:SelectCategory(nil);
        self:RefreshProgressBar();
        self.searchBox:SetFocus();
        self:AddSkills();
    end);
    professionSelection:SetPoint("TOPLEFT", 180, -28);
    self.professionSelection = professionSelection;

    -- add search box
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    searchLabel:SetPoint("TOPLEFT", 348, -12);
    searchLabel:SetText(localeService:Get("ProfessionsViewSearch"));
    self.searchLabel = searchLabel;

    local searchContainer = uiService:CreateEditBox(frame, 100);
    searchContainer:SetPoint("TOPLEFT", 348, -28);
    if (addon.hasExpansion) then
        searchContainer:SetPoint("RIGHT", frame, "RIGHT", -150, 0);
    else
        searchContainer:SetPoint("RIGHT", frame, "RIGHT", -12, 0);
    end
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
            PM_CharacterSettings.lastOwnSearchText = self.searchBox:GetText();
            self:AddSkills();
        end);
    end);
    searchBox:SetScript("OnKeyDown", function(_, key)
        if (key == "ESCAPE") then
            professionsView:Hide();
        elseif (key == "ENTER") then
            self.addon.compat.ChatFrame_OpenChat("", nil, nil);
        end
    end);

    -- add addon dropdown
    if (addon.hasExpansion) then
        local addonLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        addonLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -140, -12);
        addonLabel:SetText(localeService:Get("ProfessionsViewAddon"));
        self.addonLabel = addonLabel;

        local addonItems = self:BuildAddonItems();
        local addonSelection = uiService:CreateDropdown(frame, 130, addonItems, function(value)
            self:SelectAddon(value);
            self:RefreshProgressBar();
            self.searchBox:SetFocus();
            self:AddSkills();
        end);
        addonSelection:SetPoint("TOPLEFT", frame, "TOPRIGHT", -142, -28);
        self.addonSelection = addonSelection;

        -- set initial addon value
        if (self.addonId) then
            addonSelection:SetValue(self.addonId);
        end
    else
        -- vanilla without SoD: lock to vanilla addon
        self.addonId = 1;
    end

    -- add mode filter dropdown
    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    modeLabel:SetPoint("TOPLEFT", 12, -58);
    modeLabel:SetText(localeService:Get("ProfessionsViewMode"));
    self.modeLabel = modeLabel;
    local modeSelection = uiService:CreateDropdown(frame, ModeFilterWidth, {
        { value = "known", text = localeService:Get("ProfessionsViewModeKnown") },
        { value = "unknown", text = localeService:Get("ProfessionsViewModeUnknown") },
        { value = "all", text = localeService:Get("ProfessionsViewModeAll") },
    }, function(value)
        self.modeId = value;
        PM_CharacterSettings.lastOwnMode = value;
        self:AddSkills();
    end);
    modeSelection:SetPoint("TOPLEFT", 12, -74);
    self.modeSelection = modeSelection;

    -- add max skill filter dropdown (the recipes up to a rank cap)
    local maxLevelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    maxLevelLabel:SetPoint("TOPLEFT", 120, -58);
    maxLevelLabel:SetText(localeService:Get("ProfessionsViewMaxLevel"));
    self.maxLevelLabel = maxLevelLabel;
    local maxLevelSelection = uiService:CreateDropdown(frame, MaxLevelFilterWidth, self:BuildMaxLevelItems(), function(value)
        self.maxLevelFilter = value;
        PM_CharacterSettings.lastOwnMaxLevel = value;
        self:AddSkills();
    end);
    maxLevelSelection:SetPoint("TOPLEFT", 120, -74);
    self.maxLevelSelection = maxLevelSelection;

    -- add difficulty filter dropdown
    local difficultyFilterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    difficultyFilterLabel:SetPoint("TOPLEFT", 200, -58);
    difficultyFilterLabel:SetText(localeService:Get("ProfessionsViewDifficulty"));
    self.difficultyFilterLabel = difficultyFilterLabel;

    -- colored difficulty names, combined ranges are shown as "first - last" to keep the texts short
    local difficultyNames = {
        red = "|cffff4040" .. localeService:Get("ProfessionsViewDifficultyRed") .. "|r",
        orange = "|cffff8040" .. localeService:Get("ProfessionsViewDifficultyOrange") .. "|r",
        yellow = "|cffffff00" .. localeService:Get("ProfessionsViewDifficultyYellow") .. "|r",
        green = "|cff40c040" .. localeService:Get("ProfessionsViewDifficultyGreen") .. "|r",
        grey = "|cffaaaaaa" .. localeService:Get("ProfessionsViewDifficultyGrey") .. "|r",
    };
    local function DifficultyRange(from, to)
        return difficultyNames[from] .. " - " .. difficultyNames[to];
    end
    local difficultyFilterSelection = uiService:CreateDropdown(frame, DifficultyFilterWidth, {
        { value = nil, text = localeService:Get("ProfessionsViewDifficultyAll") },
        { value = "red", text = difficultyNames.red },
        { value = "orange", text = difficultyNames.orange },
        { value = "orange-yellow", text = DifficultyRange("orange", "yellow") },
        { value = "orange-yellow-green", text = DifficultyRange("orange", "green") },
        { value = "orange-yellow-green-grey", text = DifficultyRange("orange", "grey") },
        { value = "yellow", text = difficultyNames.yellow },
        { value = "green", text = difficultyNames.green },
        { value = "grey", text = difficultyNames.grey },
    }, function(value)
        self.difficultyFilterId = value;
        PM_CharacterSettings.lastOwnDifficultyFilter = value;
        self:AddSkills();
    end);
    difficultyFilterSelection:SetPoint("TOPLEFT", 200, -74);
    self.difficultyFilterSelection = difficultyFilterSelection;

    -- add category filter dropdown
    local categoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    categoryLabel:SetPoint("TOPLEFT", 368, -58);
    categoryLabel:SetText(localeService:Get("ProfessionsViewCategory"));
    self.categoryLabel = categoryLabel;
    local categorySelection = uiService:CreateDropdown(frame, CategoryFilterWidth, {
        { value = nil, text = localeService:Get("ProfessionsViewCategoryAll") }
    }, function(value)
        self:SelectCategory(value);
        self:AddSkills();
    end);
    categorySelection:SetPoint("TOPLEFT", 368, -74);
    self.categorySelection = categorySelection;

    -- add subcategory filter dropdown
    local subcategoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    subcategoryLabel:SetPoint("TOPLEFT", 526, -58);
    subcategoryLabel:SetText(localeService:Get("ProfessionsViewSubcategory"));
    self.subcategoryLabel = subcategoryLabel;
    local subcategorySelection = uiService:CreateDropdown(frame, CategoryFilterWidth, {
        { value = nil, text = localeService:Get("ProfessionsViewSubcategoryAll") }
    }, function(value)
        self:SelectSubcategory(value);
        self:AddSkills();
    end);
    subcategorySelection:SetPoint("TOPLEFT", 526, -74);
    self.subcategorySelection = subcategorySelection;
    self.showSubcategory = false;
    subcategoryLabel:Hide();
    subcategorySelection:Hide();

    -- vertical layout below the filter rows (forever: "Progress" label above
    -- the bar on the grid of the filter rows)
    self.layout = uiService:IsForever() and ForeverLayout or FlatLayout;

    -- add progress bar
    local progressBarFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
    progressBarFrame:SetPoint("TOPLEFT", 12, self.layout.barTop);
    progressBarFrame:SetPoint("RIGHT", frame, "RIGHT", -12, 0);
    progressBarFrame:SetHeight(24);
    progressBarFrame:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });
    progressBarFrame:SetBackdropColor(0.15, 0.15, 0.15, 1);
    progressBarFrame:Hide();
    self.progressBarFrame = progressBarFrame;

    -- forever style: cast bar look (input field rim, black inside); the fill
    -- and the rank marks keep the returned inset away from the edges
    self.progressBarInset = uiService:IsForever() and uiService:StyleForeverBar(progressBarFrame) or 0;

    -- forever style: "Progress" label above the bar on the grid of the filter
    -- rows; a region of the bar, so it shows and hides together with it
    if (uiService:IsForever()) then
        local progressLabel = progressBarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        progressLabel:SetPoint("TOPLEFT", progressBarFrame, "TOPLEFT", 0, ForeverLayout.progressLabelTop - ForeverLayout.barTop);
        progressLabel:SetText(localeService:Get("ProfessionsViewProgress"));
        self.progressLabel = progressLabel;
    end

    -- fill: the classic style shows the darker green of the reputation bars on
    -- the status bar texture and reaches one pixel further down into the dark
    -- inside of the field; the flat style keeps its plain green
    local forever = uiService:IsForever();
    local progressBarFill = CreateFrame("Frame", nil, progressBarFrame, BackdropTemplateMixin and "BackdropTemplate");
    progressBarFill:SetPoint("TOPLEFT", self.progressBarInset, -2);
    progressBarFill:SetPoint("BOTTOMLEFT", self.progressBarInset, forever and 1 or 2);
    progressBarFill:SetWidth(1);
    if (forever) then
        progressBarFill:SetBackdrop({ bgFile = [[Interface\TargetingFrame\UI-StatusBar]] });
        progressBarFill:SetBackdropColor(0, 0.6, 0.1, 1);
    else
        progressBarFill:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });
        progressBarFill:SetBackdropColor(0.1, 0.7, 0.1, 1);
    end
    self.progressBarFill = progressBarFill;

    local progressBarTextFrame = CreateFrame("Frame", nil, progressBarFrame);
    progressBarTextFrame:SetAllPoints(progressBarFrame);
    progressBarTextFrame:SetFrameLevel(progressBarFill:GetFrameLevel() + 2);
    -- level text sits on the left inside the apprentice range, the rank marks
    -- fill the rest of the bar
    local progressBarText = progressBarTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    progressBarText:SetPoint("LEFT", progressBarFrame, "LEFT", 6, 0);
    progressBarText:SetTextColor(1, 1, 1, 1);
    self.progressBarText = progressBarText;
    self.progressBarTextFrame = progressBarTextFrame;
    self.progressBarMarks = {};

    -- leveling planner button right of the progress bar (the bar makes room
    -- for it). A child of the bar, so it hides with it wherever the bar is
    -- hidden (max level, no level known) and never ends up over the list
    local plannerButton = uiService:CreateFlatButton(progressBarFrame, localeService:Get("LevelingPlannerButton"), function()
        self:OpenLevelingPlanner();
    end);
    local plannerLabel = plannerButton:GetFontString();
    plannerButton:SetSize(math.max(110, (plannerLabel and plannerLabel:GetStringWidth() or 0) + 28), 24);
    plannerButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, self.layout.barTop);
    plannerButton:Hide();
    self.plannerButton = plannerButton;

    -- add skill header (clickable); the header texts hang at the top of their
    -- 16px buttons so all four column headers share the top line of the
    -- plain source header
    local skillHeaderButton = CreateFrame("Button", nil, frame);
    skillHeaderButton:SetPoint("TOPLEFT", 12, self:GetHeaderTop(false));
    skillHeaderButton:SetHeight(16);
    local skillText = skillHeaderButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    skillText:SetPoint("TOPLEFT", 0, 0);
    self.skillText = skillText;
    self.skillHeaderButton = skillHeaderButton;
    skillHeaderButton:SetScript("OnEnter", function()
        skillText:SetTextColor(1, 0.6, 0, 1);
    end);
    skillHeaderButton:SetScript("OnLeave", function()
        skillText:SetTextColor(1, 0.82, 0, 1);
    end);
    skillHeaderButton:SetScript("OnClick", function()
        if (self.sortColumn == "item") then
            self.sortAscending = not self.sortAscending;
        else
            self.sortColumn = "item";
            self.sortAscending = true;
        end
        PM_CharacterSettings.lastOwnSortColumn = self.sortColumn;
        PM_CharacterSettings.lastOwnSortAscending = self.sortAscending;
        self:AddSkills();
    end);

    -- add difficulty header (clickable)
    local levelingHeaderButton = CreateFrame("Button", nil, frame);
    levelingHeaderButton:SetPoint("TOPLEFT", 271, self:GetHeaderTop(false));
    levelingHeaderButton:SetHeight(16);
    local levelingText = levelingHeaderButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    levelingText:SetPoint("TOPLEFT", 0, 0);
    levelingText:SetText(localeService:Get("ProfessionsViewLeveling"));
    self.levelingText = levelingText;
    self.levelingHeaderButton = levelingHeaderButton;
    levelingHeaderButton:SetScript("OnEnter", function()
        levelingText:SetTextColor(1, 0.6, 0, 1);
    end);
    levelingHeaderButton:SetScript("OnLeave", function()
        levelingText:SetTextColor(1, 0.82, 0, 1);
    end);
    levelingHeaderButton:SetScript("OnClick", function()
        if (self.isMaxLevel) then return; end
        if (self.sortColumn == "leveling") then
            self.sortAscending = not self.sortAscending;
        else
            self.sortColumn = "leveling";
            self.sortAscending = false;
        end
        PM_CharacterSettings.lastOwnSortColumn = self.sortColumn;
        PM_CharacterSettings.lastOwnSortAscending = self.sortAscending;
        self:AddSkills();
    end);

    -- add profit header (clickable)
    local profitHeaderButton = CreateFrame("Button", nil, frame);
    profitHeaderButton:SetPoint("TOPLEFT", 341, self:GetHeaderTop(false));
    profitHeaderButton:SetHeight(16);
    local profitText = profitHeaderButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    profitText:SetPoint("TOPLEFT", 0, 0);
    profitText:SetText(localeService:Get("ProfessionsViewProfit"));
    self.profitHeaderText = profitText;
    self.profitHeaderButton = profitHeaderButton;
    profitHeaderButton:SetScript("OnEnter", function()
        profitText:SetTextColor(1, 0.6, 0, 1);
    end);
    profitHeaderButton:SetScript("OnLeave", function()
        profitText:SetTextColor(1, 0.82, 0, 1);
    end);
    profitHeaderButton:SetScript("OnClick", function()
        if (self.sortColumn == "profit") then
            self.sortAscending = not self.sortAscending;
        else
            self.sortColumn = "profit";
            self.sortAscending = false;
        end
        PM_CharacterSettings.lastOwnSortColumn = self.sortColumn;
        PM_CharacterSettings.lastOwnSortAscending = self.sortAscending;
        self:AddSkills();
    end);

    -- add recipe header
    local recipeHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    recipeHeaderText:SetPoint("TOPLEFT", 410, self:GetHeaderTop(false));
    recipeHeaderText:SetText(localeService:Get("ProfessionsViewSource") or "Source");
    self.recipeHeaderText = recipeHeaderText;

    -- add bucket list header label
    local bucketListText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    bucketListText:SetPoint("TOPLEFT", frame, "TOPRIGHT", -30, self:GetHeaderTop(false) + 4);
    bucketListText:SetText("");
    self.bucketListHeader = bucketListText;

    -- create scroll frame
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(frame);
    scrollParent:SetPoint("TOPLEFT", 6, self:GetListTop(self:GetHeaderTop(false)));
    scrollParent:SetPoint("BOTTOMRIGHT", -8, 8);
    scrollChild:SetWidth(scrollParent:GetWidth());
    self.scrollFrame = scrollParent;
    self.scrollChild = scrollChild;
    self.scrollElement = scrollElement;

    -- forever style: the parchment background of the selected profession
    -- behind the list
    self.professionBackground = uiService:CreateForeverListBackground(scrollParent);
    self:UpdateProfessionBackground();

    scrollElement:SetScript("OnVerticalScroll", function(_, offset)
        self.scrollTop = offset;
        self:RefreshRows();
    end);

    scrollParent:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);

    -- add bucket list group text
    local bucketListGroupText = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    bucketListGroupText:SetPoint("TOPLEFT", 4, -6);
    bucketListGroupText:SetTextColor(1, 0.84, 0, 1);
    bucketListGroupText:SetText(localeService:Get("ProfessionsViewBucketList"));
    bucketListGroupText:Hide();
    self.bucketListGroupText = bucketListGroupText;

    -- add favorites group text
    local favoritesGroupText = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    favoritesGroupText:SetPoint("TOPLEFT", 4, -6);
    favoritesGroupText:SetTextColor(1, 0.84, 0, 1);
    favoritesGroupText:SetText(localeService:Get("ProfessionsViewFavorites"));
    favoritesGroupText:Hide();
    self.favoritesGroupText = favoritesGroupText;

    -- add other group text
    local otherGroupText = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    otherGroupText:SetPoint("TOPLEFT", 4, -26);
    otherGroupText:SetTextColor(1, 0.84, 0, 1);
    otherGroupText:SetText(localeService:Get("ProfessionsViewNotOnBucketList"));
    otherGroupText:Hide();
    self.otherGroupText = otherGroupText;

    -- restore search text
    if (PM_CharacterSettings.lastOwnSearchText and PM_CharacterSettings.lastOwnSearchText ~= "") then
        self.searchBox:SetText(PM_CharacterSettings.lastOwnSearchText);
    end

    -- restore mode, max skill and difficulty filter (the max level item has the value nil)
    modeSelection:SetValue(self.modeId);
    maxLevelSelection:SetValue(self.maxLevelFilter);
    if (self.difficultyFilterId) then
        difficultyFilterSelection:SetValue(self.difficultyFilterId);
    end

    -- add empty state message (centered)
    local emptyContainer = CreateFrame("Frame", nil, frame);
    emptyContainer:SetPoint("CENTER", frame, "CENTER", 0, 0);
    emptyContainer:SetSize(400, 60);
    emptyContainer:Hide();
    self.emptyMessage = emptyContainer;

    local emptyTitle = emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    emptyTitle:SetPoint("TOP", emptyContainer, "TOP", 0, 0);
    emptyTitle:SetJustifyH("CENTER");
    emptyTitle:SetTextColor(0.7, 0.7, 0.7, 1);
    emptyTitle:SetText(localeService:Get("OwnNoProfessionsTitle"));

    local emptyDescription = emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    emptyDescription:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -8);
    emptyDescription:SetWidth(400);
    emptyDescription:SetJustifyH("CENTER");
    emptyDescription:SetTextColor(0.5, 0.5, 0.5, 1);
    emptyDescription:SetText(localeService:Get("OwnNoProfessionsDescription"));
end

--- Check whether a profession is only listed for debugging (debug build, not learned by the character).
-- @param professionId The profession id.
-- @return true when the profession was added as debug only entry.
function OwnSkillList:IsDebugProfession(professionId)
    return self.debugProfessionIds ~= nil and self.debugProfessionIds[professionId] == true;
end

--- Build addon dropdown items.
function OwnSkillList:BuildAddonItems()
    return self:GetService("profession-names"):BuildAddonItems(true);
end

--- Refresh addon dropdown items based on the selected profession.
function OwnSkillList:RefreshAddonItems()
    if (not self.addonSelection) then
        return;
    end
    local items = self:BuildAddonItems();
    self.addonSelection:SetItems(items);

    -- validate current addon is still in the list
    local valid = false;
    for _, item in ipairs(items) do
        if (item.value == self.addonId) then
            valid = true;
            break;
        end
    end
    if (not valid and #items > 0) then
        self.addonId = items[#items].value;
        PM_CharacterSettings.lastOwnAddon = self.addonId;
    end
    self.addonSelection:SetValue(self.addonId);
end

--- Select addon.
function OwnSkillList:SelectAddon(addonId)
    self.addonId = addonId;
    PM_CharacterSettings.lastOwnAddon = addonId;
    if (self.addonSelection) then
        self.addonSelection:SetValue(addonId);
    end
    self:RefreshCategoryItems();
    self:SelectCategory(nil);
end

--- Select category filter.
function OwnSkillList:SelectCategory(categoryId)
    self.categoryId = categoryId;
    self.subcategoryId = nil;
    PM_CharacterSettings.lastOwnCategory = categoryId;
    PM_CharacterSettings.lastOwnSubcategory = nil;
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
function OwnSkillList:SelectSubcategory(subcategoryId)
    self.subcategoryId = subcategoryId;
    PM_CharacterSettings.lastOwnSubcategory = subcategoryId;
    if (not self.subcategorySelection) then
        return;
    end
    self.subcategorySelection:SetValue(subcategoryId);
end

--- Check if a skill matches the given addon filter.
function OwnSkillList:MatchesAddon(skillData, addonId)
    return self:GetService("category"):MatchesAddon(skillData, addonId);
end

--- Check if a skill matches the currently selected category and subcategory filters.
function OwnSkillList:MatchesCategory(skillData, professionId)
    return self:GetService("category"):MatchesCategory(skillData, professionId, self.categoryId, self.subcategoryId);
end

--- Check if a skill matches the difficulty filter.
-- @param skillData Skill data with difficulty table.
-- @param currentSkillLevel Current player skill level for this profession.
-- @return true if skill passes the filter.
function OwnSkillList:MatchesDifficultyFilter(skillData, currentSkillLevel)
    if (not self.difficultyFilterId or self.isMaxLevel) then
        return true;
    end

    local difficulty = skillData.difficulty;
    if (not difficulty) then
        return false;
    end

    -- resolve lower (inclusive) and upper (exclusive) skill level bounds of the filter
    local bounds = DifficultyFilterBounds[self.difficultyFilterId];
    if (not bounds) then
        return true;
    end
    local level = currentSkillLevel or 0;
    local lower = bounds[1] and (difficulty[bounds[1]] or 0);
    local upper = bounds[2] and (difficulty[bounds[2]] or 0);
    return (not lower or level >= lower) and (not upper or level < upper);
end

--- Build the items of the max skill filter: the skill caps of the trainer ranks
--- up to the max level of the client (75, 150, ...). The max level limits
--- nothing and has the value nil.
-- @return dropdown items.
function OwnSkillList:BuildMaxLevelItems()
    local caps = self:GetService("leveling-planner"):GetRankCaps();
    local items = {};
    for index, cap in ipairs(caps) do
        local value = cap;
        if (index == #caps) then
            value = nil;
        end
        table.insert(items, { value = value, text = tostring(cap) });
    end
    return items;
end

--- Check if a skill matches the max skill filter: the skill level the recipe
--- needs (orange) is at most the chosen cap. Skills without that level stay.
-- @param skillData Skill data with difficulty table.
-- @return true if skill passes the filter.
function OwnSkillList:MatchesMaxLevelFilter(skillData)
    if (not self.maxLevelFilter) then
        return true;
    end
    local difficulty = skillData.difficulty;
    return ((difficulty and difficulty[1]) or 0) <= self.maxLevelFilter;
end

--- Check whether a skill name contains every search part (case-insensitive).
--- Shared by the three list modes (known / all / unknown).
-- @param name Skill name to test.
-- @param searchParts Already lowercased search parts.
-- @return true if the name matches the search.
function OwnSkillList:MatchesSearch(name, searchParts)
    if (#searchParts == 0) then
        return true;
    end

    -- lowercase the name once instead of once per search part
    local lowerName = string.lower(name);
    for _, part in ipairs(searchParts) do
        if (string.len(part) > 0 and string.find(lowerName, part) == nil) then
            return false;
        end
    end
    return true;
end

--- Collect visible own skill data for populating dropdowns.
function OwnSkillList:CollectVisibleSkillData()
    local skillsService = self:GetService("skills");
    local playerService = self:GetService("player");
    local result = {};

    local ownProfessions = playerService.node.own[self.selectedCharacter];
    if (not ownProfessions) then
        return result;
    end

    local professionIds;
    if (self.professionId == 0) then
        professionIds = self:GetService("profession-names"):GetProfessionIdsToShow(true);
    elseif (self.professionId and self.professionId > 0) then
        professionIds = {self.professionId};
    else
        return result;
    end

    for _, professionId in ipairs(professionIds) do
        local ownSkills = ownProfessions[professionId];
        if (ownSkills) then
            for _, ownSkill in ipairs(ownSkills) do
                local skillData = skillsService:GetSkillById(ownSkill.skillId);
                if (skillData and skillData.name) then
                    if (self.addonId == nil or self:MatchesAddon(skillData, self.addonId)) then
                        table.insert(result, {professionId = professionId, skillData = skillData});
                    end
                end
            end
        end
    end

    return result;
end

--- Refresh category dropdown items based on visible skills.
function OwnSkillList:RefreshCategoryItems()
    local categoryService = self:GetService("category");
    local items = categoryService:BuildCategoryItems(self:CollectVisibleSkillData());
    self.categorySelection:SetItems(items);
end

--- Refresh subcategory dropdown items based on visible skills and current category.
function OwnSkillList:RefreshSubcategoryItems()
    local categoryService = self:GetService("category");
    local items = categoryService:BuildSubcategoryItems(self:CollectVisibleSkillData(), self.categoryId);
    self.subcategorySelection:SetItems(items);
end

--- Refresh progress bar with current skill level.
function OwnSkillList:RefreshProgressBar()
    local playerService = self:GetService("player");
    local currentLevel = 0;
    local maxLevel = 300;

    -- the planner button follows the bar
    self.plannerButton:Hide();

    -- check if a profession is selected
    if (not self.professionId or self.professionId <= 0) then
        self.progressBarFrame:Hide();
        return;
    end

    -- determine skill level based on character
    local isCurrentCharacter = (self.selectedCharacter == playerService.current);
    if (self:IsDebugProfession(self.professionId)) then
        -- debug only profession: nothing learned, show 0 of max
        currentLevel = 0;
    elseif (isCurrentCharacter) then
        -- current character: use stored profession level
        if (PM_CharacterSettings.professionLevels and PM_CharacterSettings.professionLevels[self.professionId]) then
            currentLevel = PM_CharacterSettings.professionLevels[self.professionId];
        else
            self.progressBarFrame:Hide();
            return;
        end
    else
        -- alt character: read persisted level from node
        local ownLevels = playerService.node.ownLevels and playerService.node.ownLevels[self.selectedCharacter];
        if (ownLevels and ownLevels[self.professionId]) then
            currentLevel = ownLevels[self.professionId];
        else
            self.progressBarFrame:Hide();
            return;
        end
    end

    -- use the addon of the current game client, not the filter selection
    local currentAddonId = self:GetCurrentAddonId();
    if (currentAddonId) then
        maxLevel = GetMaxSkillLevel(self.professionId, currentAddonId);
    end

    -- hide when at max level
    if (currentLevel >= maxLevel) then
        self.progressBarFrame:Hide();
        return;
    end

    -- the planner button takes the right end of the bar row; debug only
    -- professions (level 0) get it too, so the planner can be tested without learning them
    local plannerService = self:GetService("leveling-planner");
    local showPlanner;
    if (self:IsDebugProfession(self.professionId)) then
        showPlanner = not self:GetService("profession-names"):IsGatheringProfession(self.professionId);
    else
        showPlanner = plannerService:CanPlan(self.selectedCharacter, self.professionId);
    end
    local barRight = showPlanner and (12 + self.plannerButton:GetWidth() + 8) or 12;
    self.progressBarFrame:SetPoint("RIGHT", self.frame, "RIGHT", -barRight, 0);
    self.plannerButton:SetShown(showPlanner);

    -- clamp current level to max
    local displayLevel = math.min(currentLevel, maxLevel);
    local fillRatio = maxLevel > 0 and (displayLevel / maxLevel) or 0;
    -- fill and marks use the inner width (the forever style keeps an inset for the rim)
    local barWidth = self.progressBarFrame:GetWidth() - 2 * (self.progressBarInset or 0);
    local fillWidth = math.max(1, barWidth * fillRatio);

    self.progressBarFill:SetWidth(fillWidth);
    self.progressBarText:SetText(displayLevel .. " / " .. maxLevel);
    self:RefreshProgressBarMarks(barWidth, maxLevel);
    self.progressBarFrame:Show();
end

--- Open the leveling planner for the selected character and profession.
function OwnSkillList:OpenLevelingPlanner()
    if (not self.addon.levelingPlannerView) then
        self.addon.levelingPlannerView = self.addon:NewView("leveling-planner");
    end
    self.addon:Log("OwnSkillList", "OpenLevelingPlanner", "opening leveling planner for profession %d", self.professionId);
    self.addon.levelingPlannerView:Show(self.selectedCharacter, self.professionId);
end

--- Place the skill rank ticks and names on the progress bar.
--- @param barWidth Current width of the bar.
--- @param maxLevel Max skill level of the running client.
function OwnSkillList:RefreshProgressBarMarks(barWidth, maxLevel)
    local localeService = self:GetService("locale");
    local levelTextRight = 6 + self.progressBarText:GetStringWidth() + 4;
    local markIndex = 0;

    for index, rank in ipairs(SkillRankMarks) do
        -- only ranks below the max level of the client get a tick
        if (rank.level < maxLevel) then
            markIndex = markIndex + 1;
            local mark = self.progressBarMarks[markIndex];
            if (not mark) then
                mark = self:CreateProgressBarMark();
                self.progressBarMarks[markIndex] = mark;
            end

            -- tick at the level, name right of it, limited to the rank range
            local tickOffset = math.floor(barWidth * rank.level / maxLevel);
            local tickX = (self.progressBarInset or 0) + tickOffset;
            local nextRank = SkillRankMarks[index + 1];
            local rangeEnd = (nextRank and nextRank.level < maxLevel) and nextRank.level or maxLevel;
            local rangeWidth = math.floor(barWidth * rangeEnd / maxLevel) - tickOffset;
            mark.tick:SetPoint("TOPLEFT", tickX, -2);
            mark.tick:SetPoint("BOTTOMLEFT", tickX, 2);
            mark.text:SetText(localeService:Get(rank.key));
            mark.text:SetWidth(math.max(1, rangeWidth - 8));
            mark.tick:Show();

            -- the name stays hidden when it would run into the level text (narrow windows)
            if (tickX + 4 < levelTextRight or rangeWidth < 20) then
                mark.text:Hide();
            else
                mark.text:Show();
            end
        end
    end

    -- hide marks of ranks the client does not have
    for index = markIndex + 1, #self.progressBarMarks do
        self.progressBarMarks[index].tick:Hide();
        self.progressBarMarks[index].text:Hide();
    end
end

--- Create one rank mark (tick line plus rank name) on the progress bar.
function OwnSkillList:CreateProgressBarMark()
    local tick = self.progressBarTextFrame:CreateTexture(nil, "ARTWORK");
    tick:SetWidth(1);
    tick:SetColorTexture(0.75, 0.75, 0.75, 0.9);

    local text = self.progressBarTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    text:SetPoint("LEFT", tick, "RIGHT", 4, 0);
    text:SetJustifyH("LEFT");
    text:SetWordWrap(false);
    text:SetTextColor(0.85, 0.85, 0.85, 1);
    return { tick = tick, text = text };
end

--- Handle resize.
function OwnSkillList:OnSizeChanged()
    if (self.scrollChild and self.scrollFrame) then
        self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
    end
    self:RefreshProgressBar();
    self:UpdateFlexColumns();
end

--- Set right margin.
function OwnSkillList:SetRightMargin(margin)
    if (self.frame) then
        self.frame:SetPoint("BOTTOMRIGHT", -margin, 0);
        if (self.scrollChild and self.scrollFrame) then
            self.scrollChild:SetWidth(self.scrollFrame:GetWidth());
        end
    end
end

--- Calculate and apply flex column widths.
function OwnSkillList:UpdateFlexColumns()
    if (not self.frame) then return; end

    local frameWidth = self.scrollChild and self.scrollChild:GetWidth() or self.frame:GetWidth();
    local bucketWidth = 30;
    local padding = 12;
    local auctionService = self:GetService("auction");
    local hasPrices = auctionService:CheckPricesAvailable();
    local profitWidth = hasPrices and 90 or 0;

    -- all column headers share one row: without the progress bar the whole
    -- header row moves up 32px, same as the item header and the list
    local headerTop = self:GetHeaderTop(self.hideProgressBar);

    if (self.isMaxLevel) then
        -- max level: no difficulty column
        local availableWidth = frameWidth - bucketWidth - padding - profitWidth;
        if (self.isCompact) then
            -- compact: item fills all
            self.flexItemWidth = availableWidth;
            self.flexRecipeOffset = nil;
        else
            -- full: item and recipe share space, recipe gets 15px more
            local itemWidth = math.floor(availableWidth / 2) - 15;
            self.flexItemWidth = itemWidth;
            self.flexRecipeOffset = itemWidth + profitWidth;
            if (self.recipeHeaderText) then
                self.recipeHeaderText:SetPoint("TOPLEFT", itemWidth + profitWidth + 11, headerTop);
            end
        end
        self.flexLevelingOffset = nil;
        self.flexProfitOffset = hasPrices and self.flexItemWidth or nil;
        if (self.levelingHeaderButton) then
            self.levelingHeaderButton:Hide();
        end
        if (self.profitHeaderButton) then
            if (hasPrices) then
                self.profitHeaderButton:SetPoint("TOPLEFT", self.flexProfitOffset + 11, headerTop);
                self.profitHeaderButton:Show();
            else
                self.profitHeaderButton:Hide();
            end
        end
    elseif (self.isCompact) then
        -- compact (not max level): show leveling, hide profit to save space
        local difficultyWidth = 80;
        local availableWidth = frameWidth - difficultyWidth - bucketWidth - padding;
        local itemWidth = availableWidth;

        self.flexItemWidth = itemWidth;
        self.flexLevelingOffset = itemWidth;
        self.flexProfitOffset = nil;
        self.flexRecipeOffset = nil;

        if (self.levelingHeaderButton) then
            self.levelingHeaderButton:SetPoint("TOPLEFT", itemWidth + 11, headerTop);
        end
        if (self.profitHeaderButton) then
            self.profitHeaderButton:Hide();
        end
    else
        -- check if gathering profession (Herbalism=182, Mining=186)
        local isGathering = (self.professionId == 182 or self.professionId == 186);

        -- full: difficulty = 90px, profit = 90px, item and recipe share remaining space
        local difficultyWidth = 90;
        local availableWidth = frameWidth - difficultyWidth - profitWidth - bucketWidth - padding;
        local itemWidth;
        if (isGathering) then
            itemWidth = 270;
        else
            -- recipe column gets 15px more than item
            itemWidth = math.floor(availableWidth / 2) - 15;
        end
        local recipeOffset = itemWidth + difficultyWidth + profitWidth;

        self.flexItemWidth = itemWidth;
        self.flexLevelingOffset = itemWidth;
        self.flexProfitOffset = hasPrices and (itemWidth + difficultyWidth) or nil;
        self.flexRecipeOffset = recipeOffset;

        if (self.levelingHeaderButton) then
            self.levelingHeaderButton:SetPoint("TOPLEFT", itemWidth + 11, headerTop);
        end
        if (self.profitHeaderButton) then
            if (hasPrices) then
                self.profitHeaderButton:SetPoint("TOPLEFT", itemWidth + difficultyWidth + 11, headerTop);
                self.profitHeaderButton:Show();
            else
                self.profitHeaderButton:Hide();
            end
        end
        if (self.recipeHeaderText) then
            self.recipeHeaderText:SetPoint("TOPLEFT", recipeOffset + 11, headerTop);
        end
    end
end

--- Update responsive layout based on frame width.
function OwnSkillList:UpdateResponsiveLayout()
    if (not self.frame or not self.searchContainer) then return; end
    if (self.isEmpty) then return; end
    local frameWidth = self.frame:GetWidth();
    if (frameWidth < 550) then
        self.isCompact = true;

        -- hide addon dropdown
        if (self.addonLabel) then self.addonLabel:Hide(); end
        if (self.addonSelection) then self.addonSelection:Hide(); end

        -- hide character dropdown in compact mode
        self.characterLabel:Hide();
        self.characterSelection:Hide();

        -- move profession to left position
        self.professionLabel:SetPoint("TOPLEFT", 12, -12);
        self.professionSelection:SetPoint("TOPLEFT", 12, -28);

        -- move search next to profession
        self.searchLabel:SetPoint("TOPLEFT", 180, -12);
        self.searchContainer:SetPoint("TOPLEFT", 180, -28);
        self.searchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -12, 0);

        -- hide category and subcategory
        self.categoryLabel:Hide();
        self.categorySelection:Hide();
        self.subcategoryLabel:Hide();
        self.subcategorySelection:Hide();

        -- mode, max skill and difficulty in the filter row
        self:LayoutFilterRow();

        -- hide recipe column header
        self.recipeHeaderText:Hide();

        -- apply flex columns
        self:UpdateFlexColumns();
    else
        self.isCompact = false;

        -- show addon dropdown
        if (self.addonLabel) then self.addonLabel:Show(); end
        if (self.addonSelection) then self.addonSelection:Show(); end

        -- show/hide character dropdown based on character count
        if (self.showCharacterDropdown) then
            self.characterLabel:Show();
            self.characterSelection:Show();

            -- positions with character dropdown visible
            self.characterLabel:SetPoint("TOPLEFT", 12, -12);
            self.characterSelection:SetPoint("TOPLEFT", 12, -28);
            self.professionLabel:SetPoint("TOPLEFT", 180, -12);
            self.professionSelection:SetPoint("TOPLEFT", 180, -28);
            self.searchLabel:SetPoint("TOPLEFT", 348, -12);
            self.searchContainer:SetPoint("TOPLEFT", 348, -28);
        else
            self.characterLabel:Hide();
            self.characterSelection:Hide();

            -- shift profession and search to the left
            self.professionLabel:SetPoint("TOPLEFT", 12, -12);
            self.professionSelection:SetPoint("TOPLEFT", 12, -28);
            self.searchLabel:SetPoint("TOPLEFT", 180, -12);
            self.searchContainer:SetPoint("TOPLEFT", 180, -28);
        end
        if (self.professionsView.addon.hasExpansion) then
            self.searchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -150, 0);
        else
            self.searchContainer:SetPoint("RIGHT", self.frame, "RIGHT", -12, 0);
        end

        -- show category (subcategory depends on state)
        self.categoryLabel:Show();
        self.categorySelection:Show();
        if (self.showSubcategory) then
            self.subcategoryLabel:Show();
            self.subcategorySelection:Show();
        end

        -- all filters in the filter row
        self:LayoutFilterRow();

        -- show recipe column header
        self.recipeHeaderText:Show();

        -- apply flex columns
        self:UpdateFlexColumns();
    end
end

--- Place the filter row from left to right: mode, max skill, difficulty
--- (hidden at max level), category and subcategory (hidden when compact).
--- Difficulty, category and subcategory get narrower when the list is narrow,
--- so the row never runs into the shopping list.
function OwnSkillList:LayoutFilterRow()
    local frameWidth = self.frame:GetWidth();

    -- max skill right of the mode
    local left = 12 + ModeFilterWidth + 8;
    self.maxLevelLabel:SetPoint("TOPLEFT", left, -58);
    self.maxLevelSelection:SetPoint("TOPLEFT", left, -74);
    left = left + MaxLevelFilterWidth + 8;

    -- difficulty right of it; at max level it is hidden and the category takes its place
    local difficultyWidth = math.max(80, math.min(DifficultyFilterWidth, frameWidth - 12 - left));
    self.difficultyFilterLabel:SetPoint("TOPLEFT", left, -58);
    self.difficultyFilterSelection:SetPoint("TOPLEFT", left, -74);
    self.difficultyFilterSelection:SetWidth(difficultyWidth);
    if (not self.isMaxLevel) then
        left = left + difficultyWidth + 8;
    end
    if (self.isCompact) then
        return;
    end

    -- category and subcategory share the rest of the row
    local categoryWidth = math.max(80, math.min(CategoryFilterWidth, math.floor((frameWidth - 12 - left - 8) / 2)));
    self.categoryLabel:SetPoint("TOPLEFT", left, -58);
    self.categorySelection:SetPoint("TOPLEFT", left, -74);
    self.categorySelection:SetWidth(categoryWidth);
    left = left + categoryWidth + 8;
    self.subcategoryLabel:SetPoint("TOPLEFT", left, -58);
    self.subcategorySelection:SetPoint("TOPLEFT", left, -74);
    self.subcategorySelection:SetWidth(categoryWidth);
end

--- Add and filter skills.
--- Get the top offset of the column headers: under the progress bar, or in
--- its place while the bar is hidden (see FlatLayout / ForeverLayout).
-- @param barHidden True while the progress bar is hidden.
-- @return Top offset of the column headers.
function OwnSkillList:GetHeaderTop(barHidden)
    local layout = self.layout or FlatLayout;
    return barHidden and layout.headerTopNoBar or layout.headerTop;
end

--- Get the top offset of the list below its column headers; the forever style
--- keeps two more pixels of air between the headers and the list.
-- @param headerTop Top offset of the column headers.
-- @return Top offset of the list.
function OwnSkillList:GetListTop(headerTop)
    local gap = self:GetService("ui"):IsForever() and 14 or 12;
    return headerTop - gap;
end

--- Show the parchment background of the selected profession (forever style only).
function OwnSkillList:UpdateProfessionBackground()
    if (self.professionBackground) then
        self.professionBackground:SetArt(self:GetModel("profession-backgrounds"):GetName(self.professionId));
    end
end

function OwnSkillList:AddSkills()
    self:UpdateProfessionBackground();
    local messageService = self:GetService("message");
    local localeService = self:GetService("locale");
    local skillsService = self:GetService("skills");
    local playerService = self:GetService("player");

    -- build character dropdown items from own node
    local characterItems = {};
    for characterName, _ in pairs(playerService.node.own) do
        -- extract short name (before the dash)
        local shortName = string.match(characterName, "^([^%-]+)") or characterName;
        table.insert(characterItems, { value = characterName, text = shortName });
    end

    -- sort with current player first, then alphabetical
    table.sort(characterItems, function(a, b)
        if (a.value == playerService.current) then return true; end
        if (b.value == playerService.current) then return false; end
        return a.text < b.text;
    end);
    self.characterSelection:SetItems(characterItems);

    -- hide character dropdown if only one character available
    self.showCharacterDropdown = (#characterItems > 1);

    -- validate selected character still exists in node
    local validCharacter = false;
    for _, item in ipairs(characterItems) do
        if (item.value == self.selectedCharacter) then
            validCharacter = true;
            break;
        end
    end
    if (not validCharacter) then
        self.selectedCharacter = playerService.current;
    end
    self.characterSelection:SetValue(self.selectedCharacter);

    -- determine which professions the selected character has
    local allProfessionIds = self:GetService("profession-names"):GetProfessionIdsToShow(true);
    local ownProfessionIds = {};
    local ownProfessions = playerService.node.own[self.selectedCharacter];
    if (ownProfessions) then
        for _, professionId in ipairs(allProfessionIds) do
            if (ownProfessions[professionId]) then
                table.insert(ownProfessionIds, professionId);
            end
        end
    end

    -- debug build: list every profession, the missing ones as debug only entries after the learned ones
    -- (not for a character without any profession, it gets the empty state like in a release build)
    self.debugProfessionIds = {};
    if (self.addon.isDebug and #ownProfessionIds > 0) then
        for _, professionId in ipairs(allProfessionIds) do
            if (not (ownProfessions and ownProfessions[professionId])) then
                self.debugProfessionIds[professionId] = true;
                table.insert(ownProfessionIds, professionId);
            end
        end
    end

    -- show empty state if no own professions
    if (#ownProfessionIds == 0) then
        self.isEmpty = true;
        self.searchLabel:Hide();
        self.searchContainer:Hide();
        self.characterLabel:Hide();
        self.characterSelection:Hide();
        self.professionLabel:Hide();
        self.professionSelection:Hide();
        self.skillHeaderButton:Hide();
        self.levelingHeaderButton:Hide();
        self.profitHeaderButton:Hide();
        self.recipeHeaderText:Hide();
        self.bucketListHeader:Hide();
        self.scrollFrame:Hide();
        self.progressBarFrame:Hide();
        self.categoryLabel:Hide();
        self.categorySelection:Hide();
        self.subcategoryLabel:Hide();
        self.subcategorySelection:Hide();
        self.modeLabel:Hide();
        self.modeSelection:Hide();
        self.maxLevelLabel:Hide();
        self.maxLevelSelection:Hide();
        self.difficultyFilterLabel:Hide();
        self.difficultyFilterSelection:Hide();
        if (self.addonLabel) then self.addonLabel:Hide(); end
        if (self.addonSelection) then self.addonSelection:Hide(); end
        self.emptyMessage:Show();
        return;
    end

    -- show controls
    self.isEmpty = false;
    self.searchLabel:Show();
    self.searchContainer:Show();
    self.professionLabel:Show();
    self.professionSelection:Show();
    self.skillHeaderButton:Show();
    self.levelingHeaderButton:Show();
    self.recipeHeaderText:Show();
    self.scrollFrame:Show();
    self.categoryLabel:Show();
    self.categorySelection:Show();
    self.modeLabel:Show();
    self.modeSelection:Show();
    self.maxLevelLabel:Show();
    self.maxLevelSelection:Show();
    self.difficultyFilterLabel:Show();
    self.difficultyFilterSelection:Show();
    if (self.addonLabel) then self.addonLabel:Show(); end
    if (self.addonSelection) then self.addonSelection:Show(); end
    self.emptyMessage:Hide();

    -- show/hide subcategory based on previous state
    if (self.showSubcategory) then
        self.subcategoryLabel:Show();
        self.subcategorySelection:Show();
    else
        self.subcategoryLabel:Hide();
        self.subcategorySelection:Hide();
    end

    -- apply responsive layout
    self:UpdateResponsiveLayout();

    -- rebuild dropdown items with only own professions (no "all professions" option)
    local professionItems = {};
    local professionNamesService = self:GetService("profession-names");
    for _, professionId in ipairs(ownProfessionIds) do
        local professionText = professionNamesService:GetProfessionText(professionId, 133739);

        -- mark debug only professions in gray behind the name
        if (self:IsDebugProfession(professionId)) then
            professionText = professionText .. " |cff808080(debugging)|r";
        end
        table.insert(professionItems, { value = professionId, text = professionText });
    end
    self.professionSelection:SetItems(professionItems);

    -- validate saved profession is still valid
    local validProfession = false;
    for _, item in ipairs(professionItems) do
        if (item.value == self.professionId) then
            validProfession = true;
            break;
        end
    end
    if (not validProfession) then
        self.professionId = ownProfessionIds[1] or 0;
    end
    self.professionSelection:SetValue(self.professionId);

    -- refresh progress bar
    self:RefreshProgressBar();

    -- get search parts
    local searchText = string.lower(messageService:TrimString(self.searchBox:GetText()));
    local searchParts = messageService:SplitString(string.gsub(searchText, "%-", "%%-"), " ");
    for i, part in ipairs(searchParts) do
        searchParts[i] = messageService:TrimString(searchParts[i]);
    end

    self.skills = {};
    self.bucketListSkillAmount = 0;
    self.favoriteSkillAmount = 0;

    local professionIds;
    if (self.professionId == 0) then
        professionIds = ownProfessionIds;
    else
        professionIds = { self.professionId };
    end

    -- get current skill level
    local playerService2 = self:GetService("player");
    local isCurrentCharacter = (self.selectedCharacter == playerService2.current);
    local currentSkillLevel = 0;
    if (isCurrentCharacter and PM_CharacterSettings.professionLevels and self.professionId > 0) then
        -- current character: use stored profession level
        currentSkillLevel = PM_CharacterSettings.professionLevels[self.professionId] or 0;
    elseif (not isCurrentCharacter and self.professionId > 0) then
        -- alt character: read persisted level from node
        local ownLevels = playerService2.node.ownLevels and playerService2.node.ownLevels[self.selectedCharacter];
        if (ownLevels and ownLevels[self.professionId]) then
            currentSkillLevel = ownLevels[self.professionId];
        end
    end

    -- check if profession is at max level
    local currentAddonId = self:GetCurrentAddonId();
    local maxSkillLevel = GetMaxSkillLevel(self.professionId, currentAddonId);
    self.isMaxLevel = (self.professionId > 0 and currentSkillLevel >= maxSkillLevel);

    -- determine if progress bar will be hidden (debug only professions always show 0 of max)
    self.hideProgressBar = self.isMaxLevel or (currentSkillLevel == 0 and not self:IsDebugProfession(self.professionId));

    -- at max level: hide difficulty column, progress bar, and shift list up
    if (self.isMaxLevel) then
        self.levelingHeaderButton:Hide();
        self.difficultyFilterLabel:Hide();
        self.difficultyFilterSelection:Hide();
        self.progressBarFrame:Hide();

        -- shift headers and scroll frame up (save ~32px from hidden progress bar)
        self.skillHeaderButton:SetPoint("TOPLEFT", 12, self:GetHeaderTop(true));
        self.scrollFrame:SetPoint("TOPLEFT", 6, self:GetListTop(self:GetHeaderTop(true)));
        if (self.sortColumn == "leveling") then
            self.sortColumn = "item";
            self.sortAscending = true;
            PM_CharacterSettings.lastOwnSortColumn = self.sortColumn;
            PM_CharacterSettings.lastOwnSortAscending = self.sortAscending;
        end
    else
        self.levelingHeaderButton:Show();
        self.difficultyFilterLabel:Show();
        self.difficultyFilterSelection:Show();

        -- shift headers up when progress bar is hidden (alt character)
        if (self.hideProgressBar) then
            self.progressBarFrame:Hide();
            self.skillHeaderButton:SetPoint("TOPLEFT", 12, self:GetHeaderTop(true));
            self.scrollFrame:SetPoint("TOPLEFT", 6, self:GetListTop(self:GetHeaderTop(true)));
        else
            -- restore headers and scroll frame positions
            self.skillHeaderButton:SetPoint("TOPLEFT", 12, self:GetHeaderTop(false));
            self.scrollFrame:SetPoint("TOPLEFT", 6, self:GetListTop(self:GetHeaderTop(false)));
        end
    end

    -- the category takes the place of the hidden difficulty at max level
    self:LayoutFilterRow();

    -- update flex column widths (also positions recipeHeaderText correctly)
    self:UpdateFlexColumns();

    if (self.modeId == "unknown") then
        -- unknown mode: show all skills for profession that player does NOT know
        -- build lookup of known skill ids
        local knownSkillIds = {};
        for _, professionId in ipairs(professionIds) do
            local ownSkills = ownProfessions and ownProfessions[professionId];
            if (ownSkills) then
                for _, ownSkill in ipairs(ownSkills) do
                    knownSkillIds[ownSkill.skillId] = true;
                end
            end
        end

        -- iterate all skills and find unknown ones for selected professions
        -- (skills that were never learnable on this client stay out)
        for skillId, skillData in pairs(skillsService.allSkills) do
            if (skillData.name and skillData.professionId and not knownSkillIds[skillId] and not skillsService:IsHiddenSkill(skillData)) then
                -- check if skill belongs to one of the selected professions
                local matchesProfession = false;
                for _, professionId in ipairs(professionIds) do
                    if (skillData.professionId == professionId) then
                        matchesProfession = true;
                        break;
                    end
                end

                if (matchesProfession) then
                    -- apply addon filter
                    if (self.addonId and not self:MatchesAddon(skillData, self.addonId)) then
                        -- skip
                    -- apply category/subcategory filter
                    elseif (not self:MatchesCategory(skillData, skillData.professionId)) then
                        -- skip
                    -- apply difficulty filter
                    elseif (not self:MatchesDifficultyFilter(skillData, currentSkillLevel)) then
                        -- skip
                    -- apply max skill filter
                    elseif (not self:MatchesMaxLevelFilter(skillData)) then
                        -- skip
                    else
                        if (self:MatchesSearch(skillData.name, searchParts)) then
                            local isFavorite = playerService.node.ownFavorites[skillId] ~= nil;
                            table.insert(self.skills, {
                                professionId = skillData.professionId,
                                skillId = skillId,
                                skill = skillData,
                                bucketListAmount = nil,
                                isFavorite = isFavorite,
                            });
                            if (isFavorite) then
                                self.favoriteSkillAmount = self.favoriteSkillAmount + 1;
                            end
                        end
                    end
                end
            end
        end
    elseif (self.modeId == "all") then
        -- all mode: show all known skills for the profession from all sources
        for skillId, skillData in pairs(skillsService.allSkills) do
            if (skillData.name and skillData.professionId) then
                -- check if skill belongs to one of the selected professions
                local matchesProfession = false;
                for _, professionId in ipairs(professionIds) do
                    if (skillData.professionId == professionId) then
                        matchesProfession = true;
                        break;
                    end
                end

                if (matchesProfession) then
                    -- apply addon filter
                    if (self.addonId and not self:MatchesAddon(skillData, self.addonId)) then
                        -- skip
                    -- apply category/subcategory filter
                    elseif (not self:MatchesCategory(skillData, skillData.professionId)) then
                        -- skip
                    -- apply difficulty filter
                    elseif (not self:MatchesDifficultyFilter(skillData, currentSkillLevel)) then
                        -- skip
                    -- apply max skill filter
                    elseif (not self:MatchesMaxLevelFilter(skillData)) then
                        -- skip
                    else
                        local bucketListAmount = PM_BucketList[skillId];
                        if (self:MatchesSearch(skillData.name, searchParts)) then
                            -- favorites group only holds items not already on the shopping list
                            local isFavorite = (not bucketListAmount) and playerService.node.ownFavorites[skillId] ~= nil;
                            table.insert(self.skills, {
                                professionId = skillData.professionId,
                                skillId = skillId,
                                skill = skillData,
                                bucketListAmount = bucketListAmount,
                                isFavorite = isFavorite,
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
    else
        -- known mode: show skills from own professions
        for _, professionId in ipairs(professionIds) do
            local ownSkills = ownProfessions and ownProfessions[professionId];
            if (ownSkills) then
                for _, ownSkill in ipairs(ownSkills) do
                    local skillId = ownSkill.skillId;
                    local skillData = skillsService:GetSkillById(skillId);
                    if (skillData and skillData.name ~= nil) then
                        -- apply addon filter
                        if (self.addonId and not self:MatchesAddon(skillData, self.addonId)) then
                            -- skip
                        -- apply category/subcategory filter
                        elseif (not self:MatchesCategory(skillData, professionId)) then
                            -- skip
                        -- apply difficulty filter
                        elseif (not self:MatchesDifficultyFilter(skillData, currentSkillLevel)) then
                            -- skip
                        -- apply max skill filter
                        elseif (not self:MatchesMaxLevelFilter(skillData)) then
                            -- skip
                        else
                            local bucketListAmount = PM_BucketList[skillId];
                            if (self:MatchesSearch(skillData.name, searchParts)) then
                                -- favorites group only holds items not already on the shopping list
                                local isFavorite = (not bucketListAmount) and playerService.node.ownFavorites[skillId] ~= nil;
                                table.insert(self.skills, {
                                    professionId = professionId,
                                    skillId = skillId,
                                    skill = skillData,
                                    bucketListAmount = bucketListAmount,
                                    isFavorite = isFavorite,
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

    -- sort: bucket list items first, then by selected column
    local sortColumn = self.sortColumn;
    local sortAscending = self.sortAscending;
    local skillSortService = self:GetService("skill-sort");
    local auctionService = self:GetService("auction");

    -- calculate profit for each skill entry
    for _, entry in ipairs(self.skills) do
        entry.profit = auctionService:GetSkillProfit(entry.skillId);
    end

    if (sortColumn == "item") then
        skillSortService:SortByName(self.skills, sortAscending);
    elseif (sortColumn == "profit") then
        skillSortService:SortByProfit(self.skills, sortAscending);
    else
        skillSortService:SortByDifficulty(self.skills, currentSkillLevel, sortAscending);
    end

    -- update header texts with sort arrows
    local arrowUp = "|TInterface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up:12:12:2:0:32:32:6:26:6:26|t";
    local arrowDown = "|TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:12:12:2:0:32:32:6:26:6:26|t";
    local itemArrow = "";
    local levelingArrow = "";
    local profitArrow = "";
    if (sortColumn == "item") then
        itemArrow = sortAscending and arrowUp or arrowDown;
    elseif (sortColumn == "profit") then
        profitArrow = sortAscending and arrowUp or arrowDown;
    else
        levelingArrow = sortAscending and arrowUp or arrowDown;
    end
    self.skillText:SetText(localeService:Get("ProfessionsViewItem") .. itemArrow);
    self.levelingText:SetText(localeService:Get("ProfessionsViewLeveling") .. levelingArrow);
    self.profitHeaderText:SetText(localeService:Get("ProfessionsViewProfit") .. profitArrow);
    self.skillHeaderButton:SetWidth(self.skillText:GetStringWidth() + 4);
    self.levelingHeaderButton:SetWidth(self.levelingText:GetStringWidth() + 4);
    self.profitHeaderButton:SetWidth(self.profitHeaderText:GetStringWidth() + 4);

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

    -- set scroll height
    local headerHeight = (bucketCount > 0 and 20 or 0) + (favoriteCount > 0 and 20 or 0) + (specialCount > 0 and 20 or 0);
    self.scrollChild:SetHeight(#self.skills * 20 + headerHeight);

    -- store for row rendering
    self.currentSkillLevel = currentSkillLevel;

    -- refresh rows
    self:RefreshRows();
end

--- Get difficulty color string for a skill.
function OwnSkillList:GetlevelingText(skillData)
    return self:GetService("skill-sort"):GetLevelingText(skillData.difficulty, self.currentSkillLevel or 0);
end

--- Show difficulty tooltip on the game tooltip (only one tooltip per column now,
--- so the secondary tooltip frame is no longer needed here).
-- @param owner Frame to anchor to.
-- @param skillData Skill data with difficulty table.
function OwnSkillList:ShowLevelingTooltip(owner, skillData)
    if (not skillData or not skillData.difficulty) then return; end
    local tooltip = GameTooltip;
    local localeService = self:GetService("locale");

    local d1 = skillData.difficulty[1] or 0;
    local d2 = skillData.difficulty[2] or 0;
    local d3 = skillData.difficulty[3] or 0;
    local d4 = skillData.difficulty[4] or 0;
    local level = self.currentSkillLevel or 0;

    -- tooltip hangs below the row with its top-right corner at the column's bottom-left
    tooltip:SetOwner(owner, "ANCHOR_NONE");
    tooltip:ClearAllPoints();
    tooltip:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 0, 2);
    tooltip:ClearLines();

    tooltip:AddLine(localeService:Get("ProfessionsViewLeveling"), 1, 0.82, 0);

    -- d1 line (red)
    if (d1 > 1) then
        local line1 = "|cffff4040< " .. d1 .. "|r";
        if (level < d1) then
            line1 = line1 .. "  |cffffffff" .. (localeService:Get("DifficultyRemaining") or "remaining") .. " " .. (d1 - level) .. "|r";
        end
        tooltip:AddLine(line1);
    end

    -- d2 line (orange)
    if (d2 > 1) then
        local line2 = "|cffff8040< " .. d2 .. "|r";
        if (level < d1) then
            line2 = line2 .. "  |cffffffff(" .. (d2 - d1) .. ")|r";
        elseif (level < d2) then
            line2 = line2 .. "  |cffffffff" .. (localeService:Get("DifficultyRemaining") or "remaining") .. " " .. (d2 - level) .. "|r";
        end
        tooltip:AddLine(line2);
    end

    -- d3 line (yellow)
    if (d3 > 1) then
        local line3 = "|cffffff00< " .. d3 .. "|r";
        if (level < d1) then
            line3 = line3 .. "  |cffffffff(" .. (d3 - d2) .. ")|r";
        elseif (level < d3) then
            line3 = line3 .. "  |cffffffff" .. (localeService:Get("DifficultyRemaining") or "remaining") .. " " .. (d3 - level) .. "|r";
        end
        tooltip:AddLine(line3);
    end

    -- d4 line (green)
    if (d4 > 1) then
        local line4 = "|cff40c040< " .. d4 .. "|r";
        if (level < d1) then
            line4 = line4 .. "  |cffffffff(" .. (d4 - d3) .. ")|r";
        elseif (level < d4) then
            line4 = line4 .. "  |cffffffff" .. (localeService:Get("DifficultyRemaining") or "remaining") .. " " .. (d4 - level) .. "|r";
        end
        tooltip:AddLine(line4);
    end

    tooltip:Show();
end

--- Refresh visible rows.
function OwnSkillList:RefreshRows()
    if (not self.skills or #self.skills == 0) then
        for _, row in ipairs(self.rowPool) do
            row:Hide();
        end
        return;
    end

    local visibleRowCount = math.ceil((self.scrollFrame:GetHeight() or 400) / 20) + 6;
    local startIndex = math.max(math.floor(self.scrollTop / 20) - 3, 1);
    local endIndex = math.min(startIndex + visibleRowCount, #self.skills);
    local visibleCount = endIndex - startIndex + 1;

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
        itemText:SetWidth(254);
        itemText:SetWordWrap(false);
        itemText:SetJustifyH("LEFT");
        row.itemText = itemText;

        -- add favorite toggle (talisman adds; overlaid red the click removes;
        -- shown while the row is hovered; same icon as in the guild list)
        local favoriteButton = CreateFrame("Button", nil, row);
        favoriteButton:SetSize(20, 20);
        local favoriteStar = favoriteButton:CreateTexture(nil, "OVERLAY");
        favoriteStar:SetSize(16, 16);
        favoriteStar:SetPoint("CENTER", 0, 0);
        favoriteStar:SetTexture("Interface\\Icons\\INV_Jewelry_Talisman_08");
        favoriteButton.star = favoriteStar;
        favoriteButton:Hide();
        row.favoriteButton = favoriteButton;

        -- update the favorite toggle state (red overlay = click removes) and
        -- show it while the row is hovered
        local function ShowFavoriteButton()
            if (not row.skillId) then return; end
            local favorites = self:GetService("player").node.ownFavorites;
            if (favorites[row.skillId]) then
                favoriteButton.star:SetVertexColor(1, 0.35, 0.35);
            else
                favoriteButton.star:SetVertexColor(1, 1, 1);
            end
            favoriteButton:Show();
        end

        -- toggle favorite state and re-render the list
        favoriteButton:SetScript("OnClick", function()
            if (not row.skillId) then return; end
            local favorites = self:GetService("player").node.ownFavorites;
            if (favorites[row.skillId]) then
                favorites[row.skillId] = nil;
                self.addon:Log("OwnSkillList", "ToggleFavorite", "Removed skill %s from own favorites", tostring(row.skillId));
            else
                favorites[row.skillId] = true;
                self.addon:Log("OwnSkillList", "ToggleFavorite", "Added skill %s to own favorites", tostring(row.skillId));
            end
            GameTooltip:Hide();
            self:AddSkills();
        end);
        favoriteButton:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            local favorites = self:GetService("player").node.ownFavorites;
            local tooltipKey = favorites[row.skillId] and "ProfessionsViewRemoveFromFavorites" or "ProfessionsViewAddToFavorites";
            GameTooltip:SetOwner(favoriteButton, "ANCHOR_RIGHT");
            GameTooltip:SetText(self:GetService("locale"):Get(tooltipKey));
            GameTooltip:Show();
        end);
        favoriteButton:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            favoriteButton:Hide();
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
        end);

        -- add difficulty label (clickable area with tooltip)
        local levelingButton = CreateFrame("Button", nil, row);
        levelingButton:SetPoint("TOPLEFT", 260, 0);
        levelingButton:SetPoint("BOTTOMLEFT", 260, 0);
        levelingButton:SetWidth(100);
        local levelingLabel = levelingButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        levelingLabel:SetPoint("TOPLEFT", 0, -3);
        levelingLabel:SetJustifyH("LEFT");
        row.levelingLabel = levelingLabel;
        row.levelingButton = levelingButton;
        levelingButton:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowFavoriteButton();
            self:ShowLevelingTooltip(levelingButton, row.skill);
        end);
        levelingButton:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
        end);

        -- add recipe labels pool (multiple recipes per row)
        row.recipeLabels = {};

        -- add zones text for gathering skills
        local zonesText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        zonesText:SetJustifyH("LEFT");
        zonesText:SetTextColor(1, 1, 1);
        zonesText:SetNonSpaceWrap(false);
        zonesText:SetWordWrap(false);
        zonesText:Hide();
        row.zonesText = zonesText;

        -- clip children so recipe labels don't overflow
        row:SetClipsChildren(true);

        -- add bucket list count
        local bucketText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        bucketText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -3);
        bucketText:SetJustifyH("RIGHT");
        row.bucketText = bucketText;

        -- add profit text
        local profitLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        profitLabel:SetJustifyH("LEFT");
        profitLabel:Hide();
        row.profitLabel = profitLabel;

        -- hover (highlight only; the skill tooltip is shown by the item hover region)
        row:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowFavoriteButton();
        end);
        row:SetScript("OnLeave", function()
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
            GameTooltip:Hide();
        end);

        -- click (shared by the row and the item hover region)
        local function onRowMouseDown(_, button)
            if (button == "LeftButton") and IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow() then
                if (IsControlKeyDown()) then
                    if (self.professionsView.addon.isBccAtLeast and row.skill and row.skill.skillLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.skillLink);
                    elseif (row.skillId) then
                        local professionName = self:GetService("profession-names"):GetProfessionName(row.professionId);
                        local spellName = self.addon.compat.GetSpellInfo(row.skillId) or (row.skill and row.skill.name);
                        if (spellName) then
                            local linkText = professionName and (professionName .. ": " .. spellName) or spellName;
                            local editbox = GetCurrentKeyBoardFocus();
                            if (editbox) then
                                editbox:Insert("[PM: " .. linkText .. " : " .. row.skillId .. "]");
                            end
                        end
                    end
                else
                    if (row.skill and row.skill.itemLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.itemLink);
                    elseif (self.professionsView.addon.isBccAtLeast and row.skill and row.skill.skillLink) then
                        self.addon.compat.ChatEdit_InsertLink(row.skill.skillLink);
                    elseif (row.skillId) then
                        local professionName = self:GetService("profession-names"):GetProfessionName(row.professionId);
                        local spellName = self.addon.compat.GetSpellInfo(row.skillId) or (row.skill and row.skill.name);
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
                self.professionsView:ShowSkillView(row);
            end
        end
        row:SetScript("OnMouseDown", onRowMouseDown);

        -- item hover region (first column): shows the skill tooltip; width is
        -- synced to the flex item column in the render pass
        local itemHover = CreateFrame("Frame", nil, row);
        itemHover:SetPoint("TOPLEFT", 0, 0);
        itemHover:SetPoint("BOTTOMLEFT", 0, 0);
        itemHover:SetWidth(254);
        itemHover:EnableMouse(true);
        itemHover:SetScript("OnEnter", function()
            row:SetBackdropColor(0.2, 0.2, 0.2);
            ShowFavoriteButton();
            -- tooltip hangs with its top-right corner at the column's top-left
            GameTooltip:SetOwner(itemHover, "ANCHOR_NONE");
            GameTooltip:ClearAllPoints();
            GameTooltip:SetPoint("TOPRIGHT", itemHover, "TOPLEFT", -2, 0);
            self:GetService("tooltip"):ShowTooltip(GameTooltip, row.professionId, row.skillId, row.skill, nil);
        end);
        itemHover:SetScript("OnLeave", function()
            GameTooltip:Hide();
            if (row:IsMouseOver()) then return; end
            if (row.bgColor) then
                row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
            end
            favoriteButton:Hide();
        end);
        itemHover:SetScript("OnMouseDown", onRowMouseDown);
        row.itemHover = itemHover;

        -- keep the favorite toggle clickable above the item hover region
        favoriteButton:SetFrameLevel(itemHover:GetFrameLevel() + 1);

        -- purple hover glow (border + purple backdrop), kept alive by the column regions
        self:GetService("ui"):AttachHoverGlow(row, { levelingButton, itemHover, favoriteButton });

        self.rowPool[poolIndex] = row;
    end

    -- hide all pooled frames
    for _, row in ipairs(self.rowPool) do
        row:Hide();
    end

    -- render visible rows
    local poolUsed = 0;
    for i = 0, visibleCount - 1 do
        local rowIndex = startIndex + i;
        local skillData = self.skills[rowIndex];
        if (skillData) then
            poolUsed = poolUsed + 1;
            local row = self.rowPool[poolUsed];

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

            row:ClearAllPoints();
            row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -top);
            row:SetPoint("RIGHT", self.scrollChild, "RIGHT", -28, 0);
            row:SetHeight(20);

            local backgroundColor = (rowIndex % 2 == 0) and 0.12 or 0.06;
            row.bgColor = backgroundColor;
            row:SetBackdropColor(backgroundColor, backgroundColor, backgroundColor, 0.5);

            row.professionId = skillData.professionId;
            row.skillId = skillData.skillId;
            row.skill = skillData.skill;

            -- apply flex column widths
            local itemWidth = self.flexItemWidth or 254;
            local levelingOffset = self.flexLevelingOffset;
            local recipeOffset = self.flexRecipeOffset or 400;

            -- keep the item hover region in sync with the item column
            row.itemHover:SetWidth(itemWidth);

            if (self.isMaxLevel) then
                -- no difficulty column at max level
                row.levelingButton:Hide();
                row.itemText:SetWidth(itemWidth - 6);
            else
                levelingOffset = levelingOffset or 260;
                row.itemText:SetWidth(itemWidth - 6);
                local profitOffset = self.flexProfitOffset;
                local levelingWidth = profitOffset and (profitOffset - levelingOffset - 6) or (self.isCompact and (row:GetWidth() - levelingOffset - 30)) or (recipeOffset - levelingOffset - 6);
                row.levelingButton:SetPoint("TOPLEFT", levelingOffset, 0);
                row.levelingButton:SetPoint("BOTTOMLEFT", levelingOffset, 0);
                row.levelingButton:SetWidth(levelingWidth);
                row.levelingButton:Show();
            end

            -- set profit text
            local profitOffset = self.flexProfitOffset;
            if (profitOffset and skillData.profit) then
                local auctionService = self:GetService("auction");
                local profitFormatted = auctionService:FormatProfit(skillData.profit);
                row.profitLabel:SetText(profitFormatted or "");
                row.profitLabel:ClearAllPoints();
                row.profitLabel:SetPoint("TOPLEFT", profitOffset, -3);
                row.profitLabel:SetWidth(86);
                row.profitLabel:Show();
            else
                row.profitLabel:SetText("");
                row.profitLabel:Hide();
            end

            -- set item text with icon and item color
            local icon = skillData.skill.icon or 134400;
            local itemName;

            -- mining nodes: gold color
            if (skillData.skillId >= 9000000 and skillData.professionId == 186) then
                itemName = "|cffffff00" .. (skillData.skill.name or "?");
            else
                itemName = skillData.skill.itemColor and ("|c" .. skillData.skill.itemColor .. skillData.skill.name) or skillData.skill.name;
            end

            local skillInfo = self:GetService("skills"):GetSkillById(skillData.skillId);
            local itemAmount = skillInfo and skillInfo.itemAmount;
            if (itemAmount and itemAmount > 1) then
                itemName = itemName .. "|r x" .. itemAmount;
            end

            -- availability icon behind the name (seasonal or unavailable recipe)
            local tooltipService = self:GetService("tooltip");
            local availabilityIcon = tooltipService:GetAvailabilityIcon(self:GetService("skills"):GetSkillAvailability(skillInfo), 14);
            if (availabilityIcon ~= "") then
                itemName = itemName .. "|r  " .. availabilityIcon;
            end
            row.itemText:SetText("|T" .. icon .. ":16|t  " .. itemName);

            -- favorite toggle right aligned at the end of the item column (like the guild list)
            local nameWidth = math.min(row.itemText:GetStringWidth() + 6, row.itemText:GetWidth() - 20);
            row.favoriteButton:ClearAllPoints();
            row.favoriteButton:SetPoint("RIGHT", row, "LEFT", itemWidth - 8, 0);
            row.favoriteButton:Hide();

            -- the skill tooltip only shows over the icon and name, not the whole column
            row.itemHover:SetWidth(math.max(24, math.min(itemWidth, nameWidth + 3)));

            -- set difficulty text
            local levelingText = self:GetlevelingText(skillData.skill);
            row.levelingLabel:SetText(levelingText or "");

            -- set recipe labels or zone text for gathering skills
            local recipes = skillData.skill.recipes;
            local zones = skillData.skill.zones;

            -- hide all existing recipe labels for this row
            for _, label in ipairs(row.recipeLabels) do
                label:Hide();
            end
            row.zonesText:Hide();

            -- gathering skills: show zone names
            if (not self.isCompact and zones and #zones > 0 and skillData.skillId >= 9000000) then
                local skillsService = self:GetService("skills");
                local zoneNames = skillsService.zoneNames or {};
                local zoneTextParts = {};
                for _, zoneId in ipairs(zones) do
                    local zoneName = zoneNames[zoneId];
                    if (zoneName) then
                        table.insert(zoneTextParts, zoneName);
                    end
                end
                if (#zoneTextParts > 0) then
                    row.zonesText:SetText(table.concat(zoneTextParts, ", "));
                    row.zonesText:ClearAllPoints();
                    row.zonesText:SetPoint("TOPLEFT", recipeOffset, -3);
                    row.zonesText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -26, -3);
                    row.zonesText:Show();
                end

            -- crafted skills: show the source labels (recipe items, trainer, quest, discovery)
            elseif (not self.isCompact) then
                local sourceLabels = self:GetService("tooltip"):GetSkillSourceLabels(skillData.skill);
                local offsetX = recipeOffset;
                for index, sourceLabel in ipairs(sourceLabels) do
                    do
                        local label = row.recipeLabels[index];
                        if (not label) then
                            label = CreateFrame("Button", nil, row);
                            label:SetHeight(16);
                            label.text = label:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
                            label.text:SetPoint("LEFT", 0, 0);
                            -- source tooltip on the game tooltip (the skill
                            -- tooltip is only shown on the item column now)
                            label:SetScript("OnEnter", function(button)
                                row:SetBackdropColor(0.2, 0.2, 0.2);
                                if (button.source) then
                                    self:GetService("tooltip"):ShowSourceLabelTooltip(button, button.source, true);
                                end
                            end);
                            label:SetScript("OnLeave", function()
                                GameTooltip:Hide();
                                if (not row:IsMouseOver()) then
                                    if (row.bgColor) then
                                        row:SetBackdropColor(row.bgColor, row.bgColor, row.bgColor, 0.5);
                                    end
                                    row.favoriteButton:Hide();
                                end
                            end);
                            label:SetScript("OnClick", function(button)
                                if (IsShiftKeyDown() and self.addon.compat.ChatEdit_GetActiveWindow() and button.recipe and button.recipe.itemLink) then
                                    self.addon.compat.ChatEdit_InsertLink(button.recipe.itemLink);
                                end
                            end);

                            -- keep the row hover glow alive over the label
                            if (row.hoverGlowEnter) then
                                label:HookScript("OnEnter", row.hoverGlowEnter);
                                label:HookScript("OnLeave", row.hoverGlowLeave);
                            end
                            row.recipeLabels[index] = label;
                        end
                        label:ClearAllPoints();
                        label:SetPoint("TOPLEFT", offsetX, -2);
                        local labelText = sourceLabel.text;
                        if (index < #sourceLabels) then
                            labelText = labelText .. ",";
                        end
                        label.text:SetText(labelText);
                        label:SetWidth(label.text:GetStringWidth() + 4);
                        label.source = sourceLabel;
                        label.recipe = sourceLabel.recipe;
                        label:Show();
                        offsetX = offsetX + label.text:GetStringWidth() + 6;
                    end
                end
            end

            -- set bucket list amount
            if (skillData.bucketListAmount) then
                row.bucketText:SetText("|cff00ff00" .. skillData.bucketListAmount .. "|r");
                row.bucketText:Show();
            else
                row.bucketText:SetText("");
                row.bucketText:Hide();
            end

            row:Show();
        end
    end
end

