local _, ns = ...

-- The narrator panel (/lorever narrator): which voice reads each kind of page,
-- in each language, and the reader's own narrator profiles. Every row has a
-- Test button that reads a short sentence with that choice.
--
-- Only frames of our own: no Blizzard menus or dropdowns (COMPLIANCE.md, R3).
-- Lists open in a small panel of ours; sliders are plain sliders.

local NP = {}
ns.NarratorPanel = NP

local Theme = ns.Theme
local Profiles = ns.VoiceProfiles

local frame
local lang -- the language being edited
local N = ns.N
local ENGINE_NAMES = {
	auto = N("Automatic"),
	game = N("Built-in TTS (the game's voice)"),
	pack = N("Voice pack (Lorever Narration)"),
}
local editing -- the profile id being edited
local widgets = {}

-- A list of choices in a little panel of ours ------------------------------------------------

local list
local function closeList() if list then list:Hide() end end

local function openList(anchor, items, onPick)
	if not list then
		list = CreateFrame("Frame", "LoreverNarratorList", UIParent)
		list:SetFrameStrata("FULLSCREEN_DIALOG")
		list:EnableMouse(true)
		local bg = list:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.06, 0.05, 0.04, 0.97)
		list.rows = {}
	end
	for _, r in ipairs(list.rows) do r:Hide() end
	local width = math.max(anchor:GetWidth() or 160, 160)
	for i, item in ipairs(items) do
		local r = list.rows[i]
		if not r then
			r = CreateFrame("Button", nil, list)
			r:SetHeight(18)
			r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			r.text:SetPoint("LEFT", 6, 0)
			r.text:SetJustifyH("LEFT")
			r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			list.rows[i] = r
		end
		r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 18)
		r:SetWidth(width - 4)
		r.text:SetText(item.label)
		r:SetScript("OnClick", function() closeList() onPick(item.value) end)
		r:Show()
	end
	list:SetSize(width, 4 + #items * 18)
	list:ClearAllPoints()
	list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	list:Show()
end

local function picker(parent, width)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 22)
	b:SetScript("OnClick", function(self)
		if list and list:IsShown() then return closeList() end
		openList(self, self.items and self.items() or {}, function(v) if self.onPick then self.onPick(v) end end)
	end)
	return b
end

local function button(parent, label, width, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 22)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	return b
end

local function text(parent, label, font)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
	fs:SetText(label or "")
	fs:SetJustifyH("LEFT")
	return fs
end

-- A plain slider with a label and its value.
local function slider(parent, label, min, max, step, format, onChange)
	local s = CreateFrame("Slider", nil, parent)
	s:SetOrientation("HORIZONTAL")
	s:SetSize(170, 14)
	s:SetMinMaxValues(min, max)
	s:SetValueStep(step)
	if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
	s:EnableMouse(true)
	s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("LEFT", 0, 0)
	track:SetPoint("RIGHT", 0, 0)
	track:SetHeight(4)
	track:SetColorTexture(0.35, 0.3, 0.22, 0.9)
	s.label = text(parent, label)
	s.label:SetPoint("RIGHT", s, "LEFT", -8, 0)
	s.value = text(parent, "")
	s.value:SetPoint("LEFT", s, "RIGHT", 8, 0)
	s.format = format
	s:SetScript("OnValueChanged", function(self, v)
		self.value:SetText(string.format(self.format, v))
		if not self.quiet and onChange then onChange(v) end
	end)
	function s:Put(v)
		self.quiet = true
		self:SetValue(v)
		self.value:SetText(string.format(self.format, v))
		self.quiet = nil
	end
	function s:SetActive(on)
		self:EnableMouse(on)
		self:SetAlpha(on and 1 or 0.4)
		self.label:SetAlpha(on and 1 or 0.4)
		self.value:SetAlpha(on and 1 or 0.4)
	end
	return s
end

-- Choices -------------------------------------------------------------------------------------

local function profileItems()
	local items = {}
	for _, p in ipairs(Profiles.List(lang)) do
		items[#items + 1] = { label = (p.builtin and "" or "* ") .. ns.T(p.name or "?"), value = p.id }
	end
	return items
end

local function profileName(id)
	local p = Profiles.Get(id, lang)
	return ns.T(p.name or "?")
end

local function gameVoiceItems()
	local items = { { label = ns.T("Automatic (a voice of this language)"), value = false } }
	for _, v in ipairs(ns.Voice.Speaker.Voices()) do
		items[#items + 1] = { label = v.name or tostring(v.voiceID), value = v.voiceID }
	end
	return items
end

local function gameVoiceName(id)
	if not id then return ns.T("Automatic (a voice of this language)") end
	for _, v in ipairs(ns.Voice.Speaker.Voices()) do if v.voiceID == id then return v.name or tostring(id) end end
	return ns.T("Automatic (a voice of this language)")
end

-- Refresh -------------------------------------------------------------------------------------

function NP.Refresh()
	if not frame or not frame:IsShown() then return end
	local engine, choice = Profiles.Engine(lang), Profiles.Choice()
	widgets.engine:SetText(ns.T(ENGINE_NAMES[choice] or "Automatic"))
	widgets.lang:SetText(ns.T(Profiles.LANG_NAMES[lang]))
	for _, row in ipairs(widgets.kinds) do row.pick:SetText(profileName(Profiles.UseOf(lang, row.kind))) end

	local p = Profiles.Get(editing, lang)
	if p.lang and p.lang ~= lang and not p.builtin then editing = Profiles.UseOf(lang, "region") p = Profiles.Get(editing, lang) end
	local own = not p.builtin
	widgets.edit:SetText(profileName(editing))
	widgets.delete:SetEnabled(own)
	widgets.name:SetText(own and (p.name or "") or "")
	widgets.name:SetShown(own)
	widgets.nameLabel:SetShown(own)
	widgets.styleNote:SetShown(not own)

	local game = engine == "game"
	widgets.packNote:SetShown(not game)
	local packs = ns.Voice.Pack.List(lang)
	widgets.pack:SetShown(not game and #packs > 1)
	widgets.packLabel:SetShown(not game and #packs > 1)
	if #packs > 0 then widgets.pack:SetText(ns.Voice.Pack.TitleOf(packs[1])) end
	for _, w in ipairs(widgets.gameGroup) do w:SetShown(game) end
	if game then
		local _, gameRate, gameVolume = ns.Voice.Speaker.Profile(nil, lang, { game = {} })
		local rate, volume = Profiles.GameRateVolume(p, gameRate - 0, gameVolume)
		widgets.gameVoice:SetText(gameVoiceName(p.game and p.game.voiceID))
		widgets.gameVoice:SetEnabled(own)
		widgets.rate:Put(rate)
		widgets.volume:Put(volume)
		widgets.rate:SetActive(own)
		widgets.volume:SetActive(own)
	end
	widgets.status:SetText(ns.Voice.Pack.Installed(lang)
		and ns.T("A Lorever Narration pack is installed for this language: \"Automatic\" reads with its storyteller.")
		or ns.T("Voices, speed and volume of the game's Text to Speech. Want a natural storyteller voice? Install the Lorever Narration pack of your language, from CurseForge."))
end

-- Build ---------------------------------------------------------------------------------------

local function set(path) return function(v) Profiles.Set(editing, path, v) end end

local function build()
	frame = CreateFrame("Frame", "LoreverNarratorPanel", UIParent)
	frame:SetSize(470, 600)
	frame:SetPoint("CENTER", -200, 20)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnHide", closeList)
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.96)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 2)

	local title = text(frame, ns.T("Lorever narrator"), "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 14, -12)
	title:SetTextColor(unpack(Theme.TURQUOISE))

	-- Engine: who speaks
	local engineLabel = text(frame, ns.T("Voice:"), "GameFontNormal")
	engineLabel:SetPoint("TOPLEFT", 14, -44)
	widgets.engine = picker(frame, 260)
	widgets.engine:SetPoint("TOPLEFT", 100, -40)
	widgets.engine.items = function()
		local items = {}
		for _, e in ipairs(Profiles.ENGINES) do
			-- The voice pack is offered only when a pack for this language is installed.
			if e ~= "pack" or ns.Voice.Pack.Installed(lang) then
				items[#items + 1] = { label = ns.T(ENGINE_NAMES[e]), value = e }
			end
		end
		return items
	end
	widgets.engine.onPick = function(v) Profiles.SetEngine(v) NP.Refresh() end

	-- Language
	local langLabel = text(frame, ns.T("Language:"), "GameFontNormal")
	langLabel:SetPoint("TOPLEFT", 14, -76)
	widgets.lang = picker(frame, 200)
	widgets.lang:SetPoint("TOPLEFT", 100, -72)
	widgets.lang.items = function()
		local items = {}
		for _, l in ipairs(Profiles.LANGS) do items[#items + 1] = { label = ns.T(Profiles.LANG_NAMES[l]), value = l } end
		return items
	end
	widgets.lang.onPick = function(v) lang = v editing = Profiles.UseOf(lang, "region") NP.Refresh() end

	-- What reads each kind of page
	local head = text(frame, ns.T("Who reads each kind of page"), "GameFontNormal")
	head:SetPoint("TOPLEFT", 14, -108)
	head:SetTextColor(unpack(Theme.TURQUOISE))
	widgets.kinds = {}
	for i, k in ipairs(Profiles.KINDS) do
		local y = -130 - (i - 1) * 26
		local l = text(frame, ns.T(k.label))
		l:SetPoint("TOPLEFT", 14, y - 4)
		l:SetWidth(170)
		local pick = picker(frame, 170)
		pick:SetPoint("TOPLEFT", 190, y)
		pick.items = profileItems
		pick.onPick = function(v) Profiles.SetUse(lang, k.key, v) editing = v NP.Refresh() end
		local test = button(frame, ns.T("Test"), 70, function() ns.Voice.TestProfile(lang, Profiles.UseOf(lang, k.key)) end)
		test:SetPoint("LEFT", pick, "RIGHT", 6, 0)
		widgets.kinds[i] = { kind = k.key, pick = pick }
	end

	-- Edit a profile
	local y0 = -130 - #Profiles.KINDS * 26 - 14
	local editHead = text(frame, ns.T("Narrator profile"), "GameFontNormal")
	editHead:SetPoint("TOPLEFT", 14, y0)
	editHead:SetTextColor(unpack(Theme.TURQUOISE))
	widgets.edit = picker(frame, 170)
	widgets.edit:SetPoint("TOPLEFT", 14, y0 - 20)
	widgets.edit.items = profileItems
	widgets.edit.onPick = function(v) editing = v NP.Refresh() end
	local new = button(frame, ns.T("Copy"), 80, function()
		editing = Profiles.Duplicate(editing, lang)
		NP.Refresh()
	end)
	new:SetPoint("LEFT", widgets.edit, "RIGHT", 6, 0)
	widgets.delete = button(frame, ns.T("Delete"), 80, function()
		Profiles.Delete(editing)
		editing = Profiles.UseOf(lang, "region")
		NP.Refresh()
	end)
	widgets.delete:SetPoint("LEFT", new, "RIGHT", 6, 0)

	-- Which pack reads first, when a language has several (a second voice, or one a player recorded).
	widgets.packLabel = text(frame, ns.T("Pack:"), "GameFontNormal")

	widgets.pack = picker(frame, 260)

	widgets.pack.items = function()
		local items = {}
		for _, id in ipairs(ns.Voice.Pack.List(lang)) do items[#items + 1] = { label = ns.Voice.Pack.TitleOf(id), value = id } end
		return items
	end
	widgets.pack.onPick = function(v) ns.Voice.Pack.Choose(v) NP.Refresh() end
	widgets.packNote = text(frame, ns.T("The voice pack reads every page with its own storyteller, made in advance. Choose another voice to set your own."))
	widgets.packNote:SetPoint("TOPLEFT", 14, y0 - 84)
	widgets.packNote:SetWidth(440)
	widgets.packLabel:SetPoint("TOPLEFT", widgets.packNote, "BOTTOMLEFT", 0, -14)
	widgets.pack:SetPoint("LEFT", widgets.packLabel, "RIGHT", 8, 0)
	widgets.styleNote = text(frame, ns.T("The ready-made styles cannot be changed. Press Copy to make your own profile from this one."))
	widgets.styleNote:SetPoint("TOPLEFT", 14, y0 - 48)
	widgets.styleNote:SetWidth(440)
	widgets.nameLabel = text(frame, ns.T("Name:"))
	widgets.nameLabel:SetPoint("TOPLEFT", 14, y0 - 52)
	widgets.name = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	widgets.name:SetSize(200, 20)
	widgets.name:SetPoint("TOPLEFT", 64, y0 - 48)
	widgets.name:SetAutoFocus(false)
	widgets.name:SetMaxLetters(40)
	widgets.name:SetScript("OnEnterPressed", function(self) Profiles.Set(editing, "name", self:GetText()) self:ClearFocus() NP.Refresh() end)
	widgets.name:SetScript("OnEscapePressed", function(self) self:ClearFocus() NP.Refresh() end)

	local y1 = y0 - 80
	-- The game's voice
	local gvLabel = text(frame, ns.T("Voice"))
	gvLabel:SetPoint("TOPLEFT", 14, y1 - 4)
	widgets.gameVoice = picker(frame, 300)
	widgets.gameVoice:SetPoint("TOPLEFT", 120, y1)
	widgets.gameVoice.items = gameVoiceItems
	widgets.gameVoice.onPick = function(v) Profiles.Set(editing, "game.voiceID", v or nil) NP.Refresh() end
	widgets.rate = slider(frame, ns.T("Speed"), -10, 10, 1, "%d", set("game.rate"))
	widgets.rate:SetPoint("TOPLEFT", 120, y1 - 36)
	widgets.volume = slider(frame, ns.T("Volume"), 0, 100, 5, "%d", set("game.volume"))
	widgets.volume:SetPoint("TOPLEFT", 120, y1 - 62)
	widgets.gameGroup = { gvLabel, widgets.gameVoice, widgets.rate, widgets.rate.label, widgets.rate.value,
		widgets.volume, widgets.volume.label, widgets.volume.value }

	local testProfile = button(frame, ns.T("Test this profile"), 140, function() ns.Voice.TestProfile(lang, editing) end)
	testProfile:SetPoint("BOTTOMLEFT", 14, 58)
	local reset = button(frame, ns.T("Back to the styles"), 140, function() Profiles.Reset(lang) NP.Refresh() end)
	reset:SetPoint("LEFT", testProfile, "RIGHT", 8, 0)

	widgets.status = text(frame, "")
	widgets.status:SetPoint("BOTTOMLEFT", 14, 12)
	widgets.status:SetWidth(440)
	widgets.status:SetTextColor(0.75, 0.72, 0.65)

	frame:SetScript("OnShow", NP.Refresh)
	frame:Hide()
end

function NP.Toggle()
	if not frame then build() end
	if frame:IsShown() then return frame:Hide() end
	lang = (ns.Lore and ns.Lore.language) or "enUS"
	editing = Profiles.UseOf(lang, "region")
	frame:Show()
	NP.Refresh()
end

ns.Listen("FL_VOICE_PROFILES", function() NP.Refresh() end)
