-- Karakter Anıları / Character Memoir - Dil dosyası / Localization
-- Yeni bir dil eklemek için LOCALES içine bir tablo daha ekle.

local ADDON, ns = ...

-- WoW'un kendi fontlarında ş ve ğ yok. Bu yüzden addonla birlikte Türkçe destekli
-- DejaVu fontlarını getiriyoruz (Fonts/LICENSE-DejaVu.txt). Çince/Korece istemcilerde
-- bölge adları görünsün diye oyunun kendi fontu kullanılır.
local FONT_DIR = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\"
local CJK = { zhCN = true, zhTW = true, koKR = true }
if CJK[GetLocale()] then
    ns.FONT = STANDARD_TEXT_FONT or "Fonts\\ARIALN.TTF"
    ns.BOOK_FONT = ns.FONT
else
    ns.FONT = FONT_DIR .. "DejaVuSansCondensed.ttf"
    ns.BOOK_FONT = FONT_DIR .. "DejaVuSerifCondensed.ttf"
end

local LOCALES = {}
ns.LOCALES = LOCALES

----------------------------------------------------------------------
-- Buton yazıları: oyunun buton şablonu, fare üzerine gelince ya da vurgu
-- değişince yazı tipini kendi fontuna geri çevirebiliyor ve bazı butonlar boş
-- görünüyordu. Bu yüzden şablonun yazısını kullanmıyor, her butona kendi
-- etiketimizi koyuyoruz.
----------------------------------------------------------------------
local GOLD, WHITE, GRAY = { 1, 0.82, 0 }, { 1, 1, 1 }, { 0.5, 0.5, 0.5 }

local function LabelOf(b)
    if not b._label then
        b:SetText("")
        local fs = b:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetFont(ns.FONT, 12, "")
        fs:SetShadowOffset(1, -1)
        fs:SetWordWrap(false)
        fs:SetTextColor(unpack(GOLD))
        b._label = fs
    end
    return b._label
end

local function Recolor(b)
    local fs = LabelOf(b)
    if b._disabled then fs:SetTextColor(unpack(GRAY))
    elseif b._active then fs:SetTextColor(unpack(WHITE))
    else fs:SetTextColor(unpack(GOLD)) end
end

function ns.SetButtonLabel(b, text)
    LabelOf(b):SetText(text)
    Recolor(b)
end

-- Seçili filtre / biçim: vurgu + beyaz yazı
function ns.SetButtonActive(b, on)
    b._active = on and true or false
    if on then b:LockHighlight() else b:UnlockHighlight() end
    Recolor(b)
end

function ns.SetButtonEnabled(b, on)
    b._disabled = not on
    b:SetEnabled(on and true or false)
    Recolor(b)
end

----------------------------------------------------------------------
-- TÜRKÇE
----------------------------------------------------------------------
LOCALES.tr = {
    LANG_NAME = "Türkçe",
    ADDON_SHORT = "Anılar",
    UNKNOWN_PLACE = "bilinmeyen bir yer",
    MONTHS = { "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
               "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık" },

    -- Anı türleri
    TYPE_start = "Başlangıç", TYPE_level = "Seviye", TYPE_zone = "Keşif",
    TYPE_achievement = "Başarım", TYPE_loot = "Ganimet", TYPE_mount = "Binek",
    TYPE_boss = "Boss", TYPE_death = "Ölüm", TYPE_quest = "Görev", TYPE_note = "Not", TYPE_photo = "Fotoğraf",

    -- Defter ve sohbet metinleri (2. şahıs)
    MEM_start = "Anı defteri açıldı: %s, seviye %d %s. Başlangıç noktası: %s.",
    MEM_zone = "Yeni bir yer keşfettin: %s",
    MEM_level = "%d. seviyeye ulaştın!",
    MEM_level_dur = "%d. seviyeye ulaştın! (%s sürdü)",
    MEM_photo = "Bir anı fotoğrafladın.",
    MEM_photo_file = "Bir anı fotoğrafladın: %s",
    DUR_HM = "%d sa %d dk",
    DUR_M = "%d dk",
    LIST_AND = " ve ",
    MEM_death_first = "Hayatındaki ilk ölüm. Yer: %s",
    MEM_death_milestone = "Toplamda %d. kez öldün. Pes etmek yok!",
    MEM_death_zone = "%s seni ilk kez yere serdi.",
    MEM_quest = "%d. görevini tamamladın.",
    MEM_quest_title = "%d. görevini tamamladın: %s.",
    MEM_achievement = "Başarım kazandın: %s (%d puan)",
    MEM_mount = "Yeni binek: %s",
    MEM_boss = "%s ilk kez yenildi!",
    MEM_boss_diff = "%s ilk kez yenildi! (%s)",
    MEM_loot = "%s: %s",
    LOOTLABEL_0 = "Değersiz ganimet", LOOTLABEL_1 = "Sıradan ganimet",
    LOOTLABEL_2 = "Sıradışı ganimet", LOOTLABEL_3 = "Nadir ganimet",
    LOOTLABEL_4 = "Destansı ganimet", LOOTLABEL_5 = "Efsanevi ganimet",

    -- Kitap anlatımı (3. şahıs)
    BOOK_SUBTITLE = "Bir Kahramanın Anıları",
    BOOK_PROLOGUE = "Önsöz",
    BOOK_PROLOGUE_TEXT = "Bu hikâye %s tarihinde, %s diyarında başlar. O gün %s, %d. seviyede bir %s idi ve önünde yazılmayı bekleyen upuzun bir yol vardı.",
    BOOK_PROLOGUE_FALLBACK = "Bu hikâye, anı defterinin ilk sayfası açıldığı gün başlar.",
    BOOK_CHAPTER = "Bölüm %d · %s",
    BOOK_EPILOGUE = "Şimdilik Son",
    BOOK_EPILOGUE_TEXT = "Şimdiye dek %d farklı diyar gördü, %d görev tamamladı ve %d boss'u ilk kez yendi. %s Hikâyenin geri kalanı henüz yazılmadı...",
    BOOK_NO_DEATHS = "Bir kez bile ölmedi.",
    BOOK_DEATHS = "%d kez öldü, ama her seferinde yeniden ayağa kalktı.",
    NAR_note = "Günlüğüne şunu yazdı: \"%s\"",
    NAR_level = "%d. seviyeye ulaştı.",
    NAR_level_dur = "%d. seviyeye ulaştı; bu seviye %s sürdü.",
    NAR_levels = "%d seviye atlayarak %d. seviyeye ulaştı.",
    NAR_zones = "Yeni diyarlar keşfetti: %s.",
    NAR_photo_one = "O günü bir fotoğrafla ölümsüzleştirdi.",
    NAR_photos = "O gün %d fotoğraf çekti.",
    BOOK_CHAPTER_LEVEL = "Bölüm %d · Seviye %d–%d",
    BOOK_CHAPTER_PAST = "Bölüm %d · Defterden Önce",
    BOOK_PROLOGUE_PAST = "Bu defter %s tarihinde, %s diyarında açıldığında %s zaten %d. seviyede bir %s idi. Defterden önceki maceraları, yol boyunca kazandığı başarımlardan derlendi.",
    NAR_zone = "Yeni bir diyar keşfetti: %s.",
    NAR_achievement = "\"%s\" başarımıyla adını tarihe yazdırdı.",
    NAR_loot = "Eline %s bir ganimet geçti: %s.",
    NAR_loot_minor = "Ayrıca %d parça ekipman topladı.",
    NAR_loot_minor_one = "Ayrıca bir parça ekipman topladı.",
    QUALITY_0 = "değersiz", QUALITY_1 = "sıradan", QUALITY_2 = "sıradışı", QUALITY_3 = "nadir", QUALITY_4 = "destansı", QUALITY_5 = "efsanevi",
    NAR_mount = "Artık yeni bir bineği vardı: %s.",
    NAR_boss = "%s ilk kez onun karşısında diz çöktü.",
    NAR_boss_diff = "%s ilk kez onun karşısında diz çöktü (%s).",
    NAR_death_first = "%s topraklarında ilk kez öldü; ama ruhu yeniden ayağa kalktı.",
    NAR_death_milestone = "%d. ölümünü de geride bıraktı. Pes etmek ona göre değildi.",
    NAR_death_zone = "%s onu ilk kez yere serdi.",
    NAR_quest = "%d. görevini tamamladı.",
    NAR_quest_title = "%d. görevini tamamladı: \"%s\".",

    -- Arayüz
    UI_TITLE = "%s - Anı Defteri",
    UI_ALL = "Tümü",
    UI_STATS = "|cffffd100%d|r anı  •  |cff66ccff%d|r keşfedilen yer  •  |cffffff66%d|r görev  •  |cffff4040%d|r ilk boss zaferi",
    UI_DEATHS = "|cffaaaaaa%d|r ölüm",
    UI_DEADLIEST = "  •  En tehlikeli yer: |cffff8080%s|r (%d)",
    UI_STARTED = "  •  Defter açılışı: %s",
    UI_PLAYED = "  •  Oyun süresi: %s",
    UI_EMPTY = "Burada henüz bir anı yok. Maceraya devam!",
    UI_MORE = "(Daha eski anılar burada gösterilmiyor.)",
    BTN_READ_BOOK = "Kitabı Oku",
    BTN_EXPORT = "Dışa Aktar",
    BTN_PREV = "< Önceki",
    BTN_NEXT = "Sonraki >",
    BOOK_PAGE = "Sayfa %d / %d",
    EXPORT_TITLE = "Kitabı Dışa Aktar",
    EXPORT_HINT = "Metin seçili: |cffffd100Ctrl+C|r ile kopyala, Discord'a ya da bir belgeye yapıştır.",
    EXPORT_PLAIN = "Düz metin",
    EXPORT_LENGTH = "Uzunluk: %d karakter",
    EXPORT_DISCORD_WARN = "(Discord tek mesajda 2000 karakter alır; parça parça gönder.)",

    -- Minimap butonu
    MM_TITLE = "FallenMemoir · Karakter Anıları",
    MM_LEFT = "Sol tık: Anı defterini aç/kapat",
    MM_RIGHT = "Sağ tık: Kitabı aç/kapat",
    MM_DRAG = "Sürükle: Butonu taşı",
    MSG_MINIMAP_ON = "Minimap butonu gösteriliyor.",
    MSG_MINIMAP_OFF = "Minimap butonu gizlendi. Geri getirmek için: /anilar minimap",

    -- Komut mesajları
    MSG_NOTE_USAGE = "Kullanım: /anilar not <metin>",
    MSG_CHAPTERS_LEVEL = "Kitap bölümleri artık seviyeye göre (1–9, 10–19, ...).",
    MSG_CHAPTERS_MONTH = "Kitap bölümleri artık aylara göre.",
    MSG_CHAPTERS_USAGE = "Kullanım: /anilar bolum ay  veya  /anilar bolum seviye",
    MSG_HISTORY_ADDED = "Geçmişten %d başarım, kazanıldığı tarihlerle deftere eklendi.",
    TYPE_title = "Unvan",
    MEM_title = "Yeni bir unvan kazandın: %s",
    NAR_title = "Artık ona “{title}” deniyordu.",
    BOOK_TITLES = "Kazandığı unvanlar: {titles}.",
    TITLE_champion = "Azeroth'un Şampiyonu", TITLE_boss15 = "Efsane Avcısı",
    TITLE_quest500 = "Halkın Kahramanı", TITLE_explorer25 = "Diyarlar Kâşifi",
    TITLE_undying = "Ölümsüz", TITLE_spirit = "Ruh Şifacısının Dostu",
    TITLE_boss5 = "Zindan Fatihi", TITLE_treasure = "Hazine Avcısı",
    TITLE_quest100 = "Yardımsever", TITLE_explorer10 = "Gezgin",
    TITLE_photo10 = "Anıların Bekçisi", TITLE_bane = "{zone} Bedbahtı",
    SUM_TEXT = "{month}, {name} için {mood} bir aydı: {parts}.",
    SUM_levels = "{n} seviye atladı", SUM_levels_one = "bir seviye atladı",
    SUM_deaths = "{n} kez öldü", SUM_deaths_one = "bir kez öldü",
    SUM_quests = "{n} görev tamamladı", SUM_quests_one = "bir görev tamamladı",
    SUM_zone = "en çok {zone} topraklarında vakit geçirdi",
    MOOD_hard = "zorlu", MOOD_busy = "verimli", MOOD_calm = "sakin",
    LIB_TITLE = "Lonca Kütüphanesi",
    LIB_SEARCHING = "Loncada kitaplar aranıyor...",
    LIB_NONE = "Kitabını paylaşan kimse bulunamadı. Lonca arkadaşlarının da bu addonu kullanması gerekiyor.",
    LIB_NO_GUILD = "Bir loncada değilsin.",
    LIB_FOUND = "%d kitap bulundu. Okumak için birine tıkla.",
    LIB_REQUESTING = "İsteniyor: %s",
    LIB_RECEIVING = "Alınıyor: %d / %d",
    LIB_NOT_SHARING = "Bu oyuncu kitabını paylaşmıyor.",
    LIB_UNAVAILABLE = "Şu an lonca mesajları gönderilemiyor (zindanda ya da savaşta olabilirsin).",
    LIB_ROW = "%s · %d. seviye %s · %d anı",
    BTN_REFRESH = "Yenile", BTN_LIBRARY = "Kütüphane",
    EXPORT_JSON = "JSON (Bot)",
    MSG_SHARE_ON = "Kitabın lonca kütüphanesinde paylaşılıyor (notların hariç).",
    MSG_SHARE_OFF = "Kitabın artık paylaşılmıyor.",
    MSG_MOTTO_SET = "Kapak sözün: “%s”",
    MSG_MOTTO_CLEARED = "Kapak sözün silindi.",
    MSG_MOTTO_USAGE = "Kullanım: /anilar soz <cümle>  (silmek için: /anilar soz sil)",
    MSG_NARRATOR_RACE = "Anlatıcı: ırkına ve sınıfına göre (varsayılan).",
    MSG_NARRATOR_PLAIN = "Anlatıcı: sade.",
    MSG_NARRATOR_USAGE = "Kullanım: /anilar anlatici irk  veya  /anilar anlatici sade",
    MSG_HISTORY_NONE = "Deftere eklenecek yeni bir geçmiş başarım bulunamadı.",
    MSG_HISTORY_SCAN = "Tarama: %d kategori, %d başarım, %d tamamlanmış, %d bu karakterin, %d tarihli.",
    MSG_QUIET_ON = "Bildirimler kapatıldı.",
    MSG_QUIET_OFF = "Bildirimler açıldı.",
    MSG_LOOT_SET = "Ganimet kalitesi eşiği: %d",
    MSG_LOOT_HELP = "0=Gri, 1=Beyaz, 2=Yeşil, 3=Mavi, 4=Mor, 5=Efsanevi (varsayılan 0 = hepsi)",
    MSG_RESET = "Tüm anılar silindi, yeni bir sayfa açıldı.",
    MSG_LANG_SET = "Dil: Türkçe. (English: /anilar dil en)",
    MSG_LANG_USAGE = "Kullanım: /anilar dil tr  veya  /anilar dil en",
    MSG_ERROR = "Hata (%s): %s",
    HELP = {
        "Komutlar:",
        "  /anilar  - Anı defterini aç/kapat",
        "  /anilar kitap  - Hikâyeni kitap olarak oku",
        "  /anilar aktar  - Kitabı kopyalanabilir metin olarak dışa aktar",
        "  /anilar not <metin>  - Kendi anını ekle",
        "  /anilar sessiz  - Sohbet bildirimlerini aç/kapat",
        "  /anilar ganimet <0-5>  - Kaydedilecek en düşük ekipman kalitesi (0 = hepsi)",
        "  /anilar sifirla evet  - Bu karakterin tüm anılarını sil",
        "  /anilar bolum <ay|seviye>  - Kitap bölümlerini aya ya da seviyeye göre ayır",
        "  /anilar gecmis  - Defterden önceki başarımları tarihleriyle tekrar tara",
        "  /anilar anlatici <irk|sade>  - Kitabı ırkına özel anlatıcıyla ya da sade anlat",
        "  /anilar soz <cümle>  - Kitabın kapağına kendi sözünü yaz (sil: /anilar soz sil)",
        "  /anilar kutuphane  - Lonca arkadaşlarının kitaplarını oku",
        "  /anilar paylas <ac|kapat>  - Kitabını lonca kütüphanesinde paylaş",
        "  /anilar minimap  - Minimap butonunu göster/gizle",
        "  /anilar dil en  - Switch to English",
    },
}

----------------------------------------------------------------------
-- ENGLISH
----------------------------------------------------------------------
LOCALES.en = {
    LANG_NAME = "English",
    ADDON_SHORT = "Memoir",
    UNKNOWN_PLACE = "an unknown place",
    MONTHS = { "January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December" },

    TYPE_start = "Beginning", TYPE_level = "Level", TYPE_zone = "Discovery",
    TYPE_achievement = "Achievement", TYPE_loot = "Loot", TYPE_mount = "Mount",
    TYPE_boss = "Boss", TYPE_death = "Death", TYPE_quest = "Quest", TYPE_note = "Note", TYPE_photo = "Photo",

    MEM_start = "Memoir started: %s, level %d %s. The story begins in %s.",
    MEM_zone = "Discovered a new place: %s",
    MEM_level = "Reached level %d!",
    MEM_level_dur = "Reached level %d! (took %s)",
    MEM_photo = "You captured a moment.",
    MEM_photo_file = "You captured a moment: %s",
    DUR_HM = "%dh %dm",
    DUR_M = "%dm",
    LIST_AND = " and ",
    MEM_death_first = "Your very first death. Place: %s",
    MEM_death_milestone = "Death number %d. Never give up!",
    MEM_death_zone = "%s took you down for the first time.",
    MEM_quest = "Quest #%d completed.",
    MEM_quest_title = "Quest #%d completed: %s.",
    MEM_achievement = "Achievement earned: %s (%d points)",
    MEM_mount = "New mount: %s",
    MEM_boss = "%s defeated for the first time!",
    MEM_boss_diff = "%s defeated for the first time! (%s)",
    MEM_loot = "%s: %s",
    LOOTLABEL_0 = "Poor loot", LOOTLABEL_1 = "Common loot",
    LOOTLABEL_2 = "Uncommon loot", LOOTLABEL_3 = "Rare loot",
    LOOTLABEL_4 = "Epic loot", LOOTLABEL_5 = "Legendary loot",

    BOOK_SUBTITLE = "Memoirs of a Hero",
    BOOK_PROLOGUE = "Prologue",
    BOOK_PROLOGUE_TEXT = "This story begins on %s, in the lands of %s. That day, %s was a level %d %s, with a long road ahead still waiting to be written.",
    BOOK_PROLOGUE_FALLBACK = "This story begins on the day the first page of the memoir was opened.",
    BOOK_CHAPTER = "Chapter %d · %s",
    BOOK_EPILOGUE = "The End, For Now",
    BOOK_EPILOGUE_TEXT = "So far: %d lands seen, %d quests completed and %d bosses defeated for the first time. %s The rest of the story is yet to be written...",
    BOOK_NO_DEATHS = "Not a single death.",
    BOOK_DEATHS = "Died %d times, yet rose again every time.",
    NAR_note = "Wrote in the journal: \"%s\"",
    NAR_level = "Reached level %d.",
    NAR_level_dur = "Reached level %d after %s of play.",
    NAR_levels = "Gained %d levels, reaching level %d.",
    NAR_zones = "Discovered new lands: %s.",
    NAR_photo_one = "Captured the day in a screenshot.",
    NAR_photos = "Took %d screenshots that day.",
    BOOK_CHAPTER_LEVEL = "Chapter %d · Levels %d–%d",
    BOOK_CHAPTER_PAST = "Chapter %d · Before the Memoir",
    BOOK_PROLOGUE_PAST = "When this memoir was opened on %s, in %s, %s was already a level %d %s. The adventures before it were pieced together from the achievements earned along the way.",
    NAR_zone = "Discovered a new land: %s.",
    NAR_achievement = "Etched a name into history with \"%s\".",
    NAR_loot = "Claimed %s treasure: %s.",
    NAR_loot_minor = "Also picked up %d pieces of gear.",
    NAR_loot_minor_one = "Also picked up a piece of gear.",
    QUALITY_0 = "a poor", QUALITY_1 = "a common", QUALITY_2 = "an uncommon", QUALITY_3 = "a rare", QUALITY_4 = "an epic", QUALITY_5 = "a legendary",
    NAR_mount = "Gained a new mount: %s.",
    NAR_boss = "%s fell before our hero for the first time.",
    NAR_boss_diff = "%s fell before our hero for the first time (%s).",
    NAR_death_first = "Died for the first time in %s, but the spirit rose again.",
    NAR_death_milestone = "Left death number %d behind. Giving up was never an option.",
    NAR_death_zone = "%s brought our hero down for the first time.",
    NAR_quest = "Completed quest #%d.",
    NAR_quest_title = "Completed quest #%d: \"%s\".",

    UI_TITLE = "%s - Memoir",
    UI_ALL = "All",
    UI_STATS = "|cffffd100%d|r memories  •  |cff66ccff%d|r places discovered  •  |cffffff66%d|r quests  •  |cffff4040%d|r first boss kills",
    UI_DEATHS = "|cffaaaaaa%d|r deaths",
    UI_DEADLIEST = "  •  Deadliest place: |cffff8080%s|r (%d)",
    UI_STARTED = "  •  Started: %s",
    UI_PLAYED = "  •  Play time: %s",
    UI_EMPTY = "No memories here yet. Keep adventuring!",
    UI_MORE = "(Older memories are not shown here.)",
    BTN_READ_BOOK = "Read Book",
    BTN_EXPORT = "Export",
    BTN_PREV = "< Previous",
    BTN_NEXT = "Next >",
    BOOK_PAGE = "Page %d / %d",
    EXPORT_TITLE = "Export Book",
    EXPORT_HINT = "Text is selected: press |cffffd100Ctrl+C|r to copy, then paste into Discord or a document.",
    EXPORT_PLAIN = "Plain text",
    EXPORT_LENGTH = "Length: %d characters",
    EXPORT_DISCORD_WARN = "(Discord allows 2000 characters per message; send it in parts.)",

    MM_TITLE = "FallenMemoir · Character Memoir",
    MM_LEFT = "Left-click: Toggle memoir",
    MM_RIGHT = "Right-click: Toggle book",
    MM_DRAG = "Drag: Move button",
    MSG_MINIMAP_ON = "Minimap button shown.",
    MSG_MINIMAP_OFF = "Minimap button hidden. To bring it back: /memoir minimap",

    MSG_NOTE_USAGE = "Usage: /memoir note <text>",
    MSG_CHAPTERS_LEVEL = "Book chapters are now by level (1–9, 10–19, ...).",
    MSG_CHAPTERS_MONTH = "Book chapters are now by month.",
    MSG_CHAPTERS_USAGE = "Usage: /memoir chapters month  or  /memoir chapters level",
    MSG_HISTORY_ADDED = "%d past achievements were added to your memoir with their dates.",
    TYPE_title = "Title",
    MEM_title = "New title earned: %s",
    NAR_title = "From then on, they called {name} “{title}”.",
    BOOK_TITLES = "Titles earned: {titles}.",
    TITLE_champion = "Champion of Azeroth", TITLE_boss15 = "Legend Slayer",
    TITLE_quest500 = "Hero of the People", TITLE_explorer25 = "Pathfinder",
    TITLE_undying = "the Undying", TITLE_spirit = "Friend of the Spirit Healer",
    TITLE_boss5 = "Dungeon Conqueror", TITLE_treasure = "Treasure Hunter",
    TITLE_quest100 = "the Helpful", TITLE_explorer10 = "the Wanderer",
    TITLE_photo10 = "Keeper of Memories", TITLE_bane = "the Doomed of {zone}",
    SUM_TEXT = "{month} was a {mood} month for {name}: {parts}.",
    SUM_levels = "gained {n} levels", SUM_levels_one = "gained a level",
    SUM_deaths = "died {n} times", SUM_deaths_one = "died once",
    SUM_quests = "completed {n} quests", SUM_quests_one = "completed a quest",
    SUM_zone = "spent most of the time in {zone}",
    MOOD_hard = "hard", MOOD_busy = "productive", MOOD_calm = "quiet",
    LIB_TITLE = "Guild Library",
    LIB_SEARCHING = "Searching the guild for books...",
    LIB_NONE = "No one is sharing a book right now. Guildmates need this addon too.",
    LIB_NO_GUILD = "You are not in a guild.",
    LIB_FOUND = "%d books found. Click one to read.",
    LIB_REQUESTING = "Requesting: %s",
    LIB_RECEIVING = "Receiving: %d / %d",
    LIB_NOT_SHARING = "This player isn't sharing their book.",
    LIB_UNAVAILABLE = "Guild messages can't be sent right now (you may be in an instance or in combat).",
    LIB_ROW = "%s · level %d %s · %d memories",
    BTN_REFRESH = "Refresh", BTN_LIBRARY = "Library",
    EXPORT_JSON = "JSON (Bot)",
    MSG_SHARE_ON = "Your book is shared in the guild library (your notes excluded).",
    MSG_SHARE_OFF = "Your book is no longer shared.",
    MSG_MOTTO_SET = "Your cover motto: “%s”",
    MSG_MOTTO_CLEARED = "Your cover motto was removed.",
    MSG_MOTTO_USAGE = "Usage: /memoir motto <sentence>  (to remove: /memoir motto clear)",
    MSG_NARRATOR_RACE = "Narrator: by race and class (default).",
    MSG_NARRATOR_PLAIN = "Narrator: plain.",
    MSG_NARRATOR_USAGE = "Usage: /memoir narrator race  or  /memoir narrator plain",
    MSG_HISTORY_NONE = "No new past achievements found to add.",
    MSG_HISTORY_SCAN = "Scan: %d categories, %d achievements, %d completed, %d by this character, %d with a date.",
    MSG_QUIET_ON = "Notifications off.",
    MSG_QUIET_OFF = "Notifications on.",
    MSG_LOOT_SET = "Loot quality threshold: %d",
    MSG_LOOT_HELP = "0=Gray, 1=White, 2=Green, 3=Blue, 4=Epic, 5=Legendary (default 0 = all)",
    MSG_RESET = "All memories erased. A fresh page begins.",
    MSG_LANG_SET = "Language: English. (Türkçe: /memoir lang tr)",
    MSG_LANG_USAGE = "Usage: /memoir lang en  or  /memoir lang tr",
    MSG_ERROR = "Error (%s): %s",
    HELP = {
        "Commands:",
        "  /memoir  - Toggle the memoir window",
        "  /memoir book  - Read your story as a book",
        "  /memoir export  - Export the book as copyable text",
        "  /memoir note <text>  - Add your own memory",
        "  /memoir quiet  - Toggle chat notifications",
        "  /memoir loot <0-5>  - Minimum gear quality to record (0 = all)",
        "  /memoir reset yes  - Erase all memories for this character",
        "  /memoir chapters <month|level>  - Split book chapters by month or by level",
        "  /memoir history  - Rescan achievements earned before the memoir, with dates",
        "  /memoir narrator <race|plain>  - Tell the book in your race's voice, or plainly",
        "  /memoir motto <sentence>  - Write your own motto on the book cover (clear: /memoir motto clear)",
        "  /memoir library  - Read your guildmates' books",
        "  /memoir share <on|off>  - Share your book in the guild library",
        "  /memoir minimap  - Show/hide the minimap button",
        "  /memoir lang tr  - Türkçe'ye geç",
    },
}

----------------------------------------------------------------------
-- Dil seçimi / Language selection
----------------------------------------------------------------------
-- Varsayılan: Türkçe istemcide tr, diğerlerinde en. Kayıtlı seçim ADDON_LOADED'da uygulanır.
ns.lang = (GetLocale() == "trTR") and "tr" or "en"

ns.L = setmetatable({}, {
    __index = function(_, key)
        local v = (LOCALES[ns.lang] or LOCALES.en)[key]
        if v == nil then v = LOCALES.en[key] end
        if v == nil then return key end
        return v
    end,
})

local callbacks = {}
function ns.OnLanguageChanged(fn)
    callbacks[#callbacks + 1] = fn
end

-- Sohbet ve tooltip WoW'un kendi fontunu kullanır; orada ş/ğ/İ görünmez.
-- Bu yüzden sadece o alanlarda bu harfleri en yakın Latin harfe çeviriyoruz.
local FOLD = { ["ş"] = "s", ["Ş"] = "S", ["ğ"] = "g", ["Ğ"] = "G", ["İ"] = "I" }
function ns.GameFontSafe(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("\197\159", FOLD["ş"]):gsub("\197\158", FOLD["Ş"])
             :gsub("\196\159", FOLD["ğ"]):gsub("\196\158", FOLD["Ğ"])
             :gsub("\196\176", FOLD["İ"]))
end

function ns.SetLanguage(code)
    code = code and code:lower()
    if not LOCALES[code] then return false end
    ns.lang = code
    if ns.settings then ns.settings.lang = code end
    for _, fn in ipairs(callbacks) do pcall(fn) end
    return true
end
