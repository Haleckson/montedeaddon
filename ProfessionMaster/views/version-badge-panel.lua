--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel
local VersionBadgePanel = _G.professionMaster:CreateView("version-badge-panel");

--- Create version badge panel.
-- @param parentFrame The parent view frame to attach to.
function VersionBadgePanel:Create(parentFrame)
    -- initialize state
    self.dismissed = false;

    local localeService = self:GetService("locale");

    -- create badge frame with dark background and orange/gold border
    local frame = CreateFrame("Frame", nil, parentFrame, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    });
    frame:SetBackdropColor(0.12, 0.1, 0.08, 1);
    frame:SetBackdropBorderColor(1, 0.45, 0.1, 1);
    frame:SetHeight(36);
    frame:SetWidth(500);
    frame:SetPoint("TOP", parentFrame, "TOP", 0, -16);
    frame:SetFrameLevel(parentFrame:GetFrameLevel() + 10);
    frame:Hide();
    self.frame = frame;

    -- add badge text (white, non-bold; the shown hint is picked per cause)
    local badgeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    badgeText:SetPoint("LEFT", 8, 0);
    badgeText:SetPoint("RIGHT", -22, 0);
    badgeText:SetJustifyH("CENTER");
    badgeText:SetTextColor(1, 1, 1, 1);
    badgeText:SetText(localeService:Get("VersionOutdatedShort"));
    self.badgeText = badgeText;

    -- add close button
    local closeButton = CreateFrame("Button", nil, frame);
    closeButton:SetSize(16, 16);
    closeButton:SetPoint("RIGHT", -3, 0);
    closeButton:SetNormalFontObject("GameFontNormalSmall");
    closeButton:SetText("x");
    closeButton:GetFontString():SetTextColor(1, 1, 1, 0.8);
    closeButton:SetScript("OnClick", function()
        self:Hide();
        self.dismissed = true;
    end);
end

--- Show badge if an update is needed and not dismissed: a newer PM version
--- seen in the guild, or an installed TradeBoard whose host api does not match
--- this PM build (the trade integration stays disabled until both addons are
--- updated together).
function VersionBadgePanel:ShowIfOutdated()
    if (not self.frame or self.dismissed) then
        return;
    end

    local localeService = self:GetService("locale");

    -- check if version service detected a newer version
    local versionService = self:GetService("version");
    if (versionService.outdatedVersionNotified) then
        self.badgeText:SetText(localeService:Get("VersionOutdatedShort"));
        self.frame:Show();
        return;
    end

    -- installed but incompatible TradeBoard: a newer TradeBoard api means this
    -- PM is the outdated one, otherwise the TradeBoard needs the update
    if (_G.tradeBoard and not self.addon:IsTradeBoardCompatible()) then
        local tradeBoardApi = _G.tradeBoard.hostApiVersion or 0;
        if (tradeBoardApi > self.addon.RequiredTradeBoardApi) then
            self.badgeText:SetText(localeService:Get("VersionOutdatedShort"));
        else
            self.badgeText:SetText(localeService:Get("TradeBoardOutdatedShort"));
        end
        self.frame:Show();
    end
end

--- Show badge.
function VersionBadgePanel:Show()
    if (self.frame) then
        self.frame:Show();
    end
end

--- Hide badge.
function VersionBadgePanel:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end
