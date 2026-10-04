local _, ns = ...

function ns.IsCollected(id)
    return ns.collected and ns.collected[id] == true
end

function ns.SetCollected(id, value)
    if not ns.books[id] then return end
    -- Explicit false is a manual override: bag scans must not undo the user.
    ns.collected[id] = value == true
    if GameTooltip then GameTooltip:Hide() end
    ns.Refresh()
end

function ns.InitTracking()
    if type(HandyNotes_ForeverBooksCharDB) ~= "table" then HandyNotes_ForeverBooksCharDB = {} end
    local db = HandyNotes_ForeverBooksCharDB
    if type(db.collected) ~= "table" then db.collected = {} end
    ns.collected = db.collected
    for id, value in pairs(ns.collected) do
        if not ns.books[id] or type(value) ~= "boolean" then ns.collected[id] = nil end
    end
    ns.ScanBags()
end

function ns.ScanBags()
    if not ns.collected or not ns.db.autoCollect then return end
    local slots = C_Container and C_Container.GetContainerNumSlots
    local itemAt = C_Container and C_Container.GetContainerItemID
    if not slots or not itemAt then return end
    local changed = false
    -- Scan only carried bags, never other players or bank containers.
    -- Item IDs work in all client languages and need no item-cache requests.
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, slots(bag) do
            local itemID = itemAt(bag, slot)
            local id = itemID and ns.itemBooks[itemID]
            if id and ns.collected[id] == nil then
                ns.collected[id] = true
                changed = true
            end
        end
    end
    if changed then ns.Refresh() end
end

-- A shared Blackrock reference pin represents TWO books. Let the player
-- select the actual book instead of silently completing both.
local picker
function ns.ShowBookPicker(entries)
    if not picker then
        picker = CreateFrame("Frame", "ForeverBooksPicker", UIParent, "BasicFrameTemplateWithInset")
        picker:SetSize(460, 150)
        picker:SetPoint("CENTER")
        picker:SetFrameStrata("DIALOG")
        picker.TitleText:SetText("Forever Books – Buch auswählen")
        picker.buttons = {}
        if UISpecialFrames then table.insert(UISpecialFrames, "ForeverBooksPicker") end
    end
    for _, button in ipairs(picker.buttons) do button:Hide() end
    picker:SetHeight(55 + #entries * 34)
    for i, entry in ipairs(entries) do
        local id = entry.book
        local button = picker.buttons[i]
        if not button then
            button = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
            button:SetSize(430, 28)
            button:SetPoint("TOP", 0, -30 - (i - 1) * 34)
            picker.buttons[i] = button
        end
        button:SetText((ns.IsCollected(id) and "[x] " or "[ ] ") .. ns.books[id].title)
        button:SetScript("OnClick", function()
            ns.SetCollected(id, not ns.IsCollected(id))
            picker:Hide()
        end)
        button:Show()
    end
    picker:Show()
end
