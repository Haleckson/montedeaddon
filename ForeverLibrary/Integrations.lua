local _, A = ...
local name = "ForeverLibrary"

function A.CreateMinimapButton()
    if A.broker then return end
    local brokerLib = LibStub("LibDataBroker-1.1")
    local iconLib = LibStub("LibDBIcon-1.0")
    A.broker = brokerLib:NewDataObject(name, {
        type = "launcher",
        label = "Forever Library Scout",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "RightButton" then
                A.db.showTracker = not A.db.showTracker
                A.Refresh()
            else A.ToggleWindow() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Forever Library Scout", 1, 0.82, 0.45)
            local found, returned = A.Counts()
            tooltip:AddLine(string.format("%d / 40 collected • %d returned", found, returned), 1, 1, 1)
            tooltip:AddLine("Left-click: journal | Right-click: tracker", 1, 1, 1)
            tooltip:AddLine("Drag to move the minimap button.", 0.7, 0.7, 0.7)
        end,
    })
    if type(A.db.minimap) ~= "table" then A.db.minimap = {minimapPos = 225} end
    if Minimap then
        if iconLib:IsRegistered(name) then iconLib:Refresh(name, A.db.minimap)
        else iconLib:Register(name, A.broker, A.db.minimap) end
    end
end

function A.ToggleMinimapButton()
    A.CreateMinimapButton()
    A.db.minimap.hide = not A.db.minimap.hide
    local iconLib = LibStub("LibDBIcon-1.0")
    if iconLib:IsRegistered(name) then
        if A.db.minimap.hide then iconLib:Hide(name) else iconLib:Show(name) end
    end
end
