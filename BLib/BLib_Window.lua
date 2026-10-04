-- BLib_Window.lua
-- The pieces an addon window is made of, beyond buttons and boxes: a tab
-- row, a status line, menus, a money box, shift-clicked links and a copy
-- dialog. Most were written for Countinghouse and moved here in 1.8.0 so
-- Forgemaster's windows are built from the same parts.
-- Depends on: BLib_Compat.lua, BLib_Core.lua, BLib_Widgets.lua, BLib_Format.lua

BLib = BLib or {}

-- ============================================================
-- TABS
-- BLib.MakeTabs(parent, names, width, t, onSelect)
-- A row of tab buttons from the parent's top left. onSelect(index) runs when
-- one is pressed (and on tabs:Select). Returns the tabs:
--   tabs.buttons[i]   tabs.current
--   tabs:Select(i)
--   tabs:SetNote(i, text, colour)  a short line under the tab ("3 to buy");
--                                  the caller leaves room for it (12 px)
-- ============================================================

function BLib.MakeTabs(parent, names, width, t, onSelect)
    local tabs = { buttons = {}, notes = {} }
    for i, name in ipairs(names) do
        local b = BLib.MakeButton(parent, name, width or 90, 22, t)
        if i == 1 then
            b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        else
            b:SetPoint("LEFT", tabs.buttons[i - 1], "RIGHT", 4, 0)
        end
        b:SetScript("OnClick", function() tabs:Select(i) end)
        tabs.buttons[i] = b
    end
    function tabs:Select(i)
        self.current = i
        for j, b in ipairs(self.buttons) do
            BLib.SetTC(b.label, j == i and t.accent or t.subText)
        end
        if onSelect then onSelect(i) end
    end
    function tabs:SetNote(i, text, colour)
        local b = self.buttons[i]
        if not b then return end
        local fs = self.notes[i]
        if not fs then
            fs = BLib.MakeFS(parent, BLib.FONT_SM - 1, t.subText)
            fs:SetPoint("TOP", b, "BOTTOM", 0, -2)
            fs:SetWidth(b:GetWidth())
            fs:SetWordWrap(false)
            self.notes[i] = fs
        end
        BLib.SetTC(fs, colour or t.subText)
        fs:SetText(text or "")
    end
    return tabs
end

-- ============================================================
-- STATUS LINE
-- BLib.MakeStatusLine(parent, t)
-- A line of text for the foot of a window: a message on the left, and
-- optionally a figure on the right. The caller anchors and sizes the frame.
--   line:SetText(text)        line:SetRightText(text)
--   line:SetRightEdge(frame)  the message stops short of this frame (a button
--                             or bar placed at the right)
-- ============================================================

function BLib.MakeStatusLine(parent, t)
    local line = CreateFrame("Frame", nil, parent)
    line:SetHeight(22)

    local right = BLib.MakeFS(line, BLib.FONT_SM, t.text)
    right:SetPoint("RIGHT", line, "RIGHT", -2, 0)
    right:SetJustifyH("RIGHT")
    right:SetWordWrap(false)
    line.right = right

    local text = BLib.MakeFS(line, BLib.FONT_SM, t.subText)
    text:SetPoint("LEFT", line, "LEFT", 2, 0)
    text:SetPoint("RIGHT", right, "LEFT", -10, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    line.text = text

    function line:SetText(s) text:SetText(s or "") end
    function line:SetRightText(s) right:SetText(s or "") end
    function line:SetRightEdge(frame)
        right:ClearAllPoints()
        right:SetPoint("RIGHT", frame, "LEFT", -10, 0)
    end
    return line
end

-- ============================================================
-- BUTTON STATE
-- BLib.SetButton(button, text, enabled)
-- A BLib button's label, whether it can be pressed, and whether it shows (an
-- empty or nil label hides it).
-- ============================================================

function BLib.SetButton(b, text, enabled)
    b.label:SetText(text)
    b:SetEnabled(enabled and true or false)
    b:SetAlpha(enabled and 1 or 0.45)
    b:SetShown(text ~= nil and text ~= "")
end

-- ============================================================
-- MENUS
-- Blizzard's MenuUtil, which draws menus of radios, checkboxes and titles in
-- the client's own style (Satchel and Forgemaster used it by hand first).
--   BLib.OpenMenu(owner, build)    build(root) adds the entries:
--       root:CreateTitle(text)
--       root:CreateButton(text, onClick)
--       root:CreateRadio(text, isSelected, onSelect, data)
--       root:CreateCheckbox(text, isSelected, onToggle)
--     Returns false when the client has no MenuUtil.
--   BLib.MENU_KEEP_OPEN            return it from a checkbox's onToggle to keep
--                                  the menu open for another pick
--   BLib.MakeMenuButton(parent, text, w, h, t, build, fallback)
--     A button with a "v" that opens the menu; fallback() runs instead on a
--     client without MenuUtil. button:SetText(text) changes its label.
-- ============================================================

BLib.MENU_KEEP_OPEN = MenuResponse and MenuResponse.Refresh

function BLib.OpenMenu(owner, build)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return false end
    MenuUtil.CreateContextMenu(owner, function(_, root) build(root) end)
    return true
end

function BLib.MakeMenuButton(parent, text, w, h, t, build, fallback)
    local b = BLib.MakeButton(parent, text, w, h, t)
    local arrow = BLib.MakeFS(b, BLib.FONT_SM, t.subText)
    arrow:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    arrow:SetText("v")
    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", b, "LEFT", 6, 0)
    b.label:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetWordWrap(false)
    b:SetScript("OnClick", function(self)
        if not BLib.OpenMenu(self, build) and fallback then fallback() end
    end)
    function b:SetText(s) self.label:SetText(s or "") end
    return b
end

-- ============================================================
-- MONEY BOX
-- BLib.MakeMoneyInput(parent, width, t, onChange)
-- A box for an amount of money, typed as "1g 20s", "75s" or copper, with the
-- amount it reads as shown beside it. onChange(copper, typed) runs on every
-- change; typed is true when the player made it rather than code.
--   box:GetAmount()   box:SetAmount(copper)
-- ============================================================

function BLib.MakeMoneyInput(parent, width, t, onChange)
    local box = BLib.MakeInputBox(parent, width, 22, t, "e.g. 1g 20s")
    local preview = BLib.MakeFS(parent, BLib.FONT_SM, t.subText)
    preview:SetPoint("LEFT", box, "RIGHT", 8, 0)
    box.preview = preview

    function box:GetAmount()
        local amount = BLib.ParseMoney(self:GetText())
        if amount and amount > 0 then return amount end
        return nil
    end

    function box:Update()
        local amount = self:GetAmount()
        if amount then
            preview:SetText(BLib.Money(amount))
        else
            preview:SetText(self:GetText() ~= "" and "|cffff6666not a price|r" or "")
        end
    end

    function box:SetAmount(copper)
        self:SetText(copper and BLib.MoneyPlain(copper) or "")
        self:Update()
    end

    box:HookScript("OnTextChanged", function(self, userInput)
        self:Update()
        if onChange then onChange(self:GetAmount(), userInput and true or false) end
    end)
    return box
end

-- ============================================================
-- SHIFT-CLICKED ITEMS
-- A shift-click on an item goes through ChatFrameUtil.InsertLink on Forever
-- (ChatEdit_InsertLink elsewhere). One hook serves every box that wants
-- links, across addons: a box takes one while it has focus, or, when
-- grabWhileShown is set, while it is on screen and no chat line is being
-- typed.
--   BLib.AcceptLinks(getBox, onLink, grabWhileShown)
-- getBox is a function, since the box may not be built yet.
-- ============================================================

local linkTargets = {}
local linkHooked = false

local function OnInsertLink(text)
    if type(text) ~= "string" or not text:find("item:", 1, true) then return end
    local typing = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
    -- A focused box first, then one that grabs while shown.
    for pass = 1, 2 do
        for _, target in ipairs(linkTargets) do
            local box = target.getBox()
            if box and box:IsVisible() then
                if (pass == 1 and box:HasFocus()) or (pass == 2 and target.grab and not typing) then
                    target.onLink(text)
                    return
                end
            end
        end
    end
end

function BLib.AcceptLinks(getBox, onLink, grabWhileShown)
    linkTargets[#linkTargets + 1] = { getBox = getBox, onLink = onLink, grab = grabWhileShown }
    if linkHooked then return end
    linkHooked = true
    if ChatFrameUtil and ChatFrameUtil.InsertLink then
        hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink)
    elseif type(ChatEdit_InsertLink) == "function" then
        hooksecurefunc("ChatEdit_InsertLink", OnInsertLink)
    end
end

-- ============================================================
-- COPY DIALOG
-- BLib.ShowCopyDialog(title, text, t)
-- Text selected in a box, ready for Ctrl-C: a shopping list for a forum post
-- or another addon. One dialog serves every addon; a second call replaces
-- what the first showed.
-- ============================================================

local copyDialog

local function BuildCopyDialog(t)
    local f, content = BLib.MakePopout("Copy", 420, 320, t, nil, "DIALOG")
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    tinsert(UISpecialFrames, f:GetName())

    local box = CreateFrame("Frame", nil, content)
    box:SetPoint("TOPLEFT", 6, -6)
    box:SetPoint("BOTTOMRIGHT", -6, 26)
    BLib.MakeBg(box, t.panelBg)
    BLib.ApplyBorder(box, box, t.border)

    local sf = CreateFrame("ScrollFrame", nil, box)
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -6, 6)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetWidth(420 - 8 - 12 - 12)
    eb:SetHeight(20)
    BLib.SetFontSafe(eb, BLib.FONT, BLib.FONT_SM, "")
    eb:SetTextColor(BLib.CR(t.text), BLib.CG(t.text), BLib.CB(t.text))
    sf:SetScrollChild(eb)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    -- The cursor kept in view as it moves through a long list.
    eb:SetScript("OnCursorChanged", function(_, _, y, _, h)
        local offset, height = sf:GetVerticalScroll(), sf:GetHeight()
        y = -y
        if y < offset then
            sf:SetVerticalScroll(y)
        elseif y + h > offset + height then
            sf:SetVerticalScroll(y + h - height)
        end
    end)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 28)))
    end)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() eb:SetFocus() end)
    f.editBox, f.scroll = eb, sf

    local hint = BLib.MakeFS(content, BLib.FONT_SM, t.subText)
    hint:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 8, 7)
    hint:SetText("Ctrl-A to select all, Ctrl-C to copy.")
    return f
end

function BLib.ShowCopyDialog(title, text, t)
    t = t or BLib.GetTheme()
    copyDialog = copyDialog or BuildCopyDialog(t)
    copyDialog.titleFS:SetText(title or "Copy")
    copyDialog.editBox:SetText(text or "")
    copyDialog.scroll:SetVerticalScroll(0)
    copyDialog:Show()
    copyDialog.editBox:SetFocus()
    copyDialog.editBox:HighlightText()
    return copyDialog
end
