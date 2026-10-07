--[[
  Forever Companion - Settings/SettingsSchema.lua
  Declarative description of the settings window. Each category has sections
  of controls bound to setting paths; the window renders them generically.
  Adding a setting = adding one line here plus its default in Constants.lua.

  Control types:
    checkbox  { path, label, tip, disabled() }
    checkgrid { items() -> { {path, text, icon} }, columns }  (a nil setting counts as on)
    slider    { path, label, min, max, step, format(v) }
    dropdown  { path, label, items() -> { {value, text, icon} } }
    color     { role, label }                          (theme role override)
    button    { label, onClick(), style }
    note      { text }                                 (muted paragraph)
    custom    { build(parent, width) -> frame, height }
]]

local _, FC = ...

local L = FC.L

local ICON = "Interface\\Icons\\"

local function pages()
    local items = {}
    for _, page in ipairs(FC.MainWindow.PAGES) do
        if page.kind ~= "action" then items[#items + 1] = { value = page.key, text = L[page.label], icon = page.icon } end
    end
    return items
end

local function themes()
    local items = {}
    for _, name in ipairs(FC.Theme:List()) do
        items[#items + 1] = { value = name, text = FC.Theme:IsPreset(name) and name or (name .. "  (" .. L.CUSTOM .. ")") }
    end
    return items
end

local function fonts()
    local items = {}
    for _, font in ipairs(FC.Fonts:List()) do items[#items + 1] = { value = font.name, text = font.name } end
    return items
end

local function sounds()
    local items = {}
    for _, name in ipairs(FC.Compat.SOUNDS) do
        if FC.Compat.SoundAvailable(name) then
            items[#items + 1] = { value = name, text = L["SOUND_" .. name] }
        end
    end
    return items
end

local function notificationCategories()
    local items = {}
    for _, entry in ipairs(FC.Notifications:CategoryList()) do
        items[#items + 1] = { path = "notifications.categories." .. entry.key, text = entry.label, icon = entry.icon }
    end
    return items
end

local MAP_GROUP_ICONS = {
    quest = "INV_Misc_Note_02", rare = "INV_Misc_Head_Dragon_01", vendor = "INV_Misc_Bag_10",
    recipe = "INV_Scroll_04", npc = "INV_Misc_Head_Human_01", creature = "Ability_Hunter_Pet_Wolf",
    secret = "INV_Misc_QuestionMark", treasure = "INV_Box_02", explored = "INV_Misc_Map_01",
    dungeon = "INV_Misc_Key_03", profession = "Trade_Herbalism", path = "Ability_Tracking",
    note = "INV_Misc_Note_01", other = "INV_Misc_Gear_01",
}

local function mapGroups()
    local items = {}
    for _, group in ipairs(FC.Categories.MAP_GROUPS) do
        items[#items + 1] = {
            path = "map.hiddenGroups." .. group.key,
            text = L[group.label],
            icon = MAP_GROUP_ICONS[group.key] and (ICON .. MAP_GROUP_ICONS[group.key]),
        }
    end
    return items
end

local function mapPreset(everything)
    return function()
        local hidden = {}
        for _, group in ipairs(FC.Categories.MAP_GROUPS) do
            hidden[group.key] = not everything and FC.Defaults.map.hiddenGroups[group.key] == true
        end
        FC.Config:Set("map.hiddenGroups", hidden)
        FC.Config:Set("map.showDeaths", everything)
    end
end

local function syncOff() return not FC.P.sync.enabled end

local function percent(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

-- The quest marker's size, with the marker drawn at that size over the bar
-- of a nameplate; it follows the slider while it is dragged.
local function markerSize(parent)
    local UI = FC.UI
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(460, 74)
    local plate = UI.Texture(frame, "ARTWORK", "danger", 0.9)
    plate:SetSize(80, 6)
    plate:SetPoint("BOTTOMLEFT", 360, 6)
    local mark = frame:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("BOTTOM", plate, "TOP", 0, 2)
    local brass = FC.QuestMarkers:ApplyTexture(mark)
    local function show(scale)
        mark:SetSize(FC.QuestMarkers:MarkerSize(scale, brass))
    end
    local slider = UI.Slider(frame, L.SET_QUEST_MARKER_SIZE, 0.6, 1.8, 0.05, function() return FC.P.nameplates.markerScale or 1 end, function(value)
        FC.Config:Set("nameplates.markerScale", value)
        show(value)
    end, percent)
    slider:SetWidth(320)
    slider:SetPoint("TOPLEFT", 0, -12)
    frame.slider, frame.mark = slider, mark
    function frame:Refresh()
        slider:Refresh()
        show(FC.P.nameplates.markerScale)
    end
    frame:Refresh()
    return frame, 74
end

FC.SettingsSchema = {
    {
        key = "general", label = "SET_GENERAL", icon = ICON .. "INV_Misc_Gear_01",
        sections = {
            -- first: what players look for (account-wide, kept in the
            -- database, not in the profile; the Progress page has it too)
            { title = "SET_SEC_PROGRESS", controls = {
                { type = "dropdown", label = "SET_PROGRESS_MODE", items = {
                    { value = "account", text = L.PROGRESS_MODE_ACCOUNT }, { value = "character", text = L.PROGRESS_MODE_CHARACTER } },
                    get = function() return FC.Progress:Mode() end,
                    set = function(value) FC.Progress:SetMode(value) end },
                { type = "note", text = "SET_PROGRESS_NOTE" },
                { type = "button", label = "SET_PROGRESS_OPEN", onClick = function() FC.MainWindow:Show("progress") end },
            } },
            { title = "SET_SEC_LAUNCHERS", controls = {
                { type = "checkbox", path = "general.minimap.show", label = "SET_MINIMAP", tip = "SET_MINIMAP_TIP" },
                { type = "checkbox", path = "general.targetButton.show", label = "SET_TARGET_BUTTON", tip = "SET_TARGET_BUTTON_TIP" },
                { type = "button", label = "SET_RESET_TARGET_BUTTON", onClick = function()
                    FC.P.general.targetButton.point = nil
                    FC.Config:Set("general.targetButton.show", FC.P.general.targetButton.show)
                end },
                { type = "checkbox", path = "general.chatLinks", label = "SET_CHAT_LINKS", tip = "SET_CHAT_LINKS_TIP" },
            } },
            { title = "SET_SEC_START", controls = {
                { type = "dropdown", path = "journal.defaultPage", label = "SET_DEFAULT_PAGE", items = pages },
                { type = "button", label = "SET_RUN_ONBOARDING", onClick = function() FC.Onboarding:Start() end },
            } },
        },
    },
    {
        key = "appearance", label = "SET_APPEARANCE", icon = ICON .. "INV_Misc_Gem_Variety_01",
        sections = {
            { title = "SET_SEC_THEME", controls = {
                { type = "dropdown", path = "appearance.style", label = "SET_STYLE", items = {
                    { value = "journal", text = L.SET_STYLE_JOURNAL }, { value = "flat", text = L.SET_STYLE_FLAT } } },
                { type = "note", text = "SET_STYLE_NOTE" },
                { type = "dropdown", path = "appearance.theme", label = "SET_THEME", items = themes, set = function(value) FC.Theme:Select(value) end },
                { type = "checkbox", path = "appearance.highContrast", label = "SET_HIGH_CONTRAST", tip = "SET_HIGH_CONTRAST_TIP" },
            } },
            { title = "SET_SEC_WINDOW", controls = {
                { type = "slider", path = "appearance.scale", label = "SET_SCALE", min = 0.6, max = 1.6, step = 0.05, format = percent },
                { type = "slider", path = "appearance.alpha", label = "SET_ALPHA", min = 0.3, max = 1, step = 0.05, format = percent },
                { type = "slider", path = "appearance.bgAlpha", label = "SET_BG_ALPHA", min = 0.5, max = 1, step = 0.01, format = percent },
                { type = "slider", path = "appearance.window.width", label = "SET_WINDOW_WIDTH", min = 860, max = 1800, step = 10 },
                { type = "slider", path = "appearance.window.height", label = "SET_WINDOW_HEIGHT", min = 500, max = 1200, step = 10 },
                { type = "button", label = "SET_RESET_WINDOW", onClick = function()
                    local w = FC.P.appearance.window
                    w.point, w.relPoint, w.x, w.y = nil, nil, nil, nil
                    w.width, w.height, w.detailWidth = 1100, 660, 340
                    FC.Config:Set("appearance.window", w)
                end },
            } },
            { title = "SET_SEC_STYLE", controls = {
                { type = "slider", path = "appearance.borderSize", label = "SET_BORDER_SIZE", min = 0, max = 3, step = 1 },
                { type = "dropdown", path = "appearance.corners", label = "SET_CORNERS", items = {
                    { value = "sharp", text = L.SET_CORNERS_SHARP }, { value = "soft", text = L.SET_CORNERS_SOFT } } },
                { type = "dropdown", path = "appearance.buttonStyle", label = "SET_BUTTON_STYLE", items = {
                    { value = "filled", text = L.SET_BUTTON_FILLED }, { value = "outlined", text = L.SET_BUTTON_OUTLINED } } },
                { type = "dropdown", path = "appearance.cardDensity", label = "SET_CARD_DENSITY", items = {
                    { value = "comfortable", text = L.SET_DENSITY_COMFORTABLE }, { value = "compact", text = L.SET_DENSITY_COMPACT } } },
                { type = "dropdown", path = "appearance.tooltipStyle", label = "SET_TOOLTIP_STYLE", items = {
                    { value = "addon", text = L.SET_TOOLTIP_ADDON }, { value = "blizzard", text = L.SET_TOOLTIP_BLIZZARD } } },
                { type = "checkbox", path = "appearance.animations", label = "SET_ANIMATIONS", tip = "SET_ANIMATIONS_TIP" },
            } },
        },
    },
    {
        key = "fonts", label = "SET_FONTS", icon = ICON .. "INV_Inscription_Tradeskill01",
        sections = {
            { title = "SET_SEC_FONTS", controls = {
                { type = "dropdown", path = "fonts.main", label = "SET_FONT_MAIN", items = fonts },
                { type = "dropdown", path = "fonts.header", label = "SET_FONT_HEADER", items = fonts },
                { type = "slider", path = "fonts.size", label = "SET_FONT_SIZE", min = 9, max = 18, step = 1 },
                { type = "dropdown", path = "fonts.outline", label = "SET_FONT_OUTLINE", items = {
                    { value = "NONE", text = L.SET_OUTLINE_NONE }, { value = "OUTLINE", text = L.SET_OUTLINE_THIN }, { value = "THICKOUTLINE", text = L.SET_OUTLINE_THICK } } },
                { type = "checkbox", path = "fonts.shadow", label = "SET_FONT_SHADOW" },
                { type = "slider", path = "fonts.spacing", label = "SET_FONT_SPACING", min = 0, max = 6, step = 1 },
                { type = "custom", build = function(parent, width)
                    local frame = CreateFrame("Frame", nil, parent)
                    frame:SetSize(width, 96)
                    local UI = FC.UI
                    local roles = { { "title", "SET_PREVIEW_TITLE" }, { "header", "SET_PREVIEW_HEADER" }, { "body", "SET_PREVIEW_BODY" }, { "meta", "SET_PREVIEW_META" } }
                    local y = 0
                    for _, r in ipairs(roles) do
                        local text = UI.Text(frame, r[1], r[1] == "meta" and "muted" or "text")
                        text:SetPoint("TOPLEFT", 0, -y)
                        text:SetText(L[r[2]])
                        y = y + 24
                    end
                    return frame, 100
                end },
            } },
        },
    },
    {
        key = "colors", label = "SET_COLORS", icon = ICON .. "INV_Misc_Gem_Ruby_01",
        sections = {
            { title = "SET_SEC_THEME_TOOLS", controls = {
                { type = "note", text = "SET_THEME_FLAT_NOTE" },
                { type = "dropdown", path = "appearance.theme", label = "SET_THEME", items = themes, set = function(value) FC.Theme:Select(value) end },
                { type = "button", label = "SET_THEME_COPY", onClick = function()
                    FC.UI.Prompt(L.SET_THEME_COPY, L.SET_THEME_NAME_PROMPT, FC.P.appearance.theme .. " copy", function(name)
                        local saved = FC.Theme:CopyCurrent(name)
                        if saved then FC.Theme:Select(saved) end
                    end, 32)
                end },
                { type = "button", label = "SET_THEME_EXPORT", onClick = function()
                    local text = FC.ImportExport:ExportTheme(FC.P.appearance.theme, FC.Theme:CurrentPalette())
                    if text then FC.UI.TextDialog(L.SET_THEME_EXPORT, text, true) end
                end },
                { type = "button", label = "SET_THEME_IMPORT", onClick = function()
                    FC.UI.TextDialog(L.SET_THEME_IMPORT, "", false, function(text)
                        local result, err = FC.ImportExport:Import(text)
                        if result then
                            FC:Print(FC.ImportExport:Describe(result))
                            if result.kind == "theme" then FC.Theme:Select(result.name) end
                        else
                            FC:Print(L.IMPORT_FAILED, err or "?")
                        end
                    end)
                end },
                { type = "button", label = "SET_THEME_DELETE", style = "danger", disabled = function() return FC.Theme:IsPreset(FC.P.appearance.theme) end, onClick = function()
                    local name = FC.P.appearance.theme
                    FC.UI.Confirm(L.SET_THEME_DELETE, string.format(L.SET_THEME_DELETE_TEXT, name), L.DELETE, function() FC.Theme:DeleteCustom(name) end, true)
                end },
                { type = "button", label = "SET_THEME_RESET", onClick = function() FC.Theme:ResetColors() end },
            } },
            { title = "SET_SEC_COLORS", controls = {
                { type = "note", text = "SET_COLORS_NOTE" },
                { type = "color", role = "accent", label = "ROLE_ACCENT" },
                { type = "color", role = "bg", label = "ROLE_BG" },
                { type = "color", role = "panel", label = "ROLE_PANEL" },
                { type = "color", role = "panelAlt", label = "ROLE_PANELALT" },
                { type = "color", role = "border", label = "ROLE_BORDER" },
                { type = "color", role = "highlight", label = "ROLE_HIGHLIGHT" },
                { type = "color", role = "text", label = "ROLE_TEXT" },
                { type = "color", role = "muted", label = "ROLE_MUTED" },
                { type = "color", role = "success", label = "ROLE_SUCCESS" },
                { type = "color", role = "warning", label = "ROLE_WARNING" },
                { type = "color", role = "danger", label = "ROLE_DANGER" },
                { type = "color", role = "secret", label = "ROLE_SECRET" },
            } },
        },
    },
    {
        key = "journal", label = "SET_JOURNAL", icon = ICON .. "INV_Misc_Book_09",
        sections = {
            { title = "SET_SEC_JOURNAL", controls = {
                { type = "dropdown", path = "journal.sort", label = "SET_SORT", items = function()
                    local items = {}
                    for _, key in ipairs(FC.Query.SORTS) do items[#items + 1] = { value = key, text = L["SORT_" .. key:upper()] } end
                    return items
                end },
                { type = "checkbox", path = "journal.showArchived", label = "SET_SHOW_ARCHIVED" },
                { type = "checkbox", path = "milestones.enabled", label = "SET_MILESTONES", tip = "SET_MILESTONES_TIP" },
            } },
            { title = "SET_SEC_BIOGRAPHY", controls = {
                { type = "checkbox", path = "biography.enabled", label = "SET_BIOGRAPHY", tip = "SET_BIOGRAPHY_TIP" },
                { type = "checkbox", path = "biography.screenshots", label = "SET_BIOGRAPHY_SCREENSHOTS", tip = "SET_BIOGRAPHY_SCREENSHOTS_TIP" },
            } },
            { title = "SET_SEC_KNOWLEDGE", controls = {
                { type = "note", text = "SET_KNOWLEDGE_NOTE" },
                { type = "dropdown", path = "knowledge.mode", label = "SET_KNOWLEDGE_MODE", items = {
                    { value = "mine", text = L.KNOWLEDGE_MINE }, { value = "verified", text = L.KNOWLEDGE_VERIFIED }, { value = "all", text = L.KNOWLEDGE_ALL } } },
                { type = "checkbox", path = "knowledge.veil", label = "KNOWLEDGE_VEIL", tip = "SET_VEIL_TIP" },
                { type = "slider", path = "discovery.verifyThreshold", label = "SET_VERIFY_THRESHOLD", min = 2, max = 6, step = 1 },
            } },
        },
    },
    {
        key = "map", label = "SET_MAP", icon = ICON .. "INV_Misc_Map_01",
        sections = {
            { title = "SET_SEC_MAP", controls = {
                { type = "checkbox", path = "map.enabled", label = "MAP_SHOW_PINS" },
                { type = "checkbox", path = "map.showMine", label = "MAP_SHOW_MINE" },
                { type = "checkbox", path = "map.showGuild", label = "MAP_SHOW_GUILD" },
                { type = "slider", path = "map.iconScale", label = "SET_ICON_SCALE", min = 0.6, max = 2, step = 0.05, format = percent },
                { type = "slider", path = "map.iconAlpha", label = "SET_ICON_ALPHA", min = 0.3, max = 1, step = 0.05, format = percent },
                { type = "checkbox", path = "map.altClickNotes", label = "SET_ALT_CLICK", tip = "SET_ALT_CLICK_TIP" },
                { type = "checkbox", path = "map.preferTomTom", label = "SET_TOMTOM", tip = "SET_TOMTOM_TIP", disabled = function() return not FC.Waypoints:HasTomTom() end },
            } },
            { title = "SET_SEC_MINIMAP", controls = {
                { type = "checkbox", path = "map.minimap", label = "SET_MINIMAP_PINS", tip = "SET_MINIMAP_PINS_TIP" },
                { type = "slider", path = "map.minimapScale", label = "SET_MINIMAP_PIN_SIZE", min = 0.6, max = 2, step = 0.05, format = percent },
            } },
            { title = "SET_SEC_ZONE_GUIDE", controls = {
                { type = "note", text = "SET_ZONE_GUIDE_NOTE" },
                { type = "button", label = "SET_ZONE_GUIDE_OPEN", onClick = function() FC.ZoneGuide:Toggle() end },
                { type = "checkbox", path = "zoneGuide.autoOpen", label = "SET_ZONE_GUIDE_AUTO" },
            } },
            { title = "SET_SEC_MAP_WHAT", controls = {
                { type = "note", text = "SET_MAP_WHAT_NOTE" },
                { type = "checkgrid", items = mapGroups, columns = 2, invert = true },
                { type = "checkbox", path = "map.showDeaths", label = "MAP_SHOW_DEATHS" },
                { type = "button", label = "SET_MAP_IMPORTANT", onClick = mapPreset(false) },
                { type = "button", label = "SET_MAP_EVERYTHING", onClick = mapPreset(true) },
            } },
        },
    },
    {
        key = "discovery", label = "SET_DISCOVERY", icon = ICON .. "INV_Misc_Spyglass_03",
        sections = {
            { title = "SET_SEC_AUTO", controls = {
                { type = "note", text = "SET_AUTO_NOTE" },
                { type = "checkbox", path = "discovery.autoText", label = "SET_AUTO_TEXT", tip = "SET_AUTO_TEXT_TIP" },
            } },
            { title = "SET_SEC_AUTO_CREATURES", controls = {
                { type = "checkbox", path = "discovery.rares", label = "SET_DETECT_RARES" },
                { type = "checkbox", path = "discovery.creatures", label = "SET_DETECT_CREATURES", tip = "SET_DETECT_CREATURES_TIP" },
                { type = "checkbox", path = "discovery.nameplates", label = "SET_DETECT_NAMEPLATES", tip = "SET_DETECT_NAMEPLATES_TIP" },
                { type = "checkbox", path = "discovery.gossip", label = "SET_DETECT_GOSSIP", tip = "SET_DETECT_GOSSIP_TIP" },
                { type = "checkbox", path = "discovery.vendors", label = "SET_DETECT_VENDORS" },
                { type = "checkbox", path = "discovery.trainers", label = "SET_DETECT_TRAINERS" },
                { type = "checkbox", path = "discovery.travel", label = "SET_DETECT_TRAVEL" },
            } },
            { title = "SET_SEC_AUTO_WORLD", controls = {
                { type = "checkbox", path = "discovery.explored", label = "SET_DETECT_EXPLORED", tip = "SET_DETECT_EXPLORED_TIP" },
                { type = "checkbox", path = "discovery.caves", label = "SET_DETECT_CAVES", tip = "SET_DETECT_CAVES_TIP" },
                { type = "checkbox", path = "discovery.routes", label = "SET_DETECT_ROUTES", tip = "SET_DETECT_ROUTES_TIP" },
                { type = "checkbox", path = "discovery.objects", label = "SET_DETECT_OBJECTS", tip = "SET_DETECT_OBJECTS_TIP" },
                { type = "checkbox", path = "discovery.readables", label = "SET_DETECT_READABLES" },
                { type = "checkbox", path = "discovery.deaths", label = "SET_DETECT_DEATHS", tip = "SET_DETECT_DEATHS_TIP" },
            } },
            { title = "SET_SEC_AUTO_ITEMS", controls = {
                { type = "checkbox", path = "discovery.loot", label = "SET_DETECT_LOOT" },
                { type = "dropdown", path = "discovery.lootQuality", label = "SET_LOOT_QUALITY", items = {
                    { value = 2, text = L.QUALITY_UNCOMMON }, { value = 3, text = L.QUALITY_RARE }, { value = 4, text = L.QUALITY_EPIC } } },
                { type = "checkbox", path = "discovery.recipes", label = "SET_DETECT_RECIPES" },
                { type = "checkbox", path = "discovery.recipesLearned", label = "SET_DETECT_LEARNED" },
                { type = "checkbox", path = "discovery.gathering", label = "SET_DETECT_GATHERING", tip = "SET_DETECT_GATHERING_TIP" },
            } },
            { title = "SET_SEC_AUTO_QUESTS", controls = {
                { type = "checkbox", path = "discovery.quests", label = "SET_DETECT_QUESTS" },
                { type = "checkbox", path = "discovery.questChains", label = "SET_DETECT_CHAINS", tip = "SET_DETECT_CHAINS_TIP" },
                { type = "checkbox", path = "discovery.dungeons", label = "SET_DETECT_DUNGEONS" },
                { type = "checkbox", path = "discovery.dungeonAreas", label = "SET_DETECT_DUNGEON_AREAS" },
                { type = "checkbox", path = "discovery.bosses", label = "SET_DETECT_BOSSES" },
                { type = "checkbox", path = "discovery.mechanics", label = "SET_DETECT_MECHANICS", tip = "SET_DETECT_MECHANICS_TIP" },
            } },
        },
    },
    {
        key = "sync", label = "SET_SYNC", icon = FC.C.GUILD_ICON,
        sections = {
            { title = "SET_SEC_SHARING", controls = {
                { type = "checkbox", path = "sync.enabled", label = "SET_SYNC_ENABLED", tip = "SET_SYNC_ENABLED_TIP" },
                { type = "dropdown", path = "sync.channel", label = "SET_SYNC_CHANNEL", items = {
                    { value = "GUILD", text = L.CHANNEL_GUILD }, { value = "PARTY", text = L.CHANNEL_PARTY },
                    { value = "RAID", text = L.CHANNEL_RAID }, { value = "NONE", text = L.CHANNEL_NONE } }, disabled = syncOff },
                { type = "checkbox", path = "sync.autoShare", label = "SET_AUTO_SHARE", tip = "SET_AUTO_SHARE_TIP", disabled = syncOff },
                { type = "checkbox", path = "sync.shareQuests", label = "SET_SHARE_QUESTS", disabled = syncOff },
                { type = "checkbox", path = "sync.shareQuestKnowledge", label = "SET_SHARE_QUEST_KNOWLEDGE", tip = "SET_SHARE_QUEST_KNOWLEDGE_TIP", disabled = syncOff },
                { type = "checkbox", path = "sync.shareNotes", label = "SET_SHARE_NOTES", disabled = syncOff },
                { type = "checkbox", path = "sync.shareCoords", label = "SET_SHARE_COORDS", tip = "SET_SHARE_COORDS_TIP", disabled = syncOff },
                { type = "checkbox", path = "sync.shareCreatures", label = "SET_SHARE_CREATURES", disabled = syncOff },
                { type = "checkbox", path = "sync.shareGathering", label = "SET_SHARE_GATHERING", disabled = syncOff },
                { type = "checkbox", path = "sync.notifyVersion", label = "SET_NOTIFY_VERSION" },
            } },
            { title = "SET_SEC_SYNC_TOOLS", controls = {
                { type = "note", text = "SET_SYNC_NOTE" },
                { type = "button", label = "SET_SYNC_NOW", onClick = function() FC.Commands:Run("sync") end },
                { type = "button", label = "SET_SYNC_STATUS", onClick = function() FC.Commands:Run("sync status") end },
            } },
        },
    },
    {
        key = "notifications", label = "SET_NOTIFICATIONS", icon = ICON .. "Ability_Warrior_BattleShout",
        sections = {
            -- first: which discoveries show a toast (what players look for)
            { title = "SET_SEC_NOTIFY_WHAT", controls = {
                { type = "checkbox", path = "notifications.enabled", label = "SET_NOTIFY_ENABLED" },
                { type = "note", text = "SET_NOTIFY_WHAT_NOTE" },
                { type = "checkgrid", items = notificationCategories, columns = 2 },
                { type = "button", label = "SET_NOTIFY_IMPORTANT", onClick = function() FC.Notifications:ApplyCategoryPreset(false) end },
                { type = "button", label = "SET_NOTIFY_EVERYTHING", onClick = function() FC.Notifications:ApplyCategoryPreset(true) end },
            } },
            { title = "SET_SEC_NOTIFY", controls = {
                { type = "slider", path = "notifications.duration", label = "SET_NOTIFY_DURATION", min = 2, max = 20, step = 1, format = function(v) return v .. "s" end },
                { type = "slider", path = "notifications.scale", label = "SET_NOTIFY_SCALE", min = 0.6, max = 1.6, step = 0.05, format = percent },
                { type = "slider", path = "notifications.maxVisible", label = "SET_NOTIFY_MAX", min = 1, max = 5, step = 1 },
                { type = "checkbox", path = "notifications.animate", label = "SET_NOTIFY_ANIMATE" },
                { type = "checkbox", path = "notifications.sound", label = "SET_NOTIFY_SOUND" },
                { type = "dropdown", path = "notifications.soundKit", label = "SET_NOTIFY_SOUND_KIT", items = sounds, set = function(value)
                    FC.Config:Set("notifications.soundKit", value)
                    FC.Compat.PlaySoundKit(value)
                end },
                { type = "checkbox", path = "notifications.eventSounds", label = "SET_NOTIFY_EVENT_SOUNDS", tip = "SET_NOTIFY_EVENT_SOUNDS_TIP" },
                { type = "checkbox", path = "notifications.flightPathSound", label = "SET_NOTIFY_FLIGHT_SOUND", tip = "SET_NOTIFY_FLIGHT_SOUND_TIP", set = function(value)
                    FC.Config:Set("notifications.flightPathSound", value)
                    if value then FC.Notifications:PlayFlightPathSound() end
                end },
                { type = "button", label = "SET_NOTIFY_PREVIEW_SOUNDS", onClick = function() FC.Notifications:PreviewSounds() end },
                { type = "button", label = "SET_NOTIFY_MOVE", onClick = function() FC.Notifications:ToggleAnchor() end },
                { type = "button", label = "SET_NOTIFY_TEST", onClick = function() FC.Notifications:Test("rare") end },
            } },
            { title = "SET_SEC_NOTIFY_TYPES", controls = {
                { type = "checkbox", path = "notifications.types.personal", label = "NOTIFYTYPE_PERSONAL" },
                { type = "checkbox", path = "notifications.types.guild", label = "NOTIFYTYPE_GUILD" },
                { type = "checkbox", path = "notifications.types.kill", label = "NOTIFYTYPE_KILL", tip = "NOTIFYTYPE_KILL_TIP" },
                { type = "checkbox", path = "notifications.types.nearby", label = "NOTIFYTYPE_NEARBY", tip = "NOTIFYTYPE_NEARBY_TIP" },
                { type = "checkbox", path = "notifications.flash", label = "SET_NOTIFY_FLASH", tip = "SET_NOTIFY_FLASH_TIP" },
                { type = "checkbox", path = "notifications.types.milestone", label = "NOTIFYTYPE_MILESTONE" },
                { type = "checkbox", path = "notifications.types.sync", label = "NOTIFYTYPE_SYNC" },
            } },
        },
    },
    {
        key = "tooltips", label = "SET_TOOLTIPS", icon = ICON .. "INV_Scroll_02",
        sections = {
            { title = "SET_SEC_TOOLTIP_NPC", controls = {
                { type = "note", text = "SET_TOOLTIPS_NOTE" },
                { type = "checkbox", path = "tooltips.unit", label = "SET_TOOLTIP_UNIT" },
                { type = "checkbox", path = "tooltips.quests", label = "SET_TOOLTIP_QUESTS", tip = "SET_TOOLTIP_QUESTS_TIP" },
                { type = "checkbox", path = "tooltips.questItems", label = "SET_TOOLTIP_QUEST_ITEMS", tip = "SET_TOOLTIP_QUEST_ITEMS_TIP" },
                { type = "checkbox", path = "tooltips.alts", label = "SET_TOOLTIP_ALTS", tip = "SET_TOOLTIP_ALTS_TIP" },
                { type = "checkbox", path = "tooltips.npcID", label = "SET_TOOLTIP_NPC_ID" },
                { type = "checkbox", path = "tooltips.spawn", label = "SET_TOOLTIP_SPAWN", tip = "SET_TOOLTIP_SPAWN_TIP" },
            } },
            { title = "SET_SEC_TOOLTIP_ITEM", controls = {
                { type = "checkbox", path = "tooltips.item", label = "SET_TOOLTIP_ITEM" },
                { type = "checkbox", path = "tooltips.sources", label = "SET_TOOLTIP_SOURCES", tip = "SET_TOOLTIP_SOURCES_TIP" },
            } },
        },
    },
    {
        -- its own page: the marker's size is what players come looking for
        key = "markers", label = "SET_MARKERS", icon = ICON .. "INV_Misc_Note_02",
        sections = {
            { title = "SET_SEC_NAMEPLATES", controls = {
                { type = "custom", build = markerSize },
                { type = "checkbox", path = "nameplates.questMarker", label = "SET_QUEST_MARKER", tip = "SET_QUEST_MARKER_TIP" },
                { type = "checkbox", path = "nameplates.hideInCombat", label = "SET_QUEST_MARKER_COMBAT", tip = "SET_QUEST_MARKER_COMBAT_TIP" },
            } },
        },
    },
    { key = "profiles", label = "SET_PROFILES", icon = ICON .. "INV_Misc_Head_Human_02", custom = "profiles" },
    { key = "data", label = "SET_DATA", icon = ICON .. "INV_Scroll_03", custom = "data" },
    {
        key = "advanced", label = "SET_ADVANCED", icon = ICON .. "INV_Gizmo_02",
        sections = {
            { title = "SET_SEC_DEBUG", controls = {
                { type = "checkbox", path = "debug.enabled", label = "SET_DEBUG", tip = "SET_DEBUG_TIP" },
                { type = "dropdown", path = "debug.level", label = "SET_DEBUG_LEVEL", items = {
                    { value = 1, text = "ERROR" }, { value = 2, text = "WARN" }, { value = 3, text = "INFO" }, { value = 4, text = "DEBUG" }, { value = 5, text = "TRACE" } } },
                { type = "button", label = "SET_SHOW_LOG", onClick = function() FC.Log:Dump(40) end },
                { type = "button", label = "SET_REBUILD", onClick = function()
                    local removed = FC.Store:ValidateAll()
                    FC.Store:RebuildIndexes()
                    FC.Bus:Emit("STORE_RESET")
                    FC:Print(L.MSG_REBUILT, removed)
                end },
            } },
        },
    },
    { key = "about", label = "SET_ABOUT", icon = FC.C.MEDIA .. "Logo", custom = "about" },
}

