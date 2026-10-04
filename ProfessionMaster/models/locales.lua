--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]
-- create model
local LocalesModel = _G.professionMaster:CreateModel("locales");

-- Create model.
function LocalesModel:Create()
    return {
        ["en"] = self:GetModel("locale-enUS"):Create(),
        ["de"] = self:GetModel("locale-deDE"):Create(),
        ["ru"] = self:GetModel("locale-ruRU"):Create(),
        ["es"] = self:GetModel("locale-esES"):Create(),
        ["fr"] = self:GetModel("locale-frFR"):Create(),
        ["it"] = self:GetModel("locale-itIT"):Create(),
        ["ko"] = self:GetModel("locale-koKR"):Create(),
        ["pt"] = self:GetModel("locale-ptBR"):Create(),
        ["zhCN"] = self:GetModel("locale-zhCN"):Create(),
        ["zhTW"] = self:GetModel("locale-zhTW"):Create()
    };
end
