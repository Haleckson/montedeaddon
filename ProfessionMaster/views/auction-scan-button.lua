--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local AuctionScanButton = _G.professionMaster:CreateView("auction-scan-button");

--- Attach the price scan button to the auction house frame (created once).
-- The button is the manual trigger of the own price scan (see auction-scan
-- service) and shows the scan progress and the cooldown until the next scan.
function AuctionScanButton:Attach()
    -- the blizzard auction frame exists once the auction house was opened
    local isModern = self:GetService("auction-scan").isModern;
    local parent = isModern and AuctionHouseFrame or AuctionFrame;
    if (not parent) then
        return;
    end

    -- already created: only refresh the state
    if (self.button) then
        self:UpdateState();
        self:StartTicker();
        return;
    end

    local uiService = self:GetService("ui");
    local localeService = self:GetService("locale");
    local scanService = self:GetService("auction-scan");

    -- flat button beside the portrait, left of the centered title
    local button = uiService:CreateFlatButton(parent, localeService:Get("PriceScanButton"), function()
        scanService:StartScan(false);
    end);
    button:SetSize(130, 18);
    button:SetFrameLevel(parent:GetFrameLevel() + 5);
    if (isModern) then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -4);
    else
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 75, -14);
    end
    self.button = button;

    -- tooltip with the last scan info
    uiService:BindTooltip(button, function()
        return self:GetTooltipText();
    end);

    -- follow the scan state (start, progress, finish, abort)
    scanService:AddListener(function()
        self:UpdateState();
    end);

    self.addon:Log("AuctionScanButton", "Attach", "scan button attached to auction house frame");
    self:UpdateState();
    self:StartTicker();
end

--- Build the tooltip text: description plus last scan time and price count.
-- @return tooltip text.
function AuctionScanButton:GetTooltipText()
    local localeService = self:GetService("locale");
    local scanService = self:GetService("auction-scan");
    local text = localeService:Get("PriceScanButtonTooltip");

    local lastScan = scanService:GetLastScanTime();
    if (lastScan) then
        local age = self:GetService("timer"):FormatTime(math.max(1, time() - lastScan), true);
        text = text .. "\n\n" .. localeService:Get("PriceScanLastScan", age, scanService:GetPriceCount());
    else
        text = text .. "\n\n" .. localeService:Get("PriceScanNever");
    end

    return text;
end

--- Update the button text: scan progress, cooldown countdown or ready to scan.
function AuctionScanButton:UpdateState()
    if (not self.button) then
        return;
    end

    local localeService = self:GetService("locale");
    local scanService = self:GetService("auction-scan");

    if (scanService:IsInProgress()) then
        self.button:SetText(localeService:Get("PriceScanButtonScanning", math.floor(scanService.progress * 100)));
        return;
    end

    local wait = scanService:GetSecondsUntilNextScan();
    if (wait > 0) then
        self.button:SetText(localeService:Get("PriceScanButtonCooldown", self:GetService("timer"):FormatTime(wait)));
    else
        self.button:SetText(localeService:Get("PriceScanButton"));
    end
end

--- Refresh the countdown once per second while the auction house is open.
function AuctionScanButton:StartTicker()
    if (self.ticker) then
        return;
    end

    self.ticker = C_Timer.NewTicker(1, function()
        self:UpdateState();
    end);
end

--- Stop the countdown refresh when the auction house closes.
function AuctionScanButton:Detach()
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
end
