-- Karakter Anıları / Character Memoir - Anlatıcı sesleri / Narrator voices
-- Kitap, karakterin ırkına göre farklı bir anlatıcının ağzından yazılır ve sınıfına
-- göre küçük dokunuşlar eklenir. Bir anahtarın değeri tablo ise, olayın zamanına
-- göre bir seçenek seçilir (aynı olay her açılışta aynı cümleyle anlatılır).
--
-- Yer tutucular: {name} {zone} {zones} {level} {count} {dur} {total} {boss}
--                {diffnote} {date} {raceclass} {quests} {bosses} {deaths}
-- Türkçe metinlerde yer tutucuların hemen arkasına ek getirmiyoruz (ör. "{zone}'da"),
-- çünkü ünlü uyumu isme göre değişir; bunun yerine "{zone} topraklarında" gibi yapılar.

local ADDON, ns = ...

local V = { tr = {}, en = {} }   -- ırk sesleri
local C = { tr = {}, en = {} }   -- sınıf dokunuşları
ns.VOICES, ns.CLASS_VOICES = V, C

----------------------------------------------------------------------
-- TÜRKÇE · IRKLAR
----------------------------------------------------------------------
V.tr.default = {
    SUBTITLE = "Bir Kahramanın Anıları",
    PROLOGUE = "Bu hikâye {date} tarihinde, {zone} diyarında başlar. O gün {name}, {level}. seviyede bir {raceclass} idi ve önünde yazılmayı bekleyen upuzun bir yol vardı.",
    PROLOGUE_PAST = "Bu defter {date} tarihinde, {zone} diyarında açıldığında {name} zaten {level}. seviyede bir {raceclass} idi. Defterden önceki maceraları, yol boyunca kazandığı başarımlardan derlendi.",
    ZONE = { "Yeni bir diyar keşfetti: {zone}." },
    ZONES = { "Yeni diyarlar keşfetti: {zones}." },
    LEVEL = { "{level}. seviyeye ulaştı." },
    LEVEL_DUR = { "{level}. seviyeye ulaştı; bu seviye {dur} sürdü.", "{dur} süren bir emeğin ardından {level}. seviyeye ulaştı.", "{level}. seviye; bu basamak {dur} sürdü." },
    LEVELS = { "{count} seviye atlayarak {level}. seviyeye ulaştı.", "{count} seviye birden atladı; artık {level}. seviyedeydi.", "Verimli bir gün: {count} seviye ve sonunda {level}. seviye." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez öldü; ama ruhu yeniden ayağa kalktı." },
    DEATH_MILESTONE = { "{total}. ölümünü de geride bıraktı. Pes etmek ona göre değildi." },
    DEATH_ZONE = { "{zone} onu ilk kez yere serdi." },
    BOSS = { "{boss} ilk kez onun karşısında diz çöktü{diffnote}.", "{boss} artık bir tehdit değildi{diffnote}." },
    EPILOGUE = "Şimdiye dek {zones} farklı diyar gördü, {quests} görev tamamladı ve {bosses} boss'u ilk kez yendi.",
    DEATHS = "{deaths} kez öldü, ama her seferinde yeniden ayağa kalktı.",
    NO_DEATHS = "Bir kez bile ölmedi.",
    END = "Hikâyenin geri kalanı henüz yazılmadı...",
}

-- Terk Edilmişler: kara mizah, sabır, ölümün ironisi
V.tr.Scourge = {
    SUBTITLE = "Bir Terk Edilmişin Kayıtları",
    PROLOGUE = "Ölüm, {name} için bir son değil, bir başlangıçtı. {date} tarihinde, {zone} topraklarında gözlerini yeniden açtığında {level}. seviyede bir {raceclass} idi. Kalbi atmıyordu; ama iradesi artık yalnızca kendisine aitti.",
    PROLOGUE_PAST = "Bu kayıtlar {date} tarihinde, {zone} topraklarında başladığında {name} çoktan {level}. seviyede bir {raceclass} idi. Mezardan sonraki ilk adımları unutulmuştu; ama kazandığı başarımlar geride iz bırakmıştı.",
    ZONE = {
        "Solgun gözleri yeni bir diyara değdi: {zone}.",
        "{zone}... Yaşayanların hâlâ korkuyla andığı bir yer. Artık Terk Edilmişlerin yolu da buradan geçiyordu.",
        "Çürüyen ayakları onu yeni bir diyara taşıdı: {zone}.",
    },
    ZONES = {
        "Yorulmak nedir bilmeyen bedeni bir günde birçok diyarı aştı: {zones}.",
        "Ölümsüz adımları onu sırasıyla şu diyarlara götürdü: {zones}.",
    },
    LEVEL = {
        "{level}. seviyeye ulaştı. Ölüm bile onu zayıflatamamıştı.",
        "Ölümsüz bedeni güçlendi: {level}. seviye.",
        "{level}. seviye. Lich King'in zincirlerinden uzaklaştıkça güçleniyordu.",
    },
    LEVEL_DUR = { "{dur} süren bir uğraşın sonunda {level}. seviyeye ulaştı. Zaman, ölüler için ucuzdu.", "{level}. seviye. Bunun için {dur} harcadı; ölüler acele etmez.", "{dur} sonra {level}. seviyeye ulaştı. Sabır, Terk Edilmişlerin en keskin silahıydı." },
    LEVELS = { "Bir gecede {count} seviye birden atladı ve {level}. seviyeye ulaştı. Yorgunluk, yaşayanlara özgü bir zayıflıktı.", "Ölümsüz bedeni durmak bilmedi: {count} seviye atladı ve {level}. seviyeye ulaştı.", "Mezarın soğuğu onu yavaşlatmadı; {count} seviye sonra artık {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ikinci kez öldü. İlki çok daha kalıcıydı." },
    DEATH_MILESTONE = { "{total}. kez yere düştü. Ruh şifacısı artık onu adıyla tanıyordu." },
    DEATH_ZONE = { "{zone} onu yeniden mezarına göndermeye çalıştı. Başaramadı." },
    BOSS = {
        "{boss} yere yığıldı{diffnote}. Belki bir gün o da Terk Edilmişlere katılırdı.",
        "{boss} ilk kez onun önünde düştü{diffnote}. Ölüler, sabırlı düşmanlardır.",
        "{boss} son nefesini verdi{diffnote}. {name} ise nefes almaya çoktan ihtiyaç duymuyordu.",
    },
    EPILOGUE = "Şimdiye dek {zones} diyar dolaştı, {quests} görev tamamladı ve {bosses} güçlü düşmanı ilk kez mezara gönderdi.",
    DEATHS = "{deaths} kez daha öldü; ama zaten ölü olanı durdurmak kolay değildir.",
    NO_DEATHS = "Bu hayatında bir kez bile ölmedi. Bir öncekinde ise bir kez yetmişti.",
    END = "Hikâyesi sürüyor; Terk Edilmişlerin vakti bol...",
}

-- Gece Elfleri: ay ışığı, Elune, kadim zaman, şiirsel
V.tr.NightElf = {
    SUBTITLE = "Elune'un Işığında Bir Yolculuk",
    PROLOGUE = "Ay ışığı {zone} topraklarını gümüşe boyarken, {date} tarihinde {name} adında {level}. seviyede bir {raceclass} yola çıktı. Kaldorei için on bin yıl bir göz kırpması kadar kısaydı; ama bu hikâye tam da o gece başladı.",
    PROLOGUE_PAST = "Bu satırlar {date} tarihinde, {zone} topraklarında yazılmaya başladığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki yolculuklarını, Elune'un tanıklık ettiği başarımlar anlatıyordu.",
    ZONE = {
        "Ay ışığı ona yeni bir yol gösterdi: {zone}.",
        "{zone} topraklarına adım attığında ağaçlar onu eski bir dost gibi selamladı.",
        "Rüzgârın fısıltısını izleyerek yeni bir diyara ulaştı: {zone}.",
    },
    ZONES = {
        "Gece boyunca gümüş patikalar onu şu diyarlara taşıdı: {zones}.",
        "Elune'un ışığı altında birçok yeni diyar gördü: {zones}.",
    },
    LEVEL = {
        "{level}. seviyeye ulaştı. Ruhunda kadim bir güç uyanıyordu.",
        "{level}. seviye. Yıldızlar, onun büyüyüşünü sessizce izledi.",
        "Ay bir kez daha doğdu ve {name} artık {level}. seviyedeydi.",
    },
    LEVEL_DUR = { "{dur} sonra {level}. seviyeye ulaştı. Ölümsüzlüğünü yitirmiş bir halk için zaman artık değerliydi.", "{dur} süren bir yolculuğun sonunda {level}. seviyeye ulaştı. Ağaçlar bile bu sabrı takdir ederdi.", "{level}. seviye. Ay ışığı altında geçen {dur} karşılığını vermişti." },
    LEVELS = { "Ay batmadan {count} seviye atladı ve {level}. seviyeye ulaştı.", "Yıldızlar yer değiştirirken {count} seviye atladı ve {level}. seviyeye ulaştı.", "Ormanın sessizliğinde {count} seviye daha; artık {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez düştü. Ruhu bir ışık perisi gibi ay ışığında süzüldü ve bedenine geri döndü." },
    DEATH_MILESTONE = { "{total}. kez düştü. Her seferinde Elune onu geri çağırdı." },
    DEATH_ZONE = { "{zone} ona ölümlü olduğunu bir kez daha hatırlattı." },
    BOSS = {
        "{boss} yenildi{diffnote}. Nöbetçilerin şarkıları bu zaferi anlatacaktı.",
        "{boss} ilk kez onun iradesi karşısında düştü{diffnote}.",
        "{boss} düştü{diffnote}. Ormanın dengesi yeniden kuruldu.",
    },
    EPILOGUE = "Şimdiye dek {zones} diyarda iz bıraktı, {quests} görev tamamladı ve {bosses} kudretli düşmanı ilk kez alt etti.",
    DEATHS = "{deaths} kez düştü; ama her şafakta yeniden kalktı.",
    NO_DEATHS = "Elune onu korudu; bir kez bile düşmedi.",
    END = "Ay yeniden doğacak ve hikâye sürecek...",
}

-- İnsanlar: vakayiname, ozanlar, cesaret
V.tr.Human = {
    SUBTITLE = "Stormwind Vakayinamesinden",
    PROLOGUE = "Kayıtlar gösteriyor ki {date} tarihinde, {zone} diyarında, {name} adında {level}. seviyede bir {raceclass} yüreğini ortaya koyup yola çıktı. İnsanların cesareti kısa ömürlerinden büyüktü; bu da onun hikâyesiydi.",
    PROLOGUE_PAST = "Bu vakayiname {date} tarihinde, {zone} diyarında açıldığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki yılları, kazandığı başarımlarla kayda geçti.",
    ZONE = {
        "Yolu onu yeni bir diyara çıkardı: {zone}.",
        "{zone} diyarına vardığında vakayinamede yeni bir sayfa açıldı.",
        "Haritasına yeni bir isim ekledi: {zone}.",
    },
    ZONES = { "Tek bir günde haritasına birçok isim ekledi: {zones}." },
    LEVEL = {
        "{level}. seviyeye ulaştı. Ozanlar adını öğrenmeye başlamıştı.",
        "{level}. seviye. Krallığın ona olan inancı büyüyordu.",
        "Emeğinin karşılığını aldı: {level}. seviye.",
    },
    LEVEL_DUR = { "{dur} süren bir çabanın ardından {level}. seviyeye ulaştı.", "{level}. seviye. Vakayinameye göre bu basamak {dur} sürdü.", "{dur} süren azimli bir çabayla {level}. seviyeye yükseldi." },
    LEVELS = { "Durmak bilmeden {count} seviye atladı ve {level}. seviyeye ulaştı.", "Ozanların yetişmekte zorlandığı bir gün: {count} seviye ve sonunda {level}. seviye.", "Krallık uyurken o durmadı; {count} seviye sonra {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez yere düştü. Ama bir ruh şifacısı onu Işık'a geri getirdi." },
    DEATH_MILESTONE = { "{total}. düşüşü de vakayinameye geçti. Her seferinde yeniden kalktı." },
    DEATH_ZONE = { "{zone} ona ağır bir ders verdi." },
    BOSS = {
        "{boss} yenildi{diffnote}! Stormwind'in meydanlarında bu zafer konuşulacaktı.",
        "{boss} ilk kez onun cesareti karşısında düştü{diffnote}.",
        "{boss} artık krallığı tehdit etmeyecekti{diffnote}.",
    },
    EPILOGUE = "Vakayinameye göre şimdiye dek {zones} diyar gördü, {quests} görev tamamladı ve {bosses} kudretli düşmanı ilk kez yendi.",
    DEATHS = "{deaths} kez düştü ve {deaths} kez yeniden kalktı.",
    NO_DEATHS = "Tek bir kez bile düşmedi; Işık onunla birlikteydi.",
    END = "Vakayinamenin geri kalanı henüz yazılmadı...",
}

-- Cüceler: Kâşifler Birliği, bira, taş, inat
V.tr.Dwarf = {
    SUBTITLE = "Kâşifler Birliği Kayıtları",
    PROLOGUE = "{date} tarihinde, {zone} diyarında, {name} adında {level}. seviyede bir {raceclass} sakalını düzeltti, birasını bitirdi ve yola koyuldu. Dağların çocukları için her macera, kazılmayı bekleyen bir hazineydi.",
    PROLOGUE_PAST = "Bu kayıtlar {date} tarihinde, {zone} diyarında tutulmaya başladığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki maceraları, taşa kazınmış rünler gibi kazandığı başarımlardan çıkarıldı.",
    ZONE = {
        "Kâşifler Birliği defterine yeni bir yer eklendi: {zone}.",
        "{zone}! Bir cüce için her yeni diyar, keşfedilmeyi bekleyen bir mağaradır.",
        "Sırt çantasını omzuna attı ve yeni bir diyara ulaştı: {zone}.",
    },
    ZONES = { "Bir günde birçok yeri haritaya geçirdi: {zones}. Akşam birası hak edilmişti." },
    LEVEL = {
        "{level}. seviyeye ulaştı! Bunu bir fıçı birayla kutlamak şarttı.",
        "{level}. seviye. Örs gibi sağlam, dağ gibi güçlü.",
        "Her darbede biraz daha güçlendi: {level}. seviye.",
    },
    LEVEL_DUR = { "{dur} süren sıkı bir çalışmanın ardından {level}. seviyeye ulaştı. Cüceler acele etmez, ama durmaz da.", "{level}. seviye. {dur} sürdü, ama cüce işi sağlam olur.", "{dur} boyunca kazdı, dövdü, savaştı; sonunda {level}. seviye." },
    LEVELS = { "Bir günde {count} seviye atladı ve {level}. seviyeye ulaştı. Ironforge'da bunun şerefine kadeh kaldırıldı.", "Bir fıçı bira bitmeden {count} seviye atladı ve {level}. seviyeye ulaştı.", "Taş taş üstüne: {count} seviye, ve şimdi {level}. seviye." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez yere serildi. Kalkınca ilk işi birasını aramak oldu." },
    DEATH_MILESTONE = { "{total}. kez yere düştü. Cüce kafası gerçekten de taştan yapılmıştı." },
    DEATH_ZONE = { "{zone} onu yere serdi. Bunu unutmayacaktı." },
    BOSS = {
        "{boss} devrildi{diffnote}! Bu hikâye Ironforge meyhanelerinde yıllarca anlatılacaktı.",
        "{boss} ilk kez onun cüce inadı karşısında düştü{diffnote}.",
        "{boss} yere serildi{diffnote}. Kâşifler Birliği bunu altın harflerle yazacaktı.",
    },
    EPILOGUE = "Kâşifler Birliği kayıtlarına göre şimdiye dek {zones} diyar keşfetti, {quests} görev tamamladı ve {bosses} kudretli düşmanı ilk kez devirdi.",
    DEATHS = "{deaths} kez yere düştü; ama bir cüceyi yerde tutmak imkânsızdır.",
    NO_DEATHS = "Bir kez bile düşmedi. Granit gibi sağlam!",
    END = "Kazı devam ediyor...",
}

-- Gnomlar: mucidin saha günlüğü, teknik ve esprili
V.tr.Gnome = {
    SUBTITLE = "Bir Mucidin Saha Günlüğü",
    PROLOGUE = "Günlük kaydı #1 · {date}. Konum: {zone}. Denek: {name}, {level}. seviye {raceclass}. Hedef: dünyayı keşfetmek, mümkünse patlamadan. Gnomeregan'ın onuru bu küçük omuzlardaydı.",
    PROLOGUE_PAST = "Günlük kaydı #1 · {date}, {zone}. Not: Denek {name}, kayıt başladığında zaten {level}. seviyede bir {raceclass} idi. Önceki veriler başarım arşivinden kurtarıldı.",
    ZONE = {
        "Yeni veri noktası: {zone}. Haritalama başarılı.",
        "Ulaşılan bölge: {zone}. Gözlem: ilginç, muhtemelen tehlikeli.",
        "Koordinatlar güncellendi: {zone}.",
    },
    ZONES = { "Verimli bir gün! Haritaya eklenen bölgeler: {zones}." },
    LEVEL = {
        "{level}. seviyeye ulaşıldı. Verimlilik artışı: kayda değer.",
        "{level}. seviye! Hesaplamalar doğrulandı.",
        "Sürüm güncellemesi: {name} v{level}.0",
    },
    LEVEL_DUR = { "{level}. seviyeye ulaşıldı. Geçen süre: {dur}. Bir sonraki deneyde optimize edilecek.", "{level}. seviye tamamlandı. Ölçülen süre: {dur}. Tolerans dahilinde.", "{dur} süren test döngüsü başarıyla kapandı: {level}. seviye." },
    LEVELS = { "Hızlandırılmış gelişim: {count} seviye atlandı, şu anki seviye {level}. Deney başarılı!", "Toplu güncelleme uygulandı: +{count} seviye. Yeni sürüm: {level}.", "Verim grafiği tavan yaptı: {count} seviye, şu an {level}. seviye." },
    DEATH_FIRST = { "Beklenmeyen sonuç: denek şu bölgede öldü: {zone}. Kendime not: bunu bir daha yapma." },
    DEATH_MILESTONE = { "{total}. ölüm kaydedildi. İstatistiksel olarak bu artık bir yöntem." },
    DEATH_ZONE = { "Ölümcül arıza. Bölge: {zone}. Rapor yazıldı." },
    BOSS = {
        "{boss} etkisiz hale getirildi{diffnote}. Deney başarılı!",
        "{boss} ilk kez yenildi{diffnote}. Sonuçlar beklentilerin üzerinde.",
        "{boss}: tehdit seviyesi sıfıra indirildi{diffnote}.",
    },
    EPILOGUE = "Özet rapor: {zones} bölge haritalandı, {quests} görev tamamlandı, {bosses} büyük tehdit ilk kez etkisiz hale getirildi.",
    DEATHS = "Toplam ölüm: {deaths}. Hepsi bilim uğruna.",
    NO_DEATHS = "Ölüm sayısı: sıfır. Kusursuz mühendislik.",
    END = "Deney devam ediyor...",
}

-- Orklar: onur, atalar, savaş davulları
V.tr.Orc = {
    SUBTITLE = "Horde İçin Yazılmış Bir Destan",
    PROLOGUE = "{date} tarihinde, {zone} topraklarında {name} adında {level}. seviyede bir {raceclass} yola çıktı. Ataların ruhları onu izliyordu. Lok'tar ogar!",
    PROLOGUE_PAST = "Bu destan {date} tarihinde, {zone} topraklarında yazılmaya başladığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki savaşları, kazandığı onurlarla anılır.",
    ZONE = {
        "Savaş yolu onu yeni topraklara götürdü: {zone}.",
        "{zone}! Horde'un adını buraya da taşıyacaktı.",
        "Yeni topraklar, yeni savaşlar: {zone}.",
    },
    ZONES = { "Bir günde birçok diyarı aştı: {zones}. Davullar onun adımlarıyla çaldı." },
    LEVEL = {
        "{level}. seviyeye ulaştı. Kanı daha da güçlü akıyordu.",
        "{level}. seviye. Atalar gururluydu.",
        "Savaşın ateşinde dövüldü: {level}. seviye.",
    },
    LEVEL_DUR = { "{dur} süren mücadelenin ardından {level}. seviyeye ulaştı. Onur, sabırla kazanılır.", "{level}. seviye. {dur} süren bir savaşın ödülü.", "{dur} kan ve terle geçti; sonunda {level}. seviye." },
    LEVELS = { "Durdurulamaz bir öfkeyle {count} seviye atladı ve {level}. seviyeye ulaştı.", "Savaş davulları susmadı: {count} seviye, ve şimdi {level}. seviye.", "Öfkesi dinmeden {count} seviye daha atladı; artık {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez düştü. Ama bir ork, ölüme bile meydan okur." },
    DEATH_MILESTONE = { "{total}. kez düştü. Her yara, yeni bir ders." },
    DEATH_ZONE = { "{zone} onu yere serdi. İntikam vakti gelecekti." },
    BOSS = {
        "{boss} yenildi{diffnote}! Zafer, Horde'undu.",
        "{boss} ilk kez onun öfkesi karşısında düştü{diffnote}. Lok'tar!",
        "{boss} yere düştü{diffnote}. Atalar bu zaferi duydu.",
    },
    EPILOGUE = "Şimdiye dek {zones} diyarda savaştı, {quests} görev tamamladı ve {bosses} güçlü düşmanı ilk kez yendi.",
    DEATHS = "{deaths} kez düştü; ama her seferinde daha güçlü kalktı.",
    NO_DEATHS = "Bir kez bile düşmedi. Gerçek bir savaş ustası.",
    END = "Davullar hâlâ çalıyor...",
}

-- Taurenler: sözlü gelenek, Toprak Ana, rüzgâr
V.tr.Tauren = {
    SUBTITLE = "Rüzgârın Taşıdığı Hikâye",
    PROLOGUE = "Yaşlılar şöyle anlatır: {date} tarihinde, {zone} topraklarında {name} adında {level}. seviyede bir {raceclass} yolculuğa başladı. Toprak Ana onun adımlarını hissetti ve rüzgâr bu hikâyeyi taşımaya söz verdi.",
    PROLOGUE_PAST = "Rüzgâr bu hikâyeyi {date} tarihinde, {zone} topraklarında taşımaya başladığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki yolları, kazandığı başarımlarda yaşar.",
    ZONE = {
        "Toynakları yeni bir toprağa bastı: {zone}.",
        "{zone} topraklarına vardığında rüzgâr yön değiştirdi.",
        "Toprak Ana ona yeni bir yer gösterdi: {zone}.",
    },
    ZONES = { "Rüzgârı izleyerek birçok yeni diyara ulaştı: {zones}." },
    LEVEL = {
        "{level}. seviyeye ulaştı. Toprak Ana ona güç verdi.",
        "{level}. seviye. Ruhu uzak dağlar kadar sağlamlaştı.",
        "Bir mevsim daha geçti ve {name} {level}. seviyeye ulaştı.",
    },
    LEVEL_DUR = { "{dur} süren sabırlı bir yolculukla {level}. seviyeye ulaştı. Taurenler acele etmez.", "{level}. seviye. {dur} süren sabırlı adımların karşılığı.", "{dur} boyunca yürüdü, dinledi, öğrendi; sonunda {level}. seviye." },
    LEVELS = { "Bir gün içinde {count} seviye atlayarak {level}. seviyeye ulaştı. Rüzgâr bile ona yetişemedi.", "Ovaların rüzgârı gibi hızlıydı: {count} seviye ve sonunda {level}. seviye.", "Toprak Ana'nın kucağında {count} seviye daha; artık {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez düştü. Toprak Ana onu kucakladı ve geri gönderdi." },
    DEATH_MILESTONE = { "{total}. kez düştü. Ruhlar onu her seferinde geri yolladı." },
    DEATH_ZONE = { "{zone} onu yere serdi. Kabile bundan ders alacaktı." },
    BOSS = {
        "{boss} yenildi{diffnote}. Bu zafer kamp ateşi başında anlatılacaktı.",
        "{boss} ilk kez onun gücü karşısında devrildi{diffnote}.",
        "{boss} devrildi{diffnote}. Totemlerin üzerine yeni bir çentik atıldı.",
    },
    EPILOGUE = "Rüzgârın anlattığına göre şimdiye dek {zones} diyar dolaştı, {quests} görev tamamladı ve {bosses} kudretli düşmanı ilk kez yendi.",
    DEATHS = "{deaths} kez düştü; Toprak Ana her seferinde onu geri gönderdi.",
    NO_DEATHS = "Bir kez bile düşmedi. Ataları onu koruyordu.",
    END = "Rüzgâr hâlâ esiyor ve hikâye sürüyor...",
}

-- Troller: Darkspear, loa'lar, vudu, "mon"
V.tr.Troll = {
    SUBTITLE = "Darkspear Kabilesinden Bir Hikâye",
    PROLOGUE = "Loa'lar fısıldıyordu, mon: {date} tarihinde, {zone} topraklarında {name} adında {level}. seviyede bir {raceclass} yolculuğa başladı. Ruhlar gülümsedi; hikâye başlamıştı.",
    PROLOGUE_PAST = "Loa'lar bu hikâyeyi {date} tarihinde, {zone} topraklarında anlatmaya başladığında {name} zaten {level}. seviyede bir {raceclass} idi. Önceki maceraları kazandığı başarımlarda saklı, mon.",
    ZONE = {
        "Yeni bir yer, yeni ruhlar: {zone}.",
        "{zone}! Loa'lar ona bu yolu gösterdi, mon.",
        "Sinsice ilerleyerek yeni bir diyara ulaştı: {zone}.",
    },
    ZONES = { "Ruhların peşinde bir günde birçok diyara uğradı: {zones}." },
    LEVEL = {
        "{level}. seviyeye ulaştı. Loa'lar memnundu, mon.",
        "{level}. seviye. Bunda güçlü bir vudu var!",
        "Ruhlar ona yeni bir güç fısıldadı: {level}. seviye.",
    },
    LEVEL_DUR = { "{dur} sonra {level}. seviyeye ulaştı. Sabırlı avcı, büyük avı yakalar.", "{level}. seviye. {dur} sürdü, ama ruhlar sabırlıdır, mon.", "{dur} boyunca avladı ve öğrendi; sonunda {level}. seviye." },
    LEVELS = { "Ruhların coşkusuyla {count} seviye atladı ve {level}. seviyeye ulaştı.", "Ruhlar dans etti, o da durmadı: {count} seviye ve şimdi {level}. seviye, mon.", "Loa'ların hediyesi: {count} seviye daha; artık {level}. seviyedeydi." },
    DEATH_FIRST = { "{zone} topraklarında ilk kez öldü. Loa'lar onu geri yolladı; işi henüz bitmemişti, mon." },
    DEATH_MILESTONE = { "{total}. kez öldü. Bwonsamdi bile artık onu tanıyordu." },
    DEATH_ZONE = { "{zone} onu yere serdi. Ruhlar bunu not etti." },
    BOSS = {
        "{boss} düştü{diffnote}! Kabile bu zaferi dans ederek kutlayacaktı.",
        "{boss} ilk kez onun vudusu karşısında yenildi{diffnote}, mon.",
        "{boss} yenildi{diffnote}. Bwonsamdi yeni bir ruh daha aldı, mon.",
    },
    EPILOGUE = "Şimdiye dek {zones} diyar dolaştı, {quests} görev tamamladı ve {bosses} güçlü düşmanı ilk kez yendi, mon.",
    DEATHS = "{deaths} kez öldü; ama loa'lar onu her seferinde geri gönderdi.",
    NO_DEATHS = "Bir kez bile ölmedi. Ruhlar onu iyi koruyor.",
    END = "Hikâye devam ediyor, mon...",
}

----------------------------------------------------------------------
-- ENGLISH · RACES
----------------------------------------------------------------------
V.en.default = {
    SUBTITLE = "Memoirs of a Hero",
    PROLOGUE = "This story begins on {date}, in the lands of {zone}. That day, {name} was a level {level} {raceclass}, with a long road ahead still waiting to be written.",
    PROLOGUE_PAST = "When this memoir was opened on {date}, in {zone}, {name} was already a level {level} {raceclass}. The adventures before it were pieced together from the achievements earned along the way.",
    ZONE = { "Discovered a new land: {zone}." },
    ZONES = { "Discovered new lands: {zones}." },
    LEVEL = { "Reached level {level}." },
    LEVEL_DUR = { "Reached level {level} after {dur} of play.", "After {dur} of effort, reached level {level}.", "Level {level}; this step took {dur}." },
    LEVELS = { "Gained {count} levels, reaching level {level}.", "{count} levels in one go; now level {level}.", "A productive day: {count} levels, ending at level {level}." },
    DEATH_FIRST = { "Died for the first time in {zone}, but the spirit rose again." },
    DEATH_MILESTONE = { "Left death number {total} behind. Giving up was never an option." },
    DEATH_ZONE = { "{zone} brought our hero down for the first time." },
    BOSS = { "{boss} fell before our hero for the first time{diffnote}.", "{boss} was no longer a threat{diffnote}." },
    EPILOGUE = "So far: {zones} lands seen, {quests} quests completed and {bosses} bosses defeated for the first time.",
    DEATHS = "Died {deaths} times, yet rose again every time.",
    NO_DEATHS = "Not a single death.",
    END = "The rest of the story is yet to be written...",
}

V.en.Scourge = {
    SUBTITLE = "Records of the Forsaken",
    PROLOGUE = "For {name}, death was not an ending but a beginning. On {date}, in the lands of {zone}, a level {level} {raceclass} opened their eyes once more. The heart no longer beat, but the will was finally their own.",
    PROLOGUE_PAST = "When these records began on {date}, in {zone}, {name} was already a level {level} {raceclass}. The first steps after the grave were forgotten, but the achievements left their mark.",
    ZONE = {
        "Pale eyes fell upon a new land: {zone}.",
        "{zone}... a place the living still speak of in fear. Now it lay on the path of the Forsaken.",
        "Rotting feet carried {name} to a new land: {zone}.",
    },
    ZONES = {
        "A body that never tires crossed many lands in a single day: {zones}.",
        "Undead steps wandered through {zones}.",
    },
    LEVEL = {
        "Reached level {level}. Not even death could make {name} weaker.",
        "The undead body grew stronger: level {level}.",
        "Level {level}. The farther from the Lich King's chains, the greater the strength.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur} of toil. Time is cheap for the dead.", "Level {level}. It took {dur}; the dead are never in a hurry.", "Reached level {level} after {dur}. Patience is the sharpest weapon of the Forsaken." },
    LEVELS = { "Gained {count} levels in a single night, reaching level {level}. Fatigue is a weakness of the living.", "The undead body knew no rest: {count} levels, reaching level {level}.", "The chill of the grave did not slow {name}; {count} levels later, level {level}." },
    DEATH_FIRST = { "Died in {zone} for the second time. The first one was far more permanent." },
    DEATH_MILESTONE = { "Fell for the {total}th time. The spirit healer now knew {name} by name." },
    DEATH_ZONE = { "{zone} tried to send {name} back to the grave. It failed." },
    BOSS = {
        "{boss} collapsed{diffnote}. Perhaps one day it would join the Forsaken too.",
        "{boss} fell before {name} for the first time{diffnote}. The dead are patient enemies.",
        "{boss} drew a last breath{diffnote}. {name} had long stopped needing one.",
    },
    EPILOGUE = "So far: {zones} lands wandered, {quests} quests completed and {bosses} mighty foes sent to the grave for the first time.",
    DEATHS = "Died {deaths} more times; but it is hard to stop someone who is already dead.",
    NO_DEATHS = "Not a single death in this life. In the previous one, once was enough.",
    END = "The story goes on, for the Forsaken have all the time in the world...",
}

V.en.NightElf = {
    SUBTITLE = "A Journey in Elune's Light",
    PROLOGUE = "As moonlight silvered the lands of {zone} on {date}, a level {level} {raceclass} named {name} set out. To the kaldorei, ten thousand years pass like the blink of an eye; but this story began on that very night.",
    PROLOGUE_PAST = "When these lines began on {date}, in {zone}, {name} was already a level {level} {raceclass}. The journeys before were told by achievements Elune herself had witnessed.",
    ZONE = {
        "Moonlight revealed a new path: {zone}.",
        "Stepping into {zone}, the trees greeted {name} like an old friend.",
        "Following the whisper of the wind, {name} reached a new land: {zone}.",
    },
    ZONES = {
        "Through the night, silver paths led on to {zones}.",
        "Under Elune's light, many new lands were seen: {zones}.",
    },
    LEVEL = {
        "Reached level {level}. An ancient power stirred within.",
        "Level {level}. The stars watched in silence as {name} grew.",
        "The moon rose once more, and {name} was now level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur}. For a people who lost their immortality, time had become precious.", "After a journey of {dur}, reached level {level}. Even the trees would admire such patience.", "Level {level}. The {dur} spent beneath the moon had paid off." },
    LEVELS = { "Before the moon set, {count} levels were gained, reaching level {level}.", "As the stars wheeled overhead, {count} levels were gained, reaching level {level}.", "In the quiet of the forest, {count} more levels; now level {level}." },
    DEATH_FIRST = { "Fell for the first time in {zone}. The spirit drifted like a wisp through the moonlight before returning." },
    DEATH_MILESTONE = { "Fell for the {total}th time. Each time, Elune called {name} back." },
    DEATH_ZONE = { "{zone} was a reminder of mortality, once again." },
    BOSS = {
        "{boss} was defeated{diffnote}. The Sentinels would sing of this victory.",
        "{boss} fell for the first time before the will of {name}{diffnote}.",
        "{boss} fell{diffnote}. The balance of the forest was restored.",
    },
    EPILOGUE = "So far: footprints left in {zones} lands, {quests} quests completed and {bosses} mighty foes overcome for the first time.",
    DEATHS = "Fell {deaths} times, yet rose again with every dawn.",
    NO_DEATHS = "Elune kept watch; not a single fall.",
    END = "The moon will rise again, and the story will go on...",
}

V.en.Human = {
    SUBTITLE = "From the Chronicles of Stormwind",
    PROLOGUE = "The chronicles record that on {date}, in {zone}, a level {level} {raceclass} named {name} set out with a brave heart. The courage of humankind was greater than its short years, and this was {name}'s story.",
    PROLOGUE_PAST = "When this chronicle opened on {date}, in {zone}, {name} was already a level {level} {raceclass}. The earlier years entered the record through the achievements earned.",
    ZONE = {
        "The road led to a new land: {zone}.",
        "Arriving in {zone}, a new page of the chronicle was turned.",
        "A new name was added to the map: {zone}.",
    },
    ZONES = { "In a single day, many names were added to the map: {zones}." },
    LEVEL = {
        "Reached level {level}. The bards were beginning to learn the name {name}.",
        "Level {level}. The kingdom's faith in {name} grew.",
        "Hard work paid off: level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur} of effort.", "Level {level}. The chronicle notes this step took {dur}.", "With {dur} of determined effort, rose to level {level}." },
    LEVELS = { "Without rest, {count} levels were gained, reaching level {level}.", "A day the bards struggled to keep up with: {count} levels, ending at level {level}.", "While the kingdom slept, {name} pressed on; {count} levels later, level {level}." },
    DEATH_FIRST = { "Fell for the first time in {zone}. But a spirit healer brought {name} back to the Light." },
    DEATH_MILESTONE = { "The {total}th fall entered the chronicle. Each time, {name} rose again." },
    DEATH_ZONE = { "{zone} taught a hard lesson." },
    BOSS = {
        "{boss} was defeated{diffnote}! This victory would be told in the squares of Stormwind.",
        "{boss} fell for the first time before the courage of {name}{diffnote}.",
        "{boss} would threaten the kingdom no more{diffnote}.",
    },
    EPILOGUE = "According to the chronicle: {zones} lands seen, {quests} quests completed and {bosses} mighty foes defeated for the first time.",
    DEATHS = "Fell {deaths} times, and rose {deaths} times.",
    NO_DEATHS = "Not a single fall; the Light was with {name}.",
    END = "The rest of the chronicle is yet to be written...",
}

V.en.Dwarf = {
    SUBTITLE = "Records of the Explorers' League",
    PROLOGUE = "On {date}, in {zone}, a level {level} {raceclass} named {name} straightened the beard, finished the ale and hit the road. For the children of the mountain, every adventure is a treasure waiting to be dug up.",
    PROLOGUE_PAST = "When these records began on {date}, in {zone}, {name} was already a level {level} {raceclass}. The earlier adventures were unearthed from the achievements earned, like runes carved in stone.",
    ZONE = {
        "A new site for the Explorers' League ledger: {zone}.",
        "{zone}! To a dwarf, every new land is a cave waiting to be explored.",
        "Pack on the shoulder, {name} reached a new land: {zone}.",
    },
    ZONES = { "Many places were mapped in a single day: {zones}. The evening ale was well earned." },
    LEVEL = {
        "Reached level {level}! That called for a whole keg.",
        "Level {level}. Solid as an anvil, strong as a mountain.",
        "Every blow made {name} a little stronger: level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur} of hard work. Dwarves don't rush, but they don't stop either.", "Level {level}. It took {dur}, but dwarven work is built to last.", "{dur} of digging, forging and fighting; at last, level {level}." },
    LEVELS = { "Gained {count} levels in a day, reaching level {level}. Ironforge raised a mug in honor.", "Before the keg ran dry, {count} levels were gained, reaching level {level}.", "Stone upon stone: {count} levels, and now level {level}." },
    DEATH_FIRST = { "Knocked down for the first time in {zone}. The first thing {name} did after getting up was look for the ale." },
    DEATH_MILESTONE = { "Fell for the {total}th time. A dwarven skull truly is made of stone." },
    DEATH_ZONE = { "{zone} knocked {name} down. That would not be forgotten." },
    BOSS = {
        "{boss} was toppled{diffnote}! This tale would be told in Ironforge's taverns for years.",
        "{boss} fell for the first time before sheer dwarven stubbornness{diffnote}.",
        "{boss} hit the ground{diffnote}. The Explorers' League would write this in gold.",
    },
    EPILOGUE = "According to the Explorers' League: {zones} lands explored, {quests} quests completed and {bosses} mighty foes toppled for the first time.",
    DEATHS = "Fell {deaths} times; but keeping a dwarf down is impossible.",
    NO_DEATHS = "Not a single fall. Solid as granite!",
    END = "The dig continues...",
}

V.en.Gnome = {
    SUBTITLE = "An Inventor's Field Journal",
    PROLOGUE = "Journal entry #1 · {date}. Location: {zone}. Subject: {name}, level {level} {raceclass}. Objective: explore the world, preferably without exploding. The honor of Gnomeregan rested on these small shoulders.",
    PROLOGUE_PAST = "Journal entry #1 · {date}, {zone}. Note: subject {name} was already a level {level} {raceclass} when recording began. Earlier data recovered from the achievement archive.",
    ZONE = {
        "New data point: {zone}. Mapping successful.",
        "Arrived in {zone}. Observation: interesting, probably dangerous.",
        "Coordinates updated: {zone}.",
    },
    ZONES = { "A productive day! Regions added to the map: {zones}." },
    LEVEL = {
        "Reached level {level}. Efficiency gain: significant.",
        "Level {level}! Calculations confirmed.",
        "Version update: {name} v{level}.0",
    },
    LEVEL_DUR = { "Reached level {level}. Elapsed time: {dur}. To be optimized in the next experiment.", "Level {level} complete. Measured time: {dur}. Within tolerance.", "A {dur} test cycle closed successfully: level {level}." },
    LEVELS = { "Accelerated development: {count} levels gained, current level {level}. Experiment successful!", "Batch update applied: +{count} levels. New version: {level}.", "The efficiency chart went off the scale: {count} levels, now level {level}." },
    DEATH_FIRST = { "Unexpected result: subject died in {zone}. Note to self: don't do that again." },
    DEATH_MILESTONE = { "Death #{total} recorded. Statistically, this is now a method." },
    DEATH_ZONE = { "Fatal malfunction in {zone}. Report filed." },
    BOSS = {
        "{boss} neutralized{diffnote}. Experiment successful!",
        "{boss} defeated for the first time{diffnote}. Results exceeded expectations.",
        "{boss}: threat level reduced to zero{diffnote}.",
    },
    EPILOGUE = "Summary report: {zones} regions mapped, {quests} quests completed, {bosses} major threats neutralized for the first time.",
    DEATHS = "Total deaths: {deaths}. All in the name of science.",
    NO_DEATHS = "Death count: zero. Flawless engineering.",
    END = "Experiment ongoing...",
}

V.en.Orc = {
    SUBTITLE = "A Saga Written for the Horde",
    PROLOGUE = "On {date}, in the lands of {zone}, a level {level} {raceclass} named {name} set out. The spirits of the ancestors were watching. Lok'tar ogar!",
    PROLOGUE_PAST = "When this saga began on {date}, in {zone}, {name} was already a level {level} {raceclass}. The earlier battles are remembered through the honors earned.",
    ZONE = {
        "The warpath led to new lands: {zone}.",
        "{zone}! The name of the Horde would be carried here too.",
        "New lands, new battles: {zone}.",
    },
    ZONES = { "Many lands were crossed in a single day: {zones}. The drums beat with every step." },
    LEVEL = {
        "Reached level {level}. The blood ran stronger.",
        "Level {level}. The ancestors were proud.",
        "Forged in the fire of battle: level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur} of struggle. Honor is earned with patience.", "Level {level}. The reward of a {dur} battle.", "{dur} of blood and sweat; at last, level {level}." },
    LEVELS = { "With unstoppable fury, {count} levels were gained, reaching level {level}.", "The war drums never stopped: {count} levels, and now level {level}.", "Fury unspent, {count} more levels; now level {level}." },
    DEATH_FIRST = { "Fell for the first time in {zone}. But an orc defies even death." },
    DEATH_MILESTONE = { "Fell for the {total}th time. Every wound, a new lesson." },
    DEATH_ZONE = { "{zone} brought {name} down. The time for vengeance would come." },
    BOSS = {
        "{boss} was defeated{diffnote}! Victory belonged to the Horde.",
        "{boss} fell for the first time before the fury of {name}{diffnote}. Lok'tar!",
        "{boss} hit the dirt{diffnote}. The ancestors heard of this victory.",
    },
    EPILOGUE = "So far: battles fought across {zones} lands, {quests} quests completed and {bosses} mighty foes defeated for the first time.",
    DEATHS = "Fell {deaths} times; yet rose stronger every time.",
    NO_DEATHS = "Not a single fall. A true master of war.",
    END = "The drums still beat...",
}

V.en.Tauren = {
    SUBTITLE = "A Tale Carried by the Wind",
    PROLOGUE = "The elders tell it this way: on {date}, in the lands of {zone}, a level {level} {raceclass} named {name} began a journey. The Earth Mother felt those steps, and the wind promised to carry this tale.",
    PROLOGUE_PAST = "When the wind began carrying this tale on {date}, in {zone}, {name} was already a level {level} {raceclass}. The earlier roads live on in the achievements earned.",
    ZONE = {
        "Hooves touched new ground: {zone}.",
        "Upon reaching {zone}, the wind changed direction.",
        "The Earth Mother revealed a new place: {zone}.",
    },
    ZONES = { "Following the wind, many new lands were reached: {zones}." },
    LEVEL = {
        "Reached level {level}. The Earth Mother lent her strength.",
        "Level {level}. The spirit grew as steady as the distant mountains.",
        "Another season passed, and {name} reached level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after a patient journey of {dur}. The tauren do not hurry.", "Level {level}. The reward of {dur} of patient steps.", "{dur} of walking, listening and learning; at last, level {level}." },
    LEVELS = { "Gained {count} levels in a single day, reaching level {level}. Even the wind could not keep up.", "Swift as the wind of the plains: {count} levels, ending at level {level}.", "In the Earth Mother's embrace, {count} more levels; now level {level}." },
    DEATH_FIRST = { "Fell for the first time in {zone}. The Earth Mother embraced {name} and sent them back." },
    DEATH_MILESTONE = { "Fell for the {total}th time. The spirits sent {name} back every time." },
    DEATH_ZONE = { "{zone} brought {name} down. The tribe would learn from this." },
    BOSS = {
        "{boss} was defeated{diffnote}. This victory would be told around the campfire.",
        "{boss} was toppled for the first time by the strength of {name}{diffnote}.",
        "{boss} was toppled{diffnote}. A new notch was carved into the totems.",
    },
    EPILOGUE = "As the wind tells it: {zones} lands wandered, {quests} quests completed and {bosses} mighty foes defeated for the first time.",
    DEATHS = "Fell {deaths} times; each time the Earth Mother sent {name} back.",
    NO_DEATHS = "Not a single fall. The ancestors kept watch.",
    END = "The wind still blows, and the tale goes on...",
}

V.en.Troll = {
    SUBTITLE = "A Tale of the Darkspear",
    PROLOGUE = "The loa were whispering, mon: on {date}, in the lands of {zone}, a level {level} {raceclass} named {name} began a journey. The spirits smiled; the story had begun.",
    PROLOGUE_PAST = "When the loa began telling this tale on {date}, in {zone}, {name} was already a level {level} {raceclass}. The earlier adventures hide in the achievements earned, mon.",
    ZONE = {
        "New place, new spirits: {zone}.",
        "{zone}! The loa showed this path, mon.",
        "Moving quietly, {name} reached a new land: {zone}.",
    },
    ZONES = { "Following the spirits, many lands were visited in one day: {zones}." },
    LEVEL = {
        "Reached level {level}. The loa were pleased, mon.",
        "Level {level}. Strong voodoo in this one!",
        "The spirits whispered new power: level {level}.",
    },
    LEVEL_DUR = { "Reached level {level} after {dur}. The patient hunter catches the biggest prey.", "Level {level}. It took {dur}, but the spirits are patient, mon.", "{dur} of hunting and learning; at last, level {level}." },
    LEVELS = { "Gained {count} levels in the spirits' frenzy, reaching level {level}.", "The spirits danced and so did {name}: {count} levels, now level {level}, mon.", "A gift from the loa: {count} more levels; now level {level}." },
    DEATH_FIRST = { "Died for the first time in {zone}. The loa sent {name} back; the work wasn't done yet, mon." },
    DEATH_MILESTONE = { "Died for the {total}th time. Even Bwonsamdi knew {name} by now." },
    DEATH_ZONE = { "{zone} brought {name} down. The spirits took note." },
    BOSS = {
        "{boss} fell{diffnote}! The tribe would celebrate this victory with dancing.",
        "{boss} was defeated for the first time by the voodoo of {name}{diffnote}, mon.",
        "{boss} was defeated{diffnote}. Bwonsamdi claimed one more soul, mon.",
    },
    EPILOGUE = "So far: {zones} lands wandered, {quests} quests completed and {bosses} mighty foes defeated for the first time, mon.",
    DEATHS = "Died {deaths} times; but the loa sent {name} back every time.",
    NO_DEATHS = "Not a single death. The spirits protect this one well.",
    END = "The story goes on, mon...",
}

----------------------------------------------------------------------
-- SINIFLAR / CLASSES
-- INTRO: önsöze eklenen bir cümle. MILESTONE: 10, 20, 30... seviyelerde eklenir.
----------------------------------------------------------------------
C.tr = {
    WARRIOR = { INTRO = "Silahı ağır, iradesi ondan da ağırdı.",
        MILESTONE = { "{level}. seviyede kas ve çelik bir oldu.", "{level}. seviye: artık savaş meydanlarında adı korkuyla anılıyordu." } },
    PALADIN = { INTRO = "Işık onun yolunu aydınlatıyordu.",
        MILESTONE = { "{level}. seviyede Işık'a olan inancı daha da derinleşti.", "{level}. seviye: kalkanı artık yalnızca kendisini değil, başkalarını da koruyordu." } },
    HUNTER = { INTRO = "Yanında sadık bir yoldaş, elinde nişanı şaşmayan bir silah vardı.",
        MILESTONE = { "{level}. seviyede vahşi doğa onu kendinden biri saydı.", "{level}. seviye: hiçbir av artık ondan kaçamıyordu." } },
    ROGUE = { INTRO = "Gölgeler onun en yakın dostuydu.",
        MILESTONE = { "{level}. seviyede gölgeler onu daha iyi saklıyordu.", "{level}. seviye: hançerleri artık iz bırakmadan konuşuyordu." } },
    PRIEST = { INTRO = "Duaları hem iyileştirebilir hem de cezalandırabilirdi.",
        MILESTONE = { "{level}. seviyede inancı bir kalkan kadar sağlamlaştı.", "{level}. seviye: dokunduğu yaralar artık daha hızlı kapanıyordu." } },
    SHAMAN = { INTRO = "Elementler onun çağrısına kulak veriyordu.",
        MILESTONE = { "{level}. seviyede toprak, ateş, su ve hava onu daha iyi tanıdı.", "{level}. seviye: totemleri artık fırtınaları bile çağırabiliyordu." } },
    MAGE = { INTRO = "Parmak uçlarında gizemli güçler kıvılcımlanıyordu.",
        MILESTONE = { "{level}. seviyede büyü kitabına yeni sayfalar eklendi.", "{level}. seviye: arcane güçler onun iradesine boyun eğiyordu." } },
    WARLOCK = { INTRO = "Yasak bilgiler ve fısıldayan gölgeler onun yoldaşıydı.",
        MILESTONE = { "{level}. seviyede iblisler onun adını öğrenmişti.", "{level}. seviye: ruh taşları her geçen gün ağırlaşıyordu." } },
    DRUID = { INTRO = "Doğanın bin bir yüzünü içinde taşıyordu.",
        MILESTONE = { "{level}. seviyede doğa ona yeni biçimler öğretti.", "{level}. seviye: ormanın kalbi onunla birlikte atıyordu." } },
    DEATHKNIGHT = { INTRO = "Lich King'in zincirlerinden kurtulmuştu, ama soğuk hâlâ içindeydi.",
        MILESTONE = { "{level}. seviyede rün kılıcı daha fazlasına acıktı." } },
    MONK = { INTRO = "Dengesi kusursuz, yumrukları affetmezdi.",
        MILESTONE = { "{level}. seviyede chi'si hiç olmadığı kadar güçlü akıyordu." } },
    DEMONHUNTER = { INTRO = "Gözleri bağlıydı, ama hiçbir şey ondan saklanamazdı.",
        MILESTONE = { "{level}. seviyede içindeki fel enerjisini zaptetmek zorlaştı." } },
    EVOKER = { INTRO = "Ejderlerin kadim gücü damarlarında akıyordu.",
        MILESTONE = { "{level}. seviyede ejder alevi daha parlak yandı." } },
}

C.en = {
    WARRIOR = { INTRO = "The weapon was heavy, the will heavier still.",
        MILESTONE = { "At level {level}, muscle and steel became one.", "Level {level}: the name was now spoken with fear on the battlefield." } },
    PALADIN = { INTRO = "The Light illuminated the path.",
        MILESTONE = { "At level {level}, faith in the Light grew deeper.", "Level {level}: the shield now protected not only {name}, but others too." } },
    HUNTER = { INTRO = "A loyal companion at the side, a weapon that never missed in hand.",
        MILESTONE = { "At level {level}, the wild accepted {name} as one of its own.", "Level {level}: no prey could escape anymore." } },
    ROGUE = { INTRO = "The shadows were the closest of friends.",
        MILESTONE = { "At level {level}, the shadows hid {name} even better.", "Level {level}: the daggers now spoke without leaving a trace." } },
    PRIEST = { INTRO = "Those prayers could both heal and punish.",
        MILESTONE = { "At level {level}, faith became as solid as a shield.", "Level {level}: every wound touched now closed faster." } },
    SHAMAN = { INTRO = "The elements answered the call.",
        MILESTONE = { "At level {level}, earth, fire, water and air knew {name} better.", "Level {level}: the totems could now call even storms." } },
    MAGE = { INTRO = "Mysterious power crackled at the fingertips.",
        MILESTONE = { "At level {level}, new pages were added to the spellbook.", "Level {level}: arcane power bent to the caster's will." } },
    WARLOCK = { INTRO = "Forbidden knowledge and whispering shadows were constant companions.",
        MILESTONE = { "At level {level}, the demons had learned the name {name}.", "Level {level}: the soul shards grew heavier by the day." } },
    DRUID = { INTRO = "Nature's many faces were carried within.",
        MILESTONE = { "At level {level}, nature taught new forms.", "Level {level}: the heart of the forest beat as one with {name}." } },
    DEATHKNIGHT = { INTRO = "Free from the Lich King's chains, yet the cold remained within.",
        MILESTONE = { "At level {level}, the runeblade hungered for more." } },
    MONK = { INTRO = "Perfect balance, unforgiving fists.",
        MILESTONE = { "At level {level}, the chi flowed stronger than ever." } },
    DEMONHUNTER = { INTRO = "Blindfolded, yet nothing could hide from those eyes.",
        MILESTONE = { "At level {level}, the fel within grew harder to restrain." } },
    EVOKER = { INTRO = "The ancient power of dragons flowed through the veins.",
        MILESTONE = { "At level {level}, the dragonflame burned brighter." } },
}

----------------------------------------------------------------------
-- Seçim ve doldurma / Lookup and fill
----------------------------------------------------------------------
function ns.Fill(tpl, vars)
    return (tpl:gsub("{(%w+)}", function(k)
        local v = vars and vars[k]
        if v == nil then return "" end
        return tostring(v)
    end))
end

-- Seçenekler sırayla dönüşümlü kullanılır: aynı türden art arda iki olay asla aynı
-- cümleyle anlatılmaz. Başlangıç noktası olayın zamanından gelir; kitap her
-- oluşturuluşta sayaç sıfırlandığı için aynı anılar her zaman aynı metni üretir.
local usage, offset = {}, {}
function ns.ResetVoiceRotation() wipe(usage); wipe(offset) end

local function Pick(v, seed, key)
    if type(v) ~= "table" then return v end
    local n = #v
    if n == 0 then return nil end
    if not offset[key] then
        -- Bu anahtarın kitaptaki ilk kullanımı: başlangıç noktasını olayın zamanından al
        seed = math.floor(seed or 0)
        offset[key] = (seed % 9973) * 31 + math.floor(seed / 3600)
    end
    local used = usage[key] or 0
    usage[key] = used + 1
    return v[((offset[key] + used) % n) + 1]
end

-- Anlatıcı: "race" (varsayılan, ırka göre) ya da "plain" (sade, tek ses)
local function NarratorRace()
    if ns.settings and ns.settings.narrator == "plain" then return nil end
    local _, raceFile = UnitRace("player")
    return raceFile
end

local function ClassFile()
    if ns.settings and ns.settings.narrator == "plain" then return nil end
    local _, classFile = UnitClass("player")
    return classFile
end

local function Lookup(set, group, key)
    local t = set and group and set[group]
    return t and t[key]
end

-- Irk sesi: önce seçili dil + ırk, sonra seçili dil + varsayılan, sonra İngilizce
function ns.Voice(key, seed, vars)
    local race = NarratorRace()
    local set = V[ns.lang] or V.en
    local v = Lookup(set, race, key) or Lookup(set, "default", key)
        or Lookup(V.en, race, key) or Lookup(V.en, "default", key)
    v = Pick(v, seed, "race:" .. key)
    if not v then return nil end
    return ns.Fill(v, vars)
end

-- Sınıf dokunuşu: yoksa nil (sessizce atlanır)
function ns.ClassVoice(key, seed, vars)
    local class = ClassFile()
    if not class then return nil end
    local set = C[ns.lang] or C.en
    local v = Lookup(set, class, key) or Lookup(C.en, class, key)
    v = Pick(v, seed, "class:" .. key)
    if not v then return nil end
    return ns.Fill(v, vars)
end
