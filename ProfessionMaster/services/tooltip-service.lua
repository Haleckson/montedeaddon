--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]
-- create service
local TooltipService = _G.professionMaster:CreateService("tooltip");

-- availability icons: recipes only sold during a holiday, recipes no player can get
local SeasonalIcon = "Interface\\Icons\\INV_Misc_Gift_01";
local UnavailableIcon = "Interface\\RaidFrame\\ReadyCheck-NotReady";

--- Initialize service.
function TooltipService:Initialize()
    self.watching = false;
    self.currentText = nil;
    self.currentTextLine = nil;
    self.shiftWasDown = false;
    self.lastSeenTooltipText = nil;
    self.gatheringOriginalLines = nil;
    self.gatheringNodeDataCache = nil;
    self.gatheringNodeText = nil;
    self.refreshingGathering = false;
    self.showingGathering = false;

    -- create secondary tooltip for dual-tooltip display
    local secondaryTooltip = CreateFrame("GameTooltip", "PmSecondaryTooltip", UIParent, "GameTooltipTemplate");
    secondaryTooltip:SetFrameStrata("TOOLTIP");
    self.secondaryTooltip = secondaryTooltip;

    -- create hidden scratchpad tooltip for reading item lines without disturbing secondaryTooltip
    local scratchTooltip = CreateFrame("GameTooltip", "PmScratchTooltip", UIParent, "GameTooltipTemplate");
    scratchTooltip:SetFrameStrata("TOOLTIP");
    self.scratchTooltip = scratchTooltip;

    self.tooltips = { 
        GameTooltip, 
        ItemRefTooltip, 
        ShoppingTooltip1, 
        ShoppingTooltip2, 
        ShoppingTooltip3 
    };
end

-- Watch tooltip.
function TooltipService:WatchTooltip()
    -- check if already watching
    if (self.watching) then
        return;
    end

    -- set watching
    self.watching = true;

    -- the modern client (WoW Forever) has no OnTooltipSet* scripts, tooltips are
    -- filled from tooltip data and announce it through the data processor
    local usesDataProcessor = TooltipDataProcessor ~= nil and not GameTooltip:HasScript("OnTooltipSetItem");
    if (usesDataProcessor) then
        self:WatchTooltipData();
    end

    -- hook tooltips
    for _, tooltip in ipairs(self.tooltips) do
        if (not usesDataProcessor) then
            -- hook set item
            tooltip:HookScript("OnTooltipSetItem", function (_self)
                if _self["ProfessionMaster"] then
                    return;
                end
                _self["ProfessionMaster"] = true;
                self:CheckTooltip(_self);
            end)

            -- hook set spell
            tooltip:HookScript("OnTooltipSetSpell", function (_self)
                if _self["ProfessionMaster"] then
                    return;
                end
                _self["ProfessionMaster"] = true;
                self:CheckTooltip(_self);
            end)
        end

        -- hook tooltip cleared
        tooltip:HookScript("OnTooltipCleared", function (_self)
            _self["ProfessionMaster"] = nil;
            _self["PmGathering"] = nil;
        end)
    end

    -- clear gathering state when GameTooltip actually disappears (not just redrawn)
    GameTooltip:HookScript("OnHide", function()
        self:ClearGatheringState();
    end)

    -- clear gathering state when the tooltip content is rebuilt for a new target
    -- (e.g. moving from a gathering node to an npc without the tooltip hiding);
    -- skip while our own code rebuilds the same tooltip content; resetting the
    -- last seen text makes the poll below re-detect the new content
    GameTooltip:HookScript("OnTooltipCleared", function()
        if (self.refreshingGathering or self.showingGathering) then return; end
        self.lastSeenTooltipText = nil;
        self:ClearGatheringState();
    end)

    -- hook unit tooltip for player professions (option 4)
    if (not usesDataProcessor) then
        GameTooltip:HookScript("OnTooltipSetUnit", function(_self)
            if (not self:IsTooltipOptionActive("tooltipShowPlayerProfessions")) then return; end
            self:CheckUnitTooltip(_self);
        end)
    end

    -- catch lua re-shows of an already visible tooltip (own refreshes, other
    -- addons) so gathering lines are re-added right away; the engine shows
    -- world tooltips without going through the lua Show() method, so the
    -- reliable detection for those is the per-frame poll below
    hooksecurefunc(GameTooltip, "Show", function(_self)
        self:CheckShownTooltipForGathering(_self);
    end)

    -- monitor the visible tooltip every frame (poll only runs while a tooltip
    -- is shown): detect world gathering nodes by their first line — world
    -- tooltips get no reliable show/set events and may fill their text only
    -- after OnShow — and refresh our lines when the shift key state changes
    local shiftFrame = CreateFrame("Frame");
    shiftFrame:Hide();
    shiftFrame:SetScript("OnUpdate", function()
        -- detect gathering nodes once per tooltip content (one GetText per frame)
        local textLeft1 = GameTooltipTextLeft1;
        local text = self:ReadText(textLeft1);
        if (text ~= self.lastSeenTooltipText) then
            self.lastSeenTooltipText = text;
            self:CheckShownTooltipForGathering(GameTooltip);
        end

        -- refresh our tooltip content when the shift key state changes
        local shiftDown = IsShiftKeyDown();
        if (shiftDown ~= self.shiftWasDown) then
            self.shiftWasDown = shiftDown;
            self:RefreshVisibleTooltip();
        end
    end)
    GameTooltip:HookScript("OnShow", function()
        -- the tooltip was just built with the current shift state, so only
        -- future shift changes need a refresh
        self.shiftWasDown = IsShiftKeyDown();
        self.lastSeenTooltipText = nil;
        self.gatheringVariantRetries = nil;
        shiftFrame:Show();
    end)
    GameTooltip:HookScript("OnHide", function()
        self.lastSeenTooltipText = nil;
        shiftFrame:Hide();
    end)
end

--- Read the text of a tooltip line. The modern client hands out secret values
--- for protected content (auras and units in combat), which raise an error on
--- any comparison or string operation, so those count as no text.
-- @param fontString Font string of the line (may be nil).
-- @return Text or nil.
function TooltipService:ReadText(fontString)
    local text = fontString and fontString:GetText();
    if (issecretvalue and issecretvalue(text)) then
        return nil;
    end
    return text;
end

--- Read the node name from the title of a gathering node tooltip. The map
--- tooltips put an icon (e.g. an arrow for a node above or below the player)
--- as texture code in front of the name, which is removed here.
-- @param fontString Font string of the title line (may be nil).
-- @return Name without leading icons or nil.
function TooltipService:ReadNodeName(fontString)
    local text = self:ReadText(fontString);
    if (not text) then
        return nil;
    end
    local count;
    repeat
        text, count = string.gsub(text, "^%s*|T.-|t%s*", "");
    until (count == 0);
    return text;
end

--- Watch item, spell and unit tooltips through the tooltip data processor of
--- the modern client. The post calls fire for every tooltip of the ui, so only
--- the watched tooltips are handled.
function TooltipService:WatchTooltipData()
    local watched = {};
    for _, tooltip in ipairs(self.tooltips) do
        watched[tooltip] = true;
    end

    -- item and spell tooltips
    -- in combat the client hands out secret values for units and auras, which
    -- break every lookup, so the tooltips stay untouched then
    local function OnItemOrSpell(tooltip)
        if (not watched[tooltip] or tooltip["ProfessionMaster"] or self.addon.inCombat) then
            return;
        end
        tooltip["ProfessionMaster"] = true;
        self:CheckTooltip(tooltip);
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemOrSpell);
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnItemOrSpell);

    -- unit tooltip for player professions (option 4)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if (tooltip ~= GameTooltip or self.addon.inCombat or not self:IsTooltipOptionActive("tooltipShowPlayerProfessions")) then return; end
        self:CheckUnitTooltip(tooltip);
    end);
    self.addon:Log("TooltipService", "WatchTooltipData", "tooltips watched through the tooltip data processor");
end

--- Find the gathering node a tooltip title belongs to: the node of that name,
--- or the base node of a variant (models/gathering-node-variants.lua, e.g. the
--- withered herbs and meager veins of the WoW Forever starting zones). A
--- variant is only accepted when the tooltip also names the profession, and is
--- remembered under its own name afterwards.
-- @param tooltip Tooltip showing the node.
-- @param text First line of the tooltip.
-- @return Node data of the lookup or nil.
function TooltipService:FindGatheringNode(tooltip, text)
    local nodeData = self.gatheringNodeLookup[text];
    if (nodeData or not self.gatheringVariantNodes) then
        return nodeData;
    end

    for _, variant in ipairs(self.gatheringVariantNodes) do
        if (string.find(text, variant.name, 1, true)) then
            -- the profession line can arrive a moment after the title, so the
            -- poll looks at the same title a few more times
            if (self:HasTooltipLineWith(tooltip, variant.professionName)) then
                self.gatheringNodeLookup[text] = variant.data;
                self.gatheringVariantRetries = nil;
                self.addon:Log("TooltipService", "FindGatheringNode", "%s counts as a variant of %s", text, variant.name);
                return variant.data;
            end
            self.gatheringVariantRetries = (self.gatheringVariantRetries or 0) + 1;
            if (self.gatheringVariantRetries <= 10) then
                self.lastSeenTooltipText = nil;
            end
            return nil;
        end
    end
    self.gatheringVariantRetries = nil;
    return nil;
end

--- Check whether a line below the title of a tooltip contains a text.
-- @param tooltip Tooltip to read.
-- @param needle Text to look for (plain, no pattern).
-- @return True when found.
function TooltipService:HasTooltipLineWith(tooltip, needle)
    local tooltipName = tooltip:GetName();
    if (not tooltipName or not needle or needle == "") then
        return false;
    end
    for i = 2, tooltip:NumLines() do
        local lineText = self:ReadText(_G[tooltipName .. "TextLeft" .. i]);
        if (lineText and string.find(lineText, needle, 1, true)) then
            return true;
        end
    end
    return false;
end

--- Check a shown GameTooltip for a world gathering node (mining vein, herb)
--- and save/add the gathering info.
function TooltipService:CheckShownTooltipForGathering(tooltip)
    if (tooltip["ProfessionMaster"]) then return; end
    if (tooltip["PmGathering"]) then return; end
    if (self.showingGathering or self.refreshingGathering) then return; end

    -- read first line of the tooltip
    local textLeft1 = GameTooltipTextLeft1;
    if (not textLeft1) then return; end
    local text = self:ReadNodeName(textLeft1);
    if (not text or text == "") then return; end

    -- build lookup on first use
    if (not self.gatheringNodeLookup) then
        self:BuildGatheringNodeLookup();
    end

    -- check if this matches a known gathering node or a variant of one
    if (not self.gatheringNodeLookup or not self:FindGatheringNode(tooltip, text)) then
        -- tooltip is for something else, clear stale gathering state
        if (self.gatheringNodeText) then
            self:ClearGatheringState();
        end
        return;
    end

    -- save original lines only if this is a fresh tooltip (not our own re-show)
    if (text ~= self.gatheringNodeText) then
        self:SaveOriginalTooltipLines(tooltip);
        self.gatheringNodeText = text;
        self.gatheringNodeDataCache = self.gatheringNodeLookup[text];
    end

    -- always append the remaining skill points to the requires line,
    -- independent of the gathering tooltip setting
    local requiresChanged = self:AddSkillPointsLeftToRequiresLine(tooltip, self.gatheringNodeDataCache);

    -- add gathering info only if the option is currently active
    if (self:IsTooltipOptionActive("tooltipShowGatheringNodes")) then
        self:CheckGatheringNodeTooltip(tooltip, text);
    elseif (requiresChanged) then
        -- re-layout the tooltip for the longer line without re-triggering our hooks
        self.showingGathering = true;
        tooltip:Show();
        self.showingGathering = false;
    end
end

--- Append the remaining skill points until the next difficulty stage to the
--- "Requires <profession>" line of a gathering node tooltip. Shown whenever
--- the own character has the profession, independent of the tooltip settings.
-- @param tooltip Tooltip to modify.
-- @param nodeData Gathering node lookup entry (difficulty, professionId).
-- @return True if a line was changed (tooltip needs a re-layout via Show).
function TooltipService:AddSkillPointsLeftToRequiresLine(tooltip, nodeData)
    if (not nodeData or not nodeData.difficulty or not nodeData.professionId) then
        return false;
    end

    -- only for own professions with a known level
    local professionLevels = PM_CharacterSettings and PM_CharacterSettings.professionLevels;
    local level = professionLevels and professionLevels[nodeData.professionId];
    if (not level or level <= 0) then
        return false;
    end

    -- find the remaining points until the next stage: below orange the target
    -- is orange (gatherable), then yellow, green, gray; gray has no next stage
    local pointsLeft = nil;
    for i = 1, 4 do
        local threshold = nodeData.difficulty[i];
        if (threshold and level < threshold) then
            pointsLeft = threshold - level;
            break;
        end
    end
    if (not pointsLeft) then
        return false;
    end

    -- find the requires line by the localized profession name
    local professionName = self:GetService("profession-names"):GetProfessionName(nodeData.professionId);
    local tooltipName = tooltip:GetName();
    if (not professionName or not tooltipName) then
        return false;
    end
    -- locale Get formats itself, so the number is passed straight through
    local suffix = " (" .. self:GetService("locale"):Get("TooltipSkillPointsLeft", pointsLeft) .. ")";
    for i = 2, tooltip:NumLines() do
        local lineObj = _G[tooltipName .. "TextLeft" .. i];
        local lineText = self:ReadText(lineObj);
        if (lineText and string.find(lineText, professionName, 1, true)) then
            -- skip when already appended (lua re-shows without content change)
            if (string.find(lineText, suffix, 1, true)) then
                return false;
            end
            lineObj:SetText(lineText .. suffix);
            return true;
        end
    end
    return false;
end

--- Get the item, spell or unit a tooltip shows. On the modern client only
--- GameTooltip style tooltips still have the methods, the shopping tooltips
--- need the tooltip util.
-- @param tooltip Tooltip to read.
-- @param kind "Item", "Spell" or "Unit".
-- @return Name and link (item), spell id (spell) or unit token (unit).
function TooltipService:GetDisplayed(tooltip, kind)
    local method = tooltip["Get" .. kind];
    if (method) then
        return method(tooltip);
    end
    local reader = TooltipUtil and TooltipUtil["GetDisplayed" .. kind];
    if (reader) then
        return reader(tooltip);
    end
    return nil;
end

-- Check tooltip.
function TooltipService:CheckTooltip(tooltip)
    -- prepare skill
    local skillId, skill, professionId = nil;
    local itemId = nil;

    -- check for item link (use actual tooltip, not hardcoded GameTooltip)
    local _, itemLink = self:GetDisplayed(tooltip, "Item");
    if (itemLink) then
        -- extract item id from link
        itemId = tonumber(itemLink:match("item:(%d+)"));

        -- find skill by item link
        skillId, skill, professionId = self:GetService("profession-query"):FindSkillByItemLink(itemLink);
    end

    -- check for spell id (direct lookup, works for all professions including smelting)
    if (not skill) then
        local _, spellId = self:GetDisplayed(tooltip, "Spell");
        if (spellId) then
            skillId, skill, professionId = self:GetService("profession-query"):FindSkillByIdOrItemId(spellId, nil);
        end
    end

    -- fallback: text-based lookup via tooltip lines
    if (not skill) then
        local tooltipName = tooltip:GetName();
        if (tooltipName) then
            local text1Obj = _G[tooltipName .. "TextLeft1"];
            local text1 = self:ReadText(text1Obj);
            if (text1 and string.find(text1, ":")) then
                skillId, skill, professionId = self:GetService("profession-query"):FindSkillByName(text1);
            end
        end
    end

    -- option 1: show players who can craft this
    if (skill and professionId and self:IsTooltipOptionActive("tooltipShowPlayers")) then
        local professionQueryService = self:GetService("profession-query");
        local players = professionQueryService:GetSkillPlayers(professionId, skillId);
        local playerNames = self:GetService("player"):CombinePlayerNames(players, 5);
        if (#playerNames > 0) then
            local localeService = self:GetService("locale");
            tooltip:AddLine("|n|cffDA8CFF" .. localeService:Get("TooltipPlayers") .. "|r " .. table.concat(playerNames, ", "));
        end
    end

    -- option 3: show what recipes use this item as a reagent
    if (itemId and self:IsTooltipOptionActive("tooltipShowReagentFor")) then
        self:AddReagentForToTooltip(tooltip, itemId);
    end
end

--- Check unit tooltip to show player professions (option 4).
function TooltipService:CheckUnitTooltip(tooltip)
    -- the modern client hands out the unit token and name as secret values
    -- whenever it restricts unit data, not only in combat; no api accepts them
    local _, unit = self:GetDisplayed(tooltip, "Unit");
    if (not unit or (issecretvalue and issecretvalue(unit)) or not UnitIsPlayer(unit)) then return; end

    -- get player name with realm
    local playerService = self:GetService("player");
    local fullName = GetUnitName(unit, true);
    if (issecretvalue and issecretvalue(fullName)) then return; end
    local unitName = playerService:GetLongName(fullName);
    if (not unitName) then return; end

    -- build player→professions cache if needed
    if (not self.playerProfessionsCache) then
        self:BuildPlayerProfessionsCache();
    end

    local playerProfessionIds = self.playerProfessionsCache[unitName];
    if (not playerProfessionIds or next(playerProfessionIds) == nil) then return; end

    local professionNamesService = self:GetService("profession-names");
    local professionIds = professionNamesService:GetProfessionIdsToShow();
    local professionNames = {};

    for _, professionId in ipairs(professionIds) do
        -- skip secondary professions (cooking=185, first aid=129)
        if (professionId ~= 185 and professionId ~= 129) then
            if (playerProfessionIds[professionId]) then
                local professionName = professionNamesService:GetProfessionName(professionId);
                if (professionName) then
                    table.insert(professionNames, professionName);
                end
            end
        end
    end

    if (#professionNames > 0) then
        local localeService = self:GetService("locale");
        tooltip:AddLine("|cffDA8CFF" .. localeService:Get("TooltipProfessions") .. "|r |cffffffff" .. table.concat(professionNames, ", ") .. "|r");
    end
end

--- Build a cached reverse index: playerName → set of professionIds.
function TooltipService:BuildPlayerProfessionsCache()
    self.playerProfessionsCache = {};
    local playerService = self:GetService("player");

    -- from own professions
    for playerName, professions in pairs(playerService.node.own) do
        local fullName = playerService:GetLongName(playerName);
        if (not self.playerProfessionsCache[fullName]) then
            self.playerProfessionsCache[fullName] = {};
        end
        for professionId, _ in pairs(professions) do
            self.playerProfessionsCache[fullName][professionId] = true;
        end
    end

    -- from guildmates (player-centric structure)
    for playerName, professions in pairs(playerService.node.guildmates) do
        local fullName = playerService:GetLongName(playerName);
        if (not self.playerProfessionsCache[fullName]) then
            self.playerProfessionsCache[fullName] = {};
        end
        for professionId, _ in pairs(professions) do
            self.playerProfessionsCache[fullName][professionId] = true;
        end
    end
end

--- Fill tooltip.
function TooltipService:ShowTooltip(tooltip, professionId, skillId, skillMeta, players)
    -- gathering skills: show custom tooltip with node/herb name and difficulty levels
    if (skillId and skillId >= 9000000) then
        self:ShowGatheringTooltip(tooltip, skillMeta);
        return;
    end

    -- tbc+: use native hyperlink tooltips
    if (self.addon.isBccAtLeast) then
        if (skillMeta.skillLink) then
            tooltip:SetHyperlink(skillMeta.skillLink);
            return;
        end
        if (skillMeta.itemLink) then
            tooltip:SetHyperlink(skillMeta.itemLink);
            return;
        end
    end

    -- vanilla: build custom tooltip with profession header, description, reagents, and item info
    self:GetSpellDescriptionAsync(skillId, function(spellDescription)
        tooltip:ClearLines();
        local professionName = self:GetService("profession-names"):GetProfessionName(professionId);
        tooltip:SetText((professionName or "") .. ": " .. (skillMeta.name or ""));

        -- add spell description (e.g. what an enchantment does)
        if (spellDescription) then
            tooltip:AddLine("|cffffd100" .. spellDescription .. "|r", nil, nil, nil, true);
        end

        -- add reagents
        self:GetTooltipReagents(skillId, function(reagents)
            if (reagents) then
                tooltip:AddLine("|cffffffff" .. SPELL_REAGENTS .. reagents, nil, nil, nil, true);
            end

            -- add item info below a blank line separator (wait for item to load)
            if (skillMeta.itemLink) then
                local itemId = tonumber(skillMeta.itemLink:match("item:(%d+)"));
                if (itemId and C_Item.DoesItemExistByID(itemId)) then
                    local item = Item:CreateFromItemID(itemId);
                    item:ContinueOnItemLoad(function()
                        tooltip:AddLine(" ");
                        self:AppendItemTooltipLines(tooltip, skillMeta.itemLink);
                        self:AddPlayersToTooltip(tooltip, players);
                        tooltip:Show();
                    end);
                    return;
                end
            end

            -- no item or item not available
            self:AddPlayersToTooltip(tooltip, players);
            tooltip:Show();
        end);
    end);
end

--- Add players line to tooltip with blank line separator and purple header.
function TooltipService:AddPlayersToTooltip(tooltip, players)
    if (not players) then return; end
    local playerNames = self:GetService("player"):CombinePlayerNames(players, 5);
    if (#playerNames > 0) then
        tooltip:AddLine(" ");
        tooltip:AddLine("|cffDA8CFF" .. self:GetService("locale"):Get("SkillViewPlayers") .. ":|r " .. table.concat(playerNames, ", "), nil, nil, nil, true);
    end
end

--- Append item tooltip lines from a hidden tooltip to the target tooltip.
function TooltipService:AppendItemTooltipLines(tooltip, itemLink)
    for _, line in ipairs(self:GetHyperlinkTooltipLines(itemLink)) do
        if (line.right) then
            tooltip:AddDoubleLine(line.left, line.right, line.lr, line.lg, line.lb, line.rr, line.rg, line.rb);
        else
            tooltip:AddLine(line.left, line.lr, line.lg, line.lb, true);
        end
    end
end

-- Get tooltip reagents.
function TooltipService:GetTooltipReagents(skillId, callback)
    -- get skills service
    local skillsService = self:GetService("skills");

    -- get skill reagents
    local skillInfo = skillsService:GetSkillById(skillId);
    if (not skillInfo) then
        callback(nil);
        return;
    end

    -- scan inventory
    local inventoryService = self:GetService("inventory");
    inventoryService:ScanInventory();

    -- count reagents
    local reagentCount = 0;
    if skillInfo.reagents then 
        for _ in pairs(skillInfo.reagents) do
            reagentCount = reagentCount + 1;
        end

        -- iterate skill reagents
        local result = {};
        for reagentItemId, reagentAmount in pairs(skillInfo.reagents) do
            -- check if item id known
            if (C_Item.DoesItemExistByID(reagentItemId)) then
                -- get item data
                local reagentItem = Item:CreateFromItemID(reagentItemId);
                if (not reagentItem:IsItemEmpty()) then
                    pcall(function()
                        -- wait until loaded
                        reagentItem:ContinueOnItemLoad(function()
                            -- prepare reagent text
                            local reagentText = "";

                            -- check if inventory amount is not high enough
                            local lowStocks = (inventoryService.inventory[reagentItemId] or 0) < reagentAmount;
                            if (lowStocks) then
                                reagentText = "|cFFFF0000";
                            end

                            -- add reagent name
                            reagentText = reagentText .. reagentItem:GetItemName();

                            -- add reagent amount
                            if (reagentAmount > 1) then
                                reagentText = reagentText .. " (" .. reagentAmount .. ")";
                            end

                            -- reset color
                            if (lowStocks) then
                                reagentText = reagentText .. "|r";
                            end

                            -- add regent text
                            table.insert(result, reagentText);
                            if (#result >= reagentCount) then
                                callback(table.concat(result, ", "));
                            end
                        end);
                    end);
                end
            end
        end
    else
        callback(nil);
    end
end

--- Show a custom recipe source tooltip on the given owner frame.
-- @param owner Frame to anchor the tooltip to.
-- @param recipe Table with name, itemColor and the source fields of models/recipe-sources (vendors, drops, zoneDrops, worldDrop, quests, objects, containers, fishing, pickpocket, crafted, unobtainable).
function TooltipService:ShowRecipeSourceTooltip(owner, recipe, anchorLeft)
    if (not recipe or not recipe.name) then return; end

    if (anchorLeft) then
        -- tooltip hangs below the row with its top-right corner at the
        -- element's bottom-left
        GameTooltip:SetOwner(owner, "ANCHOR_NONE");
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 0, 2);
    else
        GameTooltip:SetOwner(owner, "ANCHOR_TOPRIGHT");
    end
    GameTooltip:ClearLines();

    -- title line in recipe color
    local r, g, b = self:HexToRgb(recipe.itemColor or "FF1EFF00");
    GameTooltip:AddLine(recipe.name, r, g, b, true);

    -- source sections
    for _, line in ipairs(self:GetRecipeSourceLines(recipe)) do
        GameTooltip:AddLine(line);
    end

    GameTooltip:Show();
end

--- Show the source tooltip of a skill without recipe item: trainers, quests,
--- discovery, learned with the profession or not available.
-- @param owner Frame the tooltip is anchored to.
-- @param skill Skill wrapper (with sources, name).
-- @param anchorLeft True to hang the tooltip below the owner with its top-right corner at the owner's bottom-left.
function TooltipService:ShowSkillSourceTooltip(owner, skill, anchorLeft)
    local sources = skill and skill.sources;
    if (not sources) then return; end

    if (anchorLeft) then
        GameTooltip:SetOwner(owner, "ANCHOR_NONE");
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 0, 2);
    else
        GameTooltip:SetOwner(owner, "ANCHOR_TOPRIGHT");
    end
    GameTooltip:ClearLines();
    GameTooltip:AddLine(skill.name or "", 1, 1, 1, true);

    -- source sections
    for _, line in ipairs(self:GetSkillSourceLines(skill)) do
        GameTooltip:AddLine(line);
    end

    GameTooltip:Show();
end

--- Show the tooltip of a source label of the source column (recipe item or skill source).
-- @param owner Frame the tooltip is anchored to.
-- @param label Label entry from GetSkillSourceLabels.
-- @param anchorLeft See ShowRecipeSourceTooltip.
function TooltipService:ShowSourceLabelTooltip(owner, label, anchorLeft)
    if (not label) then return; end
    if (label.recipe) then
        self:ShowRecipeSourceTooltip(owner, label.recipe, anchorLeft);
    elseif (label.skill) then
        self:ShowSkillSourceTooltip(owner, label.skill, anchorLeft);
    end
end

--- Add "reagent for" info to a tooltip (option 3).
function TooltipService:AddReagentForToTooltip(tooltip, reagentItemId)
    local skillsService = self:GetService("skills");
    local skillIds = skillsService:GetSkillIdsByReagentItemId(reagentItemId);
    if (not skillIds or #skillIds == 0) then return; end

    local localeService = self:GetService("locale");
    local names = {};
    local count = 0;
    local truncated = false;

    for _, skillId in ipairs(skillIds) do
        if (count >= 5) then
            truncated = true;
            break;
        end
        local skillData = skillsService:GetSkillById(skillId);
        if (skillData and skillData.name) then
            table.insert(names, skillData.name);
            count = count + 1;
        end
    end

    -- append "..." to the last entry if truncated
    if (truncated and #names > 0) then
        names[#names] = names[#names] .. " ...";
    end

    -- single entry: header and name on same line
    if (#names == 1) then
        tooltip:AddLine("|n|cffDA8CFF" .. localeService:Get("TooltipReagentFor") .. "|r |cffffffff" .. names[1] .. "|r");
    else
        -- multiple entries: header on its own line, each name below
        tooltip:AddLine("|n|cffDA8CFF" .. localeService:Get("TooltipReagentFor") .. "|r");
        for i = 1, #names do
            tooltip:AddLine("|cffffffff" .. names[i] .. "|r");
        end
    end
end

--- Show a custom tooltip for gathering skills (mining nodes, herbs).
function TooltipService:ShowGatheringTooltip(tooltip, skillMeta)
    -- prevent the Show hook from adding gathering lines on top of ours
    self.showingGathering = true;

    tooltip:ClearLines();
    tooltip:SetText(skillMeta.name or "?");
    self:AddGatheringDifficultyLines(tooltip, skillMeta.difficulty);

    -- add mining node contents if available
    if (skillMeta.contents) then
        self:AddMiningContentsLines(tooltip, skillMeta.contents);
    end

    -- mark tooltip to prevent Show hook from adding gathering lines again
    tooltip["PmGathering"] = true;
    tooltip:Show();
    self.showingGathering = false;
end

--- Add colored difficulty level line to a tooltip (orange/yellow/green/gray).
function TooltipService:AddGatheringDifficultyLines(tooltip, difficulty)
    if (not difficulty) then return; end

    local d1 = difficulty[1] or 0;
    local d2 = difficulty[2] or 0;
    local d3 = difficulty[3] or 0;
    local d4 = difficulty[4] or 0;

    tooltip:AddLine(
        "|cffff8040" .. d1 .. "|r  |cffffff00" .. d2 .. "|r  |cff40c040" .. d3 .. "|r  |cff808080" .. d4 .. "|r"
    );
end

--- Check if the GameTooltip text matches a known gathering node and add difficulty info.
function TooltipService:CheckGatheringNodeTooltip(tooltip, text)
    if (not text or text == "") then return; end

    -- build lookup on first use
    if (not self.gatheringNodeLookup) then
        self:BuildGatheringNodeLookup();
    end

    -- check if the tooltip text matches a known gathering node
    local nodeData = self:FindGatheringNode(tooltip, text);
    if (nodeData) then
        self:AddGatheringDifficultyLines(tooltip, nodeData.difficulty);

        -- add mining node contents if available
        if (nodeData.contents) then
            self:AddMiningContentsLines(tooltip, nodeData.contents);
        end

        -- mark tooltip so a repeated show does not add the lines again
        tooltip["PmGathering"] = true;

        -- prevent re-entry from our own Show() call
        self.showingGathering = true;
        tooltip:Show();
        self.showingGathering = false;
    end
end

--- Build a reverse lookup from gathering node display names to skill data.
function TooltipService:BuildGatheringNodeLookup()
    local skillsService = self:GetService("skills");

    -- build into a local table: requesting item data can finish right away and
    -- invalidate the lookup while the loop still runs, so repeat the pass then
    -- to pick up the names that arrived meanwhile
    local variantItems = self:GetModel("gathering-node-variants") or {};
    local professionNamesService = self:GetService("profession-names");
    local lookup, variants;
    local pass = 0;
    repeat
        pass = pass + 1;
        lookup = {};
        variants = {};
        self.gatheringNodeLookupInvalidated = nil;

        for skillId, skill in pairs(skillsService.allSkills) do
            if (skillId >= 9000000 and skill.name and skill.difficulty) then
                lookup[skill.name] = {
                    difficulty = skill.difficulty,
                    contents = skill.contents,
                    professionId = skill.professionId
                };

                -- base node of weaker variants that carry its name in theirs
                if (variantItems[skill.itemId]) then
                    table.insert(variants, {
                        name = skill.name,
                        professionName = professionNamesService:GetProfessionName(skill.professionId),
                        data = lookup[skill.name]
                    });
                end

                -- pre-cache content item data for instant tooltip display
                if (pass == 1 and skill.contents) then
                    for _, entry in ipairs(skill.contents) do
                        local contentItemId = entry[1];
                        if (contentItemId and C_Item.DoesItemExistByID(contentItemId)) then
                            C_Item.RequestLoadItemDataByID(contentItemId);
                        end
                    end
                end
            end
        end
    until (not self.gatheringNodeLookupInvalidated or pass >= 3);

    self.gatheringNodeLookup = lookup;
    self.gatheringVariantNodes = variants;
end

--- Invalidate the gathering node lookup (call when skill names finish loading).
function TooltipService:InvalidateGatheringNodeLookup()
    self.gatheringNodeLookup = nil;
    self.gatheringNodeLookupInvalidated = true;
end

--- Clear the saved gathering node tooltip state.
function TooltipService:ClearGatheringState()
    self.gatheringOriginalLines = nil;
    self.gatheringNodeDataCache = nil;
    self.gatheringNodeText = nil;
end

--- Add mining node content items to a tooltip.
function TooltipService:AddMiningContentsLines(tooltip, contents)
    if (not contents or #contents == 0) then return; end

    tooltip:AddLine(" ");

    for _, entry in ipairs(contents) do
        local contentItemId = entry[1];
        local dropPercent = entry[2];

        -- resolve item name and quality color
        local itemName, _, itemQuality = self.addon.compat.GetItemInfo(contentItemId);
        if (itemName) then
            local r, g, b = self.addon.compat.GetItemQualityColor(itemQuality or 1);
            tooltip:AddDoubleLine(
                itemName,
                dropPercent .. "%",
                r, g, b,
                0.7, 0.7, 0.7
            );
        end
    end
end

--- Check if a tooltip option is currently active based on its setting value.
-- @param settingKey Key in PM_Settings (e.g. "tooltipShowPlayers").
-- @return boolean True if the option should be shown right now.
function TooltipService:IsTooltipOptionActive(settingKey)
    local value = PM_Settings[settingKey];
    if (value == "always") then
        return true;
    elseif (value == "shift") then
        return IsShiftKeyDown();
    else
        return false;
    end
end

--- Refresh the currently visible GameTooltip when Shift state changes.
function TooltipService:RefreshVisibleTooltip()
    -- check if any option uses shift mode
    local hasShiftOption = (PM_Settings.tooltipShowPlayers == "shift")
        or (PM_Settings.tooltipShowReagentFor == "shift")
        or (PM_Settings.tooltipShowPlayerProfessions == "shift")
        or (PM_Settings.tooltipShowGatheringNodes == "shift");
    if (not hasShiftOption) then return; end

    -- only refresh if GameTooltip is currently visible
    if (not GameTooltip:IsShown()) then return; end

    -- for gathering node tooltips, restore saved original lines and re-add our content
    -- check this first because Vanilla herbs may also return an item link from GetItem()
    local originalLines = self.gatheringOriginalLines;
    if (originalLines) then
        -- only restore if the visible tooltip still shows the saved node; the saved
        -- state can go stale when the engine swaps the tooltip target (e.g. to an
        -- npc) without the tooltip hiding
        local textLeft1 = GameTooltipTextLeft1;
        local currentText = self:ReadNodeName(textLeft1);
        if (currentText ~= self.gatheringNodeText) then
            self:ClearGatheringState();
            originalLines = nil;
        end
    end
    if (originalLines) then
        self.refreshingGathering = true;
        GameTooltip:ClearLines();

        -- restore original tooltip content
        for i, line in ipairs(originalLines) do
            if (i == 1) then
                GameTooltip:SetText(line.left, line.lr, line.lg, line.lb);
            elseif (line.right) then
                GameTooltip:AddDoubleLine(line.left, line.right, line.lr, line.lg, line.lb, line.rr, line.rg, line.rb);
            else
                GameTooltip:AddLine(line.left, line.lr, line.lg, line.lb, true);
            end
        end

        -- always re-append the remaining skill points to the requires line
        self:AddSkillPointsLeftToRequiresLine(GameTooltip, self.gatheringNodeDataCache);

        -- add gathering info if the option is currently active
        if (self:IsTooltipOptionActive("tooltipShowGatheringNodes")) then
            local nodeData = self.gatheringNodeDataCache;
            if (nodeData) then
                self:AddGatheringDifficultyLines(GameTooltip, nodeData.difficulty);
                if (nodeData.contents) then
                    self:AddMiningContentsLines(GameTooltip, nodeData.contents);
                end

                -- mark tooltip so the show hook does not add the lines again
                GameTooltip["PmGathering"] = true;
            end
        end

        GameTooltip:Show();
        self.refreshingGathering = false;
        return;
    end

    -- for item/spell tooltips, refresh depending on the owner frame
    local _, itemLink = self:GetDisplayed(GameTooltip, "Item");
    local _, spellId = self:GetDisplayed(GameTooltip, "Spell");
    if (itemLink or spellId) then
        local owner = GameTooltip:GetOwner();
        if (not owner) then
            return;
        end

        -- own frames: re-trigger our own OnEnter handler to rebuild the tooltip
        if (self:IsOwnFrame(owner)) then
            local onEnter = owner:GetScript("OnEnter");
            if (onEnter) then
                onEnter(owner);
            end
            return;
        end

        -- foreign tooltips whose owner refreshes them itself are left alone:
        -- GameTooltip_OnUpdate calls owner:UpdateTooltip() every 0.2s while the
        -- tooltip is shown (bags, character slots, merchant, action bars),
        -- which re-runs our tooltip hooks with the new shift state and
        -- blizzards own shift item comparison; rebuilding these here via
        -- SetHyperlink closed the tooltip instead (SetHyperlink with the
        -- currently shown link hides the tooltip) and clobbered the comparison
        -- tooltips
        if (owner.UpdateTooltip) then
            return;
        end

        -- foreign item tooltips without an UpdateTooltip owner get no refresh
        -- from the default ui, so rebuild via hyperlink without invoking the
        -- foreign OnEnter handler (vanilla world herbs return an item link
        -- from GetItem, chat links)
        if (itemLink) then
            GameTooltip:SetHyperlink(itemLink);
            GameTooltip:Show();
        end

        -- foreign spell tooltips (action bar, spell book) are skipped on purpose:
        -- calling their OnEnter/UpdateTooltip from addon code taints the
        -- protected action buttons and breaks the action bar grid (buttons
        -- vanish after opening the spell book); the tooltip refreshes on
        -- re-hover instead
        return;
    end
end

--- Check if a tooltip owner frame belongs to Profession Master.
-- @param frame Owner frame of the tooltip.
-- @return boolean True if the frame is inside a Profession Master view.
function TooltipService:IsOwnFrame(frame)
    while (frame) do
        if (frame.ownerAddon == self.addon) then
            return true;
        end
        frame = frame:GetParent();
    end
    return false;
end

--- Save the current tooltip lines for later restoration (shift key refresh).
function TooltipService:SaveOriginalTooltipLines(tooltip)
    local tooltipName = tooltip:GetName();
    if (not tooltipName) then return; end

    local lines = {};
    for i = 1, tooltip:NumLines() do
        local leftObj = _G[tooltipName .. "TextLeft" .. i];
        local rightObj = _G[tooltipName .. "TextRight" .. i];
        local leftText = leftObj and leftObj:GetText();
        if (leftText) then
            local lr, lg, lb = leftObj:GetTextColor();
            local entry = { left = leftText, lr = lr, lg = lg, lb = lb };
            local rightText = rightObj and rightObj:GetText();
            if (rightText and rightText ~= "") then
                local rr, rg, rb = rightObj:GetTextColor();
                entry.right = rightText;
                entry.rr = rr;
                entry.rg = rg;
                entry.rb = rb;
            end
            table.insert(lines, entry);
        end
    end

    self.gatheringOriginalLines = lines;
end

--- Get the inline icon of an availability key ("seasonal" or "unavailable"), "" otherwise.
-- @param availability Key from skills-service:GetSkillAvailability.
-- @param size Icon size in pixels, 14 by default.
function TooltipService:GetAvailabilityIcon(availability, size)
    local texture = self:GetAvailabilityTexture(availability);
    if (not texture) then
        return "";
    end
    return "|T" .. texture .. ":" .. (size or 14) .. "|t";
end

--- Get the texture path of an availability key, nil for none.
function TooltipService:GetAvailabilityTexture(availability)
    if (availability == "seasonal") then
        return SeasonalIcon;
    elseif (availability == "unavailable") then
        return UnavailableIcon;
    end
    return nil;
end

--- Get the tooltip text of an availability key, nil for none.
function TooltipService:GetAvailabilityText(availability)
    local localeService = self:GetService("locale");
    if (availability == "seasonal") then
        return localeService:Get("SkillViewSeasonalOnly");
    elseif (availability == "unavailable") then
        return localeService:Get("SkillViewNotAvailable");
    end
    return nil;
end

--- Build the labels of the source column for a skill: one entry per obtainable
--- recipe item plus "Trainer", "Quest", "Discovery" or "Not available".
--- Recipes only sold during a holiday and the "Not available" label carry
--- the availability icon in front of the text.
-- @param skill Skill wrapper (recipes, sources, name).
-- @return Array of { text, recipe = recipe or nil, skill = skill or nil }.
function TooltipService:GetSkillSourceLabels(skill)
    local labels = {};
    if (not skill) then return labels; end
    local localeService = self:GetService("locale");
    local sources = skill.sources;

    -- recipe items (vestigial items without any source stay hidden)
    if (skill.recipes) then
        for _, recipe in ipairs(skill.recipes) do
            if (recipe.name and not recipe.unobtainable) then
                local prefix = self:GetService("skills"):IsSeasonalRecipe(recipe) and (self:GetAvailabilityIcon("seasonal", 12) .. " ") or "";
                labels[#labels + 1] = { text = prefix .. "|c" .. (recipe.itemColor or "FF1EFF00") .. recipe.name .. "|r", recipe = recipe };
            end
        end
    end

    -- skill sources
    if (sources) then
        if ((sources.trainers and #sources.trainers > 0) or sources.auto) then
            labels[#labels + 1] = { text = "|cffd0d0d0" .. localeService:Get("SourceTrainer") .. "|r", skill = skill };
        end
        if (sources.quests and #sources.quests > 0) then
            labels[#labels + 1] = { text = "|cffd0d0d0" .. localeService:Get("SkillViewQuest") .. "|r", skill = skill };
        end
        if (sources.objects and #sources.objects > 0) then
            labels[#labels + 1] = { text = "|cffd0d0d0" .. localeService:Get("SkillViewLearnedFrom") .. "|r", skill = skill };
        end
        if (sources.discovery and #sources.discovery > 0) then
            labels[#labels + 1] = { text = "|cffd0d0d0" .. localeService:Get("SourceDiscovery") .. "|r", skill = skill };
        end
        if (#labels == 0 and sources.unobtainable) then
            labels[#labels + 1] = { text = self:GetAvailabilityIcon("unavailable", 12) .. " |cff808080" .. localeService:Get("SourceUnavailable") .. "|r", skill = skill };
        end
    end
    return labels;
end

--- Build the source lines of a recipe item (vendors, drops, quests, ...) as
--- colored tooltip lines, one blank line (" ") before every section.
-- @param recipe Table with name, itemColor and the source fields of models/recipe-sources (vendors, drops, zoneDrops, worldDrop, quests, objects, containers, fishing, pickpocket, crafted, unobtainable).
-- @return Array of line strings.
function TooltipService:GetRecipeSourceLines(recipe)
    local lines = {};
    if (not recipe) then return lines; end

    local localeService = self:GetService("locale");
    local skillsService = self:GetService("skills");
    local npcNames = skillsService.npcNames or {};
    local zoneNames = skillsService.zoneNames or {};
    local function AddLine(text)
        lines[#lines + 1] = text;
    end

    -- vendors (own faction first, the other side only when nothing else is left)
    local vendors = self:FilterBySide(recipe.vendors, 3);
    if (#vendors > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewSoldBy") .. "|r");
        for _, vendor in ipairs(vendors) do
            local suffix = skillsService:IsSeasonalVendor(vendor) and (" (" .. localeService:Get("SkillViewSeasonal") .. ")") or "";
            AddLine("|cffffffff" .. self:FormatNpcLine(vendor[1], vendor[2], npcNames, zoneNames) .. suffix .. "|r");
        end
    end

    -- drops
    if (recipe.drops and #recipe.drops > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewDroppedBy") .. "|r");
        for i, drop in ipairs(recipe.drops) do
            if (i > 20) then
                AddLine("|cff999999...|r");
                break;
            end
            AddLine("|cffffffff" .. self:FormatNpcLine(drop[1], drop[2], npcNames, zoneNames) .. "|r");
        end
    end

    -- zone drops (trash of an instance or enemies of a zone)
    if (recipe.zoneDrops and #recipe.zoneDrops > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewDroppedIn") .. "|r");
        for _, zoneId in ipairs(recipe.zoneDrops) do
            AddLine("|cffffffff" .. (self:GetZoneName(zoneId, zoneNames) or "?") .. "|r");
        end
    end

    -- world drop
    if (recipe.worldDrop) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewWorldDrop") .. "|r");
    end

    -- game objects (chests, caches, books)
    if (recipe.objects and #recipe.objects > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewLootedFrom") .. "|r");
        local objectNames = skillsService.objectNames or {};
        for _, object in ipairs(recipe.objects) do
            local objectName = objectNames[object[1]] or "?";
            local locationText = self:GetZoneName(object[2], zoneNames);
            AddLine("|cffffffff" .. objectName .. (locationText and (" - " .. locationText) or "") .. "|r");
        end
    end

    -- container items (bags, caches, reward satchels), shown with their localized link
    if (recipe.containers and #recipe.containers > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewContainedIn") .. "|r");
        local itemLinks = skillsService.itemLinks or {};
        for _, containerItemId in ipairs(recipe.containers) do
            local link = itemLinks[containerItemId];
            if (link) then
                AddLine(link);
            end
        end
    end

    -- fishing
    if (recipe.fishing and #recipe.fishing > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewFishedIn") .. "|r");
        for _, zoneId in ipairs(recipe.fishing) do
            AddLine("|cffffffff" .. (self:GetZoneName(zoneId, zoneNames) or "?") .. "|r");
        end
    end

    -- pickpocket
    if (recipe.pickpocket and #recipe.pickpocket > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewPickpocketedFrom") .. "|r");
        for _, entry in ipairs(recipe.pickpocket) do
            AddLine("|cffffffff" .. self:FormatNpcLine(entry[1], entry[2], npcNames, zoneNames) .. "|r");
        end
    end

    -- quests
    self:AddQuestLines(lines, recipe.quests, npcNames, zoneNames);

    -- recipe items made by another profession (goblin rocket fuel recipe, inscription techniques)
    if (recipe.crafted and recipe.itemId) then
        local craftingSkillIds = skillsService.allItems and skillsService.allItems[recipe.itemId];
        if (craftingSkillIds and #craftingSkillIds > 0) then
            AddLine(" ");
            AddLine("|cffffd100" .. localeService:Get("SkillViewCraftedBy") .. "|r");
            for _, craftingSkillId in ipairs(craftingSkillIds) do
                local craftingSkill = skillsService.allSkills and skillsService.allSkills[craftingSkillId];
                local professionName = craftingSkill and craftingSkill.professionId and self:GetService("profession-names"):GetProfessionName(craftingSkill.professionId);
                local text = (craftingSkill and craftingSkill.name) or self.addon.compat.GetSpellInfo(craftingSkillId) or "?";
                if (professionName) then
                    text = text .. " (" .. professionName .. ")";
                end
                AddLine("|cffffffff" .. text .. "|r");
            end
        end
    end

    -- recipe item that no longer exists in the game
    if (recipe.unobtainable) then
        AddLine(" ");
        AddLine("|cff999999" .. localeService:Get("SkillViewNotAvailable") .. "|r");
    end

    return lines;
end

--- Build the source lines of a skill without recipe item (trainers, quests,
--- discovery, learned with the profession, not available) as colored tooltip
--- lines, one blank line (" ") before every section.
-- @param skill Skill wrapper (with sources, name).
-- @return Array of line strings (empty without sources).
function TooltipService:GetSkillSourceLines(skill)
    local lines = {};
    local sources = skill and skill.sources;
    if (not sources) then return lines; end

    local localeService = self:GetService("locale");
    local skillsService = self:GetService("skills");
    local npcNames = skillsService.npcNames or {};
    local zoneNames = skillsService.zoneNames or {};
    local function AddLine(text)
        lines[#lines + 1] = text;
    end

    -- learned automatically with the profession
    if (sources.auto) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewLearnedWithProfession") .. "|r");
    end

    -- trainers of the own faction, sorted by zone
    if (sources.trainers and #sources.trainers > 0) then
        local trainers = self:FilterTrainersBySide(sources.trainers, skillsService);
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewTaughtBy") .. "|r");
        for i, trainer in ipairs(trainers) do
            if (i > 30) then
                AddLine("|cff999999...|r");
                break;
            end
            AddLine("|cffffffff" .. self:FormatNpcLine(trainer[1], trainer[2], npcNames, zoneNames) .. "|r");
        end
    end

    -- quests
    self:AddQuestLines(lines, sources.quests, npcNames, zoneNames);

    -- game objects that teach the recipe directly (readable schematics, tablets, books)
    if (sources.objects and #sources.objects > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewLearnedFrom") .. "|r");
        local objectNames = skillsService.objectNames or {};
        for _, object in ipairs(sources.objects) do
            local objectName = objectNames[object[1]] or "?";
            local locationText = self:GetZoneName(object[2], zoneNames);
            AddLine("|cffffffff" .. objectName .. (locationText and (" - " .. locationText) or "") .. "|r");
        end
    end

    -- discovery while crafting or via a research spell
    if (sources.discovery and #sources.discovery > 0) then
        AddLine(" ");
        AddLine("|cffffd100" .. localeService:Get("SkillViewDiscoveredVia") .. "|r");
        for _, researchSpellId in ipairs(sources.discovery) do
            local researchName = (researchSpellId and researchSpellId > 0) and self.addon.compat.GetSpellInfo(researchSpellId) or nil;
            AddLine("|cffffffff" .. (researchName or localeService:Get("SkillViewDiscoveredWhileCrafting")) .. "|r");
        end
    end

    -- recipe that is not available to players
    if (sources.unobtainable) then
        AddLine(" ");
        AddLine(self:GetAvailabilityIcon("unavailable", 12) .. " |cff999999" .. localeService:Get("SkillViewNotAvailable") .. "|r");
    end

    return lines;
end

--- Add the quest section (icon, localized title, quest giver with zone) to a
--- list of source lines.
-- @param lines Array of line strings the section is appended to.
-- @param quests Quest entries {questId, giverId, zoneId, side, flags, giverType}.
-- @param npcNames Npc name lookup.
-- @param zoneNames Zone name lookup.
function TooltipService:AddQuestLines(lines, quests, npcNames, zoneNames)
    quests = self:FilterBySide(quests, 4);
    if (#quests == 0) then return; end
    local localeService = self:GetService("locale");
    local skillsService = self:GetService("skills");
    lines[#lines + 1] = " ";
    lines[#lines + 1] = "|cffffd100" .. localeService:Get("SkillViewQuest") .. "|r";
    for _, quest in ipairs(quests) do
        local flags = quest[5] or 0;

        -- blue exclamation mark for daily, weekly and repeatable quests, yellow for the others
        local icon = (flags > 0) and "|TInterface\\GossipFrame\\DailyQuestIcon:14:14:0:0|t" or "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14:0:0|t";
        lines[#lines + 1] = icon .. " |cffffffff" .. self:GetQuestTitle(quest[1]) .. "|r";

        -- quest giver: npc, game object or starting item
        local giverId, giverType = quest[2], quest[6];
        local giverName;
        if (giverId) then
            if (giverType == "o") then
                giverName = (skillsService.objectNames or {})[giverId];
            elseif (giverType == "i") then
                giverName = (skillsService.itemLinks or {})[giverId] or nil;
                if (giverName == false) then giverName = nil; end
            else
                giverName = npcNames[giverId];
            end
        end
        if (giverName) then
            local locationText = self:GetZoneName(quest[3], zoneNames);
            lines[#lines + 1] = "   |cffbbbbbb" .. giverName .. (locationText and (" - " .. locationText) or "") .. "|r";
        end
    end
end

--- Get the localized title of a quest from the client, english fallback from the static data.
-- @param questId Quest id.
-- @return Title.
function TooltipService:GetQuestTitle(questId)
    local title;
    if (C_QuestLog) then
        if (C_QuestLog.GetTitleForQuestID) then
            title = C_QuestLog.GetTitleForQuestID(questId);
        elseif (C_QuestLog.GetQuestInfo) then
            title = C_QuestLog.GetQuestInfo(questId);
        end

        -- ask the server for the quest data so the next tooltip shows the localized title
        if ((not title or title == "") and C_QuestLog.RequestLoadQuestByID) then
            pcall(C_QuestLog.RequestLoadQuestByID, questId);
        end
    end
    if (not title or title == "") then
        local questNames = self:GetService("skills").questNames;
        title = questNames and questNames[questId];
    end
    return title or ("#" .. tostring(questId));
end

--- Keep the entries of the player's faction; entries without side always stay and
--- the other faction is kept only when nothing would be left otherwise.
-- @param entries Array of tuples.
-- @param sideIndex Tuple index of the side ("A"/"H"/nil).
-- @return Filtered array (never nil).
function TooltipService:FilterBySide(entries, sideIndex)
    if (not entries) then return {}; end
    local playerSide = self:GetPlayerSide();
    local filtered = {};
    for _, entry in ipairs(entries) do
        local side = entry[sideIndex];
        if (not side or side == playerSide) then
            filtered[#filtered + 1] = entry;
        end
    end
    if (#filtered == 0) then
        for _, entry in ipairs(entries) do
            filtered[#filtered + 1] = entry;
        end
    end
    return filtered;
end

--- Resolve trainer npc ids to {npcId, zoneId} tuples of the player's faction, sorted by zone name.
-- @param trainerIds Array of npc ids.
-- @param skillsService Skills service (trainer info, zone names).
-- @return Array of {npcId, zoneId}.
function TooltipService:FilterTrainersBySide(trainerIds, skillsService)
    skillsService = skillsService or self:GetService("skills");
    local playerSide = self:GetPlayerSide();
    local zoneNames = skillsService.zoneNames or {};
    local npcNames = skillsService.npcNames or {};
    local trainers = {};
    local others = {};
    for _, npcId in ipairs(trainerIds) do
        local zoneId, side = skillsService:GetTrainerInfo(npcId);
        local entry = { npcId, zoneId };
        if (not side or side == playerSide) then
            trainers[#trainers + 1] = entry;
        else
            others[#others + 1] = entry;
        end
    end
    if (#trainers == 0) then
        trainers = others;
    end
    table.sort(trainers, function(a, b)
        local zoneA = (a[2] and zoneNames[a[2]]) or "";
        local zoneB = (b[2] and zoneNames[b[2]]) or "";
        if (zoneA ~= zoneB) then
            return zoneA < zoneB;
        end
        return (npcNames[a[1]] or "") < (npcNames[b[1]] or "");
    end);
    return trainers;
end

--- Get the player's side letter as used by the source data.
-- @return "A" or "H".
function TooltipService:GetPlayerSide()
    if (not self.playerSide) then
        self.playerSide = (UnitFactionGroup("player") == "Horde") and "H" or "A";
    end
    return self.playerSide;
end

--- Format "Npc name - Zone" for the source texts.
-- @param npcId Npc id.
-- @param zoneId Zone id or nil.
-- @param npcNames Npc name lookup.
-- @param zoneNames Zone name lookup.
-- @return Line text.
function TooltipService:FormatNpcLine(npcId, zoneId, npcNames, zoneNames)
    local name = npcNames[npcId] or "?";
    local locationText = self:GetZoneName(zoneId, zoneNames);
    if (locationText) then
        return name .. " - " .. locationText;
    end
    return name;
end

--- Get a zone name from a zone ID via the zoneNames lookup table.
function TooltipService:GetZoneName(zoneId, zoneNames)
    if (type(zoneId) == "number" and zoneNames) then
        return zoneNames[zoneId];
    end
    return nil;
end

--- Convert an 8-character hex color (AARRGGBB) to normalized r, g, b values.
function TooltipService:HexToRgb(hex)
    if (not hex or #hex < 6) then return 1, 1, 1; end
    local offset = (#hex == 8) and 3 or 1;
    local r = tonumber(hex:sub(offset, offset + 1), 16);
    local g = tonumber(hex:sub(offset + 2, offset + 3), 16);
    local b = tonumber(hex:sub(offset + 4, offset + 5), 16);

    -- not a hex color (e.g. a cached value of an unknown link format)
    if (not r or not g or not b) then return 1, 1, 1; end
    return r / 255, g / 255, b / 255;
end

--- Read the tooltip lines of a hyperlink (item or enchantment link) from the
--- hidden scratch tooltip.
-- @param link Hyperlink.
-- @return Array of { left, lr, lg, lb, right, rr, rg, rb } (right fields optional).
function TooltipService:GetHyperlinkTooltipLines(link)
    local scratch = self.scratchTooltip;
    scratch:SetOwner(UIParent, "ANCHOR_NONE");
    scratch:ClearLines();
    scratch:SetHyperlink(link);

    local lines = {};
    for i = 1, scratch:NumLines() do
        local leftLine = _G["PmScratchTooltipTextLeft" .. i];
        local rightLine = _G["PmScratchTooltipTextRight" .. i];
        if (leftLine and leftLine:GetText()) then
            local lr, lg, lb = leftLine:GetTextColor();
            local entry = { left = leftLine:GetText(), lr = lr, lg = lg, lb = lb };
            if (rightLine and rightLine:GetText()) then
                local rr, rg, rb = rightLine:GetTextColor();
                entry.right = rightLine:GetText();
                entry.rr = rr;
                entry.rg = rg;
                entry.rb = rb;
            end
            lines[#lines + 1] = entry;
        end
    end

    scratch:Hide();
    return lines;
end

--- Get a spell description asynchronously (spell data may still need to load).
-- @param spellId Id of the spell to get the description for.
-- @param callback Function called with the description text or nil.
function TooltipService:GetSpellDescriptionAsync(spellId, callback)
    -- resolve the description getter (moved to C_Spell on newer clients)
    local getDescription = (C_Spell and C_Spell.GetSpellDescription) or GetSpellDescription;
    if (not spellId or not getDescription) then
        callback(nil);
        return;
    end

    -- check if the description is already available
    local description = getDescription(spellId);
    if (description and description ~= "") then
        callback(description);
        return;
    end

    -- wait for spell data to load, then read the description again
    local created, spell = pcall(function() return Spell:CreateFromSpellID(spellId); end);
    if (not created or not spell or spell:IsSpellEmpty()) then
        callback(nil);
        return;
    end
    spell:ContinueOnSpellLoad(function()
        local loadedDescription = getDescription(spellId);
        if (loadedDescription and loadedDescription ~= "") then
            callback(loadedDescription);
        else
            callback(nil);
        end
    end);
end

--- Format a cost of the price sources, "free" in green for nothing.
-- @param coppers The cost in copper (fractions come from crafted reagents).
-- @return formatted text.
function TooltipService:FormatSourceCost(coppers)
    local rounded = math.floor((coppers or 0) + 0.5);
    if (rounded <= 0) then
        return "|cff40c040" .. self:GetService("locale"):Get("LevelingPlannerFree") .. "|r";
    end
    return self:GetService("auction"):FormatPrice(rounded);
end

--- Show where the units of a reagent come from and what they cost: own
--- amounts for free, vendor and auction house offers level by level with unit
--- price and sum (leveling planner, missing reagents window).
-- @param owner The hovered element (the tooltip hangs left of it).
-- @param reagent Reagent of leveling-planner:BuildReagent.
-- @param coloredName The item name in quality color.
-- @param chartOwner The hovered price, nil while the mouse is elsewhere on
--        the row: a reagent the auction house prices gets the price charts
--        of Auctionizer at the mouse there.
function TooltipService:ShowPriceSourcesTooltip(owner, reagent, coloredName, chartOwner)
    local localeService = self:GetService("locale");
    local auctionService = self:GetService("auction");

    GameTooltip:SetOwner(owner, "ANCHOR_NONE");
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", owner, "TOPLEFT", -2, 0);
    if (coloredName) then
        GameTooltip:AddLine(coloredName);
    end

    local sourceKeys = {
        bags = "LevelingPlannerSourceBags",
        bank = "LevelingPlannerSourceBank",
        mail = "LevelingPlannerSourceMail",
        produced = "LevelingPlannerSourceProduced",
        vendor = "LevelingPlannerSourceVendor",
        auction = "LevelingPlannerSourceAuction",
        estimate = "LevelingPlannerSourceEstimate",
        craft = "LevelingPlannerSourceCraft",
        missing = "LevelingPlannerSourceMissing",
    };

    for _, source in ipairs(reagent.sources) do
        local left = localeService:Get(sourceKeys[source.kind]);
        local right;
        if (source.kind == "bags" or source.kind == "bank" or source.kind == "mail" or source.kind == "produced") then
            right = source.count .. "x  " .. self:FormatSourceCost(0);
        elseif (source.kind == "craft") then
            right = "|cff80c0ff" .. source.count .. "x|r";
        elseif (source.kind == "missing") then
            right = "|cffff4040" .. source.count .. "x|r";
        else
            local unitPrice = math.floor(source.unitPrice + 0.5);
            right = source.count .. "x  " .. (auctionService:FormatPrice(unitPrice) or "") .. "  =  " .. self:FormatSourceCost(source.count * source.unitPrice);
        end
        GameTooltip:AddDoubleLine(left, right, 1, 0.82, 0, 1, 1, 1);
    end

    GameTooltip:AddLine(" ");
    GameTooltip:AddDoubleLine(localeService:Get("LevelingPlannerSourceTotal"), reagent.count .. "x  " .. self:FormatSourceCost(reagent.cost), 1, 0.82, 0, 1, 1, 1);

    -- units from the auction house: a price of Auctionizer has price charts,
    -- shown at the mouse on the price; a price of another addon gets a quiet
    -- line that charts come with Auctionizer
    if (self:HasAuctionSource(reagent)) then
        local hint = auctionService:GetPriceChartHint(reagent.itemId);
        if (hint) then
            GameTooltip:AddLine(hint, 0.6, 0.6, 0.6);
        elseif (chartOwner) then
            auctionService:ShowPriceChart(reagent.itemId, chartOwner);
        end
    end
    GameTooltip:Show();
end

--- Check whether units of a reagent are priced by the auction house (offers
--- of the scan or the estimated price beyond them).
-- @param reagent Reagent of leveling-planner:BuildReagent.
-- @return boolean
function TooltipService:HasAuctionSource(reagent)
    for _, source in ipairs(reagent.sources) do
        if (source.kind == "auction" or source.kind == "estimate") then
            return true;
        end
    end
    return false;
end
