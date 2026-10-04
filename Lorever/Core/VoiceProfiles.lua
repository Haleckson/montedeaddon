local _, ns = ...

-- Narrator profiles: how the narrator reads, for each language and each kind
-- of page. A profile is a reading style (Chronicler, Storyteller...) with its
-- own voice, speed, tone and pauses. The reader picks one profile per kind of
-- page (regions, figures, topics, books, letters) and per language, and can
-- save profiles of their own.
--
-- A profile sets the game's own text to speech (C_VoiceChat): voice, rate, volume.
-- A narration pack (Lorever Narration, an optional add-on per language) reads
-- with its own storyteller, made in advance: profiles do not change it.
--
-- Saved in LoreverDB.settings.voice:
--   engine   = "auto" | "game" | "pack"
--              auto: the voice pack of the language when installed, else the game's voice
--   profiles = { [id] = profile }        the reader's own profiles ("user:N")
--   use      = { [lang] = { [kind] = profile id } }
--   nextID   = number

local Profiles = {}
ns.VoiceProfiles = Profiles

local N = ns.N

Profiles.KINDS = {
	{ key = "region", label = N("Regions and places") },
	{ key = "figure", label = N("Figures") },
	{ key = "topic", label = N("Peoples, orders and events") },
	{ key = "book", label = N("Books and legends") },
	{ key = "letter", label = N("Letters and journals") },
}

Profiles.LANGS = { "enUS", "ptBR", "deDE", "frFR", "esES", "esMX", "zhCN", "ruRU" }
Profiles.LANG_NAMES = {
	enUS = N("English (United States)"),
	ptBR = N("Portuguese (Brazil)"),
	deDE = N("German (Germany)"),
	frFR = N("French (France)"),
	esES = N("Spanish (Spain)"),
	esMX = N("Spanish (Mexico)"),
	zhCN = N("Chinese (Simplified)"),
	ruRU = N("Russian"),
}

-- A short sentence of our own for the Test buttons, in each language.
Profiles.SAMPLE = {
	enUS = "The chronicles of Azeroth keep the stories of kingdoms raised and lost.",
	ptBR = "As crônicas de Azeroth guardam as histórias de reinos erguidos e perdidos.",
	deDE = "Die Chroniken Azeroths bewahren die Geschichten von Reichen, die entstanden und vergingen.",
	frFR = "Les chroniques d'Azeroth gardent l'histoire des royaumes bâtis puis perdus.",
	esES = "Las crónicas de Azeroth guardan las historias de reinos que se alzaron y se perdieron.",
	esMX = "Las crónicas de Azeroth guardan las historias de reinos que se alzaron y se perdieron.",
	zhCN = "艾泽拉斯的编年史记载着那些兴起又失落的王国的故事。",
	ruRU = "Хроники Азерота хранят истории королевств, что возвысились и пали.",
}

-- Reading styles. "rate" is added to the game's own speech rate (-10 to 10).
Profiles.STYLES = {
	{ key = "chronicler", label = N("Chronicler"), tip = N("Calm and clear, like an encyclopedia."),
		rate = 0 },
	{ key = "storyteller", label = N("Storyteller"), tip = N("Warm and unhurried, for books and legends."),
		rate = -1 },
	{ key = "epic", label = N("Epic"), tip = N("Deep and slow, for great events."),
		rate = -2 },
	{ key = "serene", label = N("Serene"), tip = N("Light and gentle, for letters and journals."),
		rate = 0 },
}
local STYLE = {}
for _, s in ipairs(Profiles.STYLES) do STYLE[s.key] = s end

-- What each kind of page uses until the reader chooses.
Profiles.DEFAULT_USE = { region = "style:chronicler", figure = "style:chronicler", topic = "style:epic",
	book = "style:storyteller", letter = "style:serene" }

Profiles.LIMITS = {
	rate = { -10, 10 }, volume = { 0, 100 },
}

local function clamp(key, v)
	local l = Profiles.LIMITS[key]
	if v == nil or not l then return v end
	return math.max(l[1], math.min(l[2], v))
end
Profiles.Clamp = clamp

local function store()
	local s = ns.db.settings
	s.voice = s.voice or {}
	local v = s.voice
	v.engine = v.engine or "auto"
	v.profiles = v.profiles or {}
	v.use = v.use or {}
	v.nextID = v.nextID or 1
	return v
end
Profiles.Store = store

local function packHere(lang)
	return ns.Voice and ns.Voice.Pack and ns.Voice.Pack.Installed(lang) or false
end

-- What the reader chose: "auto", "game" or "pack". A choice this version no
-- longer has (saved by an older one) counts as "auto".
function Profiles.Choice()
	local choice = store().engine
	return (choice == "game" or choice == "pack") and choice or "auto"
end

-- The voice that reads now: "pack" or "game".
function Profiles.Engine(lang)
	local choice = Profiles.Choice()
	if choice == "game" then return "game" end
	return packHere(lang) and "pack" or "game"
end

Profiles.ENGINES = { "auto", "game", "pack" }
function Profiles.SetEngine(engine)
	local ok = { game = true, pack = true }
	store().engine = ok[engine] and engine or "auto"
	ns.Fire("FL_VOICE_PROFILES")
end

-- The kind of a page, for choosing its profile.
function Profiles.KindOf(entry)
	if not entry then return "region" end
	if entry.kind == "book" then
		local c = entry.category or "book"
		return (c == "letter" or c == "journal") and "letter" or "book"
	end
	if entry.kind == "figure" then return "figure" end
	if entry.kind == "topic" then return "topic" end
	return "region"
end

-- A built-in profile: one style, in one language, with nothing changed.
local function builtin(styleKey, lang)
	local st = STYLE[styleKey] or STYLE.chronicler
	return {
		id = "style:" .. st.key, name = st.label, builtin = true, style = st.key, lang = lang,
		game = { voiceID = nil, rate = nil, rateOffset = st.rate, volume = nil },
	}
end

function Profiles.Get(id, lang)
	lang = lang or "enUS"
	if type(id) == "string" and id:sub(1, 6) == "style:" then return builtin(id:sub(7), lang) end
	local p = store().profiles[id]
	if p then return p end
	return builtin("chronicler", lang)
end

-- Every profile the reader can pick in a language: the styles, then their own.
function Profiles.List(lang)
	local out = {}
	for _, st in ipairs(Profiles.STYLES) do out[#out + 1] = builtin(st.key, lang) end
	local own = {}
	for id, p in pairs(store().profiles) do
		if p.lang == lang then own[#own + 1] = p end
		p.id = id
	end
	table.sort(own, function(a, b) return (a.name or "") < (b.name or "") end)
	for _, p in ipairs(own) do out[#out + 1] = p end
	return out
end

function Profiles.UseOf(lang, kind)
	local use = store().use[lang]
	local id = use and use[kind] or Profiles.DEFAULT_USE[kind] or "style:chronicler"
	if type(id) == "string" and id:sub(1, 5) == "user:" and not store().profiles[id] then
		id = Profiles.DEFAULT_USE[kind] or "style:chronicler"
	end
	return id
end

function Profiles.SetUse(lang, kind, id)
	local v = store()
	v.use[lang] = v.use[lang] or {}
	v.use[lang][kind] = id
	ns.Fire("FL_VOICE_PROFILES")
end

-- The profile that reads this page (or this kind of page) in this language.
function Profiles.For(entryOrKind, lang)
	lang = lang or (ns.Lore and ns.Lore.language) or "enUS"
	local kind = type(entryOrKind) == "string" and entryOrKind or Profiles.KindOf(entryOrKind)
	return Profiles.Get(Profiles.UseOf(lang, kind), lang)
end

local function copy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do out[k] = copy(v) end
	return out
end

-- A new profile of the reader's, made from another one (a style or their own).
function Profiles.Duplicate(id, lang, name)
	local v = store()
	local base = Profiles.Get(id, lang)
	local p = copy(base)
	p.builtin, p.lang = nil, lang
	p.name = name or string.format(ns.T("My %s"), ns.T(base.name or "profile"))
	local newID = "user:" .. v.nextID
	v.nextID = v.nextID + 1
	p.id = newID
	v.profiles[newID] = p
	ns.Fire("FL_VOICE_PROFILES")
	return newID, p
end

function Profiles.Delete(id)
	local v = store()
	if not v.profiles[id] then return false end
	v.profiles[id] = nil
	for _, kinds in pairs(v.use) do
		for kind, used in pairs(kinds) do if used == id then kinds[kind] = nil end end
	end
	ns.Fire("FL_VOICE_PROFILES")
	return true
end

-- Changes one value of the reader's own profile ("game.rate", "game.volume"...).
function Profiles.Set(id, path, value)
	local p = store().profiles[id]
	if not p then return false end
	local group, key = path:match("^(%a+)%.(%a+)$")
	if not group then
		if path == "name" then p.name = tostring(value) end
		ns.Fire("FL_VOICE_PROFILES")
		return true
	end
	p[group] = p[group] or {}
	p[group][key] = (type(value) == "number") and clamp(key, value) or value
	ns.Fire("FL_VOICE_PROFILES")
	return true
end

-- Every assignment back to the styles, in one language (or all).
function Profiles.Reset(lang)
	local v = store()
	if lang then v.use[lang] = nil else v.use = {} end
	ns.Fire("FL_VOICE_PROFILES")
end

-- Game engine: the rate and volume this profile gives the game's TTS.
function Profiles.GameRateVolume(p, gameRate, gameVolume)
	local g = p and p.game or {}
	local rate = g.rate
	if rate == nil then rate = (gameRate or 0) + (g.rateOffset or 0) end
	local volume = g.volume
	if volume == nil then volume = gameVolume or 100 end
	return clamp("rate", rate), clamp("volume", volume)
end
