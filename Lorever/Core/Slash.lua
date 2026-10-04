local _, ns = ...

local N = ns.N
local HELP = {
	N("/lorever - open the book of lore"),
	N("/lorever nameplates - show friendly NPC nameplates, so lore marks can appear"),
	N("/lorever level - your Lore and Literature levels"),
	N("/lorever options - open the options"),
	N("/lorever where - the current map, zone and subzone (for writing lore data)"),
	N("/lorever found - where you found writings whose place was not yet known"),
	N("/lorever export - your community reports (writings found in new places), as text"),
	N("/lorever listen - the narrator reads the land you stand in"),
	N("/lorever pause - pause or resume the narrator"),
	N("/lorever stop - stop the narrator"),
	N("/lorever narrator - the narrator panel: voices, styles, speed and tone for each kind of page"),
	N("/lorever voicetest - the narrator says one sentence, and tells which voice it uses"),
	N("/lorever language auto|en|pt|de|fr|es|zh|ru - the add-on's language (auto follows the game)"),
	N("/lorever voices - the voices installed; /lorever voice <number> picks the narrator's voice (auto: an English one)"),
	N("/lorever theme lorever|dark|classic|axell - the look of the book"),
	N("/lorever banner - show a sample banner, to drag the banners where you want them (Shift-drag)"),
	N("/lorever resetpos - put the lore window, the banners and the buttons back in their places"),
}

local COMMANDS = {}

function COMMANDS.nameplates() ns.Markers.EnableFriendlyPlates() end

function COMMANDS.banner() ns.Toast.Sample() end

function COMMANDS.theme(rest)
	local name = (rest or ""):lower():match("^%s*(%a+)")
	if not (name and ns.Theme.THEMES[name]) then
		ns.Print(string.format(ns.T("Look of the book: %s. Choose with /lorever theme lorever, dark, classic or axell."), ns.Theme.name))
		return
	end
	ns.db.settings.theme = name
	ns.Fire("FL_SETTINGS_CHANGED", "theme")
	ns.Print(string.format(ns.T("Look of the book: %s."), name))
end

function COMMANDS.resetpos()
	ns.Window.ResetPosition()
	ns.FigureButton.ResetPosition()
	ns.Movable.ResetAll()
	ns.Print(ns.T("The lore window, the banners and the buttons are back in their places."))
end

function COMMANDS.level()
	local level, into, need = ns.Progress.Level("lore")
	local found, total = ns.Progress.Totals("lore")
	ns.Print(string.format(ns.T("Lore Level %d, %d / %d toward the next. %d of %d pages discovered."), level, into, need, found, total))
	level, into, need = ns.Progress.Level("books")
	found, total = ns.Progress.Totals("books")
	ns.Print(string.format(ns.T("Literature Level %d, %d / %d toward the next. %d of %d writings read."), level, into, need, found, total))
end

function COMMANDS.options()
	if not ns.OpenOptions() then ns.Print(ns.T("The options panel is not available.")) end
end

function COMMANDS.where()
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	local x, y = 0, 0
	if pos and pos.GetXY then x, y = pos:GetXY() end
	-- Kept in English: these lines are copied into lore data.
	ns.Print(string.format("map %s  zone \"%s\"  subzone \"%s\"  at %.1f, %.1f",
		tostring(mapID), GetRealZoneText() or "", GetSubZoneText() or "", x * 100, y * 100))
	local npcID = ns.U.UnitNpcID("target")
	if npcID then ns.Print("target npc " .. npcID) end
end

-- Places the catalogue does not know yet. Players can send these to us.
function COMMANDS.found()
	local shown = 0
	for _, book in ipairs(ns.Lore.books) do
		local at = not book.pin and not book.pins and ns.Library.FoundAt(book)
		if at then
			ns.Print(string.format(ns.T("%s: map %s, %.1f, %.1f (%s)"), book.title, tostring(at.map), at.x, at.y, at.zone or "?"))
			shown = shown + 1
		end
	end
	for _, title in ipairs(ns.Library.Unlisted()) do
		local at = ns.db.foundAt[title]
		ns.Print(string.format(ns.T("%s (unlisted)%s"), title, at and string.format(ns.T(": map %s, %.1f, %.1f (%s)"), tostring(at.map), at.x, at.y, at.zone or "?") or ""))
		shown = shown + 1
	end
	if shown == 0 then ns.Print(ns.T("Nothing new: every writing you found is already on the map.")) end
end

function COMMANDS.listen() Lorever_NarrateHere() end
function COMMANDS.pause() Lorever_NarrateToggle() end
function COMMANDS.stop() ns.Voice.Stop() end
function COMMANDS.voicetest() ns.Voice.Test() end
function COMMANDS.narrator() ns.NarratorPanel.Toggle() end

function COMMANDS.export()
	local n = #ns.Reports.Pending()
	ns.Reports.ShowExport()
	ns.Print(string.format(ns.T("%d report(s) ready."), n))
end

function COMMANDS.voices() ns.Voice.ListVoices() end

function COMMANDS.help()
	for _, line in ipairs(HELP) do ns.Print(ns.T(line)) end
end

-- Only /lorever: /lore is used by other lore addons.
SLASH_LOREVER1 = "/lorever"
SlashCmdList.LOREVER = function(msg)
	local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
	if cmd == "" then
		ns.QuestLogTab.Open()
		return
	end
	if cmd == "language" then
		local arg = ((msg or ""):match("^%s*%S+%s+(%S+)") or ""):lower()
		local pick = ({ auto = "auto", en = "enUS", enus = "enUS", english = "enUS", pt = "ptBR", ptbr = "ptBR", portugues = "ptBR", de = "deDE", dede = "deDE", deutsch = "deDE", fr = "frFR", frfr = "frFR", francais = "frFR", es = "esES", eses = "esES", espanol = "esES", mx = "esMX", esmx = "esMX", zh = "zhCN", zhcn = "zhCN", chinese = "zhCN", ru = "ruRU", ruru = "ruRU", russian = "ruRU" })[arg]
		if not pick then
			ns.Print(ns.T("Language: /lorever language auto, en or pt. Now:") .. " " .. ns.Lang())
			return
		end
		ns.db.settings.language = pick
		ns.Print(ns.T("Language saved. Type /reload to apply it."))
		return
	end
	if cmd == "voice" then
		local arg = (msg or ""):match("^%s*%S+%s+(%S+)")
		local name = ns.Voice.SetVoice(arg)
		ns.Print(name and string.format(ns.T("Narrator voice: %s."), name) or ns.T("No voice with that number. Type /lorever voices to see the list."))
		return
	end
	local fn = COMMANDS[cmd] or COMMANDS.help
	fn((msg or ""):match("^%s*%S+%s+(.-)%s*$"))
end
