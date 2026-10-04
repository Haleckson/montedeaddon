--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local DataView = _G.professionMaster:CreateView("data");

--- Serialize a value to a Lua-style string with indentation.
function DataView:Serialize(value, indent)
    -- default indent level
    indent = indent or 0;
    local prefix = string.rep("    ", indent);
    local childPrefix = string.rep("    ", indent + 1);

    -- handle nil
    if (value == nil) then
        return "nil";
    end

    -- handle booleans
    if (type(value) == "boolean") then
        return tostring(value);
    end

    -- handle numbers
    if (type(value) == "number") then
        return tostring(value);
    end

    -- handle strings
    if (type(value) == "string") then
        return "\"" .. value:gsub("\"", "\\\""):gsub("\n", "\\n") .. "\"";
    end

    -- handle tables
    if (type(value) == "table") then
        local lines = {};
        table.insert(lines, "{");

        -- iterate table entries
        local index = 1;
        local hasEntries = false;
        for key, val in pairs(value) do
            hasEntries = true;
            local serializedValue = self:Serialize(val, indent + 1);

            -- format key
            local keyString;
            if (type(key) == "number") then
                keyString = "[" .. key .. "]";
            else
                keyString = "[\"" .. tostring(key) .. "\"]";
            end

            table.insert(lines, childPrefix .. keyString .. " = " .. serializedValue .. ",");
            index = index + 1;
        end

        -- handle empty tables
        if (not hasEntries) then
            return "{}";
        end

        table.insert(lines, prefix .. "}");
        return table.concat(lines, "\n");
    end

    -- fallback for other types
    return tostring(value);
end

--- Show data view.
function DataView:Show()
    -- get services
    local uiService = self:GetService("ui");
    local playerService = self:GetService("player");

    -- check if view created
    if (self.view == nil) then
        -- create view
        local view = uiService:CreateView("PmData", 700, 500, "Node Data", true);
        view:EnableKeyboard();
        view:SetScript("OnKeyDown", function(_, key)
            if (key == "ESCAPE") then
                self:Hide();
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

        -- add scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate");
        scrollFrame:SetPoint("TOPLEFT", 12, -36);
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 42);

        -- add edit box for selectable/copyable text
        local editBox = CreateFrame("EditBox", nil, scrollFrame);
        editBox:SetMultiLine(true);
        editBox:SetAutoFocus(false);
        editBox:SetFontObject(GameFontHighlightSmall);
        editBox:SetWidth(scrollFrame:GetWidth() - 10);
        editBox:SetScript("OnEscapePressed", function()
            editBox:ClearFocus();
        end);
        editBox:SetScript("OnTextChanged", function(_, userInput)
            if (userInput) then
                -- prevent user edits, restore original text
                editBox:SetText(self.dataText or "");
                editBox:SetCursorPosition(0);
            end
        end);
        scrollFrame:SetScrollChild(editBox);
        self.editBox = editBox;

        -- create ok button
        local okButton = uiService:CreateFlatButton(view, "OK", function()
            self:Hide();
        end);
        okButton:SetWidth(100);
        okButton:SetHeight(22);
        okButton:SetPoint("BOTTOMRIGHT", -uiService:GetSideInset(12), uiService:GetBottomInset(8));
    end

    -- serialize node data
    self.dataText = self:Serialize(playerService.node, 0);
    self.editBox:SetText(self.dataText);
    self.editBox:SetCursorPosition(0);

    -- show view
    self.view:Show();
    self.visible = true;
end

--- Hide view.
function DataView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
    end
end

--- Toggle visibility.
function DataView:ToggleVisibility()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end
