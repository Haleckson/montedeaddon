local _, ns = ...

-- Colors, fonts and text markup for the book-like look.

local Theme = {}
ns.Theme = Theme

Theme.TURQUOISE = { 0.24, 0.88, 0.78 }       -- #3DE0C8, the Lorever color
Theme.TURQUOISE_HEX = "ff3de0c8"
Theme.ACCENT = Theme.TURQUOISE              -- the line under the chosen tab
Theme.TEAL_INK = "ff1f7f73"                 -- turquoise that reads on parchment
Theme.PARCHMENT = { 0.93, 0.87, 0.73 }
Theme.PARCHMENT_EDGE = { 0.55, 0.42, 0.25 }
Theme.INK = { 0.20, 0.13, 0.06 }
Theme.HEADING = "ff6b2a0a"
Theme.BOLD = "ff4a2408"
Theme.ITALIC = "ff6b5a3a"
Theme.FADED = "ff8a7f6a"

-- Looks of the book (option "Look of the book", or /lorever theme <name>):
--   lorever  the add-on's own parchment and ink (the values above)
--   dark     a dark page with light ink
--   classic  the game's quest window: its parchment and its black ink, and
--            the game's bar frame around headings and tabs
--   axell    a dark panel with gold headings on bars and boxed tabs, in the
--            manner of the game's newer quest log (a player's idea)
-- BACKGROUND is a texture of the game, named by its path (R8); nil paints the plain color.
Theme.THEMES = {
	lorever = {
		PARCHMENT = { 0.93, 0.87, 0.73 }, PARCHMENT_EDGE = { 0.55, 0.42, 0.25 }, INK = { 0.20, 0.13, 0.06 },
		HEADING = "ff6b2a0a", BOLD = "ff4a2408", ITALIC = "ff6b5a3a", FADED = "ff8a7f6a", TEAL_INK = "ff1f7f73",
		LINK = "ff1a5f8a", LINK_LOCKED = "ff5f7f8f", LINK_MISSING = "ff9a3a2a",
	},
	dark = {
		PARCHMENT = { 0.149, 0.149, 0.141 }, PARCHMENT_EDGE = { 0.26, 0.26, 0.25 }, INK = { 0.93, 0.92, 0.89 },
		HEADING = "ffd97757", BOLD = "fffaf9f5", ITALIC = "ffc2c0b6", FADED = "ff8f8c84", TEAL_INK = "ff3de0c8",
		LINK = "ff7ab8ea", LINK_LOCKED = "ff6f8fa3", LINK_MISSING = "ffe08a76",
	},
	classic = {
		PARCHMENT = { 0.89, 0.82, 0.66 }, PARCHMENT_EDGE = { 0.36, 0.26, 0.14 }, INK = { 0, 0, 0 },
		HEADING = "ff000000", BOLD = "ff000000", ITALIC = "ff2e2110", FADED = "ff5c4a34", TEAL_INK = "ff0f5c54",
		LINK = "ff0c3c8c", LINK_LOCKED = "ff4a5a70", LINK_MISSING = "ff7a1a10",
		-- The quest parchment fills only part of its 512 x 512 file: about 300 x 317 pixels.
		BACKGROUND = "Interface\\QuestFrame\\QuestBG", BACKGROUND_COORDS = { 0, 0.5859, 0, 0.62 },
		-- A light brown wash behind headings and tabs, inside the game's bar frame.
		HEADING_BAR = { 0.36, 0.26, 0.14, 0.20 }, HEADING_BAR_EDGE = { 0.36, 0.26, 0.14, 0.20 },
		TAB_BOX = { 0.36, 0.26, 0.14, 0.14 }, TAB_EDGE = { 0.36, 0.26, 0.14, 0.14 },
		GAME_BORDER = true,
	},
}
Theme.THEMES.axell = {
	PARCHMENT = { 0.075, 0.065, 0.055 }, PARCHMENT_EDGE = { 0.36, 0.28, 0.14 }, INK = { 0.92, 0.92, 0.92 },
	HEADING = "ffffc61a", BOLD = "ffffffff", ITALIC = "ffcfcfcf", FADED = "ff9c9c9c", TEAL_INK = "ff3de0c8",
	LINK = "ffffd100", LINK_LOCKED = "ffa0a0a0", LINK_MISSING = "ffff7a66",
	-- A bar behind each heading, a box around each tab, and gold where the others use turquoise.
	HEADING_BAR = { 0.17, 0.11, 0.05, 0.95 }, HEADING_BAR_EDGE = { 0.42, 0.32, 0.14, 1 },
	TAB_BOX = { 0.10, 0.085, 0.07, 1 }, TAB_EDGE = { 0.38, 0.30, 0.16, 1 },
	ACCENT = { 1, 0.78, 0.10 },
	GAME_BORDER = true, -- the game's bar frame around headings and tabs (a player's idea)
}
Theme.THEME_ORDER = { "lorever", "dark", "classic", "axell" }
Theme.name = "lorever"

-- Takes the colors of one look, and tells the open books to repaint.
function Theme.Apply(name)
	local look = Theme.THEMES[name] or Theme.THEMES.lorever
	Theme.name = Theme.THEMES[name] and name or "lorever"
	Theme.BACKGROUND, Theme.BACKGROUND_COORDS = nil, nil
	Theme.HEADING_BAR, Theme.HEADING_BAR_EDGE, Theme.TAB_BOX, Theme.TAB_EDGE = nil, nil, nil, nil
	Theme.GAME_BORDER = nil
	Theme.ACCENT = Theme.TURQUOISE
	for key, value in pairs(look) do Theme[key] = value end
	if ns.Fire then ns.Fire("FL_THEME", Theme.name) end
	return Theme.name
end

ns.Listen("FL_DB_READY", function() Theme.Apply(ns.db.settings.theme) end)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key) if key == "theme" then Theme.Apply(ns.db.settings.theme) end end)

Theme.ICON = "Interface\\Icons\\INV_Misc_Book_09"
Theme.MARKER = "Interface\\GossipFrame\\AvailableQuestIcon" -- tinted turquoise
Theme.LOCK = "|TInterface\\LFGFrame\\UI-LFG-ICON-LOCK:12:12:0:0|t"

function Theme.Color(hex, text)
	return "|c" .. hex .. text .. "|r"
end

Theme.LINK = "ff1a5f8a"         -- ink blue: a page you can read
Theme.LINK_LOCKED = "ff5f7f8f"  -- faded blue: a page not yet discovered
Theme.LINK_MISSING = "ff9a3a2a" -- faded red: a page not yet written
Theme.LINK_PREFIX = "lorever:"

-- {link:id}..{/link}, {red:id}..{/red}, {b}..{/b} and {i}..{/i} from the
-- build tool become hyperlinks and ink colors.
function Theme.Render(text)
	if not text then return "" end
	local Lore, P = ns.Lore, ns.Progress
	text = text:gsub("{link:([%w%-]+)}(.-){/link}", function(id, label)
		local color = (Lore.Get(id) and P.IsUnlocked(id)) and Theme.LINK or Theme.LINK_LOCKED
		return "|c" .. color .. "|H" .. Theme.LINK_PREFIX .. id .. "|h" .. Lore.Label(id, label) .. "|h|r"
	end)
	text = text:gsub("{red:([%w%-]+)}(.-){/red}", function(id, label)
		return "|c" .. Theme.LINK_MISSING .. "|H" .. Theme.LINK_PREFIX .. id .. "|h" .. label .. "|h|r"
	end)
	text = text:gsub("{b}", "|c" .. Theme.BOLD):gsub("{/b}", "|r")
	text = text:gsub("{i}", "|c" .. Theme.ITALIC):gsub("{/i}", "|r")
	return text
end

-- Plain text for tooltips and toasts (dark backgrounds).
function Theme.Plain(text)
	if not text then return "" end
	text = text:gsub("{link:([%w%-]+)}(.-){/link}", function(id, label) return ns.Lore.Label(id, label) end)
	text = text:gsub("{red:[%w%-]+}", ""):gsub("{/red}", "")
	return (text:gsub("{/?[bi]}", ""))
end

-- "lorever:elwynn-forest" -> "elwynn-forest"
function Theme.LinkTarget(link)
	return type(link) == "string" and link:match("^" .. Theme.LINK_PREFIX .. "([%w%-]+)$") or nil
end

-- "the-first-war" -> "The First War" (title for a page not yet written)
function Theme.TitleFromID(id)
	return (id:gsub("%-", " "):gsub("(%a)(%w*)", function(a, b) return a:upper() .. b end))
end

local function font(name, fallback)
	return _G[name] and name or fallback
end

Theme.FONT_TITLE = font("QuestTitleFont", "GameFontNormalLarge")
Theme.FONT_BODY = font("QuestFont", "GameFontHighlight")
Theme.FONT_SMALL = font("QuestFontNormalSmall", "GameFontHighlightSmall")

-- Turquoise "!" texture: the gossip quest icon, desaturated and tinted.
function Theme.Marker(texture)
	texture:SetTexture(Theme.MARKER)
	texture:SetDesaturated(true)
	texture:SetVertexColor(unpack(Theme.TURQUOISE))
end

-- A round cut for a square icon of the game (the book marks on the maps), or none.
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
function Theme.Round(owner, texture, on)
	if not (owner.CreateMaskTexture and texture.AddMaskTexture) then return end
	if on and not owner.loreverMask then
		local mask = owner:CreateMaskTexture()
		mask:SetAllPoints(texture)
		mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		owner.loreverMask = mask
	end
	local mask = owner.loreverMask
	if not mask then return end
	if on and not owner.loreverMasked then
		texture:AddMaskTexture(mask)
		owner.loreverMasked = true
	elseif not on and owner.loreverMasked then
		texture:RemoveMaskTexture(mask)
		owner.loreverMasked = false
	end
end

function Theme.PlaySound(kind)
	if not ns.db or not ns.db.settings.sound or not PlaySound or not SOUNDKIT then return end
	local id = kind == "level" and (SOUNDKIT.UI_LEVELUP or SOUNDKIT.LEVELUPSOUND)
		or SOUNDKIT.IG_QUEST_LIST_COMPLETE or SOUNDKIT.IG_QUEST_LOG_OPEN
	if id then pcall(PlaySound, id) end
end
