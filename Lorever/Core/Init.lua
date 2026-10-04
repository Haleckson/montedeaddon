local ADDON, ns = ...

ns.name = ADDON
ns.version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"

ns.defaults = {
	schema = 1,
	settings = {
		accountWide = true,      -- discoveries are shared by every character
		questLogTab = true,      -- "Lore" tab beside the quest log
		nameplateMarkers = true, -- turquoise "!" above undiscovered figures
		mapPins = true,          -- turquoise "!" on the world map
		mapPinsDiscovered = false,
		unitTooltip = true,
		toasts = true,
		sound = true,
		mouseoverDiscovery = true, -- passing the mouse over a figure discovers it
		bookPins = true,           -- book icons on the map for books not yet read
		tracker = true,            -- the Lore tracker on the right of the screen
		trackerAuto = true,        -- it also lists the nearest undiscovered lore
		trackerAutoCount = 3,
		useQuestieIcons = false,   -- draw marks with Questie's icons (map and minimap)
		narrator = true,           -- read lore aloud with the game's text-to-speech
		narratorBar = true,        -- the narrator bar while reading
		narratorCombatPause = false,
		narrateDiscoveries = false, -- read each new discovery aloud
		narrateFlights = false,    -- travel mode: read the lands flown over
		minimapButton = true,
		continentPins = true,      -- on a continent map, one mark per zone with what is left
		questLore = true,          -- a lore line in quest windows
		targetButton = true,       -- a book button by the target frame, for figures with a page
		mapButton = true,          -- the book button on the world map (Lorever's marks)
		bookNote = true,           -- beside an open book: how many of its pages are kept
		bagBooks = true,           -- a writing in your bags is found, even before you open it
		rightClickLore = true,     -- a right-click on a figure that opens no window opens its page
		itemTooltip = true,        -- Literature lines on item tooltips
		minimapPins = true,        -- turquoise marks on the minimap
		theme = "lorever",         -- the look of the book: "lorever", "dark" or "classic"
		language = "auto",         -- "auto" (the game's language), "enUS" or "ptBR"
	},
	account = { unlocked = {} }, -- [partKey] = time
	chars = {},                  -- [charKey] = { unlocked = {} }
	read = {},                   -- [partKey] = true once opened in the panel
	tips = {},                   -- one-time tips already shown
	localNames = {},             -- [entry id] = the name the game showed in the reader's language
	texts = {},                  -- [title] = { pages = { [n] = text }, count, at }: writings read in the world
	foundAt = {},                -- [title] = { map, x, y, zone, subzone, at }: where a writing was first read
}

-- Event bus ----------------------------------------------------------------

local frame = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
	local list = handlers[event]
	if not list then
		list = {}
		handlers[event] = list
		frame:RegisterEvent(event)
	end
	list[#list + 1] = fn
end

frame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then return end
	for i = 1, #list do
		local ok, err = pcall(list[i], event, ...)
		if not ok then geterrorhandler()(err) end
	end
end)

local listeners = {}

function ns.Listen(message, fn)
	listeners[message] = listeners[message] or {}
	table.insert(listeners[message], fn)
end

function ns.Fire(message, ...)
	local list = listeners[message]
	if not list then return end
	for i = 1, #list do
		local ok, err = pcall(list[i], message, ...)
		if not ok then geterrorhandler()(err) end
	end
end

-- Saved variables ----------------------------------------------------------

local function applyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then target[key] = {} end
			applyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end
ns.applyDefaults = applyDefaults

ns.On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	LoreverDB = LoreverDB or {}
	applyDefaults(LoreverDB, ns.defaults)
	ns.db = LoreverDB
	ns.db.showcase = nil -- every reader sees their own progress
	ns.lang = ns.Lang()
	if ns.lang ~= "enUS" and ns.Lore and ns.Lore.ApplyLanguage then
		ns.Lore.ApplyLanguage(ns.lang)
		for id, name in pairs(LoreverDB.localNames) do ns.Lore.SetLocalName(id, name) end
	end
	-- Keep in memory only the language in use: a change of language needs /reload.
	if ns.Lore and ns.Lore.translations then
		ns.Lore.translations = { [ns.lang] = ns.Lore.translations[ns.lang] }
	end
	ns.Fire("FL_DB_READY")
end)

ns.On("PLAYER_LOGIN", function()
	ns.Fire("FL_LOGIN")
end)

-- Language -------------------------------------------------------------------

-- The language of the add-on: the setting, or the game's own language when a
-- translation exists for it. English otherwise.
ns.LOCALES = { enUS = true, ptBR = true, deDE = true, frFR = true, esES = true, esMX = true, zhCN = true, ruRU = true }
function ns.Lang()
	local wanted = ns.db and ns.db.settings.language or "auto"
	if wanted == "auto" then wanted = GetLocale and GetLocale() or "enUS" end
	return ns.LOCALES[wanted] and wanted or "enUS"
end

-- Interface text: ns.T("English") gives the active language's text, or the English.
ns.L = {} -- [locale] = { [english] = translated }, filled by Locales/*.lua
function ns.T(text)
	local set = ns.L[ns.lang or "enUS"]
	return set and set[text] or text
end

-- Marks English text kept in a table at load time, before the language is known.
-- It changes nothing: the text is translated with ns.T where it is shown.
-- (tools/i18n_check.py reads ns.N and ns.T to find every text to translate.)
function ns.N(text)
	return text
end

function ns.Print(msg)
	print("|cff3de0c8Lorever|r: " .. tostring(msg))
end

-- Helpers ------------------------------------------------------------------

local U = {}
ns.U = U

function U.CharKey()
	return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

function U.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) or false
end

function U.InCombat()
	return InCombatLockdown and InCombatLockdown() or false
end

-- Creature GUID: Creature-0-[server]-[instance]-[zone]-[npcID]-[spawnUID]
function U.NpcID(guid)
	if type(guid) ~= "string" or U.IsSecret(guid) then return nil end
	local kind, _, _, _, _, npcID = strsplit("-", guid)
	if kind == "Creature" or kind == "Vehicle" then return tonumber(npcID) end
end

function U.UnitNpcID(unit)
	if not UnitExists(unit) then return nil end
	return U.NpcID(UnitGUID(unit))
end
