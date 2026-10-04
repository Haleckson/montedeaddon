local ADDON, ns = ...

-- Options: Esc > Options > AddOns > Lorever.

local N = ns.N
local OPTIONS = {
	{ "accountWide", N("Share lore across characters"), N("Everything one of your characters discovers is known to all of them. Turn off to let each character discover the world alone.") },
	{ "questLogTab", N("Lore tab in the quest log"), N("Adds a Lore tab beside the quest log. Takes effect after /reload.") },
	{ "nameplateMarkers", N("Mark figures above their heads"), N("Shows a turquoise mark above figures whose lore you have not yet discovered. Needs friendly NPC nameplates (/lorever nameplates).") },
	{ "mapPins", N("Mark figures on the world map"), N("Shows a turquoise mark on the map where figures with undiscovered lore can be found.") },
	{ "mouseoverDiscovery", N("Discover figures at a glance"), N("A figure's lore is discovered as soon as you pass the mouse over them, not only when you speak with them.") },
	{ "bookPins", N("Mark unread books on the world map"), N("Shows a book on the map where a book you have not yet read can be found.") },
	{ "mapPinsDiscovered", N("Also mark discovered figures"), N("Keeps a faded mark on the map for figures you already know.") },
	{ "unitTooltip", N("Lore line on tooltips"), N("Adds a Lore line to the tooltip of figures with lore.") },
	{ "toasts", N("Discovery banners"), N("Shows a banner when you discover lore or reach a new Lore level.") },
	{ "sound", N("Discovery sounds"), N("Plays a sound with each banner.") },
	{ "tracker", N("Lore tracker"), N("Shows the figures and writings you track on the right of the screen, under the quest tracker (and under Questie's, when it is there).") },
	{ "trackerAuto", N("Track the nearest lore"), N("The tracker also lists the three nearest figures and writings you have not yet found in this zone.") },
	{ "narrator", N("Read lore aloud"), N("A Listen button on every page reads it aloud. Choose voices, styles, speed and tone in the narrator panel (/lorever narrator).") },
	{ "narratorBar", N("Narrator bar"), N("While lore is read aloud, a small bar with pause, next and stop stays on screen, so you can close the book and keep playing.") },
	{ "narratorCombatPause", N("Pause the narrator in combat"), N("Pauses when a fight starts and resumes after it.") },
	{ "narrateDiscoveries", N("Read discoveries aloud"), N("Each figure, place or writing you discover is added to the narrator's queue.") },
	{ "narrateFlights", N("Travel mode"), N("On a flight, the narrator reads the lands you fly over: the pages you have discovered but never heard.") },
	{ "minimapButton", N("Minimap button"), N("A book button by the minimap. Click to open, right-click for the narrator, drag to move.") },
	{ "continentPins", N("Lore left on continent maps"), N("On a continent map, each zone shows how much lore is left to find there.") },
	{ "questLore", N("Lore in quest windows"), N("A quest that reveals lore says so in its window.") },
	{ "bookNote", N("Pages kept, beside an open book"), N("While a book is open, a small note says how many of its pages Lorever has kept. Lorever never turns a page for you.") },
	{ "bagBooks", N("Find writings by picking them up"), N("A book, letter or journal counts as found as soon as it is in your bags, before you open it.") },
	{ "mapButton", N("Book button on the world map"), N("The small book on the world map that chooses which Lorever marks are shown. Shift-drag to move it.") },
	{ "targetButton", N("Lore button on your target"), N("When your target is a figure with a lore page, a small book button appears by the target frame. Click it to open the page. Shift-drag to move it.") },
	{ "rightClickLore", N("Right-click a figure to open its lore"), N("A right-click on a friendly figure that opens no window of its own (no quest, shop or talk) opens its lore page. Never in combat.") },
	{ "itemTooltip", N("Literature on item tooltips"), N("Books, letters and journals say on their tooltip whether you have read them.") },
	{ "minimapPins", N("Marks on the minimap"), N("Shows the nearest undiscovered figures and writings on the minimap. (With Use Questie icons, Questie draws them instead.)") },
	{ "useQuestieIcons", N("Use Questie icons"), N("When Questie is installed, draws Lorever's marks with Questie's icons: on the minimap too, and hidden or shown with Questie's own buttons.") },
}

local THEME_NAMES = { lorever = N("Lorever (parchment)"), dark = N("Dark"), classic = N("Classic (quest window)"), axell = N("Axell (dark and gold)") }

local function build()
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then return end
	local s = ns.db.settings
	local category = Settings.RegisterVerticalLayoutCategory(ADDON)
	-- The look of the book: a list with the three looks.
	pcall(function()
		local setting = Settings.RegisterAddOnSetting(category, ADDON .. "_theme", "theme", s,
			Settings.VarType.String, ns.T("Look of the book"), ns.defaults.settings.theme)
		local function looks()
			local container = Settings.CreateControlTextContainer()
			for _, key in ipairs(ns.Theme.THEME_ORDER) do container:Add(key, ns.T(THEME_NAMES[key])) end
			return container:GetData()
		end
		Settings.CreateDropdown(category, setting, looks, ns.T("Lorever: the add-on's own parchment. Dark: a dark page with light ink. Classic: the look of the game's quest window. Axell: a dark panel with gold headings."))
		if setting.SetValueChangedCallback then
			setting:SetValueChangedCallback(function() ns.Fire("FL_SETTINGS_CHANGED", "theme") end)
		end
	end)
	for _, row in ipairs(OPTIONS) do
		local key, name, tip = row[1], row[2], row[3]
		local setting = Settings.RegisterAddOnSetting(category, ADDON .. "_" .. key, key, s,
			Settings.VarType.Boolean, ns.T(name), ns.defaults.settings[key])
		Settings.CreateCheckbox(category, setting, ns.T(tip))
		if setting.SetValueChangedCallback then
			setting:SetValueChangedCallback(function()
				ns.Progress.Invalidate()
				ns.Fire("FL_SETTINGS_CHANGED", key)
			end)
		end
	end
	Settings.RegisterAddOnCategory(category)
	ns.settingsCategory = category
end

ns.Listen("FL_DB_READY", function()
	local ok, err = pcall(build)
	if not ok then ns.Print(ns.T("options panel:") .. " " .. tostring(err)) end
end)

ns.Listen("FL_SETTINGS_CHANGED", function()
	ns.Markers.UpdateAll()
end)

function ns.OpenOptions()
	if ns.settingsCategory and Settings.OpenToCategory then
		Settings.OpenToCategory(ns.settingsCategory:GetID())
		return true
	end
	return false
end
