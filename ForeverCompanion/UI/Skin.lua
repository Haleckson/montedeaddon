--[[
  Forever Companion - UI/Skin.lua
  The journal style: textures painted for the addon (Media\GUI), drawn as
  9-slice frames and panels, 3-slice plates, tiled leather and illustrated
  page headers. Every texture path, its geometry and the page -> header art
  mapping live here, in one place.

  With the flat style (Settings > Appearance > Style) widgets keep their flat
  theme surfaces; so do they when a texture cannot be loaded.

  Pieces are laid out by hand (corners at a fixed size, edges repeated in
  whole tiles, centers stretched) instead of relying on texture slicing, so
  the result does not depend on how the client scales texels.
]]

local _, FC = ...

local Skin = {}
FC.Skin = Skin

local ROOT = FC.C.MEDIA .. "GUI\\"
local COMMON = ROOT .. "Common\\"
local HEADERS = ROOT .. "Headers\\"

-- Geometry in texels of each file (Media\GUI\Common, made from the
-- Midjourney originals kept in Media\GUI\Source).
Skin.ASSETS = {
    -- 9-slice squares: `corner` texels per corner; the painted band of the
    -- frame runs from bandOuter to bandInner of a corner (fractions)
    frame = { path = COMMON .. "window_frame", size = 256, corner = 64, bandOuter = 0.10, bandInner = 0.64 },
    panel = { path = COMMON .. "panel_parchment", size = 256, corner = 32 },
    background = { path = COMMON .. "window_background", size = 512 },
    -- plates: the shape inside the file (x0..x1, y0..y1) and its end caps
    -- ends: rounded brass, kept whole (36 texels hold the curve and the rivets)
    button = { path = COMMON .. "button_plate", width = 256, height = 64, x0 = 11, x1 = 244, y0 = 2, y1 = 62, left = 36, right = 36 },
    tab = { path = COMMON .. "nav_selected", width = 512, height = 64, x0 = 62, x1 = 449, y0 = 2, y1 = 62, left = 36, right = 30 },
    input = { path = COMMON .. "input_field", width = 512, height = 64, x0 = 57, x1 = 455, y0 = 2, y1 = 62, left = 16, right = 16 },
    divider = { path = COMMON .. "divider", width = 512, height = 32, x0 = 74, x1 = 438, y0 = 2, y1 = 30, left = 16, right = 16, stud = 24 },
    emptyJournal = { path = COMMON .. "empty_journal" },
    emptySearch = { path = COMMON .. "empty_search" },
    glow = { path = COMMON .. "glow" },
    -- over creatures in the world, whatever the journal's style
    questMarker = { path = COMMON .. "quest_marker", width = 64, height = 128 },
}

-- Page header art, by the journal's real page keys (and the settings
-- window). Files are 1024x256; focusY picks the band shown in short headers.
Skin.HEADERS = {
    overview = { file = "header_overview" },
    recent = { file = "header_recent" },
    quests = { file = "header_quests" },
    questlog = { file = "header_quests" },
    npcs = { file = "header_npcs" },
    rares = { file = "header_rares" },
    bestiary = { file = "header_bestiary" },
    vendors = { file = "header_vendors" },
    recipes = { file = "header_recipes" },
    items = { file = "header_items" },
    secrets = { file = "header_secrets" },
    dungeons = { file = "header_dungeons" },
    professions = { file = "header_professions" },
    guild = { file = "header_guild" },
    favorites = { file = "header_favorites" },
    notes = { file = "header_notes" },
    archived = { file = "header_archived" },
    progress = { file = "header_progress" },
    statistics = { file = "header_statistics" },
    biography = { file = "header_biography" },
    settings = { file = "header_settings" },
}

-- The welcome guide's steps.
Skin.BANNERS = {
    progress = { file = "onboarding_progress" },
    share = { file = "onboarding_share" },
}

-- Text drawn on light parchment (the selected tab) is ink, not cream.
Skin.INK = { 0.17, 0.11, 0.06 }

local missing = {}

--- The journal style is on (the default).
function Skin:Enabled()
    return FC.P ~= nil and FC.P.appearance.style ~= "flat"
end

--- Sets a texture file; false (and remembered) when the client cannot load it.
function Skin:SetFile(texture, path)
    if missing[path] then return false end
    local ok = texture:SetTexture(path)
    if ok == false then
        missing[path] = true
        FC.Log:Warn("Texture missing: %s", tostring(path))
        return false
    end
    return true
end

--- Whether an asset can be drawn: the journal style is on and its file loads.
function Skin:Has(key)
    local asset = self.ASSETS[key]
    return asset ~= nil and not missing[asset.path] and self:Enabled()
end

function Skin:HeaderPath(key)
    local def = self.HEADERS[key]
    return def and (HEADERS .. def.file) or nil, def and def.focusY
end

function Skin:BannerPath(key)
    local def = self.BANNERS[key]
    return def and (HEADERS .. def.file) or nil
end

--- Every file the style uses (for checks and the art credits).
function Skin:AllPaths()
    local list = {}
    for _, asset in pairs(self.ASSETS) do list[#list + 1] = asset.path end
    for key in pairs(self.HEADERS) do list[#list + 1] = (self:HeaderPath(key)) end
    for key in pairs(self.BANNERS) do list[#list + 1] = self:BannerPath(key) end
    table.sort(list)
    return list
end

------------------------------------------------------------------------
-- Shared piece handling
------------------------------------------------------------------------

local Pieces = {}
Pieces.__index = Pieces

local function newPieces(frame, key, opts)
    opts = opts or {}
    local asset = Skin.ASSETS[key]
    local set = setmetatable({
        frame = frame,
        key = key,
        asset = asset,
        layer = opts.layer or "BACKGROUND",
        sublevel = opts.sublevel or -6,
        all = {},
        color = { 1, 1, 1, 1 },
        shown = true,
    }, Pieces)
    return set, opts
end

function Pieces:Texture(sublevel)
    local tex = self.frame:CreateTexture(nil, self.layer, nil, sublevel or self.sublevel)
    Skin:SetFile(tex, self.asset.path)
    if tex.SetSnapToPixelGrid then
        -- exact coordinates, so neighbouring pieces meet without gaps
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
    local c = self.color
    tex:SetVertexColor(c[1], c[2], c[3], c[4])
    if self.desaturated and tex.SetDesaturated then tex:SetDesaturated(true) end
    if self.blend then tex:SetBlendMode(self.blend) end
    tex:SetShown(self.shown)
    self.all[#self.all + 1] = tex
    return tex
end

function Pieces:SetVertexColor(r, g, b, a)
    local c = self.color
    c[1], c[2], c[3], c[4] = r, g, b, a or 1
    for _, tex in ipairs(self.all) do tex:SetVertexColor(r, g, b, a or 1) end
end

function Pieces:SetDesaturated(on)
    self.desaturated = on and true or false
    for _, tex in ipairs(self.all) do
        if tex.SetDesaturated then tex:SetDesaturated(self.desaturated) end
    end
end

function Pieces:SetBlendMode(mode)
    self.blend = mode
    for _, tex in ipairs(self.all) do tex:SetBlendMode(mode) end
end

function Pieces:SetShown(shown)
    self.shown = shown and true or false
    if self.shown then
        self:Layout()
    else
        for _, tex in ipairs(self.all) do tex:Hide() end
    end
end

function Pieces:Show() self:SetShown(true) end
function Pieces:Hide() self:SetShown(false) end
function Pieces:IsShown() return self.shown end

-- A list of textures that repeat along a length; extras are hidden.
local function repeated(set, list, count)
    for i = #list + 1, count do list[i] = set:Texture() end
    for i = count + 1, #list do list[i]:Hide() end
end

local function watch(set)
    set.frame:HookScript("OnSizeChanged", function()
        if set.shown then set:Layout() end
    end)
    set:Layout()
    return set
end

------------------------------------------------------------------------
-- 9-slice: corners, edges in whole tiles, stretched center
------------------------------------------------------------------------

local NineSlice = setmetatable({}, { __index = Pieces })
NineSlice.__index = NineSlice

--- opts: corner (UI units of one corner), center (false: hollow), layer, sublevel
function Skin:NineSlice(frame, key, opts)
    local set
    set, opts = newPieces(frame, key, opts)
    setmetatable(set, NineSlice)
    set.corner = opts.corner or 24
    set.hollow = opts.center == false
    set.tl, set.tr, set.bl, set.br = set:Texture(), set:Texture(), set:Texture(), set:Texture()
    set.top, set.bottom, set.left, set.right, set.centers = {}, {}, {}, {}, {}
    return watch(set)
end

--- The corner size in UI units (a frame's painted band and insets follow it).
function NineSlice:SetCorner(size)
    self.corner = size
    if self.shown then self:Layout() end
end

function NineSlice:Layout()
    if not self.shown then return end
    local frame = self.frame
    local w, h = frame:GetWidth(), frame:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then return end
    local a = self.asset
    local f = a.corner / a.size                       -- a corner, as a fraction of the file
    local C = math.min(self.corner, w / 2, h / 2)
    local tile = C * (a.size - 2 * a.corner) / a.corner -- UI length of one edge tile

    local function corner(tex, point, l, r, t, b)
        tex:ClearAllPoints()
        tex:SetPoint(point, frame, point, 0, 0)
        tex:SetSize(C, C)
        tex:SetTexCoord(l, r, t, b)
        tex:Show()
    end
    corner(self.tl, "TOPLEFT", 0, f, 0, f)
    corner(self.tr, "TOPRIGHT", 1 - f, 1, 0, f)
    corner(self.bl, "BOTTOMLEFT", 0, f, 1 - f, 1)
    corner(self.br, "BOTTOMRIGHT", 1 - f, 1, 1 - f, 1)

    local function edge(list, length, horizontal, point, l, r, t, b)
        if length <= 0 then
            repeated(self, list, 0)
            return
        end
        local count = math.max(1, math.floor(length / tile + 0.5))
        local step = length / count
        repeated(self, list, count)
        for i = 1, count do
            local tex = list[i]
            tex:ClearAllPoints()
            if horizontal then
                tex:SetPoint(point, frame, point, C + (i - 1) * step, 0)
                tex:SetSize(step, C)
            else
                tex:SetPoint(point, frame, point, 0, -(C + (i - 1) * step))
                tex:SetSize(C, step)
            end
            tex:SetTexCoord(l, r, t, b)
            tex:Show()
        end
    end
    edge(self.top, w - 2 * C, true, "TOPLEFT", f, 1 - f, 0, f)
    edge(self.bottom, w - 2 * C, true, "BOTTOMLEFT", f, 1 - f, 1 - f, 1)
    edge(self.left, h - 2 * C, false, "TOPLEFT", 0, f, f, 1 - f)
    edge(self.right, h - 2 * C, false, "TOPRIGHT", 1 - f, 1, f, 1 - f)

    -- the middle repeats at the same scale as the edges (it is a seamless
    -- tile; stretched, a long flat panel turned its grain into streaks)
    if not self.hollow then
        local cw, ch = w - 2 * C, h - 2 * C
        if cw <= 0 or ch <= 0 then
            repeated(self, self.centers, 0)
            return
        end
        local cols, rows = math.ceil(cw / tile - 0.001), math.ceil(ch / tile - 0.001)
        repeated(self, self.centers, cols * rows)
        local span = 1 - 2 * f
        local i = 0
        for row = 1, rows do
            for col = 1, cols do
                i = i + 1
                local tex = self.centers[i]
                local tw = math.min(tile, cw - (col - 1) * tile)
                local th = math.min(tile, ch - (row - 1) * tile)
                tex:ClearAllPoints()
                tex:SetPoint("TOPLEFT", frame, "TOPLEFT", C + (col - 1) * tile, -(C + (row - 1) * tile))
                tex:SetSize(tw, th)
                tex:SetTexCoord(f, f + span * tw / tile, f, f + span * th / tile)
                tex:Show()
            end
        end
    end
end

--- How far a frame's content stays from its edge: past the band, with a
--- strip of leather between the frame and what lies inside it.
function Skin:FrameInset(corner)
    return math.ceil(corner * self.ASSETS.frame.bandInner) + 9
end

------------------------------------------------------------------------
-- Tiled fill (the leather background)
------------------------------------------------------------------------

local Tiled = setmetatable({}, { __index = Pieces })
Tiled.__index = Tiled

--- opts: tile (UI units of one tile), inset (UI units kept clear on every side)
function Skin:Tiled(frame, key, opts)
    local set
    set, opts = newPieces(frame, key, opts)
    setmetatable(set, Tiled)
    set.tile = opts.tile or 320
    set.inset = opts.inset or 0
    set.tiles = {}
    return watch(set)
end

function Tiled:SetInset(inset)
    self.inset = inset
    if self.shown then self:Layout() end
end

function Tiled:Layout()
    if not self.shown then return end
    local frame = self.frame
    local inset = self.inset
    local w, h = (frame:GetWidth() or 0) - 2 * inset, (frame:GetHeight() or 0) - 2 * inset
    if w <= 1 or h <= 1 then return end
    local T = self.tile
    local cols, rows = math.ceil(w / T), math.ceil(h / T)
    repeated(self, self.tiles, cols * rows)
    local i = 0
    for row = 1, rows do
        for col = 1, cols do
            i = i + 1
            local tex = self.tiles[i]
            local tw = math.min(T, w - (col - 1) * T)
            local th = math.min(T, h - (row - 1) * T)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", frame, "TOPLEFT", inset + (col - 1) * T, -(inset + (row - 1) * T))
            tex:SetSize(tw, th)
            tex:SetTexCoord(0, tw / T, 0, th / T)
            tex:Show()
        end
    end
end

------------------------------------------------------------------------
-- Plates: left cap, stretched middle, right cap (buttons, tabs, inputs)
------------------------------------------------------------------------

local Plate = setmetatable({}, { __index = Pieces })
Plate.__index = Plate

function Skin:Plate(frame, key, opts)
    local set
    set, opts = newPieces(frame, key, opts)
    setmetatable(set, Plate)
    set.l, set.m, set.r = set:Texture(), set:Texture(), set:Texture()
    return watch(set)
end

--- UI width of the end caps at the frame's height (content padding).
function Plate:CapWidth()
    local a = self.asset
    local h = self.frame:GetHeight() or 0
    return a.left * h / (a.y1 - a.y0)
end

function Plate:Layout()
    if not self.shown then return end
    local frame = self.frame
    local w, h = frame:GetWidth(), frame:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then return end
    local a = self.asset
    local scale = h / (a.y1 - a.y0)
    local L, R = a.left * scale, a.right * scale
    if L + R > w then
        local k = w / (L + R)
        L, R = L * k, R * k
    end
    local W, H = a.width, a.height
    local t, b = a.y0 / H, a.y1 / H
    self.l:ClearAllPoints()
    self.l:SetPoint("TOPLEFT")
    self.l:SetPoint("BOTTOMLEFT")
    self.l:SetWidth(L)
    self.l:SetTexCoord(a.x0 / W, (a.x0 + a.left) / W, t, b)
    self.r:ClearAllPoints()
    self.r:SetPoint("TOPRIGHT")
    self.r:SetPoint("BOTTOMRIGHT")
    self.r:SetWidth(R)
    self.r:SetTexCoord((a.x1 - a.right) / W, a.x1 / W, t, b)
    self.m:ClearAllPoints()
    self.m:SetPoint("TOPLEFT", L, 0)
    self.m:SetPoint("BOTTOMRIGHT", -R, 0)
    self.m:SetTexCoord((a.x0 + a.left) / W, (a.x1 - a.right) / W, t, b)
    for _, tex in ipairs(self.all) do tex:Show() end
end

------------------------------------------------------------------------
-- Divider: pointed ends, a stud in the middle, bars stretched between
------------------------------------------------------------------------

local Divider = setmetatable({}, { __index = Pieces })
Divider.__index = Divider

function Skin:Divider(frame, opts)
    local set
    set, opts = newPieces(frame, "divider", opts)
    setmetatable(set, Divider)
    set.l, set.lm, set.stud, set.rm, set.r = set:Texture(), set:Texture(), set:Texture(), set:Texture(), set:Texture()
    return watch(set)
end

function Divider:Layout()
    if not self.shown then return end
    local frame = self.frame
    local w, h = frame:GetWidth(), frame:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then return end
    local a = self.asset
    local W, H = a.width, a.height
    local scale = h / (a.y1 - a.y0)
    local cap, stud = a.left * scale, a.stud * scale
    local mid = (a.x0 + a.x1) / 2
    local t, b = a.y0 / H, a.y1 / H
    local bar = math.max(0, (w - 2 * cap - stud) / 2)
    local function place(tex, x, width, l, r)
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", x, 0)
        tex:SetSize(math.max(0.01, width), h)
        tex:SetTexCoord(l, r, t, b)
        tex:Show()
    end
    place(self.l, 0, cap, a.x0 / W, (a.x0 + a.left) / W)
    place(self.lm, cap, bar, (a.x0 + a.left) / W, (mid - a.stud / 2) / W)
    place(self.stud, cap + bar, stud, (mid - a.stud / 2) / W, (mid + a.stud / 2) / W)
    place(self.rm, cap + bar + stud, bar, (mid + a.stud / 2) / W, (a.x1 - a.right) / W)
    place(self.r, w - cap, cap, (a.x1 - a.right) / W, a.x1 / W)
end

------------------------------------------------------------------------
-- Illustration that covers its frame without distortion
------------------------------------------------------------------------

local Art = setmetatable({}, { __index = Pieces })
Art.__index = Art

--- Art for page headers and banners: fills the frame, keeps the file's
--- proportions (aspect = width / height of the file), crops the rest.
function Skin:Art(frame, opts)
    opts = opts or {}
    local set = setmetatable({
        frame = frame, all = {}, color = { 1, 1, 1, 1 }, shown = true,
        layer = opts.layer or "BACKGROUND", sublevel = opts.sublevel or -4,
        aspect = opts.aspect or 4, focusX = 0.5, focusY = 0.5,
    }, Art)
    set.tex = frame:CreateTexture(nil, set.layer, nil, set.sublevel)
    set.tex:SetAllPoints(frame)
    set.all[1] = set.tex
    return watch(set)
end

function Art:SetArt(path, focusX, focusY)
    self.path = path
    self.focusX, self.focusY = focusX or 0.5, focusY or 0.5
    self.ok = path ~= nil and Skin:SetFile(self.tex, path)
    self:Layout()
    return self.ok
end

function Art:Layout()
    if not self.shown or not self.ok then
        self.tex:Hide()
        return
    end
    local w, h = self.frame:GetWidth(), self.frame:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then return end
    local ratio = w / h
    if ratio >= self.aspect then
        local visible = self.aspect / ratio
        local top = (1 - visible) * self.focusY
        self.tex:SetTexCoord(0, 1, top, top + visible)
    else
        local visible = ratio / self.aspect
        local left = (1 - visible) * self.focusX
        self.tex:SetTexCoord(left, left + visible, 0, 1)
    end
    self.tex:Show()
end

------------------------------------------------------------------------
-- Gradient shade (legibility of titles over art)
------------------------------------------------------------------------

--- A texture shaded from one side: orientation "HORIZONTAL" (left dark) or
--- "VERTICAL" (bottom dark); r, g, b and the strongest alpha.
function Skin:Shade(frame, orientation, r, g, b, alpha, layer, sublevel)
    local tex = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or -3)
    tex:SetTexture(FC.C.WHITE)
    local ok = false
    if tex.SetGradient and CreateColor then
        ok = pcall(tex.SetGradient, tex, orientation, CreateColor(r, g, b, alpha), CreateColor(r, g, b, 0))
    end
    if not ok then tex:SetColorTexture(r, g, b, alpha * 0.5) end
    return tex
end
