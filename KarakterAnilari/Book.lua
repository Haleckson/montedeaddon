-- Karakter Anıları / Character Memoir - Kitap okuyucu ve dışa aktarma

local ADDON, ns = ...
local L = ns.L
local FONT = ns.FONT
local BOOK_FONT = ns.BOOK_FONT

----------------------------------------------------------------------
-- Yardımcılar
----------------------------------------------------------------------
local function DayLabel(t)
    local d = date("*t", t)
    return d.day .. " " .. L.MONTHS[d.month]
end

local function MonthLabel(t)
    local d = date("*t", t)
    return L.MONTHS[d.month] .. " " .. d.year
end

local function FullDate(t)
    local d = date("*t", t)
    return d.day .. " " .. L.MONTHS[d.month] .. " " .. d.year
end

-- Renk kodlarını ve linkleri temizler: "|cff..|Hitem:..|h[Kılıç]|h|r" -> "[Kılıç]"
local function Plain(s)
    s = s:gsub("|H.-|h(.-)|h", "%1")
    s = s:gsub("|cn[^:]*:", "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    s = s:gsub("|T.-|t", "")
    return s
end

ns.PlainText = Plain

----------------------------------------------------------------------
-- Anı -> anlatı cümlesi (3. şahıs), seçili dilde
----------------------------------------------------------------------
local function PlayerName() return UnitName("player") or "?" end

local function Narrate(e)
    local d, k = e.d, e.k
    local seed = e.t or 0
    if k == "start" then return nil end
    if k == "note" then return L.NAR_note:format((d and d.text) or e.x or "") end
    if not d then -- tanınmayan eski kayıt: olduğu gibi, cümle sonu ekleyerek
        local x = e.x or ""
        if x ~= "" and not x:find("[%.!%?]$") then x = x .. "." end
        return x
    end

    if k == "level" then
        return L.NAR_level:format(d.level)
    elseif k == "zone" then
        return L.NAR_zone:format(d.zone)
    elseif k == "achievement" then
        return L.NAR_achievement:format(d.name)
    elseif k == "loot" then
        local q = math.max(0, math.min(5, d.q or 4))
        return L.NAR_loot:format(L["QUALITY_" .. q], d.link)
    elseif k == "mount" then
        return L.NAR_mount:format(d.name)
    elseif k == "boss" then
        return ns.Voice("BOSS", seed, { boss = d.name, name = PlayerName(),
            diffnote = d.diff and (" (" .. d.diff .. ")") or "" })
    elseif k == "death" then
        local vars = { zone = d.zone, total = d.total, name = PlayerName() }
        if d.kind == "first" then return ns.Voice("DEATH_FIRST", seed, vars) end
        if d.kind == "milestone" then return ns.Voice("DEATH_MILESTONE", seed, vars) end
        return ns.Voice("DEATH_ZONE", seed, vars)
    elseif k == "quest" then
        if d.title then return L.NAR_quest_title:format(d.count, d.title) end
        return L.NAR_quest:format(d.count)
    elseif k == "title" then
        return ns.Fill(L.NAR_title, { title = ns.TitleText(d.id) or "?", name = PlayerName() })
    end
    return e.x
end

local function SafeNarrate(e)
    local ok, s, tag = pcall(Narrate, e)
    if ok then return s, tag end
    return e.x
end

-- "A, B ve C" / "A, B and C"
local function JoinList(items)
    if #items == 1 then return items[1] end
    return table.concat(items, ", ", 1, #items - 1) .. L.LIST_AND .. items[#items]
end

-- Bir anının kitaptaki rolü: gruplanacak bir şey mi, yoksa tek başına bir cümle mi?
local function Classify(e, opts)
    local d = e.d
    if e.k == "start" then return nil end
    if e.k == "note" and opts and opts.noNotes then return nil end
    if d and e.k == "zone" and d.zone then return "zone", d.zone end
    if d and e.k == "level" and d.level then return "level", d end
    if e.k == "photo" then return "photo" end
    if d and e.k == "loot" and (d.q or 4) < ns.LOOT_NOTIFY_MIN then return "minor" end
    local s = SafeNarrate(e)
    if s and s ~= "" then return "text", s end
end

-- Bölüm anahtarı: aya göre (varsayılan) ya da 10'luk seviye aralığına göre
local function ChapterKey(e, byLevel)
    if e.d and e.d.past then
        return "PAST", function(n) return L.BOOK_CHAPTER_PAST:format(n) end
    end
    if byLevel then
        local lv = (e.k == "level" and e.d and e.d.level) or e.l or 1
        local lo = math.floor(lv / 10) * 10
        local hi = lo + 9
        if lo < 1 then lo = 1 end
        return "L" .. lo, function(n) return L.BOOK_CHAPTER_LEVEL:format(n, lo, hi) end
    end
    local month = MonthLabel(e.t)
    return month, function(n) return L.BOOK_CHAPTER:format(n, month) end
end

local ZONES, LEVELS = {}, {} -- gün içi grup yer tutucuları

-- Kitabı bloklar halinde üretir: title, subtitle, chapter, para
-- Ay sonu özeti: "Eylül, Noras için zorlu bir aydı: 4 seviye atladı, 7 kez öldü..."
local function MonthSummary(db, monthKey, monthName, name)
    local m = db.monthly and db.monthly[monthKey]
    if not m then return nil end
    local parts = {}
    local function count(n, one, many)
        if n == 1 then parts[#parts + 1] = L[one]
        elseif n > 1 then parts[#parts + 1] = ns.Fill(L[many], { n = n }) end
    end
    count(m.levels or 0, "SUM_levels_one", "SUM_levels")
    count(m.deaths or 0, "SUM_deaths_one", "SUM_deaths")
    count(m.quests or 0, "SUM_quests_one", "SUM_quests")
    local topZone, topTime = nil, 0
    for z, t in pairs(m.zoneTime or {}) do
        if t > topTime then topZone, topTime = z, t end
    end
    if topZone and topTime >= 600 then parts[#parts + 1] = ns.Fill(L.SUM_zone, { zone = topZone }) end
    if #parts == 0 then return nil end
    local mood = ((m.deaths or 0) >= 5 and L.MOOD_hard) or ((m.levels or 0) >= 5 and L.MOOD_busy) or L.MOOD_calm
    return ns.Fill(L.SUM_TEXT, { month = monthName, name = name, mood = mood, parts = JoinList(parts) })
end

function ns.BuildBookBlocks(opts)
    local db = ns.db
    ns.ResetVoiceRotation()
    local name = UnitName("player") or "?"
    local blocks = {}
    local function add(kind, text, day)
        blocks[#blocks + 1] = { kind = kind, text = text, day = day }
    end

    add("title", name)
    add("subtitle", ns.Voice("SUBTITLE", 0, { name = name }) or L.BOOK_SUBTITLE)
    -- Kapak: en prestijli unvan ve oyuncunun kendi sözü
    local titles = ns.EarnedTitles and ns.EarnedTitles() or {}
    if titles[1] then add("honor", ns.TitleText(titles[1])) end
    if db.motto and db.motto ~= "" then add("motto", "“" .. db.motto .. "”") end

    -- Önsöz / Prologue
    local start
    for _, e in ipairs(db.events) do
        if e.k == "start" then start = e break end
    end
    add("chapter", L.BOOK_PROLOGUE)
    local hasPast = false
    for _, e in ipairs(db.events) do
        if e.d and e.d.past then hasPast = true break end
    end
    if start and start.d then
        local sd = start.d
        -- Geçmişi doldurulmuş karakter: hikâye defterden önce başlamıştı
        local text = ns.Voice(hasPast and "PROLOGUE_PAST" or "PROLOGUE", start.t, {
            date = FullDate(start.t), zone = sd.zone or L.UNKNOWN_PLACE,
            name = name, level = sd.level or 1, raceclass = ns.RaceClass(sd) })
        -- Sınıfa özgü bir cümle (ör. "Işık onun yolunu aydınlatıyordu.")
        local intro = ns.ClassVoice("INTRO", start.t, { name = name })
        if intro then text = text .. " " .. intro end
        add("para", text)
    else
        add("para", L.BOOK_PROLOGUE_FALLBACK)
    end

    -- Bölümler: her bölümde her gün bir paragraf. Aynı gündeki keşifler, seviyeler,
    -- fotoğraflar ve sıradan ekipmanlar tek cümlede toplanır.
    local byLevel = ns.settings and ns.settings.chapters == "level"
    local function NewDay() return { parts = {}, zones = {}, levels = {}, photos = 0, minor = 0, seed = 0 } end
    local cur, curKey, chapterNo = NewDay(), nil, 0
    local monthKey, monthNum -- açık olan ay bölümü (özet için)
    local function addSummary()
        if monthKey then
            local s = MonthSummary(db, monthKey, L.MONTHS[monthNum], name)
            if s then add("summary", s) end
        end
        monthKey = nil
    end

    local function flush()
        if cur.label then
            local out = {}
            for _, p in ipairs(cur.parts) do
                if p == ZONES then
                    out[#out + 1] = (#cur.zones == 1)
                        and ns.Voice("ZONE", cur.seed, { zone = cur.zones[1], name = name })
                        or ns.Voice("ZONES", cur.seed, { zones = JoinList(cur.zones), name = name })
                elseif p == LEVELS then
                    local lv = cur.levels
                    local top = lv[#lv].level
                    if #lv == 1 and lv[1].dur then
                        out[#out + 1] = ns.Voice("LEVEL_DUR", cur.seed,
                            { level = top, dur = ns.FormatDuration(lv[1].dur), name = name })
                    elseif #lv == 1 then
                        out[#out + 1] = ns.Voice("LEVEL", cur.seed, { level = top, name = name })
                    else
                        out[#out + 1] = ns.Voice("LEVELS", cur.seed, { count = #lv, level = top, name = name })
                    end
                    -- 10, 20, 30... seviyelerde sınıfa özgü bir dokunuş
                    local milestone
                    for _, x in ipairs(lv) do
                        if x.level and x.level % 10 == 0 then milestone = x.level end
                    end
                    if milestone then
                        local m = ns.ClassVoice("MILESTONE", cur.seed + milestone, { level = milestone, name = name })
                        if m then out[#out + 1] = m end
                    end
                else
                    out[#out + 1] = p
                end
            end
            if cur.photos == 1 then out[#out + 1] = L.NAR_photo_one
            elseif cur.photos > 1 then out[#out + 1] = L.NAR_photos:format(cur.photos) end
            if cur.minor == 1 then out[#out + 1] = L.NAR_loot_minor_one
            elseif cur.minor > 1 then out[#out + 1] = L.NAR_loot_minor:format(cur.minor) end
            if #out > 0 then add("para", table.concat(out, " "), cur.label) end
        end
        cur = NewDay()
    end

    for _, e in ipairs(db.events) do
        local kind, value = Classify(e, opts)
        if kind then
            local key, label = ChapterKey(e, byLevel)
            if key ~= curKey then
                flush()
                addSummary()
                chapterNo = chapterNo + 1
                curKey = key
                add("chapter", label(chapterNo))
                if not byLevel and not (e.d and e.d.past) then
                    monthKey, monthNum = date("%Y-%m", e.t), date("*t", e.t).month
                end
            end
            local dl = DayLabel(e.t)
            if dl ~= cur.label then
                flush()
                cur.label = dl
                cur.seed = e.t or 0
            end
            if kind == "zone" then
                if #cur.zones == 0 then cur.parts[#cur.parts + 1] = ZONES end
                cur.zones[#cur.zones + 1] = value
            elseif kind == "level" then
                if #cur.levels == 0 then cur.parts[#cur.parts + 1] = LEVELS end
                cur.levels[#cur.levels + 1] = value
            elseif kind == "photo" then
                cur.photos = cur.photos + 1
            elseif kind == "minor" then
                cur.minor = cur.minor + 1
            else
                cur.parts[#cur.parts + 1] = value
            end
        end
    end
    flush()
    addSummary()

    -- Sonsöz / Epilogue
    local zones, bosses = 0, 0
    for _ in pairs(db.zones) do zones = zones + 1 end
    for _ in pairs(db.bosses) do bosses = bosses + 1 end
    local deaths = db.deaths.total
    local vars = { zones = zones, quests = db.quests, bosses = bosses, deaths = deaths, name = name }
    local deathText = (deaths == 0) and ns.Voice("NO_DEATHS", 0, vars) or ns.Voice("DEATHS", 0, vars)
    add("chapter", L.BOOK_EPILOGUE)
    add("para", ns.Voice("EPILOGUE", 0, vars) .. " " .. deathText .. " " .. ns.Voice("END", 0, vars))
    if #titles > 0 then
        local names = {}
        for i, id in ipairs(titles) do names[i] = ns.TitleText(id) end
        add("para", ns.Fill(L.BOOK_TITLES, { titles = JoinList(names) }))
    end

    return blocks
end

----------------------------------------------------------------------
-- Dışa aktarma metni
----------------------------------------------------------------------
-- JSON: Discord botu ve web görüntüleyici için makine-okunur biçim
local function JStr(s)
    s = tostring(s or ""):gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
        elseif c == "\n" then return "\\n" elseif c == "\t" then return "\\t" end
        return string.format("\\u%04x", c:byte())
    end)
    return '"' .. s .. '"'
end

function ns.RenderJSON(blocks, meta)
    blocks = blocks or ns.BuildBookBlocks()
    meta = meta or {}
    local _, classFile = UnitClass("player")
    local _, raceFile = UnitRace("player")
    local titles = {}
    for _, id in ipairs(ns.EarnedTitles and ns.EarnedTitles() or {}) do titles[#titles + 1] = JStr(ns.TitleText(id)) end
    local out = {}
    for _, b in ipairs(blocks) do
        local item = '{"k":' .. JStr(b.kind)
        if b.day then item = item .. ',"d":' .. JStr(b.day) end
        out[#out + 1] = item .. ',"t":' .. JStr(Plain(b.text)) .. "}"
    end
    return "{" .. table.concat({
        '"format":"fallenmemoir"', '"version":1',
        '"lang":' .. JStr(ns.lang),
        '"name":' .. JStr(meta.name or UnitName("player")),
        '"realm":' .. JStr(meta.realm or (GetRealmName and GetRealmName()) or ""),
        '"level":' .. tostring(meta.level or UnitLevel("player") or 0),
        '"race":' .. JStr(meta.race or UnitRace("player")),
        '"raceFile":' .. JStr(meta.raceFile or raceFile),
        '"class":' .. JStr(meta.class or UnitClass("player")),
        '"classFile":' .. JStr(meta.classFile or classFile),
        '"titles":[' .. table.concat(titles, ",") .. "]",
        '"motto":' .. JStr(ns.db and ns.db.motto or ""),
        '"blocks":[' .. table.concat(out, ",") .. "]",
    }, ",") .. "}"
end

function ns.RenderBook(fmt, blocks)
    local out = {}
    if fmt == "json" then return ns.RenderJSON(blocks) end
    for _, b in ipairs(blocks or ns.BuildBookBlocks()) do
        local t = Plain(b.text)
        if fmt == "discord" then
            if b.kind == "title" then out[#out + 1] = "# " .. t
            elseif b.kind == "subtitle" then out[#out + 1] = "*" .. t .. "*"
            elseif b.kind == "honor" then out[#out + 1] = "**~ " .. t .. " ~**"
            elseif b.kind == "motto" then out[#out + 1] = "> " .. t
            elseif b.kind == "summary" then out[#out + 1] = "*" .. t .. "*"
            elseif b.kind == "chapter" then out[#out + 1] = "## " .. t
            elseif b.day then out[#out + 1] = "**" .. b.day .. "** — " .. t
            else out[#out + 1] = t end
        else
            if b.kind == "title" then out[#out + 1] = "=== " .. t .. " ==="
            elseif b.kind == "subtitle" then out[#out + 1] = t
            elseif b.kind == "honor" then out[#out + 1] = "~ " .. t .. " ~"
            elseif b.kind == "chapter" then out[#out + 1] = "--- " .. t .. " ---"
            elseif b.day then out[#out + 1] = b.day .. " — " .. t
            else out[#out + 1] = t end
        end
    end
    return table.concat(out, "\n\n")
end

----------------------------------------------------------------------
-- Ortak buton yardımcısı
----------------------------------------------------------------------
local function SetButtonText(b, text)
    ns.SetButtonLabel(b, text)
end

----------------------------------------------------------------------
-- Kitap okuyucu (parşömen sayfalar)
----------------------------------------------------------------------
local INK      = { 0.23, 0.15, 0.07 }
local C_TITLE  = "|cff4a2808"
local C_CHAP   = "|cff7a1f1f"
local C_DAY    = "|cff6b4a1f"
local C_HONOR  = "|cff8a5a12"
local C_MOTTO  = "|cff5a4632"
local C_SUM    = "|cff5a4632"
local ORNAMENT = "◆" -- DejaVu Serif'te bulunan bir süs

-- Sesler: oyunun kendi kitap sesleri (yoksa sessizce atlanır)
local function Sound(name, fallback)
    if not PlaySound then return end
    local id = (SOUNDKIT and SOUNDKIT[name]) or fallback
    if id then pcall(PlaySound, id) end
end

-- Kapakta sınıf ikonu (oyunun sınıf ikonu dokusundan)
local function ClassIconCoords(classFile)
    return classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
end
local PAGE_W, PAGE_H = 390, 430

-- Oyunun parlak kalite renkleri parşömen zeminde soluk kalıyor; kitapta koyu tonlar
local INK_BY_HEX = {
    ["9d9d9d"] = "5e5e5e", ["ffffff"] = "3b2612", ["1eff00"] = "1d6b00", ["0070dd"] = "0b4f9e",
    ["a335ee"] = "6d1fa3", ["ff8000"] = "a34f00", ["e6cc80"] = "8a6d1f", ["00ccff"] = "006b8a",
}
local INK_BY_QUALITY = { [0] = "5e5e5e", "3b2612", "1d6b00", "0b4f9e", "6d1fa3", "a34f00", "8a6d1f", "006b8a" }

local function InkColors(text)
    text = text:gsub("|cnIQ(%d):", function(q) return "|cff" .. (INK_BY_QUALITY[tonumber(q)] or "3b2612") end)
    text = text:gsub("|c[fF][fF](%x%x%x%x%x%x)", function(h)
        local dark = INK_BY_HEX[h:lower()]
        return dark and ("|cff" .. dark) or nil
    end)
    return text
end

local book, pageText, pageLabel, prevBtn, nextBtn, bookExportBtn, measure, coverIcon
local pages, pageIndex = {}, 1
local shownBlocks, shownMeta -- başkasının kitabı açıksa onun blokları

-- Blokları, ölçerek sayfalara böler. Her bölüm yeni sayfada başlar.
local function Paginate(blocks)
    pages = {}
    local cur = ""
    local function push()
        if cur ~= "" then pages[#pages + 1] = cur end
        cur = ""
    end
    local function fits(text)
        measure:SetText(text)
        return measure:GetStringHeight() <= PAGE_H
    end
    local function append(piece, sep)
        local candidate = (cur == "") and piece or (cur .. sep .. piece)
        if cur ~= "" and not fits(candidate) then
            push()
            cur = piece
        else
            cur = candidate
        end
    end

    for _, b in ipairs(blocks or ns.BuildBookBlocks()) do
        if b.kind == "title" then
            -- Kapak sayfası: üstte sınıf ikonu için boşluk bırak
            cur = "\n\n\n\n\n" .. C_TITLE .. b.text .. "|r"
        elseif b.kind == "subtitle" then
            cur = cur .. "\n" .. C_DAY .. b.text .. "|r"
        elseif b.kind == "honor" then
            cur = cur .. "\n\n" .. C_HONOR .. "~ " .. b.text .. " ~|r"
        elseif b.kind == "motto" then
            cur = cur .. "\n\n\n" .. C_MOTTO .. b.text .. "|r"
        elseif b.kind == "chapter" then
            push() -- ilk bölümde kapak sayfası kapanır
            cur = C_CHAP .. ORNAMENT .. "  " .. b.text .. "|r"
        elseif b.kind == "summary" then
            append(C_SUM .. ORNAMENT .. " " .. b.text .. "|r", "\n\n")
        else
            -- Uzun paragrafları cümle cümle ekle ki sayfaya sığsın
            local first = true
            local prefix = b.day and (C_DAY .. b.day .. "|r — ") or ""
            local text = InkColors(b.text)
            for sent in text:gmatch("[^%.!]+[%.!]*%s*") do
                if first then
                    append(prefix .. sent, "\n\n")
                    first = false
                else
                    append(sent, "")
                end
            end
            if first then append(prefix .. text, "\n\n") end
        end
    end
    push()
end

local function ShowPage()
    pageIndex = math.max(1, math.min(pageIndex, #pages))
    -- Sınıf ikonu sadece kapakta
    local coords = ClassIconCoords(shownMeta and shownMeta.classFile or select(2, UnitClass("player")))
    if coverIcon then
        if pageIndex == 1 and coords then
            coverIcon:SetTexCoord(unpack(coords))
            coverIcon:Show()
        else
            coverIcon:Hide()
        end
    end
    pageText:SetJustifyH(pageIndex == 1 and "CENTER" or "LEFT")
    pageText:SetText(pages[pageIndex] or "")
    pageLabel:SetText(L.BOOK_PAGE:format(pageIndex, #pages))
    ns.SetButtonEnabled(prevBtn, pageIndex > 1)
    ns.SetButtonEnabled(nextBtn, pageIndex < #pages)
end

local function Flip(delta)
    local before = pageIndex
    pageIndex = math.max(1, math.min(pageIndex + delta, #pages))
    if pageIndex ~= before then Sound("IG_ABILITY_PAGE_TURN", 836) end
    ShowPage()
end

local function UpdateBookTexts()
    SetButtonText(prevBtn, L.BTN_PREV)
    SetButtonText(nextBtn, L.BTN_NEXT)
    SetButtonText(bookExportBtn, L.BTN_EXPORT)
end

local function CreateBook()
    book = CreateFrame("Frame", "KarakterAnilariBook", UIParent, "BackdropTemplate")
    book:SetSize(450, 560)
    book:SetPoint("CENTER")
    book:SetFrameStrata("DIALOG")
    book:SetClampedToScreen(true)
    book:SetMovable(true)
    book:EnableMouse(true)
    book:RegisterForDrag("LeftButton")
    book:SetScript("OnDragStart", book.StartMoving)
    book:SetScript("OnDragStop", book.StopMovingOrSizing)
    book:Hide()
    tinsert(UISpecialFrames, "KarakterAnilariBook")

    book:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    book:SetBackdropColor(0.93, 0.86, 0.70, 1)
    book:SetBackdropBorderColor(0.45, 0.28, 0.12, 1)

    local close = CreateFrame("Button", nil, book, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    book:SetScript("OnHide", function() Sound("IG_SPELLBOOK_CLOSE", 830) end)

    coverIcon = book:CreateTexture(nil, "ARTWORK")
    coverIcon:SetSize(56, 56)
    coverIcon:SetPoint("TOP", 0, -36)
    coverIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    coverIcon:Hide()

    pageText = book:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(BOOK_FONT, 15, "")
    pageText:SetTextColor(unpack(INK))
    pageText:SetPoint("TOPLEFT", 30, -40)
    pageText:SetSize(PAGE_W, PAGE_H)
    pageText:SetJustifyV("TOP")
    pageText:SetSpacing(4)

    -- Sayfalama için görünmez ölçüm alanı (aynı font ve genişlik)
    measure = book:CreateFontString(nil, "OVERLAY")
    measure:SetFont(BOOK_FONT, 15, "")
    measure:SetWidth(PAGE_W)
    measure:SetSpacing(4)
    measure:SetJustifyH("LEFT")
    measure:SetPoint("TOPLEFT", 30, -40)
    measure:SetAlpha(0) -- görünmez ama ölçüm için "gösterilir" durumda

    pageLabel = book:CreateFontString(nil, "OVERLAY")
    pageLabel:SetFont(FONT, 12, "")
    pageLabel:SetTextColor(unpack(INK))
    pageLabel:SetPoint("BOTTOM", 0, 48)

    prevBtn = CreateFrame("Button", nil, book, "UIPanelButtonTemplate")
    prevBtn:SetSize(100, 22)
    prevBtn:SetPoint("BOTTOMLEFT", 20, 16)
    prevBtn:SetScript("OnClick", function() Flip(-1) end)

    nextBtn = CreateFrame("Button", nil, book, "UIPanelButtonTemplate")
    nextBtn:SetSize(100, 22)
    nextBtn:SetPoint("BOTTOMRIGHT", -20, 16)
    nextBtn:SetScript("OnClick", function() Flip(1) end)

    bookExportBtn = CreateFrame("Button", nil, book, "UIPanelButtonTemplate")
    bookExportBtn:SetSize(120, 22)
    bookExportBtn:SetPoint("BOTTOM", 0, 16)
    bookExportBtn:SetScript("OnClick", function() ns.OpenExport("discord") end)

    UpdateBookTexts()

    book:EnableMouseWheel(true)
    book:SetScript("OnMouseWheel", function(_, delta) Flip(-delta) end)
end

function ns.ToggleBook()
    if book and book:IsShown() then book:Hide() else ns.OpenBook() end
end

-- blocks/meta verilirse başkasının kitabı (lonca kütüphanesi) açılır
function ns.OpenBook(blocks, meta)
    if not ns.db then return end
    if not book then CreateBook() end
    shownBlocks, shownMeta = blocks, meta
    Paginate(blocks)
    pageIndex = 1
    ShowPage()
    bookExportBtn:SetShown(blocks == nil)
    if not book:IsShown() then Sound("IG_SPELLBOOK_OPEN", 829) end
    book:Show()
end

----------------------------------------------------------------------
-- Dışa aktarma penceresi (kopyalanabilir metin)
----------------------------------------------------------------------
local exp, expTitle, expHint, editBox, expScroll, lengthText
local exportText, exportFmt = "", "discord"
local fmtButtons = {}

local function FillExport()
    exportText = ns.RenderBook(exportFmt)
    editBox:SetText(exportText)
    local len = strlenutf8 and strlenutf8(exportText) or #exportText
    local text = L.EXPORT_LENGTH:format(len)
    if exportFmt == "discord" and len > 2000 then
        text = text .. "  |cffff8080" .. L.EXPORT_DISCORD_WARN .. "|r"
    end
    lengthText:SetText(text)
    for key, b in pairs(fmtButtons) do
        ns.SetButtonActive(b, key == exportFmt)
    end
    expScroll:SetVerticalScroll(0)
    editBox:SetFocus()
    editBox:SetCursorPosition(0)
    editBox:HighlightText()
end

local function UpdateExportTexts()
    expTitle:SetText("|cffffd100" .. L.EXPORT_TITLE .. "|r")
    expHint:SetText(L.EXPORT_HINT)
    SetButtonText(fmtButtons.discord, "Discord")
    SetButtonText(fmtButtons.plain, L.EXPORT_PLAIN)
    SetButtonText(fmtButtons.json, L.EXPORT_JSON)
end

local function MakeFmtButton(key, x)
    local b = CreateFrame("Button", nil, exp, "UIPanelButtonTemplate")
    b:SetSize(110, 22)
    b:SetPoint("TOPLEFT", x, -52)
    b:SetScript("OnClick", function()
        exportFmt = key
        FillExport()
    end)
    fmtButtons[key] = b
end

local function CreateExport()
    exp = CreateFrame("Frame", "KarakterAnilariExport", UIParent, "BasicFrameTemplateWithInset")
    exp:SetSize(600, 500)
    exp:SetPoint("CENTER")
    exp:SetFrameStrata("FULLSCREEN_DIALOG")
    exp:SetClampedToScreen(true)
    exp:SetMovable(true)
    exp:EnableMouse(true)
    exp:RegisterForDrag("LeftButton")
    exp:SetScript("OnDragStart", exp.StartMoving)
    exp:SetScript("OnDragStop", exp.StopMovingOrSizing)
    exp:Hide()
    tinsert(UISpecialFrames, "KarakterAnilariExport")

    expTitle = exp:CreateFontString(nil, "OVERLAY")
    expTitle:SetFont(FONT, 14, "")
    expTitle:SetPoint("TOP", 0, -5)

    expHint = exp:CreateFontString(nil, "OVERLAY")
    expHint:SetFont(FONT, 12, "")
    expHint:SetPoint("TOPLEFT", 16, -30)

    MakeFmtButton("discord", 14)
    MakeFmtButton("plain", 128)
    MakeFmtButton("json", 242)

    lengthText = exp:CreateFontString(nil, "OVERLAY")
    lengthText:SetFont(FONT, 11, "")
    lengthText:SetPoint("LEFT", fmtButtons.json, "RIGHT", 10, 0)
    lengthText:SetWidth(225)
    lengthText:SetJustifyH("LEFT")
    lengthText:SetTextColor(0.8, 0.8, 0.8)

    expScroll = CreateFrame("ScrollFrame", "KarakterAnilariExportScroll", exp, "UIPanelScrollFrameTemplate")
    expScroll:SetPoint("TOPLEFT", 14, -84)
    expScroll:SetPoint("BOTTOMRIGHT", -32, 12)

    editBox = CreateFrame("EditBox", nil, expScroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetFont(FONT, 13, "")
    editBox:SetWidth(540)
    editBox:SetHeight(400)
    expScroll:SetScrollChild(editBox)

    editBox:SetScript("OnEscapePressed", function() exp:Hide() end)
    -- Salt okunur: kullanıcı yazarsa metni geri koy
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(exportText)
            self:HighlightText()
        end
    end)
    if ScrollingEdit_OnCursorChanged then
        editBox:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
        editBox:SetScript("OnUpdate", function(self, elapsed)
            ScrollingEdit_OnUpdate(self, elapsed, expScroll)
        end)
    end
    expScroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    UpdateExportTexts()
end

function ns.OpenExport(fmt)
    if not ns.db then return end
    if not exp then CreateExport() end
    exportFmt = fmt or exportFmt
    exp:Show()
    FillExport()
end

----------------------------------------------------------------------
-- Dil değişince açık pencereleri yenile
----------------------------------------------------------------------
ns.OnLanguageChanged(function()
    if book then
        UpdateBookTexts()
        if book:IsShown() and not shownBlocks then
            local keep = pageIndex
            Paginate()
            pageIndex = keep
            ShowPage()
        end
    end
    if exp then
        UpdateExportTexts()
        if exp:IsShown() then FillExport() end
    end
end)
