--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local LevelingTodoView = _G.professionMaster:CreateView("leveling-todo");

-- layout of the missing reagents window: rows of 16px below the title. The
-- rows must not overlap: a row left through the overlap still counts as
-- hovered and keeps its highlight
local ViewWidth = 300;
local RowTop = 33;
local RowStep = 16;
local RowHeight = 16;
local IconSize = 12;
local CountWidth = 46;

-- the list shows what comes next, the rest is summed up in one line
local MaxSteps = 15;

--- Show the remaining steps of the leveling plan of a profession as small
--- to do list. The list follows skill ups, learned recipes and trained ranks
--- and closes itself once nothing is left to do.
-- @param characterName The character of the plan.
-- @param professionId The profession id.
function LevelingTodoView:Show(characterName, professionId)
    if (not self.view) then
        self:CreateWindow();
    end

    self.characterName = characterName;
    self.professionId = professionId;
    self.active = true;
    self.signature = nil;

    -- remembered per character: the list comes back after a reload or login
    if (characterName == self:GetService("player").current) then
        PM_CharacterSettings.levelingTodo = professionId;
    end

    self.addon:Log("LevelingTodoView", "Show", "to do list of profession %s shown", tostring(professionId));
    self:Refresh(true);
end

--- Close the list and forget it for the character.
function LevelingTodoView:Close()
    self.active = false;
    if (self.view) then
        self.view:Hide();
    end
    PM_CharacterSettings.levelingTodo = nil;
end

--- Set the background alpha (the setting of the missing reagents window).
function LevelingTodoView:SetBackgroundAlpha(value)
    self.view:SetBackdropColor(0, 0, 0, value);
    self.view:SetBackdropBorderColor(0.5, 0.5, 0.5, value);
end

--- Get the leveling planner view (created on first use, its window only when shown).
function LevelingTodoView:GetPlannerView()
    if (not self.addon.levelingPlannerView) then
        self.addon.levelingPlannerView = self.addon:NewView("leveling-planner");
    end
    return self.addon.levelingPlannerView;
end

--- Create the window once.
function LevelingTodoView:CreateWindow()
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local plannerService = self:GetService("leveling-planner");

    local view = uiService:CreateOverlayView("PmLevelingTodo", ViewWidth, 100, "");
    view:Hide();
    self.view = view;
    self.rows = {};
    self.requestedItems = {};
    self:SetBackgroundAlpha(PM_Settings.backgroundMissingReagents or 0);

    -- close button (shown while the window is hovered)
    local closeButton = uiService:CreateFlatCloseButton(view, function()
        self.addon:Log("LevelingTodoView", "Close", "to do list closed by the player");
        self:Close();
    end);
    closeButton:SetHeight(20);
    closeButton:SetWidth(20);
    closeButton:SetPoint("TOPRIGHT", -12, -8);
    closeButton:Hide();

    -- back to the full planner (left of close, shown while the window is hovered)
    local plannerButton = CreateFrame("Button", nil, view);
    plannerButton:SetSize(18, 18);
    plannerButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0);
    local plannerIcon = plannerButton:CreateTexture(nil, "ARTWORK");
    plannerIcon:SetPoint("TOPLEFT", 2, -2);
    plannerIcon:SetPoint("BOTTOMRIGHT", -2, 2);
    plannerIcon:SetTexture([[Interface\Icons\INV_Misc_Note_01]]);
    plannerButton:SetScript("OnClick", function()
        GameTooltip:Hide();
        self:GetPlannerView():Show(self.characterName, self.professionId);
    end);
    plannerButton:Hide();

    -- solid background and header buttons while hovered, like the missing reagents window
    self.onViewEnter = function()
        self:SetBackgroundAlpha(0.8);
        closeButton:Show();
        plannerButton:Show();
    end;
    self.onViewLeave = function()
        C_Timer.After(0.05, function()
            if (not view:IsVisible() or view:IsMouseOver()) then
                return;
            end
            self:SetBackgroundAlpha(PM_Settings.backgroundMissingReagents or 0);
            closeButton:Hide();
            plannerButton:Hide();
        end);
    end;
    view:SetScript("OnEnter", self.onViewEnter);
    view:SetScript("OnLeave", self.onViewLeave);
    closeButton:HookScript("OnEnter", self.onViewEnter);
    closeButton:HookScript("OnLeave", self.onViewLeave);
    plannerButton:SetScript("OnEnter", function()
        self.onViewEnter();
        GameTooltip:SetOwner(plannerButton, "ANCHOR_BOTTOM");
        GameTooltip:SetText(localeService:Get("LevelingTodoOpenPlanner"));
        GameTooltip:Show();
    end);
    plannerButton:SetScript("OnLeave", function()
        GameTooltip:Hide();
        self.onViewLeave();
    end);

    -- follow the plan: skill ups, trained ranks, learned recipes, a new calculation
    plannerService:AddListener(function(reasons)
        if (not self.active) then
            return;
        end

        -- the bags only matter while a recipe waits to be bought (bought: learn your own recipe)
        local force = reasons.calculated == true or (reasons.bags == true and self.hasRecipeStep == true);
        if (force or reasons.progress) then
            self:Refresh(force);
        end
    end);
end

--- Bring the list up to date.
-- @param force true to render even when skill level, rank and known recipes did not change.
function LevelingTodoView:Refresh(force)
    if (not self.active) then
        return;
    end

    -- skill events of other skills (weapon skills) change nothing
    local plannerService = self:GetService("leveling-planner");
    local signature = plannerService:GetPlanSignature(self.characterName, self.professionId);
    if (not force and signature == self.signature) then
        return;
    end

    local plan = plannerService:GetCachedPlan(self.characterName, self.professionId);
    if (not plan) then
        -- no plan that fits the skill level (any more): calculate one in the
        -- background, the listener renders it; without a result the list closes
        if (not plannerService:IsCalculating()) then
            self.addon:Log("LevelingTodoView", "Refresh", "no plan for the to do list, calculating");
            plannerService:Calculate(self.characterName, self.professionId, function() end, function(newPlan)
                if (not newPlan) then
                    self:Close();
                end
            end);
        end
        return;
    end

    self.signature = signature;
    self:Render(plan);
end

--- Render the remaining steps; the window is as high as its rows.
-- @param plan The plan, already brought up to date.
function LevelingTodoView:Render(plan)
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local professionNamesService = self:GetService("profession-names");

    -- nothing left to do: the list is done
    if (#plan.steps == 0) then
        self.addon:Log("LevelingTodoView", "Render", "no steps left for profession %s, closing the to do list", tostring(self.professionId));
        self:Close();
        return;
    end

    local professionName = professionNamesService:GetProfessionName(self.professionId) or "";
    self.view.titleLabel:SetText(self.addon.shortcut .. localeService:Get("LevelingPlannerTitle", professionName));

    for _, row in ipairs(self.rows) do
        row:Hide();
    end

    -- the next steps, one row each
    self.hasRecipeStep = false;
    local rowCount = math.min(#plan.steps, MaxSteps);
    for index = 1, rowCount do
        self:FillRow(self:GetRow(index), plan.steps[index], plan);
    end

    -- one line for the steps beyond
    if (#plan.steps > MaxSteps) then
        rowCount = rowCount + 1;
        local row = self:GetRow(rowCount);
        self:ResetRow(row);
        row.nameText:SetText("|cffaaaaaa" .. localeService:Get("LevelingTodoMore", #plan.steps - MaxSteps) .. "|r");
        row.hoverGlowDisabled = true;
        row:Show();
    end

    -- window height follows the rows; the classic style keeps a little more room below
    local viewHeight = RowTop + rowCount * RowStep + (uiService:IsForever() and 14 or 12);
    self.view.minHeight = viewHeight;
    self.view:SetHeight(viewHeight);
    self.view:Show();
end

--- Get a pooled row, created on first use: amount, icon, name, skill range.
-- @param index Row index.
-- @return row frame.
function LevelingTodoView:GetRow(index)
    local row = self.rows[index];
    if (row) then
        return row;
    end

    row = CreateFrame("Button", nil, self.view, BackdropTemplateMixin and "BackdropTemplate");
    local top = RowTop + (index - 1) * RowStep;
    row:SetPoint("TOPLEFT", self.view, "TOPLEFT", 10, -top);
    row:SetPoint("BOTTOMRIGHT", self.view, "TOPRIGHT", -10, -(top + RowHeight));
    row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] });
    row:SetBackdropColor(0, 0, 0, 0);

    -- amount first
    local countText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    countText:SetPoint("LEFT", 2, 0);
    countText:SetWidth(CountWidth);
    countText:SetJustifyH("RIGHT");
    countText:SetTextColor(1, 1, 1);
    row.countText = countText;

    -- icon
    local icon = row:CreateTexture(nil, "ARTWORK");
    icon:SetSize(IconSize, IconSize);
    icon:SetPoint("LEFT", countText, "RIGHT", 5, 0);
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
    row.icon = icon;

    -- skill range on the right
    local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    levelText:SetPoint("RIGHT", -6, 0);
    levelText:SetJustifyH("RIGHT");
    levelText:SetTextColor(0.7, 0.7, 0.7);
    row.levelText = levelText;

    -- name (truncated with ellipsis)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0);
    nameText:SetPoint("RIGHT", levelText, "LEFT", -6, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    row.nameText = nameText;

    -- hover: highlight and the tooltip of the step (item, reagents, trainers or the recipe item)
    row:SetScript("OnEnter", function()
        self.onViewEnter();

        -- only one row is highlighted at a time
        for _, otherRow in ipairs(self.rows) do
            if (otherRow ~= row) then
                self:ClearRowHover(otherRow);
            end
        end
        if (not row.hoverGlowDisabled) then
            row:SetBackdropColor(0.3, 0.3, 0.3, 0.5);
        end
        if (row.onEnter) then
            row.onEnter();
        end
    end);
    row:SetScript("OnLeave", function()
        self:ClearRowHover(row);
        GameTooltip:Hide();
        self.onViewLeave();
    end);

    -- shift+click puts the item link into the chat
    row:SetScript("OnMouseDown", function(_, button)
        if (button == "LeftButton" and IsShiftKeyDown() and row.itemLink) then
            self.addon.compat.ChatEdit_InsertLink(row.itemLink);
        end
    end);

    self:GetService("ui"):AttachHoverGlow(row);
    self.rows[index] = row;
    return row;
end

--- Remove the hover highlight of a row. The rows have no hover regions of
--- their own, so leaving a row always ends its highlight (the hover glow of
--- the library keeps it while the mouse is still inside the row rectangle).
function LevelingTodoView:ClearRowHover(row)
    row:SetBackdropColor(0, 0, 0, 0);
    if (row.hoverGlowHide) then
        row.hoverGlowHide();
    end
end

--- Reset everything a recycled row may still show.
function LevelingTodoView:ResetRow(row)
    row.countText:SetText("");
    row.icon:SetTexture(nil);
    row.nameText:SetText("");
    row.levelText:SetText("");
    row.onEnter = nil;
    row.itemLink = nil;
    row.hoverGlowDisabled = nil;
end

--- Fill the row of a step.
-- @param row The row.
-- @param step The plan step (craft, recipe to buy, rank to train).
-- @param plan The plan.
function LevelingTodoView:FillRow(row, step, plan)
    local localeService = self:GetService("locale");
    local plannerView = self:GetPlannerView();
    local professionIcon = self:GetService("profession-names"):GetProfessionIcon(plan.professionId);
    self:ResetRow(row);

    if (step.kind == "craft") then
        local recipe = step.recipe;
        local skill = recipe.skill;
        row.countText:SetText(step.crafts .. "x");
        row.icon:SetTexture(skill.icon or (recipe.itemId and recipe.itemId ~= 0 and self.addon.compat.GetItemIcon(recipe.itemId)) or professionIcon);
        row.nameText:SetText("|c" .. (skill.itemColor or "ffffffff") .. (skill.name or "") .. "|r");
        row.levelText:SetText(step.fromLevel .. "-" .. step.toLevel);
        row.itemLink = skill.itemLink;
        row.onEnter = function()
            plannerView:ShowCraftTooltip(row, step);
        end;
    elseif (step.kind == "recipe") then
        -- the recipe to buy (or to learn once it is in the bags) before its first craft
        local recipe = step.recipe;
        local _, coloredName, icon = plannerView:GetItemDisplay(recipe.recipeItemId);
        if (not coloredName) then
            self:RequestItem(recipe.recipeItemId);
        end
        self.hasRecipeStep = true;
        row.countText:SetText("1x");
        row.icon:SetTexture(icon or professionIcon);
        local key = step.owned and "LevelingPlannerStepOwnedRecipe" or "LevelingPlannerStepBuyRecipe";
        row.nameText:SetText(localeService:Get(key, coloredName or recipe.skill.name or ""));
        row.levelText:SetText(tostring(step.level));
        row.onEnter = function()
            plannerView:AnchorTooltip(row);
            GameTooltip:SetHyperlink("item:" .. recipe.recipeItemId);
            GameTooltip:Show();
        end;
    else
        -- the next rank to train at the trainer
        row.icon:SetTexture(professionIcon);
        row.nameText:SetText(localeService:Get("LevelingPlannerStepRank", localeService:Get(step.key)));
        row.levelText:SetText(tostring(step.level));
        row.hoverGlowDisabled = true;
    end

    row:Show();
end

--- Request the data of an item once and render again when it arrives (the
--- name of a recipe item may be missing right after the login).
-- @param itemId The item id.
function LevelingTodoView:RequestItem(itemId)
    if (not itemId or self.requestedItems[itemId] or not C_Item.DoesItemExistByID(itemId)) then
        return;
    end

    self.requestedItems[itemId] = true;
    local item = Item:CreateFromItemID(itemId);
    item:ContinueOnItemLoad(function()
        self:Refresh(true);
    end);
end
