--[[
  Forever Companion - UI/Notifications.lua
  Discovery toasts: your discoveries, guild discoveries, rares and world
  bosses you defeat, milestones and sync summaries. Toasts stack under a
  movable anchor, pause while hovered, show a shrinking time bar, and can be
  clicked to open the discovery. Bursts (a vendor with ten recipes, a sync
  batch) collapse into one summary toast.

  Which discoveries deserve a toast is chosen per category in Settings >
  Notifications ("What counts as a discovery"); routine finds such as quests
  are recorded quietly by default.
]]

local _, FC = ...

local Notifications = FC:NewModule("Notifications")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Theme = FC.Theme
local Categories = FC.Categories
local Compat = FC.Compat

local TOAST_WIDTH, TOAST_HEIGHT = 340, 78
local BURST_WINDOW = 1.2
local BURST_LIMIT = 3
local QUEUE_LIMIT = 20   -- toasts waiting their turn at most; the oldest go first
local LEAVE_GRACE = 2    -- seconds a toast may take to fade before it is let go anyway
-- finds that keep their own toast in a burst of finds
local BIG_FINDS = { rare = true, boss = true, dungeon = true, treasure = true, secret = true, cave = true }
local SKULL_ICON = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local SOUND_GAP = 1.5 -- at most one toast sound this often

-- Big finds get their own sound from the game's sound kits (first one the
-- client has wins). Everything else plays the sound chosen in Settings.
-- Ordered by importance: a burst summary uses the biggest sound it contains.
local EVENT_SOUNDS = {
    { key = "kill", kits = { "UI_WORLDQUEST_COMPLETE", "IG_QUEST_LIST_COMPLETE" } },
    { key = "boss", kits = { "UI_GARRISON_TOAST_MISSION_COMPLETE", "UI_EPICLOOT_TOAST" } },
    { key = "milestone", kits = { "UI_LEGENDARY_LOOT_TOAST", "UI_EPICLOOT_TOAST" } },
    { key = "rare", kits = { "UI_RAID_BOSS_WHISPER_WARNING", "RAID_WARNING" } },
    { key = "treasure", kits = { "UI_DIG_SITE_COMPLETION_TOAST", "LOOT_WINDOW_COIN_SOUND" } },
    { key = "dungeon", kits = { "PVP_THROUGH_QUEUE", "READY_CHECK" } },
    { key = "item", kits = { "UI_EPICLOOT_TOAST" } },
    { key = "recipe", kits = { "UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST", "UI_BNET_TOAST" } },
    { key = "secret", kits = { "UI_WORLDQUEST_START", "ALARM_CLOCK_WARNING_3" } },
    -- a short chime when a flight path is learned (Settings > Notifications)
    { key = "flightpath", kits = { "UI_MAP_WAYPOINT_SUPERTRACK_ON", "UI_WORLDQUEST_MAP_SELECT", "IG_QUEST_LIST_SELECT" } },
}
local SOUND_ALIASES = { profession = "recipe", cave = "secret", shortcut = "secret" }
local soundByKey, soundRank = {}, {}
for rank, entry in ipairs(EVENT_SOUNDS) do
    soundByKey[entry.key] = entry.kits
    soundRank[entry.key] = rank
end

Notifications.active = {}
Notifications.queue = {}
Notifications.pending = {}

------------------------------------------------------------------------
-- Anchor
------------------------------------------------------------------------

function Notifications:BuildAnchor()
    if self.anchor then return end
    local anchor = UI.Panel(UIParent, { name = "ForeverCompanionToastAnchor", strata = "HIGH", bg = "accent", bgAlpha = 0.25, border = "accent" })
    anchor:SetSize(TOAST_WIDTH, 30)
    anchor.label = UI.Text(anchor, "meta", "text")
    anchor.label:SetPoint("CENTER")
    anchor.label:SetText(L.NOTIFY_ANCHOR)
    anchor.bg:SetShown(false)
    UI.SetBorderColor(anchor, "accent", 0)
    anchor.label:Hide()
    UI.MakeMovable(anchor, anchor, function(point, relPoint, x, y)
        FC.P.notifications.point = { point, relPoint, x, y }
    end)
    anchor:EnableMouse(false)
    self.anchor = anchor
    self:PlaceAnchor()
end

function Notifications:PlaceAnchor()
    local p = FC.P.notifications.point or { "TOP", "TOP", 0, -150 }
    self.anchor:ClearAllPoints()
    self.anchor:SetPoint(p[1] or "TOP", UIParent, p[2] or "TOP", p[3] or 0, p[4] or -150)
    self.anchor:SetScale(FC.P.notifications.scale or 1)
end

function Notifications:ToggleAnchor()
    self:BuildAnchor()
    self.unlocked = not self.unlocked
    self.anchor:EnableMouse(self.unlocked)
    self.anchor.bg:SetShown(self.unlocked)
    self.anchor.label:SetShown(self.unlocked)
    UI.SetBorderColor(self.anchor, "accent", self.unlocked and 1 or 0)
    if self.unlocked then
        self:Push({ kind = "personal", force = true, header = L.NOTIFY_PREVIEW_HEADER, title = L.NOTIFY_PREVIEW_TITLE, line = L.NOTIFY_PREVIEW_LINE, icon = C.MEDIA .. "Logo" })
    end
    return self.unlocked
end

------------------------------------------------------------------------
-- Toasts
------------------------------------------------------------------------

local function createToast(self)
    local toast = UI.Panel(UIParent, { strata = "HIGH", bgAlpha = 0.97, skin = "panel", corner = 12 })
    toast:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    toast:SetClampedToScreen(true)
    toast:EnableMouse(true)
    toast.stripe = UI.Texture(toast, "ARTWORK", "accent", 1)
    toast.stripe:SetPoint("TOPLEFT", 1, -1)
    toast.stripe:SetPoint("BOTTOMLEFT", 1, 1)
    toast.stripe:SetWidth(3)
    -- journal style: a warm burst of light behind the icon
    toast.glow = toast:CreateTexture(nil, "BACKGROUND", nil, 1)
    toast.glow:SetSize(96, 96)
    toast.glow:SetBlendMode("ADD")
    toast.glow:SetAlpha(0.75)
    toast.iconBorder = toast:CreateTexture(nil, "ARTWORK", nil, 1)
    toast.iconBorder:SetTexture(C.WHITE)
    toast.icon = UI.Icon(toast, 42, "ARTWORK")
    toast.icon:SetDrawLayer("ARTWORK", 2)
    toast.icon:SetPoint("LEFT", 14, 0)
    toast.glow:SetPoint("CENTER", toast.icon, "CENTER", 0, 0)
    -- shows the glow and hides the flat stripe in the journal style
    function toast:ApplyStyle()
        local Skin = FC.Skin
        local journal = Skin:Enabled()
        local glow = journal and Skin:Has("glow") and Skin:SetFile(self.glow, Skin.ASSETS.glow.path)
        self.glow:SetShown(glow and true or false)
        self.stripe:SetShown(not journal)
    end
    toast:ApplyStyle()
    Theme:OnChange(toast, function(t) t:ApplyStyle() end)
    toast.iconBorder:SetPoint("TOPLEFT", toast.icon, -1, 1)
    toast.iconBorder:SetPoint("BOTTOMRIGHT", toast.icon, 1, -1)
    toast.header = UI.Text(toast, "meta", "accent")
    toast.header:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 12, 1)
    toast.header:SetPoint("RIGHT", -52, 0)
    toast.title = UI.Text(toast, "cardTitle", "text")
    toast.title:SetPoint("TOPLEFT", toast.header, "BOTTOMLEFT", 0, -4)
    toast.title:SetPoint("RIGHT", -14, 0)
    toast.line = UI.Text(toast, "meta", "muted")
    toast.line:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -4)
    toast.line:SetPoint("RIGHT", -14, 0)
    toast.close = UI.IconButton(toast, "Interface\\Buttons\\UI-StopButton", 18, nil, function() self:Dismiss(toast) end)
    toast.close:SetPoint("TOPRIGHT", -6, -6)
    -- which discoveries show a toast: this kind off at once, or the whole list
    toast.options = UI.IconButton(toast, "Interface\\Buttons\\UI-OptionsButton", 18, L.NOTIFY_OPTIONS, function(button)
        self:OpenToastMenu(toast, button)
    end)
    toast.options:SetPoint("RIGHT", toast.close, "LEFT", -2, 0)
    toast.timer = UI.Texture(toast, "OVERLAY", "accent", 0.7)
    toast.timer:SetPoint("BOTTOMLEFT", 1, 1)
    toast.timer:SetHeight(2)

    local anim = toast:CreateAnimationGroup()
    local slide = anim:CreateAnimation("Translation")
    slide:SetOffset(0, 16)
    slide:SetDuration(0)
    slide:SetOrder(1)
    local back = anim:CreateAnimation("Translation")
    back:SetOffset(0, -16)
    back:SetDuration(0.25)
    back:SetSmoothing("OUT")
    back:SetOrder(2)
    local fade = anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.25)
    fade:SetOrder(2)
    toast.intro = anim

    local out = toast:CreateAnimationGroup()
    local fadeOut = out:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.3)
    out:SetScript("OnFinished", function() self:Release(toast) end)
    toast.outro = out

    toast:SetScript("OnMouseUp", function(t, button)
        if button == "RightButton" then
            self:Dismiss(t)
        elseif t.data and t.data.onView then
            FC:SafeCall("toast:view", t.data.onView)
            self:Dismiss(t)
        end
    end)
    toast:SetScript("OnEnter", function(t) t.hovered = true end)
    toast:SetScript("OnLeave", function(t) t.hovered = false end)
    toast:SetScript("OnUpdate", function(t, elapsed)
        if t.leaving then
            -- a fade-out that never finished (the UI was hidden meanwhile) would
            -- keep the toast, and its place, for good
            if GetTime() - (t.leftAt or 0) > LEAVE_GRACE then self:Release(t) end
            return
        end
        if t.hovered or t.pinned then return end
        t.remaining = t.remaining - elapsed
        local duration = t.duration > 0 and t.duration or 1
        t.timer:SetWidth(math.max(1, (TOAST_WIDTH - 2) * math.max(0, t.remaining) / duration))
        if t.remaining <= 0 then self:Dismiss(t) end
    end)
    toast:Hide()
    return toast
end

function Notifications:Acquire()
    self.pool = self.pool or {}
    local toast = table.remove(self.pool)
    if not toast then toast = createToast(self) end
    toast.pooled = false
    return toast
end

function Notifications:Release(toast)
    if toast.pooled then return end -- let go already (a fade-out that ended late)
    toast.pooled = true
    toast:Hide()
    toast.leaving = false
    toast.pinned = nil
    toast.data = nil
    for i, t in ipairs(self.active) do
        if t == toast then table.remove(self.active, i) break end
    end
    self.pool[#self.pool + 1] = toast
    self:Layout()
    self:ShowNext()
end

function Notifications:Dismiss(toast)
    if toast.leaving then return end
    toast.leaving = true
    toast.leftAt = GetTime()
    if UI.AnimationsEnabled() and FC.P.notifications.animate then
        toast.outro:Play()
    else
        self:Release(toast)
    end
end

function Notifications:Layout()
    local y = 0
    for _, toast in ipairs(self.active) do
        toast:ClearAllPoints()
        toast:SetPoint("TOP", self.anchor, "TOP", 0, -y)
        y = y + TOAST_HEIGHT + 8
    end
end

function Notifications:ShowNext()
    local settings = FC.P.notifications
    while #self.active < (settings.maxVisible or 3) and #self.queue > 0 do
        local data = table.remove(self.queue, 1)
        local toast = self:Acquire()
        toast.data = data
        toast:SetScale(settings.scale or 1)
        UI.SetIcon(toast.icon, data.icon)
        toast.icon:SetDesaturated(data.desaturate and true or false)
        local r, g, b = U.HexToRGB(data.color or Theme:Hex("accent"))
        toast.iconBorder:SetColorTexture(r, g, b)
        toast.stripe:SetColorTexture(r, g, b)
        Theme:Forget(toast.stripe)
        toast.header:SetText(data.header or "")
        toast.title:SetText(data.title or "")
        toast.line:SetText(data.line or "")
        toast.duration = settings.duration or 6
        toast.remaining = toast.duration
        toast.hovered = false
        self.active[#self.active + 1] = toast
        self:Layout()
        toast:SetAlpha(1)
        toast:Show()
        if UI.AnimationsEnabled() and settings.animate then toast.intro:Play() end
        if settings.sound and not data.silent then self:PlayToastSound(data) end
    end
end

--- The sound kit a toast plays: the big-find sound of its kind when those are
--- on and the client has one, otherwise the sound chosen in Settings.
function Notifications:SoundKitFor(data)
    local settings = FC.P.notifications
    if settings.eventSounds and data.soundKey then
        for _, kit in ipairs(soundByKey[data.soundKey] or {}) do
            if Compat.SoundAvailable(kit) then return kit end
        end
    end
    return settings.soundKit
end

--- The flight path chime: its own switch, and the first kit the client has.
function Notifications:PlayFlightPathSound()
    if not FC.P.notifications.flightPathSound then return false end
    for _, kit in ipairs(soundByKey.flightpath) do
        if Compat.SoundAvailable(kit) then
            self.lastSound = GetTime()
            Compat.PlaySoundKit(kit)
            return kit
        end
    end
    return false
end

function Notifications:PlayToastSound(data)
    local now = GetTime()
    if self.lastSound and now - self.lastSound < SOUND_GAP then return end
    self.lastSound = now
    Compat.PlaySoundKit(self:SoundKitFor(data))
end

--- Plays every big-find sound once, a moment apart (Settings preview).
function Notifications:PreviewSounds()
    for i, entry in ipairs(EVENT_SOUNDS) do
        C_Timer.After((i - 1) * 1.8, function()
            for _, kit in ipairs(entry.kits) do
                if Compat.SoundAvailable(kit) then Compat.PlaySoundKit(kit) return end
            end
        end)
    end
end

--- data: { kind, header, title, line, icon, color, onView, force, silent, desaturate, soundKey }
function Notifications:Push(data)
    local settings = FC.P.notifications
    if not data.force then
        if not settings.enabled then return end
        if settings.types[data.kind] == false then return end
    end
    self:BuildAnchor()
    self.queue[#self.queue + 1] = data
    if #self.queue > QUEUE_LIMIT then table.remove(self.queue, 1) end
    self:ShowNext()
end

------------------------------------------------------------------------
-- Record notifications (with burst coalescing)
------------------------------------------------------------------------

local ICON = "Interface\\Icons\\"

-- What a toast can be about, in the order Settings shows them: the finds
-- worth interrupting play for first. Most follow the discovery type; a few
-- types are split because one half is routine and the other is not.
Notifications.CATEGORY_ORDER = {
    "rare", "boss", "dungeon", "treasure", "secret", "cave", "item", "recipe", "profession", "shortcut", "other",
    "npc", "vendorrecipe", "gathering", "vendor", "trainer", "travel", "creature", "quest", "questchain",
    "landmark", "path", "entrance", "room", "mechanic", "object", "note",
}
local CATEGORY_ICONS = {
    boss = ICON .. "INV_Misc_Bone_HumanSkull_01",
    profession = ICON .. "INV_Scroll_05",
    vendorrecipe = ICON .. "INV_Misc_Bag_10",
    gathering = ICON .. "Trade_Herbalism",
}

--- The notification category of a record: world bosses are bosses, learned
--- recipes and gathering spots are told apart, and recipes on a vendor's
--- shelf are not the same event as a recipe that dropped.
function Notifications.NotifyCategory(rec)
    local t = rec.t
    if t == "npc" and rec.cls == "worldboss" then return "boss" end
    if t == "profession" and type(rec.id) == "string" and rec.id:find("^gather:") then return "gathering" end
    if t == "recipe" and type(rec.pa) == "string" and rec.pa:find("^vendor:") then return "vendorrecipe" end
    return t
end

--- Settings rows for "What counts as a discovery": { key, label, icon },
--- including categories registered after the built-in ones.
function Notifications:CategoryList()
    local list, seen = {}, {}
    local function add(key)
        if seen[key] then return end
        seen[key] = true
        local def = Categories.types[key]
        list[#list + 1] = {
            key = key,
            -- rawget: a missing locale key would come back as its own name
            label = rawget(L, "NOTIFYCAT_" .. key:upper()) or (def and L[def.label]) or key,
            icon = CATEGORY_ICONS[key] or (def and def.icon),
        }
    end
    for _, key in ipairs(self.CATEGORY_ORDER) do add(key) end
    for _, key in ipairs(Categories.order) do add(key) end
    return list
end

--- Presets for the category grid: the defaults ("only important finds") or everything.
function Notifications:ApplyCategoryPreset(everything)
    local categories = {}
    for _, entry in ipairs(self:CategoryList()) do
        if everything then
            categories[entry.key] = true
        else
            categories[entry.key] = FC.Defaults.notifications.categories[entry.key] ~= false
        end
    end
    FC.Config:Set("notifications.categories", categories)
end

--- The name a category has in Settings > Notifications.
function Notifications:CategoryLabel(key)
    for _, entry in ipairs(self:CategoryList()) do
        if entry.key == key then return entry.label end
    end
    return key
end

-- toasts that are not about a discovery of yours, and what stops them
local TYPE_LABELS = {
    guild = "NOTIFYTYPE_GUILD", kill = "NOTIFYTYPE_KILL", nearby = "NOTIFYTYPE_NEARBY",
    milestone = "NOTIFYTYPE_MILESTONE", sync = "NOTIFYTYPE_SYNC",
}

--- The cog on a toast: no more toasts of this kind, at once, or the list of
--- which discoveries show one (Settings > Notifications).
function Notifications:OpenToastMenu(toast, anchor)
    local data = toast.data
    if not data then return end
    local items = {}
    local function mute(path, label)
        FC.Config:Set(path, false)
        FC:Print(L.MSG_NOTIFY_MUTED, label)
        self:Dismiss(toast)
    end
    if data.rec then
        local category = self.NotifyCategory(data.rec)
        local label = self:CategoryLabel(category)
        items[#items + 1] = { text = label, isTitle = true }
        items[#items + 1] = { text = L.NOTIFY_MUTE_CATEGORY, onClick = function() mute("notifications.categories." .. category, label) end }
    end
    local typeLabel = TYPE_LABELS[data.kind] and L[TYPE_LABELS[data.kind]]
    if typeLabel then
        items[#items + 1] = { text = string.format(L.NOTIFY_MUTE_TYPE, typeLabel), onClick = function() mute("notifications.types." .. data.kind, typeLabel) end }
    end
    if #items > 0 then items[#items + 1] = { divider = true } end
    items[#items + 1] = { text = L.NOTIFY_CHOOSE, onClick = function() FC.SettingsWindow:Show("notifications") end }
    toast.pinned = true -- the toast waits while its menu is open
    UI.OpenMenu(anchor, items, 230, function() toast.pinned = nil end)
end

--- Whether this kind of discovery makes a toast (Settings > Notifications).
--- Categories added later (plugins, newer versions) notify until switched off.
function Notifications:WantsRecord(rec)
    local categories = FC.P.notifications.categories
    return type(categories) ~= "table" or categories[self.NotifyCategory(rec)] ~= false
end

--- kind: "personal" (default), "guild" (fromGuild) or an event kind such as "kill".
function Notifications:RecordToast(rec, header, line, fromGuild, kind)
    local info = UI.Display(rec)
    local category = self.NotifyCategory(rec)
    local soundKey = kind == "kill" and "kill" or SOUND_ALIASES[category] or category
    return {
        kind = kind or (fromGuild and "guild" or "personal"),
        rec = rec,
        soundKey = soundByKey[soundKey] and soundKey or nil,
        header = header,
        title = U.Escape(info.title),
        line = line or UI.MetaLine(info),
        icon = info.icon,
        desaturate = info.rumored,
        color = Categories:Get(rec.t).color,
        onView = function() FC.MainWindow:ShowDiscovery(rec.id) end,
    }
end

--- A find that keeps its own toast in a burst: rares, bosses, treasure,
--- dungeon finds, secrets and caves, what is near you and what you defeat.
--- The routine finds of a town are the ones a summary stands for.
local function bigFind(data)
    if data.kind == "nearby" or data.kind == "kill" then return true end
    return data.rec ~= nil and BIG_FINDS[Notifications.NotifyCategory(data.rec)] == true
end

function Notifications:Queue(data)
    local settings = FC.P.notifications
    if not settings.enabled or settings.types[data.kind] == false then return end
    if data.rec and not self:WantsRecord(data.rec) then return end
    self.pending[#self.pending + 1] = data
    if self.flushScheduled then return end
    self.flushScheduled = true
    C_Timer.After(BURST_WINDOW, function()
        self.flushScheduled = false
        local pending, big = {}, {}
        for _, item in ipairs(self.pending) do
            if bigFind(item) then big[#big + 1] = item else pending[#pending + 1] = item end
        end
        self.pending = {}
        for _, item in ipairs(big) do self:Push(item) end
        if #pending > BURST_LIMIT then
            local soundKey
            for _, item in ipairs(pending) do
                if item.soundKey and (not soundKey or soundRank[item.soundKey] < soundRank[soundKey]) then soundKey = item.soundKey end
            end
            self:Push({
                kind = pending[1].kind,
                soundKey = soundKey,
                header = "|T" .. C.FAVORITE_ICON .. ":12|t " .. L.NOTIFY_MANY_HEADER,
                title = string.format(L.NOTIFY_MANY_TITLE, #pending),
                line = pending[1].title .. ", " .. pending[2].title .. ", ...",
                icon = pending[1].icon,
                onView = function() FC.MainWindow:Show("recent") end,
            })
        else
            for _, item in ipairs(pending) do self:Push(item) end
        end
    end)
end

local function vendorLine(rec)
    if rec.t ~= "vendor" or not rec.inv then return nil end
    for _, item in ipairs(rec.inv) do
        if item.rc or item.l then
            return string.format(L.NOTIFY_INTERESTING_ITEM, U.Escape(item.n or "?"))
        end
    end
    return nil
end

function Notifications:OnEnable()
    local Bus = FC.Bus
    Bus:On("DISCOVERY_ADDED", self, function(_, rec, source)
        if source ~= "auto" then return end
        local header = "|T" .. C.FAVORITE_ICON .. ":12|t " .. L.NOTIFY_NEW_DISCOVERY
        self:Queue(self:RecordToast(rec, header, vendorLine(rec)))
    end)
    Bus:On("GUILD_DISCOVERY", self, function(_, rec, sender)
        if not FC.Store:IsKnown(rec) then return end
        if FC.Store:IsMine(rec) then return end -- one of your own finds, back from the guild
        local info = UI.Display(rec)
        local header = "|T" .. C.GUILD_ICON .. ":12|t " .. L.NOTIFY_NEW_GUILD_DISCOVERY
        local line = string.format(L.NOTIFY_GUILD_LINE, info.typeLabel, U.ShortName(sender or rec.a), info.zone .. (info.coords and not info.rumored and (" \194\183 " .. info.coords) or ""))
        self:Queue(self:RecordToast(rec, header, line, true))
    end)
    -- progress per character: a discovery another of your characters made
    -- is new to the one you play, and announced like any new find
    Bus:On("DISCOVERY_FOUND", self, function(_, rec)
        local header = "|T" .. C.FAVORITE_ICON .. ":12|t " .. L.NOTIFY_NEW_DISCOVERY
        self:Queue(self:RecordToast(rec, header, vendorLine(rec)))
    end)
    Bus:On("DISCOVERY_ENCOUNTERED", self, function(_, rec)
        local header = "|T" .. C.VERIFIED_ICON .. ":12|t " .. L.NOTIFY_ENCOUNTERED
        self:Queue(self:RecordToast(rec, header, string.format(L.NOTIFY_FIRST_FOUND_BY, U.ShortName(rec.a))))
    end)
    Bus:On("DISCOVERY_REVEALED", self, function(_, rec)
        local header = "|T" .. UI.STATUS.rumored.icon .. ":12|t " .. L.NOTIFY_REVEALED
        self:Queue(self:RecordToast(rec, header, string.format(L.NOTIFY_FIRST_FOUND_BY, U.ShortName(rec.a))))
    end)
    Bus:On("NEARBY_FOUND", self, function(_, rec, kind)
        local header = "|T" .. (kind == "rare" and SKULL_ICON or C.FAVORITE_ICON) .. ":12|t " .. (kind == "rare" and L.NOTIFY_RARE_NEARBY or L.NOTIFY_TREASURE_NEARBY)
        local toast = self:RecordToast(rec, header, nil, false, "nearby")
        toast.soundKey = kind == "rare" and "rare" or "treasure"
        if rec.id and rec.id:find("^vignette:") then toast.onView = nil end
        self:Queue(toast)
        if FC.P.notifications.flash and _G.FlashClientIcon then pcall(_G.FlashClientIcon) end
    end)
    Bus:On("RARE_DEFEATED", self, function(_, rec)
        local header = "|T" .. SKULL_ICON .. ":12|t " .. (rec.t == "rare" and L.NOTIFY_RARE_DEFEATED or L.NOTIFY_BOSS_DEFEATED)
        local estimate = FC.Store:RespawnEstimate(rec)
        local line
        if estimate and estimate.low then
            line = string.format(L.NOTIFY_RESPAWN_LINE, U.FormatDuration(estimate.low), U.FormatDuration(estimate.high))
        end
        self:Queue(self:RecordToast(rec, header, line, false, "kill"))
    end)
    Bus:On("FLIGHT_PATH_LEARNED", self, function() self:PlayFlightPathSound() end)
    Bus:On("SYNC_COMPLETE", self, function(_, count, sender)
        self:Push({
            kind = "sync",
            header = "|T" .. C.GUILD_ICON .. ":12|t " .. L.NOTIFY_SYNC_HEADER,
            title = string.format(L.NOTIFY_SYNC_TITLE, count),
            line = string.format(L.NOTIFY_SYNC_LINE, U.ShortName(sender)),
            icon = C.GUILD_ICON,
            onView = function() FC.MainWindow:Show("guild") end,
        })
    end)
    Bus:On("MILESTONE_UNLOCKED", self, function(_, ms)
        self:Push({
            kind = "milestone",
            soundKey = "milestone",
            header = "|T" .. C.FAVORITE_ICON .. ":12|t " .. L.NOTIFY_MILESTONE,
            title = L[ms.label],
            line = L[ms.desc],
            icon = ms.icon,
            color = Theme:Hex("secret"),
            onView = function() FC.MainWindow:Show("statistics") end,
        })
    end)
    Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if self.anchor and (path == "*" or path:find("^notifications")) then self:PlaceAnchor() end
    end)
end

--- Developer/test helper: shows a sample toast of the given kind.
function Notifications:Test(kind)
    local samples = {
        rare = { "rare", "INV_Misc_Head_Dragon_01", "The Forgotten Watcher" },
        recipe = { "recipe", "INV_Scroll_04", "Recipe: Elixir of Shadows" },
        secret = { "secret", "INV_Misc_QuestionMark", "Hidden cave behind the waterfall" },
        dungeon = { "dungeon", "INV_Misc_Key_03", "Hidden door in the western corridor" },
        guild = { "guild", "INV_Misc_Bag_10", "Mysterious Trader" },
        personal = { "personal", "INV_Misc_Map_01", "Old watchtower ruins" },
    }
    local sample = samples[kind] or samples.rare
    self:Push({
        kind = sample[1], force = true, soundKey = soundByKey[sample[1]] and sample[1] or nil,
        header = "|T" .. C.FAVORITE_ICON .. ":12|t " .. (sample[1] == "guild" and L.NOTIFY_NEW_GUILD_DISCOVERY or L.NOTIFY_NEW_DISCOVERY),
        title = sample[3], line = "Ashenvale \194\183 42.4, 68.1",
        icon = "Interface\\Icons\\" .. sample[2],
        color = Categories:Get(sample[1] == "guild" and "vendor" or (sample[1] == "personal" and "landmark" or sample[1])).color,
    })
end
