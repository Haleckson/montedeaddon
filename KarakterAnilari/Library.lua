-- FallenMemoir / Karakter Anıları - Lonca kütüphanesi
-- Lonca arkadaşları birbirlerinin kitabını oyun içinde okuyabilir.
--
-- Protokol (addon mesajları, önek "FallenMemoir"):
--   "L"                         lonca kanalına: kitabı olan var mı?
--   "H\t<lvl>\t<sınıf>\t<n>\t<unvan>\t<classFile>"   fısıltıyla yanıt: bende var
--   "R"                         fısıltı: kitabını gönderir misin?
--   "N"                         fısıltı: paylaşmıyorum
--   "B\t<sıra>\t<toplam>\t<veri>"  fısıltı: kitabın bir parçası
-- Kitap, renk ve link kodları temizlenmiş düz metin olarak gönderilir ve kişisel
-- notlar paylaşılmaz. Zindan ve savaş içinde Blizzard addon mesajlarını
-- kısıtlayabildiği için tüm gönderimler korumalıdır.

local ADDON, ns = ...
local L = ns.L
local FONT = ns.FONT

local PREFIX = "FallenMemoir"
local CHUNK = 200            -- bir mesajdaki veri baytı (sınır 255)
local SEND_INTERVAL = 0.12   -- mesajlar arası saniye (sunucu kısıtına takılmamak için)
local MAX_BOOK = 60000       -- bir kitabın gönderilebilecek en büyük boyutu (bayt)
local REC, FLD = "\030", "\031" -- kayıt ve alan ayırıcıları

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function Me()
    return UnitName("player")
end

local function ShortName(sender)
    if Ambiguate then return Ambiguate(sender, "none") end
    return (sender:gsub("%-.*$", ""))
end

----------------------------------------------------------------------
-- Gönderim (sıraya alınmış, yavaşlatılmış)
----------------------------------------------------------------------
local queue, ticking = {}, false

local function RawSend(msg, channel, target)
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return false end
    local ok, result = pcall(send, PREFIX, msg, channel, target)
    -- Yeni istemciler bir sonuç kodu döndürür; 0 / nil / true başarılı demektir
    return ok and (result == nil or result == true or result == 0)
end

local function Pump()
    local item = table.remove(queue, 1)
    if not item then ticking = false return end
    RawSend(item[1], item[2], item[3])
    if #queue > 0 and C_Timer and C_Timer.After then
        C_Timer.After(SEND_INTERVAL, Pump)
    else
        while #queue > 0 do Pump() end
        ticking = false
    end
end

local function Send(msg, channel, target)
    queue[#queue + 1] = { msg, channel, target }
    if not ticking then
        ticking = true
        Pump()
    end
end

----------------------------------------------------------------------
-- Kitabı düz metin kayıtlarına çevir / geri çöz
----------------------------------------------------------------------
local function Clean(s)
    s = ns.PlainText and ns.PlainText(s or "") or (s or "")
    return (s:gsub("[\030\031\n\r\t]", " "))
end

local function Serialize()
    local _, classFile = UnitClass("player")
    local recs = { table.concat({ "META", Clean(Me()), classFile or "", tostring(UnitLevel("player") or 0) }, FLD) }
    for _, b in ipairs(ns.BuildBookBlocks({ noNotes = true })) do
        recs[#recs + 1] = table.concat({ b.kind or "para", Clean(b.day or ""), Clean(b.text) }, FLD)
    end
    local data = table.concat(recs, REC)
    if #data > MAX_BOOK then data = data:sub(1, MAX_BOOK) end
    return data
end

local function Deserialize(data)
    local blocks, meta = {}, {}
    for rec in (data .. REC):gmatch("(.-)" .. REC) do
        local a, b, c, d = rec:match("^(.-)" .. FLD .. "(.-)" .. FLD .. "(.-)" .. FLD .. "(.*)$")
        if a == "META" then
            meta.name, meta.classFile, meta.level = b, c, tonumber(d)
        else
            local kind, day, text = rec:match("^(.-)" .. FLD .. "(.-)" .. FLD .. "(.*)$")
            if kind and text then
                blocks[#blocks + 1] = { kind = kind, day = (day ~= "" and day or nil), text = text }
            end
        end
    end
    return blocks, meta
end

-- UTF-8 karakterini ortasından bölmeden parçalara ayır
local function Chunks(data)
    local out, i, n = {}, 1, #data
    while i <= n do
        local j = math.min(i + CHUNK - 1, n)
        while j < n and j > i do
            local nextByte = data:byte(j + 1)
            if nextByte and nextByte >= 0x80 and nextByte < 0xC0 then j = j - 1 else break end
        end
        out[#out + 1] = data:sub(i, j)
        i = j + 1
    end
    return out
end

----------------------------------------------------------------------
-- Kütüphane penceresi
----------------------------------------------------------------------
local win, statusText, rows, refreshBtn
local found, order = {}, {}       -- gönderen -> bilgi
local incoming = {}               -- gönderen -> { total, parts, got }
local waitingFor                  -- kitabını beklediğimiz oyuncu
local ROWS = 12

local function SetStatus(text)
    if statusText then statusText:SetText(text or "") end
end

local function RefreshRows()
    if not win then return end
    for i = 1, ROWS do
        local row, sender = rows[i], order[i]
        if sender then
            local info = found[sender]
            local line = L.LIB_ROW:format(ShortName(sender), info.level or 0, info.class or "", info.count or 0)
            if info.title and info.title ~= "" then line = line .. "  |cffffcc66~ " .. info.title .. " ~|r" end
            row.text:SetText(line)
            row.sender = sender
            row:Show()
        else
            row:Hide()
        end
    end
end

local searchToken = 0
local function Search()
    wipe(found); wipe(order)
    RefreshRows()
    if not IsInGuild or not IsInGuild() then return SetStatus(L.LIB_NO_GUILD) end
    if not RawSend("L", "GUILD") then return SetStatus(L.LIB_UNAVAILABLE) end
    SetStatus(L.LIB_SEARCHING)
    searchToken = searchToken + 1
    local token = searchToken
    if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
            if token ~= searchToken then return end
            if #order == 0 then SetStatus(L.LIB_NONE) end
        end)
    end
end

local function RequestBook(sender)
    waitingFor = sender
    incoming[sender] = nil
    SetStatus(L.LIB_REQUESTING:format(ShortName(sender)))
    if not RawSend("R", "WHISPER", sender) then SetStatus(L.LIB_UNAVAILABLE) end
end

local function CreateWindow()
    win = CreateFrame("Frame", "KarakterAnilariLibrary", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(460, 380)
    win:SetPoint("CENTER", 0, 40)
    win:SetFrameStrata("HIGH")
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "KarakterAnilariLibrary")

    win.title = win:CreateFontString(nil, "OVERLAY")
    win.title:SetFont(FONT, 14, "")
    win.title:SetPoint("TOP", 0, -5)

    statusText = win:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(FONT, 12, "")
    statusText:SetPoint("TOPLEFT", 16, -34)
    statusText:SetWidth(428)
    statusText:SetJustifyH("LEFT")
    statusText:SetTextColor(0.85, 0.85, 0.85)

    rows = {}
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, win)
        row:SetSize(428, 22)
        row:SetPoint("TOPLEFT", 16, -60 - (i - 1) * 23)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetFont(FONT, 12, "")
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetWidth(416)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row:SetScript("OnClick", function(self) if self.sender then RequestBook(self.sender) end end)
        row:Hide()
        rows[i] = row
    end

    refreshBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    refreshBtn:SetSize(120, 22)
    refreshBtn:SetPoint("BOTTOM", 0, 12)
    refreshBtn:SetScript("OnClick", Search)

    win:SetScript("OnShow", Search)
end

local function UpdateTexts()
    if not win then return end
    win.title:SetText("|cffffd100" .. L.LIB_TITLE .. "|r")
    ns.SetButtonLabel(refreshBtn, L.BTN_REFRESH)
    RefreshRows()
end

function ns.ToggleLibrary()
    if not win then
        CreateWindow()
        UpdateTexts()
    end
    win:SetShown(not win:IsShown())
end

ns.OnLanguageChanged(UpdateTexts)

----------------------------------------------------------------------
-- Gelen mesajlar
----------------------------------------------------------------------
local function Sharing()
    return not (ns.settings and ns.settings.share == false)
end

local function OnMessage(prefix, msg, channel, sender)
    if prefix ~= PREFIX or IsSecret(msg) or IsSecret(sender) or type(msg) ~= "string" then return end
    if not sender or ShortName(sender) == Me() then return end
    local cmd = msg:sub(1, 1)

    if cmd == "L" then
        -- Biri kütüphaneyi açtı: kitabımız varsa kendimizi tanıt
        if Sharing() and ns.db and ns.db.started then
            local titles = ns.EarnedTitles and ns.EarnedTitles() or {}
            local _, classFile = UnitClass("player")
            Send(table.concat({ "H", tostring(UnitLevel("player") or 0), Clean(UnitClass("player") or ""),
                tostring(#ns.db.events), Clean(titles[1] and ns.TitleText(titles[1]) or ""), classFile or "" }, "\t"),
                "WHISPER", sender)
        end

    elseif cmd == "H" then
        local _, level, class, count, title, classFile = strsplit("\t", msg)
        if not found[sender] then order[#order + 1] = sender end
        found[sender] = { level = tonumber(level), class = class, count = tonumber(count),
                          title = title, classFile = classFile }
        if win and win:IsShown() then
            SetStatus(L.LIB_FOUND:format(#order))
            RefreshRows()
        end

    elseif cmd == "R" then
        if not Sharing() or not ns.db then return Send("N", "WHISPER", sender) end
        local ok, data = pcall(Serialize)
        if not ok then return end
        local parts = Chunks(data)
        for i, part in ipairs(parts) do
            Send("B\t" .. i .. "\t" .. #parts .. "\t" .. part, "WHISPER", sender)
        end

    elseif cmd == "N" then
        if waitingFor == sender then SetStatus(L.LIB_NOT_SHARING) end

    elseif cmd == "B" then
        local seq, total, data = msg:match("^B\t(%d+)\t(%d+)\t(.*)$")
        seq, total = tonumber(seq), tonumber(total)
        if not seq or not total or waitingFor ~= sender then return end
        local buf = incoming[sender]
        if not buf or buf.total ~= total then
            buf = { total = total, parts = {}, got = 0 }
            incoming[sender] = buf
        end
        if not buf.parts[seq] then
            buf.parts[seq] = data
            buf.got = buf.got + 1
        end
        SetStatus(L.LIB_RECEIVING:format(buf.got, total))
        if buf.got == total then
            incoming[sender] = nil
            waitingFor = nil
            local blocks, meta = Deserialize(table.concat(buf.parts))
            meta.name = meta.name or ShortName(sender)
            if found[sender] then meta.classFile = meta.classFile or found[sender].classFile end
            SetStatus("")
            ns.OpenBook(blocks, meta)
        end
    end
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        local register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
        if register then pcall(register, PREFIX) end
        return
    end
    pcall(OnMessage, ...)
end)

-- Testler için iç fonksiyonlar
ns._lib = { Serialize = Serialize, Deserialize = Deserialize, Chunks = Chunks, OnMessage = OnMessage, RequestBook = RequestBook }
