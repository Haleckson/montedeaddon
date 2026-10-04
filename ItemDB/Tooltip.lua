--- LibItemDB-1.0 — the reagent tooltip.
---
--- Shows "Used by: Alchemy, Tailoring" on a material's tooltip, from the library's own
--- `GetReagentUses` data. This is the display half of folding SmexyMats in; the operator,
--- 2026-09-22: _"i don't want a smexymats bridge, i want full feature parity IN ItemDB, that addon
--- is abandoned."_ There is no fallback to that addon anywhere — the data is ours on every version.
---
--- THIS IS THE LIBRARY'S FIRST TOOLTIP HOOK, and that was previously a deliberate absence:
--- `Integrations.lua` records that RecipeMaster, SmexyMats and Leatrix Plus all hook the tooltip
--- themselves and need no bridge from us. Hooking one is a new responsibility and a new failure
--- surface, so everything here is written to fail quiet rather than loud — a tooltip is drawn on
--- every mouseover, and an error there is unusable spam rather than a useful report.
---
--- THE TRAP THIS EXISTS NOT TO REPEAT. SmexyMats' own `ModifyItemTooltip` read
--- `_G["GameTooltipTextLeft1"]` and latched a file-local `isTooltipDone` (SmexyCore.lua:280-286),
--- so it only ever behaved on `GameTooltip` itself and did nothing useful on any custom tooltip.
--- Two rules follow, and both are load-bearing:
---
---   1. **Never name a tooltip.** Every function here operates on the frame it is HANDED. A
---      consumer drawing its own tooltip calls `AddReagentLines(theirTooltip, id)` and it works.
---   2. **Never latch in a file-local.** De-duplication is keyed by the TOOLTIP FRAME (in a weak
---      table, so a transient tooltip is collectable), because two tooltips can be open at once
---      and a single boolean makes the second one silently skip its lines.

local MAJOR = "LibItemDB-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then return end

-- The library's single SavedVariables table, declared as `## SavedVariables: LibItemDB_PriceDB` in
-- every TOC. It is named for its first use (prices) and is the library's only one -- a second
-- declaration would be a TOC change that Tests/toc_spec.lua asserts against ("declares the price
-- SavedVariables in every flavour, under one name"), and it would strand this setting in a file
-- players' existing installs do not have. So the tooltip's own settings live under their own
-- top-level key inside it rather than beside the price data.
local SV_NAME = "LibItemDB_PriceDB"
local SV_KEY = "tooltip"

-- The four labels, per client language. The translations are SmexyMats' own (its Locales/*.lua,
-- which covered deDE, frFR, esES, esMX, ruRU and koKR); every other language gets English. Keyed
-- in order: expansion, source, used by, item id.
local LABELS = {
    enUS = { "Expansion:", "Source:", "Used by:", "Item ID:" },
    deDE = { "Expansion:", "Quelle(n):", "Beruf(e):", "ItemID:" },
    frFR = { "Extension:", "Source(s):", "Métier(s):", "ID de l'objet:" },
    esES = { "Expansión:", "Fuente:", "Profesión de:", "ItemID:" },
    esMX = { "Expansión:", "Fuente:", "Profesión de:", "ID Del Artículo:" },
    ruRU = { "Дополнение:", "Источник:", "Профессия:", "ItemID:" },
    koKR = { "확장팩:", "획득 방법:", "전문 기술:", "아이템ID:" },
}
local LOCALE = (GetLocale and GetLocale()) or "enUS"
local L = LABELS[LOCALE] or LABELS.enUS

-- The profession and source WORDS, per language, again SmexyMats' own translations (Locales/*.lua,
-- same six languages). The data carries these words in English; the tooltip shows the translation
-- where one exists and the English word where it does not (First Aid, PvP, Quest, Reputation,
-- Crafted, and Drop in German). Icons are still looked up by the English word.
local WORDS = ({
    deDE = { Alchemy = "Alchemie", Archaeology = "Archäologie", Blacksmithing = "Schmiedekunst",
        Cooking = "Kochkunst", Enchanting = "Verzauberkunst", Engineering = "Ingenieurskunst",
        Fishing = "Angeln", Herbalism = "Kräuterkunde", Inscription = "Inschriftenkunde",
        Jewelcrafting = "Juwelierskunst", Leatherworking = "Lederverarbeitung", Mining = "Bergbau",
        Skinning = "Kürschnerei", Tailoring = "Schneiderei", Vendor = "Verkäufer" },
    frFR = { Alchemy = "Alchimie", Archaeology = "Archéologie", Blacksmithing = "Forge",
        Cooking = "Cuisine", Drop = "Loot", Enchanting = "Enchantement", Engineering = "Ingénierie",
        Fishing = "Pêche", Herbalism = "Herboristerie", Inscription = "Calligraphie",
        Jewelcrafting = "Joaillerie", Leatherworking = "Travail du cuir", Mining = "Minage",
        Skinning = "Dépecage", Tailoring = "Couture", Vendor = "Vendeur" },
    esES = { Alchemy = "Alquimia", Archaeology = "Arqueología", Blacksmithing = "Herrería",
        Cooking = "Cocina", Enchanting = "Encantador", Engineering = "Ingenieria", Fishing = "Pescar",
        Herbalism = "Herboristería", Inscription = "Inscripción", Jewelcrafting = "Joyería",
        Leatherworking = "Peleteria", Mining = "Minería", Skinning = "Desuello",
        Tailoring = "Sastrería", Vendor = "Vendedor" },
    esMX = { Alchemy = "Alquimia", Archaeology = "Arqueología", Blacksmithing = "Herrería",
        Cooking = "Cocina", Drop = "Gota", Enchanting = "Encantador", Engineering = "Ingenieria",
        Fishing = "Pescar", Herbalism = "Herbolario", Inscription = "Inscripción",
        Jewelcrafting = "Joyería", Leatherworking = "Trabajo De Cuero", Mining = "Minería",
        Skinning = "Pelado", Tailoring = "Sastrería", Vendor = "Vendedor" },
    ruRU = { Alchemy = "Алхимия", Archaeology = "Археология", Blacksmithing = "Кузнечное дело",
        Cooking = "Кулинария", Drop = "Добыча", Enchanting = "Наложение чар",
        Engineering = "Инженерное дело", Fishing = "Рыбная ловля", Herbalism = "Травничество",
        Inscription = "Начертание", Jewelcrafting = "Ювелирное дело", Leatherworking = "Кожевничество",
        Mining = "Горное дело", Skinning = "Снятие шкур", Tailoring = "Портняжное дело",
        Vendor = "Торговец" },
    koKR = { Alchemy = "연금술", Archaeology = "고고학", Blacksmithing = "대장기술", Cooking = "요리",
        Enchanting = "마법부여", Engineering = "기계공학", ["First Aid"] = "응급치료", Fishing = "낚시",
        Herbalism = "약초채집", Inscription = "주문각인", Jewelcrafting = "보석세공",
        Leatherworking = "가죽세공", Mining = "채광", Skinning = "무두질", Tailoring = "재봉술",
        Vendor = "상인" },
})[LOCALE] or {}
local LABEL_EXPANSION, LABEL_SOURCE, LABEL_USED_BY, LABEL_ITEM_ID = L[1], L[2], L[3], L[4]
local HEADER = "ItemDB"
-- Appended to the heading, in grey, while Alt+click opens the "Where to get it" window (Where.lua),
-- so a player learns the click exists from the tooltip itself. The operator, 2026-09-24: "add the
-- directions text to 'ItemDB Alt+Click to see sources' or something like that".
-- The %s is the player's own click (ClickBindingText), "Alt+Click" by default.
local HEADER_HINT = "  |cff9d9d9d(%s: where to get it)|r"

-- GetExpansion's number -> the name and colour SmexyMats drew it in (Utilities.lua:30-31:
-- CLASSIC |cFFE6CC80, TBC |cFF1EFF00). Only the expansions this library ships data for. The NAME
-- is the client's own localised EXPANSION_NAME<n> global where it has one ("World of Warcraft:
-- Clásico", "经典旧世"), read at call time, with English as the fallback.
local EXPANSION = {
    [0] = { "Classic", 0xE6 / 255, 0xCC / 255, 0x80 / 255 },
    [1] = { "The Burning Crusade", 0x1E / 255, 1.0, 0.0 },
}
local function expansionName(n)
    local g = _G["EXPANSION_NAME" .. n]
    return type(g) == "string" and g ~= "" and g or EXPANSION[n][1]
end

-- A GetSources row's `source` kind -> the word the tooltip shows. `gathered` is absent on
-- purpose: its row's `instance` IS the profession (Mining, Herbalism, Skinning, Fishing), which
-- is the answer SmexyMats' "sourced from" line gave. A boss-graph row carries an encounterID
-- and reads "Drop" whatever provider built it. An unknown kind is skipped rather than printed
-- raw, so a kind added to the data later cannot put an internal token on a player's screen.
local SOURCE_LABEL = {
    drop = "Drop", vendor = "Vendor", crafted = "Crafted", quest = "Quest",
    pvp = "PvP", reputation = "Reputation",
}

--- The distinct "where it comes from" words for an item: the professions that produce it first
--- (gathering, disenchanting or crafting -- the answer a material's tooltip is usually asked for),
--- then the rest in first-seen order.
local function sourceLabels(self, itemID)
    local gathered, other, seen = {}, {}, {}
    local rows = self:GetSources(itemID)
    for i = 1, #rows do
        local r = rows[i]
        local label, list
        if r.source == "gathered" then
            label, list = r.instance, gathered
        elseif r.source == "crafted" and r.instance and r.instance ~= "Crafted" then
            -- The location of a crafted row is the profession that makes it (Tailoring, Mining
            -- for a smelted bar); only an item no profession teaches still reads "Crafted".
            label, list = r.instance, gathered
        elseif r.encounterID then
            label, list = SOURCE_LABEL.drop, other
        else
            label, list = SOURCE_LABEL[r.source], other
        end
        if label and not seen[label] then
            seen[label] = true
            list[#list + 1] = label
        end
    end
    for i = 1, #other do gathered[#gathered + 1] = other[i] end
    return gathered
end
-- Icons, as SmexyMats drew them (on by default there: profile.IconsEnabled = true, size 20).
-- FILE DATA IDS, NOT PATHS, and none is guessed: every id below was read from the client's own
-- ManifestInterfaceData on Vanilla 1.15.9 AND TBC 2.5.6 (wago), under Interface\ICONS\, and the
-- professions use the very textures SmexyMats' Utilities.lua:183-302 named. Keyed by the enUS
-- word the data carries (Reagents.lua and ItemLocations.lua are enUS). A word with no verified
-- icon -- Inscription, Archaeology, the bare "Crafted" -- is drawn as text, never as a guess.
-- Quest / PvP / Reputation have no SmexyMats icon; those three are our choice of existing icons.
local ICON = {
    Alchemy = 136240, Blacksmithing = 136241, Cooking = 133971, Enchanting = 136244,
    Engineering = 136243, Fishing = 136245, Herbalism = 136246, Jewelcrafting = 134071,
    Leatherworking = 136247, Mining = 136248, Skinning = 134366, Tailoring = 136249,
    ["First Aid"] = 135966,
    Drop = 132594, Vendor = 133784,
    Quest = 134327, PvP = 132486, Reputation = 134156,
}

-- A muted gold for the label and plain white for the value, matching how the game's own tooltips
-- present a "label: value" row.
local LABEL_R, LABEL_G, LABEL_B = 1.0, 0.82, 0.0
local VALUE_R, VALUE_G, VALUE_B = 1.0, 1.0, 1.0

-- Tooltips we have already decorated, keyed by FRAME and holding the item id we decorated it with.
-- Weak keys: a consumer's transient tooltip must not be kept alive by this table.
local decorated = setmetatable({}, { __mode = "k" })

-- ...AND FORGOTTEN WHEN THE TOOLTIP IS CLEARED. The table above used to be written and never
-- reset, so the second time the player hovered the same item -- every bag slot, every time -- the
-- tooltip was rebuilt from nothing and our lines were refused as "already added". The game clears
-- a tooltip before it draws the next thing on it, so OnTooltipCleared is exactly the moment the
-- memory stops being true. Hooked once per frame; a consumer's table with no HookScript keeps the
-- documented "a second call for the same item is a no-op" behaviour instead.
local clearWatched = setmetatable({}, { __mode = "k" })
local function forgetOnClear(tooltip)
    if clearWatched[tooltip] or type(tooltip.HookScript) ~= "function" then return end
    clearWatched[tooltip] = true
    pcall(tooltip.HookScript, tooltip, "OnTooltipCleared", function(tt) decorated[tt] = nil end)
end

-- `GetItemInfoInstant` is captured at load, as the rest of the library does with the APIs it needs:
-- it exists on every flavour we ship, under one spelling or the other (Classic Era has the bare
-- global; later clients moved it into C_Item).
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

-- `TooltipUtil` is read at CALL time, NOT captured, and so is TooltipDataProcessor below. Both are
-- OPTIONAL modern-client APIs rather than things we require, and capturing an optional global at
-- load records its absence permanently -- on a client that gains it later, or under a test that
-- stubs it, the captured nil is what we would keep asking. Consistency matters here too: the
-- processor was always read at call time, and half-and-half is how the two paths drift.
local function displayedItemFn()
    local util = _G.TooltipUtil
    return type(util) == "table" and util.GetDisplayedItem or nil
end

--- The item id a tooltip is currently showing, or nil.
---
--- Feature-detected across the two eras and never by flavour name: modern clients answer through
--- `TooltipUtil.GetDisplayedItem`, Classic through the tooltip's own `GetItem`. Both return a LINK,
--- which is turned into an id through `GetItemInfoInstant` rather than by parsing the link here --
--- a hand-rolled `item:(%d+)` parser is the thing that breaks on the next link format.
local function displayedItemID(tooltip)
    if type(tooltip) ~= "table" then return nil end

    local link
    local getDisplayed = displayedItemFn()
    if getDisplayed then
        local ok, _, l = pcall(getDisplayed, tooltip)
        if ok then link = l end
    end
    if not link and type(tooltip.GetItem) == "function" then
        local ok, _, l = pcall(tooltip.GetItem, tooltip)
        if ok then link = l end
    end
    if type(link) ~= "string" or link == "" then return nil end

    if not GetItemInfoInstant then return nil end
    local ok, id = pcall(GetItemInfoInstant, link)
    return ok and tonumber(id) or nil
end

-- The tooltip's settings and their defaults. The defaults are SmexyMats' own (Data/Options/
-- Defaults.lua): everything on, icons on at size 20, because a player giving that addon up should
-- see what they saw without configuring anything.
local OPTION_DEFAULTS = {
    enabled  = true,     -- the whole feature
    header   = true,     -- an "ItemDB" heading above our lines (SmexyMats' '[SM]' marker, 'SMText')
    expansion = true,    -- the "Expansion:" line (SmexyMats' 'Contents')
    source   = true,     -- the "Source:" line (SmexyMats' 'Sources')
    usedBy   = true,     -- the "Used by:" line (SmexyMats' 'Professions')
    itemID   = true,     -- the "Item ID:" line, on every item (SmexyMats' 'ItemIDs')
    icons    = true,     -- draw professions / kinds as icons rather than words
    iconSize = 20,
    -- SmexyMats' colour-blind mode (Options.lua:98-158): off by default, and when on every label
    -- takes colour #1 and every value colour #2, both chosen by the player. Six hex digits, as
    -- SmexyMats stored them (ColorBlindPickedOne / Two).
    colorblind = false,
    color1   = "ffffff",
    color2   = "ffffff",
    -- Alt+click on any item opens the "Where to get it" window (Where.lua). On by default: the
    -- default UI gives Alt+click on an item no job (HandleModifiedItemClick acts on the CHATLINK and
    -- DRESSUP modifiers only). Switchable because another addon may use Alt+click; not verified.
    altClick = true,
    -- WHICH click opens it (Where.lua, IsWhereClick): WoW's binding spelling, validated by
    -- ParseClickBinding on the way in. `altClick` above stays the on/off switch.
    whereClick = "ALT-LeftButton",
}

-- r, g, b (0..1) from six hex digits.
local function hexRGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
           tonumber(hex:sub(5, 6), 16) / 255
end
local ICON_SIZE_MIN, ICON_SIZE_MAX = 8, 64

--- The names of the on/off tooltip settings, sorted. The /itemdb window keeps its own labelled
--- list of checkboxes, and its spec checks every name here has one -- so a switch added to
--- OPTION_DEFAULTS cannot silently never reach the window.
--- @return string[] names
function lib:GetTooltipSwitches()
    local out = {}
    for k, v in pairs(OPTION_DEFAULTS) do
        if type(v) == "boolean" then out[#out + 1] = k end
    end
    table.sort(out)
    return out
end

--- A tooltip setting: the stored value, or its default. nil for a key that is not a setting.
---
--- @param key string enabled | header | expansion | source | usedBy | itemID | icons | iconSize |
---                   colorblind | color1 | color2 | altClick | whereClick
--- @return any value
function lib:GetTooltipOption(key)
    local default = OPTION_DEFAULTS[key]
    if default == nil then return nil end
    -- Explicit branches, NOT an `a and b` chain: with no SavedVariables that chain yields FALSE
    -- rather than nil, and every setting then read as "off" instead of its default -- a fresh
    -- install would have shown nothing. The spec's defaults example caught exactly that.
    local sv = _G[SV_NAME]
    if type(sv) ~= "table" or type(sv[SV_KEY]) ~= "table" then return default end
    local v = sv[SV_KEY][key]
    if v == nil then return default end
    return v
end

--- A tooltip setting's default, ignoring what is stored. Private: the /itemdb window's click
--- chooser reads it for its Default button, so the default lives in OPTION_DEFAULTS only.
--- @param key string
--- @return any default, nil for a key that is not a setting
function lib:_GetTooltipDefault(key)
    return OPTION_DEFAULTS[key]
end

--- Change a tooltip setting, persistently, through the library's SavedVariables.
---
--- A boolean setting is coerced to a boolean; iconSize is clamped to 8..64. An unknown key is
--- refused rather than stored. Called before SavedVariables exist it returns false and changes
--- nothing -- there is nowhere to keep it.
---
--- @param key string
--- @param value any
--- @return boolean applied
function lib:SetTooltipOption(key, value)
    local default = OPTION_DEFAULTS[key]
    if default == nil then return false end
    if type(default) == "boolean" then
        value = value and true or false
    elseif key == "whereClick" then
        -- A click binding, stored in its canonical spelling; anything unparsable is refused.
        value = self.ParseClickBinding and self:ParseClickBinding(value)
        if not value then return false end
    elseif type(default) == "string" then
        -- A colour: exactly six hex digits, stored lower-case. Anything else is refused rather
        -- than stored, because a bad value would reach every tooltip line's colour.
        if type(value) ~= "string" or not value:match("^%x%x%x%x%x%x$") then return false end
        value = value:lower()
    else
        value = tonumber(value)
        if not value then return false end
        value = math.max(ICON_SIZE_MIN, math.min(ICON_SIZE_MAX, math.floor(value)))
    end
    local sv = _G[SV_NAME]
    if type(sv) ~= "table" then return false end
    if type(sv[SV_KEY]) ~= "table" then sv[SV_KEY] = {} end
    sv[SV_KEY][key] = value
    return true
end

--- Whether the reagent lines are switched on. Defaults to TRUE, so a player who installs the
--- library sees the feature without configuring anything -- which is the parity that matters,
--- since the addon this replaces showed its lines by default too.
---
--- @return boolean enabled
function lib:IsReagentTooltipEnabled()
    return self:GetTooltipOption("enabled") and true or false
end

--- Turn the reagent tooltip lines on or off, persistently. Same as SetTooltipOption("enabled").
---
--- @param enabled boolean
--- @return boolean applied false only when SavedVariables are not available to write to
function lib:SetReagentTooltipEnabled(enabled)
    return self:SetTooltipOption("enabled", enabled)
end

--- The words as the tooltip draws them: icons when that setting is on (a word with no verified
--- icon stays a word), otherwise the words comma-separated.
local function render(self, words)
    local icons, size, out = self:GetTooltipOption("icons"), self:GetTooltipOption("iconSize"), {}
    for i = 1, #words do
        local id = icons and ICON[words[i]]
        out[i] = id and ("|T" .. id .. ":" .. size .. "|t") or WORDS[words[i]] or words[i]
    end
    return table.concat(out, icons and " " or ", ")
end

--- Append this library's reagent lines to a tooltip.
---
--- Works on ANY tooltip frame, including one a consumer drew itself -- the frame is the argument
--- and is never looked up by name. Safe to call more than once for the same tooltip and item: the
--- second call is a no-op rather than a duplicate line.
---
--- @param tooltip table the tooltip frame to add to
--- @param itemID number|nil the item; omitted, it is read from what the tooltip is displaying
--- @return boolean added true only when a line was actually appended
function lib:AddReagentLines(tooltip, itemID)
    if type(tooltip) ~= "table" or type(tooltip.AddDoubleLine) ~= "function" then return false end
    if not self:IsReagentTooltipEnabled() then return false end

    itemID = tonumber(itemID) or displayedItemID(tooltip)
    if not itemID then return false end

    -- Keyed by the FRAME, not a file-local flag. The game calls OnTooltipSetItem more than once for
    -- the same item on some paths, and two tooltips can be open at once.
    if decorated[tooltip] == itemID then return false end
    forgetOnClear(tooltip)

    -- Remembered whether or not anything is added: the common case is "not a reagent", and
    -- re-deriving that on every repeat call of the same tooltip is the cost this gate avoids.
    decorated[tooltip] = itemID
    local added = false

    -- The material lines, only on a reagent as SmexyMats did (a "Source:" line on every piece of
    -- gear is a different feature), in its order: Expansion, Source(s), Profession(s)
    -- (SmexyCore.lua:198-252).
    -- Every line goes through here, so colour-blind mode reaches all of them: the label takes
    -- colour #1 and the value colour #2, overriding the expansion's own colour as SmexyMats did.
    local blind = self:GetTooltipOption("colorblind")
    local lr, lg, lb = LABEL_R, LABEL_G, LABEL_B
    local cr, cg, cb
    if blind then
        lr, lg, lb = hexRGB(self:GetTooltipOption("color1"))
        cr, cg, cb = hexRGB(self:GetTooltipOption("color2"))
    end
    -- THE HEADING, drawn once before the first line. Without it the operator could not find our
    -- lines at all (2026-09-24, Deeprock Salt: "i don't see the item DB lines" -- they were there,
    -- directly under TSM's block and indistinguishable from it). The suite's other addons open
    -- their block with a blank line and their name in gold (TOGPM, TOGBankClassic), and SmexyMats
    -- marked every line "[SM]". Drawn only on a frame that has AddLine; a consumer's minimal
    -- tooltip without one still gets the lines themselves.
    local hasAddLine = type(tooltip.AddLine) == "function"
    local headed = not (self:GetTooltipOption("header") and hasAddLine)
    local icons = self:GetTooltipOption("icons")
    -- SMEXYMATS' LAYOUT, because it reads more easily (the operator, 2026-09-24, comparing the two
    -- side by side: "it's easier to people read"): every line left-aligned, and an icon row on a
    -- line of its own under its label (SmexyCore.lua:233 and :246 -- label, then the icons below).
    -- Words stay on the label's line, the value in its own colour. A frame without AddLine gets
    -- the two-column AddDoubleLine form instead, which is all it can draw.
    local function line(label, value, vr, vg, vb, iconRow)
        if not headed then
            headed = true
            tooltip:AddLine(" ")
            local combo = self.OpenWhereWindow and self:GetTooltipOption("altClick")
                and self.ClickBindingText and self:ClickBindingText()
            local hint = combo and HEADER_HINT:format(combo) or ""
            tooltip:AddLine(HEADER .. hint, lr, lg, lb)
        end
        if blind then vr, vg, vb = cr, cg, cb end
        vr, vg, vb = vr or VALUE_R, vg or VALUE_G, vb or VALUE_B
        if not hasAddLine then
            tooltip:AddDoubleLine(label, value, lr, lg, lb, vr, vg, vb)
        elseif iconRow then
            tooltip:AddLine(label, lr, lg, lb)
            tooltip:AddLine(value, vr, vg, vb)
        else
            tooltip:AddLine(("%s |cff%02x%02x%02x%s|r"):format(label, math.floor(vr * 255 + 0.5),
                math.floor(vg * 255 + 0.5), math.floor(vb * 255 + 0.5), value), lr, lg, lb)
        end
        added = true
    end

    local uses = self:GetReagentUses(itemID)
    if uses then
        local n = self:GetTooltipOption("expansion") and self:GetExpansion(itemID)
        local exp = n and EXPANSION[n]
        if exp then line(LABEL_EXPANSION, expansionName(n), exp[2], exp[3], exp[4]) end
        local sources = self:GetTooltipOption("source") and sourceLabels(self, itemID) or {}
        if #sources > 0 then line(LABEL_SOURCE, render(self, sources), nil, nil, nil, icons) end
        if self:GetTooltipOption("usedBy") then
            local names = {}
            for i = 1, #uses do names[i] = uses[i].name or tostring(uses[i].id) end
            line(LABEL_USED_BY, render(self, names), nil, nil, nil, icons)
        end
    end

    -- The item id, on EVERY item, last -- SmexyMats' 'ItemIDs' line (SmexyCore.lua:253-259), which
    -- was not gated on the item being a material.
    if self:GetTooltipOption("itemID") then line(LABEL_ITEM_ID, tostring(itemID)) end
    return added
end

-- ---------------------------------------------------------------------------
-- The automatic hook
-- ---------------------------------------------------------------------------
-- A player with no consumer addon should still see the line, which is the whole point of parity
-- with an addon they are giving up. Both eras are feature-detected, never branched on flavour:
--
--   * DATA-DRIVEN (`TooltipDataProcessor`): one handler covers every tooltip the game draws,
--     including ones that do not exist yet. Registered against Enum.TooltipDataType.Item.
--   * CLASSIC (`HookScript("OnTooltipSetItem")`): hooked per frame. HookScript COMPOSES, so this
--     runs after whatever else is already attached and cannot displace another addon's handler.
--
-- THE DETECTION IS `C_TooltipInfo`, NOT `TooltipDataProcessor`, AND GETTING THAT WRONG SHIPPED A
-- TOOLTIP THAT NEVER APPEARED ON CLASSIC ERA. Era's UI source DEFINES TooltipDataProcessor
-- (Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua:199), so registering succeeds -- but its
-- post-calls run only from TooltipDataHandlerMixin:ProcessInfo (:298), which builds a tooltip from
-- a C_TooltipInfo getter (:251), and Era's C_TooltipInfo has no functions. Era draws bag, link and
-- vendor tooltips natively, so a registered post-call there is never called. The old code took a
-- successful registration as proof, returned, and never hooked OnTooltipSetItem: the operator saw
-- SmexyMats' lines on Runecloth and none of ours. A client whose item tooltips really are
-- data-driven has the getters, so their presence is what decides.
--
-- TEST THE FUNCTION, NEVER THE NAMESPACE. Era DOES define a C_TooltipInfo table -- with an EMPTY
-- function list (Era's TooltipInfoDocumentation.lua:5 and :8-10; Peer Review, inbox 8f920dbe) --
-- so "simplifying" this to `if C_TooltipInfo then` would bring the v1.0.0 bug straight back.
local function dataDrivenItemTooltips()
    local info = _G.C_TooltipInfo
    return type(info) == "table" and type(info.GetBagItem) == "function"
end
--
-- Only the two tooltips the game itself draws items on are hooked. A consumer's own tooltip calls
-- AddReagentLines directly -- hooking frames we do not own is how a library starts surprising people.
local HOOK_FRAMES = { "GameTooltip", "ItemRefTooltip" }
local hooked = false

--- Attach the automatic tooltip hook. Idempotent, and called once at load.
---
--- Separated from the load so a consumer that wants the data without the display can simply never
--- call it. Failures are swallowed on purpose: a broken hook must not take the library down with
--- it, because everything else here works without one.
---
--- `frames` exists because the target should be stateable rather than implied. It defaults to the
--- two tooltips the game itself draws items on, which is what the load-time call uses; a consumer
--- with its own PERSISTENT tooltip can pass that instead of calling AddReagentLines by hand on
--- every refresh. It is also the only way to drive this under test, since the harness owns
--- `GameTooltip` and a spec cannot put a stand-in there.
---
--- @param frames table|nil list of tooltip frames to hook; defaults to the game's own
--- @return boolean attached false when there was nothing to hook, which is not an error
function lib:EnableReagentTooltip(frames)
    if hooked and not frames then return true end

    -- The data-driven route first, where one registration covers every tooltip the game draws --
    -- including ones that do not exist yet, which per-frame hooking cannot reach. Skipped when
    -- the caller named specific frames, because then they have said what they want hooked, and
    -- skipped on a client whose tooltips would never call it (see dataDrivenItemTooltips).
    if not frames and dataDrivenItemTooltips() then
        local processor = _G.TooltipDataProcessor
        local dataType = _G.Enum and _G.Enum.TooltipDataType and _G.Enum.TooltipDataType.Item
        if processor and type(processor.AddTooltipPostCall) == "function" and dataType then
            -- The client hands the item id in the tooltip data, which saves resolving a link.
            local ok = pcall(processor.AddTooltipPostCall, dataType, function(tooltip, data)
                lib:AddReagentLines(tooltip, type(data) == "table" and data.id or nil)
            end)
            if ok then
                hooked = true
                return true
            end
        end
    end

    local targets = frames
    if not targets then
        targets = {}
        for _, name in ipairs(HOOK_FRAMES) do targets[#targets + 1] = _G[name] end
    end

    local any = false
    for _, frame in ipairs(targets) do
        if type(frame) == "table" and type(frame.HookScript) == "function" then
            local ok = pcall(frame.HookScript, frame, "OnTooltipSetItem", function(tt)
                lib:AddReagentLines(tt)
            end)
            any = any or ok
        end
    end
    hooked = hooked or any
    return any
end

lib:EnableReagentTooltip()
