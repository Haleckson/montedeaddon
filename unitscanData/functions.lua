local _, L = ...;

function getPlayerZoneNameId()
    local mapID = C_Map.GetBestMapForUnit("player");
    local mapname = REGIONS_TABLE[mapID];
    return mapname;
end

function getPlayerZoneLocalizedName()
    local mapID = C_Map.GetBestMapForUnit("player");
    if mapID == nil then return getPlayerZoneNameId() end
    local map = C_Map.GetMapInfo(mapID);
    if map == nil or map.name == nil then return getPlayerZoneNameId() end
    return map.name;
end

function getActiveGrid()
    local allGridsState = _G["CHECKBOX_GRID_STATE"];
    local zoneId = getPlayerZoneNameId()
    local r = allGridsState[zoneId]
    if r == nil then
        r = {}
        for i=1,75 do
            r[i] = {}
            r[i]["active"] = false
        end
    end
    return r
end

function drawGrid(CHECKBOX_GRID_STATE)
    local allNonActive = true;
    for i, checkboxTable in pairs(CHECKBOX_GRID_STATE) do
        local MyCheckButton = _G["MyCheckButton" .. i];
        local colour = "ff7efa02"
        if checkboxTable["active"] then
            allNonActive = false;
            if checkboxTable["cls"] == 2 then  colour = "ffc2c1c0" end
            if checkboxTable["cls"] == 4 then colour = "ff595d63" end
            _G["MyCheckButton" .. i .. 'Text']:SetText("|c" .. colour .. checkboxTable["text"] .. "|r");
            MyCheckButton:Show();
            MyCheckButton:SetChecked(checkboxTable["check"]);
        else
            MyCheckButton:Hide();
            MyCheckButton:SetChecked(false);
        end
    end
    local GridTitleContainer = _G["TestAddonGridTitleContainer"];
    if allNonActive then
        GridTitleContainer.Label:SetText(L["NO_CHECKBOX_DATA"])
    else
        GridTitleContainer.Label:SetText(getPlayerZoneLocalizedName())
    end
    GridTitleContainer:SetSize(GridTitleContainer.Label:GetStringWidth(), 36);
    return not allNonActive;
end

function onZoneChangeEvent(event)
    if UNIT_SCAN_DATA["LAST_REGION"] ~= nil then
        unitscan_removeAllFromGrid(_G["CHECKBOX_GRID_STATE"][UNIT_SCAN_DATA["LAST_REGION"]])
    end
    local activeGrid = getActiveGrid();
    local r = drawGrid(activeGrid);
	enableToggles(r);
    unitscan_updateAllFromGrid(activeGrid);
    UNIT_SCAN_DATA["LAST_REGION"] = getPlayerZoneNameId();
end

function toggleAllByClassification(classification)
    local CHECKBOX_GRID_STATE = getActiveGrid();
    local newState = nil;
    for i, checkboxTable in pairs(CHECKBOX_GRID_STATE) do
        if checkboxTable["active"] then
            if checkboxTable["cls"] == classification then
                if newState == nil then
                    newState = not checkboxTable["check"];
                end
                checkboxTable["check"] = newState;
            end
        end
    end
end

function toggleToDefault()
    local zoneId = getPlayerZoneNameId();
    if OUTPUT_TABLE[zoneId] == nil then return end
    _G["CHECKBOX_GRID_STATE"][zoneId] = nil
    _G["CHECKBOX_GRID_STATE"][zoneId] = {}
    for index, checkboxContent in pairs(OUTPUT_TABLE[zoneId]) do
        _G["CHECKBOX_GRID_STATE"][zoneId][index] = {}
         for key, value in pairs(checkboxContent) do
            _G["CHECKBOX_GRID_STATE"][zoneId][index][key] = value
        end
    end
end

function getInfoText()
    return L.INFO_TEXT
end

function getRegionId(region)
    if region == nil then return nil end
    for key, val in pairs(REGIONS_TABLE) do
        if val == region then
            return key
        end
    end
    return nil
end

function enableToggles(enable)
    if enable then
        _G["TestAddonToggle1Button"]:Enable();
        _G["TestAddonToggle2Button"]:Enable();
        _G["TestAddonToggle4Button"]:Enable();
        _G["TestAddonToDefaultButton"]:Enable();
    else
        _G["TestAddonToggle1Button"]:Disable();
        _G["TestAddonToggle2Button"]:Disable();
        _G["TestAddonToggle4Button"]:Disable();
        _G["TestAddonToDefaultButton"]:Disable();
    end
end

function unitscan_toggleTarget(key)
	if unitscan_targets[key] then
		unitscan_targets[key] = nil
	else
		unitscan_targets[key] = true
	end
end

function autoscan_verifyConsistency(checkboxTable)
    local key = "";
    local inList = false;
    for _, singleCheckbox in pairs(checkboxTable) do
        if singleCheckbox.active then
            key = strupper(singleCheckbox.text);
            inList = unitscan_targets[key];
            if inList == nil then inList = false end
            if singleCheckbox.check ~= inList then
                singleCheckbox.check = not singleCheckbox.check;
            end
        end
    end
end

function unitscan_updateSingleCheckbox(singleCheckbox)
    if singleCheckbox.active then
        local key = strupper(singleCheckbox.text);
        local isInList = unitscan_targets[key];
        if isInList == nil then isInList = false end
        if singleCheckbox.check ~= isInList then
            unitscan_toggleTarget(key);
        end
    end
end

function unitscan_updateAllFromGrid(checkboxTable)
    local key = "";
    local inList = false;
    for _, singleCheckbox in pairs(checkboxTable) do
        if singleCheckbox.active then
            key = strupper(singleCheckbox.text);
            inList = unitscan_targets[key];
            if inList == nil then inList = false end
            if singleCheckbox.check ~= inList then unitscan_toggleTarget(key) end
        end
    end
end

function unitscan_removeAllFromGrid(checkboxTable)
    if checkboxTable == nil then return end
    for _, singleCheckbox in pairs(checkboxTable) do
        if singleCheckbox.active then
            local key = strupper(singleCheckbox.text);
            local inList = unitscan_targets[key];
            if inList == nil then inList = false end
            if inList then unitscan_toggleTarget(key) end
        end
    end
end

function unitscan_clean()
    for _, checkboxGrid in pairs(_G["CHECKBOX_GRID_STATE"]) do
        unitscan_removeAllFromGrid(checkboxGrid);
    end
end

function bothAddonsLoaded()
    unitscan_clean();
    onZoneChangeEvent("ADDON_LOADED");
end