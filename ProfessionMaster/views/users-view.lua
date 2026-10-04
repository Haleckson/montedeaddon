--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local UsersView = _G.professionMaster:CreateView("users");

--- Collect guild members that are not known in Profession Master data.
function UsersView:CollectMembersWithoutProfessionMaster()
    local playerService = self:GetService("player");
    local members = {};

    for playerName, guildmate in pairs(playerService.guildmates) do
        local longName = playerService:GetLongName(playerName);
        local hasProfessionMasterData = playerService.node.guildmates[longName] ~= nil or playerService.node.guildmates[playerName] ~= nil;

        if (not hasProfessionMasterData and not playerService:IsCurrentPlayer(longName) and not playerService:IsOwnPlayer(longName)) then
            table.insert(members, {
                name = longName,
                isOnline = guildmate.online
            });
        end
    end

    table.sort(members, function(a, b)
        if (a.isOnline ~= b.isOnline) then
            return a.isOnline;
        end
        return playerService:GetRealmShortName(a.name) < playerService:GetRealmShortName(b.name);
    end);

    return members;
end

--- Prepare invite whisper to a guild member.
function UsersView:PrepareWhisperInvite(memberName)
    local localeService = self:GetService("locale");
    local whisperTarget = self:GetService("player"):GetWhisperTarget(memberName);
    self.addon.compat.ChatFrame_OpenChat("/w " .. whisperTarget .. " " .. localeService:Get("MembersWithoutProfessionMasterWhisperText"));
end

--- Prepare invite message to guild chat.
function UsersView:PrepareGuildAnnounce()
    local localeService = self:GetService("locale");
    self.addon.compat.ChatFrame_OpenChat("/g " .. localeService:Get("MembersWithoutProfessionMasterGuildAnnounceText"));
end

--- Show users view.
function UsersView:Show()
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    self.members = self:CollectMembersWithoutProfessionMaster();

    if (self.view == nil) then
        local view = uiService:CreateToolView("PmUsers", 420, 420, localeService:Get("MembersWithoutProfessionMasterTitle"), true, true, nil, nil, { "TOP", "BOTTOM" });
        view:EnableKeyboard();
        view:SetScript("OnKeyDown", function(_, key)
            if (key == "ESCAPE") then
                self:Hide();
            end
        end);
        self.view = view;

        local closeButton = uiService:CreateFlatCloseButton(view, function()
            self:Hide();
        end);
        closeButton:SetHeight(22);
        closeButton:SetWidth(22);
        closeButton:SetPoint("TOPRIGHT", -12, -8);

        local usersFrame = uiService:CreatePanel(view);
        usersFrame:SetPoint("TOPLEFT", 8, -34);

        -- the classic style ends the list above the button row with some room
        usersFrame:SetPoint("BOTTOMRIGHT", -8, uiService:IsForever() and (uiService:GetBottomInset(8) + 30) or 38);
        self.usersFrame = usersFrame;

        local scrollFrame, scrollChild, scrollElement = uiService:CreateScrollFrame(usersFrame);
        scrollFrame:SetPoint("TOPLEFT", 5, -5);
        scrollFrame:SetPoint("BOTTOMRIGHT", -5, 5);
        scrollChild:SetWidth(scrollFrame:GetWidth());
        scrollElement:SetScript("OnVerticalScroll", function(_, top)
            self.scrollTop = top;
            self:RefreshRows();
        end);
        self.scrollFrame = scrollFrame;
        self.scrollChild = scrollChild;
        self.scrollElement = scrollElement;
        self.scrollTop = 0;

        local emptyText = usersFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable");
        emptyText:SetPoint("CENTER", usersFrame, "CENTER", 0, 0);
        emptyText:SetText(localeService:Get("MembersWithoutProfessionMasterNone"));
        self.emptyText = emptyText;

        local announceButton = uiService:CreateFlatButton(view, localeService:Get("MembersWithoutProfessionMasterGuildAnnounceButton"), function()
            self:PrepareGuildAnnounce();
        end);
        announceButton:SetWidth(180);
        announceButton:SetHeight(22);
        announceButton:SetPoint("BOTTOMRIGHT", -uiService:GetSideInset(12), uiService:GetBottomInset(8));
    end

    self.scrollChild:SetHeight(math.max(#self.members * 22, 1));
    self.scrollTop = 0;
    self:RefreshRows();

    self.view:Show();
    self.visible = true;
end

--- Refresh visible user rows.
function UsersView:RefreshRows()
    local uiService = self:GetService("ui");
    local playerService = self:GetService("player");
    local rowHeight = 22;
    local members = self.members or {};
    local startIndex = math.max(math.floor((self.scrollTop or 0) / rowHeight) - 1, 1);
    local endIndex = math.min(startIndex + 25, #members);
    local visibleCount = math.max(endIndex - startIndex + 1, 0);

    if (not self.rowPool) then
        self.rowPool = {};
    end

    while (#self.rowPool < visibleCount) do
        local row = CreateFrame("Button", nil, self.scrollChild, BackdropTemplateMixin and "BackdropTemplate");
        row:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]]
        });
        row:SetHeight(rowHeight);

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        nameText:SetPoint("LEFT", 6, 0);
        nameText:SetPoint("RIGHT", row, "RIGHT", -32, 0);
        nameText:SetJustifyH("LEFT");
        row.nameText = nameText;

        local whisperButton = CreateFrame("Button", nil, row);
        whisperButton:SetSize(18, 18);
        whisperButton:SetPoint("RIGHT", row, "RIGHT", -6, 0);
        whisperButton:Hide();
        row.whisperButton = whisperButton;

        local whisperIcon = whisperButton:CreateTexture(nil, "ARTWORK");
        whisperIcon:SetAllPoints();
        whisperIcon:SetTexture([[Interface\Icons\INV_Letter_15]]);

        local whisperHighlight = whisperButton:CreateTexture(nil, "HIGHLIGHT");
        whisperHighlight:SetPoint("TOPLEFT", -1, 1);
        whisperHighlight:SetPoint("BOTTOMRIGHT", 1, -1);
        whisperHighlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]]);
        whisperHighlight:SetBlendMode("ADD");

        local function HideHover()
            C_Timer.After(0.05, function()
                if (row:IsMouseOver() or whisperButton:IsMouseOver()) then
                    return;
                end
                row.whisperButton:Hide();
                uiService:SetRowColor(row, row.rowIndex or 1);
            end);
        end

        row:SetScript("OnEnter", function()
            -- offline members cannot be whispered, so no hover feedback
            if (not row.memberIsOnline) then
                return;
            end
            row:SetBackdropColor(0.24, 0.24, 0.24, 0.65);
            row.whisperButton:Show();
        end);
        row:SetScript("OnLeave", HideHover);

        whisperButton:SetScript("OnEnter", function(button)
            row:SetBackdropColor(0.24, 0.24, 0.24, 0.65);
            if (row.memberIsOnline) then
                row.whisperButton:Show();
            end
            if (row.memberName and row.memberIsOnline) then
                GameTooltip:SetOwner(button, "ANCHOR_BOTTOM");
                GameTooltip:SetText(self:GetService("locale"):Get("MembersWithoutProfessionMasterWhisperTooltip", self:GetService("player"):GetRealmShortName(row.memberName)));
                GameTooltip:Show();
            end
        end);
        whisperButton:SetScript("OnLeave", function()
            GameTooltip:Hide();
            HideHover();
        end);
        whisperButton:SetScript("OnClick", function()
            if (row.memberName and row.memberIsOnline) then
                self:PrepareWhisperInvite(row.memberName);
            end
        end);

        -- purple hover glow (border + purple backdrop), kept alive by the whisper button
        self:GetService("ui"):AttachHoverGlow(row, { whisperButton });

        table.insert(self.rowPool, row);
    end

    for _, row in ipairs(self.rowPool) do
        row:Hide();
    end

    if (self.emptyText) then
        if (#members == 0) then
            self.emptyText:Show();
        else
            self.emptyText:Hide();
        end
    end

    if (#members == 0) then
        return;
    end

    for i = 0, visibleCount - 1 do
        local rowIndex = startIndex + i;
        local member = members[rowIndex];
        local row = self.rowPool[i + 1];
        local top = (rowIndex - 1) * rowHeight;

        row.rowIndex = rowIndex;
        row.memberName = member.name;
        row.memberIsOnline = member.isOnline;
        row.hoverGlowDisabled = not member.isOnline;
        row.whisperButton:Hide();
        row:ClearAllPoints();
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -top);
        row:SetPoint("RIGHT", self.scrollChild, "RIGHT", -28, 0);
        uiService:SetRowColor(row, rowIndex);

        if (member.isOnline) then
            row.nameText:SetTextColor(1, 1, 1, 1);
        else
            row.nameText:SetTextColor(0.55, 0.55, 0.55, 1);
        end
        row.nameText:SetText(playerService:GetRealmShortName(member.name));
        row:Show();
    end
end

--- Refresh members.
function UsersView:Refresh()
    self.members = self:CollectMembersWithoutProfessionMaster();
    if (self.scrollChild) then
        self.scrollChild:SetHeight(math.max(#self.members * 22, 1));
    end
    self:RefreshRows();
end

--- Hide users view.
function UsersView:Hide()
    if (self.view) then
        self.view:Hide();
        self.visible = false;
    end
end

--- Toggle visibility.
function UsersView:ToggleVisibility()
    if (self.visible) then
        self:Hide();
    else
        self:Show();
    end
end
