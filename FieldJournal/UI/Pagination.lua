local _, FieldJournal = ...

FieldJournal.UI = FieldJournal.UI or {}
FieldJournal.UI.Pagination = FieldJournal.UI.Pagination or {}
local Pagination = FieldJournal.UI.Pagination

local function GetScrollBar(frame)
    return frame.scrollFrame.ScrollBar or _G.FieldJournalJournalScrollFrameScrollBar
end

local function GetController(frame)
    if frame.journalPages then return frame.journalPages end
    local controller = { pages = {}, page = 1 }
    frame.journalPages = controller

    local label = frame.right:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetWidth(100)
    label:SetJustifyH("RIGHT")
    label:SetPoint("BOTTOMRIGHT", frame.right, "BOTTOMRIGHT", -94, 12)
    controller.label = label

    local function MakeArrow(direction, rightOffset, delta)
        local button = CreateFrame("Button", nil, frame.right)
        button:SetSize(32, 32)
        button:SetPoint("BOTTOMRIGHT", frame.right, "BOTTOMRIGHT", rightOffset, 3)
        local texture = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
        button:SetNormalTexture(texture .. "Up")
        button:SetPushedTexture(texture .. "Down")
        button:SetDisabledTexture(texture .. "Disabled")
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        button:SetScript("OnClick", function()
            if delta < 0 and controller.page <= 1 then return end
            if delta > 0 and controller.page >= #controller.pages then return end
            controller.page = controller.page + delta
            Pagination:Render(frame)
            if FieldJournal.UI.PlayJournalSound then
                FieldJournal.UI:PlayJournalSound("page")
            elseif PlaySound then
                PlaySound((SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN) or 836)
            end
        end)
        return button
    end

    controller.previous = MakeArrow("Prev", -58, -1)
    controller.next = MakeArrow("Next", -22, 1)
    label:Hide()
    controller.previous:Hide()
    controller.next:Hide()
    return controller
end

local function SetPageViewport(frame, paged)
    frame.scrollFrame:ClearAllPoints()
    frame.scrollFrame:SetPoint("TOPLEFT", frame.right, "TOPLEFT", 0, -4)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame.right, "BOTTOMRIGHT",
        -26, paged and 38 or 4)
    frame.scrollFrame:SetVerticalScroll(0)
    local scrollBar = GetScrollBar(frame)
    if scrollBar then scrollBar:Hide() end
end

local MeasuredHeight

local function ActiveColor(value)
    local color, index = nil, 1
    while true do
        local startColor, endColor = value:find("|c%x%x%x%x%x%x%x%x", index)
        local startReset, endReset = value:find("|r", index, true)
        if not startColor and not startReset then return color end
        if startColor and (not startReset or startColor < startReset) then
            color = value:sub(startColor, endColor)
            index = endColor + 1
        else
            color = nil
            index = endReset + 1
        end
    end
end

-- A single record can exceed a page. Split only that record at a word or
-- newline boundary, carrying its color markup into the continuation page.
local function SplitOversizedBlock(frame, header, block, limit)
    local pieces = {}
    local remaining = block
    while MeasuredHeight(frame, header .. remaining) > limit do
        local cutStart, cutEnd
        for first, last in remaining:gmatch("()%s+()") do
            local candidate = remaining:sub(1, first - 1)
            if candidate ~= "" and MeasuredHeight(frame, header .. candidate) <= limit then
                cutStart, cutEnd = first, last
            elseif cutStart then
                break
            end
        end
        if not cutStart then break end
        local part = remaining:sub(1, cutStart - 1)
        local color = ActiveColor(part)
        pieces[#pieces + 1] = part .. (color and "|r" or "")
        remaining = (color or "") .. remaining:sub(cutEnd)
    end
    pieces[#pieces + 1] = remaining
    return pieces
end

MeasuredHeight = function(frame, value)
    frame.right.text:SetText(value)
    local height = frame.right.text:GetStringHeight() or 0
    if height > 0 then return height end
    -- The initial hidden-frame layout can report zero before the first show.
    -- This conservative estimate is only a fallback for that frame.
    local plain = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local lines = 0
    for line in (plain .. "\n"):gmatch("(.-)\n") do
        lines = lines + math.max(1, math.ceil(#line / 42))
    end
    return lines * 14
end

function Pagination:Clear(frame)
    local controller = frame.journalPages
    if not controller then return end
    controller.key = nil
    controller.pages = {}
    controller.label:Hide()
    controller.previous:Hide()
    controller.next:Hide()
    controller.pageMeta = nil
    if frame.ShowCreaturePage then frame:ShowCreaturePage(nil) end
    SetPageViewport(frame, false)
end

function Pagination:Render(frame)
    local controller = GetController(frame)
    local count = #controller.pages
    controller.page = math.max(1, math.min(controller.page, count))
    local pageText = controller.pages[controller.page] or ""
    frame.right.text:SetText(pageText)
    if frame.ShowCreaturePage then
        frame:ShowCreaturePage(controller.pageMeta and controller.pageMeta[controller.page])
    end
    local height = frame.right.text:GetStringHeight() or 0
    frame.scrollChild:SetHeight(math.max(frame.scrollFrame:GetHeight(), height + 8))
    frame.scrollFrame:SetVerticalScroll(0)
    local scrollBar = GetScrollBar(frame)
    if scrollBar then scrollBar:Hide() end
    controller.label:SetText("Page " .. controller.page .. "/" .. count)
    controller.previous:SetEnabled(controller.page > 1)
    controller.next:SetEnabled(controller.page < count)
    controller.label:Show()
    controller.previous:Show()
    controller.next:Show()
end

-- Each block is one complete entry. Repeated headers give context on every
-- page; GetStringHeight measures wrapped WoW text rather than character count.
function Pagination:Show(frame, key, header, blocks, requestedPage, creaturePages)
    local controller = GetController(frame)
    local previousPage = controller.key == key and controller.page or 1
    controller.key = key
    SetPageViewport(frame, true)

    local titleHeight = frame.subjectTitle and frame.subjectTitle:IsShown()
        and (math.max(frame.subjectTitle:GetStringHeight() or 0, 30) + 14) or 0
    local viewportHeight = frame.scrollFrame:GetHeight()
    if viewportHeight <= 0 then viewportHeight = 358 end
    controller.limit = math.max(80, viewportHeight - titleHeight - 8)

    local pages = {}
    local body = ""
    header = header or ""
    for _, block in ipairs(blocks or {}) do
        for _, part in ipairs(SplitOversizedBlock(frame, header, block, controller.limit)) do
            local candidate = body .. part
            if body ~= "" and MeasuredHeight(frame, header .. candidate) > controller.limit then
                pages[#pages + 1] = header .. body
                body = part
            else
                body = candidate
            end
        end
    end
    pages[#pages + 1] = header .. body
    controller.pageMeta = nil
    if creaturePages and #creaturePages > 0 then
        controller.pageMeta = {}
        for _, creature in ipairs(creaturePages) do
            pages[#pages + 1] = ""
            controller.pageMeta[#pages] = creature
        end
    end
    controller.pages = pages
    controller.page = requestedPage or previousPage
    self:Render(frame)
end
