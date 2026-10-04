-- BLib_Layout.lua
-- One edit mode for every addon (the user's request, 2026-10-01; HANDOVER "A GLOBAL EDIT MODE FOR EVERY ADDON").
--
-- An addon registers each thing that can be moved. /move (or /blib move, or an addon's own "unlock") lays a
-- handle over every registered thing from every addon at once, with a small toolbar: Lock, Grid, Reset all.
-- Drag a handle and the thing follows it; right-click it to put that one back; click one and the arrow keys
-- nudge it a unit at a time (Shift: ten). It locks itself when a fight starts and will not open in one: a secure
-- frame cannot be moved in combat. Escape locks it too.
--
-- Positions are not BLib's. Every addon already saves its own, each its own way (per character in screen
-- units, account-wide anchor and offsets, a setting), so an item carries an adapter over that rather than a
-- common format, and nothing is migrated.
--
--   BLib.Layout:Register(item)        item = {
--       id      = "Foreverbound.bar1",   unique
--       addon   = "Foreverbound",        shown on the handle, and what Unlock(addon) picks out
--       name    = "Bar 1",
--       frame   = frame,                 or getFrame = function() return frame end
--       isShown = function() end,        optional: whether it gets a handle now (default: the frame is shown)
--       getRect = function() end,        optional: left, bottom, width, height in UIParent's units
--                                        (default: the frame's own rectangle, scale and all)
--       setPos  = function(left, bottom) end,   required: put it there and save it; called while dragging
--       drop    = function(left, bottom) end,   optional: where it lands (snapping, docking); default setPos
--       reset   = function() end,        optional: back to where it started
--   }
--   BLib.Layout:Unregister(id)
--   BLib.Layout:Unlock(addon, window)  open edit mode; addon (optional) is drawn brighter than the rest;
--                              window (optional), its settings window, is put away until the mode shuts
--   BLib.Layout:Lock()         BLib.Layout:IsUnlocked()       BLib.Layout:Refresh()
--   BLib.Layout:OnChange(fn)   fn(unlocked, addon): for an addon that shows more while things are arranged
--                              (empty party frames, bars hidden by a rule)
--
-- An addon must still work with an older BLib that has no BLib.Layout: guard every call and keep its own
-- mover as the fallback, as with BLib.Rival.

BLib = BLib or {}
local L = {}
BLib.Layout = L

local items, order = {}, {}       -- [id] = item; ids in registration order
local handles = {}                -- [id] = handle frame
local listeners = {}
local unlocked, focus = false, nil
local gridOn = false
local selected                    -- the handle the arrow keys move
local toolbar, grid

local GRID = 16                   -- grid spacing and snap, in UIParent units
local EDGE_SNAP = 8               -- this close to a screen edge, it goes to the edge

local function Theme() return BLib.GetTheme and BLib.GetTheme("BLib") or {} end
local function Say(text) if BLib.Print then BLib.Print("BLib", text) else print("BLib: " .. text) end end

-- ============================================================
-- REGISTRY
-- ============================================================

function L:Register(item)
    if type(item) ~= "table" or type(item.id) ~= "string" or type(item.setPos) ~= "function" then
        return false
    end
    if not items[item.id] then order[#order + 1] = item.id end
    items[item.id] = item
    if unlocked then L:Refresh() end
    return true
end

function L:Unregister(id)
    if not items[id] then return end
    items[id] = nil
    for i, v in ipairs(order) do
        if v == id then table.remove(order, i) break end
    end
    if handles[id] then handles[id]:Hide() end
end

function L:Get(id) return items[id] end
function L:IsUnlocked() return unlocked end

function L:OnChange(fn)
    if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

local function Notify()
    for _, fn in ipairs(listeners) do pcall(fn, unlocked, focus) end
end

-- ============================================================
-- WHERE THINGS ARE
-- ============================================================

local function FrameOf(item)
    if item.getFrame then
        local ok, f = pcall(item.getFrame)
        return ok and f or nil
    end
    return item.frame
end

-- A frame's rectangle in UIParent's units: its own coordinates are in its own
-- effective scale.
function L.RectOf(frame)
    if not (frame and frame.GetLeft) then return nil end
    local left, bottom, w, h = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
    if not (left and bottom and w and h) then return nil end
    local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return left * k, bottom * k, w * k, h * k
end

local function RectFor(item)
    if item.getRect then
        local ok, l, b, w, h = pcall(item.getRect)
        if ok and l and b and w and h then return l, b, w, h end
        return nil
    end
    return L.RectOf(FrameOf(item))
end

local function Shown(item)
    if item.isShown then
        local ok, on = pcall(item.isShown)
        return ok and on and true or false
    end
    local f = FrameOf(item)
    return f and f.IsShown and f:IsShown() or false
end

-- Where a drop lands: whole units, on the grid when it is on, and onto a
-- screen edge when it is within a few units of one.
local function Snap(left, bottom, w, h)
    if gridOn then
        left   = math.floor(left / GRID + 0.5) * GRID
        bottom = math.floor(bottom / GRID + 0.5) * GRID
    else
        left, bottom = math.floor(left + 0.5), math.floor(bottom + 0.5)
    end
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if math.abs(left) <= EDGE_SNAP then left = 0 end
    if math.abs(bottom) <= EDGE_SNAP then bottom = 0 end
    if w and math.abs(sw - (left + w)) <= EDGE_SNAP then left = sw - w end
    if h and math.abs(sh - (bottom + h)) <= EDGE_SNAP then bottom = sh - h end
    return left, bottom
end
L.Snap = Snap   -- for the fixtures

-- ============================================================
-- HANDLES
-- ============================================================

local function Place(handle, item)
    local l, b, w, h = RectFor(item)
    if not l then handle:Hide() return false end
    handle:ClearAllPoints()
    handle:SetSize(math.max(w, 24), math.max(h, 16))
    handle:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
    return true
end

local function Paint(handle)
    local t = Theme()
    local a = t.accent or { 1, 0.82, 0, 1 }
    local item = items[handle.id]
    local dim = focus and item and item.addon ~= focus
    local fill = (handle == selected) and 0.45 or 0.28
    handle.bg:SetColorTexture(a[1], a[2], a[3], dim and fill * 0.45 or fill)
    handle:SetAlpha(dim and 0.6 or 1)
end

local function Move(item, left, bottom, final)
    local fn = final and (item.drop or item.setPos) or item.setPos
    pcall(fn, left, bottom)
end

local SetArrowKeys   -- below: the arrow keys nudge the selected handle

local function Select(handle)
    local old = selected
    selected = handle
    if old and old ~= handle then Paint(old) end
    if handle then Paint(handle) end
    SetArrowKeys(handle ~= nil)
end

local function Nudge(handle, dx, dy)
    local item = items[handle.id]
    local l, b = RectFor(item)
    if not l then return end
    Move(item, math.floor(l + 0.5) + dx, math.floor(b + 0.5) + dy, true)
    Place(handle, item)
end

-- ============================================================
-- KEYS
--
-- Escape locks the mode and the arrow keys nudge the selected handle, through
-- override bindings that click a button of ours. Never a frame that takes the
-- keyboard and passes keys on (SetPropagateKeyboardInput): a key passed on from
-- addon code runs its binding tainted, and Escape then reached Blizzard's game
-- menu handlers in BLib's name ("BLib tried to call the protected function
-- SpellStopCasting()", the user, 2026-10-03), and any action bar key would have
-- too. Override bindings are set and cleared out of combat only; the mode never
-- is open in one.
-- ============================================================

local keys        -- the button the bindings click; also the owner of Escape's
local arrowOwner  -- owns the arrow keys' bindings, so they clear on their own

local NUDGE = {
    UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 },
    ["SHIFT-UP"] = { 0, 10 }, ["SHIFT-DOWN"] = { 0, -10 }, ["SHIFT-LEFT"] = { -10, 0 }, ["SHIFT-RIGHT"] = { 10, 0 },
}

local function Keys()
    if keys then return keys end
    keys = CreateFrame("Button", "BLibLayoutKeys", UIParent)
    keys:Hide()
    keys:SetScript("OnClick", function(_, button)
        if InCombatLockdown() then return end
        if button == "ESCAPE" then
            L:Lock()
        elseif NUDGE[button] and selected then
            Nudge(selected, NUDGE[button][1], NUDGE[button][2])
        end
    end)
    arrowOwner = CreateFrame("Frame", nil, UIParent)
    return keys
end

SetArrowKeys = function(on)
    if InCombatLockdown() or not (SetOverrideBindingClick and ClearOverrideBindings) then return end
    Keys()
    ClearOverrideBindings(arrowOwner)
    if on then
        for key in pairs(NUDGE) do SetOverrideBindingClick(arrowOwner, true, key, "BLibLayoutKeys", key) end
    end
end

local function SetEscape(on)
    if InCombatLockdown() or not (SetOverrideBindingClick and ClearOverrideBindings) then return end
    Keys()
    ClearOverrideBindings(keys)
    if on then SetOverrideBindingClick(keys, true, "ESCAPE", "BLibLayoutKeys", "ESCAPE") end
end

local function HandleFor(id)
    if handles[id] then return handles[id] end
    local h = CreateFrame("Button", nil, UIParent)
    h.id = id
    h:SetFrameStrata("DIALOG")
    h:SetMovable(true)
    h:SetClampedToScreen(true)
    h:RegisterForDrag("LeftButton")
    h:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    h.bg = h:CreateTexture(nil, "BACKGROUND")
    h.bg:SetAllPoints()
    local t = Theme()
    if BLib.ApplyBorder and t.accent then BLib.ApplyBorder(h, h, t.accent) end
    h.label = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h.label:SetPoint("CENTER")

    h:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        Select(self)
        self:StartMoving()
        local item = items[self.id]
        -- The thing follows the handle while it is dragged, not only when it is dropped.
        self:SetScript("OnUpdate", function(handle)
            if InCombatLockdown() then return end
            local l, b = handle:GetLeft(), handle:GetBottom()
            if l and b and item then Move(item, l, b, false) end
        end)
    end)
    h:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:StopMovingOrSizing()
        local item = items[self.id]
        if not item or InCombatLockdown() then L:Refresh() return end
        local l, b = Snap(self:GetLeft(), self:GetBottom(), self:GetWidth(), self:GetHeight())
        Move(item, l, b, true)
        Place(self, item)
    end)
    h:SetScript("OnClick", function(self, button)
        local item = items[self.id]
        if button == "RightButton" then
            if item and item.reset and not InCombatLockdown() then
                pcall(item.reset)
                Place(self, item)
            end
        else
            Select(self)
        end
    end)
    h:SetScript("OnEnter", function(self)
        local item = items[self.id]
        if not item then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine((item.addon and (item.addon .. ": ") or "") .. (item.name or item.id), 1, 1, 1)
        GameTooltip:AddLine("Drag to move. Click, then the arrow keys to nudge (Shift: 10).", 0.8, 0.8, 0.8, true)
        if item.reset then GameTooltip:AddLine("Right-click: back to where it started.", 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    h:SetScript("OnLeave", function() GameTooltip:Hide() end)

    handles[id] = h
    return h
end

-- ============================================================
-- THE GRID
-- ============================================================

local function ShowGrid(on)
    if on and not grid then
        grid = CreateFrame("Frame", nil, UIParent)
        grid:SetAllPoints(UIParent)
        grid:SetFrameStrata("BACKGROUND")
        grid.lines = {}
    end
    if not grid then return end
    for _, l in ipairs(grid.lines) do l:Hide() end
    if not on then grid:Hide() return end
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local n = 0
    local function Line(vertical, at, centre)
        n = n + 1
        local l = grid.lines[n] or grid:CreateTexture(nil, "BACKGROUND")
        grid.lines[n] = l
        l:ClearAllPoints()
        l:SetColorTexture(1, 1, 1, centre and 0.35 or 0.08)
        if vertical then
            l:SetPoint("TOPLEFT", grid, "TOPLEFT", at, 0)
            l:SetSize(1, h)
        else
            l:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", 0, at)
            l:SetSize(w, 1)
        end
        l:Show()
    end
    for x = 0, w, GRID * 2 do Line(true, x) end
    for y = 0, h, GRID * 2 do Line(false, y) end
    Line(true, math.floor(w / 2), true)
    Line(false, math.floor(h / 2), true)
    grid:Show()
end

-- ============================================================
-- THE TOOLBAR
-- ============================================================

local function Count()
    local shown, addons, seen = 0, 0, {}
    for _, id in ipairs(order) do
        local h = handles[id]
        if h and h:IsShown() then
            shown = shown + 1
            local a = items[id].addon or "?"
            if not seen[a] then seen[a] = true addons = addons + 1 end
        end
    end
    return shown, addons
end

-- Only a key of Blizzard's table is ours. Never "StaticPopupDialogs = StaticPopupDialogs or {}": writing the
-- global itself, even with the same table, puts BLib's taint on every read of it, so every one of Blizzard's
-- popups (Delete Item, the summons, Release Spirit) ran in BLib's name (taint audit, 2026-10-03).
if StaticPopupDialogs then
    StaticPopupDialogs["BLIB_LAYOUT_RESET_ALL"] = {
        text = "Put everything shown back where it started?",
        button1 = YES or "Yes", button2 = NO or "No",
        OnAccept = function() L:ResetAll() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

local function BuildToolbar()
    local t = Theme()
    local f = CreateFrame("Frame", "BLibLayoutToolbar", UIParent)
    f:SetSize(330, 54)
    f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if BLib.MakeBg and t.frameBg then BLib.MakeBg(f, t.frameBg) end
    if BLib.ApplyBorder and t.border then BLib.ApplyBorder(f, f, t.border) end

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 8, -6)
    f.title:SetText("Edit mode")
    f.count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.count:SetPoint("TOPRIGHT", -8, -8)

    local function Button(text, x, w, accent, onClick)
        local b = BLib.MakeButton and BLib.MakeButton(f, text, w, 22, t, accent)
            or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        if not BLib.MakeButton then b:SetSize(w, 22) b:SetText(text) end
        b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, 6)
        b:SetScript("OnClick", onClick)
        return b
    end
    f.lock = Button("Lock", 8, 90, true, function() L:Lock() end)
    f.grid = Button("Grid: off", 104, 100, false, function(self)
        gridOn = not gridOn
        ShowGrid(gridOn)
        local label = self.label or self
        if label.SetText then label:SetText(gridOn and "Grid: on" or "Grid: off") end
    end)
    f.reset = Button("Reset all", 210, 112, false, function()
        if StaticPopup_Show then StaticPopup_Show("BLIB_LAYOUT_RESET_ALL") else L:ResetAll() end
    end)

    f:Hide()
    return f
end

local function UpdateToolbar()
    if not toolbar then return end
    local shown, addons = Count()
    toolbar.count:SetText(("%d frame%s, %d addon%s"):format(shown, shown == 1 and "" or "s",
        addons, addons == 1 and "" or "s"))
end

-- ============================================================
-- OPEN AND SHUT
-- ============================================================

function L:Refresh()
    if not unlocked then
        for _, h in pairs(handles) do h:Hide() end
        return
    end
    for _, id in ipairs(order) do
        local item = items[id]
        if Shown(item) then
            local h = HandleFor(id)
            h.label:SetText(item.name or id)
            if Place(h, item) then
                Paint(h)
                h:Show()
            end
        elseif handles[id] then
            handles[id]:Hide()
        end
    end
    UpdateToolbar()
end

-- Windows put away for the mode: an addon's settings window, when the mode was
-- opened from it, would sit over what is being moved (the user, 2026-10-03).
-- Shown again when the mode shuts, however it shuts.
local putAway = {}

-- window (optional): the caller's settings window. Hidden now if it is open,
-- and shown again when the mode shuts.
function L:Unlock(addon, window)
    if InCombatLockdown() then
        Say("not in combat: frames that are secure cannot be moved in a fight.")
        return false
    end
    if type(window) == "table" and window.IsShown and window:IsShown() then
        window:Hide()
        putAway[#putAway + 1] = window
    end
    focus = addon
    local was = unlocked
    unlocked = true
    toolbar = toolbar or BuildToolbar()
    SetEscape(true)   -- Escape locks, by a binding of its own (see KEYS)
    toolbar:Show()
    Notify()
    L:Refresh()
    -- Things an addon shows only while arranged (Notify) may take a frame to lay out.
    if C_Timer and C_Timer.After then C_Timer.After(0, function() if unlocked then L:Refresh() end end) end
    if not was then
        local shown, addons = Count()
        Say(("edit mode: %d frame%s from %d addon%s. Drag to move; Lock, Escape or /move when done."):format(
            shown, shown == 1 and "" or "s", addons, addons == 1 and "" or "s"))
    end
    return true
end

function L:Lock(quiet)
    if not unlocked then return end
    unlocked, focus = false, nil
    SetEscape(false)
    Select(nil)
    for _, h in pairs(handles) do
        h:SetScript("OnUpdate", nil)
        h:StopMovingOrSizing()
        h:Hide()
    end
    if toolbar then toolbar:Hide() end
    gridOn = false
    ShowGrid(false)
    if toolbar and toolbar.grid then
        local label = toolbar.grid.label or toolbar.grid
        if label.SetText then label:SetText("Grid: off") end
    end
    Notify()
    -- After Notify, so a window shows the addon's state as it is now (its unlock toggle off).
    local windows = putAway
    putAway = {}
    for _, w in ipairs(windows) do w:Show() end
    if not quiet then Say("locked.") end
end

function L:Toggle(addon)
    if unlocked then L:Lock() else L:Unlock(addon) end
end

function L:ResetAll()
    if InCombatLockdown() then return end
    for _, id in ipairs(order) do
        local item = items[id]
        local h = handles[id]
        if item.reset and h and h:IsShown() then pcall(item.reset) end
    end
    L:Refresh()
end

-- A fight locks it: a secure frame cannot be moved in combat. PLAYER_REGEN_DISABLED comes before the lockdown.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if unlocked then
            L:Lock(true)
            Say("edit mode locked for combat.")
        end
    elseif unlocked then
        if gridOn then ShowGrid(true) end
        L:Refresh()
    end
end)

-- ============================================================
-- SLASH
-- ============================================================

-- /move, unless another addon has it. Claimed at login, when every addon's own slash commands exist.
local claim = CreateFrame("Frame")
claim:RegisterEvent("PLAYER_LOGIN")
claim:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local taken = false
    for name, _ in pairs(SlashCmdList) do
        for i = 1, 20 do   -- bounded: a command has a handful of aliases
            local alias = _G["SLASH_" .. name .. i]
            if type(alias) ~= "string" then break end
            if string.lower(alias) == "/move" then taken = true end
        end
    end
    if not taken then
        SLASH_BLIBLAYOUT1 = "/move"
        SlashCmdList["BLIBLAYOUT"] = function(msg)
            local addon = msg and msg:match("^%s*(%S.-)%s*$")
            L:Toggle(addon)
        end
    end
    L.slashMove = not taken
end)
