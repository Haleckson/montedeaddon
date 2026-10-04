-- Karakter Anıları / Character Memoir - Anı defteri penceresi

local ADDON, ns = ...
local L = ns.L
local FONT = ns.FONT
local MAX_SHOWN = 400

local frame, titleText, statsText, bodyText, content, scroll, bookBtn, exportBtn, libraryBtn
local filterButtons = {}
local currentFilter -- nil = hepsi / all

----------------------------------------------------------------------
-- Metin üretimi
----------------------------------------------------------------------
local function FormatDay(t)
    local d = date("*t", t)
    return string.format("%d %s %d", d.day, L.MONTHS[d.month], d.year)
end
ns.FormatDay = FormatDay

local function BuildStats()
    local db = ns.db
    local zones = 0
    for _ in pairs(db.zones) do zones = zones + 1 end
    local bosses = 0
    for _ in pairs(db.bosses) do bosses = bosses + 1 end

    local worstZone, worstCount = nil, 0
    for z, c in pairs(db.deaths.byZone) do
        if c > worstCount then worstZone, worstCount = z, c end
    end

    local line2 = L.UI_DEATHS:format(db.deaths.total)
    if worstZone then line2 = line2 .. L.UI_DEADLIEST:format(worstZone, worstCount) end
    -- 3. satır: defter açılışı ve oyun süresi (baştaki "  •  " ayıracını atarak)
    local line3 = {}
    local function strip(t) return (t:gsub("^%s*\226\128\162%s*", "")) end
    if db.started then line3[#line3 + 1] = strip(L.UI_STARTED:format(FormatDay(db.started))) end
    local played = ns.ActiveNow and ns.ActiveNow() or 0
    if played >= 60 then line3[#line3 + 1] = strip(L.UI_PLAYED:format(ns.FormatDuration(played))) end
    if #line3 > 0 then line2 = line2 .. "\n|cffaaaaaa" .. table.concat(line3, "  \226\128\162  ") .. "|r" end

    return L.UI_STATS:format(#db.events, zones, db.quests, bosses) .. "\n" .. line2
end

local function BuildBody()
    local events = ns.db.events
    local out, lastDay, shown, lastZone = {}, nil, 0, nil

    for i = #events, 1, -1 do -- en yeni en üstte / newest first
        local e = events[i]
        if not currentFilter or e.k == currentFilter then
            local day = FormatDay(e.t)
            if day ~= lastDay then
                out[#out + 1] = (lastDay and "\n" or "") .. "|cffffd100" .. day .. "|r"
                lastDay = day
                lastZone = nil
            end
            -- Bölge adını sadece değiştiğinde göster (her satırda tekrar edip satırları kaydırmasın)
            local where = ""
            if e.z and e.z ~= lastZone then where = "  |cff777777— " .. e.z .. "|r" end
            lastZone = e.z or lastZone
            out[#out + 1] = string.format("   |cff888888%s|r  |c%s%s|r  %s%s",
                (e.d and e.d.past) and "--:--" or date("%H:%M", e.t), ns.TypeColor(e.k), ns.TypeLabel(e.k), ns.Describe(e), where)
            shown = shown + 1
            if shown >= MAX_SHOWN then
                out[#out + 1] = "\n|cff888888" .. L.UI_MORE .. "|r"
                break
            end
        end
    end

    if shown == 0 then
        out[1] = "|cff888888" .. L.UI_EMPTY .. "|r"
    end
    return table.concat(out, "\n")
end

local function SetButtonText(b, text)
    ns.SetButtonLabel(b, text)
end

-- Dil değişince tüm sabit yazıları güncelle
local function UpdateTexts()
    titleText:SetText(L.UI_TITLE:format("|cffffd100" .. (UnitName("player") or "") .. "|r"))
    SetButtonText(filterButtons.all, L.UI_ALL)
    for _, key in ipairs(ns.FILTER_ORDER) do
        SetButtonText(filterButtons[key], ns.TypeLabel(key))
    end
    SetButtonText(bookBtn, L.BTN_READ_BOOK)
    SetButtonText(exportBtn, L.BTN_EXPORT)
    SetButtonText(libraryBtn, L.BTN_LIBRARY)
end

local function Refresh()
    if not frame or not ns.db then return end
    statsText:SetText(BuildStats())
    bodyText:SetText(BuildBody())
    content:SetHeight(bodyText:GetStringHeight() + 12)
    scroll:SetVerticalScroll(0)
    for key, b in pairs(filterButtons) do
        ns.SetButtonActive(b, key == (currentFilter or "all"))
    end
end

----------------------------------------------------------------------
-- Pencere
----------------------------------------------------------------------
local function MakeFilterButton(key, index)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(88, 20)
    local col = (index - 1) % 6
    local row = math.floor((index - 1) / 6)
    b:SetPoint("TOPLEFT", 14 + col * 90, -86 - row * 22)
    b:SetScript("OnClick", function()
        currentFilter = (key ~= "all") and key or nil
        Refresh()
    end)
    filterButtons[key] = b
end

local function CreateUI()
    frame = CreateFrame("Frame", "KarakterAnilariFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "KarakterAnilariFrame") -- ESC ile kapanır

    titleText = frame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT, 14, "")
    titleText:SetPoint("TOP", 0, -5)

    statsText = frame:CreateFontString(nil, "OVERLAY")
    statsText:SetFont(FONT, 12, "")
    statsText:SetPoint("TOPLEFT", 16, -32)
    statsText:SetWidth(528)
    statsText:SetJustifyH("LEFT")
    statsText:SetSpacing(3)

    MakeFilterButton("all", 1)
    for i, key in ipairs(ns.FILTER_ORDER) do
        MakeFilterButton(key, i + 1)
    end

    scroll = CreateFrame("ScrollFrame", "KarakterAnilariScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -136)
    scroll:SetPoint("BOTTOMRIGHT", -32, 40)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(510, 10)
    scroll:SetScrollChild(content)

    bodyText = content:CreateFontString(nil, "OVERLAY")
    bodyText:SetFont(FONT, 13, "")
    bodyText:SetPoint("TOPLEFT", 2, -4)
    bodyText:SetWidth(504)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetJustifyV("TOP")
    bodyText:SetSpacing(3)

    bookBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    bookBtn:SetSize(124, 22)
    bookBtn:SetPoint("BOTTOM", frame, "BOTTOM", -130, 10)
    bookBtn:SetScript("OnClick", function() ns.OpenBook() end)

    exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exportBtn:SetSize(124, 22)
    exportBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    exportBtn:SetScript("OnClick", function() ns.OpenExport("discord") end)

    libraryBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    libraryBtn:SetSize(124, 22)
    libraryBtn:SetPoint("BOTTOM", frame, "BOTTOM", 130, 10)
    libraryBtn:SetScript("OnClick", function() if ns.ToggleLibrary then ns.ToggleLibrary() end end)

    UpdateTexts()
    frame:SetScript("OnShow", Refresh)
end

function ns.ToggleUI()
    if not frame then CreateUI() end
    frame:SetShown(not frame:IsShown())
end

function ns.OnNewMemory()
    if frame and frame:IsShown() then Refresh() end
end

ns.OnLanguageChanged(function()
    if not frame then return end
    UpdateTexts()
    if frame:IsShown() then Refresh() end
end)

-- Minimap'teki addon menüsü (Retail) için giriş noktası
function KarakterAnilari_OnAddonCompartmentClick()
    ns.ToggleUI()
end
