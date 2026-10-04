local _, ns = ...

-- The narrator: reads lore aloud with the game's own text-to-speech, so the
-- reader can listen while playing. No recorded audio.
--
-- A page becomes a script of short chunks (a sentence or two). Chunks are
-- spoken one by one, which gives a queue, pause, next / previous section, and
-- resuming where the reader left off, even after /reload.
--
--   Voice.Play(id)      read this page now (replaces the queue)
--   Voice.Enqueue(id)   read it after the others
--   Voice.PlayList(ids) read these pages in order
--   Voice.Toggle()      pause / resume
--   Voice.Next() / Voice.Prev()   next section / start of this section
--   Voice.Stop()        stop and empty the queue
--
-- Only what the reader has discovered is read. Hidden chapters are named as hidden.

local Voice = {}
ns.Voice = Voice

local Lore, P = ns.Lore, ns.Progress
local CHUNK = 220            -- characters per spoken chunk

-- Script ------------------------------------------------------------------------------

-- Spaces are named one by one: Lua's %s also matches byte 0xA0, which is half of
-- letters such as "à" in UTF-8, and would break them.
local SP = "[ \t\r\n]"
local function clean(text)
	text = ns.Theme.Plain(text or "")
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
	text = text:gsub("<[^>]+>", " "):gsub("%*", ""):gsub("\n%- ", "\n"):gsub("[ \t\r\n]+", " ")
	return (text:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

-- Sentences joined into chunks of about CHUNK characters.
-- Chinese ends a sentence with full-width marks and puts no space after them.
local WIDE_ENDS = { "\227\128\130", "\239\188\129", "\239\188\159" }   -- 。 ！ ？
local WIDE_PAUSES = { "\239\188\140", "\227\128\129", "\239\188\155" } -- ， 、 ；

-- Where the sentence that starts at pos ends.
local function nextEnd(t, pos)
	local _, e = t:find("[%.!?]+[\"']?[ \t\r\n]+", pos)
	for _, mark in ipairs(WIDE_ENDS) do
		local _, e2 = t:find(mark, pos, true)
		if e2 and (not e or e2 < e) then e = e2 end
	end
	return e
end

-- Where to cut a sentence longer than a chunk: the last comma or space before
-- the limit, and never inside a letter (letters can take several bytes).
local function cutPoint(s, limit)
	local head = s:sub(1, limit)
	local cut = head:find(",[^,]*$") or head:find(" [^ ]*$")
	for _, mark in ipairs(WIDE_PAUSES) do
		local last, a, b = 0, nil, nil
		repeat
			a, b = head:find(mark, last + 1, true)
			if b then last = b end
		until not a
		if last > 0 and (not cut or last > cut) then cut = last end
	end
	cut = cut or limit
	while cut > 1 and cut < #s do
		local nb = s:byte(cut + 1)
		if nb < 128 or nb >= 192 then break end
		cut = cut - 1
	end
	return cut
end

local function chunks(text)
	local t, sentences, pos = clean(text), {}, 1
	while pos <= #t do
		local e = nextEnd(t, pos)
		if not e then
			sentences[#sentences + 1] = t:sub(pos)
			break
		end
		sentences[#sentences + 1] = (t:sub(pos, e):gsub("[ \t\r\n]+$", ""))
		pos = e + 1
	end
	local out, current = {}, ""
	for _, sentence in ipairs(sentences) do
		if #current > 0 and #current + #sentence > CHUNK then
			out[#out + 1] = current
			current = sentence
		else
			current = (#current > 0 and (current .. " ") or "") .. sentence
		end
	end
	if #current > 0 then out[#out + 1] = current end
	-- A sentence longer than a chunk is cut at a comma or a space.
	local final = {}
	for _, c in ipairs(out) do
		while #c > CHUNK * 1.5 do
			local cut = cutPoint(c, CHUNK)
			final[#final + 1] = c:sub(1, cut)
			c = c:sub(cut + 1):gsub("^[ \t\r\n]+", "")
		end
		if #c > 0 then final[#final + 1] = c end
	end
	return final
end

Voice.Chunks = chunks -- for the tests

-- The script of a page: { { section = title, chunks = { ... } }, ... }.
function Voice.Script(entry)
	local script = {}
	local function add(title, text)
		local list = chunks(text)
		if #list > 0 then script[#script + 1] = { section = title, chunks = list } end
	end
	local opening = entry.title .. "."
	if entry.subtitle then opening = opening .. " " .. entry.subtitle .. "." end
	add(entry.title, opening)
	if not P.IsUnlocked(entry.id) then
		add(entry.title, ns.T("This page is not yet discovered.") .. " " .. Lore.Hint(entry))
		return script
	end
	if entry.kind == "book" then
		add(ns.T("Where to Find It"), entry.found or "")
		for _, section in ipairs(entry.sections or {}) do add(section.title, section.text) end
		for _, t in ipairs(ns.Library.TextsOf(entry)) do
			local numbers = {}
			for n in pairs(t.text.pages) do numbers[#numbers + 1] = n end
			table.sort(numbers)
			for _, n in ipairs(numbers) do add(t.title, t.text.pages[n]) end
		end
		return script
	end
	for _, section in ipairs(entry.sections or {}) do add(section.title, section.text) end
	for _, chapter in ipairs(entry.chapters or {}) do
		if P.IsUnlocked(chapter.part.key) then
			add(chapter.title, chapter.title .. ". " .. chapter.text)
		else
			add(chapter.title, ns.T("One chapter of this story remains hidden."))
		end
	end
	return script
end

-- State ----------------------------------------------------------------------------------

-- Saved: { ids = { ... }, item, section, chunk, paused }.
local function state()
	ns.db.narration = ns.db.narration or { ids = {}, item = 1, section = 1, chunk = 1 }
	return ns.db.narration
end

-- Speech ---------------------------------------------------------------------------------
--
-- The Speaker talks to the game's text-to-speech (C_VoiceChat, C_TTSSettings).
-- It knows one thing at a time: the utterance it started. The game names each
-- utterance in its STARTED and FINISHED events, so a chunk ends when the game
-- says *that* utterance finished. After a stop, the next chunk waits until the
-- game confirms the stopped speech is over (or a short while passes).

local function settings() return ns.db.settings end

local Speaker = { voices = nil, pending = nil, utterance = nil, settling = false }
Voice.Speaker = Speaker

-- The voices the game offers, read once and again when the game says they changed.
function Speaker.Voices()
	if not Speaker.voices then
		local ok, list = pcall(C_VoiceChat.GetTtsVoices)
		Speaker.voices = ok and type(list) == "table" and list or {}
	end
	return Speaker.voices
end

-- The narrator speaks the language of the texts:
-- 1. the voice of the page's narrator profile (VoiceProfiles.lua), if it is still installed;
-- 2. the voice picked with /lorever voice <n>, if it is still installed;
-- 3. the reader's own voice from the game's Text to Speech options, if it speaks that language;
-- 4. else the first installed voice whose name says it speaks that language.
local SPEAKS = {
	enUS = { "English", "%f[%a]en[%-_]%u%u" },
	ptBR = { "Portugu", "Brazil", "Brasil", "%f[%a]pt[%-_]%u%u" },
	deDE = { "German", "Deutsch", "%f[%a]de[%-_]%u%u" },
	frFR = { "French", "Fran", "%f[%a]fr[%-_]%u%u" },
	esES = { "Spanish", "Espa", "%f[%a]es[%-_]%u%u" },
	esMX = { "Spanish", "Espa", "%f[%a]es[%-_]%u%u" },
	zhCN = { "Chinese", "Huihui", "Yaoyao", "Kangkang", "Xiaoxiao", "%f[%a]zh[%-_]%u%u" },
	ruRU = { "Russian", "Irina", "Pavel", "%f[%a]ru[%-_]%u%u" },
}

local function speaks(voice, lang)
	local name = voice and voice.name or ""
	for _, pattern in ipairs(SPEAKS[lang] or SPEAKS.enUS) do
		if name:find(pattern) then return true end
	end
	return false
end

local function contentLanguage()
	return ns.Lore and ns.Lore.language or "enUS"
end

local function isEnglish(voice) return speaks(voice, "enUS") end
Voice.IsEnglish = isEnglish
Voice.Speaks = speaks

function Speaker.Pick(lang, profile)
	local voices = Speaker.Voices()
	local mine = profile and profile.game and profile.game.voiceID
	if mine then
		for _, v in ipairs(voices) do if v.voiceID == mine then return v end end
	end
	local wanted = settings().narratorVoiceID
	if wanted then
		for _, v in ipairs(voices) do if v.voiceID == wanted then return v end end
	end
	local TS = C_TTSSettings
	local own
	if TS and TS.GetVoiceOptionID and Enum and Enum.TtsVoiceType then
		local ok, id = pcall(TS.GetVoiceOptionID, Enum.TtsVoiceType.Standard)
		if ok then
			for _, v in ipairs(voices) do if v.voiceID == id then own = v end end
		end
	end
	lang = lang or contentLanguage()
	if speaks(own, lang) then return own end
	for _, v in ipairs(voices) do
		if speaks(v, lang) then return v end
	end
	if not Speaker.warnedNoEnglish and #voices > 0 then
		Speaker.warnedNoEnglish = true
		local language = ({ ptBR = ns.T("Portuguese (Brazil)"), deDE = ns.T("German (Germany)"), frFR = ns.T("French (France)"),
			esES = ns.T("Spanish (Spain)"), esMX = ns.T("Spanish (Mexico)"), zhCN = ns.T("Chinese (Simplified)"), ruRU = ns.T("Russian") })[lang] or ns.T("English (United States)")
		ns.Print(string.format(ns.T("No %s voice is installed on this computer, so the narrator uses another language. "
			.. "Windows: Settings > Time & language > Speech > Add voices > %s. "
			.. "Mac: System Settings > Accessibility > Spoken Content > System voice > Manage Voices. Then restart the game."), language, language))
	end
	return own or voices[1]
end

-- Voice ID, rate and volume for a page (or a kind of page) in a language: the
-- page's narrator profile over the game's own Text to Speech options.
function Speaker.Profile(entryOrKind, lang, profile)
	local TS = C_TTSSettings
	lang = lang or contentLanguage()
	profile = profile or ns.VoiceProfiles.For(entryOrKind or "region", lang)
	local voice = Speaker.Pick(lang, profile)
	local rate = TS and TS.GetSpeechRate and tonumber((select(2, pcall(TS.GetSpeechRate)))) or 0
	local volume = TS and TS.GetSpeechVolume and tonumber((select(2, pcall(TS.GetSpeechVolume)))) or 100
	rate, volume = ns.VoiceProfiles.GameRateVolume(profile, rate, volume)
	return voice and voice.voiceID, rate, volume
end

-- /lorever voices and /lorever voice <n>: choose the narrator's voice by hand.
function Voice.ListVoices()
	local current = Speaker.Pick()
	for i, v in ipairs(Speaker.Voices()) do
		ns.Print(string.format("%d. %s%s", i, v.name or string.format(ns.T("voice %s"), tostring(v.voiceID)),
			current and current.voiceID == v.voiceID and ("  <- " .. ns.T("narrator")) or ""))
	end
	if #Speaker.Voices() == 0 then ns.Print(ns.T("The game lists no voices. Turn on Text to Speech in the game's options (Accessibility).")) end
end

function Voice.SetVoice(arg)
	if arg == "auto" or arg == nil or arg == "" then
		settings().narratorVoiceID = nil
		local v = Speaker.Pick()
		return v and v.name or ns.T("none")
	end
	local v = Speaker.Voices()[tonumber(arg) or 0]
	if not v then return nil end
	settings().narratorVoiceID = v.voiceID
	return v.name or tostring(v.voiceID)
end

-- Older clients take a destination before the rate; newer ones do not. The
-- client's own enum tells which kind this is.
function Speaker.Shape()
	return (Enum and Enum.VoiceTtsDestination) and "destination" or "plain"
end

function Voice.Available()
	return settings().narrator ~= false and C_VoiceChat ~= nil and C_VoiceChat.SpeakText ~= nil
end

-- Starts one utterance. Returns true, rate when the game accepted it.
function Speaker.Say(text, entryOrKind, lang, profile)
	local voiceID, rate, volume = Speaker.Profile(entryOrKind, lang, profile)
	if voiceID == nil or not Voice.Available() then return false end
	local ok
	if Speaker.Shape() == "destination" then
		ok = pcall(C_VoiceChat.SpeakText, voiceID, text, Enum.VoiceTtsDestination.LocalPlayback, rate, volume)
	else
		ok = pcall(C_VoiceChat.SpeakText, voiceID, text, rate, volume, false)
	end
	Speaker.utterance = nil -- named by the STARTED event that follows
	return ok, rate
end

-- Stops speech; what comes next waits for the game to confirm the stop.
function Speaker.Hush()
	if C_VoiceChat and C_VoiceChat.StopSpeakingText then
		pcall(C_VoiceChat.StopSpeakingText)
		Speaker.settling = true
		C_Timer.After(0.6, function() Speaker.Settled() end) -- in case no confirmation comes
	end
	Speaker.utterance = nil
end

-- Runs fn now, or once the stopped speech is over.
function Speaker.WhenQuiet(fn)
	if Speaker.settling then Speaker.pending = fn else fn() end
end

function Speaker.Settled()
	if not Speaker.settling then return end
	Speaker.settling = false
	local fn = Speaker.pending
	Speaker.pending = nil
	if fn then fn() end
end

local script, scriptOf -- the script of the current page
local speaking, token, spokeAt = false, 0, 0
local CHARS_PER_SECOND = 11 -- for the fallback, when the game never reports an end

function Voice.Current()
	local s = state()
	local id = s.ids[s.item]
	return id and Lore.Get(id), s
end

local function currentScript()
	local entry = Voice.Current()
	if not entry then return nil end
	if scriptOf ~= entry.id then
		script, scriptOf = Voice.Script(entry), entry.id
	end
	return script
end

function Voice.IsPlaying() return speaking end
function Voice.IsActive() return #state().ids > 0 end

-- Narration packs (optional add-ons, any number per language) -------------------------
--
-- A pack holds chunks of the narrator already spoken, as audio files, with an
-- index: LoreverNarration[id][chunk text] = { file, seconds }.
--   id "enUS"       the Lorever Narration pack of a language (folder LoreverNarration_enUS)
--   id "enUS_F"     a second voice of that language (folder LoreverNarration_enUS_F)
--   any other id    a pack that describes itself in LoreverNarrationInfo[id] =
--                   { lang = "enUS", title = "...", folder = "...", custom = true },
--                   for example one recorded by a player with Lorever Voice Studio.
-- A pack may also hold a whole section in one recording (a person reading at
-- their own pace): its key is Pack.SectionKey(chunks), "#section:" and the
-- section's chunks joined by spaces.
-- Each chunk is read by the first pack that holds it: the pack the reader chose,
-- then packs recorded by people, then the language's own pack, then the others;
-- a chunk no pack holds is read by the game's voice. The game says nothing when
-- a sound file ends, so the next chunk follows after its length.
local Pack = {}
Voice.Pack = Pack
Pack.PAUSE = 0.35 -- seconds between two chunks
-- Spanish of Spain and of Mexico share one pack.
Pack.OF = { enUS = "enUS", ptBR = "ptBR", deDE = "deDE", frFR = "frFR", esES = "esES", esMX = "esES", zhCN = "zhCN", ruRU = "ruRU" }

local function info(id)
	local all = _G.LoreverNarrationInfo
	local i = type(all) == "table" and all[id] or nil
	return type(i) == "table" and i or nil
end

function Pack.LangOf(id)
	local i = info(id)
	return i and i.lang or (type(id) == "string" and id:match("^(%a%a%u%u)")) or nil
end

function Pack.FolderOf(id)
	local i = info(id)
	return i and i.folder or ("LoreverNarration_" .. id)
end

-- Names for our first packs, made before the packs named themselves
-- (LoreverNarrationInfo): the language and the narrator.
Pack.NAMES = {
	enUS = "English, Michael", ptBR = "Português (Brasil), Santa", deDE = "Deutsch, Thorsten",
	frFR = "Français, Gilles", esES = "Español, Santa", zhCN = "简体中文, Yunxi", ruRU = "Русский, Dmitri",
}

function Pack.TitleOf(id)
	local i = info(id)
	if i and i.title then return i.title end
	if Pack.NAMES[id] then return Pack.NAMES[id] end
	if id:find("_") then return id end
	return ns.T("Voice pack (Lorever Narration)")
end

local function indexOf(id)
	local all = _G.LoreverNarration
	local idx = type(all) == "table" and all[id] or nil
	if not idx and id == "enUS" and type(_G.LoreverNarrationIndex) == "table" then idx = _G.LoreverNarrationIndex end
	return type(idx) == "table" and idx or nil
end

-- The packs for a language, in the order they are asked for a chunk.
function Pack.List(lang)
	local want = Pack.OF[lang or contentLanguage()]
	if not want then return {} end
	local ids = {}
	local all = type(_G.LoreverNarration) == "table" and _G.LoreverNarration or {}
	for id in pairs(all) do
		if Pack.LangOf(id) == want and indexOf(id) then ids[#ids + 1] = id end
	end
	if want == "enUS" and not all.enUS and indexOf("enUS") then ids[#ids + 1] = "enUS" end
	local chosen = ns.db and ns.db.settings and ns.db.settings.voice and ns.db.settings.voice.pack
	local function rank(id)
		if id == chosen then return 0 end
		local i = info(id)
		if i and i.custom then return 1 end
		if id == want then return 2 end
		return 3
	end
	table.sort(ids, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then return ra < rb end
		return a < b
	end)
	return ids
end

function Pack.Installed(lang) return #Pack.List(lang) > 0 end

-- The pack the reader chose for the narrator (nil: the order above).
function Pack.Choose(id)
	local v = ns.db.settings.voice or {}
	ns.db.settings.voice = v
	v.pack = id
	ns.Fire("FL_VOICE_PROFILES")
end

function Pack.SectionKey(chunks)
	return "#section:" .. table.concat(chunks, " ")
end

-- The clip for this chunk, when a pack can read it now. At the first chunk of a
-- section, a pack's recording of the whole section counts too (clip.whole).
function Pack.Find(text, section)
	if ns.VoiceProfiles.Engine() ~= "pack" then return nil end
	local whole = section and Pack.SectionKey(section)
	for _, id in ipairs(Pack.List()) do
		local idx = indexOf(id)
		local clip = whole and idx[whole]
		if type(clip) == "table" then return { clip[1], clip[2], id, whole = true } end
		clip = idx[text]
		if type(clip) == "table" then return { clip[1], clip[2], id } end
	end
	return nil
end

function Pack.Play(clip)
	if not PlaySoundFile then return false end
	local path = "Interface\\AddOns\\" .. Pack.FolderOf(clip[3]) .. "\\audio\\" .. clip[1]:gsub("/", "\\")
	local ok, willPlay, handle = pcall(PlaySoundFile, path, "Dialog")
	if ok and willPlay then
		Pack.handle = handle
		return true
	end
	return false
end

function Pack.Stop()
	if Pack.handle and StopSound then pcall(StopSound, Pack.handle, 150) end
	Pack.handle = nil
end

local function silence()
	if Pack.handle then Pack.Stop()
	elseif speaking then Speaker.Hush() end
	speaking = false
	token = token + 1
end

local advance

local function speakCurrent(auto)
	local s = state()
	local sc = currentScript()
	if not sc then return Voice.Stop() end
	local section = sc[s.section]
	local text = section and section.chunks[s.chunk]
	if not text then return advance() end
	token = token + 1
	local mine = token
	Speaker.WhenQuiet(function()
		if mine ~= token or s.paused then return end
		local clip = Pack.Find(text, s.chunk == 1 and section.chunks or nil)
		if clip and Pack.Play(clip) then
			speaking, spokeAt = true, GetTime()
			C_Timer.After((tonumber(clip[2]) or 3) + Pack.PAUSE, function()
				if mine == token and speaking then
					Pack.handle = nil
					-- A recording of the whole section: the narrator goes on to the next one.
					if clip.whole then s.chunk = #section.chunks end
					advance()
				end
			end)
			ns.Fire("FL_NARRATION")
			return
		end
		local ok, rate = Speaker.Say(text, Voice.Current())
		if not ok then
			ns.Print(ns.T("The narrator could not speak. Turn on Text to Speech in the game's options (Accessibility), then try /lorever voicetest."))
			s.paused = true
			ns.Fire("FL_NARRATION")
			return
		end
		speaking, spokeAt = true, GetTime()
		-- Fallback: some clients may never report the end. A generous estimate moves on.
		local estimate = #text / (CHARS_PER_SECOND * (1 + (rate or 0) * 0.1)) + 1.5
		if Voice.eventsWork then estimate = estimate * 2 + 4 end
		C_Timer.After(estimate, function()
			if mine == token and speaking then advance() end
		end)
		ns.Fire("FL_NARRATION")
	end)
end

-- The next chunk, section or page.
advance = function()
	local s = state()
	speaking = false
	local sc = currentScript()
	if not sc then return Voice.Stop() end
	local section = sc[s.section]
	if section and s.chunk < #section.chunks then
		s.chunk = s.chunk + 1
	elseif s.section < #sc then
		s.section, s.chunk = s.section + 1, 1
	else
		local entry = Voice.Current()
		if entry then ns.db.heard[entry.id] = true end
		if s.item < #s.ids then
			s.item, s.section, s.chunk = s.item + 1, 1, 1
		else
			return Voice.Stop()
		end
	end
	speakCurrent(true)
end

-- The game started an utterance: while we are speaking, it is ours.
function Voice.OnStarted(utteranceID)
	if speaking and Speaker.utterance == nil then Speaker.utterance = utteranceID end
end

-- The game finished (or failed) an utterance.
function Voice.OnFinished(utteranceID)
	Voice.eventsWork = true
	if Speaker.settling then
		Speaker.Settled() -- the stopped speech is over
		return
	end
	if not speaking then return end
	local ours = (utteranceID ~= nil and Speaker.utterance ~= nil and utteranceID == Speaker.utterance)
		or ((utteranceID == nil or Speaker.utterance == nil) and GetTime() - spokeAt > 0.5)
	if ours then advance() end
end

-- Controls ---------------------------------------------------------------------------------

function Voice.PlayList(ids)
	if #ids == 0 then return end
	silence()
	local s = state()
	s.ids, s.item, s.section, s.chunk, s.paused = {}, 1, 1, 1, nil
	for _, id in ipairs(ids) do s.ids[#s.ids + 1] = id end
	scriptOf = nil
	speakCurrent()
end

function Voice.Play(id) Voice.PlayList({ id }) end

function Voice.Enqueue(id)
	local s = state()
	if #s.ids == 0 then return Voice.Play(id) end
	for _, v in ipairs(s.ids) do if v == id then return end end
	s.ids[#s.ids + 1] = id
	ns.Fire("FL_NARRATION")
end

function Voice.Pause()
	local s = state()
	if #s.ids == 0 then return end
	s.paused = true
	silence()
	ns.Fire("FL_NARRATION")
end

function Voice.Resume()
	local s = state()
	if #s.ids == 0 then return end
	s.paused = nil
	speakCurrent() -- the chunk that was cut starts again
end

function Voice.Toggle()
	local s = state()
	if #s.ids == 0 then return false end
	if s.paused or not speaking then Voice.Resume() else Voice.Pause() end
	return true
end

function Voice.Next()
	local s = state()
	local sc = currentScript()
	if not sc then return end
	silence()
	if s.section < #sc then
		s.section, s.chunk = s.section + 1, 1
	elseif s.item < #s.ids then
		s.item, s.section, s.chunk = s.item + 1, 1, 1
	else
		return Voice.Stop()
	end
	s.paused = nil
	speakCurrent()
end

function Voice.Prev()
	local s = state()
	if #s.ids == 0 then return end
	silence()
	if s.chunk == 1 and s.section > 1 then s.section = s.section - 1 end
	s.chunk, s.paused = 1, nil
	speakCurrent()
end

function Voice.Stop()
	silence()
	local s = state()
	wipe(s.ids)
	s.item, s.section, s.chunk, s.paused = 1, 1, 1, nil
	scriptOf = nil
	ns.Fire("FL_NARRATION")
end

-- "Section 2 of 5" for the narrator bar.
function Voice.Progress()
	local s = state()
	local sc = currentScript()
	return s.section, sc and #sc or 0, s.item, #s.ids
end

-- The land the reader stands in: the region, then its discovered places and figures.
function Voice.PlayHere()
	local region = ns.Triggers.CurrentRegion()
	if not region then return false end
	local ids = { region.id }
	for _, list in ipairs({ Lore.PlacesOf(region.id), Lore.FiguresOf(region.id) }) do
		for _, entry in ipairs(list) do
			if P.IsFound(entry.id) then ids[#ids + 1] = entry.id end
		end
	end
	Voice.PlayList(ids)
	return true
end

-- The Test buttons of the narrator panel: one sentence of our own, in that
-- language, read with that profile. The queue (if any) is paused first.
function Voice.TestProfile(lang, profileID)
	local Profiles = ns.VoiceProfiles
	local profile = Profiles.Get(profileID, lang)
	local text = Profiles.SAMPLE[lang] or Profiles.SAMPLE.enUS
	if Voice.IsActive() and not state().paused then Voice.Pause() end
	silence()
	Speaker.WhenQuiet(function()
		local ok = Speaker.Say(text, nil, lang, profile)
		if not ok then ns.Print(ns.T("Turn on Text to Speech in the game's options (Accessibility), and pick a voice there.")) end
	end)
	return true
end

-- /lorever voicetest: one sentence through the narrator's voice, and what it uses.
function Voice.Test()
	silence()
	local voiceID, rate, volume = Speaker.Profile()
	local name = ns.T("none")
	for _, v in ipairs(Speaker.Voices()) do if v.voiceID == voiceID then name = v.name or tostring(voiceID) end end
	Speaker.WhenQuiet(function()
		local ok = Speaker.Say(ns.T("The narrator of Lorever is ready."))
		ns.Print(string.format(ns.T("Narrator test: voice \"%s\", speed %s, volume %s, %s. %s"), name, tostring(rate), tostring(volume),
			Speaker.Shape(), ok and ns.T("Sent to the game.") or ns.T("The game did not accept it.")))
		if not ok then ns.Print(ns.T("Turn on Text to Speech in the game's options (Accessibility), and pick a voice there.")) end
	end)
end

-- Events ------------------------------------------------------------------------------------

-- STARTED: (consumers, utteranceID, durationMS, destination); FINISHED: (consumers,
-- utteranceID, destination); FAILED: (status, utteranceID, destination).
ns.On("VOICE_CHAT_TTS_PLAYBACK_STARTED", function(_, _, utteranceID) Voice.OnStarted(utteranceID) end)
ns.On("VOICE_CHAT_TTS_PLAYBACK_FINISHED", function(_, _, utteranceID) Voice.OnFinished(utteranceID) end)
ns.On("VOICE_CHAT_TTS_PLAYBACK_FAILED", function(_, _, utteranceID) Voice.OnFinished(utteranceID) end)
ns.On("VOICE_CHAT_TTS_VOICES_UPDATE", function() Speaker.voices = nil end)

-- Combat: pause, and resume after, when the reader wants it.
local pausedForCombat
ns.On("PLAYER_REGEN_DISABLED", function()
	if settings().narratorCombatPause and speaking then
		pausedForCombat = true
		Voice.Pause()
	end
end)
ns.On("PLAYER_REGEN_ENABLED", function()
	if pausedForCombat then
		pausedForCombat = nil
		Voice.Resume()
	end
end)

-- After /reload the queue is still there, paused, waiting for the reader.
ns.Listen("FL_DB_READY", function()
	Speaker.settling, Speaker.pending = false, nil
	ns.db.heard = ns.db.heard or {}
	local s = state()
	if #s.ids > 0 then s.paused = true end
end)

-- Read discoveries aloud as they come, when the reader asks for it.
ns.Listen("FL_UNLOCKED", function(_, part, _, quiet)
	if quiet or not settings().narrateDiscoveries or part.kind ~= "base" then return end
	if part.entry.kind == "region" and part.entry.regionKind ~= "place" then return end
	Voice.Enqueue(part.entry.id)
end)

-- Travel mode: on a flight, the pages of each land flown over that the reader
-- has discovered but never heard are read, one land after another.
local flying = false
local function onFlightCheck()
	local onTaxi = UnitOnTaxi and UnitOnTaxi("player")
	if not onTaxi then
		flying = false
		return
	end
	if not settings().narrateFlights then return end
	flying = true
	local region = ns.Triggers.CurrentRegion()
	if not region or not P.IsFound(region.id) then return end
	local ids = {}
	if not ns.db.heard[region.id] then ids[#ids + 1] = region.id end
	for _, entry in ipairs(Lore.FiguresOf(region.id)) do
		if #ids >= 4 then break end
		if P.IsFound(entry.id) and not ns.db.heard[entry.id] then ids[#ids + 1] = entry.id end
	end
	for _, id in ipairs(ids) do Voice.Enqueue(id) end
end
Voice.OnFlightCheck = onFlightCheck
ns.On("PLAYER_CONTROL_LOST", function() C_Timer.After(1, onFlightCheck) end)
ns.On("ZONE_CHANGED_NEW_AREA", function() if flying or (UnitOnTaxi and UnitOnTaxi("player")) then onFlightCheck() end end)
ns.On("PLAYER_CONTROL_GAINED", function() flying = false end)
