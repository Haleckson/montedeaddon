--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create panel (one-time hint inside the professions view what the optional
-- TradeBoard addon adds; shown while it is not installed, dismissing persists)
local TradeBoardHintPanel = _G.professionMaster:CreateView("trade-board-hint");

-- panel layout constants
local PanelWidth = 460;
local ContentOffset = 18;  -- left/right inset of the texts
local BulletGap = 8;       -- space between the feature lines

--- Create the hint panel (hidden; Show sizes it to its wrapped content).
-- @param parentFrame The professions view frame to attach to.
function TradeBoardHintPanel:Create(parentFrame)
    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");

    -- centered dark panel with the trade board purple as border accent
    local frame = CreateFrame("Frame", nil, parentFrame, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    });
    frame:SetBackdropColor(0.06, 0.05, 0.08, 0.97);
    frame:SetBackdropBorderColor(0.62, 0.3, 0.9, 0.7);
    frame:SetWidth(PanelWidth);
    frame:SetHeight(240);
    frame:SetPoint("CENTER", parentFrame, "CENTER", 0, 20);
    frame:SetFrameLevel(parentFrame:GetFrameLevel() + 20);
    frame:EnableMouse(true);
    frame:Hide();
    self.frame = frame;

    -- title: trade board coin icon plus the addon name in its purple
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", ContentOffset, -16);
    title:SetText("|TInterface\\Icons\\INV_Misc_Coin_03:20|t |cffDA8CFF" .. localeService:Get("TradeBoardHintTitle"));

    -- intro line under the title
    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10);
    intro:SetPoint("RIGHT", frame, "RIGHT", -ContentOffset, 0);
    intro:SetJustifyH("LEFT");
    intro:SetWordWrap(true);
    intro:SetText(localeService:Get("TradeBoardHintIntro"));

    -- feature lines with purple bullets, anchored below each other so wrapped
    -- lines push the following ones down
    local previousText = intro;
    for index = 1, 3 do
        local feature = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        feature:SetPoint("TOPLEFT", previousText, "BOTTOMLEFT", 0, -BulletGap);
        feature:SetPoint("RIGHT", frame, "RIGHT", -ContentOffset, 0);
        feature:SetJustifyH("LEFT");
        feature:SetWordWrap(true);
        feature:SetText("|cffDA8CFF•|r " .. localeService:Get("TradeBoardHintFeature" .. index));
        previousText = feature;
    end

    -- footer: where to get the addon (gold, like the section labels)
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    footer:SetPoint("TOPLEFT", previousText, "BOTTOMLEFT", 0, -12);
    footer:SetPoint("RIGHT", frame, "RIGHT", -ContentOffset, 0);
    footer:SetJustifyH("LEFT");
    footer:SetWordWrap(true);
    footer:SetTextColor(1, 0.84, 0, 1);
    footer:SetText(localeService:Get("TradeBoardHintFooter"));
    self.footer = footer;

    -- dismiss button under the footer; closing persists account-wide, so the
    -- hint appears exactly once until clicked away
    local dismissButton = uiService:CreateFlatButton(frame, localeService:Get("TradeBoardHintDismiss"), function()
        self:Dismiss();
    end);
    dismissButton:SetHeight(22);
    dismissButton:SetWidth(math.max(110, (dismissButton:GetFontString():GetStringWidth() or 0) + 24));
    dismissButton:SetPoint("TOPLEFT", footer, "BOTTOMLEFT", 0, -14);
    self.dismissButton = dismissButton;

    -- close button top right dismisses too
    local closeButton = uiService:CreateFlatCloseButton(frame, function()
        self:Dismiss();
    end);
    closeButton:SetPoint("TOPRIGHT", -10, -10);
end

--- Show the hint and size the panel to its wrapped content (text heights are
--- only known after the first layout pass).
function TradeBoardHintPanel:Show()
    self.frame:Show();
    C_Timer.After(0, function()
        if (not self.frame:IsShown()) then return; end
        local frameTop = self.frame:GetTop();
        local buttonBottom = self.dismissButton:GetBottom();
        if (frameTop and buttonBottom) then
            self.frame:SetHeight(frameTop - buttonBottom + 16);
        end
    end);
end

--- Dismiss the hint for good (account-wide).
function TradeBoardHintPanel:Dismiss()
    self.frame:Hide();
    PM_Settings.tradeBoardHintDismissed = true;
    self.addon:Log("TradeBoardHintPanel", "Dismiss", "trade board hint dismissed");
end
