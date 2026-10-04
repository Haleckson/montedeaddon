local ADDON_NAME, ns = ...
ns = ns or {}
_G.Chronicle = ns

ns.name = ADDON_NAME or "Chronicle"
ns.displayName = "Chronicle Forever"
ns.version = "1.5.65"
ns.modules = {}
ns.callbacks = {}

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



























































