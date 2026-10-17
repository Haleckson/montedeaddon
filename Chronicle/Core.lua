local ADDON_NAME, ns = ...
ns = ns or {}
_G.Chronicle = ns

ns.name = ADDON_NAME or "Chronicle"
ns.displayName = "Chronicle Forever"
ns.version = "1.5.256"
ns.modules = {}
ns.callbacks = {}

function ns:BossDifficultyColor(bossLevel)
    local level = tonumber(bossLevel)
    local playerLevel = UnitLevel and tonumber(UnitLevel("player"))
    if not level or not playerLevel or playerLevel < 1 then return 1, .82, .1 end
    if GetCreatureDifficultyColor then
        local ok, color, green, blue = pcall(GetCreatureDifficultyColor, level)
        if ok then
            if type(color) == "table" and color.r and color.g and color.b then
                return color.r, color.g, color.b
            elseif type(color) == "number" and type(green) == "number" and
                type(blue) == "number" then
                return color, green, blue
            end
        end
    end
    local difference = level - playerLevel
    local grayLevel = playerLevel <= 5 and 0 or
        (playerLevel <= 39 and playerLevel - math.floor(playerLevel / 10) - 5 or playerLevel - 9)
    if level <= grayLevel then return .55, .55, .55 end
    if difference <= -3 then return .25, .75, .25 end
    if difference <= 2 then return 1, .82, .1 end
    if difference <= 4 then return 1, .48, .1 end
    return 1, .18, .18
end

function ns:RegisterModule(name, module)
    self.modules[name] = module
end

function ns:On(event, callback)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], callback)
end

function ns:Fire(event, ...)
    local list = self.callbacks[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Chronicle Forever:|r " .. tostring(err))
        end
    end
end

function ns:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Chronicle Forever:|r " .. tostring(message))
    end
end

function Chronicle_OnAddonCompartmentClick()
    ns:Toggle()
end

function Chronicle_OnAddonCompartmentEnter(button)
    if not GameTooltip then return end
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.displayName, 1, 0.82, 0.1)
    GameTooltip:AddLine(ns:L("subtitle"), 0.9, 0.85, 0.7)
    GameTooltip:AddLine("Version " .. ns.version, 0.72, 0.65, 0.52)
    GameTooltip:AddLine(ns:L("openAddon"), 1, 1, 1)
    GameTooltip:Show()
end

function Chronicle_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end




































































