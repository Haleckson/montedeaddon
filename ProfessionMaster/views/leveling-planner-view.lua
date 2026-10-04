--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local LevelingPlannerView = _G.professionMaster:CreateView("leveling-planner");

-- compact list layout: amount, icon, name, skill range or owned amount, price
local RowHeight = 20;
local IconSize = 16;
local CountWidth = 52;
local InfoWidth = 90;
local PriceWidth = 120;
local ScrollBarClearance = 28;

-- text colors
local CraftedColor = "ff80c0ff";
local OwnedColor = "ff40c040";
local MissingColor = "ffff4040";

--- Show the planner for a character and profession. A plan calculated earlier
--- in this session is shown again (brought up to date with the skill level),
--- only the first opening calculates.
-- @param characterName The character to plan for.
-- @param professionId The profession id.
function LevelingPlannerView:Show(characterName, professionId)
    if (not self.view) then
        self:CreateWindow();
    end

    self.characterName = characterName;
    self.professionId = professionId;

    -- the target chosen last for this profession, otherwise the max level
    self.targetLevel = self:GetService("leveling-planner"):GetTargetLevel(characterName, professionId);
    self.view:Show();
    self.visible = true;
    self:StartTicker();
    if (not self:ShowCachedPlan(false)) then
        self:Recalculate();
    end
end

--- Show the plan of this session, brought up to date like a to do list: done
--- steps are gone, the step in progress needs fewer crafts, learned recipes and
--- trained ranks are no longer listed.
-- @param keepScroll true to keep the scroll position (update while the window is open).
-- @return true if a plan was shown, false if one has to be calculated.
function LevelingPlannerView:ShowCachedPlan(keepScroll)
    local plannerService = self:GetService("leveling-planner");
    local plan = plannerService:GetCachedPlan(self.characterName, self.professionId);
    if (not plan) then
        return false;
    end

    -- a target below the max level that was reached is done: the reopened
    -- window plans on to the next target (the open window shows the goal row)
    local targetDone = #plan.steps == 0 and plan.reachedLevel >= plan.targetLevel and plan.targetLevel < plannerService:GetMaxLevel();
    if (not keepScroll and targetDone) then
        return false;
    end

    -- a reopened window must not show the rows of another plan while items load
    if (not keepScroll) then
        self:ClearList();
    end

    self.plan = plan;
    self.targetLevel = plan.targetLevel;
    self.signature = self:GetService("leveling-planner"):GetPlanSignature(self.characterName, self.professionId);
    self.keepScroll = keepScroll;
    self.progress:Hide();
    self:UpdateHeader();
    self:UpdateStatus();
    self:LoadItemsAndRender();
    return true;
end

--- Update the title, the portrait and the skill range of the header.
function LevelingPlannerView:UpdateHeader()
    local plannerService = self:GetService("leveling-planner");
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");

    -- the plan starts at skill 1 (where learning a profession starts), the header says so too
    local level = math.max(plannerService:GetCurrentLevel(self.characterName, self.professionId) or 0, 1);
    local shortName = self:GetService("player"):GetShortName(self.characterName) or "";
    self.subtitle:SetText(localeService:Get("LevelingPlannerSubtitle", level, self.targetLevel, shortName));

    -- targets: the rank caps above the skill level; a reached target of the
    -- shown plan stays in the list, so the dropdown still names it
    local targetItems = {};
    if (self.targetLevel <= level and self.targetLevel < plannerService:GetMaxLevel()) then
        table.insert(targetItems, { value = self.targetLevel, text = tostring(self.targetLevel) });
    end
    for _, cap in ipairs(plannerService:GetRankCaps(level)) do
        table.insert(targetItems, { value = cap, text = tostring(cap) });
    end
    self.targetSelection:SetItems(targetItems);
    self.targetSelection:SetValue(self.targetLevel);

    -- the profession names the window and shows as portrait (classic style)
    local professionName = professionNamesService:GetProfessionName(self.professionId) or "";
    self.view.titleLabel:SetText(localeService:Get("LevelingPlannerTitle", professionName));
    self:GetService("ui"):SetViewPortrait(self.view, professionNamesService:GetProfessionIcon(self.professionId));
end

--- Hide the planner. A running calculation goes on: its plan is kept for the
--- next opening and the to do list may be waiting for it.
function LevelingPlannerView:Hide()
    if (self.view) then
        self.view:Hide();
    end
    self.visible = false;
    self:StopTicker();
end

--- Create the window once.
function LevelingPlannerView:CreateWindow()
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local scanService = self:GetService("auction-scan");

    local view = uiService:CreateView("PmLevelingPlanner", 560, 640, "", false, true, 540, 380);
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
    self.rows = {};

    -- add close button
    local closeButton = uiService:CreateFlatCloseButton(view, function()
        self:Hide();
    end);
    closeButton:SetHeight(22);
    closeButton:SetWidth(22);
    closeButton:SetPoint("TOPRIGHT", -12, -8);

    -- the classic style keeps the window border clear
    -- (same footer as the Auctionizer window, the sum panel sits in it)
    local sideInset, headerHeight, footerHeight = 12, 40, 40;
    if (uiService:IsForever()) then
        local foreverSide, foreverHeader, foreverFooter = uiService:GetForeverInsets();
        sideInset, headerHeight, footerHeight = foreverSide, foreverHeader - 20, foreverFooter + 10;
    end

    -- profession and level range
    local subtitle = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    subtitle:SetPoint("TOPLEFT", sideInset + 4, -(headerHeight + 20));
    subtitle:SetJustifyH("LEFT");
    self.subtitle = subtitle;

    -- scan button: the planner needs the quantities of the offers, so it scans
    -- itself even when Auctionator or TSM deliver the lowest prices
    local scanButton = uiService:CreateFlatButton(view, localeService:Get("PriceScanButton"), function()
        scanService:StartScan(false);
    end);
    scanButton:SetSize(140, 22);
    scanButton:SetPoint("TOPRIGHT", -sideInset, -headerHeight + 6);
    uiService:BindTooltip(scanButton, function()
        return localeService:Get("LevelingPlannerScanTooltip");
    end);
    self.scanButton = scanButton;

    -- age of the auction house data, right below the scan button
    local status = view:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    status:SetPoint("TOPRIGHT", scanButton, "BOTTOMRIGHT", 0, -5);
    status:SetJustifyH("RIGHT");
    self.status = status;

    -- recalculate button (new skill level, bought reagents)
    local recalculateButton = uiService:CreateFlatButton(view, localeService:Get("LevelingPlannerRecalculate"), function()
        self:Recalculate();
    end);
    recalculateButton:SetSize(120, 22);
    recalculateButton:SetPoint("RIGHT", scanButton, "LEFT", -8, 0);

    -- target of the plan left of the recalculate button: a rank cap above the
    -- skill level (items follow the skill level, see UpdateHeader); a new
    -- target calculates the plan again
    local targetSelection = uiService:CreateDropdown(view, 72, {}, function(value)
        if (value == self.targetLevel) then
            return;
        end
        self.addon:Log("LevelingPlannerView", "SelectTarget", "target of profession %d set to %d", self.professionId, value);
        self.targetLevel = value;
        self:Recalculate();
    end);
    targetSelection:SetPoint("RIGHT", recalculateButton, "LEFT", -8, 0);
    self.targetSelection = targetSelection;

    local targetLabel = view:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    targetLabel:SetPoint("RIGHT", targetSelection, "LEFT", -6, 0);
    targetLabel:SetText(localeService:Get("LevelingPlannerTarget"));

    -- scroll frame with the steps and the reagent list
    local scrollParent, scrollChild, scrollElement = uiService:CreateScrollFrame(view);
    scrollParent:SetPoint("TOPLEFT", sideInset, -(headerHeight + 40));
    scrollParent:SetPoint("BOTTOMRIGHT", -sideInset, footerHeight);
    scrollChild:SetWidth(scrollElement:GetWidth());
    scrollElement:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width);
    end);
    self.scrollElement = scrollElement;
    self.scrollChild = scrollChild;

    -- calculation progress (or failure) in the middle of the emptied list
    local progress = scrollParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    progress:SetPoint("CENTER", scrollParent, "CENTER", 0, 0);
    progress:SetJustifyH("CENTER");
    progress:Hide();
    self.progress = progress;

    -- total cost on a dark panel at the bottom right, like the sum of the Auctionizer window
    local totalFrame = CreateFrame("Frame", nil, view, BackdropTemplateMixin and "BackdropTemplate");
    totalFrame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    });
    totalFrame:SetBackdropColor(0, 0, 0, 0.3);
    totalFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5);
    totalFrame:SetSize(190, 22);
    local footerBottom = uiService:IsForever() and (footerHeight - 28) or 14;
    totalFrame:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -sideInset, footerBottom);
    self.totalFrame = totalFrame;

    -- take the crafts of the plan as shopping list (left, level with the total)
    local bucketListButton = uiService:CreateFlatButton(view, localeService:Get("LevelingPlannerToBucketList"), function()
        self:ApplyToBucketList();
    end);
    local bucketListLabel = bucketListButton:GetFontString();
    bucketListButton:SetSize(math.max(160, (bucketListLabel and bucketListLabel:GetStringWidth() or 0) + 28), 22);
    bucketListButton:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", sideInset, footerBottom);
    bucketListButton:Hide();
    self.bucketListButton = bucketListButton;

    local totalLabel = totalFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    totalLabel:SetPoint("LEFT", totalFrame, "LEFT", 6, 0);
    totalLabel:SetText(localeService:Get("LevelingPlannerSourceTotal"));
    self.totalLabel = totalLabel;

    local total = totalFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    total:SetPoint("RIGHT", totalFrame, "RIGHT", -6, 0);
    total:SetJustifyH("RIGHT");
    self.total = total;

    -- show the remaining steps as small to do list and close the planner
    -- (own character only, nobody else gains the skill points)
    local todoButton = uiService:CreateFlatButton(view, localeService:Get("LevelingPlannerTodoButton"), function()
        self.addon:Log("LevelingPlannerView", "CreateWindow", "switching to the to do list of profession %d", self.professionId);
        self:GetService("leveling-planner"):ShowTodo(self.characterName, self.professionId);
        self:Hide();
    end);
    local todoLabel = todoButton:GetFontString();
    todoButton:SetSize(math.max(100, (todoLabel and todoLabel:GetStringWidth() or 0) + 28), 22);
    todoButton:SetPoint("LEFT", bucketListButton, "RIGHT", 8, 0);
    uiService:BindTooltip(todoButton, function()
        return localeService:Get("LevelingPlannerTodoTooltip");
    end);
    todoButton:Hide();
    self.todoButton = todoButton;

    -- the marks of the total (~ estimated, ? not enough offers) are explained on hover
    totalFrame:EnableMouse(true);
    totalFrame:SetScript("OnEnter", function()
        if (self.totalHints and #self.totalHints > 0) then
            GameTooltip:SetOwner(totalFrame, "ANCHOR_TOP");
            for _, hintLine in ipairs(self.totalHints) do
                GameTooltip:AddLine(hintLine, 1, 1, 1);
            end
            GameTooltip:Show();
        end
    end);
    totalFrame:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    -- to do list: the shown plan follows skill ups, learned recipes, trained
    -- ranks and the bags while the window is open
    self:GetService("leveling-planner"):AddListener(function(reasons)
        local plannerService = self:GetService("leveling-planner");

        -- the own calculation just rendered its plan
        if (reasons.calculated and self.ownCalculationFinished) then
            self.ownCalculationFinished = nil;
            return;
        end
        if (not self.visible or not self.plan or plannerService:IsCalculating()) then
            return;
        end

        -- skill events of other skills (weapon skills) change nothing
        if (not reasons.bags and not reasons.calculated
            and self.signature == plannerService:GetPlanSignature(self.characterName, self.professionId)) then
            return;
        end
        if (not self:ShowCachedPlan(true)) then
            self.addon:Log("LevelingPlannerView", "CreateWindow", "shown plan no longer fits the skill level, recalculating");
            self:Recalculate();
        end
    end);

    -- follow the price scan: button state while it runs, new plan when it finished
    scanService:AddListener(function(service)
        self:UpdateScanButton();
        if (self.visible and not service:IsInProgress() and service.progress == 1) then
            self.addon:Log("LevelingPlannerView", "CreateWindow", "price scan finished, recalculating the plan");
            self:Recalculate();
        end
    end);
end

--- Refresh the scan button and the data age once per second while the window is open.
function LevelingPlannerView:StartTicker()
    if (self.ticker) then
        return;
    end
    self.ticker = C_Timer.NewTicker(1, function()
        self:UpdateScanButton();
        self:UpdateStatus();
    end);
    self:UpdateScanButton();
end

--- Stop the refresh ticker.
function LevelingPlannerView:StopTicker()
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
end

--- Update the scan button text: progress, cooldown or ready.
function LevelingPlannerView:UpdateScanButton()
    if (not self.scanButton) then
        return;
    end

    local localeService = self:GetService("locale");
    local scanService = self:GetService("auction-scan");
    if (scanService:IsInProgress()) then
        self.scanButton:SetText(localeService:Get("PriceScanButtonScanning", math.floor(scanService.progress * 100)));
        return;
    end

    local auctionOpen = self:GetService("auction"):IsOpen();
    local wait = auctionOpen and scanService:GetSecondsUntilNextScan() or 0;
    if (wait > 0) then
        self.scanButton:SetText(localeService:Get("PriceScanButtonCooldown", self:GetService("timer"):FormatTime(wait)));
    else
        self.scanButton:SetText(localeService:Get("PriceScanButton"));
    end
end

--- Update the status line with the age of the auction house data.
function LevelingPlannerView:UpdateStatus()
    local localeService = self:GetService("locale");
    local listingsTime = self:GetService("auction-scan"):GetListingsTime();
    if (listingsTime) then
        local age = self:GetService("timer"):FormatTime(math.max(1, time() - listingsTime), true);
        self.status:SetText(localeService:Get("LevelingPlannerDataAge", age));
    else
        self.status:SetText(localeService:Get("LevelingPlannerNoData"));
    end
end

--- Start a new calculation for the shown character and profession.
function LevelingPlannerView:Recalculate()
    local plannerService = self:GetService("leveling-planner");
    local localeService = self:GetService("locale");

    -- a reached target gives way to the next one (the max level of the client)
    local level = math.max(plannerService:GetCurrentLevel(self.characterName, self.professionId) or 0, 1);
    if (not self.targetLevel or self.targetLevel <= level) then
        self.targetLevel = plannerService:GetTargetLevel(self.characterName, self.professionId);
    end
    self:UpdateHeader();

    -- empty the list, the progress shows in its middle until the new plan is rendered
    self.plan = nil;
    self.bucketListButton:Hide();
    self.todoButton:Hide();
    self:ClearList();
    self:UpdateStatus();
    self.total:SetText("");
    self.totalHints = nil;
    self.progress:SetText(localeService:Get("LevelingPlannerCalculating", 0));
    self.progress:Show();

    plannerService:Calculate(self.characterName, self.professionId, function(fraction)
        self.progress:SetText(localeService:Get("LevelingPlannerCalculating", math.floor(fraction * 100)));
    end, function(plan)
        self.plan = plan;
        self.signature = plannerService:GetPlanSignature(self.characterName, self.professionId);
        self.ownCalculationFinished = true;
        self:UpdateStatus();
        self:LoadItemsAndRender();
    end, self.targetLevel);
end

--- Load the data of every item the plan shows, then render. Rows are never
--- shown with placeholder names; the render waits for the item answers.
function LevelingPlannerView:LoadItemsAndRender()
    local plan = self.plan;
    if (not plan) then
        self:Render();
        return;
    end

    -- collect the items of the plan
    local itemIds = {};
    for _, step in ipairs(plan.steps) do
        if (step.kind == "recipe") then
            itemIds[step.recipe.recipeItemId] = true;
        end
        for reagentId in pairs(step.reagents or {}) do
            itemIds[reagentId] = true;
        end
    end
    for _, reagent in ipairs(plan.reagents) do
        itemIds[reagent.itemId] = true;
    end

    -- ask for the missing ones and render once all answered
    local pending = 0;
    local renderPlan = plan;
    for itemId in pairs(itemIds) do
        if (not self.addon.compat.GetItemInfo(itemId) and C_Item.DoesItemExistByID(itemId)) then
            pending = pending + 1;
            local item = Item:CreateFromItemID(itemId);
            item:ContinueOnItemLoad(function()
                pending = pending - 1;
                if (pending == 0 and self.plan == renderPlan) then
                    self:Render();
                end
            end);
        end
    end

    if (pending == 0) then
        self:Render();
        return;
    end

    -- an item the server never answers must not keep the plan hidden; such rows are left out
    C_Timer.After(3, function()
        if (pending > 0 and self.plan == renderPlan) then
            self.addon:Log("LevelingPlannerView", "LoadItemsAndRender", "%d items did not load, rendering without them", pending);
            pending = 0;
            self:Render();
        end
    end);
end

--- Get the display data of a loaded item.
-- @param itemId The item id.
-- @return name, colored name, icon; nil if the item is not loaded.
function LevelingPlannerView:GetItemDisplay(itemId)
    local name, _, quality, _, _, _, _, _, _, icon = self.addon.compat.GetItemInfo(itemId);
    if (not name) then
        return nil;
    end

    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1];
    local coloredName = color and (color.hex .. name .. "|r") or name;
    return name, coloredName, icon;
end

--- Format a price, "free" for nothing.
-- @param coppers The price in copper.
-- @return formatted text.
function LevelingPlannerView:FormatCost(coppers)
    return self:GetService("tooltip"):FormatSourceCost(coppers);
end

--- Replace the shopping list with the crafts of the plan (the crafts, not the
--- reagents: the shopping list works out the reagents itself), close the
--- planner and refresh every window showing the shopping list.
function LevelingPlannerView:ApplyToBucketList()
    local plan = self.plan;
    if (not plan) then
        return;
    end

    -- crafts of the same recipe in several steps add up; the list counts items
    PM_BucketList = {};
    local skillCount = 0;
    local skillByItem = {};
    for _, step in ipairs(plan.steps) do
        if (step.kind == "craft") then
            local skillId = step.recipe.skillId;
            if (not PM_BucketList[skillId]) then
                skillCount = skillCount + 1;
            end
            PM_BucketList[skillId] = (PM_BucketList[skillId] or 0) + step.crafts * step.recipe.itemAmount;
            if (step.recipe.itemId and step.recipe.itemId ~= 0) then
                skillByItem[step.recipe.itemId] = skillId;
            end
        end
    end

    -- "craft yourself" like the plan: reagents the plan crafts (along the way or
    -- in earlier steps) are watched, the shopping list then crafts them from
    -- their reagents; the others are bought. Items of earlier steps that later
    -- steps use are taken off their own entry, the watched reagent brings them back
    if (not PM_ReagentWatchList) then
        PM_ReagentWatchList = {};
    end
    local watchedCount = 0;
    for _, reagent in ipairs(plan.reagents) do
        local crafted = false;
        for _, source in ipairs(reagent.sources) do
            if (source.kind == "craft" or source.kind == "produced") then
                crafted = true;
            end
            local skillId = skillByItem[reagent.itemId];
            if (source.kind == "produced" and skillId and PM_BucketList[skillId]) then
                local remaining = PM_BucketList[skillId] - source.count;
                PM_BucketList[skillId] = (remaining > 0) and remaining or nil;
            end
        end
        PM_ReagentWatchList[reagent.itemId] = crafted or nil;
        if (crafted) then
            watchedCount = watchedCount + 1;
        end
    end
    self.addon:Log("LevelingPlannerView", "ApplyToBucketList", "shopping list replaced with %d recipes of the plan, %d reagents crafted yourself", skillCount, watchedCount);

    self:Hide();

    -- main window with the shopping list panel and its lists, the database window
    -- (refreshed along with it), an open recipe detail and the missing reagents
    local professionsView = self.addon.professionsView;
    if (professionsView) then
        professionsView:CheckBucketList();
        professionsView:Refresh();
        if (professionsView.skillViewVisible and professionsView.skillView) then
            professionsView.skillView:RefreshBucketListAmount();
        end
    end
    local databaseView = self.addon.databaseView;
    if (databaseView and databaseView.visible and databaseView.detailSkill) then
        databaseView:RenderDetail();
    end
    self:GetService("inventory"):CheckMissingReagents();
end

--- Hide all rows of the list and scroll back to the top.
-- @param keepScroll true to leave height and scroll position alone (the render sets both).
function LevelingPlannerView:ClearList(keepScroll)
    for _, row in ipairs(self.rows) do
        row:Hide();
    end
    if (not keepScroll) then
        self.scrollChild:SetHeight(1);
        self.scrollElement:SetVerticalScroll(0);
    end
end

--- Render the plan as one compact list: the steps in order (crafts, recipes
--- to buy, ranks to train, goal), then the reagents.
function LevelingPlannerView:Render()
    local plan = self.plan;
    local localeService = self:GetService("locale");
    local scrollChild = self.scrollChild;
    local top = 4;
    local rowIndex = 0;

    -- an update of the open list keeps its scroll position
    local keepScroll = self.keepScroll == true;
    local scrollOffset = keepScroll and self.scrollElement:GetVerticalScroll() or 0;
    self.keepScroll = nil;

    self:ClearList(keepScroll);
    if (not plan) then
        self.progress:SetText(localeService:Get("LevelingPlannerFailed"));
        self.progress:Show();
        return;
    end
    self.progress:Hide();
    self.bucketListButton:SetShown(#plan.steps > 0);
    self.todoButton:SetShown(#plan.steps > 0 and self.characterName == self:GetService("player").current);

    -- place the next row (stripes restart per section)
    local function AddRow(stripeIndex)
        rowIndex = rowIndex + 1;
        local row = self:GetRow(rowIndex);
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -top);
        row:SetPoint("RIGHT", scrollChild, "RIGHT", -ScrollBarClearance + 8, 0);
        self:ResetRow(row, stripeIndex);
        row:Show();
        top = top + RowHeight;
        return row;
    end

    -- steps; the goal (or the level the plan gets stuck at) closes them
    local steps = {};
    for _, step in ipairs(plan.steps) do
        table.insert(steps, step);
    end
    table.insert(steps, { kind = plan.reachedLevel >= plan.targetLevel and "goal" or "stuck", level = plan.reachedLevel });
    for index, step in ipairs(steps) do
        self:FillStepRow(AddRow(index), step, plan);
    end

    -- reagents below the steps, with their own golden section line
    if (#plan.reagents > 0) then
        top = top + 8;
        local section = AddRow(nil);
        section:SetBackdropColor(0, 0, 0, 0);
        section.nameText:SetText("|cffffd100" .. localeService:Get("LevelingPlannerReagents") .. "|r");

        local stripeIndex = 0;
        for _, reagent in ipairs(plan.reagents) do
            local name, coloredName, icon = self:GetItemDisplay(reagent.itemId);
            if (name) then
                stripeIndex = stripeIndex + 1;
                self:FillReagentRow(AddRow(stripeIndex), reagent, coloredName, icon);
            end
        end
    end

    scrollChild:SetHeight(top + 4);
    if (keepScroll) then
        local maxOffset = math.max(0, top + 4 - (self.scrollElement:GetHeight() or 0));
        self.scrollElement:SetVerticalScroll(math.min(scrollOffset, maxOffset));
    end

    -- total with its marks, explained in the tooltip of the total
    local totalText = (plan.hasEstimates and "~" or "") .. self:FormatCost(plan.totalCost);
    if (plan.hasMissing) then
        totalText = "|c" .. MissingColor .. "?|r " .. totalText;
    end
    self.total:SetText(totalText);
    self.totalFrame:SetWidth(math.max(190, self.totalLabel:GetStringWidth() + self.total:GetStringWidth() + 30));
    self.totalHints = {};
    if (plan.hasEstimates) then
        table.insert(self.totalHints, localeService:Get("LevelingPlannerEstimateHint"));
    end
    if (plan.hasMissing) then
        table.insert(self.totalHints, "|c" .. MissingColor .. localeService:Get("LevelingPlannerMissingHint") .. "|r");
    end
end

--- Get a pooled list row, created on first use. Columns: amount, icon,
--- name, skill range (or owned amount), price.
-- @param index Row index.
-- @return row frame.
function LevelingPlannerView:GetRow(index)
    local row = self.rows[index];
    if (row) then
        return row;
    end

    row = CreateFrame("Frame", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
    row:SetHeight(RowHeight);
    row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });
    row:EnableMouse(true);

    -- amount first
    local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    countText:SetPoint("LEFT", row, "LEFT", 4, 0);
    countText:SetWidth(CountWidth);
    countText:SetJustifyH("RIGHT");
    row.countText = countText;

    -- icon
    local icon = row:CreateTexture(nil, "ARTWORK");
    icon:SetSize(IconSize, IconSize);
    icon:SetPoint("LEFT", countText, "RIGHT", 6, 0);
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
    row.icon = icon;

    -- price on the right, skill range or owned amount left of it
    local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    priceText:SetPoint("RIGHT", row, "RIGHT", -6, 0);
    priceText:SetJustifyH("RIGHT");
    row.priceText = priceText;

    local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    infoText:SetPoint("RIGHT", row, "RIGHT", -PriceWidth, 0);
    infoText:SetJustifyH("RIGHT");
    row.infoText = infoText;

    -- name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    nameText:SetPoint("RIGHT", row, "RIGHT", -(PriceWidth + InfoWidth), 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    row.nameText = nameText;

    -- hover: skill with reagents and trainers, recipe item, or price breakdown
    row:SetScript("OnEnter", function()
        if (row.onEnter) then
            row.onEnter(row);
        end
    end);
    row:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    -- hover over the price: the tooltip of the row, and for a reagent the
    -- auction house prices the price charts of Auctionizer at the mouse
    local priceHover = CreateFrame("Frame", nil, row);
    priceHover:SetPoint("TOPLEFT", priceText, "TOPLEFT", 0, 2);
    priceHover:SetPoint("BOTTOMRIGHT", priceText, "BOTTOMRIGHT", 0, -2);
    priceHover:EnableMouse(true);
    priceHover:SetScript("OnEnter", function()
        if (row.onEnter) then
            row.onEnter(row, priceHover);
        end
    end);
    priceHover:SetScript("OnLeave", function()
        GameTooltip:Hide();
        self:GetService("auction"):HidePriceChart();
    end);

    self.rows[index] = row;
    return row;
end

--- Reset everything a recycled row may still show.
-- @param row The row.
-- @param stripeIndex Index for the alternating background, nil for none.
function LevelingPlannerView:ResetRow(row, stripeIndex)
    if (stripeIndex) then
        self:GetService("ui"):SetRowColor(row, stripeIndex);
    else
        row:SetBackdropColor(0, 0, 0, 0);
    end
    row.countText:SetText("");
    row.icon:SetTexture(nil);
    row.icon:SetDesaturated(false);
    row.nameText:SetText("");
    row.infoText:SetText("");
    row.priceText:SetText("");
    row.onEnter = nil;
end

--- Anchor the tooltip of a row left of it (top right corner at the row's top left).
-- @param row The hovered row.
function LevelingPlannerView:AnchorTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_NONE");
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -2, 0);
end

--- Fill a step row.
-- @param row The row.
-- @param step The plan step.
-- @param plan The plan.
function LevelingPlannerView:FillStepRow(row, step, plan)
    local localeService = self:GetService("locale");
    local professionIcon = self:GetService("profession-names"):GetProfessionIcon(plan.professionId);

    if (step.kind == "craft") then
        local recipe = step.recipe;
        local skill = recipe.skill;
        row.countText:SetText(step.crafts .. "x");
        row.icon:SetTexture(skill.icon or (recipe.itemId and recipe.itemId ~= 0 and self.addon.compat.GetItemIcon(recipe.itemId)) or professionIcon);
        row.nameText:SetText("|c" .. (skill.itemColor or "ffffffff") .. (skill.name or "") .. "|r");
        row.infoText:SetText(step.fromLevel .. "-" .. step.toLevel);
        row.priceText:SetText(self:FormatCost(step.cost));
        row.onEnter = function()
            self:ShowCraftTooltip(row, step);
        end;
    elseif (step.kind == "recipe") then
        -- buying the recipe sits right before its first craft
        local recipe = step.recipe;
        local _, coloredName, icon = self:GetItemDisplay(recipe.recipeItemId);
        row.countText:SetText("1x");
        row.icon:SetTexture(icon or professionIcon);
        local key = step.owned and "LevelingPlannerStepOwnedRecipe" or "LevelingPlannerStepBuyRecipe";
        row.nameText:SetText(localeService:Get(key, coloredName or recipe.skill.name or ""));
        row.infoText:SetText(tostring(step.level));
        row.priceText:SetText(self:FormatCost(step.cost));
        row.onEnter = function()
            self:AnchorTooltip(row);
            GameTooltip:SetHyperlink("item:" .. recipe.recipeItemId);
            GameTooltip:Show();
        end;
    elseif (step.kind == "rank") then
        row.icon:SetTexture(professionIcon);
        row.nameText:SetText(localeService:Get("LevelingPlannerStepRank", localeService:Get(step.key)));
        row.infoText:SetText(tostring(step.level));
    elseif (step.kind == "goal") then
        row.icon:SetTexture(professionIcon);
        row.nameText:SetText("|cff40c040" .. localeService:Get("LevelingPlannerStepGoal", step.level) .. "|r");
    else
        row.icon:SetTexture(professionIcon);
        row.icon:SetDesaturated(true);
        row.nameText:SetText("|c" .. MissingColor .. localeService:Get("LevelingPlannerStepStuck", step.level) .. "|r");
    end
end

--- Show the tooltip of a craft step: the crafted item (or the spell), the
--- reagents of all crafts of the step and, for a recipe the character does
--- not know yet, where to learn it.
-- @param row The hovered row.
-- @param step The craft step.
function LevelingPlannerView:ShowCraftTooltip(row, step)
    local localeService = self:GetService("locale");
    local recipe = step.recipe;
    local skill = recipe.skill;

    self:AnchorTooltip(row);
    if (skill.itemLink) then
        GameTooltip:SetHyperlink(skill.itemLink);
    elseif (not pcall(GameTooltip.SetSpellByID, GameTooltip, recipe.skillId)) then
        GameTooltip:AddLine(skill.name or "", 1, 1, 1);
    end

    -- reagents of the step; reagents crafted along the way are tinted
    local reagentIds = {};
    for reagentId in pairs(step.reagents) do
        table.insert(reagentIds, reagentId);
    end
    table.sort(reagentIds);
    GameTooltip:AddLine(" ");
    GameTooltip:AddLine(localeService:Get("LevelingPlannerReagents"), 1, 0.82, 0);
    for _, reagentId in ipairs(reagentIds) do
        local _, coloredName = self:GetItemDisplay(reagentId);
        if (coloredName) then
            local amount = step.reagents[reagentId] .. "x";
            if (step.crafted[reagentId]) then
                amount = "|c" .. CraftedColor .. amount .. "|r";
            end
            GameTooltip:AddDoubleLine(coloredName, amount, 1, 1, 1, 1, 1, 1);
        end
    end

    -- where to learn a recipe the character does not know yet
    if (recipe.source == "trainer") then
        for _, line in ipairs(self:GetService("tooltip"):GetSkillSourceLines(skill)) do
            GameTooltip:AddLine(line);
        end
    end

    GameTooltip:Show();
end

--- Fill a reagent row.
-- @param row The row.
-- @param reagent The plan reagent.
-- @param coloredName The item name in quality color.
-- @param icon The item icon.
function LevelingPlannerView:FillReagentRow(row, reagent, coloredName, icon)
    local localeService = self:GetService("locale");
    row.countText:SetText(reagent.count .. "x");
    row.icon:SetTexture(icon);
    row.nameText:SetText(coloredName);
    if (reagent.owned > 0) then
        row.infoText:SetText("|c" .. OwnedColor .. localeService:Get("LevelingPlannerOwned", reagent.owned) .. "|r");
    end

    local priceText = self:FormatCost(reagent.cost);
    if (reagent.hasMissing) then
        priceText = "|c" .. MissingColor .. "?|r " .. priceText;
    elseif (reagent.hasEstimate) then
        priceText = "~" .. priceText;
    end
    row.priceText:SetText(priceText);

    -- where the units come from and what each of them costs
    row.onEnter = function(_, chartOwner)
        self:ShowReagentTooltip(row, reagent, coloredName, chartOwner);
    end;
end

--- Show the price breakdown of a reagent: every source with amount and unit price.
-- @param owner The hovered row.
-- @param reagent The plan reagent.
-- @param coloredName The item name in quality color.
-- @param chartOwner The hovered price of the row, nil for the rest of the row.
function LevelingPlannerView:ShowReagentTooltip(owner, reagent, coloredName, chartOwner)
    self:GetService("tooltip"):ShowPriceSourcesTooltip(owner, reagent, coloredName, chartOwner);
end
