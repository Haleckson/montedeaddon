--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create view
local PriceToggleButton = _G.professionMaster:CreateView("price-toggle-button");
PriceToggleButton.addon = _G.professionMaster;

--- Create a price toggle button on a container frame.
-- @param container The parent frame to attach the button to.
-- @param viewName The view identifier for per-view price state.
-- @param refreshCallback Function to call after toggling to refresh the view.
-- @return The created button frame.
function PriceToggleButton:Create(container, viewName, refreshCallback)
    -- create button frame
    local button = CreateFrame("Button", nil, container);
    button:SetSize(18, 18);
    button.viewName = viewName;

    -- add coin icon
    local icon = button:CreateTexture(nil, "ARTWORK");
    icon:SetPoint("TOPLEFT", 2, -2);
    icon:SetPoint("BOTTOMRIGHT", -2, 2);
    icon:SetTexture([[Interface\Icons\INV_Misc_Coin_01]]);
    button.icon = icon;

    -- add border overlay
    local border = button:CreateTexture(nil, "OVERLAY");
    border:SetPoint("TOPLEFT", -1, 1);
    border:SetPoint("BOTTOMRIGHT", 1, -1);
    border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]]);
    border:SetBlendMode("ADD");
    button.border = border;

    -- update visual state
    local auctionService = self.addon:GetService("auction");
    button.UpdateState = function(self)
        -- check if prices are shown for this view
        local showPrices = auctionService:CheckPricesVisible(self.viewName);
        if (showPrices) then
            -- gold border when active
            self.border:SetVertexColor(1, 0.82, 0, 0.8);
            self.icon:SetDesaturated(false);
        else
            -- gray border when inactive
            self.border:SetVertexColor(0.5, 0.5, 0.5, 0.5);
            self.icon:SetDesaturated(true);
        end
    end;

    -- handle click to toggle
    button:SetScript("OnClick", function(self)
        -- toggle setting for this view
        local showPrices = auctionService:CheckPricesVisible(self.viewName);
        auctionService:SetPricesVisible(self.viewName, not showPrices);

        -- update own state
        self:UpdateState();

        -- refresh the view
        if (refreshCallback) then
            refreshCallback();
        end
    end);

    -- add tooltip on hover
    local localeService = self.addon:GetService("locale");
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
        GameTooltip:SetText(localeService:Get("TogglePrices"));
        GameTooltip:Show();
    end);
    button:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    -- set initial state
    button:UpdateState();

    return button;
end
