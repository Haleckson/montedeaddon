-- Karakter Anıları / Character Memoir - Core
-- Karakterinin hayatındaki önemli anları otomatik olarak kaydeder.
-- Anılar ham veri olarak saklanır; metin, gösterilirken seçili dilde üretilir.

local ADDON, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- Anı türleri
----------------------------------------------------------------------
ns.TYPES = {
    start       = { color = "ffffd100" },
    level       = { color = "ff40ff40" },
    zone        = { color = "ff66ccff" },
    achievement = { color = "ffffa500" },
    loot        = { color = "ffa335ee" },
    mount       = { color = "ff33ffcc" },
    boss        = { color = "ffff4040" },
    death       = { color = "ffaaaaaa" },
    quest       = { color = "ffffff66" },
    note        = { color = "ffffffff" },
    photo       = { color = "ffff99cc" },
    title       = { color = "ffffcc66" },
}
ns.FILTER_ORDER = { "level", "zone", "achievement", "loot", "mount", "boss", "death", "quest", "photo", "title", "note" }

function ns.TypeColor(kind)
    return (ns.TYPES[kind] or ns.TYPES.note).color
end

function ns.TypeLabel(kind)
    return L["TYPE_" .. kind]
end

local MILESTONES = {
    [1] = true, [10] = true, [25] = true, [50] = true, [100] = true, [250] = true,
    [500] = true, [1000] = true, [2500] = true, [5000] = true, [10000] = true,
}

local DB

----------------------------------------------------------------------
-- Aktif oyun süresi (addonun ölçtüğü, karakter oyundayken geçen süre)
-- /played isteği sohbeti kirletmesin diye kendi sayacımızı tutuyoruz.
----------------------------------------------------------------------
local sessionStart

local function ActiveNow()
    local base = (DB and DB.activeTime) or 0
    if sessionStart then base = base + (GetTime() - sessionStart) end
    return base
end
ns.ActiveNow = ActiveNow

local function SaveActive()
    if not DB or not sessionStart then return end
    DB.activeTime = ActiveNow()
    sessionStart = GetTime()
end

function ns.FormatDuration(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
    if h > 0 then return L.DUR_HM:format(h, m) end
    return L.DUR_M:format(math.max(1, m))
end

local function Print(msg)
    print(ns.GameFontSafe("|cffffd100[" .. L.ADDON_SHORT .. "]|r " .. msg))
end
ns.Print = Print

----------------------------------------------------------------------
-- Yardımcılar
----------------------------------------------------------------------
-- Midnight (12.0+) "secret value" koruması: gizli değerlere dokunmayız.
local function IsSecret(...)
    if not issecretvalue then return false end
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then return true end
    end
    return false
end

local function CurrentZone()
    local zone = GetRealZoneText and GetRealZoneText()
    if (not zone or zone == "") and C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        local info = mapID and C_Map.GetMapInfo(mapID)
        -- Kıta/dünya haritasını bölge sanma (ör. "Eastern Kingdoms"): 0-2 = kozmik/dünya/kıta
        if info and (not info.mapType or info.mapType >= 3) then zone = info.name end
    end
    if not zone or zone == "" or IsSecret(zone) then return nil end
    return zone
end

----------------------------------------------------------------------
-- Anı -> kısa metin (defter ve sohbet için), seçili dilde
----------------------------------------------------------------------
-- "Orc Shaman" (boş parçaları atlar)
function ns.RaceClass(d)
    local s = ((d.race or "") .. " " .. (d.class or "")):gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function Describe(e)
    local d, k = e.d, e.k
    if not d then return e.x or "?" end -- v0.1'den kalan kayıtlar

    if k == "start" then
        return L.MEM_start:format(d.name or "?", d.level or 1, ns.RaceClass(d),
            d.zone or L.UNKNOWN_PLACE)
    elseif k == "note" then
        return d.text or e.x or ""
    elseif k == "zone" then
        return L.MEM_zone:format(d.zone)
    elseif k == "level" then
        if d.dur then return L.MEM_level_dur:format(d.level, ns.FormatDuration(d.dur)) end
        return L.MEM_level:format(d.level)
    elseif k == "photo" then
        if d.file then return L.MEM_photo_file:format(d.file) end
        return L.MEM_photo
    elseif k == "title" then
        return L.MEM_title:format(ns.TitleText(d.id) or "?")
    elseif k == "death" then
        if d.kind == "first" then return L.MEM_death_first:format(d.zone) end
        if d.kind == "milestone" then return L.MEM_death_milestone:format(d.total) end
        return L.MEM_death_zone:format(d.zone)
    elseif k == "quest" then
        if d.title then return L.MEM_quest_title:format(d.count, d.title) end
        return L.MEM_quest:format(d.count)
    elseif k == "achievement" then
        return L.MEM_achievement:format(d.name, d.points or 0)
    elseif k == "mount" then
        return L.MEM_mount:format(d.name)
    elseif k == "boss" then
        if d.diff then return L.MEM_boss_diff:format(d.name, d.diff) end
        return L.MEM_boss:format(d.name)
    elseif k == "loot" then
        local q = math.max(0, math.min(5, d.q or 4))
        return L.MEM_loot:format(L["LOOTLABEL_" .. q], d.link)
    end
    return e.x or "?"
end

function ns.Describe(e)
    local ok, s = pcall(Describe, e)
    if ok and s then return s end
    return e.x or "?"
end

function ns.AddMemory(kind, data)
    if not DB then return end
    local e = {
        t = time(),
        k = kind,
        d = data or {},
        z = CurrentZone(),
        l = UnitLevel("player"),
    }
    table.insert(DB.events, e)
    -- Sohbet bildirimi: düşük kaliteli ganimetler sohbeti doldurmasın (mavi ve üstü)
    local minor = (kind == "loot") and (e.d.q or 4) < ns.LOOT_NOTIFY_MIN
    if not DB.quiet and not minor then
        Print("|c" .. ns.TypeColor(kind) .. ns.Describe(e) .. "|r")
    end
    if kind ~= "title" and kind ~= "start" and ns.CheckTitles then ns.CheckTitles() end
    if ns.OnNewMemory then ns.OnNewMemory() end
end

----------------------------------------------------------------------
-- Unvanlar: istatistiklere göre otomatik kazanılır, bir kez kazanılan kalır.
-- Sıra, kapakta hangi unvanın gösterileceğini belirler (en prestijlisi önce).
----------------------------------------------------------------------
local TITLE_ORDER = { "champion", "boss15", "quest500", "explorer25", "undying", "spirit",
                      "boss5", "treasure", "quest100", "explorer10", "photo10", "bane" }

local function CountKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function EvalTitles()
    local earned = {}
    local zones, bosses = CountKeys(DB.zones), CountKeys(DB.bosses)
    local level = UnitLevel("player") or 1
    local epics, photos = 0, 0
    for _, e in ipairs(DB.events) do
        if e.k == "loot" and e.d and (e.d.q or 0) >= 4 then epics = epics + 1 end
        if e.k == "photo" then photos = photos + 1 end
    end
    if level >= 60 then earned.champion = true end
    if bosses >= 15 then earned.boss15 = true end
    if bosses >= 5 then earned.boss5 = true end
    if DB.quests >= 500 then earned.quest500 = true end
    if DB.quests >= 100 then earned.quest100 = true end
    if zones >= 25 then earned.explorer25 = true end
    if zones >= 10 then earned.explorer10 = true end
    if level >= 20 and DB.deaths.total == 0 then earned.undying = true end
    if DB.deaths.total >= 50 then earned.spirit = true end
    if epics >= 3 then earned.treasure = true end
    if photos >= 10 then earned.photo10 = true end
    for z, c in pairs(DB.deaths.byZone) do
        if c >= 5 and z ~= "?" then earned["bane:" .. z] = true end
    end
    return earned
end

function ns.TitleText(id)
    local zone = id and id:match("^bane:(.+)$")
    if zone then return ns.Fill(L.TITLE_bane, { zone = zone }) end
    return L["TITLE_" .. tostring(id)]
end

-- Kazanılmış unvanlar, prestij sırasıyla
function ns.EarnedTitles(titles)
    titles = titles or (DB and DB.titles) or {}
    local out = {}
    for _, id in ipairs(TITLE_ORDER) do
        if id == "bane" then
            for key in pairs(titles) do
                if key:match("^bane:") then out[#out + 1] = key end
            end
        elseif titles[id] then
            out[#out + 1] = id
        end
    end
    return out
end

local checkingTitles = false
function ns.CheckTitles()
    if checkingTitles or not DB or not DB.started then return end
    checkingTitles = true
    DB.titles = DB.titles or {}
    local ok, earned = pcall(EvalTitles)
    if ok then
        for _, id in ipairs(ns.EarnedTitles(earned)) do
            if not DB.titles[id] then
                DB.titles[id] = time()
                ns.AddMemory("title", { id = id })
            end
        end
    end
    checkingTitles = false
end

----------------------------------------------------------------------
-- Aylık istatistikler (ay sonu özeti için): ölüm, seviye, görev, bölge süresi
----------------------------------------------------------------------
local function Month()
    DB.monthly = DB.monthly or {}
    local key = date("%Y-%m")
    local m = DB.monthly[key]
    if not m then
        m = { deaths = 0, levels = 0, quests = 0, zoneTime = {} }
        DB.monthly[key] = m
    end
    return m
end

local zoneTrack
local function TrackZoneTime()
    if not DB or not DB.started then return end
    local now = ActiveNow()
    if zoneTrack and zoneTrack.zone then
        local dt = now - zoneTrack.active
        if dt > 0 and dt < 86400 then
            local m = Month()
            m.zoneTime[zoneTrack.zone] = (m.zoneTime[zoneTrack.zone] or 0) + dt
        end
    end
    zoneTrack = { zone = CurrentZone(), active = now }
end

----------------------------------------------------------------------
-- Ganimet tespiti (sadece kendi ganimetin; istemci dilinden bağımsız)
----------------------------------------------------------------------
local function ToPattern(fmt)
    if type(fmt) ~= "string" then return nil end
    local p = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    p = p:gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
    return "^" .. p .. "$"
end

local LOOT_PATTERNS = {}
for _, g in ipairs({ "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
                     "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE" }) do
    local p = ToPattern(_G[g])
    if p then table.insert(LOOT_PATTERNS, p) end
end

-- Kalite: 0=gri, 1=beyaz, 2=yeşil, 3=mavi, 4=mor, 5=turuncu
ns.LOOT_NOTIFY_MIN = 3 -- bundan düşükler sohbette gösterilmez, kitapta toplu anlatılır

local HEX_QUALITY = {
    ff9d9d9d = 0, ffffffff = 1, ff1eff00 = 2, ff0070dd = 3, ffa335ee = 4, ffff8000 = 5, ffe6cc80 = 6, ff00ccff = 7,
}

local function LinkQuality(link)
    if C_Item and C_Item.GetItemQualityByID then
        local ok, q = pcall(C_Item.GetItemQualityByID, link)
        if ok and q then return q end
    end
    local q = link:match("|cnIQ(%d)")
    if q then return tonumber(q) end
    local hex = link:match("|c(%x%x%x%x%x%x%x%x)")
    return hex and HEX_QUALITY[hex:lower()] or nil
end

-- Sadece giyilebilir silah ve zırhlar. Yiyecek, malzeme, görev eşyası vb. atlanır.
local CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local CLASS_ARMOR  = (Enum and Enum.ItemClass and Enum.ItemClass.Armor) or 4
local NOT_WORN = { [""] = true, INVTYPE_NON_EQUIP = true, INVTYPE_NON_EQUIP_IGNORE = true, INVTYPE_BAG = true }

local function IsWearableGear(link)
    local getInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not getInfo then return false end
    local ok, itemID, _, _, equipLoc, _, classID = pcall(getInfo, link)
    if not ok or not itemID then return false end
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end
    return not NOT_WORN[equipLoc or ""], equipLoc
end

----------------------------------------------------------------------
-- Olaylar
----------------------------------------------------------------------
local handlers = {}

-- v0.1 kayıtları sadece Türkçe metin (x) içeriyordu. Bunları ham veriye çevir ki
-- eski anılar da her iki dilde gösterilebilsin. Tanınmayanlar olduğu gibi kalır.
local LEGACY = {
    { "zone", "^Yeni bir yer keşfettin: (.+)$", function(z) return { zone = z } end },
    { "level", "^(%d+)%. seviyeye ulaştın!$", function(l) return { level = tonumber(l) } end },
    { "achievement", "^Başarım kazandın: (.+) %((%d+) puan%)$",
        function(n, p) return { name = n, points = tonumber(p) } end },
    { "mount", "^Yeni binek: (.+)$", function(n) return { name = n } end },
    { "death", "^Hayatındaki ilk ölüm%. Yer: (.+)$", function(z) return { kind = "first", zone = z } end },
    { "death", "^Toplamda (%d+)%. kez öldün", function(n) return { kind = "milestone", total = tonumber(n) } end },
    { "death", "^(.+) seni ilk kez yere serdi%.$", function(z) return { kind = "zonefirst", zone = z } end },
    { "quest", "^(%d+)%. görevini tamamladın: (.+)%.$", function(n, t) return { count = tonumber(n), title = t } end },
    { "quest", "^(%d+)%. görevini tamamladın%.$", function(n) return { count = tonumber(n) } end },
    { "boss", "^(.+) ilk kez yenildi! %((.+)%)$", function(n, d) return { name = n, diff = d } end },
    { "boss", "^(.+) ilk kez yenildi!$", function(n) return { name = n } end },
    { "loot", "^Efsanevi ganimet: (.+)$", function(l) return { link = l, q = 5 } end },
    { "loot", "^Destansı ganimet: (.+)$", function(l) return { link = l, q = 4 } end },
    { "start", "^Anı defteri açıldı: (.-), seviye (%d+) (.-)%. Hikâye (.-)'de başlıyor%.$",
        function(n, l, rc, z) return { name = n, level = tonumber(l), race = rc, class = "", zone = z } end },
}

local function MigrateLegacy(events)
    for _, e in ipairs(events) do
        if not e.d and e.x then
            if e.k == "note" then
                e.d = { text = e.x }
            else
                for _, rule in ipairs(LEGACY) do
                    if rule[1] == e.k then
                        local caps = { e.x:match(rule[2]) }
                        if caps[1] then
                            e.d = rule[3](unpack(caps))
                            break
                        end
                    end
                end
            end
        end
    end
end

function handlers.ADDON_LOADED(name)
    if name ~= ADDON then return end
    -- Hesap geneli ayarlar (dil)
    KarakterAnilariSettings = KarakterAnilariSettings or {}
    ns.settings = KarakterAnilariSettings
    if ns.settings.lang then ns.SetLanguage(ns.settings.lang) end

    -- Karaktere özel anılar
    KarakterAnilariDB = KarakterAnilariDB or {}
    DB = KarakterAnilariDB
    DB.events  = DB.events or {}
    DB.zones   = DB.zones or {}
    DB.deaths  = DB.deaths or { total = 0, byZone = {} }
    DB.quests  = DB.quests or 0
    DB.bosses  = DB.bosses or {}
    -- v0.4: artık tüm kaliteler kaydediliyor (eski "en az destansı" ayarı sıfırlanır)
    if DB.lootMin == nil then DB.lootMin = 0 end
    DB.minLootQuality = nil
    pcall(MigrateLegacy, DB.events)
    ns.db = DB
end

local function StartBook()
    DB.started = time()
    DB.levelStart = { level = UnitLevel("player"), active = ActiveNow() }
    local zone = CurrentZone()
    if zone then DB.zones[zone] = time() end
    ns.AddMemory("start", {
        name = UnitName("player"),
        level = UnitLevel("player"),
        race = UnitRace("player") or "",
        class = UnitClass("player") or "",
        zone = zone,
    })
end

local function CheckZone()
    if not DB.started then return end
    local zone = CurrentZone()
    if not zone or DB.zones[zone] then return end
    DB.zones[zone] = time()
    ns.AddMemory("zone", { zone = zone })
end
local ScheduleHistory -- aşağıda tanımlanıyor (geçmişi doldurma)

-- İlk girişte bölge adı birkaç an geç yüklenir; defteri biraz bekleyip açıyoruz.
local starting = false
function handlers.PLAYER_ENTERING_WORLD()
    if not sessionStart then sessionStart = GetTime() end
    -- Eski sürümden gelenler: seviye sayacını şimdiki seviyeden başlat
    if DB.started and not DB.levelStart then
        DB.levelStart = { level = UnitLevel("player"), active = ActiveNow() }
    end
    if DB.started then
        ScheduleHistory()
        TrackZoneTime()
        CheckZone()
        return ns.CheckTitles()
    end
    if starting then return end
    starting = true
    local function go()
        if not DB.started then StartBook() end
        TrackZoneTime()
        CheckZone()
        ScheduleHistory()
    end
    if C_Timer and C_Timer.After then C_Timer.After(3, go) else go() end
end
function handlers.ZONE_CHANGED_NEW_AREA()
    TrackZoneTime()
    CheckZone()
end

function handlers.PLAYER_LEVEL_UP(level)
    if IsSecret(level) then return end
    local now = ActiveNow()
    local data = { level = level }
    -- Bir önceki seviyeden bu yana geçen oyun süresi (sadece kesintisiz izlediysek)
    local ls = DB.levelStart
    if ls and ls.level == level - 1 and now >= ls.active then
        data.dur = math.floor(now - ls.active)
    end
    DB.levelStart = { level = level, active = now }
    if DB.started then Month().levels = Month().levels + 1 end
    SaveActive()
    ns.AddMemory("level", data)
end

-- Çıkışta ve /reload'da oyun süresini kaydet
function handlers.PLAYER_LOGOUT()
    TrackZoneTime()
    SaveActive()
end

-- Ekran görüntüsü: yer ve saatle birlikte anı. WoW dosyayı yerel saatle adlandırır
-- (WoWScrnShot_AAGGYY_SSDDss.jpg); bu yüzden dosya adını tahmin edip saklıyoruz.
function handlers.SCREENSHOT_SUCCEEDED()
    ns.AddMemory("photo", { file = date("WoWScrnShot_%m%d%y_%H%M%S.jpg") })
end

function handlers.PLAYER_DEAD()
    local zone = CurrentZone() or "?"
    local d = DB.deaths
    d.total = d.total + 1
    d.byZone[zone] = (d.byZone[zone] or 0) + 1
    if DB.started then Month().deaths = Month().deaths + 1 end

    if d.total == 1 then
        ns.AddMemory("death", { kind = "first", total = d.total, zone = zone })
    elseif MILESTONES[d.total] then
        ns.AddMemory("death", { kind = "milestone", total = d.total, zone = zone })
    elseif d.byZone[zone] == 1 then
        ns.AddMemory("death", { kind = "zonefirst", total = d.total, zone = zone })
    else
        ns.CheckTitles() -- kayda geçmeyen ölümler de unvan kazandırabilir
    end
end

function handlers.QUEST_TURNED_IN(questID)
    DB.quests = DB.quests + 1
    if DB.started then Month().quests = Month().quests + 1 end
    if not MILESTONES[DB.quests] then return ns.CheckTitles() end
    local title
    if not IsSecret(questID) and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        title = C_QuestLog.GetTitleForQuestID(questID)
    end
    ns.AddMemory("quest", { count = DB.quests, title = (title and title ~= "") and title or nil })
end

function handlers.ACHIEVEMENT_EARNED(achievementID)
    if IsSecret(achievementID) then return end
    local _, name, points = GetAchievementInfo(achievementID)
    if not name then return end
    ns.AddMemory("achievement", { id = achievementID, name = name, points = points })
end

----------------------------------------------------------------------
-- Geçmişi doldurma: defter açılmadan önce kazanılmış başarımlar, kazanıldıkları
-- tarihlerle birlikte "Defterden Önce" bölümüne eklenir. Karakter başına bir kez
-- otomatik çalışır; /anilar gecmis ile elle tekrar çalıştırılabilir.
----------------------------------------------------------------------
local function DateToTime(month, day, year)
    if not (month and day and year) or IsSecret(month, day, year) then return nil end
    if year < 100 then year = year + 2000 end
    return time({ year = year, month = month, day = day, hour = 12 })
end

local function CollectPastAchievements(before)
    local stats = { cats = 0, total = 0, completed = 0, mine = 0, dated = 0 }
    if not (GetCategoryList and GetCategoryNumAchievements and GetAchievementInfo) then return {}, stats end
    local known = {}
    for _, e in ipairs(DB.events) do
        if e.k == "achievement" and e.d then
            if e.d.id then known[e.d.id] = true end
            if e.d.name then known[e.d.name] = true end
        end
    end
    local found, seen = {}, {}
    for _, cat in ipairs(GetCategoryList() or {}) do
        stats.cats = stats.cats + 1
        local n = GetCategoryNumAchievements(cat, true) or 0
        for i = 1, n do
            local id, name, points, completed, month, day, year, _, _, _, _, isGuild, wasEarnedByMe =
                GetAchievementInfo(cat, i)
            stats.total = stats.total + 1
            if completed then stats.completed = stats.completed + 1 end
            if completed and wasEarnedByMe ~= false then stats.mine = stats.mine + 1 end
            if completed and month and day and year then stats.dated = stats.dated + 1 end
            -- Sadece bu karakterin kazandıkları (hesap genelinde başka karakterin kazandığı değil)
            if id and name and completed and not isGuild and wasEarnedByMe ~= false
                and not seen[id] and not known[id] and not known[name] then
                seen[id] = true
                local t = DateToTime(month, day, year)
                if t and t < before then
                    found[#found + 1] = { t = t, k = "achievement",
                        d = { id = id, name = name, points = points, past = true } }
                end
            end
        end
    end
    return found, stats
end

function ns.Backfill(manual)
    if not DB or not DB.started then return end
    -- Defterin açıldığı günün sonuna kadar kazanılanlar "geçmiş" sayılır (zaten kayıtlıysa atlanır)
    local ok, found, stats = pcall(CollectPastAchievements, DB.started + 86400)
    if not ok then
        if manual then Print(L.MSG_ERROR:format("history", tostring(found))) return end
        if DB.debug then Print(L.MSG_ERROR:format("history", tostring(found))) end
        return
    end
    DB.historyDone = true
    -- Elle çalıştırıldığında ne bulunduğunu raporla (sorun tespiti için)
    if manual and stats then
        Print(L.MSG_HISTORY_SCAN:format(stats.cats, stats.total, stats.completed, stats.mine, stats.dated))
    end
    if #found == 0 then
        if manual then Print(L.MSG_HISTORY_NONE) end
        return
    end
    -- Geçmiş anıları tarih sırasıyla en başa, diğer anıları olduğu gibi arkaya diz
    local past, rest = {}, {}
    for _, e in ipairs(DB.events) do
        if e.d and e.d.past then past[#past + 1] = e else rest[#rest + 1] = e end
    end
    for _, e in ipairs(found) do past[#past + 1] = e end
    table.sort(past, function(a, b) return a.t < b.t end)
    wipe(DB.events)
    for _, e in ipairs(past) do DB.events[#DB.events + 1] = e end
    for _, e in ipairs(rest) do DB.events[#DB.events + 1] = e end
    Print(L.MSG_HISTORY_ADDED:format(#found))
    if ns.OnNewMemory then ns.OnNewMemory() end
end

ScheduleHistory = function()
    if DB.historyDone then return end
    if C_Timer and C_Timer.After then
        C_Timer.After(6, function() pcall(ns.Backfill, false) end)
    else
        pcall(ns.Backfill, false)
    end
end

function handlers.NEW_MOUNT_ADDED(mountID)
    if IsSecret(mountID) or not C_MountJournal then return end
    local name = C_MountJournal.GetMountInfoByID(mountID)
    if name then ns.AddMemory("mount", { name = name }) end
end

function handlers.ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
    if IsSecret(encounterID, encounterName, difficultyID, success) then return end
    if success ~= 1 and success ~= true then return end
    local key = encounterID .. ":" .. (difficultyID or 0)
    if DB.bosses[key] then return end
    DB.bosses[key] = time()
    local diffName = difficultyID and GetDifficultyInfo and GetDifficultyInfo(difficultyID)
    ns.AddMemory("boss", { name = encounterName, diff = (diffName and diffName ~= "") and diffName or nil })
end

function handlers.CHAT_MSG_LOOT(msg)
    if IsSecret(msg) or type(msg) ~= "string" then return end
    local mine = false
    for _, p in ipairs(LOOT_PATTERNS) do
        if msg:match(p) then mine = true break end
    end
    if not mine then return end
    local link = msg:match("(|c.-|h|r)")
    if not link then return end
    local wearable, slot = IsWearableGear(link)
    if not wearable then return end
    local q = LinkQuality(link)
    if not q or q < DB.lootMin then return end
    ns.AddMemory("loot", { link = link, q = q, slot = slot })
end

----------------------------------------------------------------------
-- Olay kaydı (sürümde olmayan olaylar sessizce atlanır)
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
for event in pairs(handlers) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event ~= "ADDON_LOADED" and not DB then return end
    local ok, err = pcall(handlers[event], ...)
    if not ok and DB and DB.debug then Print(L.MSG_ERROR:format(event, tostring(err))) end
end)

----------------------------------------------------------------------
-- Komutlar (Türkçe ve İngilizce alt komutlar birlikte çalışır)
----------------------------------------------------------------------
local ALIASES = {
    kitap = "book", book = "book",
    aktar = "export", export = "export",
    ["not"] = "note", note = "note",
    sessiz = "quiet", quiet = "quiet",
    ganimet = "loot", loot = "loot",
    sifirla = "reset", reset = "reset",
    dil = "lang", lang = "lang", language = "lang",
    tr = "tr", en = "en",
    yardim = "help", help = "help",
    minimap = "minimap", buton = "minimap", button = "minimap",
    bolum = "chapters", chapters = "chapters",
    gecmis = "history", history = "history",
    anlatici = "narrator", narrator = "narrator",
    soz = "motto", motto = "motto",
    kutuphane = "library", library = "library",
    paylas = "share", share = "share",
    debug = "debug",
}

local function Help()
    for _, line in ipairs(L.HELP) do
        Print(line)
    end
end

local function ChangeLanguage(code)
    if ns.SetLanguage(code) then
        Print(L.MSG_LANG_SET)
    else
        Print(L.MSG_LANG_USAGE)
    end
end

SLASH_KARAKTERANILARI1 = "/anilar"
SLASH_KARAKTERANILARI2 = "/ka"
SLASH_KARAKTERANILARI3 = "/memoir"
SlashCmdList.KARAKTERANILARI = function(msg)
    if not DB then return end
    local word, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    word = (word or ""):lower()
    local cmd = ALIASES[word]

    if word == "" then
        ns.ToggleUI()
    elseif cmd == "book" then
        ns.OpenBook()
    elseif cmd == "export" then
        ns.OpenExport("discord")
    elseif cmd == "note" then
        if rest ~= "" then ns.AddMemory("note", { text = rest }) else Print(L.MSG_NOTE_USAGE) end
    elseif cmd == "quiet" then
        DB.quiet = not DB.quiet
        Print(DB.quiet and L.MSG_QUIET_ON or L.MSG_QUIET_OFF)
    elseif cmd == "loot" then
        local q = tonumber(rest)
        if q and q >= 0 and q <= 5 then
            DB.lootMin = q
            Print(L.MSG_LOOT_SET:format(q))
        else
            Print(L.MSG_LOOT_HELP)
        end
    elseif cmd == "reset" and (rest:lower() == "evet" or rest:lower() == "yes") then
        wipe(DB.events); wipe(DB.zones); wipe(DB.bosses)
        DB.deaths = { total = 0, byZone = {} }
        DB.quests = 0
        StartBook()
        Print(L.MSG_RESET)
    elseif cmd == "lang" then
        ChangeLanguage(rest)
    elseif cmd == "tr" or cmd == "en" then
        ChangeLanguage(cmd)
    elseif cmd == "motto" then
        local low = rest:lower()
        if low == "sil" or low == "clear" then
            DB.motto = nil
            Print(L.MSG_MOTTO_CLEARED)
        elseif rest ~= "" then
            DB.motto = rest:sub(1, 140)
            Print(L.MSG_MOTTO_SET:format(DB.motto))
        else
            Print(DB.motto and L.MSG_MOTTO_SET:format(DB.motto) or L.MSG_MOTTO_USAGE)
        end
    elseif cmd == "library" then
        if ns.ToggleLibrary then ns.ToggleLibrary() end
    elseif cmd == "share" then
        local low = rest:lower()
        if low == "ac" or low == "on" then ns.settings.share = true
        elseif low == "kapat" or low == "off" then ns.settings.share = false
        else ns.settings.share = (ns.settings.share == false) end
        Print(ns.settings.share == false and L.MSG_SHARE_OFF or L.MSG_SHARE_ON)
    elseif cmd == "narrator" then
        local mode = ({ irk = "race", race = "race", sade = "plain", plain = "plain" })[rest:lower()]
        if mode then
            ns.settings.narrator = mode
            Print(mode == "plain" and L.MSG_NARRATOR_PLAIN or L.MSG_NARRATOR_RACE)
        else
            Print(L.MSG_NARRATOR_USAGE)
        end
    elseif cmd == "history" then
        ns.Backfill(true)
    elseif cmd == "chapters" then
        local mode = ({ ay = "month", month = "month", seviye = "level", level = "level" })[rest:lower()]
        if mode then
            ns.settings.chapters = mode
            Print(mode == "level" and L.MSG_CHAPTERS_LEVEL or L.MSG_CHAPTERS_MONTH)
        else
            Print(L.MSG_CHAPTERS_USAGE)
        end
    elseif cmd == "minimap" then
        local shown = ns.ToggleMinimapButton()
        Print(shown and L.MSG_MINIMAP_ON or L.MSG_MINIMAP_OFF)
    elseif cmd == "debug" then
        DB.debug = not DB.debug
        Print("Debug: " .. tostring(DB.debug))
    else
        Help()
    end
end
