-- LibItemDB-1.0 — the price configuration window (MINOR 25)
--
-- Where the numbers COME FROM on this machine: which sources are on, in what order, which
-- statistic a bare lookup answers with, and the scan. Per-account preferences, nothing else.
-- Guild policy (discounts, overrides, donation rates) is a consumer's and never appears here.
--
-- ITS OWN WINDOW, not a Blizzard options page — the operator's direction, 2026-09-14, with
-- VersionCheck-1.0's roster window as the reference: LibAceGUIWidgets' ClearFrame (the suite's
-- chrome, bottom bar exposed), a TabGroup branded with W:BrandTabGroup, and a RowList where a list
-- is wanted. Built on FIRST OPEN and never before: ~20 addons load this library and most of their
-- users will never type the command, so they do not pay for a window they do not open.
--
-- The window owns no data. Rows come from GetPriceSources, every control writes through
-- SetPriceSetting / MovePriceSource, and it repaints on the library's own callbacks — so a
-- consumer changing a setting through the API is reflected here, and vice versa.

local MAJOR = "LibItemDB-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib or not lib._PriceStore then return end

local function Widgets() return LibStub and LibStub("LibAceGUIWidgets-1.0", true) or nil end

lib.priceWindow = lib.priceWindow or nil

-- A source's on/off goes through SetPriceSourceEnabled(id), whichever kind of source the row is:
-- the built-ins map to their settings keys inside the library, and a FED source (a guild's price
-- list handed to StoreExternalPrices) has no settings key at all. This file used to keep its own
-- id -> key table; that was the same fact in two places, and it could not have known a fed id.

-- The per-source secondary toggles, for the row's right-click menu. Wording from TOGPM's
-- settings panel, where these lived until 2026-09-14.
local SUB_TOGGLES = {
    auctionator = { { key = "useAuctionatorHistorical", text = "Use cached historical fallback" } },
    auctioneer  = { { key = "useAuctioneerCached",      text = "Use cached stat-engine fallback" } },
    tsm         = { { key = "useTSMAppHelper",          text = "Region data from the TSM Desktop App first" } },
}

local HELP = "Where LibItemDB's item prices come from on this machine.\n\n"
    .. "Sources -- one row per price source. Click the check to turn a source on or off, the "
    .. "arrows to change its precedence, or right-click a row for its extra options. A lookup "
    .. "asks each enabled source in order and takes the first answer.\n\n"
    .. "Detected -- whether that addon is installed and loaded right now. A price list another "
    .. "addon feeds in (a guild's published list, say) is a source too: Detected means this realm "
    .. "and faction hold its data, and Data age is how old its newest figure is.\n\n"
    .. "Default statistic -- what a lookup answers with when the caller does not name one.\n\n"
    .. "Scan -- LibItemDB's own Auction House scan: the whole house in one server query, priced "
    .. "per unit. Also the ItemDB Scan button on the Auction House itself.\n\n"
    .. "Tooltip -- the lines LibItemDB adds to item tooltips: a material's expansion, where it "
    .. "comes from and which professions use it, and every item's ID. Each can be turned off, "
    .. "and professions can be shown as icons or as words.\n\n"
    .. "These are your account's preferences. Guild pricing policy lives in the addon that uses "
    .. "the numbers, not here."

local AUTO_SCAN_TIP = "Off by default. When on, LibItemDB scans the entire Auction House (a single "
    .. "getAll query) each time you open the AH. WARNING: the server limits that scan to roughly ONCE "
    .. "EVERY 15 MINUTES for your whole game client, and the limit is shared across all addons -- if "
    .. "another Auction House addon (Auctionator, TradeSkillMaster, ...) runs its own full scan, "
    .. "turning this on will consume that budget and block theirs."

local DELAY_TIP = "Seconds between targeted-scan queries. The client default is 1.5s on Classic Era "
    .. "and Anniversary and 3.0s on TBC, Wrath, Cata and MoP, whose servers throttle stricter. Lower "
    .. "it for faster scans, raise it if scans stall. 0.5-10 seconds."

-- ---------------------------------------------------------------------------
-- Pure helpers (specced without a frame)
-- ---------------------------------------------------------------------------
--- Seconds as a short age: "never" for nil, "just now" under a minute, then "5m", "2h 14m",
--- "3d 4h". For "last scan 3d ago" in any consumer's UI, so the wording matches this window's.
function lib:FormatPriceAge(seconds)
    if type(seconds) ~= "number" or seconds < 0 then return "never" end
    if seconds < 60 then return "just now" end
    local m = math.floor(seconds / 60)
    if m < 60 then return m .. "m" end
    local h = math.floor(m / 60)
    m = m % 60
    if h < 24 then return (m > 0) and (h .. "h " .. m .. "m") or (h .. "h") end
    local d = math.floor(h / 24)
    h = h % 24
    return (h > 0) and (d .. "d " .. h .. "h") or (d .. "d")
end

--- The Sources tab's rows, one per source in precedence order. Frame-free so the shape a user
--- sees is pinned by a spec without building the window.
function lib:BuildPriceSourceRows()
    local rows = {}
    local sources = self:GetPriceSources()
    for _, src in ipairs(sources) do
        local labels = {}
        for _, stat in ipairs(src.statistics) do labels[#labels + 1] = self:GetPriceStatisticLabel(stat) end
        rows[#rows + 1] = {
            id         = src.id,
            name       = src.name,
            detected   = src.detected and "Yes" or "No",
            enabled    = src.enabled and "On" or "Off",
            isEnabled  = src.enabled,
            statistics = table.concat(labels, ", "),
            -- Only a source the library holds the data of can be dated: the own scan and a fed
            -- list. A third party's row says nothing rather than "never", which would be a claim.
            age        = src.count and self:FormatPriceAge(src.age) or "",
            precedence = src.precedence,
            total      = #sources,
        }
    end
    return rows
end

--- The Scan tab's status lines, frame-free.
--- @return string auctionHouse "Auction House: open" | "Auction House: closed"
--- @return string lastScan     "Last full scan: 2h 14m ago (1,234 items)" | "Last full scan: never"
--- @return string|nil progress "Scanning ... 12/40" while a scan runs, nil otherwise
function lib:BuildScanStatus()
    local st = self:GetScanState()
    local ah = "Auction House: " .. (st.auctionHouseOpen and "open" or "closed")
    local last
    if st.lastScanAt then
        local age = self:FormatPriceAge(self:_PriceNow() - st.lastScanAt)
        last = ("Last full scan: %s ago (%d items)"):format(age, st.lastScanCount or 0)
    else
        last = "Last full scan: never"
    end
    local progress
    if st.kind == "full" then
        progress = "Scanning the whole Auction House..."
    elseif st.kind == "targeted" then
        progress = ("Scanning... %d/%d"):format(st.scanned, st.total)
    end
    return ah, last, progress
end

-- ---------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------
local function versionText()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = getMeta and getMeta("ItemDB", "Version")
    return "LibItemDB " .. (v or "dev") .. "  |cff888888" .. lib:GetPriceScope() .. "|r"
end

local function menuItems(win, entry)
    local items = {}
    items[#items + 1] = {
        text    = "Enabled",
        checked = lib:IsPriceSourceEnabled(entry.id),
        onClick = function() lib:SetPriceSourceEnabled(entry.id, not lib:IsPriceSourceEnabled(entry.id)) end,
    }
    for _, sub in ipairs(SUB_TOGGLES[entry.id] or {}) do
        items[#items + 1] = {
            text    = sub.text,
            checked = lib:GetPriceSetting(sub.key) == true,
            onClick = function() lib:SetPriceSetting(sub.key, not lib:GetPriceSetting(sub.key)) end,
        }
    end
    if entry.precedence > 1 then
        items[#items + 1] = { text = "Move up",   onClick = function() lib:MovePriceSource(entry.id, -1) end }
    end
    if entry.precedence < entry.total then
        items[#items + 1] = { text = "Move down", onClick = function() lib:MovePriceSource(entry.id, 1) end }
    end
    win.menuItems = items
    return items
end

local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"

-- The list sits DIRECTLY on the TabGroup's content frame, exactly as VersionCheck's roster list
-- does -- that arrangement is known to draw in the client. The first cut put it on an intermediate
-- frame anchored inside the content (to leave a strip for the picker) and the list rendered
-- nothing in game, header included, while every offline assertion about its DATA passed. The
-- picker lives on the window's bottom bar now instead, where VersionCheck parks its buttons.
local function buildSourcesList(W, win, parent)
    win.list = W.RowList:New(parent, {
        rowCount = 8,
        columns  = {
            { key = "name",       header = "Source",     justify = "LEFT" },
            { key = "detected",   header = "Detected",   justify = "LEFT", width = 70 },
            { key = "enabled",    header = "Enabled",    justify = "LEFT", width = 60 },
            { key = "statistics", header = "Statistics", justify = "LEFT", width = 170 },
            { key = "age",        header = "Data age",   justify = "LEFT", width = 64 },
            { key = "precedence", header = "Order",      justify = "RIGHT", width = 44 },
        },
        actions = {
            {
                texture = function(entry) return CHECK, not entry.isEnabled end,
                tooltip = "Turn this source on or off",
                onClick = function(entry)
                    lib:SetPriceSourceEnabled(entry.id, not lib:IsPriceSourceEnabled(entry.id))
                end,
            },
            {
                texture = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up",
                tooltip = "Ask this source earlier",
                show    = function(entry) return entry.precedence > 1 end,
                onClick = function(entry) lib:MovePriceSource(entry.id, -1) end,
            },
            {
                texture = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
                tooltip = "Ask this source later",
                show    = function(entry) return entry.precedence < entry.total end,
                onClick = function(entry) lib:MovePriceSource(entry.id, 1) end,
            },
        },
        onRowClick = function(entry, _, _, button, rowFrame)
            button = button or (GetMouseButtonClicked and GetMouseButtonClicked())
            if button == "RightButton" and W.OpenMenu then
                W:OpenMenu(rowFrame or win.frame, menuItems(win, entry), { width = 240 })
            end
        end,
    })
    win.list:SetSort("precedence")
end

-- RowList has no Hide of its own; the Scan tab shares the content frame, so the list's pieces are
-- hidden by hand there and shown again by the next Refresh on the way back.
local function showList(win, shown)
    local list = win.list
    if list.header then
        if shown then list.header:Show() else list.header:Hide() end
    end
    if not shown then
        for _, row in ipairs(list.rows) do row:Hide() end
        if list.scrollbar then list.scrollbar:Hide() end
    end
end

-- The default-statistic picker, on ClearFrame's bottom bar immediately left of the info "i" --
-- the same anchor and 6 px gap ClearFrame's own SetSettingsButton uses, with the status bar
-- re-anchored to end at the label. `info` and `statusbg` are fields ClearFrame exposes on purpose.
local function buildStatisticPicker(W, win)
    -- Built fresh per open so the check mark follows the setting; kept on `win` so it is reachable
    -- offline without opening the menu.
    win.statItems = function()
        local items = {}
        local current = lib:GetPriceSetting("defaultStatistic")
        for _, s in ipairs(lib:GetPriceStatistics()) do
            items[#items + 1] = {
                text    = s.label,
                checked = s.id == current,
                onClick = function() lib:SetPriceSetting("defaultStatistic", s.id) end,
            }
        end
        items[#items + 1] = {
            text    = lib:GetPriceStatisticLabel("best"),
            checked = current == "best",
            onClick = function() lib:SetPriceSetting("defaultStatistic", "best") end,
        }
        return items
    end
    win.statBox = W:CreateDropdownBox(win.frame, {
        width    = 170,
        tipTitle = "Default statistic",
        tipBody  = "What a price lookup answers with when the asking addon does not name a statistic.",
        items    = win.statItems,
    })
    win.statBox:SetPoint("RIGHT", win.widget.info, "LEFT", -6, 0)
    win.statLabel = W:MakeLabel(win.frame, "Default statistic", { width = 100, height = 22, justify = "RIGHT" })
    win.statLabel:ClearAllPoints()
    win.statLabel:SetPoint("RIGHT", win.statBox, "LEFT", -4, 0)
    win.widget.statusbg:SetPoint("BOTTOMRIGHT", win.statLabel, "BOTTOMLEFT", -6, -2)
end

local function paintSources(win)
    win.list:SetData(lib:BuildPriceSourceRows(), true)
    win.statBox.label:SetText(lib:GetPriceStatisticLabel(lib:GetPriceSetting("defaultStatistic")))
end

local function paintScanStatus(win)
    if not (win.ahLabel and win.lastLabel and win.progressLabel) then return end
    local ah, last, progress = lib:BuildScanStatus()
    win.ahLabel:SetText(ah)
    win.lastLabel:SetText(last)
    win.progressLabel:SetText(progress or "")
    local st = lib:GetScanState()
    win.scanButton:SetDisabled(st.running or not st.auctionHouseOpen)
end

-- Bring the Scan tab's controls into line with the settings WITHOUT rebuilding them. A settings
-- change is usually raised by one of these very controls, from inside its own click handler, and
-- releasing an AceGUI widget while its handler is still running is not a thing to do to it.
local function syncScanControls(win)
    if not (win.autoBox and win.defaultDelayBox and win.delaySlider) then return end
    win.autoBox:SetValue(lib:GetPriceSetting("autoScan") == true)
    local delay = lib:GetPriceSetting("scanDelay")
    local useDefault = not (type(delay) == "number" and delay > 0)
    win.defaultDelayBox:SetValue(useDefault)
    win.delaySlider:SetValue(lib:GetEffectiveScanDelay())
    win.delaySlider:SetDisabled(useDefault)
    paintScanStatus(win)
end

local function buildScanTab(W, win, AceGUI)
    local tabs = win.tabs

    win.ahLabel = AceGUI:Create("Label")
    win.ahLabel:SetFullWidth(true)
    tabs:AddChild(win.ahLabel)

    win.lastLabel = AceGUI:Create("Label")
    win.lastLabel:SetFullWidth(true)
    tabs:AddChild(win.lastLabel)

    win.progressLabel = AceGUI:Create("Label")
    win.progressLabel:SetFullWidth(true)
    tabs:AddChild(win.progressLabel)

    win.scanButton = AceGUI:Create("Button")
    win.scanButton:SetText("Scan now")
    win.scanButton:SetWidth(140)
    win.scanButton:SetCallback("OnClick", function()
        local ok, reason = lib:StartFullScan(false)
        -- Repaint FIRST: it writes the progress line, and a refusal has to survive it.
        paintScanStatus(win)
        if not ok then
            win.progressLabel:SetText("Could not start a scan: " .. tostring(reason))
        end
    end)
    if W.AttachTooltip then
        W:AttachTooltip(win.scanButton.frame, "Scan now",
            "Scan the whole Auction House and refresh LibItemDB's own prices for this realm and "
            .. "faction. Needs the Auction House open; the server allows roughly one such scan every "
            .. "15 minutes per client.")
    end
    tabs:AddChild(win.scanButton)

    local auto = AceGUI:Create("CheckBox")
    auto:SetLabel("Auto-scan the Auction House on open")
    auto:SetFullWidth(true)
    auto:SetValue(lib:GetPriceSetting("autoScan") == true)
    auto:SetCallback("OnValueChanged", function(_, _, value) lib:SetPriceSetting("autoScan", value) end)
    if W.AttachTooltip then W:AttachTooltip(auto.frame, "Auto-scan", AUTO_SCAN_TIP) end
    tabs:AddChild(auto)
    win.autoBox = auto

    local delay = lib:GetPriceSetting("scanDelay")
    local useDefault = AceGUI:Create("CheckBox")
    useDefault:SetLabel("Use this client's default scan delay (1.5s on Classic Era, 3.0s elsewhere)")
    useDefault:SetFullWidth(true)
    useDefault:SetValue(not (type(delay) == "number" and delay > 0))
    tabs:AddChild(useDefault)
    win.defaultDelayBox = useDefault

    local slider = AceGUI:Create("Slider")
    slider:SetLabel("Scan delay (seconds)")
    slider:SetSliderValues(0.5, 10, 0.1)
    slider:SetValue(lib:GetEffectiveScanDelay())
    slider:SetWidth(260)
    slider:SetDisabled(useDefault:GetValue())
    slider:SetCallback("OnValueChanged", function(_, _, value) lib:SetPriceSetting("scanDelay", value) end)
    if W.AttachTooltip then W:AttachTooltip(slider.frame, "Scan delay", DELAY_TIP) end
    tabs:AddChild(slider)
    win.delaySlider = slider

    useDefault:SetCallback("OnValueChanged", function(_, _, value)
        if value then
            lib:SetPriceSetting("scanDelay", 0)
            slider:SetValue(lib:GetEffectiveScanDelay())
        else
            lib:SetPriceSetting("scanDelay", slider:GetValue())
        end
        slider:SetDisabled(value)
    end)

    paintScanStatus(win)
end

-- The Tooltip tab: one checkbox per line the reagent tooltip can draw, plus the icon size. These
-- are SmexyMats' own /sm toggles (its Data/Options/Options.lua), now that the tooltip is ours.
-- Every control writes straight through SetTooltipOption; the tab is rebuilt on each open, so it
-- always shows what is stored.
local TOOLTIP_TOGGLES = {
    { key = "enabled",   label = "Show LibItemDB's tooltip lines",
      tip = "Turns every line below on or off together." },
    { key = "header",    label = "\"ItemDB\" heading above the lines",
      tip = "Marks which lines on a tooltip are LibItemDB's, as the other addons' headings do." },
    { key = "expansion", label = "Expansion a material comes from",
      tip = "Classic or The Burning Crusade, on a crafting material's tooltip." },
    { key = "source",    label = "Where a material comes from",
      tip = "Mining, Herbalism, Tailoring, Drop, Vendor and so on." },
    { key = "usedBy",    label = "Professions that use a material",
      tip = "Every profession with a recipe that needs it." },
    { key = "itemID",    label = "Item ID on every item",
      tip = "The item's ID number. Some addons (AllTheThings) show one too." },
    { key = "icons",     label = "Show professions as icons",
      tip = "Off shows the profession names as words instead." },
    { key = "colorblind", label = "Colour-blind mode",
      tip = "Draw every label in colour #1 and every value in colour #2, chosen below." },
    { key = "altClick",  label = "Click an item: where to get it",
      tip = "Click any item (bags, bank, loot, chat links) with the combination chosen beside this "
          .. "to open the Where to get it window. Alt+Click unless you change it." },
}

-- WHICH click opens the Where to get it window (the `whereClick` option), in WoW's binding spelling.
-- LibAceGUIWidgets MINOR 38 ships "LAGW-ClickBinding" (TOGPM's contract e0f3923e3548): the player
-- performs the combination on it. It stores the same canonical string ParseClickBinding writes, with
-- the same buttons and the same "needs a modifier" rule, so a value saved by either control reads in
-- the other. An older LibAceGUIWidgets gets the dropdown below instead: every modifier combination
-- with the left or right button. A plain click is not offered by either: it is the game's own (use,
-- equip, pick up). Shift and Ctrl alone ARE allowed, with the warning in the tip, because the default
-- UI gives them jobs (link to chat, dressing room) that a player may not use.
local CLICK_CHOICES = {}
do
    local combos = { "ALT", "CTRL", "SHIFT", "ALT-CTRL", "ALT-SHIFT", "CTRL-SHIFT", "ALT-CTRL-SHIFT" }
    for _, button in ipairs({ "LeftButton", "RightButton" }) do
        for _, mods in ipairs(combos) do CLICK_CHOICES[#CLICK_CHOICES + 1] = mods .. "-" .. button end
    end
end
local CLICK_TIP = "Pick another if an addon you use already has this click (Gargul uses Alt+Click). "
    .. "Shift+Click links an item to chat and Ctrl+Click opens the dressing room, so avoid those two "
    .. "unless you never use them."

local function clickChooser(AceGUI, W)
    local c
    if W and W.IsClickBinding and AceGUI:GetWidgetVersion("LAGW-ClickBinding") then
        c = AceGUI:Create("LAGW-ClickBinding")
        c:SetDefault(lib:_GetTooltipDefault("whereClick"))
    else
        c = AceGUI:Create("Dropdown")
        local list = {}
        for _, b in ipairs(CLICK_CHOICES) do list[b] = lib:ClickBindingText(b) end
        c:SetList(list, CLICK_CHOICES)
    end
    c:SetLabel("Which click")
    c:SetValue(lib:GetTooltipOption("whereClick"))
    c:SetDisabled(not lib:GetTooltipOption("altClick"))
    c:SetCallback("OnValueChanged", function(_, _, value) lib:SetTooltipOption("whereClick", value) end)
    return c
end

-- Six hex digits from a colour picker's 0..1 channels, rounded rather than truncated so a colour
-- the picker hands back is stored as the same colour it will be read back as.
local function toHex(r, g, b)
    local function byte(v) return math.max(0, math.min(255, math.floor((tonumber(v) or 0) * 255 + 0.5))) end
    return ("%02x%02x%02x"):format(byte(r), byte(g), byte(b))
end

local function colorPicker(AceGUI, key, label)
    local p = AceGUI:Create("ColorPicker")
    p:SetLabel(label)
    local hex = lib:GetTooltipOption(key)
    p:SetColor(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
               tonumber(hex:sub(5, 6), 16) / 255, 1)
    p:SetDisabled(not lib:GetTooltipOption("colorblind"))
    -- BOTH events write. AceGUI fires OnValueConfirmed only from the picker's OPACITY callback on
    -- close (AceGUIWidget-ColorPicker.lua:39-40), and this picker has no opacity; whether the client
    -- still calls that callback then was not verified, so a colour saved only on confirm might be
    -- shown and never kept. OnValueChanged fires while the picker is open (:35).
    local function save(_, _, r, g, b) lib:SetTooltipOption(key, toHex(r, g, b)) end
    p:SetCallback("OnValueChanged", save)
    p:SetCallback("OnValueConfirmed", save)
    return p
end

-- TWO COLUMNS, because one did not fit. Nine full-width checkboxes, the slider and both pickers
-- stacked in the tab's List layout ran past the bottom of the 400-px window, with the pickers
-- drawn over the status bar (operator, in game, 2026-09-24). Flow puts the checkboxes in pairs and
-- the slider and pickers on one row: five checkbox rows and one slider row. The TabGroup goes back
-- to List for the other tabs in _PaintPriceWindow.
local function buildTooltipTab(win, AceGUI)
    local tabs = win.tabs
    win.tooltipBoxes = {}
    local slider = AceGUI:Create("Slider")
    local pick1 = colorPicker(AceGUI, "color1", "Colour #1 (labels)")
    local pick2 = colorPicker(AceGUI, "color2", "Colour #2 (values)")
    pick1:SetRelativeWidth(0.3)
    pick2:SetRelativeWidth(0.3)
    local W = Widgets()
    local click = clickChooser(AceGUI, W)
    click:SetRelativeWidth(0.5)
    if W.AttachTooltip then W:AttachTooltip(click.frame, "Which click", CLICK_TIP) end
    for _, t in ipairs(TOOLTIP_TOGGLES) do
        local box = AceGUI:Create("CheckBox")
        box:SetLabel(t.label)
        box:SetRelativeWidth(0.5)
        box:SetValue(lib:GetTooltipOption(t.key) and true or false)
        box:SetCallback("OnValueChanged", function(_, _, value)
            lib:SetTooltipOption(t.key, value)
            if t.key == "icons" then slider:SetDisabled(not value) end
            if t.key == "colorblind" then
                pick1:SetDisabled(not value)
                pick2:SetDisabled(not value)
            end
            if t.key == "altClick" then click:SetDisabled(not value) end
        end)
        if W.AttachTooltip then W:AttachTooltip(box.frame, t.label, t.tip) end
        tabs:AddChild(box)
        win.tooltipBoxes[t.key] = box
        -- The click chooser sits beside its own switch, filling that row's empty right half.
        if t.key == "altClick" then tabs:AddChild(click) end
    end
    win.clickChooser = click
    slider:SetLabel("Icon size")
    slider:SetSliderValues(8, 64, 1)
    slider:SetValue(lib:GetTooltipOption("iconSize"))
    slider:SetRelativeWidth(0.4)
    slider:SetDisabled(not lib:GetTooltipOption("icons"))
    slider:SetCallback("OnValueChanged", function(_, _, value) lib:SetTooltipOption("iconSize", value) end)
    tabs:AddChild(slider)
    win.iconSlider = slider
    tabs:AddChild(pick1)
    tabs:AddChild(pick2)
    win.colorPickers = { pick1, pick2 }
end

-- BUILD the selected tab, on open and on a tab switch. Sources is the RowList, shown or hidden;
-- Scan and Tooltip are AceGUI children that are released and rebuilt, the ordinary TabGroup pattern.
function lib:_PaintPriceWindow()
    local win = self.priceWindow
    if not (win and win.tabs) then return false end
    local W = Widgets()
    local AceGUI = LibStub("AceGUI-3.0")
    win.tabs:ReleaseChildren()
    win.ahLabel, win.lastLabel, win.progressLabel, win.scanButton = nil, nil, nil, nil
    win.autoBox, win.defaultDelayBox, win.delaySlider = nil, nil, nil
    win.tooltipBoxes, win.iconSlider, win.colorPickers, win.clickChooser = nil, nil, nil, nil
    win.tabs:SetLayout(win.tab == "tooltip" and "Flow" or "List")
    if win.tab == "scan" then
        showList(win, false)
        buildScanTab(W, win, AceGUI)
    elseif win.tab == "tooltip" then
        showList(win, false)
        buildTooltipTab(win, AceGUI)
    else
        showList(win, true)
        paintSources(win)
        win.list:Refresh()
    end
    win.widget:SetStatusText(versionText())
    return true
end

-- REFRESH the selected tab in place, on a settings change or a scan finishing: the rows are
-- re-read, the controls are re-synced, nothing is released.
function lib:_RefreshPriceWindow()
    local win = self.priceWindow
    if not (win and win.tabs) then return false end
    if win.tab == "scan" then
        syncScanControls(win)
    elseif win.tab ~= "tooltip" then
        -- The Tooltip tab has nothing a price event can change, and repainting the sources list
        -- while it is hidden would draw rows over the tab's controls.
        paintSources(win)
    end
    return true
end

function lib:CreatePriceWindow(W)
    local AceGUI = LibStub("AceGUI-3.0")
    local win = { tab = "sources" }

    ---@diagnostic disable-next-line: param-type-mismatch
    local frame = AceGUI:Create("ClearFrame")
    frame:SetTitle("LibItemDB")
    frame:SetStatusText(versionText())
    frame:SetInfoTooltip(HELP)
    frame:SetLayout("Fill")
    local saved = self:_PriceDB().window
    if W.PersistWindow then
        W:PersistWindow(frame, saved, { width = 640, height = 400, minWidth = 560, minHeight = 320 })
    else
        frame:SetStatusTable(saved)
    end
    win.widget = frame
    ---@diagnostic disable-next-line: invisible
    win.frame  = frame.frame

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("List")
    -- THE LINE THE FIRST IN-GAME OPEN WAS MISSING. A TabGroup re-sizes ITSELF to its children
    -- after every layout (`LayoutFinished` -> `SetHeight(children + 23 + borderoffset)`), and the
    -- Sources tab has NO AceGUI children -- the RowList is a raw frame on the content -- so the
    -- group shrank to 53 px, its content frame to an explicit height of 0, and RowList, which
    -- sizes its visible rows from `parent:GetHeight()`, showed nothing. VersionCheck never meets
    -- this because its tab layout is "Fill", which never shrinks; the Scan tab here needs "List"
    -- for its stacked controls. `noAutoHeight` is the widget's own opt-out, read in
    -- `LayoutFinished`: the group keeps the size the window's Fill layout gave it on both tabs.
    tabs.noAutoHeight = true
    tabs:SetTabs({ { text = "Sources", value = "sources" }, { text = "Scan", value = "scan" },
                   { text = "Tooltip", value = "tooltip" } })
    if W.BrandTabGroup then W:BrandTabGroup(tabs) end
    tabs:SetCallback("OnGroupSelected", function(_, _, value)
        win.tab = value
        lib:_PaintPriceWindow()
    end)
    frame:AddChild(tabs)
    win.tabs = tabs

    buildSourcesList(W, win, tabs.content or win.frame)
    buildStatisticPicker(W, win)

    -- Repaint on the library's own events, so a change made through the API (or by a scan
    -- finishing) shows without reopening the window. `win` is the callback owner.
    if self.RegisterCallback then
        self.RegisterCallback(win, "LibItemDB_PriceSettingsChanged", function() lib:_RefreshPriceWindow() end)
        self.RegisterCallback(win, "LibItemDB_ScanComplete",         function() lib:_RefreshPriceWindow() end)
        self.RegisterCallback(win, "LibItemDB_AuctionHouse",         function() paintScanStatus(win) end)
        self.RegisterCallback(win, "LibItemDB_ScanProgress",         function() paintScanStatus(win) end)
    end

    self.priceWindow = win
    tabs:SelectTab("sources")
    return win
end

--- Open the window if it is closed, close it if it is open. Built on first use. Returns the
--- window table, or nil (with a chat line) when LibAceGUIWidgets is not installed.
function lib:TogglePriceWindow()
    local W = Widgets()
    if not (W and W.RowList) then
        self:_PricePrint("The price window needs LibAceGUIWidgets with RowList.")
        return nil
    end
    local win = self.priceWindow
    if win and win.frame and win.frame:IsShown() then
        win.frame:Hide()
        return win
    end
    if not win then win = self:CreatePriceWindow(W) end
    win.frame:Show()
    self:_PaintPriceWindow()
    -- RowList sizes its visible pool from its parent's height, and an anchored frame's height
    -- reads 0 until the client's next layout pass -- which has not happened yet for a window
    -- built and shown in this same execution. Refresh once more on the next frame, when the
    -- rects exist; an in-place recompute, so it costs nothing when the first paint was right.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if win.frame:IsShown() and win.tab == "sources" then win.list:Refresh() end
        end)
    end
    return win
end

--- Open the window (never closes it). For a consumer's "configure prices" button.
function lib:OpenPriceWindow()
    local win = self.priceWindow
    if win and win.frame and win.frame:IsShown() then return win end
    return self:TogglePriceWindow()
end

-- ---------------------------------------------------------------------------
-- Slash command
-- ---------------------------------------------------------------------------
--   /itemdb              toggle the window
--   /itemdb scan         start a full scan (the AH must be open)
--   /itemdb price <item> [statistic]   print what the ladder answers for an item id or link
local function slash(msg)
    msg = tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if not cmd or cmd == "" then
        lib:TogglePriceWindow()
        return
    end
    cmd = cmd:lower()
    if cmd == "scan" then
        local ok, reason = lib:StartFullScan(false)
        if not ok then lib:_PricePrint("Scan not started: " .. tostring(reason)) end
    elseif cmd == "where" and lib.WhereSearch then
        -- An id or a link opens that item's places; anything else is a name to search for, and
        -- nothing opens the window empty, ready for its search box.
        if tonumber(rest) or rest:find("item:%d+") then
            lib:OpenWhereWindow(rest)
        else
            lib:WhereSearch(rest)
        end
    elseif cmd == "price" then
        -- An item LINK carries the item's name, spaces included, so the argument cannot be split
        -- on whitespace: take the id out of the link and the statistic from after its closing
        -- `|r`. Otherwise the last word is the statistic if it names one, and what is left is a
        -- bare id or an item NAME -- this is a name database; refusing "Roasted Quail" would be
        -- absurd. Suffixed names resolve to their base item, which is what is priced.
        local itemID, stat
        if rest:find("|Hitem:", 1, true) then
            itemID = tonumber(rest:match("|Hitem:(%d+)"))
            stat   = rest:match("|r%s+(%S+)%s*$")
        else
            local head, last = rest:match("^(.-)%s+(%S+)$")
            if last and lib:GetPriceStatisticLabel(last) ~= last then
                rest, stat = head, last
            end
            itemID = tonumber(rest:match("^%d+$"))
            if not itemID and rest ~= "" then
                local found = lib:ResolveName(rest)
                itemID = found and found.id
                if not itemID then
                    lib:_PricePrint(("No item named %q."):format(rest))
                    return
                end
            end
        end
        if not itemID then
            -- No `|` in this string: the chat frame reads `|h` as a hyperlink escape and swallows it.
            lib:_PricePrint("Usage: /itemdb price <itemID, link or name> [minBuyout / market / historical / best]")
            return
        end
        local price, info = lib:GetPrice(itemID, (stat and stat ~= "") and stat or nil)
        if not price then
            lib:_PricePrint(("No price for item %d."):format(itemID))
            return
        end
        lib:_PricePrint(("Item %d: %s (%s, %s, %s)"):format(itemID, lib:FormatMoney(price),
            info.sourceName, lib:GetPriceStatisticLabel(info.statistic),
            info.age and (lib:FormatPriceAge(info.age) .. " old") or "age unknown"))
    else
        lib:_PricePrint("Commands: /itemdb -- /itemdb scan -- /itemdb price <itemID, link or name> [statistic]"
            .. " -- /itemdb where [itemID, link or name]")
    end
end
lib._PriceSlash = slash

if SlashCmdList then
    _G.SLASH_ITEMDB1    = "/itemdb"
    _G.SLASH_LIBITEMDB1 = "/libitemdb"
    SlashCmdList.ITEMDB    = slash
    SlashCmdList.LIBITEMDB = slash
end
